# Hosanna Mobile (Flutter)

Flutter rewrite of the Hosanna musician app (previously React + Capacitor). The
React app remains the *behavioral* reference; this app is a clean, idiomatic
Flutter implementation and does **not** clone its UI or architecture.

## Toolchain & targets

- **Flutter** 3.47.2 (stable) / **Dart** 3.13.2 — set at migration time.
- **Android** `minSdk 24` (Flutter 3.47 default), `targetSdk`/`compileSdk` = Flutter defaults (SDK 36).
- **iOS** deployment target `15.0` (Flutter 3.47 default).

## Running

```bash
cd mobile_flutter
flutter pub get
flutter gen-l10n            # regenerate if ARB files change
dart run build_runner build # regenerate Drift code if tables change
flutter run
```

Configuration is injected at compile time via `--dart-define`:

| Key | Purpose | Default |
| --- | --- | --- |
| `HOSANNA_API_URL` | Backend origin (no trailing slash) | `https://hosanna-server-beta.vercel.app` |
| `HOSANNA_TURNSTILE_SITE_KEY` | Cloudflare Turnstile **site** (public) key | *(empty)* |

```bash
flutter run \
  --dart-define=HOSANNA_API_URL=https://your-api.example.com \
  --dart-define=HOSANNA_TURNSTILE_SITE_KEY=0x4AAAA...
```

> **Turnstile is required.** The backend enforces Cloudflare Turnstile on
> `/sign-up/email`, `/sign-in/email`, and `/request-password-reset`. Until
> `HOSANNA_TURNSTILE_SITE_KEY` is provided, those actions surface a localized
> "captcha not configured" message. Once set, a native WebView renders the
> Turnstile widget and returns the token.

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

### ChordPro seam

`features/songs/presentation/song_body_renderer.dart` (`SongBodyRenderer`) is the
single place that renders song content — today it shows raw ChordPro in a
monospace block. A real parser/renderer slots in there without touching the rest
of the song feature.

### Sync model

- Local storage is Drift (SQLite); per-resource checkpoints and the
  last-synced timestamp live in `shared_preferences`.
- Sync is **user-triggered only** in v1: on app launch/resume (debounced) and on
  pull-to-refresh. No polling, no background sync. Extension point is
  `core/sync/replication_engine.dart`.
- Conflict resolution is **server-wins**, matching the backend
  (`assumedMasterState.updatedAt != server.updatedAt` → server doc wins).
- Deletions are soft (`isDeleted` flag + `purgeAt`), mirroring the server's
  trash semantics.

## Scope (v1)

In scope: auth (email/password, verification, reset, account), folders/songs/
services replication + browsing, raw ChordPro display, keep-awake, metronome /
circle-of-fifths / PDF export placeholders, Material 3 + high-contrast theming,
pt/en/es localization.

Out of scope (wired for later, not built): chord diagrams/transposition, org
switching UI (single-org assumed), social login/2FA/passkeys, push
notifications, background sync, automated tests.
