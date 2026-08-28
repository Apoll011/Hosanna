import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final docsDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(storage: FileStorage(docsDir.path));
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        cookieJarProvider.overrideWithValue(cookieJar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HosannaApp(),
    ),
  );
}
