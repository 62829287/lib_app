import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/pb.dart';

mixin PbCrudMixin {
  Dio get dio;
  String get collection;

  Future<void> pbSoftDelete(String id) => guard(() async {
    await dio.patch(
      pbRecord(collection, id),
      data: {'deletedAt': DateTime.now().toUtc().toIso8601String()},
    );
  });

  Future<void> pbHardDelete(String id) =>
      guard(() => dio.delete(pbRecord(collection, id)));

  Future<void> pbRestore(String id) => guard(() async {
    await dio.patch(pbRecord(collection, id), data: {'deletedAt': null});
  });

  Future<int> pbSoftDeleteMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await pbSoftDelete(id);
      n++;
    }
    return n;
  }

  Future<int> pbHardDeleteMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await pbHardDelete(id);
      n++;
    }
    return n;
  }

  Future<int> pbRestoreMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await pbRestore(id);
      n++;
    }
    return n;
  }

  Future<T?> pbFindById<T>(
    String id,
    T Function(Map<String, dynamic>) map,
  ) => guardRead(() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        pbRecord(collection, id),
      );
      return map(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.error is NotFoundException) {
        return null;
      }
      rethrow;
    }
  });
}
