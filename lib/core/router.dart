import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/author_detail_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/genre_detail_screen.dart';
import '../screens/genre_form_screen.dart';
import '../screens/genre_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/publisher_detail_screen.dart';
import '../screens/publisher_form_screen.dart';
import '../screens/publisher_list_screen.dart';
import '../screens/reader_detail_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/reader_list_screen.dart';
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
            path: '/books',
            name: 'books',
            builder: (context, state) => const BookListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'book-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const BookFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'book',
                builder: (context, state) => BookDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'book-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => BookFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/authors',
            name: 'authors',
            builder: (context, state) => const AuthorListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'author-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const AuthorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'author',
                builder: (context, state) => AuthorDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'author-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => AuthorFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/genres',
            name: 'genres',
            builder: (context, state) => const GenreListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'genre-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const GenreFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'genre',
                builder: (context, state) => GenreDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'genre-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => GenreFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/publishers',
            name: 'publishers',
            builder: (context, state) => const PublisherListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'publisher-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const PublisherFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'publisher',
                builder: (context, state) => PublisherDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'publisher-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => PublisherFormScreen(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/readers',
            name: 'readers',
            builder: (context, state) => const ReaderListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'reader-new',
                onExit: _confirmFormExit,
                builder: (context, state) => const ReaderFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'reader',
                builder: (context, state) => ReaderDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'reader-edit',
                    onExit: _confirmFormExit,
                    builder: (context, state) => ReaderFormScreen(
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
