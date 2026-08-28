import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/coming_soon_page.dart';

class ExportPdfPage extends StatelessWidget {
  const ExportPdfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonPage(
      title: l10n.exportPdfTitle,
      description: l10n.comingSoonDescription,
      icon: Icons.picture_as_pdf_outlined,
    );
  }
}
