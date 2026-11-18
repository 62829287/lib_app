import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/auth_user.dart';
import '../repositories/auth_api.dart';
import 'load_status.dart';

class AuthAccountsNotifier extends ChangeNotifier {
  AuthAccountsNotifier(this._api);

  final AuthApi _api;

  LoadStatus _status = LoadStatus.idle;
  List<AuthUser> _items = const [];
  String? _error;
  String _search = '';

  LoadStatus get status => _status;
  List<AuthUser> get items => _items;
  String? get error => _error;
  String get search => _search;

  Future<void> load({String? search}) async {
    if (search != null) _search = search;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.listAccounts(search: _search);
      _status = LoadStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<AuthUser> updateRole(int id, String role) async {
    final updated = await _api.updateAccountRole(id, role);
    _items = [
      for (final u in _items)
        if (u.id == id) updated else u,
    ];
    notifyListeners();
    return updated;
  }
}
