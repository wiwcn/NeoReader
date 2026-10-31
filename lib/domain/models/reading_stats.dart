import 'package:equatable/equatable.dart';

class ReadingSession extends Equatable {
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
  });

  final String id;
  final String bookId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;

  Map<String, Object?> toMap() => {
        'id': id,
        'book_id': bookId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
      };

  factory ReadingSession.fromMap(Map<String, Object?> map) => ReadingSession(
        id: map['id']! as String,
        bookId: map['book_id']! as String,
        startedAt: DateTime.parse(map['started_at']! as String),
        endedAt: DateTime.parse(map['ended_at']! as String),
        durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [id, bookId, startedAt, endedAt, durationSeconds];
}

class ReadingStatsSummary extends Equatable {
  const ReadingStatsSummary({
    required this.todaySeconds,
    required this.totalSeconds,
    required this.booksStarted,
    required this.booksFinished,
    required this.perBookSeconds,
  });

  final int todaySeconds;
  final int totalSeconds;
  final int booksStarted;
  final int booksFinished;
  final Map<String, int> perBookSeconds;

  @override
  List<Object?> get props =>
      [todaySeconds, totalSeconds, booksStarted, booksFinished, perBookSeconds];
}
