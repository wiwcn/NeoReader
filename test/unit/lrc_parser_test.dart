import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/music/vivid/lrc_parser.dart';

void main() {
  group('LrcParser.parse', () {
    test('parses mm:ss.xx timestamps', () {
      const raw = '''
[00:12.50]第一句
[00:18.00]第二句
[01:02.05]第三句
''';
      final lines = LrcParser.parse(raw);
      expect(lines.length, 3);
      expect(lines[0].startMs, 12500);
      expect(lines[0].text, '第一句');
      expect(lines[1].startMs, 18000);
      expect(lines[2].startMs, 62050);
      expect(lines[2].text, '第三句');
    });

    test('supports multi-timestamp lines and ms fractions', () {
      const raw = '[00:01.100][00:05.200]重复句\n[ti:ignore]\n';
      final lines = LrcParser.parse(raw);
      expect(lines.length, 2);
      expect(lines[0].startMs, 1100);
      expect(lines[1].startMs, 5200);
      expect(lines[0].text, '重复句');
    });

    test('activeIndex binary search', () {
      final lines = LrcParser.parse('''
[00:10.00]A
[00:20.00]B
[00:30.00]C
''');
      expect(LrcParser.activeIndex(lines, Duration.zero), -1);
      expect(LrcParser.activeIndex(lines, const Duration(seconds: 10)), 0);
      expect(LrcParser.activeIndex(lines, const Duration(seconds: 25)), 1);
      expect(LrcParser.activeIndex(lines, const Duration(seconds: 90)), 2);
    });
  });
}
