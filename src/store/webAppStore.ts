

import { create } from 'zustand';
import { Song, Service, VirtualFile, SyncReport, ThemeType, LibraryFolder } from '../types';
import { parseChordPro } from '../lib/chordpro';
import {
  ApiSong,
  ApiService,
  createSong,
  deleteSong,
  getFoldersFlat,
  getSongs,
  getServices,
  updateSong,
  updateServiceApi,
  addSongToServiceApi,
  removeSongFromServiceApi,
  reorderServiceSongsApi,
  updateServiceNotesApi,
  updateServiceSongNotesApi,
} from '../lib/apiClient';

interface AppState {
  // Virtual Folder System (Source of Truth)
  virtualFiles: VirtualFile[];
  sourceFolderPath: string; // Simulated path, e.g., "/Armazenamento/Canticos_Igreja"

  // SQLite Cached Index
  songs: Song[];

  // Services Planner
  services: Service[];
  folders: LibraryFolder[];
  songRemoteIds: Record<string, string>;

  // Favorites & Recently Played
  favoriteSongIds: string[];
  recentlyPlayedSongIds: string[];
  activeListContext: {
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service' | 'circle' | 'settings' | 'metronome';
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
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service' | 'circle' | 'settings' | 'metronome';
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
  updateService: (id: string, name: string, date: string, notes?: string) => void;
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

type SetFn = (partial: Partial<AppState> | ((s: AppState) => Partial<AppState>)) => void;
type GetFn = () => AppState;

// Converts a server-authoritative ApiSong into the local Song shape used by the UI.
// The server's `content` is parsed for the extra ChordPro metadata fields (key, tempo,
// capo, etc.) that the API itself does not track as first-class columns.
const toLocalSong = (apiSong: ApiSong, folders: LibraryFolder[]): Song => {
  const parsed = parseChordPro(apiSong.content);
  const parts = apiSong.path.split('/');
  const fileName = parts.pop() || '';
  const folder = apiSong.folderId ? folders.find(folderItem => folderItem.id === apiSong.folderId).name : "";
  const parsedTimestamp = Date.parse(apiSong.updatedAtid);

  return {
    id: apiSong.path,
    remoteId: apiSong.id,
    remoteUpdatedAt: apiSong.updatedAt,
    title: apiSong.title || parsed.metadata.title || 'Sem Título',
    subtitle: parsed.metadata.subtitle,
    artist: apiSong.artist || parsed.metadata.artist,
    composer: parsed.metadata.composer,
    copyright: parsed.metadata.copyright,
    album: parsed.metadata.album,
    key: parsed.metadata.key,
    tempo: parsed.metadata.tempo,
    capo: parsed.metadata.capo,
    songNumber: parsed.metadata.songNumber,
    comments: parsed.metadata.comments,
    folderId: apiSong.folderId,
    folder,
    fileName,
    content: apiSong.content,
    updatedAt: Number.isNaN(parsedTimestamp) ? Date.now() : parsedTimestamp,
    tags: apiSong.tags,
  };
};

const toLSong =
  (folders: LibraryFolder[]) =>
  (apiSong: ApiSong): Song =>
    toLocalSong(apiSong, folders);

// Converts a server-authoritative ApiService into the local Service shape, resolving
// each remote song id back to the local song id (file path) used throughout the UI.
const toLocalService = (apiService: ApiService, localSongs: Song[]): Service => {
  const remoteToLocalId = new Map(
    localSongs.filter(s => s.remoteId).map(s => [s.remoteId as string, s.id])
  );
  const orderedSongs = [...apiService.songs].sort((a, b) => a.position - b.position);
  const songIds = orderedSongs.map(s => remoteToLocalId.get(s.songId) || s.songId);
  const songNotes: Record<string, string> = {};
  orderedSongs.forEach(s => {
    if (s.notes) songNotes[s.position.toString()] = s.notes;
  });

  return {
    id: apiService.id,
    name: apiService.name,
    date: apiService.date,
    notes: apiService.notes,
    songIds,
    songNotes,
    updatedAt: apiService.updatedAt,
  };
};

// Writes a server-confirmed song into local state (songs cache + virtualFiles mirror).
// `previousLocalId` is passed when a song's path may have changed as a side effect.
const commitSongLocally = (set: SetFn, get: GetFn, apiSong: ApiSong, previousLocalId?: string) => {
  const folders = get().folders;
  const localSong = toLocalSong(apiSong, folders);
  const songs = get().songs;
  const virtualFiles = get().virtualFiles;

  const nextSongs = [
    ...songs.filter(s => s.id !== localSong.id && s.id !== previousLocalId),
    localSong,
  ];
  const nextFiles = [
    ...virtualFiles.filter(f => f.path !== localSong.id && f.path !== previousLocalId),
    { path: localSong.id, content: localSong.content, updatedAt: localSong.updatedAt },
  ];

  const songRemoteIds = { ...get().songRemoteIds };
  if (previousLocalId) delete songRemoteIds[previousLocalId];
  songRemoteIds[localSong.id] = apiSong.id;

  set({ songs: nextSongs, virtualFiles: nextFiles, songRemoteIds });
  setStorageItem('cp_songs_cache', nextSongs);
  setStorageItem('cp_virtual_files', nextFiles);
  setStorageItem('cp_song_remote_ids', songRemoteIds);
};

// Writes a server-confirmed service into local state.
const commitServiceLocally = (set: SetFn, get: GetFn, apiService: ApiService) => {
  const localService = toLocalService(apiService, get().songs);
  const services = get().services.map(svc => (svc.id === localService.id ? localService : svc));
  set({ services });
  setStorageItem('cp_services', services);
};

export const useAppStore = create<AppState>((set, get) => ({
  // State initialization
  virtualFiles: getStorageItem('cp_virtual_files', DEMO_VIRTUAL_FILES),
  sourceFolderPath: getStorageItem('cp_source_folder', '/Armazenamento/Canticos_Igreja'),
  songs: getStorageItem('cp_songs_cache', []), // Initially empty until first sync, or syncs on mount
  services: getStorageItem('cp_services', INITIAL_SERVICES),
  folders: getStorageItem('cp_folders', []),
  songRemoteIds: getStorageItem('cp_song_remote_ids', {}),
  favoriteSongIds: getStorageItem('cp_favorites', []),
  recentlyPlayedSongIds: getStorageItem('cp_recently_played', []),
  activeListContext: { type: 'all' },
  theme: getStorageItem('cp_theme', 'light'),
  serverUrl: getStorageItem('cp_server_url', import.meta.env.VITE_API_URL),
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

  // Virtual Folder Actions — the server is the source of truth. When a server is
  // configured, every write goes to the API first; local state is only updated once
  // the server confirms the change. Nothing is pushed to the server as a side effect
  // of local edits alone.
  createVirtualFile: async (folder, fileName, content) => {
    const folderSelection = folder.trim();
    const matchedFolder = get().folders.find(folderItem => folderItem.id === folderSelection || folderItem.name === folderSelection);
    const resolvedFolderName = matchedFolder?.name || folderSelection;
    const cleanFolder = resolvedFolderName.trim().replace(/^\/?|\/$/g, '');
    const cleanFileName = fileName.trim().endsWith('.chopro') ? fileName.trim() : `${fileName.trim()}.chopro`;
    const fullPath = cleanFolder ? `${cleanFolder}/${cleanFileName}` : cleanFileName;

    const files = get().virtualFiles;
    if (files.some(f => f.path.toLowerCase() === fullPath.toLowerCase())) {
      throw new Error(`Um ficheiro com o caminho "${fullPath}" já existe.`);
    }

    const { serverUrl, serverToken } = get();
    const parsed = parseChordPro(content);

    if (serverUrl.trim() !== '') {
      const created = await createSong(serverUrl, serverToken, {
        title: parsed.metadata.title || cleanFileName.replace(/\.chopro$/i, ''),
        artist: parsed.metadata.artist,
        content,
        folderId: matchedFolder?.id ?? null,
        path: fullPath,
      });
      commitSongLocally(set, get, created);
      return;
    }

    // No server configured — operate purely locally.
    const newFile: VirtualFile = { path: fullPath, content, updatedAt: Date.now() };
    const updatedFiles = [newFile, ...files];
    set({ virtualFiles: updatedFiles });
    setStorageItem('cp_virtual_files', updatedFiles);
    get().syncLibrary().catch(() => {});
  },

  updateVirtualFile: async (path, content) => {
    const { serverUrl, serverToken, songs } = get();

    if (serverUrl.trim() !== '') {
      const existing = songs.find(s => s.id === path);
      if (!existing?.remoteId) {
        throw new Error('Não foi possível encontrar este cântico no servidor. Sincronize e tente novamente.');
      }
      const parsed = parseChordPro(content);
      const updated = await updateSong(serverUrl, serverToken, existing.remoteId, {
        updatedAt: existing.remoteUpdatedAt || '',
        title: parsed.metadata.title || existing.title,
        content,
        folderId: existing.folderId ?? null,
        tags: existing.tags,
      });
      commitSongLocally(set, get, updated, path);
      return;
    }

    // No server configured — operate purely locally.
    const updatedFiles = get().virtualFiles.map(file => {
      if (file.path === path) {
        return { ...file, content, updatedAt: Date.now() };
      }
      return file;
    });
    set({ virtualFiles: updatedFiles });
    setStorageItem('cp_virtual_files', updatedFiles);
    get().syncLibrary().catch(() => {});
  },

  deleteVirtualFile: async (path) => {
    const { serverUrl, serverToken, songs } = get();

    if (serverUrl.trim() !== '') {
      const existing = songs.find(s => s.id === path);
      if (existing?.remoteId) {
        await deleteSong(serverUrl, serverToken, existing.remoteId);
      }
    }

    // Only remove locally once the server deletion (if any) has succeeded.
    const updatedFiles = get().virtualFiles.filter(file => file.path !== path);
    const updatedSongs = get().songs.filter(s => s.id !== path);
    const songRemoteIds = { ...get().songRemoteIds };
    delete songRemoteIds[path];

    set({ virtualFiles: updatedFiles, songs: updatedSongs, songRemoteIds });
    setStorageItem('cp_virtual_files', updatedFiles);
    setStorageItem('cp_songs_cache', updatedSongs);
    setStorageItem('cp_song_remote_ids', songRemoteIds);

    // Clean active states if deleted
    if (get().activeSongId === path) {
      set({ activeSongId: null, isEditing: false });
    }
  },

  // SYNC SYSTEM — pull-only. The server is the single source of truth: this never
  // pushes local edits (those go out immediately via createVirtualFile/updateVirtualFile/
  // deleteVirtualFile and the service actions below). Sync just fetches the current
  // server state and overwrites local state to match it. All requests run in parallel
  // (including every song page) so a full sync is a couple of round-trips, not a
  // sequential per-song loop.
  syncLibrary: async () => {
    set({ syncStatus: 'syncing', syncReport: null });

    const { serverUrl, serverToken } = get();

    if (!serverUrl || serverUrl.trim() === '') {
      // No server configured — nothing to pull. Just report success instantly.
      const report: SyncReport = { added: [], modified: [], deleted: [], conflicts: [] };
      const now = Date.now();
      set({ syncStatus: 'success', lastSyncTime: now, syncReport: report });
      setStorageItem('cp_last_sync_time', now);
      return report;
    }

    try {
      const [folders, firstPage, apiServices] = await Promise.all([
        getFoldersFlat(serverUrl, serverToken),
        getSongs(serverUrl, serverToken, { page: 1, limit: 200, sortBy: 'title', sortOrder: 'asc' }),
        getServices(serverUrl, serverToken),
      ]);

      let apiSongs = [...firstPage.songs];
      if (firstPage.totalPages > 1) {
        const remainingPages = await Promise.all(
          Array.from({ length: firstPage.totalPages - 1 }, (_, i) =>
            getSongs(serverUrl, serverToken, { page: i + 2, limit: 200, sortBy: 'title', sortOrder: 'asc' })
          )
        );
        remainingPages.forEach(page => apiSongs.push(...page.songs));
      }

      const finalSongs = apiSongs.map(toLSong(folders));
      const virtualFiles: VirtualFile[] = finalSongs.map(s => ({
        path: s.id,
        content: s.content,
        updatedAt: s.updatedAt,
      }));
      const songRemoteIds: Record<string, string> = {};
      finalSongs.forEach(s => {
        if (s.remoteId) songRemoteIds[s.id] = s.remoteId;
      });

      const finalServices = apiServices.map(svc => toLocalService(svc, finalSongs));

      const finalSongIds = new Set(finalSongs.map(s => s.id));
      const updatedFavorites = get().favoriteSongIds.filter(id => finalSongIds.has(id));
      const updatedRecent = get().recentlyPlayedSongIds.filter(id => finalSongIds.has(id));

      const report: SyncReport = { added: [], modified: [], deleted: [], conflicts: [] };
      const now = Date.now();

      set({
        folders,
        services: finalServices,
        virtualFiles,
        songs: finalSongs,
        songRemoteIds,
        favoriteSongIds: updatedFavorites,
        recentlyPlayedSongIds: updatedRecent,
        syncStatus: 'success',
        lastSyncTime: now,
        syncReport: report,
      });

      setStorageItem('cp_folders', folders);
      setStorageItem('cp_services', finalServices);
      setStorageItem('cp_virtual_files', virtualFiles);
      setStorageItem('cp_songs_cache', finalSongs);
      setStorageItem('cp_song_remote_ids', songRemoteIds);
      setStorageItem('cp_favorites', updatedFavorites);
      setStorageItem('cp_recently_played', updatedRecent);
      setStorageItem('cp_last_sync_time', now);

      return report;
    } catch (err: any) {
      console.error('Erro na sincronização remota:', err);
      set({ syncStatus: 'error' });
      throw err;
    }
  },


  // Services Actions — server-authoritative when a server is configured: every
  // action calls the API first and only patches local state from the server's
  // response once it succeeds. Falls back to local-only editing (no server calls)
  // when no server URL is set.
  updateService: async (id, name, date, notes) => {
    const { serverUrl, serverToken, services } = get();
    const current = services.find(svc => svc.id === id);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      try {
        // The dedicated /notes endpoint is available to musician tokens too, so use
        // it whenever only the notes are changing; a name/date change requires the
        // admin-only full update endpoint.
        const onlyNotesChanged = name === current.name && date === current.date;
        const updated = onlyNotesChanged
          ? await updateServiceNotesApi(serverUrl, serverToken, id, {
              updatedAt: current.updatedAt || '',
              notes: notes || '',
            })
          : await updateServiceApi(serverUrl, serverToken, id, {
              updatedAt: current.updatedAt || '',
              name,
              date,
              notes,
            });
        commitServiceLocally(set, get, updated);
      } catch (e) {
        console.error('Failed to update service', e);
      }
      return;
    }

    const updatedServices = services.map(svc => (svc.id === id ? { ...svc, name, date, notes } : svc));
    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  addSongToService: async (serviceId, songId) => {
    const { serverUrl, serverToken, services, songs } = get();
    const current = services.find(svc => svc.id === serviceId);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      const song = songs.find(s => s.id === songId);
      if (!song?.remoteId) {
        console.error('Cannot add song to service: song is not yet synced with the server.');
        return;
      }
      try {
        const updated = await addSongToServiceApi(serverUrl, serverToken, serviceId, {
          updatedAt: current.updatedAt || '',
          songId: song.remoteId,
        });
        commitServiceLocally(set, get, updated);
      } catch (e) {
        console.error('Failed to add song to service', e);
      }
      return;
    }

    const updatedServices = services.map(svc =>
      svc.id === serviceId ? { ...svc, songIds: [...svc.songIds, songId] } : svc
    );
    set({ services: updatedServices });
    setStorageItem('cp_services', updatedServices);
  },

  removeSongFromService: async (serviceId, index) => {
    const { serverUrl, serverToken, services, songs } = get();
    const current = services.find(svc => svc.id === serviceId);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      const localSongId = current.songIds[index];
      const song = songs.find(s => s.id === localSongId);
      if (!song?.remoteId) {
        console.error('Cannot remove song from service: song is not yet synced with the server.');
        return;
      }
      try {
        const updated = await removeSongFromServiceApi(serverUrl, serverToken, serviceId, song.remoteId, {
          updatedAt: current.updatedAt || '',
        });
        commitServiceLocally(set, get, updated);
      } catch (e) {
        console.error('Failed to remove song from service', e);
      }
      return;
    }

    const updatedServices = services.map(svc => {
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

  reorderSongsInService: async (serviceId, fromIndex, toIndex) => {
    const { serverUrl, serverToken, services, songs } = get();
    const current = services.find(svc => svc.id === serviceId);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      const songIds = [...current.songIds];
      const [removed] = songIds.splice(fromIndex, 1);
      songIds.splice(toIndex, 0, removed);

      const remoteIds = songIds.map(id => songs.find(s => s.id === id)?.remoteId);
      if (remoteIds.some(id => !id)) {
        console.error('Cannot reorder: some songs are not yet synced with the server.');
        return;
      }

      try {
        const updated = await reorderServiceSongsApi(serverUrl, serverToken, serviceId, {
          updatedAt: current.updatedAt || '',
          orderedSongIds: remoteIds as string[],
        });
        commitServiceLocally(set, get, updated);
      } catch (e) {
        console.error('Failed to reorder service songs', e);
      }
      return;
    }

    const updatedServices = services.map(svc => {
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

  replaceSongInService: async (serviceId, index, newSongId) => {
    const { serverUrl, serverToken, services, songs } = get();
    const current = services.find(svc => svc.id === serviceId);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      const oldLocalId = current.songIds[index];
      const oldSong = songs.find(s => s.id === oldLocalId);
      const newSong = songs.find(s => s.id === newSongId);
      if (!oldSong?.remoteId || !newSong?.remoteId) {
        console.error('Cannot replace song: not yet synced with the server.');
        return;
      }
      try {
        // There is no dedicated "replace" endpoint; a swap is a remove followed by
        // an add back at the same position, chained on each response's updatedAt.
        const afterRemove = await removeSongFromServiceApi(serverUrl, serverToken, serviceId, oldSong.remoteId, {
          updatedAt: current.updatedAt || '',
        });
        const afterAdd = await addSongToServiceApi(serverUrl, serverToken, serviceId, {
          updatedAt: afterRemove.updatedAt,
          songId: newSong.remoteId,
          position: index,
        });
        commitServiceLocally(set, get, afterAdd);
      } catch (e) {
        console.error('Failed to replace song in service', e);
      }
      return;
    }

    const updatedServices = services.map(svc => {
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

  updateSongNotesInService: async (serviceId, index, notes) => {
    const { serverUrl, serverToken, services, songs } = get();
    const current = services.find(svc => svc.id === serviceId);
    if (!current) return;

    if (serverUrl.trim() !== '') {
      const localSongId = current.songIds[index];
      const song = songs.find(s => s.id === localSongId);
      if (!song?.remoteId) {
        console.error('Cannot update note: song is not yet synced with the server.');
        return;
      }
      try {
        const updated = await updateServiceSongNotesApi(serverUrl, serverToken, serviceId, song.remoteId, {
          updatedAt: current.updatedAt || '',
          notes,
        });
        commitServiceLocally(set, get, updated);
      } catch (e) {
        console.error('Failed to update song note', e);
      }
      return;
    }

    const updatedServices = services.map(svc => {
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
      folders: [],
      songRemoteIds: {},
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