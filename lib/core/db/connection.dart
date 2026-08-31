/// Platform-specific drift connection.
///
/// Native platforms (`dart:ffi`) get a file-based SQLite database via
/// `package:drift/native.dart`; the web (`dart:js_interop`) gets a
/// WebAssembly-backed database via `package:drift/wasm.dart`.
library;

export 'connection_unsupported.dart'
    if (dart.library.ffi) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
