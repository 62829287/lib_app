import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'app_user_repository.dart';

class ApiAppUserRepository implements AppUserRepository {
  ApiAppUserRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;

  @override
  Future<PageResult<AppUser>> find(ListQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;

    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
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
            .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: (data['page'] as num?)?.toInt() ?? 1,
        size: (data['size'] as num?)?.toInt() ?? q.size,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<AppUser?> findById(int id) => guardRead(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/users/$id');
          return AppUser.fromJson(response.data!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 ||
              e.error is NotFoundException) {
            return null;
          }
          rethrow;
        }
      });

  @override
  Future<AppUser> create(AppUser user) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/users',
          data: {
            'nickname': user.nickname,
            'email': user.email,
            'region': user.region,
            'steam': user.steam.toJson(),
          },
        );
        return AppUser.fromJson(response.data!);
      });

  @override
  Future<AppUser> update(AppUser user) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/users/${user.id}',
          data: {
            'nickname': user.nickname,
            'email': user.email,
            'region': user.region,
            'steam': user.steam.toJson(),
          },
        );
        return AppUser.fromJson(response.data!);
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/users/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/users/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/users/$id/restore'));

  @override
  Future<int> softDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/users/bulk-delete',
          data: {'ids': ids},
        );
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> hardDeleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/users/bulk-delete',
          data: {'ids': ids, 'hard': true},
        );
        return (response.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<int> restoreMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/users/bulk-restore',
          data: {'ids': ids},
        );
        return (response.data?['restored'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<bool> emailExists(String email, {int? excludingId}) =>
      guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/users/email-exists',
          queryParameters: {
            'email': email,
            if (excludingId != null) 'excludingId': excludingId,
          },
        );
        return response.data?['exists'] == true;
      });
}
