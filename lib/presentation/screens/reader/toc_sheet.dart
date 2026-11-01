import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';

class TocItem {
  const TocItem({
    required this.title,
    required this.index,
    this.level = 0,
  });

  final String title;

  /// Chapter / spine index to jump to.
  final int index;
  final int level;
}

Future<int?> showTocSheet({
  required BuildContext context,
  required AppStrings strings,
  required ReadingColors colors,
  required List<TocItem> items,
  int? currentIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SolidCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.toc,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: strings.cancel,
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            strings.tocEmpty,
                            style: TextStyle(
                              color: colors.foreground.withValues(alpha: 0.65),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final selected =
                                currentIndex != null &&
                                item.index == currentIndex;
                            return ListTile(
                              dense: true,
                              selected: selected,
                              contentPadding: EdgeInsets.only(
                                left: 16.0 + item.level * 14.0,
                                right: 16,
                              ),
                              title: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.foreground,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              trailing: selected
                                  ? Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                      color: Theme.of(ctx).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(ctx, item.index),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
