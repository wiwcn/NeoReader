import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/core/l10n/app_strings.dart';
import 'package:neo_reader/core/theme/app_theme.dart';
import 'package:neo_reader/core/theme/reading_theme.dart';
import 'package:neo_reader/domain/models/app_settings.dart';
import 'package:neo_reader/domain/models/book.dart';
import 'package:neo_reader/domain/models/reading_stats.dart';
import 'package:neo_reader/music/data/waveform_cache.dart';
import 'package:neo_reader/music/models/play_mode.dart';
import 'package:neo_reader/music/models/playlist.dart';
import 'package:neo_reader/music/models/track.dart';
import 'package:neo_reader/music/player/music_audio_handler.dart';
import 'package:neo_reader/music/providers/music_providers.dart';
import 'package:neo_reader/music/ui/mini_player.dart';
import 'package:neo_reader/music/ui/music_home_screen.dart';
import 'package:neo_reader/music/ui/now_playing_page.dart';
import 'package:neo_reader/presentation/providers/providers.dart';
import 'package:neo_reader/presentation/screens/library/comic_library_screen.dart';
import 'package:neo_reader/presentation/screens/library/library_screen.dart';
import 'package:neo_reader/presentation/screens/settings/settings_hub_screen.dart';
import 'package:neo_reader/presentation/screens/stats/stats_screen.dart';
import 'package:neo_reader/presentation/screens/reader/reading_controls.dart';
import 'package:neo_reader/presentation/widgets/empty_library.dart';
import 'package:neo_reader/presentation/widgets/glass_scaffold_bg.dart';
import 'package:neo_reader/presentation/widgets/motion.dart';

/// Tall phone logical size (~19.5:9). PNG export uses pixelRatio 3 → ~1080×2340.
const _phoneSize = Size(360, 780);
const _pixelRatio = 3.0;

final _outDir = Directory(
  '/workspace/koodo-flutter-offline-app/docs/screenshots',
);
const _coverDirPath =
    '/workspace/koodo-flutter-offline-app/test/fixtures/music_covers';

Float32List _syntheticPeaks({int n = 800, int seed = 7}) {
  final rnd = math.Random(seed);
  final peaks = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / n;
    final envelope = 0.35 + 0.65 * math.sin(math.pi * t).abs();
    final beat = (math.sin(t * math.pi * 32).abs() * 0.55 + 0.2);
    peaks[i] = (envelope * beat * (0.55 + 0.45 * rnd.nextDouble()))
        .clamp(0.05, 1.0)
        .toDouble();
  }
  return peaks;
}

List<Book> _demoBooks() => [
      Book(
        id: '1',
        title: '月光小径',
        author: '艾达·河',
        format: BookFormat.epub,
        filePath: '/tmp/moon.epub',
        progress: 0.42,
        addedAt: DateTime(2026, 9, 12),
        lastReadAt: DateTime(2026, 10, 28),
      ),
      Book(
        id: '2',
        title: '二十四节气笔记',
        author: '林晓荷',
        format: BookFormat.txt,
        filePath: '/tmp/jieqi.txt',
        progress: 0.68,
        addedAt: DateTime(2026, 9, 20),
        lastReadAt: DateTime(2026, 10, 30),
      ),
      Book(
        id: '3',
        title: '星河入梦',
        author: '陈思远',
        format: BookFormat.fb2,
        filePath: '/tmp/xinghe.fb2',
        progress: 0.18,
        addedAt: DateTime(2026, 10, 1),
        lastReadAt: DateTime(2026, 10, 22),
      ),
      Book(
        id: '4',
        title: '海边的风',
        author: 'Mira Lane',
        format: BookFormat.md,
        filePath: '/tmp/wind.md',
        progress: 0.55,
        addedAt: DateTime(2026, 10, 5),
      ),
      Book(
        id: '5',
        title: '夜色漫游',
        author: 'Nova Pulse',
        format: BookFormat.cbz,
        filePath: '/tmp/night.cbz',
        progress: 0.33,
        addedAt: DateTime(2026, 10, 8),
        lastReadAt: DateTime(2026, 10, 29),
      ),
      Book(
        id: '6',
        title: '城市灯火',
        author: '艾达·河',
        format: BookFormat.cbz,
        filePath: '/tmp/city.cbz',
        progress: 0.12,
        addedAt: DateTime(2026, 10, 12),
      ),
    ];

List<Track> _demoTracks() {
  final covers = [
    for (var i = 1; i <= 6; i++) '$_coverDirPath/cover$i.png',
  ];
  final specs = <(String, String, String, String, int, bool)>[
    ('t1', '月光奏鸣曲', '陈思远', '夜色钢琴', 214000, true),
    ('t2', 'City Lights', 'Nova Pulse', 'Neon Nights', 198000, false),
    ('t3', '江南雨', '林晓荷', '二十四节气', 241000, false),
    ('t4', 'Afterglow', 'Mira Lane', 'Neon Nights', 186000, true),
    ('t5', '星河入梦', '陈思远', '夜色钢琴', 256000, false),
    ('t6', 'Blueprint', 'Nova Pulse', 'Studio Sessions', 203000, false),
    ('t7', '海边的风', '林晓荷', '二十四节气', 229000, false),
    ('t8', 'Soft Static', 'Mira Lane', 'Studio Sessions', 175000, false),
  ];
  return [
    for (var i = 0; i < specs.length; i++)
      Track(
        id: specs[i].$1,
        path: '/tmp/demo_music/${specs[i].$1}.mp3',
        title: specs[i].$2,
        artist: specs[i].$3,
        album: specs[i].$4,
        durationMs: specs[i].$5,
        coverPath: covers[i % covers.length],
        trackNumber: i + 1,
        year: 2024,
        genre: i.isEven ? 'Indie' : '流行',
        fileSize: 4_000_000 + i * 111,
        mtimeMs: 1_700_000_000_000 + i,
        addedAt: DateTime(2026, 10, 1 + i),
        isFavorite: specs[i].$6,
      ),
  ];
}

Future<void> _loadFonts() async {
  final loader = FontLoader(AppTheme.fontFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Medium.ttf'));
  await loader.load();

  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final bytes = await f.readAsBytes();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await icons.load();
    break;
  }
}

Future<void> _savePng(WidgetTester tester, String filename) async {
  _outDir.createSync(recursive: true);
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('product-shot-root')),
  );
  final out = File('${_outDir.path}/$filename');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

List<Override> _baseOverrides({
  required List<Book> books,
  required List<Track> tracks,
  required AppSettings settings,
  bool withMusicQueue = true,
}) {
  return [
    settingsProvider.overrideWith(() => _FixedSettings(settings)),
    libraryProvider.overrideWith(() => _FixedLibrary(books)),
    filteredLibraryProvider.overrideWith((ref) => AsyncData(books)),
    statsSummaryProvider.overrideWith(
      (ref) async => const ReadingStatsSummary(
        todaySeconds: 48 * 60,
        totalSeconds: 12 * 3600 + 40 * 60,
        booksStarted: 5,
        booksFinished: 2,
        perBookSeconds: {
          '1': 4200,
          '2': 3600,
          '3': 1800,
          '4': 2100,
          '5': 1500,
        },
        currentStreakDays: 5,
        last7DaysSeconds: [900, 1200, 600, 1800, 2400, 2100, 2880],
      ),
    ),
    musicLibraryProvider.overrideWith(() => _FixedMusicLibrary(tracks)),
    playlistsProvider.overrideWith(
      () => _FixedPlaylists([
        Playlist(
          id: 'pl1',
          name: '通勤精选',
          createdAt: DateTime(2026, 9, 1),
          trackIds: tracks.take(4).map((t) => t.id).toList(),
        ),
        Playlist(
          id: 'pl2',
          name: 'Focus Mix',
          createdAt: DateTime(2026, 9, 10),
          trackIds: tracks.skip(2).take(3).map((t) => t.id).toList(),
        ),
      ]),
    ),
    musicHandlerProvider.overrideWith(
      (ref) => Completer<MusicAudioHandler>().future,
    ),
    if (withMusicQueue) ...[
      playerQueueProvider.overrideWith((ref) async* {
        yield tracks;
      }),
      playerIndexProvider.overrideWith((ref) async* {
        yield 0;
      }),
      playerPlayingProvider.overrideWith((ref) async* {
        yield true;
      }),
      playerPositionProvider.overrideWith((ref) async* {
        yield const Duration(minutes: 1, seconds: 12);
      }),
      playerDurationProvider.overrideWith((ref) async* {
        yield Duration(milliseconds: tracks.first.durationMs);
      }),
      playerModeProvider.overrideWith((ref) async* {
        yield PlayMode.listLoop;
      }),
    ] else ...[
      playerQueueProvider.overrideWith((ref) async* {
        yield const <Track>[];
      }),
      playerIndexProvider.overrideWith((ref) async* {
        yield 0;
      }),
      playerPlayingProvider.overrideWith((ref) async* {
        yield false;
      }),
      playerPositionProvider.overrideWith((ref) async* {
        yield Duration.zero;
      }),
      playerDurationProvider.overrideWith((ref) async* {
        yield null;
      }),
      playerModeProvider.overrideWith((ref) async* {
        yield PlayMode.listLoop;
      }),
    ],
  ];
}

Future<void> _pumpShot(
  WidgetTester tester, {
  required Widget home,
  required bool dark,
  required List<Book> books,
  required List<Track> tracks,
  bool withMusicQueue = true,
  LibraryLayout layout = LibraryLayout.list,
}) async {
  await tester.binding.setSurfaceSize(_phoneSize);
  tester.view.physicalSize = Size(
    _phoneSize.width * _pixelRatio,
    _phoneSize.height * _pixelRatio,
  );
  tester.view.devicePixelRatio = _pixelRatio;

  final settings = AppSettings(
    themeMode: dark ? AppThemeModePref.dark : AppThemeModePref.light,
    localeCode: 'zh',
    libraryLayout: layout,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: _baseOverrides(
        books: books,
        tracks: tracks,
        settings: settings,
        withMusicQueue: withMusicQueue,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              disableAnimations: true,
              size: _phoneSize,
              devicePixelRatio: _pixelRatio,
              padding: const EdgeInsets.only(top: 28, bottom: 16),
            ),
            child: RepaintBoundary(
              key: const ValueKey('product-shot-root'),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Product shell mirroring HomeShell without DemoSeedService side effects.
class _ShotShell extends ConsumerStatefulWidget {
  const _ShotShell({required this.initialIndex, this.showMini = true});

  final int initialIndex;
  final bool showMini;

  @override
  ConsumerState<_ShotShell> createState() => _ShotShellState();
}

class _ShotShellState extends ConsumerState<_ShotShell> {
  late int _index = widget.initialIndex;

  static const _pages = <Widget>[
    LibraryScreen(),
    ComicLibraryScreen(),
    MusicHomeScreen(),
    SettingsHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(musicStringsProvider);
    final strings = ref.watch(stringsProvider);
    final hasMini = widget.showMini && ref.watch(currentTrackProvider) != null;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeIndexedStack(index: _index, children: _pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMini) const MiniPlayer(),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book_rounded),
                  label: music.novel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories_rounded),
                  label: music.comic,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.library_music_outlined),
                  selectedIcon: const Icon(Icons.library_music_rounded),
                  label: music.music,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: strings.settings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _readerGlassPage({required bool dark}) {
  final mode = dark ? ReadingThemeMode.night : ReadingThemeMode.sepia;
  final colors = ReadingColors.of(mode);
  final settings = AppSettings(
    themeMode: dark ? AppThemeModePref.dark : AppThemeModePref.light,
    localeCode: 'zh',
    readingTheme: mode,
    fontSize: 19,
  );
  return Scaffold(
    backgroundColor: colors.background,
    body: Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: colors.background.withValues(alpha: 0.92),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, color: colors.foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '月光小径',
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    Icon(Icons.tune_rounded, color: colors.foreground),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 160),
                  child: Text(
                    '第一章　月下\n\n'
                    '河对岸的灯火一盏接一盏地亮起来。风从芦苇间穿过，'
                    '带着一点潮湿的泥土味。她把书合上，指尖停在书脊，'
                    '仿佛还能听见纸页翻动时细碎的声响。\n\n'
                    '「今晚不赶路。」她轻声说。\n\n'
                    '远处的钟楼敲过九下。月光铺在石板上，像一层薄霜。'
                    '她沿着小径往前走，影子被拉得很长，直到拐进那扇'
                    '半掩的木门。',
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
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ReadingControlsSheet(
            strings: AppStrings(true),
            settings: settings,
            onChanged: (_) {},
          ),
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlassSurface.useFrostedBlur = false;
    await _loadFonts();
    final peaks = _syntheticPeaks();
    WaveformCache.debugPeaksOverride = ({
      required String path,
      required int mtimeMs,
      required int fileSize,
    }) =>
        peaks;
  });

  tearDownAll(() {
    WaveformCache.debugPeaksOverride = null;
  });

  final books = _demoBooks();
  final tracks = _demoTracks();

  for (final dark in [false, true]) {
    final prefix = dark ? 'dark' : 'light';

    testWidgets('${prefix}_shell_novels', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const _ShotShell(initialIndex: 0),
      );
      expect(find.textContaining('月光小径'), findsWidgets);
      await _savePng(tester, '${prefix}_shell_novels.png');
    });

    testWidgets('${prefix}_shell_comics', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const _ShotShell(initialIndex: 1),
      );
      expect(find.textContaining('夜色漫游'), findsWidgets);
      await _savePng(tester, '${prefix}_shell_comics.png');
    });

    testWidgets('${prefix}_shell_music', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const _ShotShell(initialIndex: 2),
      );
      expect(find.textContaining('月光奏鸣曲'), findsWidgets);
      await _savePng(tester, '${prefix}_shell_music.png');
    });

    testWidgets('${prefix}_shell_settings', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        withMusicQueue: false,
        home: const _ShotShell(initialIndex: 3, showMini: false),
      );
      expect(find.text('设置'), findsWidgets);
      await _savePng(tester, '${prefix}_shell_settings.png');
    });

    testWidgets('${prefix}_music_now_playing', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const NowPlayingPage(),
      );
      expect(find.textContaining('月光奏鸣曲'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 300));
      await _savePng(tester, '${prefix}_music_now_playing.png');
    });

    testWidgets('${prefix}_music_albums', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const MusicHomeScreen(),
      );
      await tester.tap(find.text('专辑'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Album titles may be truncated in grid; still capture the grid UI.
      await _savePng(tester, '${prefix}_music_albums.png');
    });

    testWidgets('${prefix}_music_miniplayer', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        home: const _ShotShell(initialIndex: 2, showMini: true),
      );
      expect(find.byType(MiniPlayer), findsOneWidget);
      await _savePng(tester, '${prefix}_music_miniplayer.png');
    });

    testWidgets('${prefix}_reader_glass', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        withMusicQueue: false,
        home: _readerGlassPage(dark: dark),
      );
      expect(find.textContaining('月光小径'), findsWidgets);
      await _savePng(tester, '${prefix}_reader_glass.png');
    });

    testWidgets('${prefix}_library_empty', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: const [],
        tracks: tracks,
        withMusicQueue: false,
        home: GlassScaffoldBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GlassAppBar(title: Text(AppStrings(true).isZh ? '小说' : 'Novels')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('导入'),
            ),
            body: EmptyLibrary(strings: AppStrings(true)),
          ),
        ),
      );
      await _savePng(tester, '${prefix}_library_empty.png');
    });

    testWidgets('${prefix}_stats', (tester) async {
      await _pumpShot(
        tester,
        dark: dark,
        books: books,
        tracks: tracks,
        withMusicQueue: false,
        home: const StatsScreen(),
      );
      await _savePng(tester, '${prefix}_stats.png');
    });
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

class _FixedMusicLibrary extends MusicLibraryNotifier {
  _FixedMusicLibrary(this._tracks);
  final List<Track> _tracks;
  @override
  Future<List<Track>> build() async => _tracks;

  @override
  Future<void> toggleFavorite(Track track) async {}
}

class _FixedPlaylists extends PlaylistsNotifier {
  _FixedPlaylists(this._items);
  final List<Playlist> _items;
  @override
  Future<List<Playlist>> build() async => _items;
}
