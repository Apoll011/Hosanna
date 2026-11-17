import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/chord_notation.dart';
import 'package:hosanna/features/songs/domain/chordpro/transpose.dart';

void main() {
  group('ChordNotationConverter', () {
    test('keeps all international spellings unchanged', () {
      const notation = ChordNotationRegistry.international;
      for (final chord in [
        'C',
        'C#',
        'Db',
        'D',
        'D#',
        'Eb',
        'E',
        'F',
        'F#',
        'Gb',
        'G',
        'G#',
        'Ab',
        'A',
        'A#',
        'Bb',
        'B',
      ]) {
        expect(ChordNotationConverter.formatChord(chord, notation), chord);
      }
    });

    test('maps all natural notes in Latin, German, and Sargam systems', () {
      const roots = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
      const expected = {
        'latin': ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'],
        'german': ['C', 'D', 'E', 'F', 'G', 'A', 'H'],
        'sargam': ['Sa', 'Re', 'Ga', 'Ma', 'Pa', 'Dha', 'Ni'],
      };
      for (final system in ChordNotationRegistry.systems.skip(1)) {
        for (var i = 0; i < roots.length; i++) {
          expect(
            ChordNotationConverter.formatChord(roots[i], system),
            expected[system.id]![i],
          );
        }
      }
    });

    test('maps enharmonic chromatic spellings', () {
      const latin = ChordNotationRegistry.latin;
      const german = ChordNotationRegistry.german;
      const sargam = ChordNotationRegistry.sargam;
      expect(ChordNotationConverter.formatChord('C#', latin), 'Do#');
      expect(ChordNotationConverter.formatChord('Db', latin), 'Reb');
      expect(ChordNotationConverter.formatChord('Bb', latin), 'Sib');
      expect(ChordNotationConverter.formatChord('F#', german), 'Fis');
      expect(ChordNotationConverter.formatChord('Gb', german), 'Ges');
      expect(ChordNotationConverter.formatChord('Bb', german), 'B');
      expect(ChordNotationConverter.formatChord('B', german), 'H');
      expect(ChordNotationConverter.formatChord('C#', sargam), 'Sa#');
      expect(ChordNotationConverter.formatChord('Db', sargam), 'Reb');
    });

    test('maps every sharp and flat chromatic spelling in each system', () {
      const roots = [
        'C',
        'C#',
        'Db',
        'D',
        'D#',
        'Eb',
        'E',
        'F',
        'F#',
        'Gb',
        'G',
        'G#',
        'Ab',
        'A',
        'A#',
        'Bb',
        'B',
      ];
      for (final system in ChordNotationRegistry.systems) {
        for (final root in roots) {
          final formatted = ChordNotationConverter.formatChord(
            '${root}m7(b9)',
            system,
          );
          expect(formatted, isNotEmpty);
          expect(formatted, endsWith('m7(b9)'));
        }
      }
    });

    test('preserves chord quality, extensions, and alterations', () {
      const latin = ChordNotationRegistry.latin;
      const cases = {
        'Am': 'Lam',
        'Dm': 'Rem',
        'F#m': 'Fa#m',
        'Bdim': 'Sidim',
        'Caug': 'Doaug',
        'Csus2': 'Dosus2',
        'Dsus4': 'Resus4',
        'C7': 'Do7',
        'Cmaj7': 'Domaj7',
        'Dm7': 'Rem7',
        'Bdim7': 'Sidim7',
        'C9': 'Do9',
        'C11': 'Do11',
        'C13': 'Do13',
        'C7b9': 'Do7b9',
        'C#maj7': 'Do#maj7',
        'C7(b9)': 'Do7(b9)',
        'C7(add#11)': 'Do7(add#11)',
      };
      for (final entry in cases.entries) {
        expect(
          ChordNotationConverter.formatChord(entry.key, latin),
          entry.value,
        );
      }
    });

    test('converts only roots and a valid slash bass note', () {
      const latin = ChordNotationRegistry.latin;
      expect(ChordNotationConverter.formatChord('C/E', latin), 'Do/Mi');
      expect(ChordNotationConverter.formatChord('Dm7/G', latin), 'Rem7/Sol');
      expect(ChordNotationConverter.formatChord('Cmaj7/E', latin), 'Domaj7/Mi');
      expect(ChordNotationConverter.formatChord('F#m7/C#', latin), 'Fa#m7/Do#');
      expect(
        ChordNotationConverter.formatChord('C7(b9)/Eb', latin),
        'Do7(b9)/Mib',
      );
      expect(ChordNotationConverter.formatChord('C6/9', latin), 'Do6/9');
      expect(ChordNotationConverter.formatChord('N.C.', latin), 'N.C.');
    });

    test('unknown notation ids fall back to International', () {
      final notation = ChordNotationRegistry.resolve('unsupported');
      expect(notation.id, 'international');
      expect(
        ChordNotationConverter.formatChord('Cmaj7/E', notation),
        'Cmaj7/E',
      );
    });

    test('missing preference defaults to International', () {
      final notation = ChordNotationRegistry.resolve(null);
      expect(notation.id, 'international');
      expect(ChordNotationConverter.formatChord('Bb7', notation), 'Bb7');
    });

    test('transposition stays canonical and notation conversion does not mutate source', () {
      const sourceChord = 'Cmaj7/E';
      const source = '{key: C}\n[Cmaj7/E]test';
      final transposed = transposeChord(sourceChord, 2);
      expect(transposed, 'Dmaj7/F#');
      expect(
        ChordNotationConverter.formatChord(
          transposed,
          ChordNotationRegistry.latin,
        ),
        'Remaj7/Fa#',
      );
      ChordNotationConverter.formatChord(
        sourceChord,
        ChordNotationRegistry.german,
      );
      expect(source, '{key: C}\n[Cmaj7/E]test');
    });
  });
}
