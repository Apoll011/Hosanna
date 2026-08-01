// src/App.tsx
import {
    AlertTriangle,
    ArrowLeft,
    CalendarRange,
    Menu,
    Music,
    RefreshCw,
    Search,
} from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useAppStore } from "./store/appStore";

import FirstTimeSetup from "./components/FirstTimeSetup";
import NavigationDrawer from "./components/NavigationDrawer";
import ServiceManager from "./components/ServiceManager";
import SongBrowser from "./components/SongBrowser";
import SongEditor from "./components/SongEditor";
import SongView from "./components/SongView";
import { getSectionTitle } from "./utils";

const PULL_THRESHOLD = 68;
const PULL_MAX = 96;
const PULL_RESISTANCE = 0.5;

const findScrollableAncestor = (
    start: HTMLElement | null,
    boundary: HTMLElement,
): HTMLElement => {
    let node: HTMLElement | null = start;
    while (node && node !== boundary.parentElement) {
        const style = window.getComputedStyle(node);
        const canScrollY =
            (style.overflowY === "auto" || style.overflowY === "scroll") &&
            node.scrollHeight > node.clientHeight;
        if (canScrollY) return node;
        if (node === boundary) break;
        node = node.parentElement;
    }
    return boundary;
};

export default function App() {
    const theme = useAppStore((state) => state.theme);
    const songsLength = useAppStore((state) => state.songs.length);
    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const syncStatus = useAppStore((state) => state.syncStatus);
    const serverUrl = useAppStore((state) => state.serverUrl);
    const serverToken = useAppStore((state) => state.serverToken);
    const hasSkippedSetup = useAppStore((state) => state.hasSkippedSetup);

    const activeSongId = useAppStore((state) => state.activeSongId);
    const setActiveSongId = useAppStore((state) => state.setActiveSongId);

    const isEditing = useAppStore((state) => state.isEditing);
    const setIsEditing = useAppStore((state) => state.setIsEditing);

    const isPresenting = useAppStore((state) => state.isPresenting);

    const activeListContext = useAppStore((state) => state.activeListContext);
    const setActiveListContext = useAppStore(
        (state) => state.setActiveListContext,
    );

    const contentRef = useRef<HTMLDivElement>(null);
    const [pullDistance, setPullDistance] = useState(0);
    const [isPulling, setIsPulling] = useState(false);
    const touchStartY = useRef<number | null>(null);
    const scrollAncestorRef = useRef<HTMLElement | null>(null);

    const selectedFolder = useAppStore((state) => state.selectedFolder);

    const searchQuery = useAppStore((state) => state.searchQuery);
    const setSearchQuery = useAppStore((state) => state.setSearchQuery);
    const [showDrawer, setShowDrawer] = useState(false);

    useEffect(() => {
        if (songsLength === 0) {
            syncLibrary();
        }
    }, [songsLength, syncLibrary]);

    useEffect(() => {
        const root = document.documentElement;
        const applyTheme = (currentTheme: "light" | "dark") => {
            if (currentTheme === "dark") {
                root.classList.add("dark");
            } else {
                root.classList.remove("dark");
            }
        };

        if (theme === "system") {
            const systemPrefersDark = window.matchMedia(
                "(prefers-color-scheme: dark)",
            ).matches;
            applyTheme(systemPrefersDark ? "dark" : "light");

            const mediaQuery = window.matchMedia(
                "(prefers-color-scheme: dark)",
            );
            const handleMediaChange = (e: MediaQueryListEvent) => {
                applyTheme(e.matches ? "dark" : "light");
            };
            mediaQuery.addEventListener("change", handleMediaChange);
            return () =>
                mediaQuery.removeEventListener("change", handleMediaChange);
        } else {
            applyTheme(theme);
        }

        return;
    }, [theme]);

    useEffect(() => {
        const boundary = contentRef.current;
        if (!boundary) return;

        const handleTouchStart = (e: TouchEvent) => {
            if (syncStatus === "syncing" || isEditing || isPresenting) return;

            const scrollEl = findScrollableAncestor(
                e.target as HTMLElement,
                boundary,
            );
            scrollAncestorRef.current = scrollEl;

            if (scrollEl.scrollTop > 0) {
                touchStartY.current = null;
                return;
            }

            touchStartY.current = e.touches[0].clientY;
        };

        const handleTouchMove = (e: TouchEvent) => {
            if (touchStartY.current === null) return;

            const deltaY = e.touches[0].clientY - touchStartY.current;

            if (
                deltaY <= 0 ||
                (scrollAncestorRef.current &&
                    scrollAncestorRef.current.scrollTop > 0)
            ) {
                setIsPulling(false);
                setPullDistance(0);
                touchStartY.current = null;
                return;
            }

            e.preventDefault();
            setIsPulling(true);
            setPullDistance(Math.min(PULL_MAX, deltaY * PULL_RESISTANCE));
        };

        const handleTouchEnd = () => {
            if (touchStartY.current === null) return;
            touchStartY.current = null;
            setIsPulling(false);

            setPullDistance((current) => {
                if (current >= PULL_THRESHOLD) {
                    syncLibrary();
                }
                return 0;
            });
        };

        boundary.addEventListener("touchstart", handleTouchStart, {
            passive: true,
        });
        boundary.addEventListener("touchmove", handleTouchMove, {
            passive: false,
        });
        boundary.addEventListener("touchend", handleTouchEnd, {
            passive: true,
        });
        boundary.addEventListener("touchcancel", handleTouchEnd, {
            passive: true,
        });

        return () => {
            boundary.removeEventListener("touchstart", handleTouchStart);
            boundary.removeEventListener("touchmove", handleTouchMove);
            boundary.removeEventListener("touchend", handleTouchEnd);
            boundary.removeEventListener("touchcancel", handleTouchEnd);
        };
    }, [syncStatus, isEditing, isPresenting, syncLibrary]);

    const indicatorActive = isPulling || syncStatus === "syncing";
    const indicatorOffset = isPulling
        ? pullDistance
        : syncStatus === "syncing"
          ? 44
          : 0;
    const indicatorProgress = Math.min(1, pullDistance / PULL_THRESHOLD);
    const isSyncing = syncStatus === "syncing";

    const isOnMenu =
        activeListContext.type === "circle" ||
        activeListContext.type === "metronome" ||
        activeListContext.type === "settings";

    if (!serverUrl && !serverToken && !hasSkippedSetup) {
        return <FirstTimeSetup />;
    }

    return (
        <div className="flex-1 flex overflow-hidden bg-m3-bg dark:bg-m3-dark-bg text-m3-text dark:text-m3-dark-text relative h-full">
            <div className="flex-1 flex flex-col h-full overflow-hidden">
                {!activeSongId &&
                    !isEditing &&
                    !isPresenting &&
                    (!isOnMenu ? (
                        <div className="p-4 bg-m3-bg dark:bg-m3-dark-bg border-b border-m3-border dark:border-m3-dark-border flex items-center gap-2 shrink-0 z-10 relative">
                            <button
                                onClick={() => setShowDrawer(true)}
                                className="p-1.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text transition-all active:scale-95 flex items-center gap-2 pr-3"
                                title="Abrir Menu de Navegação"
                            >
                                <img
                                    src="/logo.png"
                                    className="w-7 h-7 rounded-lg object-cover border border-m3-border/20 shadow-xs"
                                    alt="Hosanna"
                                    referrerPolicy="no-referrer"
                                />
                                <Menu className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                            </button>

                            <div className="relative flex-1">
                                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-m3-secondary dark:text-m3-dark-secondary" />
                                <input
                                    type="text"
                                    placeholder={
                                        activeListContext.type === "service"
                                            ? "Pesquisar cultos..."
                                            : "Pesquisar título, autor, letra..."
                                    }
                                    value={searchQuery}
                                    onChange={(e) =>
                                        setSearchQuery(e.target.value)
                                    }
                                    className="w-full pl-10 pr-4 py-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-m3-primary/20 focus:border-m3-primary text-m3-text dark:text-m3-dark-text placeholder-m3-secondary/70"
                                />
                            </div>
                        </div>
                    ) : (
                        <div className="flex items-center justify-between">
                            <div className="flex-1">
                                <h2 className="text-lg font-black text-m3-text dark:text-m3-dark-text tracking-tight">
                                    {getSectionTitle(
                                        activeListContext.type,
                                        activeListContext.folderName,
                                        selectedFolder,
                                    )}
                                </h2>
                            </div>

                            <button
                                onClick={() =>
                                    setActiveListContext({ type: "all" })
                                }
                                className="p-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text transition-all active:scale-95"
                                title="Voltar para Cânticos"
                            >
                                <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                            </button>
                        </div>
                    ))}

                <NavigationDrawer
                    show={showDrawer}
                    onClose={() => setShowDrawer(false)}
                />

                <div
                    ref={contentRef}
                    className="flex-1 overflow-hidden relative touch-pan-y"
                >
                    <div
                        className="absolute left-1/2 top-2 z-30 flex items-center justify-center w-9 h-9 rounded-full bg-m3-toolbar/95 dark:bg-m3-dark-toolbar/95 border border-m3-border/40 dark:border-m3-dark-border/40 shadow-md pointer-events-none"
                        style={{
                            transform: `translate(-50%, ${indicatorOffset - 40}px)`,
                            opacity: indicatorActive
                                ? isSyncing
                                    ? 1
                                    : indicatorProgress
                                : 0,
                            transition: isPulling
                                ? "none"
                                : "transform 0.25s ease, opacity 0.25s ease",
                        }}
                    >
                        {syncStatus === "error" && !isSyncing ? (
                            <AlertTriangle className="w-4 h-4 text-red-500" />
                        ) : (
                            <RefreshCw
                                className={`w-4 h-4 text-m3-primary dark:text-m3-dark-primary ${isSyncing ? "animate-spin" : ""}`}
                                style={
                                    !isSyncing
                                        ? {
                                              transform: `rotate(${indicatorProgress * 360}deg)`,
                                          }
                                        : undefined
                                }
                            />
                        )}
                    </div>

                    <div
                        style={{
                            transform: `translateY(${isPulling ? pullDistance : 0}px)`,
                            transition: isPulling
                                ? "none"
                                : "transform 0.25s ease",
                        }}
                        className="h-full"
                    >
                        {activeListContext.type === "service" ? (
                            <ServiceManager />
                        ) : (
                            <>
                                {isEditing ? (
                                    <SongEditor
                                        songId={activeSongId || undefined}
                                        onClose={() => setIsEditing(false)}
                                    />
                                ) : activeSongId ? (
                                    <SongView
                                        songId={activeSongId}
                                        onBack={() => setActiveSongId(null)}
                                        onEdit={() => setIsEditing(true)}
                                        setSong={setActiveSongId}
                                    />
                                ) : (
                                    <SongBrowser
                                        onSelectSong={(id) => {
                                            setActiveSongId(id);
                                            setIsEditing(false);
                                        }}
                                        onAddNewSong={() => {
                                            setActiveSongId(null);
                                            setIsEditing(true);
                                        }}
                                    />
                                )}
                            </>
                        )}
                    </div>
                </div>

                {!activeSongId && !isEditing && !isPresenting && (
                    <div className="absolute bottom-5 left-1/2 -translate-x-1/2 w-[70%] max-w-[220px] h-14 bg-m3-toolbar/90 dark:bg-m3-dark-toolbar/90 border border-m3-border/40 dark:border-m3-dark-border/40 rounded-full shadow-lg shadow-black/10 px-4 flex items-center justify-around select-none z-40 backdrop-blur-md animate-fade-in">
                        <button
                            onClick={() => {
                                setActiveListContext({ type: "all" });
                                setActiveSongId(null);
                                setIsEditing(false);
                            }}
                            id="nav_btn_songs"
                            className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all ${
                                activeListContext.type !== "service"
                                    ? "text-m3-primary dark:text-m3-dark-primary scale-105"
                                    : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text"
                            }`}
                        >
                            <div
                                className={`px-5 py-0.5 rounded-full transition-all ${activeListContext.type !== "service" ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border border-m3-border/20 dark:border-m3-dark-border/20" : ""}`}
                            >
                                <Music className="w-4.5 h-4.5" />
                            </div>
                            <span className="text-[10px] font-black tracking-wide">
                                Cânticos
                            </span>
                        </button>

                        <button
                            onClick={() => {
                                setActiveListContext({ type: "service" });
                                setActiveSongId(null);
                                setIsEditing(false);
                            }}
                            id="nav_btn_services"
                            className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all ${
                                activeListContext.type === "service"
                                    ? "text-m3-primary dark:text-m3-dark-primary scale-105"
                                    : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text"
                            }`}
                        >
                            <div
                                className={`px-5 py-0.5 rounded-full transition-all ${activeListContext.type === "service" ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border border-m3-border/20 dark:border-m3-dark-border/20" : ""}`}
                            >
                                <CalendarRange className="w-4.5 h-4.5" />
                            </div>
                            <span className="text-[10px] font-black tracking-wide">
                                Cultos
                            </span>
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}
