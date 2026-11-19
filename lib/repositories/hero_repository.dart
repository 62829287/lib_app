import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class HeroRepository {
  Future<PageResult<DotaHero>> find(ListQuery query);
  Future<DotaHero?> findById(String id);
  Future<DotaHero> create(DotaHero hero);
  Future<DotaHero> update(DotaHero hero);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<List<DotaHero>> allActive();
  void invalidateCatalogCache();
}
