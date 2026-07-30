// src/store/appStore.ts
import { create } from "zustand";
import {
    Song,
    Service,
    VirtualFile,
    ThemeType,
    Folder,
    ServiceElement,
} from "../types";
import { parseChordPro } from "../lib/chordpro";
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
    updateServiceElementsApi,
} from "../lib/apiClient";

interface AppState {
    virtualFiles: VirtualFile[];
    sourceFolderPath: string;
    songs: Song[];
    services: Service[];
    folders: Folder[];
    songRemoteIds: Record<string, string>;
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
    instrument: "guitar" | "piano";
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
    setInstrument: (instrument: "guitar" | "piano") => void;
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

    syncLibrary: () => void;
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

type SetFn = (
    partial: Partial<AppState> | ((s: AppState) => Partial<AppState>),
) => void;
type GetFn = () => AppState;

const toLocalSong = (apiSong: ApiSong, folders: Folder[]): Song => {
    const parsed = parseChordPro(apiSong.content);
    const parts = apiSong.path.split("/");
    const fileName = parts.pop() || "";
    const folder = apiSong.folderId
        ? folders.find((folderItem) => folderItem.id === apiSong.folderId)
              ?.name || ""
        : "";
    const parsedTimestamp = Date.parse(apiSong.updatedAt);

    return {
        id: apiSong.path,
        remoteId: apiSong.id,
        remoteUpdatedAt: apiSong.updatedAt,
        title: apiSong.title || parsed.metadata.title || "Sem Título",
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
        tags: apiSong.tags || [],
    };
};

const toLSong =
    (folders: Folder[]) =>
    (apiSong: ApiSong): Song =>
        toLocalSong(apiSong, folders);

const toLocalService = (apiService: ApiService): Service => {
    return {
        id: apiService.id,
        name: apiService.name,
        date: apiService.date,
        notes: apiService.notes,
        elements: apiService.elements || [],
        updatedAt: apiService.updatedAt,
    };
};

const commitSongLocally = (
    set: SetFn,
    get: GetFn,
    apiSong: ApiSong,
    previousLocalId?: string,
) => {
    const folders = get().folders;
    const localSong = toLocalSong(apiSong, folders);
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
            updatedAt: localSong.updatedAt,
        },
    ];

    const songRemoteIds = { ...get().songRemoteIds };
    if (previousLocalId) delete songRemoteIds[previousLocalId];
    songRemoteIds[localSong.id] = apiSong.id;

    set({ songs: nextSongs, virtualFiles: nextFiles, songRemoteIds });
    setStorageItem("cp_songs_cache", nextSongs);
    setStorageItem("cp_virtual_files", nextFiles);
    setStorageItem("cp_song_remote_ids", songRemoteIds);
};

const commitServiceLocally = (
    set: SetFn,
    get: GetFn,
    apiService: ApiService,
) => {
    const localService = toLocalService(apiService);
    const services = get().services.map((svc) =>
        svc.id === localService.id ? localService : svc,
    );
    set({ services });
    setStorageItem("cp_services", services);
};

export const useAppStore = create<AppState>((set, get) => ({
    virtualFiles: getStorageItem("cp_virtual_files", DEMO_VIRTUAL_FILES),
    sourceFolderPath: getStorageItem(
        "cp_source_folder",
        "/Armazenamento/Canticos_Igreja",
    ),
    songs: getStorageItem("cp_songs_cache", []),
    services: getStorageItem("cp_services", INITIAL_SERVICES),
    folders: getStorageItem("cp_folders", []),
    songRemoteIds: getStorageItem("cp_song_remote_ids", {}),
    favoriteSongIds: getStorageItem("cp_favorites", []),
    recentlyPlayedSongIds: getStorageItem("cp_recently_played", []),
    activeListContext: { type: "all" },
    theme: getStorageItem("cp_theme", "light"),
    serverUrl: getStorageItem(
        "cp_server_url",
        import.meta.env.VITE_API_URL || "",
    ),
    serverToken: getStorageItem("cp_server_token", ""),
    fontSize: getStorageItem("cp_font_size", 16),
    showChords: getStorageItem("cp_show_chords", true),
    showDiagrams: getStorageItem("cp_show_diagrams", true),
    keepScreenAwake: getStorageItem("cp_keep_awake", true),
    slowDownOnRepeat: getStorageItem("cp_slow_down_repeat", true),
    instrument: getStorageItem("cp_instrument", "guitar"),
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
        setStorageItem("cp_theme", theme);
    },
    setServerUrl: (serverUrl) => {
        set({ serverUrl });
        setStorageItem("cp_server_url", serverUrl);
    },
    setServerToken: (serverToken) => {
        set({ serverToken });
        setStorageItem("cp_server_token", serverToken);
    },
    setFontSize: (fontSize) => {
        set({ fontSize });
        setStorageItem("cp_font_size", fontSize);
    },
    setShowChords: (showChords) => {
        set({ showChords });
        setStorageItem("cp_show_chords", showChords);
    },
    setShowDiagrams: (showDiagrams) => {
        set({ showDiagrams });
        setStorageItem("cp_show_diagrams", showDiagrams);
    },
    setKeepScreenAwake: (keepScreenAwake) => {
        set({ keepScreenAwake });
        setStorageItem("cp_keep_awake", keepScreenAwake);
    },
    setSlowDownOnRepeat: (slowDownOnRepeat) => {
        set({ slowDownOnRepeat });
        setStorageItem("cp_slow_down_repeat", slowDownOnRepeat);
    },
    setInstrument: (instrument) => {
        set({ instrument });
        setStorageItem("cp_instrument", instrument);
    },
    setSourceFolderPath: (sourceFolderPath) => {
        set({ sourceFolderPath });
        setStorageItem("cp_source_folder", sourceFolderPath);
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
        setStorageItem("cp_favorites", updated);
    },
    addRecentlyPlayedSong: (id) => {
        const current = get().recentlyPlayedSongIds;
        const filtered = current.filter((x) => x !== id);
        const updated = [id, ...filtered].slice(0, 50);
        set({ recentlyPlayedSongIds: updated });
        setStorageItem("cp_recently_played", updated);
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

            // Resolve element.songId (remoteId) to the local song.id representation
            return (service.elements || [])
                .filter((e) => e.type === "song" && e.songId)
                .map((e) => {
                    const localSong =
                        state.songs.find((s) => s.remoteId === e.songId) ??
                        state.songs.find((s) => s.id === e.songId);
                    return localSong?.id;
                })
                .filter(Boolean) as string[];
        }

        let list = [...state.songs];

        list.sort((a, b) => {
            if (state.sortBy === "number") {
                const numA = parseInt(a.songNumber || "99999");
                const numB = parseInt(b.songNumber || "99999");
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
                            song.songNumber?.includes(q) || false;
                        const keyMatch =
                            song.key?.toLowerCase().includes(q) || false;
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
            const created = await createSong(serverUrl, serverToken, {
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
        setStorageItem("cp_virtual_files", updatedFiles);
        get().syncLibrary();
    },

    updateVirtualFile: async (path, content) => {
        const { serverUrl, serverToken, songs } = get();

        if (serverUrl.trim() !== "") {
            const existing = songs.find((s) => s.id === path);
            if (!existing?.remoteId) {
                throw new Error(
                    "Não foi possível encontrar este cântico no servidor. Sincronize e tente novamente.",
                );
            }
            const parsed = parseChordPro(content);
            const updated = await updateSong(
                serverUrl,
                serverToken,
                existing.remoteId,
                {
                    updatedAt: existing.remoteUpdatedAt || "",
                    title: parsed.metadata.title || existing.title,
                    content,
                    folderId: existing.folderId ?? null,
                    tags: existing.tags || [],
                },
            );
            commitSongLocally(set, get, updated, path);
            return;
        }

        const updatedFiles = get().virtualFiles.map((file) =>
            file.path === path
                ? { ...file, content, updatedAt: Date.now() }
                : file,
        );
        set({ virtualFiles: updatedFiles });
        setStorageItem("cp_virtual_files", updatedFiles);
        get().syncLibrary();
    },

    deleteVirtualFile: async (path) => {
        const { serverUrl, serverToken, songs } = get();

        if (serverUrl.trim() !== "") {
            const existing = songs.find((s) => s.id === path);
            if (existing?.remoteId)
                await deleteSong(serverUrl, serverToken, existing.remoteId);
        }

        const updatedFiles = get().virtualFiles.filter(
            (file) => file.path !== path,
        );
        const updatedSongs = get().songs.filter((s) => s.id !== path);
        const songRemoteIds = { ...get().songRemoteIds };
        delete songRemoteIds[path];

        set({ virtualFiles: updatedFiles, songs: updatedSongs, songRemoteIds });
        setStorageItem("cp_virtual_files", updatedFiles);
        setStorageItem("cp_songs_cache", updatedSongs);
        setStorageItem("cp_song_remote_ids", songRemoteIds);

        if (get().activeSongId === path)
            set({ activeSongId: null, isEditing: false });
    },

    syncLibrary: async () => {
        set({ syncStatus: "syncing" });
        const { serverUrl, serverToken } = get();

        if (!serverUrl || serverUrl.trim() === "") {
            const now = Date.now();
            set({ syncStatus: "success", lastSyncTime: now });
            setStorageItem("cp_last_sync_time", now);
        }

        try {
            const [folders, firstPage, apiServices] = await Promise.all([
                getFoldersFlat(serverUrl, serverToken),
                getSongs(serverUrl, serverToken, {
                    page: 1,
                    limit: 200,
                    sortBy: "title",
                    sortOrder: "asc",
                }),
                getServices(serverUrl, serverToken),
            ]);

            let apiSongs = [...firstPage.songs];
            if (firstPage.totalPages > 1) {
                const remainingPages = await Promise.all(
                    Array.from({ length: firstPage.totalPages - 1 }, (_, i) =>
                        getSongs(serverUrl, serverToken, {
                            page: i + 2,
                            limit: 200,
                            sortBy: "title",
                            sortOrder: "asc",
                        }),
                    ),
                );
                remainingPages.forEach((page) => apiSongs.push(...page.songs));
            }

            const finalSongs = apiSongs.map(toLSong(folders));
            const virtualFiles: VirtualFile[] = finalSongs.map((s) => ({
                path: s.id,
                content: s.content,
                updatedAt: s.updatedAt,
            }));
            const songRemoteIds: Record<string, string> = {};
            finalSongs.forEach((s) => {
                if (s.remoteId) songRemoteIds[s.id] = s.remoteId;
            });
            const finalServices = apiServices.map((svc) => toLocalService(svc));

            const finalSongIds = new Set(finalSongs.map((s) => s.id));
            const updatedFavorites = get().favoriteSongIds.filter((id) =>
                finalSongIds.has(id),
            );
            const updatedRecent = get().recentlyPlayedSongIds.filter((id) =>
                finalSongIds.has(id),
            );

            const now = Date.now();

            set({
                folders,
                services: finalServices,
                virtualFiles,
                songs: finalSongs,
                songRemoteIds,
                favoriteSongIds: updatedFavorites,
                recentlyPlayedSongIds: updatedRecent,
                syncStatus: "success",
                lastSyncTime: now,
            });

            setStorageItem("cp_folders", folders);
            setStorageItem("cp_services", finalServices);
            setStorageItem("cp_virtual_files", virtualFiles);
            setStorageItem("cp_songs_cache", finalSongs);
            setStorageItem("cp_song_remote_ids", songRemoteIds);
            setStorageItem("cp_favorites", updatedFavorites);
            setStorageItem("cp_recently_played", updatedRecent);
            setStorageItem("cp_last_sync_time", now);
        } catch (err: any) {
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
                const updated = await updateServiceApi(
                    serverUrl,
                    serverToken,
                    id,
                    { updatedAt: current.updatedAt || "", name, date, notes },
                );
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
        setStorageItem("cp_services", updatedServices);
    },

    updateServiceElements: async (serviceId, elements) => {
        const { serverUrl, serverToken, services } = get();
        const current = services.find((svc) => svc.id === serviceId);
        if (!current) return;

        if (serverUrl.trim() !== "") {
            try {
                const updated = await updateServiceElementsApi(
                    serverUrl,
                    serverToken,
                    serviceId,
                    { updatedAt: current.updatedAt || "", elements },
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
        setStorageItem("cp_services", updatedServices);
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
    },
}));
