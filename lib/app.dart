import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/scroll_behavior.dart';
import 'core/theme.dart';
import 'repositories/app_user_repository.dart';
import 'repositories/auth_api.dart';
import 'repositories/build_repository.dart';
import 'repositories/hero_repository.dart';
import 'repositories/pro_player_repository.dart';
import 'repositories/role_repository.dart';
import 'state/app_user_list_notifier.dart';
import 'state/auth_accounts_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/build_list_notifier.dart';
import 'state/catalog_notifier.dart';
import 'state/hero_list_notifier.dart';
import 'state/pro_player_list_notifier.dart';
import 'state/role_list_notifier.dart';
import 'widgets/session_guard.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({
    super.key,
    required this.authNotifier,
    required this.authApi,
    required this.buildRepository,
    required this.proPlayerRepository,
    required this.roleRepository,
    required this.heroRepository,
    required this.appUserRepository,
  });

  final AuthNotifier authNotifier;
  final AuthApi authApi;
  final BuildRepository buildRepository;
  final ProPlayerRepository proPlayerRepository;
  final RoleRepository roleRepository;
  final HeroRepository heroRepository;
  final AppUserRepository appUserRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<AuthApi>.value(value: authApi),
        Provider<BuildRepository>.value(value: buildRepository),
        Provider<ProPlayerRepository>.value(value: proPlayerRepository),
        Provider<RoleRepository>.value(value: roleRepository),
        Provider<HeroRepository>.value(value: heroRepository),
        Provider<AppUserRepository>.value(value: appUserRepository),
        ChangeNotifierProvider(
          create: (context) => CatalogNotifier(
            roles: context.read<RoleRepository>(),
            heroes: context.read<HeroRepository>(),
            proPlayers: context.read<ProPlayerRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BuildListNotifier(context.read<BuildRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProPlayerListNotifier(context.read<ProPlayerRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RoleListNotifier(context.read<RoleRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HeroListNotifier(context.read<HeroRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AppUserListNotifier(context.read<AppUserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthAccountsNotifier(context.read<AuthApi>()),
        ),
      ],
      child: const _LibraryMaterialApp(),
    );
  }
}

class _LibraryMaterialApp extends StatefulWidget {
  const _LibraryMaterialApp();

  @override
  State<_LibraryMaterialApp> createState() => _LibraryMaterialAppState();
}

class _LibraryMaterialAppState extends State<_LibraryMaterialApp> {
  GoRouter? _router;
  AuthNotifier? _boundAuth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthNotifier>();
    if (!identical(_boundAuth, auth)) {
      _boundAuth = auth;
      _router = createRouter(auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const SizedBox.shrink();
    }
    return MaterialApp.router(
      title: 'Dota Builds',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          SessionGuard(child: child ?? const SizedBox.shrink()),
    );
  }
}
