---
tags:
  - IDS
  - IPS
  - WAF
  - NSM
  - network-security
  - blue-team
  - tools
  - devops
  - snort
  - suricata
  - zeek
  - crowdsec
  - safeline
aliases:
  - IDS IPS WAF Comparison
  - Security Tools Layer
  - Snort vs Suricata vs Zeek
created: 2026-05-29
status: operational
cssclasses:
  - wide-table
---

# 🍎🍅 SECURITY TOOLS — Bukan Apple vs Apple, Ini Apple vs Tomat

> **Masalah utama:** Orang mendebatkan "Snort vs Suricata vs Zeek vs CrowdSec" seolah mereka kompetitor langsung. Padahal mereka berbeda **kategori, layer, dan fungsi**. Ini seperti debat "lebih bagus mana — palu atau obeng?" Tergantung pakunya atau sekrupnya.

> [!info] Analogi Sebelum Mulai
> Bayangkan sebuah gedung kantor:
>
> - **Satpam pintu masuk** = Firewall (filter siapa yang boleh masuk)
> - **CCTV + rekaman** = Zeek / NSM (catat semua yang terjadi)
> - **Alarm pencuri** = Snort / Suricata IDS (detect dan alert)
> - **Pintu otomatis yang mengunci** = Suricata IPS / CrowdSec (detect dan blokir)
> - **Metal detector khusus pintu lobby** = WAF / SafeLine (cek konten yang masuk via web)
> - **Laporan ke kepolisian** = SIEM / Wazuh (korelasi dan eskalasi)
>
> Semua dibutuhkan. Tidak ada yang menggantikan yang lain.

---

## Peta Kategori — Dulu Pahami Ini

```
Kategori Tools Security Jaringan:

IDS  (Intrusion Detection System)
  → Detect ancaman → kirim ALERT → tidak blokir apapun
  → Seperti alarm yang bunyi tapi tidak kunci pintu

IPS  (Intrusion Prevention System)
  → Detect ancaman → BLOKIR secara inline
  → Seperti alarm yang sekaligus kunci pintu

NSM  (Network Security Monitor)
  → Tidak detect, tidak blokir → hanya CATAT semua
  → Seperti CCTV — pasif, tapi berharga untuk forensik

WAF  (Web Application Firewall)
  → Khusus traffic HTTP/HTTPS Layer 7
  → Tidak peduli dengan traffic non-web
  → Seperti metal detector khusus untuk tamu yang masuk via pintu web

HIDS (Host-based IDS)
  → Bukan di network, tapi di dalam host/server itu sendiri
  → Monitor file, log, proses, registry
  → Seperti alarm di dalam ruangan, bukan di pintu
```

---

## Tabel Utama — Posisi Setiap Tool

| Tool               | Kategori               | OSI Layer                        | Cara Kerja                                                                                                                                                                                                           | Deploy Di                                                            | ⚡ Sweet Spot                                                                                                                                | ☠️ Bukan untuk                                                                                              |
| ------------------ | ---------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Snort**          | IDS / IPS              | Layer 3–7                        | Signature-based rules. Cocokkan traffic dengan pattern yang diketahui berbahaya. Mode IDS: alert saja. Mode IPS: inline, blokir.                                                                                     | Network perimeter, inline di antara router dan LAN                   | Known attack pattern yang sudah ada ruleset-nya. Mature ecosystem, rules komunitas besar (ET Rules, Snort Community)                         | Zero-day yang belum ada signature-nya. Traffic terenkripsi (tidak bisa inspect TLS tanpa man-in-the-middle) |
| **Suricata**       | IDS / IPS / NSM hybrid | Layer 3–7                        | Sama seperti Snort tapi multi-threaded, lebih cepat di hardware modern. Support signature Snort + bisa output log seperti Zeek. Juga punya rule language sendiri.                                                    | Network perimeter, inline, juga bisa passive tap                     | High-throughput network. Bisa gantikan Snort sekaligus sebagian fungsi Zeek. Satu tool, lebih banyak output                                  | Tidak bisa fully replace Zeek untuk deep behavioral analysis. Tetap signature-based di core-nya             |
| **Zeek** _(Bro)_   | NSM murni              | Layer 3–7                        | **Bukan IDS, bukan IPS.** Zeek menganalisis traffic dan menghasilkan **log terstruktur** — siapa konek ke siapa, protokol apa, berapa lama, berapa byte. Tidak ada alert, tidak ada blocking.                        | Passive tap / span port. **Tidak inline.**                           | Forensik dan threat hunting. "Apa yang terjadi 3 hari lalu?" Zeek punya jawabannya. Deteksi anomali behavioral yang tidak ada signature-nya. | Real-time blocking. Zeek tidak bisa blokir apapun by design                                                 |
| **CrowdSec**       | Collaborative IPS      | Layer 3–4 (IP level)             | Analisis log dari berbagai source → detect perilaku mencurigakan (brute force, scanning) → blokir IP. **Crowd-sourced:** IP yang diblokir satu user dikirim ke community database, semua user lain otomatis protect. | Di server/host, bukan inline network. Baca log dari Nginx, SSH, dsb. | Brute force protection, scanner detection, IP reputation. Gratis dan crowd-powered.                                                          | Layer 7 attack (SQLi, XSS) — CrowdSec tidak baca konten request, hanya perilaku                             |
| **SafeLine**       | WAF                    | Layer 7 (HTTP/HTTPS only)        | Reverse proxy yang inspect semua HTTP request sebelum diteruskan ke aplikasi. Detect SQLi, XSS, LFI, RCE, path traversal. Chinese-made, open source, UI bagus.                                                       | Di depan web server / aplikasi sebagai reverse proxy                 | Protect web application dari OWASP Top 10. Easy setup, UI friendly. Cocok untuk homelab dan SME.                                             | Traffic non-HTTP. Tidak relevan untuk protect SSH, database, atau protocol lain                             |
| **ModSecurity**    | WAF                    | Layer 7 (HTTP/HTTPS only)        | WAF module untuk Nginx/Apache. Rule-based, OWASP CRS (Core Rule Set) adalah ruleset standarnya. Lebih mature dari SafeLine, lebih susah dikonfigurasi.                                                               | Embedded di dalam Nginx/Apache config                                | Enterprise web protection. OWASP CRS sangat comprehensive.                                                                                   | Standalone — butuh web server sebagai host                                                                  |
| **Cloudflare WAF** | WAF (cloud)            | Layer 7                          | WAF di edge Cloudflare, sebelum traffic sampai ke server kamu sama sekali. Managed rules + custom rules.                                                                                                             | DNS pointing ke Cloudflare                                           | DDoS mitigation + WAF sekaligus. Zero setup di sisi server.                                                                                  | On-premise requirement. Data privacy concern karena traffic lewat Cloudflare                                |
| **Wazuh**          | HIDS / SIEM / XDR      | Host-level + network correlation | Agent di setiap host — monitor file integrity, log, proses, registry. Server Wazuh korelasikan semua event dari semua host. Bisa integrate Suricata + Zeek alerts.                                                   | Agent di setiap server/endpoint, server Wazuh terpisah               | Compliance (PCI DSS, HIPAA). Korelasi lintas host. Forensik incident. Open source SIEM yang paling mature.                                   | Real-time network blocking. Wazuh detect dan alert, eksekusi blocking via integrasi lain                    |
| **Fail2ban**       | Simple IP Blocker      | Layer 3 (IP level)               | Baca log (SSH, Nginx, dsb) → jika ada pattern gagal login → tambah rule iptables untuk blokir IP tersebut sementara. Sangat sederhana.                                                                               | Di server/host yang diproteksi                                       | SSH brute force protection — efektif dan ringan                                                                                              | Sophistication. Mudah bypass dengan IP rotation. Tidak ada intelligence.                                    |

---

## Visual — Siapa Duduk Di Mana

```
INTERNET
    │
    ▼
[Cloudflare WAF] ←── Layer 7, cloud level, sebelum sampai ke kamu
    │
    ▼
[Router / Firewall] ←── Layer 3-4, filter IP dan port
    │
    ├──[Suricata IPS inline] ←── Layer 3-7, inspect dan blokir
    │
    ├──[Zeek tap/span] ←── Layer 3-7, catat semua (pasif, tidak inline)
    │
    ▼
[Switch Internal]
    │
    ▼
[Server / Host]
    ├── [SafeLine / ModSecurity] ←── Layer 7, protect web app
    ├── [Wazuh Agent] ←── Host level, monitor file+log+proses
    ├── [CrowdSec] ←── Baca log, blokir IP brute forcer
    └── [Fail2ban] ←── Sederhana, blokir SSH brute force
```

---

## Debat yang Sering Salah Premis

### ❌ "Snort vs Suricata — mana yang lebih bagus?"

```
Jawaban: Suricata lebih modern dan lebih cepat di hardware multi-core.
Snort 3 sudah catch up. Keduanya IPS/IDS signature-based.
Jika resource cukup → Suricata. Jika familiar dengan Snort rules → Snort.

Tapi: pertanyaannya salah frame. Yang lebih penting:
apakah kamu butuh IDS/IPS atau NSM?
Suricata vs Zeek adalah pertanyaan yang lebih benar.
```

### ❌ "Zeek vs Suricata — mana yang lebih bagus untuk deteksi?"

```
Jawaban: Pertanyaan ini salah karena membandingkan
dua hal yang berbeda fungsi:

Suricata = detect known bad → alert/block
Zeek     = catat semua → analyst yang decide mana yang bad

Jawaban benar: PAKAI KEDUANYA.
Suricata handle signature detection.
Zeek provide visibility untuk yang tidak ada signature-nya.
Banyak SOC mature run keduanya bersamaan.
```

### ❌ "CrowdSec vs SafeLine — mana yang lebih baik untuk protect server?"

```
Ini apple vs tomat yang paling obvious:

CrowdSec = IP-level protection, protect dari brute force dan scanner
SafeLine  = HTTP-level protection, protect dari SQLi/XSS/LFI

Keduanya protect "server" tapi dari ancaman yang berbeda.
Jawaban benar: pasang keduanya jika kamu run web server.
CrowdSec di depan untuk block bad IP.
SafeLine di depan web app untuk filter request berbahaya.
```

### ❌ "Wazuh vs Suricata — mana yang dipakai?"

```
Wazuh  = HIDS + SIEM → monitor dari dalam host
Suricata = Network IPS → monitor dari network

Mereka bahkan tidak compete — mereka complement.
Stack ideal: Suricata + Zeek → forward alerts ke Wazuh → Wazuh korelasi.
```

---

## Stack Rekomendasi per Use Case

### Homelab / Personal Server

```
Minimal viable:
├── Fail2ban → SSH brute force (5 menit setup)
├── SafeLine → protect web app (30 menit setup)
└── Wazuh agent → visibility log dan file integrity

Upgrade:
├── CrowdSec → tambah community intelligence
└── Suricata pasif mode → visibility network
```

### SME / Startup (< 100 karyawan)

```
├── Cloudflare WAF → Layer 7 cloud protection (easy win)
├── CrowdSec → collaborative IP blocking
├── Suricata IPS → inline protection di perimeter
├── Zeek → network visibility untuk forensik
└── Wazuh → HIDS + SIEM korelasi semua alert
```

### Enterprise / SOC Mature

```
├── Palo Alto NGFW → Layer 3-7 dengan TLS inspection
├── Suricata → tambahan signature detection
├── Zeek → full network visibility, feed ke SIEM
├── ModSecurity/WAF enterprise → protect semua web app
├── Wazuh atau Splunk/Elastic SIEM → korelasi semua
├── CrowdSec atau Blocklist.de → IP intelligence
└── EDR (CrowdStrike/SentinelOne) → endpoint level
```

---

## Cheat Sheet — Pilih Tool Berdasarkan Pertanyaan

```
"Saya ingin BLOKIR traffic berbahaya di network level"
→ Suricata IPS (inline) atau Snort IPS

"Saya ingin TAHU apa yang terjadi di network untuk forensik"
→ Zeek (NSM)

"Saya ingin PROTECT web application dari SQLi/XSS"
→ SafeLine / ModSecurity / Cloudflare WAF

"Saya ingin BLOKIR IP yang brute force SSH/Nginx saya"
→ CrowdSec atau Fail2ban

"Saya ingin MONITOR semua yang terjadi di dalam server saya"
→ Wazuh (HIDS + SIEM)

"Saya ingin KORELASI semua alert dari semua tool"
→ Wazuh / Elastic SIEM / Splunk

"Saya ingin SEMUA di atas"
→ Stack lengkap: Suricata + Zeek + SafeLine + CrowdSec + Wazuh
```

---

## Satu Tabel Akhir — Quick Reference

| Tool               | Blokir?              | Alert?   | Log/Catat?     | Layer | Posisi di Network     |
| ------------------ | -------------------- | -------- | -------------- | ----- | --------------------- |
| **Snort**          | ✅ (IPS mode)        | ✅       | Terbatas       | 3–7   | Inline                |
| **Suricata**       | ✅ (IPS mode)        | ✅       | ✅ (Zeek-like) | 3–7   | Inline atau Passive   |
| **Zeek**           | ❌                   | ❌       | ✅✅✅         | 3–7   | Passive (tap/span)    |
| **CrowdSec**       | ✅ (IP level)        | ✅       | ✅             | 3–4   | Di host               |
| **SafeLine**       | ✅ (HTTP)            | ✅       | ✅             | 7     | Reverse proxy         |
| **ModSecurity**    | ✅ (HTTP)            | ✅       | ✅             | 7     | Di dalam Nginx/Apache |
| **Cloudflare WAF** | ✅ (HTTP)            | ✅       | ✅             | 7     | Cloud edge            |
| **Wazuh**          | ❌ (butuh integrasi) | ✅       | ✅✅✅         | Host  | Di dalam host         |
| **Fail2ban**       | ✅ (IP via iptables) | Terbatas | ❌             | 3–4   | Di host               |

---

> [!tip] Takeaway Utama
> Tidak ada satu tool yang bisa cover semua layer. Stack yang baik itu berlapis — seperti Defense-in-Depth di [[purple-team-osi-killchain]]. Yang berbahaya bukan tidak punya tool, tapi merasa sudah aman karena pasang satu tool dan berpikir itu cukup.

> [!warning] Gotcha yang Sering Diabaikan
> **Semua IDS/IPS buta terhadap traffic terenkripsi (TLS) tanpa TLS inspection.** Suricata tidak bisa inspect isi HTTPS tanpa decrypt dulu. CrowdSec tidak peduli isi — hanya perilaku. Hanya WAF yang positioned sebagai reverse proxy yang bisa baca isi HTTPS. Ini kenapa banyak C2 modern pakai HTTPS over port 443 — lolos dari kebanyakan IDS.

---

## 🔗 Lihat Juga

- [[network-security|Network Security]] — OSI Layer threat table
- [[purple-team-osi-killchain|Purple Team Kill-Chain]] — context bagaimana tools ini dipakai dalam full attack chain
- [[01_library/ai_systems/cloud-infrastructure|Cloud Infrastructure]] — deployment tools ini di cloud environment
- [[endpoint-security|Endpoint Security]] — Wazuh sebagai HIDS, sisi host
- [[master-index|Master Index]]

---

_IDS vs IPS vs WAF vs NSM | Snort · Suricata · Zeek · CrowdSec · SafeLine · Wazuh · Fail2ban · Bukan Apple vs Apple_
