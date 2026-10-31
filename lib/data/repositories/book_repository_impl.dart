import 'package:sqflite/sqflite.dart';

import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../db/app_database.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  @override
  Future<List<Book>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('books', orderBy: 'added_at DESC');
    return rows.map(Book.fromMap).toList();
  }

  @override
  Future<Book?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('books', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  @override
  Future<void> upsert(Book book) async {
    final db = await _db.database;
    await db.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('annotations', where: 'book_id = ?', whereArgs: [id]);
    await db.delete('reading_sessions', where: 'book_id = ?', whereArgs: [id]);
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateProgress(
    String id,
    double progress,
    String? location,
  ) async {
    final db = await _db.database;
    await db.update(
      'books',
      {
        'progress': progress.clamp(0.0, 1.0),
        'last_location': location,
        'last_read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
