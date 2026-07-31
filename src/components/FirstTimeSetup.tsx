import { Camera } from "@capacitor/camera";
import { IDetectedBarcode, Scanner } from "@yudiel/react-qr-scanner";
import { Camera as CameraIcon } from "lucide-react";
import { useEffect, useState } from "react";
import { useAppStore } from "../store/appStore";
import { extractMusicianToken, extractMusicianURL } from "../utils";

export default function FirstTimeSetup() {
    const setServerUrl = useAppStore((state) => state.setServerUrl);
    const setServerToken = useAppStore((state) => state.setServerToken);
    const setHasSkippedSetup = useAppStore((state) => state.setHasSkippedSetup);

    const [hasCameraPermission, setHasCameraPermission] = useState<
        boolean | null
    >(null);

    useEffect(() => {
        checkCameraPermission();
    }, []);

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
            console.warn(
                "Capacitor camera check failed (likely running on pure web browser):",
                err,
            );
            setHasCameraPermission(true);
        }
    };

    const handleQrScan = (result: IDetectedBarcode[]) => {
        if (!result) return;

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
                setHasSkippedSetup(true); // Close the setup screen
            }
        }
    };

    return (
        <div className="fixed inset-0 bg-m3-bg dark:bg-m3-dark-bg z-50 flex flex-col items-center justify-center p-6 text-center select-none overflow-y-auto">
            <div className="w-full max-w-sm space-y-6 animate-scale-up">
                <div className="flex justify-center mb-6">
                    <img
                        src="/logo.png"
                        className="w-24 h-24 rounded-3xl shadow-xl border border-m3-border/20"
                        alt="Hosanna"
                    />
                </div>

                <h1 className="text-2xl font-black text-m3-text dark:text-m3-dark-text tracking-tight">
                    Bem-vindo ao Hosanna
                </h1>
                <p className="text-sm text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                    Para sincronizar os cânticos e planos do seu grupo de
                    louvor, escaneie o código QR de acesso fornecido pelo líder.
                </p>

                <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-3xl overflow-hidden shadow-2xl mx-auto w-full max-w-70 aspect-square relative flex items-center justify-center">
                    {hasCameraPermission === false ? (
                        <div className="p-6 text-center space-y-3">
                            <CameraIcon className="w-8 h-8 text-red-500 mx-auto" />
                            <p className="text-xs font-bold text-m3-text dark:text-m3-dark-text">
                                Câmera Bloqueada
                            </p>
                            <p className="text-[10px] text-m3-secondary">
                                Permita o acesso à câmera para escanear o código
                                QR.
                            </p>
                        </div>
                    ) : (
                        <Scanner onScan={handleQrScan} />
                    )}
                </div>

                <button
                    onClick={() => setHasSkippedSetup(true)}
                    className="mt-8 px-6 py-3 text-sm font-black text-m3-secondary hover:text-m3-text transition-colors w-full"
                >
                    Ignorar por agora
                </button>
            </div>
        </div>
    );
}
