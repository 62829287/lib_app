import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app.dart';
import 'package:library_app/repositories/in_memory_author_repository.dart';
import 'package:library_app/repositories/in_memory_book_repository.dart';
import 'package:library_app/repositories/in_memory_catalog_repository.dart';

void main() {
  testWidgets('Library app boots and shows home', (tester) async {
    await tester.pumpWidget(
      LibraryApp(
        bookRepository: InMemoryBookRepository(latency: Duration.zero),
        authorRepository: InMemoryAuthorRepository(latency: Duration.zero),
        catalogRepository: InMemoryCatalogRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Библиотека'), findsWidgets);
    expect(find.text('Книги'), findsWidgets);
    expect(find.text('Авторы'), findsWidgets);
  });
}
