# NeoMedia Music module

Offline-first local music library + player (Harmonoid-inspired Now Playing,
real amplitude waveform seekbar). See `docs/NEOMEDIA.md` §4 / §6.1.

## LG G8 ThinQ — audio hardware focus

Primary target: **LG G8 ThinQ** (LM-G820). Adaptation prioritizes **music-related
hardware**, not screen chrome alone.

| Hardware | App stance |
|----------|------------|
| **Hi-Fi Quad DAC** (wired 3.5 mm / USB-C DAC path) | Prefer the high-quality wired headphone path. Do **not** force low sample-rate / bit-depth resampling in-app. `audio_session` is configured as **music** (`USAGE_MEDIA` / `CONTENT_TYPE_MUSIC` on Android) so the system can keep the Quad DAC path engaged. |
| **Boombox / loudspeaker** | Use the normal media volume stream; avoid exotic routing or voice-call attributes. |
| **Wired headset / USB-C DAC** | Friendly by default via system audio focus + `just_audio` file playback. Media keys / headset buttons handled by `audio_service`. |
| Snapdragon 855 · ~6 GB RAM | Waveform peaks on a **background queue**, cached by `path+mtime+size`; UI downsamples draw bars; no heavy per-frame blur on the seekbar. |
| Tall OLED (~6.1", 19.5:9, up to 1440×3120) | Practical `SafeArea` / gesture insets and ≥48 dp controls — secondary to audio path quality. |

### Audio session / attributes (MVP)

- `AudioSessionConfiguration.music()` → Android: usage **media**, content type **music**.
- `just_audio` plays local files as-is (no intentional downsample).
- Notification / lock screen / headset: `audio_service`.

### Optional later (not MVP UI)

- Settings hint **「高音质 / DAC 友好」**: gapless where supported, higher quality pipeline, disable unnecessary DSP.
- Explicit sample-rate / offload toggles if platform APIs allow without breaking OEM DAC switching.

If you change waveform resolution defaults, keep draw bars ≤ ~200 on a G8-width
logical viewport so QHD paint stays cheap while audio stays DAC-first.
