import '../models/genre.dart';
import '../models/publisher.dart';

abstract interface class CatalogRepository {
  Future<List<Genre>> genres();
  Future<List<Publisher>> publishers();
  Future<List<String>> authorCountries();
}
