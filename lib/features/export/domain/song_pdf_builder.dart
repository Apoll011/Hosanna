import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../songs/domain/chordpro/chord_dictionary.dart';
import '../../songs/domain/chordpro/parser.dart';
import '../../songs/domain/chordpro/transpose.dart';

/// Display options applied to an exported PDF, mirroring the song reader's
/// `SongDisplaySettings` (transpose, capo, chords, two-column, font size,
/// instrument, diagrams, section backgrounds and the active variant).
class SongPdfOptions {
  const SongPdfOptions({
    this.transpose = 0,
    this.capo = 0,
    this.showChords = true,
    this.twoColumn = false,
    this.fontSize = 14,
    this.instrument = 'guitar',
    this.showDiagrams = false,
    this.sectionColorBackground = false,
    this.variantId = 'default',
  });

  final int transpose;
  final int capo;
  final bool showChords;
  final bool twoColumn;
  final double fontSize;
  final String instrument;
  final bool showDiagrams;
  final bool sectionColorBackground;
  final String variantId;

  bool get isGuitar => instrument == 'guitar';
}

// ── Palette (light theme, derived from the app seed color #0284C7) ──────────

const PdfColor _primary = PdfColor.fromInt(0xFF0284C7);
const PdfColor _onSurface = PdfColor.fromInt(0xFF1F2937);
const PdfColor _onSurfaceVariant = PdfColor.fromInt(0xFF64748B);
const PdfColor _outlineVariant = PdfColor.fromInt(0xFFCBD5E1);
const PdfColor _surfaceContainer = PdfColor.fromInt(0xFFF1F5F9);
const PdfColor _amber = PdfColor.fromInt(0xFFD97706);
const PdfColor _chorusBg = PdfColor.fromInt(0xFFEAF5FB);
const PdfColor _bridgeBg = PdfColor.fromInt(0xFFFDF3E3);
const PdfColor _neutralBg = PdfColor.fromInt(0xFFF3F4F6);
const PdfColor _commentBg = PdfColor.fromInt(0xFFFEF3C7);
const PdfColor _commentAccent = PdfColor.fromInt(0xFFF59E0B);
const PdfColor _commentText = PdfColor.fromInt(0xFF92400E);
const PdfColor _tabBackground = PdfColor.fromInt(0xFF0F172A);
const PdfColor _tabText = PdfColor.fromInt(0xFFCBD5E1);
const PdfColor _diagramLine = PdfColor.fromInt(0xFFA1A1AA);
const PdfColor _openColor = PdfColor.fromInt(0xFF10B981);
const PdfColor _muteColor = PdfColor.fromInt(0xFFDC2626);

const double _pageMargin = 36;

/// Builds the PDF document for [content], applying [options].
///
/// [fallbackTitle] / [fallbackArtist] are used when the parsed metadata does
/// not carry them. [songNumber] is shown as a pill when the metadata has none.
Future<Uint8List> buildSongPdf({
  required String content,
  String? fallbackTitle,
  String? fallbackArtist,
  int? songNumber,
  SongPdfOptions options = const SongPdfOptions(),
}) async {
  final document = parseChordProDocument(content);
  final version = selectVersion(document, options.variantId);
  final metadata = version.metadata;
  final effectiveCapo = options.isGuitar ? options.capo : 0;
  final effectiveTranspose = options.transpose - effectiveCapo;

  final title = _resolveTitle(metadata, fallbackTitle);
  final uniqueChords = _uniqueChords(version.body);

  final pdf = pw.Document(title: _sanitize(title));
  final fonts = _Fonts(pdf.document);

  final theme = pw.ThemeData.withFont(
    base: fonts.base,
    bold: fonts.bold,
    italic: fonts.italic,
    boldItalic: pw.Font.helveticaBoldOblique(),
  );

  final header = <pw.Widget>[
    _metadataHeader(
      metadata: metadata,
      title: title,
      fallbackArtist: fallbackArtist,
      songNumber: songNumber,
      effectiveCapo: effectiveCapo,
      effectiveTranspose: effectiveTranspose,
      transpose: options.transpose,
      fonts: fonts,
    ),
    if (options.showDiagrams && options.showChords && uniqueChords.isNotEmpty)
      _chordRoll(
        uniqueChords: uniqueChords,
        effectiveTranspose: effectiveTranspose,
        capo: effectiveCapo,
        options: options,
        fonts: fonts,
      ),
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(_pageMargin),
      theme: theme,
      build: (context) => [
        ...header,
        if (options.twoColumn)
          ..._twoColumnRows(version.body, options, effectiveTranspose, fonts)
        else
          ...version.body.map(
            (s) => _sectionWidget(s, options, effectiveTranspose, fonts),
          ),
      ],
    ),
  );

  return pdf.save();
}

class _Fonts {
  _Fonts(PdfDocument document)
    : base = pw.Font.helvetica(),
      bold = pw.Font.helveticaBold(),
      italic = pw.Font.helveticaOblique(),
      mono = pw.Font.courier(),
      monoBold = pw.Font.courierBold(),
      drawBase = PdfFont.helvetica(document);

  final pw.Font base;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font mono;
  final pw.Font monoBold;

  /// Fully-resolved font used to paint text directly on the canvas (diagrams).
  final PdfFont drawBase;
}

// ── Metadata header ─────────────────────────────────────────────────────────

String _resolveTitle(Map<String, String> metadata, String? fallbackTitle) {
  final meta = metadata['title'];
  if (meta != null && meta.isNotEmpty && meta != 'Sem Título') return meta;
  if (fallbackTitle != null && fallbackTitle.trim().isNotEmpty) {
    return fallbackTitle;
  }
  return meta ?? 'Sem Título';
}

pw.Widget _metadataHeader({
  required Map<String, String> metadata,
  required String title,
  required String? fallbackArtist,
  required int? songNumber,
  required int effectiveCapo,
  required int effectiveTranspose,
  required int transpose,
  required _Fonts fonts,
}) {
  final subtitle = metadata['subtitle'];
  final artist = _firstNonEmpty([metadata['artist'], fallbackArtist]);
  final composer = metadata['composer'];
  final byLine =
      [artist, composer].where((e) => e != null && e.isNotEmpty).join(' / ');

  final pills = <pw.Widget>[
    if (_numberOrNull(metadata['songNumber']) != null || songNumber != null)
      _pill('Nº ${_numberOrNull(metadata['songNumber']) ?? songNumber}', fonts),
    if ((metadata['key']?.isNotEmpty ?? false) || transpose != 0)
      _pill(
        'Tom: ${transposeChord(metadata['key'] ?? 'C', transpose)}',
        fonts,
      ),
    if (effectiveCapo > 0)
      _pill('Capo: $effectiveCapoª casa', fonts),
    if (effectiveCapo > 0)
      _pill(
        'Formato: ${transposeChord(metadata['key'] ?? 'C', effectiveTranspose)}',
        fonts,
      ),
    if (metadata['originalKey']?.isNotEmpty ?? false)
      _pill('Tom Orig: ${metadata['originalKey']}', fonts),
    if (metadata['tempo']?.isNotEmpty ?? false)
      _pill('${metadata['tempo']} BPM', fonts),
    if (metadata['time']?.isNotEmpty ?? false)
      _pill(metadata['time']!, fonts),
    if (metadata['ccli']?.isNotEmpty ?? false)
      _pill('CCLI: ${metadata['ccli']}', fonts),
  ];

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitize(title),
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 20,
            color: _onSurface,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          pw.Text(
            _sanitize(subtitle),
            style: pw.TextStyle(fontSize: 13, color: _onSurfaceVariant),
          ),
        if (byLine.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              _sanitize(byLine),
              style: pw.TextStyle(fontSize: 10, color: _onSurfaceVariant),
            ),
          ),
        if (pills.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              children: pills,
            ),
          ),
        if (metadata['copyright']?.isNotEmpty ?? false)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              _sanitize('© ${metadata['copyright']}'),
              style: pw.TextStyle(fontSize: 10, color: _onSurfaceVariant),
            ),
          ),
      ],
    ),
  );
}

pw.Widget _pill(String text, _Fonts fonts) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(
      color: _surfaceContainer,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      _sanitize(text),
      style: pw.TextStyle(fontSize: 9, color: _onSurfaceVariant),
    ),
  );
}

// ── Chord roll + diagrams ───────────────────────────────────────────────────

List<String> _uniqueChords(List<SectionAst> sections) {
  final chords = <String>{};
  for (final section in sections) {
    for (final line in section.lines) {
      for (final seg in line.segments ?? const <SegmentAst>[]) {
        if (seg.chord.isNotEmpty) chords.add(seg.chord);
      }
      for (final m in line.measures ?? const <MeasureAst>[]) {
        for (final c in m.chords) {
          if (c.chord.isNotEmpty) chords.add(c.chord);
        }
      }
    }
  }
  return chords.toList();
}

pw.Widget _chordRoll({
  required List<String> uniqueChords,
  required int effectiveTranspose,
  required int capo,
  required SongPdfOptions options,
  required _Fonts fonts,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (options.isGuitar && capo > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              'Capo na $capoª casa',
              style: pw.TextStyle(fontSize: 9, color: _amber),
            ),
          ),
        pw.Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: pw.WrapCrossAlignment.start,
          children: [
            for (final chord in uniqueChords)
              _chordRollItem(
                chord: chord,
                transposed: transposeChord(chord, effectiveTranspose),
                instrument: options.instrument,
                fonts: fonts,
              ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _chordRollItem({
  required String chord,
  required String transposed,
  required String instrument,
  required _Fonts fonts,
}) {
  final fingering = chordDictionary.getFingering(transposed);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        _sanitize(transposed),
        style: pw.TextStyle(
          font: fonts.monoBold,
          fontSize: 10,
          color: _primary,
        ),
      ),
      pw.SizedBox(height: 4),
      if (fingering == null)
        pw.SizedBox(
          height: 40,
          child: pw.Center(
            child: pw.Text(
              '-',
              style: pw.TextStyle(fontSize: 12, color: _onSurfaceVariant),
            ),
          ),
        )
      else if (instrument == 'piano')
        _pianoDiagram(fingering.piano)
      else if (fingering.guitar != null)
        _guitarDiagram(fingering.guitar!, fonts)
      else
        pw.SizedBox(
          height: 40,
          child: pw.Center(
            child: pw.Text(
              '-',
              style: pw.TextStyle(fontSize: 12, color: _onSurfaceVariant),
            ),
          ),
        ),
      if (fingering != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            _sanitize(fingering.piano.notes.join(' - ')),
            style: pw.TextStyle(
              font: fonts.mono,
              fontSize: 7,
              color: _onSurfaceVariant,
            ),
          ),
        ),
    ],
  );
}

/// Guitar fretboard diagram drawn directly onto the PDF canvas.
pw.Widget _guitarDiagram(GuitarFingering guitar, _Fonts fonts) {
  const double width = 100;
  const double height = 110;

  double stringX(int index) => 14 + index * 14;
  double fretY(int index) => 22 + index * 20;

  return pw.CustomPaint(
    size: PdfPoint(width, height),
    painter: (canvas, size) {
      final frets = guitar.frets;
      final fingers = guitar.fingers;
      final barre = guitar.barre;

      // The PDF canvas origin sits at the bottom-left; flip to top-down.
      double ty(double y) => height - y;

      final maxFret = frets.fold<int>(0, (a, b) => b > a ? b : a);
      var startFret = 1;
      if (maxFret > 4) {
        final positive = frets.where((f) => f > 0).toList();
        if (positive.isNotEmpty) {
          startFret = positive.reduce((a, b) => a < b ? a : b);
        }
      }

      // Nut (or top fret line).
      final nutY = ty(fretY(0) - (startFret == 1 ? 3 : 0));
      canvas.setStrokeColor(_diagramLine);
      canvas.setLineWidth(startFret == 1 ? 3.5 : 1.5);
      canvas.drawLine(stringX(0), nutY, stringX(5), nutY);
      canvas.strokePath();

      if (startFret > 1) {
        _paintText(
          canvas,
          fonts.drawBase,
          8,
          '$startFret',
          stringX(0) - 4,
          ty(fretY(0) + 12),
          _onSurface,
          alignEnd: true,
        );
      }

      // Strings.
      canvas.setStrokeColor(_diagramLine);
      canvas.setLineWidth(1.2);
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(stringX(i), ty(fretY(0)), stringX(i), ty(fretY(4)));
      }
      canvas.strokePath();

      // Frets.
      canvas.setStrokeColor(_diagramLine);
      canvas.setLineWidth(1);
      for (var i = 0; i <= 4; i++) {
        canvas.drawLine(stringX(0), ty(fretY(i)), stringX(5), ty(fretY(i)));
      }
      canvas.strokePath();

      // Barre indicator.
      if (barre != null) {
        final inWindow = barre - startFret;
        final startStr = frets.indexOf(barre);
        if (inWindow >= 0 && inWindow < 4 && startStr != -1) {
          final cy = ty(fretY(inWindow) + 10);
          final x1 = stringX(startStr);
          canvas.setFillColor(_primary);
          canvas.drawRRect(x1 - 4, cy - 4, stringX(5) - x1 + 8, 8, 4, 4);
          canvas.fillPath();
        }
      }

      for (var i = 0; i < frets.length; i++) {
        final fret = frets[i];

        if (fret == -1) {
          _paintText(
            canvas,
            fonts.drawBase,
            10,
            'x',
            stringX(i),
            ty(12),
            _muteColor,
            alignCenter: true,
          );
          continue;
        }

        if (fret == 0) {
          canvas.setStrokeColor(_openColor);
          canvas.setLineWidth(1.2);
          canvas.drawEllipse(stringX(i), ty(10), 2, 2);
          canvas.strokePath();
          continue;
        }

        final inWindow = fret - startFret;
        if (inWindow >= 0 && inWindow < 4) {
          final cx = stringX(i);
          final cy = ty(fretY(inWindow) + 10);
          final isBarred =
              barre != null && fret == barre && i >= frets.indexOf(barre);
          if (!isBarred) {
            canvas.setFillColor(_primary);
            canvas.drawEllipse(cx, cy, 5, 5);
            canvas.fillPath();
          }
          final finger =
              fingers != null && i < fingers.length ? fingers[i] : 0;
          if (finger > 0) {
            _paintText(
              canvas,
              fonts.drawBase,
              6.5,
              '$finger',
              cx,
              cy,
              PdfColors.white,
              alignCenter: true,
            );
          }
        }
      }
    },
  );
}

/// Piano keyboard diagram drawn directly onto the PDF canvas.
pw.Widget _pianoDiagram(PianoFingering piano) {
  const int whiteKeyCount = 14;
  const double keyWidth = 14;
  const double keyHeight = 56;
  const double blackWidth = 9;
  const double blackHeight = 34;
  const double width = whiteKeyCount * keyWidth + 2;
  const double height = keyHeight + 4;

  const whiteSemitones = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
  const blackSemitones = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22];

  double blackKeyX(int semitone) {
    final octave = semitone ~/ 12;
    final inOctave = semitone % 12;
    var whiteBefore = 0;
    if (inOctave == 1) {
      whiteBefore = 1;
    } else if (inOctave == 3) {
      whiteBefore = 2;
    } else if (inOctave == 6) {
      whiteBefore = 4;
    } else if (inOctave == 8) {
      whiteBefore = 5;
    } else if (inOctave == 10) {
      whiteBefore = 6;
    }
    return (octave * 7 + whiteBefore) * keyWidth - blackWidth / 2;
  }

  return pw.CustomPaint(
    size: PdfPoint(width, height),
    painter: (canvas, size) {
      double ty(double y) => height - y;

      // White keys.
      for (var idx = 0; idx < whiteSemitones.length; idx++) {
        final semitone = whiteSemitones[idx];
        final highlighted = piano.highlightKeys.contains(semitone);
        final x = idx * keyWidth + 1;
        canvas.setFillColor(highlighted ? _primary : PdfColors.white);
        canvas.drawRect(x, ty(2 + keyHeight), keyWidth - 1, keyHeight);
        canvas.fillPath();

        canvas.setStrokeColor(_diagramLine);
        canvas.setLineWidth(0.8);
        canvas.drawRect(x, ty(2 + keyHeight), keyWidth - 1, keyHeight);
        canvas.strokePath();

        if (highlighted) {
          canvas.setFillColor(PdfColors.white);
          canvas.drawEllipse(
            x + (keyWidth - 1) / 2,
            ty(keyHeight - 8),
            2,
            2,
          );
          canvas.fillPath();
        }
      }

      // Black keys.
      for (final semitone in blackSemitones) {
        final highlighted = piano.highlightKeys.contains(semitone);
        final x = blackKeyX(semitone) + 1;
        canvas.setFillColor(highlighted ? _primary : PdfColors.black);
        canvas.drawRect(x, ty(2 + blackHeight), blackWidth, blackHeight);
        canvas.fillPath();
      }
    },
  );
}

void _paintText(
  PdfGraphics canvas,
  PdfFont font,
  double size,
  String text,
  double x,
  double y,
  PdfColor color, {
  bool alignCenter = false,
  bool alignEnd = false,
}) {
  if (text.isEmpty) return;
  final width = (font.stringMetrics(text) * size).width;
  var dx = x;
  if (alignCenter) {
    dx = x - width / 2;
  } else if (alignEnd) {
    dx = x - width;
  }
  canvas.setFillColor(color);
  canvas.drawString(font, size, text, dx, y - size * 0.35);
}

// ── Sections ────────────────────────────────────────────────────────────────

pw.Widget _sectionWidget(
  SectionAst section,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  return switch (section.type) {
    'new_song' => _newSongDivider(fonts),
    'grid' => _gridSection(section, options, transpose, fonts),
    'tab' => _tabSection(section, fonts),
    'comment' => _commentSection(section, options, transpose, fonts),
    _ => _standardSection(section, options, transpose, fonts),
  };
}

pw.Widget _standardSection(
  SectionAst section,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  final isChorus = section.type == 'chorus';
  final isBridge = section.type == 'bridge';
  final accent = isChorus
      ? _primary
      : (isBridge ? _amber : _outlineVariant);
  final showBackground = options.sectionColorBackground;
  final background = !showBackground
      ? null
      : (isChorus
            ? _chorusBg
            : (isBridge ? _bridgeBg : _neutralBg));
  final label = _sectionLabel(section);

  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 8),
    padding: showBackground
        ? const pw.EdgeInsets.fromLTRB(12, 4, 8, 4)
        : const pw.EdgeInsets.only(left: 12),
    decoration: pw.BoxDecoration(
      color: background,
      border: pw.Border(left: pw.BorderSide(color: accent, width: 2)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if ((section.label?.isNotEmpty ?? false) || isChorus || isBridge)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              _sanitize(label),
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 9,
                color: accent,
                letterSpacing: 0.5,
              ),
            ),
          ),
        if (section.lines.isEmpty && isChorus)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '(Repete o refrão)',
              style: pw.TextStyle(
                font: fonts.italic,
                fontSize: 10,
                color: _onSurfaceVariant,
              ),
            ),
          ),
        for (final line in section.lines)
          _lineWidget(line, options, transpose, fonts),
      ],
    ),
  );
}

pw.Widget _gridSection(
  SectionAst section,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 12),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _surfaceContainer,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: _outlineVariant),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitize(
            section.label?.isNotEmpty == true ? section.label! : 'Instrumental',
          ),
          style: pw.TextStyle(fontSize: 9, color: _onSurfaceVariant),
        ),
        pw.SizedBox(height: 8),
        for (final line in section.lines)
          _lineWidget(line, options, transpose, fonts),
      ],
    ),
  );
}

pw.Widget _tabSection(SectionAst section, _Fonts fonts) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 12),
    padding: const pw.EdgeInsets.fromLTRB(12, 20, 12, 12),
    decoration: pw.BoxDecoration(
      color: _tabBackground,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitize(
            section.label?.isNotEmpty == true ? section.label! : 'Tablatura',
          ),
          style: pw.TextStyle(fontSize: 9, color: _tabText),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _sanitize(section.lines.map((l) => l.text ?? '').join('\n')),
          style: pw.TextStyle(
            font: fonts.mono,
            fontSize: 11,
            height: 1.6,
            color: _tabText,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _commentSection(
  SectionAst section,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final line in section.lines)
          _lineWidget(line, options, transpose, fonts),
      ],
    ),
  );
}

pw.Widget _newSongDivider(_Fonts fonts) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 20),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Divider(color: _outlineVariant)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Text(
            '~',
            style: pw.TextStyle(font: fonts.bold, color: _outlineVariant),
          ),
        ),
        pw.Expanded(child: pw.Divider(color: _outlineVariant)),
      ],
    ),
  );
}

String _sectionLabel(SectionAst section) {
  final label = section.label;
  if (label != null && label.isNotEmpty) return label;
  return switch (section.type) {
    'chorus' => 'Refrão',
    'bridge' => 'Ponte',
    _ => '',
  };
}

// ── Lines ───────────────────────────────────────────────────────────────────

pw.Widget _lineWidget(
  LineAst line,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  switch (line.type) {
    case 'empty':
      return pw.SizedBox(height: 8);
    case 'comment':
      return pw.Text(
        _sanitize(line.text ?? ''),
        style: pw.TextStyle(
          font: fonts.base,
          fontSize: 10,
          color: _onSurfaceVariant,
        ),
      );
    case 'comment_italic':
      return _commentItalicWidget(line, fonts);
    case 'comment_box':
      return _commentBoxWidget(line, fonts);
    case 'chord-section':
      return _chordSectionWidget(line, options, transpose, fonts);
    case 'tab':
      return pw.Text(
        _sanitize(line.text ?? ''),
        style: pw.TextStyle(font: fonts.mono, fontSize: 11, color: _tabText),
      );
    default:
      return _lyricsWidget(line, options, transpose, fonts);
  }
}

pw.Widget _commentItalicWidget(LineAst line, _Fonts fonts) {
  return pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.symmetric(vertical: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: _surfaceContainer,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      _sanitize(line.text ?? ''),
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        font: fonts.italic,
        fontSize: 10,
        color: _onSurfaceVariant,
      ),
    ),
  );
}

pw.Widget _commentBoxWidget(LineAst line, _Fonts fonts) {
  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: _commentBg,
      border: pw.Border(
        left: pw.BorderSide(color: _commentAccent, width: 4),
      ),
      borderRadius: const pw.BorderRadius.only(
        topRight: pw.Radius.circular(8),
        bottomRight: pw.Radius.circular(8),
      ),
    ),
    child: pw.Text(
      _sanitize(line.text ?? ''),
      style: pw.TextStyle(fontSize: 10, color: _commentText),
    ),
  );
}

pw.Widget _chordSectionWidget(
  LineAst line,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  if (!options.showChords) return pw.SizedBox.shrink();
  final measures = line.measures ?? const <MeasureAst>[];

  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: pw.BoxDecoration(
      color: _surfaceContainer,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      children: [
        if (line.startBarline != null && line.startBarline!.isNotEmpty)
          _barline(line.startBarline!, fonts),
        for (final measure in measures) ...[
          for (final c in measure.chords)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Text(
                _sanitize(transposeChord(c.chord, transpose)),
                style: pw.TextStyle(
                  font: fonts.monoBold,
                  fontSize: options.fontSize + 1,
                  color: _primary,
                ),
              ),
            ),
          if (measure.endBarline.isNotEmpty)
            _barline(measure.endBarline, fonts),
        ],
      ],
    ),
  );
}

pw.Widget _barline(String barline, _Fonts fonts) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2),
    child: pw.Text(
      barline,
      style: pw.TextStyle(
        font: fonts.bold,
        fontSize: 12,
        color: _onSurfaceVariant,
      ),
    ),
  );
}

pw.Widget _lyricsWidget(
  LineAst line,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  final items = _tokenizeLine(line);
  final chordSize = options.fontSize * 0.85;

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Wrap(
      crossAxisAlignment: pw.WrapCrossAlignment.end,
      children: [
        for (final item in items)
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (options.showChords)
                if (item.chord.isNotEmpty)
                  pw.Text(
                    _sanitize(transposeChord(item.chord, transpose)),
                    style: pw.TextStyle(
                      font: fonts.monoBold,
                      fontSize: chordSize,
                      color: _primary,
                    ),
                  )
                else
                  pw.SizedBox(height: chordSize * 1.2),
              pw.Text(
                item.text.isEmpty ? ' ' : _sanitize(item.text),
                style: pw.TextStyle(
                  fontSize: options.fontSize,
                  height: 1.3,
                  color: _onSurface,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

List<({String chord, String text})> _tokenizeLine(LineAst line) {
  final segments = line.segments ?? const <SegmentAst>[];
  final items = <({String chord, String text})>[];

  for (final seg in segments) {
    final text = seg.text;
    if (text.isEmpty) {
      items.add((chord: seg.chord, text: ''));
      continue;
    }

    final matches = RegExp(r'\S+\s*|\s+').allMatches(text).toList();
    if (matches.isEmpty) {
      items.add((chord: seg.chord, text: text));
      continue;
    }

    var chordAssigned = false;
    for (var i = 0; i < matches.length; i++) {
      final chunk = matches[i].group(0)!;
      final isWord = chunk.trim().isNotEmpty;
      if (!chordAssigned && (isWord || i == matches.length - 1)) {
        items.add((chord: seg.chord, text: chunk));
        chordAssigned = true;
      } else {
        items.add((chord: '', text: chunk));
      }
    }
  }

  return items;
}

// ── Two-column layout ───────────────────────────────────────────────────────

List<pw.Widget> _twoColumnRows(
  List<SectionAst> sections,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  if (sections.length <= 1) {
    return [
      _twoColumnRow(sections, const [], options, transpose, fonts),
    ];
  }

  // Usable A4 height minus margins, expressed in "section weight" units.
  final lineHeight = options.fontSize * (options.showChords ? 2.7 : 1.6);
  final maxWeight = (770 / lineHeight).floor().clamp(6, 60);

  final rows = <pw.Widget>[];
  var index = 0;
  while (index < sections.length) {
    final column1 = <SectionAst>[];
    final column2 = <SectionAst>[];
    var weight1 = 0;
    var weight2 = 0;

    while (index < sections.length && weight1 < maxWeight) {
      column1.add(sections[index]);
      weight1 += _sectionWeight(sections[index]);
      index++;
    }
    while (index < sections.length && weight2 < maxWeight) {
      column2.add(sections[index]);
      weight2 += _sectionWeight(sections[index]);
      index++;
    }

    rows.add(
      _twoColumnRow(column1, column2, options, transpose, fonts),
    );
  }
  return rows;
}

pw.Widget _twoColumnRow(
  List<SectionAst> column1,
  List<SectionAst> column2,
  SongPdfOptions options,
  int transpose,
  _Fonts fonts,
) {
  pw.Widget buildColumn(List<SectionAst> column) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final section in column)
          _sectionWidget(section, options, transpose, fonts),
      ],
    );
  }

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: buildColumn(column1)),
      pw.SizedBox(width: 18),
      pw.Expanded(child: buildColumn(column2)),
    ],
  );
}

int _sectionWeight(SectionAst section) {
  final lines = section.lines.isEmpty ? 1 : section.lines.length;
  return switch (section.type) {
    'tab' => lines,
    'grid' => lines + 2,
    'new_song' => 2,
    'comment' => 1,
    _ => lines + 1,
  };
}

// ── Helpers ─────────────────────────────────────────────────────────────────

int? _numberOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return null;
}

/// Replaces characters that are not representable in the built-in Type1
/// (WinAnsi) PDF fonts with ASCII equivalents.
String _sanitize(String input) {
  return input
      .replaceAll('\u2014', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u2026', '...')
      .replaceAll('\u00A0', ' ');
}
