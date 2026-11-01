import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../music/data/music_repository.dart';
import '../../music/data/music_scanner.dart';

/// Copies bundled CC0 sample tracks + square covers into a scannable folder
/// once (for demos / first launch). Independent of [DemoSeedService] book seed.
class MusicSeedService {
  static const _prefKey = 'neoreader_music_seeded_v1';

  /// Asset mp3, cover asset, destination album folder name.
  static const samples = <(String, String, String)>[
    (
      'assets/samples/music/fairitale.mp3',
      'assets/samples/music/covers/cover1.jpg',
      'Fairitale',
    ),
    (
      'assets/samples/music/interlude.mp3',
      'assets/samples/music/covers/cover2.jpg',
      'Interlude',
    ),
    (
      'assets/samples/music/dancing_needles.mp3',
      'assets/samples/music/covers/cover3.jpg',
      'Dancing Needles',
    ),
    (
      'assets/samples/music/forward_momentum.mp3',
      'assets/samples/music/covers/cover4.jpg',
      'Forward Momentum',
    ),
  ];

  Future<int> seedIfNeeded({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_prefKey) ?? false)) return 0;

    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'sample_music'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    var written = 0;
    for (final (audioAsset, coverAsset, album) in samples) {
      try {
        final albumDir = Directory(p.join(root.path, album));
        if (!await albumDir.exists()) {
          await albumDir.create(recursive: true);
        }

        final audioName = p.basename(audioAsset);
        final audioOut = File(p.join(albumDir.path, audioName));
        if (!await audioOut.exists()) {
          final data = await rootBundle.load(audioAsset);
          await audioOut.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }

        final coverOut = File(p.join(albumDir.path, 'cover.jpg'));
        if (!await coverOut.exists()) {
          final cover = await rootBundle.load(coverAsset);
          await coverOut.writeAsBytes(
            cover.buffer.asUint8List(cover.offsetInBytes, cover.lengthInBytes),
            flush: true,
          );
        }
        written++;
      } catch (_) {
        // Skip missing assets quietly.
      }
    }

    var found = 0;
    try {
      final scanner = MusicScanner(MusicRepository());
      found = await scanner.scanRoot(root.path);
    } catch (_) {
      found = 0;
    }

    await prefs.setBool(_prefKey, true);
    return found > 0 ? found : written;
  }
}
