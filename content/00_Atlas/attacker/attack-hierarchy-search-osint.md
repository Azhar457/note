---
title: Attack Perspective — OSINT & Search (Red Team Recon)
tags:
- attack
- red-team
- osint
- recon
- sigint
- xkeyscore
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# OSINT & Search — Perspektif Penyerang (Recon)

> OSINT bukan hanya tools — tapi **proses sistematis** untuk memetakan target sebelum serangan. Red team pakai OSINT untuk: identifikasi employee, email format, tech stack, exposed service, credential leak.

## 1. OSINT Attack Chain

```
Passive OSINT (no interaction dengan target):
 ├── Domain/certificate transparency (crt.sh, certspotter)
 ├── DNS records (dig, dnsdumpster, SecurityTrails)
 ├── Shodan/Censys → exposed service, port, banner
 ├── GitHub dork → credential leak, source code, config
 ├── LinkedIn → employee, role, tech stack inference
 └── Breach database → credential dump (HaveIBeenPwned, DeHashed)
 ↓
Active OSINT (interaction = target bisa deteksi):
 ├── Nmap scan (T1595) — port, version
 ├── Web crawl (T1595.002) — directory, endpoint, parameter
 ├── Email validation (T1589.002) — confirm format
 ├── Social media scrape (T1589) — photo, location, pattern
 └─ Social engineering prep (T1591) — profile target, craft phishing
 ↓
Threat Modeling (use hasil recon untuk pilih attack vector):
 ├── Tech stack → CVE selection (searchsploit, NVD)
 ├── Employee → phishing target (email, role, access level)
 ├── Exposed service → exploit selection (web RCE, VPN bypass)
 └── Credential leak → credential stuffing / password spray
```

## 2. Tool Stack OSINT Red Team

| Fase | Tool | Output | Stealth |
|------|------|--------|---------|
| **Domain recon** | crt.sh, certspotter, amass | Subdomain, cert history | Pasif — no detect |
| **Infrastructure** | Shodan, Censys, ZoomEye | Exposed service, port, banner | Pasif — Shodan data pre-indexed |
| **DNS** | dig, dnsdumpster, SecurityTrails | DNS records, history, MX, TXT | Pasif |
| **Email** | theHarvester, hunter.io | Email format, employee | Pasif |
| **Breach** | HIBP, DeHashed, IntelX | Credential leak | Pasif |
| **Social** | Maltego, Spiderfoot | Entity graph, relationship | Pasif (public data) |
| **Code** | GitHub dork, GitLab search, Gitleaks | Credential, config, source | Pasif |
| **Scan** | nmap, masscan, rustscan | Port, version | **Aktif — detectable** |
| **Web** | ffuf, gobuster, nuclei | Directory, endpoint, CVE | **Aktif — detectable** |

## 3. SIGINT & RF (Nation-State Level)

| Kemampuan | Tool / Platform | Sumber | Red Team Use |
|-----------|---------------|--------|--------------|
| **Packet interception** | XKEYSCORE (NSA) | Snowden leak | Passive filter — email, chat, browsing history |
| **Quantum Insert** | FoxAcid (NSA) | Snowden leak | MITM redirect → exploit server |
| **BGP Hijack** | QUANTUMBING, Russia FSB | Public research | Redirect traffic ke attacker |
| **IMSI Catcher** | Stingray, custom SDR | Commercial + DIY | Phone location, SMS/call intercept |
| **RTL-SDR** | RTL-SDR ($25) | Commercial | Frequency scan, decode (POCSAG, ADS-B, weather sat) |
| **TEMPEST** | Van Eck radiation | Research | Screen content via EM emanation |

## 4. Detection Gap OSINT

| Aktivitas | Defender Detect | Gap |
|-----------|----------------|-----|
| Passive OSINT | Tidak bisa deteksi (no interaction) | Pasif = invisible |
| Shodan scan | Shodan pre-indexed — tidak ada scan ke target | Tidak ada log |
| GitHub dork | GitHub search publik — no target interaction | Tidak ada log |
| Active scan (nmap) | IDS/IPS detect — port scan alert | Rate limit / distributed scan = below threshold |
| Email harvest | Tidak ada deteksi (public source) | Pasif |
| Breach database | Tidak ada deteksi (third party) | Pasif |

## 5. Referensi
- Shodan — https://www.shodan.io/
- Censys — https://censys.io/
- crt.sh — https://crt.sh/
- Maltego — https://www.maltego.com/
- theHarvester — https://github.com/laramies/theHarvester
- OSINT Framework — https://osintframework.com/
- XKEYSCORE (Snowden) — https://en.wikipedia.org/wiki/XKeyscore
---

audited
---
