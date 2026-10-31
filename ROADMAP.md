# NeoReader Roadmap — Koodo offline feature parity (一个不少)

v1 ships a solid offline core. Everything below is scaffolded in
`FormatRegistry.plannedModules` / settings UI and tracked here for follow-up.
**Goal: full parity with open-source Koodo Reader offline scope, plus NeoReader extras.**

## v1 core (done)

- [x] Unlimited local library (list / search / sort / delete)
- [x] Import local files (file_picker) — EPUB, PDF, TXT
- [x] EPUB reader (scroll + paged chapters, font/line/theme, progress)
- [x] PDF reader (pdfrx continuous view, zoom via viewer, progress)
- [x] TXT reader (UTF-8/Latin1, same theme controls)
- [x] Bookmarks / notes / highlights storage (sqflite)
- [x] Settings: ZH/EN, app theme, reading defaults
- [x] Offline-only (no account / sync / cloud / Pro)
- [x] Reading session stats (今日 / 累计 / 各书时长) — beyond Koodo
- [x] MD3 + frosted glass UI
- [x] Android minSdk 29, iOS 12.0 targets

## Formats (planned — must ship for 1:1)

- [ ] DRM-free Mobipocket / Kindle: `.mobi`, `.azw3`, `.azw`
- [ ] FictionBook `.fb2`
- [ ] Comic archives `.cbr`, `.cbz`, `.cbt`, `.cb7`
- [ ] Rich text `.md`, `.docx`
- [ ] HyperText `.html`, `.xml`, `.xhtml`, `.mhtml`, `.htm`

## Reader chrome (planned)

- [ ] Vertical layout books
- [ ] Single-column / two-column / continuous layouts (full parity)
- [ ] Font family, paragraph spacing, margins, brightness
- [ ] Highlight styles: underline, bold, italics, shadow
- [ ] Touch-optimized gestures batch

## Knowledge tools (local only)

- [ ] Local MDX dictionary lookup
- [ ] Local TTS plugins
- [ ] Local translation plugins
- [ ] Local OCR (Paddle / system) — no cloud OCR

## Library & privacy

- [ ] One-click export all books
- [ ] Export notes/highlights → CSV / Markdown / HTML / TXT / PDF
- [ ] Library password / PIN / biometric lock
- [ ] Library snapshots & version control
- [ ] Batch import polish

## Stats & polish

- [ ] Richer reading statistics charts
- [ ] Per-session heatmap / streaks
- [ ] Cover mode / list mode toggle (grid)
- [ ] HarmonyOS NEXT packaging notes & smoke tests

## Explicitly out of scope (offline policy)

- Cloud sync / account / Pro purchase
- Official cloud AI / cloud OCR / network drive import
- OPDS serving / online update channels
