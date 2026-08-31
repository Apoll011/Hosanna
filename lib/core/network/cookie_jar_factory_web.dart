import 'package:cookie_jar/cookie_jar.dart';

/// In-memory cookie jar for the web.
///
/// Browsers manage cookies themselves; the session cookie is kept for the
/// lifetime of the page (it does not survive a full reload).
Future<CookieJar> createCookieJar() async => CookieJar();
