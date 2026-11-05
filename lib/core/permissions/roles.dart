import 'permission.dart';

/// Org roles recognized by Better Auth (Hosanna-server `permissions/roles.ts`).
enum AppRole {
  owner,
  admin,
  teamLeader,
  editor,
  musician,
  member,
  guest;

  static AppRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim();
    for (final role in AppRole.values) {
      if (role.name == normalized) return role;
    }
    return null;
  }
}

/// Role → granted actions, mirroring server access control.
///
/// `member` aliases `musician`. Keep in sync with
/// `Hosanna-server/src/permissions/roles.ts`.
const Map<AppRole, Map<String, Set<String>>> kRoleStatements = {
  AppRole.owner: {
    'song': {'create', 'access', 'update', 'delete', 'import'},
    'ai': {'manage', 'use'},
    'export': {'pdf'},
  },
  AppRole.admin: {
    'song': {'create', 'access', 'update', 'delete', 'import'},
    'ai': {'manage', 'use'},
    'export': {'pdf'},
  },
  AppRole.teamLeader: {
    'song': {'create', 'access', 'update', 'import'},
    'ai': {'use'},
    'export': {'pdf'},
  },
  AppRole.editor: {
    'song': {'create', 'access', 'update', 'import'},
    'ai': {'use'},
    'export': {'pdf'},
  },
  AppRole.musician: {
    'song': {'create', 'access', 'update', 'import'},
    'ai': {'use'},
    'export': {'pdf'},
  },
  AppRole.member: {
    'song': {'create', 'access', 'update', 'import'},
    'ai': {'use'},
    'export': {'pdf'},
  },
  AppRole.guest: {
    'song': {'access'},
    'export': {'pdf'},
  },
};

/// Whether [role] grants every permission in [permissions].
///
/// Returns `false` when the role is unknown so UI actions stay hidden until
/// membership resolves.
bool roleHasPermissions(AppRole? role, Iterable<AppPermission> permissions) {
  if (role == null) return false;
  final statements = kRoleStatements[role];
  if (statements == null) return false;
  for (final permission in permissions) {
    final actions = statements[permission.resource];
    if (actions == null || !actions.contains(permission.action)) {
      return false;
    }
  }
  return true;
}

bool roleHasPermission(AppRole? role, AppPermission permission) =>
    roleHasPermissions(role, [permission]);
