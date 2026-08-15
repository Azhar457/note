---
title: Tentang Vault — Azhar's Notes
tags:
- vault
- obsidian
- documentation
- knowledge-base
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---


# Tentang Vault — Azhar's Notes

> Vault Obsidian "Azhar's Notes" adalah knowledge base personal yang terstruktur dalam 3 bagian utama: 00_Atlas (hierarki konsep), 01_Library (dokumen teknis per domain), 02_SOPs (prosedur operasional), dan 03_Resources (referensi & arsip).

## Struktur Vault

| Folder | Isi | Contoh |
|--------|-----|--------|
| **00_Atlas/** | Hierarki konsep (64 note) | cybersecurity-defense-architecture, threat-modeling |
| **01_Library/** | Dokumen teknis per domain (100+ note) | Cyber_Security, AI_Systems, Quantum_Crypto |
| **02_SOPs/** | Prosedur operasional | hardening-setup, hpa-exorcism |
| **03_Resources/** | Referensi & arsip | picoctf-beginner-guide, chat-logs-phase-1 |

## Kategori Utama di 01_Library

| Domain | Topik | Jumlah |
|--------|-------|--------|
| **Cyber_Security** | Attack/defense, red team, web, network | 60+ |
| **AI_Systems** | LLM, agent, RAG, ML | 20+ |
| **Quantum_Crypto** | PQC, QKD, quantum threat | 10+ |
| **Systems_Architecture** | Cloud, infra, kernel | 15+ |
| **military-and-intelligence-tools** | OSINT, intel, spyware | 5+ |

## Konvensi Penulisan

1. **Frontmatter**: YAML (title, tags, created, updated, status, cssclasses)
2. **Bahasa**: Indonesia dengan istilah teknis English (MITRE, CVE, SIEM)
3. **Format note teknis**: Ringkasan > Daftar Isi > Isi (tabel/matrix) > Koneksi ke Vault > Referensi
4. **Attack perspective**: File `attack-*.md` berisi versi red-team/adversary POV
5. **Link**: Obsidian `wikilink` untuk cross-reference

## Sumber & Referensi Utama

| Sumber | Penggunaan |
|--------|-----------|
| **MITRE ATT&CK** | Framework TTP serangan |
| **OWASP Top 10** | Web vulnerability classification |
| **NIST CSF** | Defense architecture framework |
| **CVE Database** | Kerentanan konkret |
| **arXiv / Paper** | Research akademis (AI, crypto) |

## Koneksi ke Vault Lain

- **Graphify**: Knowledge graph index di `graphify-out/`
- **Evidence**: Threat-intel raw output di `/mnt/data_d/Documents/Wide Note/Evidence/`
- **TESTFROMDARKNET**: Koleksi sampel malware/RAT di `/home/jars/TESTFROMDARKNET/`

## FAQ

**Q: Siapa pemilik vault?**
A: Azhar (Max) — nama di index.md. Fokus: cybersecurity, AI, red team research.

**Q: Bagaimana cara menambah note baru?**
A: Ikuti konvensi frontmatter + struktur. Subfolder sesuai kategori. Prefix `attack-` untuk perspektif adversary.

**Q: Bagaimana cara menjalankan graph update?**
A: `/graphify` command → `graphify update .` untuk AST-only incremental.

**Q: Apa standar word count untuk note?**
A: Target minimum 1000 kata untuk note konten. File `_index.md` (struktural) dikecualikan.

**Q: Bagaimana format attack-*.md?**
A: Frontmatter (YAML) → Threat Model → MITRE ATT&CK mapping → CVE Intelligence → Kill Chain → Tool Stack → OpSec → References. Bahasa Indonesia + istilah teknis English.

**Q: Bagaimana cara mencari note di vault?**
A: Obsidian search (Ctrl+Shift+F), atau `graphify query "pertanyaan"` di terminal.

**Q: Apa itu graphify-out?**
A: Knowledge graph yang di-generate dari AST source. Gunakan `graphify query`, `graphify path`, `graphify explain` untuk navigasi cepat.

## Referensi
- Obsidian — https://obsidian.md/
- Quartz (publisher) — https://quartz.jzhao.xyz/
- Graphify — https://github.com/graphify
- MITRE ATT&CK — https://attack.mitre.org/
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework


## Detail Kategori 01_Library

### Cyber_Security

Subfolder utama: Web_Security, Endpoint_Detection, Network_Threats, Mobile_Security, WAF_Reverse_Proxy, Threat_Intel_Privacy, IAM, Supply_Chain_Security, Web_App_Purple.

Topik utama: WAF evasion, OWASP CRS, APT C2/DNS, supply chain, AD/Windows, cloud IAM, mobile security, firmware RE, eBPF kernel, covert channel, SIEM bypass, zero trust, ICS/SCADA, automotive CAN, exploit development, blockchain, side channel, cognitive security, digital privacy, ISP surveillance.

### AI_Systems

Subfolder utama: Machine_Learning, Swarm_AI.

Topik utama: LLM security red-teaming, hallucination mitigation, transformer deepdive, attention mechanism, RNN vs LSTM vs Transformer, semantic search pipeline, hybrid search vector+keyword, computer vision, deepfake detection, adversarial ML, reinforcement learning, cosine similarity, binary quantization Hamming popcount.

### Quantum_Crypto

Topik utama: post-quantum TLS implementation, quantum cryptography stack, PQC (Kyber/Dilithium), HNDL threat, Shor algorithm, Grover algorithm, QKD.

### Systems_Architecture

Topik utama: homelab Proxmox, Linux performance debugging, systems architecture evolution, infrastructure evolution, kernel bypass networking.

### Other

- **Algorithms_Math**: SICP (Abelson & Sussman), formal verification
- **Software_Engineering**: compiler design, refactoring (Martin Fowler), Rust web framework, knowledge log
- **Platform_Technologies**: Kubernetes roadmap, package managers
- **DevOps**: CI/CD pipeline, eBPF runtime security
- **Data_Engineering**: data engineering pipeline, data lifecycle
- **Firmware_RE**: firmware RE roadmap
- **Infrastructure**: offline internet Indonesia, homelab

## Attack-Overlay Coverage

| Layer | Attack File | Status |
|-------|-------------|--------|
| 00_Atlas | 53 attack-hierarchy-*.md | 100% covered |
| 01_Library/Cyber_Security | 25+ attack-*.md | Expanded |
| 01_Library/AI_Systems | attack-llm-security-red-teaming.md | Expanded |
| 01_Library/Container_K8s | attack-container-k8s.md | Expanded |
| 01_Library/Quantum_Crypto | attack-quantum-pqc.md | Expanded |
| 01_Library/Systems_Architecture | attack-systems-architecture.md | Expanded |
| 01_Library/Machine_Learning | attack-adversarial-ml.md | Expanded |
| 01_Library/military-and-intelligence-tools | attack-military-intel.md | Expanded |

Total: 92 attack-*.md file, 9.122 baris, 458 KB, 23 subfolder.

## Maintenance

- **Cron**: vault-nightly (upgrade profile, 0 22:00), vault-dark (red-team profile, 0 10,22:00)
- **Mojibake fix**: 78 file diperbaiki (252 karakter rusak dihapus), 0 tersisa
- **Word count**: Semua content file >= 1000 kata (kecuali _index.md struktural)
- **Graph**: `graphify update .` setelah modifikasi code/struktur


## Sejarah & Evolusi Vault

Vault "Azhar's Notes" dimulai sebagai koleksi note personal untuk riset cybersecurity dan AI. Seiring waktu, struktur berkembang menjadi knowledge base formal dengan 3 bagian: Atlas (hierarki konsep), Library (dokumen teknis), dan SOPs/Resources.

### Fase Pengembangan

| Fase | Aktivitas | Output |
|------|-----------|--------|
| **Fase 1** | Setup Obsidian + Quartz | Vault dasar, publish |
| **Fase 2** | Audit 64 Atlas hierarchy | Semua status pending |
| **Fase 3** | Attack-overlay (92 file) | Red-team/adversary POV per kategori |
| **Fase 4** | Expand stub ke deepdive | 38 stub di-expand |
| **Fase 5** | Expand content < 1000 kata | Note content semua >= 1000 |
| **Fase 6** | Mojibake fix | 78 file, 252 karakter rusak dihapus |
| **Fase 7** | Bahasa Indonesia | Full-English diganti ke ID + istilah EN |

### Statistik Vault

| Metrik | Nilai |
|--------|-------|
| Total .md file | 527 |
| Attack file | 92 |
| Content file | ~100 |
| Index file | ~45 |
| Total baris (attack) | 9.122 |
| Total size (attack) | 458 KB |
| Subfolder | 23 |

### Konvensi Bahasa

Body text Bahasa Indonesia. Istilah teknis tetap English: MITRE, CVE, SIEM, EDR, SOAR, OWASP, NIST, WAF, XSS, SQLi, SSRF, RCE, LLM, RAG, MCP, PQC, QKD, TLS, DNS, HTTP, API, RBAC, IAM, CI/CD, SBOM, SLSA.

### Tools & Integrasi

| Tool | Fungsi |
|------|--------|
| **Obsidian** | Editor utama, graph view, wikilink |
| **Quartz** | Publish ke web (static site) |
| **Graphify** | Knowledge graph AST index |
| **Maltego** | OSINT link analysis (eksternal) |
| **Hermes** | Agent orchestration, cron, memory |

audited
---
