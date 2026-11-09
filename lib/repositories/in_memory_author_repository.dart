import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  InMemoryAuthorRepository({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;
  final List<Author> _authors = [...seedAuthors];
  int _nextId = seedAuthors.length + 1;

  Future<void> _delay() => Future<void>.delayed(latency);

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await _delay();

    var rows =
        _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.lastName.toLowerCase().contains(needle) ||
                a.country.toLowerCase().contains(needle) ||
                a.firstName.toLowerCase().contains(needle),
          )
          .toList();
    }

    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' =>
          a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    await _delay();
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Author> create(Author author) async {
    await _delay();
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
      deletedAt: author.deletedAt,
    );
    _authors.add(created);
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    await _delay();
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    return _authors[i];
  }

  @override
  Future<void> softDelete(int id) async {
    await _delay();
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _delay();
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await _delay();
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    await _delay();
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    await _delay();
    final before = _authors.length;
    _authors.removeWhere((a) => ids.contains(a.id));
    return before - _authors.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    await _delay();
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    return count;
  }
}
