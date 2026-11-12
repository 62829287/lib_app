import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/app_user_detail_screen.dart';
import '../screens/app_user_form_screen.dart';
import '../screens/app_user_list_screen.dart';
import '../screens/build_detail_screen.dart';
import '../screens/build_form_screen.dart';
import '../screens/build_list_screen.dart';
import '../screens/hero_detail_screen.dart';
import '../screens/hero_form_screen.dart';
import '../screens/hero_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/pro_player_detail_screen.dart';
import '../screens/pro_player_form_screen.dart';
import '../screens/pro_player_list_screen.dart';
import '../screens/role_detail_screen.dart';
import '../screens/role_form_screen.dart';
import '../screens/role_list_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/form_exit_scope.dart';

FutureOr<bool> _confirmFormExit(BuildContext context, GoRouterState state) {
  return FormExitScope.allowExit(context);
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/builds',
            name: 'builds',
            builder: (context, state) => const BuildListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'build-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const BuildFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'build',
                builder: (context, state) => BuildDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'build-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => BuildFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/pros',
            name: 'pros',
            builder: (context, state) => const ProPlayerListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pro-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const ProPlayerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'pro',
                builder: (context, state) => ProPlayerDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'pro-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => ProPlayerFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/roles',
            name: 'roles',
            builder: (context, state) => const RoleListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'role-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const RoleFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'role',
                builder: (context, state) => RoleDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'role-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => RoleFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/heroes',
            name: 'heroes',
            builder: (context, state) => const HeroListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'hero-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const HeroFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'hero',
                builder: (context, state) => HeroDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'hero-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => HeroFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            builder: (context, state) => const AppUserListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'user-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const AppUserFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'user',
                builder: (context, state) => AppUserDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'user-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => AppUserFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
