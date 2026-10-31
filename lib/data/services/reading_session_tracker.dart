import 'package:uuid/uuid.dart';

import '../../domain/models/reading_stats.dart';
import '../../domain/repositories/stats_repository.dart';

/// Tracks wall-clock reading time while a reader screen is open.
class ReadingSessionTracker {
  ReadingSessionTracker(this._stats);

  final StatsRepository _stats;
  final _uuid = const Uuid();
  DateTime? _started;
  String? _bookId;

  void start(String bookId) {
    _bookId = bookId;
    _started = DateTime.now();
  }

  Future<void> stop() async {
    final started = _started;
    final bookId = _bookId;
    _started = null;
    _bookId = null;
    if (started == null || bookId == null) return;
    final ended = DateTime.now();
    final seconds = ended.difference(started).inSeconds;
    await _stats.addSession(
      ReadingSession(
        id: _uuid.v4(),
        bookId: bookId,
        startedAt: started,
        endedAt: ended,
        durationSeconds: seconds,
      ),
    );
  }
}
