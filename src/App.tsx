/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useEffect, useState } from 'react';
import { Music, CalendarRange, Settings, RefreshCw, Bookmark } from 'lucide-react';
import { useAppStore } from './store/appStore';

import SongBrowser from './components/SongBrowser';
import SongView from './components/SongView';
import SongEditor from './components/SongEditor';
import ServiceManager from './components/ServiceManager';
import SettingsView from './components/SettingsView';

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

  // Automatic SQLite synchronization on startup if index is empty
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

  return (
    <div className="flex-1 flex overflow-hidden bg-m3-bg dark:bg-m3-dark-bg text-m3-text dark:text-m3-dark-text relative h-full">
      
      {/* Primary Screen Area */}
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        


        {/* Active Tab Screen Content Renderer */}
        <div className="flex-1 overflow-hidden relative">
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

        {/* Floating iOS-style Navigation Pill Bar */}
        <div className="absolute bottom-5 left-1/2 -translate-x-1/2 w-[90%] max-w-sm h-14 bg-m3-toolbar/90 dark:bg-m3-dark-toolbar/90 border border-m3-border/40 dark:border-m3-dark-border/40 rounded-full shadow-lg shadow-black/10 px-4 flex items-center justify-around select-none z-40 backdrop-blur-md animate-fade-in">
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

          <button
            onClick={() => {
              syncLibrary().catch(() => {});
            }}
            disabled={syncStatus === 'syncing'}
            id="nav_btn_sync"
            className={`flex flex-col items-center justify-center gap-0.5 w-20 py-1 transition-all ${
              syncStatus === 'syncing'
                ? 'text-m3-primary dark:text-m3-dark-primary scale-105'
                : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text'
            }`}
          >
            <div className={`px-5 py-0.5 rounded-full transition-all ${syncStatus === 'syncing' ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light border border-m3-border/20 dark:border-m3-dark-border/20 animate-pulse' : ''}`}>
              <RefreshCw className={`w-4.5 h-4.5 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
            </div>
            <span className="text-[10px] font-black tracking-wide">
              {syncStatus === 'syncing' ? 'A Sinc...' : syncStatus === 'error' ? 'Erro' : 'Sinc'}
            </span>
          </button>
        </div>

      </div>
    </div>
  );
}
