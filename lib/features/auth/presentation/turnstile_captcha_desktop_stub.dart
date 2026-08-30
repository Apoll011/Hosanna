// lib/features/auth/presentation/turnstile_captcha_desktop_stub.dart
//
// Fallback implementation used when `dart:io` is unavailable (e.g. web).
//
// `resolveCaptchaToken` only routes to the desktop captcha on Linux/Windows,
// which always have `dart:io`, so this is never called at runtime — it exists
// purely to keep the conditional import compiling on web. It throws to surface
// a programming error if it ever is reached.
import 'package:flutter/widgets.dart';

import '../../../core/config/app_config.dart';

Future<String?> resolveDesktopCaptchaToken(
  BuildContext context,
  AppConfig config,
) {
  throw UnsupportedError(
    'The desktop captcha window is not supported on this platform.',
  );
}
