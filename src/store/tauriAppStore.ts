/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { create } from 'zustand';
import { Song, Service, VirtualFile, SyncReport, ThemeType } from '../types';
import { parseChordPro } from '../lib/chordpro';
import Database from '@tauri-apps/plugin-sql';

interface AppState {
  virtualFiles: VirtualFile[];
  sourceFolderPath: string;
  songs: Song[];
  services: Service[];
  favoriteSongIds: string[];
  recentlyPlayedSongIds: string[];
  activeListContext: {
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service';
    serviceId?: string;
    folderName?: string;
    searchQuery?: string;
  };
  theme: ThemeType;
  serverUrl: string;
  serverToken: string;
  fontSize: number;
  showChords: boolean;
  showDiagrams: boolean;
  keepScreenAwake: boolean;
  slowDownOnRepeat: boolean;
  instrument: 'guitar' | 'piano';
  selectedFolder: string;
  activeSongId: string | null;
  activeServiceId: string | null;
  isEditing: boolean;
  searchQuery: string;
  sortBy: 'title' | 'number' | 'folder';
  syncStatus: 'idle' | 'syncing' | 'success' | 'error';
  lastSyncTime: number | null;
  syncReport: SyncReport | null;

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
  toggleFavoriteSong: (id: string) => void;
  addRecentlyPlayedSong: (id: string) => void;
  setActiveListContext: (context: {
    type: 'all' | 'favorites' | 'recent' | 'folder' | 'search' | 'service';
    serviceId?: string;
    folderName?: string;
    searchQuery?: string;
  }) => void;
  getActiveSongListIds: () => string[];
  createVirtualFile: (folder: string, fileName: string, content: string) => Promise<void>;
  updateVirtualFile: (path: string, content: string) => Promise<void>;
  deleteVirtualFile: (path: string) => Promise<void>;
  syncLibrary: () => Promise<SyncReport>;
  createService: (name: string, date: string) => void;
  updateService: (id: string, name: string, date: string, notes?: string) => void;
  deleteService: (id: string) => void;
  addSongToService: (serviceId: string, songId: string) => void;
  removeSongFromService: (serviceId: string, index: number) => void;
  reorderSongsInService: (serviceId: string, fromIndex: number, toIndex: number) => void;
  replaceSongInService: (serviceId: string, index: number, newSongId: string) => void;
  updateSongNotesInService: (serviceId: string, index: number, notes: string) => void;
  resetToDemo: () => void;
  initDb: () => Promise<void>;
}

let db: Database | null = null;

const DEMO_VIRTUAL_FILES: VirtualFile[] = [
  {
    path: "Adoração/Digno_és_Tu.chopro",
    content: `{title: Digno és Tu}\n{artist: Aline Barros}\n{key: G}\n{tempo: 72}\n{song_number: 101}\n{capo: 0}\n\n{start_of_chorus: Refrão}\nDigno és [G]Tu, digno és [D]Tu\nDigno és [C]Tu, Senhor de [G]receber [D]\nA [G]glória, a [D]honra\nE o po[C]der, para [G]sempre. [D]\n{end_of_chorus}\n\n[G]Graças te damos, Se[D]nhor e Deus nosso\nPor [C]Tua bondade e [G]amor sem fi[D]m\n[G]Criaste todas as [D]coisas no mundo\nPor [C]Tua vontade exis[G]tem a[D]qui.\n\n{comment: Repetir o Refrão com júbilo}\n`,
    updatedAt: Date.now()
  },
  {
    path: "Geral/Grande_é_o_Senhor.chopro",
    content: `{title: Grande é o Senhor}\n{artist: Adoração & Adoradores}\n{key: C}\n{tempo: 80}\n{song_number: 45}\n\n[C]Grande é o Se[F]nhor e mui digno de lou[C]vor [F]\nNa ci[C]dade do nosso Deus, no seu [Am]monte santo\nA[Dm]gria de toda a [G]terra.\n\n[C]Grande é o Se[F]nhor em quem nós temos a vi[C]tória [F]\nQue nos [C]ajuda contra o ini[Am]migo\nPor isso nos pros[Dm]tramos diante d[G]Ele.\n\n{start_of_chorus: Refrão}\nQueremos o Teu [C]nome exal[Em]tar\nE [F]agradecer-Te por [G]tudo o que tens feito em [C]nós [Em]\nCon[F]fiamos no Teu in[G]finito amor\nPois só [F]Tu és Deus e[G]terno\nSobre [F]toda a [G]terra e [C]céus.\n{end_of_chorus}\n`,
    updatedAt: Date.now() - 10000
  }
];

const INITIAL_SERVICES: Service[] = [
  {
    id: "service-1",
    name: "Culto de Domingo de Manhã",
    date: "2026-07-19",
    songIds: ["Adoração/Digno_és_Tu.chopro", "Geral/Grande_é_o_Senhor.chopro"],
    notes: "Preparar pregação antes do cântico de transição. Aline Barros guia o refrão repetidamente."
  }
];

async function getDb() {
  if (db) return db;
  db = await Database.load("sqlite:hosanna.db");
  await db.execute(`
    CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);
    CREATE TABLE IF NOT EXISTS virtual_files (path TEXT PRIMARY KEY, content TEXT, updatedAt INTEGER);
    CREATE TABLE IF NOT EXISTS songs_cache (id TEXT PRIMARY KEY, data TEXT);
    CREATE TABLE IF NOT EXISTS services (id TEXT PRIMARY KEY, data TEXT);
    CREATE TABLE IF NOT EXISTS favorites (id TEXT PRIMARY KEY);
    CREATE TABLE IF NOT EXISTS recently_played (id TEXT PRIMARY KEY, timestamp INTEGER);
  `);
  return db;
}

async function saveSetting(key: string, value: any) {
  const database = await getDb();
  await database.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", [key, JSON.stringify(value)]);
}

async function loadSetting<T>(key: string, defaultValue: T): Promise<T> {
  const database = await getDb();
  const res = await database.select<{ value: string }[]>("SELECT value FROM settings WHERE key = ?", [key]);
  if (res.length > 0) {
    try {
      return JSON.parse(res[0].value);
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

export const useAppStore = create<AppState>((set, get) => ({
  virtualFiles: [],
  sourceFolderPath: '/Armazenamento/Canticos_Igreja',
  songs: [],
  services: INITIAL_SERVICES,
  favoriteSongIds: [],
  recentlyPlayedSongIds: [],
  activeListContext: { type: 'all' },
  theme: 'light',
  serverUrl: '',
  serverToken: '',
  fontSize: 16,
  showChords: true,
  showDiagrams: true,
  keepScreenAwake: true,
  slowDownOnRepeat: true,
  instrument: 'guitar',
  selectedFolder: '',
  activeSongId: null,
  activeServiceId: null,
  isEditing: false,
  searchQuery: '',
  sortBy: 'title',
  syncStatus: 'idle',
  lastSyncTime: null,
  syncReport: null,

  initDb: async () => {
    const virtualFiles = await loadSetting('cp_virtual_files', DEMO_VIRTUAL_FILES);
    const sourceFolderPath = await loadSetting('cp_source_folder', '/Armazenamento/Canticos_Igreja');
    const songs = await loadSetting('cp_songs_cache', []);
    const services = await loadSetting('cp_services', INITIAL_SERVICES);
    const favoriteSongIds = await loadSetting('cp_favorites', []);
    const recentlyPlayedSongIds = await loadSetting('cp_recently_played', []);
    const theme = await loadSetting('cp_theme', 'light');
    const serverUrl = await loadSetting('cp_server_url', '');
    const serverToken = await loadSetting('cp_server_token', '');
    const fontSize = await loadSetting('cp_font_size', 16);
    const showChords = await loadSetting('cp_show_chords', true);
    const showDiagrams = await loadSetting('cp_show_diagrams', true);
    const keepScreenAwake = await loadSetting('cp_keep_awake', true);
    const slowDownOnRepeat = await loadSetting('cp_slow_down_repeat', true);
    const instrument = await loadSetting('cp_instrument', 'guitar');
    const lastSyncTime = await loadSetting('cp_last_sync_time', null);

    set({
      virtualFiles,
      sourceFolderPath,
      songs,
      services,
      favoriteSongIds,
      recentlyPlayedSongIds,
      theme,
      serverUrl,
      serverToken,
      fontSize,
      showChords,
      showDiagrams,
      keepScreenAwake,
      slowDownOnRepeat,
      instrument,
      lastSyncTime
    });
  },

  setTheme: (theme) => {
    set({ theme });
    saveSetting('cp_theme', theme);
  },
  setServerUrl: (serverUrl) => {
    set({ serverUrl });
    saveSetting('cp_server_url', serverUrl);
  },
  setServerToken: (serverToken) => {
    set({ serverToken });
    saveSetting('cp_server_token', serverToken);
  },
  setFontSize: (fontSize) => {
    set({ fontSize });
    saveSetting('cp_font_size', fontSize);
  },
  setShowChords: (showChords) => {
    set({ showChords });
    saveSetting('cp_show_chords', showChords);
  },
  setShowDiagrams: (showDiagrams) => {
    set({ showDiagrams });
    saveSetting('cp_show_diagrams', showDiagrams);
  },
  setKeepScreenAwake: (keepScreenAwake) => {
    set({ keepScreenAwake });
    saveSetting('cp_keep_awake', keepScreenAwake);
  },
  setSlowDownOnRepeat: (slowDownOnRepeat) => {
    set({ slowDownOnRepeat });
    saveSetting('cp_slow_down_repeat', slowDownOnRepeat);
  },
  setInstrument: (instrument) => {
    set({ instrument });
    saveSetting('cp_instrument', instrument);
  },
  setSourceFolderPath: (sourceFolderPath) => {
    set({ sourceFolderPath });
    saveSetting('cp_source_folder', sourceFolderPath);
  },
  setSelectedFolder: (selectedFolder) => set({ selectedFolder }),
  setActiveSongId: (activeSongId) => set({ activeSongId }),
  setActiveServiceId: (activeServiceId) => set({ activeServiceId }),
  setIsEditing: (isEditing) => set({ isEditing }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setSortBy: (sortBy) => set({ sortBy }),

  toggleFavoriteSong: (id) => {
    const favoriteSongIds = get().favoriteSongIds;
    const isFav = favoriteSongIds.includes(id);
    const updated = isFav ? favoriteSongIds.filter(fId => fId !== id) : [...favoriteSongIds, id];
    set({ favoriteSongIds: updated });
    saveSetting('cp_favorites', updated);
  },
  addRecentlyPlayedSong: (id) => {
    const current = get().recentlyPlayedSongIds;
    const filtered = current.filter(x => x !== id);
    const updated = [id, ...filtered].slice(0, 50);
    set({ recentlyPlayedSongIds: updated });
    saveSetting('cp_recently_played', updated);
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
    if (context.type === 'favorites') return list.filter(s => state.favoriteSongIds.includes(s.id)).map(s => s.id);
    if (context.type === 'recent') return state.recentlyPlayedSongIds.filter(id => list.some(s => s.id === id));
    if (context.type === 'folder') return list.filter(s => s.folder === context.folderName).map(s => s.id);
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

  createVirtualFile: async (folder, fileName, content) => {
    const cleanFolder = folder.trim().replace(/^\/|\/$/g, '');
    const cleanFileName = fileName.trim().endsWith('.chopro') ? fileName.trim() : `${fileName.trim()}.chopro`;
    const fullPath = cleanFolder ? `${cleanFolder}/${cleanFileName}` : cleanFileName;
    const files = get().virtualFiles;
    if (files.some(f => f.path.toLowerCase() === fullPath.toLowerCase())) throw new Error(`Already exists`);
    const newFile: VirtualFile = { path: fullPath, content, updatedAt: Date.now() };
    const updatedFiles = [newFile, ...files];
    set({ virtualFiles: updatedFiles });
    await saveSetting('cp_virtual_files', updatedFiles);
    get().syncLibrary().catch(() => {});
  },
  updateVirtualFile: async (path, content) => {
    const updatedFiles = get().virtualFiles.map(file => file.path === path ? { ...file, content, updatedAt: Date.now() } : file);
    set({ virtualFiles: updatedFiles });
    await saveSetting('cp_virtual_files', updatedFiles);
    get().syncLibrary().catch(() => {});
  },
  deleteVirtualFile: async (path) => {
    const updatedFiles = get().virtualFiles.filter(file => file.path !== path);
    set({ virtualFiles: updatedFiles });
    await saveSetting('cp_virtual_files', updatedFiles);
    get().syncLibrary().catch(() => {});
    if (get().activeSongId === path) set({ activeSongId: null, isEditing: false });
  },

  syncLibrary: async () => {
    set({ syncStatus: 'syncing', syncReport: null });
    // Simplified sync for offline Tauri version
    try {
      const vFiles = get().virtualFiles;
      const cachedSongs = get().songs;
      const added: string[] = [];
      const modified: string[] = [];
      const deleted: string[] = [];
      const finalSongs: Song[] = [];
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
        if (!cached) added.push(file.path);
        else if (cached.content !== file.content || cached.updatedAt !== file.updatedAt) modified.push(file.path);
        finalSongs.push(songObj);
        cacheMap.delete(file.path);
      }
      for (const [deletedId] of cacheMap) deleted.push(deletedId);
      const now = Date.now();
      const report: SyncReport = { added, modified, deleted, conflicts: [] };
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
      await saveSetting('cp_songs_cache', finalSongs);
      await saveSetting('cp_favorites', updatedFavorites);
      await saveSetting('cp_recently_played', updatedRecent);
      await saveSetting('cp_last_sync_time', now);
      return report;
    } catch (error) {
      set({ syncStatus: 'error' });
      throw error;
    }
  },

  createService: (name, date) => {
    const id = `service-${Date.now()}`;
    const newService = { id, name, date, songIds: [], notes: '' };
    const updatedServices = [newService, ...get().services];
    set({ services: updatedServices, activeServiceId: id });
    saveSetting('cp_services', updatedServices);
  },
  updateService: (id, name, date, notes) => {
    const updatedServices = get().services.map(svc => svc.id === id ? { ...svc, name, date, notes } : svc);
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
  },
  deleteService: (id) => {
    const updatedServices = get().services.filter(svc => svc.id !== id);
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
    if (get().activeServiceId === id) set({ activeServiceId: null });
  },
  addSongToService: (serviceId, songId) => {
    const updatedServices = get().services.map(svc => svc.id === serviceId ? { ...svc, songIds: [...svc.songIds, songId] } : svc);
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
  },
  removeSongFromService: (serviceId, index) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const updatedSongs = [...svc.songIds];
        updatedSongs.splice(index, 1);
        return { ...svc, songIds: updatedSongs };
      }
      return svc;
    });
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
  },
  reorderSongsInService: (serviceId, fromIndex, toIndex) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const songIds = [...svc.songIds];
        const [removed] = songIds.splice(fromIndex, 1);
        songIds.splice(toIndex, 0, removed);
        return { ...svc, songIds };
      }
      return svc;
    });
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
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
    saveSetting('cp_services', updatedServices);
  },
  updateSongNotesInService: (serviceId, index, notes) => {
    const updatedServices = get().services.map(svc => {
      if (svc.id === serviceId) {
        const songNotes = { ...(svc.songNotes || {}) };
        if (notes.trim() === '') delete songNotes[index.toString()];
        else songNotes[index.toString()] = notes;
        return { ...svc, songNotes };
      }
      return svc;
    });
    set({ services: updatedServices });
    saveSetting('cp_services', updatedServices);
  },
  resetToDemo: () => {
    set({ virtualFiles: DEMO_VIRTUAL_FILES, songs: [], services: INITIAL_SERVICES, activeSongId: null, activeServiceId: null, isEditing: false, searchQuery: '', selectedFolder: '', syncReport: null, syncStatus: 'idle', lastSyncTime: null });
    saveSetting('cp_virtual_files', DEMO_VIRTUAL_FILES);
    saveSetting('cp_songs_cache', []);
    saveSetting('cp_services', INITIAL_SERVICES);
    saveSetting('cp_last_sync_time', null);
  }
}));
