import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';
import 'book_actions_sheet.dart';
import 'book_details_page.dart';
import 'book_edit_sheet.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// Shared cover size / left edge across list book cards.
  static const double _coverW = 52;
  static const double _coverH = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(filteredLibraryProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final layout = settings.libraryLayout;
    final cs = Theme.of(context).colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: GlassAppBar(
          title: Text(strings.library),
          actions: [
            IconButton(
              tooltip: layout == LibraryLayout.grid
                  ? strings.layoutList
                  : strings.layoutGrid,
              icon: Icon(
                layout == LibraryLayout.grid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: () {
                final next = layout == LibraryLayout.grid
                    ? LibraryLayout.list
                    : LibraryLayout.grid;
                ref
                    .read(settingsProvider.notifier)
                    .saveSettings((c) => c.copyWith(libraryLayout: next));
              },
            ),
            PopupMenuButton<BookSort>(
              tooltip: strings.sortBy,
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) =>
                  ref.read(librarySortProvider.notifier).state = v,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: BookSort.added,
                  child: Text(strings.sortAdded),
                ),
                PopupMenuItem(
                  value: BookSort.recent,
                  child: Text(strings.sortRecent),
                ),
                PopupMenuItem(
                  value: BookSort.title,
                  child: Text(strings.sortTitle),
                ),
                PopupMenuItem(
                  value: BookSort.author,
                  child: Text(strings.sortAuthor),
                ),
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
            if (layout == LibraryLayout.grid) {
              return _buildGrid(context, ref, strings, books);
            }
            return _buildList(context, ref, strings, books);
          },
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    List<Book> books,
  ) {
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
                onActions: () => _showActions(context, ref, strings, book),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    List<Book> books,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 3 : 2;
    return staggeredListView(
      context: context,
      listView: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 112),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: books.length,
        itemBuilder: (context, i) {
          final book = books[i];
          return StaggeredFadeSlide(
            index: i,
            child: PressScale(
              pressedScale: 0.97,
              child: _BookGridCard(
                book: book,
                strings: strings,
                onOpen: () => openReader(context, book),
                onActions: () => _showActions(context, ref, strings, book),
              ),
            ),
          );
        },
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

  Future<void> _openEdit(BuildContext context, Book book) async {
    await showBookEditSheet(context, book: book);
  }

  Future<void> _handleBookAction(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    Book book,
    BookAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case BookAction.open:
        openReader(context, book);
      case BookAction.details:
        await _openDetails(context, book);
      case BookAction.edit:
        await _openEdit(context, book);
      case BookAction.delete:
        await _confirmDelete(context, ref, strings, book);
    }
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    Book book,
  ) async {
    final action = await showBookActionsSheet(
      context,
      book: book,
      strings: strings,
    );
    if (!context.mounted) return;
    await _handleBookAction(context, ref, strings, book, action);
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    Book book,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final file = File(book.filePath);
      if (await file.exists()) await file.delete();
      if (book.coverPath != null) {
        final c = File(book.coverPath!);
        if (await c.exists()) await c.delete();
      }
    } catch (_) {}
    await ref.read(bookRepositoryProvider).delete(book.id);
    await ref.read(libraryProvider.notifier).refresh();
  }
}


/// One translucent glass card per book — list mode.
class _BookGlassCard extends StatelessWidget {
  const _BookGlassCard({
    required this.book,
    required this.strings,
    required this.coverW,
    required this.coverH,
    required this.onOpen,
    required this.onActions,
  });

  final Book book;
  final AppStrings strings;
  final double coverW;
  final double coverH;
  final VoidCallback onOpen;
  final VoidCallback onActions;

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
          onLongPress: onActions,
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
                tooltip: strings.moreActions,
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: onActions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookGridCard extends StatelessWidget {
  const _BookGridCard({
    required this.book,
    required this.strings,
    required this.onOpen,
    required this.onActions,
  });

  final Book book;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = '${(book.progress * 100).round()}%';

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          onLongPress: onActions,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: BookCover(
                            book: book,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            borderRadius: 12,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: cs.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            child: IconButton(
                              tooltip: strings.moreActions,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: cs.onSurface,
                              ),
                              onPressed: onActions,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      value: book.progress,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(width: 6),
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
      ),
    );
  }
}
