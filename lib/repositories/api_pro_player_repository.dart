import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/pb.dart';
import '../models/page_result.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';
import 'pb_crud.dart';
import 'pro_player_repository.dart';

class ApiProPlayerRepository with PbCrudMixin implements ProPlayerRepository {
  ApiProPlayerRepository(this._dio);

  final Dio _dio;
  CancelToken? _findToken;
  List<ProPlayer>? _allActiveCache;

  @override
  Dio get dio => _dio;

  @override
  String get collection => 'pro_players';

  @override
  void invalidateCatalogCache() => _allActiveCache = null;

  @override
  Future<PageResult<ProPlayer>> find(ProPlayerQuery q) {
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
        parts.add('(nickname ~ "$safe" || realName ~ "$safe")');
      }
      if (q.country != null && q.country!.isNotEmpty) {
        parts.add('country = "${q.country}"');
      }
      if (q.teamId != null && q.teamId!.isNotEmpty) {
        parts.add('teamId = "${q.teamId}"');
      }
      if (q.teamId != null && q.teamId!.isNotEmpty) {
        parts.add('teamId = "${q.teamId}"');
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
        ProPlayer.fromJson,
        fallbackPage: q.page,
        fallbackSize: q.size,
      );
    });
  }

  @override
  Future<ProPlayer?> findById(String id) =>
      pbFindById(id, ProPlayer.fromJson);

  @override
  Future<ProPlayer> create(ProPlayer player) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      pbRecords(collection),
      data: {
        'nickname': player.nickname,
        'realName': player.realName,
        'teamId': player.teamId.isEmpty ? null : player.teamId,
        'rating': player.rating,
        'country': player.country,
      },
    );
    invalidateCatalogCache();
    return ProPlayer.fromJson(response.data!);
  });

  @override
  Future<ProPlayer> update(ProPlayer player) => guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      pbRecord(collection, player.id),
      data: {
        'nickname': player.nickname,
        'realName': player.realName,
        'teamId': player.teamId.isEmpty ? null : player.teamId,
        'rating': player.rating,
        'country': player.country,
      },
    );
    invalidateCatalogCache();
    return ProPlayer.fromJson(response.data!);
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
  Future<List<ProPlayer>> allActive() async {
    final cached = _allActiveCache;
    if (cached != null) return cached;
    return guardRead(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        pbRecords(collection),
        queryParameters: {
          'perPage': 500,
          'filter': '(deletedAt = "" || deletedAt = null)',
          'sort': 'nickname',
        },
      );
      final list = (response.data?['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ProPlayer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allActiveCache = list;
      return list;
    });
  }
}
