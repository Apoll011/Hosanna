/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface Song {
  id: string; // File path inside the folder, e.g., "Worship/Digno_es_Tu.chopro"
  title: string;
  subtitle?: string;
  artist?: string;
  composer?: string;
  copyright?: string;
  album?: string;
  key?: string;
  tempo?: string;
  capo?: string;
  songNumber?: string;
  comments?: string;
  folder: string; // e.g. "Worship" or "" (root)
  fileName: string; // e.g. "Digno_es_Tu.chopro"
  content: string; // Raw ChordPro content
  updatedAt: number; // Timestamp of last edit
}

export interface Service {
  id: string;
  name: string;
  date: string;
  songIds: string[]; // Ordered list of song IDs
  notes?: string;
  songNotes?: Record<string, string>; // Map of index to custom notes
}

export interface VirtualFile {
  path: string; // Relative path, e.g., "Worship/Digno_es_Tu.chopro"
  content: string;
  updatedAt: number;
}

export interface SyncConflict {
  path: string;
  localContent: string;
  incomingContent: string;
  localTime: number;
  incomingTime: number;
}

export interface SyncReport {
  added: string[];
  modified: string[];
  deleted: string[];
  conflicts: SyncConflict[];
}

export type ThemeType = 'light' | 'dark' | 'system';
