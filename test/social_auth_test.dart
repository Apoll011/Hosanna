import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/auth/session_store.dart';
import 'package:hosanna/core/auth/social_auth_exception.dart';
import 'package:hosanna/core/auth/social_auth_provider.dart';
import 'package:hosanna/core/config/app_config.dart';
import 'package:hosanna/core/network/api_client.dart';
import 'package:hosanna/core/network/api_exception.dart';
import 'package:hosanna/features/auth/data/auth_repository.dart';
import 'package:hosanna/features/auth/data/google_auth_provider.dart';
import 'package:hosanna/features/auth/data/google_sign_in_client.dart';
import 'package:hosanna/features/auth/domain/auth_controller.dart';

/// Canned response for one route.
class _Route {
  const _Route({this.statusCode = 200, this.body = const {}});

  /// Simulates a request that never reaches the server.
  const _Route.offline()
      : statusCode = 0,
        body = null;

  final int statusCode;
  final Object? body;

  bool get isOffline => statusCode == 0;
}

/// Fake transport: matches requests by path suffix and records them, so tests
/// can assert on the exact Better Auth call the client makes.
class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, _Route> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = routes.entries
        .where((entry) => options.path.endsWith(entry.key))
        .map((entry) => entry.value)
        .firstOrNull;
    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'No route for ${options.path}'}),
        404,
        headers: _jsonHeaders,
      );
    }
    if (route.isOffline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.statusCode,
      headers: _jsonHeaders,
    );
  }

  @override
  void close({bool force = false}) {}

  static const Map<String, List<String>> _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  RequestOptions request(String pathSuffix) =>
      requests.lastWhere((request) => request.path.endsWith(pathSuffix));

  /// Request body as a map, whether Dio handed it over as a `Map` or already
  /// encoded it.
  Map<String, dynamic> body(String pathSuffix) {
    final data = request(pathSuffix).data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(jsonDecode(data as String) as Map);
  }
}

/// Records what the shared Google flow asks of the native layer.
class _FakeGoogleSignInClient extends GoogleSignInClient {
  _FakeGoogleSignInClient({
    this.restoredIdToken,
    this.interactiveIdToken,
    this.interactiveError,
    this.supported = true,
  });

  final String? restoredIdToken;
  final String? interactiveIdToken;
  final SocialAuthException? interactiveError;
  final bool supported;

  int initializeCalls = 0;
  String? serverClientId;
  String? nonce;

  @override
  bool get supportsInteractiveSignIn => supported;

  @override
  Future<void> initialize({required String serverClientId, String? nonce}) async {
    initializeCalls++;
    this.serverClientId = serverClientId;
    this.nonce = nonce;
  }

  @override
  Future<String?> restoreIdToken() async => restoredIdToken;

  @override
  Future<String?> signInIdToken() async {
    if (interactiveError != null) throw interactiveError!;
    return interactiveIdToken;
  }
}

class _FakeProvider implements SocialAuthProvider {
  _FakeProvider({this.credential, this.error});

  final SocialAuthCredential? credential;
  final SocialAuthException? error;
  int authenticateCalls = 0;

  @override
  String get id => 'google';

  @override
  String get displayName => 'Google';

  @override
  Future<SocialAuthCredential> authenticate() async {
    authenticateCalls++;
    if (error != null) throw error!;
    return credential!;
  }
}

const _sessionBonus = {
  'redirect': false,
  'token': 'session-token',
  'user': {
    'id': 'user-1',
    'name': 'Ana',
    'email': 'ana@example.com',
    'emailVerified': true,
  },
};

AppConfig _config({String clientId = 'web-client.apps.googleusercontent.com', bool nonce = false}) =>
    AppConfig(
      apiBaseUrl: 'https://api.example.com',
      turnstileUrl: '',
      origin: 'http://localhost',
      googleServerClientId: clientId,
      googleNonceEnabled: nonce,
    );

AuthController _controller(_RouteAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = adapter;
  return AuthController(
    AuthRepository(dio),
    SessionStore(),
    TokenStore(),
    _config(),
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SocialAuthCredential', () {
    test('serialises to the Better Auth idToken shape', () {
      const credential = SocialAuthCredential(
        idToken: 'id-token',
        accessToken: 'access-token',
        nonce: 'nonce',
      );

      expect(credential.toJson(), {
        'token': 'id-token',
        'nonce': 'nonce',
        'accessToken': 'access-token',
      });
    });

    test('omits the access token and nonce when the provider gave none', () {
      const credential = SocialAuthCredential(idToken: 'id-token');

      expect(credential.toJson(), {'token': 'id-token'});
    });

    test('never exposes token material through toString', () {
      const credential = SocialAuthCredential(
        idToken: 'super-secret-id-token',
        accessToken: 'super-secret-access-token',
        nonce: 'super-secret-nonce',
      );

      expect(credential.toString(), isNot(contains('super-secret')));
      expect(credential.toString(), contains('<redacted>'));
    });
  });

  group('generateSocialAuthNonce', () {
    test('is URL-safe, non-empty and unique per call', () {
      final first = generateSocialAuthNonce();
      final second = generateSocialAuthNonce();

      expect(first, isNotEmpty);
      expect(first, isNot(second));
      expect(first, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });
  });

  group('GoogleAuthProvider', () {
    test('fails clearly when the server client id is not configured', () async {
      final client = _FakeGoogleSignInClient(interactiveIdToken: 'id-token');
      final provider = GoogleAuthProvider(_config(clientId: ''), client: client);

      await expectLater(
        provider.authenticate(),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.code,
            'code',
            SocialAuthErrorCode.notConfigured,
          ),
        ),
      );
      // Nothing is handed to the native layer without a client id.
      expect(client.initializeCalls, 0);
    });

    test('reports an unsupported platform as unavailable', () async {
      final provider = GoogleAuthProvider(
        _config(),
        client: _FakeGoogleSignInClient(supported: false, interactiveIdToken: 'x'),
      );

      await expectLater(
        provider.authenticate(),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.code,
            'code',
            SocialAuthErrorCode.unavailable,
          ),
        ),
      );
    });

    test('initialises once with the web client id and returns the id token',
        () async {
      final client = _FakeGoogleSignInClient(
        restoredIdToken: 'restored-id-token',
      );
      final provider = GoogleAuthProvider(_config(), client: client);

      final first = await provider.authenticate();
      final second = await provider.authenticate();

      expect(provider.id, 'google');
      expect(first.idToken, 'restored-id-token');
      expect(second.idToken, 'restored-id-token');
      expect(client.initializeCalls, 1);
      expect(client.serverClientId, 'web-client.apps.googleusercontent.com');
      expect(client.nonce, isNull);
      expect(first.nonce, isNull);
      expect(first.accessToken, isNull);
    });

    test('falls back to the interactive (native) flow', () async {
      final client = _FakeGoogleSignInClient(interactiveIdToken: 'fresh-id-token');

      final credential =
          await GoogleAuthProvider(_config(), client: client).authenticate();

      expect(credential.idToken, 'fresh-id-token');
    });

    test('reports "no account" when neither flow yields a token', () async {
      final client = _FakeGoogleSignInClient();

      await expectLater(
        GoogleAuthProvider(_config(), client: client).authenticate(),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.code,
            'code',
            SocialAuthErrorCode.noAccount,
          ),
        ),
      );
    });

    test('propagates a cancellation from the native picker', () async {
      final client = _FakeGoogleSignInClient(
        interactiveError: const SocialAuthException(SocialAuthErrorCode.canceled),
      );

      await expectLater(
        GoogleAuthProvider(_config(), client: client).authenticate(),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.isCancellation,
            'isCancellation',
            isTrue,
          ),
        ),
      );
    });

    test('only binds a nonce when the build opts in', () async {
      final client = _FakeGoogleSignInClient(interactiveIdToken: 'id-token');

      final credential = await GoogleAuthProvider(
        _config(nonce: true),
        client: client,
      ).authenticate();

      expect(client.nonce, isNotNull);
      expect(client.nonce, isNotEmpty);
      // The same nonce the native layer minted the token with is forwarded to
      // Better Auth for validation.
      expect(credential.nonce, client.nonce);
    });
  });

  group('AuthRepository.signInWithSocial', () {
    test('posts the provider id and id token to Better Auth', () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(body: _sessionBonus),
      });
      final repository =
          AuthRepository(Dio(BaseOptions(baseUrl: 'https://api.example.com'))
            ..httpClientAdapter = adapter);

      final session = await repository.signInWithSocial(
        providerId: 'google',
        credential: const SocialAuthCredential(idToken: 'google-id-token'),
      );

      expect(adapter.request('/api/auth/sign-in/social').method, 'POST');
      expect(adapter.body('/api/auth/sign-in/social'), {
        'provider': 'google',
        'idToken': {'token': 'google-id-token'},
      });
      expect(session.sessionToken, 'session-token');
      expect(session.user.email, 'ana@example.com');
    });

    test('includes the access token only when the provider supplied one',
        () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(body: _sessionBonus),
      });
      final repository =
          AuthRepository(Dio(BaseOptions(baseUrl: 'https://api.example.com'))
            ..httpClientAdapter = adapter);

      await repository.signInWithSocial(
        providerId: 'google',
        credential: const SocialAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
          nonce: 'google-nonce',
        ),
      );

      expect(adapter.body('/api/auth/sign-in/social')['idToken'], {
        'token': 'google-id-token',
        'nonce': 'google-nonce',
        'accessToken': 'google-access-token',
      });
    });

    test('surfaces a rejected id token as an ApiException', () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(
          statusCode: 401,
          body: {'message': 'Invalid token', 'code': 'INVALID_TOKEN'},
        ),
      });
      final repository =
          AuthRepository(Dio(BaseOptions(baseUrl: 'https://api.example.com'))
            ..httpClientAdapter = adapter);

      await expectLater(
        repository.signInWithSocial(
          providerId: 'google',
          credential: const SocialAuthCredential(idToken: 'bad-token'),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'INVALID_TOKEN')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('AuthController.signInWithSocial', () {
    test('applies the Better Auth session exactly like email sign-in',
        () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(body: _sessionBonus),
        '/api/auth/organization/get-full-organization': const _Route(body: {}),
        '/api/auth/organization/list': const _Route(body: []),
      });
      final controller = _controller(adapter);
      final provider = _FakeProvider(
        credential: const SocialAuthCredential(idToken: 'google-id-token'),
      );

      await controller.signInWithSocial(provider);

      expect(provider.authenticateCalls, 1);
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.session?.sessionToken, 'session-token');
      expect(controller.state.session?.user.email, 'ana@example.com');

      final stored = await SessionStore().readSession();
      expect(stored?.sessionToken, 'session-token');
      expect(await SessionStore().readToken(), 'session-token');
    });

    test('maps a rejected credential to a non-cancellation social failure',
        () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(
          statusCode: 401,
          body: {'message': 'Invalid token', 'code': 'INVALID_TOKEN'},
        ),
      });
      final controller = _controller(adapter);

      await expectLater(
        controller.signInWithSocial(
          _FakeProvider(
            credential: const SocialAuthCredential(idToken: 'bad-token'),
          ),
        ),
        throwsA(
          isA<SocialAuthException>()
              .having((e) => e.code, 'code', SocialAuthErrorCode.rejected)
              .having((e) => e.isCancellation, 'isCancellation', isFalse),
        ),
      );
      expect(controller.state.status, isNot(AuthStatus.authenticated));
    });

    test('maps an unreachable server to a network failure', () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route.offline(),
      });
      final controller = _controller(adapter);

      await expectLater(
        controller.signInWithSocial(
          _FakeProvider(
            credential: const SocialAuthCredential(idToken: 'google-id-token'),
          ),
        ),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.code,
            'code',
            SocialAuthErrorCode.network,
          ),
        ),
      );
    });

    test('maps a server failure to a server error', () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(
          statusCode: 500,
          body: {'message': 'Internal error'},
        ),
      });
      final controller = _controller(adapter);

      await expectLater(
        controller.signInWithSocial(
          _FakeProvider(
            credential: const SocialAuthCredential(idToken: 'google-id-token'),
          ),
        ),
        throwsA(
          isA<SocialAuthException>().having(
            (e) => e.code,
            'code',
            SocialAuthErrorCode.server,
          ),
        ),
      );
    });

    test('does not reach the server when the provider cancels', () async {
      final adapter = _RouteAdapter({
        '/api/auth/sign-in/social': const _Route(body: _sessionBonus),
      });
      final controller = _controller(adapter);

      await expectLater(
        controller.signInWithSocial(
          _FakeProvider(
            error: const SocialAuthException(SocialAuthErrorCode.canceled),
          ),
        ),
        throwsA(isA<SocialAuthException>()),
      );
      expect(
        adapter.requests.where(
          (request) => request.path.endsWith('/sign-in/social'),
        ),
        isEmpty,
      );
    });
  });
}
