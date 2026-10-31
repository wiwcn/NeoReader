import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/reading_theme.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/book.dart';
import 'domain/models/reading_stats.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/settings/settings_hub_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/widgets/empty_library.dart';
import 'presentation/widgets/glass_scaffold_bg.dart';

/// Dev gallery for capturing real UI screenshots (web/desktop).
void main() {
  GlassSurface.useFrostedBlur = false;
  runApp(const ProviderScope(child: _GalleryApp()));
}

final demoBooks = [
  Book(
    id: '1',
    title: '月光小径',
    author: '艾达·河',
    format: BookFormat.fb2,
    filePath: '/tmp/story.fb2',
    progress: 0.35,
    addedAt: DateTime(2026, 10, 1),
    lastReadAt: DateTime(2026, 10, 31),
  ),
  Book(
    id: '2',
    title: 'NeoReader Markdown 指南',
    author: 'Markdown',
    format: BookFormat.md,
    filePath: '/tmp/guide.md',
    progress: 0.6,
    addedAt: DateTime(2026, 10, 2),
  ),
  Book(
    id: '3',
    title: '欢迎使用 NeoReader',
    author: '未知作者',
    format: BookFormat.txt,
    filePath: '/tmp/welcome.txt',
    progress: 0.1,
    addedAt: DateTime(2026, 10, 3),
  ),
  Book(
    id: '4',
    title: '演示漫画',
    author: 'Comic',
    format: BookFormat.cbz,
    filePath: '/tmp/demo.cbz',
    progress: 0.5,
    addedAt: DateTime(2026, 10, 4),
  ),
  Book(
    id: '5',
    title: '离线阅读短论',
    author: 'NeoReader Demo',
    format: BookFormat.html,
    filePath: '/tmp/essay.html',
    progress: 0.2,
    addedAt: DateTime(2026, 10, 5),
  ),
];

class _GalleryApp extends StatelessWidget {
  const _GalleryApp();

  @override
  Widget build(BuildContext context) {
    const settings = AppSettings(themeMode: AppThemeModePref.light, localeCode: 'zh');
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => _FixedSettings(settings)),
        libraryProvider.overrideWith(() => _FixedLibrary(demoBooks)),
        filteredLibraryProvider.overrideWith((ref) => AsyncData(demoBooks)),
        statsSummaryProvider.overrideWith(
          (ref) async => const ReadingStatsSummary(
            todaySeconds: 42 * 60,
            totalSeconds: 5 * 3600 + 20 * 60,
            booksStarted: 4,
            booksFinished: 1,
            perBookSeconds: {'1': 3600, '2': 1800, '3': 900, '4': 1200},
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NeoReader Screenshots',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        routes: {
          '/': (_) => const _Index(),
          '/empty': (_) => GlassScaffoldBackground(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: GlassAppBar(title: const Text('书库')),
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('导入'),
                  ),
                  body: EmptyLibrary(strings: AppStrings(true)),
                ),
              ),
          '/library': (_) => const LibraryScreen(),
          '/stats': (_) => const StatsScreen(),
          '/settings': (_) => const SettingsHubScreen(),
          '/reader': (_) {
            final colors = ReadingColors.of(ReadingThemeMode.sepia);
            return Scaffold(
              backgroundColor: colors.background,
              appBar: AppBar(
                backgroundColor: colors.background.withValues(alpha: 0.92),
                foregroundColor: colors.foreground,
                title: const Text('欢迎使用 NeoReader'),
                actions: const [Icon(Icons.tune_rounded), SizedBox(width: 12)],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                child: Text(
                  'NeoReader — 欢迎\n\n'
                  'NeoReader 是一款纯离线电子书阅读器，采用 Material Design 3 '
                  '与毛玻璃界面。\n\n'
                  '支持：EPUB、PDF、TXT、MOBI/AZW3、FB2、CBZ、Markdown、HTML、DOCX。\n\n'
                  '一切数据留在本机 — 无账号、无云同步。',
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 18,
                    height: 1.6,
                    fontFamily: AppTheme.fontFamily,
                    fontFamilyFallback: AppTheme.fontFamilyFallback,
                  ),
                ),
              ),
              bottomNavigationBar: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: LinearProgressIndicator(value: 0.22),
                ),
              ),
            );
          },
        },
      ),
    );
  }
}

class _Index extends StatelessWidget {
  const _Index();
  @override
  Widget build(BuildContext context) {
    final routes = ['/empty', '/library', '/stats', '/settings', '/reader'];
    return Scaffold(
      appBar: AppBar(title: const Text('NeoReader screenshot gallery')),
      body: ListView(
        children: [
          for (final r in routes)
            ListTile(
              title: Text(r),
              onTap: () => Navigator.pushNamed(context, r),
            ),
        ],
      ),
    );
  }
}

class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;
  @override
  Future<AppSettings> build() async => _settings;
}

class _FixedLibrary extends LibraryNotifier {
  _FixedLibrary(this._books);
  final List<Book> _books;
  @override
  Future<List<Book>> build() async => _books;
}
