---
title: "Digital Forensic — Kompetisi Prep Guide: Memory, Disk, Network, Mobile Forensics, Tools & Teknik"
tags:
  - cyber-security
  - digital-forensic
  - ctf
  - kompetisi
  - forensics
  - library
aliases:
  - "Digital Forensic Competition Guide"
  - "DFIR Forensics Prep"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Panduan persiapan kompetisi **Digital Forensic** — mencakup teknik memory forensic (Volatility), disk forensic (Autopsy/Sleuth Kit), network forensic (Wireshark/Zeek), mobile forensic, serta file carving. Berdasarkan direktori riset di [[research-resource-directory-deep]] dan metodologi di [[ctf-competition-methodology-strategy]]. Target: 30 menit per soal forensic, zero missed evidence.

**Cross-link:** [[ctf-tool-arsenal-universal]] → [[hierarchy-digital-evidence-acquisition]] → [[network-forensics-pcap-analysis]] → [[windows-forensics-artifact-analysis]] → [[file-carving-data-recovery-advanced]] → [[memory-forensics-volatility-deepdive]]

---

## Daftar Isi

- [[#S1 — Strategi Umum Forensic]]
- [[#S2 — Memory Forensic (Volatility)]]
- [[#S3 — Disk Forensic & File Carving]]
- [[#S4 — Network Forensic (PCAP)]]
- [[#S5 — Mobile Forensic]]
- [[#S6 — Windows Artifact Forensic]]
- [[#S7 — Tool Priority Matrix]]
- [[#S8 — Referensi Cepat]]

---

## S1 — Strategi Umum Forensic

Competition forensic berbeda dengan real incident response: waktu terbatas, evidence sudah dipersiapkan, dan biasanya ada **flag** yang dicari.

### Flow Dasar

```
1. IDENTIFIKASI → Tentukan jenis evidence yang dikasih (.mem, .dd, .pcap, .e01)
2. PREPROCESS → Hash, timeline, string extraction
3. ANALISIS → Cari artifact spesifik (file deleted, process hidden, network conn)
4. EKSTRAKSI → Dapatkan flag dalam format yang diminta
5. DOKUMENTASI → Catat langkah untuk writeup
```

### Pertanyaan Kunci Setiap Soal

| Pertanyaan                      | Tools                           | Waktu Target |
| ------------------------------- | ------------------------------- | ------------ |
| "Apa password user?"            | Mimikatz, hashcat, registry     | 5 menit      |
| "IP address attacker?"          | Wireshark, Volatility netscan   | 3 menit      |
| "File apa yang di-download?"    | Timeline, USN journal, prefetch | 10 menit     |
| "Kapan insiden terjadi?"        | $MFT timestamps, event logs     | 5 menit      |
| "Proses apa yang mencurigakan?" | Volatility pstree, pslist       | 5 menit      |

**Golden rule:** Baca soal dulu — jangan langsung scan semua. Soal sering kasih hint evidence type yang relevan.

---

## S2 — Memory Forensic (Volatility)

### Quick Commands

```bash
# Identifikasi profile/image info
volatility3 -f image.mem windows.info
volatility -f image.mem imageinfo  # Vol 2

# Proses
volatility3 -f image.mem windows.pstree
volatility3 -f image.mem windows.pslist
volatility3 -f image.mem windows.psscan  # Hidden process (rootkit)

# Network
volatility3 -f image.mem windows.netscan
volatility3 -f image.mem windows.netstat

# Credentials
volatility3 -f image.mem windows.hashdump
volatility3 -f image.mem windows.lsadump  # LSA secrets

# Files
volatility3 -f image.mem windows.filescan  # File handles
volatility3 -f image.mem windows.mftscan   # MFT entries

# Malware
volatility3 -f image.mem windows.malfind   # Code injection
volatility3 -f image.mem windows.dlllist   # Loaded DLLs
volatility3 -f image.mem windows.cmdline   # Command lines
volatility3 -f image.mem windows.cmdscan   # Cmd history

# Registry
volatility3 -f image.mem windows.registry.printkey --key "Software\Microsoft\Windows\CurrentVersion\Run"
```

### Hunting Checklist

- [ ] **Hidden process** — bandingkan `pslist` vs `psscan` vs `pstree`
- [ ] **Injected code** — `malfind` cek region dengan PAGE_EXECUTE_READWRITE
- [ ] **Network connection** — `netscan` cari IP asing
- [ ] **CMD history** — `cmdscan` atau `consoles` untuk rekonstruksi attacker action
- [ ] **Registry autorun** — `printkey` di Run keys
- [ ] **Dump process** — `memdump -p PID`, lalu analisis dengan strings/binwalk

---

## S3 — Disk Forensic & File Carving

### Sleuth Kit / Autopsy

```bash
# Lihat partition table
mmls image.dd

# Lihat file system info
fsstat -o 2048 image.dd

# Lihat file di direktori
fls -o 2048 image.dd
fls -o 2048 image.dd 65-128-3  # Inode spesifik

# Ekstrak file
icat -o 2048 image.dd 65-128-3 > recovered.jpg

# Timeline
fls -m / -o 2048 -r image.dd > body.txt
mactime -b body.txt > timeline.csv
```

### File Carving (Recover Deleted Files)

```bash
# Foremost — signature-based carving
foremost -t all -i image.dd -o output/

# Scalpel — configurable carving
scalpel -c scalpel.conf -o output/ -i image.dd

# Bulk extractor — ekstrak semua artifact
bulk_extractor -o output/ image.dd

# PhotoRec — file carving komprehensif
photorec /d output/ image.dd
```

### File Signature (Magic Bytes)

```text
JPEG:  FF D8 FF
PDF:   25 50 44 46
ZIP:   50 4B 03 04
PNG:   89 50 4E 47
ELF:   7F 45 4C 46
DOCX:  50 4B 03 04 (ZIP-based)
```

---

## S4 — Network Forensic (PCAP)

### Wireshark Display Filters

```bash
# HTTP
http.request
http.response
http.request.method == POST

# DNS
dns.qry.name contains "malware"
dns.flags.response == 0  # Queries only

# IP
ip.src == 192.168.1.1
ip.addr == 10.0.0.1

# TCP
tcp.port == 443
tcp.flags.syn == 1 and tcp.flags.ack == 0  # SYN scan

# Export objects
# File → Export Objects → HTTP/SMB/TFTP
```

### Zeek (Bro) — Automated Analysis

```bash
# Process PCAP
zeek -r capture.pcap
# Output: conn.log, http.log, dns.log, ssl.log, files.log

# Cek koneksi mencurigakan
cat conn.log | zeek-cut ts id.orig_h id.resp_h proto service duration | sort -k 5 -n

# Ekstrak file dari HTTP
cat files.log | zeek-cut tx_hosts filename mime_type
```

### TShark — Command Line

```bash
# Top talkers
tshark -r capture.pcap -T fields -e ip.src -e ip.dst | sort | uniq -c | sort -rn

# HTTP requests
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# Extract payload
tshark -r capture.pcap -Y "data.data" -T fields -e data.data | xxd -r -p
```

---

## S5 — Mobile Forensic

### Android

```bash
# ADB backup (jika debug mode aktif)
adb backup -f backup.ab -noapk

# Ekstrak backup
dd if=backup.ab bs=24 skip=1 | openssl zlib -d > backup.tar

# SQLite database
sqlite3 /data/data/com.whatsapp/databases/msgstore.db "SELECT * FROM messages;"

# Cari artifact: call log, SMS, contacts, WhatsApp, browser history
```

### iOS

```bash
# Logical acquisition (jailbreak/jam managed)
# Tools: libimobiledevice, iphone-backup-extractor

# Ekstrak backup iTunes
idevicebackup2 backup --full ./backup/
# Parse dengan tools seperti iBackupBot atau libimobiledevice
```

---

## S6 — Windows Artifact Forensic

### Timeline Artifact

| Artifact            | Lokasi                                   | Informasi                             |
| ------------------- | ---------------------------------------- | ------------------------------------- |
| **Prefetch**        | `C:\Windows\Prefetch\`                   | Program execution history             |
| **USN Journal**     | `$UsnJrnl` di NTFS                       | File changes (create, delete, modify) |
| **Event Logs**      | `C:\Windows\System32\winevt\Logs\*.evtx` | Security, System, Application events  |
| **Registry**        | `C:\Windows\System32\config\`            | System config, user activity          |
| **$MFT**            | `$MFT`                                   | All file metadata                     |
| **Browser History** | `%APPDATA%\...`                          | URL history, downloads                |
| **Jump Lists**      | `%APPDATA%\Microsoft\Windows\Recent\`    | Recently opened files                 |
| **Recycle Bin**     | `$Recycle.Bin`                           | Deleted files info                    |

### Tools Cepat

```bash
# PECmd — Prefetch parser
PECmd.exe -f C:\Windows\Prefetch\*.pf

# JLECmd — Jump List parser
JLECmd.exe -f "C:\Users\...\AutomaticDestinations"

# Timeline Explorer — GUI untuk $MFT
# Eric Zimmerman tools — standar industri forensic Windows
```

---

## S7 — Tool Priority Matrix

Berdasarkan [[research-resource-directory-deep]], berikut prioritas tool per kategori forensic:

| Subdomain        | Tool #1              | Tool #2               | Tool #3               |
| ---------------- | -------------------- | --------------------- | --------------------- |
| Memory           | Volatility 3         | strings + grep        | Rekall (legacy)       |
| Disk             | Sleuth Kit + Autopsy | FTK Imager            | Magnet AXIOM          |
| File Carving     | Foremost             | Scalpel               | PhotoRec              |
| Network PCAP     | Wireshark            | Zeek                  | tshark                |
| Mobile (Android) | ADB + sqlite3        | Cellebrite (jika ada) | Oxygen Forensic       |
| Windows Artifact | EZ Tools (Zimmerman) | RegRipper             | Plaso (log2timeline)  |
| Registry         | RegRipper            | Registry Explorer     | python-registry       |
| Browser          | Hindsight (Chrome)   | BHE (Firefox)         | DB Browser for SQLite |

---

## S8 — Referensi Cepat

- [[research-resource-directory-deep]] — sumber riset lengkap
- [[ctf-competition-methodology-strategy]] — strategi umum CTF
- [[ctf-tool-arsenal-universal]] — semua tool CTF
- [[network-forensics-pcap-analysis]] — panduan PCAP
- [[windows-forensics-artifact-analysis]] — artifact Windows
- [[file-carving-data-recovery-advanced]] — file recovery
- [[memory-forensics-volatility-deepdive]] — memory forensic
- [[blueteam-detection-matrix]] — detection mapping
