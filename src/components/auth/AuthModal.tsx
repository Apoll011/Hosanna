import { Button, Input, Modal } from "@hosanna/shared";
import {
    AlertTriangle,
    CheckCircle2,
    Lock,
    Server,
    Shield,
    UserPlus,
} from "lucide-react";
import React, { useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { authClient, reconfigureAuthClient } from "../../lib/authClient";
import { useAppStore } from "../../store/appStore";

interface AuthModalProps {
    isOpen: boolean;
    onClose: () => void;
    initialTab?: "signin" | "signup";
}

export const AuthModal: React.FC<AuthModalProps> = ({
    isOpen,
    onClose,
    initialTab = "signin",
}) => {
    const { refetch: refetchAuth } = useAuth();
    const serverUrl = useAppStore((state) => state.serverUrl);
    const setServerUrl = useAppStore((state) => state.setServerUrl);
    const syncLibrary = useAppStore((state) => state.syncLibrary);

    const [tab, setTab] = useState<"signin" | "signup">(initialTab);
    const [showServerConfig, setShowServerConfig] = useState(false);
    const [customServerUrl, setCustomServerUrl] = useState(serverUrl);

    // Form states
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [name, setName] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");

    // 2FA state
    const [is2FAChallenge, setIs2FAChallenge] = useState(false);
    const [totpCode, setTotpCode] = useState("");

    // Loading & error
    const [isLoading, setIsLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const [successMsg, setSuccessMsg] = useState("");

    const resetForm = () => {
        setEmail("");
        setPassword("");
        setName("");
        setConfirmPassword("");
        setIs2FAChallenge(false);
        setTotpCode("");
        setErrorMsg("");
        setSuccessMsg("");
        setShowServerConfig(false);
    };

    const handleClose = () => {
        resetForm();
        onClose();
    };

    const handleSaveServerUrl = () => {
        const clean = customServerUrl.trim().replace(/\/api\/?$/, "");
        setServerUrl(clean);
        reconfigureAuthClient(clean);
        setShowServerConfig(false);
        setErrorMsg("");
        setSuccessMsg("Endereço do servidor atualizado!");
        setTimeout(() => setSuccessMsg(""), 3000);
    };

    const handleSignIn = async (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        if (!email.trim() || !password) {
            setErrorMsg("Por favor preencha o e-mail e a palavra-passe.");
            return;
        }

        setErrorMsg("");
        setIsLoading(true);

        try {
            const res = await authClient.signIn.email({
                email: email.trim(),
                password,
            });

            if (res.error) {
                // Check if two-factor is required
                if (
                    res.error.status === 403 &&
                    (res.error.message?.includes("two") ||
                        (res.error as Record<string, unknown>).code ===
                            "TWO_FACTOR_REQUIRED")
                ) {
                    setIs2FAChallenge(true);
                    setErrorMsg("");
                } else {
                    setErrorMsg(
                        res.error.message ||
                            "Erro ao iniciar sessão. Verifique as credenciais.",
                    );
                }
            } else {
                // Success
                setSuccessMsg("Sessão iniciada com sucesso!");
                await refetchAuth();
                syncLibrary().catch(() => {});
                setTimeout(() => {
                    handleClose();
                }, 600);
            }
        } catch (err: unknown) {
            setErrorMsg(
                (err as Error).message || "Falha na ligação com o servidor.",
            );
        } finally {
            setIsLoading(false);
        }
    };

    const handleVerify2FA = async (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        if (!totpCode || totpCode.length < 6) {
            setErrorMsg("Por favor introduza o código de 6 dígitos.");
            return;
        }

        setErrorMsg("");
        setIsLoading(true);

        try {
            const res = await authClient.twoFactor.verifyTotp({
                code: totpCode,
                trustDevice: true,
            });

            if (res.error) {
                setErrorMsg(
                    res.error.message || "Código de verificação inválido.",
                );
            } else {
                setSuccessMsg("Verificado com sucesso!");
                await refetchAuth();
                syncLibrary().catch(() => {});
                setTimeout(() => {
                    handleClose();
                }, 600);
            }
        } catch (err: unknown) {
            setErrorMsg(
                (err as Error).message || "Erro ao verificar código 2FA.",
            );
        } finally {
            setIsLoading(false);
        }
    };

    const handleSignUp = async (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        if (!name.trim()) {
            setErrorMsg("Por favor introduza o seu nome.");
            return;
        }
        if (!email.trim() || !email.includes("@")) {
            setErrorMsg("Por favor introduza um e-mail válido.");
            return;
        }
        if (password.length < 6) {
            setErrorMsg("A palavra-passe deve ter pelo menos 6 caracteres.");
            return;
        }
        if (password !== confirmPassword) {
            setErrorMsg("As palavras-passe não coincidem.");
            return;
        }

        setErrorMsg("");
        setIsLoading(true);

        try {
            const res = await authClient.signUp.email({
                name: name.trim(),
                email: email.trim(),
                password,
            });

            if (res.error) {
                setErrorMsg(res.error.message || "Erro ao criar conta.");
            } else {
                setSuccessMsg("Conta criada com sucesso! A iniciar sessão...");
                await refetchAuth();
                syncLibrary().catch(() => {});
                setTimeout(() => {
                    handleClose();
                }, 800);
            }
        } catch (err: unknown) {
            setErrorMsg((err as Error).message || "Falha ao criar conta.");
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Modal
            isOpen={isOpen}
            onClose={handleClose}
            title={
                is2FAChallenge
                    ? "Autenticação em Duas Etapas"
                    : tab === "signin"
                      ? "Iniciar Sessão"
                      : "Criar Conta no Hosanna"
            }
        >
            <div className="space-y-4 py-2">
                {/* Error / Success Feedback */}
                {errorMsg && (
                    <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 rounded-xl text-xs text-red-600 dark:text-red-400 flex items-center gap-2 animate-in fade-in duration-200">
                        <AlertTriangle className="w-4 h-4 shrink-0" />
                        <span>{errorMsg}</span>
                    </div>
                )}

                {successMsg && (
                    <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900/50 rounded-xl text-xs text-emerald-600 dark:text-emerald-400 flex items-center gap-2 animate-in fade-in duration-200">
                        <CheckCircle2 className="w-4 h-4 shrink-0" />
                        <span>{successMsg}</span>
                    </div>
                )}

                {/* 2FA Challenge View */}
                {is2FAChallenge ? (
                    <form onSubmit={handleVerify2FA} className="space-y-4">
                        <div className="text-center space-y-1">
                            <div className="w-12 h-12 rounded-2xl bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-primary flex items-center justify-center mx-auto mb-2">
                                <Shield className="w-6 h-6" />
                            </div>
                            <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary">
                                Esta conta tem a proteção 2FA ativada. Introduza
                                o código de 6 dígitos gerado pelo seu
                                autenticador:
                            </p>
                        </div>

                        <Input
                            type="text"
                            label="Código de Autenticação (6 dígitos)"
                            placeholder="123456"
                            value={totpCode}
                            onChange={(e) =>
                                setTotpCode(
                                    e.target.value
                                        .replace(/\D/g, "")
                                        .slice(0, 6),
                                )
                            }
                            maxLength={6}
                            autoFocus
                        />

                        <div className="flex items-center justify-between gap-2 pt-2">
                            <button
                                type="button"
                                onClick={() => setIs2FAChallenge(false)}
                                className="text-xs text-m3-secondary hover:text-m3-text"
                            >
                                Voltar
                            </button>
                            <Button
                                variant="primary"
                                size="sm"
                                type="submit"
                                isLoading={isLoading}
                            >
                                Verificar & Entrar
                            </Button>
                        </div>
                    </form>
                ) : (
                    <>
                        {/* Tabs: Sign In / Sign Up */}
                        <div className="flex bg-m3-sidebar dark:bg-m3-dark-sidebar p-1 rounded-xl border border-m3-border/30">
                            <button
                                type="button"
                                onClick={() => {
                                    setTab("signin");
                                    setErrorMsg("");
                                }}
                                className={`flex-1 py-1.5 text-xs font-black rounded-lg transition-all flex items-center justify-center gap-1.5 ${
                                    tab === "signin"
                                        ? "bg-m3-primary text-white shadow-xs"
                                        : "text-m3-secondary hover:text-m3-text"
                                }`}
                            >
                                <Lock className="w-3.5 h-3.5" />
                                Iniciar Sessão
                            </button>
                            <button
                                type="button"
                                onClick={() => {
                                    setTab("signup");
                                    setErrorMsg("");
                                }}
                                className={`flex-1 py-1.5 text-xs font-black rounded-lg transition-all flex items-center justify-center gap-1.5 ${
                                    tab === "signup"
                                        ? "bg-m3-primary text-white shadow-xs"
                                        : "text-m3-secondary hover:text-m3-text"
                                }`}
                            >
                                <UserPlus className="w-3.5 h-3.5" />
                                Criar Conta
                            </button>
                        </div>

                        {/* SIGN IN FORM */}
                        {tab === "signin" && (
                            <form
                                onSubmit={handleSignIn}
                                className="space-y-3 pt-1"
                            >
                                <Input
                                    type="email"
                                    label="Endereço de E-mail"
                                    placeholder="seu.email@exemplo.com"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    autoComplete="email"
                                    required
                                />
                                <Input
                                    type="password"
                                    label="Palavra-passe"
                                    placeholder="Sua palavra-passe"
                                    value={password}
                                    onChange={(e) =>
                                        setPassword(e.target.value)
                                    }
                                    autoComplete="current-password"
                                    required
                                />

                                <div className="pt-2">
                                    <Button
                                        variant="primary"
                                        size="sm"
                                        type="submit"
                                        isLoading={isLoading}
                                        className="w-full justify-center"
                                    >
                                        Entrar na Conta
                                    </Button>
                                </div>
                            </form>
                        )}

                        {/* SIGN UP FORM */}
                        {tab === "signup" && (
                            <form
                                onSubmit={handleSignUp}
                                className="space-y-3 pt-1"
                            >
                                <Input
                                    type="text"
                                    label="Nome Completo"
                                    placeholder="Seu nome"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    required
                                />
                                <Input
                                    type="email"
                                    label="Endereço de E-mail"
                                    placeholder="seu.email@exemplo.com"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    autoComplete="email"
                                    required
                                />
                                <Input
                                    type="password"
                                    label="Palavra-passe"
                                    placeholder="Mínimo 6 caracteres"
                                    value={password}
                                    onChange={(e) =>
                                        setPassword(e.target.value)
                                    }
                                    autoComplete="new-password"
                                    required
                                />
                                <Input
                                    type="password"
                                    label="Confirmar Palavra-passe"
                                    placeholder="Repita a palavra-passe"
                                    value={confirmPassword}
                                    onChange={(e) =>
                                        setConfirmPassword(e.target.value)
                                    }
                                    autoComplete="new-password"
                                    required
                                />

                                <div className="pt-2">
                                    <Button
                                        variant="primary"
                                        size="sm"
                                        type="submit"
                                        isLoading={isLoading}
                                        className="w-full justify-center"
                                    >
                                        Registar Nova Conta
                                    </Button>
                                </div>
                            </form>
                        )}

                        {/* Server Settings Accordion */}
                        <div className="pt-3 border-t border-m3-border/30">
                            <button
                                type="button"
                                onClick={() =>
                                    setShowServerConfig(!showServerConfig)
                                }
                                className="text-[11px] font-bold text-m3-secondary hover:text-m3-primary dark:hover:text-m3-dark-primary flex items-center gap-1.5 mx-auto"
                            >
                                <Server className="w-3.5 h-3.5" />
                                {showServerConfig
                                    ? "Ocultar URL do Servidor"
                                    : "Configurar URL do Servidor"}
                            </button>

                            {showServerConfig && (
                                <div className="mt-3 p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30 space-y-2">
                                    <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider block">
                                        URL do Servidor Remoto
                                    </label>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            value={customServerUrl}
                                            onChange={(e) =>
                                                setCustomServerUrl(
                                                    e.target.value,
                                                )
                                            }
                                            placeholder="https://api.hosanna.exemplo.com"
                                            className="flex-1 px-3 py-1.5 bg-m3-card dark:bg-m3-dark-card border border-m3-border dark:border-m3-dark-border rounded-lg font-mono text-xs text-m3-text dark:text-m3-dark-text focus:outline-none focus:ring-1 focus:ring-m3-primary"
                                        />
                                        <button
                                            type="button"
                                            onClick={handleSaveServerUrl}
                                            className="px-3 py-1.5 bg-m3-primary text-white text-xs font-black rounded-lg shadow-xs"
                                        >
                                            OK
                                        </button>
                                    </div>
                                </div>
                            )}
                        </div>
                    </>
                )}
            </div>
        </Modal>
    );
};
