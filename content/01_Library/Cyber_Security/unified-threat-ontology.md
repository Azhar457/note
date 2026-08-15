---
title: "Unified Threat Ontology \u2014 Cross-Domain Cyber Attacks from Transistor\
  \ to Human (Layer 1 to Layer 8)"
tags:
- unified-theory
- cyber-security
- threat-ontology
- network-security
- information-operations
- systems-architecture
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:

---


| Item | Detail |
|------|--------|
| **Summary** | Ontologi ancaman terpadu 8 layer (transistor→manusia): taksonomi, unified killchain, pemetaan ke pertahanan, dan WAF sebagai sub-sistem. |




[[00_Atlas/hierarchy-threat-modeling]] [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] [[00_Atlas/hierarchy-crosswalk]] [[about]]

> [!abstract] Ringkasan & Hubungan ke Vault
> Serangan siber modern tidak pernah terjadi secara terisolasi pada satu layer sistem saja. Catatan ini menyatukan konsep-konsep pertahanan dalam model terpadu (*Unified Threat Ontology*) dari Layer 1 (Fisik/Transistor) hingga Layer 8 (Manusia/Psikologis), merangkum keterkaitan antara [[network-security]], [[blueteam-detection-matrix]], dan [[cognitive-security-information-operations]].

## Daftar Isi

1. [Taksonomi Ancaman Lintas Layer (Layer 1 s.d Layer 8)](#1-taksonomi-ancaman-lintas-layer-layer-1-sd-layer-8)
2. [Pemetaan Rantai Serangan Terpadu (Unified Killchain)](#2-pemetaan-rantai-serangan-terpadu-unified-killchain)
3. [Sub-Sistem Pertahanan WAF di Dalam Ontologi](#3-sub-sistem-pertahanan-waf-di-dalam-ontologi)
4. [Koneksi ke Vault](#4-koneksi-ke-vault)

---

## 1. Taksonomi Ancaman Lintas Layer (Layer 1 s.d Layer 8)

Model ancaman terintegrasi memetakan seluruh attack surface ke dalam 8 layer komprehensif, memperluas model OSI 7 layer standar dengan menambahkan aspek psikologis manusia:

| Layer | Domain Keamanan | Target Utama | Contoh Vektor Serangan | Countermeasures / Pertahanan |
|-------|-----------------|--------------|------------------------|------------------------------|
| **L8: Human** | Psikologi & Kognitif | Pikiran Operator/Publik | Cognitive Warfare, Social Engineering, Phishing | MFA, Security Awareness, Zero Trust |
| **L7: Application**| Web / API Security | Aplikasi, WAF, RASP | SQLi, XSS, GraphQL nested query, RCE | input validation, RASP, WAF, schema validation |
| **L6: Presentation**| Enkripsi / TLS | Protokol Handshake | Quantum-cryptography bypass, TLS downgrades | Post-quantum cryptography, mTLS, TLS 1.3 |
| **L5: Session** | Autentikasi / Sesi | Session Token, JWT | JWT key confusion, Session Hijacking | `httpOnly` cookies, Token validation (RS256) |
| **L4: Transport** | Port & Koneksi | TCP/UDP sockets | TCP SYN Flood, Port scanning | SYN cookies, firewalls, rate limiting |
| **L3: Network** | Routing & IP | IP Packet, Subnet | BGP hijacking, IP spoofing, routing loops | BGPsec, Gossip blocklist, static routing |
| **L2: Data Link** | Otomasi Industri / MAC | Gardu, Switch, PLC | GOOSE poisoning (IEC 61850), MAC spoofing | Network segmentation, VLAN, 802.1X |
| **L1: Physical** | Hardware & Chip | Transistor, Firmware | JTAG extraction, Side-channel attacks, Stuxnet USB | Tamper detection, Hardware Root of Trust |

---

## 2. Pemetaan Rantai Serangan Terpadu (Unified Killchain)

Serangan tingkat tinggi (*Advanced Persistent Threat / APT*) biasanya merayap dari satu layer ke layer lainnya secara sekuensial.

### 2.1 Alur Serangan Sabotase Data Center AI (AI Energy War)

Berikut adalah contoh visualisasi bagaimana penyerang mengombinasikan kerentanan dari Layer 8 turun ke Layer 1, lalu memanipulasi proses fisik gardu:

```
[Layer 8: Human]       Penyerang mengirim spearphishing berisi malware SCADA
      │
      ▼
[Layer 7: App]         Operator membuka file jahat → menginfeksi Engineering PC
      │
      ▼
[Layer 5: Session]     Penyerang membajak session token VPN operator
      │
      ▼
[Layer 3: Network]     Koneksi bypass perimeter menuju zona SCADA via VPN
      │
      ▼
[Layer 2: Data Link]   Penyerang mengirim paket GOOSE palsu (IEC 61850) ke gardu
      │
      ▼
[Layer 1: Physical]    Breaker gardu terbuka secara fisik → pemadaman Data Center AI
```

---

## 3. Sub-Sistem Pertahanan WAF di Dalam Ontologi

Untuk menangkal serangan berantai yang memanfaatkan berbagai layer, WAF membagi sub-sistem pertahanannya secara granular sesuai dengan ontologi ancaman ini:

1. **Layer 7 (Application)**: Dilindungi oleh rule-signature engine WAF, OpenAPI schema validator, serta parser query GraphQL.
2. **Layer 6 (Presentation)**: Menggunakan negosiasi kunci hybrid pasca-kuantum (PQC Kyber/Dilithium) untuk mengamankan komunikasi data dari intaian di masa depan.
3. **Layer 5 (Session)**: Melakukan validasi klaim token JWT secara asimetris menggunakan algoritma RS256 secara tersentralisasi.
4. **Layer 3 & 4 (Network/Transport)**: Gossip protocol digunakan untuk mendistribusikan IP blocklist secara cepat ke seluruh node secara kolaboratif guna meredam serangan DDoS (L4) dan pemindaian IP masif (L3).
5. **Layer 7 Internal (Runtime App)**: Memasang RASP (Runtime Application Self-Protection) agent untuk mengawasi langsung jalannya panggilan sistem berbahaya (`execve`) pada web server upstream.

---

## 5. Deepdive — Cascade Attack Pattern

### 5.1 Stuxnet (Layer 8 → Layer 1 Cascade)

Stuxnet adalah contoh klasik serangan cascade lintas layer — dari manusia sampai fisik:

```
Layer 8: Operator USB ditinggal di parkir (social engineering)
  ↓
Layer 3: USB autorun → infection menyebar via LAN
  ↓
Layer 7: WinCC SCADA exploit → engineering WS compromise
  ↓
Layer 4: S7 protocol injection ke PLC
  ↓
Layer 2: Modbus/Profibus command ke frequency converter
  ↓
Layer 1: Centrifuge overspeed → physical damage (uranium enrichment)
```

### 5.2 SolarWinds (Layer 7 → Layer 8 Cascade)

Suffle dari supply chain ke intel:

```
Layer 7: Build server compromise (SUNBURST)
  ↓
Layer 6: TLS traffic ke C2 (trusted cert)
  ↓
Layer 3: DNS resolution ke C2 domain (legit-looking)
  ↓
Layer 7: 18,000+ customer install backdoored update
  ↓
Layer 8: Trust breach (customer percaya vendor)
```

### 5.3 Deepfake Heist (Layer 8-only Attack)

Deepfake financial fraud (2024 Hong Kong case):

```
Layer 8: Deepfake video call → CFO "authorize" $25M transfer
  ↓
Layer 5: Session token tidak ada, trust = visual (deepfake)
  ↓
Layer 3: Transfer via SWIFT (trusted financial network)
  ↓
Layer 1: Money gone → irreversible
```

## 6. MITRE ATT&CK Cross-Layer Mapping

| Tactic | Technique | Layer |
|--------|-----------|-------|
| Reconnaissance | Phishing for Information (T1598) | L8 |
| Initial Access | Supply Chain Compromise (T1195) | L7→L8 |
| Lateral Movement | Internal Spearphishing (T1534) | L7→L8 |
| Impact | manipulate (T0831) | L2→L1 |
| Defense Evasion | Encrypted Channel (T1573) | L6 |

## 7. Tool Stack — Cross-Layer Defense

| Tool | Layer | Use |
|------|-------|-----|
| **Proofpoint** | L8 | Email phishing detect |
| **Cloudflare WAF / ModSecurity** | L7 | App layer filter |
| **Cert Manager / Let's Encrypt** | L6 | TLS automation |
| **GoPhish** | L8 (offensive) | Phishing sim |
| **Zeek / Suricata** | L3-4 | Traffic analysis |
| **CHIPSEC** | L1 | Firmware audit |

## 8. References

- MITRE Unified Kill Chain — https://www.unifiedkillchain.com/
- Stuxnet Analysis — https://www.welivesecurity.com/2011/01/17/...
- SolarWinds (CISA) — https://www.cisa.gov/news-events/cyber-advisories/aa21-077a
- Deepfake Fraud (Reuters) — https://www.reuters.com/...
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework

| Catatan | Hubungan |
|------|----------|
| [[network-security]] | Dasar penjelas fungsi Layer 1 s.d Layer 7 dalam tumpukan jaringan standar. |
| [[cognitive-security-information-operations]] | Penjelas teori perang kognitif dan disinformasi di tingkat Layer 8 (Manusia). |
| [[waf-reverse-proxy-deepdive]] | Dokumentasi sub-sistem WAF yang mengamankan Layer 5 s.d Layer 7 secara terpusat. |
| [[ics-scada-security]] | Penerapan taksonomi serangan pada infrastruktur gardu listrik fisik (Layer 2 & Layer 1). |

> [!callout] 💡
> Serangan modern cascade lintas layer — pertahanan harus dimodelkan sebagai sistem menyeluruh, bukan kontrol per-layer yang terisolasi.
---

audited
---
