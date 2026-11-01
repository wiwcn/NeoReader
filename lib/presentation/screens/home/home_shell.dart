import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/demo_seed_service.dart';
import '../../../music/providers/music_providers.dart';
import '../../../music/ui/mini_player.dart';
import '../../../music/ui/music_home_screen.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../library/comic_library_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_hub_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(settingsProvider.future);
      if (mounted) {
        ref.read(librarySortProvider.notifier).state = settings.defaultSort;
      }
      final n = await DemoSeedService().seedIfNeeded();
      if (n > 0 && mounted) {
        await ref.read(libraryProvider.notifier).refresh();
      }
      // Warm music audio session (DAC-friendly attributes) without blocking UI.
      ref.read(musicHandlerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(musicStringsProvider);
    final hasMini = ref.watch(currentTrackProvider) != null;

    final pages = const [
      LibraryScreen(),
      ComicLibraryScreen(),
      MusicHomeScreen(),
      SettingsHubScreen(),
    ];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: FadeIndexedStack(index: _index, children: pages),
            ),
            if (hasMini) const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
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
              icon: const Icon(Icons.more_horiz_rounded),
              selectedIcon: const Icon(Icons.more_horiz_rounded),
              label: music.more,
            ),
          ],
        ),
      ),
    );
  }
}
