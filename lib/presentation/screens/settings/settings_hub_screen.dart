import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
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

/// Settings hub: PiliPlus menu hierarchy (hub → subpages) with glass cards.
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
    final cs = theme.colorScheme;
    final titleStyle = theme.textTheme.titleMedium!;
    final subStyle = theme.textTheme.bodySmall!.copyWith(
      color: cs.onSurfaceVariant,
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        final selected = !isPortrait && item.type == _selected;
        return StaggeredFadeSlide(
          index: i,
          // Single GlassSurface per row — flat ink content inside.
          child: GlassSurface(
            borderRadius: 18,
            opacity: selected ? (cs.brightness == Brightness.dark ? 0.14 : 0.20) : null,
            child: Material(
              color: selected
                  ? cs.secondaryContainer.withValues(alpha: 0.35)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(item.icon, size: 22, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.title, style: titleStyle),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: subStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isPortrait)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
