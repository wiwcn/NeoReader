import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/reading_theme.dart';
import '../../../data/parsers/epub_parser.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../providers/providers.dart';
import 'reading_controls.dart';

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
  ReadingSessionTracker? _tracker;
  bool _paged = false;
  late final PageController _pageController;
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
        if (_scroll.hasClients && _progress > 0 && !_paged) {
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
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    _progress = p;
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

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final colors = ReadingColors.of(settings.readingTheme);

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
                  tooltip: _paged ? strings.scrollMode : strings.pageMode,
                  icon: Icon(_paged ? Icons.view_day_outlined : Icons.auto_stories_outlined),
                  onPressed: () => setState(() => _paged = !_paged),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _openControls(settings),
                ),
              ],
            )
          : null,
      body: _error != null
          ? Center(child: Text('$_error', style: TextStyle(color: colors.foreground)))
          : _data == null
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTap: () => setState(() => _chromeVisible = !_chromeVisible),
                  child: _paged ? _buildPaged(colors, settings) : _buildScroll(colors, settings),
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
                      style: TextStyle(color: colors.foreground.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildScroll(ReadingColors colors, AppSettings settings) {
    final chapters = _data!.chapters;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
      itemCount: chapters.length,
      itemBuilder: (context, i) {
        final c = chapters[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: settings.fontSize + 4,
                  fontWeight: FontWeight.w700,
                  height: settings.lineHeight,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                c.content,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                ),
                onSelectionChanged: (sel, _) {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaged(ReadingColors colors, AppSettings settings) {
    final chapters = _data!.chapters;
    return PageView.builder(
      controller: _pageController,
      itemCount: chapters.length,
      onPageChanged: (i) {
        _chapterIndex = i;
        _progress = chapters.isEmpty ? 0 : (i + 1) / chapters.length;
        setState(() {});
      },
      itemBuilder: (context, i) {
        final c = chapters[i];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: settings.fontSize + 4,
                  fontWeight: FontWeight.w700,
                  height: settings.lineHeight,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                c.content,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openControls(AppSettings settings) {
    final strings = ref.read(stringsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        var local = settings;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return ReadingControlsSheet(
              strings: strings,
              settings: local,
              onChanged: (s) {
                setModal(() => local = s);
                ref.read(settingsProvider.notifier).saveSettings((_) => s);
              },
              onAddBookmark: () async {
                await _addAnnotation(AnnotationType.bookmark);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              onAddNote: () async {
                Navigator.pop(ctx);
                await _promptNote();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addAnnotation(AnnotationType type, {String? note, String? selected}) async {
    final a = Annotation(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      type: type,
      createdAt: DateTime.now(),
      location: 'chapter:$_chapterIndex',
      chapter: _data?.chapters.isNotEmpty == true
          ? _data!.chapters[_chapterIndex.clamp(0, _data!.chapters.length - 1)].title
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.confirm)),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await _addAnnotation(AnnotationType.note, note: controller.text.trim());
    }
  }
}
