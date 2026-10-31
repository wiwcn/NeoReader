import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/reading_theme.dart';
import '../../../data/parsers/txt_parser.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import 'paginated_plain_text.dart';
import 'reader_controls_helper.dart';
import 'reader_typography.dart';
import 'vertical_text_view.dart';

class TxtReaderScreen extends ConsumerStatefulWidget {
  const TxtReaderScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<TxtReaderScreen> createState() => _TxtReaderScreenState();
}

class _TxtReaderScreenState extends ConsumerState<TxtReaderScreen> {
  String? _text;
  Object? _error;
  late final ScrollController _scroll;
  late final PageController _pageController;
  ReadingSessionTracker? _tracker;
  double _progress = 0;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    _pageController = PageController();
    _progress = widget.book.progress;
    _tracker = ref.read(sessionTrackerProvider);
    _tracker!.start(widget.book.id);
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TxtParser().parseFile(widget.book.filePath);
      if (!mounted) return;
      setState(() => _text = data.content);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _progress > 0) {
          _scroll.jumpTo(
            _scroll.position.maxScrollExtent * _progress.clamp(0, 1),
          );
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _progress = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
  }

  Future<void> _persist() async {
    await ref.read(bookRepositoryProvider).updateProgress(
          widget.book.id,
          _progress,
          'offset:${_scroll.hasClients ? _scroll.offset.round() : 0}',
        );
    await ref.read(libraryProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _persist();
    _tracker?.stop();
    _scroll.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _paragraphs(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n{2,}'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Widget _buildBody(AppSettings settings, ReadingColors colors) {
    final style = ReaderTypography.body(settings, colors);
    final padding = ReaderTypography.bodyPadding(settings);
    final text = _text!;

    if (settings.writingMode == WritingMode.vertical) {
      return VerticalTextView(
        text: text,
        style: style,
        controller: _scroll,
        padding: padding,
        onScrollProgress: (p) => _progress = p,
      );
    }

    if (settings.pageTurnMode == PageTurnMode.paged) {
      return PaginatedPlainText(
        text: text,
        style: style,
        padding: padding,
        controller: _pageController,
        onProgress: (p) {
          _progress = p;
          if (mounted) setState(() {});
        },
      );
    }

    final paras = _paragraphs(text);
    return ReaderTypography.constrainWidth(
      context: context,
      child: ListView.builder(
        controller: _scroll,
        padding: padding,
        itemCount: paras.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(bottom: settings.paragraphSpacing),
            child: SelectableText(
              paras[i],
              style: style,
              textAlign: TextAlign.justify,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final colors = ReadingColors.of(settings.readingTheme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: colors.background.withValues(alpha: 0.9),
              foregroundColor: colors.foreground,
              title: Text(widget.book.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => showReadingControls(
                    context: context,
                    ref: ref,
                    settings: settings,
                    onAddBookmark: () async {
                      await ref.read(annotationRepositoryProvider).add(
                            Annotation(
                              id: const Uuid().v4(),
                              bookId: widget.book.id,
                              type: AnnotationType.bookmark,
                              createdAt: DateTime.now(),
                              progress: _progress,
                              location:
                                  'offset:${_scroll.hasClients ? _scroll.offset.round() : 0}',
                            ),
                          );
                      ref.invalidate(allAnnotationsProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    onAddNote: () async {
                      Navigator.pop(context);
                      final c = TextEditingController();
                      final strings = ref.read(stringsProvider);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text(strings.addNote),
                          content: TextField(controller: c, maxLines: 4),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: Text(strings.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: Text(strings.confirm),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && c.text.trim().isNotEmpty) {
                        await ref.read(annotationRepositoryProvider).add(
                              Annotation(
                                id: const Uuid().v4(),
                                bookId: widget.book.id,
                                type: AnnotationType.note,
                                createdAt: DateTime.now(),
                                note: c.text.trim(),
                                progress: _progress,
                              ),
                            );
                        ref.invalidate(allAnnotationsProvider);
                      }
                    },
                  ),
                ),
              ],
            )
          : null,
      body: _error != null
          ? Center(child: Text('$_error'))
          : _text == null
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTap: () =>
                      setState(() => _chromeVisible = !_chromeVisible),
                  child: _buildBody(settings, colors),
                ),
      bottomNavigationBar: _chromeVisible
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LinearProgressIndicator(value: _progress.clamp(0, 1)),
              ),
            )
          : null,
    );
  }
}
