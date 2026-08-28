import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/config/app_config.dart';

void main() {
  test('app config defaults to the Hosanna API', () {
    expect(
      AppConfig.instance.apiBaseUrl,
      'https://api.hosanna.live',
    );
  });
}
