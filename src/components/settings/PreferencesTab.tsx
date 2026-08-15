import {
  Columns2,
  Guitar,
  Moon,
  Music,
  Piano,
  RotateCcw,
  Sun,
  SunMoon,
  Type,
  Volume2,
  Zap,
} from "lucide-react";
import React, { useState } from "react";
import { useAppStore } from "../../store/appStore";

interface PreferencesTabProps {
  active: boolean;
  onShowToast?: (message: string, type: "success" | "error" | "info") => void;
}

export const PreferencesTab: React.FC<PreferencesTabProps> = ({
  active,
  onShowToast,
}) => {
  const theme = useAppStore((state) => state.theme);
  const setTheme = useAppStore((state) => state.setTheme);

  const musicianMode = useAppStore((state) => state.musicianMode);
  const setMusicianMode = useAppStore((state) => state.setMusicianMode);

  const fontSize = useAppStore((state) => state.fontSize);
  const setFontSize = useAppStore((state) => state.setFontSize);

  const showChords = useAppStore((state) => state.showChords);
  const setShowChords = useAppStore((state) => state.setShowChords);

  const showDiagrams = useAppStore((state) => state.showDiagrams);
  const setShowDiagrams = useAppStore((state) => state.setShowDiagrams);

  const instrument = useAppStore((state) => state.instrument);
  const setInstrument = useAppStore((state) => state.setInstrument);

  const keepScreenAwake = useAppStore((state) => state.keepScreenAwake);
  const setKeepScreenAwake = useAppStore((state) => state.setKeepScreenAwake);

  const twoColumnLayout = useAppStore((state) => state.twoColumnLayout);
  const setTwoColumnLayout = useAppStore((state) => state.setTwoColumnLayout);

  const slowDownOnRepeat = useAppStore((state) => state.slowDownOnRepeat);
  const setSlowDownOnRepeat = useAppStore((state) => state.setSlowDownOnRepeat);

  const resetApp = useAppStore((state) => state.resetApp);
  const [showResetConfirm, setShowResetConfirm] = useState(false);

  if (!active) return null;

  const handleResetCache = () => {
    resetApp();
    setShowResetConfirm(false);
    onShowToast?.("Cache e dados locais foram limpos.", "info");
  };

  return (
    <div className="space-y-4">
      {/* Musician Mode */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-m3-primary-light dark:bg-m3-dark-primary-light flex items-center justify-center shrink-0">
              <Music className="w-5 h-5 text-m3-primary dark:text-m3-dark-primary" />
            </div>
            <div className="min-w-0">
              <span className="font-bold text-xs sm:text-sm text-m3-text dark:text-m3-dark-text block truncate">
                Modo Músico nos Cultos
              </span>
              <span className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary block leading-snug">
                Abre o culto diretamente no primeiro cântico com navegação lateral contínua.
              </span>
            </div>
          </div>
          <button
            onClick={() => setMusicianMode(!musicianMode)}
            className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
              musicianMode
                ? "bg-m3-primary dark:bg-m3-dark-primary"
                : "bg-m3-border dark:bg-m3-dark-border"
            }`}
          >
            <div
              className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                musicianMode ? "translate-x-5" : "translate-x-0"
              }`}
            />
          </button>
        </div>
      </div>

      {/* Theme Selector */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-3">
        <div>
          <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider block mb-1">
            Tema da Aplicação
          </label>
          <div className="grid grid-cols-3 gap-2">
            <button
              onClick={() => setTheme("light")}
              className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all ${
                theme === "light"
                  ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border-m3-primary text-m3-primary dark:text-m3-dark-primary font-bold"
                  : "bg-m3-sidebar dark:bg-m3-dark-sidebar border-m3-border/30 text-m3-secondary hover:text-m3-text"
              }`}
            >
              <Sun className="w-5 h-5" />
              <span className="text-xs">Claro</span>
            </button>
            <button
              onClick={() => setTheme("dark")}
              className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all ${
                theme === "dark"
                  ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border-m3-primary text-m3-primary dark:text-m3-dark-primary font-bold"
                  : "bg-m3-sidebar dark:bg-m3-dark-sidebar border-m3-border/30 text-m3-secondary hover:text-m3-text"
              }`}
            >
              <Moon className="w-5 h-5" />
              <span className="text-xs">Escuro</span>
            </button>
            <button
              onClick={() => setTheme("system")}
              className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all ${
                theme === "system"
                  ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border-m3-primary text-m3-primary dark:text-m3-dark-primary font-bold"
                  : "bg-m3-sidebar dark:bg-m3-dark-sidebar border-m3-border/30 text-m3-secondary hover:text-m3-text"
              }`}
            >
              <SunMoon className="w-5 h-5" />
              <span className="text-xs">Sistema</span>
            </button>
          </div>
        </div>
      </div>

      {/* Font Size & Display */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-4">
        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
              <Type className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
              Tamanho do Texto ({fontSize}px)
            </span>
            <span
              style={{ fontSize: `${fontSize}px` }}
              className="font-bold text-m3-text dark:text-m3-dark-text"
            >
              Exemplo
            </span>
          </div>
          <input
            type="range"
            min={12}
            max={28}
            step={1}
            value={fontSize}
            onChange={(e) => setFontSize(Number(e.target.value))}
            className="w-full accent-m3-primary cursor-pointer"
          />
        </div>

        <div className="pt-2 border-t border-m3-border/30 space-y-3">
          {/* Show Chords */}
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
              Mostrar Acordes
            </span>
            <button
              onClick={() => setShowChords(!showChords)}
              className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
                showChords
                  ? "bg-m3-primary dark:bg-m3-dark-primary"
                  : "bg-m3-border dark:bg-m3-dark-border"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                  showChords ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Show Diagrams */}
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
              Mostrar Diagramas de Acordes
            </span>
            <button
              onClick={() => setShowDiagrams(!showDiagrams)}
              className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
                showDiagrams
                  ? "bg-m3-primary dark:bg-m3-dark-primary"
                  : "bg-m3-border dark:bg-m3-dark-border"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                  showDiagrams ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Instrument */}
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
              Instrumento para Diagramas
            </span>
            <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-0.5 rounded-lg border border-m3-border/30">
              <button
                onClick={() => setInstrument("guitar")}
                className={`px-2.5 py-1 text-xs font-bold rounded-md flex items-center gap-1 transition-all ${
                  instrument === "guitar"
                    ? "bg-m3-primary text-white"
                    : "text-m3-secondary hover:text-m3-text"
                }`}
              >
                <Guitar className="w-3.5 h-3.5" />
                Guitarra
              </button>
              <button
                onClick={() => setInstrument("piano")}
                className={`px-2.5 py-1 text-xs font-bold rounded-md flex items-center gap-1 transition-all ${
                  instrument === "piano"
                    ? "bg-m3-primary text-white"
                    : "text-m3-secondary hover:text-m3-text"
                }`}
              >
                <Piano className="w-3.5 h-3.5" />
                Piano
              </button>
            </div>
          </div>

          {/* Keep screen awake */}
          <div className="flex items-center justify-between">
            <div className="min-w-0">
              <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text block flex items-center gap-1">
                <Zap className="w-3.5 h-3.5 text-amber-500" />
                Manter Ecrã Ligado
              </span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">
                Impede o ecrã de suspender durante a visualização de cânticos
              </span>
            </div>
            <button
              onClick={() => setKeepScreenAwake(!keepScreenAwake)}
              className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
                keepScreenAwake
                  ? "bg-m3-primary dark:bg-m3-dark-primary"
                  : "bg-m3-border dark:bg-m3-dark-border"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                  keepScreenAwake ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Two Column Layout */}
          <div className="flex items-center justify-between">
            <div className="min-w-0">
              <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text block flex items-center gap-1">
                <Columns2 className="w-3.5 h-3.5 text-m3-primary dark:text-m3-dark-primary" />
                Layout de Duas Colunas
              </span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">
                Divide a letra e acordes em duas colunas em ecrãs largos
              </span>
            </div>
            <button
              onClick={() => setTwoColumnLayout(!twoColumnLayout)}
              className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
                twoColumnLayout
                  ? "bg-m3-primary dark:bg-m3-dark-primary"
                  : "bg-m3-border dark:bg-m3-dark-border"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                  twoColumnLayout ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>

          {/* Slow down on repeat */}
          <div className="flex items-center justify-between">
            <div className="min-w-0">
              <span className="text-xs font-bold text-m3-text dark:text-m3-dark-text block flex items-center gap-1">
                <Volume2 className="w-3.5 h-3.5 text-m3-primary dark:text-m3-dark-primary" />
                Desacelerar Metrónomo na Repetição
              </span>
              <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">
                Suaviza o andamento em repetições de estrofes
              </span>
            </div>
            <button
              onClick={() => setSlowDownOnRepeat(!slowDownOnRepeat)}
              className={`w-11 h-6 rounded-full p-1 transition-colors relative flex items-center shrink-0 ${
                slowDownOnRepeat
                  ? "bg-m3-primary dark:bg-m3-dark-primary"
                  : "bg-m3-border dark:bg-m3-dark-border"
              }`}
            >
              <div
                className={`w-4 h-4 rounded-full bg-white shadow-xs transition-transform transform ${
                  slowDownOnRepeat ? "translate-x-5" : "translate-x-0"
                }`}
              />
            </button>
          </div>
        </div>
      </div>

      {/* Reset Cache Card */}
      <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
              Limpar Cache Local
            </h4>
            <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5">
              Remove cânticos em cache e reabre a aplicação como nova.
            </p>
          </div>
          <button
            onClick={() => setShowResetConfirm(true)}
            className="px-3 py-1.5 text-xs font-bold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 rounded-xl border border-red-200 dark:border-red-900/50 transition-colors"
          >
            Limpar
          </button>
        </div>

        {showResetConfirm && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 rounded-xl space-y-2">
            <p className="text-xs text-red-700 dark:text-red-300 font-bold">
              Tem a certeza de que deseja limpar a cache local?
            </p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowResetConfirm(false)}
                className="px-3 py-1 text-xs font-bold text-m3-secondary hover:text-m3-text rounded-lg"
              >
                Cancelar
              </button>
              <button
                onClick={handleResetCache}
                className="px-3 py-1 text-xs font-black bg-red-600 text-white rounded-lg hover:bg-red-700 flex items-center gap-1"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                Confirmar Limpeza
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
