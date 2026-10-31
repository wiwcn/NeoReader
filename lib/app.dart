import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'domain/models/app_settings.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/home/home_shell.dart';

class NeoReaderApp extends ConsumerWidget {
  const NeoReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final strings = ref.watch(stringsProvider);

    return MaterialApp(
      title: 'NeoReader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.seedColor),
      darkTheme: AppTheme.dark(settings.seedColor),
      themeMode: settings.flutterThemeMode,
      locale: Locale(settings.isZh ? 'zh' : 'en'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
      onGenerateTitle: (_) => strings.appTitle,
    );
  }
}
