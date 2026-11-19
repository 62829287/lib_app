import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/app_user.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'app_user_repository.dart';
import 'pb_crud.dart';

class ApiAppUserRepository with PbCrudMixin implements AppUserRepository {
  ApiAppUserRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'app_users';

  @override
  Future<PageResult<AppUser>> find(ListQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;
    return guardRead(() async {
      final filter = pbDeletedFilter(
        includeDeleted: q.includeDeleted,
        searchField: 'nickname',
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
        AppUser.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<AppUser?> findById(String id) => pbFindById(id, AppUser.fromJson);

  @override
  Future<AppUser> create(AppUser user) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
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
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, user.id),
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
  Future<void> softDelete(String id) => pbSoftDelete(id);

  @override
  Future<void> hardDelete(String id) => pbHardDelete(id);

  @override
  Future<void> restore(String id) => pbRestore(id);

  @override
  Future<int> softDeleteMany(List<String> ids) => pbSoftDeleteMany(ids);

  @override
  Future<int> hardDeleteMany(List<String> ids) => pbHardDeleteMany(ids);

  @override
  Future<int> restoreMany(List<String> ids) => pbRestoreMany(ids);

  @override
  Future<bool> emailExists(String email, {String? excludingId}) =>
      guardRead(() async {
        final safe = email.replaceAll('"', '');
        var filter = 'email = "$safe"';
        if (excludingId != null && excludingId.isNotEmpty) {
          filter += ' && id != "$excludingId"';
        }
        final response = await _dio.get<Map<String, dynamic>>(
          pbRecords(collection),
          queryParameters: {'perPage': 1, 'filter': filter},
        );
        return ((response.data?['totalItems'] as num?)?.toInt() ?? 0) > 0;
      });
}
