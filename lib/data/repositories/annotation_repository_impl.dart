import 'package:sqflite/sqflite.dart';

import '../../domain/models/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';
import '../db/app_database.dart';

class AnnotationRepositoryImpl implements AnnotationRepository {
  AnnotationRepositoryImpl({AppDatabase? db})
    : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  @override
  Future<List<Annotation>> forBook(String bookId) async {
    final db = await _db.database;
    final rows = await db.query(
      'annotations',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Annotation.fromMap).toList();
  }

  @override
  Future<List<Annotation>> all() async {
    final db = await _db.database;
    final rows = await db.query('annotations', orderBy: 'created_at DESC');
    return rows.map(Annotation.fromMap).toList();
  }

  @override
  Future<void> add(Annotation annotation) async {
    final db = await _db.database;
    await db.insert(
      'annotations',
      annotation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('annotations', where: 'id = ?', whereArgs: [id]);
  }
}
