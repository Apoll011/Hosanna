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
          builder: (context, constraints) => Column(
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
                )
              else
                const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth >= 600 ? 24 : 0,
                        vertical: constraints.maxHeight >= 700 ? 16 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: HosannaRadii.card,
                        border: Border.all(
                          color: HosannaTokens.of(context).cardBorder,
                        ),
                      ),
                      child: Theme(
                        data: theme.copyWith(
                          inputDecorationTheme: theme.inputDecorationTheme
                              .copyWith(
                                filled: true,
                                fillColor: scheme.surface,
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
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  HosannaRadii.sm,
                                ),
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
                                borderRadius: BorderRadius.circular(
                                  HosannaRadii.sm,
                                ),
                              ),
                            ),
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          shrinkWrap: true,
                          children: [
                            if (showLogo) ...[
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
              ),
            ],
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
