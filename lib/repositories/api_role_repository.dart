import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import 'role_repository.dart';

class ApiRoleRepository implements RoleRepository {
  ApiRoleRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<Role>? _allActiveCache;

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<Role>> find(ListQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;

    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/roles',
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
            .map((e) => Role.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? 1,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<Role?> findById(int id) => guardRead(() async {
        try {
          final response = await _dio.get<Map<String, dynamic>>('/roles/$id');
          return Role.fromJson(response.data!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 ||
              e.error is NotFoundException) {
            return null;
          }
          rethrow;
        }
      });

  @override
  Future<Role> create(Role role) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/roles',
          data: {'name': role.name, 'description': role.description},
        );
        invalidateCatalogCache();
        return Role.fromJson(response.data!);
      });

  @override
  Future<Role> update(Role role) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/roles/${role.id}',
          data: {'name': role.name, 'description': role.description},
        );
        invalidateCatalogCache();
        return Role.fromJson(response.data!);
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/roles/$id');
        invalidateCatalogCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete('/roles/$id', queryParameters: {'hard': true});
        invalidateCatalogCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/roles/$id/restore');
        invalidateCatalogCache();
      });

  @override
  Future<int> softDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/roles/bulk-delete',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> hardDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/roles/bulk-delete',
          data: {'ids': ids, 'hard': true},
        );
        invalidateCatalogCache();
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> restoreMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/roles/bulk-restore',
          data: {'ids': ids},
        );
        invalidateCatalogCache();
        return (response.data?['restored'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<List<Role>> allActive() async {
    final cached = _allActiveCache;
    if (cached != null) return cached;
    return guardRead(() async {
      final response = await _dio.get<List<dynamic>>('/roles/all');
      final list = (response.data ?? const [])
          .whereType<Map>()
          .map((e) => Role.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }

  @override
  Future<int> countBuildsUsing(int roleId) => guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/roles/$roleId/builds-count',
        );
        return (response.data?['count'] as num?)?.toInt() ?? 0;
      });
}
