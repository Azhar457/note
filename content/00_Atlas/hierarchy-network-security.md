---
title: "Network Security Hierarchy"
tags:
- atlas
- network-security
- OSI
- blue-team
- red-team
created: '2026-07-17'
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  
---


# 🌐 HIERARKI NETWORK SECURITY — Dari Kabel Fisik (Layer 1) sampai Manipulasi Psikologis (Layer 8)

> Setiap byte yang melewati jaringan melintasi hierarki 7 layer OSI — dan 1 layer paling berbahaya yang **bukan bagian OSI resmi tapi paling sering jebol**. Naik hierarki = naik abstraksi dari kabel tembaga sampai pikiran manusia. Defender yang paham hierarki tahu di mana harus pasang kontrol dan di mana kontrol itu sia-sia. Untuk tabel ancaman lengkap per layer (Blue vs Red), lihat [[network-security]]. Untuk tools per layer, lihat companion tools note.

> [!info] Cara Baca
> Layer 1 = paling fisik (kabel, sinyal elektrik). Layer 7 = paling abstrak (aplikasi, HTTP request). Layer 8 = tidak resmi, tapi manusia paling sering jadi titik lemah. Baca dari bawah ke atas untuk memahami bagaimana serangan **melompati** layer dan kenapa kontrol teknis saja tidak cukup.

---

## Tabel Utama — OSI Layer 1 sampai Layer 8

| 🌐 Layer | 🧠 Zona & Apa yang Beroperasi di Sini | ⚡ Contoh Threat | 🛡️ Kontrol Defender Khas | 🎯 Real-World Case |
|---|---|---|---|---|
| **Layer 1** — Physical | Kabel tembaga, sinyal elektrik, gelombang radio, **hardware interface fisik**. Semua data pada akhirnya adalah pulsa elektrik atau foton di sini | LAN Tap (Throwing Star), USB Rubber Ducky, O.MG Cable, evil maid attack, rogue device di switch port | CCTV rack server, port lock USB, tamper-evident seal, physical access control (biometric + card), grounded cabinet | NSA ANT Catalog (COTTONMOUTH) — implant hardware yang aktif dari kabel jaringan. Target embassy AS di seluruh dunia |
| **Layer 2** — Data Link | MAC address, frame switch, **subnetwork local**. ARP bekerja di sini — protokol yang memetakan IP ke MAC | ARP Poisoning, MAC Flooding, VLAN Hopping, rogue DHCP server, STP manipulation | 802.1X NAC, Dynamic ARP Inspection (DAI), port security, private VLAN, DHCP snooping | Kapsel virus Hauri (2008) — worm yang exploit ARP poisoning di korporat Korea. Serangan data center besar pertama yang terdokumentasi lewat L2 |
| **Layer 3** — Network | IP address, routing packet antar subnet, **pintu gerbang internet**. BGP, OSPF, RIP bekerja di sini | IP Spoofing, BGP Hijack (China Telecom 2010 incident), ICMP Tunnel (exfil lewat ping), route poisoning, smurf attack | Firewall stateful, BCP38 ingress filtering, RPKI + BGP route filtering, Unicast RPF | China Telecom BGP hijack incident (2010) — 15% traffic internet dialihkan selama 18 menit termasuk ke situs pemerintah AS. Begitulah kekuatan satu route poisoning |
| **Layer 4** — Transport | TCP/UDP port, **koneksi end-to-end**. SYN/ACK handshake, sesi stateful | TCP SYN Flood, UDP amplification DDoS, port scanning, session hijacking, Mirai botnet | SYN Cookie, rate limiting, Anycast DDoS mitigation, IPS (Suricata, Snort), connection state tracking | Mirai botnet (2016) — 1.2 Tbps DDoS via 145.000 kamera IP & DVR compromised. Serangan terbesar saat itu, target Dyn (down Twitter, Reddit, GitHub, Netflix) |
| **Layer 5–6** — Session / Presentation | TLS handshake, sesi SSH, **enkripsi in-transit**. Sertifikat digital bekerja di sini | SSL Stripping (sslstrip2), TLS Downgrade Attack, rogue certificate, BEAST attack, POODLE | HSTS Preload, certificate pinning, TLS 1.3 only enforcement, Certificate Transparency log monitoring | DigiNotar (2011) — Root CA Belanda dikompromi, 531 sertifikat palsu diterbitkan termasuk untuk domain Google. Seluruh Certificate Trust chain runtuh untuk CA itu |
| **Layer 7** — Application | HTTP, SQL, API call, **business logic**. Di sini tempat 90% bug bounty terjadi | SQLi, XSS, RCE, SSRF, deserialization bug, API abuse, Log4Shell (CVE-2021-44228) | WAF (ModSecurity, Cloudflare), SAST/DAST (Semgrep, ZAP), input validation, bug bounty program, patch management SLA | Log4Shell (Desember 2021) — single vulnerability di logging library dipakai seluruh Java ecosystem. Exploited dalam 72 jam dari disclosure. CVE score 10.0 |
| **☠️ Layer 8** — Human _(tidak resmi)_ | Otak manusia, **trust yang dieksploitasi**. Bukan layer teknis tapi paling sering jadi entry point | Phishing, vishing, pretexting, BEC (Business Email Compromise), SMS phishing (smishing), QR phishing (quishing) | Security awareness training, MFA wajib, anti-phishing gateway, internal phishing simulation, principle of least privilege | Twitter hack 2020 — social engineering terhadap karyawan via phone. Akun Obama, Musk, Gates, Apple official ditweet "give Bitcoin, get 2x back." Total USD 120.000 kerugian dalam jam |

---

## Peta Visual — Abstraksi vs Attack Surface

```
                    ↑ Abstraksi Meninggi
                    │ Attack Surface Ikut Melebar
                    │
    Layer 8 ────────┼──── MANUSIA (Layer tidak resmi)
                    │       (trust dieksploitasi, semua kontrol
                    │        teknis di bawahnya bisa dilewati)
                    │
    Layer 7 ────────┼──── Application Logic
                    │       (90% bug bounty ada di sini)
                    │
    Layer 5-6 ──────┼──── TLS / Session
                    │       (kripto in-transit, sertifikat)
                    │
    Layer 4 ────────┼──── TCP/UDP
                    │       (handshake, stateful)
                    │
    Layer 3 ────────┼──── IP / Routing
                    │       (BGP = single point of geopolitik)
                    │
    Layer 2 ────────┼──── MAC / Frame
                    │       (subnetwork local)
                    │
    Layer 1 ────────┼──── Kabel & Sinyal
                    │       (hardware, tap, evil maid)
                    ↓ Abstraksi Menurun
                    ↓ Satu kontrol bisa cover banyak layer (e.g. WAF = L7 only)
```

> [!warning] Layer 8 — Layer Paling Berbahaya
> Tidak ada firewall di dunia yang bisa memblokir manusia yang sudah tertipu. Satu telepon vishing yang berhasil ke IT support bisa memberikan attacker kredensial admin tanpa sentuh satu baris kode pun. Inilah kenapa organisasi yang sukses menjalankan security awareness training rutin **mengalahkan** organisasi yang cuma tambal kerentanan teknis.

---

## Kenapa Hirarki OSI Penting

### 1. Setiap Jaringan Punya Stack Ini — Tanpa Pengecualian

Internet, intranet korporat, WiFi rumahan, LTE seluler, satelit — semuanya menjalankan layered communication. Bahkan protokol "baru" seperti QUIC (HTTP/3) tetap mempertahankan abstraksi layer — hanya memindahkan TLS ke dalam transport layer. Mau pake stack apapun, hirarki 7 layer (atau 4 layer TCP/IP model) selalu ada.

### 2. Satu Serangan Bisa Cascade Lintas Layer

Contoh: Serangan SQL Injection di Layer 7 → database bocor → admin credentials terambil → ARP poisoning di Layer 2 (pakai kredensial itu) → lateral movement ke host lain di subnetwork → packet capture di Layer 1 untuk kredensial lebih banyak → phising Layer 8 terhadap eksekutif. **Satu bug di aplikasi bisa berujung kompromi penuh** karena kredensial yang dicuri di satu layer dipakai untuk nyerang layer lain.

### 3. Defense-in-Depth = Setiap Layer Punya Kontrol

| Layer Satu | Kontrol Tunggal (Murah) | Stack Defense-in-Depth (Mahal) |
|---|---|---|
| Layer 1 | Kunci rack | Kunci + CCTV + tamper seal + biometric + guard |
| Layer 2 | Port security di switch | Port security + 802.1X + NAC + DAI + DHCP snooping + private VLAN |
| Layer 3 | iptables DROP rule | Firewall stateful + IPS + RPKI + BGP filter + RTBH |
| Layer 4 | `fail2ban` | IPS + SYN cookie + Anycast DDoS mitigation + rate limiting + WAF |
| Layer 5-6 | HTTPS only | HSTS + CT log monitoring + cert pinning + TLS 1.3 only + HPKP (deprecated) |
| Layer 7 | Input validation | WAF + SAST + DAST + bug bounty + patch SLA + secure SDLC |
| Layer 8 | Email filter | Phishing simulation + awareness training + MFA + principle least privilege + zero trust |

Naik hierarki → setiap kontrol tambah mahal. Tapi **kontrol di layer yang lebih rendah mungkin lebih efektif** (Layer 3 firewall RPKI > Layer 7 WAF untuk serangan BGP hijack). Pilih kontrol berdasarkan threat yang relevan.

### 4. Threat Model Bergantung pada Serangan Layer Mana

| Target / Industri | Layer Prioritas Pertahanan |
|---|---|
| **Personal / Rumahan** | Layer 4 (Windows Firewall) + Layer 7 (browser extension uBlock Origin) + Layer 8 (anti-phishing) |
| **SMB / UKM** | + Layer 3 (next-gen firewall) + Layer 7 (WAF) + MFA wajib |
| **E-commerce** | + Layer 5-6 (TLS 1.3 enforcement, CT monitoring) + Layer 7 (SAST/DAST, bug bounty) |
| **Enterprise / Korporat** | + Layer 2 (NAC 802.1X) + Layer 3 (BGP filtering kalau BGP sendiri) + SIEM + SOC 24/7 |
| **Government / Critical Infra** | + Layer 1 (air-gap untuk system paling sensitif) + TEMPEST shielding + classified network |
| **Telecom / ISP** | + Layer 3 (BGP security RPKI wajib) + DDoS scrubbing + cross-connect monitoring |

Naik hierarki organisasi → coverage eksponensial. Tapi tidak semua organisasi butuh Layer 1 TEMPEST shielding — kecuali kalau threat model spesifik.

### 5. Dual-Use: Attacker dan Defender Paham Layer yang Sama

Setiap red teamer paham OSI layer — karena itulah rute operasi mereka: mulai dari Layer 8 (phishing initial access) → escalate ke Layer 7 (eksploitasi web app) → pivot ke Layer 2 (lateral movement via ARP poison) → persist di Layer 1 (hardware implant untuk APT). Tanpa paham hierarki, attacker cuma nyangkut di Layer 7 SQLmap — script kiddie level.

---

## Plot Twists

> [!danger] Plot Twist 1: BGP = Internet Itu Sendiri Tidak Aman
> Border Gateway Protocol (Layer 3) yang dipakai untuk routing seluruh internet **tidak punya autentikasi built-in** sampai RPKI diperkenalkan (2010+) dan itupun belum wajib. Artinya siapapun yang punya ASN (Autonomous System Number) dan router BGP bisa **prefix hijack** dan mengalihkan traffic internet. China Telecom pernah hijack 15% traffic (2010). Itu bukan hacking — itu desain protokol yang fundamentally trust semua peer. NSA dan intelijen lain secara periodik exploit properties BGP ini untuk SIGINT.

> [!danger] Plot Twist 2: SSL Stripping Masih Efektif Setelah 15+ Tahun
> Moxie Marlinspike mempresentasikan SSL stripping di Black Hat 2009. Sampai hari ini, **frequency mitigasi minim** — HTTPS enforcement (HSTS preload) cuma effective untuk browser modern, **bukan untuk aplikasi native** atau **first-visit ke domain baru**. Setiap kali organisasi gagal enforce HTTPS di **semua path** (termasuk subdomain, legacy path), attacker di posisi MITM bisa downgrade ke HTTP. Vendor Cobalt Strike punya modul HTTP downgrade bawaan untuk ini — masih dipakai rutin di red team engagement 2026.

> [!danger] Plot Twist 3: Layer 8 Justru Paling "Cheap to Attack"
> Semua kontrol teknis di Layer 1–7 harganya mahal (firewall ribuan dolar per enterprise, NAC butuh switch managed, WAF perlu appliance). Tapi Layer 8 — manusia — cuma butuh **satu telepon yang convincing**. Cost ratio attacker vs defender untuk phising adalah 1:10000. Inilah kenapa BEC (Business Email Compromise) menjadi **kategori cybercrime paling menguntungkan** di 2025 (FBI IC3 report: USD 2.9 miliar kerugian hanya di BEC). Tidak ada teknologi yang skala ekonominya mengalahkan psikologi manusia + urgensi.

> [!tip] Plot Twist 4: Layer 5-6 Adalah "Invisible Layer"
> Kebanyakan orang mengira SSL/TLS = "aman" dan tidak perlu dipikirkan lebih lanjut. Padahal Layer 5-6 punya detail halus yang menentukan apakah enkripsi itu actually aman: cipher suite yang dipilih, panjang kunci, certificate pinning, OCSP stapling, certificate transparency. **Implementasi yang salah** di Layer 5-6 lebih berbahaya dari algoritma yang lemah — "never roll your own crypto, never configure your own TLS." Heartbleed (2014) dan POODLE (2014) adalah pengingat bahwa widely-deployed open-source implementation pun punya bug.

> [!tip] Plot Twist 5: Layer 1 Tidak Diskalakan — Inilah Mengapa Hardware Attack Ekspensive
> Semua serangan di Layer 2–7 bisa **di-remote**: phising dari laptop, eksploit dari server, BGP hijack dari router. Tapi Layer 1 butuh **akses fisik atau mata-mata RF**. Ini kenapa nation-state APT menghabiskan miliaran untuk program supply chain implant (NSA ANT catalog, GRU's Agent.BTZ): karena Layer 1 attack itu inherently **physical access limited**. Setiap serangan Layer 1 yang sukses = single, high-value, one-shot — tidak bisa disebar ke banyak target.

---

## TLS / OSI Model Interaction

Layer 5-6 menarik karena dia **membungkus** Layer 7 (HTTP di dalam TLS jadi HTTPS), tapi juga bisa di-strip (downgrade attack):

```
Plain HTTP Flow:
Client ── [Layer 7: HTTP request] ──► Server
   └──── Layer 4 TCP ────────┘
        └──── Layer 3 IP ──────┘
              └──── Layer 1 cable ───┘

HTTPS Flow:
Client ── [Layer 7: HTTP] ── [TLS tunnel Layer 5-6] ──► Server
   └──── Layer 4 TCP ────────┘
        └──── Layer 3 IP ──────┘
              └──── Layer 1 cable ───┘

MITM Downgrade Attack:
Client ── [HTTP] ──► attacker ── [HTTPS] ──► Server
                ↑
        SSL Strip di sini
        Attacker baca semua plain
```

Hanya [[endpoint-security|CPU Ring & Boot Chain]] → [[cryptography-biometrics]] → namespace security memang saling terkait.

---

## Perbandingan Pendekatan Defense

| Pendekatan | Layer Coverage | Trade-off | Contoh |
|---|---|---|---|
| **Default OS Firewall** | Layer 3-4 | User-friendly, insufficient | Windows Defender Firewall default |
| **Enterprise Firewall (NGFW)** | Layer 3, 4, 7 | Mahal, performance cost | Palo Alto, Fortinet, Cisco Firepower |
| **Zero Trust Network Access** | Layer 7 + identity | Complex setup, butuh mature IAM | Zscaler ZIA, Cloudflare Access, Tailscale + Auth |
| **Defense-in-Depth Stack** | Semua layer kecuali Layer 8 | Mahal, butuh tim besar | Bank, financial institution, military |
| **Human-First Security** | Layer 8 + minimum Layer 7 | Behavioral change paling susah | KnowBe4, Cofense phishing simulation + MFA wajib |

Defense-in-Depth adalah gold standard tapi cost eksponensial naik per layer. Kebanyakan organisasi target coverage Layer 3, 4, 7 (firewall + IPS + WAF) + Layer 8 (security awareness). Layer 2 dan Layer 5-6 sering under-covered sampaiincident terjadi.

---

## Rekomendasi per Profil

| Profil | Layer Coverage Minimum | Tambahan Jika Budget Ada |
|---|---|---|
| **Personal / Rumahan** | Layer 4 (OS firewall) + Layer 7 (uBlock Origin) + Layer 8 (phishing awareness) | Layer 3 (router dengan firewall configurable) + VPN ke seluruh traffic |
| **SMB / UKM** | + Layer 3 (NGFW tier-1) + Layer 7 (WAF Cloudflare/AWS Shield) | Layer 2 (managed switch 802.1X) + EDR |
| **Mid-Market Enterprise** | + Layer 5-6 (TLS 1.3 enforcement, CT monitoring) + SIEM 24/7 + Layer 8 (phishing simulation rutin) | + Zero Trust (Zscaler, Cloudflare Access) + NAC mature |
| **Regulated / Finance / Health** | Di atas + Layer 1 (locked server room) + compliance PCI-DSS/HIPAA + audit trail kuat | + Air-gap untuk system paling sensitif + dedicated SOC |
| **Critical Infrastructure** | + Layer 1-2 OT segmentation + ICS/SCADA specialized tooling | + Air-gap untuk safety-critical control + unidirectional gateway (data diode) |
| **Government / Defense** | + Layer 1 TEMPEST shielding + classified network + physical security berlapis | + custom hardware + proprietary protocol + national crypto module |

Naik profil → coverage Layer 1 naik secara predictable, karena cost fisik (CCTV, sealed port, security guard) dominan di top-tier organizations.

---

## Sumber & Telusur Lebih Lanjut

- **Threat Landscape Lengkap per Layer** → [[network-security]] (tabel ancaman Blue vs Red Team)
- **Tools Freeware per Layer** → (akan dibuat: `network-security-tools.md`)
- **OSI Layer Analog (Komunikasi)** → [[hierarchy-offensive]] (Level 1-6 Privilege Escalation specialist menyebut OSI)
- **CPU Ring Analog (Endpoint)** → [[hierarchy-endpoint-security]] (CPU Ring -3 sampai Ring 3)
- **TLS Deep Dive** → [[tls-ssl-deepdive]] (handshake, cipher suite, certificate)
- **HTTP Deep Dive** → [[http-protocol-deepdive]] (Layer 7 dalam detail)
- **Purple Team Kill Chain** → [[purple-team-osi-killchain]] (mapping attack ke defense per layer)
- **Master Index** → [[master-index]]

---

> Begitu paham hierarki network, lo paham **di mana** satu kontrol efektif, **di mana** ia sia-sia, dan **layer mana** yang harus diperkuat pertama berdasarkan threat model spesifik organisasi lo. Tanpa pemahaman hierarki, network security jadi tambal sulam reaktif — biaya mahal, hasil tak menentu.

*Network Security Hierarchy | Layer 1 (Kabel) → Layer 7 (Aplikasi) → Layer 8 (Manusia) · Inversi Kontrol-Teknis vs Manipulasi-Psikologis*

audited
---
