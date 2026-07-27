

const TOKEN_QUERY_KEYS = ['token', 'access_token', 'accessToken', 'bearer'];

export type ApiErrorDetails = { path: string; message: string };

export class ApiError extends Error {
  code: string;
  details?: ApiErrorDetails[];
  status: number;

  constructor(status: number, code: string, message: string, details?: ApiErrorDetails[]) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export interface LibraryFolder {
  id: string;
  name: string;
  parentId: string | null;
  createdAt?: string;
  updatedAt?: string;
  songCount?: number;
}

export interface ApiSong {
  id: string;
  title: string;
  artist?: string;
  content: string;
  folderId: string | null;
  path: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface SongsListResponse {
  songs: ApiSong[];
  total: number;
  page: number;
  totalPages: number;
}

export interface ApiServiceSong {
  songId: string;
  notes?: string;
  position: number;
}

export interface ApiService {
  id: string;
  name: string;
  date: string;
  notes?: string;
  songIds: string[];
  songs: ApiServiceSong[];
  songNotes?: Record<string, string>;
  createdAt: string;
  updatedAt: string;
}

const trimTrailingSlash = (value: string) => value.replace(/\/$/, '');

export const buildApiUrl = (baseUrl: string, path: string) => {
  const normalizedBase = trimTrailingSlash(baseUrl.trim());
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${normalizedBase}${normalizedPath}`;
};

export const extractMusicianToken = (value: string): string => {
  const trimmed = value.trim();
  if (!trimmed) return '';

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
    return url.origin
  } catch {
    return null
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

type RequestOptions = {
  token?: string;
  body?: unknown;
  method?: string;
  signal?: AbortSignal;
};

export async function apiRequest<T>(baseUrl: string, path: string, options: RequestOptions = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (options.token) {
    headers.Authorization = `Bearer ${options.token}`;
  }

  const response = await fetch(buildApiUrl(baseUrl, path), {
    method: options.method || (options.body ? 'POST' : 'GET'),
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    signal: options.signal,
  });

  if (!response.ok) {
    let errorBody: any = null;
    try {
      errorBody = await response.json();
    } catch {
      errorBody = null;
    }

    const error = errorBody?.error || {};
    throw new ApiError(
      response.status,
      error.code || `HTTP_${response.status}`,
      error.message || response.statusText || 'Request failed',
      error.details,
    );
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const contentType = response.headers.get('content-type') || '';
  if (contentType.includes('application/json')) {
    return response.json() as Promise<T>;
  }

  return (await response.text()) as T;
}

export async function getFoldersFlat(baseUrl: string, token?: string): Promise<LibraryFolder[]> {
  return apiRequest<LibraryFolder[]>(baseUrl, '/api/folders/flat', {
    token,
    method: 'GET',
  });
}

export async function getSongs(baseUrl: string, token?: string, query: Record<string, string | number | undefined> = {}): Promise<SongsListResponse> {
  const searchParams = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value === undefined || value === '') return;
    searchParams.set(key, String(value));
  });

  const suffix = searchParams.toString() ? `?${searchParams.toString()}` : '';
  return apiRequest<SongsListResponse>(baseUrl, `/api/songs${suffix}`, {
    token,
    method: 'GET',
  });
}

export async function getServices(baseUrl: string, token?: string): Promise<ApiService[]> {
  return apiRequest<ApiService[]>(baseUrl, '/api/services', {
    token,
    method: 'GET',
  });
}

export async function createSong(
  baseUrl: string,
  token: string | undefined,
  body: { title: string; artist?: string; content: string; folderId?: string | null; path?: string; tags?: string[] }
): Promise<ApiSong> {
  return apiRequest<ApiSong>(baseUrl, '/api/songs', {
    token,
    method: 'POST',
    body,
  });
}

export async function updateSong(
  baseUrl: string,
  token: string | undefined,
  songId: string,
  body: { updatedAt: string; title?: string; content?: string; folderId?: string | null; tags?: string[]; newTitle?: string; newPath?: string }
): Promise<ApiSong> {
  return apiRequest<ApiSong>(baseUrl, `/api/songs/${songId}`, {
    token,
    method: 'PUT',
    body,
  });
}

export async function deleteSong(baseUrl: string, token: string | undefined, songId: string): Promise<void> {
  await apiRequest<void>(baseUrl, `/api/songs/${songId}`, {
    token,
    method: 'DELETE',
  });
}

export async function createService(
  baseUrl: string,
  token: string | undefined,
  body: {
    name: string;
    date: string;
    notes?: string;
    songIds?: string[];
    songNotes?: Record<string, string>;
    songs?: Array<{ songId: string; notes?: string }>;
  }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, '/api/services', {
    token,
    method: 'POST',
    body,
  });
}

export async function updateServiceApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  body: {
    updatedAt: string;
    name?: string;
    date?: string;
    notes?: string;
    songIds?: string[];
    songNotes?: Record<string, string>;
    songs?: Array<{ songId: string; notes?: string }>;
  }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}`, {
    token,
    method: 'PUT',
    body,
  });
}

export async function deleteService(baseUrl: string, token: string | undefined, serviceId: string): Promise<void> {
  await apiRequest<void>(baseUrl, `/api/services/${serviceId}`, {
    token,
    method: 'DELETE',
  });
}

export async function addSongToServiceApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  body: { updatedAt: string; songId: string; notes?: string; position?: number }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/songs`, {
    token,
    method: 'POST',
    body,
  });
}

export async function removeSongFromServiceApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  songId: string,
  body: { updatedAt: string }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/songs/${songId}`, {
    token,
    method: 'DELETE',
    body,
  });
}

export async function reorderServiceSongsApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  body: { updatedAt: string; orderedSongIds: string[] }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/songs/reorder`, {
    token,
    method: 'PUT',
    body,
  });
}

export async function moveServiceSongApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  songId: string,
  body: { updatedAt: string; targetIndex: number }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/songs/${songId}/move`, {
    token,
    method: 'PUT',
    body,
  });
}

export async function updateServiceNotesApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  body: { updatedAt: string; notes: string }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/notes`, {
    token,
    method: 'PUT',
    body,
  });
}

export async function updateServiceSongNotesApi(
  baseUrl: string,
  token: string | undefined,
  serviceId: string,
  songId: string,
  body: { updatedAt: string; notes: string }
): Promise<ApiService> {
  return apiRequest<ApiService>(baseUrl, `/api/services/${serviceId}/songs/${songId}/notes`, {
    token,
    method: 'PUT',
    body,
  });
}