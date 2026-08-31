import 'package:drift/drift.dart';

/// Fallback used only on platforms without `dart:ffi` or `dart:js_interop`.
///
/// In practice this is never selected: native platforms pick
/// [connection_native] and web picks [connection_web].
QueryExecutor openConnection() => throw UnimplementedError(
  'No database connection available on this platform.',
);
