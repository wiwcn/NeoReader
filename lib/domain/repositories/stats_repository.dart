import '../models/reading_stats.dart';

abstract class StatsRepository {
  Future<void> addSession(ReadingSession session);
  Future<ReadingStatsSummary> summary();
  Future<List<ReadingSession>> recent({int limit = 50});
}
