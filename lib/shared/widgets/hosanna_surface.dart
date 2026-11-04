import 'package:flutter/material.dart';

import '../../app/design/tokens.dart';

/// Soft elevated surface used for list rows, option cards and sheets.
class HosannaSurface extends StatelessWidget {
  const HosannaSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.elevated = true,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final bool elevated;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = HosannaTokens.of(context);
    final radius = borderRadius ?? HosannaRadii.card;
    final bg = color ??
        (selected ? tokens.selectedNav : theme.colorScheme.surface);
    final border = borderColor ??
        (selected ? theme.colorScheme.primary.withValues(alpha: 0.35) : tokens.cardBorder);

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(HosannaSpacing.md),
      child: child,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border),
        boxShadow: elevated
            ? HosannaElevation.card(theme.brightness)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
      ),
    );
  }
}

/// Compact leading badge used in song / service / folder rows.
class HosannaLeadingBadge extends StatelessWidget {
  const HosannaLeadingBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HosannaRadii.sm),
      ),
      child: Icon(icon, color: c, size: size * 0.45),
    );
  }
}

/// Section label used in drawers, sheets and settings groups.
class HosannaSectionLabel extends StatelessWidget {
  const HosannaSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HosannaSpacing.sm,
        HosannaSpacing.sm,
        HosannaSpacing.sm,
        HosannaSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
