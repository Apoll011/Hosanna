import {
    BookOpen,
    Edit2,
    FileText,
    HelpCircle,
    LogOut,
    Megaphone,
    Menu,
    MessageSquare,
    Music,
    Save,
    X,
} from "lucide-react";
import React, { useEffect, useMemo, useState } from "react";
import { useAppStore } from "../store/appStore";
import { Service, ServiceElement, Song } from "../types";
import SongView from "./SongView";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";

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

interface MusicianNotesEditorProps {
    initialNotes: string;
    onSave: (notes: string) => void;
    onCancel: () => void;
}

function MusicianNotesEditor({
    initialNotes,
    onSave,
    onCancel,
}: MusicianNotesEditorProps) {
    const [value, setValue] = useState(initialNotes);

    return (
        <div className="flex flex-col gap-2 w-full animate-in fade-in duration-150">
            <textarea
                value={value}
                onChange={(e) => setValue(e.target.value)}
                className="w-full bg-background border border-border rounded-xl p-3 text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-ring min-h-24 resize-none"
                placeholder="Adicione anotações para este elemento..."
                autoFocus
            />
            <div className="flex justify-end gap-2">
                <Button
                    variant="ghost"
                    size="sm"
                    onClick={onCancel}
                    className="h-8 text-xs"
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

interface MusicianServiceViewProps {
    service: Service;
    onLeaveService: () => void;
}

export default function MusicianServiceView({
    service,
    onLeaveService,
}: MusicianServiceViewProps) {
    const songs = useAppStore((state) => state.songs);
    const setActiveServiceId = useAppStore((state) => state.setActiveServiceId);
    const setActiveListContext = useAppStore(
        (state) => state.setActiveListContext,
    );
    const setActiveSongId = useAppStore((state) => state.setActiveSongId);
    const updateServiceElements = useAppStore(
        (state) => state.updateServiceElements,
    );

    const sortedElements = useMemo(() => {
        if (!service.elements) return [];
        return [...service.elements].sort(
            (a, b) => (a.position || 0) - (b.position || 0),
        );
    }, [service.elements]);

    const initialElementId = useMemo(() => {
        const firstSong = sortedElements.find((e) => e.type === "song");
        if (firstSong) return firstSong.id;
        return sortedElements[0]?.id || "";
    }, [sortedElements]);

    const [currentElementId, setCurrentElementId] =
        useState<string>(initialElementId);
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [editingNotes, setEditingNotes] = useState(false);

    useEffect(() => {
        setActiveServiceId(service.id);
        setActiveListContext({ type: "service", serviceId: service.id });
    }, [service.id, setActiveServiceId, setActiveListContext]);

    const currentElement = useMemo(
        () => sortedElements.find((e) => e.id === currentElementId) || null,
        [sortedElements, currentElementId],
    );

    const currentSong = useMemo(() => {
        if (!currentElement || currentElement.type !== "song") return null;
        return songs.find((s) => s.id === currentElement.songId) || null;
    }, [currentElement, songs]);

    useEffect(() => {
        if (currentSong) {
            setActiveSongId(currentSong.id);
        } else {
            setActiveSongId(null);
        }
    }, [currentSong, setActiveSongId]);

    const currentIndex = sortedElements.findIndex(
        (e) => e.id === currentElementId,
    );

    const navigateToElement = (id: string) => {
        setCurrentElementId(id);
        setEditingNotes(false);
        setIsMenuOpen(false);
    };

    const saveNotes = (notes: string) => {
        if (!currentElement) return;
        const newElements = sortedElements.map((e) =>
            e.id === currentElement.id ? { ...e, notes } : e,
        );
        updateServiceElements(service.id, newElements);
        setEditingNotes(false);
    };

    const songFor = (element: ServiceElement): Song | undefined =>
        songs.find((s) => s.id === element.songId);

    const currentMeta = currentElement
        ? getElementMeta(currentElement.type)
        : null;

    return (
        <div className="h-full flex flex-col overflow-hidden bg-background relative">
            {/* Direct Song / Service View without redundant top bar */}
            <div className="flex-1 overflow-hidden relative">
                {currentSong ? (
                    <SongView
                        songId={currentSong.id}
                        onBack={onLeaveService}
                        onEdit={() => {}}
                        setSong={(id: string) => {
                            const matching = sortedElements.find(
                                (e) => e.songId === id,
                            );
                            if (matching) navigateToElement(matching.id);
                        }}
                        serviceMode={true}
                        customLeftButton={
                            <div className="flex items-center gap-2">
                                <Button
                                    variant="outline"
                                    size="icon-sm"
                                    onClick={() => setIsMenuOpen(true)}
                                    className="rounded-xl shrink-0 h-9 w-9"
                                    title="Abrir Ordem do Culto"
                                >
                                    <Menu className="w-4 h-4 text-primary" />
                                </Button>
                                <div className="hidden sm:flex flex-col min-w-0">
                                    <span className="text-xs font-bold text-foreground truncate max-w-44">
                                        {service.name}
                                    </span>
                                    <span className="text-[10px] text-muted-foreground font-mono">
                                        Item {currentIndex + 1} de {sortedElements.length}
                                    </span>
                                </div>
                            </div>
                        }
                    />
                ) : (
                    <div className="h-full flex flex-col overflow-hidden bg-background">
                        {/* Minimal top action bar only for non-song elements */}
                        <div className="px-4 py-3 border-b border-border/80 bg-card flex items-center justify-between gap-2 shrink-0">
                            <div className="flex items-center gap-2">
                                <Button
                                    variant="outline"
                                    size="icon-sm"
                                    onClick={() => setIsMenuOpen(true)}
                                    className="rounded-xl h-9 w-9"
                                    title="Abrir Ordem do Culto"
                                >
                                    <Menu className="w-4 h-4 text-primary" />
                                </Button>
                                <span className="text-xs font-bold text-foreground">
                                    {service.name}
                                </span>
                            </div>
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={onLeaveService}
                                className="text-xs font-bold text-destructive hover:bg-destructive/10 gap-1.5 h-8"
                            >
                                <LogOut className="w-3.5 h-3.5" />
                                <span>Sair</span>
                            </Button>
                        </div>

                        <div className="flex-1 overflow-y-auto p-6 flex flex-col items-center justify-center text-center max-w-lg mx-auto w-full no-scrollbar">
                            {currentElement && currentMeta && (
                                <div className="flex flex-col items-center gap-4 w-full">
                                    <div className={`w-14 h-14 rounded-3xl flex items-center justify-center border shadow-xs ${currentMeta.color}`}>
                                        <currentMeta.icon className="w-6 h-6" />
                                    </div>
                                    <Badge variant={currentMeta.badgeVariant} className="text-xs px-3 py-1 font-bold rounded-full">
                                        {currentMeta.label}
                                    </Badge>
                                    <h2 className="text-xl sm:text-2xl font-black text-foreground">
                                        {currentElement.title || currentMeta.label}
                                    </h2>
                                    {currentElement.passage && (
                                        <p className="text-sm font-bold text-primary bg-muted/60 px-4 py-2 rounded-xl border border-border">
                                            {currentElement.passage}
                                        </p>
                                    )}
                                    {currentElement.content && (
                                        <div className="bg-card border border-border/80 p-5 rounded-2xl text-left w-full shadow-2xs">
                                            <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">
                                                {currentElement.content}
                                            </p>
                                        </div>
                                    )}

                                    {/* Notes in Non-Song items */}
                                    <div className="w-full mt-2 text-left">
                                        {editingNotes ? (
                                            <MusicianNotesEditor
                                                initialNotes={currentElement.notes || ""}
                                                onSave={saveNotes}
                                                onCancel={() => setEditingNotes(false)}
                                            />
                                        ) : (
                                            <div
                                                className="bg-card border border-border/80 hover:border-primary/40 rounded-2xl p-3.5 transition-all cursor-pointer shadow-2xs"
                                                onClick={() => setEditingNotes(true)}
                                            >
                                                <div className="flex items-center justify-between mb-1">
                                                    <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
                                                        <FileText className="w-3 h-3" />
                                                        Notas
                                                    </span>
                                                    <Edit2 className="w-3 h-3 text-muted-foreground" />
                                                </div>
                                                {currentElement.notes ? (
                                                    <p className="text-xs text-foreground italic whitespace-pre-wrap">
                                                        {currentElement.notes}
                                                    </p>
                                                ) : (
                                                    <p className="text-[11px] text-muted-foreground/60 italic">
                                                        Toque para adicionar anotações...
                                                    </p>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* Quick Slide-Over Menu for All Service Items */}
            {isMenuOpen && (
                <div className="fixed inset-0 z-50 flex">
                    <div
                        className="fixed inset-0 bg-black/60 backdrop-blur-xs transition-opacity"
                        onClick={() => setIsMenuOpen(false)}
                    />
                    <div className="relative w-80 max-w-[85vw] bg-card border-r border-border h-full shadow-2xl flex flex-col z-10 animate-in slide-in-from-left duration-200">
                        <div className="p-4 border-b border-border bg-muted/40 flex items-center justify-between">
                            <div>
                                <h3 className="text-sm font-bold text-foreground">
                                    Ordem do Culto
                                </h3>
                                <p className="text-[10px] text-muted-foreground">
                                    {sortedElements.length} momentos
                                </p>
                            </div>
                            <Button
                                variant="ghost"
                                size="icon-sm"
                                onClick={() => setIsMenuOpen(false)}
                                className="rounded-full"
                            >
                                <X className="w-4 h-4" />
                            </Button>
                        </div>

                        <div className="flex-1 overflow-y-auto p-3 space-y-1.5 no-scrollbar">
                            {sortedElements.map((el, idx) => {
                                const meta = getElementMeta(el.type);
                                const isSelected = el.id === currentElementId;
                                const song =
                                    el.type === "song" ? songFor(el) : undefined;
                                return (
                                    <button
                                        key={el.id}
                                        onClick={() => navigateToElement(el.id)}
                                        className={`w-full flex items-center gap-3 p-2.5 rounded-xl text-xs font-bold transition-all text-left cursor-pointer active:scale-[0.98] ${
                                            isSelected
                                                ? "bg-primary text-primary-foreground shadow-xs"
                                                : "text-foreground hover:bg-accent/60"
                                        }`}
                                    >
                                        <span className={`text-[10px] font-mono w-4 text-center ${isSelected ? "text-primary-foreground/80" : "text-muted-foreground"}`}>
                                            {idx + 1}
                                        </span>
                                        <div className="min-w-0 flex-1">
                                            <p className="truncate font-bold">
                                                {el.type === "song"
                                                    ? song?.title || "Cântico"
                                                    : el.title || meta.label}
                                            </p>
                                            <p className={`text-[10px] truncate ${isSelected ? "text-primary-foreground/80" : "text-muted-foreground"}`}>
                                                {el.type === "song" ? song?.artist || "Cântico" : meta.label}
                                            </p>
                                        </div>
                                        {el.type === "song" && song?.metadata?.key && (
                                            <span className={`text-[10px] px-1.5 py-0.5 rounded font-mono ${isSelected ? "bg-primary-foreground/20 text-primary-foreground" : "bg-muted text-muted-foreground"}`}>
                                                {song.metadata.key}
                                            </span>
                                        )}
                                    </button>
                                );
                            })}
                        </div>

                        {/* Slide-over Footer with Exit Service Option */}
                        <div className="p-3 border-t border-border bg-muted/30">
                            <Button
                                variant="outline"
                                onClick={onLeaveService}
                                className="w-full text-xs font-bold text-destructive hover:bg-destructive/10 border-destructive/30 gap-1.5"
                            >
                                <LogOut className="w-3.5 h-3.5" />
                                <span>Sair do Modo Culto</span>
                            </Button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
