import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  /// Reserve icon + two lines of value + label so all four tiles match, even
  /// when「12 小时 40 分钟」wraps while「5」does not.
  double _statMinHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final text = Theme.of(context).textTheme;
    final value = text.headlineSmall;
    final label = text.bodySmall;
    return 36 +
        12 +
        scaler.scale(value?.fontSize ?? 24) * (value?.height ?? 1.28) * 2 +
        2 +
        scaler.scale(label?.fontSize ?? 12) * (label?.height ?? 1.45);
  }

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _statRow(
                  _statCard(
                    context,
                    strings.todayReading,
                    _fmt(s.todaySeconds, isZh: isZh),
                    Icons.today_rounded,
                  ),
                  _statCard(
                    context,
                    strings.totalReading,
                    _fmt(s.totalSeconds, isZh: isZh),
                    Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                _statRow(
                  _statCard(
                    context,
                    strings.booksInProgress,
                    '${s.booksStarted}',
                    Icons.menu_book_rounded,
                  ),
                  _statCard(
                    context,
                    isZh ? '已读完' : 'Finished',
                    '${s.booksFinished}',
                    Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                SolidCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatMedallion(
                        icon: Icons.local_fire_department_rounded,
                        size: 44,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.currentStreakDays} ${strings.streakDays}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.readingStreak,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SolidCard(
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
                const SizedBox(height: 12),
                SolidCard(
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
                                : LinearProgressIndicator(
                                    value: book.progress.clamp(0, 1),
                                  ),
                            trailing: Text(_fmt(e.value, isZh: isZh)),
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
    return SolidCard(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _statMinHeight(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatMedallion(icon: icon),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall,
              maxLines: 2,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Side-by-side tiles must share one height, not centre against each other.
  Widget _statRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Small tonal icon chip used by stat tiles — MD3 primary-container pairing.
class _StatMedallion extends StatelessWidget {
  const _StatMedallion({
    required this.icon,
    this.size = 36,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: cs.onPrimaryContainer),
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
