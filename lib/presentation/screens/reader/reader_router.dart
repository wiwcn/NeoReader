import 'package:flutter/material.dart';

import '../../../data/parsers/docx_parser.dart';
import '../../../data/parsers/fb2_parser.dart';
import '../../../data/parsers/html_parser.dart';
import '../../../data/parsers/md_parser.dart';
import '../../../data/parsers/mobi_parser.dart';
import '../../../domain/models/book.dart';
import 'comic_reader_screen.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';
import 'text_content_reader_screen.dart';
import 'txt_reader_screen.dart';

void openReader(BuildContext context, Book book) {
  final Widget? page = switch (book.format) {
    BookFormat.epub => EpubReaderScreen(book: book),
    BookFormat.pdf => PdfReaderScreen(book: book),
    BookFormat.txt => TxtReaderScreen(book: book),
    BookFormat.cbz || BookFormat.cbr => ComicReaderScreen(book: book),
    BookFormat.md => TextContentReaderScreen(
      book: book,
      loader: () =>
          MdParser().parseFile(book.filePath, fallbackTitle: book.title),
    ),
    BookFormat.fb2 => TextContentReaderScreen(
      book: book,
      loader: () =>
          Fb2Parser().parseFile(book.filePath, fallbackTitle: book.title),
    ),
    BookFormat.html ||
    BookFormat.htm ||
    BookFormat.xhtml ||
    BookFormat.mhtml => TextContentReaderScreen(
      book: book,
      loader: () =>
          HtmlBookParser().parseFile(book.filePath, fallbackTitle: book.title),
    ),
    BookFormat.docx => TextContentReaderScreen(
      book: book,
      loader: () =>
          DocxParser().parseFile(book.filePath, fallbackTitle: book.title),
    ),
    BookFormat.mobi ||
    BookFormat.azw3 ||
    BookFormat.azw => TextContentReaderScreen(
      book: book,
      loader: () =>
          MobiParser().parseFile(book.filePath, fallbackTitle: book.title),
    ),
    BookFormat.unknown => null,
  };

  if (page == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Unsupported format')));
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
