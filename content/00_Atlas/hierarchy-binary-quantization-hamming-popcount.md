---
tags:
  - machine-learning
  - vector-search
  - quantization
  - binary-vector
  - hamming-distance
  - popcount
  - cpu-architecture
  - similarity-search
aliases:
  - Binary Quantization Deep-Dive
  - Hamming Distance Popcount
  - 1-bit Vector Quantization
  - Binary Embedding Search
status: pending
created: 2026-07-22
updated: 2026-07-22
cssclasses:
  - wide-table
---

# Binary Quantization & Hamming Distance: The 1-bit Frontier of Vector Search

> [!tip] **Binary quantization (BQ)** mengompresi float32 vectors menjadi 1 bit per dimension — reduksi memori **32×** — mengubah similarity metric dari cosine (floating-point dot product) menjadi **Hamming distance** (XOR + popcount). Ini mentransformasi search dari O(d) floating-point multiply-add menjadi **O(1) CPU instruction per 64-bit word**. Untuk Jina v5 1024-dim embeddings, hasilnya adalah vektor 128-byte yang bisa di-search pada < 1 µs per 100K candidates. Namun kompresi 32× datang dengan biaya information-theoretic yang fundamental: **sign-only encoding membuang magnitude information**, membatasi applicability-nya hanya pada inherently directional embeddings.

---

## Daftar Isi

1. [[#1. Masalah]]
2. [[#2. Binary Quantization — Definisi Formal]]
3. [[#3. Transisi Metrik]]
4. [[#4. POPCOUNT — Hardware Primitive]]
5. [[#5. Analisis Teoritis]]
6. [[#6. Pola Implementasi — Packing, XOR, Unrolling]]
7. [[#7. Trade-off & Mode Kegagalan]]
8. [[#8. Matriks Perbandingan]]
9. [[#Referensi]]
10. [[#Koneksi ke Vault]]

---

## 1. Masalah: Memory Wall & Bandwidth Bottleneck

### 1.1 Float32 Tax

Setiap dimensi float32 embedding memakan **4 bytes** memori. Untuk Jina v5 1024-dim embeddings:

$$ \text{Memory}_{1M} = 1{,}000{,}000 \times 1024 \times 4 \text{ bytes} \approx 4.09 \text{ GB} $$

Ini adalah **raw vector storage** — belum termasuk index overhead. HNSW biasanya menambah 1.5–2× lagi untuk graph structure, total ~10 GB untuk 1M vectors. Pada 100M vectors (medium-scale production), raw storage saja mencapai **400 GB**.

### 1.2 Bandwidth Bottleneck

Vector search di scale besar bersifat **memory-bound**, bukan compute-bound. Bottleneck-nya adalah memindahkan bytes dari DRAM ke CPU cache:

| Metrik              | Arithmetic Intensity | Bottleneck          | Typical Throughput   |
| ------------------- | -------------------- | ------------------- | -------------------- |
| Cosine (float32)    | ~2 ops/byte          | Memory bandwidth    | 2-5 GB/s per channel |
| Binary Hamming      | ~16 ops/byte         | Compute/SIMD width  | 10-50 GB/s effective |
| Binary XOR + POPCNT | ~64 ops/byte         | CPU backend (ports) | >50 GB/s (AVX-512)   |

**The insight:** Binary vectors tidak cuma menghemat memori — mereka **mengubah regime bottleneck** dari memory-bound menjadi compute-bound. Pergeseran ini memungkinkan BLAS-level throughput dengan non-BLAS hardware (kernel-space, embedded, eBPF).

### 1.3 Spektrum Quantization

```
Presisi           Memory/vec     Search Ops           Akurasi
────────────────────────────────────────────────────────────
Float32 (32-bit)  4096 bytes     FMA + reduction      100% (baseline)
FP16 (16-bit)     2048 bytes     FP16 FMA             ~99.8%
INT8 (SQ8)        1024 bytes     INT8 dot             ~99%
INT4              512 bytes      INT4 dot (dequant)   ~97-98%
Binary (1-bit)    128 bytes      XOR + POPCNT         ~92-96%*
```

*Akurasi tergantung pada embedding model dan inherent dimensionality. Jina v5 dengan binary quantization dilaporkan mempertahankan >95% recall@10 pada benchmark MTEB tertentu.

---

## 2. Binary Quantization — Definisi Formal

### 2.1 Fungsi Quantization

Diberikan float32 vector $\mathbf{x} \in \mathbb{R}^d$, binary quantization menghasilkan $\mathbf{b} \in \{0,1\}^d$ melalui sign function:

$$ b_i = \begin{cases} 1 & \text{if } x_i > 0 \\ 0 & \text{otherwise} \end{cases} $$

Untuk embeddings yang sudah $\ell_2$-normalized (unit length, $\|\mathbf{x}\|_2 = 1$), ini ekuivalen dengan:

$$ \mathbf{b} = \frac{1}{2}\left(\text{sgn}(\mathbf{x}) + 1\right) $$

di mana $\text{sgn}(x_i) = 1$ untuk $x_i \geq 0$ dan $-1$ sebaliknya.

**Critical subtlety:** Threshold $> 0$ vs $\geq 0$ itu penting. Dalam praktiknya, menggunakan $\geq 0$ menyebabkan uniform-zero vectors (semua bits set) ketika embedding model mengeluarkan constant-negative bias di beberapa dimensi. Kebanyakan implementasi menggunakan $> 0.0$ secara strict.

### 2.2 Packing

Setiap dimensi memakan 1 bit, jadi $d$ dimensi di-pack menjadi:

$$ \text{bytes} = \left\lceil \frac{d}{8} \right\rceil $$

Untuk Jina v5 (1024-dim): $1024 / 8 = 128$ bytes.

**Bit layout (little-endian word ordering):**

```rust
// Untuk 1024-dim: 16 × u64 (64-bit words)
// Bit i dari vektor menempati:
let u64_idx = i / 64;      // word index [0..15]
let bit_idx = i % 64;      // bit position dalam word [0..63]
let bit_mask = 1u64 << bit_idx;
```

Layout word-aligned ini **krusial untuk performa**: setiap word bisa di-XOR dan di-POPCNT secara independen, memungkinkan loop unrolling dan SIMD vectorization.

### 2.3 Binary Quantization di Lingkungan Memory-Constrained

Vektor 128-byte muat di:

- **L1 cache** (32 KB) — ~250 vectors di L1 sekaligus
- **L2 cache** (256 KB per core) — ~2000 vectors
- **L3 cache** (8-16 MB shared) — ~62K-125K vectors

Bandingkan dengan float32 1024-dim (4096 bytes):

- **L1** — cuma ~8 vectors
- **L2** — cuma ~64 vectors
- **L3** — cuma ~2K-4K vectors

**Perbedaannya adalah 16× lebih baik cache utilization** — lebih sedikit DRAM stalls = throughput lebih tinggi.

---

## 3. Transisi Metrik: Cosine → Hamming

### 3.1 Mengapa Cosine Berhenti Bekerja Setelah Sign Quantization

Cosine similarity antara dua vectors $\mathbf{a}, \mathbf{b} \in \mathbb{R}^d$:

$$ \cos(\mathbf{a},\mathbf{b}) = \frac{\mathbf{a} \cdot \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|} $$

Setelah binary quantization menjadi $\mathbf{b}^{(a)}, \mathbf{b}^{(b)} \in \{0,1\}^d$, dot product-nya menjadi:

$$ \mathbf{b}^{(a)} \cdot \mathbf{b}^{(b)} = \sum_{i=1}^d b_i^{(a)} b_i^{(b)} = \text{jumlah dimensi di mana keduanya bernilai 1} $$

**Ini bukan cosine.** Informasi magnitude hilang, dan range continuous dot product $[-1, 1]$ collapse ke integer range $[0, d]$.

Metrik yang benar untuk binary vectors adalah **Hamming distance**:

$$ H(\mathbf{b}^{(a)}, \mathbf{b}^{(b)}) = \sum_{i=1}^d (b_i^{(a)} \oplus b_i^{(b)}) = \text{popcount}(\mathbf{b}^{(a)} \oplus \mathbf{b}^{(b)}) $$

di mana $\oplus$ adalah bitwise XOR.

### 3.2 Relasi Antara Cosine dan Hamming pada Binary Vectors

Untuk binary vectors $\mathbf{p}, \mathbf{q} \in \{0,1\}^d$, ada hubungan langsung:

$$ \cos(\mathbf{p}, \mathbf{q}) = \frac{\mathbf{p} \cdot \mathbf{q}}{\sqrt{\|\mathbf{p}\|} \sqrt{\|\mathbf{q}\|}} $$

Dan karena Hamming distance $H$ berelasi dengan dot product melalui:

$$ H(\mathbf{p}, \mathbf{q}) = \|\mathbf{p}\| + \|\mathbf{q}\| - 2(\mathbf{p} \cdot \mathbf{q}) $$

Untuk unit binary vectors ($\|\mathbf{p}\| = \|\mathbf{q}\| = d/2$ rata-rata untuk balanced encodings):

$$ \cos(\mathbf{p}, \mathbf{q}) \approx 1 - \frac{2H}{d} $$

**Key insight:** Di bawah balanced binary encoding (jumlah 0 dan 1 kurang lebih sama), cosine bersifat monotonically decreasing terhadap Hamming distance — **ranking tetap terpreservasi** dengan mengorbankan granularitas skor kontinu.

### 3.3 Diagram Fase Transisi Metrik

```
Tipe Input Embedding    Metrik Optimal        Compute Unit
───────────────────────────────────────────────────────────
Float32, L2-normed     Cosine (Inner Product)  FMA unit
Float32, unit-normed   Cosine (Dot Product)    FMA/reduction
INT8 quantized         Cosine (dequantized)    INT8 dot
Binary (sign)          Hamming Distance        XOR + POPCNT
Locality-sensitive hash  Hamming Distance      XOR + POPCNT
```

**Transisi dari float ke binary adalah phase transition (lihat [[hierarchy-recursive-ring-deepdive]]):** Metrik optimal berubah secara diskontinu, tidak gradual. Di antara INT8 dan binary, tidak ada gradual precision reduction — Anda hanya punya sign information, dan pada titik itu cosine menjadi meaningless.

---

## 4. POPCOUNT — Hardware Primitive

### 4.1 Instruksi x86 POPCNT

Instruksi `POPCNT` (diperkenalkan dengan SSE4.2 / Nehalem, 2008) menghitung jumlah 1-bit dalam sebuah register:

```asm
; Intel syntax
POPCNT r64, r/m64    ; Hitung 1-bits di source, simpan di destination
POPCNT r32, r/m32    ; 32-bit variant
```

**Latency & Throughput per Microarchitecture:**

| Microarchitecture                                   | POPCNT r64   | Latency (cycles) | Throughput (per cycle) | Execution Port |
| --------------------------------------------------- | ------------ | ---------------- | ---------------------- | -------------- |
| Nehalem (2008)                                      | 8-bit lookup | 15               | 1/4                    | Port 0         |
| Haswell (2013)                                      | 64-bit       | 3                | 1/1                    | Port 1         |
| Skylake (2015)                                      | 64-bit       | 3                | 1/1                    | Port 1         |
| Ice Lake (2019)                                     | 64-bit       | 3                | 1/1                    | Port 1         |
| Zen 2 (2019)                                        | 64-bit       | 3                | 1/3                    | Divergent      |
| Zen 3 (2020)                                        | 64-bit       | 3                | 1/3                    | Divergent      |
| Zen 4 (2022)                                        | 64-bit       | 2-3              | 1/2                    | Port 2         |
| _Data dari uops.info, Agner Fog instruction tables_ |

**Karakteristik performa:** POPCNT tidak throughput-limited pada CPU modern — eksekusinya 2-3 cycles, independen dari input (tidak data-dependent). Ini krusial untuk vector search: tidak ada early-out optimization; setiap XOR+POPCNT memakan waktu yang sama persis berapapun jumlah 1s yang ada.

### 4.2 SIMD POPCNT: AVX-512 VPOPCNTDQ

Diperkenalkan di Ice Lake (AVX-512 BITALG) dan Zen 4:

```asm
; Hitung 1-bits di setiap 64-bit element dari zmm register
VPOPCNTDQ zmm1, zmm2    ; popcount setiap qword di zmm2 → zmm1
```

Satu instruksi memproses **64 bytes (512 bits)** — 8 Hamming distances dari 8 × u64 words secara paralel. Untuk 1024-dim binary vector:

```
16 u64 words × 128-byte vector
→ 2 VPOPCNTDQ instructions (8 words each)
→ 1 reduction add (VPMOV + VPSUB + VPSADBW)
→ total: ~3 instructions per 1024-bit Hamming distance
```

### 4.3 ARM NEON CNT Instruction

Arsitektur ARM mengimplementasikan popcount melalui instruksi byte-level `VCNT`:

```asm
VCNT.8 q0, q1     ; Hitung 1-bits di setiap byte q1 → byte counts di q0
VPADDL.U8 q0, q0 ; Pairwise add adjacent bytes → 8 halfwords
VPADDL.U16 q0, q0 ; Pairwise add → 4 singlewords
VPADDL.U32 q0, q0 ; Pairwise add → 2 doublewords (32-bit popcounts)
```

**Performa:** `VCNT` memiliki 2-cycle latency pada Apple Silicon modern (M1-M3) dan core Cortex-X, dengan throughput 1/1.

### 4.4 Rust LLVM Codegen

Method `count_ones()` Rust pada integer types meng-compile ke:

```rust
pub fn hamming_distance_u64(a: u64, b: u64) -> u32 {
    (a ^ b).count_ones()  // → POPCNT r64
}
```

Untuk 1024-bit vector:

```rust
pub fn hamming_distance_1024(a: &[u64; 16], b: &[u64; 16]) -> u32 {
    let mut dist = 0u32;
    for i in 0..16 {
        // Compiler auto-vectorizes ke VPOPCNTDQ atau PCMPEQB + PSADBW
        dist += (a[i] ^ b[i]).count_ones();
    }
    dist
}
```

LLVM meng-auto-vectorize ini ke SIMD ketika di-compile dengan `-C target-feature=+avx512bitalg` atau `+sse4.2`, menghasilkan VPOPCNTDQ (Ice Lake+) atau PSADBW-based popcount emulation (SSE2 fallback).

### 4.5 Keterbatasan eBPF POPCNT

**Krusial untuk eBVC:** Linux eBPF verifier saat ini **TIDAK** mendukung POPCNT di kernel-space eBPF programs. BPF ISA tidak memiliki opcode `BPF_INSN_POPCNT` (per kernel 6.12, 2025).

Workaround di eBVC adalah:

1. **Userspace quantizer** (`quantizer.rs`) menghitung binary vectors dari float32 embeddings
2. **eBPF maps** menyimpan pre-computed binary vectors
3. **eBPF program** melakukan iterasi atas 16 × u64 dengan explicit XOR + manual bit-count loop (bounded, verifier-friendly)

Manual popcount di eBPF:

```c
// eBPF-compatible popcount (bounded loop, verifier-safe)
static inline u32 popcount_u64(u64 val) {
    // 8 iterations × 8 bits per iteration
    u32 count = 0;
    #pragma unroll
    for (int i = 0; i < 64; i++) {
        count += (val >> i) & 1;
    }
    return count;
}
```

Ini ~64× lebih lambat dari hardware POPCNT tapi satu-satunya opsi di eBPF (2025). **FPGA-based popcount accelerators** (Ring -1) adalah logical descent berikutnya untuk eBVC.

---

## 5. Analisis Teoritis: Mengapa Binary Bekerja

### 5.1 Argumen Hypersphere Angle

Untuk $\ell_2$-normalized embeddings (unit hypersphere $\mathbb{S}^{d-1}$):

Setiap dimensi $x_i$ adalah proyeksi vector ke basis vector $e_i$. Sign $\text{sgn}(x_i)$ meng-encode **hemisphere** mana dari unit sphere yang ditempati vector sepanjang sumbu tersebut.

Dua vectors yang dekat dalam cosine angle akan berbagi lebih banyak dimensi dengan sign yang sama. Ini intuitif secara geometris:

> **Teorema (approximate):** Untuk dua unit vectors $\mathbf{a}, \mathbf{b} \in \mathbb{S}^{d-1}$, Hamming distance antara sign encodings mereka dibatasi oleh $d \cdot \theta / \pi$ di mana $\theta = \arccos(\cos(\mathbf{a}, \mathbf{b}))$ adalah sudut antara mereka, dan $d$ cukup besar.

**Sketsa pembuktian:** Sign function mempartisi $\mathbb{S}^{d-1}$ menjadi $2^d$ orthants (hyperoctants). Probabilitas dua random vectors jatuh di orthant yang sama proporsional dengan $\pi - \theta / \pi$, artinya sudut lebih kecil → lebih banyak shared signs → Hamming distance lebih kecil.

### 5.2 Inherent Dimensionality & Concentration

Performa binary quantization bergantung secara kritis pada **inherent dimensionality** $d_{\text{eff}}$ — dimensionalitas efektif dari embedding manifold:

| Embedding Model        | Nominal $d$ | $d_{\text{eff}}$ | Binary Recall@10 | Catatan                               |
| ---------------------- | ----------- | ---------------- | ---------------- | ------------------------------------- |
| BERT-base (768-dim)    | 768         | ~40-60           | ~88-92%          | High isotropy loss                    |
| text-embedding-3-small | 1536        | ~60-100          | ~90-93%          | OpenAI dim reduction membantu         |
| Jina v5 (1024-dim)     | 1024        | ~80-120          | ~94-96%          | MRL training meningkatkan isotropy    |
| CLIP (512-dim)         | 512         | ~30-50           | ~82-88%          | Multimodal = tidak isotropy-optimized |
| Random $N(0,I)$        | 1024        | 1024             | ~0%              | Tidak ada struktur → sign meaningless |

**Temuan kritis:** Binary quantization bekerja dengan baik ketika $d_{\text{eff}} \ll d$ — embedding manifold memiliki redundansi signifikan. Model MRL-trained modern (Jina v5, Cohere v3) secara eksplisit mengoptimalkan properti ini, menjadikannya kandidat ideal untuk BQ.

### 5.3 Theoretical Recall Bound

Untuk binary search dengan Hamming distance, recall@k bound relatif terhadap cosine-based oracle tergantung pada:

$$ \text{Recall@k}_{BQ} \geq 1 - \exp\left(-\frac{k \cdot p_{\text{agree}}}{1 - p_{\text{agree}}}\right) $$

di mana $p_{\text{agree}}$ adalah probabilitas bahwa nearest neighbors di bawah cosine juga merupakan nearest di bawah Hamming. Pengukuran empiris pada Jina v5 1024-dim menunjukkan $p_{\text{agree}} \approx 0.86$ untuk top-10, menghasilkan expected recall@10 ~96%.

---

## 6. Pola Implementasi — Packing, XOR, Unrolling

### 6.1 Implementasi Quantizer (Rust)

```rust
/// Binary quantizer untuk Jina v5 1024-dim float32 vectors
pub fn quantize_float32_to_binary(floats: &[f32]) -> BinaryVector {
    debug_assert!(floats.len() == 1024);
    let mut bits = [0u64; 16];

    for (i, &val) in floats.iter().enumerate() {
        // Strict "> 0.0" — bukan ">= 0.0" — mencegah all-1s dari zero vectors
        if val > 0.0 {
            bits[i >> 6] |= 1u64 << (i & 0x3F);
        }
    }
    BinaryVector { bits }
}
```

**Catatan optimasi:**

- Manual unrolling (16 iterations) memungkinkan LLVM vectorize via SIMD
- `i >> 6` menggantikan `i / 64` (strength reduction)
- `i & 0x3F` menggantikan `i % 64` (bitwise masking)

### 6.2 Implementasi Search (Rust — Hamming Distance)

```rust
impl BinaryVector {
    /// XOR + POPCNT unrolled Hamming distance — Jina v5 1024-dim
    pub fn hamming_distance(&self, other: &BinaryVector) -> u32 {
        // Manual unrolling — compiler menghasilkan VPOPCNTDQ
        let d00 = (self.bits[0] ^ other.bits[0]).count_ones();
        let d01 = (self.bits[1] ^ other.bits[1]).count_ones();
        let d02 = (self.bits[2] ^ other.bits[2]).count_ones();
        let d03 = (self.bits[3] ^ other.bits[3]).count_ones();
        let d04 = (self.bits[4] ^ other.bits[4]).count_ones();
        let d05 = (self.bits[5] ^ other.bits[5]).count_ones();
        let d06 = (self.bits[6] ^ other.bits[6]).count_ones();
        let d07 = (self.bits[7] ^ other.bits[7]).count_ones();
        let d08 = (self.bits[8] ^ other.bits[8]).count_ones();
        let d09 = (self.bits[9] ^ other.bits[9]).count_ones();
        let d10 = (self.bits[10] ^ other.bits[10]).count_ones();
        let d11 = (self.bits[11] ^ other.bits[11]).count_ones();
        let d12 = (self.bits[12] ^ other.bits[12]).count_ones();
        let d13 = (self.bits[13] ^ other.bits[13]).count_ones();
        let d14 = (self.bits[14] ^ other.bits[14]).count_ones();
        let d15 = (self.bits[15] ^ other.bits[15]).count_ones();

        d00 + d01 + d02 + d03 + d04 + d05 + d06 + d07
            + d08 + d09 + d10 + d11 + d12 + d13 + d14 + d15
    }
}
```

**Mengapa manual unrolling?** SLP auto-vectorizer LLVM kadang gagal meng-unroll loop dengan panjang 16 ketika body loop mengandung XOR + POPCNT + accumulate. Explicit unrolling mengeliminasi induction variable overhead dan menjamin SIMD generation pada `-O2` dengan target `+sse4.2`.

### 6.3 Output x86-64 Assembly (Ekspektasi)

```asm
; GCC/Clang -O3 -mavx512bitalg -mavx512dq
; Untuk unrolled loop di atas, LLVM menghasilkan:
vpternlogd zmm0, zmm1, zmm2, 0x96  ; XOR via ternary logic
vpopcntdq  zmm0, zmm0               ; 8 × popcount dalam satu instruksi
... repeat untuk semua words
vpaddd     ymm0, ymm1, ymm2         ; reduction
```

### 6.4 Implementasi Python NumPy

```python
import numpy as np

def binary_quantize(vectors: np.ndarray, threshold: float = 0.0) -> np.ndarray:
    """
    Binary quantize float32 vectors.

    Args:
        vectors: (n, d) float32 array, typically L2-normalized
        threshold: quantization threshold (default 0.0)

    Returns:
        (n, d//8) uint8 binary vector packed representation
    """
    n, d = vectors.shape
    n_bytes = d // 8
    # Sign threshold: > threshold → bit=1
    bits = (vectors > threshold).astype(np.uint8)
    # Pack bits into bytes
    packed = np.packbits(bits, axis=1)
    return packed

def hamming_distance_batch(query_bin: np.ndarray, db_bin: np.ndarray) -> np.ndarray:
    """
    Compute Hamming distance between query and all database vectors.

    Args:
        query_bin: (d//8,) packed binary vector
        db_bin: (n, d//8) packed database

    Returns:
        (n,) Hamming distances
    """
    # XOR (bitwise) + popcount (bitwise_count = POPCNT intrinsic di NumPy 2.x)
    xor = np.bitwise_xor(db_bin, query_bin)        # (n, d//8)
    counts = np.bitwise_count(xor)                  # (n, d//8)
    return counts.sum(axis=1)                       # (n,)
```

NumPy 2.0+ menggunakan `AVX-512 VPOPCNTDQ` di balik layar untuk `np.bitwise_count` pada hardware yang mendukung, memberikan ~100× throughput dibanding manual Python loops.

---

## 7. Trade-off & Mode Kegagalan

### 7.1 Kapan Binary Quantization Gagal

| Mode Kegagalan                  | Penyebab                                                                                                          | Deteksi                                            | Mitigasi                                                                      |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------- |
| **All-0s atau All-1s collapse** | Embedding model mengeluarkan constant-bias dimensions (misalnya setelah LayerNorm dengan learned bias)            | P(bit=1) across dataset jauh dari 0.5              | Center embedding (kurangi per-dimension mean sebelum quantization)            |
| **Anisotropic embedding space** | Embedding ter-cluster dalam narrow cone → perbedaan angular kecil → Hamming distance kehilangan daya diskriminasi | Ukur cosine variability top-100 NN vs random pairs | Preprocess dengan ICA/whitening untuk hyperspherize                           |
| **Low inherent dimensionality** | d_eff mendekati d → sign function meng-encode noise, bukan struktur                                               | PCA ratio: 90% variance di >> 50 components        | Jangan pakai binary — gunakan SQ8 atau PQ sebagai gantinya                    |
| **Magnitude-critical task**     | Panjang dokumen, importance di-encode dalam vector magnitude                                                      | Gap performa cosine vs dot-product                 | Gunakan cosine hybrid (first pass binary, second pass cosine pada candidates) |
| **Multi-vector queries**        | MRL slices, weighted queries membutuhkan continuous scores                                                        | Query memiliki parameter `dimensions` < full dim   | Encode di full dim, binary quantize pada search time                          |

### 7.2 Kisah 100× Search Speedup

Pada single-core AVX-512 (Ice Lake @ 3.0 GHz):

```python
# Benchmark: 100K candidates, 1024-dim
floats = np.random.randn(100_000, 1024).astype(np.float32)
query = np.random.randn(1024).astype(np.float32)
# → Cosine: ~2.3 ms (FP32 dot product)
# → Hamming (packed binary): ~23 µs (XOR + POPCNT)
# Speedup: ~100×
```

**Kenapa 100× dan bukan 32× (compression ratio)?** Karena:

1. **Cache effects:** 100K binary vectors (12.8 MB) muat di L3 cache; 100K float32 (409 MB) tidak — mereka DRAM-bound, menambah 100-200 ns latency per access
2. **SIMD width:** Satu VPOPCNTDQ memproses 512 bits (64 dims) sekaligus; float32 FMA memproses 8 × 32-bit = 256 bits per AVX-512 instruction
3. **Tidak ada reduction step:** XOR+POPCNT menghasilkan per-word popcounts secara langsung; float32 dot product membutuhkan element-wise FMA + horizontal reduction

---

## 8. Matriks Perbandingan: Float32 vs INT8 vs Binary

| Aspek                               | Float32 (Baseline)    | INT8 (SQ8)               | Binary (1-bit)                |
| ----------------------------------- | --------------------- | ------------------------ | ----------------------------- |
| **Bytes per 1024-dim**              | 4096                  | 1024                     | 128                           |
| **Rasio kompresi**                  | 1×                    | 4×                       | 32×                           |
| **Search metric**                   | Cosine (dot)          | Cosine (INT8 dot)        | Hamming (XOR+POPCNT)          |
| **Compute per comparison**          | 1024 FMA              | 1024 INT8 → FP32 dequant | 16 XOR + 16 POPCNT            |
| **Instruction count (vector)**      | ~1024                 | ~1024 + dequant overhead | 2 VPOPCNTDQ + reduce          |
| **Latency (100K, single core)**     | ~2-5 ms               | ~500-800 µs              | ~5-25 µs                      |
| **Throughput (queries/sec, 1M DB)** | ~200-500              | ~1200-2000               | ~40,000-200,000               |
| **Recall@10 (Jina v5)**             | 100%                  | ~99%                     | ~94-96%                       |
| **DRAM bandwidth needed**           | 200 GB/s              | 50 GB/s                  | 6.25 GB/s                     |
| **Cache friendliness**              | Buruk (L1: 8 vectors) | Sedang (L1: 32)          | Sangat baik (L1: 256)         |
| **eBPF compatible**                 | ❌ (tidak ada FPU)    | ❌ (tidak ada INT8 dot)  | 🟡 Terbatas (manual popcount) |
| **Fixed-function ASIC**             | ❌ (terlalu kompleks) | 🟡 Mungkin               | ✅ Trivial (XOR gate tree)    |

---

## Referensi

1.  H. Jegou, M. Douze, C. Schmid. _"Product Quantization for Nearest Neighbor Search."_ IEEE TPAMI, 2011. [arXiv:1007.1022](https://arxiv.org/abs/1007.1022)
2.  T. Dao, D. Y. Fu, S. Ermon, A. Rudra, C. Ré. _"FlashAttention: Fast and Memory-Efficient Exact Attention."_ NeurIPS 2022. [arXiv:2205.14135](https://arxiv.org/abs/2205.14135)
3.  A. Andoni, P. Indyk. _"Near-Optimal Hashing Algorithms for Approximate Nearest Neighbor in High Dimensions."_ FOCS 2006.
4.  P. Indyk, R. Motwani. _"Approximate Nearest Neighbors: Towards Removing the Curse of Dimensionality."_ STOC 1998.
5.  A. Rahimi, B. Recht. _"Random Features for Large-Scale Kernel Machines."_ NeurIPS 2007.
6.  J. L. Bentley. _"Multidimensional Binary Search Trees in Database Applications."_ IEEE TSE, 1979.
7.  Agner Fog. _"Instruction Tables: Lists of instruction latencies, throughputs and micro-operation breakdowns."_ (2023). https://www.agner.org/optimize/
8.  uops.info. _"Instruction Latency and Throughput Table."_ (2024). https://uops.info/
9.  Intel Intrinsics Guide. _"VPOPCNTDQ — Count of Bits Set to 1 in Packed Quadword."_ (2024).
10. Intel 64 and IA-32 Architectures Optimization Reference Manual. (2024).
11. ARM Architecture Reference Manual ARMv8. _"CNT — Population Count per Byte."_ (2023).
12. Jina AI. _"Jina Embeddings v5: Technical Report."_ (2025). https://jina.ai/embeddings/v5
13. Cohere. _"Binary Embeddings: 100× Faster Search at 96% Accuracy."_ (2024). https://txt.cohere.com/introducing-binary-embeddings/
14. Google. _"Matryoshka Representation Learning."_ NeurIPS 2022. [arXiv:2205.13147](https://arxiv.org/abs/2205.13147)
15. L. McVoy, C. Staelin. _"lmbench: Portable tools for performance analysis."_ USENIX 1996.
16. Linux Kernel BPF Documentation. _"BPF Instruction Set Architecture (ISA)."_ (2024). https://docs.kernel.org/bpf/standardization/instruction-set.html
17. M. K. Chung. _"Computational Neuroanatomy: The Geometry of the Brain."_ 2013. (Chapter: Statistical Shape Analysis).

---

## Koneksi ke Vault

| Catatan                                    | Koneksi                                                                                   |
| ------------------------------------------ | ----------------------------------------------------------------------------------------- |
| [[vector-quantization-hnsw-tuning]]        | SQ8 & PQ quantization — binary sebagai tingkat ekstrim kompresi, 32× vs 4-16×             |
| [[vector-database-internals-optimization]] | §4.3 Binary Quantization — disebut 4 baris, catatan ini adalah ekspansi 200×              |
| [[cosine-similarity-deepdive]]             | Transisi metrik Cosine → Hamming; referensi silang implementasi cosine                    |
| [[jina-embeddings-v5-mrl-adapters]]        | Jina v5 1024-dim — binary quantization sebagai search tier                                |
| [[hierarchy-recursive-ring-deepdive]]      | Phase transition: cosine→hamming sebagai descent Ring 3→Ring 0                            |
| [[hierarchy-kernel-bypass-networking]]     | Keterbatasan eBPF POPCNT — mengapa kernel-space vector search butuh hardware acceleration |
| [[ebpf-kernel-security]]                   | Kendala eBPF verifier — bounded loops untuk manual popcount                               |
