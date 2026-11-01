import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/annotation_export_service.dart';
import '../../../domain/models/annotation.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';

class AnnotationsScreen extends ConsumerWidget {
  const AnnotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final async = ref.watch(allAnnotationsProvider);
    final books = ref.watch(libraryProvider).value ?? [];

    String bookTitle(String id) {
      for (final b in books) {
        if (b.id == id) return b.title;
      }
      return id;
    }

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(strings.annotations),
          actions: [
            PopupMenuButton<AnnotationExportFormat>(
              tooltip: strings.exportAnnotations,
              onSelected: (format) =>
                  _export(context, ref, format, async.value ?? []),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: AnnotationExportFormat.markdown,
                  child: Text(strings.exportFormatMd),
                ),
                PopupMenuItem(
                  value: AnnotationExportFormat.txt,
                  child: Text(strings.exportFormatTxt),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    strings.export,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.sticky_note_2_outlined,
                title: strings.noAnnotations,
                message: strings.noAnnotationsHint,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AnnotationCard(
                annotation: items[i],
                bookTitle: bookTitle(items[i].bookId),
                strings: strings,
                onDelete: () async {
                  await ref
                      .read(annotationRepositoryProvider)
                      .delete(items[i].id);
                  ref.invalidate(allAnnotationsProvider);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    AnnotationExportFormat format,
    List<Annotation> items,
  ) async {
    final strings = ref.read(stringsProvider);
    final books = ref.read(libraryProvider).value ?? [];
    try {
      final result = await ref
          .read(annotationExportServiceProvider)
          .export(annotations: items, books: books, format: format);
      if (!context.mounted) return;
      final path = result.pickedUri?.toString() ?? result.primaryPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.exportSuccess}\n${strings.exportSavedTo}: $path',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.exportFailed}: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// One annotation row: colour-coded type badge → book title → quoted content.
class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({
    required this.annotation,
    required this.bookTitle,
    required this.strings,
    required this.onDelete,
  });

  final Annotation annotation;
  final String bookTitle;
  final AppStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (icon, tint, label) = _typeStyle(annotation.type, strings);

    final quote = switch (annotation.type) {
      AnnotationType.highlight => annotation.selectedText,
      AnnotationType.note => annotation.note,
      AnnotationType.bookmark => null,
    };

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (annotation.progress != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(annotation.progress! * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (quote != null && quote.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    quote.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Pill(text: label, color: tint),
                    if (annotation.chapter != null &&
                        annotation.chapter!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          annotation.chapter!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: strings.delete,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _typeStyle(AnnotationType type, AppStrings s) {
    switch (type) {
      case AnnotationType.bookmark:
        return (
          Icons.bookmark_rounded,
          const Color(0xFF5C6BC0),
          s.annotationBookmark,
        );
      case AnnotationType.highlight:
        return (
          Icons.format_color_fill_rounded,
          const Color(0xFFF9A825),
          s.annotationHighlight,
        );
      case AnnotationType.note:
        return (
          Icons.sticky_note_2_rounded,
          const Color(0xFF26A69A),
          s.annotationNote,
        );
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
