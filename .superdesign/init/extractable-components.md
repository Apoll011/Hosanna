# Extractable components — Hosanna

## HosannaNavContent (Drawer / Sidebar)
- Source: `lib/app/hosanna_drawer.dart` (`HosannaNavContent`, `HosannaDrawer`)
- Category: layout
- Description: Full nav — logo, sync, library sections, collections, tools, user→settings
- Extractable props: `collapsed` (boolean, default false), `currentBranch` (number/string, default songs), `activeLibrarySection` (string: all|favorites|recent|folders)
- Hardcoded: section labels, icon names, logo size 40, animation 250ms, Material icon set

## FloatingNavBar
- Source: `lib/app/shell.dart` (`_FloatingNavBar`)
- Category: layout
- Description: Pill bottom bar with Songs + Services only
- Extractable props: `selectedIndex` (number, default 0)
- Hardcoded: height 64, radius 42, Songs/Services icons+labels, shadow

## HosannaShell chrome
- Source: `lib/app/shell.dart`
- Category: layout
- Description: Phone drawer scaffold vs tablet sidebar+content split
- Extractable props: `isTablet` (boolean), `showNavBar` (boolean), `sidebarCollapsed` (boolean)
- Hardcoded: breakpoint 750, sidebar widths 76/288

## EmptyState
- Source: `lib/shared/widgets/empty_state.dart`
- Category: basic
- Description: Centered empty / error placeholders with optional CTAs
- Extractable props: `title` (string), `description` (string), `tone` (calm|error), `primaryLabel` (string?)
- Hardcoded: 88px circle, maxWidth 320, icon sizes

## HosannaLogo
- Source: `lib/shared/widgets/hosanna_logo.dart`
- Category: basic
- Description: Brand mark
- Extractable props: `size` (number, default 72)
- Hardcoded: `assets/logo.png`, borderRadius scale

## SyncStatusBanner
- Source: `lib/shared/widgets/sync_status_banner.dart`
- Category: basic
- Description: Sync status row
- Extractable props: `status` (string), `compact` (boolean), `lastSyncedLabel` (string)
- Hardcoded: icons per status

## SongListRow (pattern from SongLibraryPage)
- Source: `lib/features/songs/presentation/song_library_page.dart` (ListTile builder)
- Category: basic
- Description: Song row — badge, title, artist·folder·tags, favorite
- Extractable props: `title`, `subtitle`, `songNumber`, `isFavorite` (boolean)
- Hardcoded: ListTile layout, favorite colors

## ServiceListRow (pattern from ServiceListPage)
- Source: `lib/features/services/presentation/service_list_page.dart`
- Category: basic
- Description: Service row — calendar icon, name, date, chevron
- Extractable props: `name`, `dateLabel`, `archived` (boolean)
- Hardcoded: ListTile + Icons.calendar_month_outlined
