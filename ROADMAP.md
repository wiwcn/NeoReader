# NeoReader / NeoMedia Roadmap

## NeoMedia（转型方向）

产品正由 **NeoReader** 演进为 **NeoMedia**：离线优先的聚合媒体中心（小说 · 漫画 · 音乐 · GalGame）。  
**主参考：[Fushi](https://github.com/hajisensai/Fushi)**（[fushi.moe](https://fushi.moe/)）的多媒体壳；**不是** Feishin，也**不以** Anki / 词典沉浸为核心。  
**下一阶段主线：完整本地音乐播放器（Fushi 相对薄弱处的第一大补强）**；GalGame / Video 延期。  
**Music UI：Harmonoid**（极简 Now Playing / 大封面轮播）+ **真实音轨波形 seek**（预计算振幅，非装饰波浪；含 scrub 放大等小巧思）。  
Feishin / Namida / Retro Music / Auxio / Aura / Linthra 仅作音乐域次要风格 / 能力参考。完整愿景、IA、清单与技术草案见：

→ **[docs/NEOMEDIA.md](./docs/NEOMEDIA.md)**

以下 NeoReader「Koodo 离线能力一个不少」条目**全部保留**，不因转型删除。

---

# NeoReader Roadmap — Koodo offline feature parity (一个不少)

v1 ships a solid offline core. Remaining items stay scaffolded in
`FormatRegistry.plannedModules` / settings UI.
**Goal: full parity with open-source Koodo Reader offline scope, plus NeoReader extras.**

## v1 core (done)

- [x] Unlimited local library (list / search / sort / delete)
- [x] Import local files (file_picker)
- [x] EPUB reader (scroll + paged chapters, font/line/theme, progress)
- [x] PDF reader (pdfrx continuous view, zoom via viewer, progress)
- [x] TXT reader (UTF-8/Latin1, same theme controls)
- [x] Bookmarks / notes / highlights storage (sqflite)
- [x] Settings: ZH/EN, app theme, reading defaults
- [x] Offline-only (no account / sync / cloud / Pro)
- [x] Reading session stats (今日 / 累计 / 各书时长) — beyond Koodo
- [x] MD3 + frosted glass UI
- [x] Android minSdk 29, iOS 12.0 targets
- [x] Demo sample books seeded once on first launch

## Formats

- [x] DRM-free Mobipocket / Kindle text extract: `.mobi`, `.azw3`, `.azw` (PalmDOC; Huff/cdic & DRM still limited)
- [x] FictionBook `.fb2`
- [x] Comic ZIP `.cbz` (+ ZIP-mislabeled `.cbr`); true RAR `.cbr` / `.cbt` / `.cb7` still planned
- [x] Markdown `.md` (flutter_markdown)
- [x] DOCX text extract `.docx`
- [x] HyperText `.html`, `.htm`, `.xhtml`, `.mhtml`
- [ ] Comic RAR/7z (`.cbr` full, `.cbt`, `.cb7`)
- [ ] Generic `.xml` (non-FB2)

## Reader chrome (planned)

- [x] Vertical layout books
- [ ] Single-column / two-column / continuous layouts (full parity)
- [x] Font family, paragraph spacing, margins, brightness
- [ ] Highlight styles: underline, bold, italics, shadow
- [ ] Touch-optimized gestures batch

## Knowledge tools (local only)

- [ ] Local MDX dictionary lookup
- [ ] Local TTS plugins
- [ ] Local translation plugins
- [ ] Local OCR (Paddle / system) — no cloud OCR

## Library & privacy

- [ ] One-click export all books
- [x] Export notes/highlights → Markdown / TXT (CSV / HTML / PDF still planned)
- [ ] Library password / PIN / biometric lock
- [ ] Library snapshots & version control
- [ ] Batch import polish

## Stats & polish

- [x] Richer reading statistics charts (last-7-days bars)
- [x] Per-session heatmap / streaks (current streak + 7-day)
- [x] Cover mode / list mode toggle (grid)
- [ ] HarmonyOS NEXT packaging notes & smoke tests

## Explicitly out of scope (offline policy)

- Cloud sync / account / Pro purchase
- Official cloud AI / cloud OCR / network drive import
- OPDS serving / online update channels
