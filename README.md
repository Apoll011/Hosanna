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

| Key               | Purpose                                         | Default                    |
| ----------------- | ----------------------------------------------- | -------------------------- |
| `HOSANNA_API_URL` | Backend origin (no trailing slash)              | `https://api.hosanna.live` |
| `HOSANNA_ORIGIN`  | `Origin` header sent on state-changing requests | `http://localhost`         |

```bash
flutter run \
  --dart-define=HOSANNA_API_URL=https://your-api.example.com \
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
    auth/      session model, secure session store, captcha seam
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

## CI/CD

- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` on push/PR.
- `.github/workflows/android-release.yml` — builds a signed release APK (split
  per ABI) and App Bundle, then publishes them to a GitHub Release on tags
  (`v*`) or manual dispatch. Requires secrets `KEYSTORE_BASE64`,
  `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `API_URL`,
  `GITHUB_TOKEN`.
