import "../models/list_query.dart";
import "../models/page_result.dart";
import "../models/publisher.dart";

abstract interface class PublisherRepository {
  Future<PageResult<Publisher>> find(ListQuery query);
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<List<Publisher>> allActive();
  Future<List<String>> cities({String? country});
}