import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'repositories/api_app_user_repository.dart';
import 'repositories/api_build_repository.dart';
import 'repositories/api_hero_repository.dart';
import 'repositories/api_pro_player_repository.dart';
import 'repositories/api_role_repository.dart';
import 'repositories/auth_api.dart';
import 'state/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  late final AuthNotifier authNotifier;
  final dio = buildDio(
    tokenProvider: () => authNotifier.accessToken,
    refreshTokens: () async {
      try {
        await authNotifier.refreshTokens();
        return authNotifier.accessToken != null;
      } catch (_) {
        return false;
      }
    },
    onAuthLost: () => authNotifier.logout(),
  );

  final authApi = AuthApi(dio);
  authNotifier = AuthNotifier(prefs, authApi);
  await authNotifier.restore();

  runApp(
    LibraryApp(
      authNotifier: authNotifier,
      authApi: authApi,
      buildRepository: ApiBuildRepository(dio),
      proPlayerRepository: ApiProPlayerRepository(dio),
      roleRepository: ApiRoleRepository(dio),
      heroRepository: ApiHeroRepository(dio),
      appUserRepository: ApiAppUserRepository(dio),
    ),
  );
}
