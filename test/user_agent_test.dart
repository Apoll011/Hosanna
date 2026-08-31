import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/network/user_agent.dart';

void main() {
  group('formatUserAgent', () {
    test('includes app version, platform, OS, model and Flutter version', () {
      expect(
        formatUserAgent(
          appVersion: '1.0.4',
          platform: 'Android',
          os: '14 (API 34)',
          model: 'Pixel 8',
          flutterVersion: '3.47.2',
        ),
        'Hosanna/1.0.4 (Android 14 (API 34); Pixel 8) Flutter/3.47.2',
      );
    });

    test('appends the per-install id for log correlation', () {
      expect(
        formatUserAgent(
          appVersion: '1.0.4',
          platform: 'iOS',
          os: '17.2',
          model: 'iPhone15,2',
          flutterVersion: '3.47.2',
          installId: '3f9a21c7',
        ),
        'Hosanna/1.0.4 (iOS 17.2; iPhone15,2; id=3f9a21c7) Flutter/3.47.2',
      );
    });

    test('omits optional segments that are empty', () {
      expect(
        formatUserAgent(appVersion: '1.0.4', platform: 'iOS'),
        'Hosanna/1.0.4 (iOS)',
      );
      expect(
        formatUserAgent(
          appVersion: '1.0.4',
          platform: 'Android',
          os: '14 (API 34)',
          model: ' ',
          installId: '',
          flutterVersion: ' ',
        ),
        'Hosanna/1.0.4 (Android 14 (API 34))',
      );
    });

    test('falls back to a dev marker when the app version is unknown', () {
      expect(
        formatUserAgent(appVersion: '', platform: 'Android'),
        'Hosanna/dev (Android)',
      );
    });
  });

  group('generateInstallId', () {
    test('returns 8 lowercase hex characters', () {
      final id = generateInstallId();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('produces a different id on each call', () {
      expect(generateInstallId(), isNot(generateInstallId()));
    });
  });
}
