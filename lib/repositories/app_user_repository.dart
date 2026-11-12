import '../models/app_user.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class AppUserRepository {
  Future<PageResult<AppUser>> find(ListQuery query);
  Future<AppUser?> findById(int id);
  Future<AppUser> create(AppUser user);
  Future<AppUser> update(AppUser user);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<bool> emailExists(String email, {int? excludingId});
}
