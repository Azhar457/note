---
tags:
  - roadmap
  - red-team
  - pentesting
  - offensive-security
  - exploit
  - bug-bounty
  - OSCP
  - C2
  - active-directory
aliases:
  - Roadmap Red Team
  - Roadmap Pentester
  - Jalur Karir Offensive Security
  - C2 Operator Track
  - AD Attack Chain
created: 2026-04-25
updated: 2026-04-30
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
Target Karir: Junior Pentester → Pentester → Red Team Operator → APT Simulator

Urutan belajar:
  Fase 1 (fondasi)          : Linux + Networking + Python scripting
  Fase 2 (recon & exploit)  : Nmap → Burp Suite → Metasploit → SQLMap
  Fase 3 (post-exploit)     : PrivEsc → BloodHound → AD Attack → Lateral Movement
  Fase 4 (red team ops)     : C2 Framework → Evasion → Purple Team Validation
  Fase 5 (profesional)      : Report Writing → Methodology → Lab Exam

Next step: Setup Kali VM + target VM (Metasploitable3 atau HackTheBox VPN)
```

---

## Fase 1 — Fondasi Wajib (Minggu 1–6)

> **Goal:** Tanpa fondasi ini, semua tool hanya jadi tombol yang kamu tekan tanpa paham kenapa.
> **RAM Impact:** Minimal — teks editor dan terminal.

| Skill | Yang Dipelajari | Combo A+B yang Membuktikan |
|-------|-----------------|---------------------------|
| **Linux CLI Mastery** | Bash scripting, file permissions, process management, service control | Linux + **bash one-liner untuk automate recon** = kamu bisa bikin tool sendiri |
| **Networking Deep** | TCP handshake, HTTP methods, DNS resolution, ARP, routing, NAT, firewall bypass | Networking + **Wireshark analysis** = kamu paham apa yang terjadi di wire level |
| **Python for Hacking** | Socket programming, HTTP requests, parsing, automation, pwntools | Python + **custom exploit script** = kamu bukan script kiddie |
| **Web Fundamentals** | HTTP/HTTPS, cookies, sessions, CORS, CSP, SOP, OAuth flow | Web + **manual request crafting (curl/Burp)** = kamu paham web attack surface |

> [!tip] Jangan Skip Ini
> 90% orang yang gagal OSCP bukan karena exploit-nya susah — tapi karena fondasi Linux/networking/scripting mereka lemah. Fase 1 menentukan segalanya.

**Proyek Portofolio Fase 1:**
`Custom Recon Tool` — Python script yang otomatis: resolve DNS → port scan → banner grab → screenshot web → output ke markdown report. **Ini menunjukkan kamu bisa automate, bukan cuma klik tombol.**

---

## Fase 2 — Reconnaissance & Exploitation (Minggu 7–16)

> **Goal:** Dari target yang tidak dikenal → mendapatkan akses initial. Ini inti pentest.
> **RAM Impact:** Kali VM ~2GB + Target VM ~1GB = ~3GB.

| Tool/Skill | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **Nmap** | ~100MB | Port scanning, service detection, NSE scripts, OS fingerprint | Nmap + **service-specific exploit** = kamu bisa dari scan → shell |
| **Burp Suite** | ~500MB | Web proxy, interceptor, repeater, intruder, scanner | Burp + **manual finding** = kamu paham web vuln, bukan cuma scan otomatis |
| **Metasploit** | ~400MB | Exploit framework, meterpreter, post-exploit modules | Metasploit + **manual exploit tanpa Metasploit** = kamu paham exploit mechanics |
| **SQLMap / Manual SQLi** | ~100MB | SQL injection — union-based, blind, time-based, error-based | SQLMap + **manual injection** = kamu bisa jelaskan kenapa query inject-able |
| **Gobuster / ffuf** | ~50MB | Directory brute force, vhost enumeration, parameter fuzzing | Gobuster + **custom wordlist** = kamu paham attack surface discovery |

> [!warning] Jangan Jadi Script Kiddie
> **Untuk setiap tool otomatis yang kamu pakai, pastikan kamu bisa melakukan hal yang sama secara manual.** Rekruter PASTI tanya: "oke, Metasploit dapet shell. Sekarang lakukan tanpa Metasploit." Kalau tidak bisa — kamu bukan pentester, kamu operator tool.

**Proyek Portofolio Fase 2:**
`HackTheBox/TryHackMe Writeups` — dokumentasikan 10+ mesin yang kamu solve. Setiap writeup harus punya: recon methodology → vulnerability analysis → exploitation → proof of concept → remediation recommendation. **Publish di GitHub atau blog.**

---

## Fase 3 — Post-Exploitation & Active Directory (Minggu 17–26)

> **Goal:** Dari user shell → domain admin. Ini yang memisahkan pentester dari button clicker.
> **RAM Impact:** AD lab butuh ~4-5GB (DC + client). Matikan semua service lain.

| Skill/Tool | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **Linux PrivEsc** | — | SUID, cron abuse, path hijack, kernel exploit, capability abuse | PrivEsc + **custom enumeration** = kamu bisa eskalasi tanpa LinPEAS |
| **Windows PrivEsc** | — | Token impersonation, service misconfig, UAC bypass, potato attacks | PrivEsc + **manual checks** = kamu paham privilege model Windows |
| **BloodHound** | ~500MB | Active Directory attack path analysis — visualisasi graph untuk menemukan jalur privilege escalation di AD | BloodHound + **custom Cypher queries** = kamu bisa identify attack path yang tool default tidak temukan |
| **CrackMapExec** | ~200MB | Swiss army knife untuk pentesting Windows/AD — credential spraying, command execution, enumeration, dan lateral movement | CME + **pass-the-hash chain** = kamu bisa lateral movement tanpa plaintext password |
| **Impacket** | ~150MB | Python library untuk network protocols — SMB, MSRPC, LDAP, Kerberos. Foundation untuk banyak tool Windows exploitation | Impacket + **custom script** = kamu bisa bikin tool Windows exploitation sendiri |
| **Active Directory Attack** | ~4GB | Kerberoasting, AS-REP Roasting, Pass-the-Hash, DCSync, Golden Ticket | AD + **full attack chain** = kamu paham enterprise environment |
| **Lateral Movement** | — | SSH pivot, port forwarding, proxychains, chisel, ligolo-ng | Pivot + **multi-hop network** = kamu bisa operasi di segmented network |
| **Persistence** | — | Scheduled tasks, registry, WMI, SSH keys, web shells | Persistence + **detection evasion** = kamu paham apa yang Blue Team cari |

> [!tip] Tool References
> **BloodHound**, **CrackMapExec**, dan **Impacket** adalah tiga tool yang menghubungkan Fase 3 dengan Application_Offensive.html. Tanpa pemahaman ketiga tool ini, AD attack tidak bisa dieksekusi secara sistematis.

> [!tip] Lab AD Murah
> **Proxmox → Windows Server 2019 eval (gratis 180 hari) + Windows 10 eval → setup domain.** Atau pakai **GOAD (Game of Active Directory)** — automated AD lab deployment via Vagrant. Ini lab AD paling lengkap yang gratis.

**Proyek Portofolio Fase 3:**
`Active Directory Attack Lab — Full Kill Chain` — dokumentasikan: initial access (phishing sim) → BloodHound enumeration → kerberoasting → CrackMapExec lateral movement → Pass-the-Hash → Impacket DCSync → Golden Ticket → domain admin. **Dengan diagram kill chain dan rekomendasi defense.**

---

## Fase 4 — Red Team Operations & C2 (Minggu 27–34)

> **Goal:** Dari pentester → red team operator. C2 framework dan evasion adalah batasan yang memisahkan keduanya.
> **RAM Impact:** C2 server + target = ~3-4GB. C2 framework sendiri ringan tapi butuh VM multiple.

| Skill/Tool | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **Sliver C2** | ~300MB | Open-source C2 framework — cross-platform implant, multiplayer mode, DNS/HTTP/HTTPS beaconing | Sliver + **malleable C2 profile** = kamu bisa customize traffic untuk menyerupai legitimate app |
| **Havoc C2** | ~400MB | Modern post-exploitation C2 — sleep obfuscation, x64 return address spoofing, indirect syscalls | Havoc + **sleep obfuscation config** = kamu paham cara evade memory scanner EDR |
| **Mythic** | ~500MB | Collaborative red teaming platform — Docker-based agents, real-time callback, extensible payload | Mythic + **custom agent development** = kamu bisa extend capability dengan C/C++ code |
| **Cobalt Strike (trial)** | ~600MB | Commercial adversary simulation — malleable C2 profile, beaconing, post-exploitation toolkit | CS + **profile customization** = kamu paham traffic shaping untuk bypass NGFW |
| **Evasion Basics** | — | Sleep obfuscation, indirect syscalls, AMSI bypass (konsep), ETW bypass (konsep) | Evasion + **EDR testing** = kamu paham apa yang Blue Team deteksi dan kenapa |
| **Atomic Red Team** | ~200MB | Library of tests mapped to MITRE ATT&CK — simulate TTPs nyata untuk validasi detection | Atomic + **custom test** = kamu bisa validate detection capability blue team |
| **Caldera** | ~1GB | Adversary emulation platform by MITRE — automate ATT&CK TTPs, plan operations | Caldera + **operation planning** = kamu bisa measure defensive coverage organisasi |

> [!warning] Evasion = Konsep, Bukan Praktek Illegal
> Evasion technique di sini dipelajari sebagai **konsep** untuk memahami apa yang EDR deteksi. Implementasi full evasion butuh environment khusus dan legal clearance. Jangan praktekkan di production.

> [!tip] Purple Team Mindset
> Red Team Operator yang baik adalah yang paham **apa yang Blue Team lihat**. Setiap kali kamu jalankan C2, tanyakan: "alert apa yang muncul di SIEM?" Kalau tidak tahu — kamu bukan Red Team, kamu Black Box.

**Proyek Portofolio Fase 4:**
`Purple Team Exercise — C2 vs Detection` — setup Sliver/Havoc → jalankan implant → capture traffic → analisis apa yang terdeteksi Wazuh/Suricata → tulis detection gap analysis. **Ini menunjukkan kamu paham kedua sisi.**

---

## Fase 5 — Profesionalisasi & Sertifikasi (Minggu 35–40)

> **Goal:** Dari hacker → professional pentester/red team operator. Report writing dan methodology yang membedakan.

| Skill | Yang Dipelajari | Combo A+B yang Membuktikan |
|-------|-----------------|---------------------------|
| **Report Writing** | Executive summary, findings, severity rating (CVSS), remediation, evidence | Report + **professional template** = kamu bisa deliver ke klien |
| **Methodology** | OWASP Testing Guide, PTES, OSSTMM, MITRE ATT&CK mapping | Methodology + **structured approach** = kamu bukan random scanner |
| **OSCP Lab** | Real pentest lab — 70+ machines, 24-jam exam, report submission | OSCP + **pass** = industry gold standard. Ini membuka pintu |
| **Bug Bounty** | HackerOne, Bugcrowd — real targets, real money, real experience | Bug bounty + **hall of fame / payout** = proof of skill yang tidak bisa dipalsukan |

**Proyek Portofolio Fase 5:**
`Professional Penetration Test Report` — full pentest report template: scope, methodology, executive summary, technical findings (dengan screenshot + PoC), risk rating, remediation timeline. **Format yang bisa langsung dipakai untuk klien.**

---

## 🔴 Red Team Operator Tracks (Spesialisasi)

Setelah Fase 5, pilih spesialisasi berdasarkan minat dan karir target:

### Track A: Corporate Red Team
**Fokus:** Simulasi APT nyata di enterprise environment. Custom implant, long-term persistence, data exfiltration simulation.

| Skill | Tool | Level |
|-------|------|-------|
| Custom C2 Development | Sliver Armory, NimPlant, Mythic agent dev | ☠️ Danger |
| Evasion Engineering | ScareCrow, Inceptor, PEzor, AceLdr | ☠️ Danger |
| Physical Security Assessment | Flipper Zero, USB Rubber Ducky, LAN Turtle | ⚠️ Warning |
| Social Engineering Campaign | GoPhish, SET, custom pretext development | ⚠️ Warning |

### Track B: Web Application Specialist
**Fokus:** Deep dive web security, API security, cloud-native application.

| Skill | Tool | Level |
|-------|------|-------|
| Advanced Web Exploitation | Burp Suite Pro, custom extension development | ⚠️ Warning |
| API Security Testing | Postman, Arjun, custom fuzzing | ⬡ Intermediate |
| Cloud Pentesting | ScoutSuite, Prowler, CloudFox | ⚠️ Warning |
| Bug Bounty Hunting | Custom automation, recon pipeline | ⬡ Intermediate |

### Track C: Infrastructure / Network Pentester
**Fokus:** Network segmentation testing, firewall bypass, wireless assessment.

| Skill | Tool | Level |
|-------|------|-------|
| Network Protocol Exploitation | Scapy, Impacket custom, Responder | ⚠️ Warning |
| Wireless Security Assessment | Aircrack-ng, Bettercap, WiFi Pineapple | ⚠️ Warning |
| VoIP / Telecom Pentesting | SIPVicious, Viproy | ☠️ Danger |
| Mainframe / Legacy System | TN3270 exploitation, custom protocol | ☠️ Danger |

### Track D: APT Simulator / Nation-State Level
**Fokus:** Simulasi threat actor advanced. Custom malware, zero-day research, hardware implant.

| Skill | Tool | Level |
|-------|------|-------|
| Custom Malware Development | C/C++ implant, position-independent shellcode | ☠️ Danger |
| Hardware Implant | O.MG Cable, malicious USB device, PCIe DMA | ☠️ Danger |
| Supply Chain Attack | Dependency confusion, typosquatting, CI/CD poison | ☠️ Danger |
| Zero-Day Research | Fuzzing, reverse engineering, vulnerability discovery | ☠️ Danger |

> [!danger] Track D Boundary
> Track D memerlukan legal framework yang jelas — biasanya hanya dijalankan oleh government agency, military, atau contractor dengan clearance. Jangan eksplorasi tanpa legal backing.

---

## Roadmap Visual — Timeline 10 Bulan

```
Bulan 1-2      Bulan 3-4         Bulan 5-6         Bulan 7-8         Bulan 9          Bulan 10
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌─────────────┐ ┌─────────────┐
│ FASE 1        │ │ FASE 2        │ │ FASE 2→3      │ │ FASE 3        │ │ FASE 4      │ │ FASE 5      │
│               │ │               │ │               │ │               │ │             │ │             │
│ Linux CLI     │ │ Nmap          │ │ PrivEsc Linux │ │ BloodHound    │ │ Sliver C2   │ │ OSCP Lab    │
│ Networking    │ │ Burp Suite    │ │ PrivEsc Win   │ │ CrackMapExec  │ │ Havoc C2    │ │ Report      │
│ Python        │ │ Metasploit    │ │ Pivot/Tunnel  │ │ Impacket      │ │ Evasion     │ │ Bug Bounty  │
│ Web Basics    │ │ Web Exploits  │ │               │ │ AD Full Chain │ │ Atomic Red  │ │             │
│               │ │               │ │               │ │               │ │ Caldera     │ │             │
│               │ │               │ │               │ │               │ │             │ │             │
│ ► Custom Tool │ │ ► 10 Writeups │ │ ► PrivEsc Lab │ │ ► AD Lab Doc  │ │ ► Purple    │ │ ► OSCP Exam │
│               │ │               │ │               │ │               │ │   Exercise  │ │             │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘ └─────────────┘ └─────────────┘
     ▲              ▲                 ▲                 ▲                 ▲                ▲
     │              │                 │                 │                 │                │
  Portfolio:     Portfolio:        Portfolio:        Portfolio:        Portfolio:       Portfolio:
  Recon Tool     HTB Writeups      PrivEsc Lab       AD Kill Chain     Purple Team      OSCP + Report
```

---

## Sertifikasi yang Cocok per Fase

| Fase | Sertifikasi | Kenapa |
|------|-------------|--------|
| Setelah Fase 1 | **eJPT (eLearnSecurity Junior Pentester)** | Entry-level, murah (~$250), validasi fondasi |
| Setelah Fase 2-3 | **PNPT (Practical Network Penetration Tester)** | Practical exam + report — lebih realistis dari CEH |
| Setelah Fase 4 | **OSCP (Offensive Security Certified Professional)** | **THE gold standard.** Setiap job posting minta ini |
| Setelah Fase 5 | **OSEP (Offensive Security Experienced Penetration Tester)** | Evasion, C2, anti-virus bypass — Red Team level |
| Track D | **CRTO (Certified Red Team Operator)** | C2 framework, adversary simulation, detection evasion |
| Track D Advanced | **OSWE (Offensive Security Web Expert)** | Web app exploitation expert |

---

## Platform Latihan (Gratis → Berbayar)

| Platform | Tipe | Harga | Cocok Untuk |
|----------|------|-------|-------------|
| **TryHackMe** | Guided labs | Gratis (terbatas) / $10/bulan | Pemula — learning path terstruktur |
| **HackTheBox** | Challenge labs | Gratis (retired) / $14/bulan | Intermediate — real-world simulation |
| **PentesterLab** | Web exploit | $20/bulan | Web security deep dive |
| **GOAD Lab** | AD lab | Gratis | Active Directory — self-hosted |
| **VulnHub** | Downloadable VM | Gratis | Offline practice |
| **CyberDefenders** | Blue vs Red | Gratis | Purple Team exercise |

---

## 🔗 Lihat Juga

- [[🗺️Master-Index|Master Index]]
- [[endpoint-security|Endpoint Security]] — CPU Ring & Boot Chain Threat
- [[cheatsheet|Cheat Engine]] — Game hacking = offensive security dalam konteks gaming
- [[hardware-hacking-re|Hardware Hacking]] — Binary exploitation & firmware RE
- [[underground-knowledge|Underground Knowledge]] — Dual-use technique landscape
- [[cyber-security|Cyber Security Roadmap]] — Lawannya: Blue Team defense
- [[Application|Master Arsenal]] — HTML arsenal tool reference
- [[hierarchy-offensive|Offensive Security Hierarchy]] — Level 0–6 offensive hierarchy (terpisah)

---

*Roadmap Offensive Security | Fase 1 (Fondasi) → Fase 5 (OSCP) → Track D (APT Simulator) · 10 Bulan*
