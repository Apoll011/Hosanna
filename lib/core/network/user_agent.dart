import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// SharedPreferences key holding this install's stable, random identifier.
///
/// It is appended to the User-Agent (`id=…`) so server logs can tell one
/// device install apart from another even when app version, OS, and device
/// model are identical. Persisted once per install and reused for the app's
/// lifetime.
const String kInstallIdPrefsKey = 'hosanna_install_id';

/// Generates a fresh install identifier: 8 lowercase hex chars (32 bits of
/// entropy) — enough to disambiguate installs in logs without bloating the
/// User-Agent header.
String generateInstallId() {
  final rng = Random.secure();
  return List.generate(4, (_) => rng.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Builds the User-Agent header value sent with every API request.
///
/// Format:
/// `Hosanna/<version> (<platform> <os>; <model>; id=<installId>) Flutter/<flutter>`
///
/// e.g. `Hosanna/1.0.4 (Android 14 (API 34); Pixel 8; id=3f9a21c7) Flutter/3.47.2`
///
/// Platform/OS/device details come from `device_info_plus`, the app version
/// from `package_info_plus`, and the Flutter version from the Dart VM. All
/// lookups are best-effort: if a plugin is unavailable (e.g. in tests) the
/// User-Agent still builds with whatever data is available, so it never
/// blocks a request.
Future<String> buildUserAgent({String? installId}) async {
  var appVersion = '';
  try {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version.trim();
  } catch (_) {}

  final platform = await _describePlatform();

  return formatUserAgent(
    appVersion: appVersion,
    platform: platform.platform,
    os: platform.os,
    model: platform.model,
    flutterVersion: platform.flutterVersion,
    installId: installId,
  );
}

/// Assembles the final User-Agent string. Kept pure (no plugins, no async)
/// so the exact header format is trivially unit-testable.
String formatUserAgent({
  required String appVersion,
  required String platform,
  String os = '',
  String? model,
  String? flutterVersion,
  String? installId,
}) {
  final version = appVersion.trim().isEmpty ? 'dev' : appVersion.trim();

  final comment = StringBuffer(platform);
  final osTrimmed = os.trim();
  if (osTrimmed.isNotEmpty) comment.write(' $osTrimmed');
  final modelTrimmed = model?.trim() ?? '';
  if (modelTrimmed.isNotEmpty) comment.write('; $modelTrimmed');
  final id = installId?.trim() ?? '';
  if (id.isNotEmpty) comment.write('; id=$id');

  final ua = StringBuffer('Hosanna/$version ($comment)');
  final flutter = flutterVersion?.trim() ?? '';
  if (flutter.isNotEmpty) ua.write(' Flutter/$flutter');
  return ua.toString();
}

class _PlatformDescription {
  const _PlatformDescription({
    required this.platform,
    this.os = '',
    this.model,
    this.flutterVersion,
  });

  final String platform;
  final String os;
  final String? model;
  final String? flutterVersion;
}

/// Collects platform/OS/device details. Only iOS and Android are first-class;
/// anything else falls back to the plain `dart:io` values so desktop builds
/// still get a usable User-Agent.
Future<_PlatformDescription> _describePlatform() async {
  final flutterVersion = _flutterVersion();

  if (Platform.isAndroid) {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final version = info.version;
      return _PlatformDescription(
        platform: 'Android',
        os: '${version.release} (API ${version.sdkInt})',
        model: info.model,
        flutterVersion: flutterVersion,
      );
    } catch (_) {
      return _PlatformDescription(
        platform: 'Android',
        flutterVersion: flutterVersion,
      );
    }
  }

  if (Platform.isIOS) {
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      return _PlatformDescription(
        platform: 'iOS',
        os: info.systemVersion,
        // Hardware identifier (e.g. `iPhone15,2`), not the user-assigned name.
        model: info.utsname.machine,
        flutterVersion: flutterVersion,
      );
    } catch (_) {
      return _PlatformDescription(
        platform: 'iOS',
        flutterVersion: flutterVersion,
      );
    }
  }

  return _PlatformDescription(
    platform: Platform.operatingSystem,
    os: Platform.operatingSystemVersion,
    flutterVersion: flutterVersion,
  );
}

/// First token of `Platform.version`, e.g. `3.47.2` for
/// `3.47.2 (stable) (…) on "android_arm64"`.
String? _flutterVersion() {
  try {
    final version = Platform.version.split(' ').first.trim();
    return version.isEmpty ? null : version;
  } catch (_) {
    return null;
  }
}
