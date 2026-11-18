import 'package:flutter/material.dart';

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

/// Lucide ids from Studio → closest Material icons.
const Map<String, IconData> _folderIcons = {
  'music': Icons.music_note_rounded,
  'heart': Icons.favorite_rounded,
  'star': Icons.star_rounded,
  'book-open': Icons.menu_book_rounded,
  'bookmark': Icons.bookmark_rounded,
  'sun': Icons.wb_sunny_rounded,
  'moon': Icons.dark_mode_rounded,
  'sparkles': Icons.auto_awesome_rounded,
  'flame': Icons.local_fire_department_rounded,
  'cross': Icons.church_rounded,
  'church': Icons.church_rounded,
  'mic': Icons.mic_rounded,
  'radio': Icons.radio_rounded,
  'disc': Icons.album_rounded,
  'headphones': Icons.headphones_rounded,
  'guitar': Icons.music_note_rounded,
  'bell': Icons.notifications_rounded,
  'archive': Icons.archive_rounded,
  'tag': Icons.label_rounded,
  'hash': Icons.tag_rounded,
  'smile': Icons.sentiment_satisfied_alt_rounded,
  'shield': Icons.shield_rounded,
  'award': Icons.emoji_events_rounded,
  'crown': Icons.workspace_premium_rounded,
  'compass': Icons.explore_rounded,
  'map-pin': Icons.place_rounded,
  'calendar': Icons.calendar_month_rounded,
  'layers': Icons.layers_rounded,
  'folder-open': Icons.folder_open_rounded,
};

/// Resolves a Studio color id to a [Color]. Falls back to [kFolderDefaultColor].
Color folderColorOf(String? colorId) {
  if (colorId == null || colorId.isEmpty || colorId == _defaultColorId) {
    return kFolderDefaultColor;
  }
  return _folderColors[colorId] ?? kFolderDefaultColor;
}

/// Resolves a Studio icon id to a Material [IconData].
///
/// When [iconId] is default/null, [hasContents] picks an open vs outlined
/// folder — matching Studio's FolderOpen / Folder default behaviour.
IconData folderIconOf(String? iconId, {bool hasContents = false}) {
  if (iconId == null || iconId.isEmpty || iconId == _defaultIconId) {
    return hasContents ? Icons.folder_rounded : Icons.folder_outlined;
  }
  return _folderIcons[iconId] ??
      (hasContents ? Icons.folder_rounded : Icons.folder_outlined);
}
