import { ChordProRenderer, parseChordPro } from "@hosanna/shared";
import {
    ArrowLeft,
    ChevronLeft,
    ChevronRight,
    ChevronsDown,
    Columns2,
    Edit2,
    Eye,
    EyeOff,
    Heart,
    LogOut,
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
import { Button } from "./ui/button";

interface SongViewProps {
    songId: string;
    onBack: () => void;
    onEdit: () => void;
    setSong: (id: string) => void;
    serviceMode?: boolean;
    customLeftButton?: React.ReactNode;
}

export default function SongView({
    songId,
    onBack,
    onEdit,
    setSong,
    serviceMode = false,
    customLeftButton,
}: SongViewProps) {
    const songs = useAppStore((state) => state.songs);
    const services = useAppStore((state) => state.services);

    // Persisted state preferences
    const fontSize = useAppStore((state) => state.fontSize);
    const setFontSize = useAppStore((state) => state.setFontSize);
    const showChords = useAppStore((state) => state.showChords);
    const setShowChords = useAppStore((state) => state.setShowChords);
    const showDiagrams = useAppStore((state) => state.showDiagrams);
    const keepScreenAwake = useAppStore((state) => state.keepScreenAwake);
    const setKeepScreenAwake = useAppStore((state) => state.setKeepScreenAwake);
    const instrument = useAppStore((state) => state.instrument);
    const twoColumnLayout = useAppStore((state) => state.twoColumnLayout);
    const setTwoColumnLayout = useAppStore((state) => state.setTwoColumnLayout);
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
    const [capoVal, setCapoVal] = useState(0);
    const [showControls, setShowControls] = useState(false);
    const [showYoutubePlayer, setShowYoutubePlayer] = useState(false);
    const [isPlayingYoutube, setIsPlayingYoutube] = useState(false);
    const [isScrolling, setIsScrolling] = useState(false);
    const [scrollSpeed, setScrollSpeed] = useState(5);
    const wakeLockActiveRef = useRef(keepScreenAwake);

    const song = useMemo(
        () => songs.find((s) => s.id === songId),
        [songs, songId],
    );

    const ast = useMemo(() => {
        return song ? parseChordPro(song.content) : null;
    }, [song]);

    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const contentRef = useRef<HTMLDivElement | null>(null);
    const leftIndicatorRef = useRef<HTMLDivElement | null>(null);
    const rightIndicatorRef = useRef<HTMLDivElement | null>(null);
    const scrollRequestRef = useRef<number | null>(null);
    const lastScrollTimeRef = useRef<number | null>(null);
    const exactScrollTopRef = useRef<number>(0);
    const controlsPopoverRef = useRef<HTMLDivElement | null>(null);
    const settingsBtnRef = useRef<HTMLButtonElement | null>(null);
    const wakeLockRef = useRef<WakeLockSentinel | null>(null);

    // Gestures
    const swipeInfo = useRef({
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0,
        isSwiping: false,
        isLockedVertical: false,
    });

    // Close controls popover when clicked outside
    useEffect(() => {
        if (!showControls) return;
        const handleOutsideClick = (e: MouseEvent | TouchEvent) => {
            if (
                controlsPopoverRef.current &&
                !controlsPopoverRef.current.contains(e.target as Node) &&
                settingsBtnRef.current &&
                !settingsBtnRef.current.contains(e.target as Node)
            ) {
                setShowControls(false);
            }
        };
        document.addEventListener("mousedown", handleOutsideClick);
        document.addEventListener("touchstart", handleOutsideClick);
        return () => {
            document.removeEventListener("mousedown", handleOutsideClick);
            document.removeEventListener("touchstart", handleOutsideClick);
        };
    }, [showControls]);

    const handleNextSong = useCallback(() => {
        if (canSwipeNext) {
            const nextId = activeSongIds[currentIndex + 1];
            useAppStore.getState().addRecentlyPlayedSong(nextId);
            setSong(nextId);
            setTransposeVal(0);
            setCapoVal(0);
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
            setCapoVal(0);
            setShowYoutubePlayer(false);
            setIsPlayingYoutube(false);
        }
    }, [canSwipePrev, activeSongIds, currentIndex, setSong]);

    // Keyboard shortcuts inside SongView
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            const target = e.target as HTMLElement | null;
            const isTyping =
                target?.tagName === "INPUT" ||
                target?.tagName === "TEXTAREA" ||
                target?.isContentEditable;
            if (isTyping) return;

            if (e.key === "ArrowRight") {
                if (canSwipeNext) {
                    e.preventDefault();
                    handleNextSong();
                }
            } else if (e.key === "ArrowLeft") {
                if (canSwipePrev) {
                    e.preventDefault();
                    handlePrevSong();
                }
            } else if (e.key === " " || e.code === "Space") {
                e.preventDefault();
                setIsScrolling((prev) => !prev);
            } else if (e.key === "Escape") {
                if (showControls) {
                    e.preventDefault();
                    setShowControls(false);
                } else {
                    e.preventDefault();
                    onBack();
                }
            } else if (e.key === "+" || e.key === "=") {
                e.preventDefault();
                setTransposeVal((v) => v + 1);
            } else if (e.key === "-" || e.key === "_") {
                e.preventDefault();
                setTransposeVal((v) => v - 1);
            }
        };

        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [
        canSwipeNext,
        canSwipePrev,
        handleNextSong,
        handlePrevSong,
        showControls,
        onBack,
    ]);

    // Keep-Awake
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
                    wakeLockActiveRef.current = true;
                    wakeLock.addEventListener("release", () => {
                        if (isMounted) wakeLockActiveRef.current = false;
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
            wakeLockActiveRef.current = false;
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

    // Auto-Scroll Loop
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
        const basePixelsPerMs = 0.005 + scrollSpeed * 0.005;

        const scrollStep = (timestamp: number) => {
            if (!lastScrollTimeRef.current) {
                lastScrollTimeRef.current = timestamp;
                scrollRequestRef.current = requestAnimationFrame(scrollStep);
                return;
            }

            const elapsed = timestamp - lastScrollTimeRef.current;
            lastScrollTimeRef.current = timestamp;

            const increment = elapsed * basePixelsPerMs;
            exactScrollTopRef.current += increment;

            if (scrollContainer) {
                scrollContainer.scrollTop = Math.floor(
                    exactScrollTopRef.current,
                );
                if (
                    scrollContainer.scrollTop + scrollContainer.clientHeight >=
                    scrollContainer.scrollHeight - 2
                ) {
                    setIsScrolling(false);
                    return;
                }
            }

            scrollRequestRef.current = requestAnimationFrame(scrollStep);
        };

        scrollRequestRef.current = requestAnimationFrame(scrollStep);

        return () => {
            if (scrollRequestRef.current !== null) {
                cancelAnimationFrame(scrollRequestRef.current);
                scrollRequestRef.current = null;
            }
            lastScrollTimeRef.current = null;
        };
    }, [isScrolling, scrollSpeed]);

    const handleTouchStart = useCallback((e: React.TouchEvent) => {
        if (e.touches.length !== 1) return;
        const touch = e.touches[0];
        swipeInfo.current = {
            startX: touch.clientX,
            startY: touch.clientY,
            currentX: touch.clientX,
            currentY: touch.clientY,
            isSwiping: true,
            isLockedVertical: false,
        };

        if (contentRef.current) {
            contentRef.current.style.transition = "none";
        }
    }, []);

    const handleTouchMove = useCallback(
        (e: React.TouchEvent) => {
            if (!swipeInfo.current.isSwiping || e.touches.length !== 1) return;
            const touch = e.touches[0];
            swipeInfo.current.currentX = touch.clientX;
            swipeInfo.current.currentY = touch.clientY;

            const dx = touch.clientX - swipeInfo.current.startX;
            const dy = touch.clientY - swipeInfo.current.startY;

            if (
                !swipeInfo.current.isLockedVertical &&
                Math.abs(dy) > Math.abs(dx) &&
                Math.abs(dy) > 10
            ) {
                swipeInfo.current.isLockedVertical = true;
            }

            if (swipeInfo.current.isLockedVertical) return;

            if (contentRef.current) {
                const resistedDx =
                    (dx > 0 && !canSwipePrev) || (dx < 0 && !canSwipeNext)
                        ? dx * 0.2
                        : dx * 0.65;
                contentRef.current.style.transform = `translateX(${resistedDx}px)`;
            }

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
            <div className="p-8 text-center bg-background h-full flex flex-col items-center justify-center">
                <p className="text-sm text-muted-foreground">
                    Cântico não encontrado ou foi removido.
                </p>
                <Button onClick={onBack} className="mt-4 text-xs font-bold">
                    Voltar para Biblioteca
                </Button>
            </div>
        );
    }

    const isFav = favoriteSongIds.includes(song.id);
    const isGuitar = instrument === "guitar";

    return (
        <div
            className="flex-1 flex flex-col h-full bg-background overflow-hidden relative"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
        >
            {/* Top Clean Navbar */}
            <div
                className="px-3 sm:px-4 bg-card border-b border-border flex items-center justify-between shrink-0 select-none z-40 relative"
                style={{
                    paddingTop: "calc(0.5rem + env(safe-area-inset-top, 0px))",
                    paddingBottom: "0.5rem",
                    minHeight: "3.75rem",
                }}
            >
                {customLeftButton ? (
                    customLeftButton
                ) : (
                    <Button
                        variant="ghost"
                        size="sm"
                        onClick={onBack}
                        className="text-xs font-bold gap-1.5 h-9 text-muted-foreground hover:text-foreground"
                        aria-label="Voltar"
                    >
                        <ArrowLeft className="w-4 h-4 text-primary" />
                        <span>{serviceMode ? "Culto" : "Biblioteca"}</span>
                    </Button>
                )}

                <div className="flex items-center gap-1.5">
                    <Button
                        variant="ghost"
                        size="icon-sm"
                        onClick={() => toggleFavoriteSong(song.id)}
                        className={`rounded-full h-9 w-9 ${
                            isFav
                                ? "text-rose-500 bg-rose-50 dark:bg-rose-950/30"
                                : "text-muted-foreground hover:text-foreground"
                        }`}
                        title={
                            isFav
                                ? "Remover dos favoritos"
                                : "Adicionar aos favoritos"
                        }
                    >
                        <Heart
                            className={`w-4 h-4 ${isFav ? "fill-current" : ""}`}
                        />
                    </Button>

                    {!serviceMode && (
                        <Button
                            variant="ghost"
                            size="icon-sm"
                            onClick={onEdit}
                            className="rounded-full h-9 w-9 text-muted-foreground hover:text-foreground"
                            title="Editar Cântico"
                        >
                            <Edit2 className="w-4 h-4 text-primary" />
                        </Button>
                    )}

                    <Button
                        ref={settingsBtnRef}
                        variant="ghost"
                        size="icon-sm"
                        onClick={() => setShowControls(!showControls)}
                        className={`rounded-full h-9 w-9 ${
                            showControls
                                ? "bg-primary/15 text-primary"
                                : "text-muted-foreground hover:text-foreground"
                        }`}
                        title="Ajustar Tom e Tamanho"
                    >
                        <SlidersHorizontal className="w-4 h-4 text-primary" />
                    </Button>

                    {serviceMode && (
                        <Button
                            variant="ghost"
                            size="icon-sm"
                            onClick={onBack}
                            className="rounded-full h-9 w-9 text-destructive hover:bg-destructive/10 ml-1"
                            title="Sair do Culto"
                        >
                            <LogOut className="w-4 h-4" />
                        </Button>
                    )}
                </div>
            </div>

            {/* Settings Popover */}
            {showControls && (
                <div
                    id="song-settings-popover"
                    role="dialog"
                    aria-label="Ajustes de Leitura"
                    ref={controlsPopoverRef}
                    className="absolute right-4 top-16 w-72 bg-card/95 backdrop-blur-xl border border-border rounded-3xl shadow-2xl z-50 p-4 space-y-4 select-none animate-in fade-in slide-in-from-top-1 duration-200 max-h-[80vh] overflow-y-auto"
                >
                    <div className="border-b border-border pb-2 flex items-center justify-between">
                        <span className="text-xs font-black text-foreground uppercase tracking-wider">
                            Ajustes de Leitura
                        </span>
                        <button
                            onClick={() => setShowControls(false)}
                            className="text-[10px] font-bold text-primary hover:underline cursor-pointer"
                        >
                            Fechar
                        </button>
                    </div>

                    {/* Transpose & Capo Control */}
                    <div className="space-y-2">
                        <div className="flex items-center justify-between text-xs font-bold">
                            <span className="text-muted-foreground">
                                Transposição
                            </span>
                            <span className="font-mono text-primary">
                                {transposeVal > 0
                                    ? `+${transposeVal}`
                                    : transposeVal}{" "}
                                semitons
                            </span>
                        </div>
                        <div className="flex items-center justify-between gap-2 bg-muted/60 p-1.5 rounded-2xl border border-border">
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => setTransposeVal((v) => v - 1)}
                                className="flex-1 font-black text-sm h-8 rounded-xl"
                            >
                                <Minus className="w-3.5 h-3.5" />
                            </Button>
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => setTransposeVal(0)}
                                className="text-[10px] font-bold px-3 h-8 rounded-xl"
                            >
                                Original
                            </Button>
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => setTransposeVal((v) => v + 1)}
                                className="flex-1 font-black text-sm h-8 rounded-xl"
                            >
                                <Plus className="w-3.5 h-3.5" />
                            </Button>
                        </div>

                        {isGuitar && (
                            <div className="pt-2">
                                <div className="flex items-center justify-between text-xs font-bold mb-1.5">
                                    <span className="text-muted-foreground">
                                        Capotraste
                                    </span>
                                    <span className="font-mono text-primary">
                                        {capoVal === 0
                                            ? "Nenhum"
                                            : `Traste ${capoVal}`}
                                    </span>
                                </div>
                                <div className="flex items-center justify-between gap-1.5 bg-muted/60 p-1.5 rounded-2xl border border-border">
                                    {[0, 1, 2, 3, 4, 5].map((traste) => (
                                        <button
                                            key={traste}
                                            onClick={() => setCapoVal(traste)}
                                            className={`flex-1 py-1 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                                                capoVal === traste
                                                    ? "bg-primary text-primary-foreground shadow-xs"
                                                    : "text-muted-foreground hover:text-foreground"
                                            }`}
                                        >
                                            {traste === 0 ? "-" : traste}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Font Size Slider */}
                    <div className="space-y-2 pt-2 border-t border-border">
                        <div className="flex items-center justify-between text-xs font-bold">
                            <span className="text-muted-foreground">
                                Tamanho da Letra
                            </span>
                            <span className="font-mono text-primary">
                                {fontSize}px
                            </span>
                        </div>
                        <div className="flex items-center gap-2">
                            <Button
                                variant="outline"
                                size="icon-sm"
                                onClick={() =>
                                    setFontSize(Math.max(10, fontSize - 2))
                                }
                                className="rounded-xl h-8 w-8"
                            >
                                <Minus className="w-3.5 h-3.5" />
                            </Button>
                            <input
                                type="range"
                                min={10}
                                max={34}
                                step={1}
                                value={fontSize}
                                onChange={(e) =>
                                    setFontSize(parseInt(e.target.value))
                                }
                                className="flex-1 accent-primary h-2 bg-muted rounded-lg cursor-pointer"
                            />
                            <Button
                                variant="outline"
                                size="icon-sm"
                                onClick={() =>
                                    setFontSize(Math.min(34, fontSize + 2))
                                }
                                className="rounded-xl h-8 w-8"
                            >
                                <Plus className="w-3.5 h-3.5" />
                            </Button>
                        </div>
                    </div>

                    {/* Auto-Scroll Speed */}
                    <div className="space-y-2 pt-2 border-t border-border">
                        <div className="flex items-center justify-between text-xs font-bold">
                            <span className="text-muted-foreground">
                                Velocidade do Scroll
                            </span>
                            <span className="font-mono text-primary">
                                {scrollSpeed}x
                            </span>
                        </div>
                        <input
                            type="range"
                            min={1}
                            max={10}
                            step={1}
                            value={scrollSpeed}
                            onChange={(e) =>
                                setScrollSpeed(parseInt(e.target.value))
                            }
                            className="w-full accent-primary h-2 bg-muted rounded-lg cursor-pointer"
                        />
                    </div>

                    {/* Toggles */}
                    <div className="space-y-1.5 pt-2 border-t border-border">
                        <button
                            onClick={() => setShowChords(!showChords)}
                            className="w-full flex items-center justify-between py-2 px-1 text-xs font-bold text-foreground cursor-pointer"
                        >
                            <span>Mostrar Acordes</span>
                            {showChords ? (
                                <Eye className="w-4 h-4 text-primary" />
                            ) : (
                                <EyeOff className="w-4 h-4 text-muted-foreground" />
                            )}
                        </button>

                        <button
                            onClick={() => setTwoColumnLayout(!twoColumnLayout)}
                            className="w-full flex items-center justify-between py-2 px-1 text-xs font-bold text-foreground cursor-pointer"
                        >
                            <span>Layout em 2 Colunas</span>
                            <Columns2
                                className={`w-4 h-4 ${
                                    twoColumnLayout
                                        ? "text-primary"
                                        : "text-muted-foreground"
                                }`}
                            />
                        </button>

                        <button
                            onClick={() => setKeepScreenAwake(!keepScreenAwake)}
                            className="w-full flex items-center justify-between py-2 px-1 text-xs font-bold text-foreground cursor-pointer"
                        >
                            <span>Ecrã Sempre Ativo</span>
                            <Sun
                                className={`w-4 h-4 ${
                                    keepScreenAwake
                                        ? "text-amber-500"
                                        : "text-muted-foreground"
                                }`}
                            />
                        </button>
                    </div>
                </div>
            )}

            {/* Swipe Indicators */}
            <div
                ref={leftIndicatorRef}
                className="absolute left-4 top-1/2 -translate-y-1/2 z-30 opacity-0 pointer-events-none transition-transform"
            >
                <div className="bg-primary text-white p-3 rounded-full shadow-xl">
                    <ChevronLeft className="w-6 h-6" />
                </div>
            </div>
            <div
                ref={rightIndicatorRef}
                className="absolute right-4 top-1/2 -translate-y-1/2 z-30 opacity-0 pointer-events-none transition-transform"
            >
                <div className="bg-primary text-white p-3 rounded-full shadow-xl">
                    <ChevronRight className="w-6 h-6" />
                </div>
            </div>

            {/* Song Content Area */}
            <div
                ref={scrollContainerRef}
                className="flex-1 overflow-y-auto p-4 sm:p-6 no-scrollbar touch-pan-y"
            >
                <div
                    ref={contentRef}
                    className="min-h-full w-full pb-36 will-change-transform"
                >
                    <ChordProRenderer
                        content={song.content}
                        showChords={showChords}
                        transposeVal={transposeVal}
                        capoVal={capoVal}
                        fontSize={fontSize}
                        instrument={instrument}
                        showDiagrams={showDiagrams}
                        twoColumnLayout={twoColumnLayout}
                        fileName={song.fileName}
                        showYoutubePlayer={isPlayingYoutube}
                        onTransposeChange={setTransposeVal}
                        onCapoChange={setCapoVal}
                    />
                </div>
            </div>

            {/* Floating Auto-scroll, YouTube & Navigation Controls */}
            <div
                className={`absolute right-5 flex flex-col items-end gap-3 select-none shrink-0 z-40 transition-all duration-300 pointer-events-none ${
                    showYoutubePlayer ? "bottom-20" : "bottom-5"
                }`}
            >
                <div className="pointer-events-auto">
                    <button
                        onClick={() => setIsScrolling(!isScrolling)}
                        aria-pressed={isScrolling}
                        className={`p-3.5 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center cursor-pointer ${
                            isScrolling
                                ? "bg-neutral-900 dark:bg-zinc-100 text-white dark:text-neutral-900 border-neutral-700 dark:border-zinc-300 shadow-primary/20"
                                : "bg-primary text-primary-foreground border-primary-foreground/20 hover:opacity-95"
                        }`}
                        title={
                            isScrolling
                                ? "Pausar Scroll"
                                : "Iniciar Scroll Automático"
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
                                const next = !isPlayingYoutube;
                                setShowYoutubePlayer(next);
                                setIsPlayingYoutube(next);
                            }}
                            aria-pressed={showYoutubePlayer}
                            className="p-3.5 rounded-full shadow-lg border border-red-500 bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 transition-all active:scale-95 flex items-center justify-center cursor-pointer"
                            title="Ouvir no YouTube"
                        >
                            <YTIcon className="w-5 h-5" />
                        </button>
                    </div>
                )}

                <div className="flex items-center gap-2 pointer-events-auto">
                    <button
                        onClick={handlePrevSong}
                        disabled={!canSwipePrev}
                        aria-label="Cântico anterior"
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center cursor-pointer ${
                            canSwipePrev
                                ? "bg-card border-border text-primary hover:bg-accent"
                                : "bg-muted text-muted-foreground/40 border-transparent cursor-not-allowed"
                        }`}
                    >
                        <ChevronLeft className="w-5 h-5" />
                    </button>

                    <span
                        aria-live="polite"
                        className="bg-card/90 border border-border backdrop-blur-md text-[10px] font-bold font-mono px-3 py-2 rounded-full text-muted-foreground"
                    >
                        {currentIndex !== -1
                            ? `${currentIndex + 1} / ${activeSongIds.length}`
                            : "Solo"}
                    </span>

                    <button
                        onClick={handleNextSong}
                        disabled={!canSwipeNext}
                        aria-label="Próximo cântico"
                        className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center cursor-pointer ${
                            canSwipeNext
                                ? "bg-card border-border text-primary hover:bg-accent"
                                : "bg-muted text-muted-foreground/40 border-transparent cursor-not-allowed"
                        }`}
                    >
                        <ChevronRight className="w-5 h-5" />
                    </button>
                </div>
            </div>
        </div>
    );
}
