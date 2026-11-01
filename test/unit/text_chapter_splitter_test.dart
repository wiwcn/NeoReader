import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/data/parsers/text_chapter_splitter.dart';

void main() {
  group('TextChapterSplitter.isLikelyHeading', () {
    test('matches Chinese chapter lines', () {
      expect(TextChapterSplitter.isLikelyHeading('第一章 启程'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('第十二章'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('第3回 风云'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('第１０卷'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('楔子'), isTrue);
    });

    test('matches English chapter lines', () {
      expect(TextChapterSplitter.isLikelyHeading('Chapter 1'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('CHAPTER XII The End'), isTrue);
      expect(TextChapterSplitter.isLikelyHeading('Prologue'), isTrue);
    });

    test('rejects body lines', () {
      expect(TextChapterSplitter.isLikelyHeading('他说第一章很好。'), isFalse);
      expect(
        TextChapterSplitter.isLikelyHeading(
          '这是很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的一行不像标题',
        ),
        isFalse,
      );
    });
  });

  group('TextChapterSplitter.split', () {
    test('splits on multiple Chinese chapters', () {
      const text = '''
前言若干字。

第一章 出发
正文甲。

第二章 归来
正文乙。
''';
      final chapters = TextChapterSplitter.split(text);
      expect(chapters.length, greaterThanOrEqualTo(2));
      expect(chapters.any((c) => c.title.contains('第一章')), isTrue);
      expect(chapters.any((c) => c.title.contains('第二章')), isTrue);
    });

    test('falls back to single chapter when no headings', () {
      const text = '没有标题的一整段文字。\n再来一段。';
      final chapters = TextChapterSplitter.split(text, fallbackTitle: '全书');
      expect(chapters, hasLength(1));
      expect(chapters.single.title, '全书');
      expect(chapters.single.content, contains('没有标题'));
    });

    test('does not shred when only one heading', () {
      const text = '''
第一章 仅此
后面全是正文没有其他章节标题。
''';
      final chapters = TextChapterSplitter.split(text, fallbackTitle: '正文');
      expect(chapters, hasLength(1));
    });
  });
}
