import "../models/book_query.dart";
import "../models/genre.dart";
import "../models/list_query.dart";
import "../models/page_result.dart";
import "book_repository.dart";
import "genre_repository.dart";
import "json_store.dart";
import "paging.dart";
import "seed_data.dart";

class PersistentGenreRepository implements GenreRepository {
  PersistentGenreRepository(this._store, {this.books});

  static const _key = "genres_v3";
  final JsonStore _store;
  BookRepository? books;
  late List<Genre> _items;
  late int _nextId;

  void attachBooks(BookRepository value) => books = value;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedGenres.map((g) => g.copyWith()).toList();
    } else {
      try {
        _items = raw.map(Genre.fromJson).toList();
      } catch (_) {
        _items = seedGenres.map((g) => g.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, g) => g.id > m ? g.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<Genre>> find(ListQuery q) async {
    var rows = _items.where((g) => q.includeDeleted || !g.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((g) =>
              g.name.toLowerCase().contains(needle) ||
              g.description.toLowerCase().contains(needle))
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        "description" => a.description.toLowerCase().compareTo(b.description.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Genre?> findById(int id) async {
    for (final g in _items) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  Future<Genre> create(Genre genre) async {
    final created = genre.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _items.indexWhere((g) => g.id == genre.id);
    if (i == -1) throw StateError("Жанр ${genre.id} не найден");
    _items[i] = genre;
    await _persist();
    return genre;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError("Жанр $id не найден");
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((g) => g.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError("Жанр $id не найден");
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((g) => g.id == id && !g.isDeleted);
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
    _items.removeWhere((g) => ids.contains(g.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((g) => g.id == id && g.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<Genre>> allActive() async =>
      _items.where((g) => !g.isDeleted).toList();

  @override
  Future<int> countBooksUsing(int genreId) async {
    if (books == null) return 0;
    final page = await books!.find(
      BookQuery(size: 1000, includeDeleted: true),
    );
    return page.items.where((b) => b.genreIds.contains(genreId)).length;
  }
}