import {
    configureApiClient,
    getApiClient,
    parseChordPro,
    parseSong,
    Song as SharedSong,
} from "@hosanna/shared";
import { create } from "zustand";
import {
    getDatabase,
    ReplicationManager,
    setupReplication,
    SongDocType,
} from "../db";
import { purgeExpiredTrash } from "../db/trash";
import { API_BASE_URL } from "../lib/authClient";
import {
    clearStorage,
    getStorageItem,
    setStorageItemImmediate,
} from "../lib/storage";
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
            | "settings";
        serviceId?: string;
        folderName?: string;
        searchQuery?: string;
    };

    theme: ThemeType;
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

    syncStatus: "idle" | "syncing" | "success" | "error" | "offline";
    lastSyncTime: number | null;
    hasSkippedSetup: boolean;
    isHydrated: boolean;

    rehydrateStore: () => Promise<void>;
    initRxDbSubscriptions: () => Promise<() => void>;
    setTheme: (theme: ThemeType) => void;
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
    ) => Promise<void>;
    updateVirtualFile: (path: string, content: string) => Promise<void>;
    deleteVirtualFile: (path: string) => Promise<void>;

    syncLibrary: (options?: { force?: boolean }) => Promise<void>;
    setHasSkippedSetup: (skipped: boolean) => void;

    updateService: (
        id: string,
        name: string,
        date: string,
        notes?: string,
    ) => Promise<void>;
    updateServiceElements: (
        serviceId: string,
        elements: ServiceElement[],
    ) => Promise<void>;
    resetApp: () => Promise<void>;
}

let replicationManager: ReplicationManager | null = null;
let rehydrationPromise: Promise<void> | null = null;
let rxDbSubscriptionsPromise: Promise<() => void> | null = null;

export function ensureApiClient() {
    configureApiClient(API_BASE_URL.trim() + "/api");
    if (typeof localStorage !== "undefined") {
        const token = localStorage.getItem("hosanna_access_token");
        if (token) {
            getApiClient().setTokens(token);
        }
    }
}

ensureApiClient();

export const useAppStore = create<AppState>((set, get) => ({
    virtualFiles: [],
    sourceFolderPath: "/Armazenamento/Canticos_Igreja",
    songs: [],
    services: [],
    folders: [],
    favoriteSongIds: [],
    recentlyPlayedSongIds: [],
    activeListContext: { type: "all" },
    theme: "light",
    fontSize: 16,
    showChords: true,
    showDiagrams: true,
    keepScreenAwake: true,
    slowDownOnRepeat: true,
    musicianMode: false,
    instrument: "guitar",
    twoColumnLayout: false,
    selectedFolder: "",
    activeSongId: null,
    activeServiceId: null,
    isEditing: false,
    isPresenting: false,
    searchQuery: "",
    sortBy: "title",
    syncStatus: "idle",
    lastSyncTime: null,
    hasSkippedSetup: false,
    isHydrated: false,

    rehydrateStore: () => {
        if (!rehydrationPromise) {
            rehydrationPromise = (async () => {
                try {
                    const [
                        favoriteSongIds,
                        recentlyPlayedSongIds,
                        theme,
                        fontSize,
                        showChords,
                        showDiagrams,
                        keepScreenAwake,
                        slowDownOnRepeat,
                        musicianMode,
                        instrument,
                        twoColumnLayout,
                        lastSyncTime,
                        hasSkippedSetup,
                    ] = await Promise.all([
                        getStorageItem<string[]>("cp_favorites", []),
                        getStorageItem<string[]>("cp_recently_played", []),
                        getStorageItem<ThemeType>("cp_theme", "light"),
                        getStorageItem<number>("cp_font_size", 16),
                        getStorageItem<boolean>("cp_show_chords", true),
                        getStorageItem<boolean>("cp_show_diagrams", true),
                        getStorageItem<boolean>("cp_keep_screen_awake", true),
                        getStorageItem<boolean>("cp_slow_down_on_repeat", true),
                        getStorageItem<boolean>("cp_musician_mode", false),
                        getStorageItem<"guitar" | "piano">(
                            "cp_instrument",
                            "guitar",
                        ),
                        getStorageItem<boolean>("cp_two_column_layout", false),
                        getStorageItem<number | null>(
                            "cp_last_sync_time",
                            null,
                        ),
                        getStorageItem<boolean>("cp_has_skipped_setup", false),
                    ]);

                    set({
                        favoriteSongIds,
                        recentlyPlayedSongIds,
                        theme,
                        fontSize,
                        showChords,
                        showDiagrams,
                        keepScreenAwake,
                        slowDownOnRepeat,
                        musicianMode,
                        instrument,
                        twoColumnLayout,
                        lastSyncTime,
                        hasSkippedSetup,
                        isHydrated: true,
                    });
                } catch (error) {
                    console.error("Failed to rehydrate store:", error);
                    set({ isHydrated: true });
                }
            })();
        }
        return rehydrationPromise;
    },

    initRxDbSubscriptions: () => {
        if (!rxDbSubscriptionsPromise) {
            rxDbSubscriptionsPromise = (async () => {
                ensureApiClient();
                const db = await getDatabase();
                const repl = setupReplication(db);
                replicationManager = repl;
                purgeExpiredTrash(db).catch(() => {});

                repl.start();

                const statusSub = repl.status$.subscribe((st) => {
                    if (st === "syncing") {
                        set({ syncStatus: "syncing" });
                    } else if (st === "synced") {
                        const now = Date.now();
                        set({ syncStatus: "success", lastSyncTime: now });
                        setStorageItemImmediate("cp_last_sync_time", now);
                    } else if (st === "offline") {
                        set({ syncStatus: "offline" });
                    } else if (st === "error") {
                        set({ syncStatus: "error" });
                    }
                });

                // Query folders
                const foldersSub = db.folders
                    .find({ selector: { _deleted: { $ne: true } } })
                    .$.subscribe((docs) => {
                        const rawFolders = docs.map(
                            (d) => d.toJSON() as Folder,
                        );
                        set({ folders: rawFolders });
                    });

                // Query songs
                const songsSub = db.songs
                    .find({ selector: { _deleted: { $ne: true } } })
                    .$.subscribe((docs) => {
                        const folders = get().folders;
                        const rawSongs = docs.map(
                            (d) => d.toJSON() as SharedSong,
                        );
                        const parsedSongs = rawSongs.map((s) =>
                            parseSong(s, folders),
                        );
                        const virtualFiles = parsedSongs.map((s) => ({
                            path: s.id,
                            content: s.content,
                            updatedAt: Date.now(),
                        }));

                        const validSongIds = new Set(
                            parsedSongs.map((s) => s.id),
                        );
                        const updatedFavorites = get().favoriteSongIds.filter(
                            (id) => validSongIds.has(id),
                        );
                        const updatedRecent =
                            get().recentlyPlayedSongIds.filter((id) =>
                                validSongIds.has(id),
                            );

                        set({
                            songs: parsedSongs,
                            virtualFiles,
                            favoriteSongIds: updatedFavorites,
                            recentlyPlayedSongIds: updatedRecent,
                        });
                    });

                // Query services
                const servicesSub = db.services
                    .find({ selector: { _deleted: { $ne: true } } })
                    .$.subscribe((docs) => {
                        const rawServices = docs.map(
                            (d) => d.toJSON() as Service,
                        );
                        set({ services: rawServices });
                    });

                return () => {
                    statusSub.unsubscribe();
                    foldersSub.unsubscribe();
                    songsSub.unsubscribe();
                    servicesSub.unsubscribe();
                    rxDbSubscriptionsPromise = null;
                };
            })();
        }
        return rxDbSubscriptionsPromise;
    },

    setTheme: (theme) => {
        set({ theme });
        setStorageItemImmediate("cp_theme", theme);
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
        setStorageItemImmediate("cp_keep_screen_awake", keepScreenAwake);
    },
    setSlowDownOnRepeat: (slowDownOnRepeat) => {
        set({ slowDownOnRepeat });
        setStorageItemImmediate("cp_slow_down_on_repeat", slowDownOnRepeat);
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
    setSelectedFolder: (selectedFolder) => {
        set({ selectedFolder });
    },
    setActiveSongId: (activeSongId) => {
        set({ activeSongId });
    },
    setActiveServiceId: (activeServiceId) => {
        set({ activeServiceId });
    },
    setIsEditing: (isEditing) => {
        set({ isEditing });
    },
    setIsPresenting: (isPresenting) => {
        set({ isPresenting });
    },
    setSearchQuery: (searchQuery) => {
        set({ searchQuery });
    },
    setSortBy: (sortBy) => {
        set({ sortBy });
    },
    setHasSkippedSetup: (hasSkippedSetup) => {
        set({ hasSkippedSetup });
        setStorageItemImmediate("cp_has_skipped_setup", hasSkippedSetup);
    },

    toggleFavoriteSong: (id) => {
        const current = get().favoriteSongIds;
        const updated = current.includes(id)
            ? current.filter((x) => x !== id)
            : [...current, id];
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
                        const lyricsMatch =
                            q.length > 2
                                ? song.content.toLowerCase().includes(q)
                                : false;
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

        const parsed = parseChordPro(content);
        const db = await getDatabase();
        const now = new Date().toISOString();
        const id = crypto.randomUUID();

        const newDoc: SongDocType = {
            id,
            title:
                parsed.metadata.title ||
                cleanFileName.replace(/\.chopro$/i, ""),
            artist: parsed.metadata.artist || "",
            content,
            folderId: matchedFolder?.id ?? null,
            path: fullPath,
            tags: [],
            song_number: parsed.metadata.songNumber
                ? parseInt(parsed.metadata.songNumber) || null
                : null,
            createdAt: now,
            updatedAt: now,
            _deleted: false,
        };

        await db.songs.insert(newDoc);
    },

    updateVirtualFile: async (path, content) => {
        const { songs } = get();
        const existing = songs.find((s) => s.id === path);
        if (!existing) {
            throw new Error("Não foi possível encontrar este cântico.");
        }
        const parsed = parseChordPro(content);
        const db = await getDatabase();
        const doc = await db.songs.findOne(existing.id).exec();
        const now = new Date().toISOString();

        if (doc) {
            await doc.patch({
                title: parsed.metadata.title || existing.title,
                artist: parsed.metadata.artist || existing.artist || "",
                content,
                updatedAt: now,
                _deleted: false,
            });
        }
    },

    deleteVirtualFile: async (path) => {
        const { songs } = get();
        const existing = songs.find((s) => s.id === path);
        if (existing) {
            const db = await getDatabase();
            const doc = await db.songs.findOne(existing.id).exec();
            if (doc) {
                await doc.patch({
                    _deleted: true,
                    updatedAt: new Date().toISOString(),
                });
            }
        }

        if (get().activeSongId === path)
            set({ activeSongId: null, isEditing: false });
    },

    syncLibrary: async () => {
        try {
            const db = await getDatabase();
            await purgeExpiredTrash(db).catch(() => {});
        } catch {}
        if (replicationManager) {
            await replicationManager.replicateNow();
        }
    },

    updateService: async (id, name, date, notes) => {
        const db = await getDatabase();
        const doc = await db.services.findOne(id).exec();
        const now = new Date().toISOString();
        if (doc) {
            await doc.patch({
                name,
                date,
                notes: notes ?? null,
                updatedAt: now,
                _deleted: false,
            });
        }
    },

    updateServiceElements: async (serviceId, elements) => {
        const db = await getDatabase();
        const doc = await db.services.findOne(serviceId).exec();
        const now = new Date().toISOString();
        if (doc) {
            await doc.patch({
                elements,
                updatedAt: now,
                _deleted: false,
            });
        }
    },

    resetApp: async () => {
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
        await clearStorage();
    },
}));

// Immediately start rehydrating preferences and RxDB subscriptions in parallel with module loading
if (typeof window !== "undefined") {
    useAppStore
        .getState()
        .rehydrateStore()
        .catch((err) => {
            console.warn("Eager rehydration warning:", err);
        });
    useAppStore
        .getState()
        .initRxDbSubscriptions()
        .catch((err) => {
            console.warn("Eager RxDB subscriptions warning:", err);
        });
}
