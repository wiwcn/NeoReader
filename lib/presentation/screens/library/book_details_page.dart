import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';
import 'book_edit_sheet.dart';

/// Slim glass summary page for a library book. Editing opens a compact sheet.
class BookDetailsPage extends ConsumerStatefulWidget {
  const BookDetailsPage({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends ConsumerState<BookDetailsPage> {
  Book? _book;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = await ref.read(bookRepositoryProvider).getById(widget.bookId);
    if (!mounted) return;
    setState(() {
      _book = book;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final book = _book;
    if (book == null) return;
    final saved = await showBookEditSheet(context, book: book);
    if (saved && mounted) await _load();
  }

  Future<void> _changeCover() async {
    final book = _book;
    if (book == null) return;
    final strings = ref.read(stringsProvider);
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return;
    final srcPath = files.first.path;
    if (srcPath == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docs.path, AppConstants.coversDirName));
    if (!await coversDir.exists()) await coversDir.create(recursive: true);
    final ext = p.extension(srcPath).toLowerCase();
    final safeExt =
        (ext == '.png' || ext == '.webp' || ext == '.gif') ? ext : '.jpg';
    final dest = p.join(coversDir.path, '${book.id}$safeExt');
    await File(srcPath).copy(dest);
    if (book.coverPath != null && book.coverPath != dest) {
      try {
        final old = File(book.coverPath!);
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }
    final updated = book.copyWith(coverPath: dest);
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _book = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.coverUpdated)),
    );
  }

  Future<void> _removeCover() async {
    final book = _book;
    if (book == null || book.coverPath == null) return;
    final strings = ref.read(stringsProvider);
    try {
      final f = File(book.coverPath!);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final updated = book.copyWith(coverPath: null);
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _book = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.coverRemoved)),
    );
  }

  Future<void> _confirmDelete() async {
    final book = _book;
    if (book == null) return;
    final strings = ref.read(stringsProvider);
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(strings.bookDetails),
          actions: [
            IconButton(
              tooltip: strings.editBook,
              onPressed: _book == null ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _book == null
                ? Center(child: Text(strings.importFailed))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
                    children: [
                      SolidCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BookCover(
                              book: _book!,
                              width: 80,
                              height: 106,
                              borderRadius: 10,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _book!.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _book!.author.isEmpty
                                        ? strings.unknownAuthor
                                        : _book!.author,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${strings.formatLabel}: ${_book!.format.name.toUpperCase()}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: cs.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AnimatedProgressBar(
                                          value: _book!.progress,
                                          minHeight: 5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(_book!.progress * 100).round()}%',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        onPressed: _changeCover,
                                        icon: const Icon(
                                          Icons.image_outlined,
                                          size: 18,
                                        ),
                                        label: Text(strings.changeCover),
                                      ),
                                      if (_book!.coverPath != null)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          onPressed: _removeCover,
                                          icon: const Icon(
                                            Icons.hide_image_outlined,
                                            size: 18,
                                          ),
                                          label: Text(strings.removeCover),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SolidCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetaRow(
                              label: strings.bookTags,
                              value: _book!.tags.isEmpty
                                  ? '—'
                                  : _book!.tags.join(', '),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              strings.bookDescription,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _book!.description.isEmpty
                                  ? '—'
                                  : _book!.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _edit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(strings.editBook),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => openReader(context, _book!),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: Text(strings.openBook),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.dangerAction,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: cs.error.withValues(alpha: 0.5),
                          ),
                        ),
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(strings.delete),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
