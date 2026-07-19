/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Settings, Folder, Palette, HelpCircle, HardDrive, Shield, RefreshCcw, BookOpen, Layers } from 'lucide-react';
import { useAppStore } from '../store/appStore';

export default function SettingsView() {
  const serverUrl = useAppStore(state => state.serverUrl);
  const setServerUrl = useAppStore(state => state.setServerUrl);
  const serverToken = useAppStore(state => state.serverToken);
  const setServerToken = useAppStore(state => state.setServerToken);
  
  const theme = useAppStore(state => state.theme);
  const setTheme = useAppStore(state => state.setTheme);

  const fontSize = useAppStore(state => state.fontSize);
  const setFontSize = useAppStore(state => state.setFontSize);

  const keepScreenAwake = useAppStore(state => state.keepScreenAwake);
  const setKeepScreenAwake = useAppStore(state => state.setKeepScreenAwake);

  const slowDownOnRepeat = useAppStore(state => state.slowDownOnRepeat);
  const setSlowDownOnRepeat = useAppStore(state => state.setSlowDownOnRepeat);

  const syncLibrary = useAppStore(state => state.syncLibrary);
  const syncStatus = useAppStore(state => state.syncStatus);
  const lastSyncTime = useAppStore(state => state.lastSyncTime);
  const songs = useAppStore(state => state.songs);

  return (
    <div className="w-full h-full overflow-y-auto bg-m3-bg dark:bg-m3-dark-bg p-4 pb-24 space-y-4">
      
      {/* CONSOLIDATED SYNC & SERVER CONNECTION (API) */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-4">
        <span className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
          <HardDrive className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
          Sincronização com o Servidor (API)
        </span>

        <div className="space-y-3 text-xs">
          <div>
            <label className="text-m3-secondary dark:text-m3-dark-secondary font-bold block mb-1">URL do Servidor Remoto</label>
            <input
              type="text"
              value={serverUrl}
              onChange={(e) => setServerUrl(e.target.value)}
              className="w-full px-3 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl font-mono text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary text-m3-text dark:text-m3-dark-text"
              placeholder="Ex: https://api.cifras.exemplo.com"
            />
          </div>

          <div>
            <label className="text-m3-secondary dark:text-m3-dark-secondary font-bold block mb-1">Token de Segurança (Bearer Token)</label>
            <input
              type="password"
              value={serverToken}
              onChange={(e) => setServerToken(e.target.value)}
              className="w-full px-3 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl font-mono text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary text-m3-text dark:text-m3-dark-text"
              placeholder="Introduza o token para autenticação..."
            />
          </div>

          <div className="pt-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 space-y-3">
            <div className="flex items-center justify-between gap-4">
              <div>
                <span className="font-bold text-m3-text dark:text-m3-dark-text block">Sincronização da Base de Dados</span>
                <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">Faz o intercâmbio de cifras e listas de cultos com o servidor.</span>
              </div>
              <button
                onClick={() => {
                  syncLibrary().catch(() => {});
                }}
                disabled={syncStatus === 'syncing'}
                className="px-5 py-2.5 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-full shadow-xs disabled:opacity-50 transition-all active:scale-95 flex items-center gap-1.5 shrink-0"
              >
                <RefreshCcw className={`w-3.5 h-3.5 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
                Sincronizar
              </button>
            </div>

            <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-3 rounded-xl border border-m3-border/30 text-[10px] space-y-1 text-m3-secondary dark:text-m3-dark-secondary">
              <div>
                <span className="font-bold text-m3-text dark:text-m3-dark-text">Última sincronização:</span>{' '}
                <span className="font-mono">{lastSyncTime ? new Date(lastSyncTime).toLocaleString('pt-PT') : 'Nunca'}</span>
              </div>
              <div>
                <span className="font-bold text-m3-text dark:text-m3-dark-text">Total indexado:</span>{' '}
                <span>{songs.length} cânticos guardados</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* SECTION 2: APPEARANCE OVERRIDES */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-3">
        <span className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
          <Palette className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
          Definições de Aparência
        </span>

        <div className="space-y-4 text-xs">
          {/* Theme selector */}
          <div className="flex items-center justify-between gap-4">
            <div>
              <span className="font-bold text-m3-text dark:text-m3-dark-text block">Tema Visual</span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">Suporta modos Claro, Escuro e Sistema.</span>
            </div>
            <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl p-1 border border-m3-border dark:border-m3-dark-border">
              {(['light', 'dark', 'system'] as const).map(t => (
                <button
                  key={t}
                  onClick={() => setTheme(t)}
                  className={`px-3 py-1.5 text-xs font-black rounded-lg transition-all capitalize ${
                    theme === t
                      ? 'bg-m3-primary text-white shadow-xs'
                      : 'text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text'
                  }`}
                >
                  {t === 'light' ? 'Claro' : t === 'dark' ? 'Escuro' : 'Sistema'}
                </button>
              ))}
            </div>
          </div>

          {/* Base Font selector */}
          <div className="flex items-center justify-between gap-4 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
            <div>
              <span className="font-bold text-m3-text dark:text-m3-dark-text block">Tamanho de Letra Base</span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">Ajusta o tamanho padrão das letras de cânticos.</span>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setFontSize(Math.max(12, fontSize - 1))}
                className="w-8 h-8 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text font-black"
              >
                -
              </button>
              <span className="text-xs font-mono font-black text-m3-text dark:text-m3-dark-text w-10 text-center">
                {fontSize} px
              </span>
              <button
                onClick={() => setFontSize(Math.min(24, fontSize + 1))}
                className="w-8 h-8 rounded-lg bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-text dark:text-m3-dark-text font-black"
              >
                +
              </button>
            </div>
          </div>

          {/* Keep Awake selector */}
          <div className="flex items-center justify-between gap-4 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
            <div>
              <span className="font-bold text-m3-text dark:text-m3-dark-text block">Ecrã Sempre Ativo</span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">Mantém o ecrã ligado enquanto lê os cânticos.</span>
            </div>
            <button
              onClick={() => setKeepScreenAwake(!keepScreenAwake)}
              className={`w-10 h-6 rounded-full p-0.5 transition-colors relative flex items-center shrink-0 ${
                keepScreenAwake ? 'bg-m3-primary' : 'bg-neutral-200 dark:bg-zinc-800'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white shadow-sm transition-transform transform ${
                  keepScreenAwake ? 'translate-x-4' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Slow Down on Repeat selector */}
          <div className="flex items-center justify-between gap-4 border-t border-m3-border/30 dark:border-m3-dark-border/30 pt-3">
            <div>
              <span className="font-bold text-m3-text dark:text-m3-dark-text block">Abrandar nas Repetições</span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">O auto-scroll fica mais lento quando passa por refrões ou partes repetidas.</span>
            </div>
            <button
              onClick={() => setSlowDownOnRepeat(!slowDownOnRepeat)}
              className={`w-10 h-6 rounded-full p-0.5 transition-colors relative flex items-center shrink-0 ${
                slowDownOnRepeat ? 'bg-m3-primary' : 'bg-neutral-200 dark:bg-zinc-800'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white shadow-sm transition-transform transform ${
                  slowDownOnRepeat ? 'translate-x-4' : 'translate-x-0'
                }`}
              />
            </button>
          </div>
        </div>
      </div>

      {/* FOOTER NOTE */}
      <div className="text-center py-6 text-[10px] text-m3-secondary/60 dark:text-m3-dark-secondary/50 font-medium tracking-wide border-t border-m3-border/20 pt-6">
        by Tiago Inês @ Embrace for IBAV
      </div>

    </div>
  );
}
