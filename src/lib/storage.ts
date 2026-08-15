// src/lib/storage.ts
/**
 * Asynchronous IndexedDB storage engine for Hosanna.
 * Replaces synchronous localStorage to prevent UI main-thread blocking
 * and bypass storage quota limits (5MB).
 */

const DB_NAME = "hosanna_db";
const DB_VERSION = 1;
const STORE_NAME = "keyval";

let dbPromise: Promise<IDBDatabase> | null = null;

function getDB(): Promise<IDBDatabase> {
    if (!dbPromise) {
        dbPromise = new Promise((resolve, reject) => {
            if (typeof window === "undefined" || !("indexedDB" in window)) {
                reject(
                    new Error("IndexedDB is not supported in this environment"),
                );
                return;
            }

            const request = indexedDB.open(DB_NAME, DB_VERSION);

            request.onupgradeneeded = (event) => {
                const db = (event.target as IDBOpenDBRequest).result;
                if (!db.objectStoreNames.contains(STORE_NAME)) {
                    db.createObjectStore(STORE_NAME);
                }
            };

            request.onsuccess = (event) => {
                const db = (event.target as IDBOpenDBRequest).result;
                resolve(db);
            };

            request.onerror = (event) => {
                console.error(
                    "IndexedDB open error:",
                    (event.target as IDBOpenDBRequest).error,
                );
                reject((event.target as IDBOpenDBRequest).error);
            };
        });
    }
    return dbPromise;
}

/**
 * Get an item from IndexedDB with transparent fallback and automatic migration from localStorage.
 */
export async function getStorageItem<T>(
    key: string,
    defaultValue: T,
): Promise<T> {
    try {
        const db = await getDB();
        const result = await new Promise<T | undefined>((resolve, reject) => {
            const transaction = db.transaction(STORE_NAME, "readonly");
            const store = transaction.objectStore(STORE_NAME);
            const request = store.get(key);

            request.onsuccess = () => resolve(request.result as T | undefined);
            request.onerror = () => reject(request.error);
        });

        if (result !== undefined && result !== null) {
            return result;
        }

        // Attempt migration from localStorage if item wasn't in IndexedDB
        try {
            const localVal = localStorage.getItem(key);
            if (localVal !== null) {
                const parsed = JSON.parse(localVal) as T;
                // Copy to IndexedDB asynchronously
                await setStorageItemImmediate(key, parsed);
                // Clean up localStorage to free up synchronous quota
                localStorage.removeItem(key);
                return parsed;
            }
        } catch {
            // Ignore localStorage read errors
        }

        return defaultValue;
    } catch (error) {
        console.warn(`Failed to read ${key} from IndexedDB:`, error);
        // Fallback to localStorage on IndexedDB error
        try {
            const item = localStorage.getItem(key);
            return item ? (JSON.parse(item) as T) : defaultValue;
        } catch {
            return defaultValue;
        }
    }
}

/**
 * Immediately save an item to IndexedDB.
 */
export async function setStorageItemImmediate(
    key: string,
    value: unknown,
): Promise<void> {
    try {
        const db = await getDB();
        await new Promise<void>((resolve, reject) => {
            const transaction = db.transaction(STORE_NAME, "readwrite");
            const store = transaction.objectStore(STORE_NAME);
            const request = store.put(value, key);

            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    } catch (error) {
        console.warn(`Failed to write ${key} to IndexedDB:`, error);
        // Fallback to localStorage
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (e) {
            console.error(
                `Fallback write to localStorage failed for ${key}`,
                e,
            );
        }
    }
}

const storageTimers: Record<string, ReturnType<typeof setTimeout>> = {};

/**
 * Save an item to IndexedDB debounced to prevent disk I/O thrashing during frequent updates.
 */
export function setStorageItemDebounced(
    key: string,
    value: unknown,
    delay = 300,
): void {
    if (storageTimers[key]) clearTimeout(storageTimers[key]);
    storageTimers[key] = setTimeout(() => {
        setStorageItemImmediate(key, value).catch((err) => {
            console.warn(
                `Debounced write to IndexedDB failed for key ${key}`,
                err,
            );
        });
    }, delay);
}

/**
 * Remove an item from IndexedDB and localStorage.
 */
export async function removeStorageItem(key: string): Promise<void> {
    try {
        const db = await getDB();
        await new Promise<void>((resolve, reject) => {
            const transaction = db.transaction(STORE_NAME, "readwrite");
            const store = transaction.objectStore(STORE_NAME);
            const request = store.delete(key);

            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    } catch (error) {
        console.warn(`Failed to remove ${key} from IndexedDB:`, error);
    } finally {
        try {
            localStorage.removeItem(key);
        } catch {}
    }
}

/**
 * Clear all data in IndexedDB and localStorage cache keys.
 */
export async function clearStorage(): Promise<void> {
    try {
        const db = await getDB();
        await new Promise<void>((resolve, reject) => {
            const transaction = db.transaction(STORE_NAME, "readwrite");
            const store = transaction.objectStore(STORE_NAME);
            const request = store.clear();

            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    } catch (error) {
        console.warn("Failed to clear IndexedDB:", error);
    } finally {
        const keysToRemove = [
            "cp_virtual_files",
            "cp_songs_cache",
            "cp_services",
            "cp_folders",
            "cp_favorites",
            "cp_recently_played",
            "cp_last_sync_time",
            "cp_last_sync_timestamps",
            "cp_theme",
            "cp_font_size",
            "cp_show_chords",
            "cp_show_diagrams",
            "cp_keep_awake",
            "cp_slow_down_repeat",
            "cp_musician_mode",
            "cp_instrument",
            "cp_two_column_layout",
            "cp_source_folder",
        ];
        keysToRemove.forEach((k) => {
            try {
                localStorage.removeItem(k);
            } catch {}
        });
    }
}
