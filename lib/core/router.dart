import 'package:go_router/go_router.dart';

import '../screens/author_detail_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../widgets/app_shell.dart';

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
                path: ':id',
                name: 'book',
                builder: (context, state) => BookDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/authors',
            name: 'authors',
            builder: (context, state) => const AuthorListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'author',
                builder: (context, state) => AuthorDetailScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
