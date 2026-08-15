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
    X,
} from "lucide-react";
import { useMemo, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { AppState, useAppStore } from "../store/appStore";
import { AuthModal } from "./auth/AuthModal";
import { getRoleBadge } from "./settings/settingsUtils";

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

    const { user, organization, isAuthenticated, logout } = useAuth();
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
                        {/* Backdrop */}
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 0.4 }}
                            exit={{ opacity: 0 }}
                            onClick={onClose}
                            className="fixed inset-0 bg-black z-40 cursor-pointer"
                        />
                        {/* Drawer container */}
                        <motion.div
                            initial={{ x: "-100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "-100%" }}
                            transition={{
                                type: "spring",
                                damping: 25,
                                stiffness: 220,
                            }}
                            className="fixed left-0 top-0 bottom-0 w-80 max-w-[85vw] bg-m3-card dark:bg-m3-dark-card border-r border-m3-border dark:border-m3-dark-border shadow-2xl z-50 flex flex-col overflow-hidden"
                        >
                            {/* Drawer Header with User Profile / Login CTA */}
                            <div className="p-4 border-b border-m3-border/30 dark:border-m3-dark-border/30 bg-m3-sidebar dark:bg-m3-dark-sidebar space-y-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-2.5">
                                        <img
                                            src="/logo.png"
                                            className="w-8 h-8 rounded-xl border border-m3-border/20 shadow-xs object-cover"
                                            alt="Hosanna"
                                        />
                                        <div>
                                            <h2 className="text-sm font-black text-m3-primary dark:text-m3-dark-primary tracking-tight leading-none">
                                                Hosanna
                                            </h2>
                                            {organization && (
                                                <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold mt-0.5 truncate max-w-40">
                                                    {organization.name}
                                                </p>
                                            )}
                                        </div>
                                    </div>
                                    <button
                                        onClick={onClose}
                                        className="p-1.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary"
                                    >
                                        <X className="w-4 h-4" />
                                    </button>
                                </div>

                                {/* User card in Header */}
                                {isAuthenticated && user ? (
                                    <div
                                        onClick={() => navigateTo("settings")}
                                        className="p-2.5 bg-m3-card dark:bg-m3-dark-card rounded-xl border border-m3-border/30 flex items-center justify-between gap-2.5 hover:border-m3-primary/50 transition-colors cursor-pointer"
                                    >
                                        <div className="flex items-center gap-2.5 min-w-0 flex-1">
                                            <div className="w-9 h-9 rounded-full bg-linear-to-tr from-sky-600 to-indigo-600 flex items-center justify-center font-black text-white text-xs overflow-hidden shrink-0">
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
                                                <p className="text-xs font-bold text-m3-text dark:text-m3-dark-text truncate">
                                                    {user.name}
                                                </p>
                                                <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary truncate">
                                                    {user.email}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="shrink-0">
                                            {getRoleBadge(
                                                user.role || "member",
                                            )}
                                        </div>
                                    </div>
                                ) : (
                                    <button
                                        onClick={() => {
                                            onClose();
                                            setIsAuthModalOpen(true);
                                        }}
                                        className="w-full py-2 px-3 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-xl shadow-xs transition-all flex items-center justify-center gap-1.5"
                                    >
                                        <LogIn className="w-3.5 h-3.5" />
                                        Iniciar Sessão / Registar
                                    </button>
                                )}
                            </div>

                            {/* Drawer Content */}
                            <div className="flex-1 overflow-y-auto py-3 px-3 space-y-1 no-scrollbar">
                                <div className="text-[9px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1">
                                    Biblioteca
                                </div>

                                {/* All Songs Button */}
                                <button
                                    onClick={() => navigateTo("all")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "all"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <Music className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                                    <span>Todos os Cânticos</span>
                                    <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">
                                        {songs.length}
                                    </span>
                                </button>

                                {/* Favorites Button */}
                                <button
                                    onClick={() => navigateTo("favorites")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "favorites"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <Heart className="w-4 h-4 text-red-500 fill-current" />
                                    <span>Favoritos</span>
                                    <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">
                                        {favoriteSongIds.length}
                                    </span>
                                </button>

                                {/* Recently Played Button */}
                                <button
                                    onClick={() => navigateTo("recent")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "recent"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <Clock className="w-4 h-4 text-amber-500" />
                                    <span>Recentes (Histórico)</span>
                                    <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">
                                        {recentlyPlayedSongIds.length}
                                    </span>
                                </button>

                                <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-3" />

                                <div className="text-[9px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1">
                                    Ferramentas
                                </div>

                                <button
                                    onClick={() => navigateTo("circle")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "circle"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <CircleDot className="w-4 h-4 text-emerald-500" />
                                    <span>Círculo da Quinta</span>
                                </button>

                                <button
                                    onClick={() => navigateTo("metronome")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "metronome"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <Timer className="w-4 h-4 text-blue-500" />
                                    <span>Metrónomo</span>
                                </button>

                                <button
                                    onClick={() => navigateTo("settings")}
                                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
                                        selectedSection === "settings"
                                            ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                            : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    <Settings className="w-4 h-4 text-slate-500" />
                                    <span>Definições da Conta & App</span>
                                </button>

                                <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-3" />

                                <div className="text-[9px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1">
                                    Pastas & Categorias
                                </div>

                                {uniqueFolders.length === 0 ? (
                                    <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary px-3 italic">
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
                                                className={`w-full flex items-center gap-3 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                                                    isSelected
                                                        ? "bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30"
                                                        : "text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                                }`}
                                            >
                                                <Folder className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                                                <span className="truncate">
                                                    {folder}
                                                </span>
                                                <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-1.5 py-0.5 rounded border border-m3-border/20">
                                                    {count}
                                                </span>
                                            </button>
                                        );
                                    })
                                )}
                            </div>

                            {/* Drawer Footer */}
                            {isAuthenticated && (
                                <div className="p-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 bg-m3-sidebar dark:bg-m3-dark-sidebar">
                                    <button
                                        onClick={() => {
                                            logout();
                                            onClose();
                                        }}
                                        className="w-full py-2 px-3 text-xs font-bold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/30 rounded-xl transition-colors flex items-center justify-center gap-2 border border-red-200 dark:border-red-900/40"
                                    >
                                        <LogOut className="w-3.5 h-3.5" />
                                        Terminar Sessão
                                    </button>
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
