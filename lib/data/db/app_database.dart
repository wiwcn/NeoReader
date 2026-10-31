import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  format TEXT NOT NULL,
  file_path TEXT NOT NULL,
  cover_path TEXT,
  file_size INTEGER NOT NULL DEFAULT 0,
  progress REAL NOT NULL DEFAULT 0,
  last_location TEXT,
  added_at TEXT NOT NULL,
  last_read_at TEXT
)
''');
        await db.execute('''
CREATE TABLE annotations (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  location TEXT,
  chapter TEXT,
  selected_text TEXT,
  note TEXT,
  color_hex TEXT,
  progress REAL,
  FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
)
''');
        await db.execute('''
CREATE TABLE reading_sessions (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  ended_at TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
)
''');
        await db.execute(
          'CREATE INDEX idx_annotations_book ON annotations(book_id)',
        );
        await db.execute(
          'CREATE INDEX idx_sessions_book ON reading_sessions(book_id)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS reading_sessions (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  ended_at TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL
)
''');
        }
      },
    );
  }
}
