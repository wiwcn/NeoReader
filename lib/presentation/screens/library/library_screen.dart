import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';
import 'book_details_page.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// Shared cover size / left edge across all book cards.
  static const double _coverW = 52;
  static const double _coverH = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(filteredLibraryProvider);
    final cs = Theme.of(context).colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: GlassAppBar(
          title: Text(strings.library),
          actions: [
            PopupMenuButton<BookSort>(
              tooltip: strings.sortBy,
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) =>
                  ref.read(librarySortProvider.notifier).state = v,
              itemBuilder: (_) => [
                PopupMenuItem(value: BookSort.added, child: Text(strings.sortAdded)),
                PopupMenuItem(value: BookSort.recent, child: Text(strings.sortRecent)),
                PopupMenuItem(value: BookSort.title, child: Text(strings.sortTitle)),
                PopupMenuItem(value: BookSort.author, child: Text(strings.sortAuthor)),
              ],
            ),
          ],
          // Search lives in chrome — filled pill, NOT a second GlassSurface.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: strings.searchHint,
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface.withValues(alpha: 0.45),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(libraryQueryProvider.notifier).state = v,
              ),
            ),
          ),
        ),
        floatingActionButton: PressScale(
          child: FloatingActionButton.extended(
            onPressed: () => _import(context, ref, strings),
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.importBook),
          ),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (books) {
            if (books.isEmpty) return EmptyLibrary(strings: strings);
            return staggeredListView(
              context: context,
              listView: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 112),
                itemCount: books.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final book = books[i];
                  return StaggeredFadeSlide(
                    index: i,
                    child: PressScale(
                      pressedScale: 0.98,
                      child: _BookGlassCard(
                        book: book,
                        strings: strings,
                        coverW: _coverW,
                        coverH: _coverH,
                        onOpen: () => openReader(context, book),
                        onMore: () => _openDetails(context, book),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailsPage(bookId: book.id),
      ),
    );
  }

  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.importPickerExtensions,
    );
    if (files.isEmpty) return;
    final import = ref.read(importServiceProvider);
    var ok = 0;
    String? lastError;
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      final r = await import.importFile(path);
      if (r.success) {
        ok++;
      } else {
        lastError = r.error;
      }
    }
    await ref.read(libraryProvider.notifier).refresh();
    if (!context.mounted) return;
    final msg = ok > 0
        ? '${strings.importSuccess} ×$ok'
        : (lastError?.startsWith('planned_or_unsupported') == true
            ? strings.unsupportedFormat
            : '${strings.importFailed}: $lastError');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

/// One translucent glass card per book — flat content inside, no nested glass.
class _BookGlassCard extends StatelessWidget {
  const _BookGlassCard({
    required this.book,
    required this.strings,
    required this.coverW,
    required this.coverH,
    required this.onOpen,
    required this.onMore,
  });

  final Book book;
  final AppStrings strings;
  final double coverW;
  final double coverH;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final author = book.author.isEmpty ? strings.unknownAuthor : book.author;
    final pct = '${(book.progress * 100).round()}%';

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          onLongPress: onMore,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BookCover(
                book: book,
                width: coverW,
                height: coverH,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.format.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar with trailing % label (no separate column).
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedProgressBar(
                            value: book.progress,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pct,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                tooltip: strings.moreActions,
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
