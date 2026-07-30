import { Camera } from "@capacitor/camera";
import { IDetectedBarcode, Scanner } from "@yudiel/react-qr-scanner";
import {
    HardDrive,
    Keyboard,
    KeyRound,
    Link2,
    QrCode,
    RefreshCcw,
    ScanLine,
} from "lucide-react";
import React, { useEffect, useMemo, useState } from "react";
import {
    extractMusicianToken,
    extractMusicianURL,
    isMusicianAccessUrl,
} from "../lib/apiClient";
import { useAppStore } from "../store/appStore";

export default function SettingsView() {
    const serverUrl = useAppStore((state) => state.serverUrl);
    const setServerUrl = useAppStore((state) => state.setServerUrl);
    const serverToken = useAppStore((state) => state.serverToken);
    const setServerToken = useAppStore((state) => state.setServerToken);

    const [tokenInput, setTokenInput] = useState(serverToken);
    const [inputMethod, setInputMethod] = useState<"manual" | "qr">("manual");
    const [hasCameraPermission, setHasCameraPermission] = useState<
        boolean | null
    >(null);

    useEffect(() => {
        setTokenInput(serverToken);
    }, [serverToken]);

    // Request/Check permission when switching to QR mode
    useEffect(() => {
        if (inputMethod === "qr") {
            checkCameraPermission();
        }
    }, [inputMethod]);

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
            // Fallback for standard browsers
            setHasCameraPermission(true);
        }
    };

    const tokenPreview = useMemo(() => {
        const token = extractMusicianToken(tokenInput);
        if (!token) return "Nenhum token configurado";
        return token.length > 12
            ? `${token.slice(0, 8)}…${token.slice(-4)}`
            : token;
    }, [tokenInput]);

    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const syncStatus = useAppStore((state) => state.syncStatus);
    const lastSyncTime = useAppStore((state) => state.lastSyncTime);
    const songs = useAppStore((state) => state.songs);

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
                setTokenInput(extractedToken);
            }

            if (extractedUrl || extractedToken) {
                setInputMethod("manual");
            }
        }
    };

    return (
        <div className="w-full h-full overflow-y-auto bg-m3-bg dark:bg-m3-dark-bg p-4 pb-24 space-y-4">
            {/* CONSOLIDATED SYNC & SERVER CONNECTION */}
            <div className="bg-m3-card dark:bg-m3-dark-card p-4 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 space-y-4">
                {/* HEADER WITH TABS */}
                <div className="flex items-center justify-between">
                    <span className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1.5">
                        <HardDrive className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                        Acesso de Músico
                    </span>
                    <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-lg p-0.5 border border-m3-border dark:border-m3-dark-border">
                        <button
                            onClick={() => setInputMethod("manual")}
                            className={`px-3 py-1 text-[10px] font-black rounded-md transition-all flex items-center gap-1.5 ${
                                inputMethod === "manual"
                                    ? "bg-m3-primary text-white shadow-xs"
                                    : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text"
                            }`}
                        >
                            <Keyboard className="w-3 h-3" />
                            Manual
                        </button>
                        <button
                            onClick={() => setInputMethod("qr")}
                            className={`px-3 py-1 text-[10px] font-black rounded-md transition-all flex items-center gap-1.5 ${
                                inputMethod === "qr"
                                    ? "bg-m3-primary text-white shadow-xs"
                                    : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text"
                            }`}
                        >
                            <ScanLine className="w-3 h-3" />
                            QR Code
                        </button>
                    </div>
                </div>

                <div className="space-y-4 text-xs">
                    {/* TAB: MANUAL */}
                    {inputMethod === "manual" && (
                        <div className="space-y-3">
                            <div>
                                <label className="text-m3-secondary dark:text-m3-dark-secondary font-bold block mb-1">
                                    URL do Servidor Remoto
                                </label>
                                <input
                                    type="text"
                                    value={serverUrl}
                                    onChange={(
                                        e: React.ChangeEvent<HTMLInputElement>,
                                    ) => setServerUrl(e.target.value)}
                                    className="w-full px-3 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl font-mono text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary text-m3-text dark:text-m3-dark-text"
                                    placeholder="Ex: https://api.cifras.exemplo.com"
                                />
                            </div>

                            <div>
                                <label className="text-m3-secondary dark:text-m3-dark-secondary font-bold block mb-1">
                                    Token do músico ou link do QR
                                </label>
                                <div className="space-y-2">
                                    <input
                                        type="text"
                                        value={tokenInput}
                                        onChange={(
                                            e: React.ChangeEvent<HTMLInputElement>,
                                        ) => setTokenInput(e.target.value)}
                                        className="w-full px-3 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border dark:border-m3-dark-border rounded-xl font-mono text-xs focus:outline-none focus:ring-1 focus:ring-m3-primary text-m3-text dark:text-m3-dark-text"
                                        placeholder="Cole o mus_... ou o URL do acesso"
                                        autoComplete="off"
                                        spellCheck={false}
                                    />
                                    <div className="flex flex-wrap items-center gap-2">
                                        <button
                                            onClick={() =>
                                                setServerToken(
                                                    extractMusicianToken(
                                                        tokenInput,
                                                    ),
                                                )
                                            }
                                            className="px-4 py-2 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-full shadow-xs transition-all active:scale-95 flex items-center gap-1.5"
                                        >
                                            <KeyRound className="w-3.5 h-3.5" />
                                            Guardar token
                                        </button>
                                        <button
                                            onClick={() => {
                                                setTokenInput("");
                                                setServerToken("");
                                            }}
                                            className="px-4 py-2 bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary text-xs font-black rounded-full border border-m3-border/30 dark:border-m3-dark-border/30 transition-all active:scale-95"
                                        >
                                            Limpar
                                        </button>
                                    </div>
                                    <div className="flex items-start gap-2 text-[10px] text-m3-secondary dark:text-m3-dark-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30 dark:border-m3-dark-border/30 p-3">
                                        {isMusicianAccessUrl(tokenInput) ? (
                                            <Link2 className="w-3.5 h-3.5 mt-0.5 shrink-0 text-m3-primary dark:text-m3-dark-primary" />
                                        ) : (
                                            <QrCode className="w-3.5 h-3.5 mt-0.5 shrink-0 text-m3-primary dark:text-m3-dark-primary" />
                                        )}
                                        <span>
                                            Cole o token bruto ou o URL gerado
                                            pelo QR. O app extrai
                                            automaticamente o valor do parâmetro{" "}
                                            <span className="font-mono font-bold">
                                                token
                                            </span>{" "}
                                            quando houver.
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* TAB: QR CODE */}
                    {inputMethod === "qr" && (
                        <div className="space-y-3">
                            <label className="text-m3-secondary dark:text-m3-dark-secondary font-bold block mb-1">
                                Ler QR Code
                            </label>

                            <div className="rounded-xl overflow-hidden border border-m3-border dark:border-m3-dark-border relative aspect-square max-w-[300px] mx-auto bg-black flex flex-col items-center justify-center text-white p-4">
                                {hasCameraPermission === false && (
                                    <div className="text-center space-y-2">
                                        <p className="text-xs text-red-400 font-bold">
                                            Permissão de câmara negada.
                                        </p>
                                        <button
                                            onClick={checkCameraPermission}
                                            className="px-3 py-1.5 bg-m3-primary text-white text-xs font-bold rounded-full"
                                        >
                                            Pedir Permissão
                                        </button>
                                    </div>
                                )}

                                {hasCameraPermission === true && (
                                    <Scanner
                                        onScan={handleQrScan}
                                        onError={(error) =>
                                            console.error(
                                                "Erro na câmara:",
                                                error,
                                            )
                                        }
                                        styles={{
                                            container: {
                                                width: "100%",
                                                height: "100%",
                                            },
                                        }}
                                    />
                                )}
                            </div>

                            <div className="flex items-start gap-2 text-[10px] text-m3-secondary dark:text-m3-dark-secondary bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30 dark:border-m3-dark-border/30 p-3">
                                <QrCode className="w-3.5 h-3.5 mt-0.5 shrink-0 text-m3-primary dark:text-m3-dark-primary" />
                                <span>
                                    Aponte a câmara para o QR Code. O URL e o
                                    Token serão extraídos e guardados
                                    automaticamente.
                                </span>
                            </div>
                        </div>
                    )}

                    <div className="pt-3 border-t border-m3-border/30 dark:border-m3-dark-border/30 space-y-3">
                        <div className="flex items-center justify-between gap-4">
                            <div>
                                <span className="font-bold text-m3-text dark:text-m3-dark-text block">
                                    Sincronização da Base de Dados
                                </span>
                                <span className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary block">
                                    Usa o token do músico para ler os dados
                                    permitidos pelo servidor.
                                </span>
                            </div>
                            <button
                                onClick={() => {
                                    syncLibrary();
                                }}
                                disabled={syncStatus === "syncing"}
                                className="px-5 py-2.5 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-full shadow-xs disabled:opacity-50 transition-all active:scale-95 flex items-center gap-1.5 shrink-0"
                            >
                                <RefreshCcw
                                    className={`w-3.5 h-3.5 ${syncStatus === "syncing" ? "animate-spin" : ""}`}
                                />
                                Sincronizar
                            </button>
                        </div>

                        <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-3 rounded-xl border border-m3-border/30 text-[10px] space-y-1 text-m3-secondary dark:text-m3-dark-secondary">
                            <div>
                                <span className="font-bold text-m3-text dark:text-m3-dark-text">
                                    Última sincronização:
                                </span>{" "}
                                <span className="font-mono">
                                    {lastSyncTime
                                        ? new Date(lastSyncTime).toLocaleString(
                                              "pt-PT",
                                          )
                                        : "Nunca"}
                                </span>
                            </div>
                            <div>
                                <span className="font-bold text-m3-text dark:text-m3-dark-text">
                                    Token ativo:
                                </span>{" "}
                                <span className="font-mono break-all">
                                    {tokenPreview}
                                </span>
                            </div>
                            <div>
                                <span className="font-bold text-m3-text dark:text-m3-dark-text">
                                    Total indexado:
                                </span>{" "}
                                <span>{songs.length} cânticos guardados</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* APPEARANCE & FOOTER REST OF CODE REMAINS THE SAME */}
        </div>
    );
}
