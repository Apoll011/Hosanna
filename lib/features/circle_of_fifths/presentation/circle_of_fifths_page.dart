import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/coming_soon_page.dart';

class CircleOfFifthsPage extends StatelessWidget {
  const CircleOfFifthsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonPage(
      title: l10n.circleOfFifthsTitle,
      description: l10n.circleOfFifthsDescription,
      icon: Icons.donut_large,
    );
  }
}
