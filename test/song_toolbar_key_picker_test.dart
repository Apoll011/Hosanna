import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/features/songs/domain/chordpro/parser.dart';
import 'package:hosanna/features/songs/presentation/chordpro/song_display_settings.dart';
import 'package:hosanna/features/songs/presentation/song_toolbar.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSheet(ChordProDocument document) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        songCurrentDocumentProvider.overrideWith((ref) => document),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SongControlsSheet()),
      ),
    );
  }

  ChordProDocument songIn(String key) =>
      parseChordProDocument('{title: Test}\n{key: $key}\n[$key]Hello');

  SongDisplaySettings readSettings(WidgetTester tester) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SongControlsSheet)),
    );
    return container.read(songDisplaySettingsProvider);
  }

  testWidgets('shows all twelve keys with the original and selected marked', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(songIn('G')));
    await tester.pumpAndSettle();

    for (final key in [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ]) {
      expect(find.byKey(ValueKey('song-key-$key')), findsOneWidget);
    }

    // At transpose 0 the written key is both the original and the selected key.
    final original = tester.getSemantics(
      find.byKey(const ValueKey('song-key-G')),
    );
    expect(original.getSemanticsData().hint, contains('G'));
    expect(find.text('G · 0 semitones'), findsOneWidget);
    expect(readSettings(tester).transpose, 0);
  });

  testWidgets('tapping a key transposes instantly and the original resets', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(songIn('G')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('song-key-A')));
    await tester.pumpAndSettle();
    expect(readSettings(tester).transpose, 2);
    expect(find.text('A · +2 semitones'), findsOneWidget);

    // Keys below the original lower the pitch instead of jumping an octave.
    await tester.tap(find.byKey(const ValueKey('song-key-F')));
    await tester.pumpAndSettle();
    expect(readSettings(tester).transpose, -2);
    expect(find.text('F · -2 semitones'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('song-key-G')));
    await tester.pumpAndSettle();
    expect(readSettings(tester).transpose, 0);
  });

  testWidgets('uses flat names when the song is written with flats', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(songIn('Bb')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('song-key-Bb')), findsOneWidget);
    expect(find.byKey(const ValueKey('song-key-A#')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('song-key-C')));
    await tester.pumpAndSettle();
    expect(readSettings(tester).transpose, 2);
  });
}
