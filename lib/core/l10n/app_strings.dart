/// Simple ZH/EN strings. zh-CN is the primary UI language.
class AppStrings {
  AppStrings(this.isZh);

  final bool isZh;

  String get appTitle => 'NeoReader';
  String get library => isZh ? '书库' : 'Library';
  String get settings => isZh ? '设置' : 'Settings';
  String get annotations => isZh ? '标注' : 'Annotations';
  String get stats => isZh ? '阅读统计' : 'Reading stats';
  String get searchHint => isZh ? '搜索书名或作者' : 'Search title or author';
  String get importBook => isZh ? '导入图书' : 'Import book';
  String get emptyLibrary =>
      isZh ? '书库为空，点击右下角导入 EPUB / PDF / TXT' : 'Library is empty. Import EPUB / PDF / TXT';
  String get delete => isZh ? '删除' : 'Delete';
  String get deleteConfirm =>
      isZh ? '确定从书库删除这本书？（本地文件一并删除）' : 'Delete this book from the library (and local file)?';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get confirm => isZh ? '确定' : 'OK';
  String get sortBy => isZh ? '排序' : 'Sort';
  String get sortTitle => isZh ? '书名' : 'Title';
  String get sortAuthor => isZh ? '作者' : 'Author';
  String get sortRecent => isZh ? '最近阅读' : 'Recent';
  String get sortAdded => isZh ? '导入时间' : 'Date added';
  String get language => isZh ? '界面语言' : 'Language';
  String get theme => isZh ? '主题' : 'Theme';
  String get themeSystem => isZh ? '跟随系统' : 'System';
  String get themeLight => isZh ? '浅色' : 'Light';
  String get themeDark => isZh ? '深色' : 'Dark';
  String get readingDefaults => isZh ? '阅读默认' : 'Reading defaults';
  String get fontSize => isZh ? '字号' : 'Font size';
  String get lineHeight => isZh ? '行距' : 'Line height';
  String get readingTheme => isZh ? '阅读主题' : 'Reading theme';
  String get day => isZh ? '日间' : 'Day';
  String get night => isZh ? '夜间' : 'Night';
  String get sepia => isZh ? '羊皮纸' : 'Sepia';
  String get bookmarks => isZh ? '书签' : 'Bookmarks';
  String get highlights => isZh ? '高亮' : 'Highlights';
  String get notes => isZh ? '笔记' : 'Notes';
  String get addBookmark => isZh ? '添加书签' : 'Add bookmark';
  String get addNote => isZh ? '添加笔记' : 'Add note';
  String get offlinePolicy =>
      isZh ? '纯离线：无账号、无同步、无云盘、无 Pro' : 'Offline only: no account, sync, cloud, or Pro';
  String get about => isZh ? '关于' : 'About';
  String get aboutBody => isZh
      ? 'NeoReader 是全新 Flutter 离线阅读器，功能蓝本参考开源 Koodo Reader（AGPL-3.0），采用 Material Design 3 + 毛玻璃设计。本地书库无数量上限。'
      : 'NeoReader is a new Flutter offline reader inspired by open-source Koodo Reader (AGPL-3.0), with Material Design 3 + frosted glass. Unlimited local library.';
  String get progress => isZh ? '进度' : 'Progress';
  String get unknownAuthor => isZh ? '未知作者' : 'Unknown author';
  String get importFailed => isZh ? '导入失败' : 'Import failed';
  String get importSuccess => isZh ? '导入成功' : 'Imported';
  String get unsupportedFormat =>
      isZh ? '该格式已列入路线图，v1 核心支持 EPUB/PDF/TXT' : 'Format on roadmap; v1 core supports EPUB/PDF/TXT';
  String get noAnnotations => isZh ? '暂无标注' : 'No annotations yet';
  String get exportLater => isZh ? '导出（后续版本）' : 'Export (coming later)';
  String get toc => isZh ? '目录' : 'Contents';
  String get scrollMode => isZh ? '滚动' : 'Scroll';
  String get pageMode => isZh ? '翻页' : 'Paged';
  String get todayReading => isZh ? '今日阅读' : 'Today';
  String get totalReading => isZh ? '累计时长' : 'Total time';
  String get booksInProgress => isZh ? '在读' : 'In progress';
  String get features => isZh ? '功能模块' : 'Feature modules';
  String get comingSoon => isZh ? '即将推出' : 'Coming soon';
  String get minutes => isZh ? '分钟' : 'min';
  String get hours => isZh ? '小时' : 'h';
}
