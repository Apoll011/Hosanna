import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'song_filters.dart';

String songSortLabel(AppLocalizations l10n, SongSort sort) {
  return switch (sort) {
    SongSort.title => l10n.songsSortTitle,
    SongSort.artist => l10n.songsSortArtist,
    SongSort.songNumber => l10n.songsSortNumber,
    SongSort.updated => l10n.songsSortUpdated,
    SongSort.added => l10n.songsSortAdded,
  };
}

/// Leading badge for a song row: shows the song number when present,
/// otherwise falls back to a music note icon.
class SongBadge extends StatelessWidget {
  const SongBadge({super.key, required this.songNumber});

  final int? songNumber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      alignment: Alignment.center,
      child: songNumber != null
          ? Text(
              '#$songNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            )
          : Icon(
              Icons.music_note,
              size: 18,
              color: colorScheme.secondary,
            ),
    );
  }
}

/// Filter button for a list AppBar, showing a badge with the number of active
/// filters.
class SongFilterButton extends StatelessWidget {
  const SongFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: l10n.songsFilter,
        onPressed: onPressed,
      ),
    );
  }
}

/// Opens the [SongFilterSheet] over the current page.
Future<void> showSongFilterSheet(
  BuildContext context, {
  required FilterSettings initial,
  required List<String> tagOptions,
  required List<({String id, String name})> folderOptions,
  required List<String> keyOptions,
  required ValueChanged<FilterSettings> onChanged,
  bool showFolderFilter = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
      ),
      child: SongFilterSheet(
        initial: initial,
        tagOptions: tagOptions,
        folderOptions: folderOptions,
        keyOptions: keyOptions,
        onChanged: onChanged,
        showFolderFilter: showFolderFilter,
      ),
    ),
  );
}

/// Filter/sort sheet.
///
/// Stateful on purpose: it keeps its own draft of [FilterSettings] and applies
/// every change to the page immediately, so chips/radios give instant visual
/// feedback while the list behind updates live.
class SongFilterSheet extends StatefulWidget {
  const SongFilterSheet({
    super.key,
    required this.initial,
    required this.tagOptions,
    required this.folderOptions,
    required this.keyOptions,
    required this.onChanged,
    this.showFolderFilter = true,
  });

  final FilterSettings initial;
  final List<String> tagOptions;
  final List<({String id, String name})> folderOptions;
  final List<String> keyOptions;
  final ValueChanged<FilterSettings> onChanged;

  /// Hidden where the surrounding page is already scoped to a folder tree
  /// (e.g. the folder browser).
  final bool showFolderFilter;

  @override
  State<SongFilterSheet> createState() => _SongFilterSheetState();
}

class _SongFilterSheetState extends State<SongFilterSheet> {
  late FilterSettings _draft = widget.initial;

  void _apply(FilterSettings next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(l10n.songsSortBy),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in SongSort.values)
                  ChoiceChip(
                    label: Text(songSortLabel(l10n, sort)),
                    selected: _draft.sort == sort,
                    onSelected: (_) => _apply(_draft.copyWith(sort: sort)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.songsSortAscending),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.songsSortDescending),
                ),
              ],
              selected: {_draft.sortAscending},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  _apply(_draft.copyWith(sortAscending: selection.first)),
            ),
            const Divider(height: 32),
            if (widget.tagOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByTag,
                clear: _draft.selectedTags.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedTags: const {})),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.songsMatchAll)),
                  ButtonSegment(value: false, label: Text(l10n.songsMatchAny)),
                ],
                selected: {_draft.tagMatchAll},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    _apply(_draft.copyWith(tagMatchAll: selection.first)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.tagOptions)
                    FilterChip(
                      label: Text(tag),
                      selected: _draft.selectedTags.contains(tag),
                      onSelected: (selected) {
                        final tags = Set<String>.of(_draft.selectedTags);
                        selected ? tags.add(tag) : tags.remove(tag);
                        _apply(_draft.copyWith(selectedTags: tags));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            if (widget.showFolderFilter && widget.folderOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByFolder,
                clear: _draft.selectedFolders.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedFolders: const {})),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final folder in widget.folderOptions)
                    FilterChip(
                      label: Text(folder.name),
                      selected: _draft.selectedFolders.contains(folder.id),
                      onSelected: (selected) {
                        final folders = Set<String>.of(_draft.selectedFolders);
                        selected
                            ? folders.add(folder.id)
                            : folders.remove(folder.id);
                        _apply(_draft.copyWith(selectedFolders: folders));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            if (widget.keyOptions.isNotEmpty) ...[
              _sectionHeader(
                l10n.songsFilterByKey,
                clear: _draft.selectedKeys.isEmpty
                    ? null
                    : () => _apply(_draft.copyWith(selectedKeys: const {})),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in widget.keyOptions)
                    FilterChip(
                      label: Text(key),
                      selected: _draft.selectedKeys.contains(key),
                      onSelected: (selected) {
                        final keys = Set<String>.of(_draft.selectedKeys);
                        selected ? keys.add(key) : keys.remove(key);
                        _apply(_draft.copyWith(selectedKeys: keys));
                      },
                    ),
                ],
              ),
              const Divider(height: 32),
            ],
            _sectionHeader(l10n.songsFilterBySongNumber),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in SongNumberFilter.values)
                  ChoiceChip(
                    label: Text(_songNumberLabel(l10n, option)),
                    selected: _draft.songNumberFilter == option,
                    onSelected: (_) =>
                        _apply(_draft.copyWith(songNumberFilter: option)),
                  ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songsSearchLyrics),
              value: _draft.searchLyrics,
              onChanged: (value) => _apply(_draft.copyWith(searchLyrics: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.songsWithChords),
              value: _draft.withChordsOnly,
              onChanged: (value) =>
                  _apply(_draft.copyWith(withChordsOnly: value)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _apply(const FilterSettings()),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.songsResetFilters),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _songNumberLabel(AppLocalizations l10n, SongNumberFilter option) {
    return switch (option) {
      SongNumberFilter.any => l10n.songsNumberAny,
      SongNumberFilter.numbered => l10n.songsNumberOnly,
      SongNumberFilter.unnumbered => l10n.songsNumberNone,
    };
  }

  Widget _sectionHeader(String title, {VoidCallback? clear}) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (clear != null)
          TextButton(
            onPressed: clear,
            child: Text(l10n.songsClear),
          ),
      ],
    );
  }
}

/// Row of removable chips under the app bar summarizing the active filters.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.settings,
    required this.folderNames,
    required this.onOpenFilters,
    required this.onRemoveTag,
    required this.onRemoveFolder,
    required this.onRemoveKey,
    required this.onSongNumberAny,
    required this.onLyricsOff,
    required this.onChordsOff,
    required this.onReset,
  });

  final FilterSettings settings;
  final Map<String, String> folderNames;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onRemoveFolder;
  final ValueChanged<String> onRemoveKey;
  final VoidCallback onSongNumberAny;
  final VoidCallback onLyricsOff;
  final VoidCallback onChordsOff;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (settings.sort != SongSort.title || !settings.sortAscending) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.sort, size: 18),
          label: Text(
            '${songSortLabel(l10n, settings.sort)} '
            '${settings.sortAscending ? '↑' : '↓'}',
          ),
          onPressed: onOpenFilters,
        ),
      );
    }
    for (final tag in settings.selectedTags) {
      chips.add(
        InputChip(
          label: Text(tag),
          onDeleted: () => onRemoveTag(tag),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    for (final folderId in settings.selectedFolders) {
      chips.add(
        InputChip(
          label: Text(folderNames[folderId] ?? folderId),
          onDeleted: () => onRemoveFolder(folderId),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    for (final key in settings.selectedKeys) {
      chips.add(
        InputChip(
          label: Text(key),
          onDeleted: () => onRemoveKey(key),
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.songNumberFilter != SongNumberFilter.any) {
      chips.add(
        InputChip(
          label: Text(
            settings.songNumberFilter == SongNumberFilter.numbered
                ? l10n.songsNumberOnly
                : l10n.songsNumberNone,
          ),
          onDeleted: onSongNumberAny,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.searchLyrics) {
      chips.add(
        InputChip(
          label: Text(l10n.songsSearchLyrics),
          onDeleted: onLyricsOff,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    if (settings.withChordsOnly) {
      chips.add(
        InputChip(
          label: Text(l10n.songsWithChords),
          onDeleted: onChordsOff,
          deleteButtonTooltipMessage: l10n.commonDelete,
        ),
      );
    }
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.restart_alt, size: 18),
        label: Text(l10n.songsResetFilters),
        onPressed: onReset,
      ),
    );

    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}
