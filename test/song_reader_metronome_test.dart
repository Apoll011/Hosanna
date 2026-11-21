import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/app/providers.dart';
import 'package:hosanna/features/services/data/service_annotation_repository.dart';
import 'package:hosanna/features/songs/presentation/song_reader.dart';
import 'package:hosanna/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeServiceAnnotationRepository extends Fake
    implements ServiceAnnotationRepository {
  @override
  Future<Uint8List?> loadAnnotation({
    required String serviceId,
    required String songId,
  }) async => null;

  @override
  Future<void> saveAnnotation({
    required String serviceId,
    required String songId,
    required Uint8List bytes,
  }) async {}

  @override
  AnnotationSyncHandle subscribeToAnnotationUpdates({
    required String serviceId,
    required String songId,
    required void Function(RemoteAnnotation annotation) onRemoteUpdate,
  }) {
    return AnnotationSyncHandle(cancel: () async {});
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget({
    required String content,
    VoidCallback? onToggleAnnotation,
    VoidCallback? onNext,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        serviceAnnotationRepositoryProvider.overrideWithValue(
          _FakeServiceAnnotationRepository(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongReader(
            content: content,
            onToggleAnnotation: onToggleAnnotation,
            onNext: onNext,
          ),
        ),
      ),
    );
  }

  testWidgets('metronome button appears next to auto-scroll when valid tempo/time and annotation is hidden', (tester) async {
    const songWithTempo = '''{title: Amazing Grace}
{tempo: 120}
{time: 4/4}
[G]Amazing [C]grace
''';

    await tester.pumpWidget(buildTestWidget(content: songWithTempo));
    await tester.pumpAndSettle();

    final metronomeFinder = find.byTooltip('Metronome');
    expect(metronomeFinder, findsOneWidget);

    final autoScrollFinder = find.byIcon(LucideIcons.chevronsDown);
    expect(autoScrollFinder, findsOneWidget);

    final metronomeCenter = tester.getCenter(metronomeFinder);
    final autoScrollCenter = tester.getCenter(autoScrollFinder);

    // Metronome must be to the left of auto-scroll button
    expect(metronomeCenter.dx, lessThan(autoScrollCenter.dx));
    // And on the same horizontal baseline (row)
    expect((metronomeCenter.dy - autoScrollCenter.dy).abs(), lessThan(5.0));
  });

  testWidgets('metronome button appears to the left of annotation button when annotation is enabled', (tester) async {
    const songWithTempo = '''{title: Amazing Grace}
{tempo: 120}
{time: 4/4}
[G]Amazing [C]grace
''';

    await tester.pumpWidget(buildTestWidget(
      content: songWithTempo,
      onToggleAnnotation: () {},
    ));
    await tester.pumpAndSettle();

    final metronomeFinder = find.byTooltip('Metronome');
    expect(metronomeFinder, findsOneWidget);

    final annotationFinder = find.byIcon(LucideIcons.pencil);
    expect(annotationFinder, findsOneWidget);

    final metronomeCenter = tester.getCenter(metronomeFinder);
    final annotationCenter = tester.getCenter(annotationFinder);

    // Metronome is to the left of the annotation button
    expect(metronomeCenter.dx, lessThan(annotationCenter.dx));
    // And on the same horizontal baseline (row)
    expect((metronomeCenter.dy - annotationCenter.dy).abs(), lessThan(5.0));
  });
}
