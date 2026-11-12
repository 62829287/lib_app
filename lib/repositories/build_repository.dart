import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';

abstract interface class BuildRepository {
  Future<PageResult<Build>> find(BuildQuery query);
  Future<Build?> findById(int id);
  Future<Build> create(Build build);
  Future<Build> update(Build build);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<bool> codeExists(String code, {int? excludingId});
  Future<int> countByHero(int heroId);
  Future<List<int>> proPlayerIdsLinkedToHero(int heroId);
  Future<List<int>> roleIdsLinkedToHero(int heroId);
}
