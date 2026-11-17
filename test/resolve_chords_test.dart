import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/diagnostics.dart';
import 'package:hosanna/features/songs/domain/chordpro/parser.dart';
import 'package:hosanna/features/songs/domain/chordpro/resolve_chords.dart';

void main() {
  group('resolveChords — fixture parity', () {
    test('F# song + capo 4 on guitar → D shapes, label shown', () {
      final result = resolveChords(
        chords: ['F#', 'B', 'C#m', 'A'],
        key: 'F#',
        keyShift: 0,
        capo: 4,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'D');
      expect(result.shownChords, ['D', 'G', 'Am', 'F']);
      expect(result.capoLabel, 'Capo 4 · shapes in D');
    });

    test('Capo 4 on piano → no capo effect, label null', () {
      final result = resolveChords(
        chords: ['F#', 'B', 'C#m'],
        key: 'F#',
        keyShift: 0,
        capo: 4,
        instrument: 'piano',
      );
      expect(result.shownKey, 'F#');
      expect(result.shownChords, ['F#', 'B', 'C#m']);
      expect(result.capoLabel, isNull);
    });

    test('keyshift +2 on guitar', () {
      final result = resolveChords(
        chords: ['C', 'G', 'Am', 'F'],
        key: 'C',
        keyShift: 2,
        capo: 0,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'D');
      expect(result.shownChords, ['D', 'A', 'Bm', 'G']);
      expect(result.capoLabel, isNull);
    });

    test('keyshift +2 on piano', () {
      final result = resolveChords(
        chords: ['C', 'G', 'Am', 'F'],
        key: 'C',
        keyShift: 2,
        capo: 0,
        instrument: 'piano',
      );
      expect(result.shownKey, 'D');
      expect(result.shownChords, ['D', 'A', 'Bm', 'G']);
      expect(result.capoLabel, isNull);
    });

    test('keyshift +2 + capo 2 on guitar → shapeSemitones=0', () {
      final result = resolveChords(
        chords: ['C', 'G', 'Am'],
        key: 'C',
        keyShift: 2,
        capo: 2,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'C');
      expect(result.shownChords, ['C', 'G', 'Am']);
      expect(result.capoLabel, 'Capo 2 · shapes in C');
    });

    test('capo 0 → no capo effect', () {
      final result = resolveChords(
        chords: ['G', 'Em', 'C', 'D'],
        key: 'G',
        keyShift: 0,
        capo: 0,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'G');
      expect(result.shownChords, ['G', 'Em', 'C', 'D']);
      expect(result.capoLabel, isNull);
    });

    test('slash chord survives transpose', () {
      final result = resolveChords(
        chords: ['G/B', 'C/E'],
        key: 'G',
        keyShift: 2,
        capo: 0,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'A');
      expect(result.shownChords, ['A/Db', 'D/F#']);
      expect(result.capoLabel, isNull);
    });

    test('flat chords shifted up 2', () {
      final result = resolveChords(
        chords: ['Bb', 'Gm', 'Eb', 'F'],
        key: 'Bb',
        keyShift: 2,
        capo: 0,
        instrument: 'guitar',
      );
      expect(result.shownKey, 'C');
      expect(result.shownChords, ['C', 'Am', 'F', 'G']);
      expect(result.capoLabel, isNull);
    });

    test('ukulele capo 2 on C → label shown', () {
      final result = resolveChords(
        chords: ['C', 'F', 'G'],
        key: 'C',
        keyShift: 0,
        capo: 2,
        instrument: 'ukulele',
      );
      expect(result.shownKey, 'A#');
      expect(result.shownChords, ['A#', 'D#', 'F']);
      expect(result.capoLabel, 'Capo 2 · shapes in A#');
    });
  });

  group('variant directive defaults — shared fixtures', () {
    final fixtures = jsonDecode(
      File('test/fixtures/variant-defaults.json').readAsStringSync(),
    ) as List<dynamic>;
    for (final raw in fixtures) {
      final fixture = raw as Map<String, dynamic>;
      test(fixture['id'] as String, () {
        final document = parseChordProDocument(fixture['content'] as String);
        final variant = document.variants.firstWhere(
          (item) => item.id == fixture['variant'],
        );
        final defaults = resolveVariantDefaults(
          document.defaultVersion,
          variant,
        );
        final expected = fixture['expected'] as Map<String, dynamic>;
        expect(defaults.transpose, expected['keyShift']);
        expect(defaults.capo, expected['capo']);
      });
    }
  });

  group('parseCapoValue', () {
    test('returns valid values in range 0–11', () {
      expect(parseCapoValue('4'), 4);
      expect(parseCapoValue(0), 0);
      expect(parseCapoValue('11'), 11);
    });

    test('clamps out-of-range to 0', () {
      expect(parseCapoValue('12'), 0);
      expect(parseCapoValue('-1'), 0);
    });

    test('returns 0 for non-integer or invalid input', () {
      expect(parseCapoValue('abc'), 0);
      expect(parseCapoValue(null), 0);
      expect(parseCapoValue('3.5'), 0);
      expect(parseCapoValue(''), 0);
    });
  });

  group('parseKeyShiftValue', () {
    test('returns valid signed integers', () {
      expect(parseKeyShiftValue('2'), 2);
      expect(parseKeyShiftValue('-3'), -3);
      expect(parseKeyShiftValue(0), 0);
    });

    test('returns 0 for non-integer or invalid input', () {
      expect(parseKeyShiftValue('abc'), 0);
      expect(parseKeyShiftValue(null), 0);
      expect(parseKeyShiftValue('2.5'), 0);
      expect(parseKeyShiftValue(''), 0);
    });
  });

  group('parser — keyshift directive', () {
    test('parses keyshift and key_shift into keyShift metadata', () {
      final doc1 = parseChordProDocument(
        '{title: Test}\n{keyshift: 2}\n[C]Hello',
      );
      expect(doc1.defaultVersion.metadata['keyShift'], '2');

      final doc2 = parseChordProDocument(
        '{title: Test}\n{key_shift: -3}\n[C]Hello',
      );
      expect(doc2.defaultVersion.metadata['keyShift'], '-3');

      final doc3 = parseChordProDocument('{title: Test}\n{capo: 4}\n[C]Hello');
      expect(doc3.defaultVersion.metadata['capo'], '4');
    });
  });

  group('diagnostics — capo and keyshift validation', () {
    test('warns on capo > 11', () {
      final diags = lintChordPro('{title: Test}', capo: '12');
      expect(
        diags.any((d) => d.code == ChordProDiagnosticCode.invalidCapo),
        isTrue,
      );
    });

    test('accepts capo 0 and 11', () {
      final diags0 = lintChordPro('{title: Test}', capo: '0');
      expect(
        diags0.any((d) => d.code == ChordProDiagnosticCode.invalidCapo),
        isFalse,
      );

      final diags11 = lintChordPro('{title: Test}', capo: '11');
      expect(
        diags11.any((d) => d.code == ChordProDiagnosticCode.invalidCapo),
        isFalse,
      );
    });

    test('warns on non-numeric keyshift', () {
      final diags = lintChordPro('{title: Test}', keyShift: 'abc');
      expect(
        diags.any((d) => d.code == ChordProDiagnosticCode.invalidKeyShift),
        isTrue,
      );
    });

    test('accepts valid negative keyshift', () {
      final diags = lintChordPro('{title: Test}', keyShift: '-3');
      expect(
        diags.any((d) => d.code == ChordProDiagnosticCode.invalidKeyShift),
        isFalse,
      );
    });
  });
}
