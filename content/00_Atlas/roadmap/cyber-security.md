---
tags:
  - roadmap
  - blue-team
  - SOC
  - cyber-security
  - SIEM
  - IDS
  - homelab
aliases:
  - Roadmap Blue Team
  - Roadmap SOC Analyst
  - Jalur Karir Cyber Security Defensive
created: 2026-04-25
status: active
cssclasses:
  - wide-table
---

# 🛡️ Roadmap Cyber Security — Blue Team / SOC Analyst

> [!warning] **Filosofi:** Pelajari A+B, bukan A sendiri. Kalau kamu cuma install Wazuh, itu artinya kamu bisa setup SIEM. Tapi kalau kamu bisa deploy Wazuh + alert rules custom + incident response workflow di TheHive, itu artinya kamu mengerti SOC pipeline end-to-end — dan itu yang ditanya waktu interview. Rekruter akan tanya "oke, ada alert, terus prosesnya gimana?" Kalau kamu jawab "alert masuk Wazuh → trigger case di TheHive → saya triage berdasarkan MITRE ATT&CK mapping → eskalasi ke playbook yang saya tulis sendiri" — itu yang menutup pertanyaan.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

```
Stack       : Ubuntu Server → Proxmox (host) → Ubuntu VM
Jalur       : Blue Team / SOC Analyst
Spek        : i7 Gen7, 8GB RAM, GTX 1050
Target Karir: SOC Analyst L1 → L2, Security Engineer, Detection Engineer

Urutan belajar:
  Fase 1 (ringan, jalan bersamaan): Lynis → Trivy → CrowdSec → Suricata
  Fase 2 (1-2 sekaligus)         : Falco → Semgrep → OpenVAS
  Fase 3 (dedicated)             : Wazuh single-node → TheHive
  Fase 4 (konsep dulu)           : MISP → Vault

Next step: Install Proxmox, pindah Ubuntu jadi VM, buat VM target latihan
```

> [!warning] Aturan Emas
> **Satu jalur dulu.** Selesaikan sampai bisa bikin proyek yang bisa diceritakan ke rekruter, baru loncat ke jalur lain. Jangan paralel — hasilnya akan setengah-setengah di semua jalur.

---

## Fase 1 — Hardening & Visibility (Minggu 1–4)

> **Goal:** Pahami apa yang membuat sistem rentan, dan pasang "mata" pertama di infrastruktur kamu.
> **RAM Impact:** Semua tool bisa jalan bersamaan, total <2GB.

| Tool         | RAM    | Yang Dipelajari                                                   | Combo A+B yang Membuktikan                                                       |
| ------------ | ------ | ----------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Lynis**    | ~50MB  | Security auditing — skor hardening, rekomendasi fix CIS Benchmark | Lynis + **remediasi manual** = kamu bisa hardening Linux dari nol                |
| **Trivy**    | ~100MB | Container vulnerability scanning — deteksi CVE sebelum deploy     | Trivy + **Docker image scanning pipeline** = kamu paham shift-left security      |
| **CrowdSec** | ~150MB | Collaborative IPS — belajar attack patterns dari data komunal     | CrowdSec + **log analysis** = kamu lihat serangan nyata ke server kamu           |
| **Suricata** | ~350MB | Network IDS — deteksi intrusi di level packet                     | Suricata + **alert triage** = kamu bisa baca network traffic seperti SOC analyst |

> [!tip] Cara Belajar Fase 1
> Jalankan `sudo lynis audit system` — ikuti rekomendasinya satu per satu. Setiap poin yang kamu fix, catat di catatan: "Sebelum: skor 54. Sesudah: skor 72. Yang saya fix: SSH config, firewall rules, file permissions." **Ini cerita interview.**

**Proyek Portofolio Fase 1:**
`Hardening Report Ubuntu Server` — dokumen PDF/Markdown berisi skor Lynis sebelum dan sesudah hardening + penjelasan setiap fix yang diterapkan. Ini bisa jadi writing sample di lamaran.

---

## Fase 2 — Detection & Scanning (Minggu 5–10)

> **Goal:** Deteksi ancaman di level runtime (kernel) dan temukan kelemahan sebelum penyerang.
> **RAM Impact:** Jalankan 1-2 sekaligus. Matikan yang tidak dipelajari. Total aman ~3-4GB.

| Tool                  | RAM    | Yang Dipelajari                                                     | Combo A+B yang Membuktikan                                                             |
| --------------------- | ------ | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Falco**             | ~400MB | Runtime security — deteksi perilaku mencurigakan di kernel via eBPF | Falco + **custom rules** = kamu bisa menulis detection logic, bukan cuma pakai default |
| **Semgrep**           | ~200MB | SAST — cari bug keamanan di source code                             | Semgrep + **CI pipeline integration** = kamu paham DevSecOps workflow                  |
| **OpenVAS/Greenbone** | ~1.5GB | Vulnerability scanner — temukan kelemahan infrastruktur             | OpenVAS + **remediation report** = kamu bisa triage vulnerability berdasarkan CVSS     |

> [!warning] RAM Management
> **Matikan Suricata & Falco dulu sebelum jalankan OpenVAS.** OpenVAS butuh ~1.5GB sendiri. Scan ke VM lain di jaringan lokal — jangan ke server yang sedang dipelajari.

**Proyek Portofolio Fase 2:**
`Vulnerability Assessment Report` — scan jaringan homelab dengan OpenVAS, triage berdasarkan CVSS severity, tulis remediasi per finding. Format mengikuti template real pentest report.

---

## Fase 3 — SIEM & Incident Response (Minggu 11–18)

> **Goal:** Ini inti pekerjaan SOC analyst. Agregasi log, korelasi event, dan respons insiden.
> **RAM Impact:** Heavy. Jalankan satu-satu. Matikan semua tool lain.

| Tool                    | RAM    | Yang Dipelajari                                          | Combo A+B yang Membuktikan                                                           |
| ----------------------- | ------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Wazuh** (single-node) | ~3.0GB | SIEM — agregasi log, deteksi threat, compliance          | Wazuh + **custom decoder + alert rules** = kamu bisa tuning SIEM, bukan cuma install |
| **TheHive**             | ~2.0GB | Case management — cara SOC mendokumentasikan investigasi | TheHive + **incident playbook** = kamu paham workflow investigasi end-to-end         |

> [!tip] Trik RAM untuk Wazuh
> Pakai Docker Compose resmi, tapi edit `docker-compose.yml`: set `ES_JAVA_OPTS=-Xms512m -Xmx1g` untuk hemat RAM. Pasang Wazuh agent di VM lain untuk kirim log ke manager.

**Proyek Portofolio Fase 3:**
`SOC Simulation — End-to-End Incident Response` — simulasikan serangan (SSH brute force ke VM target), tunjukkan alert di Wazuh, buat case di TheHive, tulis timeline investigasi, dokumentasikan lessons learned. **Ini proyek yang membuat rekruter bilang "hire."**

---

## Fase 4 — Threat Intelligence & Secrets Management (Minggu 19–24)

> **Goal:** Level lanjutan. Berbagi IOC antar organisasi dan manage credential secara aman.
> **RAM Impact:** Pelajari konsep dulu. Jalankan hanya saat khusus belajar.

| Tool                | RAM    | Yang Dipelajari                                              | Combo A+B yang Membuktikan                                                    |
| ------------------- | ------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| **MISP**            | ~2.0GB | Threat intelligence sharing — IOC (Indicators of Compromise) | MISP + **TheHive integration** = kamu bisa automate enrichment dari IOC feeds |
| **HashiCorp Vault** | ~300MB | Secrets management — credential tidak boleh hardcode         | Vault + **auto-rotation credential database** = kamu paham zero-trust secrets |

**Proyek Portofolio Fase 4:**
`Threat Intelligence Pipeline` — setup MISP feed → TheHive auto-enrichment → Wazuh correlation. Atau: Vault secrets engine + auto-rotation credential PostgreSQL dengan audit trail.

---

## Roadmap Visual — Timeline 6 Bulan

```
Bulan 1      Bulan 2      Bulan 3      Bulan 4      Bulan 5      Bulan 6
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ FASE 1   │ │ FASE 1→2 │ │ FASE 2   │ │ FASE 3   │ │ FASE 3   │ │ FASE 4   │
│ Lynis    │ │ Falco    │ │ OpenVAS  │ │ Wazuh    │ │ TheHive  │ │ MISP     │
│ Trivy    │ │ Semgrep  │ │ Report   │ │ Setup    │ │ IR Sim   │ │ Vault    │
│ CrowdSec │ │          │ │          │ │ Custom   │ │ Playbook │ │ Pipeline │
│ Suricata │ │          │ │          │ │ Rules    │ │          │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
     ▲              ▲           ▲            ▲            ▲            ▲
     │              │           │            │            │            │
  Portfolio:     Portfolio:  Portfolio:   Portfolio:   Portfolio:   Portfolio:
  Hardening     Detection   Vuln Assess  SIEM Rules  SOC Sim     TI Pipeline
  Report        Rules       Report       Tuning      IR Report   Integration
```

---

## Sertifikasi yang Cocok per Fase

| Fase             | Sertifikasi                                         | Kenapa                                                           |
| ---------------- | --------------------------------------------------- | ---------------------------------------------------------------- |
| Setelah Fase 1–2 | **CompTIA Security+**                               | Fondasi teori security — validasi apa yang sudah kamu praktekkan |
| Setelah Fase 3   | **BTL1 (Blue Team Level 1)**                        | SOC analyst cert paling praktis — langsung pakai SIEM & IR       |
| Setelah Fase 4   | **CCD (Certified CyberDefender)** by CyberDefenders | Lab-based, pakai evidence dari SIEM/log nyata                    |
| Jangka panjang   | **GCIA (GIAC Certified Intrusion Analyst)**         | Gold standard network defense — mahal tapi berharga              |

---

## Yang TIDAK Perlu Dipelajari Sekarang

> [!warning] Jangan Buang Waktu
>
> - ~~Kali Linux tools (Metasploit, Burp Suite)~~ — itu jalur Red Team, beda roadmap
> - ~~Cloud-native security (AWS GuardDuty, Azure Sentinel)~~ — pelajari setelah punya fondasi on-prem
> - ~~Malware analysis / reverse engineering~~ — butuh fondasi assembly, beda spesialisasi
> - ~~CISSP~~ — butuh 5 tahun experience, bukan untuk pemula

---

## 🔗 Lihat Juga

- [[index|Master Index]]
- [[endpoint-security|Endpoint Security]] — CPU Ring & threat landscape yang dideteksi tools ini
- [[network-security|Network Security]] — OSI Layer defense yang dipantau Suricata
- [[cheatsheet|Cheat Engine]] — Anti-cheat = blue team di gaming industry
- [[devops|DevOps Roadmap]] — Jalur karir alternatif paling banyak lowongan
- [[offensive-security|Offensive Security Roadmap]] — Jalur Red Team (lawannya Blue Team)

---

_Roadmap Cyber Security Blue Team | Fase 1 (Hardening) → Fase 4 (Threat Intel) · 6 Bulan Homelab_
