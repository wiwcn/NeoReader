import 'package:sqflite/sqflite.dart';

import '../../domain/models/reading_stats.dart';
import '../../domain/repositories/stats_repository.dart';
import '../db/app_database.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  @override
  Future<void> addSession(ReadingSession session) async {
    if (session.durationSeconds < 1) return;
    final db = await _db.database;
    await db.insert(
      'reading_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ReadingSession>> recent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_sessions',
      orderBy: 'ended_at DESC',
      limit: limit,
    );
    return rows.map(ReadingSession.fromMap).toList();
  }

  @override
  Future<ReadingStatsSummary> summary() async {
    final db = await _db.database;
    final rows = await db.query('reading_sessions');
    final sessions = rows.map(ReadingSession.fromMap).toList();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    var today = 0;
    var total = 0;
    final perBook = <String, int>{};
    for (final s in sessions) {
      total += s.durationSeconds;
      perBook[s.bookId] = (perBook[s.bookId] ?? 0) + s.durationSeconds;
      if (s.endedAt.isAfter(startOfDay)) {
        today += s.durationSeconds;
      }
    }

    final books = await db.query('books', columns: ['id', 'progress']);
    final started = books.where((b) => ((b['progress'] as num?) ?? 0) > 0).length;
    final finished =
        books.where((b) => ((b['progress'] as num?) ?? 0) >= 0.98).length;

    return ReadingStatsSummary(
      todaySeconds: today,
      totalSeconds: total,
      booksStarted: started,
      booksFinished: finished,
      perBookSeconds: perBook,
    );
  }
}
