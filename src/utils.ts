const TOKEN_QUERY_KEYS = ["token", "access_token", "accessToken", "bearer"];

export const extractMusicianToken = (value: string): string => {
    const trimmed = value.trim();
    if (!trimmed) return "";

    const bearerMatch = trimmed.match(/^Bearer\s+(.+)$/i);
    if (bearerMatch?.[1]) {
        return bearerMatch[1].trim();
    }

    try {
        const url = new URL(trimmed);
        for (const key of TOKEN_QUERY_KEYS) {
            const token = url.searchParams.get(key);
            if (token) {
                return token.trim();
            }
        }
    } catch {
        // Not a URL, fall through to raw token handling.
    }

    return trimmed;
};

export const extractMusicianURL = (value: string): string | null => {
    const trimmed = value.trim();
    if (!trimmed) return null;

    try {
        const url = new URL(trimmed);
        return url.origin;
    } catch {
        return null;
    }
};

export const isMusicianAccessUrl = (value: string): boolean => {
    const trimmed = value.trim();
    if (!trimmed) return false;

    try {
        const url = new URL(trimmed);
        return TOKEN_QUERY_KEYS.some((key) => url.searchParams.has(key));
    } catch {
        return false;
    }
};
