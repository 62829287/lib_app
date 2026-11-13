import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'repositories/api_app_user_repository.dart';
import 'repositories/api_build_repository.dart';
import 'repositories/api_hero_repository.dart';
import 'repositories/api_pro_player_repository.dart';
import 'repositories/api_role_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final dio = buildDio();

  runApp(
    LibraryApp(
      buildRepository: ApiBuildRepository(dio),
      proPlayerRepository: ApiProPlayerRepository(dio),
      roleRepository: ApiRoleRepository(dio),
      heroRepository: ApiHeroRepository(dio),
      appUserRepository: ApiAppUserRepository(dio),
    ),
  );
}
