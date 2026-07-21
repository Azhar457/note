---
title: Unified Threat Ontology — Cross-Domain Cyber Attacks from Transistor to Human
  (Layer 1 to Layer 8)
tags:
  - unified-theory
  - cyber-security
  - threat-ontology
  - network-security
  - information-operations
  - systems-architecture
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Serangan siber modern tidak pernah terjadi secara terisolasi pada satu layer sistem saja. Catatan ini menyatukan konsep-konsep pertahanan dalam model terpadu (_Unified Threat Ontology_) dari Layer 1 (Fisik/Transistor) hingga Layer 8 (Manusia/Psikologis), merangkum keterkaitan antara [[network-security]], [[blueteam-detection-matrix]], dan [[cognitive-security-information-operations]].

## Daftar Isi

1. [Taksonomi Ancaman Lintas Layer (Layer 1 s.d Layer 8)](#1-taksonomi-ancaman-lintas-layer-layer-1-sd-layer-8)
2. [Pemetaan Rantai Serangan Terpadu (Unified Killchain)](#2-pemetaan-rantai-serangan-terpadu-unified-killchain)
3. [Sub-Sistem Pertahanan jarsWAF di Dalam Ontologi](#3-sub-sistem-pertahanan-jarswaf-di-dalam-ontologi)
4. [Koneksi ke Vault](#4-koneksi-ke-vault)

---

## 1. Taksonomi Ancaman Lintas Layer (Layer 1 s.d Layer 8)

Model ancaman terintegrasi memetakan seluruh attack surface ke dalam 8 layer komprehensif, memperluas model OSI 7 layer standar dengan menambahkan aspek psikologis manusia:

| Layer                | Domain Keamanan        | Target Utama            | Contoh Vektor Serangan                             | Countermeasures / Pertahanan                   |
| -------------------- | ---------------------- | ----------------------- | -------------------------------------------------- | ---------------------------------------------- |
| **L8: Human**        | Psikologi & Kognitif   | Pikiran Operator/Publik | Cognitive Warfare, Social Engineering, Phishing    | MFA, Security Awareness, Zero Trust            |
| **L7: Application**  | Web / API Security     | Aplikasi, jarsWAF, RASP | SQLi, XSS, GraphQL nested query, RCE               | input validation, RASP, WAF, schema validation |
| **L6: Presentation** | Enkripsi / TLS         | Protokol Handshake      | Quantum-cryptography bypass, TLS downgrades        | Post-quantum cryptography, mTLS, TLS 1.3       |
| **L5: Session**      | Autentikasi / Sesi     | Session Token, JWT      | JWT key confusion, Session Hijacking               | `httpOnly` cookies, Token validation (RS256)   |
| **L4: Transport**    | Port & Koneksi         | TCP/UDP sockets         | TCP SYN Flood, Port scanning                       | SYN cookies, firewalls, rate limiting          |
| **L3: Network**      | Routing & IP           | IP Packet, Subnet       | BGP hijacking, IP spoofing, routing loops          | BGPsec, Gossip blocklist, static routing       |
| **L2: Data Link**    | Otomasi Industri / MAC | Gardu, Switch, PLC      | GOOSE poisoning (IEC 61850), MAC spoofing          | Network segmentation, VLAN, 802.1X             |
| **L1: Physical**     | Hardware & Chip        | Transistor, Firmware    | JTAG extraction, Side-channel attacks, Stuxnet USB | Tamper detection, Hardware Root of Trust       |

---

## 2. Pemetaan Rantai Serangan Terpadu (Unified Killchain)

Serangan tingkat tinggi (_Advanced Persistent Threat / APT_) biasanya merayap dari satu layer ke layer lainnya secara sekuensial.

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

## 3. Sub-Sistem Pertahanan jarsWAF di Dalam Ontologi

Untuk menangkal serangan berantai yang memanfaatkan berbagai layer, jarsWAF membagi sub-sistem pertahanannya secara granular sesuai dengan ontologi ancaman ini:

1. **Layer 7 (Application)**: Dilindungi oleh rule-signature engine jarsWAF, OpenAPI schema validator, serta parser query GraphQL.
2. **Layer 6 (Presentation)**: Menggunakan negosiasi kunci hybrid pasca-kuantum (PQC Kyber/Dilithium) untuk mengamankan komunikasi data dari intaian di masa depan.
3. **Layer 5 (Session)**: Melakukan validasi klaim token JWT secara asimetris menggunakan algoritma RS256 secara tersentralisasi.
4. **Layer 3 & 4 (Network/Transport)**: Gossip protocol digunakan untuk mendistribusikan IP blocklist secara cepat ke seluruh node secara kolaboratif guna meredam serangan DDoS (L4) dan pemindaian IP masif (L3).
5. **Layer 7 Internal (Runtime App)**: Memasang RASP (Runtime Application Self-Protection) agent untuk mengawasi langsung jalannya panggilan sistem berbahaya (`execve`) pada web server upstream.

---

## 4. Koneksi ke Vault

| Catatan                                       | Hubungan                                                                                 |
| --------------------------------------------- | ---------------------------------------------------------------------------------------- |
| [[network-security]]                          | Dasar penjelas fungsi Layer 1 s.d Layer 7 dalam tumpukan jaringan standar.               |
| [[cognitive-security-information-operations]] | Penjelas teori perang kognitif dan disinformasi di tingkat Layer 8 (Manusia).            |
| [[waf-reverse-proxy-deepdive]]                | Dokumentasi sub-sistem jarsWAF yang mengamankan Layer 5 s.d Layer 7 secara terpusat.     |
| [[ics-scada-security]]                        | Penerapan taksonomi serangan pada infrastruktur gardu listrik fisik (Layer 2 & Layer 1). |
