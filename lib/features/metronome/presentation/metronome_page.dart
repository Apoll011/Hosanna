import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/coming_soon_page.dart';

class MetronomePage extends StatelessWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonPage(
      title: l10n.metronomeTitle,
      description: l10n.metronomeDescription,
      icon: Icons.speed,
    );
  }
}
