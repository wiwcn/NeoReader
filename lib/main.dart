import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'data/services/custom_font_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop / CI analyze helpers: sqflite FFI when not on mobile.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // pdfrx wasm / native init (safe no-op when unavailable)
  try {
    await pdfrxFlutterInitialize();
  } catch (_) {
    // PDF still usable on platforms where init is optional.
  }

  try {
    await CustomFontService().registerAll();
  } catch (_) {
    // Font registration is best-effort; reading still works with NotoSansSC.
  }

  runApp(const ProviderScope(child: NeoReaderApp()));
}
