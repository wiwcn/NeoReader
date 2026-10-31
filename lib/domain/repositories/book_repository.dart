import '../models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getAll();
  Future<Book?> getById(String id);
  Future<void> upsert(Book book);
  Future<void> delete(String id);
  Future<void> updateProgress(String id, double progress, String? location);
}
