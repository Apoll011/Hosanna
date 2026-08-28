import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Key used in `Options.extra` to carry a one-shot Turnstile captcha token
/// that the captcha interceptor injects as the `x-captcha-response` header.
const String kCaptchaTokenExtraKey = 'x-captcha-response';

/// Holds the in-memory bearer token used by the auth interceptor.
class TokenStore {
  String? _token;

  String? get token => _token;

  void update(String? token) => _token = token;
}

/// Builds the shared [Dio] instance used for both auth and replication.
///
/// - Cookies (Better Auth's `hosanna` session cookie) are persisted via a
///   [CookieJar] on the platform documents directory.
/// - A bearer token, when present in [tokenStore], is attached as
///   `Authorization: Bearer …`.
/// - `x-captcha-response` is injected per-request via `Options.extra`.
Dio buildDio({
  required AppConfig config,
  required TokenStore tokenStore,
  required CookieJar cookieJar,
}) {
  final dio = Dio(
    BaseOptions(
      // Origin only: every request path below is absolute (`/api/...`) so the
      // URL is unambiguous regardless of how Dio resolves base + path.
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  //_LoggingInterceptor(),
  dio.interceptors.addAll([
    CookieManager(cookieJar),
    _OriginInterceptor(config.origin),
    _AuthInterceptor(tokenStore),
    _CaptchaInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
}

/// Logs every request and response to the console (debug builds only).
///
/// Placed first so it captures the request before other interceptors mutate
/// headers, and logs the response/error as they come back. Sensitive headers
/// (Authorization, cookies, captcha) are redacted.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final headers = _redactHeaders(options.headers);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('→ HTTP ${options.method} ${options.uri}');
      debugPrint('  Headers: ${jsonEncode(headers)}');
      final data = options.data;
      if (data != null) {
        debugPrint('  Body: ${_truncate(_stringify(data))}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '← HTTP ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
      );
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body: ${_truncate(_stringify(response.data))}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✗ HTTP ${err.requestOptions.method} '
        '${err.requestOptions.uri}',
      );
      debugPrint('  Error: ${err.type.name} ${err.message ?? ''}');
      final response = err.response;
      if (response != null) {
        debugPrint('  Status: ${response.statusCode}');
        debugPrint('  Body: ${_truncate(_stringify(response.data))}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    handler.next(err);
  }

  static const _sensitive = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-captcha-response',
  };

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      final isSensitive = _sensitive.contains(key.toLowerCase());
      return MapEntry(key, isSensitive ? '<redacted>' : value);
    });
  }

  static String _stringify(dynamic data) {
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  static String _truncate(String value, {int max = 500}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}… (+${value.length - max} chars)';
  }
}

/// Adds an `Origin` header to state-changing requests.
///
/// Better Auth's `originCheckMiddleware` requires non-GET requests that carry a
/// session cookie to include an `Origin` (or `Referer`) matching `trustedOrigins`.
/// Native Dio requests have none, so this injects a trusted one (configurable,
/// defaults to `http://localhost`).
class _OriginInterceptor extends Interceptor {
  _OriginInterceptor(this.origin);

  final String origin;

  static const _stateChangingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final hasOrigin = options.headers.keys.any(
      (k) => k.toLowerCase() == 'origin' || k.toLowerCase() == 'referer',
    );
    if (_stateChangingMethods.contains(method) && !hasOrigin) {
      options.headers['Origin'] = origin;
    }
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.tokenStore);

  final TokenStore tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStore.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _CaptchaInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = options.extra[kCaptchaTokenExtraKey];
    if (token is String && token.isNotEmpty) {
      options.headers['x-captcha-response'] = token;
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

/// Converts a [DioException] into an [ApiException] with the server's message.
ApiException toApiException(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;

  String message;
  String? code;

  if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        message =
            (decoded['message'] as String?) ??
            decoded['error']?.toString() ??
            data;
        code = decoded['code'] as String?;
      } else {
        message = data;
      }
    } catch (_) {
      message = data;
    }
  } else if (data is Map) {
    message =
        (data['message'] as String?) ??
        data['error']?.toString() ??
        'Request failed';
    code = data['code'] as String?;
  } else {
    message = _networkMessage(error);
  }

  return ApiException(message: message, code: code, statusCode: status);
}

String _networkMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your connection.';
    default:
      return error.message ?? 'Network error.';
  }
}
