import { ChordProRenderer, parseChordPro } from "@hosanna/shared";
import {
    ArrowLeft,
    ChevronLeft,
    ChevronRight,
    ChevronsDown,
    Edit2,
    Eye,
    EyeOff,
    Heart,
    Minus,
    Pause,
    Plus,
    SlidersHorizontal,
    Sun,
    Youtube as YTIcon,
} from "lucide-react";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { useAppStore } from "../store/appStore";

interface SongViewProps {
    songId: string;
    onBack: () => void;
    onEdit: () => void;
    setSong: (id: string) => void;
    serviceMode?: boolean;
}

export default function SongView({
    songId,
    onBack,
    onEdit,
    setSong,
    serviceMode = false,
}: SongViewProps) {
    const songs = useAppStore((state) => state.songs);
    const services = useAppStore((state) => state.services);

    // Persisted state preferences
    const fontSize = useAppStore((state) => state.fontSize);
    const setFontSize = useAppStore((state) => state.setFontSize);
    const showChords = useAppStore((state) => state.showChords);
    const setShowChords = useAppStore((state) => state.setShowChords);
    const showDiagrams = useAppStore((state) => state.showDiagrams);
    const setShowDiagrams = useAppStore((state) => state.setShowDiagrams);
    const keepScreenAwake = useAppStore((state) => state.keepScreenAwake);
    const setKeepScreenAwake = useAppStore((state) => state.setKeepScreenAwake);
    const instrument = useAppStore((state) => state.instrument);
    const setInstrument = useAppStore((state) => state.setInstrument);
    const favoriteSongIds = useAppStore((state) => state.favoriteSongIds);
    const toggleFavoriteSong = useAppStore((state) => state.toggleFavoriteSong);

    // Context & Playlists
    const getActiveSongListIds = useAppStore(
        (state) => state.getActiveSongListIds,
    );
    const activeListContext = useAppStore((state) => state.activeListContext);
    const recentlyPlayedSongIds = useAppStore(
        (state) => state.recentlyPlayedSongIds,
    );
    const sortBy = useAppStore((state) => state.sortBy);

    const activeSongIds = useMemo(() => {
        return getActiveSongListIds();
    }, [
        getActiveSongListIds,
        songs,
        services,
        favoriteSongIds,
        recentlyPlayedSongIds,
        activeListContext,
        sortBy,
    ]);

    const currentIndex = useMemo(
        () => activeSongIds.indexOf(songId),
        [activeSongIds, songId],
    );

    const canSwipePrev = currentIndex > 0;
    const canSwipeNext =
        currentIndex >= 0 && currentIndex < activeSongIds.length - 1;

    // Local states
    const [transposeVal, setTransposeVal] = useState(0);
    const [showControls, setShowControls] = useState(false);
    const [showYoutubePlayer, setShowYoutubePlayer] = useState(false);
    const [isPlayingYoutube, setIsPlayingYoutube] = useState(false);
    const [isScrolling, setIsScrolling] = useState(false);
    const [scrollSpeed, setScrollSpeed] = useState(5); // Auto-scroll speed (1 to 10)
    const [_, setWakeLockActive] = useState(keepScreenAwake);

    const song = useMemo(
        () => songs.find((s) => s.id === songId),
        [songs, songId],
    );

    const ast = useMemo(() => {
        return song ? parseChordPro(song.content) : null;
    }, [song]);

    // High-Perf DOM Refs (prevents re-renders)
    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const contentRef = useRef<HTMLDivElement | null>(null);
    const leftIndicatorRef = useRef<HTMLDivElement | null>(null);
    const rightIndicatorRef = useRef<HTMLDivElement | null>(null);
    const wakeLockRef = useRef<WakeLockSentinel | null>(null);

    // Auto-Scroll Refs
    const scrollRequestRef = useRef<number | null>(null);
    const lastScrollTimeRef = useRef<number | null>(null);
    const exactScrollTopRef = useRef<number>(0);

    // Swipe interaction ref state
    const swipeInfo = useRef({
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0,
        isSwiping: false,
        isLockedVertical: false,
    });

    // Navigation Actions
    const handleNextSong = useCallback(() => {
        if (canSwipeNext) {
            const nextId = activeSongIds[currentIndex + 1];
            useAppStore.getState().addRecentlyPlayedSong(nextId);
            setSong(nextId);
            setTransposeVal(0);
            setShowYoutubePlayer(false);
            setIsPlayingYoutube(false);
        }
    }, [canSwipeNext, activeSongIds, currentIndex, setSong]);

    const handlePrevSong = useCallback(() => {
        if (canSwipePrev) {
            const prevId = activeSongIds[currentIndex - 1];
            useAppStore.getState().addRecentlyPlayedSong(prevId);
            setSong(prevId);
            setTransposeVal(0);
            setShowYoutubePlayer(false);
            setIsPlayingYoutube(false);
        }
    }, [canSwipePrev, activeSongIds, currentIndex, setSong]);

    // Screen Keep-Awake effect
    useEffect(() => {
        let isMounted = true;
        async function requestWakeLock() {
            if (
                !keepScreenAwake ||
                typeof window === "undefined" ||
                !("wakeLock" in navigator)
            )
                return;
            try {
                if (wakeLockRef.current) return;
                const wakeLock = await navigator.wakeLock.request("screen");
                if (isMounted) {
                    wakeLockRef.current = wakeLock;
                    setWakeLockActive(true);
                    wakeLock.addEventListener("release", () => {
                        if (isMounted) setWakeLockActive(false);
                    });
                }
            } catch (err) {
                console.warn("Screen wake lock failed:", err);
            }
        }

        if (keepScreenAwake) {
            requestWakeLock();
        } else if (wakeLockRef.current) {
            wakeLockRef.current.release().catch(() => {});
            wakeLockRef.current = null;
            setWakeLockActive(false);
        }

        const handleVisibility = () => {
            if (document.visibilityState === "visible" && keepScreenAwake)
                requestWakeLock();
        };

        document.addEventListener("visibilitychange", handleVisibility);
        return () => {
            isMounted = false;
            document.removeEventListener("visibilitychange", handleVisibility);
            if (wakeLockRef.current) {
                wakeLockRef.current.release().catch(() => {});
                wakeLockRef.current = null;
            }
        };
    }, [songId, keepScreenAwake]);

    // Simple & High-Performance Auto-Scroll Loop (Capacitor Safe)
    useEffect(() => {
        if (!isScrolling) {
            if (scrollRequestRef.current !== null) {
                cancelAnimationFrame(scrollRequestRef.current);
                scrollRequestRef.current = null;
            }
            lastScrollTimeRef.current = null;
            return;
        }

        const scrollContainer = scrollContainerRef.current;
        if (!scrollContainer) return;

        exactScrollTopRef.current = scrollContainer.scrollTop;

        // Calcula os píxeis a rolar por milissegundo baseado na velocidade (1 a 10)
        // 1 = ~10px por seg, 10 = ~55px por seg
        const basePixelsPerMs = 0.005 + scrollSpeed * 0.005;

        const scrollStep = (timestamp: number) => {
            if (!lastScrollTimeRef.current) {
                lastScrollTimeRef.current = timestamp;
                scrollRequestRef.current = requestAnimationFrame(scrollStep);
                return;
            }

            const elapsed = timestamp - lastScrollTimeRef.current;
            lastScrollTimeRef.current = timestamp;

            const container = scrollContainerRef.current;
            if (!container) return;

            // CAPACITOR FIX: Aumentar tolerância para evitar deteções falsas de scroll manual
            // devido ao "retina scaling" (DPR) nos ecrãs de telemóvel.
            if (
                Math.abs(container.scrollTop - exactScrollTopRef.current) > 15
            ) {
                exactScrollTopRef.current = container.scrollTop;
            }

            const distanceToScroll = basePixelsPerMs * elapsed;

            // Pára se atingirmos o fundo da página
            if (
                container.scrollTop + container.clientHeight >=
                container.scrollHeight - 2
            ) {
                setIsScrolling(false);
                return;
            }

            exactScrollTopRef.current += distanceToScroll;
            container.scrollTop = exactScrollTopRef.current;

            scrollRequestRef.current = requestAnimationFrame(scrollStep);
        };

        scrollRequestRef.current = requestAnimationFrame(scrollStep);

        return () => {
            if (scrollRequestRef.current !== null)
                cancelAnimationFrame(scrollRequestRef.current);
        };
    }, [isScrolling, scrollSpeed]);

    // Reset when changing songs
    useEffect(() => {
        setIsScrolling(false);
        if (scrollContainerRef.current)
            scrollContainerRef.current.scrollTop = 0;
    }, [songId]);

    // High-Perf Swipe Handlers
    const handleTouchStart = useCallback((e: React.TouchEvent) => {
        swipeInfo.current = {
            startX: e.touches[0].clientX,
            startY: e.touches[0].clientY,
            currentX: e.touches[0].clientX,
            currentY: e.touches[0].clientY,
            isSwiping: true,
            isLockedVertical: false,
        };
        if (contentRef.current) {
            contentRef.current.style.transition = "none";
        }
    }, []);

    const handleTouchMove = useCallback(
        (e: React.TouchEvent) => {
            if (!swipeInfo.current.isSwiping) return;

            swipeInfo.current.currentX = e.touches[0].clientX;
            swipeInfo.current.currentY = e.touches[0].clientY;

            let dx = swipeInfo.current.currentX - swipeInfo.current.startX;
            const dy = swipeInfo.current.currentY - swipeInfo.current.startY;

            // Strict lock to avoid triggering swipe while scrolling down
            if (
                !swipeInfo.current.isLockedVertical &&
                Math.abs(dy) > 10 &&
                Math.abs(dy) > Math.abs(dx)
            ) {
                swipeInfo.current.isLockedVertical = true;
            }

            if (swipeInfo.current.isLockedVertical) return;

            // Visual dampening physics
            const resistance = 0.3;

            // Add immense resistance if swiping out of bounds
            if ((dx > 0 && !canSwipePrev) || (dx < 0 && !canSwipeNext)) {
                dx = dx * 0.05;
            }

            if (contentRef.current) {
                contentRef.current.style.transform = `translateX(${dx * resistance}px)`;
            }

            // Handle visual glowing indicators
            if (dx > 20 && canSwipePrev && leftIndicatorRef.current) {
                const intensity = Math.min((dx - 20) / 100, 1);
                leftIndicatorRef.current.style.opacity = intensity.toString();
                leftIndicatorRef.current.style.transform = `scale(${1 + intensity * 0.3})`;
            } else if (dx < -20 && canSwipeNext && rightIndicatorRef.current) {
                const intensity = Math.min((Math.abs(dx) - 20) / 100, 1);
                rightIndicatorRef.current.style.opacity = intensity.toString();
                rightIndicatorRef.current.style.transform = `scale(${1 + intensity * 0.3})`;
            }
        },
        [canSwipePrev, canSwipeNext],
    );

    const handleTouchEnd = useCallback(() => {
        if (!swipeInfo.current.isSwiping) return;
        swipeInfo.current.isSwiping = false;

        const dx = swipeInfo.current.currentX - swipeInfo.current.startX;
        const wasLockedVertical = swipeInfo.current.isLockedVertical;
        swipeInfo.current.isLockedVertical = false;

        // Reset elements with buttery smooth snap-back transition
        if (contentRef.current) {
            contentRef.current.style.transition =
                "transform 0.4s cubic-bezier(0.2, 0.8, 0.2, 1)";
            contentRef.current.style.transform = "translateX(0px)";
        }

        if (leftIndicatorRef.current) {
            leftIndicatorRef.current.style.transition =
                "opacity 0.3s ease, transform 0.3s ease";
            leftIndicatorRef.current.style.opacity = "0";
            leftIndicatorRef.current.style.transform = "scale(1)";
        }

        if (rightIndicatorRef.current) {
            rightIndicatorRef.current.style.transition =
                "opacity 0.3s ease, transform 0.3s ease";
            rightIndicatorRef.current.style.opacity = "0";
            rightIndicatorRef.current.style.transform = "scale(1)";
        }

        if (wasLockedVertical) return;

        const minSwipeThreshold = 75;
        if (dx > minSwipeThreshold && canSwipePrev) {
            handlePrevSong();
        } else if (dx < -minSwipeThreshold && canSwipeNext) {
            handleNextSong();
        }
    }, [canSwipePrev, canSwipeNext, handlePrevSong, handleNextSong]);

    if (!song || !ast) {
        return (
            <div className="p-8 text-center bg-m3-bg dark:bg-m3-dark-bg h-full flex flex-col items-center justify-center">
                <p className="text-sm text-m3-secondary dark:text-m3-dark-secondary">
                    Cântico não encontrado ou foi removido.
                </p>
                <button
                    onClick={onBack}
                    className="mt-4 bg-m3-primary text-white px-5 py-2.5 rounded-2xl text-xs font-bold active:scale-95 transition-all"
                >
                    Voltar para Biblioteca
                </button>
            </div>
        );
    }

    const isFav = favoriteSongIds.includes(song.id);

    return (
        <div
            className="flex-1 flex flex-col h-full bg-m3-bg dark:bg-m3-dark-bg overflow-hidden relative"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
        >
            {/* Top Navbar */}
            <div className="h-16 px-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0 select-none z-40 relative">
                <button
                    onClick={onBack}
                    className="flex items-center gap-1 text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-primary dark:hover:text-m3-dark-primary font-medium transition-colors"
                >
                    <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                    <span className="text-sm">
                        {serviceMode ? "Culto" : "Biblioteca"}
                    </span>
                </button>

                <div className="flex items-center gap-1.5">
                    <button
                        onClick={() => toggleFavoriteSong(song.id)}
                        className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${
                            isFav
                                ? "text-red-500 bg-red-50 dark:bg-red-950/20 border border-red-200/50 dark:border-red-900/40"
                                : "text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/30"
                        }`}
                        title={
                            isFav
                                ? "Remover dos favoritos"
                                : "Adicionar aos favoritos"
                        }
                    >
                        <Heart
                            className={`w-4.5 h-4.5 ${isFav ? "fill-current" : ""}`}
                        />
                    </button>

                    {!serviceMode && (
                        <button
                            onClick={onEdit}
                            className="p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors text-m3-secondary dark:text-m3-dark-secondary"
                            title="Editar Cântico"
                        >
                            <Edit2 className="w-4.5 h-4.5 text-m3-primary dark:text-m3-dark-primary" />
                        </button>
                    )}

                    <button
                        onClick={() => setShowControls(!showControls)}
                        className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${showControls ? "bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text border border-m3-border/30" : "text-m3-secondary dark:text-m3-dark-secondary"}`}
                        title="Ajustar Tom e Tamanho"
                    >
                        <SlidersHorizontal className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                    </button>
                </div>
            </div>

            {/* Non-modal controls popover */}
            {showControls && (
                <div className="absolute right-4 top-16 w-64 bg-m3-card/95 dark:bg-m3-dark-card/95 backdrop-blur-xl border border-m3-border dark:border-m3-dark-border rounded-2xl shadow-xl z-50 p-4 space-y-4 select-none animate-in fade-in slide-in-from-top-1 duration-200">
                    <div className="border-b border-m3-border/30 dark:border-m3-dark-border/30 pb-2 flex items-center justify-between">
                        <span className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider">
                            Ajustes de Leitura
                        </span>
                        <button
                            onClick={() => setShowControls(false)}
                            className="text-[10px] font-bold text-m3-primary dark:text-m3-dark-primary hover:underline"
                        >
                            Fechar
                        </button>
                    </div>

                    <div className="space-y-2">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">
                            Exibição:
                        </span>
                        <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                            <button
                                onClick={() => setShowChords(false)}
                                className={`flex-1 py-1.5 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                                    !showChords
                                        ? "bg-m3-primary text-white shadow-xs"
                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                }`}
                            >
                                <EyeOff className="w-3 h-3" /> Apenas Letra
                            </button>
                            <button
                                onClick={() => setShowChords(true)}
                                className={`flex-1 py-1.5 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                                    showChords
                                        ? "bg-m3-primary text-white shadow-xs"
                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                }`}
                            >
                                <Eye className="w-3.5 h-3.5" /> Com Cifras
                            </button>
                        </div>
                    </div>

                    {showChords && (
                        <div className="space-y-1.5 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                            <div className="flex items-center justify-between">
                                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                                    Transposição:
                                </span>
                                <span className="text-[11px] font-bold px-2 py-0.5 bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text rounded font-mono">
                                    {transposeVal > 0
                                        ? `+${transposeVal}`
                                        : transposeVal}{" "}
                                    st
                                </span>
                            </div>
                            <div className="grid grid-cols-3 gap-1 bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                                <button
                                    onClick={() =>
                                        setTransposeVal((p) =>
                                            p - 1 < -12 ? 11 : p - 1,
                                        )
                                    }
                                    className="py-1 text-xs font-bold rounded-lg transition-all text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center gap-0.5"
                                >
                                    <Minus className="w-3 h-3" />
                                    <span>♭</span>
                                </button>
                                <button
                                    onClick={() => setTransposeVal(0)}
                                    className={`py-1 text-[10px] font-bold rounded-lg transition-all ${
                                        transposeVal === 0
                                            ? "bg-m3-primary text-white shadow-xs"
                                            : "text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover"
                                    }`}
                                >
                                    Original
                                </button>
                                <button
                                    onClick={() =>
                                        setTransposeVal((p) =>
                                            p + 1 > 11 ? -12 : p + 1,
                                        )
                                    }
                                    className="py-1 text-xs font-bold rounded-lg transition-all text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center gap-0.5"
                                >
                                    <span>#</span>
                                    <Plus className="w-3 h-3" />
                                </button>
                            </div>
                        </div>
                    )}

                    {showChords && (
                        <div className="space-y-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                            <div className="space-y-1.5">
                                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">
                                    Diagramas / Instrumento:
                                </span>
                                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30 gap-1 mb-1">
                                    <button
                                        onClick={() => setShowDiagrams(false)}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${!showDiagrams ? "bg-m3-primary text-white" : "text-m3-secondary hover:text-m3-text"}`}
                                    >
                                        Ocultar
                                    </button>
                                    <button
                                        onClick={() => setShowDiagrams(true)}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${showDiagrams ? "bg-m3-primary text-white" : "text-m3-secondary hover:text-m3-text"}`}
                                    >
                                        Mostrar
                                    </button>
                                </div>
                                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30 gap-1">
                                    <button
                                        onClick={() => setInstrument("guitar")}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${instrument === "guitar" ? "bg-m3-primary text-white" : "text-m3-secondary hover:text-m3-text"}`}
                                    >
                                        Guitarra
                                    </button>
                                    <button
                                        onClick={() => setInstrument("piano")}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${instrument === "piano" ? "bg-m3-primary text-white" : "text-m3-secondary hover:text-m3-text"}`}
                                    >
                                        Piano
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}

                    <div className="flex items-center justify-between border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                            Tamanho da Letra:
                        </span>
                        <div className="flex items-center gap-1.5">
                            <button
                                onClick={() =>
                                    setFontSize(Math.max(10, fontSize - 1))
                                }
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
                            >
                                <Minus className="w-3.5 h-3.5" />
                            </button>
                            <span className="text-[10px] font-mono font-black text-m3-text dark:text-m3-dark-text min-w-6 text-center">
                                {fontSize}px
                            </span>
                            <button
                                onClick={() =>
                                    setFontSize(Math.min(28, fontSize + 1))
                                }
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
                            >
                                <Plus className="w-3.5 h-3.5" />
                            </button>
                        </div>
                    </div>

                    <div className="flex items-center justify-between border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                            Velocidade do Scroll:
                        </span>
                        <div className="flex items-center gap-1.5">
                            <button
                                onClick={() =>
                                    setScrollSpeed(Math.max(1, scrollSpeed - 1))
                                }
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
                            >
                                <Minus className="w-3.5 h-3.5" />
                            </button>
                            <span className="text-[10px] font-mono font-black text-m3-text dark:text-m3-dark-text min-w-6 text-center">
                                {scrollSpeed}
                            </span>
                            <button
                                onClick={() =>
                                    setScrollSpeed(
                                        Math.min(10, scrollSpeed + 1),
                                    )
                                }
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
                            >
                                <Plus className="w-3.5 h-3.5" />
                            </button>
                        </div>
                    </div>

                    <div className="flex items-center justify-between border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary flex items-center gap-1">
                            <Sun className="w-3.5 h-3.5" /> Ecrã Sempre Ativo:
                        </span>
                        <button
                            onClick={() => setKeepScreenAwake(!keepScreenAwake)}
                            className={`w-9 h-5 rounded-full p-0.5 transition-colors relative flex items-center ${keepScreenAwake ? "bg-m3-primary" : "bg-neutral-200 dark:bg-zinc-800"}`}
                        >
                            <div
                                className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform transform ${keepScreenAwake ? "translate-x-4" : "translate-x-0"}`}
                            />
                        </button>
                    </div>
                </div>
            )}

            {/* Glowing Swipe Indicators */}
            <div
                ref={leftIndicatorRef}
                className="absolute left-0 inset-y-0 w-24 bg-gradient-to-r from-m3-primary/20 to-transparent flex items-center justify-start pl-4 opacity-0 pointer-events-none z-30 transition-opacity"
            >
                <ChevronLeft className="w-10 h-10 text-m3-primary dark:text-m3-dark-primary drop-shadow-md" />
            </div>

            <div
                ref={rightIndicatorRef}
                className="absolute right-0 inset-y-0 w-24 bg-gradient-to-l from-m3-primary/20 to-transparent flex items-center justify-end pr-4 opacity-0 pointer-events-none z-30 transition-opacity"
            >
                <ChevronRight className="w-10 h-10 text-m3-primary dark:text-m3-dark-primary drop-shadow-md" />
            </div>

            {/* Scrollable Main View Engine (Capacitor Safe: min-h-0 + absolute boundary & no scroll-smooth!) */}
            <div className="flex-1 w-full relative min-h-0 overflow-hidden">
                <div
                    ref={scrollContainerRef}
                    className="absolute inset-0 w-full h-full overflow-y-auto overflow-x-hidden will-change-scroll"
                    style={{ WebkitOverflowScrolling: "touch" }}
                >
                    <div
                        ref={contentRef}
                        className="min-h-full w-full pb-36 will-change-transform"
                    >
                        <ChordProRenderer
                            content={song.content}
                            showChords={showChords}
                            transposeVal={transposeVal}
                            fontSize={fontSize}
                            instrument={instrument}
                            showDiagrams={showDiagrams}
                            fileName={song.fileName}
                            showYoutubePlayer={isPlayingYoutube}
                            onTransposeChange={setTransposeVal}
                        />
                    </div>
                </div>
            </div>

            {/* Floating Navigation Controls */}
            <div
                className={`absolute right-5 flex flex-col items-end gap-3 select-none shrink-0 z-40 transition-all duration-300 pointer-events-none ${showYoutubePlayer ? "bottom-20" : "bottom-5"}`}
            >
                <div className="pointer-events-auto">
                    <button
                        onClick={() => setIsScrolling(!isScrolling)}
                        className={`p-3.5 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4 ${
                            isScrolling
                                ? "bg-neutral-800 dark:bg-zinc-100 text-white dark:text-neutral-900 border-neutral-700 dark:border-zinc-300 shadow-m3-primary/20"
                                : "bg-m3-primary dark:bg-m3-dark-primary text-white border-m3-primary-light dark:border-m3-dark-primary-light hover:opacity-90"
                        }`}
                        title={
                            isScrolling
                                ? "Pausar Rolar Automático"
                                : "Iniciar Rolar Automático"
                        }
                    >
                        {isScrolling ? (
                            <Pause className="w-5 h-5" />
                        ) : (
                            <ChevronsDown className="w-5 h-5" />
                        )}
                    </button>
                </div>

                {ast.metadata.youtube && (
                    <div className="pointer-events-auto">
                        <button
                            onClick={() => {
                                setShowYoutubePlayer((prev) => !prev);
                                setIsPlayingYoutube(!showYoutubePlayer);
                            }}
                            className="p-3.5 rounded-full shadow-lg border border-red-500 bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/60 transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4"
                            title="Ouvir Áudio no YouTube"
                        >
                            <YTIcon className="w-5 h-5" />
                        </button>
                    </div>
                )}

                <div className="flex items-center gap-2 pointer-events-auto">
                    <button
                        onClick={handlePrevSong}
                        disabled={!canSwipePrev}
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                            canSwipePrev
                                ? "bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                : "bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed"
                        }`}
                    >
                        <ChevronLeft className="w-5 h-5" />
                    </button>

                    <span className="bg-m3-card/90 dark:bg-m3-dark-card/90 border border-m3-border dark:border-m3-dark-border backdrop-blur-md text-[10px] font-bold font-mono px-3 py-2 rounded-full text-m3-secondary dark:text-m3-dark-secondary">
                        {currentIndex !== -1
                            ? `${currentIndex + 1} / ${activeSongIds.length}`
                            : "Solo"}
                    </span>

                    <button
                        onClick={handleNextSong}
                        disabled={!canSwipeNext}
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                            canSwipeNext
                                ? "bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                : "bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed"
                        }`}
                    >
                        <ChevronRight className="w-5 h-5" />
                    </button>
                </div>
            </div>
        </div>
    );
}
