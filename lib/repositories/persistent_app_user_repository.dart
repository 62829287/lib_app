import '../models/app_user.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'app_user_repository.dart';
import 'json_store.dart';
import 'paging.dart';
import 'seed_data.dart';

class PersistentAppUserRepository implements AppUserRepository {
  PersistentAppUserRepository(this._store);

  static const _key = 'dota_users_v2';
  final JsonStore _store;
  late List<AppUser> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedUsers.map((u) => u.copyWith()).toList();
    } else {
      try {
        _items = raw.map(AppUser.fromJson).toList();
      } catch (_) {
        _items = seedUsers.map((u) => u.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, u) => u.id > m ? u.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<AppUser>> find(ListQuery q) async {
    var rows = _items.where((u) => q.includeDeleted || !u.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (u) =>
                u.nickname.toLowerCase().contains(needle) ||
                u.email.toLowerCase().contains(needle) ||
                u.steam.nickname.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'region' => a.region.toLowerCase().compareTo(b.region.toLowerCase()),
        'steam' => a.steam.nickname
            .toLowerCase()
            .compareTo(b.steam.nickname.toLowerCase()),
        'rating' => a.steam.rating.compareTo(b.steam.rating),
        _ => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<AppUser?> findById(int id) async {
    for (final u in _items) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  Future<AppUser> create(AppUser user) async {
    final created = user.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<AppUser> update(AppUser user) async {
    final i = _items.indexWhere((u) => u.id == user.id);
    if (i == -1) throw StateError('Пользователь ${user.id} не найден');
    _items[i] = user;
    await _persist();
    return user;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((u) => u.id == id);
    if (i == -1) throw StateError('Пользователь $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((u) => u.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((u) => u.id == id);
    if (i == -1) throw StateError('Пользователь $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((u) => u.id == id && !u.isDeleted);
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
    _items.removeWhere((u) => ids.contains(u.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((u) => u.id == id && u.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> emailExists(String email, {int? excludingId}) async {
    final needle = email.trim().toLowerCase();
    return _items.any(
      (u) =>
          !u.isDeleted &&
          u.email.toLowerCase() == needle &&
          u.id != excludingId,
    );
  }
}
