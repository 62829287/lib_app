import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class HeroRepository {
  Future<PageResult<DotaHero>> find(ListQuery query);
  Future<DotaHero?> findById(int id);
  Future<DotaHero> create(DotaHero hero);
  Future<DotaHero> update(DotaHero hero);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<List<DotaHero>> allActive();
}
