/// Render-ready view of a parsed song.
///
/// Built once per document / variant / transposition change so the line
/// widgets never tokenize lyrics or transpose chords during `build`.
library;

import '../../../domain/chordpro/parser.dart';
import '../../../domain/chordpro/transpose.dart';

final RegExp _wordChunkRegex = RegExp(r'\S+\s*|\s+');

/// One chord (already transposed, may be empty) above one lyric chunk.
class LyricToken {
  const LyricToken({required this.chord, required this.text});

  final String chord;
  final String text;
}

class PreparedMeasure {
  const PreparedMeasure({required this.chords, required this.endBarline});

  /// Transposed chord symbols.
  final List<String> chords;
  final String endBarline;
}

class PreparedLine {
  const PreparedLine({
    required this.line,
    this.tokens = const [],
    this.measures = const [],
  });

  final LineAst line;

  /// Word-level chord/lyric cells (lyrics lines only).
  final List<LyricToken> tokens;

  /// Transposed measures (chord-section lines only).
  final List<PreparedMeasure> measures;

  String get type => line.type;
}

class PreparedSection {
  const PreparedSection({
    required this.section,
    required this.lines,
    required this.maxMeasures,
  });

  final SectionAst section;
  final List<PreparedLine> lines;

  /// Widest grid row, in measures.
  final int maxMeasures;

  String get type => section.type;

  /// Relative height used to balance the two-column layout.
  int get weight => (lines.isEmpty ? 1 : lines.length) + 2;
}

class PreparedSong {
  const PreparedSong({required this.sections, required this.uniqueChords});

  final List<PreparedSection> sections;

  /// Transposed chords in order of first appearance, without duplicates.
  final List<String> uniqueChords;

  /// Splits [sections] into two columns of roughly equal weight.
  (List<PreparedSection>, List<PreparedSection>) splitColumns() {
    final col1 = <PreparedSection>[];
    final col2 = <PreparedSection>[];
    final half = sections.fold<int>(0, (a, s) => a + s.weight) / 2;

    var current = 0;
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      if (col1.isEmpty ||
          (current + s.weight <= half && i < sections.length - 1)) {
        col1.add(s);
        current += s.weight;
      } else {
        col2.add(s);
      }
    }
    return (col1, col2);
  }
}

PreparedSong prepareSong(List<SectionAst> sections, int transpose) {
  final unique = <String>{};

  String t(String chord) {
    final out = transposeChord(chord, transpose);
    if (out.isNotEmpty) unique.add(out);
    return out;
  }

  final prepared = <PreparedSection>[];
  for (final section in sections) {
    var maxMeasures = 1;
    final lines = <PreparedLine>[];
    for (final line in section.lines) {
      switch (line.type) {
        case 'lyrics':
          lines.add(
            PreparedLine(
              line: line,
              tokens: _tokenize(line.segments ?? const [], t),
            ),
          );
        case 'chord-section':
          final measures = [
            for (final m in line.measures ?? const <MeasureAst>[])
              PreparedMeasure(
                chords: [
                  for (final c in m.chords)
                    if (c.chord.isNotEmpty) t(c.chord),
                ],
                endBarline: m.endBarline,
              ),
          ];
          if (measures.length > maxMeasures) maxMeasures = measures.length;
          lines.add(PreparedLine(line: line, measures: measures));
        default:
          lines.add(PreparedLine(line: line));
      }
    }
    prepared.add(
      PreparedSection(section: section, lines: lines, maxMeasures: maxMeasures),
    );
  }

  return PreparedSong(sections: prepared, uniqueChords: unique.toList());
}

/// Splits segments into word-sized cells so chords sit above the word they
/// start on and lines wrap word by word.
List<LyricToken> _tokenize(
  List<SegmentAst> segments,
  String Function(String) transpose,
) {
  final tokens = <LyricToken>[];
  for (final seg in segments) {
    final chord = seg.chord.isEmpty ? '' : transpose(seg.chord);
    final text = seg.text;
    if (text.isEmpty) {
      tokens.add(LyricToken(chord: chord, text: ''));
      continue;
    }

    final matches = _wordChunkRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      tokens.add(LyricToken(chord: chord, text: text));
      continue;
    }

    var chordAssigned = false;
    for (var i = 0; i < matches.length; i++) {
      final chunk = matches[i].group(0)!;
      final isWord = chunk.trim().isNotEmpty;
      if (!chordAssigned && (isWord || i == matches.length - 1)) {
        tokens.add(LyricToken(chord: chord, text: chunk));
        chordAssigned = true;
      } else {
        tokens.add(LyricToken(chord: '', text: chunk));
      }
    }
  }
  return tokens;
}
