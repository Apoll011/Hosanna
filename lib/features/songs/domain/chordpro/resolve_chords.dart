library;

import 'instruments/instruments.dart';
import 'transpose.dart';
import 'parser.dart' show ChordProVersion;

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

String? _normalizedKey(String? key) {
  final match = RegExp(
    r'^([A-Ga-g])([#b]?)(m|minor|min)?$',
    caseSensitive: false,
  ).firstMatch(key?.trim() ?? '');
  if (match == null) return null;
  const pitch = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final alteration = match.group(2) == '#'
      ? 1
      : match.group(2) == 'b'
      ? -1
      : 0;
  final semitone =
      (pitch[match.group(1)!.toUpperCase()]! + alteration + 12) % 12;
  return '$semitone:${match.group(3) == null ? 'major' : 'minor'}';
}

({int transpose, int capo}) resolveVariantDefaults(
  ChordProVersion main, [
  ChordProVersion? variant,
]) {
  if (variant == null) {
    return (
      transpose: parseKeyShiftValue(main.metadata['keyShift']),
      capo: parseCapoValue(main.metadata['capo']),
    );
  }
  final variantKey = variant.metadata['key'];
  final mainKey = main.metadata['key'];
  final normalizedMainKey = _normalizedKey(mainKey);
  final sameKey = normalizedMainKey != null
      ? _normalizedKey(variantKey) == normalizedMainKey
      : mainKey == null && variantKey == null;
  return (
    transpose: variant.declaredDirectives.contains('key_shift')
        ? parseKeyShiftValue(variant.metadata['keyShift'])
        : 0,
    capo: variant.declaredDirectives.contains('capo')
        ? parseCapoValue(variant.metadata['capo'])
        : sameKey
        ? parseCapoValue(main.metadata['capo'])
        : 0,
  );
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
  final shownKey = shapeSemitones == 0
      ? rawKey
      : transposeChord(rawKey, shapeSemitones);

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
