import { useEffect, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { useAppStore } from "../store/appStore";
import { AuthModal } from "./auth/AuthModal";

export default function FirstTimeSetup() {
    const setHasSkippedSetup = useAppStore((state) => state.setHasSkippedSetup);
    const { isAuthenticated } = useAuth();

    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);

    useEffect(() => {
        if (isAuthenticated) {
            setHasSkippedSetup(true);
        }
    }, [isAuthenticated, setHasSkippedSetup]);

    return (
        <div className="fixed inset-0 bg-m3-bg dark:bg-m3-dark-bg z-50 flex flex-col items-center justify-center p-6 text-center select-none overflow-y-auto">
            <div className="w-full max-w-sm space-y-6 animate-scale-up">
                <div className="flex justify-center mb-2">
                    <img
                        src="/logo.png"
                        className="w-20 h-20 rounded-3xl shadow-xl border border-m3-border/20 object-cover"
                        alt="Hosanna"
                    />
                </div>

                <div className="space-y-1.5">
                    <h1 className="text-2xl font-black text-m3-text dark:text-m3-dark-text tracking-tight flex items-center justify-center gap-2">
                        Bem-vindo ao Hosanna
                    </h1>
                    <p className="text-xs sm:text-sm text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                        A sua biblioteca e planos de louvor sempre sincronizados
                        no telemóvel.
                    </p>
                </div>

                <div className="space-y-3 pt-2">
                    <button
                        onClick={() => setIsAuthModalOpen(true)}
                        className="w-full py-3.5 px-4 bg-m3-primary hover:opacity-90 text-white font-black text-xs sm:text-sm rounded-2xl shadow-md transition-all active:scale-98 flex items-center justify-center gap-2"
                    >
                        Iniciar Sessão / Criar Conta
                    </button>

                    <button
                        onClick={() => setHasSkippedSetup(true)}
                        className="pt-2 text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text transition-colors block mx-auto"
                    >
                        Continuar em modo offline por agora
                    </button>
                </div>
            </div>

            <AuthModal
                isOpen={isAuthModalOpen}
                onClose={() => setIsAuthModalOpen(false)}
            />
        </div>
    );
}
