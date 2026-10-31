import 'dart:convert';
import 'dart:io';

import 'text_content.dart';

class MdParser {
  Future<TextContent> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes, allowInvalid: true);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    var title = fallbackTitle ?? 'Markdown';
    if (text.startsWith('---')) {
      final end = text.indexOf(RegExp(r'\n---\s*\n'));
      if (end > 0) {
        final fm = text.substring(3, end);
        final titleRe = RegExp(r'^title:\s*(.*)$', multiLine: true);
        final m = titleRe.firstMatch(fm);
        if (m != null) {
          var t = m.group(1)!.trim();
          if ((t.startsWith('"') && t.endsWith('"')) ||
              (t.startsWith("'") && t.endsWith("'"))) {
            t = t.substring(1, t.length - 1);
          }
          if (t.isNotEmpty) title = t;
        }
        text = text.substring(end + 5).trimLeft();
      }
    }
    final h1 = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(text);
    if (h1 != null && (fallbackTitle == null || title == fallbackTitle)) {
      title = h1.group(1)!.trim();
    }

    return TextContent(
      title: title,
      author: 'Markdown',
      body: text,
      isMarkdown: true,
    );
  }
}
