// src/components/MusicianServiceView.tsx
import {
    BookOpen,
    CalendarRange,
    ChevronLeft,
    ChevronRight,
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
                className="w-full bg-m3-bg dark:bg-m3-dark-bg border border-m3-border dark:border-m3-dark-border rounded-xl p-3 text-xs text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 min-h-24 resize-none"
                placeholder="Adicione notas para este elemento..."
                autoFocus
            />
            <div className="flex justify-end gap-2">
                <button
                    onClick={onCancel}
                    className="px-3.5 py-1.5 rounded-xl text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-all"
                >
                    Cancelar
                </button>
                <button
                    onClick={() => onSave(value)}
                    className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl text-xs font-bold bg-m3-primary dark:bg-m3-dark-primary text-white active:scale-95 transition-transform shadow-xs"
                >
                    <Save className="w-3.5 h-3.5" />
                    Guardar
                </button>
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

    // Initial element: find first song element or default to 1st element
    const initialElementId = useMemo(() => {
        const firstSong = sortedElements.find((e) => e.type === "song");
        if (firstSong) return firstSong.id;
        return sortedElements[0]?.id || "";
    }, [sortedElements]);

    const [selectedElementId, setSelectedElementId] =
        useState<string>(initialElementId);
    const [isDrawerOpen, setIsDrawerOpen] = useState(false);
    const [editingNotesId, setEditingNotesId] = useState<string | null>(null);

    // Sync active service context in store
    useEffect(() => {
        setActiveServiceId(service.id);
        setActiveListContext({ type: "service", serviceId: service.id });
    }, [service.id, setActiveServiceId, setActiveListContext]);

    // If selectedElementId is empty or not in sortedElements, reset to initial
    useEffect(() => {
        if (
            sortedElements.length > 0 &&
            !sortedElements.some((e) => e.id === selectedElementId)
        ) {
            setSelectedElementId(initialElementId);
        }
    }, [sortedElements, selectedElementId, initialElementId]);

    const songFor = (element: ServiceElement): Song | undefined => {
        if (element.type !== "song" || !element.songId) return undefined;
        return (
            songs.find((s) => s.remoteId === element.songId) ||
            songs.find((s) => s.id === element.songId)
        );
    };

    const selectedElementIndex = sortedElements.findIndex(
        (e) => e.id === selectedElementId,
    );
    const currentElement: ServiceElement | undefined =
        sortedElements[selectedElementIndex] || sortedElements[0];

    const currentSong = currentElement ? songFor(currentElement) : undefined;

    // Sync activeSongId in store when switching elements
    useEffect(() => {
        if (currentElement && currentElement.type === "song" && currentSong) {
            setActiveSongId(currentSong.id);
        } else {
            setActiveSongId(null);
        }
    }, [currentElement, currentSong, setActiveSongId]);

    const handleSelectElement = (elementId: string) => {
        setSelectedElementId(elementId);
        setIsDrawerOpen(false);
        setEditingNotesId(null);
    };

    const handleSaveNotes = (elementId: string, notes: string) => {
        const newElements = (service.elements || []).map((e) =>
            e.id === elementId ? { ...e, notes } : e,
        );
        updateServiceElements(service.id, newElements);
        setEditingNotesId(null);
    };

    const goPrevElement = () => {
        if (selectedElementIndex > 0) {
            handleSelectElement(sortedElements[selectedElementIndex - 1].id);
        }
    };

    const goNextElement = () => {
        if (selectedElementIndex < sortedElements.length - 1) {
            handleSelectElement(sortedElements[selectedElementIndex + 1].id);
        }
    };

    return (
        <div className="h-full w-full flex flex-col relative overflow-hidden bg-m3-bg dark:bg-m3-dark-bg">
            {/* LEFT MENU DRAWER (Songbook Pro Style) */}
            {isDrawerOpen && (
                <div
                    className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs transition-opacity animate-in fade-in duration-200"
                    onClick={() => setIsDrawerOpen(false)}
                >
                    <div
                        className="fixed top-0 left-0 bottom-0 z-50 w-80 max-w-[85vw] bg-m3-card dark:bg-m3-dark-card border-r border-m3-border dark:border-m3-dark-border shadow-2xl flex flex-col animate-in slide-in-from-left duration-200"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Drawer Header */}
                        <div className="p-4 border-b border-m3-border dark:border-m3-dark-border flex flex-col gap-3 shrink-0 bg-m3-sidebar dark:bg-m3-dark-sidebar">
                            <div className="flex items-center justify-between">
                                <div className="min-w-0 flex-1">
                                    <h3 className="text-base font-black text-m3-text dark:text-m3-dark-text truncate">
                                        {service.name}
                                    </h3>
                                    <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary capitalize truncate">
                                        {formatDate(service.date)}
                                    </p>
                                </div>
                                <button
                                    onClick={() => setIsDrawerOpen(false)}
                                    className="p-2 rounded-xl text-m3-secondary dark:text-m3-dark-secondary hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors shrink-0"
                                >
                                    <X className="w-5 h-5" />
                                </button>
                            </div>

                            {/* LEAVE SERVICE BUTTON */}
                            <button
                                onClick={() => {
                                    setIsDrawerOpen(false);
                                    onLeaveService();
                                }}
                                className="w-full py-2.5 px-3 rounded-xl bg-red-50 dark:bg-red-950/30 text-red-600 dark:text-red-400 border border-red-200/50 dark:border-red-900/30 font-bold text-xs flex items-center justify-center gap-2 hover:bg-red-100 dark:hover:bg-red-900/40 active:scale-95 transition-all shadow-xs"
                            >
                                <LogOut className="w-4 h-4" />
                                Sair do Culto
                            </button>
                        </div>

                        {/* Drawer Elements List */}
                        <div className="flex-1 overflow-y-auto p-3 space-y-1.5 no-scrollbar">
                            <div className="px-2 py-1 flex items-center justify-between">
                                <span className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider">
                                    Elementos do Culto
                                </span>
                                <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary">
                                    {sortedElements.length}{" "}
                                    {sortedElements.length === 1
                                        ? "item"
                                        : "itens"}
                                </span>
                            </div>

                            {sortedElements.map((el, idx) => {
                                const meta = getElementMeta(el.type);
                                const Icon = meta.icon;
                                const isSong = el.type === "song";
                                const song = isSong ? songFor(el) : undefined;
                                const isSelected = el.id === selectedElementId;

                                return (
                                    <button
                                        key={el.id}
                                        onClick={() =>
                                            handleSelectElement(el.id)
                                        }
                                        className={`w-full text-left p-3 rounded-xl border flex items-center gap-3 transition-all active:scale-[0.98] ${
                                            isSelected
                                                ? "bg-m3-primary/10 dark:bg-m3-dark-primary/15 border-m3-primary/50 dark:border-m3-dark-primary/50 shadow-xs"
                                                : "bg-m3-sidebar/50 dark:bg-m3-dark-sidebar/50 border-m3-border/40 dark:border-m3-dark-border/40 hover:bg-m3-hover dark:hover:bg-m3-dark-hover"
                                        }`}
                                    >
                                        <span
                                            className={`text-xs font-bold w-4 shrink-0 text-center ${
                                                isSelected
                                                    ? "text-m3-primary dark:text-m3-dark-primary"
                                                    : "text-m3-secondary dark:text-m3-dark-secondary"
                                            }`}
                                        >
                                            {idx + 1}
                                        </span>
                                        <div
                                            className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${meta.bg} ${meta.text}`}
                                        >
                                            <Icon className="w-4 h-4" />
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <p
                                                className={`text-xs font-bold truncate ${
                                                    isSelected
                                                        ? "text-m3-primary dark:text-m3-dark-primary"
                                                        : "text-m3-text dark:text-m3-dark-text"
                                                }`}
                                            >
                                                {isSong
                                                    ? song
                                                        ? song.title
                                                        : "Cântico Desconhecido"
                                                    : el.title || meta.label}
                                            </p>
                                            <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary truncate">
                                                {isSong
                                                    ? song?.artist || meta.label
                                                    : el.passage || meta.label}
                                            </p>
                                        </div>
                                        {isSelected && (
                                            <div className="w-2 h-2 rounded-full bg-m3-primary dark:bg-m3-dark-primary shrink-0" />
                                        )}
                                    </button>
                                );
                            })}
                        </div>
                    </div>
                </div>
            )}

            {/* MAIN CONTENT VIEW */}
            {!currentElement ? (
                /* Empty state */
                <div className="flex-1 flex flex-col items-center justify-center p-6 text-center">
                    <div className="w-14 h-14 rounded-2xl bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-center mb-3">
                        <CalendarRange className="w-6 h-6 text-m3-secondary dark:text-m3-dark-secondary" />
                    </div>
                    <p className="text-sm font-bold text-m3-text dark:text-m3-dark-text">
                        Este culto não tem elementos.
                    </p>
                    <button
                        onClick={onLeaveService}
                        className="mt-4 px-4 py-2 bg-m3-primary text-white text-xs font-bold rounded-xl"
                    >
                        Voltar aos Cultos
                    </button>
                </div>
            ) : currentElement.type === "song" && currentSong ? (
                /* SONG VIEW MODE WITH MENU BUTTON */
                <SongView
                    songId={currentSong.id}
                    onBack={() => setIsDrawerOpen(true)}
                    onEdit={() => {}}
                    setSong={(newSongId) => {
                        const targetEl = sortedElements.find((e) => {
                            if (e.type !== "song") return false;
                            const s = songFor(e);
                            return s?.id === newSongId;
                        });
                        if (targetEl) {
                            setSelectedElementId(targetEl.id);
                        }
                    }}
                    serviceMode={true}
                    customLeftButton={
                        <button
                            onClick={() => setIsDrawerOpen(true)}
                            className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border/40 dark:border-m3-dark-border/40 text-m3-text dark:text-m3-dark-text font-medium hover:bg-m3-hover active:scale-95 transition-all shadow-xs"
                            title="Abrir Menu do Culto"
                        >
                            <Menu className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                            <span className="text-xs font-bold">Menu</span>
                        </button>
                    }
                />
            ) : (
                /* NON-SONG ELEMENT VIEW OR MISSING SONG */
                <div className="flex-1 flex flex-col h-full overflow-hidden">
                    {/* Top Navbar */}
                    <div className="h-16 px-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0 select-none z-40 relative">
                        <button
                            onClick={() => setIsDrawerOpen(true)}
                            className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border/40 dark:border-m3-dark-border/40 text-m3-text dark:text-m3-dark-text font-medium hover:bg-m3-hover active:scale-95 transition-all shadow-xs"
                            title="Abrir Menu do Culto"
                        >
                            <Menu className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
                            <span className="text-xs font-bold">Menu</span>
                        </button>
                        <div className="text-center min-w-0 px-2">
                            <h2 className="text-xs font-bold text-m3-text dark:text-m3-dark-text truncate">
                                {service.name}
                            </h2>
                            <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary">
                                Elemento {selectedElementIndex + 1} de{" "}
                                {sortedElements.length}
                            </p>
                        </div>
                        <div className="w-16" />{" "}
                        {/* Spacer for visual center alignment */}
                    </div>

                    {/* Non-Song Main Body */}
                    <div className="flex-1 overflow-y-auto p-4 sm:p-6 flex flex-col items-center justify-start max-w-2xl mx-auto w-full gap-5 no-scrollbar">
                        {/* Meta badge */}
                        {(() => {
                            const meta = getElementMeta(currentElement.type);
                            const Icon = meta.icon;
                            return (
                                <div className="flex flex-col items-center gap-3 pt-4">
                                    <div
                                        className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-xs ${meta.bg} ${meta.text}`}
                                    >
                                        <Icon className="w-7 h-7" />
                                    </div>
                                    <span
                                        className={`text-xs font-bold px-3.5 py-1 rounded-full uppercase tracking-wider ${meta.bg} ${meta.text}`}
                                    >
                                        {meta.label}
                                    </span>
                                </div>
                            );
                        })()}

                        {/* Title */}
                        <h1 className="text-xl sm:text-2xl font-black text-center text-m3-text dark:text-m3-dark-text leading-snug">
                            {currentElement.type === "song"
                                ? "Cântico não encontrado"
                                : currentElement.title ||
                                  getElementMeta(currentElement.type).label}
                        </h1>

                        {/* Passage Card */}
                        {currentElement.passage && (
                            <div className="w-full bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border p-4 rounded-2xl flex items-center gap-3">
                                <BookOpen className="w-5 h-5 text-fuchsia-600 dark:text-fuchsia-400 shrink-0" />
                                <div>
                                    <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider block">
                                        Passagem Bíblica
                                    </span>
                                    <p className="text-sm font-bold text-m3-text dark:text-m3-dark-text">
                                        {currentElement.passage}
                                    </p>
                                </div>
                            </div>
                        )}

                        {/* Content Box */}
                        {currentElement.content && (
                            <div className="w-full bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border p-5 rounded-2xl">
                                <p className="text-sm text-m3-text dark:text-m3-dark-text whitespace-pre-wrap leading-relaxed">
                                    {currentElement.content}
                                </p>
                            </div>
                        )}

                        {/* Notes Section */}
                        <div className="w-full space-y-2">
                            <div className="flex items-center justify-between px-1">
                                <span className="text-[11px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
                                    <FileText className="w-3.5 h-3.5" />
                                    Notas Músico
                                </span>
                                {editingNotesId !== currentElement.id && (
                                    <button
                                        onClick={() =>
                                            setEditingNotesId(currentElement.id)
                                        }
                                        className="text-xs font-bold text-m3-primary dark:text-m3-dark-primary hover:underline flex items-center gap-1"
                                    >
                                        <Edit2 className="w-3 h-3" />
                                        {currentElement.notes
                                            ? "Editar"
                                            : "Adicionar"}
                                    </button>
                                )}
                            </div>

                            {editingNotesId === currentElement.id ? (
                                <MusicianNotesEditor
                                    initialNotes={currentElement.notes || ""}
                                    onSave={(notes) =>
                                        handleSaveNotes(
                                            currentElement.id,
                                            notes,
                                        )
                                    }
                                    onCancel={() => setEditingNotesId(null)}
                                />
                            ) : currentElement.notes ? (
                                <div
                                    onClick={() =>
                                        setEditingNotesId(currentElement.id)
                                    }
                                    className="p-4 rounded-2xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border text-xs italic text-m3-text dark:text-m3-dark-text whitespace-pre-wrap cursor-pointer hover:border-m3-primary/40 transition-colors"
                                >
                                    {currentElement.notes}
                                </div>
                            ) : (
                                <button
                                    onClick={() =>
                                        setEditingNotesId(currentElement.id)
                                    }
                                    className="w-full p-4 rounded-2xl bg-m3-sidebar/50 dark:bg-m3-dark-sidebar/50 border border-dashed border-m3-border dark:border-m3-dark-border text-xs italic text-m3-secondary dark:text-m3-dark-secondary text-left hover:bg-m3-hover transition-colors"
                                >
                                    Nenhuma nota adicionada. Clique para
                                    escrever notas de apoio...
                                </button>
                            )}
                        </div>
                    </div>

                    {/* Bottom Navigation Bar */}
                    <div className="p-3 bg-m3-toolbar dark:bg-m3-dark-toolbar border-t border-m3-border dark:border-m3-dark-border flex items-center justify-between gap-3 shrink-0">
                        <button
                            onClick={goPrevElement}
                            disabled={selectedElementIndex <= 0}
                            className="flex-1 py-3 px-4 rounded-xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border font-bold text-xs flex items-center justify-center gap-1.5 text-m3-text dark:text-m3-dark-text disabled:opacity-30 active:scale-95 transition-all shadow-xs"
                        >
                            <ChevronLeft className="w-4 h-4" />
                            Anterior
                        </button>

                        <button
                            onClick={goNextElement}
                            disabled={
                                selectedElementIndex >=
                                sortedElements.length - 1
                            }
                            className="flex-1 py-3 px-4 rounded-xl bg-m3-primary dark:bg-m3-dark-primary text-white font-bold text-xs flex items-center justify-center gap-1.5 disabled:opacity-30 active:scale-95 transition-all shadow-xs"
                        >
                            Seguinte
                            <ChevronRight className="w-4 h-4" />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
