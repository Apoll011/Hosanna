import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/sync/sync_controller.dart';
import '../../l10n/generated/app_localizations.dart';

/// Compact sync status indicator: idle / syncing / synced / error / offline,
/// plus the last-synced timestamp and a manual sync affordance.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (IconData icon, Color color, String label) = switch (sync.status) {
      SyncStatus.syncing => (
          Icons.sync,
          theme.colorScheme.primary,
          l10n.syncSyncing
        ),
      SyncStatus.synced => (
          Icons.cloud_done_outlined,
          theme.colorScheme.primary,
          l10n.syncSynced
        ),
      SyncStatus.error => (
          Icons.cloud_off_outlined,
          theme.colorScheme.error,
          l10n.syncError
        ),
      SyncStatus.offline => (
          Icons.wifi_off,
          theme.colorScheme.tertiary,
          l10n.syncOffline
        ),
      SyncStatus.idle => (
          Icons.cloud_outlined,
          theme.colorScheme.onSurfaceVariant,
          l10n.syncSynced
        ),
    };

    final lastSynced = sync.lastSyncedAt == null
        ? l10n.syncNever
        : l10n.syncLastSynced(
            DateFormat.Hm(Localizations.localeOf(context).toString())
                .format(sync.lastSyncedAt!),
          );

    return Row(
      children: [
        if (sync.isSyncing)
          const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: compact ? 16 : 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            compact ? label : '$label · $lastSynced',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
