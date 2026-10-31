import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../annotations/annotations_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final pages = const [
      LibraryScreen(),
      AnnotationsScreen(),
      StatsScreen(),
      SettingsScreen(),
    ];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.local_library_outlined),
              selectedIcon: const Icon(Icons.local_library_rounded),
              label: strings.library,
            ),
            NavigationDestination(
              icon: const Icon(Icons.sticky_note_2_outlined),
              selectedIcon: const Icon(Icons.sticky_note_2_rounded),
              label: strings.annotations,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: strings.stats,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: strings.settings,
            ),
          ],
        ),
      ),
    );
  }
}
