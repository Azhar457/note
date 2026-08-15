---
title: 'Regenerate: jalanin script audit hierarchy → deepdive'
tags:
- atlas
- hierarchy
- gap-analysis
- knowledge-management
- crosswalk
aliases:
- Hierarchy Crosswalk
- Hierarchy Gap Map
- Neraca Hierarchy
created: 2026-07-26
updated: 2026-07-26
status: pending
cssclasses:
  - wide-table
  
---


> [!abstract] Peta Koneksi Hierarchy → Library Deepdive
> Catatan ini memetakan semua file `hierarchy-*.md` di 00_Atlas ke deepdive yang ada di 01_Library. Hierarchy **tanpa** deepdive adalah prioritas catatan baru. Hierarchy **dengan** deepdive tapi stale/low-coverage perlu update. Warna: ✅ aman, ⚠️ partial, ❌ belum ada.

---

## Ringkasan

| Status | Jumlah |
|:-------|:------:|
| ✅ Ada deepdive match | 15 |
| ⚠️ Partial / nama beda | 3 |
| ❌ Belum ada deepdive | 12 |
| **Total hierarchy** | **30** |

---

## ✅ Hierarchy dengan Deepdive (15)

| Hierarchy | Deepdive | Folder | Coverage |
|:----------|:---------|:-------|:--------:|
| `hierarchy-biometrics` | [[cryptography-biometrics]] | Cyber_Security | ✅ penuh |
| `hierarchy-cloud-infrastructure` | [[cloud-infrastructure]] | AI_Systems | ✅ penuh |
| `hierarchy-cryptography` | [[quantum-cryptography-deepdive]], [[quantum-cryptography-roadmap]] | Quantum_Crypto | ✅ penuh |
| `hierarchy-data-recovery` | [[data-recovery]] | Data_Forensics | ✅ penuh |
| `hierarchy-embedded-systems` | [[embedded-systems]] | AI_Systems | ✅ penuh |
| `hierarchy-hardware-hacking` | [[hardware-hacking-re]] | Cyber_Security | ✅ penuh |
| `hierarchy-network-security` | [[network-security]] | Cyber_Security/Network_Threats | ✅ penuh |
| `hierarchy-offensive` | [[offensive-security]] | Cyber_Security | ✅ penuh |
| `hierarchy-reverse-engineering` | [[firmware-reverse-engineering-deepdive]] | Firmware_RE | ✅ penuh |
| `hierarchy-side-channel` | [[side-channel-analysis]] | Cyber_Security | ✅ penuh |
| `hierarchy-threat-modeling` | [[threat-modeling-deepdive]] | Cyber_Security | ✅ penuh |
| `hierarchy-waf-reverse-proxy` | [[waf-reverse-proxy-deepdive]] | Cyber_Security/WAF_Reverse_Proxy | ✅ penuh |
| `hierarchy-wireless` | [[wireless-security-deepdive]], [[wireless-pentesting-aircrack-ng-wpa3-practical]] | Wireless_Security | ✅ penuh |
| `hierarchy-search` | [[semantic-search-pipeline]], [[hybrid-search-vector-keyword]] | Machine_Learning, AI_Systems | ✅ multi |
| `hierarchy-endpoint-security` | [[endpoint-security]], [[endpoint-detection-playbook]], [[endpoint-security-freeware]] | Cyber_Security/Endpoint_Detection | ✅ multiple |

---

## ⚠️ Hierarchy dengan Partial Match (3)

| Hierarchy | Deepdive Mirip | Masalah | Prioritas |
|:----------|:---------------|:--------|:---------:|
| `hierarchy-identity-trust` | [[identity-and-access-management]] | IAM aja, belum cover trust model / PKI / federation | **Sedang** — perlu catatan trust architecture terpisah |
| `hierarchy-malware-analysis` | [[malware-analysis-reverse-engineering-playbook]] | Playbook fokus ke RE, kurang coverage malware behavior / sandbox / static analysis chain | **Sedang** — perlu deepdive malware analysis dedicated |
| `hierarchy-supply-chain-security` | [[software-supply-chain-security]], [[software-supply-chain-security-deepdive]] | Udah lumayan dalam, tapi hierarchy baru hari ini mungkin perlu sync wikilink | **Rendah** — update wikilink aja |

---

## ❌ Hierarchy Tanpa Deepdive (12) — Prioritas Catatan Baru

| Hierarchy                            | Domain                 | Kenapa Perlu                                                                                                                                                                   |                     Prioritas                      |     |
| :----------------------------------- | :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------: | --- |
| `hierarchy-abstraction-layers`       | Fundamentals           | Abstraction layers adalah fondasi thinking framework — OSI layers, API gates, HAL, ABI. Fundamen buat semua hierarchy lain                                                     |                     **Tinggi**                     |     |
| `hierarchy-ai-levels`                | AI_Systems             | Levels of AI (rule-based → agentic → AGI). Partial overlap sama [[00_Atlas/hierarchy-llm-ai-systems]] di AI_Systems, tapi belum ada deepdive dedicated                                  |                     **Tinggi**                     |     |
| `hierarchy-concurrency-consensus`    | Systems / Distributed  | Concurrency models (actor, CSP, STM) + consensus (Raft, Paxos, PBFT).                                                                                                          | **Tinggi** — kritikal buat [[distributed-systems]] |     |
| `hierarchy-database-storage-systems` | Data_Engineering       | Ada [[database-internals-indexing-mvcc]] dan [[database-schema-sharding-replication]], tapi belum ada catatan yang nyambungin hierarchy → implementasi                         |                     **Sedang**                     |     |
| `hierarchy-failure-modes-resilience` | Systems / SRE          | Failure modes + resilience patterns (circuit breaker, bulkhead, chaos engineering). Ada [[security-chaos-engineering]] tapi fokus security, bukan infra                        |                     **Tinggi**                     |     |
| `hierarchy-it-domain`                | Infrastructure         | IT domain landscape — helpdesk → infra → cloud → security. Mungkin overlap sama [[infrastructure-administrator]]                                                               |             **Rendah** — evaluate dulu             |     |
| `hierarchy-memory-storage`           | Systems                | Memory hierarchy (L1–L3 cache, NUMA, virtual memory, storage tiers). Ada [[memory-forensics-volatility-deepdive]] tapi itu forensik, bukan arsitektur                          |                     **Sedang**                     |     |
| `hierarchy-operating-systems`        | Systems / Fundamentals | OS internals — scheduler, VMM, syscall, IPC. Ada [[ostep-three-easy-pieces]] (book summary) dan beberapa linux notes, tapi belum ada deepdive dedicated                        |                     **Tinggi**                     |     |
| `hierarchy-osint-rf`                 | OSINT / SIGINT         | OSINT + RF spectrum. Ada [[osint]] (umum) dan [[military-sigint-deepdive]] (SIGINT), tapi gap di RF exploitation                                                               |                     **Sedang**                     |     |
| `hierarchy-programming-language`     | Software_Engineering   | PL theory — type systems, memory models, FFI, runtime vs compiled. Ada [[hierarchy-compiler-design]] dan [[compiler-design-deepdive]] (tentang compiler, bukan PL secara umum) |                     **Tinggi**                     |     |
| `hierarchy-recursive-ring-deepdive`  | AI_Systems             | Catatan ini **adalah** deepdive-nya sendiri — recursive self-improvement rings. Tapi belum ada link ke [[meta-agent-orchestration]]                                            |            **Rendah** — update wikilink            |     |
| `it-domain`                          | Infrastructure         | Gap: high it-domain                                                                                                                                                            |                                                    |     |

> **Catatan:** `hierarchy-recursive-ring-deepdive` bukan hierarchy murni — dia adalah deepdive tentang recursive improvement. Nama file misleading. Mungkin perlu rename atau bikin hierarchy terpisah.

---

## Tindak Lanjut — Besok

### Priority 1 — Tinggi (minggu ini)

1. **`hierarchy-abstraction-layers-deepdive`** — layer thinking framework: OSI, HAL, ABI, API gates, virtualisation boundaries. Hubungin ke `hierarchy-it-domain`, `hierarchy-operating-systems`, `hierarchy-network-security`.
2. **`hierarchy-concurrency-consensus-deepdive`** — actor model vs CSP vs STM, Raft vs Paxos vs PBFT, distributed consensus di WAN.
3. **`hierarchy-operating-systems-deepdive`** — kernel space vs user space, scheduler (CFS, O(1), EDF), virtual memory, IPC mechanisms.
4. **`hierarchy-programming-language-deepdive`** — type system taxonomy (Hindley-Milner, gradual, dependent), memory safety models (Rust borrow, GC tracing, ARC), FFI boundary.

### Priority 2 — Sedang (2 minggu)

5. **`hierarchy-ai-levels-deepdive`** — dari rule-based → ML → agentic → AGI. Mapping ke [[00_Atlas/hierarchy-llm-ai-systems]].
6. **`hierarchy-failure-modes-resilience-deepdive`** — circuit breaker, bulkhead, graceful degradation, chaos engineering patterns.
7. **`hierarchy-identity-trust-deepdive`** — trust models (web of trust, PKI, SPKI/SDSI), identity federation (SAML, OIDC), ZKP identity.
8. **`hierarchy-malware-analysis-deepdive`** — static analysis chain (disasm → decompile → CFG reconstruction), dynamic sandboxing, YARA rules engineering.
9. **`hierarchy-memory-storage-deepdive`** — cache hierarchy, memory pooling, storage tiers (NVMe → SSD → HDD → tape), CXL.mem.
10. **`hierarchy-osint-rf-deepdive`** — RF OSINT tools (rtl_433, dump1090, multimon-ng), spectrum analysis, direction finding.

---

## Cara Update Catatan Ini

```bash
# Regenerate: jalanin script audit hierarchy → deepdive
# 00_Atlas/hierarchy-*.md → cari match di 01_Library/**/*.md
# Output: markdown table + gap list
```

Script ada di `03_Resources/scripts/` — atau jalanin manual:

```bash
for h in 00_Atlas/hierarchy-*.md; do
  name=$(basename "$h" .md | sed 's/hierarchy-//')
  match=$(find 01_Library -maxdepth 3 -type f -iname "*${name}*" ! -path "*/hierarchy-*" 2>/dev/null)
  if [ -z "$match" ]; then echo "❌ $name"; else echo "✅ $name"; fi
done
```

---

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[curriculum-mapping]] | Semua hierarchy ini bagian dari curriculum structure |
| [[master-index]] | Root entry — crosswalk ini perlu di-link dari master index |
| [[master-index-audit-broken-wikilink-sweep]] | SOP audit wikilink — jalanin setelah bikin catatan baru |

audited
---
