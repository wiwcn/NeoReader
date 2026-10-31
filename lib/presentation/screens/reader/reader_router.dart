import 'package:flutter/material.dart';

import '../../../domain/models/book.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';
import 'txt_reader_screen.dart';

void openReader(BuildContext context, Book book) {
  final page = switch (book.format) {
    BookFormat.epub => EpubReaderScreen(book: book),
    BookFormat.pdf => PdfReaderScreen(book: book),
    BookFormat.txt => TxtReaderScreen(book: book),
    BookFormat.unknown => null,
  };
  if (page == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unsupported format')),
    );
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
