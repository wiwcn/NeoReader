import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  String _fmt(int seconds, {required bool isZh}) {
    if (seconds < 60) return isZh ? '$seconds 秒' : '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return isZh ? '$m 分钟' : '${m}m';
    final h = m ~/ 60;
    final rm = m % 60;
    return isZh ? '$h 小时 $rm 分钟' : '${h}h ${rm}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final summary = ref.watch(statsSummaryProvider);
    final books = ref.watch(libraryProvider).value ?? [];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.stats)),
        body: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (s) {
            final isZh = strings.isZh;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        strings.todayReading,
                        _fmt(s.todaySeconds, isZh: isZh),
                        Icons.today_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        strings.totalReading,
                        _fmt(s.totalSeconds, isZh: isZh),
                        Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        strings.booksInProgress,
                        '${s.booksStarted}',
                        Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        isZh ? '已读完' : 'Finished',
                        '${s.booksFinished}',
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassSurface(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.readingStreak,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.currentStreakDays} ${strings.streakDays}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.last7Days,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: _Last7DaysChart(
                          seconds: s.last7DaysSeconds,
                          isZh: isZh,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '各书阅读时长' : 'Time per book',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (s.perBookSeconds.isEmpty)
                        Text(
                          isZh
                              ? '暂无记录，打开一本书开始阅读即可累计。'
                              : 'No sessions yet. Open a book to track time.',
                        )
                      else
                        ...s.perBookSeconds.entries.map((e) {
                          final matches = books
                              .where((b) => b.id == e.key)
                              .toList();
                          final title = matches.isEmpty
                              ? e.key
                              : matches.first.title;
                          final book = matches.isEmpty ? null : matches.first;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: book == null
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: AnimatedProgressBar(
                                      value: book.progress,
                                      minHeight: 4,
                                    ),
                                  ),
                            trailing: Text(
                              _fmt(e.value, isZh: isZh),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Last7DaysChart extends StatelessWidget {
  const _Last7DaysChart({required this.seconds, required this.isZh});

  final List<int> seconds;
  final bool isZh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = seconds.length == 7 ? seconds : List<int>.filled(7, 0);
    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const zh = ['一', '二', '三', '四', '五', '六', '日'];
    final labels = isZh ? zh : en;

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelBand = 36.0;
        final available = (constraints.maxHeight - labelBand).clamp(40.0, 200.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final day = DateTime(
              today.year,
              today.month,
              today.day,
            ).subtract(Duration(days: 6 - i));
            final v = values[i];
            final frac = maxV <= 0 ? 0.0 : (v / maxV).clamp(0.0, 1.0);
            final barH = 8.0 + frac * (available - 8.0);
            final label = labels[(day.weekday - 1) % 7];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: barH,
                            decoration: BoxDecoration(
                              color: cs.primary
                                  .withValues(alpha: v > 0 ? 0.85 : 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        v <= 0 ? ' ' : (v < 60 ? '${v}s' : '${v ~/ 60}m'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
