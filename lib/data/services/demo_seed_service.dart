import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'import_service.dart';

/// Copies bundled public-domain / own-work sample books into the library once
/// (for demos / first launch). Independent of [MusicSeedService].
class DemoSeedService {
  /// Bump when sample book set changes so existing installs re-seed once.
  static const _prefKey = 'neomedia_demo_seeded_v2';

  static const samples = <String>[
    'assets/samples/books/alice_in_wonderland.epub',
    'assets/samples/books/aesops_fables.epub',
    'assets/samples/books/yellow_wallpaper.epub',
    'assets/samples/books/christmas_carol.epub',
    'assets/samples/books/shijing.epub',
    'assets/samples/books/sample_comic.cbz',
  ];

  Future<int> seedIfNeeded({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_prefKey) ?? false)) return 0;

    final tmp = await getTemporaryDirectory();
    final import = ImportService();
    var ok = 0;
    for (final asset in samples) {
      try {
        final data = await rootBundle.load(asset);
        final name = p.basename(asset);
        final out = File(p.join(tmp.path, 'neomedia_seed_$name'));
        await out.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        final r = await import.importFile(out.path);
        if (r.success) ok++;
      } catch (_) {
        // Skip missing assets quietly.
      }
    }
    await prefs.setBool(_prefKey, true);
    return ok;
  }
}
