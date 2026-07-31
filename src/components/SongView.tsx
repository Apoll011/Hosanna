import { ChordProRenderer, parseChordPro } from "@hosanna/shared";
import {
    ArrowLeft,
    BookOpen,
    ChevronLeft,
    ChevronRight,
    ChevronsDown,
    Edit2,
    Eye,
    EyeOff,
    Heart,
    HelpCircle,
    Minus,
    Pause,
    Plus,
    SlidersHorizontal,
    Sun,
    X,
    Youtube as YTIcon,
} from "lucide-react";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { chordDictionary } from "../lib/chordDictionary";
import { SectionAST } from "../lib/chordpro";
import { useAppStore } from "../store/appStore";
import { GuitarDiagram, PianoDiagram } from "./ChordRoll";

const hasRepeatInText = (text?: string): boolean => {
    if (!text) return false;
    const lower = text.toLowerCase();
    return (
        lower.includes("bis") ||
        lower.includes("2x") ||
        lower.includes("3x") ||
        lower.includes("x2") ||
        lower.includes("x3") ||
        lower.includes("repetir") ||
        lower.includes("repete") ||
        lower.includes("refrão") ||
        lower.includes("chorus") ||
        lower.includes("coro")
    );
};

const isSectionRepeated = (section: SectionAST): boolean => {
    if (section.type === "chorus") return true;
    if (section.label && hasRepeatInText(section.label)) return true;
    for (const line of section.lines) {
        if (line.text && hasRepeatInText(line.text)) return true;
        if (line.segments) {
            for (const seg of line.segments) {
                if (seg.text && hasRepeatInText(seg.text)) return true;
            }
        }
    }
    return false;
};

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

    // Persisted state preferences from store
    const fontSize = useAppStore((state) => state.fontSize);
    const setFontSize = useAppStore((state) => state.setFontSize);
    const showChords = useAppStore((state) => state.showChords);
    const setShowChords = useAppStore((state) => state.setShowChords);
    const showDiagrams = useAppStore((state) => state.showDiagrams);
    const setShowDiagrams = useAppStore((state) => state.setShowDiagrams);
    const keepScreenAwake = useAppStore((state) => state.keepScreenAwake);
    const setKeepScreenAwake = useAppStore((state) => state.setKeepScreenAwake);
    const slowDownOnRepeat = useAppStore((state) => state.slowDownOnRepeat);
    const instrument = useAppStore((state) => state.instrument);
    const setInstrument = useAppStore((state) => state.setInstrument);
    const favoriteSongIds = useAppStore((state) => state.favoriteSongIds);
    const toggleFavoriteSong = useAppStore((state) => state.toggleFavoriteSong);

    // Swipe logic & active song lists
    const getActiveSongListIds = useAppStore(
        (state) => state.getActiveSongListIds,
    );
    const activeListContext = useAppStore((state) => state.activeListContext);
    const recentlyPlayedSongIds = useAppStore(
        (state) => state.recentlyPlayedSongIds,
    );
    const sortBy = useAppStore((state) => state.sortBy);

    // Memoize the song list IDs to prevent infinite loops (by caching the result array)
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

    // Touch state for swiping
    const [touchStart, setTouchStart] = useState<number | null>(null);
    const [touchEnd, setTouchEnd] = useState<number | null>(null);

    // Local overrides (transpose isn't persisted long-term to raw file)
    const [transposeVal, setTransposeVal] = useState(0);
    const [showControls, setShowControls] = useState(false);
    const [selectedChord, setSelectedChord] = useState<string | null>(null);

    // YouTube Audio Player states
    const [showYoutubePlayer, setShowYoutubePlayer] = useState(false);
    const [isPlayingYoutube, setIsPlayingYoutube] = useState(false);

    const song = useMemo(
        () => songs.find((s) => s.id === songId),
        [songs, songId],
    );

    if (!song) {
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

    // Parse raw ChordPro text on-the-fly
    const ast = useMemo(() => {
        return parseChordPro(song.content);
    }, [song.content]);

    // Screen Keep-Awake states
    const [_, setWakeLockActive] = useState(keepScreenAwake);
    const wakeLockRef = useRef<WakeLockSentinel | null>(null);

    // Auto-scroll states
    const [isScrolling, setIsScrolling] = useState(false);
    const [_activeSectionIndex, setActiveSectionIndex] = useState<
        number | null
    >(null);
    const [_isSlowedDown, setIsSlowedDown] = useState(false);

    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const scrollRequestRef = useRef<number | null>(null);
    const lastScrollTimeRef = useRef<number | null>(null);
    const exactScrollTopRef = useRef<number>(0);

    // Keep-Awake effect
    useEffect(() => {
        let isMounted = true;
        async function requestWakeLock() {
            if (!keepScreenAwake) return;
            if (
                typeof window === "undefined" ||
                !window.navigator ||
                !("wakeLock" in window.navigator)
            ) {
                return;
            }
            try {
                if (wakeLockRef.current) return;
                const wakeLock =
                    await window.navigator.wakeLock.request("screen");
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
            if (document.visibilityState === "visible" && keepScreenAwake) {
                requestWakeLock();
            }
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

    // Auto-Scroll Tick Loop
    useEffect(() => {
        if (!isScrolling) {
            if (scrollRequestRef.current !== null) {
                cancelAnimationFrame(scrollRequestRef.current);
                scrollRequestRef.current = null;
            }
            lastScrollTimeRef.current = null;
            setIsSlowedDown(false);
            return;
        }

        const scrollContainer = scrollContainerRef.current;
        if (!scrollContainer) return;

        // Synchronize exact accumulator with actual scroll in case user manually scrolled
        exactScrollTopRef.current = scrollContainer.scrollTop;

        // Tempo multiplier from metadata (BPM)
        const tempo = ast.metadata.tempo
            ? parseInt(ast.metadata.tempo, 10)
            : 80;
        const tempoFactor = tempo / 100;
        // Map speed to pixels-per-ms, scaled by the song tempo
        const basePixelsPerMs = 0.015 * tempoFactor;

        const scrollStep = (timestamp: number) => {
            if (!lastScrollTimeRef.current) {
                lastScrollTimeRef.current = timestamp;
                scrollRequestRef.current = requestAnimationFrame(scrollStep);
                return;
            }

            const elapsed = timestamp - lastScrollTimeRef.current;
            lastScrollTimeRef.current = timestamp;

            const container = scrollContainerRef.current;
            let activeIndex = null;
            let isRepeatSectionActive = false;

            if (container) {
                const sectionElems = container.querySelectorAll(
                    "[data-section-index]",
                );
                const containerRect = container.getBoundingClientRect();
                // Focus area is in the upper third of the viewport (which is where performers read)
                const focusY = containerRect.top + containerRect.height / 3;

                for (let i = 0; i < sectionElems.length; i++) {
                    const elem = sectionElems[i];
                    const rect = elem.getBoundingClientRect();
                    if (rect.top <= focusY && rect.bottom >= focusY) {
                        activeIndex = parseInt(
                            elem.getAttribute("data-section-index") || "0",
                            10,
                        );
                        break;
                    }
                }

                if (activeIndex !== null) {
                    setActiveSectionIndex(activeIndex);
                    const currentSection = ast.sections[activeIndex];
                    if (currentSection) {
                        isRepeatSectionActive = isSectionRepeated(
                            currentSection as any,
                        );
                    }
                }
            }

            let speedMultiplier = 1.0;
            if (slowDownOnRepeat && isRepeatSectionActive) {
                // Slow down to 35% of selected speed for repeated sections / chorus
                speedMultiplier = 0.35;
                setIsSlowedDown(true);
            } else {
                setIsSlowedDown(false);
            }

            const distanceToScroll =
                basePixelsPerMs * elapsed * speedMultiplier;

            if (container) {
                // If we reached the bottom, stop
                if (
                    container.scrollTop + container.clientHeight >=
                    container.scrollHeight - 2
                ) {
                    setIsScrolling(false);
                    return;
                }
                exactScrollTopRef.current += distanceToScroll;
                container.scrollTop = exactScrollTopRef.current;
            }

            scrollRequestRef.current = requestAnimationFrame(scrollStep);
        };

        scrollRequestRef.current = requestAnimationFrame(scrollStep);

        return () => {
            if (scrollRequestRef.current !== null) {
                cancelAnimationFrame(scrollRequestRef.current);
            }
        };
    }, [isScrolling, slowDownOnRepeat, ast.sections, ast.metadata.tempo]);

    // Reset scroll & state when song ID changes
    useEffect(() => {
        setIsScrolling(false);
        setActiveSectionIndex(null);
        setIsSlowedDown(false);
        if (scrollContainerRef.current) {
            scrollContainerRef.current.scrollTop = 0;
        }
    }, [songId]);

    const handleTranspose = (amount: number) => {
        setTransposeVal((prev) => {
            let next = prev + amount;
            if (next > 11) next -= 12;
            if (next < -12) next += 12;
            return next;
        });
    };

    // Touch Swipe handlers
    const handleTouchStart = (e: React.TouchEvent) => {
        setTouchStart(e.targetTouches[0].clientX);
    };

    const handleTouchMove = (e: React.TouchEvent) => {
        setTouchEnd(e.targetTouches[0].clientX);
    };

    const handleTouchEnd = () => {
        if (touchStart === null || touchEnd === null) return;
        const distance = touchStart - touchEnd;
        const minSwipeDistance = 70;

        if (distance > minSwipeDistance) {
            handleNextSong();
        } else if (distance < -minSwipeDistance) {
            handlePrevSong();
        }

        setTouchStart(null);
        setTouchEnd(null);
    };

    // Desktop click navigations
    const handleNextSong = () => {
        if (currentIndex < activeSongIds.length - 1) {
            const nextId = activeSongIds[currentIndex + 1];
            useAppStore.getState().addRecentlyPlayedSong(nextId);
            setSong(nextId);
            setTransposeVal(0);
            setShowYoutubePlayer(false);
            setIsPlayingYoutube(false);
        }
    };

    const handlePrevSong = () => {
        if (currentIndex > 0) {
            const prevId = activeSongIds[currentIndex - 1];
            useAppStore.getState().addRecentlyPlayedSong(prevId);
            setSong(prevId);
            setTransposeVal(0);
            setShowYoutubePlayer(false);
            setIsPlayingYoutube(false);
        }
    };

    const isFav = favoriteSongIds.includes(song.id);

    // Load selected chord fingering
    const chordFingering = useMemo(() => {
        if (!selectedChord) return null;
        return chordDictionary.getFingering(selectedChord);
    }, [selectedChord]);

    return (
        <div
            className="flex-1 flex flex-col h-full bg-m3-bg dark:bg-m3-dark-bg overflow-hidden relative"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
        >
            {/* Top Navbar with details */}
            <div className="h-16 px-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0 select-none">
                <button
                    onClick={onBack}
                    id="btn_song_view_back"
                    className="flex items-center gap-1 text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-primary dark:hover:text-m3-dark-primary font-medium"
                >
                    <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                    <span className="text-sm">
                        {serviceMode ? "Culto" : "Biblioteca"}
                    </span>
                </button>

                <div className="flex items-center gap-1.5">
                    {/* Favorite heart toggle */}
                    <button
                        onClick={() => toggleFavoriteSong(song.id)}
                        id="btn_song_view_favorite"
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
                            id="btn_song_view_edit"
                            className="p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors text-m3-secondary dark:text-m3-dark-secondary"
                            title="Editar Cântico"
                        >
                            <Edit2 className="w-4.5 h-4.5 text-m3-primary dark:text-m3-dark-primary" />
                        </button>
                    )}

                    <button
                        onClick={() => setShowControls(!showControls)}
                        id="btn_song_view_controls"
                        className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${showControls ? "bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text border border-m3-border/30" : "text-m3-secondary dark:text-m3-dark-secondary"}`}
                        title="Ajustar Tom e Tamanho"
                    >
                        <SlidersHorizontal className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                    </button>
                </div>
            </div>

            {/* Non-modal controls popover */}
            {showControls && (
                <div className="absolute right-4 top-16 w-64 bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-2xl shadow-xl z-30 p-4 space-y-4 select-none animate-in fade-in slide-in-from-top-1 duration-200">
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

                    {/* Show/Hide Chords Segmented Control */}
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
                                <EyeOff className="w-3 h-3" />
                                Apenas Letra
                            </button>
                            <button
                                onClick={() => setShowChords(true)}
                                className={`flex-1 py-1.5 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                                    showChords
                                        ? "bg-m3-primary text-white shadow-xs"
                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                }`}
                            >
                                <Eye className="w-3.5 h-3.5" />
                                Com Cifras
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
                                    semitons
                                </span>
                            </div>
                            <div className="grid grid-cols-3 gap-1 bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                                <button
                                    onClick={() => handleTranspose(-1)}
                                    className="py-1 text-xs font-bold rounded-lg transition-all text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center gap-0.5"
                                    title="Diminuir Semitom"
                                >
                                    <Minus className="w-3 h-3" />
                                    <span>♭</span>
                                </button>
                                <button
                                    onClick={() => setTransposeVal(0)}
                                    className={`py-1 text-[10px] font-bold rounded-lg transition-all ${
                                        transposeVal === 0
                                            ? "bg-m3-primary text-white shadow-xs"
                                            : "text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                    }`}
                                >
                                    Original
                                </button>
                                <button
                                    onClick={() => handleTranspose(1)}
                                    className="py-1 text-xs font-bold rounded-lg transition-all text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center gap-0.5"
                                    title="Aumentar Semitom"
                                >
                                    <span>#</span>
                                    <Plus className="w-3 h-3" />
                                </button>
                            </div>
                        </div>
                    )}

                    {/* Show/Hide Diagrams & Instrument select (Only visible when chords are enabled) */}
                    {showChords && (
                        <div className="space-y-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3 animate-in fade-in duration-200">
                            {/* Show/Hide Diagrams */}
                            <div className="space-y-1.5">
                                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">
                                    Diagramas de Acordes:
                                </span>
                                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                                    <button
                                        onClick={() => setShowDiagrams(false)}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                                            !showDiagrams
                                                ? "bg-m3-primary text-white shadow-xs"
                                                : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                        }`}
                                    >
                                        Ocultar
                                    </button>
                                    <button
                                        onClick={() => setShowDiagrams(true)}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                                            showDiagrams
                                                ? "bg-m3-primary text-white shadow-xs"
                                                : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                        }`}
                                    >
                                        Mostrar
                                    </button>
                                </div>
                            </div>

                            {/* Instrument select */}
                            <div className="space-y-1.5">
                                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">
                                    Instrumento de Acordes:
                                </span>
                                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                                    <button
                                        onClick={() => setInstrument("guitar")}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${
                                            instrument === "guitar"
                                                ? "bg-m3-primary text-white shadow-xs"
                                                : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                        }`}
                                    >
                                        Guitarra
                                    </button>
                                    <button
                                        onClick={() => setInstrument("piano")}
                                        className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${
                                            instrument === "piano"
                                                ? "bg-m3-primary text-white shadow-xs"
                                                : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                        }`}
                                    >
                                        Piano
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Font size */}
                    <div className="flex items-center justify-between border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                            Tamanho da Letra:
                        </span>
                        <div className="flex items-center gap-1.5">
                            <button
                                onClick={() =>
                                    setFontSize(Math.max(10, fontSize - 1))
                                }
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center text-xs font-black text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/20 active:scale-90 transition-transform"
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
                                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center text-xs font-black text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/20 active:scale-90 transition-transform"
                            >
                                <Plus className="w-3.5 h-3.5" />
                            </button>
                        </div>
                    </div>

                    {/* Keep Awake */}
                    <div className="flex items-center justify-between border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
                        <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary flex items-center gap-1">
                            <Sun className="w-3.5 h-3.5" />
                            Ecrã Sempre Ativo:
                        </span>
                        <button
                            onClick={() => setKeepScreenAwake(!keepScreenAwake)}
                            className={`w-9 h-5 rounded-full p-0.5 transition-colors relative flex items-center ${
                                keepScreenAwake
                                    ? "bg-m3-primary"
                                    : "bg-neutral-200 dark:bg-zinc-800"
                            }`}
                        >
                            <div
                                className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform transform ${
                                    keepScreenAwake
                                        ? "translate-x-4"
                                        : "translate-x-0"
                                }`}
                            />
                        </button>
                    </div>
                </div>
            )}

            <ChordProRenderer
                content={song.content}
                showChords={showChords}
                transposeVal={transposeVal}
                fontSize={fontSize}
                instrument={instrument}
                showDiagrams={showDiagrams}
                onChordClick={setSelectedChord}
                fileName={song.fileName}
                showYoutubePlayer={isPlayingYoutube}
                onTransposeChange={setTransposeVal}
            />

            {/* Swipe Chevron navigation cluster (Desktop support) */}
            <div
                className={`absolute right-5 flex flex-col items-end gap-3 select-none shrink-0 z-20 transition-all duration-300 ${showYoutubePlayer ? "bottom-20" : "bottom-5"}`}
            >
                {/* Auto Scroll Floating Button */}
                <button
                    onClick={() => setIsScrolling(!isScrolling)}
                    className={`p-3.5 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4 ${
                        isScrolling
                            ? "bg-neutral-800 dark:bg-zinc-100 text-white dark:text-neutral-900 border-neutral-700 dark:border-zinc-300"
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

                {/* YouTube Floating Play Button */}
                {ast.metadata.youtube && (
                    <>
                        <button
                            onClick={() => {
                                setShowYoutubePlayer((prev) => !prev);
                                if (showYoutubePlayer) {
                                    setIsPlayingYoutube(false);
                                } else {
                                    setIsPlayingYoutube(true);
                                }
                            }}
                            className="p-3.5 rounded-full shadow-lg border border-red-500 bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/60 transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4"
                            title="Ouvir Áudio no YouTube"
                        >
                            <YTIcon className="w-5 h-5" />
                        </button>
                    </>
                )}

                <div className="flex items-center gap-2">
                    <button
                        onClick={handlePrevSong}
                        disabled={currentIndex <= 0}
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                            currentIndex > 0
                                ? "bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                : "bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed"
                        }`}
                        title="Cântico Anterior"
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
                        disabled={
                            currentIndex >= activeSongIds.length - 1 ||
                            currentIndex === -1
                        }
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                            currentIndex < activeSongIds.length - 1 &&
                            currentIndex !== -1
                                ? "bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                : "bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed"
                        }`}
                        title="Cântico Seguinte"
                    >
                        <ChevronRight className="w-5 h-5" />
                    </button>
                </div>
            </div>

            {/* Chord Fingering Dictionary Modal Overlay */}
            {selectedChord && (
                <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4 select-none animate-in fade-in duration-200">
                    <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-3xl w-full max-w-sm overflow-hidden shadow-2xl flex flex-col p-6 space-y-4 animate-in zoom-in-95 duration-200">
                        {/* Modal Header */}
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <BookOpen className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                                <h3 className="text-sm font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider">
                                    Dicionário: {selectedChord}
                                </h3>
                            </div>
                            <button
                                onClick={() => setSelectedChord(null)}
                                className="p-1 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary"
                            >
                                <X className="w-5 h-5" />
                            </button>
                        </div>

                        {/* Instrument switcher inside modal */}
                        <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-1 rounded-2xl border border-m3-border dark:border-m3-dark-border">
                            <button
                                onClick={() => setInstrument("guitar")}
                                className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                                    instrument === "guitar"
                                        ? "bg-m3-primary text-white shadow-sm"
                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                }`}
                            >
                                Diagrama de Guitarra
                            </button>
                            <button
                                onClick={() => setInstrument("piano")}
                                className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                                    instrument === "piano"
                                        ? "bg-m3-primary text-white shadow-sm"
                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text"
                                }`}
                            >
                                Teclado de Piano
                            </button>
                        </div>

                        {/* Fingering render */}
                        <div className="py-4 flex flex-col items-center justify-center min-h-[140px] border border-m3-border/30 dark:border-m3-dark-border/30 rounded-2xl bg-m3-sidebar/30 dark:bg-m3-dark-sidebar/10">
                            {chordFingering ? (
                                instrument === "guitar" &&
                                chordFingering.guitar ? (
                                    <GuitarDiagram
                                        frets={chordFingering.guitar.frets}
                                        fingers={chordFingering.guitar.fingers}
                                        barre={chordFingering.guitar.barre}
                                    />
                                ) : instrument === "piano" &&
                                  chordFingering.piano ? (
                                    <PianoDiagram
                                        highlightKeys={
                                            chordFingering.piano.highlightKeys
                                        }
                                    />
                                ) : (
                                    <div className="text-center p-4">
                                        <HelpCircle className="w-8 h-8 mx-auto text-amber-500 opacity-80 mb-2" />
                                        <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary font-medium">
                                            O diagrama para{" "}
                                            {instrument === "guitar"
                                                ? "Guitarra"
                                                : "Piano"}{" "}
                                            não pôde ser calculado.
                                        </p>
                                    </div>
                                )
                            ) : (
                                <div className="text-center p-6 space-y-2">
                                    <HelpCircle className="w-8 h-8 mx-auto text-amber-500 opacity-80" />
                                    <p className="text-xs text-m3-text dark:text-m3-dark-text font-bold">
                                        Acorde &quot;{selectedChord}&quot; não
                                        registado
                                    </p>
                                    <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary max-w-[200px] leading-normal">
                                        Este acorde não se encontra no nosso
                                        dicionário estrito, mas pode tocá-lo com
                                        as notas de acompanhamento habituais.
                                    </p>
                                </div>
                            )}
                        </div>

                        {/* Modal Notes representation */}
                        {chordFingering?.piano && (
                            <div className="text-center font-mono text-xs text-m3-secondary dark:text-m3-dark-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar py-2 rounded-xl">
                                Notas do Acorde:{" "}
                                <span className="font-bold text-m3-primary dark:text-m3-dark-primary">
                                    {chordFingering.piano.notes.join(" - ")}
                                </span>
                            </div>
                        )}

                        {/* Close button */}
                        <button
                            onClick={() => setSelectedChord(null)}
                            className="w-full bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text text-xs py-3 rounded-2xl border border-m3-border dark:border-m3-dark-border font-bold active:scale-95 transition-all"
                        >
                            Voltar ao Cântico
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
