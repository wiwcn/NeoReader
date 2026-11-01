import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Separate music DB so book schema stays untouched.
class MusicDatabase {
  MusicDatabase._();
  static final MusicDatabase instance = MusicDatabase._();

  static const dbName = 'neo_music.db';
  static const dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE tracks (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT NOT NULL,
  album_artist TEXT NOT NULL DEFAULT '',
  track_number INTEGER NOT NULL DEFAULT 0,
  disc_number INTEGER NOT NULL DEFAULT 0,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  year INTEGER NOT NULL DEFAULT 0,
  genre TEXT NOT NULL DEFAULT '',
  cover_path TEXT,
  file_size INTEGER NOT NULL DEFAULT 0,
  mtime_ms INTEGER NOT NULL DEFAULT 0,
  added_at TEXT NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0
)
''');
        await db.execute('''
CREATE TABLE library_roots (
  path TEXT PRIMARY KEY,
  added_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE playlists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE playlist_tracks (
  playlist_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (playlist_id, track_id),
  FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
  FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
)
''');
        await db.execute('''
CREATE TABLE waveform_cache (
  cache_key TEXT PRIMARY KEY,
  path TEXT NOT NULL,
  mtime_ms INTEGER NOT NULL,
  file_size INTEGER NOT NULL,
  peaks_blob BLOB NOT NULL,
  sample_rate_hint INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
)
''');
        await db.execute(
          'CREATE INDEX idx_tracks_artist ON tracks(artist)',
        );
        await db.execute(
          'CREATE INDEX idx_tracks_album ON tracks(album)',
        );
        await db.execute(
          'CREATE INDEX idx_playlist_tracks_pos ON playlist_tracks(playlist_id, position)',
        );
      },
    );
  }
}
