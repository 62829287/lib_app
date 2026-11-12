import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'hero_repository.dart';
import 'json_store.dart';
import 'paging.dart';
import 'seed_data.dart';

class PersistentHeroRepository implements HeroRepository {
  PersistentHeroRepository(this._store);

  static const _key = 'dota_heroes_v2';
  final JsonStore _store;
  late List<DotaHero> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedHeroes.map((h) => h.copyWith()).toList();
    } else {
      try {
        _items = raw.map(DotaHero.fromJson).toList();
      } catch (_) {
        _items = seedHeroes.map((h) => h.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, h) => h.id > m ? h.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<DotaHero>> find(ListQuery q) async {
    var rows = _items.where((h) => q.includeDeleted || !h.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (h) =>
                h.name.toLowerCase().contains(needle) ||
                h.primaryAttribute.toLowerCase().contains(needle) ||
                h.attackType.toLowerCase().contains(needle),
          )
          .toList();
    }
    final attr = q.filters['attribute'];
    if (attr != null && attr.isNotEmpty) {
      rows = rows.where((h) => h.primaryAttribute == attr).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'primaryAttribute' => a.primaryAttribute
            .toLowerCase()
            .compareTo(b.primaryAttribute.toLowerCase()),
        'attackType' =>
          a.attackType.toLowerCase().compareTo(b.attackType.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<DotaHero?> findById(int id) async {
    for (final h in _items) {
      if (h.id == id) return h;
    }
    return null;
  }

  @override
  Future<DotaHero> create(DotaHero hero) async {
    final created = hero.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<DotaHero> update(DotaHero hero) async {
    final i = _items.indexWhere((h) => h.id == hero.id);
    if (i == -1) throw StateError('Герой ${hero.id} не найден');
    _items[i] = hero;
    await _persist();
    return hero;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((h) => h.id == id);
    if (i == -1) throw StateError('Герой $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((h) => h.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((h) => h.id == id);
    if (i == -1) throw StateError('Герой $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((h) => h.id == id && !h.isDeleted);
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
    _items.removeWhere((h) => ids.contains(h.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((h) => h.id == id && h.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<DotaHero>> allActive() async =>
      _items.where((h) => !h.isDeleted).toList();
}
