import '../models/app_user.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class AppUserRepository {
  Future<PageResult<AppUser>> find(ListQuery query);
  Future<AppUser?> findById(String id);
  Future<AppUser> create(AppUser user);
  Future<AppUser> update(AppUser user);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<bool> emailExists(String email, {String? excludingId});
}
