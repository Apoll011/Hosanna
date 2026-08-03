// src/store/appStore.ts
import {
    configureApiClient,
    foldersApi,
    getApiClient,
    parseChordPro,
    parseSong,
    servicesApi,
    Song as SharedSong,
    songsApi,
    syncApi,
    SyncStatusResponse,
} from "@hosanna/shared";
import { create } from "zustand";
import {
    Folder,
    Service,
    ServiceElement,
    Song,
    ThemeType,
    VirtualFile,
} from "../types";

export interface AppState {
    virtualFiles: VirtualFile[];
    sourceFolderPath: string;
    songs: Song[];
    services: Service[];
    folders: Folder[];
    favoriteSongIds: string[];
    recentlyPlayedSongIds: string[];
    activeListContext: {
        type:
            | "all"
            | "favorites"
            | "recent"
            | "folder"
            | "search"
            | "service"
            | "circle"
            | "settings"
            | "metronome";
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
    musicianMode: boolean;
    instrument: "guitar" | "piano";
    twoColumnLayout: boolean;
    selectedFolder: string;
    activeSongId: string | null;
    activeServiceId: string | null;
    isEditing: boolean;
    isPresenting: boolean;
    searchQuery: string;
    sortBy: "title" | "number" | "folder";

    syncStatus: "idle" | "syncing" | "success" | "error";
    lastSyncTime: number | null;
    hasSkippedSetup: boolean;

    setTheme: (theme: ThemeType) => void;
    setServerUrl: (url: string) => void;
    setServerToken: (token: string) => void;
    setFontSize: (size: number) => void;
    setShowChords: (show: boolean) => void;
    setShowDiagrams: (show: boolean) => void;
    setKeepScreenAwake: (keep: boolean) => void;
    setSlowDownOnRepeat: (slow: boolean) => void;
    setMusicianMode: (enabled: boolean) => void;
    setInstrument: (instrument: "guitar" | "piano") => void;
    setTwoColumnLayout: (enabled: boolean) => void;
    setSourceFolderPath: (path: string) => void;
    setSelectedFolder: (folder: string) => void;
    setActiveSongId: (id: string | null) => void;
    setActiveServiceId: (id: string | null) => void;
    setIsEditing: (editing: boolean) => void;
    setIsPresenting: (presenting: boolean) => void;
    setSearchQuery: (query: string) => void;
    setSortBy: (sort: "title" | "number" | "folder") => void;

    toggleFavoriteSong: (id: string) => void;
    addRecentlyPlayedSong: (id: string) => void;
    setActiveListContext: (context: AppState["activeListContext"]) => void;
    getActiveSongListIds: () => string[];

    createVirtualFile: (
        folder: string,
        fileName: string,
        content: string,
    ) => void;
    updateVirtualFile: (path: string, content: string) => void;
    deleteVirtualFile: (path: string) => void;

    syncLibrary: (options?: { force?: boolean }) => Promise<void>;
    setHasSkippedSetup: (skipped: boolean) => void;

    updateService: (
        id: string,
        name: string,
        date: string,
        notes?: string,
    ) => void;
    updateServiceElements: (
        serviceId: string,
        elements: ServiceElement[],
    ) => void;
    resetApp: () => void;
}

const DEMO_VIRTUAL_FILES: VirtualFile[] = [];
const INITIAL_SERVICES: Service[] = [];

const getStorageItem = <T>(key: string, defaultValue: T): T => {
    try {
        const item = localStorage.getItem(key);
        return item ? JSON.parse(item) : defaultValue;
    } catch {
        return defaultValue;
    }
};

const storageTimers: Record<string, ReturnType<typeof setTimeout>> = {};

const setStorageItemDebounced = (key: string, value: unknown, delay = 300) => {
    if (storageTimers[key]) clearTimeout(storageTimers[key]);
    storageTimers[key] = setTimeout(() => {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (e) {
            console.warn(`Failed to save ${key} to localStorage`, e);
        }
    }, delay);
};

const setStorageItemImmediate = (key: string, value: unknown) => {
    try {
        localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
        console.warn(`Failed to save ${key} to localStorage`, e);
    }
};

type SetFn = (
    partial: Partial<AppState> | ((s: AppState) => Partial<AppState>),
) => void;
type GetFn = () => AppState;

function ensureApiClient(serverUrl: string, serverToken: string) {
    if (serverUrl && serverUrl.trim() !== "") {
        configureApiClient(serverUrl.trim());
        getApiClient().setTokens(serverToken ? serverToken.trim() : null);
    }
}

const commitSongLocally = (
    set: SetFn,
    get: GetFn,
    apiSong: SharedSong,
    previousLocalId?: string,
) => {
    const folders = get().folders;
    const localSong = parseSong(apiSong, folders);
    const songs = get().songs;
    const virtualFiles = get().virtualFiles;

    const nextSongs = [
        ...songs.filter(
            (s) => s.id !== localSong.id && s.id !== previousLocalId,
        ),
        localSong,
    ];
    const nextFiles = [
        ...virtualFiles.filter(
            (f) => f.path !== localSong.id && f.path !== previousLocalId,
        ),
        {
            path: localSong.id,
            content: localSong.content,
            updatedAt: Date.now(),
        },
    ];

    set({ songs: nextSongs, virtualFiles: nextFiles });
    setStorageItemDebounced("cp_songs_cache", nextSongs);
    setStorageItemDebounced("cp_virtual_files", nextFiles);
};

const commitServiceLocally = (set: SetFn, get: GetFn, apiService: Service) => {
    const services = get().services.map((svc) =>
        svc.id === apiService.id ? apiService : svc,
    );
    set({ services });
    setStorageItemImmediate("cp_services", services);
};

const initialServerUrl = getStorageItem<string>(
    "cp_server_url",
    import.meta.env.VITE_API_URL || "",
);
const initialServerToken = getStorageItem<string>("cp_server_token", "");
ensureApiClient(initialServerUrl, initialServerToken);

// This is keep for backwards compatibility
const initialRawSongs = getStorageItem<
    (Song & {
        remoteId: string;
        remoteUpdatedAt: string;
        parsedUpdatedAt: string;
    })[]
>("cp_songs_cache", []);
const initialSongs: Song[] = initialRawSongs.map((s) => {
    const { remoteId, ...rest } = s;
    if (remoteId && s.id !== remoteId) {
        return { ...rest, id: remoteId };
    }
    return rest as Song;
});
try {
    localStorage.removeItem("cp_song_remote_ids");
} catch {}

export const useAppStore = create<AppState>((set, get) => ({
    virtualFiles: getStorageItem("cp_virtual_files", DEMO_VIRTUAL_FILES),
    sourceFolderPath: getStorageItem(
        "cp_source_folder",
        "/Armazenamento/Canticos_Igreja",
    ),
    songs: initialSongs,
    services: getStorageItem("cp_services", INITIAL_SERVICES),
    folders: getStorageItem("cp_folders", []),
    favoriteSongIds: getStorageItem("cp_favorites", []),
    recentlyPlayedSongIds: getStorageItem("cp_recently_played", []),
    activeListContext: { type: "all" },
    theme: getStorageItem("cp_theme", "light"),
    serverUrl: initialServerUrl,
    serverToken: initialServerToken,
    fontSize: getStorageItem("cp_font_size", 16),
    showChords: getStorageItem("cp_show_chords", true),
    showDiagrams: getStorageItem("cp_show_diagrams", true),
    keepScreenAwake: getStorageItem("cp_keep_awake", true),
    slowDownOnRepeat: getStorageItem("cp_slow_down_repeat", true),
    musicianMode: getStorageItem("cp_musician_mode", false),
    instrument: getStorageItem("cp_instrument", "guitar"),
    twoColumnLayout: getStorageItem("cp_two_column_layout", false),
    selectedFolder: "",
    activeSongId: null,
    activeServiceId: null,
    isEditing: false,
    isPresenting: false,
    searchQuery: "",
    sortBy: "title",
    syncStatus: "idle",
    lastSyncTime: getStorageItem("cp_last_sync_time", null),
    hasSkippedSetup: false,

    setTheme: (theme) => {
        set({ theme });
        setStorageItemImmediate("cp_theme", theme);
    },
    setServerUrl: (serverUrl) => {
        set({ serverUrl });
        setStorageItemImmediate("cp_server_url", serverUrl);
        ensureApiClient(serverUrl, get().serverToken);
    },
    setServerToken: (serverToken) => {
        set({ serverToken });
        setStorageItemImmediate("cp_server_token", serverToken);
        ensureApiClient(get().serverUrl, serverToken);
    },
    setFontSize: (fontSize) => {
        set({ fontSize });
        setStorageItemImmediate("cp_font_size", fontSize);
    },
    setShowChords: (showChords) => {
        set({ showChords });
        setStorageItemImmediate("cp_show_chords", showChords);
    },
    setShowDiagrams: (showDiagrams) => {
        set({ showDiagrams });
        setStorageItemImmediate("cp_show_diagrams", showDiagrams);
    },
    setKeepScreenAwake: (keepScreenAwake) => {
        set({ keepScreenAwake });
        setStorageItemImmediate("cp_keep_awake", keepScreenAwake);
    },
    setSlowDownOnRepeat: (slowDownOnRepeat) => {
        set({ slowDownOnRepeat });
        setStorageItemImmediate("cp_slow_down_repeat", slowDownOnRepeat);
    },
    setMusicianMode: (musicianMode) => {
        set({ musicianMode });
        setStorageItemImmediate("cp_musician_mode", musicianMode);
    },
    setInstrument: (instrument) => {
        set({ instrument });
        setStorageItemImmediate("cp_instrument", instrument);
    },
    setTwoColumnLayout: (twoColumnLayout) => {
        set({ twoColumnLayout });
        setStorageItemImmediate("cp_two_column_layout", twoColumnLayout);
    },
    setSourceFolderPath: (sourceFolderPath) => {
        set({ sourceFolderPath });
        setStorageItemImmediate("cp_source_folder", sourceFolderPath);
    },
    setSelectedFolder: (selectedFolder) => set({ selectedFolder }),
    setActiveSongId: (activeSongId) => set({ activeSongId }),
    setActiveServiceId: (activeServiceId) => set({ activeServiceId }),
    setIsEditing: (isEditing) => set({ isEditing }),
    setIsPresenting: (isPresenting) => set({ isPresenting }),
    setSearchQuery: (searchQuery) => set({ searchQuery }),
    setSortBy: (sortBy) => set({ sortBy }),
    setHasSkippedSetup: (hasSkippedSetup) => set({ hasSkippedSetup }),

    toggleFavoriteSong: (id) => {
        const favoriteSongIds = get().favoriteSongIds;
        const isFav = favoriteSongIds.includes(id);
        const updated = isFav
            ? favoriteSongIds.filter((fId) => fId !== id)
            : [...favoriteSongIds, id];
        set({ favoriteSongIds: updated });
        setStorageItemImmediate("cp_favorites", updated);
    },
    addRecentlyPlayedSong: (id) => {
        const current = get().recentlyPlayedSongIds;
        const filtered = current.filter((x) => x !== id);
        const updated = [id, ...filtered].slice(0, 50);
        set({ recentlyPlayedSongIds: updated });
        setStorageItemImmediate("cp_recently_played", updated);
    },
    setActiveListContext: (activeListContext) => {
        set({ activeListContext });
    },
    getActiveSongListIds: () => {
        const state = get();
        const context = state.activeListContext;

        if (context.type === "service") {
            const service = state.services.find(
                (s) => s.id === context.serviceId,
            );
            if (!service) return [];

            return (service.elements || [])
                .filter((e) => e.type === "song" && e.songId)
                .map((e) => {
                    const localSong = state.songs.find(
                        (s) => s.id === e.songId,
                    );
                    return localSong?.id;
                })
                .filter(Boolean) as string[];
        }

        let list = [...state.songs];

        list.sort((a, b) => {
            if (state.sortBy === "number") {
                const numA = parseInt(a.metadata?.songNumber || "99999");
                const numB = parseInt(b.metadata?.songNumber || "99999");
                return numA - numB;
            } else if (state.sortBy === "folder") {
                const fComp = a.folder.localeCompare(b.folder);
                if (fComp !== 0) return fComp;
                return a.title.localeCompare(b.title);
            } else {
                return a.title.localeCompare(b.title);
            }
        });

        if (context.type === "favorites")
            return list
                .filter((s) => state.favoriteSongIds.includes(s.id))
                .map((s) => s.id);
        if (context.type === "recent")
            return state.recentlyPlayedSongIds.filter((id) =>
                list.some((s) => s.id === id),
            );
        if (context.type === "folder")
            return list
                .filter((s) => s.folder === context.folderName)
                .map((s) => s.id);
        if (context.type === "search") {
            const q = (context.searchQuery || "").toLowerCase().trim();
            if (q !== "") {
                return list
                    .filter((song) => {
                        const titleMatch = song.title.toLowerCase().includes(q);
                        const artistMatch =
                            song.artist?.toLowerCase().includes(q) || false;
                        const numberMatch =
                            song.metadata?.songNumber?.includes(q) || false;
                        const keyMatch =
                            song.metadata?.key?.toLowerCase().includes(q) ||
                            false;
                        const lyricsMatch = song.content
                            .toLowerCase()
                            .includes(q);
                        return (
                            titleMatch ||
                            artistMatch ||
                            numberMatch ||
                            keyMatch ||
                            lyricsMatch
                        );
                    })
                    .map((s) => s.id);
            }
        }

        return list.map((s) => s.id);
    },

    createVirtualFile: async (folder, fileName, content) => {
        const folderSelection = folder.trim();
        const matchedFolder = get().folders.find(
            (folderItem) =>
                folderItem.id === folderSelection ||
                folderItem.name === folderSelection,
        );
        const resolvedFolderName = matchedFolder?.name || folderSelection;
        const cleanFolder = resolvedFolderName.trim().replace(/^\/?|\/$/g, "");
        const cleanFileName = fileName.trim().endsWith(".chopro")
            ? fileName.trim()
            : `${fileName.trim()}.chopro`;
        const fullPath = cleanFolder
            ? `${cleanFolder}/${cleanFileName}`
            : cleanFileName;

        const files = get().virtualFiles;
        if (
            files.some((f) => f.path.toLowerCase() === fullPath.toLowerCase())
        ) {
            throw new Error(
                `Um ficheiro com o caminho "${fullPath}" já existe.`,
            );
        }

        const { serverUrl, serverToken } = get();
        const parsed = parseChordPro(content);

        if (serverUrl.trim() !== "") {
            ensureApiClient(serverUrl, serverToken);
            const created = await songsApi.createSong({
                title:
                    parsed.metadata.title ||
                    cleanFileName.replace(/\.chopro$/i, ""),
                artist: parsed.metadata.artist,
                content,
                folderId: matchedFolder?.id ?? null,
                path: fullPath,
            });
            commitSongLocally(set, get, created);
            return;
        }

        const newFile: VirtualFile = {
            path: fullPath,
            content,
            updatedAt: Date.now(),
        };
        const updatedFiles = [newFile, ...files];
        set({ virtualFiles: updatedFiles });
        setStorageItemDebounced("cp_virtual_files", updatedFiles);
        get().syncLibrary();
    },

    updateVirtualFile: async (path, content) => {
        const { serverUrl, serverToken, songs } = get();

        if (serverUrl.trim() !== "") {
            const existing = songs.find((s) => s.id === path);
            if (!existing) {
                throw new Error(
                    "Não foi possível encontrar este cântico no servidor. Sincronize e tente novamente.",
                );
            }
            ensureApiClient(serverUrl, serverToken);
            const parsed = parseChordPro(content);
            const updated = await songsApi.updateSong(existing.id, {
                updatedAt: existing.updatedAt || new Date().toISOString(),
                title: parsed.metadata.title || existing.title,
                content,
                folderId: existing.folderId ?? null,
                tags: existing.tags || [],
            });
            commitSongLocally(set, get, updated, path);
            return;
        }

        const updatedFiles = get().virtualFiles.map((file) =>
            file.path === path
                ? { ...file, content, updatedAt: Date.now() }
                : file,
        );
        set({ virtualFiles: updatedFiles });
        setStorageItemDebounced("cp_virtual_files", updatedFiles);
        get().syncLibrary();
    },

    deleteVirtualFile: async (path) => {
        const { serverUrl, serverToken, songs } = get();

        if (serverUrl.trim() !== "") {
            const existing = songs.find((s) => s.id === path);
            if (existing) {
                ensureApiClient(serverUrl, serverToken);
                await songsApi.deleteSong(existing.id);
            }
        }

        const updatedFiles = get().virtualFiles.filter(
            (file) => file.path !== path,
        );
        const updatedSongs = get().songs.filter((s) => s.id !== path);

        set({ virtualFiles: updatedFiles, songs: updatedSongs });
        setStorageItemDebounced("cp_virtual_files", updatedFiles);
        setStorageItemDebounced("cp_songs_cache", updatedSongs);

        if (get().activeSongId === path)
            set({ activeSongId: null, isEditing: false });
    },

    syncLibrary: async (options) => {
        set({ syncStatus: "syncing" });
        const {
            serverUrl,
            serverToken,
            songs: currentSongs,
            folders: currentFolders,
            services: currentServices,
        } = get();

        if (!serverUrl || serverUrl.trim() === "") {
            const now = Date.now();
            set({ syncStatus: "success", lastSyncTime: now });
            setStorageItemImmediate("cp_last_sync_time", now);
            return;
        }

        ensureApiClient(serverUrl, serverToken);

        try {
            let status: SyncStatusResponse | null = null;
            try {
                status = await syncApi.getStatus();
            } catch (err) {
                console.warn(
                    "Could not fetch server sync status, falling back to full sync:",
                    err,
                );
            }

            const lastSyncTimestamps = getStorageItem<Record<string, string>>(
                "cp_last_sync_timestamps",
                {},
            );

            const force = options?.force === true;
            const songsChanged =
                force ||
                !status ||
                !lastSyncTimestamps.songs ||
                lastSyncTimestamps.songs !== status.timestamps.songs ||
                currentSongs.length === 0;

            const foldersChanged =
                force ||
                !status ||
                !lastSyncTimestamps.folders ||
                lastSyncTimestamps.folders !== status.timestamps.folders ||
                currentFolders.length === 0;

            const servicesChanged =
                force ||
                !status ||
                !lastSyncTimestamps.services ||
                lastSyncTimestamps.services !== status.timestamps.services ||
                currentServices.length === 0;

            if (!songsChanged && !foldersChanged && !servicesChanged) {
                const now = Date.now();
                set({ syncStatus: "success", lastSyncTime: now });
                setStorageItemImmediate("cp_last_sync_time", now);
                return;
            }

            let folders: Folder[] = currentFolders;
            if (foldersChanged) {
                folders = await foldersApi.getFlatFolders();
            }

            let services: Service[] = currentServices;
            if (servicesChanged) {
                services = await servicesApi.getServices();
            }

            let finalSongs: Song[] = currentSongs;
            let virtualFiles: VirtualFile[] = get().virtualFiles;

            if (songsChanged) {
                const firstPage = await songsApi.getParsedSongs(
                    {
                        page: 1,
                        limit: 200,
                        sortBy: "title",
                        sortOrder: "asc",
                    },
                    folders,
                );

                let apiSongs = [...firstPage.songs];
                if (firstPage.totalPages > 1) {
                    const remainingPages = await Promise.all(
                        Array.from(
                            { length: firstPage.totalPages - 1 },
                            (_, i) =>
                                songsApi.getParsedSongs(
                                    {
                                        page: i + 2,
                                        limit: 200,
                                        sortBy: "title",
                                        sortOrder: "asc",
                                    },
                                    folders,
                                ),
                        ),
                    );
                    remainingPages.forEach((page) =>
                        apiSongs.push(...page.songs),
                    );
                }

                finalSongs = apiSongs;
                virtualFiles = finalSongs.map((s) => ({
                    path: s.id,
                    content: s.content,
                    updatedAt: Date.now(),
                }));
            }

            const finalSongIds = new Set(finalSongs.map((s) => s.id));
            const updatedFavorites = get().favoriteSongIds.filter((id) =>
                finalSongIds.has(id),
            );
            const updatedRecent = get().recentlyPlayedSongIds.filter((id) =>
                finalSongIds.has(id),
            );

            const now = Date.now();
            const newTimestamps = status?.timestamps
                ? {
                      songs: status.timestamps.songs,
                      folders: status.timestamps.folders,
                      services: status.timestamps.services,
                  }
                : lastSyncTimestamps;

            set({
                folders,
                services,
                virtualFiles,
                songs: finalSongs,
                favoriteSongIds: updatedFavorites,
                recentlyPlayedSongIds: updatedRecent,
                syncStatus: "success",
                lastSyncTime: now,
            });

            setStorageItemImmediate("cp_folders", folders);
            setStorageItemImmediate("cp_services", services);
            setStorageItemDebounced("cp_virtual_files", virtualFiles);
            setStorageItemDebounced("cp_songs_cache", finalSongs);
            setStorageItemImmediate("cp_favorites", updatedFavorites);
            setStorageItemImmediate("cp_favorites", updatedFavorites);
            setStorageItemImmediate("cp_recently_played", updatedRecent);
            setStorageItemImmediate("cp_last_sync_time", now);
            setStorageItemImmediate("cp_last_sync_timestamps", newTimestamps);
        } catch (err) {
            console.error("Erro na sincronização remota:", err);
            set({ syncStatus: "error" });
            throw err;
        }
    },

    updateService: async (id, name, date, notes) => {
        const { serverUrl, serverToken, services } = get();
        const current = services.find((svc) => svc.id === id);
        if (!current) return;

        if (serverUrl.trim() !== "") {
            try {
                ensureApiClient(serverUrl, serverToken);
                const updated = await servicesApi.updateService(id, {
                    updatedAt: current.updatedAt || new Date().toISOString(),
                    name,
                    date,
                    notes,
                });
                commitServiceLocally(set, get, updated);
            } catch (e) {
                console.error("Failed to update service", e);
            }
            return;
        }

        const updatedServices = services.map((svc) =>
            svc.id === id ? { ...svc, name, date, notes } : svc,
        );
        set({ services: updatedServices });
        setStorageItemImmediate("cp_services", updatedServices);
    },

    updateServiceElements: async (serviceId, elements) => {
        const { serverUrl, serverToken, services } = get();
        const current = services.find((svc) => svc.id === serviceId);
        if (!current) return;

        if (serverUrl.trim() !== "") {
            try {
                ensureApiClient(serverUrl, serverToken);
                const updated = await servicesApi.updateServiceElements(
                    serviceId,
                    {
                        updatedAt:
                            current.updatedAt || new Date().toISOString(),
                        elements,
                    },
                );
                commitServiceLocally(set, get, updated);
            } catch (e) {
                console.error("Failed to update service elements", e);
            }
            return;
        }

        const updatedServices = services.map((svc) =>
            svc.id === serviceId ? { ...svc, elements } : svc,
        );
        set({ services: updatedServices });
        setStorageItemImmediate("cp_services", updatedServices);
    },

    resetApp: () => {
        set({
            virtualFiles: [],
            songs: [],
            services: [],
            folders: [],
            activeSongId: null,
            activeServiceId: null,
            isEditing: false,
            isPresenting: false,
            searchQuery: "",
            selectedFolder: "",
            syncStatus: "idle",
            lastSyncTime: null,
        });
        localStorage.removeItem("cp_virtual_files");
        localStorage.removeItem("cp_songs_cache");
        localStorage.removeItem("cp_services");
        localStorage.removeItem("cp_last_sync_time");
        localStorage.removeItem("cp_last_sync_timestamps");
        localStorage.removeItem("cp_song_remote_ids");
    },
}));
