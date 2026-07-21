---
tags:
  - product-requirement-document
  - ebpf
  - machine-learning
  - vector-search
  - system-design
aliases:
  - PRD eBVC
  - eBVC Product Requirement Document
  - eBVC PRD
status: evergreen
created: 2026-07-21
updated: 2026-07-21
---

# Product Requirement Document (PRD): eBVC (eBPF Vector Cache)

> [!important] **eBVC (eBPF Vector Cache)** adalah sistem pencarian semantik (Vector Search) tingkat rendah yang berjalan di _kernel-space_ menggunakan program eBPF XDP/TC. PRD ini mendokumentasikan spesifikasi teknis, rancangan arsitektur, dan penyelesaian masalah kompleksitas pencarian $O(N)$ di bawah batasan ketat Linux Kernel Verifier.

---

## 1. Latar Belakang & Pernyataan Masalah

Infrastruktur RAG kontemporer menderita akibat latensi I/O sistem operasi yang tinggi ($2\text{ ms} - 15\text{ ms}$). Pemindahan pencarian vektor ke kernel-space menggunakan eBPF menjanjikan latensi sub-mikrodetik ($< 50\text{ \mu s}$). Namun, implementasi langsung terbentur oleh batasan arsitektur kernel Linux.

### Batasan Utama eBPF Verifier:

1.  **No Dynamic Memory Allocation**: Tidak boleh menggunakan alokasi memori dinamis di dalam kernel. Semua buffer harus berukuran tetap (_statically sized_).
2.  **Instruction Limit & Loop Bounds**: Kernel melarang loop tak terbatas (_infinite loops_). Setiap loop wajib memiliki batas iterasi statis yang kecil (biasanya $\le 256$ iterasi) agar lolos analisis verifikator.
3.  **Stack Size Limit**: Batas memori stack eBPF hanya **512 byte**. Menyimpan array vektor dimensi tinggi di stack akan memicu kegagalan kompilasi.
4.  **The $O(N)$ Bottleneck**: Melakukan pencarian linier (_brute-force scan_) pada $N$ vektor cache di kernel space berkapasitas besar akan melampaui batas instruksi verifikator ($1,000,000$ instruksi) dan menyebabkan degradasi performa jaringan (_packet drops_).

---

## 2. Analisis Masalah & Self-Correction (Penyelesaian Bottleneck $O(N)$)

### ❌ Pendekatan Naif (Gagal Verifikasi): Flat HashMap Scan

Model non-frontier biasanya menyarankan untuk menyimpan seluruh vektor ke dalam satu BPF HashMap, lalu melakukan iterasi satu per satu:

- _Masalah_: Jika ada $10.000$ vektor, loop harus berjalan $10.000$ kali. Verifikator kernel akan langsung menolak program karena loop dinamis tidak terbukti berhenti dalam batas instruksi aman.

### 🔍 Self-Correction: Desain Pembagian Ruang Vektor (eBPF-native Inverted File Index / IVF)

Untuk mencapai kompleksitas pencarian mendekati logaritmik $O(\log N)$ atau sub-linear tanpa melanggar batasan loop, kita harus mensintesiskan struktur **Inverted File Index (IVF)** ke dalam tipe BPF Maps yang didukung secara native.

```
       [ Input Query Vector (512-bit) ]
                       │
                       ▼
            ┌──────────────────────┐
            │   CENTROIDS_MAP      │ ──> Hitung Hamming terhadap C Centroids (C = 16)
            └──────────┬───────────┘     (O(C) search space - Sangat Kecil)
                       │
                       ▼ (Dapatkan Centroid ID Terdekat, misal: Bucket #3)
            ┌──────────────────────┐
            │   IVF_BUCKETS_MAP    │ ──> Ambil Bucket #3 (Array Vektor Kandidat)
            └──────────┬───────────┘
                       │
                       ▼
             [ Loop hanya pada B Vektor di Bucket #3 ] (B = 64)
             (Total operasi: C + B = 16 + 64 = 80 iterasi statis)
```

#### Spesifikasi Algoritma IVF di Kernel-Space:

1.  **User-Space Clustering**: Daemon userspace (Rust) melakukan kueri clustering K-Means pada seluruh dataset vektor untuk menghasilkan $C$ kelompok centroid (misalnya $C = 16$).
2.  **Centroids Map**: Koordinat $C$ centroid disimpan di BPF Map khusus.
3.  **Bucketed Array Maps**: Kita membuat BPF Array of Arrays (atau HashMap dengan kunci gabungan `[Centroid ID][Index]`). Setiap centroid mengarah ke satu bucket berisi maksimal $B$ vektor kandidat (misalnya $B = 64$).
4.  **Verification Check**: Dengan membatasi $C=16$ dan $B=64$, total instruksi loop di kernel bersifat konstan ($16 + 64 = 80$ kali perbandingan). Ini dijamin lolos verifikasi eBPF 100% dan memangkas waktu pencarian secara dramatis.

---

## 3. Spesifikasi Teknis & Skema BPF Maps

### A. Tipe Data Common (`ebvc-common/src/lib.rs`)

```rust
// Struktur vektor biner 512-bit (direpresentasikan sebagai array 8x u64)
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
#[repr(C)]
pub struct BinaryVector {
    pub bits: [u64; 8],
}

// Data centroid
#[derive(Copy, Clone, Debug)]
#[repr(C)]
pub struct CentroidEntry {
    pub id: u32,
    pub vector: BinaryVector,
}
```

### B. Konfigurasi Maps di Kernel Space

#### 1. `CENTROIDS_MAP`

Menyimpan vektor centroid hasil klasterisasi K-Means.

```rust
#[map(name = "CENTROIDS")]
static mut CENTROIDS: Array<CentroidEntry> = Array::with_max_entries(16, 0);
// C = 16 Centroids
```

#### 2. `IVF_BUCKETS`

Menyimpan kumpulan vektor dokumen yang dipetakan berdasarkan ID Centroid terdekat.

```rust
#[map(name = "IVF_BUCKETS")]
static mut IVF_BUCKETS: HashMap<u64, BinaryVector> = HashMap::with_max_entries(1024, 0);
// Kunci u64: menggabungkan Centroid_ID (32-bit tinggi) dan Bucket_Offset_Index (32-bit rendah)
// Value: BinaryVector kandidat
```

#### 3. `DOC_ID_MAP`

Menghubungkan vektor biner pemenang ke ID dokumen riil untuk dikirim sebagai respons.

```rust
#[map(name = "DOC_ID_MAP")]
static mut DOC_ID_MAP: HashMap<BinaryVector, u32> = HashMap::with_max_entries(1024, 0);
```

---

## 4. Analisis Dampak & Kompleksitas Perhitungan Memori

### Penggunaan Memori RAM di Kernel Space (Footprint)

- **Vektor Centroid**: $16 \times (64 \text{ byte} + 4 \text{ byte ID}) = 1.088 \text{ byte}$ ($\approx 1\text{ KB}$).
- **IVF Buckets**: $1024 \times (8 \text{ byte Key} + 64 \text{ byte Vector}) = 73.728 \text{ byte}$ ($\approx 73.7\text{ KB}$).
- **Doc ID Map**: $1024 \times (64 \text{ byte Vector} + 4 \text{ byte ID}) = 69.632 \text{ byte}$ ($\approx 69.6\text{ KB}$).
- **Total RAM Kernel**: $\approx 145.3\text{ KB}$ untuk kapasitas 1024 dokumen hot-cache. Sangat efisien dan aman bagi alokasi memori non-paged kernel.

---

## 5. Fitur Utama & Kriteria Keberhasilan (Go-Live Criteria)

1.  **Bypass TCP Stack**: Kueri RAG UDP ditangkap di level XDP, dievaluasi, dan langsung dibalas dari driver tanpa menyentuh TCP/IP stack OS.
2.  **Verifier Compliance**: Biner eBPF wajib terkompilasi bersih tanpa peringatan "_unbounded loop_" atau "_stack depth limit exceeded_".
3.  **Throughput & Latency Target**:
    - Latensi RTT kueri semantik: **$< 50 \text{ mikrodetik}$ (0.05 ms)**.
    - Throughput minimal: **$> 500.000$ request per detik** pada 1 core CPU.

---

## 🔗 Referensi & Catatan Terkait

- [[jarswaf-internal-architecture-deepdive]] — Integrasi eBPF XDP pada JarsWAF
- [[vector-quantization-hnsw-tuning]] — Teori Kuantisasi Vektor Biner
- [[linux-performance-debugging-toolkit]] — Profiling Latensi Jaringan menggunakan bpftrace
