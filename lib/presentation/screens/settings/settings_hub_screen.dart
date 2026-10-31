import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';
import 'settings_about_page.dart';
import 'settings_appearance_page.dart';
import 'settings_library_page.dart';
import 'settings_privacy_page.dart';
import 'settings_reading_page.dart';
import 'settings_stats_page.dart';

enum _SettingsCategory {
  appearance,
  reading,
  library,
  privacy,
  stats,
  about,
}

class _Cat {
  const _Cat(this.type, this.icon, this.title, this.subtitle);
  final _SettingsCategory type;
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Top-level settings list (PiliPlus-style): categories push sub-pages on phone;
/// tablet/landscape uses a master–detail split.
class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  _SettingsCategory _selected = _SettingsCategory.appearance;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final size = MediaQuery.sizeOf(context);
    final isPortrait = size.width < 840;

    final items = [
      _Cat(
        _SettingsCategory.appearance,
        Icons.palette_outlined,
        strings.settingsAppearance,
        strings.settingsAppearanceSub,
      ),
      _Cat(
        _SettingsCategory.reading,
        Icons.menu_book_outlined,
        strings.settingsReading,
        strings.settingsReadingSub,
      ),
      _Cat(
        _SettingsCategory.library,
        Icons.library_books_outlined,
        strings.settingsLibrary,
        strings.settingsLibrarySub,
      ),
      _Cat(
        _SettingsCategory.privacy,
        Icons.privacy_tip_outlined,
        strings.settingsPrivacy,
        strings.settingsPrivacySub,
      ),
      _Cat(
        _SettingsCategory.stats,
        Icons.insights_outlined,
        strings.settingsStats,
        strings.settingsStatsSub,
      ),
      _Cat(
        _SettingsCategory.about,
        Icons.info_outline,
        strings.about,
        strings.settingsAboutSub,
      ),
    ];

    final list = _buildList(context, items, isPortrait);

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(
            isPortrait
                ? strings.settings
                : items.firstWhere((e) => e.type == _selected).title,
          ),
        ),
        body: isPortrait
            ? list
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: list),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                  ),
                  Expanded(
                    flex: 6,
                    child: _pageFor(_selected, showAppBar: false),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<_Cat> items, bool isPortrait) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium!;
    final subStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: (!isPortrait && item.type == _selected)
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.65)
                  : theme.colorScheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title, style: titleStyle),
                subtitle: Text(item.subtitle, style: subStyle),
                trailing: isPortrait
                    ? const Icon(Icons.chevron_right_rounded)
                    : null,
                onTap: () {
                  if (isPortrait) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _pageFor(item.type, showAppBar: true),
                      ),
                    );
                  } else {
                    setState(() => _selected = item.type);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _pageFor(_SettingsCategory type, {required bool showAppBar}) {
    return switch (type) {
      _SettingsCategory.appearance =>
        SettingsAppearancePage(showAppBar: showAppBar),
      _SettingsCategory.reading => SettingsReadingPage(showAppBar: showAppBar),
      _SettingsCategory.library => SettingsLibraryPage(showAppBar: showAppBar),
      _SettingsCategory.privacy => SettingsPrivacyPage(showAppBar: showAppBar),
      _SettingsCategory.stats => SettingsStatsPage(showAppBar: showAppBar),
      _SettingsCategory.about => SettingsAboutPage(showAppBar: showAppBar),
    };
  }
}

/// Kept for golden/screenshot imports that still reference the old name.
typedef SettingsScreen = SettingsHubScreen;
