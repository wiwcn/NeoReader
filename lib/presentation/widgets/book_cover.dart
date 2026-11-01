import 'dart:io';

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

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (book.coverPath != null && File(book.coverPath!).existsSync()) {
      child = Image.file(
        File(book.coverPath!),
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  /// Generated spine cover: no artwork yet, so each format gets its own tint
  /// (bookshelf reads as varied as a real shelf instead of one flat block).
  Widget _placeholder() {
    final look = _formatLook(book.format);
    final hsl = HSLColor.fromColor(look.tint);
    final top = hsl
        .withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0))
        .toColor();
    final bottom = hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .toColor();

    final showLabel = width >= 48;
    final iconSize = (width < height ? width : height) * 0.36;
    final spineW = (width * 0.10).clamp(3.0, 7.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom vignette so the label / icon stay legible on bright tints.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
          // Left spine band.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: spineW,
              color: Colors.black.withValues(alpha: 0.16),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: spineW),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  look.icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.94),
                ),
                if (showLabel) ...[
                  SizedBox(height: iconSize * 0.18),
                  Text(
                    book.format.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: (width * 0.15).clamp(8.0, 11.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FormatLook _formatLook(BookFormat format) {
    switch (format) {
      case BookFormat.epub:
        return const _FormatLook(Icons.menu_book_rounded, Color(0xFF3F51B5));
      case BookFormat.pdf:
        return const _FormatLook(
          Icons.picture_as_pdf_rounded,
          Color(0xFFE53935),
        );
      case BookFormat.txt:
        return const _FormatLook(Icons.article_rounded, Color(0xFF00897B));
      case BookFormat.md:
        return const _FormatLook(Icons.tag_rounded, Color(0xFF6D4C41));
      case BookFormat.docx:
        return const _FormatLook(Icons.description_rounded, Color(0xFF546E7A));
      case BookFormat.html:
      case BookFormat.htm:
      case BookFormat.xhtml:
      case BookFormat.mhtml:
        return const _FormatLook(Icons.language_rounded, Color(0xFF7E57C2));
      case BookFormat.fb2:
        return const _FormatLook(
          Icons.chrome_reader_mode_rounded,
          Color(0xFF43A047),
        );
      case BookFormat.mobi:
      case BookFormat.azw3:
      case BookFormat.azw:
        return const _FormatLook(Icons.tablet_mac_rounded, Color(0xFFFB8C00));
      case BookFormat.cbz:
      case BookFormat.cbr:
        return const _FormatLook(Icons.auto_stories_rounded, Color(0xFFD81B60));
      case BookFormat.unknown:
        return const _FormatLook(Icons.book_rounded, Color(0xFF757575));
    }
  }
}

class _FormatLook {
  const _FormatLook(this.icon, this.tint);
  final IconData icon;
  final Color tint;
}
