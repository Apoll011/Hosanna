import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/features/songs/presentation/song_library_page.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSong({
    required String id,
    required String title,
    String artist = 'Artist',
    String content = '',
    List<String> tags = const [],
    String? folderId,
    int? songNumber,
    String createdAt = '2024-01-01T00:00:00Z',
    String updatedAt = '2024-01-01T00:00:00Z',
  }) async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            content: content,
            path: 'songs/$id',
            tags: Value(tags),
            folderId: Value(folderId),
            songNumber: Value(songNumber),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
  }

  Future<void> seedFolder({required String id, required String name}) async {
    await db.into(db.folders).insert(
          FoldersCompanion.insert(
            id: id,
            name: name,
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-01T00:00:00Z',
          ),
        );
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SongLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openFilters(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    final finder = find.widgetWithText(FilterChip, label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FilterChip chip(WidgetTester tester, String label) =>
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));

  group('filter sheet visual feedback (regression: taps not reflected)', () {
    testWidgets('tag chip shows pressed state and filters live', (tester) async {
      await seedSong(id: 'a', title: 'Song A', tags: const ['worship']);
      await seedSong(id: 'b', title: 'Song B');
      await pumpLibrary(tester);

      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsOneWidget);

      await openFilters(tester);
      await tapChip(tester, 'worship');

      // The chip must reflect its selection without reopening the sheet.
      expect(chip(tester, 'worship').selected, isTrue);
      // The list behind updates live.
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsNothing);

      // Tapping again deselects and restores the list.
      await tapChip(tester, 'worship');
      expect(chip(tester, 'worship').selected, isFalse);
      expect(find.text('Song B'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('sort choice chip shows pressed state', (tester) async {
      await seedSong(id: 'a', title: 'Alpha', songNumber: 2);
      await seedSong(id: 'b', title: 'Beta', songNumber: 1);
      await pumpLibrary(tester);

      // Default sort is title ascending: Alpha before Beta.
      expect(
        tester.getTopLeft(find.text('Alpha')).dy,
        lessThan(tester.getTopLeft(find.text('Beta')).dy),
      );

      await openFilters(tester);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Song number'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Song number'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Song number'),
      );
      expect(chip.selected, isTrue);
      // List re-sorted live: Beta (1) before Alpha (2).
      expect(
        tester.getTopLeft(find.text('Beta')).dy,
        lessThan(tester.getTopLeft(find.text('Alpha')).dy),
      );
    });
  });

  group('multi-select tags', () {
    testWidgets('match-all filters to songs containing every tag',
        (tester) async {
      await seedSong(
        id: 'a',
        title: 'Song A',
        tags: const ['worship', 'fast'],
      );
      await seedSong(id: 'b', title: 'Song B', tags: const ['worship']);
      await seedSong(id: 'c', title: 'Song C', tags: const ['fast']);
      await seedSong(id: 'd', title: 'Song D');
      await pumpLibrary(tester);

      await openFilters(tester);
      await tapChip(tester, 'worship');
      await tapChip(tester, 'fast');

      expect(chip(tester, 'worship').selected, isTrue);
      expect(chip(tester, 'fast').selected, isTrue);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsNothing);
      expect(find.text('Song C'), findsNothing);
      expect(find.text('Song D'), findsNothing);

      // Switching to "match any" widens the result set.
      await tester.tap(find.text('Match any'));
      await tester.pumpAndSettle();
      expect(find.text('Song B'), findsOneWidget);
      expect(find.text('Song C'), findsOneWidget);
      expect(find.text('Song D'), findsNothing);
    });
  });

  group('content-derived filters', () {
    testWidgets('key chips come from parsed metadata and filter live',
        (tester) async {
      await seedSong(id: 'a', title: 'Song A', content: '{key: C}\n[C]Oh [G]say');
      await seedSong(id: 'b', title: 'Song B', content: '{key: G}\n[G]Hi');
      await seedSong(id: 'c', title: 'Song C', content: 'Plain lyrics');
      await pumpLibrary(tester);

      await openFilters(tester);
      await tapChip(tester, 'C');
      expect(chip(tester, 'C').selected, isTrue);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsNothing);
      expect(find.text('Song C'), findsNothing);

      // Second key is additive (OR within keys).
      await tapChip(tester, 'G');
      expect(chip(tester, 'G').selected, isTrue);
      expect(find.text('Song B'), findsOneWidget);
      expect(find.text('Song C'), findsNothing);
    });

    testWidgets('"only with chords" hides chord-less songs', (tester) async {
      await seedSong(id: 'a', title: 'Song A', content: '[C]Oh [G]say');
      await seedSong(id: 'b', title: 'Song B', content: 'Plain lyrics');
      await pumpLibrary(tester);

      await openFilters(tester);
      await tester.ensureVisible(find.text('Only with chords'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Only with chords'));
      await tester.pumpAndSettle();

      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Only with chords'),
      );
      expect(tile.value, isTrue);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsNothing);
    });
  });

  group('folder filter', () {
    testWidgets('multi-select folders', (tester) async {
      await seedFolder(id: 'f1', name: 'Worship');
      await seedFolder(id: 'f2', name: 'Hymns');
      await seedSong(id: 'a', title: 'Song A', folderId: 'f1');
      await seedSong(id: 'b', title: 'Song B', folderId: 'f2');
      await seedSong(id: 'c', title: 'Song C');
      await pumpLibrary(tester);

      await openFilters(tester);
      await tapChip(tester, 'Worship');
      expect(chip(tester, 'Worship').selected, isTrue);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsNothing);
      expect(find.text('Song C'), findsNothing);

      await tapChip(tester, 'Hymns');
      expect(chip(tester, 'Hymns').selected, isTrue);
      expect(find.text('Song B'), findsOneWidget);
      expect(find.text('Song C'), findsNothing);
    });
  });

  group('active filter chips row', () {
    testWidgets('removable chips summarize active filters and reset works',
        (tester) async {
      await seedSong(id: 'a', title: 'Song A', tags: const ['worship']);
      await seedSong(id: 'b', title: 'Song B');
      await pumpLibrary(tester);

      expect(find.byIcon(Icons.filter_alt_off), findsNothing);

      await openFilters(tester);
      await tapChip(tester, 'worship');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Badge on the filter button reflects one active filter.
      expect(find.text('1'), findsOneWidget);

      // Active chip row shows the selected tag and the reset action.
      final tagChip = find.widgetWithText(InputChip, 'worship');
      expect(tagChip, findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);

      // Deleting the tag chip restores the list.
      await tester.tap(find.descendant(
        of: tagChip,
        matching: find.byIcon(Icons.clear),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Song B'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'worship'), findsNothing);
      expect(find.text('1'), findsNothing);
    });
  });
}
