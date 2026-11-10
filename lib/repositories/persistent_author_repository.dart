import "../models/author.dart";
import "../models/author_query.dart";
import "../models/page_result.dart";
import "author_repository.dart";
import "json_store.dart";
import "paging.dart";
import "seed_data.dart";

class PersistentAuthorRepository implements AuthorRepository {
  PersistentAuthorRepository(this._store);

  static const _key = "authors_v2";
  final JsonStore _store;
  late List<Author> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = [...seedAuthors];
    } else {
      try {
        _items = raw.map(Author.fromJson).toList();
      } catch (_) {
        _items = [...seedAuthors];
      }
    }
    _nextId = _items.fold<int>(0, (m, a) => a.id > m ? a.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    var rows = _items.where((a) => q.includeDeleted || !a.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle) ||
              a.firstName.toLowerCase().contains(needle))
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        "firstName" => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        "country" => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        "birthYear" => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Author?> findById(int id) async {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<Author> create(Author author) async {
    final created = author.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _items.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError("Автор ${author.id} не найден");
    _items[i] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError("Автор $id не найден");
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError("Автор $id не найден");
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((a) => a.id == id && !a.isDeleted);
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
    _items.removeWhere((a) => ids.contains(a.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((a) => a.id == id && a.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<Author>> allActive() async =>
      _items.where((a) => !a.isDeleted).toList();
}