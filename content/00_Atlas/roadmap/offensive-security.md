---
tags:
  - roadmap
  - red-team
  - pentesting
  - offensive-security
  - exploit
  - bug-bounty
  - OSCP
aliases:
  - Roadmap Red Team
  - Roadmap Pentester
  - Jalur Karir Offensive Security
created: 2026-04-25
status: active
cssclasses:
  - wide-table
---

# 🗡️ Roadmap Offensive Security — Red Team / Penetration Tester

> **Filosofi:** Kalau kamu cuma bisa jalankan `nmap -sV target`, itu artinya kamu bisa scan. Tapi kalau kamu bisa enumerate → exploit → privilege escalate → pivot → exfiltrate → tulis laporan profesional, itu artinya kamu paham kill chain end-to-end — dan itu yang ditanya waktu interview. Rekruter akan tanya "oke, kamu dapet shell user, terus?" Kalau kamu jawab "saya enumerate SUID binaries, dapet misconfigured sudo, eskalasi ke root, lalu pivot ke mesin lain via SSH key yang saya temukan di home directory" — itu yang menutup pertanyaan.

> [!warning] Peringatan Legal
> **Semua teknik di sini hanya boleh dipraktekkan di lab sendiri atau platform legal** (HackTheBox, TryHackMe, PentesterLab). Scanning/exploiting tanpa izin tertulis = tindak pidana. Tidak ada pengecualian.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

```
Stack       : Kali Linux VM → Metasploitable/DVWA (target) di Proxmox
Jalur       : Penetration Tester / Red Team Operator
Spek        : i7 Gen7, 8GB RAM, GTX 1050
Target Karir: Junior Pentester → Pentester → Red Team Operator

Urutan belajar:
  Fase 1 (fondasi)          : Linux + Networking + Python scripting
  Fase 2 (recon & exploit)  : Nmap → Burp Suite → Metasploit → SQLMap
  Fase 3 (post-exploit)     : PrivEsc → Lateral Movement → AD Attack
  Fase 4 (profesional)      : Report Writing → Methodology → Lab Exam

Next step: Setup Kali VM + target VM (Metasploitable3 atau HackTheBox VPN)
```

---

## Fase 1 — Fondasi Wajib (Minggu 1–6)

> **Goal:** Tanpa fondasi ini, semua tool hanya jadi tombol yang kamu tekan tanpa paham kenapa.
> **RAM Impact:** Minimal — teks editor dan terminal.

| Skill                  | Yang Dipelajari                                                                 | Combo A+B yang Membuktikan                                                      |
| ---------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Linux CLI Mastery**  | Bash scripting, file permissions, process management, service control           | Linux + **bash one-liner untuk automate recon** = kamu bisa bikin tool sendiri  |
| **Networking Deep**    | TCP handshake, HTTP methods, DNS resolution, ARP, routing, NAT, firewall bypass | Networking + **Wireshark analysis** = kamu paham apa yang terjadi di wire level |
| **Python for Hacking** | Socket programming, HTTP requests, parsing, automation, pwntools                | Python + **custom exploit script** = kamu bukan script kiddie                   |
| **Web Fundamentals**   | HTTP/HTTPS, cookies, sessions, CORS, CSP, SOP, OAuth flow                       | Web + **manual request crafting (curl/Burp)** = kamu paham web attack surface   |

> [!tip] Jangan Skip Ini
> 90% orang yang gagal OSCP bukan karena exploit-nya susah — tapi karena fondasi Linux/networking/scripting mereka lemah. Fase 1 menentukan segalanya.

**Proyek Portofolio Fase 1:**
`Custom Recon Tool` — Python script yang otomatis: resolve DNS → port scan → banner grab → screenshot web → output ke markdown report. **Ini menunjukkan kamu bisa automate, bukan cuma klik tombol.**

---

## Fase 2 — Reconnaissance & Exploitation (Minggu 7–16)

> **Goal:** Dari target yang tidak dikenal → mendapatkan akses initial. Ini inti pentest.
> **RAM Impact:** Kali VM ~2GB + Target VM ~1GB = ~3GB.

| Tool/Skill               | RAM    | Yang Dipelajari                                               | Combo A+B yang Membuktikan                                                      |
| ------------------------ | ------ | ------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Nmap**                 | ~100MB | Port scanning, service detection, NSE scripts, OS fingerprint | Nmap + **service-specific exploit** = kamu bisa dari scan → shell               |
| **Burp Suite**           | ~500MB | Web proxy, interceptor, repeater, intruder, scanner           | Burp + **manual finding** = kamu paham web vuln, bukan cuma scan otomatis       |
| **Metasploit**           | ~400MB | Exploit framework, meterpreter, post-exploit modules          | Metasploit + **manual exploit tanpa Metasploit** = kamu paham exploit mechanics |
| **SQLMap / Manual SQLi** | ~100MB | SQL injection — union-based, blind, time-based, error-based   | SQLMap + **manual injection** = kamu bisa jelaskan kenapa query inject-able     |
| **Gobuster / ffuf**      | ~50MB  | Directory brute force, vhost enumeration, parameter fuzzing   | Gobuster + **custom wordlist** = kamu paham attack surface discovery            |

> [!warning] Jangan Jadi Script Kiddie
> **Untuk setiap tool otomatis yang kamu pakai, pastikan kamu bisa melakukan hal yang sama secara manual.** Rekruter PASTI tanya: "oke, Metasploit dapet shell. Sekarang lakukan tanpa Metasploit." Kalau tidak bisa — kamu bukan pentester, kamu operator tool.

**Proyek Portofolio Fase 2:**
`HackTheBox/TryHackMe Writeups` — dokumentasikan 10+ mesin yang kamu solve. Setiap writeup harus punya: recon methodology → vulnerability analysis → exploitation → proof of concept → remediation recommendation. **Publish di GitHub atau blog.**

---

## Fase 3 — Post-Exploitation & Active Directory (Minggu 17–26)

> **Goal:** Dari user shell → domain admin. Ini yang memisahkan pentester dari button clicker.
> **RAM Impact:** AD lab butuh ~4-5GB (DC + client). Matikan semua service lain.

| Skill/Tool           | RAM  | Yang Dipelajari                                                      | Combo A+B yang Membuktikan                                               |
| -------------------- | ---- | -------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **Linux PrivEsc**    | —    | SUID, cron abuse, path hijack, kernel exploit, capability abuse      | PrivEsc + **custom enumeration** = kamu bisa eskalasi tanpa LinPEAS      |
| **Windows PrivEsc**  | —    | Token impersonation, service misconfig, UAC bypass, potato attacks   | PrivEsc + **manual checks** = kamu paham privilege model Windows         |
| **Active Directory** | ~4GB | Kerberoasting, AS-REP Roasting, Pass-the-Hash, DCSync, Golden Ticket | AD + **full attack chain** = kamu paham enterprise environment           |
| **Lateral Movement** | —    | SSH pivot, port forwarding, proxychains, chisel, ligolo-ng           | Pivot + **multi-hop network** = kamu bisa operasi di segmented network   |
| **Persistence**      | —    | Scheduled tasks, registry, WMI, SSH keys, web shells                 | Persistence + **detection evasion** = kamu paham apa yang Blue Team cari |

> [!tip] Lab AD Murah
> **Proxmox → Windows Server 2019 eval (gratis 180 hari) + Windows 10 eval → setup domain.** Atau pakai **GOAD (Game of Active Directory)** — automated AD lab deployment via Vagrant. Ini lab AD paling lengkap yang gratis.

**Proyek Portofolio Fase 3:**
`Active Directory Attack Lab — Full Kill Chain` — dokumentasikan: initial access (phishing sim) → kerberoasting → lateral movement via Pass-the-Hash → DCSync → Golden Ticket → domain admin. **Dengan diagram kill chain dan rekomendasi defense.**

---

## Fase 4 — Profesionalisasi & Sertifikasi (Minggu 27–36)

> **Goal:** Dari hacker → professional pentester. Report writing dan methodology yang membedakan.

| Skill              | Yang Dipelajari                                                            | Combo A+B yang Membuktikan                                                         |
| ------------------ | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Report Writing** | Executive summary, findings, severity rating (CVSS), remediation, evidence | Report + **professional template** = kamu bisa deliver ke klien                    |
| **Methodology**    | OWASP Testing Guide, PTES, OSSTMM, MITRE ATT&CK mapping                    | Methodology + **structured approach** = kamu bukan random scanner                  |
| **OSCP Lab**       | Real pentest lab — 70+ machines, 24-jam exam, report submission            | OSCP + **pass** = industry gold standard. Ini membuka pintu                        |
| **Bug Bounty**     | HackerOne, Bugcrowd — real targets, real money, real experience            | Bug bounty + **hall of fame / payout** = proof of skill yang tidak bisa dipalsukan |

**Proyek Portofolio Fase 4:**
`Professional Penetration Test Report` — full pentest report template: scope, methodology, executive summary, technical findings (dengan screenshot + PoC), risk rating, remediation timeline. **Format yang bisa langsung dipakai untuk klien.**

---

## Roadmap Visual — Timeline 9 Bulan

```
Bulan 1-2      Bulan 3-4         Bulan 5-6         Bulan 7-8         Bulan 9
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌─────────────┐
│ FASE 1        │ │ FASE 2        │ │ FASE 2→3      │ │ FASE 3        │ │ FASE 4      │
│               │ │               │ │               │ │               │ │             │
│ Linux CLI     │ │ Nmap          │ │ PrivEsc Linux │ │ Active Dir    │ │ OSCP Lab    │
│ Networking    │ │ Burp Suite    │ │ PrivEsc Win   │ │ Full Chain    │ │ Report      │
│ Python        │ │ Metasploit    │ │ Pivot/Tunnel  │ │ Persistence   │ │ Bug Bounty  │
│ Web Basics    │ │ Web Exploits  │ │               │ │               │ │             │
│               │ │               │ │               │ │               │ │             │
│ ► Custom Tool │ │ ► 10 Writeups │ │ ► PrivEsc Lab │ │ ► AD Lab Doc  │ │ ► OSCP Exam │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘ └─────────────┘
```

---

## Sertifikasi yang Cocok per Fase

| Fase             | Sertifikasi                                          | Kenapa                                              |
| ---------------- | ---------------------------------------------------- | --------------------------------------------------- |
| Setelah Fase 1   | **eJPT (eLearnSecurity Junior Pentester)**           | Entry-level, murah (~$250), validasi fondasi        |
| Setelah Fase 2-3 | **PNPT (Practical Network Penetration Tester)**      | Practical exam + report — lebih realistis dari CEH  |
| Setelah Fase 4   | **OSCP (Offensive Security Certified Professional)** | **THE gold standard.** Setiap job posting minta ini |
| Jangka panjang   | **OSEP / CRTO**                                      | Advanced: evasion, C2 framework — Red Team level    |

---

## Platform Latihan (Gratis → Berbayar)

| Platform         | Tipe            | Harga                         | Cocok Untuk                          |
| ---------------- | --------------- | ----------------------------- | ------------------------------------ |
| **TryHackMe**    | Guided labs     | Gratis (terbatas) / $10/bulan | Pemula — learning path terstruktur   |
| **HackTheBox**   | Challenge labs  | Gratis (retired) / $14/bulan  | Intermediate — real-world simulation |
| **PentesterLab** | Web exploit     | $20/bulan                     | Web security deep dive               |
| **GOAD Lab**     | AD lab          | Gratis                        | Active Directory — self-hosted       |
| **VulnHub**      | Downloadable VM | Gratis                        | Offline practice                     |

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[ENDPOINT_SECURITY]] — CPU Ring yang di-exploit di Level 3+ cheat/malware
- [[CHEAT]] — Game hacking = offensive security dalam konteks gaming
- [[RE_HARDWARE_HACKING]] — Binary exploitation & firmware RE
- [[UNDERGROUND_KNOWLEDGE]] — Dual-use technique landscape
- [[Roadmap_Cyber_Security]] — Lawannya: Blue Team defense

---

_Roadmap Offensive Security | Fase 1 (Fondasi) → Fase 4 (OSCP) · 9 Bulan_
