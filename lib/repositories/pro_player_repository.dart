import '../models/page_result.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';

abstract interface class ProPlayerRepository {
  Future<PageResult<ProPlayer>> find(ProPlayerQuery query);
  Future<ProPlayer?> findById(String id);
  Future<ProPlayer> create(ProPlayer player);
  Future<ProPlayer> update(ProPlayer player);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<List<ProPlayer>> allActive();
  void invalidateCatalogCache();
}
