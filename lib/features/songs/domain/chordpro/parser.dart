/// ChordPro parser, ported faithfully from `@hosanna/shared/src/chordpro/parser.ts`.
///
/// Produces a [SongAst] that the renderer consumes. Section labels are stored
/// as-authored (empty when the directive carried no value); the renderer is
/// responsible for localizing the default labels.
library;

class SegmentAst {
  const SegmentAst({required this.chord, required this.text, this.timing});

  final String chord;
  final String text;
  final double? timing;
}

class MeasureAst {
  const MeasureAst({required this.chords, required this.endBarline});

  final List<SegmentAst> chords;
  final String endBarline;
}

class LineAst {
  const LineAst({
    required this.type,
    this.text,
    this.segments,
    this.measures,
    this.startBarline,
  });

  final String type; // lyrics | comment | comment_box | tab | empty | chord-section
  final String? text;
  final List<SegmentAst>? segments;
  final List<MeasureAst>? measures;
  final String? startBarline;
}

class SectionAst {
  SectionAst({
    required this.type,
    this.label,
    List<LineAst>? lines,
    this.repeat,
  }) : lines = lines ?? [];

  final String type; // verse | chorus | bridge | tab | comment | grid | new_song
  final String? label;
  final List<LineAst> lines;
  String? repeat;
}

class SongAst {
  const SongAst({required this.metadata, required this.sections});

  final Map<String, String> metadata;
  final List<SectionAst> sections;
}

final RegExp _timingRegex = RegExp(r'^(.+?)@([0-9]*\.?[0-9]+)x$');
final RegExp _chordRegex = RegExp(r'\[([^\]]+)\]');

({String chord, double? timing}) _parseChordTiming(String rawChord) {
  final match = _timingRegex.firstMatch(rawChord);
  if (match != null) {
    return (
      chord: match.group(1)!,
      timing: double.tryParse(match.group(2)!),
    );
  }
  return (chord: rawChord, timing: null);
}

List<SegmentAst> parseLineSegments(String lineText) {
  final segments = <SegmentAst>[];
  var lastIndex = 0;
  var currentChord = '';
  double? currentTiming;

  for (final match in _chordRegex.allMatches(lineText)) {
    final rawChord = match.group(1)!;
    final parsed = _parseChordTiming(rawChord);
    final chord = parsed.chord;
    final timing = parsed.timing;
    final textBefore = lineText.substring(lastIndex, match.start);

    if (lastIndex == 0 && textBefore.isEmpty) {
      currentChord = chord;
      currentTiming = timing;
    } else {
      segments.add(
        SegmentAst(chord: currentChord, text: textBefore, timing: currentTiming),
      );
      currentChord = chord;
      currentTiming = timing;
    }
    lastIndex = match.end;
  }

  final remainingText = lineText.substring(lastIndex);
  segments.add(
    SegmentAst(chord: currentChord, text: remainingText, timing: currentTiming),
  );

  return segments;
}

const Map<String, String> _aliasMap = {
  't': 'title',
  'st': 'subtitle',
  'a': 'artist',
  'k': 'key',
  'c': 'comment',
  'ci': 'comment_italic',
  'cb': 'comment_box',
  'soc': 'start_of_chorus',
  'eoc': 'end_of_chorus',
  'sov': 'start_of_verse',
  'eov': 'end_of_verse',
  'sob': 'start_of_bridge',
  'eob': 'end_of_bridge',
  'sot': 'start_of_tab',
  'eot': 'end_of_tab',
  'sog': 'start_of_grid',
  'eog': 'end_of_grid',
  'ch': 'chorus',
  'v': 'verse',
  'b': 'bridge',
  're': 'repeat',
  'ns': 'new_song',
  'time_signature': 'time',
  'timesignature': 'time',
  'time signature': 'time',
  'original_key': 'original_key',
  'original key': 'original_key',
};

String _camelCaseMetaKey(String name) {
  return name
      .replaceAllMapped(
        RegExp(r'[-_\s]+([a-zA-Z])'),
        (m) => m.group(1)!.toUpperCase(),
      )
      .replaceAll(RegExp(r'\s+'), '');
}

SongAst parseChordPro(String content) {
  final lines = content.split(RegExp(r'\r?\n'));
  final metadata = <String, String>{};
  final sections = <SectionAst>[];

  SectionAst? currentSection;
  var isTab = false;
  var isGrid = false;
  var lastChorusLines = <LineAst>[];

  void commitSection() {
    final section = currentSection;
    if (section == null) return;
    sections.add(section);
    if (section.type == 'chorus') {
      lastChorusLines = List.of(section.lines);
    }
    currentSection = null;
  }

  for (final rawLine in lines) {
    final line = rawLine;
    final trimmed = line.trim();

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final directive = trimmed.substring(1, trimmed.length - 1).trim();
      final colonIndex = directive.indexOf(':');
      var rawName = directive;
      var value = '';

      if (colonIndex != -1) {
        rawName = directive.substring(0, colonIndex).trim();
        value = directive.substring(colonIndex + 1).trim();
      }

      final lowerName = rawName.toLowerCase();
      final name = _aliasMap[lowerName] ?? lowerName;

      switch (name) {
        case 'start_of_chorus':
          commitSection();
          currentSection =
              SectionAst(type: 'chorus', label: value);
        case 'start_of_verse':
          commitSection();
          currentSection =
              SectionAst(type: 'verse', label: value);
        case 'start_of_bridge':
          commitSection();
          currentSection =
              SectionAst(type: 'bridge', label: value);
        case 'start_of_tab':
          commitSection();
          isTab = true;
          currentSection =
              SectionAst(type: 'tab', label: value);
        case 'start_of_grid':
          commitSection();
          isGrid = true;
          currentSection =
              SectionAst(type: 'grid', label: value);
        case 'end_of_chorus':
          if (currentSection?.type == 'chorus') commitSection();
        case 'end_of_verse':
          if (currentSection?.type == 'verse') commitSection();
        case 'end_of_bridge':
          if (currentSection?.type == 'bridge') commitSection();
        case 'end_of_tab':
          isTab = false;
          if (currentSection?.type == 'tab') commitSection();
        case 'end_of_grid':
          isGrid = false;
          if (currentSection?.type == 'grid') commitSection();
        case 'chorus':
          commitSection();
          sections.add(
            SectionAst(type: 'chorus', label: value, lines: [...lastChorusLines]),
          );
        case 'verse':
          commitSection();
          currentSection =
              SectionAst(type: 'verse', label: value);
        case 'bridge':
          commitSection();
          currentSection =
              SectionAst(type: 'bridge', label: value);
        case 'comment':
        case 'comment_italic':
          final commentLine = LineAst(type: 'comment', text: value);
          if (currentSection != null) {
            currentSection!.lines.add(commentLine);
          } else {
            sections.add(SectionAst(type: 'comment', lines: [commentLine]));
          }
        case 'comment_box':
          final cbLine = LineAst(type: 'comment_box', text: value);
          if (currentSection != null) {
            currentSection!.lines.add(cbLine);
          } else {
            sections.add(SectionAst(type: 'comment', lines: [cbLine]));
          }
        case 'repeat':
          final repeat = value.isEmpty ? '2' : value;
          if (currentSection != null) {
            currentSection!.repeat = repeat;
          } else {
            sections.add(
              SectionAst(
                type: 'comment',
                lines: [LineAst(type: 'comment_box', text: 'Repetir: $repeat')],
              ),
            );
          }
        case 'new_song':
          commitSection();
          sections.add(SectionAst(type: 'new_song', lines: []));
        case 'duration':
          if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) {
            final parts = value.split(':').map(int.parse).toList();
            metadata['duration'] = '${parts[0] * 60 + parts[1]}';
          } else {
            metadata['duration'] = value;
          }
        default:
          if (value.isNotEmpty) {
            final metaKey = _camelCaseMetaKey(name);
            metadata[metaKey] = value;
          }
      }
      continue;
    }

    if (trimmed.isEmpty) {
      if (currentSection != null) {
        currentSection!.lines.add(const LineAst(type: 'empty'));
      }
      continue;
    }

    if (trimmed.startsWith('#') && !isTab) continue;

    var lineType = 'lyrics';
    var parsedSegments = <SegmentAst>[];

    if (isTab) {
      lineType = 'tab';
    } else {
      parsedSegments = parseLineSegments(line);
      final textContent = parsedSegments.map((s) => s.text).join();
      final onlyBarsAndSpaces = RegExp(r'^[\s|:\-.%]*$').hasMatch(textContent);
      final hasBars = textContent.contains('|');

      if (isGrid || (onlyBarsAndSpaces && hasBars)) {
        lineType = 'chord-section';
      }
    }

    var parsedLine = LineAst(type: lineType);

    if (lineType == 'tab') {
      parsedLine = LineAst(type: 'tab', text: line);
    } else if (lineType == 'lyrics') {
      parsedLine = LineAst(type: 'lyrics', segments: parsedSegments);
    } else if (lineType == 'chord-section') {
      final measures = <MeasureAst>[];
      var currentChords = <SegmentAst>[];
      var startBarline = '';
      var hasSeenChord = false;
      var startBarlineFound = false;

      for (final seg in parsedSegments) {
        if (seg.chord.isNotEmpty) {
          currentChords.add(SegmentAst(chord: seg.chord, text: '', timing: seg.timing));
          hasSeenChord = true;
        }

        final barlineMatches = RegExp(r'\|\||:\||\|:|\|').allMatches(seg.text);
        for (final m in barlineMatches) {
          final b = m.group(0)!;
          if (!hasSeenChord && !startBarlineFound) {
            startBarline = b;
            startBarlineFound = true;
          } else {
            measures.add(MeasureAst(chords: currentChords, endBarline: b));
            currentChords = [];
          }
        }
      }

      if (currentChords.isNotEmpty) {
        measures.add(MeasureAst(chords: currentChords, endBarline: ''));
      }

      parsedLine = LineAst(
        type: 'chord-section',
        segments: parsedSegments,
        measures: measures,
        startBarline: startBarline,
      );
    }

    currentSection ??= SectionAst(type: 'verse', lines: []);
    currentSection!.lines.add(parsedLine);
  }

  commitSection();
  if (!metadata.containsKey('title')) metadata['title'] = 'Sem Título';

  return SongAst(metadata: metadata, sections: sections);
}
