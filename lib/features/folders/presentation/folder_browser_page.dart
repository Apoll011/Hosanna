import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/sync_status_banner.dart';
import '../data/folder_repository.dart';

class FolderBrowserPage extends ConsumerWidget {
  const FolderBrowserPage({super.key});

  Future<void> _refresh(WidgetRef ref) =>
      ref.read(syncControllerProvider.notifier).syncAll();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final foldersAsync = ref.watch(foldersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foldersTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: SizedBox.shrink(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SyncStatusBanner(compact: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: switch (foldersAsync) {
                AsyncValue(:final value?) => _FolderTree(
                    folders: value,
                    onRefresh: () => _refresh(ref),
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTree extends StatelessWidget {
  const _FolderTree({required this.folders, required this.onRefresh});

  final List<FolderRow> folders;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roots = folders.where((f) => f.parentId == null).toList();

    if (roots.isEmpty) {
      return _Empty(message: l10n.foldersEmpty, onRefresh: onRefresh);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final root in roots)
          _FolderTile(folder: root, all: folders),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.all});

  final FolderRow folder;
  final List<FolderRow> all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final children = all.where((f) => f.parentId == folder.id).toList();

    final subtitle = [
      l10n.foldersSongsCount(folder.songCount),
      if (folder.folderCount > 0) l10n.foldersSubfolders,
    ].join(' · ');

    if (children.isEmpty) {
      return ListTile(
        leading: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
        title: Text(folder.name),
        subtitle: Text(subtitle),
      );
    }

    return ExpansionTile(
      leading: Icon(Icons.folder, color: theme.colorScheme.primary),
      title: Text(folder.name),
      subtitle: Text(subtitle),
      children: [
        for (final child in children)
          _FolderTile(folder: child, all: all),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
