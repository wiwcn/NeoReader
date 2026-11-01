# NeoMedia

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)
[![Offline](https://img.shields.io/badge/%E7%BA%AF%E7%A6%BB%E7%BA%BF-%E6%97%A0%E8%B4%A6%E5%8F%B7%E6%97%A0%E4%BA%91-success)](#)
[![Platform](https://img.shields.io/badge/Android%20%2F%20iOS-green)](#)

**你的本地媒体中心 — 小说 · 漫画 · 音乐 · 设置，全在一台手机上。**

NeoMedia 面向想把书、漫画和音乐都留在自己设备里的人：打开就能读、打开就能听，**不需要账号，没有云同步，也没有 Pro 墙**。界面走 Material Design 3：内容卡片用实色表面，顶栏 / 底栏保留轻度毛玻璃，浅色与深色都清晰可读。

> 仓库与应用过渡名曾用 **NeoReader**；产品叙事以 **NeoMedia** 为准。

**仓库：** <https://github.com/wiwcn/NeoReader>  
English → [README.md](./README.md)

---

## 核心承诺

- **纯离线** — 内容、进度、歌单都在本机
- **无账号 / 无云 / 无 Pro** — 下载下来就能用，没有订阅门槛
- **一壳四页** — 小说、漫画、音乐、设置，底部一键切换
- **MD3 + 安静 chrome** — 实色卡片、轻量毛玻璃顶栏/底栏，适合长时间阅读
- **开箱即读即听** — 首次打开会种入若干 **带封面的公版名著** 与 **CC0 示例曲**，方便马上体验

---

## 界面一览

浅色 / 深色各一套，来自真实界面组件截图（约 1080×2340）。书库截图中的书名为真实公版书名（Alice、Aesop、《詩經》等）。

### 壳：四页导航

| 小说书库 | 漫画 | 音乐 | 设置 |
| :---: | :---: | :---: | :---: |
| ![小说](docs/screenshots/light_shell_novels.png) | ![漫画](docs/screenshots/light_shell_comics.png) | ![音乐](docs/screenshots/light_shell_music.png) | ![设置](docs/screenshots/light_shell_settings.png) |

| 小说 · 深色 | 漫画 · 深色 | 音乐 · 深色 | 设置 · 深色 |
| :---: | :---: | :---: | :---: |
| ![小说深](docs/screenshots/dark_shell_novels.png) | ![漫画深](docs/screenshots/dark_shell_comics.png) | ![音乐深](docs/screenshots/dark_shell_music.png) | ![设置深](docs/screenshots/dark_shell_settings.png) |

### 音乐与阅读

| Now Playing | 专辑网格 | 迷你播放条 | 阅读器 |
| :---: | :---: | :---: | :---: |
| ![播放](docs/screenshots/light_music_now_playing.png) | ![专辑](docs/screenshots/light_music_albums.png) | ![迷你条](docs/screenshots/light_music_miniplayer.png) | ![阅读](docs/screenshots/light_reader_glass.png) |

| Now Playing · 深色 | 专辑 · 深色 | 迷你条 · 深色 | 阅读器 · 深色 |
| :---: | :---: | :---: | :---: |
| ![播放深](docs/screenshots/dark_music_now_playing.png) | ![专辑深](docs/screenshots/dark_music_albums.png) | ![迷你深](docs/screenshots/dark_music_miniplayer.png) | ![阅读深](docs/screenshots/dark_reader_glass.png) |

### 更多

| 空书库 | 阅读统计 |
| :---: | :---: |
| ![空](docs/screenshots/light_library_empty.png) | ![统计](docs/screenshots/light_stats.png) |

| 空书库 · 深色 | 统计 · 深色 |
| :---: | :---: |
| ![空深](docs/screenshots/dark_library_empty.png) | ![统计深](docs/screenshots/dark_stats.png) |

---

## 你能做什么

### 小说
把 EPUB、PDF、TXT、MOBI/AZW3、FB2、Markdown、HTML、DOCX 等本地文件放进书库，随时搜、排、继续读。字号、行距、日间 / 夜间 / 羊皮纸主题随手调；书签、笔记、高亮留在本机。阅读页带毛玻璃控件，读起来不抢戏。

### 漫画
单独的漫画页，专放 CBZ 等本地漫画。书架与小说分开，翻到想看的那一册即可。

### 音乐
扫描本机歌曲，在本地听完整专辑；Now Playing 用真实波形拖进度，而不是装饰性波浪。迷你播放条跟着你切换小说 / 漫画 / 设置，通勤路上也能一眼回到当前曲目。歌单、收藏、队列都在设备里。

### 设置与统计
浅色 / 深色、界面语言、阅读默认项一处搞定。阅读统计看得见今天读了多久、连续几天在读——纯本地，不上云。

### 示例内容
首次打开会种入一小架 **带封面的公版** 书（Project Gutenberg 名著，如 *Alice*、*Aesop*、*The Yellow Wallpaper*、*A Christmas Carol*，以及中文《詩經》）、一本自有抽象示例漫画，以及 **CC0** 器乐示例曲，方便开箱体验。随时可用自己的书与歌替换；来源与许可见 [ATTRIBUTION.md](./ATTRIBUTION.md)。

---

## 平台

Android / iOS。

---

## 展望

接下来更想把体验做满，而不是堆概念：

- 音乐再精致一点：均衡器、更顺手的队列与歌词呈现
- 漫画再完整一点：更多压缩格式与更舒服的翻页手势
- 阅读器再贴心一点：竖排与双栏、本机词典 / TTS（仍保持离线）
- 壳层再稳一点：导入批量、书库整理与本地备份更省心
- 更远一点：GalGame 等本地互动内容（不急，先把现有三页用爽）

---

## 灵感

多媒体壳层的组织方式受到 [Fushi](https://github.com/hajisensai/Fushi) 启发；音乐 Now Playing 的安静气质参考了 [Harmonoid](https://github.com/harmonoid/harmonoid)。它们都是优秀的开源作品，NeoMedia 以自己的 Flutter 实现走离线路线。

---

## 许可

[GNU General Public License v3.0](./LICENSE)（GPL-3.0）。

---

## 鸣谢

功能蓝本曾参考开源项目 [Koodo Reader](https://github.com/koodo-reader/koodo-reader) 的离线能力列表；本仓库的 Flutter 代码为独立实现。字体、示例书 / 示例曲、动效包与其他致谢见 [ATTRIBUTION.md](./ATTRIBUTION.md)。
