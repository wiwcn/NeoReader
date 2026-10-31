import 'package:equatable/equatable.dart';

enum AnnotationType { bookmark, highlight, note }

class Annotation extends Equatable {
  const Annotation({
    required this.id,
    required this.bookId,
    required this.type,
    required this.createdAt,
    this.location,
    this.chapter,
    this.selectedText,
    this.note,
    this.colorHex,
    this.progress,
  });

  final String id;
  final String bookId;
  final AnnotationType type;
  final DateTime createdAt;
  final String? location;
  final String? chapter;
  final String? selectedText;
  final String? note;
  final String? colorHex;
  final double? progress;

  Map<String, Object?> toMap() => {
    'id': id,
    'book_id': bookId,
    'type': type.name,
    'created_at': createdAt.toIso8601String(),
    'location': location,
    'chapter': chapter,
    'selected_text': selectedText,
    'note': note,
    'color_hex': colorHex,
    'progress': progress,
  };

  factory Annotation.fromMap(Map<String, Object?> map) {
    return Annotation(
      id: map['id']! as String,
      bookId: map['book_id']! as String,
      type: AnnotationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnnotationType.note,
      ),
      createdAt: DateTime.parse(map['created_at']! as String),
      location: map['location'] as String?,
      chapter: map['chapter'] as String?,
      selectedText: map['selected_text'] as String?,
      note: map['note'] as String?,
      colorHex: map['color_hex'] as String?,
      progress: (map['progress'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, bookId, type, createdAt];
}
