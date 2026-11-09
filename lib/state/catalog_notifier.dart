import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/catalog_repository.dart';
import 'load_status.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier(this._repository);

  final CatalogRepository _repository;

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
        _repository.genres(),
        _repository.publishers(),
        _repository.authorCountries(),
      ]);
      _genres = results[0] as List<Genre>;
      _publishers = results[1] as List<Publisher>;
      _countries = results[2] as List<String>;
      _status = LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
