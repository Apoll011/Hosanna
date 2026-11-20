# Hosanna app: agent handbook

Guidance for coding agents working in this repository. This is the Flutter musician app for Hosanna, a separate repository from the suite monorepo.

**Owner:** Apoll0_11 (software engineer). Prefer asking questions over guessing. Keep responses clear and direct, with enough explanation that the system change is understandable.

**Related handbook:** when the suite repository is checked out next to this one, read `../suite/AGENTS.md` for cross-cutting product, auth, API, and visual-language rules. This file wins for Flutter-specific decisions.

---

## 1. What this repo is

Hosanna is a ChordPro songbook and worship planning app for church musicians. Studio (web) handles library admin, teams, and service planning. This app is what musicians open on stage.

- Application id: `live.hosanna.music`
- Current version: `2.8.2` in `pubspec.yaml`
- Targets: Android (`minSdk 24`) and iOS (deployment target `15.0`)
- Languages: Portuguese (default), English, Spanish
- Architecture: feature-first, layered, offline-first

The suite owns the API contract, Better Auth, RBAC, sync semantics, and visual language. This app must stay compatible with those, not invent parallel behavior.

### How to work with the human

1. Ask when requirements, tradeoffs, or docs/code conflicts are unclear. Do not invent product decisions.
2. Use plan mode for multi-file or architecture-shaped work.
3. At the end of a meaningful change, explain the system that now exists, not only the files touched.
4. Make local implementation choices without asking only when the existing pattern is clear, the change is backwards-compatible, and it is easy to revise.
5. Ask before product, UX, schema, security, billing, destructive-data, or public API decisions.

---

## 2. Repo map

```
lib/main.dart              bootstrap, service init, ProviderScope overrides
lib/app/                   app shell, go_router, theme, providers, settings
lib/app/design/            HosannaTokens, colors, spacing, radii, illustrations
lib/core/config/           compile-time AppConfig (--dart-define)
lib/core/network/          Dio client, interceptors, HosannaApi facade, errors
lib/core/auth/             session model, secure store, captcha, social auth seams
lib/core/db/               Drift tables, database, platform connections
lib/core/sync/             replication engine, adapters, sync controller
lib/core/permissions/      AppPermission, AppRole, local RBAC
lib/core/analytics/        PostHog service, events, route observer, error handler
lib/features/<feature>/    data, domain, presentation per feature
lib/shared/                reusable widgets and utilities
lib/l10n/                  ARB files and generated AppLocalizations
test/                      unit, widget, and migration tests
openapi/openapi.yaml       snapshot of the suite API contract
android/, ios/             native projects and release config
.github/workflows/         CI and Android release
docs/                      app-specific notes (thin; suite docs are canonical)
.agents/skills/            installed project skills (gitignored)
```

Feature folders in use: `agenda`, `auth`, `circle_of_fifths`, `collections`, `export`, `folders`, `input`, `metronome`, `notifications`, `onboarding`, `services`, `settings`, `setup`, `songs`.

---

## 3. Commands

Run from the repository root.

```bash
flutter pub get
flutter gen-l10n                 # after ARB changes
dart run build_runner build      # after Drift table changes
flutter analyze
flutter test
flutter test test/<name>_test.dart
flutter run
```

Useful build commands (only when release work is requested):

```bash
flutter build apk --release --dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=...
flutter build appbundle --release --dart-define=HOSANNA_GOOGLE_SERVER_CLIENT_ID=...
```

Compile-time configuration uses `--dart-define`. Defaults and current behavior live in `lib/core/config/app_config.dart`.

| Key                               | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `HOSANNA_API_URL`                 | Backend origin, no trailing slash                    |
| `HOSANNA_AUTH_URL`                | Better Auth origin, no trailing slash                |
| `HOSANNA_TURNSTILE_URL`           | Hosted Turnstile captcha page                        |
| `HOSANNA_ORIGIN`                  | `Origin` header on state-changing requests           |
| `HOSANNA_GOOGLE_SERVER_CLIENT_ID` | Google web/server OAuth client ID for native sign-in |
| `HOSANNA_GOOGLE_NONCE`            | Send a nonce with the Google ID token                |
| `HOSANNA_POSTHOG_KEY`             | PostHog key; analytics is disabled when empty        |
| `HOSANNA_POSTHOG_HOST`            | PostHog ingestion host                               |

CI runs `flutter analyze` and `flutter test` on pushes to `develop` and `master` and on pull requests.

---

## 4. Docs: read before non-trivial work

Start with:

- `README.md` for product scope, setup, architecture, and release notes.
- `docs/ui-improvements.md` for known UI gaps and design direction.

When the suite repository is available, read what matches the task:

| Task                                          | Read first                                              |
| --------------------------------------------- | ------------------------------------------------------- |
| Cross-client behavior, where something lives  | `../suite/docs/architecture/README.md`                  |
| Auth, sessions, RBAC, billing                 | `../suite/docs/architecture/auth-and-billing.md`        |
| Sync, replication, local data                 | `../suite/docs/architecture/data-and-sync.md`           |
| Flutter client behavior and responsibilities  | `../suite/docs/architecture/clients.md`                 |
| UI, color, typography, navigation             | `../suite/docs/hosanna-visual-language.md`              |
| API routes and contract                       | `../suite/docs/openapi.md` and `openapi/openapi.yaml`   |
| Annotations and Firebase                      | `../suite/docs/ANNOTATIONS_FIREBASE.md`                 |

If docs and code disagree, ask the human before choosing. Do not silently "fix" docs to match a guess.

On big behavior or architecture changes, update the relevant docs without waiting to be asked. For app-only behavior, add a short note under `docs/`. For cross-client behavior, update the suite docs when that repository is part of the task.

---

## 5. Architecture rules

Keep the feature-first, layered structure:

- `data/`: repositories, API calls, Firebase, preferences, local persistence.
- `domain/`: models, pure logic, controllers (`StateNotifier`), validation.
- `presentation/`: pages and widgets only.

Rules:

- No business logic in widgets. No direct Dio, Drift, or Firestore calls from UI.
- Shared singletons and app-wide overrides live in `lib/app/providers.dart`. Feature-specific providers stay near the feature.
- Riverpod 2.x is used with hand-written providers. Do not introduce `riverpod_generator` or provider codegen unless asked.
- `go_router` owns navigation. The shell is a `StatefulShellRoute.indexedStack`; branch order must match the constants in `lib/app/nav_branches.dart`.
- Router redirects depend on auth status, organization resolution, and setup completion. Do not bypass those states.
- Reuse `lib/shared/widgets` and `lib/app/design` before creating one-off variants.
- Match local naming, imports, and file layout. In `lib/`, use relative imports. In tests, use `package:hosanna/...`.
- Do not add a dependency for something the platform or existing packages already cover. Reuse first.
- Stay on task. No drive-by refactors unrelated to the request.

---

## 6. Offline data and sync

This app is local-first. Drift/SQLite is the source of truth on device, and the replication engine keeps it aligned with the suite API.

Core invariants:

- Local writes go to Drift first and are marked `dirty`, then pushed by sync.
- `serverUpdatedAt` is the last server timestamp acknowledged by this client. It is the conflict token for `assumedMasterState`. Do not drop or reset it casually.
- Soft delete and trash use `isDeleted` and `purgeAt`. Wire `_deleted` is a hard-delete tombstone.
- Tenant state is scoped to the active organization: rows, favorites, recents, and replication checkpoints.
- Switching organizations clears replicated rows and checkpoints before pulling the new tenant.
- Pull is the primary path today. Push exists for dirty rows; do not assume one direction only.
- Derived local fields (folder and collection counts) are never sent or received.

Schema rules:

- Drift schema version lives in `lib/core/db/database.dart`. Bump it for schema changes.
- Migrations are append-only and idempotent. Guard column additions with existence checks when older databases can be in between versions.
- Add a migration test under `test/` when changing the schema.
- `lib/core/db/database.g.dart` is generated. Change tables and run `dart run build_runner build`; never hand-edit generated code.

Adding a replicated collection touches, at minimum: Drift table, replication adapter, wire mapping, API collection list, OpenAPI contract, and suite-side compatibility. Coordinate with the suite repo rather than inventing a shape.

Never drop, wipe, truncate, or reset the database or tenant data unless the human explicitly orders that exact operation.

---

## 7. Auth, API, and permissions

Auth:

- Better Auth over Dio, with persisted cookies and a bearer token in secure storage.
- Turnstile is required for sign-up, email sign-in, and password reset. The app loads the hosted captcha page in a WebView.
- Native Google sign-in exchanges an ID token at `/api/auth/sign-in/social`.
- Session and organization state drive routing. Keep `AuthStatus`, `resolvingOrganization`, and setup state consistent when changing auth flows.
- Do not bypass the auth, captcha, or social-auth seams.

API:

- `HosannaApi` in `lib/core/network/hosanna_api.dart` is hand-maintained and aligned with the OpenAPI operation IDs.
- `openapi/openapi.yaml` is a snapshot of the suite contract. Do not hand-edit it. Coordinate contract changes with the suite repo.
- Use the shared Dio interceptors for cookies, bearer, captcha, Origin, user agent, and error normalization.
- Normalize errors through `ApiException`. Do not surface raw server messages or secrets to users.

Permissions:

- `AppPermission` and `AppRole` mirror the server RBAC (`resource.action`).
- `kRoleStatements` must stay in sync with the server roles. If the server changes, update this app and ask before diverging.
- Unknown roles deny access by default. UI actions stay hidden until membership resolves.
- Validate both allowed and denied paths for security-sensitive changes.

Notifications and analytics:

- FCM device registration and notification consent are separate concerns. Respect the consent store.
- PostHog is disabled when no key is provided. Do not add telemetry, external services, or network calls without explicit approval.

---

## 8. i18n and UI

Localization:

- `lib/l10n/app_pt.arb` is the template. Keep `app_en.arb` and `app_es.arb` complete.
- No hardcoded user-facing strings. Use `AppLocalizations.of(context)`.
- Use locale-aware formatting for dates, numbers, and plurals.
- After ARB changes, run `flutter gen-l10n`. Generated files under `lib/l10n/generated/` are committed but not edited by hand.
- Keep keys grouped and named consistently with existing keys. Product copy may use proper typography for its locale; agent responses and code comments stay ASCII.

Visual language:

- Use `HosannaTokens`, `HosannaColors`, `HosannaSpacing`, and `HosannaRadii`. Do not add raw `Colors.*` values in new UI.
- Material 3, with light, dark, and high-contrast variants. Test all three when changing surfaces or text.
- Respect phone and tablet layouts, large text, and long locales. Avoid fixed heights that clip translated labels.
- Maintain touch targets (about 44dp), semantics, and focus behavior.
- Shared chrome and widgets belong in `lib/shared/` or `lib/app/design/`, not copied per feature.

Product rules:

- Per-musician transpose, capo, chord visibility, font size, and instrument preferences are device-local. Never mutate the stored song for a personal view setting.
- Stage tools (metronome, auto-scroll, wakelock, circle of fifths) must keep working offline.
- The ChordPro parser, transpose, and renderer are a Dart port under `lib/features/songs/domain/chordpro/`. Do not import the npm package.
- Annotations use Firestore plus a REST fallback and a local `.fcv` cache. Keep the offline path intact.

---

## 9. Tests and validation

Run the smallest relevant check first, then broaden.

```bash
flutter analyze
flutter test
flutter test test/<name>_test.dart
```

Patterns already in use:

- Unit tests for controllers, ChordPro logic, sync, permissions, and utilities.
- Widget tests with an in-memory Drift database and `SharedPreferences.setMockInitialValues`.
- Migration tests using a temporary database file and `NativeDatabase`.
- `test/test_pump.dart` for screens with infinite animations; avoid `pumpAndSettle` there.

When changing:

- Drift tables: bump schema version, add a migration, run `dart run build_runner build`, run migration tests.
- ARB files: run `flutter gen-l10n`, check all locales, run widget tests that render copy.
- Shared widgets or navigation: add or update widget tests for the affected flow.
- Auth, sync, or permissions: test both the allowed and the failure path.

Do not claim a change is tested if only static inspection was performed. Report the exact commands run and whether they passed.

---

## 10. Git and existing changes

- Default branch: `develop`. Do not create feature branches unless explicitly told.
- Commit in coherent batches with conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`). Focus the subject on why.
- Never co-author or co-sign commits. No `Co-authored-by`, no model attribution, no agent trailer.
- Do not push unless asked. Do not force-push, skip hooks, or rewrite shared history.
- Inspect `git status` before editing. Treat pre-existing modifications as user-owned.
- Never revert, overwrite, reformat, or include unrelated changes.
- If a requested change overlaps a modified hunk, inspect it carefully and preserve the user's intent. If the overlap makes the change unsafe, stop and ask.
- If the tree becomes clean or new commits appear while you work, the human committed. Adapt and continue.
- Tags matching `v*` trigger the Android release workflow. Do not create tags unless asked.

---

## 11. Writing style and comments

Agent responses, commit messages, and documentation:

- No em dashes. Use commas, parentheses, colons, or separate sentences.
- Sentence case for headings.
- ASCII punctuation by default.
- No emojis unless requested or required by an existing output format.
- No filler such as "Sure," "Absolutely," or "Great question."
- Do not restate the user's request unless clarification is needed.
- Explain decisions and tradeoffs briefly, not as long essays.

Comments in code:

- Comments are rare. Default is no comment.
- Do not narrate what the next lines do, restate a type or name, or write design essays.
- Do not add history, "why we changed it", "this used to", "IMPORTANT", or "NOTE:" comments.
- Allowed only for a non-obvious invariant or external constraint that code and names cannot express. One short line, present tense.
- When editing a hunk, strip narrative comments you would not be allowed to add. Do not drive-by-delete unrelated documentation.
- Prefer renaming a symbol over documenting a vague one.

Litmus test: if deleting the comment would not make a careful reader misunderstand an active, non-obvious invariant, delete it.

---

## 12. Safety and secrets

This project can run against real production-like data.

- Never print, paste, commit, or transmit secrets, tokens, cookies, private keys, keystores, or production credentials. Redact them from command output and responses.
- Do not commit signing keys, keystores, or `.env` contents. The existing `android/app/google-services.json` is tracked client configuration; do not add secrets to it.
- Do not run destructive database operations, migration resets, or mass deletes unless explicitly ordered.
- Be careful with auth cookies, session domains, billing, push devices, and replication checkpoints. Ask if a change could strand real users or data.
- Treat auth, authorization, billing, webhooks, file uploads, and user-controlled HTML as security-sensitive.
- Do not add dependencies, telemetry, external services, or network calls without approval.

---

## 13. Definition of done

A typical patch is done when:

1. Unclear product or architecture choices were resolved with the human.
2. Code matches existing patterns; new comments are strictly necessary.
3. `flutter analyze` passes.
4. Relevant tests were added or updated and pass.
5. ARB files were regenerated with `flutter gen-l10n` when copy changed.
6. Drift code was regenerated with `dart run build_runner build` when tables changed.
7. Docs were updated for big behavior or UI-direction changes.
8. The change is committed as a coherent conventional commit, without co-authors.
9. The response explains what system now exists or how it changed, and which commands were run.

---

## 14. Agent skills

Project skills live under `.agents/skills/` (gitignored). Refresh with `npx skills list -p` when needed.

Installed categories include:

- **Flutter and Dart:** `flutter`, `dart-add-unit-test`, `dart-run-static-analysis`, `dart-use-pattern-matching`, `dart-write-documentation`, `dart-use-primary-constructors`.
- **Flutter UI and architecture:** `flutter-apply-architecture-best-practices`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-add-widget-test`, `flutter-add-widget-preview`, `flutter-setup-localization`, `flutter-setup-declarative-routing`, `flutter-use-http-package`.
- **Data and platform:** `dart-generate-test-mocks`, `dart-collect-coverage`, `dart-resolve-package-conflicts`, `dart-setup-ffi-assets`, `dart-use-ffigen`, `flutter-implement-json-serialization`, `flutter-add-integration-test`, `dart-fix-runtime-errors`.

Hosanna docs and this handbook beat generic skill advice when they conflict.
