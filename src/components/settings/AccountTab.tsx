import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { useQuery } from "@tanstack/react-query";
import {
    Camera,
    Info,
    KeyRound,
    Loader2,
    Lock,
    LogOut,
    MonitorSmartphone,
    PenLine,
    RefreshCw,
    Save,
    Trash2,
} from "lucide-react";
import React, { useEffect, useRef, useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { authClient } from "../../lib/authClient";
import { compressImage, getRoleBadge } from "./settingsUtils";
import { TwoFactorSection } from "./TwoFactor";

interface AccountTabProps {
    active: boolean;
    onOpenAuthModal?: () => void;
    onShowToast?: (message: string, type: "success" | "error" | "info") => void;
}

const ActiveSessionsSection: React.FC<{
    onShowToast?: (message: string, type: "success" | "error" | "info") => void;
}> = ({ onShowToast }) => {
    const {
        data: sessions,
        refetch,
        isLoading,
    } = useQuery({
        queryKey: ["activeSessions"],
        queryFn: async () => {
            try {
                const { data } = await authClient.listSessions();
                return data || [];
            } catch {
                return [];
            }
        },
    });

    const handleRevoke = async (token: string) => {
        try {
            await authClient.revokeSession({ token });
            onShowToast?.("Sessão revogada com sucesso.", "success");
            refetch();
        } catch {
            onShowToast?.("Erro ao revogar sessão.", "error");
        }
    };

    return (
        <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
            <div className="flex items-center justify-between mb-3">
                <div>
                    <h3 className="text-xs sm:text-sm font-bold text-m3-text dark:text-m3-dark-text flex items-center gap-1.5">
                        <MonitorSmartphone className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                        Sessões Ativas
                    </h3>
                    <p className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5">
                        Dispositivos autenticados na sua conta.
                    </p>
                </div>
                <button
                    onClick={() => refetch()}
                    className="p-1.5 text-m3-secondary hover:text-m3-text dark:hover:text-m3-dark-text rounded-lg hover:bg-m3-hover dark:hover:bg-m3-dark-hover transition-colors"
                    title="Atualizar sessões"
                >
                    <RefreshCw className="w-4 h-4" />
                </button>
            </div>

            {isLoading ? (
                <div className="py-6 text-center text-xs text-m3-secondary flex items-center justify-center gap-2">
                    <Loader2 className="w-4 h-4 animate-spin text-m3-primary dark:text-m3-dark-primary" />
                    A carregar sessões...
                </div>
            ) : sessions && sessions.length > 0 ? (
                <div className="space-y-2.5">
                    {sessions.map(
                        (
                            sess: {
                                id: string;
                                createdAt: Date;
                                updatedAt: Date;
                                userId: string;
                                expiresAt: Date;
                                token: string;
                                ipAddress?: string | null;
                                userAgent?: string | null;
                            },
                            idx: number,
                        ) => (
                            <div
                                key={sess.id || idx}
                                className="p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30 flex items-center justify-between gap-3"
                            >
                                <div className="flex items-center gap-2.5 min-w-0 flex-1">
                                    <div className="p-2 bg-m3-card dark:bg-m3-dark-card rounded-lg border border-m3-border/20 shrink-0">
                                        <MonitorSmartphone className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <p className="text-xs font-bold text-m3-text dark:text-m3-dark-text truncate">
                                            {sess.userAgent ||
                                                "Sessão Móvel / Navegador"}
                                        </p>
                                        <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary font-mono mt-0.5 truncate">
                                            IP: {sess.ipAddress || "Atual"} ·{" "}
                                            {new Date(
                                                sess.createdAt,
                                            ).toLocaleDateString("pt-PT")}
                                        </p>
                                    </div>
                                </div>

                                <button
                                    onClick={() => handleRevoke(sess.token)}
                                    className="px-2.5 py-1 text-[11px] font-black text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 rounded-lg transition-colors border border-red-200 dark:border-red-900/50 shrink-0"
                                >
                                    Encerrar
                                </button>
                            </div>
                        ),
                    )}
                </div>
            ) : (
                <p className="text-xs text-m3-secondary py-3 text-center">
                    Apenas a sessão atual deste dispositivo está ativa.
                </p>
            )}
        </div>
    );
};

export const AccountTab: React.FC<AccountTabProps> = ({
    active,
    onOpenAuthModal,
    onShowToast,
}) => {
    const {
        user,
        organization,
        isAuthenticated,
        refetch: refetchAuth,
        logout,
    } = useAuth();
    const avatarInputRef = useRef<HTMLInputElement>(null);

    const [displayUser, setDisplayUser] = useState(user);

    useEffect(() => {
        setDisplayUser(user);
    }, [user]);

    const [isEditingName, setIsEditingName] = useState(false);
    const [isEditingEmail, setIsEditingEmail] = useState(false);
    const [isEditingPassword, setIsEditingPassword] = useState(false);

    const [draftName, setDraftName] = useState("");
    const [draftEmail, setDraftEmail] = useState("");
    const [draftOldPassword, setDraftOldPassword] = useState("");
    const [draftNewPassword, setDraftNewPassword] = useState("");
    const [draftConfirmPassword, setDraftConfirmPassword] = useState("");
    const [isCompressingAvatar, setIsCompressingAvatar] = useState(false);
    const [isSavingName, setIsSavingName] = useState(false);
    const [isSavingEmail, setIsSavingEmail] = useState(false);
    const [isSavingPassword, setIsSavingPassword] = useState(false);

    if (!active) return null;

    const showToast = (
        message: string,
        type: "success" | "error" | "info" = "info",
    ) => {
        onShowToast?.(message, type);
    };

    const handleAvatarChange = async (
        e: React.ChangeEvent<HTMLInputElement>,
    ) => {
        const file = e.target.files?.[0];
        if (!file) return;
        if (!file.type.startsWith("image/")) {
            showToast(
                "Por favor selecione um ficheiro de imagem válido.",
                "error",
            );
            return;
        }

        try {
            setIsCompressingAvatar(true);
            const compressedBase64 = await compressImage(file, 800, 0.8);

            setDisplayUser((prev) =>
                prev ? { ...prev, image: compressedBase64 } : prev,
            );

            await authClient.updateUser({ image: compressedBase64 });
            await refetchAuth();
            showToast("Avatar atualizado com sucesso!", "success");
        } catch (err: unknown) {
            showToast(
                "Erro ao atualizar o avatar: " +
                    ((err as Error).message || "Erro de rede"),
                "error",
            );
        } finally {
            setIsCompressingAvatar(false);
            e.target.value = "";
        }
    };

    const handleRemoveAvatar = async () => {
        try {
            setDisplayUser((prev) =>
                prev ? { ...prev, image: undefined } : prev,
            );
            await authClient.updateUser({ image: "" });
            await refetchAuth();
            showToast("Avatar removido com sucesso!", "success");
        } catch {
            showToast("Erro ao remover o avatar.", "error");
        }
    };

    const handleSaveName = async () => {
        if (!draftName.trim()) {
            showToast("O nome não pode estar vazio.", "error");
            return;
        }

        try {
            setIsSavingName(true);
            setDisplayUser((prev) =>
                prev ? { ...prev, name: draftName } : prev,
            );
            setIsEditingName(false);

            await authClient.updateUser({ name: draftName });
            await refetchAuth();
            showToast("Nome guardado com sucesso!", "success");
        } catch {
            showToast("Erro ao guardar o novo nome.", "error");
        } finally {
            setIsSavingName(false);
        }
    };

    const handleSaveEmail = async () => {
        if (!draftEmail.trim() || !draftEmail.includes("@")) {
            showToast("Por favor introduza um e-mail válido.", "error");
            return;
        }

        try {
            setIsSavingEmail(true);
            setIsEditingEmail(false);
            await authClient.changeEmail({ newEmail: draftEmail });
            await refetchAuth();
            showToast("Pedido de alteração de e-mail enviado!", "success");
        } catch (err: unknown) {
            showToast(
                "Erro ao alterar o e-mail: " +
                    ((err as Error).message || "Tente novamente"),
                "error",
            );
        } finally {
            setIsSavingEmail(false);
        }
    };

    const handleSavePassword = async () => {
        if (!draftOldPassword) {
            showToast(
                "Por favor introduza a sua palavra-passe atual.",
                "error",
            );
            return;
        }
        if (draftNewPassword.length < 6) {
            showToast(
                "A nova palavra-passe deve ter pelo menos 6 caracteres.",
                "error",
            );
            return;
        }
        if (draftNewPassword !== draftConfirmPassword) {
            showToast("As palavras-passe não coincidem.", "error");
            return;
        }

        try {
            setIsSavingPassword(true);
            await authClient.changePassword({
                newPassword: draftNewPassword,
                currentPassword: draftOldPassword,
                revokeOtherSessions: true,
            });

            showToast("Palavra-passe alterada com sucesso!", "success");
            setIsEditingPassword(false);
            setDraftOldPassword("");
            setDraftNewPassword("");
            setDraftConfirmPassword("");
        } catch (err: unknown) {
            showToast(
                "Erro ao alterar palavra-passe: " +
                    ((err as Error).message ||
                        "Verifique a palavra-passe atual"),
                "error",
            );
        } finally {
            setIsSavingPassword(false);
        }
    };

    const getUserInitials = (name?: string) => {
        if (!name) return "U";
        return name
            .split(" ")
            .map((w) => w.charAt(0))
            .join("")
            .toUpperCase()
            .slice(0, 2);
    };

    // If user is not logged in, show login CTA
    if (!isAuthenticated || !displayUser) {
        return (
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-6 text-center space-y-4 shadow-xs">
                <div className="w-14 h-14 rounded-2xl bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-primary mx-auto flex items-center justify-center">
                    <Lock className="w-7 h-7" />
                </div>
                <div className="space-y-1 max-w-sm mx-auto">
                    <h3 className="text-base font-black text-m3-text dark:text-m3-dark-text">
                        Sessão Não Iniciada
                    </h3>
                    <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                        Inicie sessão com a sua conta Better Auth para gerir o
                        seu perfil, 2FA, sessões ativas e sincronizar com a sua
                        organização.
                    </p>
                </div>
                <button
                    onClick={onOpenAuthModal}
                    className="px-6 py-2.5 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-full shadow-xs transition-all active:scale-95"
                >
                    Iniciar Sessão / Criar Conta
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            {/* User Profile Card */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex items-center gap-3.5">
                        <div className="relative group shrink-0">
                            <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-linear-to-tr from-sky-600 to-indigo-600 flex items-center justify-center font-black text-white text-lg sm:text-xl overflow-hidden shadow-md">
                                {displayUser?.image ? (
                                    <img
                                        src={displayUser.image}
                                        alt={displayUser.name}
                                        className="w-full h-full object-cover"
                                    />
                                ) : (
                                    <span>
                                        {getUserInitials(displayUser?.name)}
                                    </span>
                                )}
                            </div>

                            <input
                                ref={avatarInputRef}
                                type="file"
                                accept="image/*"
                                onChange={handleAvatarChange}
                                className="hidden"
                            />

                            <button
                                type="button"
                                onClick={() => avatarInputRef.current?.click()}
                                disabled={isCompressingAvatar}
                                className="absolute bottom-0 right-0 p-1.5 bg-m3-primary text-white rounded-full shadow-md hover:opacity-90 transition-colors cursor-pointer"
                                title="Alterar imagem de perfil"
                            >
                                <Camera className="w-3.5 h-3.5" />
                            </button>
                        </div>

                        <div className="min-w-0 flex-1">
                            <h2 className="text-sm sm:text-base font-bold text-m3-text dark:text-m3-dark-text flex items-center gap-2 flex-wrap">
                                <span className="truncate">
                                    {displayUser?.name || "Utilizador"}
                                </span>
                                {getRoleBadge(displayUser?.role || "member")}
                            </h2>
                            <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary mt-0.5 truncate">
                                {displayUser?.email}
                            </p>
                        </div>
                    </div>

                    <div className="flex items-center gap-2 self-start sm:self-center">
                        {displayUser?.image && (
                            <button
                                type="button"
                                onClick={handleRemoveAvatar}
                                className="text-xs font-bold text-red-600 dark:text-red-400 hover:opacity-80 flex items-center gap-1 px-2 py-1 rounded-lg border border-red-200 dark:border-red-900/50"
                            >
                                <Trash2 className="w-3.5 h-3.5" />
                                Remover Foto
                            </button>
                        )}
                        <button
                            type="button"
                            onClick={logout}
                            className="text-xs font-bold text-m3-secondary hover:text-red-600 dark:text-m3-dark-secondary dark:hover:text-red-400 flex items-center gap-1 px-3 py-1.5 rounded-lg border border-m3-border/30 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors"
                        >
                            <LogOut className="w-3.5 h-3.5" />
                            Terminar Sessão
                        </button>
                    </div>
                </div>
            </div>

            {/* Name Section */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                    <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider">
                        Nome de Exibição
                    </label>
                    {!isEditingName && (
                        <button
                            onClick={() => {
                                setDraftName(displayUser?.name || "");
                                setIsEditingName(true);
                            }}
                            className="text-xs font-bold text-m3-primary dark:text-m3-dark-primary hover:underline flex items-center gap-1"
                        >
                            <PenLine className="w-3.5 h-3.5" />
                            Editar
                        </button>
                    )}
                </div>

                {isEditingName ? (
                    <div className="space-y-3 pt-1">
                        <Input
                            value={draftName}
                            onChange={(e) => setDraftName(e.target.value)}
                            placeholder="Seu nome completo"
                        />
                        <div className="flex justify-end gap-2">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setIsEditingName(false)}
                            >
                                Cancelar
                            </Button>
                            <Button
                                variant="primary"
                                size="sm"
                                isLoading={isSavingName}
                                onClick={handleSaveName}
                                icon={<Save className="w-4 h-4" />}
                            >
                                Guardar
                            </Button>
                        </div>
                    </div>
                ) : (
                    <p className="text-sm font-semibold text-m3-text dark:text-m3-dark-text">
                        {displayUser?.name || "—"}
                    </p>
                )}
            </div>

            {/* Email Section */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                    <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider">
                        Endereço de E-mail
                    </label>
                    {!isEditingEmail && (
                        <button
                            onClick={() => {
                                setDraftEmail(displayUser?.email || "");
                                setIsEditingEmail(true);
                            }}
                            className="text-xs font-bold text-m3-primary dark:text-m3-dark-primary hover:underline flex items-center gap-1"
                        >
                            <PenLine className="w-3.5 h-3.5" />
                            Alterar
                        </button>
                    )}
                </div>

                {isEditingEmail ? (
                    <div className="space-y-3 pt-1">
                        <Input
                            type="email"
                            value={draftEmail}
                            onChange={(e) => setDraftEmail(e.target.value)}
                            placeholder="novo.email@exemplo.com"
                        />
                        <div className="flex justify-end gap-2">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setIsEditingEmail(false)}
                            >
                                Cancelar
                            </Button>
                            <Button
                                variant="primary"
                                size="sm"
                                isLoading={isSavingEmail}
                                onClick={handleSaveEmail}
                                icon={<Save className="w-4 h-4" />}
                            >
                                Guardar E-mail
                            </Button>
                        </div>
                    </div>
                ) : (
                    <p className="text-sm font-semibold text-m3-text dark:text-m3-dark-text">
                        {displayUser?.email || "—"}
                    </p>
                )}
            </div>

            {/* Password Section */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
                <div className="flex items-center justify-between mb-2">
                    <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider flex items-center gap-1">
                        <Lock className="w-3.5 h-3.5 text-m3-primary dark:text-m3-dark-primary" />
                        Palavra-passe
                    </label>
                    {!isEditingPassword && (
                        <button
                            onClick={() => setIsEditingPassword(true)}
                            className="text-xs font-bold text-m3-primary dark:text-m3-dark-primary hover:underline flex items-center gap-1"
                        >
                            <KeyRound className="w-3.5 h-3.5" />
                            Alterar
                        </button>
                    )}
                </div>

                {isEditingPassword ? (
                    <div className="space-y-3 pt-1">
                        <Input
                            type="password"
                            label="Palavra-passe Atual"
                            value={draftOldPassword}
                            onChange={(e) =>
                                setDraftOldPassword(e.target.value)
                            }
                            placeholder="Introduza a sua palavra-passe atual"
                        />
                        <Input
                            type="password"
                            label="Nova Palavra-passe"
                            value={draftNewPassword}
                            onChange={(e) =>
                                setDraftNewPassword(e.target.value)
                            }
                            placeholder="Mínimo 6 caracteres"
                        />
                        <Input
                            type="password"
                            label="Confirmar Nova Palavra-passe"
                            value={draftConfirmPassword}
                            onChange={(e) =>
                                setDraftConfirmPassword(e.target.value)
                            }
                            placeholder="Repita a nova palavra-passe"
                        />

                        <div className="flex justify-end gap-2 pt-2">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => {
                                    setIsEditingPassword(false);
                                    setDraftOldPassword("");
                                    setDraftNewPassword("");
                                    setDraftConfirmPassword("");
                                }}
                            >
                                Cancelar
                            </Button>
                            <Button
                                variant="primary"
                                size="sm"
                                isLoading={isSavingPassword}
                                onClick={handleSavePassword}
                                icon={<Save className="w-4 h-4" />}
                            >
                                Atualizar Palavra-passe
                            </Button>
                        </div>
                    </div>
                ) : (
                    <p className="text-sm font-semibold text-m3-secondary tracking-widest">
                        ••••••••••••
                    </p>
                )}
            </div>

            {/* Two-Factor Authentication Section */}
            <TwoFactorSection onShowToast={showToast} />

            {/* Active Sessions Section */}
            <ActiveSessionsSection onShowToast={showToast} />

            {/* Account Info */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
                <h3 className="text-xs sm:text-sm font-bold text-m3-text dark:text-m3-dark-text flex items-center gap-1.5 mb-3">
                    <Info className="w-4 h-4 text-m3-secondary dark:text-m3-dark-secondary" />
                    Informações da Conta
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30">
                        <span className="text-[9px] font-black uppercase tracking-wider text-m3-secondary dark:text-m3-dark-secondary block mb-1">
                            ID do Utilizador
                        </span>
                        <p className="text-xs font-mono text-m3-text dark:text-m3-dark-text truncate select-all">
                            {displayUser?.id || "—"}
                        </p>
                    </div>
                    <div className="p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30">
                        <span className="text-[9px] font-black uppercase tracking-wider text-m3-secondary dark:text-m3-dark-secondary block mb-1">
                            Função
                        </span>
                        {getRoleBadge(displayUser?.role || "member")}
                    </div>
                    <div className="p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30">
                        <span className="text-[9px] font-black uppercase tracking-wider text-m3-secondary dark:text-m3-dark-secondary block mb-1">
                            Organização Ativa
                        </span>
                        <span className="text-xs font-bold text-m3-primary dark:text-m3-dark-primary truncate block">
                            {organization?.name || "Sem organização ativa"}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
};
