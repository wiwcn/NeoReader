import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/demo_seed_service.dart';
import '../../../data/services/music_seed_service.dart';
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

  static const _pages = <Widget>[
    LibraryScreen(),
    ComicLibraryScreen(),
    MusicHomeScreen(),
    SettingsHubScreen(),
  ];

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
      final musicN = await MusicSeedService().seedIfNeeded();
      if (musicN > 0 && mounted) {
        await ref.read(musicLibraryProvider.notifier).refresh();
      }
      // Warm music audio session (DAC-friendly attributes) without blocking UI.
      ref.read(musicHandlerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(musicStringsProvider);
    final strings = ref.watch(stringsProvider);
    final hasMini = ref.watch(currentTrackProvider) != null;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Full-bleed body; mini player lives in bottom chrome so FABs / lists
        // get the correct bottom inset and never cover tab labels.
        body: FadeIndexedStack(index: _index, children: _pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMini) const MiniPlayer(),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              // Theme tokens own frost; keep chrome from tint-morphing on theme switch.
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
