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
      ? 'NeoReader 是全新 Flutter 离线阅读器（GPL-3.0），功能蓝本参考开源 Koodo Reader，采用 Material Design 3 + 毛玻璃设计。本地书库无数量上限。'
      : 'NeoReader is a new Flutter offline reader (GPL-3.0), inspired by open-source Koodo Reader’s feature set, with Material Design 3 + frosted glass. Unlimited local library.';
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

  // Settings hub categories (PiliPlus-style)
  String get settingsAppearance => isZh ? '外观' : 'Appearance';
  String get settingsAppearanceSub => isZh
      ? '主题亮/暗/跟随系统、种子色、毛玻璃强度'
      : 'Theme, seed color, glass blur';
  String get settingsReading => isZh ? '阅读' : 'Reading';
  String get settingsReadingSub => isZh
      ? '默认字号、行距、阅读主题、翻页方式'
      : 'Font size, line height, reading theme, page turn';
  String get settingsLibrary => isZh ? '书库与导入' : 'Library & import';
  String get settingsLibrarySub => isZh
      ? '排序默认、导入格式说明、清空缓存'
      : 'Default sort, import formats, clear cache';
  String get settingsPrivacy => isZh ? '隐私与安全' : 'Privacy & security';
  String get settingsPrivacySub => isZh
      ? 'PIN/库锁、导出笔记路径说明'
      : 'PIN/library lock, notes export path';
  String get settingsStats => isZh ? '统计' : 'Stats';
  String get settingsStatsSub => isZh
      ? '阅读时长展示、重置统计'
      : 'Show reading time, reset stats';
  String get settingsAboutSub => isZh
      ? '版本、许可证、致谢与开源仓库'
      : 'Version, license, credits, repository';

  String get seedColor => isZh ? '种子色' : 'Seed color';
  String get glassBlur => isZh ? '毛玻璃强度' : 'Glass blur';
  String get pageTurn => isZh ? '翻页方式' : 'Page turn';
  String get defaultSort => isZh ? '默认排序' : 'Default sort';
  String get importFormats => isZh ? '支持的导入格式' : 'Supported import formats';
  String get importFormatsBody => isZh
      ? '已实现：EPUB、PDF、TXT、MOBI/AZW3、FB2、CBZ/CBR、Markdown、HTML、DOCX。更多格式见路线图。'
      : 'Implemented: EPUB, PDF, TXT, MOBI/AZW3, FB2, CBZ/CBR, Markdown, HTML, DOCX. More on the roadmap.';
  String get clearCache => isZh ? '清空缓存' : 'Clear cache';
  String get clearCacheConfirm => isZh
      ? '将删除封面缓存等临时文件，不会删除书库中的图书。确定继续？'
      : 'This removes temporary cover cache files, not your books. Continue?';
  String get clearCacheDone => isZh ? '缓存已清空' : 'Cache cleared';
  String get libraryPin => isZh ? '库锁（PIN）' : 'Library lock (PIN)';
  String get libraryPinSub => isZh
      ? '占位开关，后续版本可设置 PIN 保护书库'
      : 'Placeholder — PIN lock coming in a later release';
  String get exportNotesPath => isZh ? '导出笔记路径' : 'Notes export path';
  String get exportNotesPathBody => isZh
      ? '笔记与标注保存在本机应用目录，导出功能将写入你选择的本地文件夹（后续版本）。'
      : 'Notes stay in the app documents directory; export will write to a folder you choose (coming later).';
  String get showReadingDuration => isZh ? '展示阅读时长' : 'Show reading duration';
  String get resetStats => isZh ? '重置统计' : 'Reset stats';
  String get resetStatsConfirm => isZh
      ? '将清空全部阅读时长记录，此操作不可撤销。确定重置？'
      : 'This permanently clears all reading-time records. Reset?';
  String get resetStatsDone => isZh ? '统计已重置' : 'Stats reset';
  String get license => isZh ? '许可证' : 'License';
  String get thanksKoodo => isZh ? '致谢' : 'Credits';
  String get thanksKoodoBody => isZh
      ? '功能蓝本参考开源项目 Koodo Reader；UI 中文字体使用 Noto Sans SC（SIL OFL）。'
      : 'Feature scope inspired by open-source Koodo Reader; UI CJK font is Noto Sans SC (SIL OFL).';
  String get openSourceRepo => isZh ? '开源仓库' : 'Source repository';
  String get versionLabel => isZh ? '版本' : 'Version';
  String get dangerAction => isZh ? '危险操作' : 'Destructive';
}
