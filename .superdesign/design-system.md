# Hosanna Design System (current baseline)

## Product

Hosanna is a church musician app: offline-first song library (ChordPro), services/run-of-show, metronome, circle of fifths, org sync. Primary post-login surface is the **song library**. Brand: **Hosanna**. Bundle id `com.embrace.hosanna`.

## Brand

- **Logo:** `assets/logo.png` via `HosannaLogo` (rounded square). Must appear in nav header, splash, sign-in, onboarding — never substitute initials/emoji/generic marks.
- **Name:** "Hosanna" in primary-colored titleMedium w800 in nav.
- **Seed / primary:** `#0284C7` (sky blue). Full palette from Material 3 `ColorScheme.fromSeed`.
- **Typography:** Material 3 defaults (no custom display font today). Prefer clean sans for musician readability on stage.

## Color roles (current)

| Role | Intent |
|------|--------|
| primary `#0284C7` family | Brand actions, selected nav, titles |
| surface / surfaceContainer* | Scaffold, pill nav, sidebar |
| onSurface / onSurfaceVariant | Body / secondary text |
| error | Favorites heart when active; errors |
| tertiary | Recents, metronome accents, offline sync |

**Redesign goal (user):** more **concise** palette — fewer competing accents (primary/secondary/tertiary/feature hex stacks), clearer hierarchy, better UX density for lists and musician flows.

## Layout patterns

- **Phone:** hamburger drawer + floating pill bottom nav (Songs | Services only). Tools & settings via drawer.
- **Tablet ≥750:** collapsible sidebar (76/288) + content; floating nav overlays content pane when relevant.
- **Full-screen:** song detail, service detail (no shell chrome).
- Lists use Material `ListTile`; empty states use soft primary circle + tonal CTA.
- Bottom content padding clears ~92px floating nav.

## Motion

- Sidebar/drawer collapse: 250ms `easeOutCubic`
- Prefer intentional, calm motion for stage use — avoid flashy gradients/glow

## Key screens for redesign priority

1. Song library (+ shell/nav)
2. Service list
3. Sign-in
4. Service detail / song reader (musician focus)
5. Metronome / settings (secondary)

## Constraints for Superdesign HTML drafts

- Mobile-first phone frame unless asked for tablet.
- Use ONLY fonts/colors/spacing declared in the active design-system for the draft round.
- Real logo Brand Asset URL in every logo position.
- Preserve information architecture: Library sections, Services, Tools, Settings — improve clarity, don't invent unrelated marketing sections.
