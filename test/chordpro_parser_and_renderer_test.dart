import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro/parser.dart';
import 'package:hosanna/features/songs/presentation/chordpro/chord_pro_renderer.dart';

void main() {
  group('ChordPro parser key_note support', () {
    test('parses key_note directive in header', () {
      const input = '''
{title: Canção da Graça}
{key: C}
{key_note: Verso 4 e final modulam para D (meio tom acima)}

{start_of_verse}
[C]Graça bendita e sublime
{end_of_verse}
''';

      final ast = parseChordPro(input);

      expect(
        ast.metadata['keyNote'],
        'Verso 4 e final modulam para D (meio tom acima)',
      );
      expect(
        ast.metadata['key_note'],
        'Verso 4 e final modulam para D (meio tom acima)',
      );
      expect(ast.metadata['key'], 'C');
      expect(ast.sections.length, 1);
      expect(ast.sections.first.type, 'verse');
    });

    test('supports aliases: key note, keynote, kn, key_notes', () {
      final variations = [
        '{key note: Modula para D}',
        '{keynote: Modula para D}',
        '{kn: Modula para D}',
        '{key_notes: Modula para D}',
      ];

      for (final directive in variations) {
        final input = '''
{title: Teste}
{key: C}
$directive

{start_of_verse}
[C]Graça
{end_of_verse}
''';
        final ast = parseChordPro(input);
        expect(
          ast.metadata['keyNote'],
          'Modula para D',
          reason: 'Failed for $directive',
        );
        expect(
          ast.metadata['key_note'],
          'Modula para D',
          reason: 'Failed for $directive',
        );
      }
    });

    test('parses inline key_note inside a section', () {
      const input = '''
{title: Teste}
{key: C}

{start_of_verse}
[C]Graça
{key_note: Verso 4 e final modulam para D (meio tom acima)}
[D]Glória
{end_of_verse}
''';

      final ast = parseChordPro(input);
      expect(ast.sections.length, 1);
      final verse = ast.sections.first;
      expect(verse.lines.length, 3);
      expect(verse.lines[1].type, 'key_note');
      expect(
        verse.lines[1].text,
        'Verso 4 e final modulam para D (meio tom acima)',
      );
    });

    test('parses key_note between sections', () {
      const input = '''
{title: Teste}
{key: C}

{start_of_verse}
[C]Verso 1
{end_of_verse}

{key_note: Modula para D}

{start_of_verse}
[D]Verso 2
{end_of_verse}
''';

      final ast = parseChordPro(input);
      expect(ast.sections.length, 3);
      expect(ast.sections[0].type, 'verse');
      expect(ast.sections[1].type, 'comment');
      expect(ast.sections[1].lines.first.type, 'key_note');
      expect(ast.sections[1].lines.first.text, 'Modula para D');
      expect(ast.sections[2].type, 'verse');
    });

    test('variant inherits and can override key_note', () {
      const input = '''
{title: Teste}
{key: C}
{key_note: Padrão modula para D}

{start_of_verse}
[C]Letra
{end_of_verse}

{start_of_version: Acústico}
{key_note: Acústico permanece em C}
{start_of_verse}
[C]Letra acústica
{end_of_verse}
{end_of_version}

{start_of_version: Ao Vivo}
{start_of_verse}
[C]Letra ao vivo
{end_of_verse}
{end_of_version}
''';

      final doc = parseChordProDocument(input);
      expect(doc.defaultVersion.metadata['keyNote'], 'Padrão modula para D');

      final acustico = selectVersion(doc, slugifyVariantName('Acústico'));
      expect(acustico.metadata['keyNote'], 'Acústico permanece em C');

      final aoVivo = selectVersion(doc, slugifyVariantName('Ao Vivo'));
      // Inherits from previous version
      expect(aoVivo.metadata['keyNote'], 'Acústico permanece em C');
    });
  });

  group('ChordProRenderer key_note widget display', () {
    testWidgets('renders key_note in metadata header', (tester) async {
      const content = '''
{title: Canção de Louvor}
{key: C}
{key_note: Verso 4 e final modulam para D (meio tom acima)}

{start_of_verse}
[C]Graça sem fim
{end_of_verse}
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChordProRenderer(
              content: content,
              showChords: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Verso 4 e final modulam para D (meio tom acima)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.text('Tom: C'), findsOneWidget);
    });

    testWidgets('renders key_note inline inside a section', (tester) async {
      const content = '''
{title: Canção}
{key: C}

{start_of_verse}
[C]Graça sem fim
{key_note: Subir meio tom para Eb}
[Eb]Nova vida
{end_of_verse}
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChordProRenderer(
              content: content,
              showChords: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subir meio tom para Eb'), findsWidgets);
      expect(find.byIcon(Icons.music_note), findsWidgets);
    });
  });
}
