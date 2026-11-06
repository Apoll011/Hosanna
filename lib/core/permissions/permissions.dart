import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_controller.dart';
import 'permission.dart';
import 'roles.dart';

export 'permission.dart';
export 'roles.dart';

/// Active organization membership role for the signed-in user.
final memberRoleProvider = Provider<AppRole?>((ref) {
  return AppRole.tryParse(ref.watch(authControllerProvider).memberRole);
});

/// Whether the active member role grants [permission].
bool can(WidgetRef ref, AppPermission permission) {
  return roleHasPermission(ref.watch(memberRoleProvider), permission);
}

/// Provider form of [can] for a single permission.
final canPermissionProvider =
    Provider.family<bool, AppPermission>((ref, permission) {
  return roleHasPermission(ref.watch(memberRoleProvider), permission);
});
