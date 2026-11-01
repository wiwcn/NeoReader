# NeoMedia 设计文档

> NeoReader → **NeoMedia**：离线优先的聚合媒体中心  
> Primary: 中文 · Short EN notes where helpful

---

## 1. Vision / 愿景

将现有 **NeoReader**（纯离线电子书阅读器）演进为 **NeoMedia**：同一应用内聚合四类本地媒体，统一隐私原则与视觉语言。

| 模块 | 中文 | 说明 (EN) |
|------|------|-----------|
| Novel | 小说 / 电子书 | 已有 NeoReader 书库与多格式阅读器 |
| Comic | 漫画 | 已有 CBZ 等；后续补全 CBR/CBT/CB7 |
| Music | 音乐 | **下一阶段主线**：本地库 + 播放器 |
| GalGame | 视觉小说 / Gal | **延后**；先占位 IA，不做引擎 |

**产品原则**

- **Offline-first（离线优先）**：本地扫描与本地播放是默认路径；网络能力一律可选、默认关闭。
- **美观、易用、功能扎实**：延续 MD3 + 毛玻璃；音乐 UI 参考优秀开源播放器的信息架构与交互，而非照搬某一家皮肤。
- **一个壳、多媒体域**：底部 Tab 切换域；各域共享设置 / 主题 / 隐私策略，数据表与导入路径可分域。

---

## 2. Privacy & License / 隐私与许可

与 NeoReader 一致，**不因转型而引入账号体系**：

- 无账号、无云同步、无官方云盘、无 Pro / 内购墙  
- 不强制遥测；若将来加诊断日志，须显式 opt-in  
- 可选「自建媒体服务器」（如 Subsonic / OpenSubsonic）= 用户自己的服务器，**不是**我们的云  
- 许可继续 **GPL-3.0**（见仓库根目录 `LICENSE`）  
- EN: *No account / cloud / Pro. Optional self-hosted APIs only. GPL-3.0.*

---

## 3. Reference projects / 参考项目（借什么 · 不借什么）

用户提到的「feshi」对应 **[Feishin](https://github.com/jeffvli/feishin)**（自托管音乐客户端）。另参考 **Namida**、**Aura**、**Linthra** 等开源播放器做能力对照。

### 3.1 Feishin（feshi）

| 借 (Borrow) | 不借 / 慎用 (Avoid or later) |
|-------------|------------------------------|
| 清晰的媒体层次：艺人 → 专辑 → 曲目；队列与「下一首 / 加到队列」 | 强依赖 Jellyfin / Navidrome / Subsonic 才能用（我们 MVP **先本地**） |
| 播放队列、智能/普通播放列表心智模型 | MPV / 桌面端双后端复杂度 |
| 歌词展示交互思路（同步 / 非同步） | Last.fm / ListenBrainz 等云端 scrobble（与离线原则冲突，默认不做） |
| 主题与「现代、干净」布局节奏 | 多服务器切换、远程控制、DLNA 等（后期可选） |
| OpenSubsonic 兼容作为**可选增强**的 API 形状 | 服务端智能歌单编辑器（服务端特性，本地可用简化版规则） |

### 3.2 Namida（Flutter）

| 借 | 不借 / 慎用 |
|----|-------------|
| 本地索引器、文件夹库、防重复、丰富排序 | YouTube 流媒体 / 下载中心（非目标） |
| 可靠队列持久化、历史与「最常播放」 | Listening Party、跨设备强制同步 |
| 播放列表 + 基于规则的智能列表思路 | 重度视频站内播放器 |
| Tag 编辑、歌词编辑的产品完整度（后期） | 与「纯离线默认」冲突的在线依赖 |

### 3.3 Aura（Flutter，local-first）

| 借 | 不借 / 慎用 |
|----|-------------|
| **Local-first** 叙事与我们一致：无广告、无云、无追踪 | 过早上齐 karaoke 词级同步 / 10 段 EQ（可进 enhance） |
| Miniplayer → 全屏 Now Playing 动效与波形 seek 灵感 | 依赖在线歌词源作为唯一歌词路径（本地 LRC 优先） |
| Songs / Albums / Artists 浏览 + 搜索 | 把视觉做成「另一套品牌」而破坏 NeoReader MD3 统一感 |

### 3.4 Linthra 等「本地 + 可选服务器」客户端

| 借 | 不借 / 慎用 |
|----|-------------|
| 本地文件为主、Jellyfin / Navidrome / Subsonic 为可选层的分层 | 一上来就做 Plex / 全服务器矩阵 |
| 后台播放、锁屏控件、可选离线缓存心智 | 把服务器做成必填 onboarding |

**总结一句**：Feishin 管「库浏览 + 队列 + 列表」的专业感；Aura / Namida 管「本地索引与 Flutter 播放体验」；Subsonic 系 API 仅作 **Later / Optional**。

---

## 4. Information Architecture / 信息架构

### 4.1 底部 Tab（草案）

```
[ 阅读 ]  [ 漫画 ]  [ 音乐 ]  [ 更多/设置 ]
  Novel    Comic    Music     More
```

- **阅读**：现有书库 + 阅读器（小说 / 电子书）。  
- **漫画**：可从阅读域拆出独立 Tab（封面网格、横向/纵向阅读）；初期也可仍挂在阅读域，用格式过滤。  
- **音乐**：独立域（见下）。  
- **更多**：设置、关于、统计入口、实验开关（含「启用可选 Subsonic」等）。  
- GalGame：**不占主 Tab**，仅在「更多 → 实验 / 路线图」说明「已规划、未开工」。

EN: *Bottom tabs; GalGame deferred — no primary tab yet.*

### 4.2 音乐库结构

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

## 5. Music checklists / 音乐功能清单

### 5.1 MVP（下一阶段必须可演示）

- [ ] 选择文件夹 / 媒体库路径并 **本地扫描**（音频扩展名白名单）
- [ ] 解析基础标签与封面（title / artist / album / track / duration；嵌入封面或同目录 `cover.jpg`）
- [ ] 库浏览：歌曲、专辑、艺人；排序与简单搜索
- [ ] 播放引擎：`just_audio` + `audio_service`（后台、通知栏 / 锁屏、耳机键）
- [ ] 队列：播放、下一首、加入队列、清空、基本重排；持久化当前队列
- [ ] 播放模式：顺序 / 循环列表 / 单曲循环 / 随机
- [ ] 用户播放列表：新建 / 重命名 / 删除 / 增删曲目；导入导出 `.m3u` / `.m3u8`（至少导出）
- [ ] Miniplayer + 全屏 Now Playing（封面、进度、上一首/下一首、播放暂停）
- [ ] 与现有 MD3 + 毛玻璃视觉统一；中英设置项
- [ ] 无账号、默认真离线（扫描与播放不访问网络）

### 5.2 Enhance（MVP 后增强）

- [ ] 睡眠定时、播放速度、（可选）交叉淡化 / 跳过静音
- [ ] 历史、最常播放、最近添加等自动列表
- [ ] 规则型智能歌单（本地规则：流派、年份、播放次数等）
- [ ] 波形或增强 seek bar；更精致的 Now Playing 动效
- [ ] 均衡器（系统 / equalizer 插件，视平台能力）
- [ ] 文件夹视图、多根目录、扫描排除规则打磨
- [ ] 基础标签编辑与封面替换（谨慎写回文件，需确认对话框）
- [ ] 本地歌词：**同名 `.lrc` / 内嵌歌词** 优先；同步滚动 UI
- [ ] 播放统计（可与阅读统计分域展示）

### 5.3 Later（更后 / 可选）

- [ ] 在线歌词源（LRCLIB 等）—— **默认关**，用户显式开启
- [ ] 词级 / karaoke 歌词、歌词编辑器
- [ ] **可选 Subsonic / OpenSubsonic / Navidrome 客户端**（用户自建服务器；可浏览与流式播放；可选缓存到本地）
- [ ] Jellyfin 音乐库只读客户端（非优先）
- [ ] Android Auto / CarPlay、桌面端专项、投屏 / DLNA
- [ ] ReplayGain、进阶 DSP、多输出设备
- [ ] 与 Feishin 级「智能服务端歌单」对齐（依赖服务器）

EN: *MVP = local scan + just_audio/audio_service + queue + playlists. Lyrics later. Optional Subsonic later.*

---

## 6. Tech stack draft / 技术栈草案

| 层级 | 选型（草案） | 备注 |
|------|----------------|------|
| 应用框架 | Flutter 3.x（现有） | 与 NeoReader 同仓演进 |
| 本地元数据 DB | `sqflite` / 现有 DB 扩表，或独立 `neo_music.db` | 书籍与音乐表隔离，避免迁移风险 |
| 音频播放 | `just_audio` | 本地 file / 日后 uri |
| 后台与系统媒体会话 | `audio_service`（+ `audio_session`） | 通知栏、锁屏、中断处理 |
| 媒体扫描 | `path_provider` + 自研扫描器；权限用现有/补充 SAFs 或媒体权限 | Android 10+ 注意分区存储 |
| 标签 / 封面 | 成熟 Dart/FFI 标签库（选型时锁定一种，如 metadata_god 等） | 需在文档实现阶段写清 license |
| 状态管理 | 与现有阅读模块对齐（不新开一套「宗教」） | 音乐域可模块化 `lib/music/` |
| 播放列表文件 | `.m3u` / `.m3u8` 读写 | 互操作 |
| 可选网络 | OpenSubsonic HTTP API（Later） | Feature flag；默认不编译进关键路径也可 |
| UI | Material 3 + 现有毛玻璃组件 | 与阅读器同一 ThemeExtension |

**不做（MVP）**：自研解码器、强制性云歌词、账号 SSO。

---

## 7. Phased roadmap / 分阶段路线

| 阶段 | 内容 | 状态意向 |
|------|------|----------|
| **P0** | NeoReader 既有能力维持；本设计文档落地 | 文档 ✅ |
| **P1 — Music MVP** | 本地扫描、库浏览、just_audio + audio_service、队列、用户歌单、Miniplayer | **Next** |
| **P2 — Music Enhance** | 智能/自动列表、本地歌词 UI、EQ/速度/睡眠、库管理打磨 | 其后 |
| **P3 — Comic polish** | 完整 RAR/7z 漫画、漫画专用阅读手势与目录 | 与 P2 可并行部分项 |
| **P4 — Optional servers** | Subsonic / OpenSubsonic 可选连接 + 缓存 | Later |
| **P5 — GalGame** | 引擎选型、脚本/资源包格式、存档；**明确延期** | Deferred |
| 持续 | ROADMAP 中 NeoReader「一个不少」条目不删除，继续清债 | Ongoing |

GalGame：仅保留愿景与目录占位，**不排进近期 sprint**，避免拖慢音乐主线。

---

## 8. Naming & repo migration / 命名与仓库

| 项 | 建议 |
|----|------|
| 产品名 | 对外逐步使用 **NeoMedia**；过渡期文案可写「NeoMedia（由 NeoReader 演进）」 |
| 应用显示名 | 可先改 Android `label` / iOS `CFBundleDisplayName`，或设置内「关于」说明 |
| Dart package / 目录 | 短期内可保留 `koodo_flutter_offline` 等历史名，避免无意义大爆破；新代码用 `lib/music/`、`lib/comic/` 分域 |
| GitHub 仓库 | 现为 `wiwcn/NeoReader`；更名 `NeoMedia` 需单独决策（Redirect 旧名、更新 README badge、文档链接） |
| 文档 | 本文件为权威设计入口：`docs/NEOMEDIA.md`；`ROADMAP.md` 顶部链到此处 |
| 品牌 | **暂不**全面重写 README 主标题与截图区；先加「方向」说明（见 `README_cn.md`） |

EN: *Docs-first rename. Repo/package rename is a separate, explicit step.*

---

## 9. Non-goals（本阶段明确不做）

- 账号、官方云同步、订阅制 Pro  
- 以 YouTube / 网易云等商业流媒体为中心的产品  
- GalGame 可玩引擎（P5 之前）  
- 为对齐 Feishin 而引入必选自建服务器  
- 放弃 GPL-3.0 或引入与离线原则冲突的强制联网 SDK  

---

## 10. Open questions（实现前可再定）

1. 音乐库与书库是否共用一个 sqflite 文件（分表）还是独立 DB？  
2. Android 扫描走 MediaStore 索引还是纯文件系统递归（或混合）？  
3. iOS 音乐文件导入路径（Files / 文档目录）与后台音频模式清单。  
4. 仓库是否正式改名为 NeoMedia，以及应用包名是否变更（影响升级路径）。  

---

*Document status: design draft for transformation · 2026-11 · NeoMedia*
