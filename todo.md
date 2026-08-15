Key Issues Found:

1. Bug: SongView.tsx:107 - setWakeLockActive state never actually used (just _)
2. Bug: SongView.tsx:998-1013 - YouTube button state inconsistency (showYoutubePlayer and
   isPlayingYoutube are separate but linked incorrectly)
3. Bug: NavigationDrawer.tsx - uniqueFolders derived from songs.map(s => s.folder) without
   memoizing counts in a Map (O(n²) for large lists)
4. UX: FirstTimeSetup.tsx - missing loading state, no feedback while auth is loading
5. Bug: AuthContext.tsx - fetchSession called from useEffect but no guard against multiple
   concurrent calls
6. Bug: SongEditor.tsx - no unsaved changes guard when closing
