/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useMemo, useEffect, useRef } from 'react';
import { 
  CalendarRange, Plus, Trash2, ChevronUp, ChevronDown, BookOpen, 
  FileText, Search, Check, ArrowLeft, SlidersHorizontal, Eye, EyeOff, 
  ChevronLeft, ChevronRight, User, X, GripVertical, HelpCircle,
  Youtube, Play, Pause, Repeat, SkipBack, SkipForward, Disc, Edit2, Music,
  Minus, RotateCcw, ChevronsDown, Sun, Printer, FileDown
} from 'lucide-react';
import { useAppStore } from '../store/appStore';
import { parseChordPro, transposeChord } from '../lib/chordpro';
import { chordDictionary } from '../lib/chordDictionary';
import { ChordRoll, GuitarDiagram, PianoDiagram } from './ChordRoll';
import YouTube from 'react-youtube';
import { exportServiceToPDF } from '../lib/pdfExport';

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

interface ServiceManagerProps {
  onSelectSong: (id: string) => void;
}

export default function ServiceManager({ onSelectSong }: ServiceManagerProps) {
  const services = useAppStore(state => state.services);
  const songs = useAppStore(state => state.songs);
  const activeServiceId = useAppStore(state => state.activeServiceId);
  const setActiveServiceId = useAppStore(state => state.setActiveServiceId);

  const createService = useAppStore(state => state.createService);
  const updateService = useAppStore(state => state.updateService);
  const deleteService = useAppStore(state => state.deleteService);
  const removeSongFromService = useAppStore(state => state.removeSongFromService);
  const reorderSongsInService = useAppStore(state => state.reorderSongsInService);
  const addSongToService = useAppStore(state => state.addSongToService);
  const replaceSongInService = useAppStore(state => state.replaceSongInService);
  const updateSongNotesInService = useAppStore(state => state.updateSongNotesInService);
  const baseFontSize = useAppStore(state => state.fontSize);

  // Active song index within the service alignment for the Special Song Viewer
  const [activeServiceSongIndex, setActiveServiceSongIndex] = useState<number | null>(null);

  // Creators Modal
  const [isCreating, setIsCreating] = useState(false);
  const [newName, setNewName] = useState('');
  const [newDate, setNewDate] = useState('');

  // Song Adder Modal / Replacer Modal
  const [isAddingSong, setIsAddingSong] = useState(false);
  const [isReplacingIndex, setIsReplacingIndex] = useState<number | null>(null);
  const [songSearchQuery, setSongSearchQuery] = useState('');

  // PDF Export Modal State
  const [isExportingPDF, setIsExportingPDF] = useState(false);
  const [pdfIncludeChords, setPdfIncludeChords] = useState(true);

  // Song Notes Editing
  const [editingNoteIndex, setEditingNoteIndex] = useState<number | null>(null);
  const [editingNoteText, setEditingNoteText] = useState('');

  // Local song settings for the Special Song Viewer
  const [transposeVal, setTransposeVal] = useState(0);
  const showChords = useAppStore(state => state.showChords);
  const setShowChords = useAppStore(state => state.setShowChords);
  const showDiagrams = useAppStore(state => state.showDiagrams);
  const setShowDiagrams = useAppStore(state => state.setShowDiagrams);
  const keepScreenAwake = useAppStore(state => state.keepScreenAwake);
  const setKeepScreenAwake = useAppStore(state => state.setKeepScreenAwake);
  const slowDownOnRepeat = useAppStore(state => state.slowDownOnRepeat);
  const instrument = useAppStore(state => state.instrument);
  const setInstrument = useAppStore(state => state.setInstrument);
  const [selectedChord, setSelectedChord] = useState<string | null>(null);
  const [localFontOffset, setLocalFontOffset] = useState(0);
  const [showControls, setShowControls] = useState(false);

  // Auto-scroll & Keep awake
  const [wakeLockActive, setWakeLockActive] = useState(false);
  const wakeLockRef = useRef<any>(null);
  const [isScrolling, setIsScrolling] = useState(false);
  const [activeSectionIndex, setActiveSectionIndex] = useState<number | null>(null);
  const [isSlowedDown, setIsSlowedDown] = useState(false);

  const scrollContainerRef = useRef<HTMLDivElement | null>(null);
  const scrollRequestRef = useRef<number | null>(null);
  const lastScrollTimeRef = useRef<number | null>(null);
  const exactScrollTopRef = useRef<number>(0);

  // Load selected chord fingering
  const chordFingering = useMemo(() => {
    if (!selectedChord) return null;
    return chordDictionary.getFingering(selectedChord);
  }, [selectedChord]);

  // Drag and drop ordering states
  const [draggedIdx, setDraggedIdx] = useState<number | null>(null);
  const [dragOverIdx, setDragOverIdx] = useState<number | null>(null);

  // YouTube Audio Player states
  const [showYoutubePlayer, setShowYoutubePlayer] = useState(false);
  const [isPlayingYoutube, setIsPlayingYoutube] = useState(false);
  const [isYoutubeRepeat, setIsYoutubeRepeat] = useState(false);
  const [youtubePlayer, setYoutubePlayer] = useState<any>(null);

  // Active Service calculation
  const activeService = useMemo(() => {
    return services.find(s => s.id === activeServiceId) || null;
  }, [services, activeServiceId]);

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim() || !newDate) return;
    createService(newName.trim(), newDate);
    setIsCreating(false);
    setNewName('');
    setNewDate('');
  };

  const handleUpdateNotes = (notes: string) => {
    if (!activeService) return;
    updateService(activeService.id, activeService.name, activeService.date, notes);
  };

  const handleUpdateDetails = (name: string, date: string) => {
    if (!activeService) return;
    updateService(activeService.id, name, date, activeService.notes);
  };

  const handleDelete = (id: string) => {
    if (window.confirm('Tem a certeza de que deseja eliminar este culto?')) {
      if (activeServiceId === id) {
        setActiveServiceId(null);
      }
      deleteService(id);
    }
  };

  const handleMoveSong = (index: number, direction: 'up' | 'down') => {
    if (!activeService) return;
    const targetIdx = direction === 'up' ? index - 1 : index + 1;

    if (targetIdx < 0 || targetIdx >= activeService.songIds.length) return;

    reorderSongsInService(activeService.id, index, targetIdx);
  };

  const handleDragStart = (index: number, e: React.DragEvent) => {
    setDraggedIdx(index);
    if (e.dataTransfer) {
      e.dataTransfer.effectAllowed = 'move';
    }
  };

  const handleDragOver = (index: number, e: React.DragEvent) => {
    e.preventDefault();
    if (draggedIdx !== null && draggedIdx !== index) {
      setDragOverIdx(index);
    }
  };

  const handleDragEnd = () => {
    setDraggedIdx(null);
    setDragOverIdx(null);
  };

  const handleDrop = (index: number, e: React.DragEvent) => {
    e.preventDefault();
    if (draggedIdx !== null && draggedIdx !== index) {
      if (!activeService) return;
      reorderSongsInService(activeService.id, draggedIdx, index);
    }
    setDraggedIdx(null);
    setDragOverIdx(null);
  };

  const handleTouchStartList = (index: number, e: React.TouchEvent) => {
    setDraggedIdx(index);
    // document.body.style.overflow = 'hidden'; // prevent scrolling while dragging? optionally
  };

  const handleTouchMoveList = (e: React.TouchEvent) => {
    if (draggedIdx === null) return;
    const touch = e.touches[0];
    const el = document.elementFromPoint(touch.clientX, touch.clientY);
    const item = el?.closest('[data-drag-index]');
    if (item) {
      const idx = parseInt(item.getAttribute('data-drag-index') || '-1', 10);
      if (idx >= 0 && idx !== draggedIdx && idx !== dragOverIdx) {
        setDragOverIdx(idx);
      }
    }
  };

  const handleTouchEndList = (e: React.TouchEvent) => {
    if (draggedIdx !== null && dragOverIdx !== null && draggedIdx !== dragOverIdx) {
      if (activeService) {
        reorderSongsInService(activeService.id, draggedIdx, dragOverIdx);
      }
    }
    setDraggedIdx(null);
    setDragOverIdx(null);
    // document.body.style.overflow = '';
  };

  // Find actual Song details for IDs in the active service, flagging missing files
  const serviceSongs = useMemo(() => {
    if (!activeService) return [];
    return activeService.songIds.map(id => {
      const found = songs.find(s => s.id === id);
      if (found) {
        return { ...found, isMissing: false };
      }
      return {
        id,
        title: 'Cântico em falta',
        artist: 'Ficheiro não sincronizado ou apagado',
        songNumber: '',
        content: '',
        folder: '',
        fileName: '',
        updatedAt: 0,
        isMissing: true
      };
    });
  }, [activeService, songs]);

  // Filter list of songs that can be added or replaced
  const addableSongsFiltered = useMemo(() => {
    if (!activeService) return [];
    return songs.filter(song => {
      const matchQuery = songSearchQuery === '' ||
        song.title.toLowerCase().includes(songSearchQuery.toLowerCase()) ||
        song.artist?.toLowerCase().includes(songSearchQuery.toLowerCase());
      return matchQuery;
    });
  }, [songs, songSearchQuery, activeService]);

  const computedFontSize = baseFontSize + localFontOffset;

  const handleTranspose = (amount: number) => {
    setTransposeVal(prev => {
      let next = prev + amount;
      if (next > 11) next -= 12;
      if (next < -12) next += 12;
      return next;
    });
  };

  // Touch Swipe navigation in special song viewer
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);

  const activeViewerSong = useMemo(() => {
    if (!activeService || activeServiceSongIndex === null) return null;
    const songId = activeService.songIds[activeServiceSongIndex];
    return songs.find(s => s.id === songId) || null;
  }, [activeService, activeServiceSongIndex, songs]);

  const activeViewerAst = useMemo(() => {
    if (!activeViewerSong) return null;
    return parseChordPro(activeViewerSong.content);
  }, [activeViewerSong?.content]);

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
  }, [activeServiceSongIndex, keepScreenAwake]);

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
    const tempo = activeViewerAst?.metadata.tempo ? parseInt(activeViewerAst.metadata.tempo, 10) : 80;
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

      if (container && activeViewerAst) {
        const sectionElems = container.querySelectorAll('[data-section-index]');
        const containerRect = container.getBoundingClientRect();
        // Focus area is in the upper third of the viewport
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
          const currentSection = activeViewerAst.sections[activeIndex];
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
  }, [isScrolling, slowDownOnRepeat, activeViewerAst]);

  // Reset scroll & state when song changes in service
  useEffect(() => {
    setIsScrolling(false);
    setActiveSectionIndex(null);
    setIsSlowedDown(false);
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = 0;
    }
  }, [activeServiceSongIndex]);

  const uniqueChords = useMemo(() => {
    if (!activeViewerAst) return [];
    const list: string[] = [];
    activeViewerAst.sections.forEach(section => {
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
  }, [activeViewerAst]);

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchStart(e.targetTouches[0].clientX);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const handleTouchEnd = () => {
    if (!touchStart || !touchEnd || !activeService) return;
    const distance = touchStart - touchEnd;
    const minDistance = 75;

    if (distance > minDistance && activeServiceSongIndex !== null && activeServiceSongIndex < activeService.songIds.length - 1) {
      setActiveServiceSongIndex(prev => prev! + 1);
      setTransposeVal(0);
    } else if (distance < -minDistance && activeServiceSongIndex !== null && activeServiceSongIndex > 0) {
      setActiveServiceSongIndex(prev => prev! - 1);
      setTransposeVal(0);
    }

    setTouchStart(null);
    setTouchEnd(null);
  };

  // VIEW MODE 3: SPECIAL SONG VIEWER (Full Screen setlist swipe reader inside the tab)
  if (activeService && activeServiceSongIndex !== null) {
    const songId = activeService.songIds[activeServiceSongIndex];
    
    if (!activeViewerSong || !activeViewerAst) {
      return (
        <div className="flex-1 flex flex-col items-center justify-center p-8 text-center bg-m3-bg dark:bg-m3-dark-bg h-full select-none">
          <HelpCircle className="w-12 h-12 text-red-500 mb-4 animate-pulse" />
          <h3 className="text-sm font-black text-red-600 uppercase tracking-wider mb-1">Cântico em Falta</h3>
          <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary max-w-sm leading-normal">
            O ficheiro referenciado para esta posição ({songId}) não existe ou foi excluído da biblioteca.
          </p>
          <div className="flex items-center gap-2 mt-5">
            <button 
              onClick={() => {
                setIsReplacingIndex(activeServiceSongIndex);
                setIsAddingSong(true);
              }}
              className="bg-m3-primary text-white text-xs font-black px-4 py-2.5 rounded-full transition-all hover:opacity-95"
            >
              Reassociar / Substituir
            </button>
            <button 
              onClick={() => setActiveServiceSongIndex(null)}
              className="bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary text-xs font-black px-4 py-2.5 rounded-full border border-m3-border/30 hover:bg-m3-hover"
            >
              Voltar ao Plano do Culto
            </button>
          </div>
        </div>
      );
    }

    const currentKey = activeViewerAst.metadata.key ? (transposeVal === 0 ? activeViewerAst.metadata.key : transposeChord(activeViewerAst.metadata.key, transposeVal)) : 'G';
    const currentSong = activeViewerSong;
    const ast = activeViewerAst;

    return (
      <div 
        className="flex-1 flex flex-col h-full bg-m3-bg dark:bg-m3-dark-bg overflow-hidden relative select-none"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        {/* Special Viewer Top Navbar */}
        <div className="h-16 px-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0 select-none z-10">
          <button
            onClick={() => {
              setActiveServiceSongIndex(null);
              setTransposeVal(0);
              setLocalFontOffset(0);
              setShowYoutubePlayer(false);
              setIsPlayingYoutube(false);
            }}
            className="flex items-center gap-1 text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-primary dark:hover:text-m3-dark-primary font-medium"
          >
            <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
            <span className="text-sm">Plano</span>
          </button>

          <div className="flex items-center gap-1.5">
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
              onClick={() => onSelectSong(currentSong.id)}
              className="p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors text-m3-secondary dark:text-m3-dark-secondary"
              title="Editar Cântico"
            >
              <Edit2 className="w-4.5 h-4.5 text-m3-primary dark:text-m3-dark-primary" />
            </button>

            <button
              onClick={() => setShowControls(!showControls)}
              className={`p-2.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${showControls ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text border border-m3-border/30' : 'text-m3-secondary dark:text-m3-dark-secondary'}`}
              title="Ajustar Tom e Tamanho"
            >
              <SlidersHorizontal className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
            </button>
          </div>
        </div>

        {/* Quick Settings Dropdown */}
        {showControls && (
          <div className="absolute right-4 top-16 w-64 bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-2xl shadow-xl z-30 p-4 space-y-4 select-none animate-in fade-in zoom-in-95 duration-100">
            <div className="border-b border-m3-border/30 dark:border-m3-dark-border/30 pb-2 flex items-center justify-between">
              <span className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider">Ajustes Rápidos</span>
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

            {/* Show/Hide Diagrams & Instrument Select (Only visible when chords are enabled) */}
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

                {/* Instrument Select */}
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
                  onClick={() => setLocalFontOffset(prev => Math.max(-4, prev - 1))}
                  className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
                >
                  <Minus className="w-3.5 h-3.5" />
                </button>
                <span className="text-[10px] font-mono font-black text-m3-text dark:text-m3-dark-text min-w-6 text-center">
                  {computedFontSize}px
                </span>
                <button
                  onClick={() => setLocalFontOffset(prev => Math.min(8, prev + 1))}
                  className="w-7 h-7 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover flex items-center justify-center text-xs font-black text-m3-secondary border border-m3-border/20 active:scale-90 transition-transform"
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

        {/* Scrollable Song Lyrics sheet */}
        <div 
          ref={scrollContainerRef}
          className="flex-1 overflow-y-auto px-6 py-8 space-y-6 no-scrollbar relative"
        >
          
          {/* Header block details */}
          <div className="border-b border-m3-border/30 dark:border-m3-dark-border/30 pb-4 select-none">
            <div className="flex items-start justify-between gap-4 flex-wrap">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-m3-text dark:text-m3-dark-text">
                  {ast.metadata.title}
                </h2>
                {ast.metadata.artist && (
                  <div className="flex items-center gap-1 text-xs text-m3-secondary mt-1 font-bold">
                    <User className="w-3.5 h-3.5 text-m3-primary" />
                    <span>Por: {ast.metadata.artist}</span>
                  </div>
                )}
              </div>

              <div className="flex flex-wrap items-center gap-1.5 justify-end">
                {ast.metadata.songNumber && (
                  <span className="text-[10px] font-bold bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary px-2 py-1 rounded-lg border border-m3-border/30">
                    Nº {ast.metadata.songNumber}
                  </span>
                )}
                {ast.metadata.key && (
                  <span className="text-[10px] font-bold bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary px-2.5 py-1 rounded-lg border border-m3-border/30">
                    Tom: {currentKey}
                  </span>
                )}
                {ast.metadata.tempo && (
                  <span className="text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary px-2 py-1 rounded-lg font-mono font-bold">
                    ♩ {ast.metadata.tempo} BPM
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Service Song Specific Notes */}
          {activeService.songNotes?.[activeServiceSongIndex.toString()] && (
            <div className="bg-amber-50 dark:bg-amber-950/20 text-amber-800 dark:text-amber-200 border border-amber-200/50 dark:border-amber-900/40 rounded-xl p-3 text-xs italic select-none">
              <span className="font-bold not-italic text-amber-600 dark:text-amber-400 mr-1">Notas:</span>
              {activeService.songNotes[activeServiceSongIndex.toString()]}
            </div>
          )}

          {/* Scrollable Chord Visualizer Row */}
          <ChordRoll 
            uniqueChords={uniqueChords}
            transposeVal={transposeVal}
            onChordClick={(chord) => setSelectedChord(chord)}
          />

          {/* AST Section Render loop */}
          <div className="space-y-6 select-text" style={{ fontSize: `${computedFontSize}px` }}>
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
                        <LineRenderer key={lineIdx} line={line} showChords={showChords} transpose={transposeVal} onChordClick={(chord) => setSelectedChord(chord)} />
                      ))}
                    </div>
                  </div>
                );
              }

              if (section.type === 'tab') {
                return (
                  <div key={secIdx} data-section-index={secIdx} className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-4 rounded-xl border border-m3-border dark:border-m3-dark-border my-4 select-text">
                    <div className="text-[10px] font-bold text-m3-secondary uppercase tracking-wider mb-2 select-none">
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
                  <div key={secIdx} data-section-index={secIdx} className="italic text-xs text-m3-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar px-4 py-2 rounded-xl border-l-2 border-m3-border dark:border-m3-dark-border my-2 select-none">
                    {section.lines.map(l => l.text).join(', ')}
                  </div>
                );
              }

              const verseLabel = section.label || `Verso ${secIdx + 1}`;
              return (
                <div key={secIdx} data-section-index={secIdx} className="relative pl-6 border-l border-m3-border/30 dark:border-m3-dark-border/30 py-1.5">
                  <div className="absolute -left-1 top-4 text-[9px] font-bold text-m3-primary -rotate-90 origin-left tracking-wider uppercase select-none whitespace-nowrap opacity-80">
                    {verseLabel}
                  </div>
                  <div className="space-y-4">
                    {section.lines.map((line, lineIdx) => (
                      <LineRenderer key={lineIdx} line={line} showChords={showChords} transpose={transposeVal} onChordClick={(chord) => setSelectedChord(chord)} />
                    ))}
                  </div>
                </div>
              );
            })}
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
              onClick={() => {
                if (activeServiceSongIndex > 0) {
                  setActiveServiceSongIndex(prev => prev! - 1);
                  setTransposeVal(0); // reset transposition for next song
                  setShowYoutubePlayer(false);
                  setIsPlayingYoutube(false);
                }
              }}
              disabled={activeServiceSongIndex === 0}
              className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                activeServiceSongIndex > 0 
                  ? 'bg-m3-card dark:bg-m3-dark-card border-m3-border dark:border-m3-dark-border text-m3-primary dark:text-m3-dark-primary hover:bg-m3-hover dark:hover:bg-m3-dark-hover' 
                  : 'bg-m3-border/20 dark:bg-m3-dark-border/10 text-m3-secondary/40 border-transparent cursor-not-allowed'
              }`}
              title="Cântico Anterior"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>

            <span className="bg-m3-card/90 dark:bg-m3-dark-card/90 border border-m3-border dark:border-m3-dark-border backdrop-blur-md text-[10px] font-bold font-mono px-3 py-2 rounded-full text-m3-secondary dark:text-m3-dark-secondary">
              {`${activeServiceSongIndex + 1} / ${activeService.songIds.length}`}
            </span>

            <button
              onClick={() => {
                if (activeServiceSongIndex < activeService.songIds.length - 1) {
                  setActiveServiceSongIndex(prev => prev! + 1);
                  setTransposeVal(0); // reset transposition for next song
                  setShowYoutubePlayer(false);
                  setIsPlayingYoutube(false);
                }
              }}
              disabled={activeServiceSongIndex === activeService.songIds.length - 1}
              className={`p-3 rounded-full shadow-lg border transition-all active:scale-95 flex items-center justify-center ${
                activeServiceSongIndex < activeService.songIds.length - 1
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
                        O diagrama para {instrument === 'guitar' ? 'Guitarra' : 'Piano'} não pôde ser calculated.
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

            </div>
          </div>
        )}
      </div>
    );
  }

  // VIEW MODE 2: ACTIVE SERVICE DETAILS PANEL (Aligned view on click, replaces lists)
  if (activeService) {
    return (
      <div className="flex-1 flex flex-col h-full overflow-hidden bg-m3-bg dark:bg-m3-dark-bg select-none">
        
        {/* Top bar with back navigation and inline editor details */}
        <div className="p-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border shrink-0 flex items-center gap-3">
          <button
            onClick={() => {
              setActiveServiceId(null);
              setActiveServiceSongIndex(null);
            }}
            className="p-1.5 rounded-full hover:bg-m3-hover text-m3-secondary hover:text-m3-primary transition-colors shrink-0"
            title="Voltar aos Cultos"
          >
            <ArrowLeft className="w-5 h-5 text-m3-primary" />
          </button>

          <div className="min-w-0 flex-1">
            <input
              type="text"
              value={activeService.name}
              onChange={(e) => handleUpdateDetails(e.target.value, activeService.date)}
              className="text-sm font-black bg-transparent border-b border-transparent hover:border-m3-border focus:border-m3-primary focus:outline-none text-m3-text dark:text-m3-dark-text w-full truncate"
              placeholder="Nome do Culto"
            />
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-[9px] text-m3-secondary uppercase font-bold tracking-wider">Data:</span>
              <input
                type="date"
                value={activeService.date}
                onChange={(e) => handleUpdateDetails(activeService.name, e.target.value)}
                className="text-[10px] font-mono bg-transparent border-none text-m3-secondary dark:text-m3-dark-secondary focus:outline-none font-bold"
              />
            </div>
          </div>
          
          <button
            onClick={() => setIsExportingPDF(true)}
            className="p-2 rounded-full hover:bg-m3-hover text-m3-primary dark:text-m3-dark-primary transition-colors shrink-0"
            title="Exportar Pauta para PDF"
          >
            <Printer className="w-4 h-4" />
          </button>

          <button
            onClick={() => handleDelete(activeService.id)}
            className="p-2 rounded-full hover:bg-red-50 hover:text-red-600 text-red-500 transition-colors shrink-0"
            title="Eliminar Culto"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>

        {/* Setlist & notes scrollable viewport */}
        <div className="flex-1 overflow-y-auto p-4 pb-24 space-y-4 no-scrollbar">
          
          {/* Ordered songs sector */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider">
                Plano do Culto ({serviceSongs.length})
              </span>
              <button
                onClick={() => {
                  setIsReplacingIndex(null);
                  setIsAddingSong(true);
                }}
                id="btn_add_song_to_svc_open"
                className="text-[11px] font-black text-m3-primary dark:text-m3-dark-primary hover:underline flex items-center gap-1"
              >
                + Adicionar Cântico
              </button>
            </div>

            {serviceSongs.length === 0 ? (
              <div className="p-6 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-2xl border border-dashed border-m3-border dark:border-m3-dark-border text-center">
                <BookOpen className="w-8 h-8 text-m3-secondary mx-auto mb-2 opacity-50" />
                <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary">Nenhum cântico selecionado para este culto.</p>
                <button
                  onClick={() => {
                     setIsReplacingIndex(null);
                     setIsAddingSong(true);
                  }}
                  className="mt-3 text-xs font-black bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text px-4 py-2 rounded-full hover:bg-m3-hover"
                >
                  Pesquisar e Adicionar
                </button>
              </div>
            ) : (
              <div className="space-y-2">
                {serviceSongs.map((song, index) => {
                  if (song.isMissing) {
                    return (
                      <div
                        key={`${song.id}-${index}`}
                        data-drag-index={index}
                        draggable
                        onDragStart={(e) => handleDragStart(index, e)}
                        onDragOver={(e) => handleDragOver(index, e)}
                        onDragEnd={handleDragEnd}
                        onDrop={(e) => handleDrop(index, e)}
                        onTouchStart={(e) => handleTouchStartList(index, e)}
                        onTouchMove={handleTouchMoveList}
                        onTouchEnd={handleTouchEndList}
                        className={`bg-red-50/40 dark:bg-red-950/10 border p-3.5 rounded-xl flex flex-col gap-2 shadow-2xs transition-all duration-200 ${
                          draggedIdx === index ? 'opacity-30 border-dashed border-red-500/50' : ''
                        } ${
                          dragOverIdx === index ? 'border-2 border-red-500 bg-red-100/50 scale-[1.01]' : 'border-red-200 dark:border-red-900/40'
                        }`}
                      >
                        <div className="flex items-start justify-between gap-3">
                           <div className="flex items-center gap-1.5">
                            <div className="w-5 h-5 rounded-md bg-red-100 dark:bg-red-950 text-red-600 dark:text-red-400 flex items-center justify-center text-[10px] font-bold select-none">
                              {index + 1}
                            </div>
                            <div>
                              <h4 className="text-xs font-black text-red-600 dark:text-red-400 uppercase tracking-wider flex items-center gap-1.5 select-none">
                                Cântico em Falta
                              </h4>
                              <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5 font-mono truncate max-w-xs sm:max-w-md">
                                Caminho: {song.id}
                              </p>
                            </div>
                          </div>
                          <button
                            onClick={() => removeSongFromService(activeService.id, index)}
                            className="p-1 rounded hover:bg-red-100 dark:hover:bg-red-900/30 text-red-500 hover:text-red-600 transition-colors"
                            title="Remover do Plano do Culto"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                        
                        <p className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary italic leading-relaxed pl-6 select-none">
                          Este cântico não foi encontrado. Pode ter sido apagado, renomeado ou movido durante a sincronização.
                        </p>

                        <div className="flex items-center gap-2 pl-6 pt-1 select-none">
                          <button
                            onClick={() => {
                              setIsReplacingIndex(index);
                              setIsAddingSong(true);
                            }}
                            className="px-3 py-1.5 bg-red-100 dark:bg-red-950 text-red-700 dark:text-red-300 rounded-lg text-[10px] font-bold hover:bg-red-200 dark:hover:bg-red-900 transition-all flex items-center gap-1"
                          >
                            <Search className="w-3 h-3" />
                            Localizar / Substituir
                          </button>
                          <button
                            onClick={() => removeSongFromService(activeService.id, index)}
                            className="px-3 py-1.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border/30 rounded-lg text-[10px] font-bold hover:bg-m3-hover text-m3-secondary transition-all"
                          >
                            Remover do Culto
                          </button>
                        </div>
                      </div>
                    );
                  }

                  return (
                    <div
                      key={`${song.id}-${index}`}
                      data-drag-index={index}
                      draggable
                      onDragStart={(e) => handleDragStart(index, e)}
                      onDragOver={(e) => handleDragOver(index, e)}
                      onDragEnd={handleDragEnd}
                      onDrop={(e) => handleDrop(index, e)}
                      onTouchStart={(e) => handleTouchStartList(index, e)}
                      onTouchMove={handleTouchMoveList}
                      onTouchEnd={handleTouchEndList}
                      className={`bg-m3-card dark:bg-m3-dark-card p-3 rounded-xl border flex flex-col gap-2.5 shadow-2xs transition-all duration-200 ${
                        draggedIdx === index ? 'opacity-30 border-dashed border-m3-primary/50' : ''
                      } ${
                        dragOverIdx === index ? 'border-2 border-m3-primary dark:border-m3-dark-primary bg-m3-primary-light/20 scale-[1.01]' : 'border-m3-border/30 dark:border-m3-dark-border/30 hover:border-m3-primary/30'
                      }`}
                    >
                      {/* Main Song Info Header */}
                      <div className="flex items-center justify-between gap-3">
                        <div className="flex items-center gap-1 shrink-0 select-none">
                          <GripVertical className="w-3.5 h-3.5 text-m3-secondary/50 dark:text-m3-dark-secondary/50 hidden md:block" />
                          <div className="w-6 h-6 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary dark:text-m3-dark-secondary flex items-center justify-center text-[11px] font-bold">
                            {index + 1}
                          </div>
                        </div>

                        {/* Song click starts the Special Swipe Song Viewer */}
                        <div
                          onClick={() => {
                            setActiveServiceSongIndex(index);
                            setTransposeVal(0);
                            setLocalFontOffset(0);
                          }}
                          className="flex-1 min-w-0 cursor-pointer hover:underline"
                        >
                          <h4 className="text-xs font-bold text-m3-text dark:text-m3-dark-text truncate flex items-center">
                            {song.title} 
                            {song.songNumber && <span className="text-m3-primary font-mono text-[9px] ml-1.5 px-1 bg-m3-primary-light dark:bg-m3-dark-primary-light rounded border border-m3-primary/20">#{song.songNumber}</span>}
                          </h4>
                          <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary truncate mt-0.5">{song.artist || 'Sem autor'}</p>
                        </div>

                        {/* Shifting orders */}
                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            onClick={(e) => { e.stopPropagation(); handleMoveSong(index, 'up'); }}
                            disabled={index === 0}
                            className="p-1.5 md:p-1 rounded bg-m3-sidebar hover:bg-m3-hover dark:bg-m3-dark-sidebar text-m3-secondary dark:text-m3-dark-secondary disabled:opacity-30 active:scale-95 transition-transform"
                          >
                            <ChevronUp className="w-4 h-4 md:w-3.5 md:h-3.5" />
                          </button>
                          <button
                            onClick={(e) => { e.stopPropagation(); handleMoveSong(index, 'down'); }}
                            disabled={index === serviceSongs.length - 1}
                            className="p-1.5 md:p-1 rounded bg-m3-sidebar hover:bg-m3-hover dark:bg-m3-dark-sidebar text-m3-secondary dark:text-m3-dark-secondary disabled:opacity-30 active:scale-95 transition-transform"
                          >
                            <ChevronDown className="w-4 h-4 md:w-3.5 md:h-3.5" />
                          </button>
                          <button
                            onClick={(e) => { e.stopPropagation(); removeSongFromService(activeService.id, index); }}
                            className="p-1.5 md:p-1 rounded hover:bg-red-50 dark:hover:bg-red-950/40 text-red-500 hover:text-red-600 transition-all ml-1"
                          >
                            <Trash2 className="w-4 h-4 md:w-3.5 md:h-3.5" />
                          </button>
                        </div>
                      </div>

                      {/* Service Song Note segment */}
                      <div className="border-t border-m3-border/10 dark:border-m3-dark-border/10 pt-2 flex flex-col gap-1.5">
                        {activeService.songNotes?.[index.toString()] ? (
                          <div className="flex items-start justify-between gap-2 bg-amber-50/40 dark:bg-amber-950/10 p-2 rounded-lg border border-amber-100/30 dark:border-amber-900/20 text-[11px]">
                            <div className="flex-1 text-m3-text dark:text-m3-dark-text italic font-medium leading-relaxed">
                              <span className="font-bold text-amber-600 dark:text-amber-400 not-italic mr-1">Nota:</span>
                              {activeService.songNotes[index.toString()]}
                            </div>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setEditingNoteIndex(index);
                                setEditingNoteText(activeService.songNotes?.[index.toString()] || '');
                              }}
                              className="text-[9px] font-black text-m3-primary dark:text-m3-dark-primary hover:underline"
                            >
                              Editar
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setEditingNoteIndex(index);
                              setEditingNoteText('');
                            }}
                            className="self-start text-[9px] font-bold text-m3-primary hover:underline flex items-center gap-1 opacity-75 hover:opacity-100"
                          >
                            + Adicionar nota para este cântico
                          </button>
                        )}

                        {editingNoteIndex === index && (
                          <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-2 rounded-lg border border-m3-border/30 flex flex-col gap-2 mt-1">
                            <textarea
                              value={editingNoteText}
                              onChange={(e) => setEditingNoteText(e.target.value)}
                              placeholder="Ex: Solo de piano na introdução, transição suave..."
                              rows={2}
                              className="w-full p-2 text-xs bg-white dark:bg-zinc-800 border border-m3-border/40 rounded-md focus:outline-none focus:ring-1 focus:ring-m3-primary text-m3-text dark:text-m3-dark-text"
                            />
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() => setEditingNoteIndex(null)}
                                className="px-2.5 py-1 text-[9px] font-bold bg-m3-hover rounded-md text-m3-secondary"
                              >
                                Cancelar
                              </button>
                              <button
                                onClick={() => {
                                  updateSongNotesInService(activeService.id, index, editingNoteText);
                                  setEditingNoteIndex(null);
                                }}
                                className="px-2.5 py-1 text-[9px] font-bold bg-m3-primary text-white rounded-md hover:opacity-95"
                              >
                                Guardar
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Transition & sermon Rehearsal Notes */}
          <div className="flex flex-col gap-2 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-4">
            <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1">
              <FileText className="w-3.5 h-3.5 text-m3-primary" />
              Notas de Transição e Ensaios
            </span>
            <textarea
              value={activeService.notes || ''}
              onChange={(e) => handleUpdateNotes(e.target.value)}
              placeholder="Escreva notas gerais sobre orações, tons de transição, tópicos de sermão ou avisos importantes..."
              className="w-full min-h-[140px] p-3 bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-2xl text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary/30 text-m3-text dark:text-m3-dark-text"
              rows={4}
            />
          </div>

        </div>

        {/* MODAL: Export Service to PDF */}
        {isExportingPDF && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
            <div className="bg-m3-card dark:bg-m3-dark-card w-full max-w-md rounded-3xl p-5 border border-m3-border dark:border-m3-dark-border flex flex-col shadow-xl animate-scale-up select-none">
              <div className="flex justify-between items-center pb-3 border-b border-m3-border/30 dark:border-m3-dark-border/30 mb-4">
                <h4 className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider flex items-center gap-1.5">
                  <Printer className="w-4 h-4 text-m3-primary" />
                  Exportar Pauta para PDF
                </h4>
                <button 
                  onClick={() => setIsExportingPDF(false)} 
                  className="text-m3-secondary hover:text-m3-text p-1 hover:bg-m3-hover dark:hover:bg-m3-dark-hover rounded-full transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="space-y-4 text-xs">
                <p className="text-m3-secondary dark:text-m3-dark-secondary">
                  Selecione o formato pretendido para exportar a pauta do culto <span className="font-bold text-m3-text dark:text-m3-dark-text">"{activeService.name}"</span>:
                </p>

                <div className="space-y-3">
                  {/* Option 1: Just alignment */}
                  <div 
                    onClick={() => setPdfIncludeChords(false)}
                    className={`flex items-start gap-3 p-3 rounded-2xl border cursor-pointer transition-all ${
                      !pdfIncludeChords 
                        ? 'border-m3-primary bg-m3-primary-light/30 dark:bg-m3-dark-primary-light/10' 
                        : 'border-m3-border/50 dark:border-m3-dark-border/40 hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                    }`}
                  >
                    <input 
                      type="radio" 
                      name="pdf_format" 
                      checked={!pdfIncludeChords}
                      onChange={() => setPdfIncludeChords(false)}
                      className="mt-0.5 accent-m3-primary"
                    />
                    <div>
                      <span className="font-bold text-m3-text dark:text-m3-dark-text block">Alinhamento do Culto (Resumo)</span>
                      <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block mt-0.5">
                        Gera um documento compacto de 1 página ideal para consulta rápida de alinhamento, tons originais/transpostos, andamentos BPM e notas específicas de arranjo da banda.
                      </span>
                    </div>
                  </div>

                  {/* Option 2: Full chord sheets */}
                  <div 
                    onClick={() => setPdfIncludeChords(true)}
                    className={`flex items-start gap-3 p-3 rounded-2xl border cursor-pointer transition-all ${
                      pdfIncludeChords 
                        ? 'border-m3-primary bg-m3-primary-light/30 dark:bg-m3-dark-primary-light/10' 
                        : 'border-m3-border/50 dark:border-m3-dark-border/40 hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                    }`}
                  >
                    <input 
                      type="radio" 
                      name="pdf_format" 
                      checked={pdfIncludeChords}
                      onChange={() => setPdfIncludeChords(true)}
                      className="mt-0.5 accent-m3-primary"
                    />
                    <div>
                      <span className="font-bold text-m3-text dark:text-m3-dark-text block">Cancioneiro Completo (Com Cifras)</span>
                      <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block mt-0.5">
                        Gera a folha de alinhamento na primeira página e anexa a folha de letras com cifras detalhadas para cada cântico nas páginas seguintes, com tons transpostos e notas individuais.
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2.5 mt-5 pt-3 border-t border-m3-border/30 dark:border-m3-dark-border/30">
                <button
                  onClick={() => setIsExportingPDF(false)}
                  className="px-4 py-2 text-xs font-black text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover rounded-full transition-colors border border-m3-border/40 dark:border-m3-dark-border/40"
                >
                  Cancelar
                </button>
                <button
                  onClick={async () => {
                    const offsets: Record<string, number> = {};
                    if (activeServiceSongIndex !== null && activeViewerSong) {
                      offsets[activeViewerSong.id] = transposeVal;
                    }
                    await exportServiceToPDF(activeService, serviceSongs, { 
                      includeChords: pdfIncludeChords,
                      transposeOffsets: offsets
                    });
                    setIsExportingPDF(false);
                  }}
                  className="px-5 py-2 text-xs font-black text-white bg-m3-primary rounded-full hover:opacity-90 transition-all flex items-center gap-1.5"
                >
                  <FileDown className="w-3.5 h-3.5" />
                  Gerar PDF
                </button>
              </div>
            </div>
          </div>
        )}

        {/* MODAL: Search & Add / Replace song popover */}
        {isAddingSong && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in">
            <div className="bg-m3-card dark:bg-m3-dark-card w-full max-w-md rounded-3xl p-5 border border-m3-border dark:border-m3-dark-border flex flex-col max-h-[80vh] shadow-xl animate-scale-up">
              <div className="flex justify-between items-center pb-3 border-b border-m3-border/30 dark:border-m3-dark-border/30 mb-3">
                <h4 className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wider">
                  {isReplacingIndex !== null ? 'Reassociar / Substituir Cântico' : 'Pesquisar Cânticos'}
                </h4>
                <button 
                  onClick={() => { 
                    setIsAddingSong(false); 
                    setIsReplacingIndex(null);
                    setSongSearchQuery(''); 
                  }} 
                  className="text-m3-secondary hover:text-m3-text p-1 hover:bg-m3-hover rounded-full"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Selector Search */}
              <div className="relative mb-3 shrink-0">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-m3-secondary" />
                <input
                  type="text"
                  placeholder="Filtrar por título ou autor..."
                  value={songSearchQuery}
                  onChange={(e) => setSongSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
                />
              </div>

              {/* Scroll list */}
              <div className="flex-1 overflow-y-auto space-y-1.5 pr-1 no-scrollbar">
                {addableSongsFiltered.length === 0 ? (
                  <div className="p-8 text-center text-xs text-m3-secondary dark:text-m3-dark-secondary">
                    Nenhum cântico encontrado na biblioteca.
                  </div>
                ) : (
                  addableSongsFiltered.map(song => {
                    const alreadyInService = activeService.songIds.includes(song.id);
                    return (
                      <div
                        key={song.id}
                        className="p-3 rounded-xl border border-m3-border/30 dark:border-m3-dark-border/30 flex items-center justify-between gap-3 bg-m3-sidebar dark:bg-m3-dark-sidebar hover:border-m3-primary/30 transition-all"
                      >
                        <div className="min-w-0">
                          <h5 className="text-xs font-bold text-m3-text dark:text-m3-dark-text truncate">{song.title}</h5>
                          <p className="text-[10px] text-m3-secondary truncate font-medium mt-0.5">{song.artist || 'Sem autor'}</p>
                        </div>

                        <button
                          onClick={() => {
                            if (isReplacingIndex !== null) {
                              replaceSongInService(activeService.id, isReplacingIndex, song.id);
                            } else {
                              addSongToService(activeService.id, song.id);
                            }
                            setIsAddingSong(false);
                            setIsReplacingIndex(null);
                            setSongSearchQuery('');
                          }}
                          className="text-[10px] font-black px-3.5 py-1.5 rounded-full bg-m3-primary text-white hover:opacity-90 shadow-xs transition-all"
                        >
                          {isReplacingIndex !== null ? 'Selecionar' : (alreadyInService ? 'Adicionar Novo' : 'Adicionar')}
                        </button>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // VIEW MODE 1: SERVICES DIRECTORY LIST (Default list screen)
  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-m3-bg dark:bg-m3-dark-bg select-none">
      
      {/* Directory Title / Search bar */}
      <div className="p-4 bg-m3-bg dark:bg-m3-dark-bg border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0">
        <div>
          <span className="text-xs font-black text-m3-text dark:text-m3-dark-text uppercase tracking-wide flex items-center gap-1.5">
            <CalendarRange className="w-4.5 h-4.5 text-m3-primary" />
            Cultos Planeados ({services.length})
          </span>
          <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5">Gerencie os planos e notas dos cultos de música.</p>
        </div>
        <button
          onClick={() => setIsCreating(true)}
          id="btn_create_service_open"
          className="px-4 py-2 text-xs font-black bg-m3-primary text-white hover:opacity-90 rounded-full transition-all flex items-center gap-1 shadow-xs"
          title="Novo Planeamento"
        >
          <Plus className="w-4 h-4" />
          <span>Criar</span>
        </button>
      </div>

      {/* Main Grid/Scroll List of planned services */}
      <div className="flex-1 overflow-y-auto p-4 pb-24 no-scrollbar">
        {services.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center p-8 py-16">
            <CalendarRange className="w-12 h-12 text-m3-secondary dark:text-m3-dark-secondary mb-2 opacity-50" />
            <h3 className="text-sm font-bold text-m3-text dark:text-m3-dark-text">Nenhum culto planeado</h3>
            <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary mt-1">Crie um novo planeamento clicando no botão de Criar acima!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {services.map(svc => (
              <div
                key={svc.id}
                onClick={() => {
                  setActiveServiceId(svc.id);
                  setActiveServiceSongIndex(null);
                }}
                className="p-4 rounded-2xl cursor-pointer bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 hover:border-m3-primary/40 transition-all flex flex-col justify-between gap-3 shadow-2xs group relative"
              >
                <div className="min-w-0">
                  <h4 className="text-sm font-black text-m3-text dark:text-m3-dark-text truncate leading-snug group-hover:text-m3-primary transition-colors">
                     {svc.name}
                  </h4>
                  <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-mono mt-0.5 font-bold">
                    {svc.date}
                  </p>
                </div>

                <div className="flex items-center justify-between border-t border-m3-border/30 pt-3">
                  <span className="text-[10.5px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                    {svc.songIds.length === 0 ? 'Sem cânticos' : `${svc.songIds.length} cânticos no plano do culto`}
                  </span>
                  
                  <span className="text-[10px] font-black text-m3-primary group-hover:translate-x-0.5 transition-transform">
                    Entrar →
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* MODAL: Create service planning */}
      {isCreating && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <form onSubmit={handleCreate} className="bg-m3-card dark:bg-m3-dark-card w-full max-w-sm rounded-3xl p-6 border border-m3-border dark:border-m3-dark-border space-y-4 shadow-xl animate-scale-up">
            <h4 className="text-sm font-black text-m3-text dark:text-m3-dark-text">
              Novo Planeamento de Culto
            </h4>

            <div className="space-y-3">
              <div>
                <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold uppercase tracking-wider">Nome do Culto</label>
                <input
                  type="text"
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="Ex: Culto de Jovens"
                  className="w-full px-3 py-2 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl focus:outline-none focus:ring-1 focus:ring-m3-primary/30 text-m3-text"
                />
              </div>
              <div>
                <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold uppercase tracking-wider">Data</label>
                <input
                  type="date"
                  required
                  value={newDate}
                  onChange={(e) => setNewDate(e.target.value)}
                  className="w-full px-3 py-2 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl focus:outline-none focus:ring-1 focus:ring-m3-primary/30 text-m3-text font-mono font-bold"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setIsCreating(false)}
                className="px-4 py-2 text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover rounded-full transition-colors"
              >
                Cancelar
              </button>
              <button
                type="submit"
                className="px-5 py-2 text-xs font-black bg-m3-primary text-white rounded-full hover:opacity-90 transition-all shadow-xs"
              >
                Criar
              </button>
            </div>
          </form>
        </div>
      )}

    </div>
  );
}

/**
 * Sub-component to render a line of text, splitting into segmented block components
 */
function LineRenderer({ line, showChords, transpose, onChordClick }: { line: any; showChords: boolean; transpose: number; onChordClick?: (chord: string) => void; key?: any }) {
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
                onClick={() => onChordClick?.(transposed)}
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
