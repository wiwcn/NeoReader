# NeoReader

**NeoReader** is a brand-new **Flutter** offline ebook reader (mobile-primary:
Android / iOS). Feature blueprint: open-source
[Koodo Reader](https://github.com/koodo-reader/koodo-reader) offline scope
(AGPL-3.0). UI: **Material Design 3 + frosted glass (毛玻璃)**.

- Pure offline — **no** account, sync, cloud drive, Pro, or online updates
- **Unlimited** local books (no 20-book free-tier gate)
- Platforms: Android **10+ (API 29)**, iOS **12.0+**, Web (dev), Linux (analyze)

> Inspired by Koodo Reader; not a code port of its Electron UI. See
> [ATTRIBUTION.md](./ATTRIBUTION.md). Licensed under **AGPL-3.0**.

## Features (v1)

| Area | Status |
|------|--------|
| Library list / search / sort / delete | Done |
| Import EPUB / PDF / TXT | Done |
| EPUB reader (scroll/page, theme, progress) | Done |
| PDF reader (pdfrx, zoom, progress) | Done |
| TXT reader + themes | Done |
| Bookmarks / notes / highlights (local DB) | Done |
| ZH/EN UI, day/night/sepia reading themes | Done |
| Reading time stats (today / total / per book) | Done (NeoReader+) |
| mobi/azw3, fb2, comics, md/docx/html, TTS, dict, OCR, vertical, 2-col, export, PIN… | Planned — see [ROADMAP.md](./ROADMAP.md) |

## Offline policy

No network account features. Import is local-file only. Remaining Koodo items
are tracked in the roadmap and scaffolded as modules — **一个不少**.

## HarmonyOS / OpenHarmony notes

Flutter Android APKs often sideload on **HarmonyOS** devices that keep an
Android compatibility layer (older HarmonyOS 2–4.x). **HarmonyOS NEXT /
OpenHarmony** without Android APIs need a separate OpenHarmony/Flutter embedder
target — not shipped in v1. NeoReader avoids exotic Google-only Play APIs in the
core path (local files + sqflite + pdfrx). Expect to validate sideload on your
device; NEXT-native packaging is future work.

## Requirements

- Flutter SDK 3.47+ (`/home/box/flutter` on the build box)
- Android SDK (API 29+) for APK; Xcode for iOS

```bash
export PATH="/home/box/flutter/bin:$PATH"
export ANDROID_HOME=/home/box/Android/Sdk   # if installed
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## Run

```bash
cd koodo-flutter-offline-app   # or your clone root
flutter pub get
flutter analyze
flutter run                    # device / emulator
# or open the folder in Android Studio / VS Code and Run
```

### Build debug APK

```bash
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

If Android SDK is missing:

1. Install Android Studio or cmdline-tools
2. `sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"`
3. Accept licenses: `yes | sdkmanager --licenses`
4. Re-run `flutter build apk`

## Architecture

```
lib/
  core/           theme (MD3+glass), l10n, constants
  domain/         models + repository interfaces
  data/           sqflite, parsers (EPUB/TXT), import, stats
  presentation/   Riverpod + Material screens
```

Key packages: `flutter_riverpod`, `file_picker`, `path_provider`, `sqflite`,
`pdfrx`, `archive`+`xml`+`html` (custom EPUB), `shared_preferences`, `uuid`.

## License

[AGPL-3.0](./LICENSE) — see also [ATTRIBUTION.md](./ATTRIBUTION.md).
