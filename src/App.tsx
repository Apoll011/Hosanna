// src/App.tsx
import {
    AlertTriangle,
    ArrowLeft,
    CalendarRange,
    CircleDot,
    Menu,
    Music,
    Plus,
    RefreshCw,
    Search,
    Settings,
    Timer,
    X,
} from "lucide-react";
import { useEffect, useRef, useState } from "react";
import FirstTimeSetup from "./components/FirstTimeSetup";
import NavigationDrawer from "./components/NavigationDrawer";
import ServiceManager from "./components/ServiceManager";
import SongBrowser from "./components/SongBrowser";
import SongEditor from "./components/SongEditor";
import SongView from "./components/SongView";
import { AuthProvider, useAuth } from "./contexts/AuthContext";
import { useAppStore } from "./store/appStore";
import { getSectionTitle } from "./utils";
import { Badge } from "./components/ui/badge";
import { Button } from "./components/ui/button";

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

function AppContent() {
    const theme = useAppStore((state) => state.theme);
    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const syncStatus = useAppStore((state) => state.syncStatus);
    const hasSkippedSetup = useAppStore((state) => state.hasSkippedSetup);
    const rehydrateStore = useAppStore((state) => state.rehydrateStore);
    const isHydrated = useAppStore((state) => state.isHydrated);

    const { isAuthenticated, isLoading: isAuthLoading } = useAuth();

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
    const lastVisibilitySyncRef = useRef<number>(0);

    const selectedFolder = useAppStore((state) => state.selectedFolder);

    const searchQuery = useAppStore((state) => state.searchQuery);
    const setSearchQuery = useAppStore((state) => state.setSearchQuery);
    const [showDrawer, setShowDrawer] = useState(false);

    const initRxDbSubscriptions = useAppStore(
        (state) => state.initRxDbSubscriptions,
    );

    useEffect(() => {
        rehydrateStore();
        let unsubscribe: (() => void) | undefined;
        initRxDbSubscriptions().then((unsub) => {
            unsubscribe = unsub;
        });

        return () => {
            if (unsubscribe) unsubscribe();
        };
    }, [rehydrateStore, initRxDbSubscriptions]);

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

    useEffect(() => {
        const handleVisibilityChange = () => {
            if (document.visibilityState === "visible") {
                const now = Date.now();
                const THIRTY_SECONDS = 30 * 1000;
                if (now - lastVisibilitySyncRef.current < THIRTY_SECONDS)
                    return;
                lastVisibilitySyncRef.current = now;
                rehydrateStore().then(() => {
                    syncLibrary().catch(() => {});
                });
            }
        };
        document.addEventListener("visibilitychange", handleVisibilityChange);
        return () =>
            document.removeEventListener(
                "visibilitychange",
                handleVisibilityChange,
            );
    }, [rehydrateStore, syncLibrary]);

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

    // Show loading splash while IndexedDB is being read
    if (!isHydrated) {
        return (
            <div className="flex-1 flex flex-col items-center justify-center bg-background">
                <div className="flex flex-col items-center gap-4">
                    <img
                        src="/logo.png"
                        className="w-16 h-16 rounded-3xl shadow-xl border border-border/40 object-cover"
                        alt="Hosanna"
                    />
                    <div className="flex gap-1.5">
                        {[0, 1, 2].map((i) => (
                            <div
                                key={i}
                                className="w-2 h-2 rounded-full bg-primary/70 animate-bounce"
                                style={{ animationDelay: `${i * 150}ms` }}
                            />
                        ))}
                    </div>
                </div>
            </div>
        );
    }

    if (!hasSkippedSetup && !isAuthenticated && !isAuthLoading) {
        return <FirstTimeSetup />;
    }

    return (
        <div className="flex-1 flex overflow-hidden bg-background text-foreground relative h-full">
            {/* Tablet Sidebar Navigation for large viewports (>= md / 768px) */}
            {!activeSongId && !isEditing && !isPresenting && (
                <aside className="hidden md:flex flex-col w-64 border-r border-border bg-card p-4 shrink-0 justify-between select-none">
                    <div className="space-y-6">
                        {/* Tablet Brand Header */}
                        <div className="flex items-center gap-3 px-2">
                            <img
                                src="/logo.png"
                                className="w-9 h-9 rounded-2xl border border-border/40 shadow-xs object-cover"
                                alt="Hosanna"
                            />
                            <div>
                                <h1 className="text-base font-black text-primary tracking-tight">
                                    Hosanna
                                </h1>
                                <p className="text-[10px] text-muted-foreground font-semibold">
                                    Música & Cultos
                                </p>
                            </div>
                        </div>

                        {/* Navigation Links */}
                        <nav className="space-y-1">
                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "all" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                    activeListContext.type !== "service" && !isOnMenu
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent hover:text-accent-foreground"
                                }`}
                            >
                                <Music className="w-4 h-4" />
                                <span>Cânticos</span>
                            </button>

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "service" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                    activeListContext.type === "service"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent hover:text-accent-foreground"
                                }`}
                            >
                                <CalendarRange className="w-4 h-4" />
                                <span>Cultos</span>
                            </button>

                            <div className="h-px bg-border/60 my-2" />

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "circle" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                    activeListContext.type === "circle"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent hover:text-accent-foreground"
                                }`}
                            >
                                <CircleDot className="w-4 h-4 text-emerald-500" />
                                <span>Círculo da Quinta</span>
                            </button>

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "metronome" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                    activeListContext.type === "metronome"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent hover:text-accent-foreground"
                                }`}
                            >
                                <Timer className="w-4 h-4 text-sky-500" />
                                <span>Metrónomo</span>
                            </button>

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "settings" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                    activeListContext.type === "settings"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent hover:text-accent-foreground"
                                }`}
                            >
                                <Settings className="w-4 h-4 text-slate-400" />
                                <span>Definições</span>
                            </button>
                        </nav>
                    </div>

                    <div className="pt-4 border-t border-border">
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setShowDrawer(true)}
                            className="w-full justify-start text-xs font-bold gap-2"
                        >
                            <Menu className="w-4 h-4 text-primary" />
                            <span>Explorar Biblioteca</span>
                        </Button>
                    </div>
                </aside>
            )}

            <div className="flex-1 flex flex-col h-full overflow-hidden">
                {/* Mobile / Universal Top App Bar */}
                {!activeSongId && !isEditing && !isPresenting && (
                    <header className="px-3.5 sm:px-5 pb-3.5 pt-[calc(0.75rem+env(safe-area-inset-top,0px))] bg-background border-b border-border flex items-center gap-2.5 shrink-0 z-20 relative">
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setShowDrawer(true)}
                            className="h-10 px-2.5 sm:px-3 rounded-2xl flex items-center gap-2 md:hidden"
                            title="Abrir Menu de Navegação"
                        >
                            <img
                                src="/logo.png"
                                className="w-6 h-6 rounded-lg object-cover border border-border/40 shadow-2xs"
                                alt="Hosanna"
                            />
                            <Menu className="w-4 h-4 text-primary" />
                        </Button>

                        {!isOnMenu ? (
                            <div className="relative flex-1 max-w-2xl">
                                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
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
                                    className="w-full pl-10 pr-9 py-2 bg-card border border-input rounded-2xl text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent text-foreground placeholder:text-muted-foreground transition-all shadow-2xs"
                                />
                                {searchQuery !== "" && (
                                    <button
                                        onClick={() => setSearchQuery("")}
                                        className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 rounded-full text-muted-foreground hover:text-foreground transition-colors"
                                        title="Limpar pesquisa"
                                    >
                                        <X className="w-3.5 h-3.5" />
                                    </button>
                                )}
                            </div>
                        ) : (
                            <div className="flex-1 flex items-center justify-between">
                                <h2 className="text-base sm:text-lg font-black text-foreground tracking-tight">
                                    {getSectionTitle(
                                        activeListContext.type,
                                        activeListContext.folderName,
                                        selectedFolder,
                                    )}
                                </h2>

                                <Button
                                    variant="outline"
                                    size="icon-sm"
                                    onClick={() =>
                                        setActiveListContext({ type: "all" })
                                    }
                                    className="rounded-2xl"
                                    title="Voltar para Cânticos"
                                >
                                    <ArrowLeft className="w-4 h-4 text-primary" />
                                </Button>
                            </div>
                        )}
                    </header>
                )}

                <NavigationDrawer
                    show={showDrawer}
                    onClose={() => setShowDrawer(false)}
                />

                <div
                    ref={contentRef}
                    className="flex-1 overflow-hidden relative touch-pan-y"
                >
                    {/* Pull-to-Refresh Native Indicator */}
                    <div
                        className="absolute left-1/2 top-2 z-30 flex items-center justify-center w-9 h-9 rounded-full bg-card border border-border/80 shadow-md pointer-events-none"
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
                            <AlertTriangle className="w-4 h-4 text-destructive" />
                        ) : (
                            <RefreshCw
                                className={`w-4 h-4 text-primary ${isSyncing ? "animate-spin" : ""}`}
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

                {/* Mobile Floating Bottom Bar (Hidden on Tablets/Desktop & in full views) */}
                {!activeSongId && !isEditing && !isPresenting && !isOnMenu && (
                    <div className="md:hidden absolute bottom-[calc(1rem+env(safe-area-inset-bottom,0px))] left-1/2 -translate-x-1/2 w-[72%] max-w-60 h-14 bg-card/85 border border-border/80 rounded-full shadow-xl shadow-black/10 px-3 flex items-center justify-around select-none z-40 backdrop-blur-md">
                        <button
                            onClick={() => {
                                setActiveListContext({ type: "all" });
                                setActiveSongId(null);
                                setIsEditing(false);
                            }}
                            id="nav_btn_songs"
                            className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all cursor-pointer ${
                                activeListContext.type !== "service"
                                    ? "text-primary scale-105"
                                    : "text-muted-foreground hover:text-foreground"
                            }`}
                        >
                            <div
                                className={`px-4 py-0.5 rounded-full transition-all ${
                                    activeListContext.type !== "service"
                                        ? "bg-primary/15 text-primary"
                                        : ""
                                }`}
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
                            className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all cursor-pointer ${
                                activeListContext.type === "service"
                                    ? "text-primary scale-105"
                                    : "text-muted-foreground hover:text-foreground"
                            }`}
                        >
                            <div
                                className={`px-4 py-0.5 rounded-full transition-all ${
                                    activeListContext.type === "service"
                                        ? "bg-primary/15 text-primary"
                                        : ""
                                }`}
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

export default function App() {
    return (
        <AuthProvider>
            <AppContent />
        </AuthProvider>
    );
}
