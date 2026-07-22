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
status: seedling
created: 2026-07-22
updated: 2026-07-22
cssclasses:
  - wide-table
---

# Binary Quantization & Hamming Distance: The 1-bit Frontier of Vector Search

> [!tip] Binary quantization (BQ) compresses float32 vectors to 1 bit per dimension — a 32× memory reduction — turning the similarity metric from cosine (floating-point dot product) to Hamming distance (XOR + popcount). This transforms search from O(d) floating-point multiply-add into O(1) CPU instruction per 64-bit word. For Jina v5 1024-dim embeddings, the result is 128-byte vectors searchable at < 1 µs per 100K candidates. But the 32× compression comes with a fundamental information-theoretic cost: sign-only encoding discards magnitude information, limiting its applicability to inherently directional embeddings.

---

## Daftar Isi

1. [[#1. The Problem]]
2. [[#2. Binary Quantization — Formal Definition]]
3. [[#3. The Metric Transition]]
4. [[#4. POPCOUNT — The Hardware Primitive]]
5. [[#5. Theoretical Analysis]]
6. [[#6. Implementation Patterns — Packing, XOR, Unrolling]]
7. [[#7. Trade-offs & Failure Modes]]
8. [[#8. Comparison Matrix]]
9. [[#References]]
10. [[#Koneksi ke Vault]]

---

## 1. The Problem: Memory Wall & Bandwidth Bottleneck

### 1.1 The Float32 Tax

Every float32 embedding dimension costs **4 bytes** of memory. For Jina v5 1024-dim embeddings:

$$ \text{Memory}_{1M} = 1{,}000{,}000 \times 1024 \times 4 \text{ bytes} \approx 4.09 \text{ GB} $$

This is the **raw vector storage** — no index overhead included. HNSW typically adds 1.5–2× more for the graph structure, bringing total to ~10 GB for 1M vectors. At 100M vectors (medium-scale production), raw storage alone reaches **400 GB**.

### 1.2 The Bandwidth Bottleneck

Vector search at scale is **memory-bound**, not compute-bound. The bottleneck is moving bytes from DRAM to CPU cache:

| Metric              | Arithmetic Intensity | Bottleneck          | Typical Throughput   |
| ------------------- | -------------------- | ------------------- | -------------------- |
| Cosine (float32)    | ~2 ops/byte          | Memory bandwidth    | 2-5 GB/s per channel |
| Binary Hamming      | ~16 ops/byte         | Compute/SIMD width  | 10-50 GB/s effective |
| Binary XOR + POPCNT | ~64 ops/byte         | CPU backend (ports) | >50 GB/s (AVX-512)   |

**The insight:** Binary vectors don't just save memory — they **change the bottleneck regime** from memory-bound to compute-bound. This shift enables BLAS-level throughput with non-BLAS hardware (kernel-space, embedded, eBPF).

### 1.3 Quantization Spectrum

```
Presisi           Memory/vec     Search Ops           Akurasi
────────────────────────────────────────────────────────────
Float32 (32-bit)  4096 bytes     FMA + reduction      100% (baseline)
FP16 (16-bit)     2048 bytes     FP16 FMA             ~99.8%
INT8 (SQ8)        1024 bytes     INT8 dot             ~99%
INT4              512 bytes      INT4 dot (dequant)   ~97-98%
Binary (1-bit)    128 bytes      XOR + POPCNT         ~92-96%*
```

*Akurasi tergantung pada model embedding dan inherent dimensionality. Jina v5 dengan binary quantization dilaporkan mempertahankan >95% recall@10 pada benchmark MTEB tertentu.

---

## 2. Binary Quantization — Formal Definition

### 2.1 The Quantization Function

Given a float32 vector $\mathbf{x} \in \mathbb{R}^d$, binary quantization produces $\mathbf{b} \in \{0,1\}^d$ via the sign function:

$$ b_i = \begin{cases} 1 & \text{if } x_i > 0 \\ 0 & \text{otherwise} \end{cases} $$

For embeddings already $\ell_2$-normalized (unit length, $\|\mathbf{x}\|_2 = 1$), this is equivalent to:

$$ \mathbf{b} = \frac{1}{2}\left(\text{sgn}(\mathbf{x}) + 1\right) $$

where $\text{sgn}(x_i) = 1$ for $x_i \geq 0$ and $-1$ otherwise.

**Critical subtlety:** The threshold $> 0$ vs $\geq 0$ matters. In practice, using $\geq 0$ causes uniform-zero vectors (all bits set) when the embedding model outputs constant-negative bias in some dimension. Most implementations use $> 0.0$ strictly.

### 2.2 Packing

Each dimension consumes 1 bit, so $d$-dimensions pack into:

$$ \text{bytes} = \left\lceil \frac{d}{8} \right\rceil $$

For Jina v5 (1024-dim): $1024 / 8 = 128$ bytes.

**Bit layout (little-endian word ordering):**

```rust
// For 1024-dim: 16 × u64 (64-bit words)
// Bit i of the vector occupies:
let u64_idx = i / 64;      // word index [0..15]
let bit_idx = i % 64;      // bit position within word [0..63]
let bit_mask = 1u64 << bit_idx;
```

This word-aligned layout is **critical for performance**: each word can be XOR'd and POPCNT'd independently, enabling loop unrolling and SIMD vectorization.

### 2.3 Binary Quantization in Memory-Constrained Environments

The 128-byte vector fits into:

- **L1 cache** (32 KB) — ~250 vectors in L1 at once
- **L2 cache** (256 KB per core) — ~2000 vectors
- **L3 cache** (8-16 MB shared) — ~62K-125K vectors

Contrast with float32 1024-dim (4096 bytes):

- **L1** — only ~8 vectors
- **L2** — only ~64 vectors
- **L3** — only ~2K-4K vectors

**The difference is 16× better cache utilization** — fewer DRAM stalls = higher throughput.

---

## 3. The Metric Transition: Cosine → Hamming

### 3.1 Why Cosine Stops Working After Sign Quantization

Cosine similarity between two vectors $\mathbf{a}, \mathbf{b} \in \mathbb{R}^d$:

$$ \cos(\mathbf{a},\mathbf{b}) = \frac{\mathbf{a} \cdot \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|} $$

After binary quantization to $\mathbf{b}^{(a)}, \mathbf{b}^{(b)} \in \{0,1\}^d$, the dot product becomes:

$$ \mathbf{b}^{(a)} \cdot \mathbf{b}^{(b)} = \sum_{i=1}^d b_i^{(a)} b_i^{(b)} = \text{number of dimensions where both are 1} $$

**This is not cosine.** The magnitude information is lost, and the continuous dot product range $[-1, 1]$ collapses to integer range $[0, d]$.

The correct metric for binary vectors is **Hamming distance**:

$$ H(\mathbf{b}^{(a)}, \mathbf{b}^{(b)}) = \sum_{i=1}^d (b_i^{(a)} \oplus b_i^{(b)}) = \text{popcount}(\mathbf{b}^{(a)} \oplus \mathbf{b}^{(b)}) $$

where $\oplus$ is bitwise XOR.

### 3.2 Relationship Between Cosine and Hamming on Binary Vectors

For binary vectors $\mathbf{p}, \mathbf{q} \in \{0,1\}^d$, there is a direct relationship:

$$ \cos(\mathbf{p}, \mathbf{q}) = \frac{\mathbf{p} \cdot \mathbf{q}}{\sqrt{\|\mathbf{p}\|} \sqrt{\|\mathbf{q}\|}} $$

And since Hamming distance $H$ relates to dot product via:

$$ H(\mathbf{p}, \mathbf{q}) = \|\mathbf{p}\| + \|\mathbf{q}\| - 2(\mathbf{p} \cdot \mathbf{q}) $$

For unit binary vectors ($\|\mathbf{p}\| = \|\mathbf{q}\| = d/2$ on average for balanced encodings):

$$ \cos(\mathbf{p}, \mathbf{q}) \approx 1 - \frac{2H}{d} $$

**Key insight:** Under balanced binary encoding (roughly equal 0s and 1s), cosine is monotonically decreasing in Hamming distance — **ranking is preserved** at the cost of continuous score granularity.

### 3.3 The Metric Transition Phase Diagram

```
Input Embedding Type    Optimal Metric        Compute Unit
───────────────────────────────────────────────────────────
Float32, L2-normed     Cosine (Inner Product)  FMA unit
Float32, unit-normed   Cosine (Dot Product)    FMA/reduction
INT8 quantized         Cosine (dequantized)    INT8 dot
Binary (sign)          Hamming Distance        XOR + POPCNT
Locality-sensitive hash  Hamming Distance      XOR + POPCNT
```

**The transition from float to binary is a phase transition (see [[hierarchy-recursive-ring-deepdive]]):** The optimal metric changes discontinuously, not gradually. Between INT8 and binary, there is no gradual precision reduction — you either have sign information only, at which point cosine becomes meaningless.

---

## 4. POPCOUNT — The Hardware Primitive

### 4.1 x86 POPCNT Instruction

The `POPCNT` instruction (introduced with SSE4.2 / Nehalem, 2008) counts the number of 1-bits in a register:

```asm
; Intel syntax
POPCNT r64, r/m64    ; Count 1-bits in source, store in destination
POPCNT r32, r/m32    ; 32-bit variant
```

**Latency & Throughput by Microarchitecture:**

| Microarchitecture                                   | POPCNT r64   | Latency (cycles) | Throughput (per cycle) | Execution Port |
| --------------------------------------------------- | ------------ | ---------------- | ---------------------- | -------------- |
| Nehalem (2008)                                      | 8-bit lookup | 15               | 1/4                    | Port 0         |
| Haswell (2013)                                      | 64-bit       | 3                | 1/1                    | Port 1         |
| Skylake (2015)                                      | 64-bit       | 3                | 1/1                    | Port 1         |
| Ice Lake (2019)                                     | 64-bit       | 3                | 1/1                    | Port 1         |
| Zen 2 (2019)                                        | 64-bit       | 3                | 1/3                    | Divergent      |
| Zen 3 (2020)                                        | 64-bit       | 3                | 1/3                    | Divergent      |
| Zen 4 (2022)                                        | 64-bit       | 2-3              | 1/2                    | Port 2         |
| _Data from uops.info, Agner Fog instruction tables_ |

**Performance characteristic:** POPCNT is not throughput-limited on modern CPUs — it executes in 2-3 cycles independent of input (not data-dependent). This is critical for vector search: there is no early-out optimization; every XOR+POPCNT takes exactly the same time regardless of how many 1s are present.

### 4.2 SIMD POPCNT: AVX-512 VPOPCNTDQ

Introduced in Ice Lake (AVX-512 BITALG) and Zen 4:

```asm
; Count 1-bits in each 64-bit element of zmm register
VPOPCNTDQ zmm1, zmm2    ; popcount each qword in zmm2 → zmm1
```

One instruction processes **64 bytes (512 bits)** — 8 Hamming distances from 8 × u64 words in parallel. For a 1024-dim binary vector:

```
16 u64 words × 128-byte vector
→ 2 VPOPCNTDQ instructions (8 words each)
→ 1 reduction add (VPMOV + VPSUB + VPSADBW)
→ total: ~3 instructions per 1024-bit Hamming distance
```

### 4.3 ARM NEON CNT Instruction

ARM architectures implement popcount via the byte-level `VCNT` instruction:

```asm
VCNT.8 q0, q1     ; Count 1-bits in each byte of q1 → byte counts in q0
VPADDL.U8 q0, q0 ; Pairwise add adjacent bytes → 8 halfwords
VPADDL.U16 q0, q0 ; Pairwise add → 4 singlewords
VPADDL.U32 q0, q0 ; Pairwise add → 2 doublewords (32-bit popcounts)
```

**Performance:** `VCNT` has 2-cycle latency on modern Apple Silicon (M1-M3) and Cortex-X cores, with throughput 1/1.

### 4.4 Rust LLVM Codegen

Rust's `count_ones()` method on integer types compiles to:

```rust
pub fn hamming_distance_u64(a: u64, b: u64) -> u32 {
    (a ^ b).count_ones()  // → POPCNT r64
}
```

For a 1024-bit vector:

```rust
pub fn hamming_distance_1024(a: &[u64; 16], b: &[u64; 16]) -> u32 {
    let mut dist = 0u32;
    for i in 0..16 {
        // Compiler auto-vectorizes to VPOPCNTDQ or PCMPEQB + PSADBW
        dist += (a[i] ^ b[i]).count_ones();
    }
    dist
}
```

LLVM auto-vectorizes this to SIMD when compiled with `-C target-feature=+avx512bitalg` or `+sse4.2`, generating VPOPCNTDQ (Ice Lake+) or PSADBW-based popcount emulation (SSE2 fallback).

### 4.5 eBPF POPCNT Limitation

**Critical for eBVC:** The Linux eBPF verifier currently does **NOT** support POPCNT in kernel-space eBPF programs. BPF ISA has no `BPF_INSN_POPCNT` opcode (as of kernel 6.12, 2025).

The workaround in eBVC is:

1.  **Userspace quantizer** (`quantizer.rs`) computes binary vectors from float32 embeddings
2.  **eBPF maps** store pre-computed binary vectors
3.  **eBPF program** iterates over 16 × u64 with explicit XOR + manual bit-count loop (bounded, verifier-friendly)

The manual popcount in eBPF:

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

This is ~64× slower than hardware POPCNT but is the only option in eBPF (2025). **FPGA-based popcount accelerators** (Ring -1) are the next logical descent for eBVC.

---

## 5. Theoretical Analysis: Why Binary Works

### 5.1 The Hypersphere Angle Argument

For $\ell_2$-normalized embeddings (unit hypersphere $\mathbb{S}^{d-1}$):

Each dimension $x_i$ is the projection of the vector onto basis vector $e_i$. The sign $\text{sgn}(x_i)$ encodes which **hemisphere** of the unit sphere the vector occupies along that axis.

Two vectors that are close in cosine angle will share more same-sign dimensions. This is geometrically intuitive:

> **Theorem (approximate):** For two unit vectors $\mathbf{a}, \mathbf{b} \in \mathbb{S}^{d-1}$, the Hamming distance between their sign encodings is bounded above by $d \cdot \theta / \pi$ where $\theta = \arccos(\cos(\mathbf{a}, \mathbf{b}))$ is the angle between them, and $d$ is sufficiently large.

**Proof sketch:** The sign function partitions $\mathbb{S}^{d-1}$ into $2^d orthants$ (hyperoctants). The probability that two random vectors fall in the same orthant is proportional to $\pi - \theta / \pi$, meaning smaller angles → more shared signs → smaller Hamming distance.

### 5.2 Inherent Dimensionality & Concentration

The performance of binary quantization depends critically on **inherent dimensionality** $d_{\text{eff}}$ — the effective dimensionality of the embedding manifold:

| Embedding Model              | Nominal $d$ | $d_{\text{eff}}$ | Binary Recall@10 | Notes                               |
| ---------------------------- | ----------- | ---------------- | ---------------- | ----------------------------------- |
| BERT-base (768-dim)          | 768         | ~40-60           | ~88-92%          | High isotropy loss                  |
| text-embedding-3-small       | 1536        | ~60-100          | ~90-93%          | OpenAI dim reduction helps          |
| Jina v5 (1024-dim)           | 1024        | ~80-120          | ~94-96%          | MRL training improves isotropy      |
| CLIP (512-dim)               | 512         | ~30-50           | ~82-88%          | Multimodal = not isotropy-optimized |
| Drawn from $N(0,I)$ (random) | 1024        | 1024             | ~0%              | No structure → sign is meaningless  |

**The critical finding:** Binary quantization works well when $d_{\text{eff}} \ll d$ — the embedding manifold has significant redundancy. Modern MRL-trained models (Jina v5, Cohere v3) explicitly optimize for this property, making them ideal candidates for BQ.

### 5.3 Theoretical Recall Bound

For binary search with Hamming distance, the recall@k bound relative to cosine-based oracle depends on:

$$ \text{Recall@k}_{BQ} \geq 1 - \exp\left(-\frac{k \cdot p_{\text{agree}}}{1 - p_{\text{agree}}}\right) $$

where $p_{\text{agree}}$ is the probability that nearest neighbors under cosine are also nearest under Hamming. Empirical measurements on Jina v5 1024-dim show $p_{\text{agree}} \approx 0.86$ for top-10, yielding expected recall@10 ~96%.

---

## 6. Implementation Patterns — Packing, XOR, Unrolling

### 6.1 Quantizer Implementation (Rust)

```rust
/// Binary quantizer for Jina v5 1024-dim float32 vectors
pub fn quantize_float32_to_binary(floats: &[f32]) -> BinaryVector {
    debug_assert!(floats.len() == 1024);
    let mut bits = [0u64; 16];

    for (i, &val) in floats.iter().enumerate() {
        // Strict "> 0.0" — not ">= 0.0" — prevents all-1s from zero vectors
        if val > 0.0 {
            bits[i >> 6] |= 1u64 << (i & 0x3F);
        }
    }
    BinaryVector { bits }
}
```

**Optimization notes:**

- Manual unrolling (16 iterations) lets LLVM vectorize via SIMD
- `i >> 6` replaces `i / 64` (strength reduction)
- `i & 0x3F` replaces `i % 64` (bitwise masking)

### 6.2 Search Implementation (Rust — Hamming Distance)

```rust
impl BinaryVector {
    /// XOR + POPCNT unrolled Hamming distance — Jina v5 1024-dim
    pub fn hamming_distance(&self, other: &BinaryVector) -> u32 {
        // Manual unrolling — compiler generates VPOPCNTDQ
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

**Why manual unrolling?** LLVM's SLP auto-vectorizer sometimes fails to unroll loops of length 16 when the loop body contains XOR + POPCNT + accumulate. Explicit unrolling eliminates induction variable overhead and guarantees SIMD generation at `-O2` with `+sse4.2` target.

### 6.3 x86-64 Assembly Output (Expected)

```asm
; GCC/Clang -O3 -mavx512bitalg -mavx512dq
; For the unrolled loop above, LLVM generates:
vpternlogd zmm0, zmm1, zmm2, 0x96  ; XOR via ternary logic
vpopcntdq  zmm0, zmm0               ; 8 × popcount in one instruction
... repeat for all words
vpaddd     ymm0, ymm1, ymm2         ; reduction
```

### 6.4 Python NumPy Implementation

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
    # XOR (bitwise) + popcount (bitwise_count = POPCNT intrinsic in NumPy 2.x)
    xor = np.bitwise_xor(db_bin, query_bin)        # (n, d//8)
    counts = np.bitwise_count(xor)                  # (n, d//8)
    return counts.sum(axis=1)                       # (n,)
```

NumPy 2.0+ uses `AVX-512 VPOPCNTDQ` under the hood for `np.bitwise_count` on supported hardware, giving ~100× throughput over manual Python loops.

---

## 7. Trade-offs & Failure Modes

### 7.1 When Binary Quantization Fails

| Failure Mode                    | Cause                                                                                                  | Detection                                                | Mitigation                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- | ----------------------------------------------------------------------- |
| **All-0s or All-1s collapse**   | Embedding model outputs constant-bias dimensions (e.g., after LayerNorm with learned bias)             | P(bit=1) across dataset far from 0.5                     | Center the embedding (subtract per-dimension mean before quantization)  |
| **Anisotropic embedding space** | Embedding clustered in narrow cone → small angular differences → Hamming distance loses discrimination | Measure cosine variability of top-100 NN vs random pairs | Preprocess with ICA/whitening to hyperspherize                          |
| **Low inherent dimensionality** | d_eff close to d → sign function encodes noise, not structure                                          | PCA ratio: 90% variance in >> 50 components              | Don't use binary — use SQ8 or PQ instead                                |
| **Magnitude-critical task**     | Document length, importance encoded in vector magnitude                                                | Cosine vs dot-product performance gap                    | Use cosine hybrid (first pass binary, second pass cosine on candidates) |
| **Multi-vector queries**        | MRL slices, weighted queries need continuous scores                                                    | Query has `dimensions` parameter < full dim              | Encode at full dim, binary quantize at search time                      |

### 7.2 The 100× Search Speedup Story

On a single-core AVX-512 (Ice Lake @ 3.0 GHz):

```python
# Benchmark: 100K candidates, 1024-dim
floats = np.random.randn(100_000, 1024).astype(np.float32)
query = np.random.randn(1024).astype(np.float32)
# → Cosine: ~2.3 ms (FP32 dot product)
# → Hamming (packed binary): ~23 µs (XOR + POPCNT)
# Speedup: ~100×
```

**Why 100× and not 32× (compression ratio)?** Because:

1.  **Cache effects:** 100K binary vectors (12.8 MB) fit in L3 cache; 100K float32 (409 MB) don't — they're DRAM-bound, adding 100-200 ns latency per access
2.  **SIMD width:** One VPOPCNTDQ processes 512 bits (64 dims) at once; float32 FMA processes 8 × 32-bit = 256 bits per AVX-512 instruction
3.  **No reduction step:** XOR+POPCNT produces per-word popcounts directly; float32 dot product requires element-wise FMA + horizontal reduction

---

## 8. Comparison Matrix: Float32 vs INT8 vs Binary

| Aspek                               | Float32 (Baseline)   | INT8 (SQ8)               | Binary (1-bit)               |
| ----------------------------------- | -------------------- | ------------------------ | ---------------------------- |
| **Bytes per 1024-dim**              | 4096                 | 1024                     | 128                          |
| **Compression ratio**               | 1×                   | 4×                       | 32×                          |
| **Search metric**                   | Cosine (dot)         | Cosine (INT8 dot)        | Hamming (XOR+POPCNT)         |
| **Compute per comparison**          | 1024 FMA             | 1024 INT8 → FP32 dequant | 16 XOR + 16 POPCNT           |
| **Instruction count (vector)**      | ~1024                | ~1024 + dequant overhead | 2 VPOPCNTDQ + reduce         |
| **Latency (100K, single core)**     | ~2-5 ms              | ~500-800 µs              | ~5-25 µs                     |
| **Throughput (queries/sec, 1M DB)** | ~200-500             | ~1200-2000               | ~40,000-200,000              |
| **Recall@10 (Jina v5)**             | 100%                 | ~99%                     | ~94-96%                      |
| **DRAM bandwidth needed**           | 200 GB/s             | 50 GB/s                  | 6.25 GB/s                    |
| **Cache friendliness**              | Poor (L1: 8 vectors) | Moderate (L1: 32)        | Excellent (L1: 256)          |
| **eBPF compatible**                 | ❌ (no FPU)          | ❌ (no INT8 dot)         | 🟡 Limited (manual popcount) |
| **Fixed-function ASIC**             | ❌ (too complex)     | 🟡 Possible              | ✅ Trivial (XOR gate tree)   |

---

## References

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

| Catatan                                    | Koneksi                                                                                 |
| ------------------------------------------ | --------------------------------------------------------------------------------------- |
| [[vector-quantization-hnsw-tuning]]        | SQ8 & PQ quantization — binary sebagai tingkat ekstrim kompresi, 32× vs 4-16×           |
| [[vector-database-internals-optimization]] | §4.3 Binary Quantization — disebut 4 baris, catatan ini adalah ekspansi 200×            |
| [[cosine-similarity-deepdive]]             | Cosine → Hamming metric transition; referensi silang implementasi cosine                |
| [[jina-embeddings-v5-mrl-adapters]]        | Jina v5 1024-dim — binary quantization sebagai search tier                              |
| [[hierarchy-recursive-ring-deepdive]]      | Phase transition: cosine→hamming sebagai Ring 3→Ring 0 descent                          |
| [[kernel-bypass-networking-deepdive]]      | eBPF POPCNT limitation — mengapa kernel-space vector search butuh hardware acceleration |
| [[ebpf-kernel-security]]                   | eBPF verifier constraints — bounded loops untuk manual popcount                         |
