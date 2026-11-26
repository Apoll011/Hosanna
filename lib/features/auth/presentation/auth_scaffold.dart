import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/design/tokens.dart';
import '../../../shared/widgets/hosanna_logo.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.heroAsset,
    this.heroFallbackIcon = LucideIcons.music,
    this.showLogo = true,
    this.showBack = true,
    this.footer,
    this.maxWidth = 420,
  });

  final String title;
  final String? subtitle;
  final String? heroAsset;
  final IconData heroFallbackIcon;
  final bool showLogo;
  final bool showBack;
  final Widget child;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(HosannaRadii.sm),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600;
            final form = Theme(
              data: theme.copyWith(
                inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                  filled: true,
                  fillColor: scheme.surface,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: scheme.primary, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HosannaRadii.sm),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HosannaRadii.sm),
                    ),
                  ),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 24,
                  wide ? 28 : 12,
                  wide ? 28 : 24,
                  28,
                ),
                children: [
                  if (heroAsset != null) ...[
                    _AuthHero(
                      asset: heroAsset!,
                      fallbackIcon: heroFallbackIcon,
                      height: wide ? 176 : 156,
                    ),
                    const SizedBox(height: 16),
                  ] else if (showLogo) ...[
                    const HosannaLogo(size: 52),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  child,
                  if (footer != null) ...[const SizedBox(height: 20), footer!],
                ],
              ),
            );

            final panel = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: wide
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: HosannaRadii.card,
                        border: Border.all(
                          color: HosannaTokens.of(context).cardBorder,
                        ),
                      ),
                      child: form,
                    )
                  : form,
            );

            return Column(
              children: [
                if (showBack && canPop)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                  ),
                Expanded(
                  child: wide
                      ? Center(child: panel)
                      : Align(alignment: Alignment.topCenter, child: panel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.asset,
    required this.fallbackIcon,
    required this.height,
  });

  final String asset;
  final IconData fallbackIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            fallbackIcon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

abstract final class AuthHeroes {
  static const signIn = HosannaIllustrations.authSignIn;
  static const signUp = HosannaIllustrations.authSignUp;
  static const forgotPassword = HosannaIllustrations.authForgotPassword;
  static const resetPassword = HosannaIllustrations.authResetPassword;
  static const verifyEmail = HosannaIllustrations.authVerifyEmail;
  static const resetSent = HosannaIllustrations.authResetSent;
  static const passwordChanged = HosannaIllustrations.authPasswordChanged;
  static const emailVerified = HosannaIllustrations.authEmailVerified;
}
