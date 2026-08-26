import { AnimatePresence, motion } from "framer-motion";
import {
    CircleDot,
    Clock,
    Folder,
    Heart,
    LogIn,
    LogOut,
    Music,
    Settings,
    Timer,
    WifiOff,
    X,
} from "lucide-react";
import { useMemo, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { AppState, useAppStore } from "../store/appStore";
import { AuthModal } from "./auth/AuthModal";
import { getRoleBadge } from "./settings/settingsUtils";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";

export default function NavigationDrawer({
    show,
    onClose,
}: {
    show: boolean;
    onClose: () => void;
}) {
    const songs = useAppStore((state) => state.songs);
    const favoriteSongIds = useAppStore((state) => state.favoriteSongIds);
    const recentlyPlayedSongIds = useAppStore(
        (state) => state.recentlyPlayedSongIds,
    );
    const activeListContext = useAppStore((state) => state.activeListContext);
    const setActiveListContext = useAppStore(
        (state) => state.setActiveListContext,
    );
    const setActiveSongId = useAppStore((state) => state.setActiveSongId);
    const setIsEditing = useAppStore((state) => state.setIsEditing);

    const { user, organization, isAuthenticated, isOfflineAuth, logout } =
        useAuth();
    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);

    const uniqueFolders = useMemo(() => {
        const folders = songs.map((s) => s.folder).filter(Boolean);
        return Array.from(new Set(folders)).sort();
    }, [songs]);

    const selectedSection = activeListContext.type;
    const selectedFolder = activeListContext.folderName;

    const navigateTo = (
        type: AppState["activeListContext"]["type"],
        folderName?: string,
    ) => {
        setActiveListContext({
            type: type,
            folderName,
        });
        setActiveSongId(null);
        setIsEditing(false);
        onClose();
    };

    const getUserInitials = (name?: string) => {
        if (!name) return "U";
        return name
            .split(" ")
            .map((w) => w.charAt(0))
            .join("")
            .toUpperCase()
            .slice(0, 2);
    };

    return (
        <>
            <AnimatePresence>
                {show && (
                    <>
                        {/* Backdrop with native blur */}
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.2 }}
                            onClick={onClose}
                            className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 cursor-pointer"
                        />
                        {/* Drawer container with responsive width */}
                        <motion.div
                            initial={{ x: "-100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "-100%" }}
                            transition={{
                                type: "spring",
                                damping: 28,
                                stiffness: 280,
                            }}
                            className="fixed left-0 top-0 bottom-0 w-[300px] sm:w-80 max-w-[85vw] bg-card border-r border-border shadow-2xl z-50 flex flex-col overflow-hidden"
                        >
                            {/* Drawer Header with User Profile / Login CTA */}
                            <div className="pt-[calc(1rem+env(safe-area-inset-top,0px))] px-4 pb-4 border-b border-border bg-muted/40 space-y-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-2.5">
                                        <img
                                            src="/logo.png"
                                            className="w-8 h-8 rounded-xl border border-border/40 shadow-xs object-cover"
                                            alt="Hosanna"
                                        />
                                        <div>
                                            <h2 className="text-sm font-black text-primary tracking-tight leading-none">
                                                Hosanna
                                            </h2>
                                            {organization && (
                                                <p className="text-[10px] text-muted-foreground font-semibold mt-0.5 truncate max-w-40">
                                                    {organization.name}
                                                </p>
                                            )}
                                        </div>
                                    </div>
                                    <Button
                                        variant="ghost"
                                        size="icon-sm"
                                        onClick={onClose}
                                        className="rounded-full text-muted-foreground hover:text-foreground"
                                    >
                                        <X className="w-4 h-4" />
                                    </Button>
                                </div>

                                {/* User card in Header */}
                                {isAuthenticated && user ? (
                                    <div
                                        onClick={() => navigateTo("settings")}
                                        className="p-2.5 bg-background rounded-2xl border border-border/80 flex items-center justify-between gap-2.5 hover:border-primary/50 transition-all cursor-pointer shadow-xs active:scale-[0.98]"
                                    >
                                        <div className="flex items-center gap-2.5 min-w-0 flex-1">
                                            <div className="w-9 h-9 rounded-full bg-linear-to-tr from-sky-600 to-indigo-600 flex items-center justify-center font-black text-white text-xs overflow-hidden shrink-0 shadow-xs">
                                                {user.image ? (
                                                    <img
                                                        src={user.image}
                                                        alt={user.name}
                                                        className="w-full h-full object-cover"
                                                    />
                                                ) : (
                                                    <span>
                                                        {getUserInitials(
                                                            user.name,
                                                        )}
                                                    </span>
                                                )}
                                            </div>
                                            <div className="min-w-0 flex-1">
                                                <p className="text-xs font-bold text-foreground truncate">
                                                    {user.name}
                                                </p>
                                                <p className="text-[10px] text-muted-foreground truncate">
                                                    {user.email}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="shrink-0 flex items-center gap-1.5">
                                            {isOfflineAuth && (
                                                <span className="flex items-center gap-1 text-[9px] font-bold bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/30 px-1.5 py-0.5 rounded-md">
                                                    <WifiOff className="w-2.5 h-2.5" />
                                                    Offline
                                                </span>
                                            )}
                                            {getRoleBadge(
                                                user.role || "member",
                                            )}
                                        </div>
                                    </div>
                                ) : (
                                    <Button
                                        onClick={() => {
                                            onClose();
                                            setIsAuthModalOpen(true);
                                        }}
                                        className="w-full py-2 h-9 text-xs font-bold rounded-xl shadow-xs gap-1.5"
                                    >
                                        <LogIn className="w-3.5 h-3.5" />
                                        Iniciar Sessão / Registar
                                    </Button>
                                )}
                            </div>

                            {/* Drawer Content */}
                            <div className="flex-1 overflow-y-auto py-3 px-3 space-y-1 no-scrollbar">
                                <div className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-3 mb-1.5">
                                    Biblioteca
                                </div>

                                {/* All Songs Button */}
                                <button
                                    onClick={() => navigateTo("all")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "all"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <Music className="w-4 h-4 text-primary shrink-0" />
                                    <span>Todos os Cânticos</span>
                                    <Badge
                                        variant="secondary"
                                        className="ml-auto text-[10px] px-2 py-0.5 rounded-md font-mono"
                                    >
                                        {songs.length}
                                    </Badge>
                                </button>

                                {/* Favorites Button */}
                                <button
                                    onClick={() => navigateTo("favorites")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "favorites"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <Heart className="w-4 h-4 text-rose-500 fill-current shrink-0" />
                                    <span>Favoritos</span>
                                    <Badge
                                        variant="secondary"
                                        className="ml-auto text-[10px] px-2 py-0.5 rounded-md font-mono"
                                    >
                                        {favoriteSongIds.length}
                                    </Badge>
                                </button>

                                {/* Recently Played Button */}
                                <button
                                    onClick={() => navigateTo("recent")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "recent"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <Clock className="w-4 h-4 text-amber-500 shrink-0" />
                                    <span>Recentes (Histórico)</span>
                                    <Badge
                                        variant="secondary"
                                        className="ml-auto text-[10px] px-2 py-0.5 rounded-md font-mono"
                                    >
                                        {recentlyPlayedSongIds.length}
                                    </Badge>
                                </button>

                                <div className="h-px bg-border/60 my-3" />

                                <div className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-3 mb-1.5">
                                    Ferramentas
                                </div>

                                <button
                                    onClick={() => navigateTo("circle")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "circle"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <CircleDot className="w-4 h-4 text-emerald-500 shrink-0" />
                                    <span>Círculo da Quinta</span>
                                </button>

                                <button
                                    onClick={() => navigateTo("metronome")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "metronome"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <Timer className="w-4 h-4 text-sky-500 shrink-0" />
                                    <span>Metrónomo</span>
                                </button>

                                <button
                                    onClick={() => navigateTo("settings")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                        selectedSection === "settings"
                                            ? "bg-primary/10 text-primary border border-primary/20"
                                            : "text-foreground hover:bg-accent/60"
                                    }`}
                                >
                                    <Settings className="w-4 h-4 text-slate-400 shrink-0" />
                                    <span>Definições & Servidor</span>
                                </button>

                                <div className="h-px bg-border/60 my-3" />

                                <div className="text-[10px] font-black text-muted-foreground uppercase tracking-wider px-3 mb-1.5">
                                    Pastas & Categorias
                                </div>

                                {uniqueFolders.length === 0 ? (
                                    <p className="text-[11px] text-muted-foreground px-3 italic">
                                        Nenhuma pasta encontrada.
                                    </p>
                                ) : (
                                    uniqueFolders.map((folder) => {
                                        const count = songs.filter(
                                            (s) => s.folder === folder,
                                        ).length;
                                        const isSelected =
                                            selectedSection === "folder" &&
                                            selectedFolder === folder;
                                        return (
                                            <button
                                                key={folder}
                                                onClick={() =>
                                                    navigateTo("folder", folder)
                                                }
                                                className={`w-full flex items-center gap-3 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer active:scale-[0.98] ${
                                                    isSelected
                                                        ? "bg-primary/10 text-primary border border-primary/20"
                                                        : "text-foreground hover:bg-accent/60"
                                                }`}
                                            >
                                                <Folder className="w-4 h-4 text-primary shrink-0" />
                                                <span className="truncate">
                                                    {folder}
                                                </span>
                                                <Badge
                                                    variant="secondary"
                                                    className="ml-auto text-[10px] px-1.5 py-0.5 rounded font-mono"
                                                >
                                                    {count}
                                                </Badge>
                                            </button>
                                        );
                                    })
                                )}
                            </div>

                            {/* Drawer Footer */}
                            {isAuthenticated && (
                                <div className="p-3 border-t border-border bg-muted/40 pb-[calc(0.75rem+env(safe-area-inset-bottom,0px))]">
                                    <Button
                                        variant="outline"
                                        onClick={() => {
                                            logout();
                                            onClose();
                                        }}
                                        className="w-full text-xs font-bold text-destructive hover:bg-destructive/10 hover:text-destructive border-destructive/30"
                                    >
                                        <LogOut className="w-3.5 h-3.5" />
                                        Terminar Sessão
                                    </Button>
                                </div>
                            )}
                        </motion.div>
                    </>
                )}
            </AnimatePresence>

            <AuthModal
                isOpen={isAuthModalOpen}
                onClose={() => setIsAuthModalOpen(false)}
            />
        </>
    );
}
