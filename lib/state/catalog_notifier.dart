import 'package:flutter/foundation.dart';

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

  LoadStatus get status => _status;
  List<Role> get roles => _roles;
  List<DotaHero> get heroes => _heroes;
  List<String> get countries => _countries;
  String? get error => _error;

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

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
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
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
