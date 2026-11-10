import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/scroll_behavior.dart';
import 'core/theme.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/catalog_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({
    super.key,
    required this.bookRepository,
    required this.authorRepository,
    required this.genreRepository,
    required this.publisherRepository,
    required this.readerRepository,
  });

  final BookRepository bookRepository;
  final AuthorRepository authorRepository;
  final GenreRepository genreRepository;
  final PublisherRepository publisherRepository;
  final ReaderRepository readerRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>.value(value: bookRepository),
        Provider<AuthorRepository>.value(value: authorRepository),
        Provider<GenreRepository>.value(value: genreRepository),
        Provider<PublisherRepository>.value(value: publisherRepository),
        Provider<ReaderRepository>.value(value: readerRepository),
        ChangeNotifierProvider(
          create: (context) => CatalogNotifier(
            genres: context.read<GenreRepository>(),
            publishers: context.read<PublisherRepository>(),
            authors: context.read<AuthorRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              BookListNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              GenreListNotifier(context.read<GenreRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PublisherListNotifier(context.read<PublisherRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ReaderListNotifier(context.read<ReaderRepository>()),
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
