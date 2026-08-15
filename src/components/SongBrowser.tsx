import { FileText, Heart, Music, Plus, SlidersHorizontal } from "lucide-react";
import { useMemo } from "react";
import { useAppStore } from "../store/appStore";
import { Song } from "../types";
import { getSectionTitle } from "../utils";
import CircleOfFifths from "./CircleOfFifths";
import Metronome from "./Metronome";
import SettingsView from "./SettingsView";

interface SongBrowserProps {
    onSelectSong: (id: string) => void;
    onAddNewSong: () => void;
}

export default function SongBrowser({
    onSelectSong,
    onAddNewSong,
}: SongBrowserProps) {
    const songs = useAppStore((state) => state.songs);
    const favoriteSongIds = useAppStore((state) => state.favoriteSongIds);
    const recentlyPlayedSongIds = useAppStore(
        (state) => state.recentlyPlayedSongIds,
    );
    const toggleFavoriteSong = useAppStore((state) => state.toggleFavoriteSong);
    const setActiveListContext = useAppStore(
        (state) => state.setActiveListContext,
    );

    const selectedFolder = useAppStore((state) => state.selectedFolder);
    const searchQuery = useAppStore((state) => state.searchQuery);
    const sortBy = useAppStore((state) => state.sortBy);
    const setSortBy = useAppStore((state) => state.setSortBy);

    // Read section from store's activeListContext
    const activeListContext = useAppStore((state) => state.activeListContext);
    const selectedSection = activeListContext.type;

    // Comprehensive searching and sorting engine
    const filteredAndSortedSongs = useMemo(() => {
        let result = [...songs];

        // 1. Section/Folder Filtering
        if (selectedSection === "favorites") {
            result = result.filter((song) => favoriteSongIds.includes(song.id));
        } else if (selectedSection === "recent") {
            const recentList = recentlyPlayedSongIds
                .map((id) => songs.find((s) => s.id === id))
                .filter(Boolean) as Song[];
            result = recentList;
        } else if (
            selectedSection === "folder" &&
            (activeListContext.folderName || selectedFolder) !== ""
        ) {
            const folderToFilter =
                activeListContext.folderName || selectedFolder;
            result = result.filter((song) => song.folder === folderToFilter);
        }

        // 2. Query Searching (Title, Lyrics, Artist, Number, Key)
        if (searchQuery.trim() !== "") {
            const q = searchQuery.toLowerCase().trim();
            result = result.filter((song) => {
                const titleMatch = song.title.toLowerCase().includes(q);
                const artistMatch =
                    song.artist?.toLowerCase().includes(q) || false;
                const numberMatch =
                    song.metadata?.songNumber?.includes(q) || false;
                const keyMatch =
                    song.metadata?.key?.toLowerCase().includes(q) || false;
                const lyricsMatch = song.content.toLowerCase().includes(q);

                return (
                    titleMatch ||
                    artistMatch ||
                    numberMatch ||
                    keyMatch ||
                    lyricsMatch
                );
            });
        }

        // 3. Sorting (preserves chronological played history for recently played, sorts others)
        if (selectedSection !== "recent") {
            result.sort((a, b) => {
                if (sortBy === "number") {
                    const numA = parseInt(a.metadata?.songNumber || "99999");
                    const numB = parseInt(b.metadata?.songNumber || "99999");
                    return numA - numB;
                } else if (sortBy === "folder") {
                    const fComp = a.folder.localeCompare(b.folder);
                    if (fComp !== 0) return fComp;
                    return a.title.localeCompare(b.title);
                } else {
                    return a.title.localeCompare(b.title);
                }
            });
        }

        return result;
    }, [
        songs,
        selectedSection,
        selectedFolder,
        favoriteSongIds,
        recentlyPlayedSongIds,
        searchQuery,
        sortBy,
    ]);

    const handleSelectSong = (songId: string) => {
        // Determine active list context
        const contextType =
            selectedSection === "all" && searchQuery.trim() !== ""
                ? "search"
                : selectedSection;
        setActiveListContext({
            type: contextType,
            folderName:
                selectedSection === "folder"
                    ? activeListContext.folderName || selectedFolder
                    : undefined,
            searchQuery: searchQuery.trim() !== "" ? searchQuery : undefined,
        });

        // Automatically record to Recently Played on open
        useAppStore.getState().addRecentlyPlayedSong(songId);

        // Call component onSelect
        onSelectSong(songId);
    };

    return (
        <div className="flex-1 flex flex-col h-full overflow-hidden bg-m3-bg dark:bg-m3-dark-bg relative">
            {/* Header Search Area */}
            {selectedSection !== "circle" &&
                selectedSection !== "metronome" &&
                selectedSection !== "settings" && (
                    <div className="p-3.5 bg-m3-bg dark:bg-m3-dark-bg border-b border-m3-border dark:border-m3-border/30 flex items-center justify-between gap-2 shrink-0">
                        {/* Active section breadcrumb */}
                        <span className="font-mono bg-m3-sidebar dark:bg-m3-dark-sidebar px-2.5 py-1 rounded-xl border border-m3-border/30 dark:border-m3-dark-border/30 text-[10px] font-bold text-m3-primary dark:text-m3-dark-primary shadow-2xs">
                            {getSectionTitle(
                                selectedSection,
                                activeListContext.folderName,
                                selectedFolder,
                            )}
                        </span>
                        <div className="flex items-center gap-1.5 text-xs text-m3-secondary dark:text-m3-dark-secondary font-medium">
                            {selectedSection !== "recent" && (
                                <div className="flex items-center gap-1 bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-1 rounded-xl border border-m3-border/20">
                                    <SlidersHorizontal className="w-3 h-3 text-m3-secondary/70" />
                                    <select
                                        id="select_sort_songs"
                                        value={sortBy}
                                        onChange={(e) =>
                                            setSortBy(
                                                (
                                                    e as React.ChangeEvent<HTMLSelectElement>
                                                ).target.value as
                                                    | "title"
                                                    | "number"
                                                    | "folder",
                                            )
                                        }
                                        className="bg-transparent border-none p-0 pr-1 text-xs font-bold text-m3-text dark:text-m3-dark-text focus:outline-none cursor-pointer"
                                    >
                                        <option value="title">
                                            A-Z Alfabética
                                        </option>
                                        <option value="number">
                                            Número
                                        </option>
                                        <option value="folder">
                                            Pasta
                                        </option>
                                    </select>
                                </div>
                            )}
                        </div>

                        {/* Quick Creator Button */}
                        <button
                            onClick={onAddNewSong}
                            id="btn_create_new_song"
                            className="flex items-center gap-1 bg-m3-primary hover:opacity-90 text-white text-xs px-3.5 py-1.5 rounded-full font-bold shadow-xs transition-all active:scale-95"
                        >
                            <Plus className="w-3.5 h-3.5" />
                            Novo
                        </button>
                    </div>
                )}

            {/* Main Content Area */}
            {selectedSection === "circle" ? (
                <CircleOfFifths />
            ) : selectedSection === "metronome" ? (
                <Metronome />
            ) : selectedSection === "settings" ? (
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
                                <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary mt-1 max-w-60">
                                    {selectedSection === "favorites"
                                        ? "Ainda não marcou nenhum cântico como favorito."
                                        : selectedSection === "recent"
                                          ? "Nenhum cântico tocado recentemente."
                                          : "Tente redefinir os filtros ou escreva outra palavra de pesquisa."}
                                </p>
                            </div>
                        ) : (
                            filteredAndSortedSongs.map((song) => {
                                const isFav = favoriteSongIds.includes(song.id);
                                return (
                                    <div
                                        key={song.id}
                                        onClick={() =>
                                            handleSelectSong(song.id)
                                        }
                                        className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 hover:border-m3-primary/60 dark:hover:border-m3-dark-primary/60 cursor-pointer transition-all hover:shadow-xs flex items-center justify-between group active:scale-[0.99]"
                                    >
                                        <div className="flex items-start gap-3 min-w-0 flex-1">
                                            {/* Visual Number badge or note icon */}
                                            <div className="w-10 h-10 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar flex flex-col items-center justify-center shrink-0 border border-m3-border/20 group-hover:bg-m3-primary-light dark:group-hover:bg-m3-dark-primary-light transition-colors">
                                                {song.metadata?.songNumber ? (
                                                    <span className="text-[11px] font-black text-m3-primary dark:text-m3-dark-primary">
                                                        #
                                                        {
                                                            song.metadata
                                                                .songNumber
                                                        }
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
                                                    {song.artist ||
                                                        "Artista desconhecido"}
                                                </p>
                                            </div>
                                        </div>

                                        {/* Badges for Key, Tempo and Heart action */}
                                        <div className="flex items-center gap-3 shrink-0 pl-3">
                                            <div className="flex flex-col items-end gap-1">
                                                {song.metadata?.key && (
                                                    <span className="text-[10px] font-bold bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-text px-2 py-0.5 rounded-lg border border-m3-border/30">
                                                        {song.metadata.key}
                                                    </span>
                                                )}
                                                {song.metadata?.tempo && (
                                                    <span className="text-[9px] text-m3-secondary dark:text-m3-dark-secondary font-mono">
                                                        ♩ {song.metadata.tempo}
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
                                                        ? "text-red-500 hover:text-red-600"
                                                        : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-primary"
                                                }`}
                                                title={
                                                    isFav
                                                        ? "Remover dos favoritos"
                                                        : "Adicionar aos favoritos"
                                                }
                                            >
                                                <Heart
                                                    className={`w-4.5 h-4.5 ${isFav ? "fill-current" : ""}`}
                                                />
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
