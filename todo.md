Key Issues Found:

1. Bug: SongView.tsx:107 - setWakeLockActive state never actually used (just _)
2. Performance: SongBrowser.tsx - full song list rendered without virtualization (could have
   hundreds of songs)
3. Bug: SongView.tsx:998-1013 - YouTube button state inconsistency (showYoutubePlayer and
   isPlayingYoutube are separate but linked incorrectly)
4. Performance: SongBrowser.tsx - lyrics search through ALL songs' content on every keystroke
   (very slow)
5. Bug: NavigationDrawer.tsx - uniqueFolders derived from songs.map(s => s.folder) without
   memoizing counts in a Map (O(n²) for large lists)
6. UX: FirstTimeSetup.tsx - missing loading state, no feedback while auth is loading
7. Bug: AuthContext.tsx - fetchSession called from useEffect but no guard against multiple
   concurrent calls
8. UX: No loading skeleton for SongBrowser when songs are being fetched
9. Bug: SongEditor.tsx - no unsaved changes guard when closing
