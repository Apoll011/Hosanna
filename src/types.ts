

export interface Song {
  id: string; // File path inside the folder, e.g., "Worship/Digno_es_Tu.chopro"
  remoteId?: string;
  remoteUpdatedAt?: string; // Server's updatedAt (ISO string), used for optimistic concurrency
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
  folderId?: string | null;
  folder: string; // e.g. "Worship" or "" (root)
  fileName: string; // e.g. "Digno_es_Tu.chopro"
  content: string; // Raw ChordPro content
  updatedAt: number; // Timestamp of last edit
  tags?: string[];
}

export interface LibraryFolder {
  id: string;
  name: string;
  parentId: string | null;
  createdAt?: string;
  updatedAt?: string;
  songCount?: number;
}

export interface ServiceElement {
  id: string;
  type: 'welcome' | 'scripture' | 'message' | 'reading' | 'announcement' | 'custom' | 'song' | string;
  title: string;
  content?: string;
  position?: number;
  songId?: string;
  notes?: string;
  passage?: string;
}

export interface Service {
  id: string;
  name: string;
  date: string;
  elements?: ServiceElement[];
  notes?: string;
  updatedAt?: string; // Server's updatedAt (ISO string), used for optimistic concurrency
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