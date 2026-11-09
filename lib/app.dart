import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/scroll_behavior.dart';
import 'core/theme.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/in_memory_catalog_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/catalog_notifier.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({
    super.key,
    this.bookRepository,
    this.authorRepository,
    this.catalogRepository,
  });

  final BookRepository? bookRepository;
  final AuthorRepository? authorRepository;
  final CatalogRepository? catalogRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>(
          create: (_) => bookRepository ?? InMemoryBookRepository(),
        ),
        Provider<AuthorRepository>(
          create: (_) => authorRepository ?? InMemoryAuthorRepository(),
        ),
        Provider<CatalogRepository>(
          create: (_) => catalogRepository ?? InMemoryCatalogRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CatalogNotifier(context.read<CatalogRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BookListNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>()),
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
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
