import "../models/genre.dart";
import "../models/list_query.dart";
import "../models/page_result.dart";

abstract interface class GenreRepository {
  Future<PageResult<Genre>> find(ListQuery query);
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<List<Genre>> allActive();
  Future<int> countBooksUsing(int genreId);
}