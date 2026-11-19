import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';
import 'build_repository.dart';
import 'pb_crud.dart';

class ApiBuildRepository with PbCrudMixin implements BuildRepository {
  ApiBuildRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'builds';

  @override
  Future<PageResult<Build>> find(BuildQuery q) {
    _findToken?.cancel('stale');
    final token = CancelToken();
    _findToken = token;
    return guardRead(() async {
      final parts = <String>[];
      if (!q.includeDeleted) {
        parts.add('(deletedAt = "" || deletedAt = null)');
      }
      final search = q.search.trim();
      if (search.isNotEmpty) {
        final safe = search.replaceAll('"', '');
        parts.add('(title ~ "$safe" || code ~ "$safe")');
      }
      if (q.heroId != null && q.heroId!.isNotEmpty) {
        parts.add('heroId = "${q.heroId}"');
      }
      if (q.roleId != null && q.roleId!.isNotEmpty) {
        parts.add('roleIds.id ?= "${q.roleId}"');
      }
      if (q.proPlayerId != null && q.proPlayerId!.isNotEmpty) {
        parts.add('proPlayerIds.id ?= "${q.proPlayerId}"');
      }
      if (q.difficultyFrom != null) {
        parts.add('difficulty >= ${q.difficultyFrom}');
      }
      if (q.difficultyTo != null) {
        parts.add('difficulty <= ${q.difficultyTo}');
      }
      final filter = parts.isEmpty ? null : parts.join(' && ');
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
        Build.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<Build?> findById(String id) => pbFindById(id, Build.fromJson);

  @override
  Future<Build> create(Build build) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
      data: _body(build),
    );
    return Build.fromJson(response.data!);
  });

  @override
  Future<Build> update(Build build) => guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, build.id),
      data: _body(build),
    );
    return Build.fromJson(response.data!);
  });

  Map<String, dynamic> _body(Build build) => {
    'title': build.title,
    'code': build.code,
    'patch': build.patch,
    'difficulty': build.difficulty,
    'heroId': build.heroId,
    'proPlayerIds': build.proPlayerIds,
    'roleIds': build.roleIds,
    'picks': build.picks,
    'wins': build.wins,
  };

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
  Future<bool> codeExists(String code, {String? excludingId}) =>
      guardRead(() async {
        final safe = code.replaceAll('"', '');
        var filter = 'code = "$safe"';
        if (excludingId != null && excludingId.isNotEmpty) {
          filter += ' && id != "$excludingId"';
        }
        final response = await _dio.get<Map<String, dynamic>>(
          pbRecords(collection),
          queryParameters: {'perPage': 1, 'filter': filter},
        );
        return ((response.data?['totalItems'] as num?)?.toInt() ?? 0) > 0;
      });

  @override
  Future<int> countByHero(String heroId) => guardRead(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      pbRecords(collection),
      queryParameters: {
        'perPage': 1,
        'filter': 'heroId = "$heroId"',
      },
    );
    return (response.data?['totalItems'] as num?)?.toInt() ?? 0;
  });

  @override
  Future<List<String>> proPlayerIdsLinkedToHero(String heroId) =>
      guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          pbRecords(collection),
          queryParameters: {
            'perPage': 200,
            'filter': 'heroId = "$heroId"',
            'fields': 'proPlayerIds',
          },
        );
        final ids = <String>{};
        for (final item in (response.data?['items'] as List? ?? const [])) {
          if (item is Map) {
            ids.addAll(pbIdList(item['proPlayerIds']));
          }
        }
        return ids.toList();
      });

  @override
  Future<List<String>> roleIdsLinkedToHero(String heroId) =>
      guardRead(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          pbRecords(collection),
          queryParameters: {
            'perPage': 200,
            'filter': 'heroId = "$heroId"',
            'fields': 'roleIds',
          },
        );
        final ids = <String>{};
        for (final item in (response.data?['items'] as List? ?? const [])) {
          if (item is Map) {
            ids.addAll(pbIdList(item['roleIds']));
          }
        }
        return ids.toList();
      });
}
