import { Button, Input, Modal } from "@hosanna/shared";
import { AlertTriangle, CheckCircle2, Shield } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import React, { useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { authClient } from "../../lib/authClient";

interface TwoFactorSectionProps {
  onShowToast?: (message: string, type: "success" | "error" | "info") => void;
}

export const TwoFactorSection: React.FC<TwoFactorSectionProps> = ({
  onShowToast,
}) => {
  const { user, refetch: refetchAuth } = useAuth();
  const is2FAEnabled = Boolean(
    (user as { twoFactorEnabled?: boolean })?.twoFactorEnabled,
  );

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [password, setPassword] = useState("");
  const [totpURI, setTotpURI] = useState("");
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [verificationCode, setVerificationCode] = useState("");
  const [errorMsg, setErrorMsg] = useState("");

  const [step, setStep] = useState<"password" | "setup" | "backup" | "disable">(
    "password",
  );
  const [isLoading, setIsLoading] = useState(false);

  const showToast = (message: string, type: "success" | "error" | "info") => {
    if (onShowToast) {
      onShowToast(message, type);
    } else {
      if (type === "error") setErrorMsg(message);
    }
  };

  const handleEnable2FA = async () => {
    if (!password) {
      setErrorMsg("Por favor insira a palavra-passe.");
      return;
    }
    setErrorMsg("");
    setIsLoading(true);
    try {
      const { data, error } = await authClient.twoFactor.enable({ password });
      if (error) {
        setErrorMsg(error.message || "Erro ao ativar 2FA");
        showToast(error.message || "Erro ao ativar 2FA", "error");
      } else if (data) {
        setTotpURI(data.totpURI);
        setBackupCodes(data.backupCodes || []);
        setStep("setup");
      }
    } catch (err: unknown) {
      const msg = (err as Error).message || "Erro ao ativar 2FA";
      setErrorMsg(msg);
      showToast(msg, "error");
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerify2FA = async () => {
    if (!verificationCode || verificationCode.length < 6) {
      setErrorMsg("Por favor insira o código de 6 dígitos.");
      return;
    }
    setErrorMsg("");
    setIsLoading(true);
    try {
      const { error } = await authClient.twoFactor.verifyTotp({
        code: verificationCode,
        trustDevice: true,
      });
      if (error) {
        setErrorMsg(error.message || "Código inválido");
        showToast(error.message || "Código inválido", "error");
      } else {
        showToast("Código verificado com sucesso!", "success");
        setStep("backup");
      }
    } catch (err: unknown) {
      const msg = (err as Error).message || "Erro ao verificar código";
      setErrorMsg(msg);
      showToast(msg, "error");
    } finally {
      setIsLoading(false);
    }
  };

  const handleFinishSetup = async () => {
    showToast("Autenticação em 2 Etapas configurada com sucesso!", "success");
    await refetchAuth();
    closeModal();
  };

  const handleDisable2FA = async () => {
    if (!password) {
      setErrorMsg("Por favor insira a palavra-passe.");
      return;
    }
    setErrorMsg("");
    setIsLoading(true);
    try {
      const { error } = await authClient.twoFactor.disable({ password });
      if (error) {
        setErrorMsg(error.message || "Erro ao desativar 2FA");
        showToast(error.message || "Erro ao desativar 2FA", "error");
      } else {
        showToast("Autenticação em 2 Etapas desativada.", "success");
        await refetchAuth();
        closeModal();
      }
    } catch (err: unknown) {
      const msg = (err as Error).message || "Erro ao desativar 2FA";
      setErrorMsg(msg);
      showToast(msg, "error");
    } finally {
      setIsLoading(false);
    }
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setPassword("");
    setTotpURI("");
    setBackupCodes([]);
    setVerificationCode("");
    setErrorMsg("");
    setStep("password");
  };

  return (
    <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs">
      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0 flex-1">
          <h3 className="text-xs sm:text-sm font-bold text-m3-text dark:text-m3-dark-text flex items-center gap-1.5">
            <Shield className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary shrink-0" />
            Autenticação em 2 Etapas (2FA)
          </h3>
          <p className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5 leading-snug">
            Adicione uma camada extra de segurança com código temporário TOTP.
          </p>
        </div>
        <button
          onClick={() => {
            setStep(is2FAEnabled ? "disable" : "password");
            setIsModalOpen(true);
          }}
          className={`px-3 py-1.5 text-xs font-black rounded-xl transition-all shrink-0 ${
            is2FAEnabled
              ? "bg-red-50 text-red-600 hover:bg-red-100 dark:bg-red-950/40 dark:text-red-400 border border-red-200 dark:border-red-900/50"
              : "bg-m3-primary text-white hover:opacity-90 shadow-xs"
          }`}
        >
          {is2FAEnabled ? "Desativar 2FA" : "Ativar 2FA"}
        </button>
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={closeModal}
        title={is2FAEnabled ? "Desativar 2FA" : "Configurar 2FA"}
      >
        <div className="space-y-4 py-2">
          {errorMsg && (
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 rounded-xl text-xs text-red-600 dark:text-red-400 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* PASSO 1: CONFIRMAR PALAVRA-PASSE */}
          {step === "password" && (
            <div className="space-y-3">
              <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                Para ativar a verificação em duas etapas, confirme a sua palavra-passe atual:
              </p>
              <Input
                type="password"
                label="Palavra-passe"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Introduza a sua palavra-passe"
              />
              <div className="flex justify-end gap-2 pt-3">
                <Button variant="outline" size="sm" onClick={closeModal}>
                  Cancelar
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  isLoading={isLoading}
                  onClick={handleEnable2FA}
                >
                  Continuar
                </Button>
              </div>
            </div>
          )}

          {/* PASSO 2: CONFIGURAR CÓDIGO QR */}
          {step === "setup" && (
            <div className="space-y-3">
              <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                1. Digitalize o código QR com a sua aplicação de autenticação (Google Authenticator, Authy, Microsoft Authenticator):
              </p>

              {totpURI && (
                <div className="flex justify-center my-3">
                  <div className="bg-white p-3 rounded-2xl shadow-sm border border-slate-200">
                    <QRCodeSVG value={totpURI} size={150} />
                  </div>
                </div>
              )}

              <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                2. Introduza o código de 6 dígitos gerado pela aplicação:
              </p>

              <Input
                type="text"
                label="Código de Verificação"
                placeholder="123456"
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                maxLength={6}
              />

              <div className="flex justify-end gap-2 pt-3">
                <Button variant="outline" size="sm" onClick={closeModal}>
                  Cancelar
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  isLoading={isLoading}
                  onClick={handleVerify2FA}
                >
                  Verificar Código
                </Button>
              </div>
            </div>
          )}

          {/* PASSO 3: CÓDIGOS DE RECUPERAÇÃO */}
          {step === "backup" && (
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
                <CheckCircle2 className="w-5 h-5 shrink-0" />
                <span className="text-xs sm:text-sm font-black">
                  Aplicação associada com sucesso!
                </span>
              </div>

              <div className="bg-amber-50 dark:bg-amber-950/30 p-3 rounded-xl border border-amber-200 dark:border-amber-900/50 flex gap-2.5">
                <AlertTriangle className="w-4 h-4 text-amber-600 dark:text-amber-500 shrink-0 mt-0.5" />
                <p className="text-[11px] text-amber-800 dark:text-amber-400 leading-snug">
                  Guarde estes códigos de recuperação num local seguro. Eles são a única forma de recuperar o acesso caso perca o telemóvel.
                </p>
              </div>

              {backupCodes.length > 0 && (
                <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-3 rounded-xl border border-m3-border/30">
                  <div className="grid grid-cols-2 gap-2 font-mono text-xs text-m3-text dark:text-m3-dark-text text-center">
                    {backupCodes.map((code, idx) => (
                      <span
                        key={idx}
                        className="bg-m3-card dark:bg-m3-dark-card py-1.5 px-2 rounded-lg border border-m3-border/30 shadow-2xs select-all"
                      >
                        {code}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-2 pt-4">
                <Button variant="primary" size="sm" onClick={handleFinishSetup}>
                  Guardei os códigos com segurança
                </Button>
              </div>
            </div>
          )}

          {/* PASSO DESATIVAR */}
          {step === "disable" && (
            <div className="space-y-3">
              <p className="text-xs text-m3-secondary dark:text-m3-dark-secondary leading-relaxed">
                Para desativar a verificação em duas etapas, confirme a sua palavra-passe:
              </p>
              <Input
                type="password"
                label="Palavra-passe"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Sua palavra-passe atual"
              />
              <div className="flex justify-end gap-2 pt-3">
                <Button variant="outline" size="sm" onClick={closeModal}>
                  Cancelar
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  isLoading={isLoading}
                  onClick={handleDisable2FA}
                  className="bg-red-600 hover:bg-red-700 text-white border-0"
                >
                  Desativar 2FA
                </Button>
              </div>
            </div>
          )}
        </div>
      </Modal>
    </div>
  );
};
