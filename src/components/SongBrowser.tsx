

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
  const folders = useAppStore(state => state.folders);
  const favoriteSongIds = useAppStore(state => state.favoriteSongIds);
  const recentlyPlayedSongIds = useAppStore(state => state.recentlyPlayedSongIds);
  const toggleFavoriteSong = useAppStore(state => state.toggleFavoriteSong);
  const setActiveListContext = useAppStore(state => state.setActiveListContext);

  const selectedFolder = useAppStore(state => state.selectedFolder);
  const searchQuery = useAppStore(state => state.searchQuery);
  const sortBy = useAppStore(state => state.sortBy);
  const setSortBy = useAppStore(state => state.setSortBy);

  // Section navigation state
  const [selectedSection, setSelectedSection] = useState<'all' | 'favorites' | 'recent' | 'folder' | 'circle' | 'metronome' | 'settings'>('all');

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
        
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <h2 className="text-lg font-black text-m3-text dark:text-m3-dark-text tracking-tight">{getSectionTitle()}</h2>
          </div>
          {selectedSection === 'circle' || selectedSection === 'metronome' || selectedSection === 'settings' ? (
            <button
              onClick={() => setSelectedSection('all')}
              className="p-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text transition-all active:scale-95"
              title="Voltar para Cânticos"
            >
              <ArrowLeft className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
            </button>
          ) : null}
        </div>

        {/* Filters and Sorting controllers */}
        {selectedSection !== 'circle' && selectedSection !== 'metronome' && selectedSection !== 'settings' && (
          <div className="flex items-center justify-between gap-2">
            {/* Active section breadcrumb */}
            <div className="flex items-center gap-1.5 text-xs text-m3-secondary dark:text-m3-dark-secondary font-medium">
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
      </>
      )}
    </div>
  );
}
