import 'package:share_plus/share_plus.dart';

import '../../songs/presentation/chordpro/song_display_settings.dart';
import '../domain/song_pdf_builder.dart';

/// Builds the PDF for a song using the reader's current display [settings] and
/// hands it to the system share sheet, so the user can save or send it.
///
/// Throws when the document can't be built; callers own the error UI.
Future<void> shareSongPdf({
  required String content,
  required String title,
  required SongDisplaySettings settings,
  String? artist,
  int? songNumber,
}) async {
  final bytes = await buildSongPdf(
    content: content,
    fallbackTitle: title,
    fallbackArtist: artist,
    songNumber: songNumber,
    options: pdfOptionsFrom(settings),
  );

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
      fileNameOverrides: [pdfFileName(title)],
      subject: title,
      text: title,
    ),
  );
}

/// Maps the reader's display settings onto the PDF builder's options, so an
/// export always matches what the reader is showing.
SongPdfOptions pdfOptionsFrom(SongDisplaySettings settings) => SongPdfOptions(
  transpose: settings.transpose,
  capo: settings.capo,
  showChords: settings.showChords,
  twoColumn: settings.twoColumn,
  fontSize: settings.fontSize,
  instrument: settings.instrument,
  showDiagrams: settings.showDiagrams,
  sectionColorBackground: settings.sectionColorBackground,
  variantId: settings.variantId,
);

/// Turns a song title into a file name that is safe on every platform.
String pdfFileName(String title) {
  final cleaned = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return '${cleaned.isEmpty ? 'song' : cleaned}.pdf';
}
