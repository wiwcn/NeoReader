import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../domain/models/book.dart';
import '../parsers/comic_parser.dart';
import '../parsers/docx_parser.dart';
import '../parsers/epub_parser.dart';
import '../parsers/fb2_parser.dart';
import '../parsers/format_registry.dart';
import '../parsers/html_parser.dart';
import '../parsers/md_parser.dart';
import '../parsers/mobi_parser.dart';
import '../parsers/txt_parser.dart';
import '../repositories/book_repository_impl.dart';

class ImportResult {
  ImportResult.ok(this.book) : error = null;
  ImportResult.fail(this.error) : book = null;

  final Book? book;
  final String? error;
  bool get success => book != null;
}

class ImportService {
  ImportService({BookRepositoryImpl? books})
    : _books = books ?? BookRepositoryImpl();

  final BookRepositoryImpl _books;
  final _uuid = const Uuid();
  final _epub = EpubParser();
  final _txt = TxtParser();
  final _fb2 = Fb2Parser();
  final _html = HtmlBookParser();
  final _md = MdParser();
  final _docx = DocxParser();
  final _mobi = MobiParser();
  final _comic = ComicParser();

  Future<ImportResult> importFile(String sourcePath) async {
    final ext = p.extension(sourcePath).replaceAll('.', '').toLowerCase();
    final support = FormatRegistry.supportFor(ext);
    if (support != FormatSupport.implemented) {
      return ImportResult.fail('planned_or_unsupported:$ext');
    }

    try {
      final docs = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(docs.path, AppConstants.booksDirName));
      final coversDir = Directory(
        p.join(docs.path, AppConstants.coversDirName),
      );
      if (!await booksDir.exists()) await booksDir.create(recursive: true);
      if (!await coversDir.exists()) await coversDir.create(recursive: true);

      final id = _uuid.v4();
      final destName = '$id.$ext';
      final destPath = p.join(booksDir.path, destName);
      await File(sourcePath).copy(destPath);
      final size = await File(destPath).length();

      var title = p.basenameWithoutExtension(sourcePath);
      var author = 'Unknown';
      String? coverPath;
      final format = FormatRegistry.toBookFormat(ext);

      switch (format) {
        case BookFormat.epub:
          final data = await _epub.parseFile(destPath);
          title = data.title;
          author = data.author;
          if (data.coverBytes != null) {
            coverPath = p.join(coversDir.path, '$id.jpg');
            await File(coverPath).writeAsBytes(data.coverBytes!);
          }
        case BookFormat.txt:
          final data = await _txt.parseFile(destPath, fallbackTitle: title);
          title = data.title;
        case BookFormat.pdf:
          author = 'PDF';
        case BookFormat.fb2:
          final data = await _fb2.parseFile(destPath, fallbackTitle: title);
          title = data.title;
          author = data.author;
        case BookFormat.html ||
            BookFormat.htm ||
            BookFormat.xhtml ||
            BookFormat.mhtml:
          final data = await _html.parseFile(destPath, fallbackTitle: title);
          title = data.title;
          author = data.author;
        case BookFormat.md:
          final data = await _md.parseFile(destPath, fallbackTitle: title);
          title = data.title;
          author = data.author;
        case BookFormat.docx:
          final data = await _docx.parseFile(destPath, fallbackTitle: title);
          title = data.title;
          author = data.author;
        case BookFormat.mobi || BookFormat.azw3 || BookFormat.azw:
          final data = await _mobi.parseFile(destPath, fallbackTitle: title);
          title = data.title;
          author = data.author;
        case BookFormat.cbz || BookFormat.cbr:
          author = 'Comic';
          final cover = await _comic.firstImageBytes(destPath);
          if (cover != null) {
            coverPath = p.join(coversDir.path, '$id.jpg');
            await File(coverPath).writeAsBytes(cover);
          }
        case BookFormat.unknown:
          break;
      }

      final book = Book(
        id: id,
        title: title,
        author: author,
        format: format,
        filePath: destPath,
        coverPath: coverPath,
        fileSize: size,
        addedAt: DateTime.now(),
      );
      await _books.upsert(book);
      return ImportResult.ok(book);
    } catch (e) {
      return ImportResult.fail(e.toString());
    }
  }
}
