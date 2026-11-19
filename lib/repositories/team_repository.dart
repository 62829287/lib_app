import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/team.dart';

abstract interface class TeamRepository {
  Future<PageResult<Team>> find(ListQuery query);
  Future<Team?> findById(String id);
  Future<Team> create(Team team);
  Future<Team> update(Team team);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<List<Team>> allActive();
  Future<int> countProsUsing(String teamId);
  void invalidateCatalogCache();
}
