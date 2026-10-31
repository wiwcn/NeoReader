import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-imported TTF/OTF fonts stored under app documents `fonts/`.
class CustomFontInfo {
  const CustomFontInfo({
    required this.family,
    required this.displayName,
    required this.fileName,
  });

  final String family;
  final String displayName;
  final String fileName;

  Map<String, String> toJson() => {
    'family': family,
    'displayName': displayName,
    'fileName': fileName,
  };

  factory CustomFontInfo.fromJson(Map<String, dynamic> json) => CustomFontInfo(
    family: json['family'] as String,
    displayName: json['displayName'] as String? ?? json['family'] as String,
    fileName: json['fileName'] as String,
  );
}

class CustomFontService {
  static const _prefsKey = 'custom_fonts_v1';
  static const fontsDirName = 'fonts';

  final Set<String> _loaded = {};

  Future<Directory> fontsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, fontsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<CustomFontInfo>> listFonts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => CustomFontInfo.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveList(List<CustomFontInfo> fonts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(fonts.map((e) => e.toJson()).toList()),
    );
  }

  /// Copy [sourcePath] into documents/fonts and register with [FontLoader].
  Future<CustomFontInfo> importFont(String sourcePath) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw StateError('Font file not found: $sourcePath');
    }
    final ext = p.extension(sourcePath).toLowerCase();
    if (ext != '.ttf' && ext != '.otf') {
      throw StateError('Only TTF/OTF fonts are supported');
    }
    final base = p.basenameWithoutExtension(sourcePath);
    final safe = base.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\-]+'), '_');
    final family = 'Custom_$safe';
    final fileName = '$safe$ext';
    final dir = await fontsDirectory();
    final dest = File(p.join(dir.path, fileName));
    await src.copy(dest.path);

    final info = CustomFontInfo(
      family: family,
      displayName: base,
      fileName: fileName,
    );
    final fonts = await listFonts();
    fonts.removeWhere((f) => f.family == family || f.fileName == fileName);
    fonts.add(info);
    await _saveList(fonts);
    await _register(info, dest);
    return info;
  }

  Future<void> deleteFont(String family) async {
    final fonts = await listFonts();
    final match = fonts.where((f) => f.family == family).toList();
    fonts.removeWhere((f) => f.family == family);
    await _saveList(fonts);
    final dir = await fontsDirectory();
    for (final f in match) {
      final file = File(p.join(dir.path, f.fileName));
      if (await file.exists()) {
        await file.delete();
      }
    }
    _loaded.remove(family);
  }

  /// Register all imported fonts (call once at startup).
  Future<void> registerAll() async {
    final fonts = await listFonts();
    final dir = await fontsDirectory();
    for (final info in fonts) {
      final file = File(p.join(dir.path, info.fileName));
      if (await file.exists()) {
        await _register(info, file);
      }
    }
  }

  Future<void> _register(CustomFontInfo info, File file) async {
    if (_loaded.contains(info.family)) return;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(info.family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loaded.add(info.family);
  }
}
