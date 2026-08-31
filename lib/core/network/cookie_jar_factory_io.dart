import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Persistent cookie jar backed by a file in the app's documents directory.
Future<CookieJar> createCookieJar() async {
  final docsDir = await getApplicationDocumentsDirectory();
  return PersistCookieJar(storage: FileStorage(docsDir.path));
}
