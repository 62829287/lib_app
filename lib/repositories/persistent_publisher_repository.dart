import "../models/list_query.dart";
import "../models/page_result.dart";
import "../models/publisher.dart";
import "json_store.dart";
import "paging.dart";
import "publisher_repository.dart";
import "seed_data.dart";

class PersistentPublisherRepository implements PublisherRepository {
  PersistentPublisherRepository(this._store);

  static const _key = "publishers_v2";
  final JsonStore _store;
  late List<Publisher> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedPublishers.map((p) => p.copyWith()).toList();
    } else {
      try {
        _items = raw.map(Publisher.fromJson).toList();
      } catch (_) {
        _items = seedPublishers.map((p) => p.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Publisher>> find(ListQuery q) async {
    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              p.city.toLowerCase().contains(needle) ||
              p.country.toLowerCase().contains(needle))
          .toList();
    }
    final country = q.filters["country"];
    if (country != null && country.isNotEmpty) {
      rows = rows.where((p) => p.country == country).toList();
    }
    final city = q.filters["city"];
    if (city != null && city.isNotEmpty) {
      rows = rows.where((p) => p.city == city).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        "city" => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        "country" => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Publisher?> findById(int id) async {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final created = publisher.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final i = _items.indexWhere((p) => p.id == publisher.id);
    if (i == -1) throw StateError("Издательство ${publisher.id} не найдено");
    _items[i] = publisher;
    await _persist();
    return publisher;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError("Издательство $id не найдено");
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError("Издательство $id не найдено");
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
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
    _items.removeWhere((p) => ids.contains(p.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<Publisher>> allActive() async =>
      _items.where((p) => !p.isDeleted).toList();

  @override
  Future<List<String>> cities({String? country}) async {
    final rows = _items.where((p) => !p.isDeleted).where((p) {
      if (country == null || country.isEmpty) return true;
      return p.country == country;
    });
    return rows.map((p) => p.city).toSet().toList()..sort();
  }
}