# NeoReader

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Android%2010%2B%20%7C%20iOS%2012%2B-green)](#platform-targets)
[![Offline](https://img.shields.io/badge/offline--only-no%20cloud-success)](#)

**NeoReader** is a free, open-source **offline ebook reader** for Android and iOS, built with Flutter.  
Material Design 3 + frosted glass (毛玻璃). Unlimited local library. **No accounts, sync, cloud, or Pro paywall.**

Feature scope is inspired by [Koodo Reader](https://github.com/koodo-reader/koodo-reader)’s offline capabilities; the Flutter codebase is original (see [ATTRIBUTION.md](./ATTRIBUTION.md)).

**Repo:** <https://github.com/wiwcn/NeoReader>

| | |
|---|---|
| 中文说明 | [README_cn.md](./README_cn.md) |
| Roadmap | [ROADMAP.md](./ROADMAP.md) |
| License | [GPL-3.0](./LICENSE) |

## Screenshots

Real UI captures from the NeoReader Flutter widgets:

| Library (empty) | Library | Import FAB |
| :---: | :---: | :---: |
| ![empty](docs/screenshots/01_library_empty.png) | ![library](docs/screenshots/02_library_with_books.png) | ![import](docs/screenshots/03_import_fab.png) |

| Stats | Settings | Reader |
| :---: | :---: | :---: |
| ![stats](docs/screenshots/04_stats.png) | ![settings](docs/screenshots/05_settings.png) | ![reader](docs/screenshots/06_reader_txt_glass.png) |

## Features

### Working now

| Area | Details |
|------|---------|
| Library | Import, search, sort, delete — **unlimited** books, all on-device |
| Formats | **EPUB**, **PDF**, **TXT**, **MOBI/AZW/AZW3** (DRM-free text), **FB2**, **CBZ** (+ ZIP-based CBR), **Markdown**, **HTML/XHTML/MHTML**, **DOCX** (text extract) |
| Reading | Themes (day / night / sepia), font size & line height, progress, bookmarks / notes |
| Stats | Today / total reading time, per-book duration (beyond Koodo) |
| Design | MD3 `ColorScheme.fromSeed`, frosted glass surfaces, light & dark |
| Privacy | Offline-only by design |

### Roadmap (scaffolded)

Vertical / two-column layouts, TTS, local dictionary, OCR, note export, PIN lock, full RAR/7z comics (CBR/CBT/CB7), richer charts — see [ROADMAP.md](./ROADMAP.md). Goal: Koodo offline feature parity **一个不少**, plus NeoReader extras.

## Platform targets

- **Android:** minSdk **29** (Android 10+)
- **iOS:** deployment target **12.0+**
- **HarmonyOS:** Android APK often sideloads via compatibility layer. NeoReader avoids exotic Google-only APIs where practical. Native HarmonyOS NEXT / OpenHarmony packaging is not claimed yet; DRM and some system APIs may differ.

## Quick start

```bash
git clone https://github.com/wiwcn/NeoReader.git
cd NeoReader
flutter pub get
flutter run
```

First launch seeds demo books from `assets/samples/` (TXT, MD, HTML, FB2, CBZ, DOCX).

## Build APK

```bash
flutter pub get
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# Release requires your own keystore:
# flutter build apk --release
```

## Project layout

```
lib/
  data/parsers/     # EPUB, FB2, MOBI, comic, HTML, MD, DOCX, …
  presentation/     # Library, readers, stats, settings (MD3 + glass)
  domain/           # Models & repository interfaces
assets/samples/     # Demo books for first-run / screenshots
```

## Contributing

Issues and PRs welcome. Please keep the offline-only policy (no cloud sync / account / Pro). Match existing MD3 + glass style when touching UI. Run `flutter analyze` before opening a PR.

## License

[GNU General Public License v3.0](./LICENSE) — **GPL-3.0**.

NeoReader is original Flutter code. Koodo Reader is credited as **feature inspiration** only; we do not distribute Koodo’s AGPL sources. See [ATTRIBUTION.md](./ATTRIBUTION.md).
