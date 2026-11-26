import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Folder icon + color ids shared with Studio (`folderCustomization.ts`).
///
/// Values are stored on [FolderRow.icon] / [FolderRow.color] and synced from
/// the API; unknown ids fall back to the default folder look.

const _defaultColorId = 'default';
const _defaultIconId = 'default';

/// Brand primary used by Studio's default folder swatch (`#0284c7`).
const Color kFolderDefaultColor = Color(0xFF0284C7);

const Map<String, Color> _folderColors = {
  'default': kFolderDefaultColor,
  'red': Color(0xFFEF4444),
  'orange': Color(0xFFF97316),
  'amber': Color(0xFFF59E0B),
  'yellow': Color(0xFFEAB308),
  'emerald': Color(0xFF10B981),
  'green': Color(0xFF22C55E),
  'teal': Color(0xFF14B8A6),
  'cyan': Color(0xFF06B6D4),
  'sky': Color(0xFF0EA5E9),
  'blue': Color(0xFF3B82F6),
  'indigo': Color(0xFF6366F1),
  'violet': Color(0xFF8B5CF6),
  'purple': Color(0xFFA855F7),
  'fuchsia': Color(0xFFD946EF),
  'pink': Color(0xFFEC4899),
  'rose': Color(0xFFF43F5E),
  'slate': Color(0xFF64748B),
};

/// Lucide ids from Studio (`folderCustomization.ts`).
const Map<String, IconData> _folderIcons = {
  'music': LucideIcons.music,
  'heart': LucideIcons.heart,
  'star': LucideIcons.star,
  'book-open': LucideIcons.bookOpen,
  'bookmark': LucideIcons.bookmark,
  'sun': LucideIcons.sun,
  'moon': LucideIcons.moon,
  'sparkles': LucideIcons.sparkles,
  'flame': LucideIcons.flame,
  'cross': LucideIcons.cross,
  'church': LucideIcons.church,
  'mic': LucideIcons.mic,
  'radio': LucideIcons.radio,
  'disc': LucideIcons.disc,
  'headphones': LucideIcons.headphones,
  'guitar': LucideIcons.guitar,
  'bell': LucideIcons.bell,
  'archive': LucideIcons.archive,
  'tag': LucideIcons.tag,
  'hash': LucideIcons.hash,
  'smile': LucideIcons.smile,
  'shield': LucideIcons.shield,
  'award': LucideIcons.award,
  'crown': LucideIcons.crown,
  'compass': LucideIcons.compass,
  'map-pin': LucideIcons.mapPin,
  'calendar': LucideIcons.calendar,
  'layers': LucideIcons.layers,
  'folder-open': LucideIcons.folderOpen,
};

/// Resolves a Studio color id to a [Color]. Falls back to [kFolderDefaultColor].
Color folderColorOf(String? colorId) {
  if (colorId == null || colorId.isEmpty || colorId == _defaultColorId) {
    return kFolderDefaultColor;
  }
  return _folderColors[colorId] ?? kFolderDefaultColor;
}

/// Resolves a Studio icon id to an [IconData].
///
/// When [iconId] is default/null, [hasContents] picks an open vs closed folder.
IconData folderIconOf(String? iconId, {bool hasContents = false}) {
  if (iconId == null || iconId.isEmpty || iconId == _defaultIconId) {
    return hasContents ? LucideIcons.folderOpen : LucideIcons.folder;
  }
  return _folderIcons[iconId] ??
      (hasContents ? LucideIcons.folderOpen : LucideIcons.folder);
}
