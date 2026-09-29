# Page dependency trees — Hosanna

Candidate `--context-file` sets. Apply PAYLOAD BUDGET (~900-line threshold) when generating.

## /songs (Song library) — PRIMARY HOME
Entry: `lib/features/songs/presentation/song_library_page.dart`
Dependencies:
- `lib/app/shell_leading_button.dart`
  - `lib/app/shell.dart` (breakpoint)
  - `lib/app/providers.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/shell_insets.dart`
  - `lib/app/shell.dart`
- `lib/features/songs/presentation/song_filter_widgets.dart`
- `lib/features/songs/presentation/song_filters.dart`
- Shell (parent): `lib/app/shell.dart`, `lib/app/hosanna_drawer.dart`
  - `lib/shared/widgets/hosanna_logo.dart`
  - `lib/shared/widgets/sync_status_banner.dart`

## /services (Service list)
Entry: `lib/features/services/presentation/service_list_page.dart`
Dependencies:
- `lib/app/shell_leading_button.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/shell_insets.dart`
- Shell: `lib/app/shell.dart`, `lib/app/hosanna_drawer.dart`

## /songs/:id (Song detail / reader)
Entry: `lib/features/songs/presentation/song_detail_page.dart`
Dependencies:
- `lib/shared/widgets/empty_state.dart`
- `lib/features/songs/presentation/song_reader.dart`
  - `lib/features/songs/presentation/song_body_renderer.dart`
  - `lib/features/songs/presentation/chordpro/song_display_settings.dart`
- `lib/features/songs/presentation/song_toolbar.dart`
- `lib/features/export/presentation/song_pdf_share.dart`
(Outside shell — full-screen)

## /services/:id (Service detail / musician view)
Entry: `lib/features/services/presentation/service_detail_page.dart`
Dependencies:
- `lib/shared/widgets/empty_state.dart`
- `lib/features/songs/presentation/song_reader.dart`
- `lib/features/songs/presentation/song_toolbar.dart`
- `lib/features/services/presentation/service_order_page.dart`
- `lib/features/services/presentation/service_element_meta.dart`
- `lib/features/services/presentation/widgets/horizontal_swipe_navigator.dart`
- `lib/features/services/presentation/widgets/service_notes_panel.dart`
(Outside shell — full-screen)

## /metronome
Entry: `lib/features/metronome/presentation/metronome_page.dart`
Dependencies:
- `lib/app/shell_leading_button.dart`
- Shell: `lib/app/shell.dart`, `lib/app/hosanna_drawer.dart`
(No floating nav bar)

## /circle-of-fifths
Entry: `lib/features/circle_of_fifths/presentation/circle_of_fifths_page.dart`
Dependencies:
- `lib/app/shell_leading_button.dart`
- Shell layouts

## /folders
Entry: `lib/features/folders/presentation/folder_browser_page.dart`
Dependencies:
- `lib/app/shell_leading_button.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/shell_insets.dart`
- `lib/features/songs/presentation/song_filter_widgets.dart`
- `lib/features/songs/presentation/song_filters.dart`
- Shell layouts

## /settings
Entry: `lib/features/settings/presentation/settings_page.dart` (~1332 lines — line-range render sections when passing)
Dependencies:
- `lib/app/shell_leading_button.dart`
- `lib/app/theme.dart`
- `lib/features/songs/presentation/chordpro/instrument_selector.dart`
- `lib/features/songs/presentation/chordpro/song_display_settings.dart`
- Shell layouts (no floating nav)

## /sign-in
Entry: `lib/features/auth/presentation/sign_in_page.dart`
Dependencies:
- `lib/shared/widgets/hosanna_logo.dart`
- `lib/features/auth/presentation/auth_ui_utils.dart`
- `lib/features/auth/presentation/social_sign_in_button.dart`
  - `lib/shared/widgets/google_g_logo.dart`

## /onboarding
Entry: `lib/features/onboarding/presentation/onboarding_page.dart`
Dependencies:
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/hosanna_logo.dart`
