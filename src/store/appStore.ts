/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useAppStore as useWebStore } from './webAppStore';
import { useAppStore as useTauriStore } from './tauriAppStore';

// Detect Tauri
const isTauri = typeof window !== 'undefined' && !!(window as any).__TAURI_INTERNALS__;

export const useAppStore = ((selector?: any) => {
  const store = isTauri ? useTauriStore : useWebStore;
  return store(selector);
}) as typeof useWebStore;

// Map all properties of useWebStore to useAppStore (like getState, setState, etc)
Object.assign(useAppStore, isTauri ? useTauriStore : useWebStore);

// Initialization for Tauri
if (isTauri) {
    (useTauriStore.getState() as any).initDb?.().catch(console.error);
}
