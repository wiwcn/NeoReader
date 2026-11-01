import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/models/book.dart';
import '../repositories/book_repository_impl.dart';
import 'import_service.dart';

/// One bundled sample book + its optional cover asset.
class _SampleBook {
  const _SampleBook({
    required this.bookAsset,
    required this.coverAsset,
    required this.titleHints,
    required this.fileMarker,
  });

  final String bookAsset;
  final String coverAsset;
  final List<String> titleHints;
  final String fileMarker;
}

/// Copies bundled public-domain / own-work sample books into the library once
/// (for demos / first launch). Independent of [MusicSeedService].
class DemoSeedService {
  /// Bump when sample book set / covers change so existing installs re-seed once.
  static const _prefKey = 'neomedia_demo_seeded_v3';
  static const _legacyPrefKeys = <String>[
    'neomedia_demo_seeded_v2',
    'neomedia_demo_seeded_v1',
  ];

  static const samples = <_SampleBook>[
    _SampleBook(
      bookAsset: 'assets/samples/books/alice_in_wonderland.epub',
      coverAsset: 'assets/samples/books/covers/alice.jpg',
      titleHints: ['alice', "alice's adventures"],
      fileMarker: 'alice_in_wonderland',
    ),
    _SampleBook(
      bookAsset: 'assets/samples/books/aesops_fables.epub',
      coverAsset: 'assets/samples/books/covers/aesop.jpg',
      titleHints: ['aesop', 'fables'],
      fileMarker: 'aesops_fables',
    ),
    _SampleBook(
      bookAsset: 'assets/samples/books/yellow_wallpaper.epub',
      coverAsset: 'assets/samples/books/covers/yellow_wallpaper.jpg',
      titleHints: ['yellow wallpaper'],
      fileMarker: 'yellow_wallpaper',
    ),
    _SampleBook(
      bookAsset: 'assets/samples/books/christmas_carol.epub',
      coverAsset: 'assets/samples/books/covers/christmas_carol.jpg',
      titleHints: ['christmas carol'],
      fileMarker: 'christmas_carol',
    ),
    _SampleBook(
      bookAsset: 'assets/samples/books/shijing.epub',
      coverAsset: 'assets/samples/books/covers/shijing.jpg',
      titleHints: ['詩經', 'shi jing', 'shijing'],
      fileMarker: 'shijing',
    ),
    _SampleBook(
      bookAsset: 'assets/samples/books/sample_comic.cbz',
      coverAsset: 'assets/samples/books/covers/sample_comic.jpg',
      titleHints: ['sample comic', 'neomedia sample comic'],
      fileMarker: 'sample_comic',
    ),
  ];

  /// Asset paths of sample books (kept for callers / docs).
  static List<String> get sampleBookAssets =>
      samples.map((s) => s.bookAsset).toList(growable: false);

  Future<int> seedIfNeeded({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_prefKey) ?? false)) return 0;

    final books = BookRepositoryImpl();
    final existing = await books.getAll();
    final tmp = await getTemporaryDirectory();
    final import = ImportService(books: books);
    var ok = 0;

    for (final sample in samples) {
      try {
        final coverBytes = await _loadBytes(sample.coverAsset);
        final match = _findExisting(existing, sample);
        if (match != null) {
          final updated = await _ensureCover(match, coverBytes, books);
          if (updated) ok++;
          continue;
        }

        final data = await rootBundle.load(sample.bookAsset);
        final name = p.basename(sample.bookAsset);
        final out = File(p.join(tmp.path, 'neomedia_seed_$name'));
        await out.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        final r = await import.importFile(
          out.path,
          fallbackCoverBytes: coverBytes,
        );
        if (r.success) ok++;
      } catch (_) {
        // Skip missing assets quietly.
      }
    }

    await prefs.setBool(_prefKey, true);
    for (final k in _legacyPrefKeys) {
      await prefs.remove(k);
    }
    return ok;
  }

  Book? _findExisting(List<Book> books, _SampleBook sample) {
    final marker = sample.fileMarker.toLowerCase();
    for (final b in books) {
      final path = b.filePath.toLowerCase();
      if (path.contains(marker)) return b;
      final title = b.title.toLowerCase();
      for (final hint in sample.titleHints) {
        if (title.contains(hint.toLowerCase())) return b;
      }
    }
    return null;
  }

  Future<Uint8List> _loadBytes(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Writes cover bytes into the app covers dir and updates [book] when needed.
  Future<bool> _ensureCover(
    Book book,
    Uint8List coverBytes,
    BookRepositoryImpl books,
  ) async {
    final hasFile = book.coverPath != null &&
        book.coverPath!.isNotEmpty &&
        File(book.coverPath!).existsSync();
    if (hasFile) return false;

    final docs = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docs.path, AppConstants.coversDirName));
    if (!await coversDir.exists()) await coversDir.create(recursive: true);
    final dest = p.join(coversDir.path, '${book.id}.jpg');
    await File(dest).writeAsBytes(coverBytes, flush: true);
    await books.upsert(book.copyWith(coverPath: dest));
    return true;
  }
}
