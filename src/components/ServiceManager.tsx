// src/components/ServiceManager.tsx
import {
    ArrowLeft,
    BookOpen,
    CalendarRange,
    Check,
    ChevronLeft,
    ChevronRight,
    Edit2,
    FileText,
    HelpCircle,
    Megaphone,
    MessageSquare,
    Music,
    Play,
    Save,
    X,
} from "lucide-react";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { useAppStore } from "../store/appStore";
import { ServiceElement, Song } from "../types";
import MusicianServiceView from "./MusicianServiceView";
import SongView from "./SongView";

type ViewMode = "list" | "detail" | "present" | "song" | "musician";

const ELEMENT_META: Record<
    string,
    { label: string; icon: React.ElementType; bg: string; text: string }
> = {
    song: {
        label: "Cântico",
        icon: Music,
        bg: "bg-m3-primary-light dark:bg-m3-dark-primary-light",
        text: "text-m3-primary dark:text-m3-dark-primary",
    },
    welcome: {
        label: "Boas-vindas",
        icon: FileText,
        bg: "bg-blue-50 dark:bg-blue-500/10",
        text: "text-blue-600 dark:text-blue-400",
    },
    scripture: {
        label: "Escritura",
        icon: BookOpen,
        bg: "bg-fuchsia-50 dark:bg-fuchsia-500/10",
        text: "text-fuchsia-600 dark:text-fuchsia-400",
    },
    message: {
        label: "Mensagem",
        icon: MessageSquare,
        bg: "bg-amber-50 dark:bg-amber-500/10",
        text: "text-amber-600 dark:text-amber-400",
    },
    reading: {
        label: "Leitura",
        icon: FileText,
        bg: "bg-purple-50 dark:bg-purple-500/10",
        text: "text-purple-600 dark:text-purple-400",
    },
    announcement: {
        label: "Avisos",
        icon: Megaphone,
        bg: "bg-emerald-50 dark:bg-emerald-500/10",
        text: "text-emerald-600 dark:text-emerald-400",
    },
};

const getElementMeta = (type: string) =>
    ELEMENT_META[type] || {
        label: type || "Elemento",
        icon: HelpCircle,
        bg: "bg-m3-sidebar dark:bg-m3-dark-sidebar",
        text: "text-m3-secondary dark:text-m3-dark-secondary",
    };

const formatDate = (iso: string) => {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleDateString("pt-PT", {
        weekday: "long",
        day: "2-digit",
        month: "long",
        year: "numeric",
    });
};

const SWIPE_THRESHOLD = 60;

function NotesEditor({
    initialNotes,
    onSave,
    onCancel,
}: {
    initialNotes: string;
    onSave: (notes: string) => void;
    onCancel: () => void;
}) {
    const [value, setValue] = useState(initialNotes);

    return (
        <div
            className="mt-3 flex flex-col gap-2 animate-in fade-in slide-in-from-top-1 duration-200 w-full"
            onClick={(e) => e.stopPropagation()}
            onTouchStart={(e) => e.stopPropagation()}
            onTouchMove={(e) => e.stopPropagation()}
            onTouchEnd={(e) => e.stopPropagation()}
        >
            <textarea
                value={value}
                onChange={(e) => setValue(e.target.value)}
                className="w-full bg-m3-bg dark:bg-m3-dark-bg border border-m3-border dark:border-m3-dark-border rounded-xl p-3 text-xs text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 min-h-20 resize-none"
                placeholder="Adicione notas para este elemento..."
                autoFocus
            />
            <div className="flex justify-end gap-2">
                <button
                    onClick={onCancel}
                    className="px-4 py-2 rounded-xl text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover active:scale-95 transition-transform"
                >
                    Cancelar
                </button>
                <button
                    onClick={() => onSave(value)}
                    className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-m3-primary dark:bg-m3-dark-primary text-white active:scale-95 transition-transform shadow-md"
                >
                    <Save className="w-3.5 h-3.5" />
                    Guardar
                </button>
            </div>
        </div>
    );
}

export default function ServiceManager() {
    const services = useAppStore((state) => state.services);
    const songs = useAppStore((state) => state.songs);
    const searchQuery = useAppStore((state) => state.searchQuery);
    const musicianMode = useAppStore((state) => state.musicianMode);

    const setActiveServiceId = useAppStore((state) => state.setActiveServiceId);
    const setActiveListContext = useAppStore(
        (state) => state.setActiveListContext,
    );
    const setActiveSongId = useAppStore((state) => state.setActiveSongId);
    const setIsPresenting = useAppStore((state) => state.setIsPresenting);
    const updateServiceElements = useAppStore(
        (state) => state.updateServiceElements,
    );

    const [mode, setMode] = useState<ViewMode>("list");
    const [selectedServiceId, setSelectedServiceId] = useState<string | null>(
        null,
    );
    const [stepIndex, setStepIndex] = useState(0);
    const [viewingSongId, setViewingSongId] = useState<string | null>(null);
    const [returnMode, setReturnMode] = useState<ViewMode>("detail");

    const [editingNotesId, setEditingNotesId] = useState<string | null>(null);

    const touchStartX = useRef<number | null>(null);
    const touchStartY = useRef<number | null>(null);

    const selectedService = useMemo(
        () => services.find((s) => s.id === selectedServiceId) || null,
        [services, selectedServiceId],
    );

    const sortedElements = useMemo(() => {
        if (!selectedService?.elements) return [];
        return [...selectedService.elements].sort(
            (a, b) => (a.position || 0) - (b.position || 0),
        );
    }, [selectedService]);

    const filteredServices = useMemo(() => {
        // Only show non-archived services
        const list = services.filter((s) => !s.archived);
        const now = new Date().getTime();

        if (searchQuery.trim()) {
            const q = searchQuery.toLowerCase();
            return list
                .filter((s) => s.name.toLowerCase().includes(q))
                .sort(
                    (a, b) =>
                        new Date(b.date).getTime() - new Date(a.date).getTime(),
                );
        }

        list.sort((a, b) => {
            const tA = new Date(a.date).getTime();
            const tB = new Date(b.date).getTime();
            const aIsFuture = tA >= now - 86400000;
            const bIsFuture = tB >= now - 86400000;

            if (aIsFuture && bIsFuture) return tA - tB;
            else if (!aIsFuture && !bIsFuture) return tB - tA;
            else return aIsFuture ? -1 : 1;
        });

        return list;
    }, [services, searchQuery]);

    const songFor = (element: ServiceElement): Song | undefined =>
        songs.find((s) => s.id === element.songId);

    useEffect(() => {
        // Hide the bottom nav in all service sub-views (detail, musician, present)
        const inSubView =
            mode === "present" || mode === "detail" || mode === "musician";
        setIsPresenting(inSubView);
        return () => {
            setIsPresenting(false);
        };
    }, [mode, setIsPresenting]);

    const saveNotes = (elementId: string, notes: string) => {
        if (!selectedService) return;
        const newElements = (selectedService.elements || []).map((e) =>
            e.id === elementId ? { ...e, notes } : e,
        );
        updateServiceElements(selectedService.id, newElements);
        setEditingNotesId(null);
    };

    const enterService = (id: string) => {
        setSelectedServiceId(id);
        if (musicianMode) {
            setMode("musician");
        } else {
            setMode("detail");
        }
    };

    const scopeToService = (serviceId: string) => {
        setActiveServiceId(serviceId);
        setActiveListContext({ type: "service", serviceId });
    };

    const openSong = (song: Song, from: ViewMode) => {
        if (selectedService) scopeToService(selectedService.id);
        setActiveSongId(song.id);
        setViewingSongId(song.id);
        setReturnMode(from);
        setMode("song");
    };

    const closeSong = () => {
        setActiveSongId(null);
        setViewingSongId(null);
        setMode(returnMode);
    };

    const startService = () => {
        if (!sortedElements.length) return;
        setStepIndex(0);
        setEditingNotesId(null);
        setMode("present");
    };

    const goNext = () =>
        setStepIndex((i) => Math.min(sortedElements.length - 1, i + 1));
    const goPrev = () => setStepIndex((i) => Math.max(0, i - 1));

    const handleTouchStart = (e: React.TouchEvent) => {
        touchStartX.current = e.touches[0].clientX;
        touchStartY.current = e.touches[0].clientY;
    };

    const handleTouchEnd = (e: React.TouchEvent) => {
        if (touchStartX.current === null || touchStartY.current === null)
            return;
        const deltaX = e.changedTouches[0].clientX - touchStartX.current;
        const deltaY = e.changedTouches[0].clientY - touchStartY.current;
        touchStartX.current = null;
        touchStartY.current = null;

        if (
            Math.abs(deltaX) < SWIPE_THRESHOLD ||
            Math.abs(deltaX) < Math.abs(deltaY) * 1.5
        )
            return;

        if (deltaX < -SWIPE_THRESHOLD) goNext();
        else if (deltaX > SWIPE_THRESHOLD) goPrev();
    };

    // ---------- MUSICIAN SERVICE VIEW ----------
    if (mode === "musician" && selectedService) {
        return (
            <MusicianServiceView
                service={selectedService}
                onLeaveService={() => {
                    setActiveSongId(null);
                    setViewingSongId(null);
                    setMode("list");
                }}
            />
        );
    }

    // ---------- SONG VIEW ----------
    if (mode === "song" && viewingSongId) {
        return (
            <SongView
                songId={viewingSongId}
                onBack={closeSong}
                onEdit={() => {}}
                setSong={(id: string) => {
                    setActiveSongId(id);
                    setViewingSongId(id);
                }}
                serviceMode={true}
            />
        );
    }

    // ---------- LIST VIEW ----------
    if (mode === "list") {
        return (
            <div className="h-full overflow-y-auto p-4 pb-28 no-scrollbar">
                {filteredServices.length === 0 ? (
                    <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
                        <div className="w-14 h-14 rounded-2xl bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-center">
                            <CalendarRange className="w-6 h-6 text-m3-secondary dark:text-m3-dark-secondary" />
                        </div>
                        <p className="text-sm font-semibold text-m3-secondary dark:text-m3-dark-secondary">
                            Nenhum culto encontrado
                        </p>
                    </div>
                ) : (
                    <div className="flex flex-col gap-2.5">
                        {filteredServices.map((service) => {
                            const count = service.elements?.length || 0;
                            return (
                                <button
                                    key={service.id}
                                    onClick={() => enterService(service.id)}
                                    className="w-full text-left bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl p-4 flex items-center gap-3 active:scale-[0.98] transition-transform touch-manipulation select-none"
                                >
                                    <div className="w-10 h-10 rounded-xl bg-m3-primary-light dark:bg-m3-dark-primary-light flex items-center justify-center shrink-0">
                                        <CalendarRange className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <p className="text-sm font-bold truncate text-m3-text dark:text-m3-dark-text">
                                            {service.name}
                                        </p>
                                        <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary truncate capitalize">
                                            {formatDate(service.date)} · {count}{" "}
                                            {count === 1 ? "item" : "itens"}
                                        </p>
                                    </div>
                                    <ChevronRight className="w-4 h-4 text-m3-secondary dark:text-m3-dark-secondary shrink-0" />
                                </button>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    }

    // ---------- DETAIL VIEW ----------
    if (mode === "detail" && selectedService) {
        return (
            <div className="h-full flex flex-col overflow-hidden">
                <div className="p-4 border-b border-m3-border dark:border-m3-dark-border flex items-center gap-2 shrink-0">
                    <button
                        onClick={() => setMode("list")}
                        className="p-2 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border active:scale-90 transition-transform touch-manipulation"
                    >
                        <ArrowLeft className="w-4 h-4 text-m3-text dark:text-m3-dark-text" />
                    </button>
                    <div className="min-w-0 flex-1">
                        <p className="text-sm font-bold truncate text-m3-text dark:text-m3-dark-text">
                            {selectedService.name}
                        </p>
                        <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary capitalize truncate">
                            {formatDate(selectedService.date)}
                        </p>
                    </div>
                </div>

                <div className="flex-1 overflow-y-auto p-4 pb-28 flex flex-col gap-2.5 no-scrollbar">
                    <button
                        onClick={startService}
                        disabled={!sortedElements.length}
                        className="w-full py-3.5 rounded-2xl bg-m3-primary dark:bg-m3-dark-primary text-white font-bold text-sm flex items-center justify-center gap-2 active:scale-[0.98] transition-transform touch-manipulation disabled:opacity-40"
                    >
                        <Play className="w-4 h-4" fill="currentColor" />
                        Iniciar Culto
                    </button>

                    {selectedService.notes && (
                        <div className="text-xs italic px-3.5 py-2.5 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border text-m3-secondary dark:text-m3-dark-secondary whitespace-pre-wrap">
                            {selectedService.notes}
                        </div>
                    )}

                    {sortedElements.length === 0 ? (
                        <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary text-center py-10">
                            Este culto ainda não tem elementos.
                        </p>
                    ) : (
                        sortedElements.map((el, idx) => {
                            const meta = getElementMeta(el.type);
                            const Icon = meta.icon;
                            const song =
                                el.type === "song" ? songFor(el) : undefined;
                            const isSong = el.type === "song";

                            return (
                                <div
                                    key={el.id}
                                    className={`w-full text-left bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl p-3.5 flex flex-col transition-all touch-manipulation select-none ${isSong ? "active:scale-[0.98] cursor-pointer" : ""}`}
                                    onClick={() =>
                                        isSong &&
                                        song &&
                                        openSong(song, "detail")
                                    }
                                >
                                    <div className="flex items-center gap-3">
                                        <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary w-4 shrink-0 text-center">
                                            {idx + 1}
                                        </span>
                                        <div
                                            className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${meta.bg} ${meta.text}`}
                                        >
                                            <Icon className="w-4 h-4" />
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <p className="text-sm font-semibold truncate text-m3-text dark:text-m3-dark-text">
                                                {isSong
                                                    ? song
                                                        ? song.title
                                                        : "Cântico Desconhecido"
                                                    : el.title || meta.label}
                                            </p>
                                            <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary truncate">
                                                {isSong
                                                    ? song?.artist || meta.label
                                                    : el.passage || meta.label}
                                            </p>
                                        </div>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setEditingNotesId(
                                                    editingNotesId === el.id
                                                        ? null
                                                        : el.id,
                                                );
                                            }}
                                            className={`p-2 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover active:scale-95 transition-transform ${editingNotesId === el.id ? "text-m3-primary dark:text-m3-dark-primary" : "text-m3-secondary dark:text-m3-dark-secondary"}`}
                                            title="Editar Notas"
                                        >
                                            <Edit2 className="w-4 h-4" />
                                        </button>
                                        {isSong && (
                                            <ChevronRight className="w-4 h-4 text-m3-secondary dark:text-m3-dark-secondary shrink-0 ml-1" />
                                        )}
                                    </div>

                                    {!isSong &&
                                        el.content &&
                                        !editingNotesId && (
                                            <div className="mt-3 pl-7">
                                                <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary line-clamp-2">
                                                    {el.content}
                                                </p>
                                            </div>
                                        )}

                                    {editingNotesId === el.id ? (
                                        <div
                                            className="mt-3 pl-7"
                                            onClick={(e) => e.stopPropagation()}
                                        >
                                            <NotesEditor
                                                initialNotes={el.notes || ""}
                                                onSave={(notes) =>
                                                    saveNotes(el.id, notes)
                                                }
                                                onCancel={() =>
                                                    setEditingNotesId(null)
                                                }
                                            />
                                        </div>
                                    ) : (
                                        el.notes && (
                                            <div className="mt-3 pl-7">
                                                <div className="text-xs text-m3-secondary dark:text-m3-dark-secondary italic bg-m3-bg dark:bg-m3-dark-bg px-3 py-2 rounded-xl whitespace-pre-wrap border border-m3-border/30 dark:border-m3-dark-border/30">
                                                    {el.notes}
                                                </div>
                                            </div>
                                        )
                                    )}
                                </div>
                            );
                        })
                    )}
                </div>
            </div>
        );
    }

    // ---------- PRESENTATION VIEW ----------
    if (mode === "present" && selectedService) {
        const total = sortedElements.length;
        const el = sortedElements[stepIndex];
        if (!el) {
            setMode("detail");
            return null;
        }
        const meta = getElementMeta(el.type);
        const Icon = meta.icon;
        const isSong = el.type === "song";
        const song = isSong ? songFor(el) : undefined;
        const isLast = stepIndex === total - 1;
        const isFirst = stepIndex === 0;
        const progress = total > 1 ? (stepIndex / (total - 1)) * 100 : 100;

        return (
            <div className="h-full flex flex-col overflow-hidden bg-m3-bg dark:bg-m3-dark-bg absolute inset-0 z-50">
                <div className="pt-4 px-4 shrink-0">
                    <div className="flex items-center justify-between mb-3">
                        <button
                            onClick={() => setMode("detail")}
                            className="p-2 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border active:scale-90 transition-transform touch-manipulation"
                        >
                            <X className="w-4 h-4 text-m3-text dark:text-m3-dark-text" />
                        </button>
                        <span className="text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary">
                            {stepIndex + 1} / {total}
                        </span>
                    </div>
                    <div className="h-1.5 rounded-full bg-m3-sidebar dark:bg-m3-dark-sidebar overflow-hidden">
                        <div
                            className="h-full rounded-full bg-m3-primary dark:bg-m3-dark-primary transition-[width] duration-300 ease-out"
                            style={{ width: `${progress}%` }}
                        />
                    </div>
                </div>

                <div
                    className="flex-1 overflow-y-auto px-6 flex flex-col items-center justify-center gap-4 text-center select-none no-scrollbar"
                    onTouchStart={handleTouchStart}
                    onTouchEnd={handleTouchEnd}
                >
                    <div
                        className={`w-14 h-14 rounded-2xl flex items-center justify-center ${meta.bg} ${meta.text}`}
                    >
                        <Icon className="w-6 h-6" />
                    </div>
                    <span
                        className={`text-[11px] font-bold px-3 py-1 rounded-full ${meta.bg} ${meta.text}`}
                    >
                        {meta.label}
                    </span>

                    <h2 className="text-2xl font-black text-m3-text dark:text-m3-dark-text leading-snug">
                        {isSong
                            ? song
                                ? song.title
                                : "Cântico Desconhecido"
                            : el.title || meta.label}
                    </h2>

                    {isSong ? (
                        <>
                            {song?.artist && (
                                <p className="text-sm text-m3-secondary dark:text-m3-dark-secondary font-medium">
                                    {song.artist}
                                </p>
                            )}
                            {song && (
                                <button
                                    onClick={() => openSong(song, "present")}
                                    className="mt-4 px-6 py-3.5 rounded-2xl bg-m3-primary dark:bg-m3-dark-primary text-white font-bold text-sm flex items-center gap-2 active:scale-95 transition-transform touch-manipulation shadow-lg shadow-m3-primary/20"
                                >
                                    <Music className="w-5 h-5" />
                                    Ver Acordes
                                </button>
                            )}
                        </>
                    ) : (
                        <div className="flex flex-col gap-3 max-w-sm w-full select-text mt-2">
                            {el.passage && (
                                <p className="text-sm font-bold text-m3-text dark:text-m3-dark-text bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border px-4 py-2.5 rounded-xl">
                                    {el.passage}
                                </p>
                            )}
                            {el.content && (
                                <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border p-5 rounded-2xl text-left">
                                    <p className="text-sm text-m3-text dark:text-m3-dark-text whitespace-pre-wrap leading-relaxed">
                                        {el.content}
                                    </p>
                                </div>
                            )}
                        </div>
                    )}

                    <div
                        className="w-full max-w-sm mt-4 text-left"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {editingNotesId === el.id ? (
                            <NotesEditor
                                initialNotes={el.notes || ""}
                                onSave={(notes) => saveNotes(el.id, notes)}
                                onCancel={() => setEditingNotesId(null)}
                            />
                        ) : (
                            <div
                                className={`relative group bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-2xl p-4 transition-colors cursor-pointer ${el.notes ? "hover:border-m3-primary/50" : "border-dashed border-m3-border/50 dark:border-m3-dark-border/50 hover:bg-m3-hover dark:hover:bg-m3-dark-hover"}`}
                                onClick={() => setEditingNotesId(el.id)}
                            >
                                <div className="flex items-center justify-between mb-1.5">
                                    <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
                                        <FileText className="w-3.5 h-3.5" />
                                        Notas
                                    </span>
                                    <Edit2 className="w-3.5 h-3.5 text-m3-secondary/50 group-hover:text-m3-primary transition-colors" />
                                </div>
                                {el.notes ? (
                                    <p className="text-sm text-m3-text dark:text-m3-dark-text italic whitespace-pre-wrap">
                                        {el.notes}
                                    </p>
                                ) : (
                                    <p className="text-xs text-m3-secondary/50 dark:text-m3-dark-secondary/50 italic">
                                        Tocar para adicionar notas...
                                    </p>
                                )}
                            </div>
                        )}
                    </div>

                    <p className="text-[10px] font-bold text-m3-secondary/50 dark:text-m3-dark-secondary/50 mt-6 select-none pointer-events-none uppercase tracking-widest">
                        Deslize para navegar
                    </p>
                </div>

                <div className="p-5 pb-[max(1.5rem,env(safe-area-inset-bottom))] flex items-center justify-between gap-3 shrink-0 bg-m3-bg dark:bg-m3-dark-bg border-t border-m3-border/30 dark:border-m3-dark-border/30">
                    <button
                        onClick={goPrev}
                        disabled={isFirst}
                        className="flex-1 py-4 rounded-2xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border font-bold text-sm flex items-center justify-center gap-2 text-m3-text dark:text-m3-dark-text disabled:opacity-30 active:scale-95 transition-transform touch-manipulation shadow-sm"
                    >
                        <ChevronLeft className="w-4 h-4" />
                        Anterior
                    </button>
                    {isLast ? (
                        <button
                            onClick={() => setMode("detail")}
                            className="flex-1 py-4 rounded-2xl bg-m3-primary dark:bg-m3-dark-primary text-white font-bold text-sm flex items-center justify-center gap-2 active:scale-95 transition-transform touch-manipulation shadow-md shadow-m3-primary/20"
                        >
                            <Check className="w-4 h-4" />
                            Concluir
                        </button>
                    ) : (
                        <button
                            onClick={goNext}
                            className="flex-1 py-4 rounded-2xl bg-m3-primary dark:bg-m3-dark-primary text-white font-bold text-sm flex items-center justify-center gap-2 active:scale-95 transition-transform touch-manipulation shadow-md shadow-m3-primary/20"
                        >
                            Seguinte
                            <ChevronRight className="w-4 h-4" />
                        </button>
                    )}
                </div>
            </div>
        );
    }

    return null;
}
