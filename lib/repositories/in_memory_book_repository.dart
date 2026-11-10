import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;
  final List<Book> _books = seedBooks.map((b) => b.copyWith()).toList();
  int _nextId = seedBooks.length + 1;

  Future<void> _delay() => Future<void>.delayed(latency);

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

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    await _delay();
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async {
    await _delay();
    final withId = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: List<int>.from(book.authorIds),
      genreIds: List<int>.from(book.genreIds),
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
      deletedAt: book.deletedAt,
    );
    _books.add(withId);
    return withId;
  }

  @override
  Future<Book> update(Book book) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book.copyWith();
    return _books[i];
  }

  @override
  Future<void> softDelete(int id) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _delay();
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await _delay();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
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
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    await _delay();
    final before = _books.length;
    _books.removeWhere((b) => ids.contains(b.id));
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
