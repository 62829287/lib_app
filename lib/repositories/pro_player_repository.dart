import '../models/page_result.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';

abstract interface class ProPlayerRepository {
  Future<PageResult<ProPlayer>> find(ProPlayerQuery query);
  Future<ProPlayer?> findById(int id);
  Future<ProPlayer> create(ProPlayer player);
  Future<ProPlayer> update(ProPlayer player);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<List<ProPlayer>> allActive();
  void invalidateCatalogCache();
}
