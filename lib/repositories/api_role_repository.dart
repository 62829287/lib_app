import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import 'pb_crud.dart';
import 'role_repository.dart';

class ApiRoleRepository with PbCrudMixin implements RoleRepository {
  ApiRoleRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<Role>? _allActiveCache;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'roles';

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<Role>> find(ListQuery q) {
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
        Role.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<Role?> findById(String id) => pbFindById(id, Role.fromJson);

  @override
  Future<Role> create(Role role) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
      data: {'name': role.name, 'description': role.description},
    );
    invalidateCatalogCache();
    return Role.fromJson(response.data!);
  });

  @override
  Future<Role> update(Role role) => guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, role.id),
      data: {'name': role.name, 'description': role.description},
    );
    invalidateCatalogCache();
    return Role.fromJson(response.data!);
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
  Future<List<Role>> allActive() async {
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
          .map((e) => Role.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }

  @override
  Future<int> countBuildsUsing(String roleId) => guardRead(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      pbRecords('builds'),
      queryParameters: {
        'perPage': 1,
        'filter': 'roleIds.id ?= "$roleId"',
      },
    );
    return (response.data?['totalItems'] as num?)?.toInt() ?? 0;
  });
}
