/// Music-domain ZH/EN strings (mirrors AppStrings style).
class MusicStrings {
  MusicStrings(this.isZh);
  final bool isZh;

  String get music => isZh ? '音乐' : 'Music';
  String get tracks => isZh ? '歌曲' : 'Tracks';
  String get albums => isZh ? '专辑' : 'Albums';
  String get artists => isZh ? '艺人' : 'Artists';
  String get playlists => isZh ? '播放列表' : 'Playlists';
  String get queue => isZh ? '播放队列' : 'Queue';
  String get nowPlaying => isZh ? '正在播放' : 'Now Playing';
  String get scanFolder => isZh ? '扫描文件夹' : 'Scan folder';
  String get scanning => isZh ? '正在扫描…' : 'Scanning…';
  String get scanDone => isZh ? '扫描完成' : 'Scan complete';
  String get emptyLibrary =>
      isZh ? '音乐库为空，扫描本地音频文件夹开始听歌' : 'Music library empty — scan a local folder to begin';
  String get searchMusic => isZh ? '搜索歌曲、专辑、艺人' : 'Search tracks, albums, artists';
  String get play => isZh ? '播放' : 'Play';
  String get pause => isZh ? '暂停' : 'Pause';
  String get playNext => isZh ? '下一首播放' : 'Play next';
  String get addToQueue => isZh ? '加入队列' : 'Add to queue';
  String get addToPlaylist => isZh ? '加入歌单' : 'Add to playlist';
  String get clearQueue => isZh ? '清空队列' : 'Clear queue';
  String get newPlaylist => isZh ? '新建歌单' : 'New playlist';
  String get renamePlaylist => isZh ? '重命名歌单' : 'Rename playlist';
  String get deletePlaylist => isZh ? '删除歌单' : 'Delete playlist';
  String get exportM3u => isZh ? '导出 M3U' : 'Export M3U';
  String get exported => isZh ? '已导出' : 'Exported';
  String get playlistName => isZh ? '歌单名称' : 'Playlist name';
  String get sortTitle => isZh ? '标题' : 'Title';
  String get sortArtist => isZh ? '艺人' : 'Artist';
  String get sortAlbum => isZh ? '专辑' : 'Album';
  String get sortAdded => isZh ? '添加时间' : 'Date added';
  String get unknownArtist => isZh ? '未知艺人' : 'Unknown artist';
  String get unknownAlbum => isZh ? '未知专辑' : 'Unknown album';
  String get favorite => isZh ? '喜欢' : 'Favorite';
  String get unfavorite => isZh ? '取消喜欢' : 'Unfavorite';
  String get modeSequential => isZh ? '顺序播放' : 'Sequential';
  String get modeListLoop => isZh ? '列表循环' : 'List loop';
  String get modeSingle => isZh ? '单曲循环' : 'Single loop';
  String get modeShuffle => isZh ? '随机播放' : 'Shuffle';
  String get tracksCount => isZh ? '首' : 'tracks';
  String get noQueue => isZh ? '队列为空' : 'Queue is empty';
  String get libraryRoots => isZh ? '媒体库路径' : 'Library folders';
  String get rescan => isZh ? '重新扫描' : 'Rescan';
  String get permissionNeeded =>
      isZh ? '需要存储权限以扫描本地音乐' : 'Storage permission needed to scan music';
  String get removeFromPlaylist => isZh ? '从歌单移除' : 'Remove from playlist';
  /// Bottom-nav: novels / books tab.
  String get novel => isZh ? '小说' : 'Novels';
  /// Bottom-nav: comics tab.
  String get comic => isZh ? '漫画' : 'Comics';
  /// Legacy alias — bottom nav now uses AppStrings.settings (设置).
  String get more => isZh ? '设置' : 'Settings';
  String get vividMode => isZh ? '绚丽模式' : 'Vivid mode';
  String get vividModeOn => isZh ? '绚丽模式已开启' : 'Vivid mode on';
  String get vividModeOff => isZh ? '绚丽模式已关闭' : 'Vivid mode off';
  String get vividEmptyLyrics =>
      isZh ? '暂无歌词 · 可将同名 .lrc 放在音频同目录' : 'No lyrics — place a matching .lrc beside the audio file';
  String get vividFlowStyle => isZh ? '流光' : 'Flow';
}

