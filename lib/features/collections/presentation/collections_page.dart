import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/illustrations.dart';
import '../../../app/design/tokens.dart';
import '../../../app/shell_leading_button.dart';
import '../../../core/db/database.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bar_search_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hosanna_surface.dart';
import '../../../shared/widgets/shell_insets.dart';
import '../../folders/domain/folder_customization.dart';
import '../data/collection_repository.dart';
import 'collection_visuals.dart';

/// Grid hub for org collections — Studio-inspired, mobile-compact.
class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  final _search = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(syncControllerProvider.notifier).syncAll();

  void _clearSearch() {
    setState(() {
      _search.clear();
      _searchOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final collections =
        ref.watch(collectionsStreamProvider).valueOrNull ??
        const <CollectionRow>[];
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? collections
        : collections
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    (c.description?.toLowerCase().contains(query) ?? false),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ShellLeadingButton(),
        title: _searchOpen
            ? AppBarSearchField(
                controller: _search,
                hintText: l10n.collectionsSearchHint,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => setState(() {}),
              )
            : Text(l10n.navCollections),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            tooltip: l10n.commonSearch,
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _search.clear();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: visible.isEmpty
            ? (query.isNotEmpty
                  ? EmptyState(
                      illustrationAsset: HosannaIllustrations.emptySearch,
                      title: l10n.songsNoResults,
                      description: l10n.foldersNoResultsDesc,
                      primaryLabel: l10n.songsClearSearch,
                      primaryIcon: Icons.search_off_outlined,
                      onPrimary: _clearSearch,
                      scrollable: true,
                    )
                  : EmptyState(
                      illustrationAsset: HosannaIllustrations.emptyFolders,
                      title: l10n.collectionsEmpty,
                      description: l10n.collectionsEmptyDesc,
                      scrollable: true,
                    ))
            : GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  HosannaSpacing.md,
                  HosannaSpacing.sm,
                  HosannaSpacing.md,
                  shellBottomContentPadding(context),
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 196,
                  crossAxisSpacing: HosannaSpacing.sm,
                  mainAxisSpacing: HosannaSpacing.sm,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final collection = visible[index];
                  return _CollectionCard(
                    collection: collection,
                    onOpen: () =>
                        context.push('/collections/${collection.id}'),
                  );
                },
              ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onOpen});

  final CollectionRow collection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final image = collectionImageProvider(collection.image);
    final description = collection.description?.trim();
    final accent = folderColorOf(collection.color);

    return HosannaSurface(
      elevated: false,
      padding: EdgeInsets.zero,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 88,
            child: image != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(HosannaRadii.md - 1),
                    ),
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 88,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: accent.withValues(alpha: 0.10),
                        child: Center(
                          child: CollectionAccentBadge(
                            colorId: collection.color,
                            iconId: collection.icon,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  )
                : ColoredBox(
                    color: accent.withValues(alpha: 0.10),
                    child: Center(
                      child: CollectionAccentBadge(
                        colorId: collection.color,
                        iconId: collection.icon,
                        size: 44,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.foldersSongsCount(collection.songCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
