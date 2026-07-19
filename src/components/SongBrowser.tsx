/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useMemo, useState } from 'react';
import { Search, Folder, FileText, Music, SlidersHorizontal, Plus, Menu, Heart, Clock, X, Check, CircleDot, Timer, ArrowLeft, Settings } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useAppStore } from '../store/appStore';
import { Song } from '../types';
import CircleOfFifths from './CircleOfFifths';
import Metronome from './Metronome';
import SettingsView from './SettingsView';

interface SongBrowserProps {
  onSelectSong: (id: string) => void;
  onAddNewSong: () => void;
}

export default function SongBrowser({ onSelectSong, onAddNewSong }: SongBrowserProps) {
  const songs = useAppStore(state => state.songs);
  const favoriteSongIds = useAppStore(state => state.favoriteSongIds);
  const recentlyPlayedSongIds = useAppStore(state => state.recentlyPlayedSongIds);
  const toggleFavoriteSong = useAppStore(state => state.toggleFavoriteSong);
  const setActiveListContext = useAppStore(state => state.setActiveListContext);

  const selectedFolder = useAppStore(state => state.selectedFolder);
  const setSelectedFolder = useAppStore(state => state.setSelectedFolder);
  const searchQuery = useAppStore(state => state.searchQuery);
  const setSearchQuery = useAppStore(state => state.setSearchQuery);
  const sortBy = useAppStore(state => state.sortBy);
  const setSortBy = useAppStore(state => state.setSortBy);

  // Section navigation state
  const [selectedSection, setSelectedSection] = useState<'all' | 'favorites' | 'recent' | 'folder' | 'circle' | 'metronome' | 'settings'>('all');
  const [showDrawer, setShowDrawer] = useState(false);

  // Dynamically extract unique folders from songs list
  const uniqueFolders = useMemo(() => {
    const list = songs.map(s => s.folder).filter(f => f !== '');
    return Array.from(new Set(list));
  }, [songs]);

  // Comprehensive searching and sorting engine
  const filteredAndSortedSongs = useMemo(() => {
    let result = [...songs];

    // 1. Section/Folder Filtering
    if (selectedSection === 'favorites') {
      result = result.filter(song => favoriteSongIds.includes(song.id));
    } else if (selectedSection === 'recent') {
      const recentList = recentlyPlayedSongIds
        .map(id => songs.find(s => s.id === id))
        .filter(Boolean) as Song[];
      result = recentList;
    } else if (selectedSection === 'folder' && selectedFolder !== '') {
      result = result.filter(song => song.folder === selectedFolder);
    }

    // 2. Query Searching (Title, Lyrics, Artist, Number, Key)
    if (searchQuery.trim() !== '') {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(song => {
        const titleMatch = song.title.toLowerCase().includes(q);
        const artistMatch = song.artist?.toLowerCase().includes(q) || false;
        const numberMatch = song.songNumber?.includes(q) || false;
        const keyMatch = song.key?.toLowerCase().includes(q) || false;
        const lyricsMatch = song.content.toLowerCase().includes(q);

        return titleMatch || artistMatch || numberMatch || keyMatch || lyricsMatch;
      });
    }

    // 3. Sorting (preserves chronological played history for recently played, sorts others)
    if (selectedSection !== 'recent') {
      result.sort((a, b) => {
        if (sortBy === 'number') {
          const numA = parseInt(a.songNumber || '99999');
          const numB = parseInt(b.songNumber || '99999');
          return numA - numB;
        } else if (sortBy === 'folder') {
          const fComp = a.folder.localeCompare(b.folder);
          if (fComp !== 0) return fComp;
          return a.title.localeCompare(b.title);
        } else {
          return a.title.localeCompare(b.title);
        }
      });
    }

    return result;
  }, [songs, selectedSection, selectedFolder, favoriteSongIds, recentlyPlayedSongIds, searchQuery, sortBy]);

  const handleSelectSong = (songId: string) => {
    // Determine active list context
    const contextType = selectedSection === 'all' && searchQuery.trim() !== '' ? 'search' : selectedSection;
    setActiveListContext({
      type: contextType,
      folderName: selectedSection === 'folder' ? selectedFolder : undefined,
      searchQuery: searchQuery.trim() !== '' ? searchQuery : undefined
    });

    // Automatically record to Recently Played on open
    useAppStore.getState().addRecentlyPlayedSong(songId);

    // Call component onSelect
    onSelectSong(songId);
  };

  const getSectionTitle = () => {
    switch (selectedSection) {
      case 'favorites':
        return 'Favoritos';
      case 'recent':
        return 'Cânticos Recentes';
      case 'folder':
        return selectedFolder || 'Pasta';
      case 'circle':
        return 'Círculo da Quinta';
      case 'metronome':
        return 'Metrónomo';
      case 'settings':
        return 'Definições & Servidor';
      case 'all':
      default:
        return 'Todos os Cânticos';
    }
  };

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-m3-bg dark:bg-m3-dark-bg relative">
      
      {/* Header Search Area */}
      <div className="p-4 bg-m3-bg dark:bg-m3-dark-bg border-b border-m3-border dark:border-m3-dark-border flex flex-col gap-3 shrink-0">
        
        {/* Search Bar with Menu toggle */}
        <div className="flex items-center gap-2">
          {selectedSection === 'circle' || selectedSection === 'metronome' || selectedSection === 'settings' ? (
            <button
              onClick={() => setSelectedSection('all')}
              className="p-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text transition-all active:scale-95"
              title="Voltar para Cânticos"
            >
              <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
            </button>
          ) : (
            <button
              onClick={() => setShowDrawer(true)}
              id="btn_open_nav_drawer"
              className="p-1.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text transition-all active:scale-95 flex items-center gap-2 pr-3"
              title="Abrir Menu de Navegação"
            >
              <img src="/logo.png" className="w-7 h-7 rounded-lg object-cover border border-m3-border/20 shadow-xs" alt="Hosanna" referrerPolicy="no-referrer" />
              <Menu className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
            </button>
          )}
          
          {selectedSection !== 'circle' && selectedSection !== 'metronome' && selectedSection !== 'settings' ? (
            <div className="relative flex-1">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-m3-secondary dark:text-m3-dark-secondary" />
              <input
                type="text"
                id="input_search_songs"
                placeholder="Pesquisar título, letra, autor, número, tom..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-m3-primary/20 focus:border-m3-primary text-m3-text dark:text-m3-dark-text placeholder-m3-secondary/70"
              />
            </div>
          ) : (
            <div className="flex-1 pl-2">
              <h2 className="text-lg font-black text-m3-text dark:text-m3-dark-text tracking-tight">{getSectionTitle()}</h2>
            </div>
          )}
        </div>

        {/* Filters and Sorting controllers */}
        {selectedSection !== 'circle' && selectedSection !== 'metronome' && selectedSection !== 'settings' && (
          <div className="flex items-center justify-between gap-2">
            {/* Active section breadcrumb */}
            <div className="flex items-center gap-1.5 text-xs text-m3-secondary dark:text-m3-dark-secondary font-medium">
              <span className="font-mono bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded border border-m3-border/30 dark:border-m3-dark-border/30 text-[10px] font-bold text-m3-primary dark:text-m3-dark-primary">
                {getSectionTitle()}
              </span>
              {selectedSection !== 'recent' && (
                <>
                  <SlidersHorizontal className="w-3 h-3 text-m3-secondary/70" />
                  <select
                    id="select_sort_songs"
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as any)}
                    className="bg-transparent border-none p-0 pr-4 text-xs font-bold text-m3-text dark:text-m3-dark-text focus:outline-none cursor-pointer"
                  >
                    <option value="title">A-Z Alfabética</option>
                    <option value="number">Número de Cântico</option>
                    <option value="folder">Pasta / Categoria</option>
                  </select>
                </>
              )}
            </div>

            {/* Quick Creator Button */}
            <button
              onClick={onAddNewSong}
              id="btn_create_new_song"
              className="flex items-center gap-1 bg-m3-primary hover:opacity-90 text-white text-xs px-4 py-2 rounded-full font-bold shadow-xs transition-all active:scale-95"
            >
              <Plus className="w-3.5 h-3.5" />
              Novo
            </button>
          </div>
        )}
      </div>

      {/* Main Content Area */}
      {selectedSection === 'circle' ? (
        <CircleOfFifths />
      ) : selectedSection === 'metronome' ? (
        <Metronome />
      ) : selectedSection === 'settings' ? (
        <SettingsView />
      ) : (
        <>
          {/* Songs List Grid */}
          <div className="flex-1 overflow-y-auto p-4 pb-24 space-y-2 no-scrollbar">
            {filteredAndSortedSongs.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-center px-4">
                <Music className="w-12 h-12 text-m3-secondary dark:text-m3-dark-secondary mb-3 opacity-60" />
                <h3 className="text-sm font-bold text-m3-text dark:text-m3-dark-text">
                  Nenhum cântico encontrado
                </h3>
                <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary mt-1 max-w-[240px]">
                  {selectedSection === 'favorites' 
                    ? "Ainda não marcou nenhum cântico como favorito."
                    : selectedSection === 'recent'
                    ? "Nenhum cântico tocado recentemente."
                    : "Tente redefinir os filtros ou escreva outra palavra de pesquisa."}
                </p>
              </div>
            ) : (
              filteredAndSortedSongs.map(song => {
            const isFav = favoriteSongIds.includes(song.id);
            return (
              <div
                key={song.id}
                onClick={() => handleSelectSong(song.id)}
                className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 hover:border-m3-primary/60 dark:hover:border-m3-dark-primary/60 cursor-pointer transition-all hover:shadow-xs flex items-center justify-between group active:scale-[0.99]"
              >
                <div className="flex items-start gap-3 min-w-0 flex-1">
                  {/* Visual Number badge or note icon */}
                  <div className="w-10 h-10 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar flex flex-col items-center justify-center shrink-0 border border-m3-border/20 group-hover:bg-m3-primary-light dark:group-hover:bg-m3-dark-primary-light transition-colors">
                    {song.songNumber ? (
                      <span className="text-[11px] font-black text-m3-primary dark:text-m3-dark-primary">
                        #{song.songNumber}
                      </span>
                    ) : (
                      <FileText className="w-4 h-4 text-m3-secondary dark:text-m3-dark-secondary group-hover:text-m3-primary" />
                    )}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <h4 className="text-sm font-bold text-m3-text dark:text-m3-dark-text truncate">
                        {song.title}
                      </h4>
                      {song.folder && (
                        <span className="text-[9px] font-bold bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary dark:text-m3-dark-secondary px-1.5 py-0.5 rounded border border-m3-border/30">
                          {song.folder}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary mt-0.5 truncate font-medium">
                      {song.artist || 'Artista desconhecido'}
                    </p>
                  </div>
                </div>

                {/* Badges for Key, Tempo and Heart action */}
                <div className="flex items-center gap-3 shrink-0 pl-3">
                  <div className="flex flex-col items-end gap-1">
                    {song.key && (
                      <span className="text-[10px] font-bold bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text px-2 py-0.5 rounded-lg border border-m3-border/30">
                        {song.key}
                      </span>
                    )}
                    {song.tempo && (
                      <span className="text-[9px] text-m3-secondary dark:text-m3-dark-secondary font-mono">
                        ♩ {song.tempo}
                      </span>
                    )}
                  </div>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleFavoriteSong(song.id);
                    }}
                    className={`p-2 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors ${
                      isFav 
                        ? 'text-red-500 hover:text-red-600' 
                        : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-primary'
                    }`}
                    title={isFav ? "Remover dos favoritos" : "Adicionar aos favoritos"}
                  >
                    <Heart className={`w-4.5 h-4.5 ${isFav ? 'fill-current' : ''}`} />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Simple List Stats Footer */}
      <div className="px-4 py-2 bg-m3-toolbar dark:bg-m3-toolbar border-t border-m3-border dark:border-m3-dark-border text-[10px] text-m3-secondary dark:text-m3-dark-secondary flex justify-between shrink-0 font-sans font-medium">
        <span>Biblioteca Sincronizada</span>
        <span>Mostrados: {filteredAndSortedSongs.length} / {songs.length}</span>
      </div>
      </>
      )}

      {/* Navigation Drawer Overlay */}
      <AnimatePresence>
        {showDrawer && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.4 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowDrawer(false)}
              className="absolute inset-0 bg-black z-40 cursor-pointer"
            />
            {/* Drawer container */}
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 220 }}
              className="absolute left-0 top-0 bottom-0 w-72 bg-m3-card dark:bg-m3-dark-card border-r border-m3-border dark:border-m3-dark-border shadow-2xl z-50 flex flex-col overflow-hidden"
            >
              {/* Drawer Header */}
              <div className="p-6 border-b border-m3-border/30 dark:border-m3-dark-border/30 bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <img src="/logo.png" className="w-10 h-10 rounded-xl border border-m3-border/20 shadow-xs object-cover" alt="Hosanna" referrerPolicy="no-referrer" />
                  <div>
                    <h2 className="text-base font-black text-m3-primary dark:text-m3-dark-primary tracking-tight leading-none">Hosanna</h2>
                    <p className="text-[9px] text-m3-secondary dark:text-m3-dark-secondary font-medium mt-1">Menu de Navegação</p>
                  </div>
                </div>
                <button
                  onClick={() => setShowDrawer(false)}
                  className="p-1.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Drawer Content */}
              <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1.5 no-scrollbar">
                <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Biblioteca</div>
                
                {/* All Songs Button */}
                <button
                  onClick={() => {
                    setSelectedSection('all');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                    selectedSection === 'all'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <Music className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                  <span>Todos os Cânticos</span>
                  <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{songs.length}</span>
                </button>

                {/* Favorites Button */}
                <button
                  onClick={() => {
                    setSelectedSection('favorites');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                    selectedSection === 'favorites'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <Heart className="w-4 h-4 text-red-500 fill-current" />
                  <span>Favoritos</span>
                  <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{favoriteSongIds.length}</span>
                </button>

                {/* Recently Played Button */}
                <button
                  onClick={() => {
                    setSelectedSection('recent');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                    selectedSection === 'recent'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <Clock className="w-4 h-4 text-amber-500" />
                  <span>Recentes (Histórico)</span>
                  <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{recentlyPlayedSongIds.length}</span>
                </button>

                <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-4" />

                <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Ferramentas</div>

                <button
                  onClick={() => {
                    setSelectedSection('circle');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                    selectedSection === 'circle'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <CircleDot className="w-4 h-4 text-emerald-500" />
                  <span>Círculo da Quinta</span>
                </button>

                <button
                  onClick={() => {
                    setSelectedSection('metronome');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all mt-1 ${
                    selectedSection === 'metronome'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <Timer className="w-4 h-4 text-blue-500" />
                  <span>Metrónomo</span>
                </button>

                <button
                  onClick={() => {
                    setSelectedSection('settings');
                    setSelectedFolder('');
                    setShowDrawer(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all mt-1 ${
                    selectedSection === 'settings'
                      ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                      : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                  }`}
                >
                  <Settings className="w-4 h-4 text-slate-500" />
                  <span>Definições (Servidor & Sync)</span>
                </button>

                <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-4" />

                <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Pastas & Categorias</div>

                {uniqueFolders.length === 0 ? (
                  <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary px-3 italic">Nenhuma pasta encontrada.</p>
                ) : (
                  uniqueFolders.map(folder => {
                    const count = songs.filter(s => s.folder === folder).length;
                    const isSelected = selectedSection === 'folder' && selectedFolder === folder;
                    return (
                      <button
                        key={folder}
                        onClick={() => {
                          setSelectedSection('folder');
                          setSelectedFolder(folder);
                          setShowDrawer(false);
                        }}
                        className={`w-full flex items-center gap-3 px-4 py-2.5 rounded-2xl text-xs font-bold transition-all ${
                          isSelected
                            ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                            : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                        }`}
                      >
                        <Folder className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                        <span className="truncate">{folder}</span>
                        <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-1.5 py-0.5 rounded border border-m3-border/20">{count}</span>
                      </button>
                    );
                  })
                )}
              </div>

              {/* Drawer Footer */}
              <div className="p-4 border-t border-m3-border/30 dark:border-m3-dark-border/30 text-center text-[9px] text-m3-secondary dark:text-m3-dark-secondary font-sans font-semibold">
                Hosanna Repertório
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

    </div>
  );
}
