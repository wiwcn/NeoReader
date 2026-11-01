import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../domain/models/book.dart';
import '../../widgets/book_cover.dart';

enum BookAction { details, edit, open, delete }

/// Compact Anx-style book overflow hub (icon + short label rows).
Future<BookAction?> showBookActionsSheet(
  BuildContext context, {
  required Book book,
  required AppStrings strings,
}) {
  return showModalBottomSheet<BookAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      const radius = BorderRadius.vertical(top: Radius.circular(28));
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: cs.surfaceContainerHigh,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                width: 0.75,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          BookCover(
                            book: book,
                            width: 40,
                            height: 52,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  book.author.isEmpty
                                      ? strings.unknownAuthor
                                      : book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.menu_book_rounded,
                      label: strings.openBook,
                      onTap: () => Navigator.pop(ctx, BookAction.open),
                    ),
                    _ActionTile(
                      icon: Icons.info_outline_rounded,
                      label: strings.bookDetails,
                      onTap: () => Navigator.pop(ctx, BookAction.details),
                    ),
                    _ActionTile(
                      icon: Icons.edit_outlined,
                      label: strings.editBook,
                      onTap: () => Navigator.pop(ctx, BookAction.edit),
                    ),
                    _ActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: strings.delete,
                      foreground: cs.error,
                      onTap: () => Navigator.pop(ctx, BookAction.delete),
                    ),
                    const SizedBox(height: 4),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = foreground ?? theme.colorScheme.onSurface;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 22, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
