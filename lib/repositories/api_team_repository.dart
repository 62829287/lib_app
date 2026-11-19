import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import 'pb_crud.dart';
import 'team_repository.dart';

class ApiTeamRepository with PbCrudMixin implements TeamRepository {
  ApiTeamRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<Team>? _allActiveCache;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'teams';

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<Team>> find(ListQuery q) {
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
        Team.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<Team?> findById(String id) => pbFindById(id, Team.fromJson);

  @override
  Future<Team> create(Team team) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
      data: {
        'name': team.name,
        'tag': team.tag,
        'region': team.region,
        'description': team.description,
      },
    );
    invalidateCatalogCache();
    return Team.fromJson(response.data!);
  });

  @override
  Future<Team> update(Team team) => guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, team.id),
      data: {
        'name': team.name,
        'tag': team.tag,
        'region': team.region,
        'description': team.description,
      },
    );
    invalidateCatalogCache();
    return Team.fromJson(response.data!);
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
  Future<List<Team>> allActive() async {
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
          .map((e) => Team.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }

  @override
  Future<int> countProsUsing(String teamId) => guardRead(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      pbRecords('pro_players'),
      queryParameters: {
        'perPage': 1,
        'filter': 'teamId = "$teamId"',
      },
    );
    return (response.data?['totalItems'] as num?)?.toInt() ?? 0;
  });
}
