---
tags:
  - digital-plumbing
  - compression
  - zlib
  - zstd
  - deflate
  - lzma
  - information-theory
  - entropy-coding
aliases:
  - Compression Algorithms Deep-Dive
  - zlib zstd Deflate LZMA
  - Data Compression Internals
  - Lossless Compression Taxonomy
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---
# 🗜️ Compression Algorithms — Dari Deflate hingga Zstandard

> [!tip] Semua algoritma kompresi lossless bekerja dengan menghilangkan redundansi statistik. **Deflate** (zlib/gzip) — kombinasi LZ77 + Huffman coding — adalah fondasi internet sejak 1993. **Zstandard** (zstd) — dengan Finite State Entropy + dictionary compression — adalah penerus modern 3-5× lebih cepat dengan rasio lebih baik. **LZMA** (7-Zip/xz) mencapai rasio tertinggi dengan Markov chain + range coding. Dokumen ini membedah teori informasi di belakang masing-masing, implementasi konkret, benchmark, dan kasus penggunaan.

---

## 1. Klasifikasi Algoritma Kompresi

### 1.1 Lossless vs Lossy

| Aspek | Lossless (Deflate, zstd, LZMA) | Lossy (JPEG, MP3, H.264) |
|-------|:-----------------------------:|:------------------------:|
| Output identik input? | ✅ Ya | ❌ Tidak (tapi "cukup mirip") |
| Rasio kompresi | 2-5× (umum), 10-20× (ekstrim) | 10-100× |
| Matematika | Information theory (Shannon) | Psychoacoustic/psychovisual modeling |
| Bidang | Data, executable, text | Image, audio, video |
| Dokumen terkait | Catatan ini | codec-architecture-x264-x265-deepdive |

### 1.2 Keluarga Algoritma Lossless

```
                    ┌────────────────────┐
                    │  Lossless          │
                    │  Compression       │
                    └────────┬───────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
     ┌──────────┐    ┌──────────────┐  ┌──────────────┐
     │ Dictionary│    │ Entropy      │  │ Context      │
     │ (LZ*)     │    │ (Huffman,    │  │ (PPM, CM)    │
     │           │    │  Arithmetic)  │  │              │
     └──────────┘    └──────────────┘  └──────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
     LZ77, LZSS      Huffman, CABAC,     PPMd, PAQ,
     LZMA, LZ4       FSE, ANS            CM (Context Mixing)
```

**Kebanyakan algoritma adalah HYBRID:**
- Deflate = LZ77 + Huffman
- LZMA = LZ77-like + Range coding + Markov chain
- zstd = LZ77-like + FSE
- Brotli = LZ77 + Huffman + Context modeling

---

## 2. LZ77 — Jantung Dictionary Compression

### 2.1 Prinsip

LZ77 (Lempel-Ziv 1977) mengganti string berulang dengan **pointer** ke kemunculan sebelumnya + **length**:

```
Input:  "AABABABCABA"
Output: A A B A B A B C A B A
          ^     ^       ^
          │     │        └── (7,3) = ke belakang 7, copy 3: "ABA"
          │     └── (3,3) = ke belakang 3, copy 3: "ABA"
          └── (2,2) = ke belakang 2, copy 2: "AB"
```

**Parameter LZ77:**
| Parameter | Deflate | LZMA | zstd | LZ4 |
|-----------|:-------:|:----:|:----:|:---:|
| Window size | 32 KB | 4 GB | 32 MB | 64 KB |
| Min match length | 3 | 2 | 3 | 4 |
| Max match length | 258 | ∞ | ∞ | 255 |
| Hash chain | Ya | Ya | Ya (hash table) | No (hash only) |

### 2.2 Implementasi Sliding Window

```c
// Simplified LZ77 encoding
#define WINDOW_SIZE 32768  // 32 KB (Deflate)
#define MIN_MATCH 3
#define MAX_MATCH 258

void lz77_encode(const uint8_t *input, size_t len) {
    // Hash table untuk quick match
    uint32_t hash_table[65536] = {0};  // 3-byte hash → position
    
    for (size_t pos = 0; pos < len; ) {
        // Hash 3 bytes pertama
        uint32_t hash = (input[pos] << 16) | (input[pos+1] << 8) | input[pos+2];
        hash = (hash * HASH_MULT) & 0xFFFF;
        
        int32_t match_pos = hash_table[hash];
        int match_len = 0;
        
        if (match_pos > 0 && (pos - match_pos) <= WINDOW_SIZE) {
            // Coba match — extend sebanyak mungkin
            while (input[match_pos + match_len] == input[pos + match_len] 
                   && match_len < MAX_MATCH) {
                match_len++;
            }
        }
        
        if (match_len >= MIN_MATCH) {
            // Output: (distance, length) — 3 byte: 15 bit distance + 8 bit length
            output_literal_length(match_len - MIN_MATCH);
            output_distance(pos - match_pos - 1);
            pos += match_len;
        } else {
            // Output literal
            output_literal(input[pos]);
            pos++;
        }
        
        // Update hash
        hash_table[hash] = pos;
    }
}
```

---

## 3. Huffman Coding — Entropy Coding Optimal

### 3.1 Prinsip

Huffman coding mengkodekan simbol dengan panjang bit **berbanding terbalik dengan frekuensi kemunculan**:

| Simbol | Frekuensi | Huffman Code | Panjang |
|--------|:---------:|:------------:|:-------:|
| A | 40% | `0` | 1 bit |
| B | 25% | `10` | 2 bit |
| C | 20% | `110` | 3 bit |
| D | 15% | `111` | 3 bit |

**Rata-rata:** $0.40 \times 1 + 0.25 \times 2 + 0.20 \times 3 + 0.15 \times 3 = 1.95$ bit/simbol

**Entropi Shannon:** $H = -\sum p_i \log_2(p_i) = 1.92$ bit/simbol

**Efisiensi:** $1.92 / 1.95 = 98.5\%$ — Huffman mencapai batas teoritis untuk integer-length codes.

### 3.2 Canonical Huffman (Digunakan di Deflate)

Deflate tidak mengirimkan pohon Huffman — ia mengirimkan **panjang kode** (bit length) untuk setiap simbol, lalu decoder merekonstruksi pohon secara kanonikal:

```c
// Canonical Huffman: kode ditentukan oleh panjang, bukan struktur pohon
// Simbol diurutkan berdasarkan panjang → kode berurutan
// Length:  [A:1, B:2, C:3, D:3]
// Sort:    A(1), B(2), C(3), D(3)
// Kode:    A=0 (1bit), B=10 (2bit), C=110 (3bit), D=111 (3bit)
```

**Ini yang membuat Deflate efisien:** hanya butuh ~4 byte overhead untuk setiap blok, bukan pohon utuh.

---

## 4. Deflate — Tulang Punggung Internet

### 4.1 Sejarah & Dampak

| Tahun | Kejadian |
|:-----:|----------|
| 1993 | P. Deutsch merilis Deflate (RFC 1951). zlib sebagai referensi implementasi |
| 1996 | PNG mengadopsi Deflate (bukan GIF yang kena paten LZW) |
| 1996 | HTTP/1.1 menstandarisasi Content-Encoding: gzip |
| 2010-an | Hampir semua traffic HTTP via gzip |
| 2025 | zlib dipasang di ~6 miliar device. Mungkin pustaka paling banyak di-deploy sepanjang sejarah |

### 4.2 Format Blok

Deflate membagi data menjadi **blok** (biasanya 64KB). Setiap blok bisa:

| Blok Type | Deskripsi | Digunakan untuk |
|-----------|-----------|----------------|
| **Stored** | Tanpa kompresi | Data yang sudah random (gambar terenkripsi) |
| **Fixed Huffman** | Huffman tree statis (predefined) | Data kecil, meminimalkan overhead tabel |
| **Dynamic Huffman** | Huffman tree dinamis + LZ77 | Data biasa — biasanya yang paling efisien |

### 4.3 Kinerja & Limitasi

zlib (gzip -6 — default):

| Data | Size | Compressed | Ratio | Compress (MB/s) | Decompress (MB/s) |
|------|:----:|:----------:|:-----:|:---------------:|:-----------------:|
| HTML | 1 KB | 0.6 KB | 1.7× | 25 | 105 |
| JSON | 100 KB | 15 KB | 6.7× | 35 | 140 |
| Exe | 1 MB | 0.5 MB | 2.0× | 30 | 120 |
| Silesia | 202 MB | 73 MB | 2.8× | 26 | 125 |

**Limitasi utama Deflate:**
1. **Window 32 KB:** Match hanya bisa mencari 32 KB ke belakang — tidak bisa mendeteksi redundansi jarak jauh
2. **Huffman optimal untuk integer codes:** membuang 0.5-1 bit/detik dari batas Shannon
3. **Hash collision:** implementasi zlib hanya menggunakan 3-byte hash — false match mengurangi kompresi

---

## 5. Zstandard (zstd) — Generasi Berikutnya

### 5.1 Finite State Entropy (FSE)

Zstandard mengganti Huffman dengan **FSE** (t-distribution / Asymmetric Numeral Systems — ANS):

$$ \text{State update: } s' = \lfloor s / f_s \rfloor + b + C_s $$

**Keuntungan FSE vs Huffman:**
- **Fractional bits:** FSE bisa encode dengan ~0.01 bit overhead, bukan 1 bit seperti Huffman
- **Throughput:** FSE decode ~500 MB/s/core — mendekati batas memori bandwidth
- **Near-optimal:** FSE mencapai ≈99.9% dari batas Shannon

### 5.2 Dictionary Compression

Zstandard mendukung **pre-trained dictionary**:

```bash
# Train dictionary dari sampel data
zstd --train *.json -o json.dict

# Compress dengan dictionary
zstd -D json.dict data.json -o data.json.zst
```

**Hasil untuk data JSON kecil (100-500 byte):**

| Tanpa dict | Dengan dict | Perbaikan |
|:----------:|:-----------:|:---------:|
| 250 byte | 80 byte | 3.1× lebih kecil |
| 95 MB/s (decompress) | 450 MB/s | 4.7× lebih cepat |

**Use case:** Database log, API responses, source code, konfigurasi — semua data dengan struktur berulang.

### 5.3 Benchmark Komprehensif

**Dataset: silesia.tar (202 MB, campuran)**

| Algoritma | Level | Zise | Rasio | Compress | Decompress |
|-----------|:----:|:----:|:----:|:--------:|:----------:|
| zstd | 1 | 79 MB | 2.56× | **357 MB/s** | **421 MB/s** |
| zstd | 3 | 67 MB | 3.01× | 118 MB/s | 385 MB/s |
| zstd | 10 | 60 MB | 3.37× | 18 MB/s | 335 MB/s |
| zstd | 19 | 55 MB | 3.67× | 4 MB/s | 175 MB/s |
| zlib (gzip -9) | 9 | 73 MB | 2.77× | 26 MB/s | 125 MB/s |
| xz | 9 | 45 MB | 4.49× | 1.2 MB/s | 23 MB/s |
| brotli | 11 | 52 MB | 3.88× | 0.8 MB/s | 82 MB/s |
| lz4 | 1 | 108 MB | 1.87× | **490 MB/s** | **680 MB/s** |

**Insight:** zstd level 1 mengalahkan zlib -9 di **RASIO** (2.56× vs 2.77× — hampir sama) dan **KECEPATAN** (357 vs 26 MB/s — 13.7× lebih cepat).

---

## 6. LZMA — Rasio Tertinggi

### 6.1 Markov Chain + Range Coding

LZMA (Lempel-Ziv-Markov chain Algorithm) menambahkan:

1. **LZ77-like:** Match finding dengan window besar (4 GB teori, praktik ~1 GB)
2. **Context modeling:** Markov chain ya memprediksi bit berikutnya berdasarkan context (posisi, literal sebelumnya, state LZ)
3. **Range coding:** Arithmetic coding dengan presisi 64-bit — lebih efisien dari Huffman
4. **Distance/context adaptive:** Algoritma mengadaptasi model berdasarkan jenis data

### 6.2 7z vs xz

| Format | Algoritma | Window max | Karakteristik |
|--------|-----------|:----------:|---------------|
| 7z | LZMA | 4 GB | Rasio tertinggi, fitur enkripsi AES |
| xz | LZMA2 | 4 GB | Streaming-friendly, digunakan di Linux (tar.xz) |
| RAR | LZSS + PPM | — | Proprietary, recovery record |

---

## 7. LZ4 & Snappy — Real-time Compression

Digunakan untuk kompresi data **dalam memori** (database, messaging, log):

```python
# LZ4 — digunakan di Apache Arrow, RocksDB, Linux kernel (zram)
import lz4.frame
compressed = lz4.frame.compress(data * 100)  # ~2.5 GB/s compress
decompressed = lz4.frame.decompress(compressed)  # ~4.5 GB/s decompress
```

| Algoritma | Compress | Decompress | Rasio | Digunakan di |
|-----------|:--------:|:----------:|:----:|-------------|
| LZ4 -1 | 490 MB/s | 680 MB/s | 1.87× | Redis, RocksDB, Kafka, Linux |
| Snappy | 350 MB/s | 550 MB/s | 1.65× | BigTable, Cassandra, MongoDB |
| Zstd -1 | 357 MB/s | 421 MB/s | 2.56× | Facebook, AWS, systemd |
| Brotli -1 | 180 MB/s | 330 MB/s | 2.30× | HTTP (Chrome, Firefox) |

---

## 8. Panduan Memilih Algoritma

| Use Case | Pilihan | Alasan |
|----------|---------|--------|
| HTTP response (API) | **zstd** atau **brotli** | Bobot seimbang, CPU modern support |
| HTTP response (end-user) | **brotli** | Chrome/Firefox semua support, rasio terbaik |
| File archiv (backup) | **xz** atau **zstd -19** | Rasio terbaik |
| Log rotation | **zstd -3** | 3× lebih kecil dari text, 300 MB/s compress |
| Database compression | **LZ4** atau **zstd -1** | Real-time, query tidak melambat |
| Video/audio archiving | **Lossy codec** (H.265, AV1) | 100-1000× kompresi > LZMA |
| Firmware/executable | **zstd --ultra** | Rasio + verifikasi SHA-256 |
| Real-time logging | **LZ4** | 5 Gbps throughput per core |

---

## References

1. P. Deutsch. *"DEFLATE Compressed Data Format Specification."* RFC 1951 (1996).
2. P. Deutsch, J. L. Gailly. *"ZLIB Compressed Data Format."* RFC 1950 (1996).
3. Y. Collet. *"Zstandard — Real-time data compression algorithm."* (2015). https://github.com/facebook/zstd
4. I. Pavlov. *"LZMA SDK Documentation."* (2001-2025). https://7-zip.org/sdk.html
5. Y. Collet, C. Turner. *"Faster and Smaller: Building Better Compression with Zstd."* (2016).
6. J. Duda. *"Asymmetric Numeral Systems: Entropy Coding Combining Speed of Huffman Coding with Compression Rate of Arithmetic Coding."* (2013).
7. D. Huffman. *"A Method for the Construction of Minimum-Redundancy Codes."* Proceedings of the IRE, 1952.
8. J. Ziv, A. Lempel. *"A Universal Algorithm for Sequential Data Compression."* IEEE TIT, 1977.
9. Y. Collet. *"Understanding Compression Benchmarks."* (2018).
10. J. L. Gailly, M. Adler. *"zlib 1.2.x Manual."* (1995-2025).

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[Note/01_Library/Fundamentals/hierarchy-digital-plumbing]] | §5 Level 4 — Kompresi Data |
| [[codec-architecture-x264-x265-deepdive]] | Codec video juga pakai entropy coding (CABAC) — sepupu dari Huffman |
| [[math-and-algorithms]] | Entropy, Huffman tree, Markov chain — aplikasi langsung teori informasi |
| [[encoding-serialization-compression-deepdive]] | Kompresi sebagai tahap akhir dari pipeline encode |
| [[http-protocol-deepdive]] | Content-Encoding: gzip, br, zstd |
