import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';
import 'build_repository.dart';
import 'json_store.dart';
import 'paging.dart';
import 'seed_data.dart';

class PersistentBuildRepository implements BuildRepository {
  PersistentBuildRepository(this._store);

  static const _key = 'dota_builds_v2';
  final JsonStore _store;
  late List<Build> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedBuilds.map((b) => b.copyWith()).toList();
    } else {
      try {
        _items = raw.map(Build.fromJson).toList();
      } catch (_) {
        _items = seedBuilds.map((b) => b.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, b) => b.id > m ? b.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Build>> find(BuildQuery q) async {
    var rows = _items.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(needle) ||
                b.code.toLowerCase().contains(needle) ||
                b.patch.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.roleId != null) {
      rows = rows.where((b) => b.roleIds.contains(q.roleId)).toList();
    }
    if (q.heroId != null) {
      rows = rows.where((b) => b.heroId == q.heroId).toList();
    }
    if (q.proPlayerId != null) {
      rows = rows.where((b) => b.proPlayerIds.contains(q.proPlayerId)).toList();
    }
    if (q.difficultyFrom != null) {
      rows = rows.where((b) => b.difficulty >= q.difficultyFrom!).toList();
    }
    if (q.difficultyTo != null) {
      rows = rows.where((b) => b.difficulty <= q.difficultyTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'difficulty' => a.difficulty.compareTo(b.difficulty),
        'picks' => a.picks.compareTo(b.picks),
        'wins' => a.wins.compareTo(b.wins),
        'code' => a.code.compareTo(b.code),
        'patch' => a.patch.compareTo(b.patch),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Build?> findById(int id) async {
    for (final b in _items) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<Build> create(Build build) async {
    final created = build.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Build> update(Build build) async {
    final i = _items.indexWhere((b) => b.id == build.id);
    if (i == -1) throw StateError('Сборка ${build.id} не найдена');
    _items[i] = build.copyWith();
    await _persist();
    return _items[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Сборка $id не найдена');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Сборка $id не найдена');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((b) => b.id == id && !b.isDeleted);
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
    _items.removeWhere((b) => ids.contains(b.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((b) => b.id == id && b.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> codeExists(String code, {int? excludingId}) async {
    final needle = code.trim().toLowerCase();
    return _items.any(
      (b) =>
          !b.isDeleted &&
          b.code.toLowerCase() == needle &&
          b.id != excludingId,
    );
  }

  @override
  Future<int> countByHero(int heroId) async {
    return _items.where((b) => !b.isDeleted && b.heroId == heroId).length;
  }

  @override
  Future<List<int>> proPlayerIdsLinkedToHero(int heroId) async {
    final ids = <int>{};
    for (final b in _items) {
      if (!b.isDeleted && b.heroId == heroId) ids.addAll(b.proPlayerIds);
    }
    return ids.toList()..sort();
  }

  @override
  Future<List<int>> roleIdsLinkedToHero(int heroId) async {
    final ids = <int>{};
    for (final b in _items) {
      if (!b.isDeleted && b.heroId == heroId) ids.addAll(b.roleIds);
    }
    return ids.toList()..sort();
  }
}
