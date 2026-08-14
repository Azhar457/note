---
tags:
  - hierarchy
  - cross-cutting
  - failure
  - resilience
  - fault-tolerance
  - chaos
aliases:
  - Failure Modes Hierarchy
  - Resilience Layer Map
  - Fault Taxonomy
  - Failure is Not an Option
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# ⚡ Failure Modes & Resilience — Dari Bit Flip ke Bencana Sistemik

> [!tip] Setiap sistem — digital, biologis, sosial — akan gagal. Yang membedakan adalah **seberapa cepat ia pulih**. Catatan ini memetakan **8 lapisan kegagalan** dari bit-flip di level transistor hingga catastrophic cascade di level society, dengan klasifikasi failure mode, pattern mitigasi (retry, circuit breaker, bulkhead, chaos), dan analogi lintas domain (hukum, kedokteran, teknik).

---

## Daftar Isi

1. [[#1. Premise — Failure Adalah State Default]]
2. [[#2. Eight-Layer Failure Hierarchy]]
3. [[#3. Layer F0 — Physical Fault]]
4. [[#4. Layer F1 — Logic & State]]
5. [[#5. Layer F2 — Resource Contention]]
6. [[#6. Layer F3 — Communication Failure]]
7. [[#7. Layer F4 — Design Flaw]]
8. [[#8. Layer F5 — Human Error]]
9. [[#9. Layer F6 — Organizational Failure]]
10. [[#10. Layer F7 — Systemic Cascade]]
11. [[#11. Resilience Patterns by Layer]]
12. [[#12. Analogi Lintas Domain]]
13. [[#13. Cross-Reference ke Vault]]
14. [[#References]]

---

## 1. Premise — Failure Adalah State Default

Di sistem yang cukup besar, **failure bukan pengecualian — ia adalah keadaan normal**. Sistem harus dirancang untuk gagal dengan graceful.

**Hukum distribusi kegagalan:**
```
┌────────────────────────────────────────────┐
│                                            │
│  Failure Rate                              │
│    ^                                       │
│    │  ╱╲        ╱╲                         │
│    │ ╱  ╲      ╱  ╲                        │
│    │╱    ╲    ╱    ╲                       │
│    │      ╲  ╱      ╲                      │
│    │       ╲╱        ╲                     │
│    └───────────────────────────→ Time      │
│      Infant    Useful         Wear-out     │
│      Mortality Life            Phase       │
│                                            │
│    Bathtub Curve (reliability engineering) │
└────────────────────────────────────────────┘
```

---

## 2. Eight-Layer Failure Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ F7 │ Systemic Cascade                                      │ ← society-level
├────────────────────────────────────────────────────────────┤
│ F6 │ Organizational Failure                                │
├────────────────────────────────────────────────────────────┤
│ F5 │ Human Error                                           │
├────────────────────────────────────────────────────────────┤
│ F4 │ Design Flaw                                           │
├────────────────────────────────────────────────────────────┤
│ F3 │ Communication Failure                                 │
├────────────────────────────────────────────────────────────┤
│ F2 │ Resource Contention                                   │
├────────────────────────────────────────────────────────────┤
│ F1 │ Logic & State                                         │
├────────────────────────────────────────────────────────────┤
│ F0 │ Physical Fault                                        │ ← bit/transistor
└────────────────────────────────────────────────────────────┘
```

---

## 3. Layer F0 — Physical Fault

### 3.1 Failure Mode

| Mode | Contoh | Frekuensi |
|------|--------|:---------:|
| Bit flip (cosmic ray / alpha particle) | DRAM soft error | 1 per 10⁹ hours per MB |
| Electromigration | Chip wear out (5-10 tahun) | Deterministic via MTBF |
| Gate oxide breakdown | Transistor failure | Statistik |
| Thermal runaway | CPU/GPU overheating | Densitas daya meningkat |
| Connector failure | Loose cable, corrosion | Mekanis |
| Power supply failure | Capacitor aging | Batch defect |

### 3.2 Mitigasi

| Mitigasi | Contoh |
|----------|--------|
| ECC memory | SECDED (Single Error Correct, Double Error Detect) |
| CRC / checksum | Merkle tree (ZFS), SHA-256 |
| RAID | R0 (striping), R1 (mirror), R5 (parity), R6 (dual parity) |
| Redundant power | N+1 PSU + UPS |

**Analogi kedokteran:** DNA repair mechanism — base excision repair memperbaiki mutasi.

---

## 4. Layer F1 — Logic & State

### 4.1 Failure Mode

| Mode | Contoh | Level |
|------|--------|:-----:|
| Race condition | TSA/TOCTOU | Thread/proses |
| Deadlock | Lock ordering | Sinkronisasi |
| Data race | Unsync'd write | Memory |
| Null pointer | Uninitialized reference | Language |
| Buffer overflow | Stack/heap corruption | Memory safety |
| Logic error | Salah kondisi | Code |

### 4.2 Mitigasi

| Mitigasi | Contoh Tools |
|----------|--------------|
| Type safety | Rust, Haskell type system |
| Static analysis | Clippy, ESLint, SonarQube |
| Formal verification | TLA+, Promela (Spin), Dafny |
| Property-based testing | Hypothesis, QuickCheck |
| Immutable data | Persistent data structures |

---

## 5. Layer F2 — Resource Contention

### 5.1 Failure Mode

| Mode | Contoh | Sumber |
|------|--------|--------|
| OOM | Memory exhaustion | Aplikasi memory leak |
| CPU starvation | Thundering herd | Auto-scaling slow |
| Disk full | Log rotasi mati | Monitoring gagal |
| File descriptor leak | Ephemeral port exhaustion | Connection leak |
| Connection pool drain | Database Query per second > pool | Traffic spike |

### 5.2 Mitigasi

| Mitigasi | Contoh Implementasi |
|----------|---------------------|
| Rate limiting | Token bucket, leaky bucket |
| Circuit breaker | Hystrix, Resilince4j |
| Bulkhead | Thread pool separation |
| Backpressure | Reactive streams, Kafka consumer lag |
| Graceful degradation | Fallback to stale data |

---

## 6. Layer F3 — Communication Failure

### 6.1 Failure Mode

| Mode | Contoh | Protokol |
|------|--------|----------|
| Packet loss | WiFi interference | TCP retransmit |
| Timeout | DNS resolv > 30s | HTTP 504 |
| Retransmission storm | TCP incast | Many-to-one pattern |
| Network partition | Switch failure | CAP theorem (P) |
| DNS failure | TTL mismatch | Cache stale |

### 6.2 Fallacies of Distributed Computing

1. The network is reliable (❌)
2. Latency is zero (❌)
3. Bandwidth is infinite (❌)
4. The network is secure (❌)
5. Topology doesn't change (❌)
6. There is one administrator (❌)
7. Transport cost is zero (❌)
8. The network is homogeneous (❌)

---

## 7. Layer F4 — Design Flaw

### 7.1 Failure Mode

| Mode | Contoh |
|------|--------|
| Feature interaction | Fitur A + Fitur B hasilnya C yang tidak diinginkan |
| Boundary condition | Tahu 2024 != Leap year |
| Error handling bypass | catch (Exception) — tapi tetap crash |
| Single point of failure | Database dalam monolith |
| No circuit breaker | Cascade restart |

### 7.2 Mitigasi

- **Architecture review** — ADR, decision log
- **Threat modeling** — STRIDE, attack trees
- **Chaos engineering** — Litmus, Chaos Mesh, Gremlin
- **Design-for-failure** — setiap komponen harus bisa down tanpa total

**Analogi kimia:** Katalisator yang salah bisa memicu reaksi berantai (runaway reaction) — desain reaktor harus punya emergency quench.

---

## 8. Layer F5 — Human Error

### 8.1 Failure Mode

| Mode | Contoh | Reason kategori |
|------|--------|----------------|
| Slip | Typo `rm -rf /` bukan `rm -rf ./` | Skill-based |
| Lapse | Lupa commit sebelum deploy | Memory-based |
| Mistake | Salah paham requirement | Rule/knowledge-based |
| Violation | Skip review karena deadline | Normative |

**Statistik:** 70-90% security incident disebabkan human error.

### 8.2 Mitigasi

| Strategi | Contoh |
|----------|--------|
| Automation | CI/CD reduce manual step |
| Guardrails | `alias rm='trash'`, require second approval |
| Blameless postmortem | Analisis sistem, bukan individu |
| Training | Regular fire drill, red/purple team |

---

## 9. Layer F6 — Organizational Failure

### 9.1 Failure Mode

| Mode | Contoh |
|------|--------|
| Conway's Law | Tim silo → arsitektur monolith |
| Misaligned incentives | Engineering gamified → technical debt |
| No blameless culture | Incident hidden → tidak ada learning |
| Budget misallocation | Security underfunded → breach |

### 9.2 Mitigasi

- **Retrospectives** — structured learning
- **Blameless culture** — yang salah adalah proses, bukan orang
- **Clear incident command system** — OODA loop
- **Psychological safety** — laporkan error tanpa takut

---

## 10. Layer F7 — Systemic Cascade

### 10.1 Karakteristik

| Mode | Contoh |
|------|--------|
| Domino effect | Single cloud AZ down → major services |
| Cascading failure | Database overload → semua service timeout |
| Panic cascade | Social media rumor → bank run |
| Black swan | COVID supply chain |
| Common cause | Power outage di DC → semua host down |

### 10.2 Contoh

**2008 AWS US-EAST-1:** Single AZ down → EBS stuck → user reporting widespread → cascade panic.

**Mitigasi:**
- Multi-region deployment
- Bulkhead service isolation
- Runtime redundancy
- Capacity buffer (lean vs slack)

---

## 11. Resilience Patterns by Layer

| Layer | Pattern | Tooling |
|:-----:|---------|---------|
| F0 | ECC, RAID, redundant power | ZFS, mdadm, ECC DIMM |
| F1 | Static analysis, formal proof | Clippy, TLA+, Dafny |
| F2 | Rate limit, circuit breaker | Hystrix, Alibaba Sentinel |
| F3 | Retry, timeout, backoff | Resilience4j, exponential backoff |
| F4 | Architecture review, chaos | Chaos Mesh, Litmus |
| F5 | Automation, guardrails | CI/CD, approval gates |
| F6 | Blameless culture, retro | Incident trace |
| F7 | Multi-region, bulkhead | Geographic redundancy |

---

## 12. Analogi Lintas Domain

| Failure Layer | Analogi Kedokteran | Analogi Hukum |
|:-------------:|--------------------|---------------|
| F0 (bit flip) | DNA mutasi | Dokumen corrupt |
| F1 (logic) | Cacat lahir | Kontradiksi pasal |
| F2 (resource) | Gagal ginjal | Court overload |
| F3 (comm) | Stroke | Putusan tidak tersampaikan |
| F4 (design) | Malpraktik (desain rumah sakit) | Cacat undang-undang |
| F5 (human) | Salah diagnosis | Salah tafsir kontrak |
| F6 (org) | Silo RS → pasien salah rujuk | Tumpang tindih yurisdiksi |
| F7 (systemic) | Pandemi | Negara gagal |

---

## 13. Cross-Reference ke Vault

| Layer | Catatan Vault Terkait |
|:-----:|-----------------------|
| **F0-F1** | [[00_Atlas/hierarchy-digital-plumbing]] — Level 1-3: Aritmetika, parsing, encoding |
| **F1** | [[00_Atlas/hierarchy-software-engineering-paradigm]] — Design pattern, TDD |
| **F2** | [[00_Atlas/hierarchy-systems-architecture-evolution]] — Circuit breaker in microservices |
| **F3** | [[00_Atlas/hierarchy-kernel-bypass-networking]] — Zero-copy mitigasi latency |
| **F4** | [[hierarchy-ai-levels]] — AI failure mode di L5+ |
| **F5** | [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] — Human error vs security |
| **F6-F7** | [[00_Atlas/hierarchy-infrastructure-evolution]] — Multi-region infra |

---

## References

1. Laprie, J.C. *"Dependability: Basic Concepts and Terminology."* Springer, 1992.
2. Littlewood, B. & Strigini, L. *"Software Reliability and Dependability."* 2000.
3. Amdahl, G. *"Validity of the Single Processor Approach."* AFIPS, 1967.
4. Denning, P.J. *"Fault Tolerant Systems."* CACM, 1976.
5. Ford, N. et al. *"Building Evolutionary Architectures."* O'Reilly, 2017.
6. Nygard, M. *"Release It! Design and Deploy Production-Ready Software."* 2007.
7. DeMarco, T. & Lister, T. *"Peopleware: Productive Projects and Teams."* 1987.
8. Vaughan, D. *"The Challenger Launch Decision."* 1996.
9. Taleb, N.N. *"The Black Swan."* 2007.
10. Parnas, D. *"Designing Software for Ease of Extension and Contraction."* 1978.
