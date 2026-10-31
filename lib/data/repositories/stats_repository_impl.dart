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
    final daySeconds = <DateTime, int>{};

    for (final s in sessions) {
      total += s.durationSeconds;
      perBook[s.bookId] = (perBook[s.bookId] ?? 0) + s.durationSeconds;
      if (s.endedAt.isAfter(startOfDay) ||
          s.endedAt.isAtSameMomentAs(startOfDay)) {
        today += s.durationSeconds;
      }
      final day = DateTime(s.endedAt.year, s.endedAt.month, s.endedAt.day);
      daySeconds[day] = (daySeconds[day] ?? 0) + s.durationSeconds;
    }

    final last7 = <int>[];
    for (var i = 6; i >= 0; i--) {
      final d = startOfDay.subtract(Duration(days: i));
      last7.add(daySeconds[d] ?? 0);
    }

    final currentStreak = _computeStreak(daySeconds, startOfDay);

    final books = await db.query('books', columns: ['id', 'progress']);
    final started = books
        .where((b) => ((b['progress'] as num?) ?? 0) > 0)
        .length;
    final finished = books
        .where((b) => ((b['progress'] as num?) ?? 0) >= 0.98)
        .length;

    return ReadingStatsSummary(
      todaySeconds: today,
      totalSeconds: total,
      booksStarted: started,
      booksFinished: finished,
      perBookSeconds: perBook,
      currentStreakDays: currentStreak,
      last7DaysSeconds: last7,
    );
  }

  /// Streak ends on today if today has reading, else yesterday if yesterday has reading.
  int _computeStreak(Map<DateTime, int> daySeconds, DateTime startOfDay) {
    DateTime cursor;
    final todaySecs = daySeconds[startOfDay] ?? 0;
    final yesterday = startOfDay.subtract(const Duration(days: 1));
    if (todaySecs > 0) {
      cursor = startOfDay;
    } else if ((daySeconds[yesterday] ?? 0) > 0) {
      cursor = yesterday;
    } else {
      return 0;
    }
    var streak = 0;
    while ((daySeconds[cursor] ?? 0) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
