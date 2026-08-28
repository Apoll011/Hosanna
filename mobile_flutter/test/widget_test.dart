import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/config/app_config.dart';

void main() {
  test('app config defaults to the Hosanna beta API', () {
    expect(
      AppConfig.instance.apiBaseUrl,
      'https://hosanna-server-beta.vercel.app',
    );
  });
}
