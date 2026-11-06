import 'package:flutter/material.dart';

import '../../app/design/illustrations.dart';
import '../../l10n/generated/app_localizations.dart';
import 'empty_state.dart';

/// Placeholder screen for features whose logic ships in a later phase.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        illustrationAsset: HosannaIllustrations.comingSoon,
        title: title,
        description: '$description\n\n${l10n.comingSoon}',
      ),
    );
  }
}
