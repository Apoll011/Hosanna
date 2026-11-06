import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/chordpro_content.dart';

void main() {
  group('applyChordProMetadata', () {
    test('writes managed header before body comments and lyrics', () {
      const body = '{tags: adoração, gospel}\n'
          '\n'
          '{comment: Intro}\n'
          '||[A][E][B/D#][C#m][A][B][Esus4]||';

      final saved = applyChordProMetadata(
        body,
        title: '10.000 Razões',
        subtitle: 'Bless The Lord',
        artist: 'Matt Redman',
        composer: 'Jonas Myrin, Matt Redman',
        translator: 'Fabiano Silveira Medeiros',
        key: 'E',
        tempo: '73',
        timeSignature: '4/4',
        duration: '5:55',
        ccli: '6016351',
        youtube: 'https://www.youtube.com/watch?v=DXDGE_lRI0E',
        tags: 'adoração, gospel, tradução, louvor, matt redman, bless the lord, 10000 razões, salmo 103',
      );

      expect(
        saved,
        '{title: 10.000 Razões}\n'
        '{subtitle: Bless The Lord}\n'
        '{artist: Matt Redman}\n'
        '{composer: Jonas Myrin, Matt Redman}\n'
        '{translator: Fabiano Silveira Medeiros}\n'
        '{key: E}\n'
        '{tempo: 73}\n'
        '{time: 4/4}\n'
        '{duration: 5:55}\n'
        '{ccli: 6016351}\n'
        '{youtube: https://www.youtube.com/watch?v=DXDGE_lRI0E}\n'
        '{tags: adoração, gospel, tradução, louvor, matt redman, bless the lord, 10000 razões, salmo 103}\n'
        '\n'
        '{comment: Intro}\n'
        '||[A][E][B/D#][C#m][A][B][Esus4]||\n',
      );
    });

    test('stripManagedDirectives leaves body comments in place', () {
      const raw = '{title: Song}\n'
          '{tags: worship}\n'
          '\n'
          '{comment: Intro}\n'
          '[G]Hello';
      expect(
        stripManagedDirectives(raw),
        '{comment: Intro}\n[G]Hello',
      );
    });
  });
}
