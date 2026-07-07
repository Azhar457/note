---
tags:
  - software-architecture
  - flaw-detection
  - anti-patterns
  - distributed-systems
  - system-thinking
  - threat-modeling
  - chaos-engineering
aliases:
  - Architectural Flaw Detection
  - System Defect Analysis
  - Architecture Radar
  - Logical Defect Detection
created: 2026-06-18
title: Architectural Flaw Detection
status: active
updated: "2026-07-01"
---

# 🔍 ARCHITECTURAL FLAW DETECTION — Mental Models, Taxonomy, and Methodologies

> Dokumen ini adalah **radar arsitektur** yang melengkapi catatan System Design Anda. Jika catatan sebelumnya menjawab _"arsitektur apa yang harus dipakai"_, dokumen ini menjawab _"bagaimana mengetahui arsitektur tersebut sedang rusak sebelum runtuh."_

> [!info] Hubungan dengan `system-design.md`
> Catatan ini **tidak menduplikasi** Level 0–7 yang sudah ada. Sebaliknya, setiap bagian di sini **mengacu balik** ke level yang relevan dan menambahkan _lensa deteksi_ yang sebelumnya belum tercakup. Baca berdampingan.

---

## 1. Ontologi Kegagalan Arsitektural

Sebelum bisa mendeteksi flaw, seorang engineer harus memiliki **ontologi** — kerangka klasifikasi yang memungkinkan pengenalan pola kegagalan sebelum manifestasi fisik. Kegagalan arsitektural tidak muncul tiba-tiba; mereka **inkubasi** melalui serangkaian keputusan mikro yang tampak benign.

### 1.1 Hierarki Kegagalan

```
Level 0: Principle Violation          (SOLID, DRY, KISS — lihat system-design.md Level 0)
    ↓
Level 1: Pattern Misuse               (GoF yang dipaksakan — lihat system-design.md Level 1)
    ↓
Level 2: Structural Degradation       (coupling, cohesion, connascence)
    ↓
Level 3: Behavioral Defect            (race conditions, deadlocks, thundering herd)
    ↓
Level 4: Distributed Pathology        (split-brain, cascading failure, backpressure loss)
    ↓
Level 5: Evolutionary Trap            (tech debt, rigidity, over-engineering)
    ↓
Level 6: Systemic Collapse            (cascading failure yang melintas layer)
```

> **Insight kunci:** Flaw di Level 2–3 sering **tidak terdeteksi** oleh testing fungsional. Mereka memerlukan analisis struktural dan behavioral yang berbeda.

---

## 2. Mental Models untuk Deteksi Flaw

### 2.1 Second-Order Thinking (Howard Marks / John Boyd)

Kebanyakan keputusan arsitektural dievaluasi berdasarkan **efek langsung** (first-order): _"Kalau pakai microservices, deployment lebih fleksibel."_ Second-order thinking menuntut evaluasi **efek dari efek**:

- Deployment fleksibel → tim lebih banyak → komunikasi overhead naik → keputusan arsitektur lambat → **distributed monolith** (lihat system-design.md Level 3)
- Event-driven → decoupling → debugging sulit → waktu MTTR naik → **error budget habis lebih cepat** (lihat system-design.md Level 7)

**Latihan:** Untuk setiap keputusan arsitektur, tulis 3 efek second-order. Jika Anda tidak bisa menulisnya, keputusan tersebut belum cukup dipahami.

### 2.2 Adversarial Thinking (Red Team Mindset)

Berpikir seperti **attacker** bukan hanya untuk security. Dalam arsitektur, adversarial thinking berarti:

- _"Bagaimana saya bisa membuat sistem ini gagal dengan sengaja?"_
- _"Komponen mana yang, jika saya matikan, akan menyebabkan efek domino?"_
- _"Di mana sistem ini paling optimis?"_ (optimism = tempat flaw bersembunyi)

**Teknik:** Lakukan **pre-mortem** sebelum deployment. Bayangkan sistem sudah down 6 bulan dari sekarang. Apa yang menyebabkannya? Tulis laporan kegagalan _sebelum_ kegagalan terjadi.

### 2.3 Inversion (Charlie Munger)

Alih-alih bertanya _"bagaimana membuat sistem yang baik?"_, tanyakan:

- _"Bagaimana membuat sistem yang pasti gagal?"_
- _"Apa yang pasti akan kita sesali 2 tahun dari sekarang?"_

Daftar jawaban ini menjadi **checklist negatif** — daftar hal yang harus dihindari, bukan daftar fitur yang harus dicapai.

### 2.4 Feedback Loop Analysis (System Dynamics)

Setiap arsitektur memiliki **reinforcing loops** (menguatkan) dan **balancing loops** (menstabilkan):

| Loop Type   | Contoh Arsitektural                                                        | Tanda Bahaya                                      |
| ----------- | -------------------------------------------------------------------------- | ------------------------------------------------- |
| Reinforcing | Traffic naik → cache hit naik → latency turun → traffic lebih naik         | Cache stampede saat cache invalid                 |
| Balancing   | Error naik → circuit breaker trip → load turun → error turun               | Circuit breaker yang terlalu agresif → false trip |
| Delayed     | Queue depth naik → consumer scale up → 5 menit kemudian → over-provisioned | Biaya naik, tapi tidak ada yang sadar             |

**Deteksi:** Gambar causal loop diagram untuk setiap subsystem. Jika ada loop tanpa balancing mechanism, itu adalah **time bomb**.

---

## 3. Taxonomy of Architectural Flaws — Deep Dive

### 3.1 Structural Flaws

#### Connascence (Meilir Page-Jones, 1992)

Connascence adalah generalisasi dari coupling. Ada 9 tipe, dari yang lemah hingga kuat:

| Tipe                               | Definisi                                        | Contoh                                        | Severity      |
| ---------------------------------- | ----------------------------------------------- | --------------------------------------------- | ------------- |
| **Connascence of Name** (CoN)      | Komponen harus sepakat soal nama                | Rename method → compile error                 | Rendah        |
| **Connascence of Type** (CoT)      | Komponen harus sepakat soal tipe data           | `int` vs `long` di API                        | Rendah        |
| **Connascence of Meaning** (CoM)   | Komponen harus sepakat soal semantik            | `status=1` berarti "active" — tanpa konstanta | Sedang        |
| **Connascence of Position** (CoP)  | Komponen harus sepakat soat urutan              | Parameter function, tuple unpacking           | Sedang        |
| **Connascence of Algorithm** (CoA) | Komponen harus sepakat soal algoritma           | Hash yang sama di client & server             | Tinggi        |
| **Connascence of Execution** (CoE) | Komponen harus dieksekusi dalam urutan tertentu | `init()` sebelum `process()`                  | Tinggi        |
| **Connascence of Timing** (CoT)    | Komponen harus dieksekusi dalam timing tertentu | Race condition, timeout                       | Sangat Tinggi |
| **Connascence of Value** (CoV)     | Komponen harus sepakat soal nilai bersama       | Shared mutable state                          | Sangat Tinggi |
| **Connascence of Identity** (CoI)  | Komponen harus merujuk ke instance yang sama    | Singleton abuse, global session               | Sangat Tinggi |

**Aturan:** _"Connascence yang kuat harus dikurangi; connascence yang lemah harus ditingkatkan."_ Jika Anda menemukan CoI atau CoV di codebase, itu adalah **flaw kritis**.

#### Cyclomatic Complexity vs. Architectural Complexity

Cyclomatic complexity (McCabe) mengukur kompleksitas fungsi. Tapi arsitektur memerlukan **architectural complexity metrics**:

- **Afferent coupling (Ca):** Jumlah komponen yang bergantung pada modul ini. Ca tinggi = changing this module is dangerous.
- **Efferent coupling (Ce):** Jumlah komponen yang dimodul ini bergantung. Ce tinggi = this module is fragile.
- **Instability (I):** I = Ce / (Ca + Ce). I → 1 berarti modul tidak stabil (banyak dependensi keluar). I → 0 berarti modul sangat stabil (banyak yang bergantung padanya).
- **Abstractness (A):** Rasio abstract class/interface vs concrete class. A → 1 = sangat abstract, A → 0 = sangat concrete.
- **Distance from Main Sequence (D):** D = |A + I - 1|. D → 0 = modul seimbang. D → 1 = modul bermasalah (terlalu concrete & stabil, atau terlalu abstract & tidak stabil).

**Deteksi otomatis:** Gunakan tools seperti `jdepend` (Java), `pydep` (Python), atau `dependency-cruiser` (JS/TS) untuk menghitung metrik ini. Modul dengan D > 0.5 perlu direview.

### 3.2 Behavioral Flaws

#### Race Conditions & Data Races

**Data race** (level hardware/memory model) ≠ **race condition** (level logika bisnis):

- **Data race:** Dua thread mengakses lokasi memori yang sama, minimal satu write, tanpa synchronization. Dapat dideteksi oleh ThreadSanitizer, Helgrind.
- **Race condition:** Hasil program bergantung pada timing/urutan eksekusi thread. Bisa terjadi tanpa data race (misal: check-then-act pada distributed system).

**Contoh race condition arsitektural:**

```
Service A: baca saldo = $100
Service B: baca saldo = $100
Service A: tulis saldo = $50 (withdraw $50)
Service B: tulis saldo = $0  (withdraw $100)
→ Total withdrawn: $150, padahal saldo hanya $100
```

Ini adalah **Time-of-Check to Time-of-Use (TOCTOU)** flaw — sangat umum di arsitektur event-driven (lihat system-design.md Level 4).

#### Deadlock, Livelock, Starvation

| Fenomena               | Definisi                                                               | Deteksi                                                               |
| ---------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **Deadlock**           | A menunggu B, B menunggu A — permanen                                  | Thread dump analysis, wait-for graph cycle detection                  |
| **Livelock**           | A dan B saling bereaksi tapi tidak ada progress                        | Profiling: CPU usage tinggi tapi throughput nol                       |
| **Starvation**         | Satu thread tidak pernah mendapat resource                             | Monitoring: queue depth naik untuk thread tertentu                    |
| **Priority Inversion** | Thread low-priority memegang lock yang dibutuhkan thread high-priority | Real-time system monitoring, latency spike yang tidak bisa dijelaskan |

**Priority Inversion** adalah flaw yang sering terlewatkan. Contoh klasik: Mars Pathfinder 1997 — high-priority task ( komunikasi) menunggu low-priority task (meteorological) yang sedang di-preempt oleh medium-priority task. Solusi: **priority inheritance** atau **priority ceiling protocol**.

#### ABA Problem

ABA problem terjadi di lock-free programming dan distributed consensus:

```
Thread 1: baca pointer A
Thread 2: ubah A → B → A (pointer kembali ke A, tapi state berbeda)
Thread 1: CAS(A, expected=A, new=C) → SUKSES! (padahal state sudah berubah)
```

**Manifestasi arsitektural:** Dalam event sourcing (system-design.md Level 4), jika event stream di-_replay_ dan menghasilkan state yang identik secara surface tapi berbeda secara history, sistem bisa mengambil keputusan yang salah.

**Solusi:** Tagged pointers, version counters, atau **double compare-and-swap (DCAS)**.

### 3.3 Performance & Concurrency Flaws

#### False Sharing

False sharing terjadi ketika dua thread mengakses variabel berbeda yang berada di **cache line yang sama** (biasanya 64 byte). Meskipun variabelnya berbeda, CPU cache coherence protocol (MESI) memaksa invalidasi cache line, menyebabkan performance degradation yang drastis.

**Deteksi:**

- `perf c2c` (Linux) — cache-to-cache analysis
- Intel VTune — false sharing detector
- Visual Studio Profiler (Windows)

**Mitigasi:** Padding (`alignas(64)`), per-thread storage, atau struktur data cache-aware.

#### Memory Barriers & Reordering

Compiler dan CPU melakukan **instruction reordering** untuk optimasi. Tanpa memory barriers (fence), program multi-threaded bisa menghasilkan hasil yang "impossible" menurut sequential reasoning.

```cpp
// Thread 1           // Thread 2
x = 1;                if (y == 1)
y = 1;                    r = x;
```

Di atas, `r` bisa bernilai 0 meskipun secara logika seharusnya 1. Ini karena:

1. Compiler reordering: `y = 1` bisa dieksekusi sebelum `x = 1`
2. CPU store buffer: store ke `y` terlihat lebih cepat dari store ke `x`

**Deteksi:** Model checking dengan **TLA+** (Leslie Lamport). TLA+ memungkinkan verifikasi formal bahwa algoritma konkuren tidak memiliki race condition, deadlock, atau livelock — _sebelum_ kode ditulis.

#### Thundering Herd

Thundering herd terjadi ketika banyak proses/thread bangun bersamaan untuk menangani event yang sama:

```
Cache miss → 1000 thread request ke database → database overload → timeout → retry → lebih overload
```

**Varian arsitektural:**

- **Cache stampede:** Cache expired, ribuan request ke backend bersamaan.
- **Leader election thundering herd:** Semua node mencoba jadi leader setelah leader mati.
- **Wake-up thundering herd:** `epoll_wait` / `kqueue` wake-up banyak thread.

**Mitigasi:**

- **Probabilistic early expiration:** Expire cache secara random sebelum TTL.
- **Mutex per cache key:** Hanya satu thread yang boleh regenerate cache.
- **Jitter:** Random delay sebelum retry (exponential backoff + jitter).

#### N+1 Query Problem — Arsitektural Lens

Anda sudah menyebut N+1 di system-design.md Level 2, tapi ini perlu **lensa arsitektural**:

N+1 bukan hanya ORM problem. Ini adalah **communication pattern flaw**:

```
Client → API Gateway → Service A (1 query)
                    → Service A (N queries untuk setiap item)
                    → Service B (N queries untuk setiap item)
```

Di microservices (system-design.md Level 3), N+1 bisa melintas service boundary. ORM tidak bisa mendeteksinya karena setiap query terlihat "valid" secara individual.

**Deteksi arsitektural:**

- Distributed tracing (Jaeger, Zipkin): lihat span count per request.
- Jika satu user request menghasilkan >50 database spans, ada N+1.
- **Fan-out metric:** Jumlah downstream calls per incoming request.

---

## 4. Distributed System Pathologies

### 4.1 Split-Brain — Beyond CAP

Anda menyebut split-brain di system-design.md Level 5. Mari kita perdalam:

Split-brain bukan hanya "dua node kira dirinya primary." Ini adalah **consensus failure** yang memiliki beberapa varian:

| Varian                              | Mekanisme                                               | Dampak                                       |
| ----------------------------------- | ------------------------------------------------------- | -------------------------------------------- |
| **Network partition + quorum loss** | Partisi membagi cluster, tidak ada quorum               | Kedua partisi accept writes → divergen       |
| **Clock skew**                      | Node dengan clock cepat "menang"                        | Data loss silent                             |
| **Zombie primary**                  | Primary mati tapi masih menerima write sebelum failover | Data yang ditulis ke zombie hilang           |
| **Partial partition**               | Hanya subset koneksi putus                              | Byzantine failure — node lihat dunia berbeda |

**Deteksi dini:**

- **Fencing token:** Setiap primary harus memegang token dari coordinator. Zombie primary tidak punya token valid.
- **Epoch numbers:** Setiap leadership term punya epoch. Request dengan epoch lama ditolak.
- **Lease-based coordination:** Primary hold lease. Jika lease expired, primary _harus_ stop serving.

### 4.2 Cascading Failure — Anatomy

Cascading failure (system-design.md Level 3 & 5) memiliki **fase inkubasi** yang bisa dideteksi:

```
Fase 1: Latency p99 naik 10% → masih dalam SLO
Fase 2: Timeout rate naik → retry logic aktif
Fase 3: Retry storm → downstream overload
Fase 4: Thread pool exhaustion → queue build-up
Fase 5: Circuit breaker trip → fallback degradation
Fase 6: Fallback juga overload → total collapse
```

**Metric kritis untuk deteksi fase 1–2:**

- **Latency histogram** (bukan hanya average): p99, p99.9, p99.99
- **Retry rate / original request ratio:** Jika retry > 20% dari original, sistem sedang dalam stress.
- **Queue depth / processing time ratio:** Jika queue depth tumbuh lebih cepat dari processing time, backpressure gagal.
- **Error budget burn rate:** (lihat system-design.md Level 7) — burn rate > 1x SLO = investigasi segera.

### 4.3 Backpressure Failure Modes

Backpressure (system-design.md Level 5) adalah mekanisme krusial, tapi implementasinya punya flaw modes:

| Failure Mode                 | Penyebab                                                 | Tanda                                |
| ---------------------------- | -------------------------------------------------------- | ------------------------------------ |
| **Backpressure drop**        | Producer mengabaikan backpressure signal                 | Memory usage naik tanpa bound        |
| **Backpressure oscillation** | Threshold terlalu sensitif                               | Throughput oscillating, tidak stabil |
| **Backpressure deadlock**    | Consumer backpressure → producer stop → consumer starved | Deadlock distributed                 |
| **Cascading backpressure**   | Service A backpressure → Service B backpressure → ...    | Latency spike chain                  |

**Solusi:** Credit-based flow control (bukan hanya pressure signal). Consumer mengirim "credit" ke producer: "saya bisa terima N item lagi." Producer tidak mengirim lebih dari credit yang dimiliki.

---

## 5. Framework Deteksi Formal

### 5.1 ATAM — Architecture Tradeoff Analysis Method

ATAM (SEI Carnegie Mellon) adalah metodologi sistematis untuk mengevaluasi arsitektur berdasarkan **trade-off**:

**Fase ATAM:**

1. **Presentasi bisnis:** Apa yang sistem harus capai?
2. **Presentasi arsitektur:** Diagram, komponen, koneksi.
3. **Identifikasi approach:** Teknik arsitektural yang dipakai (layering, redundancy, etc.)
4. **Generate quality attribute utility tree:**
   ```
   Utility
   ├── Performance
   │   ├── Latency (p99 < 200ms, priority: HIGH)
   │   └── Throughput (>10k req/s, priority: MEDIUM)
   ├── Availability
   │   ├── Uptime (99.99%, priority: HIGH)
   │   └── Recovery time (<5 min, priority: MEDIUM)
   └── Modifiability
       ├── Time to add feature (<2 weeks, priority: HIGH)
       └── Cost of change (low, priority: MEDIUM)
   ```
5. **Analyze architectural approaches:** Untuk setiap approach, tanyakan:
   - _"Apa risiko approach ini terhadap utility tree?"_
   - _"Apa trade-off yang dibuat?"_
   - _"Apa sensitivity point?"_ (parameter yang, jika berubah, mengubah hasil)
   - _"Apa trade-off point?"_ (keputusan yang mempengaruhi multiple quality attributes)
6. **Brainstorm and prioritize scenarios:** Stakeholder membuat skenario "what if."
7. **Analyze scenarios:** Arsitek menjelaskan bagaimana arsitektur menangani skenario.
8. **Present results:** Risiko, non-risiko, sensitivity points, trade-off points, risk themes.

**Output ATAM:** Daftar **risk** (kemungkinan masalah) dan **non-risk** (keputusan yang aman). Risiko di-prioritize berdasarkan likelihood dan impact.

### 5.2 Threat Modeling — STRIDE & PASTA

Threat modeling bukan hanya untuk security; pola pikirnya bisa dipakai untuk **semua jenis flaw**:

#### STRIDE (Microsoft)

| Kategori                   | Definisi                         | Contoh Arsitektural                                             |
| -------------------------- | -------------------------------- | --------------------------------------------------------------- |
| **S**poofing               | Menyamar sebagai entity lain     | Service tanpa mTLS — service B bisa berpura-pura jadi service A |
| **T**ampering              | Modifikasi data                  | Message queue tanpa integrity check                             |
| **R**epudiation            | Menyangkal telah melakukan aksi  | Event log tanpa audit trail                                     |
| **I**nformation Disclosure | Data bocor                       | API response yang over-fetching                                 |
| **D**enial of Service      | Membuat sistem tidak tersedia    | Rate limiting yang tidak ada                                    |
| **E**levation of Privilege | Akses lebih dari yang seharusnya | API gateway yang tidak validate scope                           |

**Proses:** Buat Data Flow Diagram (DFD) → identifikasi trust boundaries → terapkan STRIDE per elemen.

#### PASTA (Process for Attack Simulation and Threat Analysis)

PASTA lebih **risk-centric**:

1. Define objectives
2. Define technical scope (assets, data flow)
3. Application decomposition (sama seperti DFD)
4. Threat analysis (STRIDE, attack trees)
5. Vulnerability & weakness analysis (CVSS scoring)
6. Attack modeling (simulasi)
7. Risk & impact analysis (quantitative)

**Keunggulan PASTA:** Menghasilkan **risk score numerik** yang bisa diprioritaskan bersama business risk.

### 5.3 TLA+ — Formal Verification

TLA+ (Temporal Logic of Actions) memungkinkan verifikasi formal algoritma distributed system:

**Kapan pakai TLA+:**

- Consensus algorithm (Raft, Paxos custom implementation)
- Distributed transaction (Saga, 2PC custom)
- Lock-free data structures
- State machine yang kompleks

**Contoh flaw yang TLA+ bisa tangkap:**

- Race condition yang hanya muncul setelah 50+ step
- Deadlock yang memerlukan timing spesifik
- Liveness violation (sistem tidak pernah mencapai goal state)

**Resource gratis:**

- "Specifying Systems" by Leslie Lamport — [free PDF](https://lamport.azurewebsites.net/tla/book.html)
- Learn TLA+ — [learntla.com](https://learntla.com) (free)

---

## 6. Metodologi Review Praktis

### 6.1 Architecture Decision Records (ADR) — Review Lens

ADR bukan hanya dokumentasi; ADR adalah **audit trail untuk flaw detection**:

```markdown
## ADR-042: Menggunakan Event Sourcing untuk Order Processing

### Context

Order processing memerlukan audit trail lengkap.

### Decision

Gunakan event sourcing dengan Kafka.

### Consequences

- ✅ Audit trail sempurna
- ✅ Bisa replay state
- ⚠️ Eventual consistency (lihat system-design.md Level 4)
- ⚠️ Schema evolution complexity
- ❌ Team belum punya pengalaman dengan event sourcing

### Risk Register

- R1: Schema breaking change → mitigation: Avro schema registry
- R2: Event replay performance → mitigation: snapshot setiap 1000 event
- R3: Debugging complexity → mitigation: distributed tracing (Jaeger)

### Review Date

2026-09-01 (3 bulan setelah implementasi)
```

**Flaw detection via ADR:** Jika ADR tidak memiliki "Risk Register" atau "Review Date," keputusan tersebut belum cukup matang.

### 6.2 Dependency Analysis — Static Detection

Gunakan tools untuk memetakan dan menganalisis dependency:

| Tool                 | Bahasa | Fungsi                                                                     |
| -------------------- | ------ | -------------------------------------------------------------------------- |
| `dependency-cruiser` | JS/TS  | Circular dependency, orphan modules, forbidden imports                     |
| `jdepend`            | Java   | Package metrics (Ca, Ce, I, A, D)                                          |
| `pydeps`             | Python | Dependency graph, transitive dependency analysis                           |
| `SonarQube`          | Multi  | Code smell, cognitive complexity, duplication                              |
| `ArchUnit`           | Java   | Unit test untuk arsitektur ("package A tidak boleh depend pada package B") |

**Contoh ArchUnit (deteksi structural flaw via test):**

```java
@ArchTest
static final ArchRule layeredArchitecture = layeredArchitecture()
    .layer("Controller").definedBy("..controller..")
    .layer("Service").definedBy("..service..")
    .layer("Repository").definedBy("..repository..")
    .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
    .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller");
```

Jika test ini gagal, Anda memiliki **architectural drift** — kode sudah menyimpang dari intended architecture.

### 6.3 Chaos Engineering — Dynamic Detection

Chaos engineering (system-design.md Level 7) adalah **eksperimen** untuk membuktikan atau membantah hipotesis tentang resilience:

**Hipotesis yang harus diuji:**

1. _"Jika database primary mati, sistem failover ke replica dalam <30 detik."_
2. _"Jika latency downstream naik 3x, circuit breaker trip sebelum thread pool exhaustion."_
3. _"Jika 50% pod dihapus, auto-scaling recover dalam <2 menit."_

**Game Day Protocol:**

1. **Define steady state:** Metric normal (p99 latency, error rate, throughput).
2. **Form hypothesis:** "X tidak akan mengubah steady state."
3. **Introduce variables:** Kill pod, inject latency, partition network.
4. **Observe:** Apakah steady state terganggu? Apakah ada efek tak terduga?
5. **Learn & Fix:** Dokumentasikan flaw yang ditemukan.
6. **Automate:** Jadikan eksperimen ini sebagai continuous chaos test.

**Tools gratis:**

- Chaos Mesh (Kubernetes-native)
- Litmus (CNCF project)
- Gremlin Free Tier
- AWS Fault Injection Simulator (free tier)

---

## 7. Cognitive Skills — Latihan Praktis

### 7.1 Post-Mortem Analysis (Learning from Others)

Baca post-mortem publik dan identifikasi **architectural flaw** yang mendasari:

| Insiden                      | Flaw Arsitektural                      | Sumber            |
| ---------------------------- | -------------------------------------- | ----------------- |
| AWS S3 outage 2017           | Human error + cascading failure        | AWS blog          |
| Knight Capital $440M loss    | Deployment flaw + dead code activation | SEC filing        |
| Cloudflare 2019 regex outage | CPU exhaustion dari regex backtracking | Cloudflare blog   |
| GitHub 43s outage 2018       | Orchestrator split-brain               | GitHub blog       |
| Facebook 2021 BGP misconfig  | Lack of out-of-band management         | Multiple analyses |

**Latihan:** Untuk setiap post-mortem, identifikasi:

1. Flaw di level berapa? (principle, pattern, structural, behavioral, distributed)
2. Apakah flaw ini bisa dideteksi sebelum insiden? Dengan metode apa?
3. Apa second-order effect dari fix yang diusulkan?

### 7.2 Architecture Kata

Architecture Kata adalah latihan desain arsitektur dengan **constraint yang sengaja dibuat ketat**:

> **Kata:** "Desain sistem e-commerce yang harus handle 10M user, dengan tim 3 engineer, budget $500/bulan, dan harus launch dalam 2 bulan."

**Flaw yang biasanya muncul:**

- Over-engineering: microservices + Kubernetes + Kafka untuk 3 engineer.
- Under-engineering: monolith tanpa modularisasi → big ball of mud dalam 6 bulan.
- Ignoring constraints: "Budget tidak masalah" → padahal constraint adalah bagian dari soal.

**Latihan:** Setelah desain, swap role. Satu orang jadi "architectural flaw detector" yang harus menemukan 5 flaw dalam desain orang lain.

### 7.3 Code Review untuk Arsitektur

Code review biasanya fokus pada bug dan style. Tambahkan **architectural review checklist:**

```
□ Apakah PR ini memperkenalkan dependency baru? Ke mana?
□ Apakah PR ini mengubah interface public? Siapa yang ter-impact?
□ Apakah PR ini menambahkan state shared? Apakah thread-safe?
□ Apakah PR ini mengubah alur data? Apakah ada bottleneck baru?
□ Apakah PR ini menambahkan I/O blocking di hot path?
□ Apakah PR ini mengubah retry logic? Apakah ada thundering herd risk?
□ Apakah PR ini menambahkan eventual consistency? Apakah user experience di-handle?
```

---

## 8. Integration Map — Menghubungkan ke system-design.md

| Dokumen Ini                                  | system-design.md Level | Hubungan                                                         |
| -------------------------------------------- | ---------------------- | ---------------------------------------------------------------- |
| Connascence, Structural Metrics              | Level 0–1              | Deteksi principle/pattern violation sebelum jadi structural flaw |
| Race conditions, ABA, False Sharing          | Level 2–3              | Behavioral flaws di monolith & microservices                     |
| Split-brain, Cascading failure, Backpressure | Level 3–5              | Distributed pathologies yang belum dideteksi                     |
| ATAM, STRIDE, TLA+                           | Level 6–7              | Framework formal untuk menemukan flaw sebelum implementasi       |
| Chaos Engineering, ADR Review                | Level 7                | Metodologi praktis untuk validasi resilience                     |
| Post-mortem, Architecture Kata               | Semua level            | Latihan kognitif untuk mengasah "nose for flaws"                 |

---

## 9. Referensi Gratis & Research-Level

| Sumber                                                     | Topik                             | Format                   |
| ---------------------------------------------------------- | --------------------------------- | ------------------------ |
| "Designing Data-Intensive Applications" (Martin Kleppmann) | Distributed system fundamentals   | Buku (bab gratis di web) |
| "Site Reliability Engineering" (Google)                    | SLI/SLO, error budget, monitoring | Buku (free online)       |
| "Building Secure and Reliable Systems" (Google)            | Threat modeling, resilience       | Buku (free online)       |
| "Specifying Systems" (Leslie Lamport)                      | TLA+ formal verification          | Buku (free PDF)          |
| SEI ATAM Methodology                                       | Architecture evaluation           | Technical Report (free)  |
| Microsoft Threat Modeling Tool                             | STRIDE implementation             | Software (free)          |
| Chaos Engineering Book (Casey Rosenthal)                   | Chaos engineering principles      | O'Reilly Free Report     |
| InfoQ Architecture & Design                                | Case studies, post-mortems        | Artikel (free)           |
| ACM Queue Magazine                                         | Research-level system design      | Artikel (free)           |
| USENIX ;login:                                             | Industry best practices           | Newsletter (free)        |

---

_Architectural Flaw Detection | Mental Models, Taxonomy, and Methodologies · Radar untuk Arsitektur yang Sudah Ada, Sedang Dibangun, dan Akan Dibangun_
