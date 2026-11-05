/// Structured ChordPro diagnostics for the song editor.
///
/// Complements [parseChordProDocument] by mapping its string errors into
/// ranged diagnostics and adding extra checks (brackets, chords, sections,
/// metadata field formats) that the permissive parser intentionally ignores.
library;

import '../youtube.dart';
import 'chord_theory.dart';
import 'parser.dart';

enum ChordProSeverity { info, warning, error }

/// Stable diagnostic codes the UI can localize.
enum ChordProDiagnosticCode {
  parserError,
  unclosedBrace,
  unclosedBracket,
  emptyChord,
  unknownChord,
  malformedDirective,
  unclosedSection,
  unexpectedEndSection,
  invalidYoutube,
  invalidKey,
  invalidTempo,
  invalidCapo,
  invalidTimeSignature,
  invalidDuration,
}

class ChordProDiagnostic {
  const ChordProDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.line,
    required this.column,
    required this.offset,
    required this.length,
    this.args = const {},
  });

  final ChordProDiagnosticCode code;
  final ChordProSeverity severity;

  /// English fallback message (useful in tests / logs).
  final String message;

  /// 1-based line number in the linted source.
  final int line;

  /// 1-based column number in the linted source.
  final int column;

  /// 0-based UTF-16 offset into the linted source.
  final int offset;

  /// Length of the underlined range (UTF-16 code units).
  final int length;

  /// Interpolation args for localized messages (e.g. `chord`, `section`).
  final Map<String, String> args;
}

/// Known ChordPro / Hosanna directive names (canonical + aliases).
const Set<String> kKnownChordProDirectives = {
  'title',
  't',
  'subtitle',
  'st',
  'artist',
  'a',
  'composer',
  'lyricist',
  'translator',
  'arranger',
  'key',
  'k',
  'original_key',
  'original key',
  'originalkey',
  'tempo',
  'time',
  'time_signature',
  'timesignature',
  'time signature',
  'duration',
  'capo',
  'copyright',
  'ccli',
  'song_number',
  'songnumber',
  'key_note',
  'key note',
  'keynote',
  'key_notes',
  'key notes',
  'kn',
  'album',
  'year',
  'youtube',
  'yt',
  'tags',
  'comment',
  'c',
  'comment_italic',
  'ci',
  'comment_box',
  'cb',
  'start_of_chorus',
  'soc',
  'end_of_chorus',
  'eoc',
  'start_of_verse',
  'sov',
  'end_of_verse',
  'eov',
  'start_of_bridge',
  'sob',
  'end_of_bridge',
  'eob',
  'start_of_tab',
  'sot',
  'end_of_tab',
  'eot',
  'start_of_grid',
  'sog',
  'end_of_grid',
  'eog',
  'chorus',
  'ch',
  'verse',
  'v',
  'bridge',
  'b',
  'repeat',
  're',
  'new_song',
  'ns',
  'start_of_version',
  'sov_ver',
  'end_of_version',
  'eov_ver',
  'meta',
  'define',
};

const Set<String> _noChordTokens = {
  '',
  'n.c.',
  'nc',
  'n.c',
  'n/c',
  '-',
  '%',
  '*',
  'x',
  '/',
};

final RegExp _lineBreakRegex = RegExp(r'\r?\n');
final RegExp _chordTokenRegex = RegExp(r'\[([^\]]*)\]');
final RegExp _timingSuffixRegex = RegExp(r'^(.+?)@([0-9]*\.?[0-9]+)x$');
final RegExp _parserLineRegex = RegExp(r'^Line (\d+):\s*(.*)$');
final RegExp _unclosedVariantRegex = RegExp(
  r'variant "([^"]+)".*started at line (\d+)',
);
final RegExp _keyPattern = RegExp(
  r'^(?:[A-G](?:#|b)?|Do|Re|Ré|Mi|Fa|Fá|Sol|La|Lá|Si)'
  r'(?:\s*(?:m|min|minor|maj|major))?(?:\s*/\s*'
  r'(?:[A-G](?:#|b)?|Do|Re|Ré|Mi|Fa|Fá|Sol|La|Lá|Si))?$',
  caseSensitive: false,
);
final RegExp _timeSignaturePattern = RegExp(r'^\d{1,2}\s*/\s*\d{1,2}$');
final RegExp _durationPattern = RegExp(r'^(\d{1,3}:\d{2}|\d+)$');

class _OpenSection {
  const _OpenSection({
    required this.type,
    required this.line,
    required this.offset,
    required this.length,
  });

  final String type;
  final int line;
  final int offset;
  final int length;
}

/// Lints [content] and optional metadata field values.
///
/// Prefer passing the **body textarea** contents so diagnostic line numbers
/// match what the user sees. Pass form-field values for metadata checks that
/// the editor manages outside the body.
List<ChordProDiagnostic> lintChordPro(
  String content, {
  String? youtube,
  String? key,
  String? tempo,
  String? capo,
  String? timeSignature,
  String? duration,
}) {
  final diagnostics = <ChordProDiagnostic>[];
  final lines = content.split(_lineBreakRegex);

  _collectParserDiagnostics(content, diagnostics);
  _scanLines(content, lines, diagnostics);
  _lintMetadataFields(
    diagnostics,
    youtube: youtube,
    key: key,
    tempo: tempo,
    capo: capo,
    timeSignature: timeSignature,
    duration: duration,
  );

  diagnostics.sort((a, b) {
    final byLine = a.line.compareTo(b.line);
    if (byLine != 0) return byLine;
    final byCol = a.column.compareTo(b.column);
    if (byCol != 0) return byCol;
    return a.severity.index.compareTo(b.severity.index);
  });
  return diagnostics;
}

void _collectParserDiagnostics(
  String content,
  List<ChordProDiagnostic> out,
) {
  final doc = parseChordProDocument(content);
  for (final raw in doc.errors) {
    final lineMatch = _parserLineRegex.firstMatch(raw);
    if (lineMatch != null) {
      final line = int.parse(lineMatch.group(1)!);
      final message = lineMatch.group(2)!;
      final loc = _lineLocation(content, line);
      out.add(
        ChordProDiagnostic(
          code: ChordProDiagnosticCode.parserError,
          severity: ChordProSeverity.error,
          message: message,
          line: line,
          column: 1,
          offset: loc.offset,
          length: loc.length.clamp(1, 80),
          args: {'detail': message},
        ),
      );
      continue;
    }

    final variantMatch = _unclosedVariantRegex.firstMatch(raw);
    if (variantMatch != null) {
      final name = variantMatch.group(1)!;
      final line = int.parse(variantMatch.group(2)!);
      final loc = _lineLocation(content, line);
      out.add(
        ChordProDiagnostic(
          code: ChordProDiagnosticCode.parserError,
          severity: ChordProSeverity.error,
          message: raw,
          line: line,
          column: 1,
          offset: loc.offset,
          length: loc.length.clamp(1, 80),
          args: {'detail': raw, 'name': name},
        ),
      );
      continue;
    }

    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.parserError,
        severity: ChordProSeverity.error,
        message: raw,
        line: 1,
        column: 1,
        offset: 0,
        length: content.isEmpty ? 0 : 1,
        args: {'detail': raw},
      ),
    );
  }
}

void _scanLines(
  String content,
  List<String> lines,
  List<ChordProDiagnostic> out,
) {
  final openSections = <_OpenSection>[];
  var offset = 0;
  var inTab = false;

  for (var i = 0; i < lines.length; i++) {
    final lineNumber = i + 1;
    final rawLine = lines[i];
    final trimmed = rawLine.trim();
    final lineStart = offset;
    final leading = rawLine.length - rawLine.trimLeft().length;

    if (!inTab && trimmed.startsWith('#') && !trimmed.startsWith('#{')) {
      offset += rawLine.length + (i < lines.length - 1 ? 1 : 0);
      continue;
    }

    // Bracket / brace balance within the line (directives & chords).
    _scanDelimiters(rawLine, lineNumber, lineStart, out);

    if (trimmed.startsWith('{')) {
      final directiveEnd = trimmed.endsWith('}');
      if (!directiveEnd) {
        final braceOffset = lineStart + rawLine.indexOf('{');
        out.add(
          ChordProDiagnostic(
            code: ChordProDiagnosticCode.malformedDirective,
            severity: ChordProSeverity.error,
            message: 'Malformed directive — missing closing "}".',
            line: lineNumber,
            column: rawLine.indexOf('{') + 1,
            offset: braceOffset,
            length: rawLine.length - rawLine.indexOf('{'),
          ),
        );
      } else {
        final inner = trimmed.substring(1, trimmed.length - 1).trim();
        final colon = inner.indexOf(':');
        final rawName = (colon == -1 ? inner : inner.substring(0, colon))
            .trim();
        final lowerName = rawName.toLowerCase();
        final dirOffset = lineStart + leading;
        final dirLength = trimmed.length;

        if (rawName.isEmpty) {
          out.add(
            ChordProDiagnostic(
              code: ChordProDiagnosticCode.malformedDirective,
              severity: ChordProSeverity.error,
              message: 'Empty directive name.',
              line: lineNumber,
              column: leading + 1,
              offset: dirOffset,
              length: dirLength,
            ),
          );
        } else if (!kKnownChordProDirectives.contains(lowerName) &&
            !lowerName.startsWith('meta ')) {
          out.add(
            ChordProDiagnostic(
              code: ChordProDiagnosticCode.malformedDirective,
              severity: ChordProSeverity.info,
              message: 'Unrecognized directive "{$rawName}".',
              line: lineNumber,
              column: leading + 1,
              offset: dirOffset,
              length: dirLength,
              args: {'name': rawName},
            ),
          );
        }

        _handleSectionDirective(
          lowerName: lowerName,
          lineNumber: lineNumber,
          offset: dirOffset,
          length: dirLength,
          openSections: openSections,
          out: out,
          onTab: (v) => inTab = v,
        );
      }
    } else if (!inTab) {
      for (final match in _chordTokenRegex.allMatches(rawLine)) {
        final rawChord = match.group(1) ?? '';
        final chordOffset = lineStart + match.start;
        final chordLength = match.end - match.start;
        final column = match.start + 1;

        if (rawChord.trim().isEmpty) {
          out.add(
            ChordProDiagnostic(
              code: ChordProDiagnosticCode.emptyChord,
              severity: ChordProSeverity.warning,
              message: 'Empty chord brackets [].',
              line: lineNumber,
              column: column,
              offset: chordOffset,
              length: chordLength,
            ),
          );
          continue;
        }

        final timingMatch = _timingSuffixRegex.firstMatch(rawChord.trim());
        final symbol =
            (timingMatch?.group(1) ?? rawChord).trim().replaceAll('()', '');
        final normalized = symbol.toLowerCase();
        if (_noChordTokens.contains(normalized)) continue;

        if (parseChordSymbol(symbol) == null) {
          out.add(
            ChordProDiagnostic(
              code: ChordProDiagnosticCode.unknownChord,
              severity: ChordProSeverity.warning,
              message: 'Unrecognized chord "$symbol".',
              line: lineNumber,
              column: column,
              offset: chordOffset,
              length: chordLength,
              args: {'chord': symbol},
            ),
          );
        }
      }
    }

    offset += rawLine.length + (i < lines.length - 1 ? 1 : 0);
  }

  for (final open in openSections) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.unclosedSection,
        severity: ChordProSeverity.warning,
        message:
            'Unclosed ${open.type} section — missing "{end_of_${open.type}}".',
        line: open.line,
        column: 1,
        offset: open.offset,
        length: open.length,
        args: {'section': open.type},
      ),
    );
  }
}

void _handleSectionDirective({
  required String lowerName,
  required int lineNumber,
  required int offset,
  required int length,
  required List<_OpenSection> openSections,
  required List<ChordProDiagnostic> out,
  required void Function(bool) onTab,
}) {
  String? startType;
  switch (lowerName) {
    case 'start_of_chorus':
    case 'soc':
      startType = 'chorus';
    case 'start_of_verse':
    case 'sov':
      startType = 'verse';
    case 'start_of_bridge':
    case 'sob':
      startType = 'bridge';
    case 'start_of_tab':
    case 'sot':
      startType = 'tab';
      onTab(true);
    case 'start_of_grid':
    case 'sog':
      startType = 'grid';
    case 'chorus':
    case 'ch':
    case 'verse':
    case 'v':
    case 'bridge':
    case 'b':
      // Shorthand section markers — parser soft-closes; no end required.
      return;
  }

  if (startType != null) {
    // Match the parser: opening a section soft-closes the previous one.
    if (openSections.isNotEmpty) openSections.removeLast();
    openSections.add(
      _OpenSection(
        type: startType,
        line: lineNumber,
        offset: offset,
        length: length,
      ),
    );
    return;
  }

  String? endType;
  switch (lowerName) {
    case 'end_of_chorus':
    case 'eoc':
      endType = 'chorus';
    case 'end_of_verse':
    case 'eov':
      endType = 'verse';
    case 'end_of_bridge':
    case 'eob':
      endType = 'bridge';
    case 'end_of_tab':
    case 'eot':
      endType = 'tab';
      onTab(false);
    case 'end_of_grid':
    case 'eog':
      endType = 'grid';
  }

  if (endType == null) return;

  final idx = openSections.lastIndexWhere((s) => s.type == endType);
  if (idx == -1) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.unexpectedEndSection,
        severity: ChordProSeverity.warning,
        message: 'Unexpected "{end_of_$endType}" with no matching start.',
        line: lineNumber,
        column: 1,
        offset: offset,
        length: length,
        args: {'section': endType},
      ),
    );
    return;
  }
  openSections.removeAt(idx);
}

void _scanDelimiters(
  String line,
  int lineNumber,
  int lineStart,
  List<ChordProDiagnostic> out,
) {
  final braceStack = <int>[];
  final bracketStack = <int>[];

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '{') {
      braceStack.add(i);
    } else if (ch == '}') {
      if (braceStack.isEmpty) {
        out.add(
          ChordProDiagnostic(
            code: ChordProDiagnosticCode.unclosedBrace,
            severity: ChordProSeverity.error,
            message: 'Unexpected closing "}".',
            line: lineNumber,
            column: i + 1,
            offset: lineStart + i,
            length: 1,
          ),
        );
      } else {
        braceStack.removeLast();
      }
    } else if (ch == '[') {
      bracketStack.add(i);
    } else if (ch == ']') {
      if (bracketStack.isEmpty) {
        out.add(
          ChordProDiagnostic(
            code: ChordProDiagnosticCode.unclosedBracket,
            severity: ChordProSeverity.error,
            message: 'Unexpected closing "]".',
            line: lineNumber,
            column: i + 1,
            offset: lineStart + i,
            length: 1,
          ),
        );
      } else {
        bracketStack.removeLast();
      }
    }
  }

  for (final start in braceStack) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.unclosedBrace,
        severity: ChordProSeverity.error,
        message: 'Unclosed "{".',
        line: lineNumber,
        column: start + 1,
        offset: lineStart + start,
        length: line.length - start,
      ),
    );
  }
  for (final start in bracketStack) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.unclosedBracket,
        severity: ChordProSeverity.error,
        message: 'Unclosed "[".',
        line: lineNumber,
        column: start + 1,
        offset: lineStart + start,
        length: line.length - start,
      ),
    );
  }
}

void _lintMetadataFields(
  List<ChordProDiagnostic> out, {
  String? youtube,
  String? key,
  String? tempo,
  String? capo,
  String? timeSignature,
  String? duration,
}) {
  final yt = youtube?.trim();
  if (yt != null && yt.isNotEmpty && parseYoutubeVideoId(yt) == null) {
    out.add(
      const ChordProDiagnostic(
        code: ChordProDiagnosticCode.invalidYoutube,
        severity: ChordProSeverity.warning,
        message: 'YouTube value is not a recognized video URL or ID.',
        line: 0,
        column: 0,
        offset: 0,
        length: 0,
      ),
    );
  }

  final k = key?.trim();
  if (k != null && k.isNotEmpty && !_keyPattern.hasMatch(k)) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.invalidKey,
        severity: ChordProSeverity.warning,
        message: 'Unusual key "$k". Expected something like G, Am, or F#m.',
        line: 0,
        column: 0,
        offset: 0,
        length: 0,
        args: {'value': k},
      ),
    );
  }

  final t = tempo?.trim();
  if (t != null && t.isNotEmpty) {
    final bpm = int.tryParse(t);
    if (bpm == null || bpm < 20 || bpm > 400) {
      out.add(
        ChordProDiagnostic(
          code: ChordProDiagnosticCode.invalidTempo,
          severity: ChordProSeverity.warning,
          message: 'Tempo should be a BPM number between 20 and 400.',
          line: 0,
          column: 0,
          offset: 0,
          length: 0,
          args: {'value': t},
        ),
      );
    }
  }

  final c = capo?.trim();
  if (c != null && c.isNotEmpty) {
    final fret = int.tryParse(c);
    if (fret == null || fret < 0 || fret > 12) {
      out.add(
        ChordProDiagnostic(
          code: ChordProDiagnosticCode.invalidCapo,
          severity: ChordProSeverity.warning,
          message: 'Capo should be a fret number from 0 to 12.',
          line: 0,
          column: 0,
          offset: 0,
          length: 0,
          args: {'value': c},
        ),
      );
    }
  }

  final ts = timeSignature?.trim();
  if (ts != null && ts.isNotEmpty && !_timeSignaturePattern.hasMatch(ts)) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.invalidTimeSignature,
        severity: ChordProSeverity.warning,
        message: 'Time signature should look like 4/4 or 6/8.',
        line: 0,
        column: 0,
        offset: 0,
        length: 0,
        args: {'value': ts},
      ),
    );
  }

  final d = duration?.trim();
  if (d != null && d.isNotEmpty && !_durationPattern.hasMatch(d)) {
    out.add(
      ChordProDiagnostic(
        code: ChordProDiagnosticCode.invalidDuration,
        severity: ChordProSeverity.warning,
        message: 'Duration should be seconds or m:ss (e.g. 3:45).',
        line: 0,
        column: 0,
        offset: 0,
        length: 0,
        args: {'value': d},
      ),
    );
  }
}

({int offset, int length}) _lineLocation(String content, int lineNumber) {
  final lines = content.split(_lineBreakRegex);
  if (lineNumber < 1 || lineNumber > lines.length) {
    return (offset: 0, length: content.isEmpty ? 0 : 1);
  }
  var offset = 0;
  for (var i = 0; i < lineNumber - 1; i++) {
    offset += lines[i].length + 1;
  }
  return (offset: offset, length: lines[lineNumber - 1].length);
}

int countDiagnosticsBySeverity(
  List<ChordProDiagnostic> diagnostics,
  ChordProSeverity severity,
) =>
    diagnostics.where((d) => d.severity == severity).length;
