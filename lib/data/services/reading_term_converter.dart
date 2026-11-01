/// Display-layer term conversion for Taiwan/HK vs Mainland wording.
///
/// Does **not** rewrite book files on disk. Apply only to strings shown in the
/// reader. Progress and annotations should stay keyed to the original text.
///
/// // EXTEND HERE: append more Taiwan↔Mainland pairs in [_pairs].
library;

import '../../domain/models/app_settings.dart';

class _TermPair {
  const _TermPair(this.taiwan, this.mainland);
  final String taiwan;
  final String mainland;
}

/// Built-in lexicon — places, food, IT, daily words.
const List<_TermPair> _pairs = [
  // Places / names
  _TermPair('義大利', '意大利'),
  _TermPair('义大利', '意大利'),
  _TermPair('紐西蘭', '新西兰'),
  _TermPair('紐約', '纽约'),
  _TermPair('洛杉磯', '洛杉矶'),
  _TermPair('舊金山', '旧金山'),
  _TermPair('華盛頓', '华盛顿'),
  _TermPair('倫敦', '伦敦'),
  _TermPair('寮國', '老挝'),
  _TermPair('北韓', '朝鲜'),
  _TermPair('南韓', '韩国'),
  _TermPair('韓國', '韩国'),

  // Food
  _TermPair('霜淇淋', '冰淇淋'),
  _TermPair('起司', '奶酪'),
  _TermPair('優格', '酸奶'),
  _TermPair('優酪乳', '酸奶'),
  _TermPair('柳丁', '橙子'),
  _TermPair('鳳梨', '菠萝'),
  _TermPair('奇異果', '猕猴桃'),
  _TermPair('馬鈴薯', '土豆'),
  _TermPair('漢堡', '汉堡'),
  _TermPair('薯條', '薯条'),
  _TermPair('可樂', '可乐'),
  _TermPair('番茄醬', '番茄酱'),

  // IT / daily
  _TermPair('軟體', '软件'),
  _TermPair('軟件', '软件'),
  _TermPair('硬體', '硬件'),
  _TermPair('網路', '网络'),
  _TermPair('網絡', '网络'),
  _TermPair('網際網路', '互联网'),
  _TermPair('記憶體', '内存'),
  _TermPair('螢幕', '屏幕'),
  _TermPair('滑鼠', '鼠标'),
  _TermPair('印表機', '打印机'),
  _TermPair('資料庫', '数据库'),
  _TermPair('檔案', '文件'),
  _TermPair('資料夾', '文件夹'),
  _TermPair('資訊', '信息'),
  _TermPair('預設', '默认'),
  _TermPair('伺服器', '服务器'),
  _TermPair('演算法', '算法'),
  _TermPair('程式', '程序'),
  _TermPair('影片', '视频'),
  _TermPair('相簿', '相册'),
  _TermPair('部落格', '博客'),
  _TermPair('網誌', '博客'),
  _TermPair('簡訊', '短信'),
  _TermPair('訊息', '消息'),
  _TermPair('智慧型手機', '智能手机'),
  _TermPair('使用者', '用户'),
  _TermPair('品質', '质量'),
  _TermPair('計程車', '出租车'),
  _TermPair('捷運', '地铁'),
  _TermPair('地鐵', '地铁'),
  _TermPair('腳踏車', '自行车'),
  _TermPair('機車', '摩托车'),
  _TermPair('公車', '公交'),
];

/// Extra one-way / variant normalizations applied on top of [_pairs].
const List<_TermPair> _mainlandExtras = [
  // Variants → preferred Mainland form
  _TermPair('冰激凌', '冰淇淋'),
  _TermPair('冰淇凌', '冰淇淋'),
];

const List<_TermPair> _taiwanExtras = [
  // Variants → preferred Taiwan form
  _TermPair('冰淇淋', '霜淇淋'),
  _TermPair('冰激凌', '霜淇淋'),
  _TermPair('冰淇凌', '霜淇淋'),
  _TermPair('意大利', '義大利'),
];

class ReadingTermConverter {
  ReadingTermConverter._();

  static final List<MapEntry<String, String>> _toMainlandSorted = _buildTable(
    toMainland: true,
  );
  static final List<MapEntry<String, String>> _toTaiwanSorted = _buildTable(
    toMainland: false,
  );

  static List<MapEntry<String, String>> _buildTable({required bool toMainland}) {
    final map = <String, String>{};
    for (final p in _pairs) {
      if (p.taiwan == p.mainland) continue;
      if (toMainland) {
        // Later variants may map into the same Mainland form.
        map[p.taiwan] = p.mainland;
      } else {
        // Prefer the first (more traditional / TW-common) mapping.
        map.putIfAbsent(p.mainland, () => p.taiwan);
      }
    }
    final extras = toMainland ? _mainlandExtras : _taiwanExtras;
    for (final p in extras) {
      if (toMainland) {
        map[p.taiwan] = p.mainland;
      } else {
        map.putIfAbsent(p.taiwan, () => p.mainland);
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }

  /// Apply conversion for display. Returns [input] unchanged when [mode] is off.
  static String convert(String input, TermConversionMode mode) {
    if (mode == TermConversionMode.off || input.isEmpty) return input;
    final table = mode == TermConversionMode.toMainland
        ? _toMainlandSorted
        : _toTaiwanSorted;

    final buf = StringBuffer();
    var i = 0;
    while (i < input.length) {
      var matched = false;
      for (final e in table) {
        final key = e.key;
        if (key.isEmpty) continue;
        final end = i + key.length;
        if (end <= input.length && input.substring(i, end) == key) {
          buf.write(e.value);
          i = end;
          matched = true;
          break;
        }
      }
      if (!matched) {
        buf.write(input[i]);
        i++;
      }
    }
    return buf.toString();
  }
}
