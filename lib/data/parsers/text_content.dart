/// Shared text payload used by scroll readers (TXT / FB2 / HTML / MD / DOCX / MOBI).
class TextContent {
  TextContent({
    required this.title,
    required this.author,
    required this.body,
    this.isMarkdown = false,
  });

  final String title;
  final String author;
  final String body;
  final bool isMarkdown;
}
