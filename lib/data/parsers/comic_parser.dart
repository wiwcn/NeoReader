import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class ComicPage {
  ComicPage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class ComicBookData {
  ComicBookData({required this.title, required this.pages});
  final String title;
  final List<ComicPage> pages;
}

/// CBZ (ZIP) comic reader. CBR: tries ZIP (some mislabeled); RAR not supported offline yet.
class ComicParser {
  static const _imageExts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};

  Future<ComicBookData> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    final title = fallbackTitle ?? p.basenameWithoutExtension(path);
    final lower = path.toLowerCase();

    Archive? archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {
      archive = null;
    }

    if (archive == null && lower.endsWith('.cbr')) {
      throw StateError(
        'CBR (RAR) archives need conversion to CBZ for offline reading. '
        'Re-save as ZIP/CBZ or convert with a comic tool.',
      );
    }
    if (archive == null) {
      // Try tar for .cbt-like
      try {
        archive = TarDecoder().decodeBytes(bytes);
      } catch (_) {
        throw StateError('Unable to open comic archive');
      }
    }

    final pages = <ComicPage>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = f.name.replaceAll('\\', '/');
      final base = p.basename(name);
      if (base.startsWith('.')) continue;
      final ext = p.extension(name).toLowerCase();
      if (!_imageExts.contains(ext)) continue;
      pages.add(
        ComicPage(
          name: name,
          bytes: Uint8List.fromList(f.content as List<int>),
        ),
      );
    }
    pages.sort((a, b) => _naturalCompare(a.name, b.name));
    if (pages.isEmpty) {
      throw StateError('No images found in comic archive');
    }
    return ComicBookData(title: title, pages: pages);
  }

  /// Extract first page as cover bytes if possible.
  Future<Uint8List?> firstImageBytes(String path) async {
    try {
      final data = await parseFile(path);
      return data.pages.first.bytes;
    } catch (_) {
      return null;
    }
  }

  int _naturalCompare(String a, String b) {
    final ra = RegExp(r'(\d+|\D+)')
        .allMatches(a.toLowerCase())
        .map((m) => m[0]!)
        .toList();
    final rb = RegExp(r'(\d+|\D+)')
        .allMatches(b.toLowerCase())
        .map((m) => m[0]!)
        .toList();
    final n = ra.length < rb.length ? ra.length : rb.length;
    for (var i = 0; i < n; i++) {
      final ca = ra[i];
      final cb = rb[i];
      final na = int.tryParse(ca);
      final nb = int.tryParse(cb);
      if (na != null && nb != null) {
        if (na != nb) return na.compareTo(nb);
      } else {
        final c = ca.compareTo(cb);
        if (c != 0) return c;
      }
    }
    return ra.length.compareTo(rb.length);
  }
}
