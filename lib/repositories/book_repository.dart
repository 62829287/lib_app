import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';

abstract interface class BookRepository {
  Future<PageResult<Book>> find(BookQuery query);
  Future<Book?> findById(int id);
  Future<Book> create(Book book);
  Future<Book> update(Book book);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> restoreMany(List<int> ids);
}
