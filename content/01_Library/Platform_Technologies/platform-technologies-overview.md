---
title: Platform Technologies Overview
tags:
- library
- platform-technologies
created: '2026-05-29'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout

---

# ⚡ PLATFORM TECHNOLOGIES — Yang Sama "OP"-nya dengan eBPF

> Ini bukan daftar tools — ini **platform-level shifts** yang mengubah cara computing bekerja secara fundamental. Seperti eBPF mengubah kernel programmability, teknologi-teknologi ini mengubah I/O, runtime, memory, hardware, dan arsitektur secara menyeluruh.

> [!info] Cara Baca
> Setiap teknologi punya: posisi di stack, masalah yang diselesaikan, siapa yang sudah adopt, dan koneksi ke vault existing. Ini adalah **peta orientasi** — setiap baris bisa jadi satu file tersendiri.

---

## Master Overview Table

| Teknologi                  | Layer                 | Masalah Lama                                                        | Solusi Baru                                                               | Adopted By                                       | Status 2026                           | Koneksi Vault                                                  |            |
| -------------------------- | --------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------- | -------------------------------------------------------------- | ---------- |
| **io_uring**               | OS / Syscall          | epoll + aio tidak skalabel, overhead syscall per-operation          | Async I/O ring buffer — satu syscall untuk ribuan operasi                 | PostgreSQL, RocksDB, NGINX, Android              | ✅ Production, kernel 5.1+             | [[computer-science-foundations\|computer-science-foundations]] |            |
| **WebAssembly (WASM)**     | Runtime               | Docker terlalu berat untuk edge/serverless, binary tidak portable   | Universal bytecode — satu binary jalan di browser/server/edge/embedded    | Cloudflare, Fastly, Docker, Shopify              | ✅ Production, WASI maturing           | [[cloud-infrastructure\|cloud-infrastructure]]                 |            |
| **CXL**                    | Hardware / Memory     | Server tidak bisa share RAM — AI training butuh RAM massif per node | Memory disaggregation — pool RAM yang bisa di-share antar server via PCIe | Intel, AMD, Samsung, AWS, Google                 | 🟡 CXL 3.0 spec, early production     | [[computer-science-foundations\|computer-science-foundations]] |            |
| **Confidential Computing** | Hardware Security     | Cloud provider bisa akses data customer di memori                   | TEE (Trusted Execution Environment) — RAM terenkripsi saat komputasi      | Azure, GCP, AWS, IBM                             | ✅ Production di semua major cloud     | [[cryptography-biometrics\|cryptography-biometrics]]           |            |
| **DPU / SmartNIC**         | Hardware / Networking | CPU waste 30% cycle untuk networking overhead                       | Dedicated programmable chip — networking/storage/security offload         | AWS (Nitro), NVIDIA (BlueField), AMD (Pensando)  | ✅ Production di hyperscaler           | [[cloud-infrastructure                                         | Cloud]]    |
| **P4 Language**            | Network Hardware      | Switch firmware closed — tidak bisa custom forwarding logic         | Program packet forwarding di ASIC/FPGA dengan bahasa deklaratif           | Google (Orion), Microsoft (SONiC), Tofino switch | 🟡 Niche tapi growing di hyperscaler  | [Network](/01_Library/Cyber_Security/Network_Threats/)         |            |
| **RISC-V**                 | CPU Architecture      | ARM/x86 = vendor lock-in, licence fees, closed ISA                  | Open instruction set — siapapun bisa buat CPU RISC-V tanpa royalti        | SiFive, StarFive, Alibaba, Google, NASA          | 🟡 Growing, dominant di embedded 2030 | [[embedded-systems                                             | Embedded]] |

---

## 1 — io_uring: "eBPF untuk I/O Subsystem"

```
MASALAH LAMA (epoll + aio + read/write):

Traditional async I/O di Linux:
→ Setiap operasi = minimal 1 syscall
→ Syscall = context switch kernel/user space
→ 1 juta request/detik = 1 juta+ context switch
→ CPU habis untuk overhead, bukan actual work

epoll punya 3 masalah:
1. File descriptor terbatas
2. Tidak support semua file type (pipe, file biasa = blocking)
3. Thundering herd problem

aio (POSIX async I/O) masalahnya:
1. Hanya support O_DIRECT (bypass cache) = tidak berguna untuk banyak kasus
2. Completions tidak selalu async
3. Implementasi sangat buruk
```

```
SOLUSI io_uring (Jens Axboe, 2019):

Ring buffer bersama antara kernel dan user space:
[User Space] → submission ring → [Kernel]
[User Space] ← completion ring ← [Kernel]

User push semua request ke submission ring
Kernel proses batch
User poll completion ring

Zero syscall setelah setup awal!
(atau satu syscall io_uring_enter untuk ribuan operasi)
```

| Metrik | epoll + read/write | io_uring |
|---|---|---|
| Syscall per operasi | 1+ | ~0 (setelah setup) |
| Throughput (file I/O) | ~500K ops/s | ~2M+ ops/s |
| CPU overhead | Tinggi (context switch) | Sangat rendah |
| Support file type | Terbatas | Semua (network, file, pipe, timer) |
| Kernel version | Legacy | 5.1+ (full feature 5.7+) |

```
Who uses io_uring in production:
✅ PostgreSQL 16+ — async I/O backend
✅ RocksDB — Facebook/Meta storage engine
✅ NGINX — experimental async mode
✅ Android — dipakai untuk I/O internal sejak Android 12
✅ liburing — library wrapper yang membuat io_uring mudah dipakai
✅ Tokio (Rust async runtime) — io_uring backend

Security note:
io_uring punya history CVE yang panjang (2021-2023)
Beberapa container platform disable io_uring karena attack surface
Tapi kernel 6.x sudah jauh lebih aman
```

>[!tip] Koneksi ke eBPF
>io_uring + eBPF adalah kombinasi sempurna: io_uring untuk zero-overhead I/O, eBPF untuk monitor setiap operasi io_uring dengan zero overhead tambahan. RocksDB + io_uring + eBPF profiler = stack observability terbaik untuk storage engine.

---

## 2 — WebAssembly (WASM): "Docker yang Lebih Ringan dan Lebih Portable"

```
EVOLUSI WASM:

2015: WASM lahir untuk browser — gantikan JavaScript untuk performa
2019: WASI (WebAssembly System Interface) — WASM di luar browser
2020: Docker founder: "Kalau WASM ada saat Docker lahir,
      Docker tidak perlu dibuat"
2023: WASM Component Model — interop antar bahasa
2024: WASI Preview 2 stable — production ready di server
2026: WASM menjadi alternatif container yang legitimate
```

```
PERBANDINGAN DENGAN PENDEKATAN LAIN:

                  Cold Start    Memory    Security    Portability
Native binary   : ~0ms          ~min      OS-level    Per-platform
Docker container: ~100-500ms    ~50-500MB Namespace   Per-OS
WASM            : ~1ms          ~1-10MB   Sandbox     Truly universal

"Truly universal" artinya:
→ Kompilasi sekali → jalan di x86, ARM, RISC-V, browser, server, edge
→ Tanpa recompile, tanpa container image per platform
```

```
USE CASE YANG SUDAH PRODUCTION:

Cloudflare Workers:
→ 100+ juta WASM functions jalan di edge Cloudflare
→ Cold start < 5ms (Docker bisa 500ms+)
→ Isolasi security per-tenant via WASM sandbox

Shopify (Oxygen platform):
→ Semua storefront logic jalan sebagai WASM
→ Deploy ke 300 edge locations sekaligus

Docker Desktop:
→ Docker sedang support WASM sebagai alternatif container
→ docker run --runtime=io.containerd.wasmedge.v1

Fermyon Spin:
→ Microservices framework berbasis WASM
→ Deploy function ke edge tanpa manage server

Plugin systems:
→ Grafana, Envoy, Redis semua support WASM plugins
→ Extend tanpa restart, tanpa native code, sandboxed
```

```
WASM vs eBPF — Soulmates yang Berbeda:

eBPF: sandboxed program di dalam kernel
WASM: sandboxed program di user space

Keduanya: verifier/sandbox, bytecode, portable
Perbedaan: eBPF di kernel = akses hardware langsung
           WASM di user space = isolasi lebih kuat, lebih general

Kombinasi masa depan:
WASM sebagai plugin runtime (business logic)
eBPF sebagai observability layer (monitor WASM execution)
```

---

## 3 — CXL: "Disaggregated Memory untuk Era AI"

```
MASALAH YANG CXL SELESAIKAN:

Training LLaMA 70B membutuhkan ~140GB RAM
Training GPT-4 membutuhkan terabyte RAM
Satu server: maksimal ~1-2TB RAM (mahal, terbatas slot)

Solusi lama: distributed training → komunikasi antar node lambat
Bottleneck: GPU menunggu data dari RAM → GPU idle

CXL (Compute Express Link):
→ Standar interconnect baru di atas PCIe 5.0
→ Memory semantics — akses ke remote memory seperti local
→ Latency: ~100-200ns (DRAM lokal: ~80ns, network: ~10,000ns)
```

```
ARSITEKTUR CXL:

CXL 1.0/2.0: Attach CXL memory expander ke satu server
CXL 3.0: Memory pooling — SATU pool RAM untuk BANYAK server

┌─────────┐    ┌─────────┐    ┌─────────┐
│ Server A│    │ Server B│    │ Server C│
│ GPU + CPU│    │ GPU + CPU│    │ GPU + CPU│
└────┬────┘    └────┬────┘    └────┬────┘
     │              │              │
     └──────────────┼──────────────┘
                    │ CXL Fabric
              ┌─────┴─────┐
              │ CXL Memory│
              │  Pool     │
              │ (10TB RAM)│
              └───────────┘

Semua server bisa akses RAM pool sesuai kebutuhan
→ Server A butuh 2TB untuk training → ambil dari pool
→ Selesai training → kembalikan ke pool
→ Dynamic memory allocation across cluster
```

```
ADOPSI NYATA:

Samsung: CXL memory module production 2023
SK Hynix: CXL DRAM shipping ke hyperscaler
Intel: Xeon server dengan CXL controller
AWS: Sedang development (bocoran dari job posting)

Prediksi:
2026-2027: CXL masuk mainstream data center AI
2028-2030: Disaggregated memory jadi standard
```

>[!tip] Koneksi ke Vault
>CXL langsung nyambung ke Computer Architecture (NUMA → CXL sebagai "remote NUMA"), Data Recovery (CXL memory bisa persistent — antara RAM dan SSD), dan AI Levels (training LLM yang feasible tanpa cluster besar).

---

## 4 — Confidential Computing: "Zero Trust untuk Cloud"

```
MASALAH:
"Saya mau proses data sensitif di cloud,
 tapi tidak mau cloud provider bisa baca data saya"

Selama ini tidak ada solusi teknis — hanya legal/kontraktual

SOLUSI: TEE (Trusted Execution Environment)
→ Hardware yang enkripsi RAM secara transparan
→ Bahkan hypervisor dan cloud provider tidak bisa akses
→ Kriptografis dibuktikan via remote attestation
```

```
TIGA IMPLEMENTASI UTAMA:

Intel TDX (Trust Domain Extensions):
→ Seluruh VM terenkripsi di hardware level
→ Memory controller enkripsi/dekripsi per memory access
→ Cloud provider lihat: ciphertext
→ User lihat: plaintext (karena punya kunci)

AMD SEV-SNP (Secure Encrypted Virtualization):
→ Sama konsep dengan Intel TDX
→ Sudah production di Azure, GCP, AWS
→ Dipakai untuk: medical data, financial computation

ARM TrustZone / Realm:
→ Untuk mobile dan edge
→ Apple Secure Enclave adalah implementasi TrustZone
→ Android Keystore = TrustZone
```

```
USE CASE NYATA:

Medical AI:
→ Rumah sakit A dan B mau latih model bersama
→ Tapi tidak mau share data pasien
→ Confidential Computing: train model di TEE
   → Keduanya masukkan data → model di-train → keluarkan model
   → Tidak ada pihak yang bisa lihat data pihak lain

Financial:
→ Bank mau detect fraud dengan data dari bank lain
→ Tidak bisa share karena regulasi
→ TEE: compute bersama tanpa share raw data

Secret AI Inference:
→ Kamu mau query model AI dengan data sensitif (diagnosis medis)
→ Tidak mau provider AI lihat data kamu
→ TEE: inference terjadi di encrypted memory
```

```
REMOTE ATTESTATION:
"Bagaimana saya tahu bahwa server yang saya kirim data
 benar-benar menjalankan TEE yang aman?"

→ CPU generate cryptographic proof
→ Signed oleh Intel/AMD root certificate
→ Kamu bisa verifikasi: "server ini memang running TDX
   dengan kode yang sudah saya audit"
→ Ini yang disebut "hardware root of trust"
```

>[!tip] Koneksi ke Vault
>Confidential Computing nyambung langsung ke Kriptografi (TEE + Post-Quantum signing), LLM Security (private AI inference), dan OS Hierarchy (Ring -1 level hardware security).

---

## 5 — DPU / SmartNIC: "CPU Dibebaskan dari Pekerjaan Kasar"

```
MASALAH:
Di server modern, 30% CPU cycles dihabiskan untuk:
→ Networking (TCP/IP stack, TLS, packet processing)
→ Storage (NVMe-oF, iSCSI)
→ Security (encryption, firewall, DPI)

Artinya: 30% server yang kamu bayar tidak mengerjakan
         workload kamu — hanya overhead infrastruktur

SOLUSI DPU (Data Processing Unit):
→ Chip terpisah yang dedicated untuk infra task
→ CPU bebas 100% untuk actual application
→ DPU punya ARM cores, FPGA, dan network ASICs sendiri
```

```
PEMAIN UTAMA:

NVIDIA BlueField-3 (paling populer):
→ 16 ARM Cortex-A78 cores
→ 400Gbps network throughput
→ Programmable dengan DOCA SDK (C/CUDA-like)
→ Dipakai di: AWS Graviton instances, Azure HBv3

AMD Pensando Elba (diakuisisi AMD 2022):
→ 24 custom MIPS cores
→ Dipakai di: Cisco UCS, Dell PowerEdge

Intel IPU (Infrastructure Processing Unit):
→ Disebut IPU, bukan DPU
→ Dipakai di: AWS Nitro System (generasi berikutnya)
```

```
AWS NITRO SYSTEM — STUDI KASUS:

Sebelum Nitro (2017):
→ EC2 instance: hypervisor + networking + storage = 20-30% overhead
→ "c3.8xlarge" 32 vCPU tapi efektif hanya ~22 vCPU untuk customer

Setelah Nitro (DPU-based):
→ Semua hypervisor function offload ke Nitro card
→ EC2 instance: 100% CPU untuk customer workload
→ AWS bisa jual "bare metal performance" di virtual machine

Hasilnya:
→ AWS efisiensi naik drastis
→ Customer dapat lebih banyak performance per dollar
→ Semua kompetitor ikut: Azure (Maia), GCP (Axiom)
```

```
PROGRAMMABLE DPU:
DPU bukan static — bisa diprogram!

DOCA SDK (NVIDIA):
→ Write C/C++ yang jalan di DPU
→ Custom firewall, custom load balancer, custom encryption
→ Deploy ke DPU tanpa restart server

Implikasi security:
→ Firewall yang tidak bisa di-bypass bahkan jika OS compromised
→ Karena firewall jalan di chip terpisah, bukan di OS
→ Root kit di OS: tidak bisa matikan DPU firewall
```

---

## 6 — P4: "Bahasa Pemrograman untuk Hardware Network"

```
APA ITU P4:
P4 = Programming Protocol-independent Packet Processors
→ Domain-specific language untuk define packet forwarding behavior
→ Jalan di: programmable ASIC (Tofino), FPGA, SmartNIC

ANALOGI:
eBPF : kernel Linux = P4 : network switch hardware

MASALAH YANG DISELESAIKAN:
Switch tradisional:
→ Firmware closed source dari Cisco/Juniper
→ Feature baru butuh tunggu vendor release update
→ Tidak bisa custom forwarding logic
→ Stuck dengan apa yang vendor putuskan

P4 switch:
→ Tulis program P4 → deploy ke switch
→ Custom protocol parsing, custom forwarding
→ Fitur baru tanpa ganti hardware
→ Open ecosystem
```

```
USE CASE NYATA:

Google (Orion):
→ Gantikan seluruh network stack data center dengan P4
→ Custom load balancing, custom routing
→ Performance yang tidak bisa dicapai dengan switch biasa

INT (In-band Network Telemetry):
→ P4 program yang tambahkan metadata ke setiap paket
→ Setiap paket membawa: timestamp di setiap hop, queue depth
→ Network telemetry resolusi microsecond
→ Tidak mungkin dilakukan dengan switch tradisional

Custom Protocol:
→ Perusahaan bisa define protokol baru
→ Switch understand protokol tersebut natively di hardware
→ RDMA over Converged Ethernet (RoCE) — diimplement via P4
```

```
HARDWARE YANG SUPPORT P4:
→ Intel Tofino (paling populer untuk research)
→ Barefoot Networks (diakuisisi Intel)
→ NVIDIA BlueField (DPU + P4 capable)
→ Netronome SmartNIC
→ Software simulator: BMv2 (gratis, untuk belajar)
```

---

## 7 — RISC-V: "Open Source Hardware"

```
MENGAPA RISC-V PENTING:

x86 (Intel/AMD):
→ ISA proprietary, license fee
→ Komplex CISC architecture, banyak legacy instruction
→ Tertutup — tidak bisa buat chip x86 tanpa license Intel/AMD

ARM:
→ ISA license dari ARM Holdings (sekarang SoftBank)
→ Fee per chip, fee per design
→ Apple, Qualcomm, Samsung semua bayar ARM
→2022: NVIDIA gagal akuisisi ARM → geopolitik hardware

RISC-V:
→ Open standard — siapapun bisa implementasi tanpa royalti
→ Modular: base ISA + extension (Vector, Crypto, dll)
→ Dari microcontroller 32-bit sampai server 64-bit
→ Didukung oleh: Linux kernel, GCC, LLVM, Rust, Go
```

```
SIAPA YANG SUDAH SERIUS:

China (motivasi geopolitik):
→ Alibaba T-Head XuanTie C910 — server-grade RISC-V
→ SOPHON CV1800B — di Milk-V Duo ($5 Linux board!)
→ China investasi besar karena tidak bisa bergantung ARM/x86

Western Companies:
→ SiFive (US) — RISC-V design house terbesar
→ Google — kontribusi ke RISC-V toolchain
→ NVIDIA — RISC-V untuk GPU firmware internal
→ Western Digital — RISC-V di semua SSD controller mereka

NASA & Defense:
→ NASA menggunakan RISC-V untuk space mission processor
→ Tidak tergantung vendor = supply chain security

Academic:
→ MIT, Berkeley, Stanford — RISC-V adalah CPU yang diajarkan
→ Generasi engineer berikutnya familiar dengan RISC-V
```

```
HARDWARE ENTRY POINT (Untuk Belajar):

$5-15:
→ Milk-V Duo (CV1800B) — Linux + RISC-V, lebih kecil dari kartu kredit

$20:
→ Sipeed Lichee RV — RISC-V dengan display support

$50-100:
→ SiFive HiFive Unmatched — desktop-grade RISC-V

$200+:
→ StarFive VisionFive 2 — server-grade, PCIe, 8GB RAM

Semua bisa jalan:
→ Linux kernel mainline
→ eBPF (kernel 6.1+)
→ Rust native compilation
→ Docker (via emulation atau native)
```

```
TIMELINE PREDIKSI:

2026: RISC-V dominant di IoT dan embedded (sudah terjadi)
2027: RISC-V masuk mainstream laptop/workstation (China first)
2028: RISC-V server chip yang kompetitif dengan ARM server
2030: 25% pasar CPU global (prediksi RISC-V International)
2035: Potentially challenge x86/ARM di data center
```

---

## Hubungan Antar Teknologi

```
LAYER DIAGRAM:

[RISC-V] ←── Arsitektur CPU yang run semua di bawah ini
    │
[CXL] ←── Memory interconnect di atas RISC-V / x86 / ARM
    │
[DPU/SmartNIC] ←── Dedicated chip untuk infra offload
    │
[Confidential Computing] ←── Hardware security layer
    │
[Linux Kernel]
    ├── [eBPF] ←── Kernel programmability
    └── [io_uring] ←── Async I/O subsystem
          │
[Runtime Layer]
    └── [WebAssembly (WASM)] ←── Universal portable runtime
          │
[Network Hardware]
    └── [P4] ←── Programmable packet forwarding
```

```
KOMBINASI YANG PALING POWERFUL:

Stack 1 — High Performance Computing:
RISC-V server + CXL memory pool + io_uring storage + eBPF observability
→ Ideal untuk: AI training yang cost-efficient

Stack 2 — Zero Trust Infrastructure:
DPU (networking) + Confidential Computing (TEE) + eBPF (monitoring)
→ Ideal untuk: regulated industry (bank, hospital)

Stack 3 — Edge Computing:
RISC-V MCU + WASM runtime + eBPF (minimal)
→ Ideal untuk: IoT yang butuh updateable logic + security

Stack 4 — Hyperscaler Internal:
P4 switch + DPU + eBPF observability + io_uring storage
→ Ini yang Google, Meta, AWS sudah pakai
```

---

## Priority — Mana yang Worth Dipelajari Sekarang

```
Untuk KAMU (security + systems + AI interest):

🔴 PRIORITAS TINGGI (dalam 6 bulan):
├── Confidential Computing
│   → Nyambung langsung ke LLM Security
│   → Private AI inference adalah use case hot
│   → Skill langka, demand tinggi
│
└── io_uring
    → Fundamental untuk understand modern storage
    → Dipakai di PostgreSQL, RocksDB
    → Mudah di-praktikkan di Linux sekarang

🟡 MENENGAH (6-12 bulan):
├── WebAssembly (WASM)
│   → Sedang jadi standard di serverless/edge
│   → Cloudflare Workers, Fastly sudah production
│
└── RISC-V
    → Entry point murah ($5-20)
    → eBPF on RISC-V = intersection menarik
    → Long game tapi worth dimulai sekarang

🟢 FUTURE WATCH (12+ bulan):
├── CXL → Masih early, tapi akan sangat penting untuk AI
├── DPU → Butuh akses hardware mahal untuk praktik
└── P4  → Butuh hardware khusus (Tofino) yang mahal
```

---

## 🔗 Lihat Juga

- [[ebpf-kernel-security|eBPF Security]] — teknologi yang sama level, sudah production
- [[ebpf-beyond-security|eBPF Beyond Security]] — referensi untuk compare
- [[computer-science-foundations|Computer Architecture]] — fondasi untuk CXL dan DPU
- [[cloud-infrastructure|Cloud Infrastructure]] — context deployment semua teknologi ini
- [[embedded-systems|Embedded Systems]] — RISC-V dan io_uring connection
- [[cryptography-biometrics|Kriptografi]] — Confidential Computing + Post-Quantum
- [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] — Confidential Computing untuk private AI
- [[master-index|Master Index]]

---

*Platform Technologies | io_uring · WebAssembly · CXL · Confidential Computing · DPU · P4 · RISC-V · The Next eBPF-level Shifts*