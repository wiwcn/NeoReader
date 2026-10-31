import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/repositories/annotation_repository_impl.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../data/services/import_service.dart';
import '../../data/services/reading_session_tracker.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/book.dart';
import '../../domain/models/reading_stats.dart';

final bookRepositoryProvider = Provider((ref) => BookRepositoryImpl());
final annotationRepositoryProvider =
    Provider((ref) => AnnotationRepositoryImpl());
final settingsRepositoryProvider = Provider((ref) => SettingsRepositoryImpl());
final statsRepositoryProvider = Provider((ref) => StatsRepositoryImpl());
final importServiceProvider = Provider((ref) => ImportService());
final sessionTrackerProvider = Provider(
  (ref) => ReadingSessionTracker(ref.watch(statsRepositoryProvider)),
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsRepositoryProvider).load();

  Future<void> saveSettings(AppSettings Function(AppSettings) cb) async {
    final current = state.value ?? const AppSettings();
    final next = cb(current);
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return AppStrings(settings.isZh);
});

class LibraryNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() => ref.read(bookRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(bookRepositoryProvider).getAll());
  }
}

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, List<Book>>(LibraryNotifier.new);

final libraryQueryProvider = StateProvider<String>((ref) => '');
final librarySortProvider = StateProvider<BookSort>((ref) => BookSort.added);

final filteredLibraryProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(libraryProvider);
  final query = ref.watch(libraryQueryProvider).trim().toLowerCase();
  final sort = ref.watch(librarySortProvider);
  return booksAsync.whenData((books) {
    var list = books;
    if (query.isNotEmpty) {
      list = list
          .where(
            (b) =>
                b.title.toLowerCase().contains(query) ||
                b.author.toLowerCase().contains(query),
          )
          .toList();
    }
    list = [...list];
    switch (sort) {
      case BookSort.title:
        list.sort((a, b) => a.title.compareTo(b.title));
      case BookSort.author:
        list.sort((a, b) => a.author.compareTo(b.author));
      case BookSort.recent:
        list.sort((a, b) {
          final ar = a.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final br = b.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return br.compareTo(ar);
        });
      case BookSort.added:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return list;
  });
});

final statsSummaryProvider = FutureProvider<ReadingStatsSummary>((ref) {
  ref.watch(libraryProvider);
  return ref.read(statsRepositoryProvider).summary();
});

final annotationsForBookProvider =
    FutureProvider.family<List<Annotation>, String>((ref, bookId) {
  return ref.read(annotationRepositoryProvider).forBook(bookId);
});

final allAnnotationsProvider = FutureProvider<List<Annotation>>((ref) {
  ref.watch(libraryProvider);
  return ref.read(annotationRepositoryProvider).all();
});
