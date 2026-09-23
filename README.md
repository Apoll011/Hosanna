# Hosanna (Flutter)

Flutter rewrite of the Hosanna musician app (previously React + Capacitor).
This is now the primary codebase.

## Toolchain & targets

- **Flutter** 3.47.2 (stable) / **Dart** 3.13.2.
- **Application id:** `com.embrace.hosanna` (Android `applicationId`/`namespace`,
  iOS `PRODUCT_BUNDLE_IDENTIFIER`).
- **Android** `minSdk 24`, `targetSdk`/`compileSdk` = Flutter defaults (SDK 36).
- **iOS** deployment target `15.0`.

## Running

```bash
flutter pub get
flutter gen-l10n            # regenerate if ARB files change
dart run build_runner build # regenerate Drift code if tables change
flutter run
```

Configuration is injected at compile time via `--dart-define`:

| Key                            | Purpose                                                          | Default                    |
| ------------------------------ | ---------------------------------------------------------------- | -------------------------- |
| `HOSANNA_API_URL`              | Backend origin (no trailing slash)                               | `https://api.hosanna.live` |
| `HOSANNA_ORIGIN`               | `Origin` header sent on state-changing requests                  | `http://localhost`         |
| `HOSANNA_GOOGLE_SERVER_CLIENT_ID` | Google **web/server** OAuth client ID used for native sign-in | *(unset)*                  |
| `HOSANNA_GOOGLE_NONCE`         | Send a nonce with the Google ID token (see below)                | `false`                    |

```bash
flutter run \
  --dart-define=HOSANNA_API_URL=https://your-api.example.com \
  --dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=1234.apps.googleusercontent.com \
```

> **Turnstile is required.** The backend enforces Cloudflare Turnstile on
> `/sign-up/email`, `/sign-in/email`, and `/request-password-reset`. The app
> loads the Studio captcha page at `https://studio.hosanna.live/captcha`.

## Architecture

Feature-first, layered:

```
lib/
  app/         bootstrap, routing (go_router), theming, DI/providers, settings
  core/
    config/    compile-time AppConfig
    network/   dio client + interceptors (cookies, bearer, captcha, errors)
    auth/      session model, secure session store, captcha + social-auth seams
    sync/      generic replication engine + per-resource adapters
    db/        Drift (SQLite) tables + database
  features/    auth, songs, folders, services, metronome, circle_of_fifths, export
  shared/      reusable widgets
  l10n/        ARB files (pt default, en, es) + generated AppLocalizations
```

Key libraries: **Riverpod** (state/DI), **dio** (HTTP), **Drift** (SQLite,
reactive `watch()` streams), **go_router** (navigation), **intl** +
**flutter_localizations** (l10n), **flutter_secure_storage** (session/bearer),
**wakelock_plus** (keep-awake), **webview_flutter** (Turnstile).

## Google sign-in (native)

The client is a hand-rolled Better Auth client, so social sign-in is just
another call to `/api/auth/sign-in/social`:

```
SocialSignInButton → SocialAuthProvider → native Google (Credential Manager)
  → Google ID token → AuthRepository.signInWithSocial → POST /api/auth/sign-in/social
  → Better Auth verifies the token, finds/creates the user, issues the session
```

The button on both `/sign-in` and `/sign-up` renders the platform's own Google
account chooser (no browser, no WebView). Google is just the first
implementation of `SocialAuthProvider` (`lib/core/auth/social_auth_provider.dart`);
Apple/GitHub/Microsoft only need a provider registered in
`socialAuthProvidersProvider` (`lib/app/providers.dart`).

Required configuration:

1. `--dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=<web client id>` — the
   **web/server** OAuth client ID, passed to Google as the ID token audience.
2. Android OAuth client in Google Cloud Console with package name
   `com.embrace.hosanna` and the SHA-1/SHA-256 of each signing key (debug and
   release). A missing/incorrect fingerprint surfaces as a
   `GoogleSignInExceptionCode.canceled` or `clientConfigurationError`.
3. The backend's `socialProviders.google.clientId` must accept that web client
   ID (Better Auth supports an array, e.g. web + iOS + Android client IDs).
   The Google **client secret** stays on the server; it is never shipped in the
   app and no server change is needed for the native ID-token flow.

`HOSANNA_GOOGLE_NONCE=true` additionally mints the ID token with a nonce and
sends it to Better Auth (`idToken.nonce`), which rejects a token whose `nonce`
claim does not match. It is off by default because `google_sign_in` accepts a
nonce only in its one-shot `initialize()` call, so the value is fixed per app
run and must match whatever Credential Manager has cached. Enable it only once
the server-side flow is confirmed to expect a nonce.

> The client never decodes the ID token, never reads profile data from it, and
> never logs token material — the server is the only component that trusts it.

## CI/CD

- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` on push/PR.
- `.github/workflows/android-release.yml` — builds a signed release APK (split
  per ABI) and App Bundle, then publishes them to a GitHub Release on tags
  (`v*`) or manual dispatch. Requires secrets `KEYSTORE_BASE64`,
  `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `API_URL`,
  `GOOGLE_SERVER_CLIENT_ID`, `GITHUB_TOKEN`.
