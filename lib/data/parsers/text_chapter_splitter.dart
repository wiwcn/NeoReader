/// Heuristic chapter detection for plain text (TXT / long HTML-extracted body).
///
/// Splits on common Chinese/English chapter heading lines. When nothing
/// reliable matches, returns a single chapter for the whole book.
library;

class TextChapter {
  TextChapter({
    required this.title,
    required this.content,
    required this.startOffset,
  });

  final String title;
  final String content;

  /// Character offset of the chapter title (or body start) in the original text.
  final int startOffset;
}

class TextChapterSplitter {
  /// Chinese: 第…章/节/回/部/卷/集 with Arabic, Chinese, or full-width digits.
  static final RegExp _zhChapter = RegExp(
    r'^[\s　]*第[一二三四五六七八九十百千零〇两\d０-９]+[章节回部卷集篇][^\n]{0,40}$',
  );

  /// English: Chapter 12 / CHAPTER XII
  static final RegExp _enChapter = RegExp(
    r'^[\s　]*(?:Chapter|CHAPTER)\s+[IVXLCDM\d]+[^\n]{0,40}$',
  );

  /// Optional short standalone titles (e.g. "序章", "楔子", "Prologue") —
  /// only accepted when they look like headings (short, alone on a line).
  static final RegExp _specialHeading = RegExp(
    r'^[\s　]*(序章|楔子|引子|前言|后记|後記|尾声|尾聲|番外|Prologue|Epilogue|Preface|Introduction|Afterword)[\s　]*$',
    caseSensitive: false,
  );

  /// Split [text] into chapters. Never returns an empty list.
  static List<TextChapter> split(String text, {String fallbackTitle = '正文'}) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.trim().isEmpty) {
      return [TextChapter(title: fallbackTitle, content: '', startOffset: 0)];
    }

    final lines = normalized.split('\n');
    final hits = <_Hit>[];
    var offset = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (_isHeading(trimmed)) {
        hits.add(_Hit(index: i, title: trimmed, offset: offset));
      }
      offset += line.length + 1; // +1 for '\n'
    }

    // Too few hits → treat as one chapter (avoid shredding).
    if (hits.length < 2) {
      return [
        TextChapter(
          title: fallbackTitle,
          content: normalized.trim(),
          startOffset: 0,
        ),
      ];
    }

    // Reject if headings are absurdly dense (e.g. every other line).
    final avgGap = normalized.length / hits.length;
    if (avgGap < 80 && hits.length > 8) {
      return [
        TextChapter(
          title: fallbackTitle,
          content: normalized.trim(),
          startOffset: 0,
        ),
      ];
    }

    final chapters = <TextChapter>[];
    // Prefatory text before first heading.
    if (hits.first.offset > 0) {
      final preface = normalized.substring(0, hits.first.offset).trim();
      if (preface.isNotEmpty) {
        chapters.add(
          TextChapter(title: fallbackTitle, content: preface, startOffset: 0),
        );
      }
    }

    for (var i = 0; i < hits.length; i++) {
      final start = hits[i].offset;
      final end = i + 1 < hits.length ? hits[i + 1].offset : normalized.length;
      var body = normalized.substring(start, end);
      // Drop the heading line itself from body (title shown separately).
      final firstNl = body.indexOf('\n');
      if (firstNl >= 0) {
        body = body.substring(firstNl + 1);
      } else {
        body = '';
      }
      chapters.add(
        TextChapter(
          title: hits[i].title,
          content: body.trim(),
          startOffset: start,
        ),
      );
    }

    return chapters.isEmpty
        ? [
            TextChapter(
              title: fallbackTitle,
              content: normalized.trim(),
              startOffset: 0,
            ),
          ]
        : chapters;
  }

  static bool _isHeading(String trimmed) {
    if (trimmed.isEmpty || trimmed.length > 60) return false;
    if (_zhChapter.hasMatch(trimmed)) return true;
    if (_enChapter.hasMatch(trimmed)) return true;
    if (_specialHeading.hasMatch(trimmed)) return true;
    return false;
  }

  /// Exposed for unit tests.
  static bool isLikelyHeading(String line) => _isHeading(line.trim());
}

class _Hit {
  _Hit({required this.index, required this.title, required this.offset});
  final int index;
  final String title;
  final int offset;
}
