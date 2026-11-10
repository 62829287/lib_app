import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import 'load_status.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier({
    required GenreRepository genres,
    required PublisherRepository publishers,
    required AuthorRepository authors,
  })  : _genresRepo = genres,
        _publishersRepo = publishers,
        _authorsRepo = authors;

  final GenreRepository _genresRepo;
  final PublisherRepository _publishersRepo;
  final AuthorRepository _authorsRepo;

  LoadStatus _status = LoadStatus.idle;
  List<Genre> _genres = const [];
  List<Publisher> _publishers = const [];
  List<String> _countries = const [];
  String? _error;

  LoadStatus get status => _status;
  List<Genre> get genres => _genres;
  List<Publisher> get publishers => _publishers;
  List<String> get countries => _countries;
  String? get error => _error;

  String genreName(int id) {
    for (final g in _genres) {
      if (g.id == id) return g.name;
    }
    return '#$id';
  }

  String publisherName(int id) {
    for (final p in _publishers) {
      if (p.id == id) return p.name;
    }
    return '#$id';
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _genresRepo.allActive(),
        _publishersRepo.allActive(),
        _authorsRepo.allActive(),
      ]);
      _genres = results[0] as List<Genre>;
      _publishers = results[1] as List<Publisher>;
      final authors = results[2] as List;
      _countries = authors
          .map((a) => a.country as String)
          .toSet()
          .toList()
        ..sort();
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
