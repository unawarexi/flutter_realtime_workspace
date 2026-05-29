/// Centralized RBAC/ABAC permission helper.
///
/// Uses [UserModel.permissionsLevel] to determine access.
/// Levels (ascending): guest → member → employee → manager → admin → super_admin
class PermissionHelper {
  PermissionHelper._();

  // ── Hierarchy index — higher = more access ──
  static const _hierarchy = <String, int>{
    'guest': 0,
    'member': 1,
    'employee': 2,
    'manager': 3,
    'admin': 4,
    'super_admin': 5,
  };

  static int _level(String permissionsLevel) =>
      _hierarchy[permissionsLevel] ?? 0;

  // ── Role checks ───────────────────────────────────────────────────────────

  static bool isSuperAdmin(String level) => level == 'super_admin';
  static bool isAdmin(String level) => _level(level) >= 4;
  static bool isManager(String level) => _level(level) >= 3;
  static bool isEmployee(String level) => _level(level) >= 2;
  static bool isMember(String level) => _level(level) >= 1;

  // ── Resource-specific gates ───────────────────────────────────────────────

  /// Whether the user can create projects, issues, teams, etc.
  static bool canCreate(String level, String resource) {
    switch (resource) {
      case 'project':
      case 'team':
      case 'channel':
      case 'workflow':
      case 'template':
        return isManager(level);
      case 'task':
      case 'issue':
      case 'ticket':
      case 'document':
      case 'schedule':
      case 'feedback':
        return isEmployee(level);
      case 'message':
      case 'comment':
        return isMember(level);
      case 'role':
      case 'policy':
      case 'integration':
      case 'organization':
        return isAdmin(level);
      case 'tenant':
        return isSuperAdmin(level);
      default:
        return isEmployee(level);
    }
  }

  /// Whether the user can edit/update a resource.
  static bool canEdit(String level, String resource, {bool isOwner = false}) {
    if (isAdmin(level)) return true;
    if (isOwner && isEmployee(level)) return true;
    switch (resource) {
      case 'task':
      case 'issue':
      case 'ticket':
        return isEmployee(level);
      case 'project':
      case 'team':
      case 'channel':
        return isManager(level);
      default:
        return isManager(level);
    }
  }

  /// Whether the user can delete a resource.
  static bool canDelete(String level, String resource) {
    switch (resource) {
      case 'project':
      case 'team':
      case 'channel':
      case 'workflow':
        return isAdmin(level);
      case 'task':
      case 'issue':
      case 'ticket':
        return isManager(level);
      case 'tenant':
        return isSuperAdmin(level);
      default:
        return isAdmin(level);
    }
  }

  /// Whether the user can manage members (invite, remove, change roles).
  static bool canManageMembers(String level) => isManager(level);

  /// Whether the user can access admin panel.
  static bool canAccessAdmin(String level) => isAdmin(level);

  /// Whether the user can access analytics dashboards.
  static bool canAccessAnalytics(String level) => isManager(level);

  /// Whether the user can use AI features.
  static bool canUseAI(String level) => isMember(level);

  /// Whether the user can use RAG queries.
  static bool canUseRAG(String level) => isEmployee(level);

  /// Whether the user can execute AI tools.
  static bool canExecuteAITools(String level) => isManager(level);

  /// Whether the user can impersonate other users.
  static bool canImpersonate(String level) => isSuperAdmin(level);

  // ── Display helpers ───────────────────────────────────────────────────────

  /// Human-readable role label.
  static String roleLabel(String level) {
    switch (level) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Employee';
      case 'member':
        return 'Member';
      case 'guest':
        return 'Guest';
      default:
        return 'Member';
    }
  }
}
