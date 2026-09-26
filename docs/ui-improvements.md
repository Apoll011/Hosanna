# Hosanna UI improvement backlog

Review date: 2026-09-26 · Updated: 2026-09-27  
Scope: Flutter musician app (`lib/features`, `lib/app`, shared widgets)

---

## Done in recent passes

- Empty vs error states (shared `EmptyState` / `ErrorState`, clearer copy).
- **Metronome sound** — fixed silent clicks (`resume()` was a no-op until `play()`; now uses `play(source)` on non-Android; Android still uses SoundPool stop/resume; WAV temp files on all platforms; immediate downbeat on start).
- Floating nav list/grid bottom padding (`shellBottomContentPadding`).
- Service musician top bar: Leave collapses to icon on narrow widths; drawer edge-drag disabled (swipe conflict).
- Annotation toolbar: 44dp color swatches; stroke slider stacks on narrow; remote-sync banner localized + wraps.
- Shared font-size range 12–28 (`SongDisplaySettings.min/maxFontSize`).
- Metronome: scrollable/compact layout, semantics on play/BPM steppers, audio-failure message.
- Circle of fifths: responsive size, centered harmonic field, semantic key buttons.
- Theme tokens instead of raw `Colors.*` (drawer, favorites, active-org, element types).
- AppBar search fields use title/hint styles; song detail shows title; breadcrumbs larger hit targets.
- i18n: archived typo, variant labels, language “System”, font preview sample, annotation remote strings.

---

## Still open (P1/P2)

### P1

- Settings tabs overflow with large text / long locales — scrollable or icons-only under breakpoint.
- Filter sheet: long chip walls without search/collapse.
- Active filter chip row fixed height 56 — clips with large text; sort ↑/↓ a11y labels.
- Settings password visibility toggle / autofill hints.
- Folders discoverability on bottom nav (optional 3rd tab).
- Folder AppBar crowded on phone (grid toggle → overflow under ~600dp).
- Service list: “Show archived” when archives exist.

### P2

- Align list leading badge sizes across songs/folders/services.
- Favorite affordance on folder browser song rows.
- Auth chrome unify (empty vs titled AppBars).
- Annotation toolbar enter/exit animation.
- Broader Semantics pass (BPM live region polish, filter badge count, auth errors).
- Settings display card section split (Display vs Device).

---

## Suggested next slice

1. Settings tabs + password visibility.  
2. Filter sheet search/collapse + active-chip height.  
3. Optional Folders bottom-nav destination.
