Key Issues Found:

3. Bug: NavigationDrawer.tsx - uniqueFolders derived from songs.map(s => s.folder) without
   memoizing counts in a Map (O(n²) for large lists)
4. Bug: AuthContext.tsx - fetchSession called from useEffect but no guard against multiple
   concurrent calls
5. Bug: SongEditor.tsx - no unsaved changes guard when closing
   j
