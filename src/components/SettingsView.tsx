import {
    Building2,
    CheckCircle2,
    Info,
    Sliders,
    User,
    XCircle,
} from "lucide-react";
import React, { useState } from "react";
import { AuthModal } from "./auth/AuthModal";
import { AccountTab } from "./settings/AccountTab";
import { PreferencesTab } from "./settings/PreferencesTab";
import { WorkspaceTab } from "./settings/WorkspaceTab";

type SettingsTab = "account" | "workspace" | "preferences";

interface ToastState {
    message: string;
    type: "success" | "error" | "info";
}

export default function SettingsView() {
    const [activeTab, setActiveTab] = useState<SettingsTab>("account");
    const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
    const [toast, setToast] = useState<ToastState | null>(null);

    const showToast = (
        message: string,
        type: "success" | "error" | "info" = "info",
    ) => {
        setToast({ message, type });
        setTimeout(() => {
            setToast((curr) => (curr?.message === message ? null : curr));
        }, 3500);
    };

    const tabs: {
        id: SettingsTab;
        label: string;
        icon: React.FC<{ className?: string }>;
    }[] = [
        { id: "account", label: "Conta", icon: User },
        { id: "workspace", label: "Organização", icon: Building2 },
        { id: "preferences", label: "Preferências", icon: Sliders },
    ];

    return (
        <div className="w-full h-full overflow-y-auto bg-m3-bg dark:bg-m3-dark-bg p-3 sm:p-4 pb-28 space-y-4 no-scrollbar">
            {/* Toast Notification Banner */}
            {toast && (
                <div
                    className={`fixed top-4 left-1/2 -translate-x-1/2 z-50 px-4 py-2.5 rounded-2xl shadow-xl border text-xs font-bold flex items-center gap-2 max-w-[90%] sm:max-w-md animate-in fade-in slide-in-from-top-4 duration-300 ${
                        toast.type === "success"
                            ? "bg-emerald-50 text-emerald-800 border-emerald-300 dark:bg-emerald-950 dark:text-emerald-200 dark:border-emerald-800"
                            : toast.type === "error"
                              ? "bg-red-50 text-red-800 border-red-300 dark:bg-red-950 dark:text-red-200 dark:border-red-800"
                              : "bg-sky-50 text-sky-800 border-sky-300 dark:bg-sky-950 dark:text-sky-200 dark:border-sky-800"
                    }`}
                >
                    {toast.type === "success" && (
                        <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                    )}
                    {toast.type === "error" && (
                        <XCircle className="w-4 h-4 text-red-600 dark:text-red-400 shrink-0" />
                    )}
                    {toast.type === "info" && (
                        <Info className="w-4 h-4 text-sky-600 dark:text-sky-400 shrink-0" />
                    )}
                    <span className="truncate">{toast.message}</span>
                </div>
            )}

            {/* Tab Selector Bar */}
            <div className="flex bg-m3-card dark:bg-m3-dark-card p-1 rounded-2xl border border-m3-border/40 dark:border-m3-dark-border/40 shadow-xs">
                {tabs.map((tab) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === tab.id;
                    return (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={`flex-1 py-2.5 px-2 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                                isActive
                                    ? "bg-m3-primary text-white shadow-xs"
                                    : "text-m3-secondary dark:text-m3-dark-secondary hover:text-m3-text dark:hover:text-m3-dark-text"
                            }`}
                        >
                            <Icon className="w-3.5 h-3.5" />
                            <span className="truncate">{tab.label}</span>
                        </button>
                    );
                })}
            </div>

            {/* Active Tab Content */}
            <div className="space-y-4">
                <AccountTab
                    active={activeTab === "account"}
                    onOpenAuthModal={() => setIsAuthModalOpen(true)}
                    onShowToast={showToast}
                />
                <WorkspaceTab
                    active={activeTab === "workspace"}
                    onShowToast={showToast}
                />
                <PreferencesTab
                    active={activeTab === "preferences"}
                    onShowToast={showToast}
                />
            </div>

            {/* Authentication Modal */}
            <AuthModal
                isOpen={isAuthModalOpen}
                onClose={() => setIsAuthModalOpen(false)}
            />
        </div>
    );
}
