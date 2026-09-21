import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/export/domain/song_pdf_builder.dart';

const _sample = '''
{title: Amazing Grace}
{artist: Banda Hosanna}
{key: G}
{tempo: 72}

{start_of_verse}
[G]Amazing grace, how [C]sweet the sound
[G]That saved a [D]wretch like me
{end_of_verse}

{start_of_chorus}
[D]How sweet the sound
{end_of_chorus}

{start_of_grid: Instrumental}
| G | C | D | G |
{end_of_grid}

{start_of_version: Versão de Estúdio}
{start_of_verse}
[Am]Another [F]take
{end_of_verse}
{end_of_version}
''';

void main() {
  group('buildSongPdf', () {
    test('builds a valid single-column PDF', () async {
      final bytes = await buildSongPdf(
        content: _sample,
        fallbackTitle: 'Amazing Grace',
      );
      expect(bytes.length, greaterThan(0));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('builds a two-column PDF with diagrams', () async {
      final bytes = await buildSongPdf(
        content: _sample,
        fallbackTitle: 'Amazing Grace',
        options: const SongPdfOptions(
          showDiagrams: true,
          twoColumn: true,
          transpose: 2,
          capo: 2,
          sectionColorBackground: true,
        ),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('renders the selected variant', () async {
      final bytes = await buildSongPdf(
        content: _sample,
        options: const SongPdfOptions(
          variantId: 'versao-de-estudio',
          instrument: 'piano',
          showDiagrams: true,
        ),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('builds without chords', () async {
      final bytes = await buildSongPdf(
        content: _sample,
        options: const SongPdfOptions(showChords: false),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
