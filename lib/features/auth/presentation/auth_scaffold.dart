import 'package:flutter/material.dart';

import '../../../app/design/illustrations.dart';
import '../../../shared/widgets/hosanna_logo.dart';

/// Shared chrome for auth screens — matches the post-login setup wizard:
/// soft primary wash, optional hero art, bold title, and rounded controls.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.heroAsset,
    this.heroFallbackIcon = Icons.music_note_rounded,
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
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.38, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (showBack && canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                )
              else
                const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                          filled: true,
                          fillColor: scheme.surface.withValues(alpha: 0.92),
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder.copyWith(
                            borderSide: BorderSide(
                              color: scheme.primary,
                              width: 1.6,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        filledButtonTheme: FilledButtonThemeData(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        outlinedButtonTheme: OutlinedButtonThemeData(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                        children: [
                          if (heroAsset != null) ...[
                            _AuthHero(
                              asset: heroAsset!,
                              fallbackIcon: heroFallbackIcon,
                            ),
                            const SizedBox(height: 20),
                          ] else if (showLogo) ...[
                            const HosannaLogo(size: 72),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
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
                          if (footer != null) ...[
                            const SizedBox(height: 20),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.asset, required this.fallbackIcon});

  final String asset;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => SizedBox(
          height: 148,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.22),
                  scheme.tertiary.withValues(alpha: 0.14),
                  scheme.surfaceContainerHighest,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fallbackIcon,
                  size: 44,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 10),
                const HosannaLogo(size: 48, borderRadius: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary CTA used on auth forms (handles the loading spinner).
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

/// Default hero assets for auth routes (drop PNGs into `assets/illustrations/`).
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
