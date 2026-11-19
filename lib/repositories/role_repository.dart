import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/role.dart';

abstract interface class RoleRepository {
  Future<PageResult<Role>> find(ListQuery query);
  Future<Role?> findById(String id);
  Future<Role> create(Role role);
  Future<Role> update(Role role);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> softDeleteMany(List<String> ids);
  Future<int> hardDeleteMany(List<String> ids);
  Future<int> restoreMany(List<String> ids);
  Future<List<Role>> allActive();
  Future<int> countBuildsUsing(String roleId);
  void invalidateCatalogCache();
}
