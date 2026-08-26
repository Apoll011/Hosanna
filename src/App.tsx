// src/App.tsx
import {
    AlertTriangle,
    ArrowLeft,
    CalendarRange,
    ChevronLeft,
    ChevronRight,
    CircleDot,
    Clock,
    Folder,
    Heart,
    LogIn,
    Menu,
    Music,
    RefreshCw,
    Search,
    Settings,
    Timer,
    WifiOff,
    X,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import { AuthModal } from "./components/auth/AuthModal";
import FirstTimeSetup from "./components/FirstTimeSetup";
import NavigationDrawer from "./components/NavigationDrawer";
import ServiceManager from "./components/ServiceManager";
import { getRoleBadge } from "./components/settings/settingsUtils";
import SongBrowser from "./components/SongBrowser";
import SongEditor from "./components/SongEditor";
import SongView from "./components/SongView";
import { Badge } from "./components/ui/badge";
import { Button } from "./components/ui/button";
import { AuthProvider, useAuth } from "./contexts/AuthContext";
import { useAppStore } from "./store/appStore";
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

function AppContent() {
    const theme = useAppStore((state) => state.theme);
    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const syncStatus = useAppStore((state) => state.syncStatus);
    const hasSkippedSetup = useAppStore((state) => state.hasSkippedSetup);
    const rehydrateStore = useAppStore((state) => state.rehydrateStore);
    const isHydrated = useAppStore((state) => state.isHydrated);

    const { user, organization, isAuthenticated, isLoading: isAuthLoading, isOfflineAuth, refetch: refetchAuth } = useAuth();

    const songs = useAppStore((state) => state.songs);
    const favoriteSongIds = useAppStore((state) => state.favoriteSongIds);
    const recentlyPlayedSongIds = useAppStore(
        (state) => state.recentlyPlayedSongIds,
    );

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
    const searchInputRef = useRef<HTMLInputElement>(null);
    const [pullDistance, setPullDistance] = useState(0);
    const [isPulling, setIsPulling] = useState(false);
    const touchStartY = useRef<number | null>(null);
    const scrollAncestorRef = useRef<HTMLElement | null>(null);
    const lastVisibilitySyncRef = useRef<number>(0);

    const selectedFolder = useAppStore((state) => state.selectedFolder);

    const searchQuery = useAppStore((state) => state.searchQuery);
    const setSearchQuery = useAppStore((state) => state.setSearchQuery);
    const [showDrawer, setShowDrawer] = useState(false);
    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

    const initRxDbSubscriptions = useAppStore(
        (state) => state.initRxDbSubscriptions,
    );

    const uniqueFolders = useMemo(() => {
        const folders = songs.map((s) => s.folder).filter(Boolean);
        return Array.from(new Set(folders)).sort();
    }, [songs]);

    const getUserInitials = (name?: string) => {
        if (!name) return "U";
        return name
            .split(" ")
            .map((w) => w.charAt(0))
            .join("")
            .toUpperCase()
            .slice(0, 2);
    };

    // Global keyboard shortcuts (Cmd+K / Ctrl+K / '/' for search, Esc to close/clear)
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            const target = e.target as HTMLElement | null;
            const isTyping =
                target?.tagName === "INPUT" ||
                target?.tagName === "TEXTAREA" ||
                target?.isContentEditable;

            if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
                e.preventDefault();
                if (activeSongId) setActiveSongId(null);
                if (isEditing) setIsEditing(false);
                if (activeListContext.type === "service" || activeListContext.type === "circle" || activeListContext.type === "metronome" || activeListContext.type === "settings") {
                    setActiveListContext({ type: "all" });
                }
                setTimeout(() => searchInputRef.current?.focus(), 50);
            } else if (e.key === "/" && !isTyping && !activeSongId && !isEditing && !isPresenting) {
                e.preventDefault();
                searchInputRef.current?.focus();
            } else if (e.key === "Escape") {
                if (showDrawer) setShowDrawer(false);
                else if (isAuthModalOpen) setIsAuthModalOpen(false);
                else if (searchQuery) setSearchQuery("");
            }
        };

        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [
        activeSongId,
        isEditing,
        isPresenting,
        activeListContext.type,
        showDrawer,
        isAuthModalOpen,
        searchQuery,
        setActiveSongId,
        setIsEditing,
        setActiveListContext,
        setSearchQuery,
    ]);

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
            {/* Tablet Sidebar Navigation: Retractable, Direct Folder & Library Access, User Profile Card */}
            {!activeSongId && !isEditing && !isPresenting && (
                <aside
                    className={`hidden md:flex flex-col border-r border-border/80 bg-card select-none transition-all duration-300 relative ${
                        isSidebarCollapsed ? "w-18 p-2.5" : "w-72 p-3.5"
                    }`}
                >
                    {/* Retract / Expand Collapse Button */}
                    <button
                        onClick={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
                        className="absolute -right-3.5 top-6 z-30 w-7 h-7 rounded-full bg-card border border-border/90 shadow-md flex items-center justify-center text-muted-foreground hover:text-foreground hover:scale-105 active:scale-95 transition-all cursor-pointer"
                        title={isSidebarCollapsed ? "Expandir menu lateral" : "Recolher menu lateral"}
                    >
                        {isSidebarCollapsed ? (
                            <ChevronRight className="w-4 h-4" />
                        ) : (
                            <ChevronLeft className="w-4 h-4" />
                        )}
                    </button>

                    {/* Brand Header */}
                    <div className="flex items-center gap-3 px-2 pt-1 pb-3 shrink-0">
                        <img
                            src="/logo.png"
                            className="w-9 h-9 rounded-2xl border border-border/40 shadow-xs object-cover shrink-0"
                            alt="Hosanna"
                        />
                        {!isSidebarCollapsed && (
                            <div className="min-w-0 flex-1">
                                <h1 className="text-base font-black text-primary tracking-tight leading-none">
                                    Hosanna
                                </h1>
                                {organization ? (
                                    <p className="text-[10px] text-muted-foreground font-semibold truncate mt-0.5">
                                        {organization.name}
                                    </p>
                                ) : (
                                    <p className="text-[10px] text-muted-foreground font-semibold">
                                        Música & Cultos
                                    </p>
                                )}
                            </div>
                        )}
                    </div>

                    {/* Main Nav Links */}
                    <div className="flex-1 overflow-y-auto space-y-4 no-scrollbar py-2">
                        <div className="space-y-1">
                            {!isSidebarCollapsed && (
                                <p className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-2.5 mb-1.5">
                                    Principal
                                </p>
                            )}

                            {/* Songs */}
                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "all" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "all"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Todos os Cânticos"
                            >
                                <Music className="w-4 h-4 shrink-0" />
                                {!isSidebarCollapsed && (
                                    <>
                                        <span className="truncate">Todos os Cânticos</span>
                                        <Badge
                                            variant="secondary"
                                            className={`ml-auto text-[10px] px-1.5 py-0.2 rounded font-mono ${
                                                activeListContext.type === "all"
                                                    ? "bg-primary-foreground/20 text-primary-foreground"
                                                    : ""
                                            }`}
                                        >
                                            {songs.length}
                                        </Badge>
                                    </>
                                )}
                            </button>

                            {/* Services */}
                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "service" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "service"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Cultos"
                            >
                                <CalendarRange className="w-4 h-4 shrink-0" />
                                {!isSidebarCollapsed && <span>Cultos</span>}
                            </button>

                            {/* Favorites */}
                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "favorites" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "favorites"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Favoritos"
                            >
                                <Heart className={`w-4 h-4 shrink-0 ${activeListContext.type === "favorites" ? "fill-primary-foreground" : "text-rose-500 fill-rose-500"}`} />
                                {!isSidebarCollapsed && (
                                    <>
                                        <span className="truncate">Favoritos</span>
                                        <Badge
                                            variant="secondary"
                                            className={`ml-auto text-[10px] px-1.5 py-0.2 rounded font-mono ${
                                                activeListContext.type === "favorites"
                                                    ? "bg-primary-foreground/20 text-primary-foreground"
                                                    : ""
                                            }`}
                                        >
                                            {favoriteSongIds.length}
                                        </Badge>
                                    </>
                                )}
                            </button>

                            {/* Recently Played */}
                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "recent" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "recent"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Recentes"
                            >
                                <Clock className={`w-4 h-4 shrink-0 ${activeListContext.type === "recent" ? "text-primary-foreground" : "text-amber-500"}`} />
                                {!isSidebarCollapsed && (
                                    <>
                                        <span className="truncate">Recentes</span>
                                        <Badge
                                            variant="secondary"
                                            className={`ml-auto text-[10px] px-1.5 py-0.2 rounded font-mono ${
                                                activeListContext.type === "recent"
                                                    ? "bg-primary-foreground/20 text-primary-foreground"
                                                    : ""
                                            }`}
                                        >
                                            {recentlyPlayedSongIds.length}
                                        </Badge>
                                    </>
                                )}
                            </button>
                        </div>

                        {/* Folders in Tablet Sidebar */}
                        {!isSidebarCollapsed && uniqueFolders.length > 0 && (
                            <div className="space-y-1 pt-2 border-t border-border/60">
                                <p className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-2.5 mb-1.5">
                                    Pastas
                                </p>
                                {uniqueFolders.map((folder) => {
                                    const count = songs.filter(
                                        (s) => s.folder === folder,
                                    ).length;
                                    const isSelected =
                                        activeListContext.type === "folder" &&
                                        activeListContext.folderName === folder;
                                    return (
                                        <button
                                            key={folder}
                                            onClick={() => {
                                                setActiveListContext({
                                                    type: "folder",
                                                    folderName: folder,
                                                });
                                                setActiveSongId(null);
                                                setIsEditing(false);
                                            }}
                                            className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                                isSelected
                                                    ? "bg-primary/10 text-primary border border-primary/20"
                                                    : "text-foreground hover:bg-accent/60"
                                            }`}
                                        >
                                            <Folder className="w-3.5 h-3.5 text-primary shrink-0" />
                                            <span className="truncate flex-1 text-left">
                                                {folder}
                                            </span>
                                            <Badge
                                                variant="secondary"
                                                className="text-[10px] px-1.5 py-0.2 rounded font-mono"
                                            >
                                                {count}
                                            </Badge>
                                        </button>
                                    );
                                })}
                            </div>
                        )}

                        {/* Tools Navigation */}
                        <div className="space-y-1 pt-2 border-t border-border/60">
                            {!isSidebarCollapsed && (
                                <p className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-2.5 mb-1.5">
                                    Ferramentas
                                </p>
                            )}

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "circle" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "circle"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Círculo da Quinta"
                            >
                                <CircleDot className="w-4 h-4 text-emerald-500 shrink-0" />
                                {!isSidebarCollapsed && <span>Círculo da Quinta</span>}
                            </button>

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "metronome" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "metronome"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Metrónomo"
                            >
                                <Timer className="w-4 h-4 text-sky-500 shrink-0" />
                                {!isSidebarCollapsed && <span>Metrónomo</span>}
                            </button>

                            <button
                                onClick={() => {
                                    setActiveListContext({ type: "settings" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                    activeListContext.type === "settings"
                                        ? "bg-primary text-primary-foreground shadow-xs"
                                        : "text-foreground hover:bg-accent/70 hover:text-accent-foreground"
                                } ${isSidebarCollapsed ? "justify-center px-0" : ""}`}
                                title="Definições"
                            >
                                <Settings className="w-4 h-4 text-slate-400 shrink-0" />
                                {!isSidebarCollapsed && <span>Definições</span>}
                            </button>
                        </div>
                    </div>

                    {/* User Profile Card at the Bottom of Tablet Sidebar */}
                    <div className="pt-3 border-t border-border/80 shrink-0">
                        {isAuthenticated && user ? (
                            <div
                                onClick={() => {
                                    setActiveListContext({ type: "settings" });
                                    setActiveSongId(null);
                                    setIsEditing(false);
                                }}
                                className={`p-2.5 rounded-2xl bg-muted/50 border border-border/60 hover:border-primary/40 flex items-center gap-2.5 transition-all cursor-pointer active:scale-[0.98] ${
                                    isSidebarCollapsed ? "justify-center p-2" : "justify-between"
                                }`}
                                title={user.name}
                            >
                                <div className="flex items-center gap-2.5 min-w-0">
                                    <div className="w-8 h-8 rounded-full bg-linear-to-tr from-sky-600 to-indigo-600 flex items-center justify-center font-black text-white text-xs overflow-hidden shrink-0 shadow-2xs">
                                        {user.image ? (
                                            <img
                                                src={user.image}
                                                alt={user.name}
                                                className="w-full h-full object-cover"
                                            />
                                        ) : (
                                            <span>{getUserInitials(user.name)}</span>
                                        )}
                                    </div>
                                    {!isSidebarCollapsed && (
                                        <div className="min-w-0 flex-1">
                                            <p className="text-xs font-bold text-foreground truncate">
                                                {user.name}
                                            </p>
                                            <p className="text-[10px] text-muted-foreground truncate">
                                                {user.email}
                                            </p>
                                        </div>
                                    )}
                                </div>
                                {!isSidebarCollapsed && (
                                    <div className="shrink-0">
                                        {getRoleBadge(user.role || "member")}
                                    </div>
                                )}
                            </div>
                        ) : (
                            <Button
                                onClick={() => setIsAuthModalOpen(true)}
                                size="sm"
                                className={`w-full text-xs font-bold rounded-xl gap-1.5 ${
                                    isSidebarCollapsed ? "px-0 justify-center" : ""
                                }`}
                                title="Iniciar Sessão"
                            >
                                <LogIn className="w-3.5 h-3.5" />
                                {!isSidebarCollapsed && <span>Entrar</span>}
                            </Button>
                        )}
                    </div>
                </aside>
            )}

            <div className="flex-1 flex flex-col h-full overflow-hidden">
                {/* Top Search / Header Bar */}
                {!activeSongId && !isEditing && !isPresenting && (
                    <header className="px-3.5 sm:px-5 pb-3.5 pt-[calc(0.75rem+env(safe-area-inset-top,0px))] bg-background border-b border-border/80 flex items-center gap-2.5 shrink-0 z-20 relative">
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
                            <div className="relative flex-1 max-w-2xl flex items-center gap-2">
                                <div className="relative flex-1">
                                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                                    <input
                                        ref={searchInputRef}
                                        type="text"
                                        placeholder={
                                            activeListContext.type === "service"
                                                ? "Pesquisar cultos... (Ctrl+K)"
                                                : "Pesquisar título, autor, letra... (Ctrl+K)"
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

                                {(isOfflineAuth || syncStatus === "offline") && (
                                    <button
                                        onClick={() => {
                                            refetchAuth();
                                            syncLibrary({ force: true }).catch(() => {});
                                        }}
                                        className="hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-600 dark:text-amber-400 text-xs font-bold shrink-0 hover:bg-amber-500/20 transition-all cursor-pointer"
                                        title="A funcionar em modo offline com sessão guardada. Clique para tentar reconectar."
                                    >
                                        <WifiOff className="w-3.5 h-3.5" />
                                        <span>Offline</span>
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
                    {/* Pull-to-Refresh Indicator */}
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

                {/* Mobile Floating Bottom Bar */}
                {!activeSongId && !isEditing && !isPresenting && !isOnMenu && (
                    <div className="md:hidden absolute bottom-[calc(1rem+env(safe-area-inset-bottom,0px))] left-1/2 -translate-x-1/2 w-[72%] max-w-60 h-14 bg-card/90 border border-border/80 rounded-full shadow-xl shadow-black/10 px-3 flex items-center justify-around select-none z-40 backdrop-blur-md">
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

            <AuthModal
                isOpen={isAuthModalOpen}
                onClose={() => setIsAuthModalOpen(false)}
            />
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
