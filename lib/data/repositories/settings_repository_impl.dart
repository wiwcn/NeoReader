import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/reading_theme.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kLocale = 'locale';
  static const _kTheme = 'theme_mode';
  static const _kFont = 'font_size';
  static const _kLine = 'line_height';
  static const _kReading = 'reading_theme';
  static const _kSeed = 'seed_color';

  @override
  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      localeCode: p.getString(_kLocale) ?? 'zh',
      themeMode: AppThemeModePref.values.firstWhere(
        (e) => e.name == p.getString(_kTheme),
        orElse: () => AppThemeModePref.system,
      ),
      fontSize: p.getDouble(_kFont) ?? 18,
      lineHeight: p.getDouble(_kLine) ?? 1.6,
      readingTheme: ReadingThemeMode.values.firstWhere(
        (e) => e.name == p.getString(_kReading),
        orElse: () => ReadingThemeMode.day,
      ),
      seedColorValue: p.getInt(_kSeed) ?? 0xFF2E7D32,
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
  }
}
