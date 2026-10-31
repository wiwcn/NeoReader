import 'package:flutter/material.dart';

/// Page-turn view for a single plain-text body using [TextPainter] measurement.
class PaginatedPlainText extends StatefulWidget {
  const PaginatedPlainText({
    super.key,
    required this.text,
    required this.style,
    required this.padding,
    this.controller,
    this.onProgress,
    this.initialPage = 0,
  });

  final String text;
  final TextStyle style;
  final EdgeInsets padding;
  final PageController? controller;

  /// Called with progress 0–1 when the page changes or pages are measured.
  final ValueChanged<double>? onProgress;
  final int initialPage;

  @override
  State<PaginatedPlainText> createState() => _PaginatedPlainTextState();
}

class _PaginatedPlainTextState extends State<PaginatedPlainText> {
  List<String> _pages = const [];
  Size? _lastSize;
  TextStyle? _lastStyle;
  String? _lastText;
  int _index = 0;

  void _emitProgress() {
    if (widget.onProgress == null || _pages.isEmpty) return;
    widget.onProgress!(((_index + 1) / _pages.length).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          (constraints.maxWidth - widget.padding.horizontal).clamp(
            40.0,
            4000.0,
          ),
          (constraints.maxHeight - widget.padding.vertical).clamp(40.0, 4000.0),
        );
        if (_pages.isEmpty ||
            _lastSize != size ||
            _lastStyle != widget.style ||
            _lastText != widget.text) {
          _lastSize = size;
          _lastStyle = widget.style;
          _lastText = widget.text;
          _pages = paginatePlainText(widget.text, widget.style, size);
          _index = _index.clamp(0, _pages.length - 1);
          WidgetsBinding.instance.addPostFrameCallback((_) => _emitProgress());
        }
        return PageView.builder(
          controller: widget.controller,
          itemCount: _pages.length,
          onPageChanged: (i) {
            _index = i;
            _emitProgress();
          },
          itemBuilder: (context, i) {
            return Padding(
              padding: widget.padding,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  _pages[i],
                  style: widget.style,
                  textAlign: TextAlign.justify,
                  softWrap: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Greedy pagination: pack as many characters as fit into [pageSize].
List<String> paginatePlainText(String text, TextStyle style, Size pageSize) {
  final body = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (body.isEmpty) return [''];

  final pages = <String>[];
  var offset = 0;
  final total = body.length;

  while (offset < total) {
    while (offset < total && body[offset] == '\n') {
      offset++;
    }
    if (offset >= total) break;

    var low = offset + 1;
    var high = total;
    var best = offset + 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final slice = body.substring(offset, mid);
      final tp = TextPainter(
        text: TextSpan(text: slice, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: pageSize.width);
      if (tp.height <= pageSize.height) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    var end = best;
    if (end < total) {
      final windowStart = (end - 40).clamp(offset, end);
      final soft = body.lastIndexOf('\n', end - 1);
      if (soft >= windowStart) {
        end = soft + 1;
      }
    }
    if (end <= offset) end = (offset + 1).clamp(0, total);
    pages.add(body.substring(offset, end).trimRight());
    offset = end;
  }

  if (pages.isEmpty) pages.add('');
  return pages;
}
