import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/data/services/reading_term_converter.dart';
import 'package:neo_reader/domain/models/app_settings.dart';

void main() {
  group('ReadingTermConverter', () {
    test('off leaves text unchanged', () {
      const raw = '義大利的霜淇淋與軟體';
      expect(
        ReadingTermConverter.convert(raw, TermConversionMode.off),
        raw,
      );
    });

    test('toMainland converts user examples', () {
      expect(
        ReadingTermConverter.convert('義大利', TermConversionMode.toMainland),
        '意大利',
      );
      expect(
        ReadingTermConverter.convert('义大利', TermConversionMode.toMainland),
        '意大利',
      );
      expect(
        ReadingTermConverter.convert('霜淇淋', TermConversionMode.toMainland),
        '冰淇淋',
      );
      expect(
        ReadingTermConverter.convert('冰淇凌', TermConversionMode.toMainland),
        '冰淇淋',
      );
      expect(
        ReadingTermConverter.convert(
          '這套軟體佔用大量記憶體，連上網路後可更新。',
          TermConversionMode.toMainland,
        ),
        contains('软件'),
      );
      expect(
        ReadingTermConverter.convert(
          '這套軟體佔用大量記憶體，連上網路後可更新。',
          TermConversionMode.toMainland,
        ),
        contains('内存'),
      );
      expect(
        ReadingTermConverter.convert(
          '這套軟體佔用大量記憶體，連上網路後可更新。',
          TermConversionMode.toMainland,
        ),
        contains('网络'),
      );
    });

    test('toTaiwan converts mainland forms', () {
      expect(
        ReadingTermConverter.convert('意大利', TermConversionMode.toTaiwan),
        '義大利',
      );
      expect(
        ReadingTermConverter.convert('冰淇淋', TermConversionMode.toTaiwan),
        '霜淇淋',
      );
      expect(
        ReadingTermConverter.convert('冰激凌', TermConversionMode.toTaiwan),
        '霜淇淋',
      );
      expect(
        ReadingTermConverter.convert('软件与网络', TermConversionMode.toTaiwan),
        '軟體与網路',
      );
    });

    test('prefers longer matches', () {
      expect(
        ReadingTermConverter.convert('智慧型手機', TermConversionMode.toMainland),
        '智能手机',
      );
      expect(
        ReadingTermConverter.convert('網際網路', TermConversionMode.toMainland),
        '互联网',
      );
    });
  });
}
