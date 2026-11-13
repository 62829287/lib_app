import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'hero_repository.dart';

class ApiHeroRepository implements HeroRepository {
  ApiHeroRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<DotaHero>? _allActiveCache;

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<DotaHero>> find(ListQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;

    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/heroes',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
          ...q.filters,
        },
        cancelToken: token,
      );
      final data = response.data!;
      return PageResult(
        items: (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => DotaHero.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? 1,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<DotaHero?> findById(int id) => guardRead(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/heroes/$id');
          return DotaHero.fromJson(response.data!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 ||
              e.error is NotFoundException) {
            return null;
          }
          rethrow;
        }
      });

  @override
  Future<DotaHero> create(DotaHero hero) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/heroes',
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
        final response = await _dio.put<Map<String, dynamic>>(
          '/heroes/${hero.id}',
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
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/heroes/$id');
        invalidateCatalogCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete('/heroes/$id', queryParameters: {'hard': true});
        invalidateCatalogCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/heroes/$id/restore');
        invalidateCatalogCache();
      });

  @override
  Future<int> softDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/heroes/bulk-delete',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> hardDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/heroes/bulk-delete',
          data: {'ids': ids, 'hard': true},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> restoreMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/heroes/bulk-restore',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['restored'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<List<DotaHero>> allActive() async {
    final cached = _allActiveCache;
    if (cached != null) return cached;
    return guardRead(() async {
      final response = await _dio.get<List<dynamic>>('/heroes/all');
      final list = (response.data ?? const [])
          .whereType<Map>()
          .map((e) => DotaHero.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }
}
