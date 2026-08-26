/**
 * React hooks for RBAC permission and role checks in Hosanna.
 *
 * @module permissions/client
 */

import { useEffect, useMemo, useRef, useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { authClient } from "../authClient";
import {
    statement,
    type PermissionRequest,
    type PermissionString,
    type Resource,
} from "./permission";
import { roles, isPermissionAllowedForRole, type AppRole } from "./roles";

function getCachedUserRole(): AppRole | null {
    try {
        const raw = typeof localStorage !== "undefined" ? localStorage.getItem("hosanna_auth_cache") : null;
        if (!raw) return null;
        const parsed = JSON.parse(raw);
        return (parsed?.user?.role as AppRole) ?? null;
    } catch {
        return null;
    }
}

// ---------------------------------------------------------------------------
// 1. Core Caching & Promise Deduplication Layer
// ---------------------------------------------------------------------------

interface PermResult {
    granted: boolean;
    loading: boolean;
    error: Error | null;
}

const DEFAULT_RESULT: PermResult = {
    granted: false,
    loading: true,
    error: null,
};

// Stores resolved booleans
const permCache = new Map<string, boolean>();
// Stores in-flight Promises so concurrent components share the exact same network request
const pendingPerms = new Map<string, Promise<boolean>>();

export function clearPermissionCache(): void {
    permCache.clear();
    pendingPerms.clear();
}

// ---------------------------------------------------------------------------
// 2. Batching Helpers
// ---------------------------------------------------------------------------

/**
 * Groups ["song.create", "service.create"]
 * into { song: ["create"], service: ["create"] }
 */
function groupPermissions(permissions: PermissionString[]): PermissionRequest {
    const grouped = {} as Record<Resource, string[]>;
    for (const perm of permissions) {
        const dotIndex = perm.indexOf(".");
        const resource = perm.slice(0, dotIndex) as Resource;
        const action = perm.slice(dotIndex + 1);

        if (!grouped[resource]) grouped[resource] = [];
        if (!grouped[resource].includes(action)) grouped[resource].push(action);
    }
    return grouped as PermissionRequest;
}

/** Creates a deterministic string key for caching */
function getCacheKey(permissions: PermissionString[]): string {
    if (permissions.length === 0) return "empty";
    const grouped = groupPermissions(permissions);
    return Object.keys(grouped)
        .sort()
        .map((res) => `${res}:${grouped[res as Resource]!.sort().join(",")}`)
        .join("|");
}

// ---------------------------------------------------------------------------
// 3. Super Efficient Fetchers
// ---------------------------------------------------------------------------

/**
 * Core fetcher. Batches permissions, deduplicates requests, and pre-populates cache.
 */
function fetchPermissionsBatch(
    permissions: PermissionString[],
): Promise<boolean> {
    if (permissions.length === 0) return Promise.resolve(true);

    const cacheKey = getCacheKey(permissions);

    if (permCache.has(cacheKey))
        return Promise.resolve(permCache.get(cacheKey)!);

    if (pendingPerms.has(cacheKey)) return pendingPerms.get(cacheKey)!;

    const promise = authClient.organization
        .hasPermission({
            permissions: groupPermissions(permissions) as Record<
                string,
                string[]
            >,
        })
        .then(({ data, error }) => {
            if (error)
                throw new Error(error.message ?? "Permission check failed");
            const granted = data?.success ?? false;

            permCache.set(cacheKey, granted);

            if (granted) {
                permissions.forEach((p) =>
                    permCache.set(getCacheKey([p]), true),
                );
            }

            return granted;
        })
        .catch((err) => {
            // If network request failed (e.g. offline mode or temporary server failure), fallback to static cached role definitions
            const cachedRole = getCachedUserRole();
            if (cachedRole) {
                const granted = permissions.every((p) =>
                    isPermissionAllowedForRole(cachedRole, p),
                );
                permCache.set(cacheKey, granted);
                if (granted) {
                    permissions.forEach((p) =>
                        permCache.set(getCacheKey([p]), true),
                    );
                }
                return granted;
            }
            throw err;
        })
        .finally(() => {
            pendingPerms.delete(cacheKey);
        });

    pendingPerms.set(cacheKey, promise);
    return promise;
}

// ---------------------------------------------------------------------------
// 4. React Hooks
// ---------------------------------------------------------------------------

/** Checks a single permission. */
export function useCan(permission: PermissionString): PermResult {
    return useCanAll(useMemo(() => [permission], [permission]));
}

export function useCannot(permission: PermissionString): {
    denied: boolean;
    loading: boolean;
    error: Error | null;
} {
    const { granted, loading, error } = useCan(permission);
    return { denied: !granted, loading, error };
}

/**
 * Checks if ALL permissions are granted.
 */
export function useCanAll(permissions: PermissionString[]): PermResult {
    const [result, setResult] = useState<PermResult>(DEFAULT_RESULT);
    const mounted = useRef(true);

    const cacheKey = useMemo(() => getCacheKey(permissions), [permissions]);

    useEffect(() => {
        mounted.current = true;

        if (permCache.has(cacheKey)) {
            setResult({
                granted: permCache.get(cacheKey)!,
                loading: false,
                error: null,
            });
            return;
        }

        setResult({ granted: false, loading: true, error: null });

        fetchPermissionsBatch(permissions)
            .then((granted) => {
                if (mounted.current)
                    setResult({ granted, loading: false, error: null });
            })
            .catch((error) => {
                if (mounted.current)
                    setResult({ granted: false, loading: false, error });
            });

        return () => {
            mounted.current = false;
        };
    }, [cacheKey, permissions]);

    return result;
}

/**
 * Checks if ANY permissions are granted.
 */
export function useCanAny(permissions: PermissionString[]): PermResult {
    const [result, setResult] = useState<PermResult>(DEFAULT_RESULT);
    const mounted = useRef(true);

    const cacheKey = useMemo(() => getCacheKey(permissions), [permissions]);

    useEffect(() => {
        mounted.current = true;

        const checkAny = async () => {
            for (const p of permissions) {
                if (permCache.get(getCacheKey([p])) === true) {
                    if (mounted.current)
                        setResult({
                            granted: true,
                            loading: false,
                            error: null,
                        });
                    return;
                }
            }

            setResult({ granted: false, loading: true, error: null });

            try {
                const results = await Promise.all(
                    permissions.map((p) => fetchPermissionsBatch([p])),
                );
                const granted = results.some(Boolean);

                if (mounted.current)
                    setResult({ granted, loading: false, error: null });
            } catch (error) {
                if (mounted.current)
                    setResult({
                        granted: false,
                        loading: false,
                        error: error as Error,
                    });
            }
        };

        checkAny();

        return () => {
            mounted.current = false;
        };
    }, [cacheKey, permissions]);

    return result;
}

// ---------------------------------------------------------------------------
// Role Hooks
// ---------------------------------------------------------------------------

export function useActiveRole(): {
    role: AppRole | null;
    loading: boolean;
    error: Error | null;
} {
    const { user, isLoading } = useAuth();

    return {
        role: (user?.role as AppRole) ?? null,
        loading: isLoading,
        error: null,
    };
}

export function useRole(role: AppRole) {
    const { role: activeRole, loading, error } = useActiveRole();
    return { matched: activeRole === role, loading, error };
}

export function useAnyRole(...allowedRoles: AppRole[]) {
    const { role: activeRole, loading, error } = useActiveRole();
    return {
        matched: activeRole ? allowedRoles.includes(activeRole) : false,
        loading,
        error,
    };
}

const ALL_PERMISSIONS: PermissionString[] = Object.entries(statement).flatMap(
    ([resource, actions]) =>
        (actions as readonly string[]).map(
            (action) => `${resource}.${action}` as PermissionString,
        ),
);

export function preloadPermissionsForRole(role: AppRole | null): void {
    if (!role || !(role in roles)) return;

    const roleConfig = roles[role];

    ALL_PERMISSIONS.forEach((perm) => {
        const dotIndex = perm.indexOf(".");
        const resource = perm.slice(
            0,
            dotIndex,
        ) as keyof typeof roleConfig.statements;
        const action = perm.slice(dotIndex + 1);

        const allowedActions = roleConfig.statements[resource];
        const isGranted =
            Array.isArray(allowedActions) && allowedActions.includes(action);

        const cacheKey = getCacheKey([perm]);
        permCache.set(cacheKey, isGranted);
    });
}

export function usePreloadPermissions(): { isReady: boolean } {
    const { role, loading } = useActiveRole();

    useEffect(() => {
        if (role && !loading) {
            preloadPermissionsForRole(role);
        }
    }, [role, loading]);

    return { isReady: !loading && role !== null };
}
