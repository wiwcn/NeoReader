import 'package:equatable/equatable.dart';

class Track extends Equatable {
  const Track({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    this.trackNumber = 0,
    this.discNumber = 0,
    this.durationMs = 0,
    this.year = 0,
    this.genre = '',
    this.coverPath,
    this.fileSize = 0,
    this.mtimeMs = 0,
    this.addedAt,
    this.isFavorite = false,
  });

  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final int trackNumber;
  final int discNumber;
  final int durationMs;
  final int year;
  final String genre;
  final String? coverPath;
  final int fileSize;
  final int mtimeMs;
  final DateTime? addedAt;
  final bool isFavorite;

  Duration get duration => Duration(milliseconds: durationMs);

  String get displayArtist =>
      artist.trim().isEmpty ? 'Unknown artist' : artist.trim();

  String get displayAlbum =>
      album.trim().isEmpty ? 'Unknown album' : album.trim();

  Track copyWith({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    int? trackNumber,
    int? discNumber,
    int? durationMs,
    int? year,
    String? genre,
    String? coverPath,
    bool clearCover = false,
    int? fileSize,
    int? mtimeMs,
    bool? isFavorite,
  }) {
    return Track(
      id: id,
      path: path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      durationMs: durationMs ?? this.durationMs,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      coverPath: clearCover ? null : (coverPath ?? this.coverPath),
      fileSize: fileSize ?? this.fileSize,
      mtimeMs: mtimeMs ?? this.mtimeMs,
      addedAt: addedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'path': path,
        'title': title,
        'artist': artist,
        'album': album,
        'album_artist': albumArtist,
        'track_number': trackNumber,
        'disc_number': discNumber,
        'duration_ms': durationMs,
        'year': year,
        'genre': genre,
        'cover_path': coverPath,
        'file_size': fileSize,
        'mtime_ms': mtimeMs,
        'added_at': (addedAt ?? DateTime.now()).toIso8601String(),
        'is_favorite': isFavorite ? 1 : 0,
      };

  factory Track.fromMap(Map<String, Object?> m) => Track(
        id: m['id']! as String,
        path: m['path']! as String,
        title: m['title']! as String,
        artist: m['artist']! as String,
        album: m['album']! as String,
        albumArtist: (m['album_artist'] as String?) ?? '',
        trackNumber: (m['track_number'] as int?) ?? 0,
        discNumber: (m['disc_number'] as int?) ?? 0,
        durationMs: (m['duration_ms'] as int?) ?? 0,
        year: (m['year'] as int?) ?? 0,
        genre: (m['genre'] as String?) ?? '',
        coverPath: m['cover_path'] as String?,
        fileSize: (m['file_size'] as int?) ?? 0,
        mtimeMs: (m['mtime_ms'] as int?) ?? 0,
        addedAt: DateTime.tryParse((m['added_at'] as String?) ?? ''),
        isFavorite: ((m['is_favorite'] as int?) ?? 0) == 1,
      );

  @override
  List<Object?> get props => [id, path, mtimeMs, fileSize, isFavorite];
}
