import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import 'line_renderers.dart';
import 'render_model.dart';

/// One song section (verse, chorus, bridge, tab, grid, comment, new song).
class SectionView extends StatelessWidget {
  const SectionView({
    super.key,
    required this.section,
    required this.options,
    this.colorBackground = false,
  });

  final PreparedSection section;
  final LineRenderOptions options;

  /// Tints verse/chorus/bridge backgrounds with their accent colour.
  final bool colorBackground;

  @override
  Widget build(BuildContext context) {
    return switch (section.type) {
      'new_song' => const _NewSongDivider(),
      'grid' => _GridSection(section: section, options: options),
      'tab' => _TabSection(section: section, fontSize: options.fontSize),
      'comment' => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in section.lines)
              LineRenderer(line: line, options: options),
          ],
        ),
      ),
      _ => _LyricSection(
        section: section,
        options: options,
        colorBackground: colorBackground,
      ),
    };
  }
}

class _NewSongDivider extends StatelessWidget {
  const _NewSongDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.music_note, color: color),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}

class _GridSection extends StatelessWidget {
  const _GridSection({required this.section, required this.options});

  final PreparedSection section;
  final LineRenderOptions options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = section.section.label;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label?.isNotEmpty == true
                    ? label!
                    : l10n.songSectionInstrumental,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (section.section.repeat != null) ...[
                const SizedBox(width: 6),
                _RepeatBadge(
                  count: section.section.repeat!,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (final line in section.lines)
            LineRenderer(line: line, options: options),
        ],
      ),
    );
  }
}

class _TabSection extends StatelessWidget {
  const _TabSection({required this.section, required this.fontSize});

  final PreparedSection section;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final label = section.section.label;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label?.isNotEmpty == true ? label! : l10n.songSectionTab,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              section.lines.map((l) => l.line.text ?? '').join('\n'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize * 0.9,
                height: 1.6,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricSection extends StatelessWidget {
  const _LyricSection({
    required this.section,
    required this.options,
    required this.colorBackground,
  });

  final PreparedSection section;
  final LineRenderOptions options;
  final bool colorBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;

    final isChorus = section.type == 'chorus';
    final isBridge = section.type == 'bridge';
    final accent = isChorus
        ? scheme.primary
        : (isBridge ? scheme.tertiary : scheme.outlineVariant);

    final rawLabel = section.section.label;
    final label = rawLabel != null && rawLabel.isNotEmpty
        ? rawLabel
        : (isChorus
              ? l10n.songSectionChorus
              : (isBridge ? l10n.songSectionBridge : ''));
    final repeat = section.section.repeat;
    final showHeader = label.isNotEmpty || repeat != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: colorBackground
          ? const EdgeInsets.fromLTRB(12, 4, 8, 4)
          : const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: colorBackground ? accent.withValues(alpha: 0.06) : null,
        borderRadius: colorBackground ? BorderRadius.circular(4) : null,
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (label.isNotEmpty)
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isChorus || isBridge
                              ? accent
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (repeat != null) ...[
                    if (label.isNotEmpty) const SizedBox(width: 6),
                    _RepeatBadge(
                      count: repeat,
                      color: isChorus || isBridge
                          ? accent
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          if (section.lines.isEmpty && isChorus)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.songRepeatChorus,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final line in section.lines)
            LineRenderer(line: line, options: options),
        ],
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  const _RepeatBadge({required this.count, required this.color});

  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '×$count',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
