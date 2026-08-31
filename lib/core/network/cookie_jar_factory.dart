/// Platform-specific cookie jar factory.
///
/// Native platforms (`dart:ffi`) get a persistent, file-backed cookie jar;
/// the web (`dart:js_interop`) gets an in-memory jar, since the browser
/// manages its own cookies.
library;

export 'cookie_jar_factory_io.dart'
    if (dart.library.js_interop) 'cookie_jar_factory_web.dart';
