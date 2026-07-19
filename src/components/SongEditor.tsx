/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useRef } from 'react';
import { Save, X, Type, Music, Tag, Clock, Hash, AlertTriangle, Info, ListCollapse } from 'lucide-react';
import { useAppStore } from '../store/appStore';
import { parseChordPro, buildChordProText } from '../lib/chordpro';

interface SongEditorProps {
  songId?: string; // If undefined, we are creating a new song
  onClose: () => void;
}

export default function SongEditor({ songId, onClose }: SongEditorProps) {
  const songs = useAppStore(state => state.songs);
  const virtualFiles = useAppStore(state => state.virtualFiles);
  const createVirtualFile = useAppStore(state => state.createVirtualFile);
  const updateVirtualFile = useAppStore(state => state.updateVirtualFile);

  const existingSong = songId ? songs.find(s => s.id === songId) : null;
  const existingFile = songId ? virtualFiles.find(f => f.path === songId) : null;

  // Metadata Form Fields
  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [key, setKey] = useState('C');
  const [capo, setCapo] = useState('0');
  const [tempo, setTempo] = useState('');
  const [songNumber, setSongNumber] = useState('');
  const [youtube, setYoutube] = useState('');
  const [composer, setComposer] = useState('');
  const [copyright, setCopyright] = useState('');
  
  // Implicit Category Folder selector
  const [folder, setFolder] = useState('Geral');
  const [fileName, setFileName] = useState('');

  // Song lyrics body (parsed from raw file without metadata lines)
  const [bodyText, setBodyText] = useState('');
  
  // Validation status
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Load existing song content on mount
  useEffect(() => {
    if (existingSong && existingFile) {
      const parsed = parseChordPro(existingFile.content);
      setTitle(parsed.metadata.title || '');
      setArtist(parsed.metadata.artist || '');
      setKey(parsed.metadata.key || 'C');
      setCapo(parsed.metadata.capo || '0');
      setTempo(parsed.metadata.tempo || '');
      setSongNumber(parsed.metadata.songNumber || '');
      setYoutube(parsed.metadata.youtube || '');
      setComposer(parsed.metadata.composer || '');
      setCopyright(parsed.metadata.copyright || '');
      setFolder(existingSong.folder || 'Geral');
      
      const parts = existingSong.id.split('/');
      setFileName(parts.pop() || '');

      // To isolate body text, find the first line that is not a directive at the top
      const lines = existingFile.content.split('\n');
      const bodyLines = lines.filter(line => {
        const trimmed = line.trim();
        // Skip metadata headers for editing body
        const isMeta = trimmed.startsWith('{title:') || trimmed.startsWith('{t:') ||
                       trimmed.startsWith('{subtitle:') || trimmed.startsWith('{st:') ||
                       trimmed.startsWith('{artist:') || trimmed.startsWith('{a:') ||
                       trimmed.startsWith('{key:') || trimmed.startsWith('{k:') ||
                       trimmed.startsWith('{capo:') || trimmed.startsWith('{tempo:') ||
                       trimmed.startsWith('{song_number:') || trimmed.startsWith('{number:') ||
                       trimmed.startsWith('{youtube:') || trimmed.startsWith('{yt:') ||
                       trimmed.startsWith('{composer:') || trimmed.startsWith('{copyright:') ||
                       trimmed.startsWith('{album:');
        return !isMeta;
      });

      setBodyText(bodyLines.join('\n').trim());
    } else {
      // Set defaults for a new song
      setTitle('');
      setArtist('');
      setKey('G');
      setCapo('0');
      setTempo('');
      setSongNumber('');
      setComposer('');
      setCopyright('');
      setFolder('Adoração');
      setFileName('');
      setBodyText(`{start_of_chorus: Refrão}
Digno és [G]Tu, Senhor de [D]receber
A [C]glória e o lou[G]vor
{end_of_chorus}

[G]Graças te damos [D]pelo Teu amor
[C]Exaltamos o Teu [G]Santo Nome`);
    }
  }, [songId, existingSong, existingFile]);

  // Insert helper text at textarea cursor position
  const insertTextAtCursor = (textToInsert: string) => {
    const textarea = textareaRef.current;
    if (!textarea) return;

    const startPos = textarea.selectionStart;
    const endPos = textarea.selectionEnd;
    const value = textarea.value;

    const newValue = value.substring(0, startPos) + textToInsert + value.substring(endPos);
    setBodyText(newValue);

    // Reposition cursor
    setTimeout(() => {
      textarea.focus();
      textarea.selectionStart = textarea.selectionEnd = startPos + textToInsert.length;
    }, 10);
  };

  const getQuickChordsForKey = (currentKey: string) => {
    // Map of popular keys and their common diatonic chords
    const chordMap: Record<string, string[]> = {
      'C': ['C', 'F', 'G', 'Am', 'Dm', 'Em', 'G/B', 'C/E'],
      'D': ['D', 'G', 'A', 'Bm', 'Em', 'F#m', 'A/C#', 'D/F#'],
      'E': ['E', 'A', 'B', 'C#m', 'F#m', 'G#m', 'B/D#', 'E/G#'],
      'F': ['F', 'Bb', 'C', 'Dm', 'Gm', 'Am', 'C/E', 'F/A'],
      'G': ['G', 'C', 'D', 'Em', 'Am', 'Bm', 'D/F#', 'G/B'],
      'A': ['A', 'D', 'E', 'F#m', 'Bm', 'C#m', 'E/G#', 'A/C#'],
      'B': ['B', 'E', 'F#', 'G#m', 'C#m', 'D#m', 'F#/A#', 'B/D#'],
    };
    
    // Normalize key (e.g. Eb -> E, C# -> C) just to fallback if needed, but simple map first
    const baseKey = currentKey.replace(/m$/, '').replace(/[b#]$/, '');
    
    if (chordMap[currentKey]) return chordMap[currentKey];
    if (chordMap[baseKey]) return chordMap[baseKey];
    
    // Default fallback
    return ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  };

  const handleSave = () => {
    if (!title.trim()) {
      setErrorMsg('O título do cântico é obrigatório.');
      return;
    }

    try {
      const metadata = {
        title: title.trim(),
        artist: artist.trim() || undefined,
        key: key.trim() || undefined,
        capo: capo.trim() !== '0' ? capo.trim() : undefined,
        tempo: tempo.trim() || undefined,
        songNumber: songNumber.trim() || undefined,
        youtube: youtube.trim() || undefined,
        composer: composer.trim() || undefined,
        copyright: copyright.trim() || undefined
      };

      const fullChordPro = buildChordProText(metadata, bodyText);

      if (songId) {
        // Editing existing file
        updateVirtualFile(songId, fullChordPro);
      } else {
        // Creating new file
        let cleanFileName = fileName.trim().replace(/[\/\\?%*:|"<>\s]/g, '_');
        if (!cleanFileName) {
          cleanFileName = title.trim().replace(/[\/\\?%*:|"<>\s]/g, '_').toLowerCase();
        }
        if (!cleanFileName.endsWith('.chopro')) {
          cleanFileName += '.chopro';
        }

        createVirtualFile(folder, cleanFileName, fullChordPro);
      }

      onClose();
    } catch (e: any) {
      setErrorMsg(e.message || 'Erro ao guardar ficheiro.');
    }
  };

  return (
    <div className="flex-1 flex flex-col h-full bg-m3-bg dark:bg-m3-dark-bg overflow-hidden select-none">
      
      {/* Editor Navbar header */}
      <div className="h-16 px-4 bg-m3-toolbar dark:bg-m3-dark-toolbar border-b border-m3-border dark:border-m3-dark-border flex items-center justify-between shrink-0">
        <button
          onClick={onClose}
          id="btn_editor_close"
          className="text-m3-secondary hover:text-m3-text p-2 rounded-full hover:bg-m3-hover flex items-center gap-1.5 text-xs font-bold transition-all"
        >
          <X className="w-4 h-4" />
          Cancelar
        </button>
        <h3 className="text-sm font-black text-m3-text dark:text-m3-dark-text font-mono">
          {songId ? 'Editar Cântico' : 'Novo Cântico .chopro'}
        </h3>
        <button
          onClick={handleSave}
          id="btn_editor_save"
          className="flex items-center gap-1.5 bg-m3-primary hover:opacity-90 text-white text-xs px-5 py-2 rounded-full font-black shadow-xs transition-all active:scale-95"
        >
          <Save className="w-4 h-4" />
          Guardar
        </button>
      </div>

      {/* Editor Main body container */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 no-scrollbar">
        {errorMsg && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 text-xs text-red-600 dark:text-red-400 rounded-xl border border-red-200 dark:border-red-900 flex items-start gap-2 select-text">
            <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* SECTION 1: METADATA FORM FIELDS */}
        <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-3">
          <div className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider mb-1">
            Metadados do Cântico (Diretivas ChordPro)
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Título *</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Ex: Digno és Tu"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
              />
            </div>
            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Artista / Autor</label>
              <input
                type="text"
                value={artist}
                onChange={(e) => setArtist(e.target.value)}
                placeholder="Ex: Aline Barros"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
              />
            </div>
          </div>

          <div className="grid grid-cols-4 gap-2">
            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Tom Base</label>
              <select
                value={key}
                onChange={(e) => setKey(e.target.value)}
                className="w-full px-2 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 font-bold"
              >
                {['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'Ab', 'A', 'Bb', 'B'].map(k => (
                  <option key={k} value={k}>{k}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Capo</label>
              <select
                value={capo}
                onChange={(e) => setCapo(e.target.value)}
                className="w-full px-2 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
              >
                {['0', '1', '2', '3', '4', '5', '6', '7'].map(c => (
                  <option key={c} value={c}>{c === '0' ? 'Sem' : `${c}ª casa`}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Ritmo (BPM)</label>
              <input
                type="number"
                value={tempo}
                onChange={(e) => setTempo(e.target.value)}
                placeholder="Ex: 80"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 font-mono"
              />
            </div>

            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Nº Cântico</label>
              <input
                type="text"
                value={songNumber}
                onChange={(e) => setSongNumber(e.target.value)}
                placeholder="Ex: 45"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 font-bold"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Vídeo YouTube (ID ou URL)</label>
              <input
                type="text"
                value={youtube}
                onChange={(e) => setYoutube(e.target.value)}
                placeholder="Ex: dQw4w9WgXcQ"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
              />
            </div>
            <div>
              <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Compositor</label>
              <input
                type="text"
                value={composer}
                onChange={(e) => setComposer(e.target.value)}
                placeholder="Ex: John Doe"
                className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
              />
            </div>
          </div>

          {!songId && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-m3-border/30 dark:border-m3-dark-border/30 mt-1">
              <div>
                <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Pasta Destino</label>
                <select
                  value={folder}
                  onChange={(e) => setFolder(e.target.value)}
                  className="w-full px-2 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30 font-bold"
                >
                  {['Adoração', 'Geral', 'Jovens', 'Natal', 'Páscoa', ''].map(f => (
                    <option key={f} value={f}>{f === '' ? 'Raiz (Sem pasta)' : f}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold">Nome do Ficheiro (.chopro)</label>
                <input
                  type="text"
                  value={fileName}
                  onChange={(e) => setFileName(e.target.value)}
                  placeholder="Ex: digno_es_tu.chopro"
                  className="w-full px-3 py-1.5 text-xs bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary/30"
                />
              </div>
            </div>
          )}
        </div>

        {/* SECTION 2: SYNTAX DIRECTIVES TOOLBAR */}
        <div className="space-y-1">
          <span className="text-[10px] font-bold text-m3-secondary dark:text-m3-dark-secondary">Inserir Diretivas ChordPro Rápidas:</span>
          
          <div className="flex flex-wrap gap-1 bg-m3-sidebar dark:bg-m3-dark-sidebar p-2 rounded-xl border border-m3-border dark:border-m3-dark-border">
            {/* ChordPro directive tags */}
            <button
              onClick={() => insertTextAtCursor('\n{start_of_chorus: Refrão}\n\n{end_of_chorus}\n')}
              className="px-2 py-1 bg-m3-card dark:bg-m3-dark-card hover:bg-m3-primary-light dark:hover:bg-m3-dark-primary-light border border-m3-border/30 dark:border-m3-dark-border/30 text-[10px] rounded font-mono text-m3-primary dark:text-m3-dark-text font-bold"
              title="Estrutura de Refrão"
            >
              + Refrão
            </button>
            <button
              onClick={() => insertTextAtCursor('{comment: }')}
              className="px-2 py-1 bg-m3-card dark:bg-m3-dark-card hover:bg-m3-primary-light dark:hover:bg-m3-dark-primary-light border border-m3-border/30 dark:border-m3-dark-border/30 text-[10px] rounded font-mono text-m3-secondary dark:text-m3-dark-secondary"
              title="Inserir Comentário"
            >
              + Comentário
            </button>
            <button
              onClick={() => insertTextAtCursor('{repeat}')}
              className="px-2 py-1 bg-m3-card dark:bg-m3-dark-card hover:bg-m3-primary-light dark:hover:bg-m3-dark-primary-light border border-m3-border/30 dark:border-m3-dark-border/30 text-[10px] rounded font-mono text-m3-secondary dark:text-m3-dark-secondary"
              title="Repetir parágrafo"
            >
              + Repetir
            </button>

            {/* Quick Chords inserter */}
            <div className="w-[1px] h-4 bg-m3-border/30 dark:bg-m3-dark-border/30 mx-1 self-center" />
            
            {getQuickChordsForKey(key).map(c => (
              <button
                key={c}
                onClick={() => insertTextAtCursor(`[${c}]`)}
                className="px-2 py-1 bg-m3-primary-light dark:bg-m3-dark-primary-light hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-[10px] font-mono font-black rounded text-m3-primary dark:text-m3-dark-text border border-m3-border/30 transition-all"
              >
                [{c}]
              </button>
            ))}
          </div>
        </div>

        {/* SECTION 3: LYRICS & CHORDS TEXT AREA */}
        <div className="flex flex-col flex-1 min-h-[300px]">
          <label className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-bold mb-1">
            Letra e Acordes Inline (Ex: Este é um [C]cântico [G]novo.)
          </label>
          <div className="relative flex-1 bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-2xl overflow-hidden focus-within:ring-2 focus-within:ring-m3-primary/20 transition-all text-sm font-mono leading-relaxed">
            
            {/* Syntax Highlight Overlay */}
            <div 
              className="absolute inset-0 p-4 pointer-events-none whitespace-pre-wrap break-words text-m3-text dark:text-m3-dark-text overflow-hidden"
              aria-hidden="true"
              dangerouslySetInnerHTML={{ 
                __html: bodyText
                  .replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/(\[.*?\])/g, '<span class="text-m3-primary dark:text-m3-dark-primary font-bold bg-m3-primary-light/10 dark:bg-m3-dark-primary-light/10 rounded px-0.5">$1</span>')
                  .replace(/(\{(.*?)\})/g, '<span class="text-m3-secondary dark:text-m3-dark-secondary italic opacity-80">$1</span>') 
              }}
            />
            
            {/* Real Textarea */}
            <textarea
              ref={textareaRef}
              value={bodyText}
              onChange={(e) => setBodyText(e.target.value)}
              onScroll={(e) => {
                const overlay = e.currentTarget.previousElementSibling as HTMLDivElement;
                if (overlay) {
                  overlay.scrollTop = e.currentTarget.scrollTop;
                  overlay.scrollLeft = e.currentTarget.scrollLeft;
                }
              }}
              className="absolute inset-0 w-full h-full p-4 bg-transparent text-transparent caret-m3-text dark:caret-m3-dark-text resize-none focus:outline-none overflow-auto z-10"
              placeholder="[G]Graças te damos [D]pelo Teu amor..."
              spellCheck={false}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
