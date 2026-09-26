import 'package:flutter/material.dart';

/// Friendly empty / zero-data placeholder.
///
/// Visually distinct from [ErrorState]: soft primary tint, calm copy, and
/// optional actions that invite the next step (clear filters, sync) rather
/// than implying something broke.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.primaryIcon = Icons.filter_alt_off_outlined,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.scrollable = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final IconData primaryIcon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// When true, fills the parent and scrolls so it works inside a
  /// [RefreshIndicator] (always-scrollable physics).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = _EmptyStateBody(
      icon: icon,
      title: title,
      description: description,
      primaryIcon: primaryIcon,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
      tone: _EmptyTone.calm,
    );

    if (!scrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Failure placeholder — tinted with error colors and a clear retry path.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.description,
    this.retryLabel,
    this.onRetry,
    this.scrollable = false,
  });

  final String title;
  final String? description;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = _EmptyStateBody(
      icon: Icons.cloud_off_outlined,
      title: title,
      description: description,
      primaryIcon: Icons.refresh,
      primaryLabel: retryLabel,
      onPrimary: onRetry,
      tone: _EmptyTone.error,
    );

    if (!scrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: content),
        ),
      ),
    );
  }
}

enum _EmptyTone { calm, error }

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({
    required this.icon,
    required this.title,
    required this.tone,
    required this.primaryIcon,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? description;
  final IconData primaryIcon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final _EmptyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isError = tone == _EmptyTone.error;

    final circleColor = isError
        ? scheme.errorContainer
        : scheme.primaryContainer.withValues(alpha: 0.65);
    final iconColor =
        isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 24),
              if (isError)
                FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
