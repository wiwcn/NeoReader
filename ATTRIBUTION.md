# Attribution / 鸣谢

**NeoMedia**（仓库过渡名 NeoReader）的 Flutter 应用代码为原创实现。产品叙事是离线媒体中心：小说 · 漫画 · 音乐 · 设置。

## Koodo Reader

功能蓝本曾参考开源桌面 / Web 项目
[Koodo Reader](https://github.com/koodo-reader/koodo-reader)（AGPL-3.0）及其社区离线能力列表 —
作为「离线阅读器可以做什么」的产品清单灵感，**不是**移植或拷贝其源码树。

本仓库以 **GPL-3.0** 在 Flutter 上独立实现移动优先的离线体验（Material Design 3 + 毛玻璃、本地无限书库、无云 / 账号 / Pro）。

- Upstream: [koodo-reader/koodo-reader](https://github.com/koodo-reader/koodo-reader)
- Upstream license: GNU Affero General Public License v3.0
- Relationship: feature-list inspiration only

## Other inspiration（用户向）

- [Fushi](https://github.com/hajisensai/Fushi) — multimedia shell organization
- [Harmonoid](https://github.com/harmonoid/harmonoid) — calm Now Playing / music UI cues

## This project

- License: [GNU General Public License v3.0](./LICENSE) (GPL-3.0)
- Repository: <https://github.com/wiwcn/NeoReader>

If you redistribute NeoMedia / NeoReader (or a modified version), GPL-3.0 applies to the
codebase as distributed here. Third-party packages keep their own licenses
(see `pubspec.yaml` / pub.dev).

## Fonts

- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) (SIL Open Font License 1.1),
  bundled under `assets/fonts/` for offline CJK UI rendering.

## Motion / animation packages

- [`animations`](https://pub.dev/packages/animations) (BSD-3-Clause) — Flutter team's Material motion
  helpers (`SharedAxisTransition`, `FadeThroughTransition`, `OpenContainer`).
- [`flutter_staggered_animations`](https://pub.dev/packages/flutter_staggered_animations) (MIT) —
  staggered list/grid entrance animations.

## Sample album covers (CC0)

Square abstract textures from Wikimedia Commons (Mitchfeatherston), Creative Commons CC0 1.0 Universal.
Bundled (resized to 512×512) under `assets/samples/music/covers/` and `test/fixtures/music_covers/`.

| File | Source |
| --- | --- |
| cover1 | [1500x1500-abstract-dfg4001.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-dfg4001.jpg) |
| cover2 | [1500x1500-abstract-dfg4002.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-dfg4002.jpg) |
| cover3 | [1500x1500-abstract-dfg4003.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-dfg4003.jpg) |
| cover4 | [1500x1500-abstract-dfg4005.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-dfg4005.jpg) |
| cover5 | [1500x1500-abstract-dfg4006.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-dfg4006.jpg) |
| cover6 | [1500x1500-abstract-sd2003.jpg](https://commons.wikimedia.org/wiki/File:1500x1500-abstract-sd2003.jpg) |

License: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

## Sample music (CC0)

Short instrumental tracks by **Ondrosik**, CC0 1.0, from the Internet Archive collection
[Ondrosik-Free-music-catalog](https://archive.org/details/Ondrosik-Free-music-catalog).
Bundled under `assets/samples/music/` (re-encoded 128 kbps MP3 for size).

| File | Title | Author | License | Link |
| --- | --- | --- | --- | --- |
| `fairitale.mp3` | Fairitale | Ondrosik | CC0 1.0 | [Archive item](https://archive.org/details/Ondrosik-Free-music-catalog) |
| `interlude.mp3` | Interlude | Ondrosik | CC0 1.0 | [Archive item](https://archive.org/details/Ondrosik-Free-music-catalog) |
| `dancing_needles.mp3` | Dancing needles | Ondrosik | CC0 1.0 | [Archive item](https://archive.org/details/Ondrosik-Free-music-catalog) |
| `forward_momentum.mp3` | Forward Momentum | Ondrosik | CC0 1.0 | [Archive item](https://archive.org/details/Ondrosik-Free-music-catalog) |

Collection license URL: <https://creativecommons.org/publicdomain/zero/1.0/>

