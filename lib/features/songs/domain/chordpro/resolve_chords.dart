library;

import 'instruments/instruments.dart';
import 'transpose.dart';

int parseCapoValue(Object? raw) {
  if (raw == null) return 0;
  final s = raw.toString().trim();
  if (!RegExp(r'^[0-9]+$').hasMatch(s)) return 0;
  final n = int.tryParse(s);
  if (n == null || n < 0 || n > 11) return 0;
  return n;
}

int parseKeyShiftValue(Object? raw) {
  if (raw == null) return 0;
  final s = raw.toString().trim();
  if (!RegExp(r'^-?[0-9]+$').hasMatch(s)) return 0;
  final n = int.tryParse(s);
  return n ?? 0;
}

class ResolvedChords {
  const ResolvedChords({
    required this.shownKey,
    required this.shownChords,
    required this.capoLabel,
  });

  final String shownKey;
  final List<String> shownChords;
  final String? capoLabel;
}

ResolvedChords resolveChords({
  required List<String> chords,
  String? key,
  required int keyShift,
  required int capo,
  required String instrument,
}) {
  final profile = instrumentRegistry.resolve(instrument);
  final supportsCapo = profile.supportsCapo;
  final shapeSemitones = keyShift - (supportsCapo ? capo : 0);

  final shownChords = shapeSemitones == 0
      ? List<String>.from(chords)
      : chords.map((c) => transposeChord(c, shapeSemitones)).toList();

  final rawKey = key ?? 'C';
  final shownKey =
      shapeSemitones == 0 ? rawKey : transposeChord(rawKey, shapeSemitones);

  String? capoLabel;
  if (supportsCapo && capo > 0) {
    capoLabel = 'Capo $capo · shapes in $shownKey';
  }

  return ResolvedChords(
    shownKey: shownKey,
    shownChords: shownChords,
    capoLabel: capoLabel,
  );
}
