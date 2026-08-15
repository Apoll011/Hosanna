import { createAuthClient } from "better-auth/client";
import {
  organizationClient,
  twoFactorClient,
} from "better-auth/client/plugins";
import { ac, roles } from "./permissions";

export const getAuthBaseUrl = (): string => {
  try {
    const stored = localStorage.getItem("cp_server_url");
    if (stored) {
      const parsed = JSON.parse(stored);
      if (parsed && typeof parsed === "string" && parsed.trim() !== "") {
        return parsed.trim().replace(/\/api\/?$/, "");
      }
    }
  } catch {
    // Ignore storage parse error
  }

  const envUrl = import.meta.env.VITE_API_URL;
  if (envUrl && typeof envUrl === "string" && envUrl.trim() !== "") {
    return envUrl.trim().replace(/\/api\/?$/, "");
  }

  return typeof window !== "undefined"
    ? window.location.origin
    : "http://localhost:3000";
};

export const createHosannaAuthClient = (customBaseURL?: string) => {
  const baseURL = (customBaseURL || getAuthBaseUrl()).replace(/\/api\/?$/, "");
  return createAuthClient({
    baseURL,
    fetchOptions: {
      credentials: "include",
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
};

export let authClient = createHosannaAuthClient();

export const reconfigureAuthClient = (newBaseUrl?: string) => {
  authClient = createHosannaAuthClient(newBaseUrl);
  return authClient;
};

export type Session = typeof authClient.$Infer.Session;
export type User = typeof authClient.$Infer.Session.user;
