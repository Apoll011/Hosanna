/// ChordPro parser, ported faithfully from `@hosanna/shared/src/chordpro/parser.ts`.
///
/// Produces a [SongAst] that the renderer consumes. Section labels are stored
/// as-authored (empty when the directive carried no value); the renderer is
/// responsible for localizing the default labels.
///
/// Also exposes [parseChordProDocument] / [selectVersion] for the song-variants
/// system: one `.pro` file can contain a default song plus unlimited alternative
/// versions wrapped in `{start_of_version: Name}` … `{end_of_version}` blocks.
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

  final String
  type; // lyrics | comment | comment_box | tab | empty | chord-section
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

  final String
  type; // verse | chorus | bridge | tab | comment | grid | new_song
  final String? label;
  final List<LineAst> lines;
  String? repeat;
}

/// One version of the song (either the default or a named variant).
class ChordProVersion {
  const ChordProVersion({
    required this.id,
    required this.name,
    required this.metadata,
    required this.body,
  });

  /// Stable slug identifier (e.g., "versao-de-estudio").
  final String id;

  /// Human-readable name as authored (e.g., "Versão de Estúdio").
  final String name;

  /// Fully resolved (inherited + overridden) metadata map.
  final Map<String, String> metadata;

  /// The song body sections for this version.
  final List<SectionAst> body;
}

/// A parsed ChordPro document that may contain the default version and
/// zero or more named variant versions.
class ChordProDocument {
  const ChordProDocument({
    required this.defaultVersion,
    required this.variants,
    required this.errors,
  });

  /// The default version (everything outside of `{start_of_version}` blocks).
  final ChordProVersion defaultVersion;

  /// Named variant versions in order of appearance.
  final List<ChordProVersion> variants;

  /// Non-fatal parse errors (e.g., nested/unclosed/duplicate blocks).
  final List<String> errors;
}

/// Backward-compatible flat AST used by existing code.
class SongAst {
  const SongAst({
    required this.metadata,
    required this.sections,
    this.defaultVersion,
    this.variants,
    this.errors,
  });

  final Map<String, String> metadata;
  final List<SectionAst> sections;

  /// The full document default version (same data as above, typed).
  final ChordProVersion? defaultVersion;

  /// Named variants, if any.
  final List<ChordProVersion>? variants;

  /// Parse errors.
  final List<String>? errors;
}

final RegExp _timingRegex = RegExp(r'^(.+?)@([0-9]*\.?[0-9]+)x$');
final RegExp _chordRegex = RegExp(r'\[([^\]]+)\]');

({String chord, double? timing}) _parseChordTiming(String rawChord) {
  final match = _timingRegex.firstMatch(rawChord);
  if (match != null) {
    return (chord: match.group(1)!, timing: double.tryParse(match.group(2)!));
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
        SegmentAst(
          chord: currentChord,
          text: textBefore,
          timing: currentTiming,
        ),
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
  // variant directives
  'start_of_version': 'start_of_version',
  'end_of_version': 'end_of_version',
  'sov_ver': 'start_of_version',
  'eov_ver': 'end_of_version',
};

String _camelCaseMetaKey(String name) {
  return name
      .replaceAllMapped(
        RegExp(r'[-_\s]+([a-zA-Z])'),
        (m) => m.group(1)!.toUpperCase(),
      )
      .replaceAll(RegExp(r'\s+'), '');
}

/// Converts an accented/special-character variant name into a stable ASCII slug.
///
/// Examples:
/// - "Simplificada"      → "simplificada"
/// - "Versão de Estúdio" → "versao-de-estudio"
/// - "  Ao Vivo (2024)!" → "ao-vivo-2024"
String slugifyVariantName(String name) {
  // Remove combining diacritical marks by filtering code units in the NFD range
  final withoutDiacritics = String.fromCharCodes(
    name.runes.where((r) => !(r >= 0x0300 && r <= 0x036F)),
  );
  return withoutDiacritics
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

// ── Version parsing context ─────────────────────────────────────────────────

class _VersionContext {
  _VersionContext({
    required this.id,
    required this.name,
    required this.metadata,
    required this.startLineNumber,
  });

  final String id;
  final String name;
  final Map<String, String> metadata;
  final int startLineNumber;

  final List<SectionAst> sections = [];
  SectionAst? currentSection;
  bool isTab = false;
  bool isGrid = false;
  List<LineAst> lastChorusLines = [];

  void commitSection() {
    final s = currentSection;
    if (s == null) return;
    sections.add(s);
    if (s.type == 'chorus') lastChorusLines = List.of(s.lines);
    currentSection = null;
  }
}

// ── Main document parser ────────────────────────────────────────────────────

/// Parses a ChordPro string into a [ChordProDocument] that separates the
/// default version from any named variant versions.
///
/// Variants are defined with:
/// ```
/// {start_of_version: Name}
/// ...
/// {end_of_version}
/// ```
///
/// Metadata is cumulative: each variant inherits the fully resolved metadata
/// of the previous version.
ChordProDocument parseChordProDocument(String content) {
  final lines = content.split(RegExp(r'\r?\n'));
  final errors = <String>[];

  final defaultCtx = _VersionContext(
    id: 'default',
    name: 'Padrão',
    metadata: {},
    startLineNumber: 1,
  );

  final variants = <ChordProVersion>[];
  final seenIds = <String>{};
  _VersionContext? activeVariant;

  for (var i = 0; i < lines.length; i++) {
    final lineNumber = i + 1;
    final rawLine = lines[i];
    final trimmed = rawLine.trim();

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

      // ── Version block directives ────────────────────────────────────────
      if (name == 'start_of_version') {
        if (activeVariant != null) {
          errors.add(
            'Line $lineNumber: Nested version block detected. '
            '"{start_of_version}" cannot be inside another version block.',
          );
          continue;
        }

        final versionName = value.trim();
        if (versionName.isEmpty) {
          errors.add(
            'Line $lineNumber: Empty version name in "{start_of_version}".',
          );
          continue;
        }

        final variantId = slugifyVariantName(versionName);
        if (variantId.isEmpty ||
            variantId == 'default' ||
            seenIds.contains(variantId)) {
          errors.add(
            'Line $lineNumber: Duplicate or invalid variant identifier '
            '"${variantId.isEmpty ? versionName : variantId}".',
          );
          continue;
        }

        defaultCtx.commitSection();
        seenIds.add(variantId);

        // Cumulative metadata: inherit from the previous variant or default
        final previousMeta = variants.isNotEmpty
            ? Map<String, String>.of(variants.last.metadata)
            : Map<String, String>.of(defaultCtx.metadata);

        activeVariant = _VersionContext(
          id: variantId,
          name: versionName,
          metadata: previousMeta,
          startLineNumber: lineNumber,
        );
        continue;
      }

      if (name == 'end_of_version') {
        if (activeVariant == null) {
          errors.add(
            'Line $lineNumber: Unexpected "{end_of_version}" '
            'without an active version block.',
          );
          continue;
        }

        activeVariant.commitSection();
        final meta = activeVariant.metadata;
        if (!meta.containsKey('title') || meta['title']!.isEmpty) {
          meta['title'] = defaultCtx.metadata['title'] ?? 'Sem Título';
        }

        variants.add(
          ChordProVersion(
            id: activeVariant.id,
            name: activeVariant.name,
            metadata: Map.of(meta),
            body: List.of(activeVariant.sections),
          ),
        );
        activeVariant = null;
        continue;
      }

      // ── Normal directive — dispatch to the active context ───────────────
      final ctx = activeVariant ?? defaultCtx;

      switch (name) {
        case 'start_of_chorus':
          ctx.commitSection();
          ctx.currentSection = SectionAst(type: 'chorus', label: value);
        case 'start_of_verse':
          ctx.commitSection();
          ctx.currentSection = SectionAst(type: 'verse', label: value);
        case 'start_of_bridge':
          ctx.commitSection();
          ctx.currentSection = SectionAst(type: 'bridge', label: value);
        case 'start_of_tab':
          ctx.commitSection();
          ctx.isTab = true;
          ctx.currentSection = SectionAst(type: 'tab', label: value);
        case 'start_of_grid':
          ctx.commitSection();
          ctx.isGrid = true;
          ctx.currentSection = SectionAst(type: 'grid', label: value);
        case 'end_of_chorus':
          if (ctx.currentSection?.type == 'chorus') ctx.commitSection();
        case 'end_of_verse':
          if (ctx.currentSection?.type == 'verse') ctx.commitSection();
        case 'end_of_bridge':
          if (ctx.currentSection?.type == 'bridge') ctx.commitSection();
        case 'end_of_tab':
          ctx.isTab = false;
          if (ctx.currentSection?.type == 'tab') ctx.commitSection();
        case 'end_of_grid':
          ctx.isGrid = false;
          if (ctx.currentSection?.type == 'grid') ctx.commitSection();
        case 'chorus':
          ctx.commitSection();
          ctx.sections.add(
            SectionAst(
              type: 'chorus',
              label: value,
              lines: [...ctx.lastChorusLines],
            ),
          );
        case 'verse':
          ctx.commitSection();
          ctx.currentSection = SectionAst(type: 'verse', label: value);
        case 'bridge':
          ctx.commitSection();
          ctx.currentSection = SectionAst(type: 'bridge', label: value);
        case 'comment':
        case 'comment_italic':
          final commentLine = LineAst(type: 'comment', text: value);
          if (ctx.currentSection != null) {
            ctx.currentSection!.lines.add(commentLine);
          } else {
            ctx.sections.add(SectionAst(type: 'comment', lines: [commentLine]));
          }
        case 'comment_box':
          final cbLine = LineAst(type: 'comment_box', text: value);
          if (ctx.currentSection != null) {
            ctx.currentSection!.lines.add(cbLine);
          } else {
            ctx.sections.add(SectionAst(type: 'comment', lines: [cbLine]));
          }
        case 'repeat':
          final repeat = value.isEmpty ? '2' : value;
          if (ctx.currentSection != null) {
            ctx.currentSection!.repeat = repeat;
          } else {
            ctx.sections.add(
              SectionAst(
                type: 'comment',
                lines: [LineAst(type: 'comment_box', text: 'Repetir: $repeat')],
              ),
            );
          }
        case 'new_song':
          ctx.commitSection();
          ctx.sections.add(SectionAst(type: 'new_song', lines: []));
        case 'duration':
          if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) {
            final parts = value.split(':').map(int.parse).toList();
            ctx.metadata['duration'] = '${parts[0] * 60 + parts[1]}';
          } else {
            ctx.metadata['duration'] = value;
          }
        default:
          if (value.isNotEmpty) {
            ctx.metadata[_camelCaseMetaKey(name)] = value;
          }
      }
      continue;
    }

    // ── Non-directive line ───────────────────────────────────────────────────
    final ctx = activeVariant ?? defaultCtx;

    if (trimmed.isEmpty) {
      if (ctx.currentSection != null) {
        ctx.currentSection!.lines.add(const LineAst(type: 'empty'));
      }
      continue;
    }

    if (trimmed.startsWith('#') && !ctx.isTab) continue;

    var lineType = 'lyrics';
    var parsedSegments = <SegmentAst>[];

    if (ctx.isTab) {
      lineType = 'tab';
    } else {
      parsedSegments = parseLineSegments(rawLine);
      final textContent = parsedSegments.map((s) => s.text).join();
      final onlyBarsAndSpaces = RegExp(r'^[\s|:\-.%]*$').hasMatch(textContent);
      final hasBars = textContent.contains('|');

      if (ctx.isGrid || (onlyBarsAndSpaces && hasBars)) {
        lineType = 'chord-section';
      }
    }

    LineAst parsedLine;

    if (lineType == 'tab') {
      parsedLine = LineAst(type: 'tab', text: rawLine);
    } else if (lineType == 'lyrics') {
      parsedLine = LineAst(type: 'lyrics', segments: parsedSegments);
    } else {
      // chord-section
      final measures = <MeasureAst>[];
      var currentChords = <SegmentAst>[];
      var startBarline = '';
      var hasSeenChord = false;
      var startBarlineFound = false;

      for (final seg in parsedSegments) {
        if (seg.chord.isNotEmpty) {
          currentChords.add(
            SegmentAst(chord: seg.chord, text: '', timing: seg.timing),
          );
          hasSeenChord = true;
        }

        final barlineMatches = RegExp(r'\|\||:\||:\||\\|').allMatches(seg.text);
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

    ctx.currentSection ??= SectionAst(type: 'verse', lines: []);
    ctx.currentSection!.lines.add(parsedLine);
  }

  // EOF while a variant is still open
  if (activeVariant != null) {
    errors.add(
      'File ended while variant "${activeVariant.name}" '
      '(started at line ${activeVariant.startLineNumber}) was still open. '
      'Missing "{end_of_version}".',
    );
    activeVariant.commitSection();
    final meta = activeVariant.metadata;
    if (!meta.containsKey('title') || meta['title']!.isEmpty) {
      meta['title'] = defaultCtx.metadata['title'] ?? 'Sem Título';
    }
    variants.add(
      ChordProVersion(
        id: activeVariant.id,
        name: activeVariant.name,
        metadata: Map.of(meta),
        body: List.of(activeVariant.sections),
      ),
    );
  }

  defaultCtx.commitSection();
  if (!defaultCtx.metadata.containsKey('title') ||
      defaultCtx.metadata['title']!.isEmpty) {
    defaultCtx.metadata['title'] = 'Sem Título';
  }

  final defaultVersion = ChordProVersion(
    id: 'default',
    name: 'Padrão',
    metadata: Map.of(defaultCtx.metadata),
    body: List.of(defaultCtx.sections),
  );

  return ChordProDocument(
    defaultVersion: defaultVersion,
    variants: List.of(variants),
    errors: List.of(errors),
  );
}

// ── Version selection ───────────────────────────────────────────────────────

/// Selects a [ChordProVersion] by its [versionId].
///
/// Falls back to [document.defaultVersion] when [versionId] is null,
/// `"default"`, or not found among the variants.
ChordProVersion selectVersion(ChordProDocument document, [String? versionId]) {
  if (versionId == null || versionId == 'default') {
    return document.defaultVersion;
  }
  for (final v in document.variants) {
    if (v.id == versionId) return v;
  }
  return document.defaultVersion;
}

// ── Backward-compatible flat API ────────────────────────────────────────────

/// Parses a ChordPro string and returns a flat [SongAst].
///
/// This is the legacy entry point. The full document (including variants) is
/// also available as [SongAst.defaultVersion] / [SongAst.variants].
SongAst parseChordPro(String content) {
  final doc = parseChordProDocument(content);
  return SongAst(
    metadata: doc.defaultVersion.metadata,
    sections: doc.defaultVersion.body,
    defaultVersion: doc.defaultVersion,
    variants: doc.variants,
    errors: doc.errors,
  );
}
