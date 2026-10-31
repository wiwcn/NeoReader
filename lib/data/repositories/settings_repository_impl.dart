import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/reading_theme.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kLocale = 'locale';
  static const _kTheme = 'theme_mode';
  static const _kFont = 'font_size';
  static const _kLine = 'line_height';
  static const _kReading = 'reading_theme';
  static const _kSeed = 'seed_color';
  static const _kGlass = 'glass_blur';
  static const _kPageTurn = 'page_turn';
  static const _kWriting = 'writing_mode';
  static const _kCustomFont = 'custom_font_family';
  static const _kMargin = 'horizontal_margin';
  static const _kPara = 'paragraph_spacing';
  static const _kSort = 'default_sort';
  static const _kPin = 'library_pin';
  static const _kShowDuration = 'show_reading_duration';

  @override
  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      localeCode: p.getString(_kLocale) ?? 'zh',
      themeMode: AppThemeModePref.values.firstWhere(
        (e) => e.name == p.getString(_kTheme),
        orElse: () => AppThemeModePref.system,
      ),
      fontSize: p.getDouble(_kFont) ?? 19,
      lineHeight: p.getDouble(_kLine) ?? 1.75,
      readingTheme: ReadingThemeMode.values.firstWhere(
        (e) => e.name == p.getString(_kReading),
        orElse: () => ReadingThemeMode.day,
      ),
      seedColorValue: p.getInt(_kSeed) ?? 0xFF2E7D32,
      glassBlur: p.getDouble(_kGlass) ?? 1.0,
      pageTurnMode: PageTurnMode.values.firstWhere(
        (e) => e.name == p.getString(_kPageTurn),
        orElse: () => PageTurnMode.scroll,
      ),
      writingMode: WritingMode.values.firstWhere(
        (e) => e.name == p.getString(_kWriting),
        orElse: () => WritingMode.horizontal,
      ),
      customFontFamily: p.getString(_kCustomFont),
      horizontalMargin: p.getDouble(_kMargin) ?? 22,
      paragraphSpacing: p.getDouble(_kPara) ?? 14,
      defaultSort: BookSort.values.firstWhere(
        (e) => e.name == p.getString(_kSort),
        orElse: () => BookSort.added,
      ),
      libraryPinEnabled: p.getBool(_kPin) ?? false,
      showReadingDuration: p.getBool(_kShowDuration) ?? true,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, settings.localeCode);
    await p.setString(_kTheme, settings.themeMode.name);
    await p.setDouble(_kFont, settings.fontSize);
    await p.setDouble(_kLine, settings.lineHeight);
    await p.setString(_kReading, settings.readingTheme.name);
    await p.setInt(_kSeed, settings.seedColorValue);
    await p.setDouble(_kGlass, settings.glassBlur);
    await p.setString(_kPageTurn, settings.pageTurnMode.name);
    await p.setString(_kWriting, settings.writingMode.name);
    if (settings.customFontFamily == null ||
        settings.customFontFamily!.isEmpty) {
      await p.remove(_kCustomFont);
    } else {
      await p.setString(_kCustomFont, settings.customFontFamily!);
    }
    await p.setDouble(_kMargin, settings.horizontalMargin);
    await p.setDouble(_kPara, settings.paragraphSpacing);
    await p.setString(_kSort, settings.defaultSort.name);
    await p.setBool(_kPin, settings.libraryPinEnabled);
    await p.setBool(_kShowDuration, settings.showReadingDuration);
  }
}
