import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import 'reading_controls.dart';

Future<void> showReadingControls({
  required BuildContext context,
  required WidgetRef ref,
  required AppSettings settings,
  VoidCallback? onAddBookmark,
  VoidCallback? onAddNote,
}) async {
  final strings = ref.read(stringsProvider);
  final fontService = ref.read(customFontServiceProvider);
  var fonts = await fontService.listFonts();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      var local = settings;
      var localFonts = fonts;
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: ReadingControlsSheet(
              strings: strings,
              settings: local,
              customFonts: localFonts,
              onChanged: (s) {
                setModal(() => local = s);
                ref.read(settingsProvider.notifier).saveSettings((_) => s);
              },
              onImportFont: () async {
                try {
                  final files = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['ttf', 'otf'],
                  );
                  if (files.isEmpty) return;
                  final path = files.first.path;
                  if (path == null) return;
                  final info = await fontService.importFont(path);
                  localFonts = await fontService.listFonts();
                  local = local.copyWith(customFontFamily: info.family);
                  setModal(() {});
                  await ref
                      .read(settingsProvider.notifier)
                      .saveSettings((_) => local);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${strings.fontImported}: ${info.displayName}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('${strings.fontImportFailed}: $e'),
                      ),
                    );
                  }
                }
              },
              onDeleteFont: (family) async {
                await fontService.deleteFont(family);
                localFonts = await fontService.listFonts();
                if (local.customFontFamily == family) {
                  local = local.copyWith(clearCustomFont: true);
                  await ref
                      .read(settingsProvider.notifier)
                      .saveSettings((_) => local);
                }
                setModal(() {});
              },
              onAddBookmark: onAddBookmark,
              onAddNote: onAddNote,
            ),
          );
        },
      );
    },
  );
}
