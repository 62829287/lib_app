import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';
import 'build_repository.dart';

class ApiBuildRepository implements BuildRepository {
  ApiBuildRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;

  @override
  Future<PageResult<Build>> find(BuildQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;

    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/builds',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.roleId != null) 'roleId': q.roleId,
          if (q.heroId != null) 'heroId': q.heroId,
          if (q.proPlayerId != null) 'proPlayerId': q.proPlayerId,
          if (q.difficultyFrom != null) 'difficultyFrom': q.difficultyFrom,
          if (q.difficultyTo != null) 'difficultyTo': q.difficultyTo,
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
            .map((e) => Build.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? 1,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Build?> findById(int id) => guardRead(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/builds/$id');
          return Build.fromJson(response.data!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 ||
              e.error is NotFoundException) {
            return null;
          }
          rethrow;
        }
      });

  @override
  Future<Build> create(Build build) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/builds',
          data: {
            'title': build.title,
            'code': build.code,
            'patch': build.patch,
            'difficulty': build.difficulty,
            'heroId': build.heroId,
            'proPlayerIds': build.proPlayerIds,
            'roleIds': build.roleIds,
            'picks': build.picks,
            'wins': build.wins,
          },
        );
        return Build.fromJson(response.data!);
      });

  @override
  Future<Build> update(Build build) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/builds/${build.id}',
          data: {
            'title': build.title,
            'code': build.code,
            'patch': build.patch,
            'difficulty': build.difficulty,
            'heroId': build.heroId,
            'proPlayerIds': build.proPlayerIds,
            'roleIds': build.roleIds,
            'picks': build.picks,
            'wins': build.wins,
          },
        );
        return Build.fromJson(response.data!);
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/builds/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/builds/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/builds/$id/restore'));

  @override
  Future<int> softDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/builds/bulk-delete',
          data: {'ids': ids},
        );
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> hardDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/builds/bulk-delete',
          data: {'ids': ids, 'hard': true},
        );
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> restoreMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/builds/bulk-restore',
          data: {'ids': ids},
        );
        return (response.data?['restored'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<bool> codeExists(String code, {int? excludingId}) =>
      guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/builds/code-exists',
          queryParameters: {
            'code': code,
            if (excludingId != null) 'excludingId': excludingId,
          },
        );
        return response.data?['exists'] == true;
      });

  @override
  Future<int> countByHero(int heroId) => guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/builds/count-by-hero/$heroId',
        );
        return (response.data?['count'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<List<int>> proPlayerIdsLinkedToHero(int heroId) =>
      guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/builds/links-by-hero/$heroId',
        );
        final list = response.data?['proPlayerIds'];
        if (list is! List) return const [];
        return list
            .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
            .whereType<int>()
            .toList();
      });

  @override
  Future<List<int>> roleIdsLinkedToHero(int heroId) => guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/builds/links-by-hero/$heroId',
        );
        final list = response.data?['roleIds'];
        if (list is! List) return const [];
        return list
            .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
            .whereType<int>()
            .toList();
      });
}
