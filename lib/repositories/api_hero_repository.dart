import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'hero_repository.dart';
import 'pb_crud.dart';

class ApiHeroRepository with PbCrudMixin implements HeroRepository {
  ApiHeroRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<DotaHero>? _allActiveCache;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'heroes';

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<DotaHero>> find(ListQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;
    return guardRead(() async {
      final filter = pbDeletedFilter(
        includeDeleted: q.includeDeleted,
        searchField: 'name',
        search: q.search,
      );
      final response = await _dio.get<Map<String, dynamic>>(
        pbRecords(collection),
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': pbSort(q.sortField, q.sortAscending),
          if (filter != null) 'filter': filter,
        },
        cancelToken: token,
      );
      return pbPageResult(
        response.data!,
        DotaHero.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<DotaHero?> findById(String id) => pbFindById(id, DotaHero.fromJson);

  @override
  Future<DotaHero> create(DotaHero hero) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
      data: {
        'name': hero.name,
        'primaryAttribute': hero.primaryAttribute,
        'attackType': hero.attackType,
      },
    );
    invalidateCatalogCache();
    return DotaHero.fromJson(response.data!);
  });

  @override
  Future<DotaHero> update(DotaHero hero) => guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, hero.id),
      data: {
        'name': hero.name,
        'primaryAttribute': hero.primaryAttribute,
        'attackType': hero.attackType,
      },
    );
    invalidateCatalogCache();
    return DotaHero.fromJson(response.data!);
  });

  @override
  Future<void> softDelete(String id) async {
    await pbSoftDelete(id);
    invalidateCatalogCache();
  }

  @override
  Future<void> hardDelete(String id) async {
    await pbHardDelete(id);
    invalidateCatalogCache();
  }

  @override
  Future<void> restore(String id) async {
    await pbRestore(id);
    invalidateCatalogCache();
  }

  @override
  Future<int> softDeleteMany(List<String> ids) async {
    final n = await pbSoftDeleteMany(ids);
    invalidateCatalogCache();
    return n;
  }

  @override
  Future<int> hardDeleteMany(List<String> ids) async {
    final n = await pbHardDeleteMany(ids);
    invalidateCatalogCache();
    return n;
  }

  @override
  Future<int> restoreMany(List<String> ids) async {
    final n = await pbRestoreMany(ids);
    invalidateCatalogCache();
    return n;
  }

  @override
  Future<List<DotaHero>> allActive() async {
    final cached = _allActiveCache;
    if (cached != null) return cached;
    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        pbRecords(collection),
        queryParameters: {
          'perPage': 500,
          'filter': '(deletedAt = "" || deletedAt = null)',
          'sort': 'name',
        },
      );
      final list = (response.data?['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => DotaHero.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }
}
