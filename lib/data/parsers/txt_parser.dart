import 'dart:convert';
import 'dart:io';

class TxtBookData {
  TxtBookData({required this.title, required this.content});
  final String title;
  final String content;
}

class TxtParser {
  Future<TxtBookData> parseFile(
    String filePath, {
    String? fallbackTitle,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes, allowInvalid: true);
    }
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final name =
        fallbackTitle ??
        (file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last.replaceAll(
                RegExp(r'\.txt$', caseSensitive: false),
                '',
              )
            : 'Text');
    return TxtBookData(title: name, content: text);
  }
}
