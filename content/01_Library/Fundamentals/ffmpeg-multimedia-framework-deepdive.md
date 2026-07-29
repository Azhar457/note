---
tags:
  - digital-plumbing
  - ffmpeg
  - multimedia
  - video-processing
  - audio-processing
  - codec
  - libav
  - transcoding
aliases:
  - FFmpeg Architecture Deep-Dive
  - Multimedia Framework
  - libavcodec libavformat
  - FFmpeg Pipeline
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🎬 FFmpeg Multimedia Framework — Arsitektur & Pipeline Transcoding

> [!tip] FFmpeg adalah kerangka multimedia universal yang menangani 400+ format kontainer, 300+ codec, dan 200+ filter. Arsitekturnya terdiri dari 6 pustaka inti (`libavformat`, `libavcodec`, `libavfilter`, `libavutil`, `libswscale`, `libswresample`) yang dirangkai dalam pipeline **demux → decode → filter → encode → mux**. Dokumen ini membedah arsitektur internal FFmpeg, model data (AVPacket/AVFrame), pipeline transkoding, dan mengapa ia menjadi "pisau lipat Swiss" multimedia sejak 2000.

---

## 1. Sejarah & Posisi

- **2000:** Fabrice Bellard merilis FFmpeg (awalnya hanya MPEG encoder)
- **2004:** Michael Niedermayer mengambil alih; libavcodec dan libavformat lahir
- **2011:** Fork menjadi FFmpeg (aktif) vs Libav (stagnan). FFmpeg menang
- **2026:** ~100+ kontributor aktif, di-port ke setiap arsitektur CPU (x86, ARM, RISC-V, MIPS, PowerPC)

**Yang memakai FFmpeg:**

- YouTube, Vimeo, Twitch (server-side transcoding)
- Chromium, Firefox, Safari (HTML5 `<video>` — via FFmpeg WebCodecs)
- Android (MediaCodec — FFmpeg di belakangnya)
- iOS/macOS (AVFoundation — sebagian codec via FFmpeg)
- Hampir semua aplikasi konversi video (HandBrake, OBS, Kdenlive, Davinci Resolve)

---

## 2. Arsitektur FFmpeg

### 2.1 Enam Pustaka Inti

| Library           | Fungsi                    | File Penting   | Digunakan di                      |
| ----------------- | ------------------------- | -------------- | --------------------------------- |
| **libavformat**   | Demux/Mux kontainer       | `avformat.h`   | Baca/tulis MP4, MKV, AVI, FLV, TS |
| **libavcodec**    | Encoder/Decoder codec     | `avcodec.h`    | H.264, H.265, VP9, AV1, AAC, MP3  |
| **libavfilter**   | Filter graph              | `avfilter.h`   | Scale, crop, drawtext, volume     |
| **libavutil**     | Utilitas (mem, math, log) | `avutil.h`     | AVFrame, AVPacket, matematika     |
| **libswscale**    | Konversi warna & scaling  | `swscale.h`    | YUV↔RGB, resolusi scaling         |
| **libswresample** | Resampling audio          | `swresample.h` | 44.1KHz↔48KHz, mono↔stereo        |

### 2.2 Model Data — AVPacket & AVFrame

**AVPacket:** Data terkompresi. Berisi bitstream sebelum/sesudah encode.

```c
typedef struct AVPacket {
    AVBufferRef *buf;    // Buffer reference
    int64_t pts;         // Presentation timestamp
    int64_t dts;         // Decoding timestamp
    uint8_t *data;       // Compressed bitstream
    int   size;          // Size in bytes
    int   stream_index;  // Which stream (0=video, 1=audio...)
    AVPacketSideData *side_data; // Metadata (HDR, AV1 OBU...)
} AVPacket;
```

**AVFrame:** Data mentah (tidak terkompresi). Berisi piksel YUV atau sampel PCM.

```c
typedef struct AVFrame {
    uint8_t *data[AV_NUM_DATA_POINTERS]; // Plane pointers (Y, U, V)
    int linesize[AV_NUM_DATA_POINTERS];  // Stride per plane
    int width, height;                   // Untuk video
    int nb_samples;                      // Untuk audio
    int format;                          // PIX_FMT_* atau AV_SAMPLE_FMT_*
    int64_t pts;                         // Presentation timestamp
    AVBufferRef *buf[AV_NUM_DATA_POINTERS];
} AVFrame;
```

### 2.3 Pipeline Transcoding

```
┌──────────┐   AVPacket     ┌──────────┐   AVFrame    ┌──────────┐
│ Input    │──────────────→│ Decoder  │──────────────→│ Filter   │
│ File     │  (compressed)  │          │  (raw)       │ Graph    │
└──────────┘               └──────────┘               └─────┬────┘
                                                             │ AVFrame
                                                             │ (filtered)
                                                            ▼
┌──────────┐   AVPacket     ┌──────────┐   AVFrame    ┌──────────┐
│ Output   │←──────────────│ Encoder  │←──────────────│          │
│ File     │  (compressed)  │          │  (raw)       │          │
└──────────┘               └──────────┘               └──────────┘
```

**Kode pipeline (sederhana):**

```c
// 1. Open input
AVFormatContext *fmt_ctx = avformat_open_input("input.mp4");

// 2. Find decoder
const AVCodec *decoder = avcodec_find_decoder(fmt_ctx->streams[video_idx]->codecpar->codec_id);
AVCodecContext *dec_ctx = avcodec_alloc_context3(decoder);
avcodec_open2(dec_ctx, decoder, NULL);

// 3. Decode loop
AVPacket *pkt = av_packet_alloc();
AVFrame *frame = av_frame_alloc();
while (av_read_frame(fmt_ctx, pkt) >= 0) {
    avcodec_send_packet(dec_ctx, pkt);
    while (avcodec_receive_frame(dec_ctx, frame) >= 0) {
        // 4. Frame siap — kirim ke encoder atau filter
    }
}
```

---

## 3. Demuxing — libavformat

### 3.1 Format Detection

FFmpeg mendeteksi format kontainer dengan **probing** — membaca beberapa byte pertama file lalu mencocokkan dengan signature yang dikenal:

| Format        | Magic Bytes      | Ekstensi         |
| ------------- | ---------------- | ---------------- |
| MP4/ISOBMFF   | `ftyp` (4 byte)  | .mp4, .m4a, .mov |
| Matroska/WebM | `EBML` header    | .mkv, .webm      |
| AVI           | `RIFF` + `AVI `  | .avi             |
| FLV           | `FLV`            | .flv             |
| MPEG-TS       | `0x47` sync byte | .ts, .m2ts       |
| Ogg           | `OggS`           | .ogg, .opus      |
| WAV           | `RIFF` + `WAVE`  | .wav             |

### 3.2 Stream Discovery

Setelah format terdeteksi, `avformat_find_stream_info()` membaca:

- Jumlah streams (video, audio, subtitle, data)
- Codec ID (H.264 = 27, AAC = 86017)
- Resolution, framerate, bitrate
- Durasi, keyframe index
- Metadata (title, artist, rotation)

---

## 4. Filtering — libavfilter

### 4.1 Filter Graph Model

Filter di FFmpeg dirangkai sebagai **directed acyclic graph (DAG)**:

```
[Input 0: Video] ─→ scale ─→ crop ─→ drawtext ─→ [Output 0]
                                            ↑
[Input 1: PNG] ─────────────────────────────┘ (watermark)

[Input 2: Audio] ─→ volume ─→ equalizer ─→ [Output 1]
```

Setiap filter memiliki **pads** — input pad (masuk) dan output pad (keluar). Filter graph bisa sangat kompleks (puluhan filter).

### 4.2 Filter Populer & Kinerja

| Filter      | Fungsi            | Kompleksitas    | SIMD?                 |
| ----------- | ----------------- | --------------- | --------------------- |
| `scale`     | Ubah resolusi     | O(width×height) | ✅ AVX-512, SSE, NEON |
| `crop`      | Potong frame      | O(area)         | ✅ Memory copy        |
| `yadif`     | Deinterlace       | O(area)         | ✅ SSE2               |
| `drawtext`  | Tulis teks        | O(area)         | ❌ (CPU-bound)        |
| `fps`       | Ubah framerate    | O(1) per frame  | —                     |
| `volume`    | Ubah volume audio | O(samples)      | ✅ SIMD               |
| `atempo`    | Ubah tempo audio  | O(n)            | ❌ WSOLA algorithm    |
| `equalizer` | Audio EQ          | O(n) per band   | ❌ IIR filter         |

---

## 5. Konversi Warna — libswscale

### 5.1 Color Space

libswscale menangani konversi antar **pixel format**:

| Format  | Deskripsi                            | Bits per Pixel | Digunakan di                 |
| ------- | ------------------------------------ | :------------: | ---------------------------- |
| YUV420P | YUV planar, chroma subsampled 4:2:0  |       12       | H.264, H.265 — standar video |
| YUV422P | YUV planar, 4:2:2                    |       16       | ProRes, broadcast            |
| YUV444P | YUV planar, 4:4:4                    |       24       | High-end, screen capture     |
| NV12    | YUV semi-planar (Y + UV interleaved) |       12       | GPU, hardware decoder        |
| RGB24   | RGB packed                           |       24       | Screenshot, display          |
| BGRA    | RGB + alpha, byte order B-G-R-A      |       32       | OpenGL, compositor           |
| GRAY8   | Grayscale                            |       8        | Monochrome, depth maps       |

### 5.2 Algoritma Scaling

libswscale menggunakan **filter scaling** dengan kualitas bervariasi:

| Filter           |   Kualitas    | Kecepatan | Digunakan            |
| ---------------- | :-----------: | :-------: | -------------------- |
| Nearest neighbor |    Rendah     | Tercepat  | Preview, pixel art   |
| Bilinear         |    Sedang     |   Cepat   | Default              |
| Bicubic          |    Tinggi     |  Sedang   | Transcoding kualitas |
| Lanczos          | Sangat tinggi |  Lambat   | Production broadcast |
| Spline           |   Tertinggi   | Terlambat | Mastering            |

---

## 6. Kasus Spesifik: YouTube Transcoding Pipeline

Di YouTube, setiap video yang diupload melewati pipeline FFmpeg:

1. **Probe:** Deteksi format input, codec, metadata
2. **Decode:** Bongkar ke raw frames
3. **Segmentasi:** Potong video menjadi segmen 6-10 detik
4. **Multi-encode:** Encode segmen ke berbagai format/resolusi secara paralel:
   - 4K HDR: AV1 (libaom)
   - 1080p: H.264 (x264) — baseline compatibility
   - 720p/480p: VP9 (libvpx) — bandwidth hemat
   - Audio: Opus (libopus) 128kbps, AAC (libfdk_aac) 256kbps
5. **DASH/HLS:** Mux segmen ke MPEG-DASH + HLS kontainer
6. **Manifest:** Generate MPD + m3u8

**Estimasi beban:** YouTube memproses ~500 jam video per menit (2025). Setiap menit = ~300,000 FFmpeg transcoding jobs berjalan di server Google.

---

## References

1. FFmpeg Documentation. https://ffmpeg.org/doxygen/trunk/index.html
2. FFmpeg Wiki. _"H.264 Video Encoding Guide."_ https://trac.ffmpeg.org/wiki/Encode/H.264
3. Libavformat API. https://ffmpeg.org/doxygen/trunk/group__libavf.html
4. Libavfilter API. https://ffmpeg.org/doxygen/trunk/group__lavfi.html
5. Swscale Documentation. https://ffmpeg.org/doxygen/trunk/swscale_8h.html
6. W. Fisher. _"Inside YouTube's Video Processing Pipeline."_ (2019).
7. Google. _"YouTube DASH Implementation."_ (2013-2025).

## Koneksi ke Vault

| Catatan                                   | Koneksi                                   |
| ----------------------------------------- | ----------------------------------------- |
| [[hierarchy-digital-plumbing]]            | §3 Level 6 — Orkestrator FFmpeg           |
| [[codec-architecture-x264-x265-deepdive]] | Level 5 — codec video yang FFmpeg panggil |
| [[forensic-imaging-analysis]]             | FFmpeg ekstraksi frame CCTV, metadata     |
| [[deepfake-detection]]                    | Wajib tahu codec artifact vs AI artifact  |
