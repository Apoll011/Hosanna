import { useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Music, Heart, Clock, CircleDot, Timer, Settings, Folder, X } from 'lucide-react';
import { useAppStore } from '../store/appStore';

export default function NavigationDrawer({ show, onClose }: { show: boolean; onClose: () => void }) {
  const songs = useAppStore(state => state.songs);
  const favoriteSongIds = useAppStore(state => state.favoriteSongIds);
  const recentlyPlayedSongIds = useAppStore(state => state.recentlyPlayedSongIds);
  const activeListContext = useAppStore(state => state.activeListContext);
  const setActiveListContext = useAppStore(state => state.setActiveListContext);

  const uniqueFolders = useMemo(() => {
    const folders = songs.map(s => s.folder).filter(Boolean);
    return Array.from(new Set(folders)).sort();
  }, [songs]);

  const selectedSection = activeListContext.type;
  const selectedFolder = activeListContext.folderName;

  const navigateTo = (type: string, folderName?: string) => {
    setActiveListContext({ type: type as any, folderName });
    onClose();
  };

  return (
    <AnimatePresence>
      {show && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.4 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-black z-40 cursor-pointer"
          />
          {/* Drawer container */}
          <motion.div
            initial={{ x: '-100%' }}
            animate={{ x: 0 }}
            exit={{ x: '-100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 220 }}
            className="absolute left-0 top-0 bottom-0 w-72 bg-m3-card dark:bg-m3-dark-card border-r border-m3-border dark:border-m3-dark-border shadow-2xl z-50 flex flex-col overflow-hidden"
          >
            {/* Drawer Header */}
            <div className="p-6 border-b border-m3-border/30 dark:border-m3-dark-border/30 bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-between">
              <div className="flex items-center gap-3">
                <img src="/logo.png" className="w-10 h-10 rounded-xl border border-m3-border/20 shadow-xs object-cover" alt="Hosanna" referrerPolicy="no-referrer" />
                <div>
                  <h2 className="text-base font-black text-m3-primary dark:text-m3-dark-primary tracking-tight leading-none">Hosanna</h2>
                  <p className="text-[9px] text-m3-secondary dark:text-m3-dark-secondary font-medium mt-1">Menu</p>
                </div>
              </div>
              <button
                onClick={onClose}
                className="p-1.5 rounded-full hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Drawer Content */}
            <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1.5 no-scrollbar">
              <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Biblioteca</div>
              
              {/* All Songs Button */}
              <button
                onClick={() => navigateTo('all')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                  selectedSection === 'all'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <Music className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                <span>Todos os Cânticos</span>
                <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{songs.length}</span>
              </button>

              {/* Favorites Button */}
              <button
                onClick={() => navigateTo('favorites')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                  selectedSection === 'favorites'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <Heart className="w-4 h-4 text-red-500 fill-current" />
                <span>Favoritos</span>
                <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{favoriteSongIds.length}</span>
              </button>

              {/* Recently Played Button */}
              <button
                onClick={() => navigateTo('recent')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                  selectedSection === 'recent'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <Clock className="w-4 h-4 text-amber-500" />
                <span>Recentes (Histórico)</span>
                <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-2 py-0.5 rounded-lg border border-m3-border/20">{recentlyPlayedSongIds.length}</span>
              </button>

              <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-4" />

              <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Ferramentas</div>

              <button
                onClick={() => navigateTo('circle')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all ${
                  selectedSection === 'circle'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <CircleDot className="w-4 h-4 text-emerald-500" />
                <span>Círculo da Quinta</span>
              </button>

              <button
                onClick={() => navigateTo('metronome')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all mt-1 ${
                  selectedSection === 'metronome'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <Timer className="w-4 h-4 text-blue-500" />
                <span>Metrónomo</span>
              </button>

              <button
                onClick={() => navigateTo('settings')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all mt-1 ${
                  selectedSection === 'settings'
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                    : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                }`}
              >
                <Settings className="w-4 h-4 text-slate-500" />
                <span>Definições (Servidor & Sync)</span>
              </button>

              <div className="h-px bg-m3-border/30 dark:border-m3-dark-border/30 my-4" />

              <div className="text-[9px] font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider px-3 mb-1.5">Pastas & Categorias</div>

              {uniqueFolders.length === 0 ? (
                <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary px-3 italic">Nenhuma pasta encontrada.</p>
              ) : (
                uniqueFolders.map(folder => {
                  const count = songs.filter(s => s.folder === folder).length;
                  const isSelected = selectedSection === 'folder' && selectedFolder === folder;
                  return (
                    <button
                      key={folder}
                      onClick={() => navigateTo('folder', folder)}
                      className={`w-full flex items-center gap-3 px-4 py-2.5 rounded-2xl text-xs font-bold transition-all ${
                        isSelected
                          ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-text border border-m3-border/30'
                          : 'text-m3-text dark:text-m3-dark-text hover:bg-m3-hover dark:hover:bg-m3-dark-hover'
                      }`}
                    >
                      <Folder className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                      <span className="truncate">{folder}</span>
                      <span className="ml-auto text-[10px] bg-m3-sidebar dark:bg-m3-dark-sidebar px-1.5 py-0.5 rounded border border-m3-border/20">{count}</span>
                    </button>
                  );
                })
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
