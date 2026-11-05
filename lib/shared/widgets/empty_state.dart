import 'package:flutter/material.dart';

import '../../app/design/tokens.dart';

/// Scales empty-state art for phone / tablet / large layouts.
double emptyStateIllustrationSize(BuildContext context, {double base = 200}) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  if (shortest >= 900) return (base * 1.7).clamp(280.0, 360.0);
  if (shortest >= 600) return (base * 1.45).clamp(260.0, 320.0);
  return base;
}

/// Friendly empty / zero-data placeholder.
///
/// Prefer [illustrationAsset] from [HosannaIllustrations] when an illustration
/// fits the context; [icon] remains as a fallback.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon,
    this.illustrationAsset,
    this.illustrationSize,
    this.description,
    this.primaryIcon = Icons.filter_alt_off_outlined,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.scrollable = false,
  }) : assert(icon != null || illustrationAsset != null);

  final IconData? icon;
  final String? illustrationAsset;

  /// Explicit size override. When null, scales with screen size.
  final double? illustrationSize;
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
      illustrationAsset: illustrationAsset,
      illustrationSize: illustrationSize,
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
    this.illustrationAsset,
  });

  final String title;
  final String? description;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool scrollable;
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    final content = _EmptyStateBody(
      icon: Icons.cloud_off_outlined,
      illustrationAsset: illustrationAsset,
      illustrationSize: null,
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
    required this.title,
    required this.tone,
    required this.primaryIcon,
    this.icon,
    this.illustrationAsset,
    this.illustrationSize,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData? icon;
  final String? illustrationAsset;
  final double? illustrationSize;
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
    final artSize =
        illustrationSize ?? emptyStateIllustrationSize(context, base: 200);
    final contentWidth = artSize + 80;

    final circleColor = isError
        ? scheme.errorContainer
        : scheme.primaryContainer.withValues(alpha: 0.65);
    final iconColor =
        isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    final ctaShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final ctaStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: ctaShape,
      textStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    final outlinedStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: ctaShape,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HosannaSpacing.xl,
        vertical: HosannaSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth.clamp(320, 420)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustrationAsset != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isError
                          ? scheme.error.withValues(alpha: 0.08)
                          : scheme.primary.withValues(alpha: 0.08),
                      scheme.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      illustrationAsset!,
                      width: artSize,
                      height: artSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
            const SizedBox(height: HosannaSpacing.md),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: HosannaSpacing.xs),
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
              const SizedBox(height: HosannaSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPrimary,
                  style: ctaStyle,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: HosannaSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: outlinedStyle,
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
