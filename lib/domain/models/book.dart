import 'package:equatable/equatable.dart';

enum BookFormat {
  epub,
  pdf,
  txt,
  mobi,
  azw3,
  azw,
  fb2,
  cbz,
  cbr,
  md,
  docx,
  html,
  htm,
  xhtml,
  mhtml,
  unknown,
}

BookFormat bookFormatFromExtension(String ext) {
  switch (ext.toLowerCase().replaceAll('.', '')) {
    case 'epub':
      return BookFormat.epub;
    case 'pdf':
      return BookFormat.pdf;
    case 'txt':
      return BookFormat.txt;
    case 'mobi':
      return BookFormat.mobi;
    case 'azw3':
      return BookFormat.azw3;
    case 'azw':
      return BookFormat.azw;
    case 'fb2':
      return BookFormat.fb2;
    case 'cbz':
      return BookFormat.cbz;
    case 'cbr':
      return BookFormat.cbr;
    case 'md':
    case 'markdown':
      return BookFormat.md;
    case 'docx':
      return BookFormat.docx;
    case 'html':
      return BookFormat.html;
    case 'htm':
      return BookFormat.htm;
    case 'xhtml':
      return BookFormat.xhtml;
    case 'mhtml':
    case 'mht':
      return BookFormat.mhtml;
    default:
      return BookFormat.unknown;
  }
}

bool bookFormatIsComic(BookFormat f) =>
    f == BookFormat.cbz || f == BookFormat.cbr;

bool bookFormatIsTextLike(BookFormat f) => switch (f) {
      BookFormat.txt ||
      BookFormat.md ||
      BookFormat.html ||
      BookFormat.htm ||
      BookFormat.xhtml ||
      BookFormat.mhtml ||
      BookFormat.fb2 ||
      BookFormat.docx ||
      BookFormat.mobi ||
      BookFormat.azw3 ||
      BookFormat.azw =>
        true,
      _ => false,
    };

class Book extends Equatable {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.filePath,
    this.coverPath,
    this.fileSize = 0,
    this.progress = 0,
    this.lastLocation,
    required this.addedAt,
    this.lastReadAt,
  });

  final String id;
  final String title;
  final String author;
  final BookFormat format;
  final String filePath;
  final String? coverPath;
  final int fileSize;

  /// 0.0 – 1.0 reading progress.
  final double progress;
  final String? lastLocation;
  final DateTime addedAt;
  final DateTime? lastReadAt;

  Book copyWith({
    String? title,
    String? author,
    String? coverPath,
    double? progress,
    String? lastLocation,
    DateTime? lastReadAt,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format,
      filePath: filePath,
      coverPath: coverPath ?? this.coverPath,
      fileSize: fileSize,
      progress: progress ?? this.progress,
      lastLocation: lastLocation ?? this.lastLocation,
      addedAt: addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'format': format.name,
        'file_path': filePath,
        'cover_path': coverPath,
        'file_size': fileSize,
        'progress': progress,
        'last_location': lastLocation,
        'added_at': addedAt.toIso8601String(),
        'last_read_at': lastReadAt?.toIso8601String(),
      };

  factory Book.fromMap(Map<String, Object?> map) {
    return Book(
      id: map['id']! as String,
      title: map['title']! as String,
      author: map['author']! as String,
      format: BookFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => BookFormat.unknown,
      ),
      filePath: map['file_path']! as String,
      coverPath: map['cover_path'] as String?,
      fileSize: (map['file_size'] as int?) ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      lastLocation: map['last_location'] as String?,
      addedAt: DateTime.parse(map['added_at']! as String),
      lastReadAt: map['last_read_at'] != null
          ? DateTime.parse(map['last_read_at']! as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, title, author, format, progress, lastReadAt];
}

enum BookSort { title, author, recent, added }
