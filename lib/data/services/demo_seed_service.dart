import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'import_service.dart';

/// Copies bundled sample books into the library once (for demos / screenshots).
class DemoSeedService {
  static const _prefKey = 'neoreader_demo_seeded_v1';

  static const samples = <String>[
    'assets/samples/welcome.txt',
    'assets/samples/guide.md',
    'assets/samples/essay.html',
    'assets/samples/story.fb2',
    'assets/samples/demo_comic.cbz',
    'assets/samples/note.docx',
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
        final out = File(p.join(tmp.path, 'neoreader_seed_$name'));
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
