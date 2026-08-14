---
title: "Browser Security and Exploitation Learning Roadmap \u2014 From SOP Bypass\
  \ to V8 Enclave Shellcode"
tags:
- browser-security
- vulnerability-research
- exploitation
- v8
- sandbox-escape
- roadmap
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
- callout
---


| Item | Detail |
|------|--------|
| **Summary** | Kurikulum 4 fase keamanan & eksploitasi browser: SOP/CSP → arsitektur sandbox & Mojo IPC → memori V8 → sandbox escape & shellcode. |




[[00_Atlas/hierarchy-offensive]] [[00_Atlas/hierarchy-threat-modeling]] [[00_Atlas/overview]]

> [!abstract] Ringkasan & Hubungan ke Vault
> Peramban web modern adalah salah satu permukaan serangan (*attack surface*) paling kompleks karena mengeksekusi kode tidak tepercaya dari internet di mesin lokal. Catatan ini menyediakan kurikulum terstruktur untuk mempelajari proteksi browser dan eksploitasi kerentanan memori, sebagai pasangan praktis dari berkas teoritis [[browser-security-exploitation-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Kebijakan Keamanan Web & Proteksi Dasar (SOP, CORS, CSP)](#2-fase-1-kebijakan-keamanan-web--proteksi-dasar-sop-cors-csp)
3. [Fase 2: Arsitektur Sandbox & Komunikasi IPC (Mojo)](#3-fase-2-arsitektur-sandbox--komunikasi-ipc-mojo)
4. [Fase 3: Eksplorasi Kerentanan Memori V8 (Type Confusion, UAF)](#4-fase-3-eksplorasi-kerentanan-memori-v8-type-confusion-uaf)
5. [Fase 4: Rekayasa Eksploitasi & Meloloskan Diri dari Sandbox (Sandbox Escape)](#5-fase-4-rekayasa-eksploitasi--meloloskan-diri-dari-sandbox-sandbox-escape)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini membimbing Anda dari eksploitasi logic web hingga perusakan memori tingkat rendah:

```
[Fase 1: Web Security] ──> [Fase 2: Sandbox Architecture] ──> [Fase 3: V8 Internals] ──> [Fase 4: Exploit Dev]
- SOP & CORS Bypass         - Multi-process Model           - JIT Optimizations     - shellcode in JS
- CSP & XSS Evading         - Mojo IPC Protocol             - Type Confusion        - Sandbox Escape
- Cookie Hardening          - Site Isolation                - Use-After-Free (UAF)  - CVE Debugging
```

---

## 2. Fase 1: Kebijakan Keamanan Web & Proteksi Dasar (SOP, CORS, CSP)

Sebelum mengeksploitasi kode C++ browser, Anda wajib memahami kontrol keamanan logical di level aplikasi web:

- **Same-Origin Policy (SOP)**: Aturan dasar yang membatasi dokumen/script dari satu asal (*origin* - kombinasi protokol, domain, port) untuk membaca atau memodifikasi data dari asal lain.
- **Cross-Origin Resource Sharing (CORS)**: Mekanisme header HTTP yang memperbolehkan server menyatakan asal luar mana yang diizinkan memotong batas SOP.
- **Content Security Policy (CSP)**: Lapisan deteksi dan mitigasi tambahan untuk mencegah serangan injeksi data seperti XSS (Cross-Site Scripting) dengan membatasi asal pemuatan skrip eksekusi dan memblokir inline script.

---

## 3. Fase 2: Arsitektur Sandbox & Komunikasi IPC (Mojo)

Browser modern (seperti Chromium) tidak berjalan sebagai proses tunggal. Mereka menerapkan model multi-proses untuk membatasi kerusakan jika terjadi kompromi pada tab web:

```
                          ┌─────────────────────────────┐
                          │   Browser Process (Privileged)│
                          │   - Akses Disk, Network     │
                          └──────────────▲──────────────┘
                                         │
                                         ▼ Mojo IPC (Inter-Process Comm)
┌────────────────────────────────────────┴────────────────────────────────────────┐
│                              Sandbox Boundary                                   │
│  ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────┐  │
│  │     Renderer Process    │  │     Renderer Process    │  │   GPU Process   │  │
│  │    (Blink / V8 - Low)   │  │    (Blink / V8 - Low)   │  │                 │  │
│  └─────────────────────────┘  └─────────────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

- **Renderer Process (Low Privilege)**: Menjalankan parse HTML/CSS dan mengeksekusi JavaScript. Proses ini dikunci di dalam **Sandbox** sistem operasi (menggunakan `chroot`, `namespaces`, `seccomp-bpf` di Linux, atau `AppContainer` di Windows), sehingga tidak dapat mengakses disk atau jaringan secara langsung.
- **Browser Process (High Privilege)**: Mengelola UI, tab, dan melakukan operasi I/O atas nama Renderer.
- **Mojo IPC**: Protokol komunikasi pesan terstruktur yang digunakan oleh Renderer Process untuk meminta layanan dari Browser Process secara terkendali. Eksploitasi pada Mojo IPC adalah jalur utama untuk melakukan **Sandbox Escape**.

---

## 4. Fase 3: Eksplorasi Kerentanan Memori V8 (Type Confusion, UAF)

Sebagian besar eksploitasi browser berfokus pada manipulasi memori di dalam mesin JavaScript V8 yang ditulis dalam C++.

### 4.1 Type Confusion (Kekacauan Tipe)
Kerentanan ini terjadi ketika engine mengasumsikan objek memori memiliki tipe data $A$, padahal memori tersebut telah dimodifikasi menjadi tipe data $B$.
- **Contoh**: Meng-hook properti array sehingga optimizer JIT (TurboFan) mengabaikan pemeriksaan tipe (*Type Check*) saat penulisan, membiarkan nilai integer ditulis langsung ke memori yang seharusnya berisi pointer objek. Penyerang mendapatkan kemampuan manipulasi memori primitif: membaca dan menulis alamat memori secara acak (*Arbitrary Read/Write*).

---

## 5. Fase 4: Rekayasa Eksploitasi & Meloloskan Diri dari Sandbox (Sandbox Escape)

Fase akhir adalah merangkai kerentanan V8 untuk mengendalikan eksekusi sistem secara penuh:

### 5.1 Siklus Eksploitasi Rantai Penuh (Full Chain Exploit)
1. **RCE (Remote Code Execution)**: Menggunakan kerentanan JIT V8 untuk mengalokasikan area memori RWX (Read-Write-Execute) atau memanipulasi pointer instruksi CPU (Instruction Pointer RIP) untuk menjalankan shellcode di dalam proses Renderer.
2. **Sandbox Escape**: Dari dalam Renderer Process yang dikunci sandbox, shellcode mengirimkan payload eksploitasi Mojo IPC ke Browser Process untuk memicu kerentanan perusakan memori di level privilege tinggi.
3. **Sistem Kompromi**: Eksekusi perintah sistem luar (misalnya meluncurkan `calc.exe` atau membuka terminal `/bin/sh`).

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Jelaskan perbedaan dampak eksploitasi jika penyerang berhasil mendapatkan celah **RCE pada Renderer Process** vs celah **Sandbox Escape**!

**Solusi**
- **RCE pada Renderer Process**: Penyerang hanya menguasai memori di dalam batas tab browser. Penyerang dapat mencuri cookie, kredensial, atau history tab tersebut, namun **tidak dapat** membaca file lokal di komputer korban (karena diblokir seccomp/sandbox OS) dan tidak dapat menginstal malware persistensi di OS host.
- **Sandbox Escape**: Penyerang berhasil menembus batas karantina sandbox dan mengeksekusi instruksi di level hak akses user sistem operasi. Penyerang kini memiliki kemampuan penuh untuk membaca seluruh harddisk, menginstal malware trojan, atau mengambil alih kendali komputer secara permanen.

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[browser-security-exploitation-deepdive]] | Analisis detail kerentanan V8, debugging CVE, dan bypass mitigasi ASLR/DEP. |
| [[browser-engine-architecture]] | Pemahaman dasar layout rendering pipeline dan hidden classes V8 yang dieksploitasi. |
| [[exploit-development]] | Teori dasar eksploitasi binary C++ seperti ROP chain dan heap feng-shui. |

> [!callout] 💡
> Rantai eksploitasi browser modern nyaris selalu kombinasi bug JS engine (V8) + sandbox escape — kuasai dua level itu secara paralel, bukan terpisah.

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
