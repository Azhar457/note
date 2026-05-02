---
tags:
  - incident-report
  - arp-spoofing
  - forensik
  - evidence
  - network-security
  - blue-team
created: 2026-04-30
status: active
aliases:
  - ARP Spoofing Incident Addendum
  - IR Addendum 2026-04-30
---

# 📋 INCIDENT REPORT ADDENDUM — ARP Spoofing 2026-04-30

> **Parent Document:** [[arp-spoofing-mitigation]]
> **Tujuan:** Melengkapi dokumentasi teknis dengan section yang diperlukan standar profesional:
> Timeline detail, Impact Assessment, Evidence Integrity, dan Attacker Fingerprint.
> **Konteks:** Lab exercise — attacker (teman, offensive role) vs defender (kamu, defensive role). Jaringan kampus 192.168.0.0/24.

---

## 1. Incident Overview (Executive Summary)

Pada 2026-04-30, terjadi serangan ARP Spoofing di jaringan kampus (192.168.0.0/24) sebagai bagian dari latihan offensive-defensive antara dua pihak yang diketahui. Attacker menggunakan IP 192.168.0.240 dan melancarkan serangan berlapis: ARP Poisoning (L2) → ICMP Redirect injection (L3) → Multicast Flood (SSDP/mDNS/IGMP). Dampak pada victim (192.168.0.214): koneksi internet terputus dan potensi traffic ter-sniff selama fase MITM aktif. Serangan berhasil diidentifikasi via Wireshark dan dimitigasi secara parsial dari sisi endpoint tanpa akses ke infrastruktur switch/router kampus.

---

## 2. Timeline Detail

> [!info] Catatan Timestamp
> Timestamp di bawah direkonstruksi dari kolom Time di Wireshark capture (relatif dari start capture). Untuk timestamp absolut, lihat kolom "Epoch Time" di Wireshark: `View → Time Display Format → UTC Date and Time`.

### 2.1 Rekonstruksi dari Wireshark Capture

| Timestamp (Relatif) | Frame No. | Event                                                     | Analisis                                                                   |
| ------------------- | --------- | --------------------------------------------------------- | -------------------------------------------------------------------------- |
| T+26.15s            | 7480      | SSDP M-SEARCH dari 192.168.0.240 → 239.255.255.250        | **Flood dimulai** — attacker mulai spam multicast SSDP                     |
| T+27.07s            | 7481      | SSDP M-SEARCH (repeat)                                    | Flood berlanjut dengan interval ~1 detik                                   |
| T+27.99s            | 7484      | SSDP M-SEARCH (repeat)                                    | —                                                                          |
| T+28.91s            | 7535      | SSDP M-SEARCH (repeat)                                    | —                                                                          |
| T+39.36s            | 7550      | IGMPv2 Membership Report 239.255.255.250                  | Attacker join multicast group — persiapan flood lebih dalam                |
| T+61.78s            | 7637      | mDNS query A cap.local dari 192.168.0.240                 | mDNS spam dimulai paralel                                                  |
| T+61.78s            | 7638      | mDNS response 0x0000 A, cache flush 192.168.0.240         | **Cache flush** — paksa victim update cache mDNS                           |
| T+65.78s            | 7658      | mDNS query AAAA cap.local                                 | mDNS IPv6 query spam                                                       |
| T+65.78s            | 7659      | mDNS response AAAA, cache flush fe80::eb93:a360:2d11:6243 | IPv6 address attacker terekspos di sini                                    |
| T+68.54s            | **7672**  | **ICMP Redirect → 192.168.0.214**                         | ⚠️ **KRITIS** — ICMP Type 5 inject ke victim. Internet mulai putus.        |
| T+77.46s            | **7721**  | **ICMP Redirect → 192.168.0.214 (repeat)**                | ⚠️ Attacker kirim ulang redirect — memastikan routing table victim berubah |
| T+77.46s            | 7936      | mDNS query ADB tcp/tls-connect dari 192.168.0.240         | **ANOMALI** — ADB (Android Debug Bridge) query muncul dari IP attacker     |
| T+145.96s           | 8114      | SSDP M-SEARCH (lanjut)                                    | Flood masih berjalan                                                       |
| T+157.94s           | 8154      | mDNS response cache flush (repeat)                        | Cache flush diulang — ARP table refresh paksa                              |
| T+165.01s           | 8175      | IGMPv2 Membership Report 224.0.0.251                      | Join multicast group mDNS — flood level 2                                  |
| T+167.47s           | 8181      | mDNS DESKTOP-G87G0LL.local query                          | Device identifier attacker muncul: **DESKTOP-G87G0LL**                     |

### 2.2 Rekonstruksi Fase Attack

```
[T+0s]      Attacker mulai recon (sebelum capture dimulai)
[T+26s]     SSDP flood dimulai → bandwidth mulai terkuras
[T+39s]     IGMP join → persiapan multicast flood lebih dalam
[T+61s]     mDNS spam + cache flush → ARP/DNS cache victim dikacaukan
[T+68s]     ⚠️ ICMP Redirect Type 5 pertama → routing table victim dimanipulasi
[T+77s]     ⚠️ ICMP Redirect kedua → internet victim putus konfirmasi
[T+78s]     ADB mDNS query muncul → anomali device Android terdeteksi
[T+145s+]   Flood berlanjut — denial of service sustained
```

---

## 3. Impact Assessment

### 3.1 Apa yang Terekspos Selama MITM Aktif

> [!warning] Penting Dipahami
> ARP Spoofing dalam mode MITM "baik" (attacker forward traffic) = semua traffic HTTP **tidak terenkripsi** bisa dibaca attacker. Traffic HTTPS tetap terenkripsi — tapi metadata (hostname, IP tujuan, timing) tetap terlihat.

| Tipe Data                         | Terekspos?         | Kondisi                                               |
| --------------------------------- | ------------------ | ----------------------------------------------------- |
| **HTTP traffic** (plaintext)      | ✅ YA — sepenuhnya | Jika ada situs HTTP yang diakses saat MITM aktif      |
| **HTTPS traffic** (konten)        | ❌ TIDAK           | Dienkripsi TLS — attacker hanya lihat ciphertext      |
| **HTTPS metadata** (hostname, IP) | ⚠️ PARSIAL         | SNI (Server Name Indication) visible di TLS handshake |
| **DNS query**                     | ✅ YA              | DNS biasanya UDP plaintext — query terlihat jelas     |
| **Credential di HTTP**            | ✅ YA              | Form login di situs HTTP = plaintext di capture       |
| **Cookie HTTP**                   | ✅ YA              | Session cookie bisa di-hijack                         |
| **Cookie HTTPS (HttpOnly)**       | ❌ TIDAK           | Protected oleh TLS                                    |
| **mDNS/NetBIOS hostname**         | ✅ YA              | Nama device terbaca: DESKTOP-G87G0LL                  |
| **Traffic pattern/timing**        | ✅ YA              | Bisa inferensi aktivitas meski konten terenkripsi     |

### 3.2 Estimasi Window Eksposur

```
Fase MITM aktif (attacker forward traffic):
→ Dari: T+0 (sebelum capture, ARP poison sudah terjadi)
→ Sampai: T+68s (ICMP Redirect membuat internet putus)
→ Estimasi: beberapa menit (tergantung kapan ARP poison dimulai)

Yang berpotensi ter-capture oleh attacker dalam window ini:
- DNS query semua domain yang dikunjungi
- HTTP traffic jika ada
- Hostname dan IP device di jaringan
- Pola aktivitas browsing (via metadata HTTPS)
```

### 3.3 Data yang Dapat Dikonfirmasi Terekspos

Dari capture yang tersedia (sisi victim):

```
✅ Hostname victim: DESKTOP-G87G0LL (terlihat di mDNS query)
✅ IPv4 victim: 192.168.0.214
✅ IPv6 victim: fe80::eb93:a360:2d11:6243
✅ MAC victim: 1c:1b:b5:42:0d:2e (terlihat di Ethernet frame)
✅ Software yang berjalan: Android ADB (adb._tcp.local, adb-tls-pairing._tcp.local)
```

> [!tip] Untuk Latihan Ini
> Karena ini lab exercise antara dua pihak yang diketahui, impact nyata minimal. Tapi dalam skenario nyata, window eksposur ini cukup untuk credential harvesting jika ada HTTP traffic.

---

## 4. Evidence Integrity

### 4.1 Mengapa Evidence Integrity Penting

Di dunia profesional forensik dan incident response, setiap file bukti harus punya **hash kriptografis** yang diverifikasi sebelum dan sesudah analisis. Tujuannya: membuktikan file tidak dimodifikasi sejak dikumpulkan (chain of custody).

### 4.2 Cara Generate Hash File Wireshark Capture

```powershell
# Windows — hash file .pcapng / .pcap
Get-FileHash "C:\path\to\capture.pcapng" -Algorithm SHA256
Get-FileHash "C:\path\to\capture.pcapng" -Algorithm MD5

# Output format yang harus dicatat:
# Algorithm: SHA256
# Hash: [64 karakter hex]
# Path: [full path file]
```

```bash
# Linux
sha256sum capture.pcapng
md5sum capture.pcapng

# Output:
# [hash]  capture.pcapng
```

### 4.3 Template Evidence Log

```
═══════════════════════════════════════════════════════
EVIDENCE LOG — Incident 2026-04-30
═══════════════════════════════════════════════════════

File           : Wi-Fi_capture_20260430.pcapng
Collected by   : [Nama kamu]
Collection time: 2026-04-30 [HH:MM:SS] WIB
Collection method: Wireshark live capture, interface Wi-Fi
                   Filter applied: ip.addr == 192.168.0.240

SHA256: [HASH — generate dengan perintah di atas]
MD5   : [HASH]

Verified by    : [Nama]
Verified time  : 2026-04-30 [HH:MM:SS] WIB
Integrity      : [ ] VERIFIED  [ ] FAILED

Storage location: [path lokal / cloud]
Backup location : [lokasi backup]

Notes:
- Capture dilakukan dari sisi victim (192.168.0.214)
- Capture dimulai saat anomali pertama terdeteksi
- Filter Wireshark: ip.addr == 192.168.0.240
═══════════════════════════════════════════════════════
```

### 4.4 Chain of Custody Sederhana

```
[COLLECTION]
Siapa    : [Nama kamu]
Kapan    : 2026-04-30
Bagaimana: Wireshark live capture di interface Wi-Fi
           Filter: ip.addr == 192.168.0.240
File     : Wi-Fi_capture_20260430.pcapng
Hash     : [SHA256]
        │
        ▼
[ANALYSIS]
Siapa    : [Nama kamu]
Kapan    : 2026-04-30
Tool     : Wireshark [versi]
Action   : Read-only analysis — file original tidak dimodifikasi
Hash after: [SHA256 — harus identik dengan hash collection]
        │
        ▼
[STORAGE]
Location : [path]
Backup   : [path]
Retention: [berapa lama disimpan]
```

---

## 5. Attacker Fingerprint

### 5.1 Informasi yang Bisa Diekstrak dari Capture

Dari analisis Wireshark capture (sisi victim), attacker meninggalkan jejak berikut:

| Atribut              | Nilai                                                   | Sumber di Capture                                               |
| -------------------- | ------------------------------------------------------- | --------------------------------------------------------------- |
| **IP Address**       | 192.168.0.240                                           | Semua frame — source IP                                         |
| **MAC Address**      | 1c:1b:b5:42:0d:2e                                       | Ethernet header frame 7480                                      |
| **NIC Vendor**       | Intel (prefix 1c:1b:b5)                                 | OUI lookup: Intel Corporate                                     |
| **IPv6 Address**     | fe80::eb93:a360:2d11:6243                               | mDNS response frame 7659                                        |
| **Hostname**         | DESKTOP-G87G0LL                                         | mDNS query frame 8181, 8188, 8224, 8237                         |
| **OS**               | Windows (DESKTOP- prefix = Windows hostname convention) | Hostname pattern                                                |
| **Connected device** | Android device via ADB                                  | mDNS: adb.\_tcp.local, adb-tls-pairing.\_tcp.local (frame 7936) |
| **ADB pairing**      | adb-tls-connect.\_tcp.local aktif                       | mDNS frame 7936 — ADB over TLS                                  |

### 5.2 Analisis ADB Anomali

```
Frame 7936 — mDNS Query dari 192.168.0.240:
  _adb._tcp.local
  _adb-tls-connect._tcp.local
  _adb-tls-pairing._tcp.local

Artinya:
- Attacker punya Android device terhubung via ADB (USB atau wireless)
- ADB over TLS aktif → Android 11+ (TLS ADB diperkenalkan Android 11)
- Device sedang dalam mode "pairing" atau sudah terpasang

Implikasi forensik:
- Attacker bukan hanya laptop — ada Android device di ekosistemnya
- Jika Android device juga di jaringan yang sama → ada IP tambahan
- ADB active saat attack = kemungkinan Android dipakai sebagai tool bantu
  atau sekadar device pribadi yang kebetulan terhubung
```

### 5.3 OUI Lookup — Vendor Identification

```bash
# Cara lookup vendor dari MAC address
# Online: https://www.wireshark.org/tools/oui-lookup.html
# CLI di Linux:
grep -i "1c:1b:b5" /usr/share/wireshark/manuf

# MAC 1c:1b:b5 → Intel Corporate
# Artinya: NIC Intel (built-in laptop atau PCIe Intel NIC)
# Bukan USB adapter — kemungkinan laptop dengan NIC onboard Intel
```

### 5.4 Fingerprint Summary

```
ATTACKER PROFILE (dari network forensik saja):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IP (v4)    : 192.168.0.240
IP (v6)    : fe80::eb93:a360:2d11:6243
MAC        : 1c:1b:b5:42:0d:2e (Intel NIC)
Hostname   : DESKTOP-G87G0LL
OS         : Windows (dari hostname convention)
Device type: Laptop/Desktop dengan Intel NIC
Extra      : Android device terhubung via ADB (Android 11+)
Tool used  : Tidak bisa dikonfirmasi 100% — kemungkinan
             Bettercap atau Ettercap berdasarkan behavior pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CATATAN: Semua informasi di atas dari analisis traffic pasif
(sisi victim). Untuk konfirmasi penuh butuh akses ke mesin
attacker atau log switch/router.
```

---

## 6. Lessons Learned

### 6.1 Yang Berhasil

- Identifikasi attack vector via Wireshark — traffic analysis efektif
- Disable ICMP Redirect — langsung atasi penyebab internet putus
- Dokumentasi real-time selama incident

### 6.2 Yang Gagal / Bisa Diperbaiki

| Kesalahan                            | Root Cause                                                               | Perbaikan                                                                  |
| ------------------------------------ | ------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Block full inbound+outbound attacker | Tidak paham bahwa attacker = "gateway" di ARP table yang sudah di-poison | Pahami state ARP table dulu sebelum block — selective block saja           |
| Tidak capture dari awal              | Wireshark baru aktif setelah anomali terdeteksi                          | Setup Wireshark capture sebelum aktivitas apapun di jaringan tidak dikenal |
| Tidak hash file capture segera       | Lupa prosedur evidence integrity                                         | Langsung hash setelah stop capture sebelum file diapa-apakan               |
| Static ARP tidak persistent          | Windows override ARP entry saat ada reply agresif                        | Gunakan Task Scheduler untuk re-apply static ARP setiap boot               |

### 6.3 Rekomendasi ke Depan

```
Sebelum connect ke jaringan tidak trusted (kampus, cafe, publik):
1. Catat MAC gateway asli dulu (arp -a saat jaringan bersih)
2. Pre-set script defense (script PowerShell di parent doc)
3. Aktifkan VPN sebelum browsing sensitif
4. Jalankan arpwatch atau XArp di background
5. Kalau mau latihan lagi → setup isolated VLAN atau GNS3/EVE-NG
   agar tidak ganggu user lain di jaringan kampus
```

---

## 7. Referensi Standar Profesional

Dokumen ini mengikuti framework berikut (disederhanakan untuk konteks latihan):

| Framework                                                      | Bagian yang Diadopsi                         |
| -------------------------------------------------------------- | -------------------------------------------- |
| **NIST SP 800-61** (Computer Security Incident Handling Guide) | Timeline, impact assessment, lessons learned |
| **SANS DFIR Methodology**                                      | Evidence integrity, chain of custody         |
| **ISO/IEC 27035** (Incident Management)                        | Dokumentasi struktural                       |
| **Wireshark Best Practices**                                   | Evidence capture, hash verification          |

---

## 🔗 Lihat Juga

- [[arp-spoofing-mitigation]] — dokumen teknis mitigasi lengkap
- [[Application|Tools Penting]] — hierarki network security threat landscape
- [[web-hacking|Web Hacking]] — multi-layer attack mindset yang overlap
- [[underground-knowledge|Underground Knowledge]] — tool offensive (Bettercap/Ettercap context)

---

_ARP Spoofing Incident Addendum | Timeline · Impact · Evidence · Attacker Fingerprint | 2026-04-30_
