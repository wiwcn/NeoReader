import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.width = 72, this.height = 96});

  final Book book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget child;
    if (book.coverPath != null && File(book.coverPath!).existsSync()) {
      child = Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(cs),
      );
    } else {
      child = _placeholder(cs);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    final icon = switch (book.format) {
      BookFormat.epub => Icons.menu_book_rounded,
      BookFormat.pdf => Icons.picture_as_pdf_rounded,
      BookFormat.txt => Icons.article_rounded,
      BookFormat.md => Icons.tag_rounded,
      BookFormat.docx => Icons.description_rounded,
      BookFormat.html ||
      BookFormat.htm ||
      BookFormat.xhtml ||
      BookFormat.mhtml =>
        Icons.language_rounded,
      BookFormat.fb2 => Icons.chrome_reader_mode_rounded,
      BookFormat.mobi || BookFormat.azw3 || BookFormat.azw => Icons.tablet_mac_rounded,
      BookFormat.cbz || BookFormat.cbr => Icons.auto_stories_rounded,
      BookFormat.unknown => Icons.book_rounded,
    };
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Icon(icon, color: cs.onPrimaryContainer, size: width * 0.4),
    );
  }
}
