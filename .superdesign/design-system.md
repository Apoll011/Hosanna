# Hosanna Design System — Concise Blue Redesign

## Product

Hosanna is a church musician app: offline-first song library (ChordPro), services/run-of-show, metronome, circle of fifths, org sync. Primary post-login surface is the **song library**. Brand: **Hosanna**.

## Brand

- **Logo:** Brand Asset key `assets-logo.png` — rounded square mark. MUST render in nav header, splash, sign-in — never initials, emoji, generic marks, invented SVG, or text-only substitutes.
- **Name:** "Hosanna" beside logo in nav when expanded.
- **Primary:** `#0284C7` (sky blue) — the only chromatic brand color in chrome.

## Concise color palette (HARD CONSTRAINT)

Use ONLY these tokens — no secondary purple, teal tertiary accents on nav icons, or rainbow icon colors.

| Token | Hex | Use |
|-------|-----|-----|
| primary | `#0284C7` | Brand, selected nav, key actions, logo title |
| primary-soft | `#E0F2FE` | Selected row / primary container tint |
| on-primary | `#FFFFFF` | Text on primary |
| surface | `#FFFFFF` | Main scaffold |
| surface-muted | `#F8FAFC` | Sidebar / drawer background |
| surface-elevated | `#F1F5F9` | Floating nav pill, chips |
| border | `#E2E8F0` | Hairline dividers |
| text | `#0F172A` | Primary text |
| text-muted | `#64748B` | Secondary text, inactive icons |
| danger | `#DC2626` | Favorite-on + errors only |

## Typography

- System / clean geometric sans (e.g. Plus Jakarta Sans or Inter-like). No decorative serifs.
- Titles: semibold–extrabold; list titles 15–16px; captions 12–13px muted.

## Layout (preserve IA)

- **Phone:** hamburger drawer + floating pill bottom nav (Songs | Services). Tools & settings via drawer.
- **Tablet ≥750:** persistent sidebar 288px (collapsed 76) + content; floating nav overlays content pane on Songs/Services.
- Lists: denser, clearer hierarchy — song number badge, title, one-line meta, favorite.
- Bottom content clears ~92px floating nav on phone.

## UX redesign goals

- Clearer visual hierarchy (less competing icon colors).
- Tighter list rows for stage scanning.
- Stronger selected states with primary-soft, not rainbow accents.
- Calm, readable musician UI — no marketing hero clutter.

## Motion

- Sidebar/drawer: 250ms ease-out. Prefer calm transitions.

## Component reuse

Prefer `<sd-component>` `HosannaNavContent` and `FloatingNavBar`. Logo inside nav component already embeds the Brand Asset URL.
