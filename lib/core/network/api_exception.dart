/// Normalized API error surfaced to the UI layer.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  /// Human-readable message (from the server when available).
  final String message;

  /// Server error code (e.g. Better Auth's `INVALID_EMAIL_OR_PASSWORD`).
  final String? code;

  /// HTTP status code, when known.
  final int? statusCode;

  bool get isNetworkError => statusCode == null || statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
