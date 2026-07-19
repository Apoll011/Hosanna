/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useMemo, useEffect, useRef } from 'react';
import { 
  ArrowLeft, Edit2, Music, Eye, EyeOff, Check, User, 
  CalendarPlus, ChevronLeft, ChevronRight, SlidersHorizontal, 
  Heart, X, BookOpen, HelpCircle,
  Youtube, Play, Pause, Repeat, SkipBack, SkipForward, Disc,
  Plus, Minus, RotateCcw, Sun, ChevronsDown, Sparkles
} from 'lucide-react';
import { useAppStore } from '../store/appStore';
import { parseChordPro, transposeChord } from '../lib/chordpro';
import { chordDictionary } from '../lib/chordDictionary';
import { ChordRoll, GuitarDiagram, PianoDiagram } from './ChordRoll';
import YouTube from 'react-youtube';

const hasRepeatInText = (text?: string): boolean => {
  if (!text) return false;
  const lower = text.toLowerCase();
  return lower.includes('bis') || 
         lower.includes('2x') || 
         lower.includes('3x') || 
         lower.includes('x2') || 
         lower.includes('x3') || 
         lower.includes('repetir') || 
         lower.includes('repete') || 
         lower.includes('refrão') ||
         lower.includes('chorus') ||
         lower.includes('coro');
};

const isSectionRepeated = (section: any): boolean => {
  if (section.type === 'chorus') return true;
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
}

export default function SongView({ songId, onBack, onEdit }: SongViewProps) {
  const songs = useAppStore(state => state.songs);
  const services = useAppStore(state => state.services);
  const addSongToService = useAppStore(state => state.addSongToService);
  
  // Persisted state preferences from store
  const fontSize = useAppStore(state => state.fontSize);
  const setFontSize = useAppStore(state => state.setFontSize);
  const showChords = useAppStore(state => state.showChords);
  const setShowChords = useAppStore(state => state.setShowChords);
  const showDiagrams = useAppStore(state => state.showDiagrams);
  const setShowDiagrams = useAppStore(state => state.setShowDiagrams);
  const keepScreenAwake = useAppStore(state => state.keepScreenAwake);
  const setKeepScreenAwake = useAppStore(state => state.setKeepScreenAwake);
  const slowDownOnRepeat = useAppStore(state => state.slowDownOnRepeat);
  const instrument = useAppStore(state => state.instrument);
  const setInstrument = useAppStore(state => state.setInstrument);
  const favoriteSongIds = useAppStore(state => state.favoriteSongIds);
  const toggleFavoriteSong = useAppStore(state => state.toggleFavoriteSong);
  const activeSongId = useAppStore(state => state.activeSongId);
  const setActiveSongId = useAppStore(state => state.setActiveSongId);

  // Swipe logic & active song lists
  const getActiveSongListIds = useAppStore(state => state.getActiveSongListIds);
  const activeListContext = useAppStore(state => state.activeListContext);
  const recentlyPlayedSongIds = useAppStore(state => state.recentlyPlayedSongIds);
  const sortBy = useAppStore(state => state.sortBy);

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
    sortBy
  ]);

  const currentIndex = useMemo(() => activeSongIds.indexOf(songId), [activeSongIds, songId]);

  // Touch state for swiping
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);

  // Local overrides (transpose isn't persisted long-term to raw file)
  const [transposeVal, setTransposeVal] = useState(0);
  const [showServiceMenu, setShowServiceMenu] = useState(false);
  const [showServiceSuccess, setShowServiceSuccess] = useState<string | null>(null);
  const [showControls, setShowControls] = useState(false);
  const [selectedChord, setSelectedChord] = useState<string | null>(null);

  // YouTube Audio Player states
  const [showYoutubePlayer, setShowYoutubePlayer] = useState(false);
  const [isPlayingYoutube, setIsPlayingYoutube] = useState(false);
  const [isYoutubeRepeat, setIsYoutubeRepeat] = useState(false);
  const [youtubePlayer, setYoutubePlayer] = useState<any>(null);

  const song = useMemo(() => songs.find(s => s.id === songId), [songs, songId]);

  if (!song) {
    return (
      <div className="p-8 text-center bg-m3-bg dark:bg-m3-dark-bg h-full flex flex-col items-center justify-center">
        <p className="text-sm text-m3-secondary dark:text-m3-dark-secondary">
          Cântico não encontrado ou foi removido.
        </p>
        <button onClick={onBack} className="mt-4 bg-m3-primary text-white px-5 py-2.5 rounded-2xl text-xs font-bold active:scale-95 transition-all">
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
  const [wakeLockActive, setWakeLockActive] = useState(false);
  const wakeLockRef = useRef<any>(null);

  // Auto-scroll states
  const [isScrolling, setIsScrolling] = useState(false);
  const [activeSectionIndex, setActiveSectionIndex] = useState<number | null>(null);
  const [isSlowedDown, setIsSlowedDown] = useState(false);

  const scrollContainerRef = useRef<HTMLDivElement | null>(null);
  const scrollRequestRef = useRef<number | null>(null);
  const lastScrollTimeRef = useRef<number | null>(null);
  const exactScrollTopRef = useRef<number>(0);

  // Keep-Awake effect
  useEffect(() => {
    let isMounted = true;
    async function requestWakeLock() {
      if (!keepScreenAwake) return;
      if (typeof window === 'undefined' || !window.navigator || !('wakeLock' in window.navigator)) {
        return;
      }
      try {
        if (wakeLockRef.current) return;
        const wakeLock = await (window.navigator as any).wakeLock.request('screen');
        if (isMounted) {
          wakeLockRef.current = wakeLock;
          setWakeLockActive(true);
          wakeLock.addEventListener('release', () => {
            if (isMounted) setWakeLockActive(false);
          });
        }
      } catch (err) {
        console.warn('Screen wake lock failed:', err);
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
      if (document.visibilityState === 'visible' && keepScreenAwake) {
        requestWakeLock();
      }
    };

    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      isMounted = false;
      document.removeEventListener('visibilitychange', handleVisibility);
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
    const tempo = ast.metadata.tempo ? parseInt(ast.metadata.tempo, 10) : 80;
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
        const sectionElems = container.querySelectorAll('[data-section-index]');
        const containerRect = container.getBoundingClientRect();
        // Focus area is in the upper third of the viewport (which is where performers read)
        const focusY = containerRect.top + containerRect.height / 3;

        for (let i = 0; i < sectionElems.length; i++) {
          const elem = sectionElems[i];
          const rect = elem.getBoundingClientRect();
          if (rect.top <= focusY && rect.bottom >= focusY) {
            activeIndex = parseInt(elem.getAttribute('data-section-index') || '0', 10);
            break;
          }
        }

        if (activeIndex !== null) {
          setActiveSectionIndex(activeIndex);
          const currentSection = ast.sections[activeIndex];
          if (currentSection) {
            isRepeatSectionActive = isSectionRepeated(currentSection);
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

      const distanceToScroll = basePixelsPerMs * elapsed * speedMultiplier;

      if (container) {
        // If we reached the bottom, stop
        if (container.scrollTop + container.clientHeight >= container.scrollHeight - 2) {
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

  // Compute transposed active key
  const currentKey = useMemo(() => {
    const baseKey = ast.metadata.key || 'G';
    if (transposeVal === 0) return baseKey;
    return transposeChord(baseKey, transposeVal);
  }, [ast.metadata.key, transposeVal]);

  // Extract unique chords used in the song
  const uniqueChords = useMemo(() => {
    const list: string[] = [];
    ast.sections.forEach(section => {
      section.lines.forEach(line => {
        if (line.segments) {
          line.segments.forEach(seg => {
            if (seg.chord && !list.includes(seg.chord)) {
              list.push(seg.chord);
            }
          });
        }
      });
    });
    return list;
  }, [ast]);

  const handleTranspose = (amount: number) => {
    setTransposeVal(prev => {
      let next = prev + amount;
      if (next > 11) next -= 12;
      if (next < -12) next += 12;
      return next;
    });
  };

  const handleAddToService = (svcId: string, svcName: string) => {
    addSongToService(svcId, song.id);
    setShowServiceSuccess(svcName);
    setTimeout(() => {
      setShowServiceSuccess(null);
      setShowServiceMenu(false);
    }, 1500);
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

    if (distance > minSwipeDistance && currentIndex < activeSongIds.length - 1) {
      // Swipe Left -> Next Song
      const nextId = activeSongIds[currentIndex + 1];
      useAppStore.getState().addRecentlyPlayedSong(nextId);
      setActiveSongId(nextId);
      setTransposeVal(0); // Reset transpose on slide
      setShowYoutubePlayer(false);
      setIsPlayingYoutube(false);
    } else if (distance < -minSwipeDistance && currentIndex > 0) {
      // Swipe Right -> Previous Song
      const prevId = activeSongIds[currentIndex - 1];
      useAppStore.getState().addRecentlyPlayedSong(prevId);
      setActiveSongId(prevId);
      setTransposeVal(0);
      setShowYoutubePlayer(false);
      setIsPlayingYoutube(false);
    }

    setTouchStart(null);
    setTouchEnd(null);
  };

  // Desktop click navigations
  const handleNextSong = () => {
    if (currentIndex < activeSongIds.length - 1) {
      const nextId = activeSongIds[currentIndex + 1];
      useAppStore.getState().addRecentlyPlayedSong(nextId);
      setActiveSongId(nextId);
      setTransposeVal(0);
      setShowYoutubePlayer(false);
      setIsPlayingYoutube(false);
    }
  };

  const handlePrevSong = () => {
    if (currentIndex > 0) {
      const prevId = activeSongIds[currentIndex - 1];
      useAppStore.getState().addRecentlyPlayedSong(prevId);
      setActiveSongId(prevId);
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
          <span className="text-sm">Biblioteca</span>
        </button>

        <div className="flex items-center gap-1.5">
          {/* Favorite heart toggle */}
          <button
            onClick={() => toggleFavoriteSong(song.id)}
            id="btn_song_view_favorite"
            className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${
              isFav 
                ? 'text-red-500 bg-red-50 dark:bg-red-950/20 border border-red-200/50 dark:border-red-900/40' 
                : 'text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/30'
            }`}
            title={isFav ? "Remover dos favoritos" : "Adicionar aos favoritos"}
          >
            <Heart className={`w-4.5 h-4.5 ${isFav ? 'fill-current' : ''}`} />
          </button>

          <button
            onClick={() => setShowChords(!showChords)}
            className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${
              showChords 
                ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text border border-m3-border/30' 
                : 'text-neutral-400 dark:text-neutral-500 border border-m3-border/30'
            }`}
            title={showChords ? "Ocultar Cifras / Acordes" : "Mostrar Cifras / Acordes"}
          >
            {showChords ? <Eye className="w-4.5 h-4.5" /> : <EyeOff className="w-4.5 h-4.5" />}
          </button>

          <button
            onClick={onEdit}
            id="btn_song_view_edit"
            className="p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors text-m3-secondary dark:text-m3-dark-secondary"
            title="Editar Cântico"
          >
            <Edit2 className="w-4.5 h-4.5 text-m3-primary dark:text-m3-dark-primary" />
          </button>

          <button
            onClick={() => setShowControls(!showControls)}
            id="btn_song_view_controls"
            className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${showControls ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text border border-m3-border/30' : 'text-m3-secondary dark:text-m3-dark-secondary'}`}
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
            <span className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider">Ajustes de Leitura</span>
            <button onClick={() => setShowControls(false)} className="text-[10px] font-bold text-m3-primary dark:text-m3-dark-primary hover:underline">Fechar</button>
          </div>

          {/* Transposition */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">Transposição:</span>
              <span className="text-[11px] font-bold px-2 py-0.5 bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text rounded font-mono">
                {transposeVal > 0 ? `+${transposeVal}` : transposeVal} semitons
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
                    ? 'bg-m3-primary text-white shadow-xs' 
                    : 'text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
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

          {/* Show/Hide Chords Segmented Control */}
          <div className="space-y-1.5 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
            <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">Exibição:</span>
            <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
              <button
                onClick={() => setShowChords(false)}
                className={`flex-1 py-1.5 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                  !showChords 
                    ? 'bg-m3-primary text-white shadow-xs' 
                    : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                }`}
              >
                <EyeOff className="w-3 h-3" />
                Apenas Letra
              </button>
              <button
                onClick={() => setShowChords(true)}
                className={`flex-1 py-1.5 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                  showChords 
                    ? 'bg-m3-primary text-white shadow-xs' 
                    : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                }`}
              >
                <Eye className="w-3.5 h-3.5" />
                Com Cifras
              </button>
            </div>
          </div>

          {/* Show/Hide Diagrams & Instrument select (Only visible when chords are enabled) */}
          {showChords && (
            <div className="space-y-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3 animate-in fade-in duration-200">
              {/* Show/Hide Diagrams */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">Diagramas de Acordes:</span>
                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                  <button
                    onClick={() => setShowDiagrams(false)}
                    className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                      !showDiagrams 
                        ? 'bg-m3-primary text-white shadow-xs' 
                        : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                    }`}
                  >
                    Ocultar
                  </button>
                  <button
                    onClick={() => setShowDiagrams(true)}
                    className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all flex items-center justify-center gap-1 ${
                      showDiagrams 
                        ? 'bg-m3-primary text-white shadow-xs' 
                        : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                    }`}
                  >
                    Mostrar
                  </button>
                </div>
              </div>

              {/* Instrument select */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary block">Instrumento de Acordes:</span>
                <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-xl border border-m3-border/30">
                  <button
                    onClick={() => setInstrument('guitar')}
                    className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${
                      instrument === 'guitar' 
                        ? 'bg-m3-primary text-white shadow-xs' 
                        : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                    }`}
                  >
                    Guitarra
                  </button>
                  <button
                    onClick={() => setInstrument('piano')}
                    className={`flex-1 py-1 text-[10px] font-bold rounded-lg transition-all ${
                      instrument === 'piano' 
                        ? 'bg-m3-primary text-white shadow-xs' 
                        : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
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
            <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary">Tamanho da Letra:</span>
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setFontSize(Math.max(10, fontSize - 1))}
                className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover flex items-center justify-center text-xs font-black text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/20 active:scale-90 transition-transform"
              >
                <Minus className="w-3.5 h-3.5" />
              </button>
              <span className="text-[10px] font-mono font-black text-m3-text dark:text-m3-dark-text min-w-6 text-center">
                {fontSize}px
              </span>
              <button
                onClick={() => setFontSize(Math.min(28, fontSize + 1))}
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
                keepScreenAwake ? 'bg-m3-primary' : 'bg-neutral-200 dark:bg-zinc-800'
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform transform ${
                  keepScreenAwake ? 'translate-x-4' : 'translate-x-0'
                }`}
              />
            </button>
          </div>
        </div>
      )}

      {/* Primary Song Sheet Viewport */}
      <div 
        ref={scrollContainerRef}
        className="flex-1 overflow-y-auto px-6 py-6 space-y-6 no-scrollbar relative"
      >
        
        {/* Title and Metadata Header block */}
        <div className="border-b border-neutral-100 dark:border-zinc-900 pb-4 select-none">
          <div className="flex items-start justify-between gap-4 flex-wrap">
            <div>
              <h2 className="text-2xl font-bold tracking-tight text-neutral-900 dark:text-white">
                {ast.metadata.title}
              </h2>
              {ast.metadata.subtitle && (
                <p className="text-sm font-medium text-neutral-500 dark:text-neutral-400 mt-0.5">
                  {ast.metadata.subtitle}
                </p>
              )}
              {ast.metadata.artist && (
                <div className="flex items-center gap-1 text-xs text-neutral-500 mt-2 font-medium">
                  <User className="w-3.5 h-3.5 text-m3-primary" />
                  <span>Por: {ast.metadata.artist}</span>
                </div>
              )}
            </div>

            {/* Floating Metadata Pills */}
            <div className="flex flex-wrap items-center gap-1.5 justify-end">
              {ast.metadata.songNumber && (
                <span className="text-[10px] font-bold bg-neutral-100 dark:bg-zinc-900 text-neutral-600 dark:text-neutral-400 px-2 py-1 rounded-lg border border-neutral-200 dark:border-zinc-800">
                  Nº {ast.metadata.songNumber}
                </span>
              )}
              {ast.metadata.key && (
                <span className="text-[10px] font-bold bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 px-2.5 py-1 rounded-lg border border-indigo-100 dark:border-indigo-950/50">
                  Tom Original: {ast.metadata.key}
                </span>
              )}
              {ast.metadata.capo && ast.metadata.capo !== '0' && (
                <span className="text-[10px] font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 px-2.5 py-1 rounded-lg border border-amber-100 dark:border-amber-950/50">
                  Capo: {ast.metadata.capo}ª casa
                </span>
              )}
              {ast.metadata.tempo && (
                <span className="text-[10px] bg-neutral-100 dark:bg-zinc-900 text-neutral-500 dark:text-neutral-400 px-2 py-1 rounded-lg font-mono">
                  ♩ {ast.metadata.tempo} BPM
                </span>
              )}
            </div>
          </div>

          {/* Transposition Indicator Banner */}
          {transposeVal !== 0 && (
            <div className="mt-4 bg-indigo-50 dark:bg-indigo-950/40 text-xs px-3 py-2 rounded-xl text-indigo-700 dark:text-indigo-300 flex items-center justify-between border border-indigo-100 dark:border-indigo-950/50">
              <span className="font-semibold">
                Transposto para: <span className="text-indigo-600 dark:text-indigo-400 font-bold bg-white dark:bg-zinc-900 px-2 py-0.5 rounded border ml-1 text-sm">{currentKey}</span>
              </span>
              <button
                onClick={() => setTransposeVal(0)}
                className="text-[10px] font-bold hover:underline underline-offset-2 uppercase text-indigo-600 dark:text-indigo-400"
              >
                Repor Tom
              </button>
            </div>
          )}
        </div>

        {/* Scrollable Chord Visualizer Row */}
        <ChordRoll 
          uniqueChords={uniqueChords}
          transposeVal={transposeVal}
          onChordClick={(chord) => setSelectedChord(chord)}
        />

        {/* Custom AST Renderer */}
        <div className="space-y-6 select-text" style={{ fontSize: `${fontSize}px` }}>
          {ast.sections.map((section, secIdx) => {
            if (section.type === 'chorus') {
              return (
                <div
                  key={secIdx}
                  data-section-index={secIdx}
                  className="pl-4 md:pl-6 border-l-2 border-m3-primary/30 dark:border-m3-dark-primary/30 my-6"
                >
                  <div className="flex items-center gap-1.5 text-[11px] font-bold text-m3-text dark:text-m3-dark-text uppercase tracking-wider mb-3 select-none">
                    <Music className="w-3.5 h-3.5 text-m3-secondary shrink-0" />
                    <span>{section.label || 'Refrão'}</span>
                  </div>
                  <div className="space-y-4 font-medium">
                    {section.lines.map((line, lineIdx) => (
                      <LineRenderer 
                        key={lineIdx} 
                        line={line} 
                        showChords={showChords} 
                        transpose={transposeVal} 
                        onChordClick={setSelectedChord}
                      />
                    ))}
                  </div>
                </div>
              );
            }

            if (section.type === 'tab') {
              return (
                <div key={secIdx} data-section-index={secIdx} className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-4 rounded-xl border border-m3-border dark:border-m3-dark-border my-4 select-text">
                  <div className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider mb-2 select-none">
                    {section.label || 'Tablatura'}
                  </div>
                  <pre className="font-mono text-xs text-m3-text dark:text-m3-dark-text overflow-x-auto leading-relaxed whitespace-pre">
                    {section.lines.map(line => line.text || '').join('\n')}
                  </pre>
                </div>
              );
            }

            if (section.type === 'comment') {
              return (
                <div key={secIdx} data-section-index={secIdx} className="italic text-xs text-m3-secondary dark:text-m3-dark-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar px-4 py-2 rounded-xl border-l-2 border-m3-border dark:border-m3-dark-border my-2 select-none">
                  {section.lines.map(l => l.text).join(', ')}
                </div>
              );
            }

            // Normal Verse with a dynamic left margin line indicator
            const verseLabel = section.label || `Verso ${secIdx + 1}`;
            return (
              <div key={secIdx} data-section-index={secIdx} className="relative pl-6 sm:pl-8 border-l border-m3-border/30 dark:border-m3-dark-border/30 py-1.5">
                <div className="absolute -left-1 top-4 text-[9px] font-bold text-m3-primary dark:text-m3-dark-primary -rotate-90 origin-left tracking-wider uppercase select-none whitespace-nowrap opacity-80">
                  {verseLabel}
                </div>
                <div className="space-y-4">
                  {section.lines.map((line, lineIdx) => (
                    <LineRenderer 
                      key={lineIdx} 
                      line={line} 
                      showChords={showChords} 
                      transpose={transposeVal} 
                      onChordClick={setSelectedChord}
                    />
                  ))}
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer info & copyrights */}
        <div className="border-t border-neutral-100 dark:border-zinc-900 pt-6 mt-12 text-center text-[10px] text-neutral-400 dark:text-neutral-500 select-none space-y-1">
          {ast.metadata.composer && <p>Compositor: {ast.metadata.composer}</p>}
          {ast.metadata.copyright && <p>© Copyright: {ast.metadata.copyright}</p>}
          {ast.metadata.album && <p>Álbum: {ast.metadata.album}</p>}
          <p className="mt-4">Carregado a partir do ficheiro: {song.fileName}</p>
        </div>
      </div>

      {/* Swipe Chevron navigation cluster (Desktop support) */}
      <div className={`absolute right-5 flex flex-col items-end gap-3 select-none shrink-0 z-20 transition-all duration-300 ${showYoutubePlayer ? 'bottom-20' : 'bottom-5'}`}>
        
        {/* Auto Scroll Floating Button */}
        <button
          onClick={() => setIsScrolling(!isScrolling)}
          className={`p-3.5 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4 ${
            isScrolling 
              ? 'bg-neutral-800 dark:bg-zinc-100 text-white dark:text-neutral-900 border-neutral-700 dark:border-zinc-300' 
              : 'bg-m3-primary dark:bg-m3-dark-primary text-white border-m3-primary-light dark:border-m3-dark-primary-light hover:opacity-90'
          }`}
          title={isScrolling ? "Pausar Rolar Automático" : "Iniciar Rolar Automático"}
        >
          {isScrolling ? <Pause className="w-5 h-5" /> : <ChevronsDown className="w-5 h-5" />}
        </button>

        {/* YouTube Floating Play Button */}
        {ast.metadata.youtube && (
          <button
            onClick={() => {
              setShowYoutubePlayer(prev => !prev);
              if (!showYoutubePlayer) setIsPlayingYoutube(true);
            }}
            className="p-3.5 rounded-full shadow-lg border border-red-500 bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/60 transition-all active:scale-95 flex items-center justify-center animate-in slide-in-from-bottom-4"
            title="Ouvir Áudio no YouTube"
          >
            <Youtube className="w-5 h-5" />
          </button>
        )}

        <div className="flex items-center gap-2">
          <button
            onClick={handlePrevSong}
            disabled={currentIndex <= 0}
            className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
              currentIndex > 0 
                ? 'bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover' 
                : 'bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed'
            }`}
            title="Cântico Anterior"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <span className="bg-m3-card/90 dark:bg-m3-dark-card/90 border border-m3-border dark:border-m3-dark-border backdrop-blur-md text-[10px] font-bold font-mono px-3 py-2 rounded-full text-m3-secondary dark:text-m3-dark-secondary">
            {currentIndex !== -1 ? `${currentIndex + 1} / ${activeSongIds.length}` : 'Solo'}
          </span>

          <button
            onClick={handleNextSong}
            disabled={currentIndex >= activeSongIds.length - 1 || currentIndex === -1}
            className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
              currentIndex < activeSongIds.length - 1 && currentIndex !== -1
                ? 'bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover' 
                : 'bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed'
            }`}
            title="Cântico Seguinte"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* YouTube Spotify-like Mini Player Bottom Bar */}
      {showYoutubePlayer && ast.metadata.youtube && (
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-m3-card dark:bg-m3-dark-card border-t border-m3-border dark:border-m3-dark-border shadow-[0_-4px_10px_rgba(0,0,0,0.05)] z-30 px-4 flex items-center justify-between animate-in slide-in-from-bottom-full">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded overflow-hidden bg-slate-200 dark:bg-slate-800 shrink-0 border border-m3-border/50">
              {ast.metadata.youtube.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([^&?]+)/) || ast.metadata.youtube.match(/^[^&?]+$/) ? (
                <img 
                  src={`https://img.youtube.com/vi/${(ast.metadata.youtube.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([^&?]+)/)?.[1] || ast.metadata.youtube)}/default.jpg`}
                  alt="YouTube Thumbnail" 
                  className="w-full h-full object-cover scale-150"
                />
              ) : (
                <Disc className="w-5 h-5 m-auto mt-2.5 text-m3-secondary opacity-50" />
              )}
            </div>
            <div className="hidden sm:block">
              <p className="text-[10px] font-black text-m3-text dark:text-m3-dark-text truncate max-w-[120px]">{ast.metadata.title}</p>
              <p className="text-[9px] text-m3-secondary font-medium">Áudio do YouTube</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button 
              onClick={() => youtubePlayer?.seekTo(Math.max(0, youtubePlayer.getCurrentTime() - 10))}
              className="text-m3-secondary hover:text-m3-primary transition-colors active:scale-95"
              title="Retroceder 10s"
            >
              <SkipBack className="w-4 h-4" />
            </button>
            
            <button 
              onClick={() => {
                if (isPlayingYoutube) {
                  youtubePlayer?.pauseVideo();
                  setIsPlayingYoutube(false);
                } else {
                  youtubePlayer?.playVideo();
                  setIsPlayingYoutube(true);
                }
              }}
              className="w-10 h-10 rounded-full bg-m3-primary text-white flex items-center justify-center hover:opacity-95 shadow-md active:scale-95 transition-all"
            >
              {isPlayingYoutube ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5 ml-1" />}
            </button>

            <button 
              onClick={() => youtubePlayer?.seekTo(youtubePlayer.getCurrentTime() + 10)}
              className="text-m3-secondary hover:text-m3-primary transition-colors active:scale-95"
              title="Avançar 10s"
            >
              <SkipForward className="w-4 h-4" />
            </button>

            <button 
              onClick={() => setIsYoutubeRepeat(!isYoutubeRepeat)}
              className={`ml-2 transition-colors active:scale-95 ${isYoutubeRepeat ? 'text-m3-primary' : 'text-m3-secondary hover:text-m3-text'}`}
              title="Repetir Áudio"
            >
              <Repeat className="w-4 h-4" />
            </button>
          </div>
          
          <div className="flex items-center gap-2">
            <button 
              onClick={() => {
                setShowYoutubePlayer(false);
                setIsPlayingYoutube(false);
              }}
              className="p-2 text-m3-secondary hover:text-red-500 transition-colors"
              title="Fechar Player"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Invisible actual player */}
          <div className="hidden">
            <YouTube 
              videoId={ast.metadata.youtube.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([^&?]+)/)?.[1] || ast.metadata.youtube}
              opts={{
                height: '0',
                width: '0',
                playerVars: {
                  autoplay: 1,
                  controls: 0,
                  disablekb: 1,
                },
              }}
              onReady={(e) => setYoutubePlayer(e.target)}
              onPlay={() => setIsPlayingYoutube(true)}
              onPause={() => setIsPlayingYoutube(false)}
              onEnd={(e) => {
                if (isYoutubeRepeat) {
                  e.target.seekTo(0);
                  e.target.playVideo();
                } else {
                  setIsPlayingYoutube(false);
                }
              }}
            />
          </div>
        </div>
      )}

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
                onClick={() => setInstrument('guitar')}
                className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                  instrument === 'guitar' 
                    ? 'bg-m3-primary text-white shadow-sm' 
                    : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                }`}
              >
                Diagrama de Guitarra
              </button>
              <button
                onClick={() => setInstrument('piano')}
                className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                  instrument === 'piano' 
                    ? 'bg-m3-primary text-white shadow-sm' 
                    : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text'
                }`}
              >
                Teclado de Piano
              </button>
            </div>

            {/* Fingering render */}
            <div className="py-4 flex flex-col items-center justify-center min-h-[140px] border border-m3-border/30 dark:border-m3-dark-border/30 rounded-2xl bg-m3-sidebar/30 dark:bg-m3-dark-sidebar/10">
              {chordFingering ? (
                instrument === 'guitar' && chordFingering.guitar ? (
                  <GuitarDiagram 
                    frets={chordFingering.guitar.frets} 
                    fingers={chordFingering.guitar.fingers} 
                    barre={chordFingering.guitar.barre} 
                  />
                ) : instrument === 'piano' && chordFingering.piano ? (
                  <PianoDiagram highlightKeys={chordFingering.piano.highlightKeys} />
                ) : (
                  <div className="text-center p-4">
                    <HelpCircle className="w-8 h-8 mx-auto text-amber-500 opacity-80 mb-2" />
                    <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary font-medium">
                      O diagrama para {instrument === 'guitar' ? 'Guitarra' : 'Piano'} não pôde ser calculado.
                    </p>
                  </div>
                )
              ) : (
                <div className="text-center p-6 space-y-2">
                  <HelpCircle className="w-8 h-8 mx-auto text-amber-500 opacity-80" />
                  <p className="text-xs text-m3-text dark:text-m3-dark-text font-bold">
                    Acorde "{selectedChord}" não registado
                  </p>
                  <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary max-w-[200px] leading-normal">
                    Este acorde não se encontra no nosso dicionário estrito, mas pode tocá-lo com as notas de acompanhamento habituais.
                  </p>
                </div>
              )}
            </div>

            {/* Modal Notes representation */}
            {chordFingering?.piano && (
              <div className="text-center font-mono text-xs text-m3-secondary dark:text-m3-dark-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar py-2 rounded-xl">
                Notas do Acorde: <span className="font-bold text-m3-primary dark:text-m3-dark-primary">{chordFingering.piano.notes.join(' - ')}</span>
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

/**
 * Sub-component to render a line of text, splitting into segmented block components
 */
function LineRenderer({ 
  line, 
  showChords, 
  transpose, 
  onChordClick 
}: { 
  line: any; 
  showChords: boolean; 
  transpose: number; 
  onChordClick: (chord: string) => void;
  key?: any;
}) {
  if (line.type === 'empty') {
    return <div className="h-2"></div>;
  }

  if (line.type === 'comment') {
    return (
      <div className="text-xs text-neutral-400 dark:text-neutral-500 italic">
        {line.text}
      </div>
    );
  }

  const segments = line.segments || [];

  return (
    <div className="flex flex-wrap items-end leading-relaxed">
      {segments.map((seg: any, segIdx: number) => {
        const hasChord = !!seg.chord;
        const transposed = hasChord ? transposeChord(seg.chord, transpose) : '';

        return (
          <div key={segIdx} className="flex flex-col justify-end relative select-text" style={{ minWidth: hasChord && showChords ? `${Math.max(1.1, transposed.length * 0.65)}em` : undefined }}>
            {showChords && hasChord && (
              <span 
                onClick={() => onChordClick(transposed)}
                className="font-black text-m3-primary dark:text-m3-dark-primary font-mono select-none pr-1 inline-block pb-0.5 hover:underline cursor-pointer transition-all"
                style={{ fontSize: '0.85em', lineHeight: '1' }}
                title="Ver fingering / dedilhado"
              >
                {transposed}
              </span>
            )}
            <span className="text-m3-text dark:text-m3-dark-text whitespace-pre">
              {seg.text || '\u00A0'}
            </span>
          </div>
        );
      })}
    </div>
  );
}


