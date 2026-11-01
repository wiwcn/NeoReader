import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';

/// Compact Anx/M3-style edit sheet for title / author / tags / description.
Future<bool> showBookEditSheet(
  BuildContext context, {
  required Book book,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BookEditSheet(book: book),
  );
  return result == true;
}

class BookEditSheet extends ConsumerStatefulWidget {
  const BookEditSheet({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<BookEditSheet> createState() => _BookEditSheetState();
}

class _BookEditSheetState extends ConsumerState<BookEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleCtrl = TextEditingController(text: book.title);
    _authorCtrl = TextEditingController(text: book.author);
    _tagsCtrl = TextEditingController(text: book.tags.join(', '));
    _descCtrl = TextEditingController(text: book.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _tagsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _denseDecoration(AppStrings strings, String label,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final strings = ref.read(stringsProvider);
    setState(() => _saving = true);
    final tags = Book.decodeTags(_tagsCtrl.text.replaceAll('，', ','));
    final updated = widget.book.copyWith(
      title: _titleCtrl.text.trim().isEmpty
          ? widget.book.title
          : _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      tags: tags,
    );
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.metadataSaved)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassSurface(
            borderRadius: 20,
            blur: 18,
            opacity: theme.brightness == Brightness.dark ? 0.12 : 0.16,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Row(
                    children: [
                      BookCover(
                        book: widget.book,
                        width: 44,
                        height: 58,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.editBook,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _denseDecoration(strings, strings.bookTitle),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _authorCtrl,
                    decoration: _denseDecoration(strings, strings.bookAuthor),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagsCtrl,
                    decoration: _denseDecoration(
                      strings,
                      strings.bookTags,
                      hint: strings.bookTagsHint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    decoration: _denseDecoration(
                      strings,
                      strings.bookDescription,
                      hint: strings.bookDescriptionHint,
                    ).copyWith(alignLabelWithHint: true),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(strings.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(strings.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
