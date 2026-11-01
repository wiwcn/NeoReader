import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/play_mode.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'music_database.dart';

class MusicRepository {
  static const _uuid = Uuid();
  static const _queueKey = 'music_queue_ids';
  static const _queueIndexKey = 'music_queue_index';
  static const _playModeKey = 'music_play_mode';

  Future<List<Track>> allTracks() async {
    final db = await MusicDatabase.instance.database;
    final rows = await db.query('tracks', orderBy: 'title COLLATE NOCASE ASC');
    return rows.map(Track.fromMap).toList();
  }

  Future<Track?> trackById(String id) async {
    final db = await MusicDatabase.instance.database;
    final rows = await db.query('tracks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Track.fromMap(rows.first);
  }

  Future<Track?> trackByPath(String path) async {
    final db = await MusicDatabase.instance.database;
    final rows =
        await db.query('tracks', where: 'path = ?', whereArgs: [path], limit: 1);
    if (rows.isEmpty) return null;
    return Track.fromMap(rows.first);
  }

  Future<void> upsertTrack(Track track) async {
    final db = await MusicDatabase.instance.database;
    await db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDuration(String id, int durationMs) async {
    final db = await MusicDatabase.instance.database;
    await db.update(
      'tracks',
      {'duration_ms': durationMs},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setFavorite(String id, bool favorite) async {
    final db = await MusicDatabase.instance.database;
    await db.update(
      'tracks',
      {'is_favorite': favorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTrack(String id) async {
    final db = await MusicDatabase.instance.database;
    await db.delete('tracks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> libraryRoots() async {
    final db = await MusicDatabase.instance.database;
    final rows = await db.query('library_roots', orderBy: 'added_at ASC');
    return rows.map((r) => r['path']! as String).toList();
  }

  Future<void> addLibraryRoot(String path) async {
    final db = await MusicDatabase.instance.database;
    await db.insert(
      'library_roots',
      {'path': path, 'added_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeLibraryRoot(String path) async {
    final db = await MusicDatabase.instance.database;
    await db.delete('library_roots', where: 'path = ?', whereArgs: [path]);
  }

  List<Album> albumsFrom(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final key = '${t.displayArtist.toLowerCase()}::${t.displayAlbum.toLowerCase()}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final albums = map.entries.map((e) {
      final list = [...e.value]
        ..sort((a, b) {
          final d = a.discNumber.compareTo(b.discNumber);
          if (d != 0) return d;
          final n = a.trackNumber.compareTo(b.trackNumber);
          if (n != 0) return n;
          return a.title.compareTo(b.title);
        });
      final first = list.first;
      return Album(
        name: first.displayAlbum,
        artist: first.displayArtist,
        tracks: list,
        coverPath: list.map((t) => t.coverPath).firstWhere(
              (c) => c != null && c.isNotEmpty,
              orElse: () => null,
            ),
        year: list.map((t) => t.year).where((y) => y > 0).fold(0, (a, b) => a > b ? a : b),
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return albums;
  }

  List<Artist> artistsFrom(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      map.putIfAbsent(t.displayArtist.toLowerCase(), () => []).add(t);
    }
    final artists = map.entries.map((e) {
      final list = [...e.value]..sort((a, b) => a.title.compareTo(b.title));
      return Artist(name: list.first.displayArtist, tracks: list);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return artists;
  }

  // --- Playlists ---

  Future<List<Playlist>> allPlaylists() async {
    final db = await MusicDatabase.instance.database;
    final rows = await db.query('playlists', orderBy: 'name COLLATE NOCASE ASC');
    final out = <Playlist>[];
    for (final r in rows) {
      final ids = await db.query(
        'playlist_tracks',
        columns: ['track_id'],
        where: 'playlist_id = ?',
        whereArgs: [r['id']],
        orderBy: 'position ASC',
      );
      out.add(
        Playlist.fromMap(
          r,
          trackIds: ids.map((e) => e['track_id']! as String).toList(),
        ),
      );
    }
    return out;
  }

  Future<Playlist> createPlaylist(String name) async {
    final db = await MusicDatabase.instance.database;
    final now = DateTime.now();
    final pl = Playlist(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Playlist' : name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('playlists', pl.toMap());
    return pl;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final db = await MusicDatabase.instance.database;
    await db.update(
      'playlists',
      {
        'name': name.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlaylist(String id) async {
    final db = await MusicDatabase.instance.database;
    await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPlaylistTracks(String playlistId, List<String> trackIds) async {
    final db = await MusicDatabase.instance.database;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    final batch = db.batch();
    for (var i = 0; i < trackIds.length; i++) {
      batch.insert('playlist_tracks', {
        'playlist_id': playlistId,
        'track_id': trackIds[i],
        'position': i,
      });
    }
    await batch.commit(noResult: true);
    await db.update(
      'playlists',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackIds) async {
    final current = await allPlaylists();
    final pl = current.firstWhere((p) => p.id == playlistId);
    final merged = [...pl.trackIds];
    for (final id in trackIds) {
      if (!merged.contains(id)) merged.add(id);
    }
    await setPlaylistTracks(playlistId, merged);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final current = await allPlaylists();
    final pl = current.firstWhere((p) => p.id == playlistId);
    await setPlaylistTracks(
      playlistId,
      pl.trackIds.where((id) => id != trackId).toList(),
    );
  }

  // --- Queue persistence ---

  Future<void> saveQueue(List<String> trackIds, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(trackIds));
    await prefs.setInt(_queueIndexKey, index);
  }

  Future<(List<String>, int)> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final index = prefs.getInt(_queueIndexKey) ?? 0;
    if (raw == null || raw.isEmpty) return (<String>[], 0);
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return (list, index.clamp(0, list.isEmpty ? 0 : list.length - 1));
    } catch (_) {
      return (<String>[], 0);
    }
  }

  Future<void> savePlayMode(PlayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playModeKey, mode.name);
  }

  Future<PlayMode> loadPlayMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_playModeKey);
    return PlayMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => PlayMode.listLoop,
    );
  }
}
