import 'package:flutter/material.dart';

/// Simple CJK vertical writing (竖排): columns top→bottom, columns right→left.
///
/// Characters flow down each column; horizontal scroll moves through columns
/// (start from the right). Suitable for plain text / EPUB text layers.
class VerticalTextView extends StatelessWidget {
  const VerticalTextView({
    super.key,
    required this.text,
    required this.style,
    this.controller,
    this.columnGap = 14,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.onScrollProgress,
  });

  final String text;
  final TextStyle style;
  final ScrollController? controller;
  final double columnGap;
  final EdgeInsets padding;
  final ValueChanged<double>? onScrollProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = style.fontSize ?? 18;
        final height = style.height ?? 1.75;
        final charH = fontSize * height;
        final usableH = (constraints.maxHeight - padding.vertical).clamp(
          80.0,
          4000.0,
        );
        final charsPerCol = (usableH / charH).floor().clamp(4, 200);
        final columns = _buildColumns(text, charsPerCol);
        final colW = fontSize * 1.15;

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (onScrollProgress != null && n.metrics.maxScrollExtent > 0) {
              // Reverse axis: offset 0 is the start (right).
              final p = (n.metrics.pixels / n.metrics.maxScrollExtent).clamp(
                0.0,
                1.0,
              );
              onScrollProgress!(p);
            }
            return false;
          },
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: padding,
            itemCount: columns.length,
            itemBuilder: (context, i) {
              final col = columns[i];
              return Padding(
                padding: EdgeInsets.only(left: columnGap),
                child: SizedBox(
                  width: colW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final ch in col)
                        SizedBox(
                          height: charH,
                          width: colW,
                          child: Center(
                            child: Text(
                              ch,
                              style: style.copyWith(height: 1.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Split into vertical columns. Newlines force a column break (paragraph).
  static List<List<String>> _buildColumns(String text, int charsPerCol) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final paragraphs = normalized.split('\n');
    final columns = <List<String>>[];
    var current = <String>[];

    void flush() {
      if (current.isNotEmpty) {
        columns.add(current);
        current = <String>[];
      }
    }

    for (final para in paragraphs) {
      final trimmed = para.trimRight();
      if (trimmed.isEmpty) {
        flush();
        // Blank line → empty column as spacing.
        columns.add(const ['　']);
        continue;
      }
      for (final rune in trimmed.runes) {
        final ch = String.fromCharCode(rune);
        if (ch.trim().isEmpty && ch != '　') {
          // Collapse ASCII spaces; keep full-width ideographic space.
          continue;
        }
        current.add(ch == ' ' ? '　' : ch);
        if (current.length >= charsPerCol) flush();
      }
      // End of paragraph: finish column so next paragraph starts fresh.
      flush();
    }
    flush();
    if (columns.isEmpty) columns.add(const ['　']);
    return columns;
  }
}
