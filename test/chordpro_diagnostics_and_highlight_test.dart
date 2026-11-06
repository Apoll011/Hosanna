import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/diagnostics.dart';
import 'package:hosanna/features/songs/domain/chordpro/highlight.dart';

void main() {
  group('lintChordPro', () {
    test('accepts a clean verse with known chords', () {
      const src = '''
{start_of_verse}
[G]Amazing [C]grace
{end_of_verse}
''';
      final diags = lintChordPro(src);
      expect(diags.where((d) => d.severity == ChordProSeverity.error), isEmpty);
      expect(
        diags.where((d) => d.code == ChordProDiagnosticCode.unknownChord),
        isEmpty,
      );
    });

    test('flags unknown chords and empty brackets', () {
      const src = '[G]ok []bad [Qzm7]weird';
      final diags = lintChordPro(src);
      expect(
        diags.any((d) => d.code == ChordProDiagnosticCode.emptyChord),
        isTrue,
      );
      expect(
        diags.any(
          (d) =>
              d.code == ChordProDiagnosticCode.unknownChord &&
              d.args['chord'] == 'Qzm7',
        ),
        isTrue,
      );
    });

    test('allows N.C. placeholder chords', () {
      const src = '[N.C.]rest [nc]also';
      final diags = lintChordPro(src);
      expect(
        diags.where((d) => d.code == ChordProDiagnosticCode.unknownChord),
        isEmpty,
      );
    });

    test('flags unclosed section and unexpected end', () {
      final unclosed = lintChordPro('{start_of_chorus}\n[G]Hey\n');
      expect(
        unclosed.any((d) => d.code == ChordProDiagnosticCode.unclosedSection),
        isTrue,
      );

      final unexpected = lintChordPro('{end_of_verse}\n');
      expect(
        unexpected.any(
          (d) => d.code == ChordProDiagnosticCode.unexpectedEndSection,
        ),
        isTrue,
      );
    });

    test('flags mismatched braces and brackets', () {
      final braces = lintChordPro('{title: missing close\n');
      expect(
        braces.any((d) => d.code == ChordProDiagnosticCode.unclosedBrace),
        isTrue,
      );

      final brackets = lintChordPro('[G major\n');
      expect(
        brackets.any((d) => d.code == ChordProDiagnosticCode.unclosedBracket),
        isTrue,
      );
    });

    test('maps parser version errors', () {
      const src = '''
{start_of_version: Live}
[G]sing
''';
      final diags = lintChordPro(src);
      expect(
        diags.any((d) => d.code == ChordProDiagnosticCode.parserError),
        isTrue,
      );
    });

    test('validates metadata fields', () {
      final diags = lintChordPro(
        '[G]hi',
        youtube: 'not-a-valid-youtube-link',
        key: 'H#',
        tempo: '9999',
        capo: '20',
        timeSignature: 'four',
        duration: 'long',
      );
      expect(
        diags.map((d) => d.code),
        containsAll([
          ChordProDiagnosticCode.invalidYoutube,
          ChordProDiagnosticCode.invalidKey,
          ChordProDiagnosticCode.invalidTempo,
          ChordProDiagnosticCode.invalidCapo,
          ChordProDiagnosticCode.invalidTimeSignature,
          ChordProDiagnosticCode.invalidDuration,
        ]),
      );
    });

    test('accepts valid youtube and key metadata', () {
      final diags = lintChordPro(
        '[G]hi',
        youtube: 'https://youtu.be/dQw4w9WgXcQ',
        key: 'Am',
        tempo: '72',
        capo: '2',
        timeSignature: '4/4',
        duration: '3:45',
      );
      expect(diags.where((d) => d.line <= 0), isEmpty);
    });
  });

  group('tokenizeChordPro', () {
    test('highlights directives, chords, comments and barlines', () {
      const src = '''
# intro
{start_of_verse: 1}
[G]Hello | [C]world
{end_of_verse}
''';
      final tokens = tokenizeChordPro(src);
      expect(tokens.any((t) => t.type == ChordProTokenType.comment), isTrue);
      expect(
        tokens.any((t) => t.type == ChordProTokenType.sectionDirective),
        isTrue,
      );
      expect(tokens.any((t) => t.type == ChordProTokenType.chord), isTrue);
      expect(tokens.any((t) => t.type == ChordProTokenType.barline), isTrue);

      // Full coverage — concatenated token text equals source.
      final rebuilt = tokens
          .map((t) => src.substring(t.start, t.end))
          .join();
      expect(rebuilt, src);
    });

    test('colors metadata directive names separately from sections', () {
      const src = '{title: Grace}';
      final tokens = tokenizeChordPro(src);
      expect(
        tokens.any((t) => t.type == ChordProTokenType.directiveName),
        isTrue,
      );
      expect(
        tokens.any((t) => t.type == ChordProTokenType.directiveValue),
        isTrue,
      );
    });
  });
}
