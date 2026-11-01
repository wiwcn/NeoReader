import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';
import 'music_repository.dart';
import 'tag_reader.dart';

typedef ScanProgress = void Function(int found, String currentPath);

/// Recursive local folder scan with audio extension whitelist.
class MusicScanner {
  MusicScanner(this._repo);

  final MusicRepository _repo;
  final TagReader _tags = TagReader();

  static const audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'opus',
    'wav',
    'wma',
    'aiff',
    'aif',
    'alac',
  };

  Future<int> scanRoot(
    String rootPath, {
    ScanProgress? onProgress,
    bool incremental = true,
  }) async {
    final root = Directory(rootPath);
    if (!await root.exists()) return 0;

    await _repo.addLibraryRoot(rootPath);

    final docs = await getApplicationDocumentsDirectory();
    final coversDir = p.join(docs.path, 'music_covers');

    final existing = {
      for (final t in await _repo.allTracks()) t.path: t,
    };

    var found = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
      if (!audioExtensions.contains(ext)) continue;

      onProgress?.call(found, entity.path);

      try {
        final stat = await entity.stat();
        final prev = existing[entity.path];
        if (incremental &&
            prev != null &&
            prev.fileSize == stat.size &&
            prev.mtimeMs == stat.modified.millisecondsSinceEpoch) {
          found++;
          continue;
        }

        final track = await _tags.read(entity, coversDir: coversDir);
        // Preserve id / favorite when refreshing same path.
        final upsert = prev != null
            ? track.copyWith(
                // keep favorite; replace metadata
              ).let((t) => Track(
                  id: prev.id,
                  path: t.path,
                  title: t.title,
                  artist: t.artist,
                  album: t.album,
                  albumArtist: t.albumArtist,
                  trackNumber: t.trackNumber,
                  discNumber: t.discNumber,
                  durationMs: prev.durationMs > 0 ? prev.durationMs : t.durationMs,
                  year: t.year,
                  genre: t.genre,
                  coverPath: t.coverPath ?? prev.coverPath,
                  fileSize: t.fileSize,
                  mtimeMs: t.mtimeMs,
                  addedAt: prev.addedAt,
                  isFavorite: prev.isFavorite,
                ))
            : track;

        await _repo.upsertTrack(upsert);
        found++;
      } catch (_) {
        // Skip unreadable files; keep scanning.
      }
    }
    return found;
  }
}

extension<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
