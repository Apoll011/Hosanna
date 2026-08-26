import { FileText, Heart, Music, Plus, SlidersHorizontal } from "lucide-react";
import { useDeferredValue, useEffect, useMemo, useRef, useState } from "react";
import { useAppStore } from "../store/appStore";
import { Song } from "../types";
import { getSectionTitle } from "../utils";
import CircleOfFifths from "./CircleOfFifths";
import Metronome from "./Metronome";
import SettingsView from "./SettingsView";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";

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
    const syncStatus = useAppStore((state) => state.syncStatus);
    const isHydrated = useAppStore((state) => state.isHydrated);
    const isLoading =
        (!isHydrated || syncStatus === "syncing") && songs.length === 0;

    // Deferred search query to avoid lag on fast keystrokes
    const deferredSearchQuery = useDeferredValue(searchQuery);

    // Pre-normalize searchable text once per song list change rather than every keystroke
    const searchIndex = useMemo(() => {
        const map = new Map<
            string,
            {
                title: string;
                artist: string;
                number: string;
                key: string;
                content: string;
            }
        >();
        for (const song of songs) {
            map.set(song.id, {
                title: song.title.toLowerCase(),
                artist: song.artist?.toLowerCase() || "",
                number: song.metadata?.songNumber || "",
                key: song.metadata?.key?.toLowerCase() || "",
                content: song.content.toLowerCase(),
            });
        }
        return map;
    }, [songs]);

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

        // 2. Query Searching
        const q = deferredSearchQuery.trim().toLowerCase();
        if (q !== "") {
            result = result.filter((song) => {
                const idx = searchIndex.get(song.id);
                if (!idx) return false;
                return (
                    idx.title.includes(q) ||
                    idx.artist.includes(q) ||
                    idx.number.includes(q) ||
                    idx.key.includes(q) ||
                    idx.content.includes(q)
                );
            });
        }

        // 3. Sorting
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
        searchIndex,
        selectedSection,
        selectedFolder,
        favoriteSongIds,
        recentlyPlayedSongIds,
        deferredSearchQuery,
        sortBy,
    ]);

    const handleSelectSong = (songId: string) => {
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

        useAppStore.getState().addRecentlyPlayedSong(songId);
        onSelectSong(songId);
    };

    // Virtualization parameters
    const containerRef = useRef<HTMLDivElement>(null);
    const [scrollTop, setScrollTop] = useState(0);
    const [containerHeight, setContainerHeight] = useState(600);

    useEffect(() => {
        const el = containerRef.current;
        if (!el) return;
        setContainerHeight(el.clientHeight);
        const ro = new ResizeObserver((entries) => {
            for (const entry of entries) {
                setContainerHeight(entry.contentRect.height);
            }
        });
        ro.observe(el);
        return () => ro.disconnect();
    }, []);

    // Responsive height per card (82px)
    const ITEM_HEIGHT = 84;
    const OVERSCAN = 6;
    const totalCount = filteredAndSortedSongs.length;
    const startIndex = Math.max(
        0,
        Math.floor(scrollTop / ITEM_HEIGHT) - OVERSCAN,
    );
    const endIndex = Math.min(
        totalCount,
        Math.ceil((scrollTop + containerHeight) / ITEM_HEIGHT) + OVERSCAN,
    );

    const visibleSongs = useMemo(
        () => filteredAndSortedSongs.slice(startIndex, endIndex),
        [filteredAndSortedSongs, startIndex, endIndex],
    );

    const paddingTop = startIndex * ITEM_HEIGHT;
    const paddingBottom = Math.max(0, (totalCount - endIndex) * ITEM_HEIGHT);

    return (
        <div className="flex-1 flex flex-col h-full overflow-hidden bg-background relative">
            {/* Header Area */}
            {selectedSection !== "circle" &&
                selectedSection !== "metronome" &&
                selectedSection !== "settings" && (
                    <div className="p-3 sm:p-4 bg-background border-b border-border/80 flex items-center justify-between gap-2 shrink-0">
                        {/* Active section badge */}
                        <div className="flex items-center gap-2">
                            <Badge
                                variant="outline"
                                className="font-mono bg-muted/50 px-2.5 py-1 rounded-xl border-border text-[11px] font-bold text-primary"
                            >
                                {getSectionTitle(
                                    selectedSection,
                                    activeListContext.folderName,
                                    selectedFolder,
                                )}
                            </Badge>
                            <span className="text-xs text-muted-foreground font-semibold hidden sm:inline">
                                ({filteredAndSortedSongs.length})
                            </span>
                        </div>

                        <div className="flex items-center gap-2 text-xs">
                            {selectedSection !== "recent" && (
                                <div className="flex items-center gap-1.5 bg-muted/60 px-2.5 py-1.5 rounded-xl border border-border/60">
                                    <SlidersHorizontal className="w-3.5 h-3.5 text-muted-foreground" />
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
                                        className="bg-transparent border-none p-0 pr-1 text-xs font-bold text-foreground focus:outline-none cursor-pointer"
                                    >
                                        <option value="title">
                                            A-Z Alfabética
                                        </option>
                                        <option value="number">Número</option>
                                        <option value="folder">Pasta</option>
                                    </select>
                                </div>
                            )}

                            {/* Quick Creator Button */}
                            <Button
                                onClick={onAddNewSong}
                                id="btn_create_new_song"
                                size="sm"
                                className="rounded-full shadow-xs gap-1 font-bold text-xs h-8 px-3.5"
                            >
                                <Plus className="w-3.5 h-3.5" />
                                Novo
                            </Button>
                        </div>
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
                    {/* Songs List with Virtualization and Native Touch Feel */}
                    <div
                        ref={containerRef}
                        onScroll={(e) =>
                            setScrollTop(e.currentTarget.scrollTop)
                        }
                        className="flex-1 overflow-y-auto p-3 sm:p-5 pb-24 sm:pb-8 no-scrollbar"
                    >
                        {isLoading ? (
                            <div className="space-y-2.5 animate-pulse">
                                {Array.from({ length: 8 }).map((_, i) => (
                                    <div
                                        key={i}
                                        className="bg-card p-4 rounded-2xl border border-border/60 flex items-center justify-between"
                                    >
                                        <div className="flex items-start gap-3 min-w-0 flex-1">
                                            <div className="w-11 h-11 rounded-2xl bg-muted shrink-0" />
                                            <div className="min-w-0 flex-1 space-y-2 pt-1">
                                                <div className="h-4 bg-muted rounded-md w-1/3" />
                                                <div className="h-3 bg-muted rounded-md w-1/4" />
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-3 shrink-0 pl-3">
                                            <div className="w-10 h-6 bg-muted rounded-lg" />
                                            <div className="w-8 h-8 rounded-full bg-muted" />
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : filteredAndSortedSongs.length === 0 ? (
                            <div className="flex flex-col items-center justify-center py-20 text-center px-4">
                                <div className="w-16 h-16 rounded-3xl bg-muted/60 flex items-center justify-center mb-4 border border-border/40">
                                    <Music className="w-8 h-8 text-muted-foreground/60" />
                                </div>
                                <h3 className="text-base font-bold text-foreground">
                                    Nenhum cântico encontrado
                                </h3>
                                <p className="text-xs text-muted-foreground mt-1 max-w-72 leading-relaxed">
                                    {selectedSection === "favorites"
                                        ? "Ainda não marcou nenhum cântico como favorito."
                                        : selectedSection === "recent"
                                          ? "Nenhum cântico tocado recentemente."
                                          : "Tente redefinir os filtros ou escreva outro termo de pesquisa."}
                                </p>
                            </div>
                        ) : (
                            <div
                                style={{
                                    paddingTop: `${paddingTop}px`,
                                    paddingBottom: `${paddingBottom}px`,
                                }}
                                className="space-y-2.5 max-w-4xl mx-auto"
                            >
                                {visibleSongs.map((song) => {
                                    const isFav = favoriteSongIds.includes(
                                        song.id,
                                    );
                                    return (
                                        <div
                                            key={song.id}
                                            onClick={() =>
                                                handleSelectSong(song.id)
                                            }
                                            className="bg-card p-3.5 sm:p-4 rounded-2xl border border-border/70 hover:border-primary/60 cursor-pointer transition-all hover:shadow-sm flex items-center justify-between group active:scale-[0.985] select-none"
                                        >
                                            <div className="flex items-center gap-3.5 min-w-0 flex-1">
                                                {/* Visual Number badge or note icon */}
                                                <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-2xl bg-muted/70 flex flex-col items-center justify-center shrink-0 border border-border/50 group-hover:bg-primary/10 group-hover:border-primary/30 transition-colors">
                                                    {song.metadata
                                                        ?.songNumber ? (
                                                        <span className="text-xs font-black text-primary">
                                                            #
                                                            {
                                                                song.metadata
                                                                    .songNumber
                                                            }
                                                        </span>
                                                    ) : (
                                                        <FileText className="w-4 h-4 sm:w-5 sm:h-5 text-muted-foreground group-hover:text-primary transition-colors" />
                                                    )}
                                                </div>

                                                <div className="min-w-0 flex-1">
                                                    <div className="flex items-center gap-2 flex-wrap">
                                                        <h4 className="text-sm font-bold text-foreground truncate">
                                                            {song.title}
                                                        </h4>
                                                        {song.folder && (
                                                            <Badge
                                                                variant="secondary"
                                                                className="text-[9px] px-1.5 py-0.5 rounded-md font-semibold text-muted-foreground"
                                                            >
                                                                {song.folder}
                                                            </Badge>
                                                        )}
                                                    </div>
                                                    <p className="text-xs text-muted-foreground mt-0.5 truncate font-medium">
                                                        {song.artist ||
                                                            "Artista desconhecido"}
                                                    </p>
                                                </div>
                                            </div>

                                            {/* Badges for Key, Tempo and Heart action */}
                                            <div className="flex items-center gap-2.5 sm:gap-3 shrink-0 pl-3">
                                                <div className="flex flex-col items-end gap-1">
                                                    {song.metadata?.key && (
                                                        <Badge
                                                            variant="primaryLight"
                                                            className="text-[10px] font-bold px-2 py-0.5 rounded-lg"
                                                        >
                                                            {song.metadata.key}
                                                        </Badge>
                                                    )}
                                                    {song.metadata?.tempo && (
                                                        <span className="text-[10px] text-muted-foreground font-mono">
                                                            ♩{" "}
                                                            {
                                                                song.metadata
                                                                    .tempo
                                                            }
                                                        </span>
                                                    )}
                                                </div>

                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        toggleFavoriteSong(
                                                            song.id,
                                                        );
                                                    }}
                                                    className={`p-2 rounded-full hover:bg-muted/80 transition-all cursor-pointer active:scale-90 ${
                                                        isFav
                                                            ? "text-rose-500 hover:text-rose-600"
                                                            : "text-muted-foreground hover:text-primary"
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
                                })}
                            </div>
                        )}
                    </div>
                </>
            )}
        </div>
    );
}
