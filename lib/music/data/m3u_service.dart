import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/playlist.dart';
import '../models/track.dart';

class M3uService {
  /// Export playlist to `.m3u8` (UTF-8 extended M3U).
  Future<File> exportPlaylist({
    required Playlist playlist,
    required List<Track> tracks,
    required Directory outDir,
  }) async {
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final safe = playlist.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(p.join(outDir.path, '$safe.m3u8'));
    final buf = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#PLAYLIST:${playlist.name}');
    for (final t in tracks) {
      final seconds = (t.durationMs / 1000).round();
      buf.writeln('#EXTINF:$seconds,${t.artist} - ${t.title}');
      buf.writeln(t.path);
    }
    await file.writeAsString(buf.toString(), flush: true);
    return file;
  }

  /// Also write classic `.m3u` alias (same UTF-8 body).
  Future<File> exportPlaylistM3u({
    required Playlist playlist,
    required List<Track> tracks,
    required Directory outDir,
  }) async {
    final f = await exportPlaylist(
      playlist: playlist,
      tracks: tracks,
      outDir: outDir,
    );
    final m3u = File(p.setExtension(f.path, '.m3u'));
    await f.copy(m3u.path);
    return m3u;
  }
}
