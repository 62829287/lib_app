enum AuthRole {
  viewer(1, 'viewer', 'Читатель'),
  editor(2, 'editor', 'Редактор'),
  admin(3, 'admin', 'Администратор');

  const AuthRole(this.level, this.key, this.label);

  final int level;
  final String key;
  final String label;

  static AuthRole fromKey(String? raw) {
    final value = (raw ?? '').toLowerCase().trim();
    return AuthRole.values.firstWhere(
      (r) => r.key == value,
      orElse: () => AuthRole.viewer,
    );
  }

  bool atLeast(AuthRole other) => level >= other.level;
}

class Permissions {
  const Permissions._();

  static bool canBrowseBuilds(AuthRole role) => true;

  static bool canBrowsePros(AuthRole role) => true;

  static bool canBrowseReferenceData(AuthRole role) =>
      role.atLeast(AuthRole.editor);

  static bool canEditCatalog(AuthRole role) => role.atLeast(AuthRole.editor);

  static bool canHardDelete(AuthRole role) => role == AuthRole.admin;

  static bool canManageUsers(AuthRole role) => role == AuthRole.admin;

  static bool canOpenUsersSection(AuthRole role) => role == AuthRole.admin;
}
