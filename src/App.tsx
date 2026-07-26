/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useEffect, useRef, useState } from 'react';
import { Music, CalendarRange, Settings, RefreshCw, Bookmark, AlertTriangle } from 'lucide-react';
import { useAppStore } from './store/appStore';

import SongBrowser from './components/SongBrowser';
import SongView from './components/SongView';
import SongEditor from './components/SongEditor';
import ServiceManager from './components/ServiceManager';
import SettingsView from './components/SettingsView';

// Pull-to-refresh tuning
const PULL_THRESHOLD = 68; // px of (resisted) drag needed to trigger a refresh
const PULL_MAX = 96; // px the indicator/content is allowed to travel
const PULL_RESISTANCE = 0.5; // finger-to-content movement ratio, like native pull-to-refresh

// Walks up from the touched element to find the nearest scrollable ancestor within
// the content boundary, so the pull gesture only engages when that ancestor is
// already scrolled to the top (otherwise a normal scroll gesture would be hijacked).
const findScrollableAncestor = (start: HTMLElement | null, boundary: HTMLElement): HTMLElement => {
  let node: HTMLElement | null = start;
  while (node && node !== boundary.parentElement) {
    const style = window.getComputedStyle(node);
    const canScrollY = (style.overflowY === 'auto' || style.overflowY === 'scroll') && node.scrollHeight > node.clientHeight;
    if (canScrollY) return node;
    if (node === boundary) break;
    node = node.parentElement;
  }
  return boundary;
};

export default function App() {
  const theme = useAppStore(state => state.theme);
  const songsLength = useAppStore(state => state.songs.length);
  const syncLibrary = useAppStore(state => state.syncLibrary);
  const syncStatus = useAppStore(state => state.syncStatus);

  const activeSongId = useAppStore(state => state.activeSongId);
  const setActiveSongId = useAppStore(state => state.setActiveSongId);
  
  const isEditing = useAppStore(state => state.isEditing);
  const setIsEditing = useAppStore(state => state.setIsEditing);

  // Active view tab state: 'songs' | 'services' | 'settings'
  const [activeTab, setActiveTab] = useState<'songs' | 'services' | 'settings'>('songs');

  // Pull-to-refresh gesture state
  const contentRef = useRef<HTMLDivElement>(null);
  const [pullDistance, setPullDistance] = useState(0);
  const [isPulling, setIsPulling] = useState(false);
  const touchStartY = useRef<number | null>(null);
  const scrollAncestorRef = useRef<HTMLElement | null>(null);

  // Automatic synchronization on startup if index is empty
  useEffect(() => {
    if (songsLength === 0) {
      syncLibrary().catch(() => {});
    }
  }, [songsLength, syncLibrary]);

  // Real-time Theme manager (Claro, Escuro, Sistema)
  useEffect(() => {
    const root = document.documentElement;
    const applyTheme = (currentTheme: 'light' | 'dark') => {
      if (currentTheme === 'dark') {
        root.classList.add('dark');
      } else {
        root.classList.remove('dark');
      }
    };

    if (theme === 'system') {
      const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      applyTheme(systemPrefersDark ? 'dark' : 'light');

      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      const handleMediaChange = (e: MediaQueryListEvent) => {
        applyTheme(e.matches ? 'dark' : 'light');
      };
      mediaQuery.addEventListener('change', handleMediaChange);
      return () => mediaQuery.removeEventListener('change', handleMediaChange);
    } else {
      applyTheme(theme);
    }
  }, [theme]);

  // Pull-to-refresh: native `onTouchMove` listeners in React are passive by default,
  // which silently blocks `preventDefault()`. Attaching the listener manually with
  // `{ passive: false }` is required to get a smooth, non-scrolling drag gesture.
  useEffect(() => {
    const boundary = contentRef.current;
    if (!boundary) return;

    const handleTouchStart = (e: TouchEvent) => {
      if (syncStatus === 'syncing' || isEditing) return;

      const scrollEl = findScrollableAncestor(e.target as HTMLElement, boundary);
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

      if (deltaY <= 0 || (scrollAncestorRef.current && scrollAncestorRef.current.scrollTop > 0)) {
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

      setPullDistance(current => {
        if (current >= PULL_THRESHOLD) {
          syncLibrary().catch(() => {});
        }
        return 0;
      });
    };

    boundary.addEventListener('touchstart', handleTouchStart, { passive: true });
    boundary.addEventListener('touchmove', handleTouchMove, { passive: false });
    boundary.addEventListener('touchend', handleTouchEnd, { passive: true });
    boundary.addEventListener('touchcancel', handleTouchEnd, { passive: true });

    return () => {
      boundary.removeEventListener('touchstart', handleTouchStart);
      boundary.removeEventListener('touchmove', handleTouchMove);
      boundary.removeEventListener('touchend', handleTouchEnd);
      boundary.removeEventListener('touchcancel', handleTouchEnd);
    };
  }, [syncStatus, isEditing, syncLibrary]);

  // Tab Header titles helper
  const getHeaderTitle = () => {
    switch (activeTab) {
      case 'songs':
        if (isEditing) return activeSongId ? 'Editar Cântico' : 'Novo Cântico';
        if (activeSongId) return 'Visualizar Cântico';
        return 'Cânticos';
      case 'services':
        return 'Cultos';
      case 'settings':
        return 'Definições';
      default:
        return 'Hosanna';
    }
  };

  // Icon corresponding to the active view
  const getHeaderIcon = () => {
    switch (activeTab) {
      case 'songs':
        return <Music className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />;
      case 'services':
        return <CalendarRange className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />;
      case 'settings':
        return <Settings className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />;
      default:
        return <Bookmark className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />;
    }
  };

  // Pull-to-refresh indicator: follows the finger while dragging, sticks near the
  // top and spins while a sync is actually in flight, and fades out otherwise.
  const indicatorActive = isPulling || syncStatus === 'syncing';
  const indicatorOffset = isPulling ? pullDistance : syncStatus === 'syncing' ? 44 : 0;
  const indicatorProgress = Math.min(1, pullDistance / PULL_THRESHOLD);
  const isSyncing = syncStatus === 'syncing';

  return (
    <div className="flex-1 flex overflow-hidden bg-m3-bg dark:bg-m3-dark-bg text-m3-text dark:text-m3-dark-text relative h-full">
      
      {/* Primary Screen Area */}
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        


        {/* Active Tab Screen Content Renderer */}
        <div ref={contentRef} className="flex-1 overflow-hidden relative touch-pan-y">
          {/* Pull-to-refresh indicator (drag down from the top to sync) */}
          <div
            className="absolute left-1/2 top-2 z-30 flex items-center justify-center w-9 h-9 rounded-full bg-m3-toolbar/95 dark:bg-m3-dark-toolbar/95 border border-m3-border/40 dark:border-m3-dark-border/40 shadow-md pointer-events-none"
            style={{
              transform: `translate(-50%, ${indicatorOffset - 40}px)`,
              opacity: indicatorActive ? (isSyncing ? 1 : indicatorProgress) : 0,
              transition: isPulling ? 'none' : 'transform 0.25s ease, opacity 0.25s ease',
            }}
          >
            {syncStatus === 'error' && !isSyncing ? (
              <AlertTriangle className="w-4 h-4 text-red-500" />
            ) : (
              <RefreshCw
                className={`w-4 h-4 text-m3-primary dark:text-m3-dark-primary ${isSyncing ? 'animate-spin' : ''}`}
                style={!isSyncing ? { transform: `rotate(${indicatorProgress * 360}deg)` } : undefined}
              />
            )}
          </div>

          <div
            style={{
              transform: `translateY(${isPulling ? pullDistance : 0}px)`,
              transition: isPulling ? 'none' : 'transform 0.25s ease',
            }}
            className="h-full"
          >
            {activeTab === 'songs' && (
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

            {activeTab === 'services' && (
              <ServiceManager
                onSelectSong={(id) => {
                  setActiveSongId(id);
                  setActiveTab('songs');
                  setIsEditing(false);
                }}
              />
            )}

            {activeTab === 'settings' && <SettingsView />}
          </div>
        </div>

        {!activeSongId && !isEditing && (
          <div className="absolute bottom-5 left-1/2 -translate-x-1/2 w-[70%] max-w-[220px] h-14 bg-m3-toolbar/90 dark:bg-m3-dark-toolbar/90 border border-m3-border/40 dark:border-m3-dark-border/40 rounded-full shadow-lg shadow-black/10 px-4 flex items-center justify-around select-none z-40 backdrop-blur-md animate-fade-in">
                <button
                    onClick={() => {
                      setActiveTab('songs');
                      setActiveSongId(null);
                      setIsEditing(false);
                    }}
                    id="nav_btn_songs"
                    className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all ${
                        activeTab === 'songs'
                            ? 'text-m3-primary dark:text-m3-dark-primary scale-105'
                            : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text'
                    }`}
                >
                  <div className={`px-5 py-0.5 rounded-full transition-all ${activeTab === 'songs' ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light border border-m3-border/20 dark:border-m3-dark-border/20' : ''}`}>
                    <Music className="w-4.5 h-4.5" />
                  </div>
                  <span className="text-[10px] font-black tracking-wide">Cânticos</span>
                </button>

                <button
                    onClick={() => {
                      setActiveTab('services');
                      setActiveSongId(null);
                      setIsEditing(false);
                    }}
                    id="nav_btn_services"
                    className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all ${
                        activeTab === 'services'
                            ? 'text-m3-primary dark:text-m3-dark-primary scale-105'
                            : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text'
                    }`}
                >
                  <div className={`px-5 py-0.5 rounded-full transition-all ${activeTab === 'services' ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light border border-m3-border/20 dark:border-m3-dark-border/20' : ''}`}>
                    <CalendarRange className="w-4.5 h-4.5" />
                  </div>
                  <span className="text-[10px] font-black tracking-wide">Cultos</span>
                </button>
              </div>
        )}

      </div>
    </div>
  );
}