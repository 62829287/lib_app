import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'json_store.dart';
import 'paging.dart';
import 'seed_data.dart';

class PersistentBookRepository implements BookRepository {
  PersistentBookRepository(this._store, {this.latency = Duration.zero});

  static const _key = 'books_v2';

  final JsonStore _store;
  final Duration latency;
  late List<Book> _books;
  late int _nextId;

  Future<void> _delay() => Future<void>.delayed(latency);

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _books = seedBooks.map((b) => b.copyWith()).toList();
      _nextId = _books.fold<int>(0, (m, b) => b.id > m ? b.id : m) + 1;
      _persist();
      return;
    }
    try {
      _books = raw.map(Book.fromJson).toList();
      _nextId = _books.fold<int>(0, (m, b) => b.id > m ? b.id : m) + 1;
    } catch (_) {
      _books = seedBooks.map((b) => b.copyWith()).toList();
      _nextId = _books.fold<int>(0, (m, b) => b.id > m ? b.id : m) + 1;
      _persist();
    }
  }

  Future<void> _persist() =>
      _store.writeList(_key, _books.map((b) => b.toJson()).toList());

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await _delay();
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(needle) ||
                b.isbn.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        'isbn' => a.isbn.compareTo(b.isbn),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<Book?> findById(int id) async {
    await _delay();
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<Book> create(Book book) async {
    await _delay();
    final created = book.copyWith(id: _nextId++);
    _books.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book.copyWith();
    await _persist();
    return _books[i];
  }

  @override
  Future<void> softDelete(int id) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await _delay();
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    await _delay();
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    await _delay();
    final before = _books.length;
    _books.removeWhere((b) => ids.contains(b.id));
    await _persist();
    return before - _books.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    await _delay();
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isbnExists(String isbn, {int? excludingId}) async {
    final needle = isbn.trim().toLowerCase();
    return _books.any(
      (b) =>
          !b.isDeleted &&
          b.isbn.toLowerCase() == needle &&
          b.id != excludingId,
    );
  }

  @override
  Future<int> countByPublisher(int publisherId) async {
    return _books
        .where((b) => !b.isDeleted && b.publisherId == publisherId)
        .length;
  }

  @override
  Future<List<int>> authorIdsLinkedToPublisher(int publisherId) async {
    final ids = <int>{};
    for (final b in _books) {
      if (!b.isDeleted && b.publisherId == publisherId) {
        ids.addAll(b.authorIds);
      }
    }
    return ids.toList()..sort();
  }

  @override
  Future<List<int>> genreIdsLinkedToPublisher(int publisherId) async {
    final ids = <int>{};
    for (final b in _books) {
      if (!b.isDeleted && b.publisherId == publisherId) {
        ids.addAll(b.genreIds);
      }
    }
    return ids.toList()..sort();
  }
}
