import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/dota_hero.dart';
import '../models/pro_player.dart';
import '../models/role.dart';
import '../repositories/hero_repository.dart';
import '../repositories/pro_player_repository.dart';
import '../repositories/role_repository.dart';
import 'load_status.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier({
    required RoleRepository roles,
    required HeroRepository heroes,
    required ProPlayerRepository proPlayers,
  })  : _rolesRepo = roles,
        _heroesRepo = heroes,
        _proPlayersRepo = proPlayers;

  final RoleRepository _rolesRepo;
  final HeroRepository _heroesRepo;
  final ProPlayerRepository _proPlayersRepo;

  LoadStatus _status = LoadStatus.idle;
  List<Role> _roles = const [];
  List<DotaHero> _heroes = const [];
  List<String> _countries = const [];
  String? _error;
  bool _recoveryAttempted = false;
  int _autoRetries = 0;

  LoadStatus get status => _status;
  List<Role> get roles => _roles;
  List<DotaHero> get heroes => _heroes;
  List<String> get countries => _countries;
  String? get error => _error;
  bool get hasData => _roles.isNotEmpty || _heroes.isNotEmpty;

  String roleName(int id) {
    for (final r in _roles) {
      if (r.id == id) return r.name;
    }
    return '#$id';
  }

  String heroName(int id) {
    for (final h in _heroes) {
      if (h.id == id) return h.name;
    }
    return '#$id';
  }

  void recoverIfNeeded() {
    if (hasData && _status == LoadStatus.success) return;
    if (_status == LoadStatus.loading) return;
    if (_recoveryAttempted) return;
    _recoveryAttempted = true;
    load();
  }

  Future<void> load() async {
    if (_status == LoadStatus.loading) return;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    _rolesRepo.invalidateCatalogCache();
    _heroesRepo.invalidateCatalogCache();
    _proPlayersRepo.invalidateCatalogCache();

    try {
      final results = await Future.wait([
        _rolesRepo.allActive(),
        _heroesRepo.allActive(),
        _proPlayersRepo.allActive(),
      ]);
      _roles = results[0] as List<Role>;
      _heroes = results[1] as List<DotaHero>;
      final players = results[2] as List<ProPlayer>;
      _countries = players.map((p) => p.country).toSet().toList()..sort();
      _status = LoadStatus.success;
      _recoveryAttempted = false;
      _autoRetries = 0;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
      _scheduleAutoRetry();
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
      _scheduleAutoRetry();
    }
    notifyListeners();
  }

  void _scheduleAutoRetry() {
    if (_autoRetries >= 3) return;
    _autoRetries++;
    final delay = Duration(seconds: _autoRetries * 2);
    Future<void>.delayed(delay, () {
      if (_status == LoadStatus.error) {
        _recoveryAttempted = false;
        load();
      }
    });
  }
}
