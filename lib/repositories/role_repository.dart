import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/role.dart';

abstract interface class RoleRepository {
  Future<PageResult<Role>> find(ListQuery query);
  Future<Role?> findById(int id);
  Future<Role> create(Role role);
  Future<Role> update(Role role);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
  Future<List<Role>> allActive();
  Future<int> countBuildsUsing(int roleId);
  void invalidateCatalogCache();
}
