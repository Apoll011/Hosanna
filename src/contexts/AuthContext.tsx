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
        const raw = localStorage.getItem(AUTH_CACHE_KEY);
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

    const handleClearSession = useCallback(() => {
        setUser(null);
        setOrganization(null);
        clearCachedAuth();
        try {
            localStorage.removeItem("active_org_slug");
        } catch {}
        getApiClient().setTokens(null);
        clearPermissionCache();
        setIsLoading(false);
    }, []);

    const fetchSession = useCallback(async () => {
        // Only show loading spinner if there's no cached user to display
        if (!getCachedAuth()) {
            setIsLoading(true);
        }

        try {
            const { data: sessionData, error: sessionError } =
                await authClient.getSession();
            const sessionUser = sessionData?.user;

            if (!sessionUser || sessionError) {
                return handleClearSession();
            }

            // Sync session token with shared ApiClient if available
            const token = (sessionData as { session?: { token?: string } })
                ?.session?.token;
            if (token) {
                getApiClient().setTokens(token);
            }

            let activeOrg: Organization | null = null;
            let userRole: string | undefined = undefined;

            const { data: initialOrg } =
                await authClient.organization.getFullOrganization();

            if (initialOrg) {
                activeOrg = normalizeOrganization(initialOrg);
            } else {
                const { data: orgs } = await authClient.organization.list();
                if (orgs && orgs.length > 0) {
                    const storedSlug = localStorage.getItem("active_org_slug");
                    const targetOrg =
                        orgs.find((o) => o.slug === storedSlug) || orgs[0];

                    await authClient.organization.setActive({
                        organizationSlug: targetOrg.slug,
                    });

                    const { data: newlyActiveOrg } =
                        await authClient.organization.getFullOrganization();
                    activeOrg = normalizeOrganization(newlyActiveOrg);
                }
            }

            if (activeOrg) {
                const previousSlug = localStorage.getItem("active_org_slug");

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
                    userRole = roleData?.role || undefined;
                }
            } else {
                localStorage.removeItem("active_org_slug");
                clearPermissionCache();
            }

            setOrganization(activeOrg);
            const resolvedUser = {
                ...sessionUser,
                role: userRole,
            } as SessionUser;
            setUser(resolvedUser);
            setCachedAuth(resolvedUser, activeOrg);
        } catch (error) {
            console.error("Failed to fetch session:", error);
            handleClearSession();
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
            refetch: fetchSession,
            logout,
            setActiveOrganization,
        }),
        [
            user,
            organization,
            isLoading,
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
