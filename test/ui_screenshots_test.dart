import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/core/l10n/app_strings.dart';
import 'package:neo_reader/core/theme/app_theme.dart';
import 'package:neo_reader/core/theme/reading_theme.dart';
import 'package:neo_reader/domain/models/annotation.dart';
import 'package:neo_reader/domain/models/app_settings.dart';
import 'package:neo_reader/domain/models/book.dart';
import 'package:neo_reader/domain/models/reading_stats.dart';
import 'package:neo_reader/presentation/providers/providers.dart';
import 'package:neo_reader/presentation/screens/annotations/annotations_screen.dart';
import 'package:neo_reader/presentation/screens/library/library_screen.dart';
import 'package:neo_reader/presentation/screens/library/book_details_page.dart';
import 'package:neo_reader/presentation/screens/library/book_edit_sheet.dart';
import 'package:neo_reader/presentation/screens/library/book_actions_sheet.dart';
import 'package:neo_reader/domain/repositories/book_repository.dart';
import 'package:neo_reader/presentation/screens/settings/settings_hub_screen.dart';
import 'package:neo_reader/presentation/screens/stats/stats_screen.dart';
import 'package:neo_reader/presentation/widgets/empty_library.dart';
import 'package:neo_reader/presentation/widgets/glass_scaffold_bg.dart';

Future<void> _loadMaterialIcons() async {
  // flutter_test uses Ahem by default; Material Icons need the real glyph font.
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  File? fontFile;
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) {
      fontFile = f;
      break;
    }
  }
  if (fontFile == null) return;
  final bytes = await fontFile.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlassSurface.useFrostedBlur = false;
    // flutter_test defaults to Ahem (all □). Load bundled CJK face for readable goldens.
    final loader = FontLoader(AppTheme.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Medium.ttf'));
    await loader.load();
    await _loadMaterialIcons();
  });

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


  final demoAnnotations = [
    Annotation(
      id: 'a1',
      bookId: '1',
      type: AnnotationType.highlight,
      createdAt: DateTime(2026, 10, 20),
      chapter: '第一章',
      selectedText: '竖排与自定义字体让阅读更贴近纸书。',
      progress: 0.12,
    ),
    Annotation(
      id: 'a2',
      bookId: '2',
      type: AnnotationType.note,
      createdAt: DateTime(2026, 10, 21),
      note: '导出为 Markdown / TXT 方便备份。',
      progress: 0.4,
    ),
    Annotation(
      id: 'a3',
      bookId: '1',
      type: AnnotationType.bookmark,
      createdAt: DateTime(2026, 10, 22),
      chapter: '书签位置',
      progress: 0.55,
    ),
  ];

  Future<void> pumpPhone(
    WidgetTester tester,
    Widget home, {
    AppSettings settings = const AppSettings(
      themeMode: AppThemeModePref.light,
      localeCode: 'zh',
    ),
  }) async {
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
              perBookSeconds: {'1': 3600, '2': 1800, '3': 900, '4': 1200},
              currentStreakDays: 3,
              last7DaysSeconds: [600, 0, 1200, 900, 1800, 2400, 2520],
            ),
          ),
          allAnnotationsProvider.overrideWith((ref) async => demoAnnotations),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: home,
        ),
      ),
    );
    await tester.pump();
    // Settle staggered / progress animations for stable goldens.
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('chinese labels readable', (tester) async {
    await pumpPhone(tester, const SettingsHubScreen());
    expect(find.textContaining('外观'), findsWidgets);
    expect(find.textContaining('阅读'), findsWidgets);
    expect(find.text('书库与导入'), findsOneWidget);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('隐私与安全'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
  });

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
    await tester.pump(const Duration(milliseconds: 100));
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
    await pumpPhone(tester, const SettingsHubScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/05_settings.png'),
    );
  });

  testWidgets('07_library_grid', (tester) async {
    await pumpPhone(
      tester,
      const LibraryScreen(),
      settings: const AppSettings(
        themeMode: AppThemeModePref.light,
        localeCode: 'zh',
        libraryLayout: LibraryLayout.grid,
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07_library_grid.png'),
    );
  });

  testWidgets('08_annotations_export', (tester) async {
    await pumpPhone(tester, const AnnotationsScreen());
    expect(find.text('导出'), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/08_annotations_export.png'),
    );
  });

  testWidgets('09_book_edit_sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final book = demoBooks.first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => _FixedSettings(
              const AppSettings(
                themeMode: AppThemeModePref.light,
                localeCode: 'zh',
              ),
            ),
          ),
          libraryProvider.overrideWith(() => _FixedLibrary(demoBooks)),
          bookRepositoryProvider.overrideWithValue(_FakeBookRepo(demoBooks)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: GlassScaffoldBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: BookEditSheet(book: book),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('编辑信息'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/09_book_edit_sheet.png'),
    );
  });

  testWidgets('10_book_actions_sheet', (tester) async {
    await pumpPhone(tester, const LibraryScreen());
    final book = demoBooks.first;
    final navigator = tester.element(find.byType(LibraryScreen));
    showBookActionsSheet(
      navigator,
      book: book,
      strings: AppStrings(true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('编辑信息'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/10_book_actions_sheet.png'),
    );
  });

  testWidgets('11_book_details_slim', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => _FixedSettings(
              const AppSettings(
                themeMode: AppThemeModePref.light,
                localeCode: 'zh',
              ),
            ),
          ),
          libraryProvider.overrideWith(() => _FixedLibrary(demoBooks)),
          bookRepositoryProvider.overrideWithValue(_FakeBookRepo(demoBooks)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const BookDetailsPage(bookId: '1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('书籍详情'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/11_book_details_slim.png'),
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
            title: const Text('欢迎使用 NeoReader'),
            actions: const [Icon(Icons.tune_rounded), SizedBox(width: 12)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 48),
            child: Text(
              'NeoReader — 欢迎\n\n'
              'NeoReader 是一款纯离线电子书阅读器，采用 Material Design 3 '
              '与毛玻璃界面。\n\n'
              '支持：EPUB、PDF、TXT、MOBI/AZW3、FB2、CBZ、Markdown、HTML、DOCX。\n\n'
              '一切数据留在本机 — 无账号、无云同步。',
              style: TextStyle(
                color: colors.foreground,
                fontSize: 19,
                height: 1.75,
                fontFamily: AppTheme.fontFamily,
                fontFamilyFallback: AppTheme.fontFamilyFallback,
                letterSpacing: 0.15,
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

class _FakeBookRepo implements BookRepository {
  _FakeBookRepo(this._books);
  final List<Book> _books;

  @override
  Future<List<Book>> getAll() async => _books;

  @override
  Future<Book?> getById(String id) async {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<void> upsert(Book book) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> updateProgress(
    String id,
    double progress,
    String? location,
  ) async {}
}
