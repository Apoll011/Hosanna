// src/components/ServiceManager.tsx
import {
    ArrowLeft,
    BookOpen,
    Calendar,
    CalendarRange,
    Check,
    ChevronLeft,
    ChevronRight,
    Clock,
    Edit2,
    FileText,
    HelpCircle,
    Megaphone,
    MessageSquare,
    Music,
    Play,
    Plus,
    Save,
    Sparkles,
    X,
} from "lucide-react";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { useAppStore } from "../store/appStore";
import { ServiceElement, Song } from "../types";
import MusicianServiceView from "./MusicianServiceView";
import SongView from "./SongView";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { Card } from "./ui/card";

type ViewMode = "list" | "detail" | "present" | "song" | "musician";

const ELEMENT_META: Record<
    string,
    { label: string; icon: React.ElementType; color: string; badgeVariant: "primaryLight" | "success" | "warning" | "secondary" | "default" }
> = {
    song: {
        label: "Cântico",
        icon: Music,
        color: "text-primary bg-primary/10 border-primary/20",
        badgeVariant: "primaryLight",
    },
    welcome: {
        label: "Boas-vindas",
        icon: FileText,
        color: "text-blue-600 bg-blue-500/10 border-blue-500/20",
        badgeVariant: "secondary",
    },
    scripture: {
        label: "Escritura",
        icon: BookOpen,
        color: "text-purple-600 bg-purple-500/10 border-purple-500/20",
        badgeVariant: "secondary",
    },
    message: {
        label: "Mensagem",
        icon: MessageSquare,
        color: "text-amber-600 bg-amber-500/10 border-amber-500/20",
        badgeVariant: "warning",
    },
    announcement: {
        label: "Avisos",
        icon: Megaphone,
        color: "text-emerald-600 bg-emerald-500/10 border-emerald-500/20",
        badgeVariant: "success",
    },
};

const getElementMeta = (type: string) =>
    ELEMENT_META[type] || {
        label: type || "Elemento",
        icon: HelpCircle,
        color: "text-muted-foreground bg-muted border-border",
        badgeVariant: "secondary",
    };

const formatDate = (iso: string) => {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleDateString("pt-PT", {
        weekday: "short",
        day: "numeric",
        month: "short",
        year: "numeric",
    });
};

const formatFullDate = (iso: string) => {
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
            className="mt-2.5 flex flex-col gap-2 animate-in fade-in slide-in-from-top-1 duration-200 w-full"
            onClick={(e) => e.stopPropagation()}
            onTouchStart={(e) => e.stopPropagation()}
            onTouchMove={(e) => e.stopPropagation()}
            onTouchEnd={(e) => e.stopPropagation()}
        >
            <textarea
                value={value}
                onChange={(e) => setValue(e.target.value)}
                className="w-full bg-background border border-border focus:border-primary/60 rounded-xl p-3 text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-ring min-h-20 resize-none transition-all shadow-2xs"
                placeholder="Escreva anotações ou observações para este momento..."
                autoFocus
            />
            <div className="flex justify-end gap-2">
                <Button
                    variant="ghost"
                    size="sm"
                    onClick={onCancel}
                    className="h-8 text-xs font-semibold"
                >
                    Cancelar
                </Button>
                <Button
                    size="sm"
                    onClick={() => onSave(value)}
                    className="h-8 text-xs font-bold gap-1.5 shadow-xs"
                >
                    <Save className="w-3.5 h-3.5" />
                    Guardar
                </Button>
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

    const songCount = useMemo(
        () => sortedElements.filter((e) => e.type === "song").length,
        [sortedElements],
    );

    const filteredServices = useMemo(() => {
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
            <div className="h-full overflow-y-auto p-3.5 sm:p-5 pb-28 no-scrollbar bg-background">
                {filteredServices.length === 0 ? (
                    <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
                        <div className="w-14 h-14 rounded-3xl bg-muted/60 flex items-center justify-center border border-border/50">
                            <CalendarRange className="w-6 h-6 text-muted-foreground" />
                        </div>
                        <h3 className="text-sm font-bold text-foreground">
                            Nenhum culto agendado
                        </h3>
                        <p className="text-xs text-muted-foreground max-w-64">
                            Os cultos e reuniões planeados aparecerão aqui organizados cronologicamente.
                        </p>
                    </div>
                ) : (
                    <div className="flex flex-col gap-2.5 max-w-4xl mx-auto">
                        <div className="flex items-center justify-between px-1 mb-1">
                            <span className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider">
                                Próximos & Recentes
                            </span>
                            <Badge variant="secondary" className="text-[10px] font-mono font-semibold">
                                {filteredServices.length} {filteredServices.length === 1 ? "culto" : "cultos"}
                            </Badge>
                        </div>

                        {filteredServices.map((service) => {
                            const count = service.elements?.length || 0;
                            const songsInService = (service.elements || []).filter(
                                (e) => e.type === "song",
                            ).length;
                            return (
                                <div
                                    key={service.id}
                                    onClick={() => enterService(service.id)}
                                    className="bg-card border border-border/70 hover:border-primary/50 rounded-2xl p-4 flex items-center gap-3.5 active:scale-[0.985] transition-all cursor-pointer shadow-xs group"
                                >
                                    <div className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/20 flex flex-col items-center justify-center shrink-0 group-hover:bg-primary group-hover:text-white transition-colors">
                                        <Calendar className="w-5 h-5 text-primary group-hover:text-white transition-colors" />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <h3 className="text-sm font-bold truncate text-foreground group-hover:text-primary transition-colors">
                                            {service.name}
                                        </h3>
                                        <div className="flex items-center gap-2 mt-1 flex-wrap">
                                            <span className="text-xs text-muted-foreground capitalize font-medium">
                                                {formatDate(service.date)}
                                            </span>
                                            <span className="text-muted-foreground/40 text-xs">•</span>
                                            <span className="text-xs text-muted-foreground font-medium">
                                                {count} {count === 1 ? "item" : "itens"}
                                            </span>
                                            {songsInService > 0 && (
                                                <Badge variant="primaryLight" className="text-[10px] px-1.5 py-0 rounded">
                                                    {songsInService} {songsInService === 1 ? "cântico" : "cânticos"}
                                                </Badge>
                                            )}
                                        </div>
                                    </div>
                                    <ChevronRight className="w-4 h-4 text-muted-foreground group-hover:text-primary transition-colors shrink-0" />
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    }

    // ---------- REDESIGNED DETAIL VIEW (Streamlined, Zero Wasted Space, Fast Action) ----------
    if (mode === "detail" && selectedService) {
        return (
            <div className="h-full flex flex-col overflow-hidden bg-background">
                {/* Hero Top Bar */}
                <div className="p-3.5 sm:p-5 border-b border-border bg-card flex items-center justify-between gap-3 shrink-0">
                    <div className="flex items-center gap-3 min-w-0 flex-1">
                        <Button
                            variant="outline"
                            size="icon-sm"
                            onClick={() => setMode("list")}
                            className="rounded-xl shrink-0"
                            title="Voltar à lista"
                        >
                            <ArrowLeft className="w-4 h-4 text-primary" />
                        </Button>
                        <div className="min-w-0 flex-1">
                            <h2 className="text-sm sm:text-base font-bold truncate text-foreground">
                                {selectedService.name}
                            </h2>
                            <p className="text-xs text-muted-foreground capitalize truncate">
                                {formatFullDate(selectedService.date)}
                            </p>
                        </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                        {/* Quick toggle to Musician Mode */}
                        <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => setMode("musician")}
                            className="text-xs font-bold gap-1.5 hidden sm:inline-flex h-9 rounded-xl"
                            title="Alternar para Modo Músico"
                        >
                            <Music className="w-3.5 h-3.5 text-primary" />
                            Modo Músico
                        </Button>

                        <Button
                            size="sm"
                            onClick={startService}
                            disabled={!sortedElements.length}
                            className="text-xs font-bold gap-1.5 h-9 rounded-xl shadow-xs"
                        >
                            <Play className="w-3.5 h-3.5" fill="currentColor" />
                            Apresentar
                        </Button>
                    </div>
                </div>

                {/* Main Content Area */}
                <div className="flex-1 overflow-y-auto p-3.5 sm:p-5 pb-24 flex flex-col gap-3 no-scrollbar max-w-4xl mx-auto w-full">
                    {/* Summary banner */}
                    <div className="flex items-center justify-between px-1">
                        <div className="flex items-center gap-2">
                            <Badge variant="outline" className="text-xs font-semibold">
                                {sortedElements.length} {sortedElements.length === 1 ? "Elemento" : "Elementos"}
                            </Badge>
                            {songCount > 0 && (
                                <Badge variant="primaryLight" className="text-xs font-semibold">
                                    {songCount} {songCount === 1 ? "Cântico" : "Cânticos"}
                                </Badge>
                            )}
                        </div>

                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setMode("musician")}
                            className="sm:hidden text-xs text-primary font-bold h-7 px-2"
                        >
                            <Music className="w-3 h-3 mr-1" />
                            Modo Músico
                        </Button>
                    </div>

                    {selectedService.notes && (
                        <div className="text-xs text-muted-foreground italic px-4 py-3 rounded-2xl bg-muted/60 border border-border/80 whitespace-pre-wrap leading-relaxed">
                            {selectedService.notes}
                        </div>
                    )}

                    {sortedElements.length === 0 ? (
                        <div className="py-16 text-center">
                            <p className="text-xs text-muted-foreground">
                                Este culto ainda não tem elementos configurados.
                            </p>
                        </div>
                    ) : (
                        <div className="space-y-2">
                            {sortedElements.map((el, idx) => {
                                const meta = getElementMeta(el.type);
                                const Icon = meta.icon;
                                const song =
                                    el.type === "song" ? songFor(el) : undefined;
                                const isSong = el.type === "song";

                                return (
                                    <div
                                        key={el.id}
                                        onClick={() => {
                                            if (isSong && song) {
                                                openSong(song, "detail");
                                            }
                                        }}
                                        className={`w-full bg-card border border-border/80 rounded-2xl p-3 sm:p-3.5 flex flex-col transition-all active:scale-[0.99] select-none shadow-2xs ${
                                            isSong
                                                ? "hover:border-primary/60 cursor-pointer"
                                                : "hover:border-border"
                                        }`}
                                    >
                                        <div className="flex items-center gap-3">
                                            {/* Index number */}
                                            <span className="text-[11px] font-bold text-muted-foreground w-5 text-center font-mono shrink-0">
                                                {idx + 1}
                                            </span>

                                            {/* Type Icon */}
                                            <div
                                                className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 border ${meta.color}`}
                                            >
                                                <Icon className="w-4 h-4" />
                                            </div>

                                            {/* Title & Info */}
                                            <div className="min-w-0 flex-1">
                                                <div className="flex items-center gap-1.5 flex-wrap">
                                                    <p className="text-xs sm:text-sm font-bold truncate text-foreground">
                                                        {isSong
                                                            ? song
                                                                ? song.title
                                                                : "Cântico Desconhecido"
                                                            : el.title || meta.label}
                                                    </p>
                                                    <Badge
                                                        variant={meta.badgeVariant}
                                                        className="text-[9px] px-1.5 py-0 rounded font-semibold"
                                                    >
                                                        {meta.label}
                                                    </Badge>
                                                </div>
                                                <p className="text-[11px] text-muted-foreground truncate mt-0.5 font-medium">
                                                    {isSong
                                                        ? song?.artist || "Artista desconhecido"
                                                        : el.passage || el.content || ""}
                                                </p>
                                            </div>

                                            {/* Actions: Notes & Open */}
                                            <div className="flex items-center gap-1 shrink-0">
                                                <Button
                                                    variant="ghost"
                                                    size="icon-sm"
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        setEditingNotesId(
                                                            editingNotesId === el.id
                                                                ? null
                                                                : el.id,
                                                        );
                                                    }}
                                                    className={`rounded-xl text-muted-foreground hover:text-foreground ${
                                                        editingNotesId === el.id || el.notes
                                                            ? "text-primary bg-primary/10"
                                                            : ""
                                                    }`}
                                                    title="Anotações"
                                                >
                                                    <Edit2 className="w-3.5 h-3.5" />
                                                </Button>

                                                {isSong && (
                                                    <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0 ml-0.5" />
                                                )}
                                            </div>
                                        </div>

                                        {/* Notes editor inline without clutter */}
                                        {editingNotesId === el.id ? (
                                            <div
                                                className="mt-2 pl-8"
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
                                                <div className="mt-2 pl-8">
                                                    <div className="text-[11px] text-muted-foreground italic bg-muted/50 px-3 py-1.5 rounded-xl border border-border/50">
                                                        {el.notes}
                                                    </div>
                                                </div>
                                            )
                                        )}
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </div>
            </div>
        );
    }

    // ---------- REDESIGNED PRESENTATION VIEW (Polished, Fast, Native Gestures) ----------
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
            <div className="h-full flex flex-col overflow-hidden bg-background absolute inset-0 z-50">
                {/* Top status & Progress bar */}
                <div className="pt-[calc(0.75rem+env(safe-area-inset-top,0px))] px-4 pb-3 shrink-0 border-b border-border/60 bg-card">
                    <div className="flex items-center justify-between mb-2.5">
                        <Button
                            variant="ghost"
                            size="icon-sm"
                            onClick={() => setMode("detail")}
                            className="rounded-full"
                        >
                            <X className="w-4 h-4" />
                        </Button>
                        <Badge variant="outline" className="text-xs font-mono font-bold">
                            {stepIndex + 1} / {total}
                        </Badge>
                    </div>
                    <div className="h-1 rounded-full bg-muted overflow-hidden">
                        <div
                            className="h-full rounded-full bg-primary transition-all duration-300 ease-out"
                            style={{ width: `${progress}%` }}
                        />
                    </div>
                </div>

                {/* Presentation Card Slide */}
                <div
                    className="flex-1 overflow-y-auto px-6 py-8 flex flex-col items-center justify-center gap-5 text-center select-none no-scrollbar max-w-xl mx-auto w-full"
                    onTouchStart={handleTouchStart}
                    onTouchEnd={handleTouchEnd}
                >
                    <div
                        className={`w-16 h-16 rounded-3xl flex items-center justify-center border shadow-xs ${meta.color}`}
                    >
                        <Icon className="w-7 h-7" />
                    </div>

                    <Badge variant={meta.badgeVariant} className="text-xs px-3 py-1 font-bold rounded-full">
                        {meta.label}
                    </Badge>

                    <h2 className="text-2xl sm:text-3xl font-black text-foreground leading-snug tracking-tight">
                        {isSong
                            ? song
                                ? song.title
                                : "Cântico Desconhecido"
                            : el.title || meta.label}
                    </h2>

                    {isSong ? (
                        <div className="flex flex-col items-center gap-4">
                            {song?.artist && (
                                <p className="text-sm text-muted-foreground font-semibold">
                                    {song.artist}
                                </p>
                            )}
                            {song && (
                                <Button
                                    onClick={() => openSong(song, "present")}
                                    size="lg"
                                    className="rounded-2xl gap-2 font-bold shadow-lg shadow-primary/25 active:scale-95"
                                >
                                    <Music className="w-4 h-4" />
                                    Ver Cifra & Letra
                                </Button>
                            )}
                        </div>
                    ) : (
                        <div className="flex flex-col gap-3 w-full select-text mt-1">
                            {el.passage && (
                                <div className="text-sm font-bold text-foreground bg-muted/60 border border-border px-4 py-2.5 rounded-2xl inline-block mx-auto">
                                    {el.passage}
                                </div>
                            )}
                            {el.content && (
                                <div className="bg-card border border-border/80 p-5 rounded-3xl text-left shadow-xs">
                                    <p className="text-sm sm:text-base text-foreground whitespace-pre-wrap leading-relaxed">
                                        {el.content}
                                    </p>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Notes Box in Presentation Mode */}
                    <div
                        className="w-full mt-2 text-left"
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
                                className="bg-card border border-border/80 hover:border-primary/40 rounded-2xl p-3.5 transition-all cursor-pointer shadow-2xs"
                                onClick={() => setEditingNotesId(el.id)}
                            >
                                <div className="flex items-center justify-between mb-1">
                                    <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
                                        <FileText className="w-3 h-3" />
                                        Notas
                                    </span>
                                    <Edit2 className="w-3 h-3 text-muted-foreground" />
                                </div>
                                {el.notes ? (
                                    <p className="text-xs text-foreground italic whitespace-pre-wrap">
                                        {el.notes}
                                    </p>
                                ) : (
                                    <p className="text-[11px] text-muted-foreground/60 italic">
                                        Toque para adicionar anotações...
                                    </p>
                                )}
                            </div>
                        )}
                    </div>

                    <p className="text-[10px] font-semibold text-muted-foreground/50 mt-4 select-none pointer-events-none uppercase tracking-widest">
                        Deslize para avançar / retroceder
                    </p>
                </div>

                {/* Bottom Navigation Controls */}
                <div className="p-4 pb-[max(1.25rem,env(safe-area-inset-bottom))] flex items-center justify-between gap-3 shrink-0 bg-card border-t border-border">
                    <Button
                        variant="outline"
                        onClick={goPrev}
                        disabled={isFirst}
                        className="flex-1 h-12 rounded-2xl font-bold text-xs gap-1.5"
                    >
                        <ChevronLeft className="w-4 h-4" />
                        Anterior
                    </Button>
                    {isLast ? (
                        <Button
                            onClick={() => setMode("detail")}
                            className="flex-1 h-12 rounded-2xl font-bold text-xs gap-1.5 shadow-md"
                        >
                            <Check className="w-4 h-4" />
                            Concluir
                        </Button>
                    ) : (
                        <Button
                            onClick={goNext}
                            className="flex-1 h-12 rounded-2xl font-bold text-xs gap-1.5 shadow-md"
                        >
                            Seguinte
                            <ChevronRight className="w-4 h-4" />
                        </Button>
                    )}
                </div>
            </div>
        );
    }

    return null;
}
