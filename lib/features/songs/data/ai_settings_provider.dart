import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/hosanna_api.dart';
import '../../../core/permissions/permissions.dart';
import '../../auth/domain/auth_controller.dart';

/// Org AI settings for the active workspace (`GET /ai/settings`).
///
/// Returns `null` when the user cannot use AI, the org has no settings, or
/// the request fails — UI should treat that as "AI not available".
final aiSettingsProvider = FutureProvider<AiSettingsPublic?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final orgId = auth.organization?.id;
  if (orgId == null) return null;
  if (!ref.watch(canPermissionProvider(AppPermission.aiUse))) return null;

  try {
    return await ref.watch(hosannaApiProvider).ai.getSettings();
  } catch (_) {
    return null;
  }
});

/// Whether Import with AI should be offered in the song library.
///
/// Matches Studio: needs `song.import` + `ai.use`, and org AI must be
/// `configured && enabled`.
final aiImportAvailableProvider = Provider<bool>((ref) {
  final canImport = ref.watch(canPermissionProvider(AppPermission.songImport));
  final canUseAi = ref.watch(canPermissionProvider(AppPermission.aiUse));
  if (!canImport || !canUseAi) return false;
  final settings = ref.watch(aiSettingsProvider).valueOrNull;
  return settings?.ready ?? false;
});
