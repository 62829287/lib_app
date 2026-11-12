import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'repositories/json_store.dart';
import 'repositories/persistent_app_user_repository.dart';
import 'repositories/persistent_build_repository.dart';
import 'repositories/persistent_hero_repository.dart';
import 'repositories/persistent_pro_player_repository.dart';
import 'repositories/persistent_role_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final store = JsonStore(prefs);
  store.ensureVersion();

  final builds = PersistentBuildRepository(store)..loadFromStorage();
  final proPlayers = PersistentProPlayerRepository(store)..loadFromStorage();
  final roles = PersistentRoleRepository(store, builds: builds)..loadFromStorage();
  final heroes = PersistentHeroRepository(store)..loadFromStorage();
  final users = PersistentAppUserRepository(store)..loadFromStorage();

  runApp(
    LibraryApp(
      buildRepository: builds,
      proPlayerRepository: proPlayers,
      roleRepository: roles,
      heroRepository: heroes,
      appUserRepository: users,
    ),
  );
}
