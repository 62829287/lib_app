import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/password_rules.dart';
import 'package:library_app/models/auth_user.dart';
import 'package:library_app/models/build.dart';
import 'package:library_app/models/dota_hero.dart';
import 'package:library_app/models/list_query.dart';
import 'package:library_app/models/role.dart';

void main() {
  group('Валидаторы пароля', () {
    test('пустой пароль отклоняется', () {
      expect(PasswordRules.validate(null), 'Пароль обязателен');
      expect(PasswordRules.validate(''), 'Пароль обязателен');
    });

    test('пароль короче восьми символов отклоняется', () {
      expect(PasswordRules.validate('Ab1!xyz'), isNotNull);
      expect(PasswordRules.hasMinLength('1234567'), isFalse);
    });

    test('пароль без цифры отклоняется', () {
      expect(PasswordRules.hasDigit('Abcdefgh!'), isFalse);
      expect(PasswordRules.validate('Abcdefgh!'), contains('цифр'));
    });

    test('пароль без спецсимвола отклоняется', () {
      expect(PasswordRules.hasSpecial('Abcdefg1'), isFalse);
      expect(PasswordRules.validate('Abcdefg1'), contains('спец'));
    });
  });

  group('Разбор моделей', () {
    test('разбор героя из JSON', () {
      final hero = DotaHero.fromJson({
        'id': 7,
        'name': 'Pudge',
        'primaryAttribute': 'str',
        'attackType': 'melee',
        'deletedAt': null,
      });
      expect(hero.id, 7);
      expect(hero.name, 'Pudge');
      expect(hero.isDeleted, isFalse);
    });

    test('разбор сборки из JSON', () {
      final build = Build.fromJson({
        'id': 1,
        'title': 'Test',
        'code': 'CODE',
        'patch': '7.41',
        'difficulty': 3,
        'heroId': 2,
        'proPlayerIds': [1, 2],
        'roleIds': [3],
        'picks': 10,
        'wins': 4,
      });
      expect(build.code, 'CODE');
      expect(build.proPlayerIds, [1, 2]);
      expect(build.picks, 10);
    });

    test('разбор роли каталога из JSON', () {
      final role = Role.fromJson({
        'id': 3,
        'name': 'Support',
        'description': 'Heal',
      });
      expect(role.name, 'Support');
      expect(role.description, 'Heal');
    });

    test('разбор учётной записи из JSON', () {
      final user = AuthUser.fromJson({
        'id': 9,
        'username': 'reader',
        'displayName': 'Читатель',
        'role': 'viewer',
      });
      expect(user.username, 'reader');
      expect(user.role.key, 'viewer');
    });

    test('разбор параметров списка из query', () {
      final q = ListQuery.fromQueryParameters({
        'page': '2',
        'size': '20',
        'search': 'pudge',
        'sort': 'name,desc',
      });
      expect(q.page, 2);
      expect(q.size, 20);
      expect(q.search, 'pudge');
      expect(q.sortField, 'name');
      expect(q.sortAscending, isFalse);
    });
  });
}
