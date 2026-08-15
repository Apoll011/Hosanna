import { Camera } from "@capacitor/camera";
import { IDetectedBarcode, Scanner } from "@yudiel/react-qr-scanner";
import { Camera as CameraIcon, Lock } from "lucide-react";
import { useEffect, useState } from "react";
import { useAuth } from "../contexts/AuthContext";
import { useAppStore } from "../store/appStore";
import { extractMusicianToken, extractMusicianURL } from "../utils";
import { AuthModal } from "./auth/AuthModal";

export default function FirstTimeSetup() {
    const setServerUrl = useAppStore((state) => state.setServerUrl);
    const setServerToken = useAppStore((state) => state.setServerToken);
    const setHasSkippedSetup = useAppStore((state) => state.setHasSkippedSetup);
    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const { isAuthenticated } = useAuth();

    const [mode, setMode] = useState<"welcome" | "qr">("welcome");
    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
    const [hasCameraPermission, setHasCameraPermission] = useState<
        boolean | null
    >(null);

    useEffect(() => {
        if (isAuthenticated) {
            setHasSkippedSetup(true);
        }
    }, [isAuthenticated, setHasSkippedSetup]);

    const checkCameraPermission = async () => {
        try {
            const status = await Camera.checkPermissions();
            if (status.camera === "granted") {
                setHasCameraPermission(true);
            } else {
                const req = await Camera.requestPermissions();
                setHasCameraPermission(req.camera === "granted");
            }
        } catch (err) {
            console.warn("Capacitor camera check fallback:", err);
            setHasCameraPermission(true);
        }
    };

    const handleStartQr = () => {
        setMode("qr");
        checkCameraPermission();
    };

    const handleQrScan = (result: IDetectedBarcode[]) => {
        if (!result || result.length === 0) return;

        const text = result[0]?.rawValue;

        if (text && typeof text === "string") {
            const extractedUrl = extractMusicianURL(text);
            const extractedToken = extractMusicianToken(text);

            if (extractedUrl) {
                setServerUrl(extractedUrl);
            }
            if (extractedToken) {
                setServerToken(extractedToken);
            }

            if (extractedUrl || extractedToken) {
                setHasSkippedSetup(true);
                syncLibrary().catch(() => {});
            }
        }
    };

    return (
        <div className="fixed inset-0 bg-m3-bg dark:bg-m3-dark-bg z-50 flex flex-col items-center justify-center p-6 text-center select-none overflow-y-auto">
            <div className="w-full max-w-sm space-y-6 animate-scale-up">
                {/* Logo and Header */}
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

                {mode === "welcome" ? (
                    <div className="space-y-3 pt-2">
                        {/* Option 1: Iniciar Sessão com Conta Better Auth */}
                        <button
                            onClick={() => setIsAuthModalOpen(true)}
                            className="w-full py-3.5 px-4 bg-m3-primary hover:opacity-90 text-white font-black text-xs sm:text-sm rounded-2xl shadow-md transition-all active:scale-98 flex items-center justify-center gap-2"
                        >
                            <Lock className="w-4 h-4" />
                            Iniciar Sessão / Criar Conta
                        </button>

                        {/* Option 3: Ignorar / Offline */}
                        <button
                            onClick={() => setHasSkippedSetup(true)}
                            className="pt-2 text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text transition-colors block mx-auto"
                        >
                            Continuar em modo offline por agora
                        </button>
                    </div>
                ) : (
                    <div className="space-y-4">
                        <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-3xl overflow-hidden shadow-2xl mx-auto w-full max-w-70 aspect-square relative flex items-center justify-center">
                            {hasCameraPermission === false ? (
                                <div className="p-6 text-center space-y-3">
                                    <CameraIcon className="w-8 h-8 text-red-500 mx-auto" />
                                    <p className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
                                        Câmara Bloqueada
                                    </p>
                                    <p className="text-[10px] text-m3-secondary">
                                        Permita o acesso à câmara para ler o
                                        código QR.
                                    </p>
                                </div>
                            ) : (
                                <Scanner onScan={handleQrScan} />
                            )}
                        </div>

                        <button
                            onClick={() => setMode("welcome")}
                            className="text-xs font-bold text-m3-secondary hover:text-m3-text"
                        >
                            Voltar
                        </button>
                    </div>
                )}
            </div>

            <AuthModal
                isOpen={isAuthModalOpen}
                onClose={() => setIsAuthModalOpen(false)}
            />
        </div>
    );
}
