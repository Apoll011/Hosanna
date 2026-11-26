import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/chord_dictionary.dart';
import 'package:hosanna/features/songs/domain/chordpro/chord_notation.dart';
import 'package:hosanna/features/songs/domain/chordpro/instruments/instruments.dart';
import 'package:hosanna/features/songs/presentation/chordpro/chord_diagrams.dart';
import 'package:hosanna/features/songs/presentation/chordpro/widgets/chord_sheet.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('diagram opens a voicing pager and swipes between options', (
    tester,
  ) async {
    final chord = chordDictionary.getFingering('C')!;
    final alternatives = chord.alternativesFor('guitar');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChordSheet(
            chords: const ['C'],
            initialIndex: 0,
            initialInstrument: 'guitar',
            capo: 0,
            preferences: const InstrumentPreferences(),
            fingeringFor: (_) => chord,
            alternativesFor: (_) => alternatives,
            chordNotation: ChordNotationRegistry.resolve('international'),
            tonic: 'C',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InstrumentDiagram).first);
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('1 / ${alternatives.length}'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-480, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('2 / ${alternatives.length}'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });
}
