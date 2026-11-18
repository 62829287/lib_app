import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/password_rules.dart';
import 'package:library_app/core/router.dart';
import 'package:library_app/models/auth_role.dart';

void main() {
  group('Права доступа по ролям', () {
    test('читатель может только просматривать сборки и про-игроков', () {
      const role = AuthRole.viewer;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isFalse);
      expect(Permissions.canEditCatalog(role), isFalse);
      expect(Permissions.canHardDelete(role), isFalse);
      expect(Permissions.canManageUsers(role), isFalse);
      expect(Permissions.canOpenUsersSection(role), isFalse);
    });

    test('редактор может править каталог, но не управляет пользователями', () {
      const role = AuthRole.editor;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isTrue);
      expect(Permissions.canEditCatalog(role), isTrue);
      expect(Permissions.canHardDelete(role), isFalse);
      expect(Permissions.canManageUsers(role), isFalse);
      expect(Permissions.canOpenUsersSection(role), isFalse);
    });

    test('администратор имеет все операции, включая пользователей и hard-delete', () {
      const role = AuthRole.admin;
      expect(Permissions.canBrowseBuilds(role), isTrue);
      expect(Permissions.canBrowsePros(role), isTrue);
      expect(Permissions.canBrowseReferenceData(role), isTrue);
      expect(Permissions.canEditCatalog(role), isTrue);
      expect(Permissions.canHardDelete(role), isTrue);
      expect(Permissions.canManageUsers(role), isTrue);
      expect(Permissions.canOpenUsersSection(role), isTrue);
    });

    test('читателю закрыты справочники и маршруты изменения', () {
      expect(routeAllowedFor(AuthRole.viewer, '/builds'), isTrue);
      expect(routeAllowedFor(AuthRole.viewer, '/pros'), isTrue);
      expect(routeAllowedFor(AuthRole.viewer, '/builds/new'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/pros/new'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/heroes'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/roles'), isFalse);
      expect(routeAllowedFor(AuthRole.viewer, '/users'), isFalse);
    });

    test('редактору доступен каталог, пользователи закрыты', () {
      expect(routeAllowedFor(AuthRole.editor, '/heroes'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/roles/new'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/pros/2/edit'), isTrue);
      expect(routeAllowedFor(AuthRole.editor, '/users'), isFalse);
      expect(routeAllowedFor(AuthRole.admin, '/users/new'), isTrue);
      expect(routeAllowedFor(AuthRole.admin, '/builds/new'), isTrue);
    });

    test('уровни ролей: читатель < редактор < администратор', () {
      expect(AuthRole.viewer.atLeast(AuthRole.viewer), isTrue);
      expect(AuthRole.viewer.atLeast(AuthRole.editor), isFalse);
      expect(AuthRole.editor.atLeast(AuthRole.viewer), isTrue);
      expect(AuthRole.editor.atLeast(AuthRole.admin), isFalse);
      expect(AuthRole.admin.atLeast(AuthRole.editor), isTrue);
    });
  });

  group('Правила пароля', () {
    test('нужны длина, цифра и спецсимвол', () {
      expect(PasswordRules.isStrong('short'), isFalse);
      expect(PasswordRules.isStrong('longenough'), isFalse);
      expect(PasswordRules.isStrong('longenough1'), isFalse);
      expect(PasswordRules.isStrong('longenough1!'), isTrue);
      expect(PasswordRules.validate('abc'), isNotNull);
      expect(PasswordRules.validate('reader123!'), isNull);
    });
  });
}
