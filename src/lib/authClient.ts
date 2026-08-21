import { createAuthClient } from "better-auth/client";
import {
    organizationClient,
    twoFactorClient,
} from "better-auth/client/plugins";
import { ac, roles } from "./permissions";

export const API_BASE_URL =
    (import.meta.env.VITE_API_URL as string | undefined)
        ?.trim()
        .replace(/\/api\/?$/, "") ||
    (typeof window !== "undefined"
        ? window.location.origin
        : "http://localhost:3000");

const AUTH_TOKEN_KEY = "hosanna_access_token";

export const authClient = createAuthClient({
    baseURL: API_BASE_URL,
    fetchOptions: {
        credentials: "include",
        onRequest: (context) => {
            if (typeof localStorage !== "undefined") {
                const token = localStorage.getItem(AUTH_TOKEN_KEY);
                if (token) {
                    context.headers.set("Authorization", `Bearer ${token}`);
                }
            }
        },
        onResponse: (context) => {
            const token = context.response.headers.get("set-auth-token");
            if (token && typeof localStorage !== "undefined") {
                localStorage.setItem(AUTH_TOKEN_KEY, token);
            }
        },
    },
    plugins: [
        twoFactorClient({
            twoFactorPage: "/two-factor",
        }),
        organizationClient({
            ac,
            roles,
            teams: {
                enabled: true,
            },
        }),
    ],
});

export type Session = typeof authClient.$Infer.Session;
export type User = typeof authClient.$Infer.Session.user;
