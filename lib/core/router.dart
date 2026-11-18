import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_role.dart';
import '../screens/app_user_detail_screen.dart';
import '../screens/app_user_form_screen.dart';
import '../screens/app_user_list_screen.dart';
import '../screens/auth_accounts_screen.dart';
import '../screens/build_detail_screen.dart';
import '../screens/build_form_screen.dart';
import '../screens/build_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/hero_detail_screen.dart';
import '../screens/hero_form_screen.dart';
import '../screens/hero_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/pro_player_detail_screen.dart';
import '../screens/pro_player_form_screen.dart';
import '../screens/pro_player_list_screen.dart';
import '../screens/register_screen.dart';
import '../screens/role_detail_screen.dart';
import '../screens/role_form_screen.dart';
import '../screens/role_list_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/form_exit_scope.dart';

FutureOr<bool> _confirmFormExit(BuildContext context, GoRouterState state) {
  return FormExitScope.allowExit(context);
}

String? _requireEditor(AuthNotifier auth) =>
    auth.canEditCatalog() ? null : '/forbidden';

String? _requirePros(AuthNotifier auth) =>
    auth.canBrowsePros() ? null : '/forbidden';

String? _requireReferenceData(AuthNotifier auth) =>
    auth.canBrowseReferenceData() ? null : '/forbidden';

String? _requireAdmin(AuthNotifier auth) =>
    auth.canManageUsers() ? null : '/forbidden';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';
      return null;
    },
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        name: 'forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
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
                redirect: (c, s) => _requireEditor(auth),
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
                    redirect: (c, s) => _requireEditor(auth),
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
            redirect: (c, s) => _requirePros(auth),
            builder: (context, state) => const ProPlayerListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'pro-new',
                redirect: (c, s) => _requireEditor(auth),
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
                    redirect: (c, s) => _requireEditor(auth),
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
            redirect: (c, s) => _requireReferenceData(auth),
            builder: (context, state) => const RoleListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'role-new',
                redirect: (c, s) => _requireEditor(auth),
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
                    redirect: (c, s) => _requireEditor(auth),
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
            redirect: (c, s) => _requireReferenceData(auth),
            builder: (context, state) => const HeroListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'hero-new',
                redirect: (c, s) => _requireEditor(auth),
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
                    redirect: (c, s) => _requireEditor(auth),
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
            path: '/accounts',
            name: 'accounts',
            redirect: (c, s) => _requireAdmin(auth),
            builder: (context, state) => const AuthAccountsScreen(),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            redirect: (c, s) => _requireAdmin(auth),
            builder: (context, state) => const AppUserListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'user-new',
                redirect: (c, s) => _requireAdmin(auth),
                onExit: _confirmFormExit,
                builder: (context, state) => const AppUserFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'user',
                redirect: (c, s) => _requireAdmin(auth),
                builder: (context, state) => AppUserDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'user-edit',
                    redirect: (c, s) => _requireAdmin(auth),
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

bool routeAllowedFor(AuthRole role, String path) {
  if (path.startsWith('/users') || path.startsWith('/accounts')) {
    return Permissions.canManageUsers(role);
  }
  if (path.startsWith('/pros')) {
    if (path.endsWith('/new') || path.endsWith('/edit')) {
      return Permissions.canEditCatalog(role);
    }
    return Permissions.canBrowsePros(role);
  }
  if (path.startsWith('/heroes') || path.startsWith('/roles')) {
    return Permissions.canBrowseReferenceData(role);
  }
  if (path.endsWith('/new') || path.endsWith('/edit')) {
    return Permissions.canEditCatalog(role);
  }
  if (path == '/' || path.startsWith('/builds')) {
    return Permissions.canBrowseBuilds(role);
  }
  return false;
}
