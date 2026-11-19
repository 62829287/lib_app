import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';

abstract interface class BuildRepository {
  Future<PageResult<Build>> find(BuildQuery query);
  Future<Build?> findById(String id);
  Future<Build> create(Build build);
  Future<Build> update(Build build);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<bool> codeExists(String code, {String? excludingId});
  Future<int> countByHero(String heroId);
  Future<List<String>> proPlayerIdsLinkedToHero(String heroId);
  Future<List<String>> roleIdsLinkedToHero(String heroId);
}
