# Hosanna

**Hosanna** is a ChordPro songbook and worship planning app for musicians and church teams. Plan the service in Studio, open it on phone or tablet on Sunday, and each musician gets their own key, capo, chord view, and display settings — including offline.

Website: [hosanna.live](https://hosanna.live) · Studio: [studio.hosanna.live](https://studio.hosanna.live)

This repository is the **Flutter mobile app** (Android / iOS). Version `2.4.x`. Application id: `com.embrace.hosanna`.

---

## What it does

Hosanna is not “just a lyrics viewer.” It is built for rehearsal and live worship:

| Area | What you get |
| --- | --- |
| **Songbook** | ChordPro library with folders, collections, favorites, and search by title, artist, lyrics, key, tags, or song number |
| **Live reading** | Per-musician transpose, capo, show/hide chords, font size, instrument chord diagrams (guitar / piano), keep-awake screen |
| **Stage tools** | Built-in **metronome** (tap tempo, 30–240 BPM), **auto-scroll** with speed control, **circle of fifths** |
| **Services** | Full service order (songs, notes, announcements, scripture cues), next-service view, personal + team notes |
| **Export** | Print-ready **song PDF** matching the reader (transpose, capo, chords, diagrams). Full **service / songbook print** is in Studio |
| **Import** | ChordPro files, plus **AI import** from photo, gallery, or PDF → reviewable ChordPro draft |
| **Offline** | Local SQLite (Drift) cache; sync when back online. Optional live annotation sync for service songs |
| **Rehearsal** | YouTube mini-player from `{youtube: …}` metadata; arrangement variants in ChordPro |
| **Languages** | Portuguese (default), English, Spanish |

Studio (web) handles library admin, team roles, agendas, and planning. This app is what musicians open on stage.

---

## Why this exists (and how it compares)

Generic “song viewer” apps stop at transpose + ChordPro. Stage-focused apps often add a metronome or PDF but leave church teams without a shared library and service plan.

Hosanna covers both sides:

- **Musician tools:** metronome, auto-scroll, PDF export, ChordPro editor, diagrams, circle of fifths — in the same app you read from.
- **Church workflow:** shared org library, service planning, roles/permissions, offline sync, Studio dashboard — so the band is not forwarding PDFs in WhatsApp.

Open ChordPro storage means you can migrate in or out; the library is not locked to a proprietary format.

---

## Features in more detail

### ChordPro reader & editor
- Syntax-aware ChordPro editing and rendering (verses, chorus, bridge, grids, tabs, comments, capo, tempo, time, CCLI, song number, …)
- Independent transpose / capo per musician without changing the church’s stored song
- Chord diagrams and instrument preferences
- Display settings that stay on the device

### Services & setlists
- Open the planned service, walk the order, stay on the current song with wakelock
- Service-level and song-level notes
- Agenda integration for upcoming gatherings

### Metronome & practice
- Full-screen metronome with tempo markings and tap-to-set BPM
- Circle of fifths for key relationships while preparing

### AI import
- Capture a paper chart or PDF; the pipeline returns a ChordPro draft you can review before saving (org AI settings + permissions required)

### Sync & auth
- Email + Google sign-in against the Hosanna API (Better Auth)
- Role-aware permissions (who can edit songs, export PDF, use AI, …)
- Replication engine keeps dirty local rows in sync with the server

---

## Related projects

| Project | Role |
| --- | --- |
| [hosanna.live](https://hosanna.live) | Marketing site |
| [Hosanna Studio](https://github.com/Apoll011/hosanna-studio) | Web dashboard (library, services, teams) |
| [Hosanna API](https://github.com/Apoll011/Hosanna-server) | Backend |
| [hosanna-chordpro](https://github.com/Apoll011/hosanna-chordpro) | Shared ChordPro tooling |

---

## Toolchain & targets

- **Flutter** 3.47.2 (stable) / **Dart** 3.13.2
- **Android** `minSdk 24`; **iOS** deployment target `15.0`

```bash
flutter pub get
flutter gen-l10n            # regenerate if ARB files change
dart run build_runner build # regenerate Drift code if tables change
flutter run
```

Compile-time config via `--dart-define`:

| Key | Purpose | Default |
| --- | --- | --- |
| `HOSANNA_API_URL` | Backend origin (no trailing slash) | `https://api.hosanna.live` |
| `HOSANNA_ORIGIN` | `Origin` header on state-changing requests | `http://localhost` |
| `HOSANNA_GOOGLE_SERVER_CLIENT_ID` | Google web/server OAuth client ID for native sign-in | *(unset)* |
| `HOSANNA_GOOGLE_NONCE` | Send a nonce with the Google ID token | `false` |

```bash
flutter run \
  --dart-define=HOSANNA_API_URL=https://your-api.example.com \
  --dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=1234.apps.googleusercontent.com
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
  features/    auth, songs, folders, services, metronome, circle_of_fifths, export, agenda, …
  shared/      reusable widgets
  l10n/        ARB files (pt default, en, es) + generated AppLocalizations
```

Key libraries: **Riverpod**, **dio**, **Drift**, **go_router**, **intl** / **flutter_localizations**, **flutter_secure_storage**, **cloud_firestore** (optional annotation sync), **wakelock_plus**, **webview_flutter** (Turnstile).

### Song annotation sync (Firebase)

When **Settings → Sync annotations** is on, FlueraCanvas annotations for a
service song sync via Firestore (`services/{serviceId}/annotations/{songId}`),
with the Hosanna API mediating writes. A local `.fcv` file remains the offline
cache. See `Hosanna-server/docs/ANNOTATIONS_FIREBASE.md`.

## Google sign-in (native)

```
SocialSignInButton → SocialAuthProvider → native Google (Credential Manager)
  → Google ID token → AuthRepository.signInWithSocial → POST /api/auth/sign-in/social
  → Better Auth verifies the token, finds/creates the user, issues the session
```

Required configuration:

1. `--dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=<web client id>`
2. Android OAuth client with package `com.embrace.hosanna` and the SHA-1/SHA-256 of each signing key
3. Backend `socialProviders.google.clientId` must accept that web client ID

`HOSANNA_GOOGLE_NONCE=true` mints the ID token with a nonce and sends it to Better Auth. Off by default.

## CI/CD

- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` on push/PR
- `.github/workflows/android-release.yml` — signed release APK (per ABI) + App Bundle → GitHub Release on `v*` tags
