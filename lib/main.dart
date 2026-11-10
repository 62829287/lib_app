import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'repositories/json_store.dart';
import 'repositories/persistent_author_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final store = JsonStore(prefs);
  store.ensureVersion();

  final books = PersistentBookRepository(store)..loadFromStorage();
  final authors = PersistentAuthorRepository(store)..loadFromStorage();
  final genres = PersistentGenreRepository(store, books: books)..loadFromStorage();
  final publishers = PersistentPublisherRepository(store)..loadFromStorage();
  final readers = PersistentReaderRepository(store)..loadFromStorage();

  runApp(
    LibraryApp(
      bookRepository: books,
      authorRepository: authors,
      genreRepository: genres,
      publisherRepository: publishers,
      readerRepository: readers,
    ),
  );
}
