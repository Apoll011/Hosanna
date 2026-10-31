import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';

class NotesCard extends StatelessWidget {
  const NotesCard({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.servicesNotes.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class MetadataHeader extends StatelessWidget {
  const MetadataHeader({
    super.key,
    required this.metadata,
    required this.soundingKey,
    required this.renderedKey,
    required this.effectiveCapo,
    required this.transposeVal,
    this.onKeyTap,
    this.onYoutubeTap,
  });

  final Map<String, String> metadata;
  final String soundingKey;
  final String renderedKey;
  final int effectiveCapo;
  final int transposeVal;

  /// Opens the transpose controls; makes the key pill tappable when set.
  final VoidCallback? onKeyTap;

  /// Opens the YouTube player; shows a YouTube pill when set.
  final VoidCallback? onYoutubeTap;

  String? _meta(String key) {
    final value = metadata[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final title = _meta('title');
    final subtitle = _meta('subtitle');
    final byline = [
      _meta('artist'),
      _meta('composer'),
    ].whereType<String>().join(' / ');
    final keyNote = _meta('keyNote') ?? _meta('key_note');
    final copyright = _meta('copyright');
    final songNumber = _meta('songNumber');
    final originalKey = _meta('originalKey');
    final tempo = _meta('tempo');
    final time = _meta('time');
    final ccli = _meta('ccli');
    final duration = _formatDuration(_meta('duration'));

    final pills = <Widget>[
      if (songNumber != null) _Pill(text: l10n.songNumberPill(songNumber)),
      if (_meta('key') != null || transposeVal != 0)
        _Pill(
          text: l10n.songKeyPill(soundingKey),
          icon: onKeyTap != null ? Icons.tune_rounded : null,
          tooltip: onKeyTap != null ? l10n.songChangeKey : null,
          onTap: onKeyTap,
          highlighted: transposeVal != 0,
        ),
      if (effectiveCapo > 0) ...[
        _Pill(text: l10n.songCapoPill('$effectiveCapo')),
        _Pill(text: l10n.songShapePill(renderedKey)),
      ],
      if (originalKey != null)
        _Pill(text: l10n.songOriginalKeyPill(originalKey)),
      if (tempo != null) _Pill(text: '$tempo BPM'),
      if (time != null) _Pill(text: time),
      if (duration != null) _Pill(text: duration, icon: Icons.schedule_rounded),
      if (ccli != null) _Pill(text: 'CCLI: $ccli'),
      if (onYoutubeTap != null)
        _Pill(
          text: 'YouTube',
          icon: Icons.smart_display_rounded,
          tooltip: l10n.songYoutubeOpenPlayer,
          onTap: onYoutubeTap,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null)
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (byline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                byline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (pills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(spacing: 6, runSpacing: 6, children: pills),
            ),
          if (keyNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        keyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (copyright != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '© $copyright',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `duration` is stored in seconds by the parser when authored as `m:ss`.
String? _formatDuration(String? raw) {
  if (raw == null) return null;
  final seconds = int.tryParse(raw);
  if (seconds == null) return raw;
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    this.icon,
    this.tooltip,
    this.onTap,
    this.highlighted = false,
  });

  final String text;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = highlighted
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final pill = Material(
      color: highlighted
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: onTap != null ? 6 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}
