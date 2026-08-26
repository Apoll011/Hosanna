import {
    Building2,
    CheckCircle2,
    HardDrive,
    RefreshCcw,
    RotateCcw,
    Users,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { authClient } from "../../lib/authClient";
import { useAppStore } from "../../store/appStore";

interface WorkspaceTabProps {
    active: boolean;
    onShowToast?: (message: string, type: "success" | "error" | "info") => void;
}

export const WorkspaceTab: React.FC<WorkspaceTabProps> = ({
    active,
    onShowToast,
}) => {
    const { organization, setActiveOrganization } = useAuth();
    const syncLibrary = useAppStore((state) => state.syncLibrary);
    const syncStatus = useAppStore((state) => state.syncStatus);
    const lastSyncTime = useAppStore((state) => state.lastSyncTime);
    const songs = useAppStore((state) => state.songs);
    const services = useAppStore((state) => state.services);

    const [isSwitchingOrg, setIsSwitchingOrg] = useState(false);

    const [orgList, setOrgList] = useState<any[]>([]);

    useEffect(() => {
        let isMounted = true;
        authClient.organization
            .list()
            .then(({ data }) => {
                if (isMounted && data) setOrgList(data);
            })
            .catch(() => {});
        return () => {
            isMounted = false;
        };
    }, []);

    if (!active) return null;

    const showToast = (
        message: string,
        type: "success" | "error" | "info" = "info",
    ) => {
        onShowToast?.(message, type);
    };

    const handleSwitchOrg = async (slug: string) => {
        if (slug === organization?.slug) return;
        setIsSwitchingOrg(true);
        try {
            await setActiveOrganization(slug);
            showToast("Organização alterada com sucesso!", "success");
            await syncLibrary({ force: true });
        } catch {
            showToast("Erro ao alterar organização.", "error");
        } finally {
            setIsSwitchingOrg(false);
        }
    };

    return (
        <div className="space-y-4">
            {/* Organization Overview Card */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs space-y-4">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="p-2 bg-m3-primary-light dark:bg-m3-dark-primary-light rounded-xl text-m3-primary dark:text-m3-dark-primary">
                            <Building2 className="w-5 h-5" />
                        </div>
                        <div>
                            <h3 className="text-sm sm:text-base font-black text-m3-text dark:text-m3-dark-text">
                                {organization?.name || "Organização"}
                            </h3>
                            <p className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary">
                                Slug:{" "}
                                <span className="font-mono">
                                    {organization?.slug || "—"}
                                </span>
                            </p>
                        </div>
                    </div>
                    {organization && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-1 rounded-full border border-emerald-200 dark:border-emerald-900/50">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            Ativa
                        </span>
                    )}
                </div>

                {organization?.metadata &&
                    typeof organization.metadata === "object" && (
                        <div className="p-3 bg-m3-sidebar dark:bg-m3-dark-sidebar rounded-xl border border-m3-border/30 text-xs space-y-1">
                            {Boolean(
                                (
                                    organization.metadata as Record<
                                        string,
                                        unknown
                                    >
                                ).description,
                            ) && (
                                <p className="text-m3-text dark:text-m3-dark-text">
                                    {String(
                                        (
                                            organization.metadata as Record<
                                                string,
                                                unknown
                                            >
                                        ).description,
                                    )}
                                </p>
                            )}
                            {Boolean(
                                (
                                    organization.metadata as Record<
                                        string,
                                        unknown
                                    >
                                ).shortName,
                            ) && (
                                <p className="text-[10px] text-m3-secondary dark:text-m3-dark-secondary">
                                    Nome Curto:{" "}
                                    <span className="font-bold text-m3-text dark:text-m3-dark-text">
                                        {String(
                                            (
                                                organization.metadata as Record<
                                                    string,
                                                    unknown
                                                >
                                            ).shortName,
                                        )}
                                    </span>
                                </p>
                            )}
                        </div>
                    )}

                {/* Organization Switcher if user belongs to multiple */}
                {orgList && orgList.length > 1 && (
                    <div className="space-y-2 pt-2 border-t border-m3-border/30">
                        <label className="text-[10px] font-black text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-wider block">
                            Alternar Organização
                        </label>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                            {orgList.map(
                                (org: {
                                    id: string;
                                    name: string;
                                    slug: string;
                                }) => {
                                    const isActive =
                                        org.slug === organization?.slug;
                                    return (
                                        <button
                                            key={org.id}
                                            disabled={
                                                isSwitchingOrg || isActive
                                            }
                                            onClick={() =>
                                                handleSwitchOrg(org.slug)
                                            }
                                            className={`p-3 rounded-xl border text-left flex items-center justify-between transition-all ${
                                                isActive
                                                    ? "bg-m3-primary-light dark:bg-m3-dark-primary-light border-m3-primary text-m3-primary dark:text-m3-dark-primary font-bold"
                                                    : "bg-m3-sidebar dark:bg-m3-dark-sidebar border-m3-border/30 hover:border-m3-primary/50 text-m3-text dark:text-m3-dark-text"
                                            }`}
                                        >
                                            <div className="min-w-0">
                                                <p className="text-xs font-bold truncate">
                                                    {org.name}
                                                </p>
                                                <p className="text-[10px] opacity-75 font-mono truncate">
                                                    {org.slug}
                                                </p>
                                            </div>
                                            {isActive && (
                                                <CheckCircle2 className="w-4 h-4 shrink-0" />
                                            )}
                                        </button>
                                    );
                                },
                            )}
                        </div>
                    </div>
                )}

                {organization?.members && (
                    <div className="flex items-center gap-2 text-xs text-m3-secondary dark:text-m3-dark-secondary">
                        <Users className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                        <span>
                            {organization.members.length} membros na organização
                        </span>
                    </div>
                )}
            </div>

            {/* Database Synchronization Card */}
            <div className="bg-m3-card dark:bg-m3-dark-card border border-m3-border/40 dark:border-m3-dark-border/40 rounded-2xl p-4 sm:p-5 shadow-xs space-y-4">
                <div className="flex items-center justify-between gap-4">
                    <div>
                        <h3 className="text-xs sm:text-sm font-bold text-m3-text dark:text-m3-dark-text flex items-center gap-1.5">
                            <HardDrive className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
                            Sincronização da Biblioteca
                        </h3>
                        <p className="text-[11px] text-m3-secondary dark:text-m3-dark-secondary mt-0.5">
                            Sincroniza cânticos, pastas e cultos da sua
                            organização.
                        </p>
                    </div>

                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => syncLibrary({ force: true })}
                            disabled={syncStatus === "syncing"}
                            title="Forçar Sincronização Completa"
                            className="p-2.5 bg-m3-sidebar dark:bg-m3-dark-sidebar hover:bg-m3-hover dark:hover:bg-m3-dark-hover text-m3-secondary dark:text-m3-dark-secondary rounded-xl border border-m3-border/30 transition-all disabled:opacity-50"
                        >
                            <RotateCcw className="w-4 h-4" />
                        </button>
                        <button
                            onClick={() => syncLibrary()}
                            disabled={syncStatus === "syncing"}
                            className="px-4 py-2.5 bg-m3-primary hover:opacity-90 text-white text-xs font-black rounded-full shadow-xs disabled:opacity-50 transition-all active:scale-95 flex items-center gap-1.5 shrink-0"
                        >
                            <RefreshCcw
                                className={`w-3.5 h-3.5 ${syncStatus === "syncing" ? "animate-spin" : ""}`}
                            />
                            Sincronizar
                        </button>
                    </div>
                </div>

                <div className="bg-m3-sidebar dark:bg-m3-dark-sidebar p-3 rounded-xl border border-m3-border/30 text-xs space-y-1.5 text-m3-secondary dark:text-m3-dark-secondary">
                    <div className="flex justify-between">
                        <span className="font-bold text-m3-text dark:text-m3-dark-text">
                            Última Sincronização:
                        </span>
                        <span className="font-mono">
                            {lastSyncTime
                                ? new Date(lastSyncTime).toLocaleString("pt-PT")
                                : "Nunca"}
                        </span>
                    </div>
                    <div className="flex justify-between">
                        <span className="font-bold text-m3-text dark:text-m3-dark-text">
                            Estado do Sync:
                        </span>
                        <span
                            className={`font-bold ${syncStatus === "error" ? "text-red-500" : syncStatus === "syncing" ? "text-m3-primary" : "text-emerald-600 dark:text-emerald-400"}`}
                        >
                            {syncStatus === "syncing"
                                ? "A sincronizar..."
                                : syncStatus === "error"
                                  ? "Erro na sincronização"
                                  : "Sincronizado"}
                        </span>
                    </div>
                    <div className="flex justify-between">
                        <span className="font-bold text-m3-text dark:text-m3-dark-text">
                            Cânticos Locais:
                        </span>
                        <span>{songs.length} cânticos</span>
                    </div>
                    <div className="flex justify-between">
                        <span className="font-bold text-m3-text dark:text-m3-dark-text">
                            Cultos Guardados:
                        </span>
                        <span>{services.length} cultos</span>
                    </div>
                </div>
            </div>
        </div>
    );
};
