import "../models/list_query.dart";
import "../models/page_result.dart";
import "../models/reader.dart";

abstract interface class ReaderRepository {
  Future<PageResult<Reader>> find(ListQuery query);
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<bool> emailExists(String email, {int? excludingId});
}