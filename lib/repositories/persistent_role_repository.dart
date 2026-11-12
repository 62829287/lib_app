import '../models/build_query.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import 'build_repository.dart';
import 'json_store.dart';
import 'paging.dart';
import 'role_repository.dart';
import 'seed_data.dart';

class PersistentRoleRepository implements RoleRepository {
  PersistentRoleRepository(this._store, {this.builds});

  static const _key = 'dota_roles_v2';
  final JsonStore _store;
  BuildRepository? builds;
  late List<Role> _items;
  late int _nextId;

  void attachBuilds(BuildRepository value) => builds = value;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedRoles.map((r) => r.copyWith()).toList();
    } else {
      try {
        _items = raw.map(Role.fromJson).toList();
      } catch (_) {
        _items = seedRoles.map((r) => r.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Role>> find(ListQuery q) async {
    var rows = _items.where((r) => q.includeDeleted || !r.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (r) =>
                r.name.toLowerCase().contains(needle) ||
                r.description.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'description' =>
          a.description.toLowerCase().compareTo(b.description.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Role?> findById(int id) async {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<Role> create(Role role) async {
    final created = role.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Role> update(Role role) async {
    final i = _items.indexWhere((r) => r.id == role.id);
    if (i == -1) throw StateError('Роль ${role.id} не найдена');
    _items[i] = role;
    await _persist();
    return role;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Роль $id не найдена');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Роль $id не найдена');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    final before = _items.length;
    _items.removeWhere((r) => ids.contains(r.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((r) => r.id == id && r.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<Role>> allActive() async =>
      _items.where((r) => !r.isDeleted).toList();

  @override
  Future<int> countBuildsUsing(int roleId) async {
    if (builds == null) return 0;
    final page = await builds!.find(
      const BuildQuery(size: 1000, includeDeleted: true),
    );
    return page.items.where((b) => b.roleIds.contains(roleId)).length;
  }
}
