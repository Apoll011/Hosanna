import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the database in the browser using SQLite compiled to WebAssembly.
///
/// Requires `web/sqlite3.wasm` and `web/drift_worker.js` to be present (see
/// https://drift.simonbinder.eu/web/). Drift picks the most reliable storage
/// implementation the browser supports (OPFS when available, otherwise
/// IndexedDB) and hosts the database in a background worker.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'hosanna',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Only reached when the browser lacks features for reliable persistence
      // (e.g. no OPFS/IndexedDB); the database then runs in-memory.
      // ignore: avoid_print
      print(
        'Hosanna: using ${result.chosenImplementation} because the browser '
        'is missing: ${result.missingFeatures}',
      );
    }

    return result.resolvedExecutor;
  }));
}
