/// Lightweight ChordPro tokenizer for syntax highlighting.
///
/// Presentation-only — does not replace [parseChordProDocument]. Persist raw
/// ChordPro strings; never store token spans.
library;

enum ChordProTokenType {
  text,
  comment,
  directiveBrace,
  directiveName,
  directiveColon,
  directiveValue,
  sectionDirective,
  chordBrace,
  chord,
  barline,
}

class ChordProToken {
  const ChordProToken({
    required this.type,
    required this.start,
    required this.end,
  });

  final ChordProTokenType type;
  final int start;
  final int end;

  int get length => end - start;
}

const Set<String> _sectionDirectiveNames = {
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
  'start_of_version',
  'sov_ver',
  'end_of_version',
  'eov_ver',
  'new_song',
  'ns',
  'repeat',
  're',
};

final RegExp _lineBreakRegex = RegExp(r'\r?\n');

/// Tokenizes [source] into non-overlapping spans covering the full string.
List<ChordProToken> tokenizeChordPro(String source) {
  if (source.isEmpty) return const [];

  final tokens = <ChordProToken>[];
  final lines = source.split(_lineBreakRegex);
  var offset = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    _tokenizeLine(line, offset, tokens);
    offset += line.length;
    if (i < lines.length - 1) {
      // Preserve newline as plain text so indices stay aligned.
      tokens.add(
        ChordProToken(
          type: ChordProTokenType.text,
          start: offset,
          end: offset + 1,
        ),
      );
      offset += 1;
    }
  }

  return _coalesce(tokens);
}

void _tokenizeLine(String line, int lineStart, List<ChordProToken> out) {
  final trimmed = line.trimLeft();
  final leading = line.length - trimmed.length;

  if (trimmed.startsWith('#') && !trimmed.startsWith('#{')) {
    if (leading > 0) {
      out.add(
        ChordProToken(
          type: ChordProTokenType.text,
          start: lineStart,
          end: lineStart + leading,
        ),
      );
    }
    out.add(
      ChordProToken(
        type: ChordProTokenType.comment,
        start: lineStart + leading,
        end: lineStart + line.length,
      ),
    );
    return;
  }

  var i = 0;
  while (i < line.length) {
    final ch = line[i];
    if (ch == '{') {
      final close = line.indexOf('}', i + 1);
      if (close == -1) {
        out.add(
          ChordProToken(
            type: ChordProTokenType.directiveBrace,
            start: lineStart + i,
            end: lineStart + line.length,
          ),
        );
        return;
      }
      _tokenizeDirective(line, lineStart, i, close, out);
      i = close + 1;
      continue;
    }
    if (ch == '[') {
      final close = line.indexOf(']', i + 1);
      if (close == -1) {
        out.add(
          ChordProToken(
            type: ChordProTokenType.chordBrace,
            start: lineStart + i,
            end: lineStart + line.length,
          ),
        );
        return;
      }
      out.add(
        ChordProToken(
          type: ChordProTokenType.chordBrace,
          start: lineStart + i,
          end: lineStart + i + 1,
        ),
      );
      if (close > i + 1) {
        out.add(
          ChordProToken(
            type: ChordProTokenType.chord,
            start: lineStart + i + 1,
            end: lineStart + close,
          ),
        );
      }
      out.add(
        ChordProToken(
          type: ChordProTokenType.chordBrace,
          start: lineStart + close,
          end: lineStart + close + 1,
        ),
      );
      i = close + 1;
      continue;
    }
    if (ch == '|' || (ch == ':' && _isBarish(line, i))) {
      final end = _consumeBarline(line, i);
      out.add(
        ChordProToken(
          type: ChordProTokenType.barline,
          start: lineStart + i,
          end: lineStart + end,
        ),
      );
      i = end;
      continue;
    }

    // Consume plain text until next special.
    var j = i + 1;
    while (j < line.length) {
      final c = line[j];
      if (c == '{' || c == '[' || c == '|' || (c == ':' && _isBarish(line, j))) {
        break;
      }
      j++;
    }
    out.add(
      ChordProToken(
        type: ChordProTokenType.text,
        start: lineStart + i,
        end: lineStart + j,
      ),
    );
    i = j;
  }
}

void _tokenizeDirective(
  String line,
  int lineStart,
  int open,
  int close,
  List<ChordProToken> out,
) {
  out.add(
    ChordProToken(
      type: ChordProTokenType.directiveBrace,
      start: lineStart + open,
      end: lineStart + open + 1,
    ),
  );

  final inner = line.substring(open + 1, close);
  final innerStart = open + 1;
  final colon = inner.indexOf(':');
  final namePart = colon == -1 ? inner : inner.substring(0, colon);
  final nameTrimmed = namePart.trim();
  final nameLeading = namePart.length - namePart.trimLeft().length;
  final nameStart = innerStart + nameLeading;
  final nameEnd = nameStart + nameTrimmed.length;
  final lower = nameTrimmed.toLowerCase();
  final isSection = _sectionDirectiveNames.contains(lower);

  if (nameLeading > 0) {
    out.add(
      ChordProToken(
        type: ChordProTokenType.text,
        start: lineStart + innerStart,
        end: lineStart + nameStart,
      ),
    );
  }
  if (nameTrimmed.isNotEmpty) {
    out.add(
      ChordProToken(
        type: isSection
            ? ChordProTokenType.sectionDirective
            : ChordProTokenType.directiveName,
        start: lineStart + nameStart,
        end: lineStart + nameEnd,
      ),
    );
  }

  if (colon != -1) {
    final colonAbs = innerStart + colon;
    // whitespace between name and colon
    if (nameEnd < colonAbs) {
      out.add(
        ChordProToken(
          type: ChordProTokenType.text,
          start: lineStart + nameEnd,
          end: lineStart + colonAbs,
        ),
      );
    }
    out.add(
      ChordProToken(
        type: ChordProTokenType.directiveColon,
        start: lineStart + colonAbs,
        end: lineStart + colonAbs + 1,
      ),
    );
    final valueStart = colonAbs + 1;
    if (valueStart < close) {
      out.add(
        ChordProToken(
          type: ChordProTokenType.directiveValue,
          start: lineStart + valueStart,
          end: lineStart + close,
        ),
      );
    }
  } else if (nameEnd < close) {
    out.add(
      ChordProToken(
        type: ChordProTokenType.text,
        start: lineStart + nameEnd,
        end: lineStart + close,
      ),
    );
  }

  out.add(
    ChordProToken(
      type: ChordProTokenType.directiveBrace,
      start: lineStart + close,
      end: lineStart + close + 1,
    ),
  );
}

bool _isBarish(String line, int i) {
  // Treat ":|" / "|:" style tokens; lone ":" in lyrics stays text.
  if (i + 1 < line.length && line[i + 1] == '|') return true;
  if (i > 0 && line[i - 1] == '|') return true;
  return false;
}

int _consumeBarline(String line, int i) {
  // Match || |: :| |] |
  if (i + 1 < line.length) {
    final two = line.substring(i, i + 2);
    if (two == '||' || two == '|:' || two == ':|' || two == '|]') {
      return i + 2;
    }
  }
  if (line[i] == '|') return i + 1;
  if (line[i] == ':' && i + 1 < line.length && line[i + 1] == '|') {
    return i + 2;
  }
  return i + 1;
}

List<ChordProToken> _coalesce(List<ChordProToken> tokens) {
  if (tokens.isEmpty) return tokens;
  final out = <ChordProToken>[];
  var current = tokens.first;
  for (var i = 1; i < tokens.length; i++) {
    final next = tokens[i];
    if (next.type == current.type && next.start == current.end) {
      current = ChordProToken(
        type: current.type,
        start: current.start,
        end: next.end,
      );
    } else {
      out.add(current);
      current = next;
    }
  }
  out.add(current);
  return out;
}
