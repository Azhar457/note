---
title: 🗄️ Memory & Storage Hierarchy — Dari Register ke Cold Archive
tags:
- hierarchy
- cross-cutting
- memory
- storage
- caching
- tier
aliases:
- Memory Hierarchy
- Storage Tier Map
- Cache Hierarchy
- From Register to Cold Archive
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---
# 🗄️ Memory & Storage Hierarchy — Dari Register ke Cold Archive

> [!tip] Data terletak di **8 lapisan hierarki memori**, di mana setiap lapisan ke atas (menuju CPU) lebih cepat, lebih kecil, lebih mahal. Catatan ini memetakan memory hierarchy dari register (0.3 ns, Byte) hingga cold archive (30+ s, Exabyte) — lintas AI (model loading), DB (B-tree caching), OS (page cache), security (cold data retention), dan storage engineering. Dengan trade-off matrix per tier, failure mode, dan decision framework.

---

## Daftar Isi

1. [[#1. Premise — Memori Itu Hierarki Tersembunyi]]
2. [[#2. Eight-Tier Memory Hierarchy]]
3. [[#3. Tier 0 — CPU Register]]
4. [[#4. Tier 1 — L1/L2/L3 Cache]]
5. [[#5. Tier 2 — RAM (Main Memory)]]
6. [[#6. Tier 3 — Persistent Memory (PMEM)]]
7. [[#7. Tier 4 — Flash (SSD, NVMe)]]
8. [[#8. Tier 5 — HDD (Spinning Disk)]]
9. [[#9. Tier 6 — Network Attached (NAS/SAN)]]
10. [[#10. Tier 7 — Cloud Object Storage]]
11. [[#11. Tier 8 — Cold Archive & Tape]]
12. [[#12. Decision Framework]]
13. [[#13. Cross-Reference ke Vault]]
14. [[#References]]

---

## 1. Premise — Memori Itu Hierarki Tersembunyi

Setiap tier memiliki hubungan trade-off mendasar:

```
Speed ↑    Cost per GB ↑    Capacity ↓
  ↓           ↓                ↑
  Register    $1000/GB         512B-1KB
  L1 Cache    $100/GB          32-64KB
  L2 Cache    $50/GB           256-512KB
  L3 Cache    $30/GB           8-32MB
  RAM         8-12/GB          hasta TB
  PMEM        5-8/GB           hasta TB
  SSD         $0.10-0.20/GB    hasta 32TB
  HDD         $0.02-0.05/GB    hasta 30TB
  Cloud Obj   $0.01-0.023/GB   Unlimited
  Tape        $0.004/GB        200-300TB
```

**Prinsip fundamental:** 90% waktu, data tidak panas. Pakai cache tier yang paling dekat.

---

## 2. Eight-Plus-One Tier Memory Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ T8  │ Cold Archive / Tape                                 │ ← min
├────────────────────────────────────────────────────────────┤
│ T7  │ Cloud Object Storage (S3, GCS, B2)                  │
├────────────────────────────────────────────────────────────┤
│ T6  │ Network Attached (NAS, SAN)                         │
├────────────────────────────────────────────────────────────┤
│ T5  │ HDD (Spinning Disk)                                 │
├────────────────────────────────────────────────────────────┤
│ T4  │ Flash SSD (NVMe, SATA)                              │
├────────────────────────────────────────────────────────────┤
│ T3  │ Persistent Memory (Optane, CXL)                     │
├────────────────────────────────────────────────────────────┤
│ T2  │ RAM (DDR5, HBM)                                     │
├────────────────────────────────────────────────────────────┤
│ T1  │ L1/L2/L3 Cache (SRAM)                               │
├────────────────────────────────────────────────────────────┤
│ T0  │ CPU Register                                        │ ← max
└────────────────────────────────────────────────────────────┘
```

---

## 3. Tier 0 — CPU Register

### 3.1 Karakteristik

| Aspek | Detail |
|-------|--------|
| **Teknologi** | Flip-flop di core CPU |
| **Kapasitas** | 512B-1KB (64-128 register × 64-bit) |
| **Latency** | 0.3-1 ns (siklus clock tunggal) |
| **Bandwidth** | 1-5 TB/s (per cycle × core count) |
| **Persistensi** | Volatile (hilang saat reset) |
| **Biaya** | ~$1000/GB (embedded di CPU die) |

### 3.2 Kegunaan

- Operand instruksi, alamat memori
- Stack pointer, program counter
- Loop counters, temporary results

**Prinsip:** Stack spill ke L1 cache saat register penuh.

---

## 4. Tier 1 — L1/L2/L3 Cache (SRAM)

### 4.1 Karakteristik per Level

| Level | Kapasitas | Latency | Bandwidth | Associativity | Shared? |
|:-----:|:---------:|:-------:|:---------:|:-------------:|:-------:|
| L1 | 32-64 KB | ~1 ns (4 cycles) | 1-5 TB/s | 8-way | Per core |
| L2 | 256-512 KB | ~3 ns (12 cycles) | 500 GB/s | 8-way | Per core |
| L3 | 8-32 MB | ~10 ns (40 cycles) | 200 GB/s | 16-20 way | Shared |

### 4.2 Prinsip Cache Miss

| Miss Type | Penyebab | Penalti |
|-----------|----------|:-------:|
| Cold miss | Pertama kali akses | ~100 cycles (RAM) |
| Capacity miss | Cache terlalu kecil | ~100 cycles |
| Conflict miss | Associativity terbatas | ~10 cycles |
| Coherence miss | CPU lain modifikasi | ~50 cycles |

### 4.3 Cache Line = 64 bytes

Setiap cache line membawa 64 byte data contiguous — **spatial locality** prized.

---

## 5. Tier 2 — RAM (Main Memory)

### 5.1 Karakteristik

| Aspek | Detail |
|-------|--------|
| **Teknologi** | DDR5, HBM (High Bandwidth Memory) |
| **Kapasitas** | 8GB - 2TB per DIMM |
| **Latency** | ~70-100 ns (DDR5), ~150 ns (HBM) |
| **Bandwidth** | 32-64 GB/s (DDR5), 1-3 TB/s (HBM) |
| **Persistensi** | Volatile |
| **Biaya** | $8-12/GB |

### 5.2 Struktur

```
DIMM → Rank → Chip → Bank → Row → Column → Cell (1T1C)
```

### 5.3 Use Case

- Program code, stack, heap
- Database buffer pool
- OS page cache
- AI model weights (in RAM)

---

## 6. Tier 3 — Persistent Memory (PMEM)

### 6.1 Karakteristik

| Aspek | Detail |
|-------|--------|
| **Teknologi** | Intel Optane (discontinued), CXL-attached, Samsung SCM |
| **Kapasitas** | 128GB-1.5TB per DIMM |
| **Latency** | ~350 ns (read), ~1 us (write) |
| **Bandwidth** | ~15 GB/s |
| **Persistensi** | Non-volatile |
| **Biaya** | $5-8/GB |

### 6.2 Use Case

- **Persistent cache** untuk DB buffer pool
- **Fast restart** — data di PMEM tidak perlu re-heat
- **Large in-memory graph** (knowledge graph, RDF)

---

## 7. Tier 4 — Flash SSD

### 7.1 Karakteristik per Interface

| Interface | Latency (Read) | Latency (Write) | Bandwidth | Kapasitas |
|-----------|:--------------:|:---------------:|:---------:|:---------:|
| SATA SSD | ~80 us | ~80 us | ~550 MB/s | hasta 4TB |
| NVMe Gen4 | ~5 us | ~10 us | ~7 GB/s | hasta 8TB |
| NVMe Gen5 | ~3 us | ~5 us | ~14 GB/s | hasta 16TB |
| Optane SSD (DC) | ~10 us | ~20 us | ~2 GB/s | hasta 1.5TB |

### 7.2 Jenis NAND

| Type | Bits/Cell | Endurance (P/E cycles) | Use Case |
|:----:|:---------:|:----------------------:|----------|
| SLC | 1 | 100K | Enterprise cache |
| MLC | 2 | 30K | Enterprise mid-range |
| TLC | 3 | 10K | Consumer, enterprise |
| QLC | 4 | 5K | Cold archive, HDD replacement |
| PLC | 5 | 1-2K | Archive (research) |

### 7.3 GC & TRIM

- **Wear leveling** — tulis merata ke semua block
- **Garbage collection** — rewrite block saat free pages di block minimum
- **TRIM** — OS memberitahu SSD bahwa page tidak dipakai

### 7.4 Use Case

- **Hot data storage**
- **Database tier** (WAL di NVMe, data di SSD)
- **Boot drive**
- **Container images**

---

## 8. Tier 5 — HDD (Spinning Disk)

### 8.1 Karakteristik

| Aspek | Detail |
|-------|--------|
| **Teknologi** | Platter + actuator + read/write head |
| **Kapasitas** | hasta 30TB (CMR/SMR) |
| **Latency** | ~5-10ms (rotation 7200 RPM) |
| **Bandwidth** | ~200 MB/s (sequential), ~1 MB/s (random) |
| **Persistensi** | Non-volatile |
| **Biaya** | $0.02-0.05/GB |

### 8.2 Perbandingan Khas

```
NVMe SSD     : 5 us read, 14 GB/s
SATA SSD     : 80 us read, 550 MB/s
HDD 7200 RPM : 7 ms read, 200 MB/s
               ↑ 3 orders of magnitude slower
```

### 8.3 Use Case

- **Cold data** (log, backup, cold tier)
- **High capacity bulk storage**
- **Offline backup** (USB HDD)

---

## 9. Tier 6 — Network Attached (NAS/SAN)

### 9.1 Karakteristik

| Fitur | NAS | SAN |
|-------|-----|-----|
| Protocol | NFS, SMB | iSCSI, FC |
| Granularity | File-level | Block-level |
| Performance | Medium (network overhead) | High (dedicated fabric) |
| Use case | Team file share | Database storage |

### 9.2 Latency Breakdown

```
Application → Network → NAS/SAN → Disk → Response

Typical: 100 us - 10 ms (best case to worst case)
```

---

## 10. Tier 7 — Cloud Object Storage

### 10.1 Karakteristik

| Provider | Product | Latency | Durability | Cost/GB/Month |
|----------|---------|:-------:|:----------:|:-------------:|
| AWS | S3 Standard | ~50-200ms | 99.999999999% | $0.023 |
| AWS | S3 Infrequent | ~50-200ms | 99.999999999% | $0.0125 |
| AWS | S3 Glacier | ~1-12h | 99.999999999% | $0.0036 |
| AWS | S3 Glacier Deep | ~12-48h | 99.999999999% | $0.00099 |
| GCP | Cloud Storage | ~50-200ms | 99.999999999% | $0.020 |
| Cloudflare | R2 | ~30-100ms | 99.999999999% | $0 (no egress) |

### 10.2 Use Case

- **Static assets** (images, video, CSS/JS)
- **Backup & archive**
- **Data lake** (Parquet, Avro)
- **AI training data** (S3 compatible)

---

## 11. Tier 8 — Cold Archive & Tape

### 11.1 Karakteristik

| Aspek | Detail |
|-------|--------|
| **Teknologi** | LTO-9 (18 TB native), LTO-10 (36 TB) |
| **Kapasitas** | 200-300 TB per library |
| **Latency** | ~30-60s (robot mount) |
| **Bandwidth** | ~300 MB/s (sequential) |
| **Persistensi** | Non-volatile (30+ tahun) |
| **Biaya** | $0.004/GB (tape media) |

### 11.2 Use Case

- **Compliance archive** (7-30 tahun retention)
- **Disaster recovery vault**
- **Air-gapped backup**
- **Scientific data** (space, genomics)

---

## 12. Decision Framework

### 12.1 Pilih Tier Berdasarkan

```
Hotness (access frequency)  →  Tier 0-2 (Cache/RAM)
Latency requirement         →  Tier 0-1 (sub-10ns)
Capacity need               →  Tier 4-8 (TB-EB)
Budget (cost per GB)        →  Tier 5-8 (HDD/Cloud/Tape)
```

### 12.2 Anti-Pattern

| Anti-Pattern | Fallout |
|--------------|---------|
| Database tiap query scan GB = RAM habis | OOM, query timeout |
| SSD untuk archive data (>90% cold) | Wear terkuras sia-sia |
| Cold data di S3 Standard = cost ledakan | Tagihan membengkak |
| Tape sebagai hot tier | Latency impossible |

---

## 13. Cross-Reference ke Vault

| Tier | Catatan Vault Terkait |
|:----:|-----------------------|
| **T0-T1** | [[hierarchy-operating-systems]] (Cache / TLB) |
| **T2** | [[00_Atlas/hierarchy-kernel-bypass-networking]] (DMA buffer) |
| **T3** | [[hierarchy-database-storage-systems]] (PMEM tier) |
| **T4** | [[00_Atlas/hierarchy-infrastructure-evolution]] (NVMe as standard) |
| **T5** | [[hierarchy-data-recovery]] (HDD recovery) |
| **T6** | [[hierarchy-network-security]] (NAS/SAN security) |
| **T7** | [[00_Atlas/hierarchy-llm-ai-systems]] (Training data in S3) |
| **T8** | [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] (Offline backup L1) |
| **All** | [[00_Atlas/hierarchy-digital-plumbing]] (Compression & parsing) |
| **All** | [[00_Atlas/hierarchy-systems-architecture-evolution]] (Distributed tiering) |
| **All** | [[hierarchy-abstraction-layers]] — L1-L8 memori |

---

## References

1. Hennessy & Patterson. *"Computer Architecture: A Quantitative Approach."* 6th ed., 2019.
2. Jacob et al. *"Memory Systems: Cache, DRAM, Disk."* 2008.
3. Intel. *"Intel Optane Persistent Memory."* (2019-2023).
4. NVM Express. *"NVM Express Base Specification v2.0."* (2021).
5. SNIA. *"Storage Networking Industry Association: Persistent Memory."* (2020).
6. LTO Consortium. *"LTO Ultrium Format Specifications."* (2023).
7. AWS. *"Amazon S3 Storage Classes."* (2024).
8. Google Cloud. *"Cloud Storage Documentation."* (2024).
9. Denning, P. *"The Working Set Model for Program Behavior."* CACM, 1968.
10. Mogul, J. *"Operating Systems and Virtual Memory: The Dark Side."* 2012.
11. Lee et al. *"Flash Memory — A 40-Year Perspective."* IEEE, 2023.
12. Rumble et al. *"It's Time for Low Latency."* USENIX ATC 2011.
