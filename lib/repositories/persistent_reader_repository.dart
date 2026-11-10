import "../models/list_query.dart";
import "../models/page_result.dart";
import "../models/reader.dart";
import "json_store.dart";
import "paging.dart";
import "reader_repository.dart";
import "seed_data.dart";

class PersistentReaderRepository implements ReaderRepository {
  PersistentReaderRepository(this._store);

  static const _key = "readers_v2";
  final JsonStore _store;
  late List<Reader> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedReaders.map((r) => r.copyWith()).toList();
    } else {
      try {
        _items = raw.map(Reader.fromJson).toList();
      } catch (_) {
        _items = seedReaders.map((r) => r.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Reader>> find(ListQuery q) async {
    var rows = _items.where((r) => q.includeDeleted || !r.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((r) =>
              r.lastName.toLowerCase().contains(needle) ||
              r.firstName.toLowerCase().contains(needle) ||
              r.email.toLowerCase().contains(needle) ||
              r.card.number.toLowerCase().contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        "email" => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        "firstName" => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        "card" => a.card.number.toLowerCase().compareTo(b.card.number.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Reader?> findById(int id) async {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<Reader> create(Reader reader) async {
    final created = reader.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final i = _items.indexWhere((r) => r.id == reader.id);
    if (i == -1) throw StateError("Читатель ${reader.id} не найден");
    _items[i] = reader;
    await _persist();
    return reader;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError("Читатель $id не найден");
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
    if (i == -1) throw StateError("Читатель $id не найден");
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
  Future<bool> emailExists(String email, {int? excludingId}) async {
    final needle = email.trim().toLowerCase();
    return _items.any((r) =>
        !r.isDeleted &&
        r.email.toLowerCase() == needle &&
        r.id != excludingId);
  }
}