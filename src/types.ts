import type {
    Folder as SharedFolder,
    ParsedSong as SharedParsedSong,
    Service as SharedService,
    ServiceElement as SharedServiceElement,
    Song as SharedSong,
} from "@hosanna/shared";

export type Song = SharedParsedSong;
export type RawSong = SharedSong;
export type ParsedSong = SharedParsedSong;

export type Folder = SharedFolder;
export type ServiceElement = SharedServiceElement;
export type Service = SharedService;

export interface VirtualFile {
    path: string;
    content: string;
    updatedAt: number;
}

export type ThemeType = "light" | "dark" | "system";
