import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/core/l10n/app_strings.dart';
import 'package:neo_reader/core/theme/app_theme.dart';
import 'package:neo_reader/core/theme/reading_theme.dart';
import 'package:neo_reader/domain/models/app_settings.dart';
import 'package:neo_reader/domain/models/book.dart';
import 'package:neo_reader/domain/models/reading_stats.dart';
import 'package:neo_reader/presentation/providers/providers.dart';
import 'package:neo_reader/presentation/screens/library/library_screen.dart';
import 'package:neo_reader/presentation/screens/settings/settings_screen.dart';
import 'package:neo_reader/presentation/screens/stats/stats_screen.dart';
import 'package:neo_reader/presentation/widgets/empty_library.dart';
import 'package:neo_reader/presentation/widgets/glass_scaffold_bg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GlassSurface.useFrostedBlur = false;
  });

  final demoBooks = [
    Book(
      id: '1',
      title: 'Moonlit Path',
      author: 'Ada River',
      format: BookFormat.fb2,
      filePath: '/tmp/story.fb2',
      progress: 0.35,
      addedAt: DateTime(2026, 10, 1),
      lastReadAt: DateTime(2026, 10, 31),
    ),
    Book(
      id: '2',
      title: 'NeoReader Markdown Guide',
      author: 'Markdown',
      format: BookFormat.md,
      filePath: '/tmp/guide.md',
      progress: 0.6,
      addedAt: DateTime(2026, 10, 2),
    ),
    Book(
      id: '3',
      title: 'Welcome',
      author: 'Unknown',
      format: BookFormat.txt,
      filePath: '/tmp/welcome.txt',
      progress: 0.1,
      addedAt: DateTime(2026, 10, 3),
    ),
    Book(
      id: '4',
      title: 'Demo Comic',
      author: 'Comic',
      format: BookFormat.cbz,
      filePath: '/tmp/demo.cbz',
      progress: 0.5,
      addedAt: DateTime(2026, 10, 4),
    ),
    Book(
      id: '5',
      title: 'A Short Essay on Offline Reading',
      author: 'NeoReader Demo',
      format: BookFormat.html,
      filePath: '/tmp/essay.html',
      progress: 0.2,
      addedAt: DateTime(2026, 10, 5),
    ),
  ];

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    const settings = AppSettings(
      themeMode: AppThemeModePref.light,
      localeCode: 'zh',
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
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
              perBookSeconds: {
                '1': 3600,
                '2': 1800,
                '3': 900,
                '4': 1200,
              },
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: home,
        ),
      ),
    );
    await tester.pump(); // one frame
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('01_library_empty', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GlassScaffoldBackground(
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
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_library_empty.png'),
    );
  });

  testWidgets('02_library_with_books', (tester) async {
    await pumpPhone(tester, const LibraryScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_library_with_books.png'),
    );
  });

  testWidgets('03_import_fab', (tester) async {
    await pumpPhone(tester, const LibraryScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03_import_fab.png'),
    );
  });

  testWidgets('04_stats', (tester) async {
    await pumpPhone(tester, const StatsScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/04_stats.png'),
    );
  });

  testWidgets('05_settings', (tester) async {
    await pumpPhone(tester, const SettingsScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/05_settings.png'),
    );
  });

  testWidgets('06_reader_txt_glass', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final colors = ReadingColors.of(ReadingThemeMode.sepia);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background.withValues(alpha: 0.92),
            foregroundColor: colors.foreground,
            title: const Text('Welcome'),
            actions: const [Icon(Icons.tune_rounded), SizedBox(width: 12)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            child: Text(
              'NeoReader — Welcome\n\n'
              'NeoReader is an offline ebook reader with Material Design 3 '
              'and frosted glass UI.\n\n'
              'Supported: EPUB, PDF, TXT, MOBI/AZW3, FB2, CBZ, Markdown, HTML, DOCX.\n\n'
              'Everything stays on device — no account, no cloud.',
              style: TextStyle(
                color: colors.foreground,
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
          bottomNavigationBar: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LinearProgressIndicator(value: 0.22),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06_reader_txt_glass.png'),
    );
  });
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
