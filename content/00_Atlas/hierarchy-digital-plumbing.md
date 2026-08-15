---
title: 🔧 Digital Plumbing Hierarchy — Fondasi Pipa Digital yang Terlupakan
tags:
- digital-plumbing
- ffmpeg
- compression
- codec
- infrastructure
- hidden-infrastructure
- unix-philosophy
- multimedia
aliases:
- Pipa Digital
- Fondasi Tersembunyi Internet
- Digital Plumbing Architecture
- Pahlawan Tak Dikenal
- Hidden Infrastructure Stack
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 🔧 Digital Plumbing Hierarchy — Fondasi Pipa Digital yang Terlupakan

> Dari `ffmpeg` hingga `zlib`: Arsitektur Tersembunyi yang Menopang Setiap Bit di Internet

> [!abstract] Fondasi yang Tak Terlihat
> Setiap kali kamu menonton video, mendengarkan musik, membuka file arsip, atau melihat gambar di web, ada deretan pustaka "pipa ledeng" yang bekerja tanpa henti. Mereka adalah `ffmpeg`, `unrar`, `zlib`, `libjpeg-turbo`, dan sejenisnya — barisan kode tanpa pamrih yang mengubah data dari satu bentuk ke bentuk lain. Tanpa mereka, internet akan berhenti. Dokumen ini adalah sebuah penghormatan, penjelasan arsitektur, dan peta hierarki dari fondasi digital yang paling terlupakan.

---

## Daftar Isi

1. [[#1. First Principles — Mengapa Pipa Digital Ini Penting]]
2. [[#2. Hierarki Pipa Digital — Piramida Enam Lapis]]
3. [[#3. Level 6 — Sang Orkestrator FFmpeg]]
4. [[#4. Level 5 — Codec Multimedia]]
5. [[#5. Level 4 — Arsip Kompresi Data]]
6. [[#6. Level 3 — Codec Gambar]]
7. [[#7. Level 2 — Parsing Validasi Kriptografi]]
8. [[#8. Level 1 — Aritmatika Biner Hashing]]
9. [[#9. Peta Koneksi ke Vault]]
10. [[#10. References]]

---

## 1. First Principles — Mengapa "Pipa Digital" Ini Penting?

Dalam ilmu komputer, kita sering terjebak dalam kompleksitas sistem besar. Namun, prinsip fundamental rekayasa justru terletak pada komponen-komponen kecil yang sangat terspesialisasi dan melakukan satu hal dengan sangat baik. Inilah **The Unix Philosophy** dalam wujudnya yang paling murni.

### 1.1 "Jembatan" Antar Format

Digital Plumbing adalah tentang menjembatani representasi data. Dunia digital adalah menara babel format: `MP4`, `MKV`, `JPEG`, `PNG`, `RAR`, `ZIP`, `MP3`, `FLAC`. Setiap format adalah bahasa yang berbeda. Alat-alat ini adalah penerjemah universal yang memungkinkan mereka untuk saling bertukar data.

### 1.2 Fondasi yang Tak Terlihat

Mereka adalah fondasi yang tak terlihat. Kamu tidak pernah "membuka" `ffmpeg` seperti membuka browser. Mereka adalah *dependency* yang dipanggil oleh aplikasi lain. Saat kamu mengunggah video ke YouTube, `ffmpeg` yang bekerja di server. Saat kamu membuka file `.zip`, `libzip` yang mengeksekusi. Keandalan internet bergantung pada keandalan kode yang jarang kita lihat ini.

### 1.3 Digital Plumbing vs Application Software

| Aspek | Aplikasi (Kamu Lihat) | Pipa Digital (Tak Terlihat) |
|-------|----------------------|---------------------------|
| **Pengguna** | Manusia (GUI/CLI) | Program lain (API/library) |
| **Bahasa** | JavaScript, Python, Ruby | C, C++, Rust, Assembly |
| **Umur** | ~2-5 tahun (framework churn) | ~20-40 tahun (zlib: 1995, libpng: 1995, ffmpeg: 2000) |
| **Stabilitas** | API break setiap major version | ABI stabil selama dekade |
| **Optimasi** | Cukup "cukup cepat" | Tiap siklus CPU diperjuangkan (SIMD, ASM) |
| **Ekosistem** | Berganti tiap era | Selamanya — codec baru hanya ditambahkan, tidak mengganti |

> [!tip] **Plot Twist:** Pustaka seperti `zlib` (dirilis 1995) masih menjadi tulang punggung kompresi HTTP di tahun 2026. Framework JavaScript yang kamu pakai tahun 2020 mungkin sudah mati. Tapi `zlib`? Masih kuat.

---

## 2. Hierarki Pipa Digital — Piramida Enam Lapis

Saya mengelompokkan pahlawan tak dikenal ini ke dalam sebuah hierarki berdasarkan fungsinya dalam aliran data, dari level tertinggi (paling dekat ke aplikasi) ke level paling fundamental (paling dekat ke hardware).

```
╔══════════════════════════════════════════════════════════════════╗
║              HIERARKI DIGITAL PLUMBING                          ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Level 6 │ Multiplexer/Demultiplexer (Kontainer)                ║
║          │ ffmpeg, mkvmerge, mp4box, gpac                       ║
║          │ → Orkestrator: baca, pisah, gabung, tulis kontainer  ║
║──────────────────────────────────────────────────────────────────║
║  Level 5 │ Codec Multimedia (Enkoder/Dekoder)                   ║
║          │ x264, x265, libvpx, libaom, flac, lame, opus, speex ║
║          │ → Transformasi signal: DCT, MDCT, motion comp, ACELP ║
║──────────────────────────────────────────────────────────────────║
║  Level 4 │ Arsip & Kompresi Data                                ║
║          │ unrar, 7-Zip, zlib, lzma, zstd, brotli, bzip2, xz   ║
║          │ → Information theory: entropy, dictionary, context    ║
║──────────────────────────────────────────────────────────────────║
║  Level 3 │ Codec Gambar                                         ║
║          │ libjpeg-turbo, libpng, libwebp, libavif, libheif     ║
║          │ → Spatial redundancy: chroma subsampling, DCT 8×8    ║
║──────────────────────────────────────────────────────────────────║
║  Level 2 │ Parsing & Validasi & Serialisasi                     ║
║          │ libxml2, libcurl, openssl, protobuf, flatbuffers,    ║
║          │ nlohmann/json, yyjson, msgpack, capnproto            ║
║          │ → Grammar, state machine, schema validation          ║
║──────────────────────────────────────────────────────────────────║
║  Level 1 │ Aritmatika Biner & Hashing                           ║
║          │ zlib (deflate core), xxHash, base64, simdutf,        ║
║          │ libbase64, BLAKE3, CRC32, MD5, SHA                   ║
║          │ → Bit manipulation, CPU intrinsics, SIMD             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

### 2.1 Prinsip Aliran Data

Data mengalir **turun** untuk di-decode dan **naik** untuk di-encode:

```
[Aplikasi Kamu]
    ↓ encode                          ↑ decode
[Level 6: Multiplexer]  ← kontainer → [Level 6: Multiplexer]
    ↓ mux                             ↑ demux
[Level 5: Codec]        ← bitstream → [Level 5: Codec]
    ↓ encode                          ↑ decode
[Level 4: Kompresi]     ← compressed → [Level 4: Kompresi]
    ↓ deflate                         ↑ inflate
[Level 1: Aritmatika]   ← raw bytes → [Level 1: Aritmatika]
```

### 2.2 Contoh Aliran: Memutar Video YouTube

```
Browser → YouTube Player (JavaScript)
  → Level 6: Demux WebM (libwebm)
  → Level 5: Decode VP9 (libvpx) + Decode Opus (libopus)
  → Level 4: Decompress frame buffer (zlib?)
  → Level 1: SIMD YUV→RGB conversion (simdutf-like)
  → GPU: Texture upload → Display
```

---

## 3. Level 6 — Sang Orkestrator: FFmpeg

> Pahlawan Utama: `ffmpeg` — Sutradara, editor, dan penerjemah video/audio.

FFmpeg adalah "pisau lipat Swiss" untuk multimedia. Ia adalah kerangka kerja yang berisi seperangkat pustaka (`libavcodec`, `libavformat`, `libavfilter`, dll.) yang bisa membaca, menulis, mentranskode, memotong, menggabungkan, dan menyaring hampir semua format media yang ada.

### 3.1 Arsitektur FFmpeg

```
┌─────────────────────────────────────────────────────────┐
│                      ffmpeg CLI                         │
├─────────────────────────────────────────────────────────┤
│  libavformat  │  libavcodec  │  libavfilter  │ libavutil │
│  (Demux/Mux)  │  (Codec)     │  (Filter)     │ (Utilitas)│
├───────────────┴──────────────┴───────────────┴──────────┤
│  libswscale   │  libswresample  │  libpostproc           │
│  (Scale/CS)   │  (Sample rate)  │  (Processing)          │
├───────────────┴────────────────┴────────────────────────┤
│  External Codec Libraries                                │
│  x264 · x265 · libvpx · libaom · libopus · lame · fdk   │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Pipeline Transcoding

Setiap operasi FFmpeg mengikuti pipeline ini:

1. **Probe:** Baca header file → identifikasi format kontainer, codec, resolution, bitrate
2. **Demuxing:** `libavformat` membaca kontainer (`.mp4`, `.mkv`, `.avi`, `.webm`) → pisahkan menjadi **streams** (video, audio, subtitle, attachment)
3. **Decoding:** `libavcodec` memanggil decoder yang sesuai (H.264 → `h264_decode`, VP9 → `vp9_decode`) → hasil: **raw frames** (YUV420P untuk video, PCM float untuk audio)
4. **Filtering (opsional):** Raw frames lewat `libavfilter` — scale, crop, rotate, drawtext, fps filter, audio volume, equalizer
5. **Encoding:** Raw frames → encoder (x264, libaom, libopus) → compressed bitstream
6. **Muxing:** Gabung streams + metadata → kontainer baru

### 3.3 Contoh Command & Yang Terjadi di Belakang

```bash
ffmpeg -i input.mp4 -c:v libx265 -c:a libopus -vf scale=1280:720 output.mkv
```

Di belakang layar:
1. Probe `input.mp4` → H.264 video, AAC audio
2. Inisialisasi `h264_decode` + `aac_decode`
3. Baca frame: untuk setiap paket → decode → raw frame
4. Scale raw frame dari resolusi asli ke 1280×720 (libswscale, SIMD-optimized)
5. Encode frame dengan `libx265` → HEVC bitstream
6. Resample audio dari 44.1KHz→48KHz (libswresample)
7. Encode audio dengan `libopus`
8. Mux H.265 + Opus ke kontainer Matroska (.mkv)

### 3.4 Kinerja & Optimasi

| Codec Path | Speed (fps) | CPU Usage | Kualitas Relatif |
|-----------|-------------|-----------|-----------------|
| H.264 → H.264 (copy stream) | 300-600 fps | ~5% | Lossless |
| H.264 → H.265 (libx265) | 15-40 fps | ~80% | ~50% bitrate saving |
| H.264 → AV1 (libaom) | 1-5 fps | ~100% | ~70% bitrate saving |
| H.264 → VP9 (libvpx) | 8-20 fps | ~60% | ~60% bitrate saving |

---

## 4. Level 5 — Codec Multimedia

> Pahlawan Utama: `x264`/`x265`, `libopus`, `lame`, `flac`

Codec adalah **penerjemah** antara sinyal mentah (raw video/audio) dan representasi terkompresi. Mereka adalah jantung dari Digital Plumbing.

### 4.1 Video Codec — Bagaimana Mereka Bekerja

Semua video codec modern (H.264, H.265, VP9, AV1) menggunakan arsitektur yang sama — hibrida **prediksi + transform + entropi**:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Frame    │───→│ Prediksi │───→│ Transform│───→│ Entropi  │───→ Bitstream
│ Input    │    │ Motion   │    │ DCT/DST  │    │ CABAC    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                     ↑
                ┌────┴────┐
                │ Frame   │
                │ Sebelum │
                │ (Referensi)│
                └─────────┘
```

**4.1.1 Frame Types**

| Type | Nama | Kompresi | Deskripsi |
|------|------|----------|-----------|
| **I-frame** | Intra-frame | Terendah | Keyframe lengkap. Bisa di-decode sendiri. Seperti JPEG. |
| **P-frame** | Predicted | Sedang | Hanya menyimpan perbedaan dari frame sebelumnya. |
| **B-frame** | Bidirectional | Tertinggi | Menyimpan perbedaan dari frame SEBELUM dan SESUDAH. |

**4.1.2 Motion Estimation**

Ini adalah bagian paling kompleks dan paling berat secara komputasi:

```c
// Simplified: motion search mencari block yang paling cocok di frame referensi
// Untuk setiap block 16×16 di frame saat ini:
for each macroblock in current_frame {
    best_match = INFINITY
    for each candidate in search_window(reference_frame, -64..+64, -64..+64) {
        sad = sum_absolute_differences(macroblock, candidate) // SAD = SSE4.1 instruction
        if sad < best_match {
            best_match = sad
            motion_vector = candidate_position - macroblock_position
        }
    }
}
```

**4.1.3 Transform Coding (DCT)**

Setelah prediksi, **residual** (selisih antara prediksi dan frame asli) di-transform dengan **Discrete Cosine Transform (DCT)**:

$$ Y_{uv} = \frac{2}{N} C(u) C(v) \sum_{x=0}^{N-1} \sum_{y=0}^{N-1} f(x,y) \cos\frac{(2x+1)u\pi}{2N} \cos\frac{(2y+1)v\pi}{2N} $$

DCT mengubah sinyal spasial (piksel) menjadi sinyal frekuensi. Energi terkonsentrasi di koefisien frekuensi rendah (pojok kiri atas). Koefisien frekuensi tinggi (yang kecil) bisa dibuang (quantization) tanpa mengurangi kualitas visual secara signifikan.

### 4.2 Audio Codec — Opus

Opus (RFC 6716) adalah codec audio paling canggih yang pernah dibuat:

| Mode | Bitrate | Sampling Rate | Use Case | Algoritma |
|------|---------|---------------|----------|-----------|
| SILK | 6-40 kbps | 8-12 kHz | Voice/VoIP | LPC (Linear Predictive Coding) |
| CELT | 32-510 kbps | 8-48 kHz | Music | MDCT (Modified DCT) |
| Hybrid | 6-64 kbps | 48 kHz | Voice+Music simultan | SILK low freq + CELT high freq |

Opus bisa **switch mode dalam frame yang sama** — bagian awal lagu dengan SILK (vokal solo) lalu switch ke CELT (full band saat musik masuk). Ini SANGAT adaptif.

### 4.3 Audio Lossless — FLAC

FLAC (Free Lossless Audio Codec) mengompresi audio tanpa kehilangan data:

1. **Blocking:** Bagi sampel audio menjadi block (default: 4096 sampel)
2. **Prediksi linier:** Cari model autoregresif yang memprediksi sampel berikutnya dari sampel sebelumnya
3. **Residual coding:** Simpan selisih antara prediksi dan nilai asli (yang kecil karena prediksi bagus)
4. **Rice coding:** Encode residual dengan Rice code (entropy coding optimal untuk distribusi geometris)

Rasio kompresi tipikal: 50-60% dari ukuran WAV asli.

---

## 5. Level 4 — Arsip & Kompresi Data

> Pahlawan Utama: `zlib`/`zstd`, `unrar`/`7-Zip`, `brotli`

### 5.1 Spektrum Kompresi

```
Kecepatan →  zstd(1)  lz4  snappy  zlib(1)  zstd(19)  xz  rar  7z  zpaq
            ────────────────────────────────────────────────────────────→
            <─── Real-time ───── <─────────── Maximum compression ─────────
```

### 5.2 Algoritma Inti

| Algoritma | Tahun | Teknik Dasar | Package |
|-----------|-------|-------------|---------|
| **Deflate** | 1993 | LZ77 + Huffman coding | zlib, gzip, png, zip |
| **LZMA** | 2001 | LZ77 + Range coding + Markov chain | 7z, xz |
| **Brotli** | 2013 | LZ77 + Huffman + Context modeling | HTTP (Chrome, Firefox) |
| **Zstandard** | 2015 | FSE (Finite State Entropy) + Dictionary | zstd (Facebook) |
| **LZ4** | 2011 | LZ77 tanpa entropi — hanya match copy | Real-time, database |

### 5.3 Benchmark: `silesia.tar` (202 MB — corpus campuran)

| Algoritma | Level | Size | Ratio | Compress | Decompress |
|-----------|-------|------|-------|----------|-----------|
| zlib (gzip -9) | 9 | 73 MB | 2.77× | 26.3 MB/s | 124.8 MB/s |
| zstd (--fast) | 1 | 79 MB | 2.56× | 357.4 MB/s | 421.1 MB/s |
| zstd | 19 | 55 MB | 3.67× | 4.3 MB/s | 175.2 MB/s |
| xz | 9 | 45 MB | 4.49× | 1.2 MB/s | 22.7 MB/s |
| bzip2 | 9 | 58 MB | 3.48× | 4.7 MB/s | 19.5 MB/s |
| brotli | 11 | 52 MB | 3.88× | 0.8 MB/s | 82.3 MB/s |

*Sumber: lzbench, Intel i7-12700, single-thread*

### 5.4 Zstd — The New Standard

Zstandard (zstd) adalah algoritma kompresi modern dari Facebook (Y. Collet, 2015):

**Keunggulan:**
- **Adaptive:** Level 1 (cepat seperti LZ4) sampai level 19 (kuat seperti xz)
- **Dictionary compression:** Pre-trained dictionary untuk domain spesifik (JSON, log, source code) — kompresi 2-4× lebih baik
- **Trainable dictionary:** `zstd --train` belajar dari sampel data kamu
- **Kernel integration:** Linux kernel 5.9+ sudah include zstd untuk initramfs, btrfs, swap

### 5.5 Zlib — Tulang Punggung Internet

zlib (1995) adalah **pustaka C yang paling banyak di-deploy di sejarah manusia**. Setiap:
- Koneksi HTTPS (TLS compression — dulu)
- Respons HTTP (Content-Encoding: gzip)
- File PNG (IDAT chunk)
- File ZIP
- Git packfile
- Distribusi paket (apt, yum, npm)

Menggunakan **Deflate** — kombinasi LZ77 (sliding window dictionary) + Huffman coding. Kode sumbernya ~20,000 baris C dan telah diaudit berulang kali.

---

## 6. Level 3 — Codec Gambar

> Pahlawan Utama: `libjpeg-turbo`, `libpng`, `libwebp`, `libavif`

| Codec | Tahun | Lossy/Lossless | Kasus | Ukuran Relatif (vs PNG) |
|-------|-------|---------------|-------|----------------------|
| JPEG | 1992 | Lossy | Foto, web | ~10-20% |
| PNG | 1996 | Lossless | Screenshot, UI | 100% (baseline) |
| WebP | 2010 | Keduanya | Web modern | ~25-30% |
| AVIF | 2019 | Keduanya | Web next-gen | ~15-20% |
| JPEG XL | 2021 | Keduanya | Universal future | ~10-15% |

### 6.1 libjpeg-turbo — SIMD yang Menyelamatkan Web

libjpeg-turbo adalah **implementasi SIMD dari JPEG codec** — 2-4× lebih cepat dari libjpeg asli karena menggunakan:

- **Intel:** MMX, SSE2, SSE4, AVX2, AVX-512
- **ARM:** NEON
- **PowerPC:** AltiVec

Tanpa libjpeg-turbo, loading gambar di web terasa 2-3× lebih lambat.

### 6.2 PNG — Deflate untuk Gambar

PNG menggunakan **Deflate** (sama dengan zlib) untuk kompresi lossless. Tapi ada langkah sebelum Deflate:

1. **Filtering:** Setiap baris piksel di-transform dengan filter (None, Sub, Up, Average, Paeth) untuk mengurangi entropi
2. **Deflate:** Hasil filtering di-kompres dengan Deflate

**Ini contoh klasik digital plumbing:** dua komponen independen (filter PNG + zlib) dirangkai untuk menyelesaikan masalah spesifik (gambar lossless).

---

## 7. Level 2 — Parsing, Validasi, Kriptografi

> Pahlawan Utama: `libxml2`, `openssl`, `protobuf`, `libcurl`

### 7.1 libxml2 — Parser Terlama yang Masih Hidup

libxml2 (1999) mem-parsing XML, HTML, dan SVG. Digunakan oleh:
- **PHP** (SimpleXML, DOMDocument)
- **Python** (lxml, minidom)
- **Ruby** (libxml-ruby)
- **Chromium** (sebagian parsing SVG)
- **macOS / iOS** (CoreGraphics parsing SVG)

**Arsitektur:** SAX (stream-based, low memory) + DOM (tree-based, random access). Keduanya diimplementasikan dengan finite state machine yang digerakkan oleh tabel transisi.

### 7.2 OpenSSL — Pipa Kriptografi

OpenSSL bukan sekadar HTTPS. Ia menyediakan:
- **Cipher:** AES, ChaCha20, DES, RC4, Camellia
- **Hash:** SHA-1, SHA-256/512, SHA-3, BLAKE2
- **Public key:** RSA, DSA, ECDSA, Ed25519
- **TLS:** TLS 1.2, TLS 1.3, DTLS
- **X.509:** Certificate parsing, validation, chain building

Setiap aplikasi yang melakukan koneksi aman di internet — HTTPS, SSH, VPN, email — menggunakan OpenSSL atau fork-nya (LibreSSL, BoringSSL).

### 7.3 Protobuf — Serialisasi Struktur Data

Protobuf (Protocol Buffers) adalah skema serialisasi dari Google:

```
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 results_per_page = 3;
}

→ Wire format (binary):
  0A 05 68 65 6C 6C 6F  → field 1 (string): "hello"
  10 01                  → field 2 (varint): 1
  18 0A                  → field 3 (varint): 10
```

**Keunggulan vs JSON/XML:** ~3-10× lebih kecil, ~10-100× lebih cepat parsing. Ini yang digunakan di gRPC, MCP, dan komunikasi internal Google.

---

## 8. Level 1 — Aritmatika Biner & Hashing

> Pahlawan Utama: `xxHash`, `base64`, `simdutf`, `CRC32`

### 8.1 Hashing Non-Kriptografis

Untuk hash table, deduplikasi, checksum — hashing cepat LEBIH penting dari hashing aman:

| Hash | Throughput (GB/s) | Collision Rate | Digunakan di |
|------|------------------|---------------|-------------|
| xxHash | 15-30 GB/s | Sangat rendah | Linux kernel, git, ZFS, RocksDB |
| CityHash | 10-20 GB/s | Rendah | Google internal |
| MurmurHash3 | 8-15 GB/s | Rendah | Cassandra, Hadoop, Elasticsearch |
| BLAKE3 | 5-10 GB/s | Sangat rendah (kriptografis!) | Mesin, Sloth |
| SHA-256 | 0.5-1 GB/s | Nol (kriptografis) | TLS, Bitcoin, Git |

### 8.2 Base64 — Konversi Binary→ASCII

Base64 mengubah binary (8-bit) menjadi ASCII (6-bit). Setiap 3 byte → 4 base64 karakter. Overhead: ~33%.

```python
import base64
base64.b64encode(b'\x00\x01\x02\x03\x04\x05')
# → 'AAECAwQF'
```

Digunakan di: email (MIME), web (data URIs), JWT, PEM certificates, CSS image data URIs.

### 8.3 SIMD UTF-8 Validation (simdutf)

Validasi UTF-8 adalah overhead konstan di aplikasi web. Setiap input dari user harus divalidasi. `simdutf` menggunakan SIMD untuk memvalidasi 64+ byte sekaligus:

```c
// Menggunakan AVX-512, validasi 64 byte UTF-8 dalam 3-5 siklus:
// 1. Load 64 bytes ke ZMM register
// 2. Check: kontinuitas, min/max range, overlong sequences
// 3. Hasil: bitmask — byte mana yang invalid
```

**Throughput:** ~5-10 GB/s (AVX-512) — 50× lebih cepat dari validasi byte-by-byte.

---

## 9. Peta Koneksi ke Vault

Dokumen ini adalah benang merah yang menghubungkan fondasi paling rendah ke puncak tertinggi di vault.

| Domain Vault | Koneksi dengan Pipa Digital |
|:---|:---|
| [[math-and-algorithms]] | **Pondasi paling langsung.** Algoritma Huffman, LZ77, DCT, dan Rantai Markov adalah "jiwa" dari `zlib`, `x264`, dan `libopus` |
| [[computer-science-foundations]] | **Implementasi SIMD.** Kecepatan `libjpeg-turbo` berasal dari instruksi SIMD di CPU |
| [[hierarchy-osint-rf]] | **Transformasi Sinyal.** DCT dalam codec video adalah "sepupu" dari FFT untuk analisis sinyal RF |
| [[forensic-imaging-analysis]] | **Senjata Forensik.** FFmpeg adalah alat wajib untuk memproses dan memulihkan file video rusak |
| [[http-protocol-deepdive]] | **Kompresi Web.** `brotli` dan `gzip` adalah fondasi *content encoding* di HTTP |
| [[llm-security-red-teaming-attack-surface-ai-layer]] | **Serangan pada Parser.** Kerentanan di `libxml2`, `libpng` adalah celah keamanan klasik |
| [[encoding-serialization-compression-deepdive]] | **Keluarga dekat.** Encoding, serialisasi, kompresi — tiga sisi dari kubus yang sama |
| [[embedding-model-selection-finetuning]] | **Tokenisasi.** Codec audio (Opus) punya prinsip yang sama dengan tokenizer LLM |

### Diagram Koneksi

```
hierarchy-digital-plumbing.md
    ├── ffmpeg-multimedia-framework-deepdive.md                [Level 6]
    ├── codec-architecture-x264-x265-deepdive.md               [Level 5]
    ├── compression-algorithms-zlib-zstd-deepdive.md           [Level 4]
    ├── plumbing-foundations-image-codec-parsing-crypto.md     [Level 3-2-1]
    │
    ├── Koneksi ke math-and-algorithms (Huffman, DCT, LZ77)
    ├── Koneksi ke computer-science-foundations (SIMD, CPU arch)
    ├── Koneksi ke http-protocol-deepdive (gzip, brotli)
    ├── Koneksi ke forensic-imaging-analysis (FFmpeg)
    └── Koneksi ke encoding-serialization-compression-deepdive
```

---

## 10. References

1. FFmpeg Documentation. https://ffmpeg.org/documentation.html
2. zlib Manual. https://zlib.net/manual.html
3. RFC 6716 — Definition of the Opus Audio Codec. https://datatracker.ietf.org/doc/html/rfc6716
4. Y. Collet. *"Zstandard — Real-time data compression algorithm."* (2015). https://github.com/facebook/zstd
5. P. Deutsch. *"DEFLATE Compressed Data Format Specification."* RFC 1951 (1996).
6. I. Mironov. *"Rencently (xxHash) — Extremely fast non-cryptographic hash algorithm."* https://github.com/Cyan4973/xxHash
7. Google. *"Protocol Buffers."* https://protobuf.dev/
8. libjpeg-turbo. *"SIMD-accelerated JPEG codec."* https://libjpeg-turbo.org/
9. *"The x264/x265 Video Codec."* VideoLAN. https://www.videolan.org/developers/x264.html
10. J. L. Gailly, M. Adler. *"zlib 1.2.x Manual."* (1995-2025).
11. W3C. *"WebP Image Format."* (2010-2025). https://developers.google.com/speed/webp
12. AOM. *"AV1 — A New Video Coding Standard."* (2019-2025). https://aomedia.org/
13. I. L. R. B. (Independent JPEG Group). *"libjpeg API Documentation."*
14. RFC 1952 — GZIP file format specification version 4.3.
15. W. Richard Stevens. *"TCP/IP Illustrated, Vol. 1."* Chapter: Content Encoding.

audited
---
