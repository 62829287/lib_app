import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';
import 'pro_player_repository.dart';

class ApiProPlayerRepository implements ProPlayerRepository {
  ApiProPlayerRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<ProPlayer>? _allActiveCache;

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<ProPlayer>> find(ProPlayerQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;

    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/pro-players',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.country != null && q.country!.isNotEmpty)
            'country': q.country,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        },
        cancelToken: token,
      );
      final data = response.data!;
      return PageResult(
        items: (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ProPlayer.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? 1,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<ProPlayer?> findById(int id) => guardRead(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/pro-players/$id');
          return ProPlayer.fromJson(response.data!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 ||
              e.error is NotFoundException) {
            return null;
          }
          rethrow;
        }
      });

  @override
  Future<ProPlayer> create(ProPlayer player) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/pro-players',
          data: {
            'nickname': player.nickname,
            'realName': player.realName,
            'team': player.team,
            'rating': player.rating,
            'country': player.country,
          },
        );
        invalidateCatalogCache();
        return ProPlayer.fromJson(response.data!);
      });

  @override
  Future<ProPlayer> update(ProPlayer player) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/pro-players/${player.id}',
          data: {
            'nickname': player.nickname,
            'realName': player.realName,
            'team': player.team,
            'rating': player.rating,
            'country': player.country,
          },
        );
        invalidateCatalogCache();
        return ProPlayer.fromJson(response.data!);
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/pro-players/$id');
        invalidateCatalogCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio
            .delete('/pro-players/$id', queryParameters: {'hard': true});
        invalidateCatalogCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/pro-players/$id/restore');
        invalidateCatalogCache();
      });

  @override
  Future<int> softDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/pro-players/bulk-delete',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> hardDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/pro-players/bulk-delete',
          data: {'ids': ids, 'hard': true},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> restoreMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/pro-players/bulk-restore',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['restored'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<List<ProPlayer>> allActive() async {
    final cached = _allActiveCache;
    if (cached != null) return cached;
    return guardRead(() async {
      final response = await _dio.get<List<dynamic>>('/pro-players/all');
      final list = (response.data ?? const [])
          .whereType<Map>()
          .map((e) => ProPlayer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }
}
