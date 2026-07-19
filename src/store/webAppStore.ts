/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { create } from 'zustand';
import { Song, Service, VirtualFile, SyncReport, ThemeType } from '../types';
import { parseChordPro } from '../lib/chordpro';

interface AppState {
  // Virtual Folder System (Source of Truth)
  virtualFiles: VirtualFile[];
  sourceFolderPath: string; // Simulated path, e.g., "/Armazenamento/Canticos_Igreja"

  // SQLite Cached Index
  songs: Song[];

  // Services Planner
  services: Service[];

  // Favorites & Recently Played
  favoriteSongIds: string[];
  recentlyPlayedSongIds: string[];
  activeListContext: {
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service';
    serviceId?: string;
    folderName?: string;
    searchQuery?: string;
  };

  // Active UI States
  theme: ThemeType;
  serverUrl: string;
  serverToken: string;
  fontSize: number;
  showChords: boolean;
  showDiagrams: boolean;
  keepScreenAwake: boolean;
  slowDownOnRepeat: boolean;
  instrument: 'guitar' | 'piano';
  selectedFolder: string; // "" means "Todas as Pastas"
  activeSongId: string | null;
  activeServiceId: string | null;
  isEditing: boolean;
  searchQuery: string;
  sortBy: 'title' | 'number' | 'folder';

  // Sync state
  syncStatus: 'idle' | 'syncing' | 'success' | 'error';
  lastSyncTime: number | null;
  syncReport: SyncReport | null;

  // Actions
  setTheme: (theme: ThemeType) => void;
  setServerUrl: (url: string) => void;
  setServerToken: (token: string) => void;
  setFontSize: (size: number) => void;
  setShowChords: (show: boolean) => void;
  setShowDiagrams: (show: boolean) => void;
  setKeepScreenAwake: (keep: boolean) => void;
  setSlowDownOnRepeat: (slow: boolean) => void;
  setInstrument: (instrument: 'guitar' | 'piano') => void;
  setSourceFolderPath: (path: string) => void;
  setSelectedFolder: (folder: string) => void;
  setActiveSongId: (id: string | null) => void;
  setActiveServiceId: (id: string | null) => void;
  setIsEditing: (editing: boolean) => void;
  setSearchQuery: (query: string) => void;
  setSortBy: (sort: 'title' | 'number' | 'folder') => void;

  // Favorites & Recently Played Actions
  toggleFavoriteSong: (id: string) => void;
  addRecentlyPlayedSong: (id: string) => void;
  setActiveListContext: (context: {
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service';
    serviceId?: string;
    folderName?: string;
    searchQuery?: string;
  }) => void;
  getActiveSongListIds: () => string[];

  // Virtual Files Actions (Updating Source of Truth)
  createVirtualFile: (folder: string, fileName: string, content: string) => void;
  updateVirtualFile: (path: string, content: string) => void;
  deleteVirtualFile: (path: string) => void;

  // Sync Action
  syncLibrary: () => Promise<SyncReport>;

  // Services Actions
  createService: (name: string, date: string) => void;
  updateService: (id: string, name: string, date: string, notes?: string) => void;
  deleteService: (id: string) => void;
  addSongToService: (serviceId: string, songId: string) => void;
  removeSongFromService: (serviceId: string, index: number) => void;
  reorderSongsInService: (serviceId: string, fromIndex: number, toIndex: number) => void;
  replaceSongInService: (serviceId: string, index: number, newSongId: string) => void;
  updateSongNotesInService: (serviceId: string, index: number, notes: string) => void;

  // Reset app state
  resetApp: () => void;
}

// Initial demo files to represent "Songs" folder
const DEMO_VIRTUAL_FILES: VirtualFile[] = [];

const INITIAL_SERVICES: Service[] = [];

// Helper to load persisted state or fallback
const getStorageItem = <T>(key: string, defaultValue: T): T => {
  try {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : defaultValue;
  } catch (e) {
    return defaultValue;
  }
};

const setStorageItem = (key: string, value: any) => {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    // ignore
  }
};

export const useAppStore = create<AppState>((set, get) => ({
  // State initialization
  virtualFiles: getStorageItem('cp_virtual_files', DEMO_VIRTUAL_FILES),
  sourceFolderPath: getStorageItem('cp_source_folder', '/Armazenamento/Canticos_Igreja'),
  songs: getStorageItem('cp_songs_cache', []), // Initially empty until first sync, or syncs on mount
  services: getStorageItem('cp_services', INITIAL_SERVICES),
  favoriteSongIds: getStorageItem('cp_favorites', []),
  recentlyPlayedSongIds: getStorageItem('cp_recently_played', []),
  activeListContext: { type: 'all' },
  theme: getStorageItem('cp_theme', 'light'),
  serverUrl: getStorageItem('cp_server_url', ''),
  serverToken: getStorageItem('cp_server_token', ''),
  fontSize: getStorageItem('cp_font_size', 16),
  showChords: getStorageItem('cp_show_chords', true),
  showDiagrams: getStorageItem('cp_show_diagrams', true),
  keepScreenAwake: getStorageItem('cp_keep_awake', true),
  slowDownOnRepeat: getStorageItem('cp_slow_down_repeat', true),
  instrument: getStorageItem('cp_instrument', 'guitar'),
  selectedFolder: '',
  activeSongId: null,
  activeServiceId: null,
  isEditing: false,
  searchQuery: '',
  sortBy: 'title',
  syncStatus: 'idle',
  lastSyncTime: getStorageItem('cp_last_sync_time', null),
  syncReport: null,

  // Simple UI Setters
  setTheme: (theme) => {
    set({ theme });
    setStorageItem('cp_theme', theme);
  },
  setServerUrl: (serverUrl) => {
    set({ serverUrl });
    setStorageItem('cp_server_url', serverUrl);
  },
  setServerToken: (serverToken) => {
    set({ serverToken });
    setStorageItem('cp_server_token', serverToken);
  },
  setFontSize: (fontSize) => {
    set({ fontSize });
    setStorageItem('cp_font_size', fontSize);
  },
  setShowChords: (showChords) => {
    set({ showChords });
    setStorageItem('cp_show_chords', showChords);
  },
  setShowDiagrams: (showDiagrams) => {
    set({ showDiagrams });
    setStorageItem('cp_show_diagrams', showDiagrams);
  },
  setKeepScreenAwake: (keepScreenAwake) => {
    set({ keepScreenAwake });
    setStorageItem('cp_keep_awake', keepScreenAwake);
  },
  setSlowDownOnRepeat: (slowDownOnRepeat) => {
    set({ slowDownOnRepeat });
    setStorageItem('cp_slow_down_repeat', slowDownOnRepeat);
  },
  setInstrument: (instrument) => {
    set({ instrument });
    setStorageItem('cp_instrument', instrument);
  },
  setSourceFolderPath: (sourceFolderPath) => {
    set({ sourceFolderPath });
    setStorageItem('cp_source_folder', sourceFolderPath);
  },
  setSelectedFolder: (selectedFolder) => set({ selectedFolder }),
  setActiveSongId: (activeSongId) => set({ activeSongId }),
  setActiveServiceId: (activeServiceId) => set({ activeServiceId }),
  setIsEditing: (isEditing) => set({ isEditing }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setSortBy: (sortBy) => set({ sortBy }),

  // Favorites & Recently Played Actions
  toggleFavoriteSong: (id) => {
    const favoriteSongIds = get().favoriteSongIds;
    const isFav = favoriteSongIds.includes(id);
    const updated = isFav ? favoriteSongIds.filter(fId => fId !== id) : [...favoriteSongIds, id];
    set({ favoriteSongIds: updated });
    setStorageItem('cp_favorites', updated);
  },
  addRecentlyPlayedSong: (id) => {
    const current = get().recentlyPlayedSongIds;
    const filtered = current.filter(x => x !== id);
    const updated = [id, ...filtered].slice(0, 50);
    set({ recentlyPlayedSongIds: updated });
    setStorageItem('cp_recently_played', updated);
  },
  setActiveListContext: (activeListContext) => {
    set({ activeListContext });
  },
  getActiveSongListIds: () => {
    const state = get();
    const context = state.activeListContext;

    if (context.type === 'service') {
      const service = state.services.find(s => s.id === context.serviceId);
      if (!service) return [];
      return service.songIds;
    }

    let list = [...state.songs];

    // Apply standard sorting
    list.sort((a, b) => {
      if (state.sortBy === 'number') {
        const numA = parseInt(a.songNumber || '99999');
        const numB = parseInt(b.songNumber || '99999');
        return numA - numB;
      } else if (state.sortBy === 'folder') {
        const fComp = a.folder.localeCompare(b.folder);
        if (fComp !== 0) return fComp;
        return a.title.localeCompare(b.title);
      } else {
        return a.title.localeCompare(b.title);
      }
    });

    if (context.type === 'favorites') {
      return list.filter(s => state.favoriteSongIds.includes(s.id)).map(s => s.id);
    }

    if (context.type === 'recent') {
      return state.recentlyPlayedSongIds.filter(id => list.some(s => s.id === id));
    }

    if (context.type === 'folder') {
      return list.filter(s => s.folder === context.folderName).map(s => s.id);
    }

    if (context.type === 'search') {
      const q = (context.searchQuery || '').toLowerCase().trim();
      if (q !== '') {
        return list.filter(song => {
          const titleMatch = song.title.toLowerCase().includes(q);
          const artistMatch = song.artist?.toLowerCase().includes(q) || false;
          const numberMatch = song.songNumber?.includes(q) || false;
          const keyMatch = song.key?.toLowerCase().includes(q) || false;
          const lyricsMatch = song.content.toLowerCase().includes(q);
          return titleMatch || artistMatch || numberMatch || keyMatch || lyricsMatch;
        }).map(s => s.id);
      }
    }

    return list.map(s => s.id);
  },

  // Virtual Folder Actions
  createVirtualFile: async (folder, fileName, content) => {
    const cleanFolder = folder.trim().replace(/^\/|\/$/g, '');
    const cleanFileName = fileName.trim().endsWith('.chopro') ? fileName.trim() : `${fileName.trim()}.chopro`;
    const fullPath = cleanFolder ? `${cleanFolder}/${cleanFileName}` : cleanFileName;

    const files = get().virtualFiles;
    if (files.some(f => f.path.toLowerCase() === fullPath.toLowerCase())) {
      throw new Error(`Um ficheiro com o caminho "${fullPath}" já existe.`);
    }

    const newFile: VirtualFile = {
      path: fullPath,
      content,
      updatedAt: Date.now()
    };

    const updatedFiles = [newFile, ...files];
    set({ virtualFiles: updatedFiles });
    setStorageItem('cp_virtual_files', updatedFiles);
    
    // Save to remote if configured
    const { serverUrl, serverToken } = get();
    if (serverUrl) {
      try {
        await fetch(`${serverUrl.replace(/\/$/, '')}/api/save_song`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(serverToken ? { 'Authorization': `Bearer ${serverToken}` } : {})
          },
          body: JSON.stringify({ path: fullPath, content })
        });
      } catch (e) {
        console.error("Failed to save to server", e);
      }
    }
    
    // Trigger sync automatically
    get().syncLibrary().catch(() => {});
  },

  updateVirtualFile: async (path, content) => {
    const updatedFiles = get().virtualFiles.map(file => {
      if (file.path === path) {
        return { ...file, content, updatedAt: Date.now() };
      }
      return file;
    });

    set({ virtualFiles: updatedFiles });
    setStorageItem('cp_virtual_files', updatedFiles);

    // Save to remote if configured
    const { serverUrl, serverToken } = get();
    if (serverUrl) {
      try {
        await fetch(`${serverUrl.replace(/\/$/, '')}/api/save_song`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(serverToken ? { 'Authorization': `Bearer ${serverToken}` } : {})
          },
          body: JSON.stringify({ path, content })
        });
      } catch (e) {
        console.error("Failed to save to server", e);
      }
    }

    // Trigger sync automatically to update server and cache
    get().syncLibrary().catch(() => {});
  },

  deleteVirtualFile: async (path) => {
    const updatedFiles = get().virtualFiles.filter(file => file.path !== path);
    set({ virtualFiles: updatedFiles });
    setStorageItem('cp_virtual_files', updatedFiles);

    // Delete from remote if configured
    const { serverUrl, serverToken } = get();
    if (serverUrl) {
      try {
        await fetch(`${serverUrl.replace(/\/$/, '')}/api/delete_song`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            ...(serverToken ? { 'Authorization': `Bearer ${serverToken}` } : {})
          },
          body: JSON.stringify({ path })
        });
      } catch (e) {
        console.error("Failed to delete from server", e);
      }
    }

    // Trigger sync automatically to update server and cache
    get().syncLibrary().catch(() => {});

    // Clean active states if deleted
    if (get().activeSongId === path) {
      set({ activeSongId: null, isEditing: false });
    }
  },

  // TRANSACTIONAL SYNC SYSTEM (SQLite Index Updater)
  syncLibrary: async () => {
    set({ syncStatus: 'syncing', syncReport: null });

    const serverUrl = get().serverUrl;
    const serverToken = get().serverToken;

    // If a server URL is defined, perform a remote sync
    if (serverUrl && serverUrl.trim() !== '') {
      try {
        const headers: Record<string, string> = {
          'Content-Type': 'application/json',
        };
        if (serverToken && serverToken.trim() !== '') {
          headers['Authorization'] = `Bearer ${serverToken}`;
        }

        const localFilesPayload = get().virtualFiles.map(f => ({
          path: f.path,
          updatedAt: f.updatedAt
        }));

        const localServicesPayload = get().services.map(s => ({
          id: s.id,
          name: s.name,
          date: s.date,
          songIds: s.songIds,
          notes: s.notes,
          songNotes: s.songNotes
        }));

        const response = await fetch(`${serverUrl.replace(/\/$/, '')}/api/sync`, {
          method: 'POST',
          headers,
          body: JSON.stringify({
            files: localFilesPayload,
            services: localServicesPayload,
          }),
        });

        if (!response.ok) {
          throw new Error(`Servidor respondeu com status ${response.status}`);
        }

        const data = await response.json();

        // Server can send back:
        // {
        //   files: VirtualFile[],    // Full list of synchronized virtual files
        //   services?: Service[]     // Full list of synchronized services
        // }
        if (data.files && Array.isArray(data.files)) {
          set({ virtualFiles: data.files });
          setStorageItem('cp_virtual_files', data.files);
        }
        if (data.services && Array.isArray(data.services)) {
          set({ services: data.services });
          setStorageItem('cp_services', data.services);
        }
      } catch (err: any) {
        console.error('Erro na sincronização remota:', err);
        set({ syncStatus: 'error' });
        // We do not throw here, so that the local index rebuild still happens.
      }
    } else {
      // Simulate standard fast android sync loading when offline/no server configured
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    try {
      const vFiles = get().virtualFiles;
      const cachedSongs = get().songs;

      const added: string[] = [];
      const modified: string[] = [];
      const deleted: string[] = [];
      const conflicts: any[] = [];

      const finalSongs: Song[] = [];

      // Create a map of currently cached songs for comparison
      const cacheMap = new Map(cachedSongs.map(s => [s.id, s]));

      for (const file of vFiles) {
        const parsed = parseChordPro(file.content);
        const parts = file.path.split('/');
        const fileName = parts.pop() || '';
        const folder = parts.length > 0 ? parts.join('/') : '';

        const cached = cacheMap.get(file.path);

        const songObj: Song = {
          id: file.path,
          title: parsed.metadata.title || 'Sem Título',
          subtitle: parsed.metadata.subtitle,
          artist: parsed.metadata.artist,
          composer: parsed.metadata.composer,
          copyright: parsed.metadata.copyright,
          album: parsed.metadata.album,
          key: parsed.metadata.key,
          tempo: parsed.metadata.tempo,
          capo: parsed.metadata.capo,
          songNumber: parsed.metadata.songNumber,
          comments: parsed.metadata.comments,
          folder,
          fileName,
          content: file.content,
          updatedAt: file.updatedAt
        };

        if (!cached) {
          added.push(file.path);
        } else if (cached.content !== file.content || cached.updatedAt !== file.updatedAt) {
          modified.push(file.path);
        }

        finalSongs.push(songObj);
        cacheMap.delete(file.path); // Remove so we know what is remaining (deleted)
      }

      // Remaining items in cacheMap are deleted virtual files
      for (const [deletedId] of cacheMap) {
        deleted.push(deletedId);
      }

      const now = Date.now();
      const report: SyncReport = { added, modified, deleted, conflicts };

      // Clean up favorites and recently played for songs that no longer exist
      const finalSongIds = new Set(finalSongs.map(s => s.id));
      const updatedFavorites = get().favoriteSongIds.filter(id => finalSongIds.has(id));
      const updatedRecent = get().recentlyPlayedSongIds.filter(id => finalSongIds.has(id));

      set({
        songs: finalSongs,
        favoriteSongIds: updatedFavorites,
        recentlyPlayedSongIds: updatedRecent,
        syncStatus: 'success',
        lastSyncTime: now,
        syncReport: report
      });

      setStorageItem('cp_songs_cache', finalSongs);
      setStorageItem('cp_favorites', updatedFavorites);
      setStorageItem('cp_recently_played', updatedRecent);
      setStorageItem('cp_last_sync_time', now);

      return report;
    } catch (error) {
      set({ syncStatus: 'error' });
      throw error;
    }
  },

  // Services Actions
  createService: (name, date) => {
    const id = `service-${Date.now()}`;
    const newService: Service = {
      id,
      name,
      date,
      songIds: [],
      notes: ''
    };

    const updatedServices = [newService, ...get().services];
    set({ services: updatedServices, activeServiceId: id });
    setStorageItem('cp_services', updatedServices);
  },

  updateService: (id, name, date, notes) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === id) {
        return { ...svc, name, date, notes };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  deleteService: (id) => {
    const updatedServices = get().services.filter(svc => svc.id !== id);
    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);

    if (get().activeServiceId === id) {
      set({ activeServiceId: null });
    }
  },

  addSongToService: (serviceId, songId) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        // Prevent duplicate songs in service or allow ordering duplicates? Usually can contain multiple.
        return { ...svc, songIds: [...svc.songIds, songId] };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  removeSongFromService: (serviceId, index) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const updatedSongs = [...svc.songIds];
        updatedSongs.splice(index, 1);

        // Shift song notes
        const songNotes: Record<string, string> = {};
        if (svc.songNotes) {
          Object.entries(svc.songNotes).forEach(([key, note]) => {
            const idx = parseInt(key, 10);
            if (idx < index) {
              songNotes[idx.toString()] = note;
            } else if (idx > index) {
              songNotes[(idx - 1).toString()] = note;
            }
          });
        }

        return { ...svc, songIds: updatedSongs, songNotes };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  reorderSongsInService: (serviceId, fromIndex, toIndex) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const songIds = [...svc.songIds];
        const [removed] = songIds.splice(fromIndex, 1);
        songIds.splice(toIndex, 0, removed);

        // Update song notes mapping
        const songNotes: Record<string, string> = {};
        if (svc.songNotes) {
          Object.entries(svc.songNotes).forEach(([key, note]) => {
            const idx = parseInt(key, 10);
            let newIdx = idx;
            
            if (idx === fromIndex) {
              newIdx = toIndex;
            } else if (idx > fromIndex && idx <= toIndex) {
              newIdx = idx - 1;
            } else if (idx < fromIndex && idx >= toIndex) {
              newIdx = idx + 1;
            }
            
            songNotes[newIdx.toString()] = note;
          });
        }

        return { ...svc, songIds, songNotes };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  replaceSongInService: (serviceId, index, newSongId) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const songIds = [...svc.songIds];
        songIds[index] = newSongId;
        return { ...svc, songIds };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  updateSongNotesInService: (serviceId, index, notes) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const songNotes = { ...(svc.songNotes || {}) };
        if (notes.trim() === '') {
          delete songNotes[index.toString()];
        } else {
          songNotes[index.toString()] = notes;
        }
        return { ...svc, songNotes };
      }
      return svc;
    });

    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  resetApp: () => {
    set({
      virtualFiles: [],
      songs: [],
      services: [],
      activeSongId: null,
      activeServiceId: null,
      isEditing: false,
      searchQuery: '',
      selectedFolder: '',
      syncReport: null,
      syncStatus: 'idle',
      lastSyncTime: null
    });
    localStorage.removeItem('cp_virtual_files');
    localStorage.removeItem('cp_songs_cache');
    localStorage.removeItem('cp_services');
    localStorage.removeItem('cp_last_sync_time');
  }
}));
