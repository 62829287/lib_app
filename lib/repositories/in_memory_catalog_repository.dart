import '../models/genre.dart';
import '../models/publisher.dart';
import 'catalog_repository.dart';
import 'seed_data.dart';

class InMemoryCatalogRepository implements CatalogRepository {
  @override
  Future<List<Genre>> genres() async => List<Genre>.from(seedGenres);

  @override
  Future<List<Publisher>> publishers() async =>
      List<Publisher>.from(seedPublishers);

  @override
  Future<List<String>> authorCountries() async {
    final countries = seedAuthors.map((a) => a.country).toSet().toList()
      ..sort();
    return countries;
  }
}
