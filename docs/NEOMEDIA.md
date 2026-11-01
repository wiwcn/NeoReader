# NeoMedia 设计文档

> NeoReader → **NeoMedia**：离线优先的聚合媒体中心  
> **Primary reference: [Fushi](https://github.com/hajisensai/Fushi)**（站点 [fushi.moe](https://fushi.moe/)）  
> Primary: 中文 · Short EN notes where helpful

---

## 1. Vision / 愿景

将现有 **NeoReader**（纯离线电子书阅读器）演进为 **NeoMedia**：同一应用内聚合多类本地媒体，统一隐私原则与视觉语言。

**定位（EN）:** *An offline-first media hub inspired by Fushi’s multi-media shell — not an immersion / Anki mining clone.*

| 模块 | 中文 | 对照 Fushi 媒体面 | NeoMedia 状态 |
|------|------|-------------------|---------------|
| Novel / Books | 小说 · 电子书 · 有声书 | Fushi Books（EPUB / 小说 / audiobook sync） | 已有 NeoReader 书库与多格式阅读器；有声书后期 |
| Comic / Manga | 漫画 | Fushi Manga（本地 + OCR 查词） | 已有 CBZ 等；后续补全 CBR/CBT/CB7；**不做查词 OCR 作核心** |
| Video | 视频 | Fushi Video（字幕点击查词 / 媒体服务器） | **可选延后**；非第一主线 |
| Music | 音乐 | Fushi **弱项**（沉浸/查词/Anki 强，非 Feishin 级本地音乐库） | **下一阶段主线**：完整本地音乐库 + 播放器 |
| GalGame | 视觉小说 / Gal | Fushi Games（Windows 文本/语音 hook） | **延后**；先占位 IA，不做引擎 / hook |

**产品原则**

- **Offline-first（离线优先）**：本地扫描与本地播放是默认路径；网络能力一律可选、默认关闭。
- **媒体中心，不是沉浸套件**：借 Fushi 的「一个壳、多媒体域」信息架构；**不把 Anki 制卡 / 词典查词 / 沉浸学习当作核心产品**（除非日后用户明确要求再开专题）。
- **音乐是第一大增量**：Fushi 覆盖书 / 漫 / 视 / 听 / Gal 的壳很完整，但对「专业本地音乐库」不如独立播放器；NeoMedia 用音乐补齐短板。**Music UI 主参考 = Harmonoid**（极简 Now Playing、大封面轮播、干净浅色 MD3-ish）；Namida / Retro Music / Auxio / Feishin / Aura 等仅作次要风格对照。
- **美观、易用、功能扎实**：延续 MD3 + 毛玻璃；可参考 Fushi 的 M3 Expressive / Cupertino 双系思路作后期选项，MVP 仍统一现有 Theme。
- **一个壳、多媒体域**：底部 Tab 切换域；各域共享设置 / 主题 / 隐私策略，数据表与导入路径可分域。

---

## 2. Privacy & License / 隐私与许可

与 NeoReader 一致，**不因转型而引入账号体系**：

- 无账号、无云同步、无官方云盘、无 Pro / 内购墙  
- 不强制遥测；若将来加诊断日志，须显式 opt-in  
- 可选「自建媒体服务器」（如 Subsonic / OpenSubsonic / Jellyfin）= 用户自己的服务器，**不是**我们的云  
- 许可继续 **GPL-3.0**（见仓库根目录 `LICENSE`；与 Fushi 同为 GPL-3.0，但**代码独立**，不 fork）  
- EN: *No account / cloud / Pro. Optional self-hosted APIs only. GPL-3.0. Inspired by Fushi’s shell, not a fork.*

---

## 3. Primary reference: Fushi / 主参考

用户澄清「feshi / fushi」指的是 **[Fushi](https://github.com/hajisensai/Fushi)**（[fushi.moe](https://fushi.moe/)），**不是** Feishin。

Fushi 是 Flutter **GPL-3.0** 沉浸式语言学习套件：EPUB 阅读、视频字幕查词、漫画 OCR、Galgame 文本/语音 hook（Windows）、有声书同步、一键 Anki 制卡；设计系统 Material 3 Expressive / Cupertino；技术栈含 Riverpod、media_kit、Drift 等。

### 3.1 借什么 · 不借什么（相对 Fushi）

| 借 (Borrow) | 不借 / 明确不做为核心 (Avoid as core) |
|-------------|----------------------------------------|
| **多媒体壳**：Home / Books / Video / Manga / Games / Settings 分域心智 | **Anki mining**、Lapis note type、AnkiConnect / AnkiDroid 制卡流水线 |
| 本地书库 + 漫画库 +（可选）视频库的「一个应用装下」叙事 | **词典查词弹层**、Yomitan / MDX 沉浸查词、音高 / 词频作为主路径 |
| EPUB / 小说阅读体验方向；有声书与文本同步的产品想象（后期） | 以「边看边学」为默认 onboarding；语言学习引导作为产品中心 |
| 漫画本地库与阅读手势；OCR **仅作 ROADMAP 知识工具可选**（与 Koodo 本地 OCR 条目一致），非查词主线 | Google Lens / 云 OCR 默认路径；漫画「点气泡制卡」 |
| GalGame **库管理 / 元数据 / 启动入口** 的 IA（参考其 Games 域） | Windows 文本 hook / 语音注入 / 游戏内查词（P5 之前不做） |
| 可选 Jellyfin / Emby / Plex 作为**后期**媒体源形状 | BitTorrent / Nyaa / 扩展源下载中心、订阅追番作为 MVP |
| M3 Expressive + 可选 Cupertino 的双设计系思路（后期） | 照搬 Fushi 品牌、皮肤或包结构 |
| Flutter + 强本地存储（Fushi 用 Drift；我们可继续 sqflite 或日后评估 Drift） | Riverpod / media_kit **强制**换栈——与现有模块对齐优先，选型单独立项 |
| 隐私默认本地、可选自建同步的分层思想 | 云同步 / Interconnect / 使用统计上报 |

**一句话**：Fushi = **多媒体壳 + 沉浸学习**；NeoMedia = **多媒体壳 + 离线媒体中心**，并用 **完整本地音乐播放器** 作为 Fushi 相对薄弱处的第一大补强。

EN: *Shell yes. Anki / dictionary immersion no (unless later asked). Local music player = first big add.*

---

## 4. Music UI & player references / 音乐 UI 与播放器参考

> **决策（2026-11）**：Music 域 **UI 主参考 = [Harmonoid](https://github.com/harmonoid/harmonoid)**。  
> Shell / 多媒体 IA 仍以 **Fushi** 为主（见 §3）；本节只约束 **音乐播放与 Now Playing 视觉/交互**。

### 4.1 Primary UI: Harmonoid

Harmonoid（跨平台本地音乐播放器）作为 NeoMedia Music **视觉与 Now Playing 交互的第一参考**：

| 借（UI / UX） | 不借 / 慎用 |
|---------------|-------------|
| **极简 Now Playing**：大封面、少控件、信息层级干净 | 照搬其品牌色 / 图标 / 桌面窗口壳 |
| **大封面轮播（carousel）**：左右滑切歌、封面主导视觉 | 强制依赖其媒体库实现或插件架构 |
| **干净浅色 MD3-ish** 观感：轻量、留白、可读 | 装饰性正弦 / 波浪路径当作「假波形」进度条 |
| 列表 / 专辑网格的克制排版思路 | 与现有 NeoReader 毛玻璃 / ThemeExtension 冲突的第二套皮肤 |

EN: *Music UI primary = Harmonoid (minimal now-playing, large cover carousel, clean light MD3-ish). Not a fork.*

### 4.2 Decision: real audio-track waveform seekbar（真实音轨波形）

用户明确要求：把 Harmonoid 式装饰波浪 seekbar **换成真实音轨波形**，并加少量「小巧思」。

| 决策 | 说明 |
|------|------|
| **Seekbar = 预计算振幅波形** | **不是**装饰用 sine / Bezier「假波浪」path；展示该文件真实（或下采样后的）振幅峰 |
| **生成时机** | 导入 / 扫描时生成 peaks（可选实现：`just_audio` 解码采样、ffmpeg、或 `audio_waveforms` 一类包）；**按文件缓存**（path + mtime/size 作 key），避免每次打开 Now Playing 重算 |
| **交互** | scrubbing 走波形区域 hit-testing（横向位置 → 时间）；松手 seek；拖动中可预览时间 |
| **视觉语言** | 保持 **MD3 frost / NeoReader glass wash**；波形可半透明叠在磨砂底上；**opaque sheets 规则仍适用**（底 sheet / 对话框不透底） |
| **性能** | peaks 低分辨率即可（如每秒 N 个桶）；UI 侧再抽稀绘制；大库后台队列生成，不阻塞首播 |

EN: *Seekbar = real precomputed amplitude waveform, cached per file; scrub via waveform hit-testing; keep MD3 frost aesthetic.*

#### 已约定小巧思（flourishes）

| 优先级 | 小巧思 | 说明 |
|--------|--------|------|
| 必做倾向 | **Scrub 局部放大** | 手指按下拖动时，指下附近波形段 magnify / zoom，便于精确定位 |
| 可选轻量 | **Playhead 软光晕** | 播放头带 soft glow，可随 beat / 当前 amp **轻度脉冲**（务必轻量，可关） |
| 可选轻量 | **Pause 呼吸** | 暂停时波形做 gentle breathing idle（透明度或微幅缩放），表示「未死、可继续」 |
| 有余力 | **封面取色着色** | 用专辑封面 dominant color 轻染波形（仍服从主题对比度） |
| 有余力 | **双击封面收藏** | double-tap cover → favorite / 喜欢 |
| 有余力 | **滑动封面切歌** | 沿用 Harmonoid carousel：swipe cover → next / prev |

实现阶段再拆任务；本文档先锁定产品意图，**暂不写 Flutter 代码**。

### 4.3 Secondary style / capability refs only（次要风格与能力对照）

下列项目**降为次要**：可对照库能力、列表密度或个别控件，**不再**主导 Now Playing 视觉。

#### Feishin

自托管音乐客户端（[jeffvli/feishin](https://github.com/jeffvli/feishin)）。曾被误当作「feshi」主参考；现仅音乐次要参考。

| 借 | 不借 / 慎用 |
|----|-------------|
| 艺人 → 专辑 → 曲目；队列与「下一首 / 加到队列」 | 强依赖 Jellyfin / Navidrome / Subsonic 才能用（MVP **先本地**） |
| 播放队列、智能/普通播放列表心智 | MPV / 桌面双后端复杂度 |
| 歌词展示交互思路 | Last.fm / ListenBrainz 等云端 scrobble（默认不做） |
| OpenSubsonic 兼容作为**可选增强**的 API 形状 | 多服务器 / 远程控制 / DLNA（后期可选） |

#### Namida（Flutter）

| 借 | 不借 / 慎用 |
|----|-------------|
| 本地索引器、文件夹库、防重复、丰富排序 | YouTube 流媒体 / 下载中心 |
| 可靠队列持久化、历史与「最常播放」 | Listening Party、跨设备强制同步 |
| 播放列表 + 规则智能列表思路 | 重度视频站内播放器；Now Playing 视觉不压过 Harmonoid |

#### Retro Music / Auxio（Android 风格对照）

| 借 | 不借 / 慎用 |
|----|-------------|
| 清晰的本地库浏览密度、通知栏 / 媒体会话习惯 | Material 旧版或第三方主题引擎整套搬入 |
| 部分列表 / 专辑页信息架构灵感 | 替代 Harmonoid 作为 Now Playing 主参考 |

#### Aura（Flutter，local-first）

| 借 | 不借 / 慎用 |
|----|-------------|
| Local-first：无广告、无云、无追踪 | 过早上齐 karaoke / 10 段 EQ |
| Miniplayer → 全屏 Now Playing 动效思路 | 在线歌词作为唯一歌词路径（本地 LRC 优先） |
| Songs / Albums / Artists 浏览 + 搜索 | 破坏现有 MD3 + frost 统一感的另一套品牌皮肤 |

#### Linthra 等「本地 + 可选服务器」客户端

| 借 | 不借 / 慎用 |
|----|-------------|
| 本地为主、Jellyfin / Navidrome / Subsonic 为可选层 | 一上来就做全服务器矩阵 |
| 后台播放、锁屏控件、可选离线缓存心智 | 把服务器做成必填 onboarding |

**音乐总结**：**UI = Harmonoid**（+ 真实波形 seek 与约定小巧思）；Feishin 管「库浏览 + 队列」专业感；Aura / Namida / Retro / Auxio 管本地索引与风格边角；Subsonic 系 API 仅 **Later / Optional**。产品仍 **offline-first**，**不以 Anki / 沉浸查词为核心**。

---

## 5. Information Architecture / 信息架构

### 5.1 对照 Fushi 壳 → NeoMedia Tab（草案）

Fushi 大致：`Home · Books · Video · Manga · Games · Browse · Settings`  
NeoMedia（离线媒体中心，MVP 更收）：

```
[ 阅读 ]  [ 漫画 ]  [ 音乐 ]  [ 更多/设置 ]
  Novel    Comic    Music     More
```

| Fushi 域 | NeoMedia 对应 |
|----------|----------------|
| Books | **阅读** Tab（小说 / EPUB；有声书后期挂此域或子入口） |
| Manga | **漫画** Tab（可先用格式过滤挂在阅读域，再拆出） |
| Video | **更多 → 实验 / 路线图**（延后；非主 Tab） |
| Games | **更多 → 实验**（GalGame 占位，不占主 Tab） |
| （Fushi 无独立 Music） | **音乐** Tab = NeoMedia 相对 Fushi 的主增量 |
| Browse / 下载 / 扩展源 | **不做**为默认能力；可选自建服务器后期入口放「更多」 |
| Settings | **更多**（设置、关于、统计、实验开关） |

- GalGame：**不占主 Tab**，仅在「更多 → 实验 / 路线图」说明「已规划、未开工」。  
- EN: *Bottom tabs mirror Fushi’s multi-media shell, minus immersion chrome; Music is our first-class add; GalGame / Video deferred.*

### 5.2 音乐库结构

```
音乐
├── 浏览
│   ├── 歌曲 (Tracks)
│   ├── 专辑 (Albums)
│   ├── 艺人 (Artists)
│   ├── 文件夹 (Folders)     ← 可选，利于无标签文件
│   └── 播放列表 (Playlists)
├── 播放中 (Now Playing / Queue)
│   ├── 迷你条 (Mini player，全局底栏上方)
│   └── 全屏页 + 队列编辑
└── 库管理
    ├── 扫描文件夹 / 增量刷新
    ├── 忽略路径、最小时长/体积过滤
    └── （后期）标签编辑、封面修复
```

搜索：跨 歌曲 / 专辑 / 艺人 的本地搜索；结果可「播放 / 加入队列 / 加入歌单」。

---

## 6. Music checklists / 音乐功能清单

### 6.1 MVP（下一阶段必须可演示）

- [x] 选择文件夹 / 媒体库路径并 **本地扫描**（音频扩展名白名单）
- [x] 解析基础标签与封面（title / artist / album / track / duration；嵌入封面或同目录 `cover.jpg`）
- [x] 库浏览：歌曲、专辑、艺人；排序与简单搜索
- [x] 播放引擎：`just_audio` + `audio_service`（后台、通知栏 / 锁屏、耳机键）
- [x] 队列：播放、下一首、加入队列、清空、基本重排；持久化当前队列
- [x] 播放模式：顺序 / 循环列表 / 单曲循环 / 随机
- [x] 用户播放列表：新建 / 重命名 / 删除 / 增删曲目；导入导出 `.m3u` / `.m3u8`（至少导出）
- [x] Miniplayer + 全屏 Now Playing（Harmonoid 向：大封面轮播、极简控件、干净浅色 MD3-ish）
- [x] **真实波形 seekbar**（预计算振幅 peaks，按文件缓存；scrub hit-testing；非装饰波浪）
- [x] 约定小巧思：scrub 局部放大；可选 playhead amp 脉冲 / pause 呼吸；有余力则封面取色、双击收藏、滑动切歌
- [x] 与现有 MD3 + 毛玻璃视觉统一；中英设置项
- [x] 无账号、默认真离线（扫描与播放不访问网络）

> **LG G8 ThinQ**：适配重点为 **Hi-Fi Quad DAC / 有线高音质路径、Boombox 正常媒体音量、耳机媒体键**（见 `lib/music/README.md`）；非仅屏幕尺寸。`audio_session` 使用 USAGE_MEDIA + CONTENT_TYPE_MUSIC。

### 6.2 Enhance（MVP 后增强）

- [ ] 睡眠定时、播放速度、（可选）交叉淡化 / 跳过静音
- [ ] 历史、最常播放、最近添加等自动列表
- [ ] 规则型智能歌单（本地规则：流派、年份、播放次数等）
- [ ] 波形生成管线打磨（后台队列、失败回退普通 slider）；Now Playing 动效与取色细化
- [ ] 均衡器（系统 / equalizer 插件，视平台能力）
- [ ] 文件夹视图、多根目录、扫描排除规则打磨
- [ ] 基础标签编辑与封面替换（谨慎写回文件，需确认对话框）
- [ ] 本地歌词：**同名 `.lrc` / 内嵌歌词** 优先；同步滚动 UI
- [ ] 播放统计（可与阅读统计分域展示）

### 6.3 Later（更后 / 可选）

- [ ] 在线歌词源（LRCLIB 等）—— **默认关**，用户显式开启
- [ ] 词级 / karaoke 歌词、歌词编辑器
- [ ] **可选 Subsonic / OpenSubsonic / Navidrome 客户端**（用户自建服务器；可浏览与流式播放；可选缓存到本地）
- [ ] Jellyfin 音乐库只读客户端（非优先）
- [ ] Android Auto / CarPlay、桌面端专项、投屏 / DLNA
- [ ] ReplayGain、进阶 DSP、多输出设备
- [ ] 与 Feishin 级「智能服务端歌单」对齐（依赖服务器；次要参考）

EN: *MVP = local scan + just_audio/audio_service + queue + playlists. Lyrics later. Optional Subsonic later.*

---

## 7. Tech stack draft / 技术栈草案

| 层级 | 选型（草案） | 备注 |
|------|----------------|------|
| 应用框架 | Flutter 3.x（现有） | 与 NeoReader 同仓演进；Fushi 亦 Flutter，可对照不照搬 |
| 本地元数据 DB | `sqflite` / 现有 DB 扩表，或独立 `neo_music.db` | 书籍与音乐表隔离；日后可评估 Drift（Fushi 所用） |
| 音频播放 | `just_audio` | 本地 file / 日后 uri；视频域若做可另评 media_kit |
| 后台与系统媒体会话 | `audio_service`（+ `audio_session`） | 通知栏、锁屏、中断处理 |
| 媒体扫描 | `path_provider` + 自研扫描器；权限用现有/补充 SAF 或媒体权限 | Android 10+ 注意分区存储 |
| 标签 / 封面 | 成熟 Dart/FFI 标签库（选型时锁定一种，如 metadata_god 等） | 需在实现阶段写清 license |
| 状态管理 | 与现有阅读模块对齐（不新开一套「宗教」） | 音乐域可模块化 `lib/music/`；Riverpod 非强制 |
| 播放列表文件 | `.m3u` / `.m3u8` 读写 | 互操作 |
| 可选网络 | OpenSubsonic HTTP API（Later） | Feature flag；默认不走主路径 |
| UI | Material 3 + 现有毛玻璃组件；Music Now Playing **对齐 Harmonoid** | 与阅读器同一 ThemeExtension；Cupertino / Expressive 后期可选 |
| 波形 peaks | 扫描/导入时预计算并缓存；绘制可用自研 CustomPainter 或 `audio_waveforms` 等 | **真实振幅**，非装饰 path；实现阶段锁定具体包与 license |

**不做（MVP）**：自研解码器、强制性云歌词、账号 SSO、Anki 管线、词典沉浸弹层。

---

## 8. Phased roadmap / 分阶段路线

| 阶段 | 内容 | 状态意向 |
|------|------|----------|
| **P0** | NeoReader 既有能力维持；本设计文档以 **Fushi 为主参考** 校正落地 | 文档 ✅ |
| **P1 — Music MVP** | 本地扫描、库浏览、just_audio + audio_service、队列、用户歌单、Harmonoid 向 Now Playing、**真实波形 seek**（含基础 scrub 放大）；G8 DAC/媒体会话 | **Done (MVP)** |
| **P2 — Music Enhance** | 智能/自动列表、本地歌词 UI、EQ/速度/睡眠、库管理打磨；波形取色 / playhead 脉冲 / pause 呼吸等小巧思细化 | 其后 |
| **P3 — Comic polish** | 完整 RAR/7z 漫画、漫画专用阅读手势与目录 | 与 P2 可并行部分项 |
| **P4 — Optional servers** | Subsonic / OpenSubsonic（及可选 Jellyfin 只读）可选连接 + 缓存 | Later |
| **P5 — GalGame** | 库入口 / 元数据；引擎选型、脚本/资源包、存档；**明确延期**（不做 Fushi 式 hook） | Deferred |
| **P6 — Video（可选）** | 本地视频库轻量播放；**不做字幕查词 / 制卡** | Deferred |
| 持续 | ROADMAP 中 NeoReader「一个不少」条目不删除，继续清债 | Ongoing |

GalGame / Video：仅保留愿景与目录占位，**不排进近期 sprint**，避免拖慢音乐主线。

---

## 9. Naming & repo migration / 命名与仓库

| 项 | 建议 |
|----|------|
| 产品名 | 对外逐步使用 **NeoMedia**；过渡期文案可写「NeoMedia（由 NeoReader 演进）」 |
| 应用显示名 | 可先改 Android `label` / iOS `CFBundleDisplayName`，或设置内「关于」说明 |
| Dart package / 目录 | 短期内可保留 `koodo_flutter_offline` 等历史名；新代码用 `lib/music/`、`lib/comic/` 分域 |
| GitHub 仓库 | 现为 `wiwcn/NeoReader`；更名 `NeoMedia` 需单独决策（Redirect 旧名、更新 README badge、文档链接） |
| 文档 | 本文件为权威设计入口：`docs/NEOMEDIA.md`；`ROADMAP.md` 顶部链到此处 |
| 品牌 | **暂不**全面重写 README 主标题与截图区；方向说明见 `README_cn.md` |
| 与 Fushi 关系 | **灵感 / 壳对照**，非 fork；致谢可写在 ATTRIBUTION 或本文件，不混用商标 |

EN: *Docs-first rename. Repo/package rename is a separate, explicit step. Inspired by Fushi, not a fork.*

---

## 10. Non-goals（本阶段明确不做）

- 账号、官方云同步、订阅制 Pro  
- 以 YouTube / 网易云等商业流媒体为中心的产品  
- **以 Anki 制卡 / 词典沉浸查词 / 语言学习引导为核心产品**（除非日后明确要求）  
- GalGame 可玩引擎或 Windows 文本/语音 hook（P5 之前）  
- 视频字幕点击查词、漫画 OCR 制卡流水线（非核心）  
- 为对齐 Feishin 而引入**必选**自建服务器  
- BitTorrent / 扩展源下载中心作为默认能力  
- 放弃 GPL-3.0 或引入与离线原则冲突的强制联网 SDK  

---

## 11. Open questions（实现前可再定）

1. 音乐库与书库是否共用一个 sqflite 文件（分表）还是独立 DB？是否评估 Drift？  
2. Android 扫描走 MediaStore 索引还是纯文件系统递归（或混合）？  
3. iOS 音乐文件导入路径（Files / 文档目录）与后台音频模式清单。  
4. 仓库是否正式改名为 NeoMedia，以及应用包名是否变更（影响升级路径）。  
5. Video / 有声书是否在音乐 MVP 之后单独开阶段，还是长期挂「更多 → 实验」。  

---

*Document status: design draft — shell ref Fushi · music UI ref Harmonoid + real waveform seek · 2026-11 · NeoMedia*
