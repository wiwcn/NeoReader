import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/reading_theme.dart';
import '../../../data/parsers/epub_parser.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import 'reader_controls_helper.dart';
import 'reader_typography.dart';
import 'vertical_text_view.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  const EpubReaderScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  EpubBookData? _data;
  Object? _error;
  late final ScrollController _scroll;
  late final PageController _pageController;
  ReadingSessionTracker? _tracker;
  double _progress = 0;
  int _chapterIndex = 0;
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
      final data = await EpubParser().parseFile(widget.book.filePath);
      if (!mounted) return;
      setState(() => _data = data);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final settings =
            ref.read(settingsProvider).value ?? const AppSettings();
        if (_scroll.hasClients &&
            _progress > 0 &&
            settings.pageTurnMode == PageTurnMode.scroll &&
            settings.writingMode == WritingMode.horizontal) {
          final max = _scroll.position.maxScrollExtent;
          _scroll.jumpTo(max * _progress.clamp(0, 1));
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
          'chapter:$_chapterIndex',
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
        .split(RegExp(r'\n{2,}|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Widget _chapterBody(
    EpubChapter c,
    AppSettings settings,
    ReadingColors colors,
  ) {
    final style = ReaderTypography.body(settings, colors);
    final titleStyle = ReaderTypography.title(settings, colors);
    final paras = _paragraphs(c.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.title, style: titleStyle),
        SizedBox(height: settings.paragraphSpacing),
        for (final para in paras)
          Padding(
            padding: EdgeInsets.only(bottom: settings.paragraphSpacing),
            child: SelectableText(
              para,
              style: style,
              textAlign: TextAlign.justify,
            ),
          ),
      ],
    );
  }

  Widget _buildScroll(ReadingColors colors, AppSettings settings) {
    final chapters = _data!.chapters;
    final padding = ReaderTypography.bodyPadding(settings);
    return ReaderTypography.constrainWidth(
      context: context,
      child: ListView.builder(
        controller: _scroll,
        padding: padding,
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(bottom: settings.paragraphSpacing + 16),
            child: _chapterBody(chapters[i], settings, colors),
          );
        },
      ),
    );
  }

  Widget _buildPaged(ReadingColors colors, AppSettings settings) {
    final chapters = _data!.chapters;
    final padding = ReaderTypography.bodyPadding(settings);
    return PageView.builder(
      controller: _pageController,
      itemCount: chapters.length,
      onPageChanged: (i) {
        _chapterIndex = i;
        _progress = chapters.isEmpty ? 0 : (i + 1) / chapters.length;
        setState(() {});
      },
      itemBuilder: (context, i) {
        return SingleChildScrollView(
          padding: padding,
          child: ReaderTypography.constrainWidth(
            context: context,
            child: _chapterBody(chapters[i], settings, colors),
          ),
        );
      },
    );
  }

  Widget _buildVertical(ReadingColors colors, AppSettings settings) {
    final chapters = _data!.chapters;
    final buf = StringBuffer();
    for (final c in chapters) {
      if (c.title.isNotEmpty) {
        buf.writeln(c.title);
        buf.writeln();
      }
      buf.writeln(c.content);
      buf.writeln();
    }
    return VerticalTextView(
      text: buf.toString(),
      style: ReaderTypography.body(settings, colors),
      controller: _scroll,
      padding: ReaderTypography.bodyPadding(settings),
      onScrollProgress: (p) {
        _progress = p;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final colors = ReadingColors.of(settings.readingTheme);
    final paged = settings.pageTurnMode == PageTurnMode.paged;
    final vertical = settings.writingMode == WritingMode.vertical;

    Widget body;
    if (_error != null) {
      body = Center(
          child: Text('$_error', style: TextStyle(color: colors.foreground)));
    } else if (_data == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vertical) {
      body = _buildVertical(colors, settings);
    } else if (paged) {
      body = _buildPaged(colors, settings);
    } else {
      body = _buildScroll(colors, settings);
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: colors.background.withValues(alpha: 0.9),
              foregroundColor: colors.foreground,
              title: Text(
                _data?.title ?? widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: paged ? strings.scrollMode : strings.pageMode,
                  icon: Icon(paged
                      ? Icons.view_day_outlined
                      : Icons.auto_stories_outlined),
                  onPressed: () {
                    ref.read(settingsProvider.notifier).saveSettings(
                          (c) => c.copyWith(
                            pageTurnMode: paged
                                ? PageTurnMode.scroll
                                : PageTurnMode.paged,
                          ),
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => showReadingControls(
                    context: context,
                    ref: ref,
                    settings: settings,
                    onAddBookmark: () async {
                      await _addAnnotation(AnnotationType.bookmark);
                      if (context.mounted) Navigator.pop(context);
                    },
                    onAddNote: () async {
                      Navigator.pop(context);
                      await _promptNote();
                    },
                  ),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _chromeVisible = !_chromeVisible),
        child: body,
      ),
      bottomNavigationBar: _chromeVisible
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: _progress.clamp(0, 1)),
                    const SizedBox(height: 4),
                    Text(
                      '${(_progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: colors.foreground.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _addAnnotation(
    AnnotationType type, {
    String? note,
    String? selected,
  }) async {
    final a = Annotation(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      type: type,
      createdAt: DateTime.now(),
      location: 'chapter:$_chapterIndex',
      chapter: _data?.chapters.isNotEmpty == true
          ? _data!
              .chapters[_chapterIndex.clamp(0, _data!.chapters.length - 1)]
              .title
          : null,
      selectedText: selected,
      note: note,
      colorHex: type == AnnotationType.highlight ? '#FFEB3B' : null,
      progress: _progress,
    );
    await ref.read(annotationRepositoryProvider).add(a);
    ref.invalidate(annotationsForBookProvider(widget.book.id));
    ref.invalidate(allAnnotationsProvider);
  }

  Future<void> _promptNote() async {
    final controller = TextEditingController();
    final strings = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.addNote),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(strings.confirm)),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await _addAnnotation(AnnotationType.note, note: controller.text.trim());
    }
  }
}
