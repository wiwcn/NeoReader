import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 56,
    this.height = 72,
    this.borderRadius = 12,
  });

  final Book book;
  final double width;
  final double height;
  final double borderRadius;

  /// FileImage codecs often never complete under flutter_test — cache bytes.
  static final Map<String, Uint8List> _bytesCache = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget child;
    final path = book.coverPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      try {
        final bytes = _bytesCache.putIfAbsent(path, () => File(path).readAsBytesSync());
        child = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _placeholder(cs),
        );
      } catch (_) {
        child = _placeholder(cs);
      }
    } else {
      child = _placeholder(cs);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
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
      BookFormat.mhtml => Icons.language_rounded,
      BookFormat.fb2 => Icons.chrome_reader_mode_rounded,
      BookFormat.mobi ||
      BookFormat.azw3 ||
      BookFormat.azw => Icons.tablet_mac_rounded,
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
