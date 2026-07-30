---
tags:
  - digital-plumbing
  - x264
  - x265
  - codec
  - video-compression
  - motion-estimation
  - dct
  - h264
  - hevc
aliases:
  - Video Codec Architecture
  - x264 x265 Deep-Dive
  - H.264 H.265 Internals
  - Video Compression Pipeline
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🎞️ Codec Architecture — x264, x265, dan Teknik Kompresi Video Modern

> [!tip] Video codec modern (H.264, H.265, VP9, AV1) menggunakan arsitektur hibrida yang telah menjadi standar industri selama 20+ tahun: **prediksi + transform + kuantisasi + entropi coding**. Inti dari kompresi video adalah menghilangkan redundansi dalam 3 domain: **spasial** (intra prediction + DCT), **temporal** (motion estimation + compensation), dan **statistik** (CABAC/CAVLC). Dokumen ini membedah setiap blok, dengan referensi spesifik ke implementasi x264 (H.264) dan x265 (H.265/HEVC), termasuk mode rate control, presets, dan tuning untuk berbagai use case.

---

## 1. Prinsip Dasar: Redundansi Tiga Domain

Video adalah urutan gambar (frame) yang berubah seiring waktu. Kompresi video mengeksploitasi:

| Domain Redundansi | Sumber                                           | Cara Eksploitasi                        | Rasio Pengurangan |
| :---------------: | :----------------------------------------------- | :-------------------------------------- | :---------------: |
|    **Spasial**    | Piksel dalam satu frame yang mirip (langit biru) | Intra prediction ~ DCT ~ quantization   |       5-10×       |
|   **Temporal**    | Frame yang mirip dengan frame sebelumnya         | Motion estimation + inter prediction    |      10-100×      |
|  **Psikovisual**  | Mata manusia tidak sensitif ke detail tertentu   | Quantization matrix, chroma subsampling |       2-4×        |
|   **Statistik**   | Simbol coding yang redundan                      | CABAC / CAVLC entropy coding            |      10-20%       |

**Total rasio kompresi:** 100-1000× dari raw video. Raw 1080p @ 30fps = ~1.5 Gbps. H.264 @ 5 Mbps = 300× kompresi.

---

## 2. Arsitektur Hibrida — Blok Diagram

```
┌────────────┐   ┌──────────────┐   ┌────────────┐   ┌──────────┐
│ Frame      │   │ Prediksi     │   │ Transform  │   │ Kuan-    │
│ Input      │──→│ (Intra/Inter)│──→│ DCT/DST    │──→│ tisasi   │──┐
└────────────┘   └──────┬───────┘   └────────────┘   └──────────┘  │
                        │                                          │
                        │   ┌───────────┐  ┌────────────┐          │
                        └───│ Frame     │←─│ Invers     │←─────────┘
                            │ Buffer    │  │ Transform  │
                            │ (Referensi)│  + Dequant   │
                            └───────────┘  └────────────┘
                                                   │
                                              ┌────┴────┐
                                              │ Entropi │
                                              │ Coding  │──→ Bitstream
                                              │ CABAC   │   (H.264 Annex B)
                                              └─────────┘
```

### 2.1 Setiap Blok Dijelaskan

| Blok                  | Fungsi                                                     |         Kompleksitas          | Algoritma                                               |
| --------------------- | ---------------------------------------------------------- | :---------------------------: | ------------------------------------------------------- |
| **Intra Prediction**  | Prediksi piksel dari piksel tetangga dalam frame yang sama |           O(block)            | Angled prediction (H.264: 9 modes, H.265: 35, AV1: 56+) |
| **Motion Estimation** | Cari block paling cocok di frame referensi                 | O(search_window × block_size) | Diamond search, hexagon search, PMVFAST                 |
| **DCT**               | Ubah residual ke domain frekuensi                          |          O(N² log N)          | DCT 4×4, 8×8 (fast DCT via Chen algorithm)              |
| **Quantization**      | Buang koefisien frekuensi tinggi                           |        O(64) per block        | Dead-zone quantizer, trellis quantization               |
| **Deblocking Filter** | Haluskan block boundary artifacts                          |           O(frame)            | Adaptive deblocking (H.264: in-loop, H.265: SAO)        |
| **CABAC**             | Entropy coding adaptif konteks                             |            O(bin)             | Binary arithmetic coding (M coder)                      |

---

## 3. Intra Prediction — Redundansi Spasial

### 3.1 H.264 Intra Modes

H.264 mendefinisikan 9 mode prediksi untuk block 4×4 dan 4 mode untuk block 16×16:

```
Mode 0 (Vertical):     Piksel disalin dari block di atas
Mode 1 (Horizontal):   Piksel disalin dari block di kiri
Mode 2 (DC):           Rata-rata piksel dari atas + kiri
Mode 3 (Diagonal Down-Left):  Prediksi diagonal 45°
Mode 4 (Diagonal Down-Right): Prediksi diagonal -45°
Mode 5 (Vertical-Right):  Prediksi 26.6° dari vertikal
Mode 6 (Horizontal-Down): Prediksi 26.6° dari horizontal
Mode 7 (Vertical-Left):   Prediksi -26.6° dari vertikal
Mode 8 (Horizontal-Up):   Prediksi -26.6° dari horizontal
```

### 3.2 H.265 — 35 Modes

H.265/HEVC meningkatkan jumlah mode intra menjadi 35 — 33 angular modes + DC + Planar. Angular modes mencakup sudut dari -135° sampai 180° dengan step ~5°.

### 3.3 AV1 — 56+ Modes

AV1 (Alliance for Open Media) memperkenalkan directional modes + palette mode (untuk screen content) + recursive filtering. Hasilnya: ~30% lebih efisien dari H.265.

---

## 4. Motion Estimation — Jantung Kompleksitas

### 4.1 Bagaimana ME Bekerja

Untuk setiap block 16×16 (macroblock) di frame saat ini, encoder mencari block paling mirip di frame referensi dalam jendela pencarian (misal ±64 piksel):

```c
// Simplified diamond search
int best_sad = INT_MAX;
int best_mv_x = 0, best_mv_y = 0;

// Center — motion vector (0,0) — biasanya yang paling umum
int sad = compute_SAD(current_block, reference_at(0,0));
best_sad = sad;

// Diamond pattern: center, up, down, left, right
int pattern_sads[4];
pattern_sads[0] = compute_SAD(center, reference_block(0, -1));  // up
pattern_sads[1] = compute_SAD(center, reference_block(0, +1));  // down
pattern_sads[2] = compute_SAD(center, reference_block(-1, 0));  // left
pattern_sads[3] = compute_SAD(center, reference_block(+1, 0));  // right

// Ulangi dengan diamond yang lebih besar sampai SAD tidak berkurang
```

### 4.2 SAD — Sum of Absolute Differences

SAD adalah metrik paling umum untuk motion estimation:

$$ \text{SAD} = \sum_{i=1}^{N} \sum_{j=1}^{N} |C_{ij} - R_{ij}| $$

Dimana C = block saat ini, R = block referensi, N = ukuran block.

**Instruksi hardware:** SSE4.1 `MPSADBW` (Multi-Packed Sum-Absolute-Differences) memproses 8×8 SAD dalam satu instruksi. AVX2 `VPSADBW` memproses 16×8 dalam satu instruksi.

### 4.3 Sub-Pixel Motion

Gerakan nyata jarang tepat integer pixel. H.264 mendukung motion vector dengan presisi **1/4 pixel** (quarter-pel):

```
Integer pixel grid:  X . X . X . X
                     . . . . . . .
Quarter-pel:        X o X o X o X
                     o o o o o o o
                     X o X o X o X
```

Interpolasi sub-pixel dilakukan dengan filter FIR 6-tap (H.264) atau DCT-based interpolation (H.265).

---

## 5. DCT & Quantization

### 5.1 Discrete Cosine Transform

Setelah prediksi, residual (selisih) di-transform dengan DCT. Untuk block 4×4 di H.264:

$$ Y = C_f \times X \times C_f^T \otimes E_f $$

Dimana $X$ = residual 4×4, $C_f$ = matriks transform, $\otimes$ = elemen-wise multiplication, $E_f$ = scaling factor.

**Output:** Koefisien DCT — $Y_{00}$ (DC, frekuensi rendah) di pojok kiri atas, koefisien frekuensi tinggi di kanan bawah.

### 5.2 Quantization

Quantization membagi koefisien DCT dengan quantization parameter (QP):

$$ Z_{ij} = \text{round}\left(\frac{Y_{ij}}{\text{QP\_step}}\right) $$

| QP  | QP_step | Visual Quality | Bitrate (1080p) |
| :-: | :-----: | :------------: | :-------------: |
| 18  |    4    |  Transparent   |    ~20 Mbps     |
| 23  |    7    |   Excellent    |     ~8 Mbps     |
| 28  |   13    |      Good      |     ~4 Mbps     |
| 33  |   25    |      Fair      |     ~2 Mbps     |
| 38  |   50    |      Poor      |     ~1 Mbps     |
| 43  |   100   |      Bad       |    ~0.5 Mbps    |

**Trellis quantization:** x264/x265 menggunakan trellis quantization — algoritma yang memilih koefisien mana yang akan di-zero-kan untuk trade-off bitrate vs distorsi optimal (RD optimization dengan Viterbi algorithm).

---

## 6. Entropy Coding — CABAC

### 6.1 CAVLC vs CABAC

| Aspek        | CAVLC (H.264 Baseline) |    CABAC (H.264 Main/High)    |
| ------------ | :--------------------: | :---------------------------: |
| Algoritma    |  Context-adaptive VLC  |   Binary arithmetic coding    |
| Kompleksitas |         Rendah         |            Tinggi             |
| Efisiensi    |        Baseline        |      ~10-15% lebih baik       |
| Digunakan    |   Webcam, video call   | Broadcast, Blu-ray, streaming |

### 6.2 Cara Kerja CABAC

1. **Binarization:** Setiap simbol coding diubah menjadi binary string (bin)
2. **Context modeling:** Probabilitas tiap bin diadaptasi berdasarkan context (simbol sebelumnya, block position, slice type)
3. **Binary arithmetic coding:** Range encoder yang membagi interval [0,1) berdasarkan probabilitas konteks

**Probabilitas adaptif:** CABAC menggunakan 460 context models di H.264, 1000+ di H.265. Setiap model memiliki state 7-bit yang diupdate setelah setiap bin.

---

## 7. x264 — Implementasi Referensi H.264

### 7.1 Presets & Tuning

x264 mendefinisikan **preset** (kecepatan) dan **tuning** (optimasi untuk konten spesifik):

**Presets (kecepatan → kualitas):**

```
ultrafast ← fastest, worst compression
superfast
veryfast
faster
fast
medium   ← default
slow
slower
veryslow
placebo  ← slowest, best compression
```

**Perbedaan kinerja antar preset:**

| Preset    | Speed (fps) | Bitrate (relatif) | Komentar                               |
| --------- | :---------: | :---------------: | -------------------------------------- |
| ultrafast |   280 fps   | +100% (terbesar)  | Tanpa motion estimation, CAVLC saja    |
| medium    |   45 fps    |   0% (baseline)   | Me = hexagon, subme = 7, ref = 3       |
| slower    |   15 fps    |        -8%        | Me = multi-hexagon, subme = 9, ref = 8 |
| placebo   |    5 fps    |       -12%        | Me = exhaustive, trellis = 2, demuix   |

### 7.2 Rate Control

| Mode       | Metode                | Digunakan untuk                  |
| ---------- | --------------------- | -------------------------------- |
| **CBR**    | Constant bitrate      | Streaming real-time (video call) |
| **CQP**    | Constant quantization | Archiving, quality first         |
| **CRF**    | Constant Rate Factor  | Umum (best trade-off)            |
| **ABR**    | Average bitrate       | Upload dengan batas bitrate      |
| **2-pass** | VBR dengan 2 pass     | Distribution (YouTube, Netflix)  |

**CRF (0-51):** Nilai default 23. Lebih rendah → kualitas lebih tinggi. Setiap -6 ≈ 2× bitrate. CRF 17 ≈ "transparent" untuk konten regular. CRF 28 untuk production streaming.

### 7.3 Profile & Level

| Profile      | Fitur                               | Digunakan               |
| ------------ | ----------------------------------- | ----------------------- |
| **Baseline** | I+P frames, CAVLC                   | Video call, webcam      |
| **Main**     | I+P+B frames, CABAC                 | SD video                |
| **High**     | 8×8 DCT, custom quantization matrix | HD video, Blu-ray       |
| **High 10**  | 10-bit depth                        | Professional production |
| **High 444** | 4:4:4 chroma, lossless              | Mastering, archives     |

---

## 8. x265 — H.265/HEVC

### 8.1 Perbaikan Utama H.265

| Fitur                  | H.264               | H.265                       | Keuntungan               |
| ---------------------- | ------------------- | --------------------------- | ------------------------ |
| CTU (coding tree unit) | 16×16 block         | 64×64 tree                  | Adaptif lebih baik       |
| Intra modes            | 9 (4×4) / 4 (16×16) | 35 modes                    | Prediksi lebih akurat    |
| Motion compensation    | 1/4 pel             | 1/4 pel + DCT interpolation | Sub-pixel lebih presisi  |
| SAO filter             | Tidak ada           | Sample Adaptive Offset      | Kurangi banding artifact |
| Wavefront              | Slice based         | WPP (Wavefront Parallel)    | Multi-threading better   |
| Tiles                  | Tidak ada           | Tiles + Slices              | Parallel encoding native |

### 8.2 Kompleksitas Encoding

| Setting      | Faktor vs x264 medium | Use Case             |
| ------------ | :-------------------: | -------------------- |
| x265 medium  |  5-10× lebih lambat   | Default              |
| x265 slower  |  20-40× lebih lambat  | Production movie     |
| x265 placebo | 80-150× lebih lambat  | Archiving, mastering |

**Bitrate saving:** ~35-50% dibanding H.264 pada kualitas yang sama.

---

## 9. AV1 — Masa Depan Codec

AV1 (2019) menggunakan teknik yang lebih canggih:

| Teknik                 |           AV1           | H.265 | Peningkatan                         |
| ---------------------- | :---------------------: | :---: | :---------------------------------- |
| Intra prediction modes | 56+ angular + recursive |  35   | ~5% gain                            |
| Warped motion          |           ✅            |  ❌   | Content-adaptive warp               |
| OBMC                   |           ✅            |  ❌   | Overlapped block motion             |
| CDEF filter            |           ✅            |  ❌   | Constrained directional enhancement |
| Film grain synthesis   |           ✅            |  ❌   | Simpan bitrate untuk grain          |

**Bitrate saving:** ~30-50% dibanding H.265 pada kualitas yang sama. Tapi encode ~5-10× lebih lambat dari x265.

---

## References

1. ITU-T H.264 / ISO 14496-10. _"Advanced Video Coding."_ (2003-2025).
2. ITU-T H.265 / ISO 23008-2. _"High Efficiency Video Coding."_ (2013-2025).
3. AOM. _"AV1 Bitstream & Decoding Specification."_ (2019-2025).
4. x264 Project. _"x264 — A free H.264/AVC encoder."_ VideoLAN. https://www.videolan.org/developers/x264.html
5. x265 Project. _"x265 — H.265/HEVC video encoder."_ http://x265.org/
6. I. E. Richardson. _"H.264 and MPEG-4 Video Compression."_ Wiley, 2003.
7. G. J. Sullivan et al. _"Overview of the High Efficiency Video Coding (HEVC) Standard."_ IEEE TCSVT, 2012.
8. J. Chen, Y. Chen. _"AV1 Codec Overview and Performance Analysis."_ 2020.
9. D. Marpe et al. _"Context-Based Adaptive Binary Arithmetic Coding in the H.264/AVC Video Compression Standard."_ IEEE TCSVT, 2003.
10. Dark Shikari (x264 lead). _"Rate Control in x264."_ Doom9 Forum, 2006-2010.

## Koneksi ke Vault

| Catatan                                  | Koneksi                                                       |
| ---------------------------------------- | ------------------------------------------------------------- |
| [[hierarchy-digital-plumbing]]           | §4 Level 5 — Codec Multimedia                                 |
| [[ffmpeg-multimedia-framework-deepdive]] | FFmpeg memanggil x264/x265 sebagai library eksternal          |
| [[math-and-algorithms]]                  | DCT adalah aplikasi dari aljabar linier dan Fourier transform |
| [[computer-science-foundations]]         | SIMD SAD, cache locality, parallel encoding (WPP, tiles)      |
