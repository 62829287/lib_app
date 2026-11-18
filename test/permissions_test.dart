import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/password_rules.dart';
import 'package:library_app/core/router.dart';
import 'package:library_app/models/auth_role.dart';

void main() {
  group('Permissions by role', () {
    test('viewer may browse builds and pros only', () {
      const role = AuthRole.viewer;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isFalse);
      expect(Permissions.canEditCatalog(role), isFalse);
      expect(Permissions.canHardDelete(role), isFalse);
      expect(Permissions.canManageUsers(role), isFalse);
      expect(Permissions.canOpenUsersSection(role), isFalse);
    });

    test('editor may browse and edit catalog but not manage users', () {
      const role = AuthRole.editor;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isTrue);
      expect(Permissions.canEditCatalog(role), isTrue);
      expect(Permissions.canHardDelete(role), isFalse);
      expect(Permissions.canManageUsers(role), isFalse);
      expect(Permissions.canOpenUsersSection(role), isFalse);
    });

    test('admin has all operations including users and hard-delete', () {
      const role = AuthRole.admin;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isTrue);
      expect(Permissions.canEditCatalog(role), isTrue);
      expect(Permissions.canHardDelete(role), isTrue);
      expect(Permissions.canManageUsers(role), isTrue);
      expect(Permissions.canOpenUsersSection(role), isTrue);
    });

    test('routeAllowedFor blocks viewer from reference and mutate paths', () {
      expect(routeAllowedFor(AuthRole.viewer, '/builds'), isTrue);
      expect(routeAllowedFor(AuthRole.viewer, '/pros'), isTrue);
      expect(routeAllowedFor(AuthRole.viewer, '/builds/new'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/pros/new'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/heroes'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/roles'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/users'), isFalse);
    });

    test('routeAllowedFor allows editor catalog but not users', () {
      expect(routeAllowedFor(AuthRole.editor, '/heroes'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/roles/new'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/pros/2/edit'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/users'), isFalse);
      expect(routeAllowedFor(AuthRole.admin, '/users/new'), isTrue);
      expect(routeAllowedFor(AuthRole.admin, '/builds/new'), isTrue);
    });

    test('role levels are ordered viewer < editor < admin', () {
      expect(AuthRole.viewer.atLeast(AuthRole.viewer), isTrue);
      expect(AuthRole.viewer.atLeast(AuthRole.editor), isFalse);
      expect(AuthRole.editor.atLeast(AuthRole.viewer), isTrue);
      expect(AuthRole.editor.atLeast(AuthRole.admin), isFalse);
      expect(AuthRole.admin.atLeast(AuthRole.editor), isTrue);
    });
  });

  group('PasswordRules', () {
    test('requires length, digit and special as user types', () {
      expect(PasswordRules.isStrong('short'), isFalse);
      expect(PasswordRules.isStrong('longenough'), isFalse);
      expect(PasswordRules.isStrong('longenough1'), isFalse);
      expect(PasswordRules.isStrong('longenough1!'), isTrue);
      expect(PasswordRules.validate('abc'), isNotNull);
      expect(PasswordRules.validate('reader123!'), isNull);
    });
  });
}
