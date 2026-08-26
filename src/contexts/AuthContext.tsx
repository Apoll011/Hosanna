import { getApiClient } from "@hosanna/shared";
import type { InvitationStatus } from "better-auth/plugins/organization";
import React, {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useState,
} from "react";
import { authClient } from "../lib/authClient";
import { clearPermissionCache } from "../lib/permissions/client";

import { preloadPermissionsForRole, type AppRole } from "../lib/permissions";
import { ensureApiClient } from "../store/appStore";

export interface SessionUser {
    id: string;
    name: string;
    email: string;
    image?: string;
    emailVerified: boolean;
    twoFactorEnabled?: boolean;
    createdAt: Date;
    updatedAt: Date;
    role?: string;
    [key: string]: unknown;
}

export type Organization = {
    id: string;
    name: string;
    slug: string;
    logo?: string | null;
    createdAt: Date;
    metadata?: {
        description?: string;
        shortName?: string;
        settings?: {
            general?: {
                locale?: string;
                timezone?: string;
                weekStartsOn?: number;
            };
            services?: {
                defaultDurations?: {
                    sermon?: number;
                    song?: number;
                };
                showNotes?: boolean;
                showServiceDuration?: boolean;
                autoSave?: boolean;
            };
            appearance?: {
                accentColor?: string;
                showBranding?: boolean;
            };
        };
        [key: string]: unknown;
    } | null;
    members?: {
        id: string;
        organizationId: string;
        role:
            | "admin"
            | "editor"
            | "guest"
            | "member"
            | "musician"
            | "owner"
            | "teamLeader";
        createdAt: Date;
        userId: string;
        teamId?: string;
        user: {
            id: string;
            email: string;
            name: string;
            image?: string;
        };
    }[];
    invitations?: {
        id: string;
        organizationId: string;
        email: string;
        role:
            | "admin"
            | "editor"
            | "guest"
            | "member"
            | "musician"
            | "owner"
            | "teamLeader";
        status: InvitationStatus;
        inviterId: string;
        expiresAt: Date;
        createdAt: Date;
        teamId?: string;
    }[];
};

const normalizeOrganization = (org: unknown): Organization => {
    const organization = org as Organization & { metadata?: unknown };

    if (typeof organization.metadata === "string") {
        try {
            organization.metadata = JSON.parse(organization.metadata) as Record<
                string,
                unknown
            >;
        } catch {
            organization.metadata = null;
        }
    }

    return organization;
};

interface AuthContextType {
    user: SessionUser | null;
    organization: Organization | null;
    isAuthenticated: boolean;
    isLoading: boolean;
    isOfflineAuth: boolean;
    refetch: () => Promise<void>;
    logout: () => Promise<void>;
    setActiveOrganization: (slug: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const AUTH_CACHE_KEY = "hosanna_auth_cache";

interface CachedAuth {
    user: SessionUser;
    organization: Organization | null;
}

const getCachedAuth = (): CachedAuth | null => {
    try {
        const raw =
            typeof localStorage !== "undefined"
                ? localStorage.getItem(AUTH_CACHE_KEY)
                : null;
        if (!raw) return null;
        return JSON.parse(raw) as CachedAuth;
    } catch {
        return null;
    }
};

const setCachedAuth = (
    user: SessionUser,
    organization: Organization | null,
) => {
    try {
        localStorage.setItem(
            AUTH_CACHE_KEY,
            JSON.stringify({ user, organization }),
        );
    } catch {}
};

const clearCachedAuth = () => {
    try {
        localStorage.removeItem(AUTH_CACHE_KEY);
    } catch {}
};

// Immediate pre-seeding from localStorage on module load
if (typeof localStorage !== "undefined") {
    ensureApiClient();
    const initialCached = getCachedAuth();
    if (initialCached?.user?.role) {
        preloadPermissionsForRole(initialCached.user.role as AppRole);
    }
}

function isExplicitAuthRejection(error: unknown, data: unknown): boolean {
    if (!error) {
        // If there is no error, and data is null, but we are online:
        // this was a clean 200 response with null session (logged out)
        if (
            data === null &&
            typeof navigator !== "undefined" &&
            navigator.onLine
        ) {
            return true;
        }
        return false;
    }
    const errObj = error as {
        status?: number;
        statusCode?: number;
        code?: string;
        message?: string;
    };
    const status = errObj.status ?? errObj.statusCode;
    // 401 Unauthorized, 403 Forbidden, 404 Not Found are definitive auth rejections
    if (status === 401 || status === 403 || status === 404) {
        return true;
    }
    // Status 0, 5xx or network errors are temporary / network glitches
    if (status === 0 || (typeof status === "number" && status >= 500)) {
        return false;
    }
    const msg = (errObj.message || "").toLowerCase();
    if (
        msg.includes("fetch") ||
        msg.includes("network") ||
        msg.includes("offline") ||
        msg.includes("timeout") ||
        msg.includes("abort") ||
        msg.includes("failed to fetch")
    ) {
        return false;
    }
    return false;
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
    children,
}) => {
    const cached = getCachedAuth();
    const [user, setUser] = useState<SessionUser | null>(cached?.user ?? null);
    const [organization, setOrganization] = useState<Organization | null>(
        cached?.organization ?? null,
    );
    // If we have a cached session, skip the loading state so the app renders immediately
    const [isLoading, setIsLoading] = useState(!cached);
    const [isOfflineAuth, setIsOfflineAuth] = useState(false);

    const handleClearSession = useCallback(() => {
        setUser(null);
        setOrganization(null);
        setIsOfflineAuth(false);
        clearCachedAuth();
        try {
            localStorage.removeItem("active_org_slug");
            localStorage.removeItem("hosanna_access_token");
        } catch {}
        getApiClient().setTokens(null);
        clearPermissionCache();
        setIsLoading(false);
    }, []);

    const fetchSession = useCallback(async () => {
        const currentCached = getCachedAuth();
        // Only show loading spinner if there's no cached user to display
        if (!currentCached) {
            setIsLoading(true);
        }

        try {
            // Fast exit if browser reports offline and we have cached auth
            if (
                typeof navigator !== "undefined" &&
                !navigator.onLine &&
                currentCached?.user
            ) {
                setUser(currentCached.user);
                setOrganization(currentCached.organization);
                setIsOfflineAuth(true);
                if (currentCached.user.role) {
                    preloadPermissionsForRole(
                        currentCached.user.role as AppRole,
                    );
                }
                setIsLoading(false);
                return;
            }

            const { data: sessionData, error: sessionError } =
                await authClient.getSession();
            const sessionUser = sessionData?.user;

            if (!sessionUser || sessionError) {
                const isRejected = isExplicitAuthRejection(
                    sessionError,
                    sessionData,
                );
                if (isRejected || !currentCached?.user) {
                    return handleClearSession();
                } else {
                    // Non-fatal error: preserve offline cached session
                    console.warn(
                        "Session fetch failed with non-auth network/server error. Using cached credentials in temporary offline mode.",
                        sessionError,
                    );
                    setUser(currentCached.user);
                    setOrganization(currentCached.organization);
                    setIsOfflineAuth(true);
                    if (currentCached.user.role) {
                        preloadPermissionsForRole(
                            currentCached.user.role as AppRole,
                        );
                    }
                    return;
                }
            }

            // Sync session token with shared ApiClient if available
            const token =
                (sessionData as any)?.session?.token ||
                (sessionData as any)?.session?.id ||
                (typeof localStorage !== "undefined"
                    ? localStorage.getItem("hosanna_access_token")
                    : null);
            if (token) {
                getApiClient().setTokens(token);
                try {
                    localStorage.setItem("hosanna_access_token", token);
                } catch {}
            }

            let activeOrg: Organization | null =
                currentCached?.organization ?? null;
            let userRole: string | undefined = currentCached?.user?.role;

            try {
                const { data: initialOrg } =
                    await authClient.organization.getFullOrganization();

                if (initialOrg) {
                    activeOrg = normalizeOrganization(initialOrg);
                } else {
                    const { data: orgs } = await authClient.organization.list();
                    if (orgs && orgs.length > 0) {
                        const storedSlug =
                            localStorage.getItem("active_org_slug");
                        const targetOrg =
                            orgs.find((o) => o.slug === storedSlug) || orgs[0];

                        await authClient.organization.setActive({
                            organizationSlug: targetOrg.slug,
                        });

                        const { data: newlyActiveOrg } =
                            await authClient.organization.getFullOrganization();
                        if (newlyActiveOrg) {
                            activeOrg = normalizeOrganization(newlyActiveOrg);
                        }
                    }
                }

                if (activeOrg) {
                    const previousSlug =
                        localStorage.getItem("active_org_slug");

                    if (previousSlug !== activeOrg.slug) {
                        localStorage.setItem("active_org_slug", activeOrg.slug);
                        clearPermissionCache();
                    }

                    const currentUserMember = activeOrg.members?.find(
                        (m) => m.userId === sessionUser.id,
                    );

                    if (currentUserMember) {
                        userRole = currentUserMember.role;
                    } else {
                        const { data: roleData } =
                            await authClient.organization.getActiveMemberRole();
                        userRole = roleData?.role || userRole;
                    }
                }
            } catch (orgErr) {
                console.warn(
                    "Could not refresh full organization details; retaining cached org:",
                    orgErr,
                );
            }

            setOrganization(activeOrg);
            const resolvedUser = {
                ...sessionUser,
                role: userRole,
            } as SessionUser;
            setUser(resolvedUser);
            setIsOfflineAuth(false);
            setCachedAuth(resolvedUser, activeOrg);
            if (userRole) {
                preloadPermissionsForRole(userRole as AppRole);
            }
        } catch (error) {
            console.warn(
                "Failed to fetch session (network/server exception):",
                error,
            );
            if (currentCached?.user) {
                setUser(currentCached.user);
                setOrganization(currentCached.organization);
                setIsOfflineAuth(true);
                if (currentCached.user.role) {
                    preloadPermissionsForRole(
                        currentCached.user.role as AppRole,
                    );
                }
            } else {
                handleClearSession();
            }
        } finally {
            setIsLoading(false);
        }
    }, [handleClearSession]);

    const setActiveOrganization = useCallback(
        async (slug: string) => {
            try {
                await authClient.organization.setActive({
                    organizationSlug: slug,
                });
                localStorage.setItem("active_org_slug", slug);
                clearPermissionCache();
                await fetchSession();
            } catch (err) {
                console.error("Failed to set active organization:", err);
            }
        },
        [fetchSession],
    );

    useEffect(() => {
        fetchSession();
    }, [fetchSession]);

    // Auto-retry session validation when network comes back online
    useEffect(() => {
        const handleOnline = () => {
            fetchSession();
        };
        window.addEventListener("online", handleOnline);
        return () => {
            window.removeEventListener("online", handleOnline);
        };
    }, [fetchSession]);

    const logout = useCallback(async () => {
        setIsLoading(true);
        try {
            await authClient.signOut();
        } catch (e) {
            console.warn("SignOut call failed:", e);
        }
        handleClearSession();
    }, [handleClearSession]);

    const contextValue = useMemo<AuthContextType>(
        () => ({
            user,
            organization,
            isAuthenticated: !!user,
            isLoading,
            isOfflineAuth,
            refetch: fetchSession,
            logout,
            setActiveOrganization,
        }),
        [
            user,
            organization,
            isLoading,
            isOfflineAuth,
            fetchSession,
            logout,
            setActiveOrganization,
        ],
    );

    return (
        <AuthContext.Provider value={contextValue}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error("useAuth must be used within an AuthProvider");
    }
    return context;
};
