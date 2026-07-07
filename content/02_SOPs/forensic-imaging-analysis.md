---
title: Forensic Imaging Analysis
tags:
  - 02-sops
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

# 🔬 Master SOP — Digital Forensics Workflow: Imaging → Analysis → Recovery

> **Environment:** Bare-Metal / Live USB (SystemRescue, Kali Linux, Paladin)
> **Status:** Production Ready
> **Target:** HDD, SSD, NVMe, USB Flash, Memory Cards, Mobile Devices
> **Goal:** Forensic Soundness ↔️ Evidence Integrity ↔️ Maximum Data Recovery

---

## 🚦 FASE 0: Chain of Custody & Evidence Seizure

**Prinsip Utama:** _"Never work on original evidence. Always create forensic image first."_

### 0.1 Pre-Acquisition Triage

Dokumentasikan kondisi fisik dan logis sebelum sentuhan apapun.

```bash
# 1. Catat waktu, lokasi, dan identitas penyita
# 2. Foto kondisi fisik device (port, label, kerusakan)
# 3. Catat apakah device ON atau OFF saat ditemukan

# 4. Jika device HIDUP → Lakukan Live Acquisition (Volatile Data)
#    - RAM Dump (Critical! Data volatile hilang saat mati)
#    - Network connections, running processes, open files
#    - Encrypted volumes yang sedang mounted
```

### 0.2 Write-Blocking & Hardware Protection

**WAJIB** gunakan write-blocker hardware sebelum colok ke workstation.

| Write-Blocker      | Interface       | Catatan                     |
| ------------------ | --------------- | --------------------------- |
| Tableau T35u       | SATA/USB 3.0    | Gold standard forensik      |
| WiebeTech USB 3.0  | Multi-interface | Portable, field-ready       |
| CRU Ditto          | SAS/SATA/NVMe   | Enterprise-grade            |
| Soft Block (Linux) | Emergency only  | `blockdev --setro /dev/sdX` |

```bash
# Verifikasi write-block aktif (Soft block emergency)
blockdev --getro /dev/sdX
# Output harus: 1 (read-only)

# Jika belum read-only, SET SEKARANG!
blockdev --setro /dev/sdX
```

### 0.3 Evidence Labeling & Hashing Baseline

```bash
# Generate hash dari device asli SEBELUM imaging
sha256sum /dev/sdX > evidence_sha256_original.txt
md5sum /dev/sdX > evidence_md5_original.txt

# Format penamaan evidence
# EVIDENCE_[CASE-ID]_[YYYYMMDD]_[ITEM-NO]_[INVESTIGATOR]
# Contoh: EVIDENCE_CYB2026_0428_001_AZHAR
```

---

## 🛡️ ALUR A: Forensic Imaging (Bit-for-Bit Copy)

**Tujuan:** Membuat duplikat forensik yang identik 100% dengan original.

### FASE A1: Imaging Level 1 — Raw Image (.dd / .raw)

Cocok untuk: HDD/SSD kecil, kasus sederhana, tool universal.

```bash
# 1. Buat direktori evidence
mkdir -p /mnt/evidence/CASE-2026-001/

# 2. Imaging dengan dd (Basic, tidak resume)
dd if=/dev/sdX of=/mnt/evidence/CASE-2026-001/disk_image.dd bs=64K status=progress

# 3. Imaging dengan dc3dd (Forensic-grade, hashing on-the-fly)
dc3dd if=/dev/sdX of=/mnt/evidence/CASE-2026-001/disk_image.dd   hash=md5 hash=sha256 log=/mnt/evidence/CASE-2026-001/imaging.log

# 4. Imaging dengan dcfldd (Logging & progress bar)
dcfldd if=/dev/sdX of=/mnt/evidence/CASE-2026-001/disk_image.dd   bs=512 hash=sha256 hashlog=/mnt/evidence/CASE-2026-001/hash.log
```

### FASE A2: Imaging Level 2 — Advanced Recovery (Bad Sector Handling)

Cocok untuk: Drive rusak, bad sector, sering hang, clicking sound.

```bash
# 1. ddrescue — Raja imaging drive rusak (BISA RESUME!)
ddrescue -f -n /dev/sdX /mnt/evidence/CASE-2026-001/disk_image.dd   /mnt/evidence/CASE-2026-001/rescue.log

# 2. Retry sektor yang gagal (pass kedua, lebih agresif)
ddrescue -d -r3 /dev/sdX /mnt/evidence/CASE-2026-001/disk_image.dd   /mnt/evidence/CASE-2026-001/rescue.log

# 3. ddrescue dengan splitting (untuk drive BESAR >2TB)
ddrescue -c 4096 -b 512 -f -n /dev/sdX image_part1.dd rescue1.log
# Lanjutkan part berikutnya jika perlu
```

### FASE A3: Imaging Level 3 — Enterprise & Mobile

Cocok untuk: RAID arrays, Logical Volume, Mobile forensics.

```bash
# 1. E01 Format (EnCase) — Compressed + CRC + Metadata
ewfacquire /dev/sdX -t /mnt/evidence/CASE-2026-001/disk_image   -C case2026 -D "Evidence HDD" -e "Azhar" -b 64 -c best -S 1.5GiB

# 2. AFF4 Format — Next-gen forensic format (Volatility compatible)
aff4imager -i /dev/sdX -o /mnt/evidence/CASE-2026-001/disk_image.aff4

# 3. Mobile Device Imaging (ADB untuk Android)
adb backup -apk -shared -all -f /mnt/evidence/CASE-2026-001/mobile_backup.ab
# Untuk iOS: gunakan iTunes backup + GrayKey/Cellebrite
```

### FASE A4: Verification & Integrity Check

```bash
# 1. Hash image yang sudah jadi
sha256sum /mnt/evidence/CASE-2026-001/disk_image.dd > image_sha256.txt

# 2. Bandingkan dengan hash original
diff evidence_sha256_original.txt image_sha256.txt
# Harus IDENTIK! Jika beda → imaging gagal, ulangi.

# 3. Mount image read-only untuk verifikasi
mkdir -p /mnt/verify
mount -o ro,loop /mnt/evidence/CASE-2026-001/disk_image.dd /mnt/verify
ls -la /mnt/verify
umount /mnt/verify
```

---

## 🔍 ALUR B: Forensic Analysis (Investigasi Image)

**Prinsip:** _"Analysis dilakukan pada IMAGE, bukan original device."_

### FASE B1: File System Analysis

```bash
# 1. Identifikasi file system & partisi
file /mnt/evidence/CASE-2026-001/disk_image.dd
fdisk -l /mnt/evidence/CASE-2026-001/disk_image.dd
mmls /mnt/evidence/CASE-2026-001/disk_image.dd

# 2. Mount image dengan offset (jika ada multiple partitions)
kpartx -av /mnt/evidence/CASE-2026-001/disk_image.dd
# Output: loop0p1, loop0p2, dll

# 3. Mount partisi spesifik (READ-ONLY!)
mkdir -p /mnt/analysis/p1
mount -o ro,loop,offset=1048576 /mnt/evidence/CASE-2026-001/disk_image.dd /mnt/analysis/p1
# Offset didapat dari `mmls` atau `fdisk -l` (start sector × 512)
```

### FASE B2: Automated Analysis Tools

| Tool                     | Fungsi                    | Use Case                                        |
| ------------------------ | ------------------------- | ----------------------------------------------- |
| **Autopsy**              | GUI forensik lengkap      | Timeline analysis, keyword search, file carving |
| **Sleuth Kit (TSK)**     | CLI forensik              | `fls`, `ils`, `icat` untuk analisis file system |
| **Volatility**           | Memory forensics          | Analisis RAM dump: process, network, malware    |
| **Plaso / log2timeline** | Timeline super-detailed   | Rekonstruksi aktivitas per-detik                |
| **Bulk Extractor**       | Scan cepat                | Email, CC, URL, SSN dari seluruh image          |
| **PhotoRec**             | File carving              | Recovery file tanpa metadata (header/footer)    |
| **Scalpel**              | File carving (custom)     | Definisi header/footer sendiri                  |
| **Foremost**             | File carving (predefined) | Recovery file umum: jpg, doc, pdf               |

```bash
# 1. Sleuth Kit — List deleted files
fls -r -p /mnt/evidence/CASE-2026-001/disk_image.dd > deleted_files.txt

# 2. Bulk Extractor — Scan semua data sensitif
bulk_extractor -o /mnt/analysis/bulk_out/ /mnt/evidence/CASE-2026-001/disk_image.dd

# 3. PhotoRec — Carving file (tanpa nama file & folder)
photorec /d /mnt/analysis/recovered_files /mnt/evidence/CASE-2026-001/disk_image.dd

# 4. Foremost — Carving dengan predefined types
foremost -t jpg,pdf,doc,zip -i /mnt/evidence/CASE-2026-001/disk_image.dd   -o /mnt/analysis/foremost_out/

# 5. Strings analysis (untuk data mentah)
strings -n 8 /mnt/evidence/CASE-2026-001/disk_image.dd | grep -i "password|secret|key" > strings_analysis.txt
```

### FASE B3: Timeline & Metadata Analysis

```bash
# 1. log2timeline — Buat timeline super detailed
log2timeline.py /mnt/analysis/timeline.plaso /mnt/evidence/CASE-2026-001/disk_image.dd

# 2. psort — Sort & filter timeline
psort.py -z "Asia/Jakarta" -o l2tcsv /mnt/analysis/timeline.plaso > timeline.csv

# 3. ExifTool — Analisis metadata file
exiftool -r /mnt/analysis/p1/ > metadata_report.txt

# 4. Analyze MFT (NTFS Master File Table)
analyzeMFT.py -f /mnt/evidence/CASE-2026-001/disk_image.dd -o mft_analysis.csv
```

### FASE B4: Keyword Search & Pattern Matching

```bash
# 1. grep dengan regex (case-insensitive)
grep -rai "password|passwd|secret|token|api_key" /mnt/analysis/p1/ > keyword_hits.txt

# 2. YARA — Pattern matching malware/IOC
yara -r /rules/malware_rules.yar /mnt/analysis/p1/ > yara_hits.txt

# 3. Regular Expressions (CC, email, phone)
grep -roE "[0-9]{4}[[space]]?[0-9]{4}[[space]]?[0-9]{4}[[space]]?[0-9]{4}" /mnt/analysis/p1/ > cc_numbers.txt
```

---

## 🔄 ALUR C: Data Recovery (Dari Image atau Drive Langsung)

**Catatan:** Recovery dari IMAGE lebih aman. Recovery langsung hanya jika image gagal dibuat.

### FASE C1: Logical Recovery (File System Intact)

```bash
# 1. TestDisk — Recovery partisi & file yang terhapus
testdisk /mnt/evidence/CASE-2026-001/disk_image.dd
# Pilih: [Intel] → [Analyse] → [Quick Search] → [Deeper Search] → [List] → Copy files

# 2. R-Studio (via Wine/Linux) — Recovery GUI powerful
# atau gunakan PhotoRec untuk recovery tanpa struktur folder

# 3. Extundelete — Recovery file ext3/ext4 yang terhapus
extundelete /mnt/evidence/CASE-2026-001/disk_image.dd --restore-all
```

### FASE C2: Physical Recovery (Drive Rusak / Firmware Corrupt)

```bash
# 1. Jika drive terdeteksi tapi tidak bisa diakses → Firmware issue
#    Gunakan: PC-3000 (Rusia) atau Dolphin (China) untuk firmware repair

# 2. Jika drive clicking / not spinning → Hardware failure
#    Bawa ke clean room untuk head swap / platter transplant

# 3. Jika bad sector parah → ddrescue (lihat FASE A2)
```

### FASE C3: DVR / CCTV Video Recovery

```bash
# 1. Dolphin Data Lab — Spesialis recovery video DVR
#    - Support 99% merek DVR: Hikvision, Dahua, XMeye, dll
#    - Bisa recovery video yang ter-overwrite (loop recording)
#    - Deep scan untuk fragmentasi video khusus DVR

# 2. PC-3000 + Video Recovery plugin
#    - Untuk DVR yang menggunakan harddisk standar
#    - Firmware repair + file carving video

# 3. Manual hex analysis (last resort)
#    - Cari signature video: H264, H265, MPEG4
#    - Reconstruct fragments secara manual
```

---

## 📊 Reporting & Chain of Custody Closure

### Format Laporan Forensik

```
═══════════════════════════════════════════════════════════════
FORENSIC ANALYSIS REPORT
Case ID: [CASE-2026-001]
Investigator: [Nama]
Date: [YYYY-MM-DD]
═══════════════════════════════════════════════════════════════

1. EVIDENCE INFORMATION
   - Device Type: [HDD/SSD/NVMe/Mobile]
   - Capacity: [Size]
   - Serial Number: [SN]
   - Condition: [Physical/Labelling]

2. ACQUISITION DETAILS
   - Method: [dd/dc3dd/ddrescue/ewfacquire]
   - Image Path: [Path]
   - Hash Original: [SHA256]
   - Hash Image: [SHA256]
   - Integrity: [VERIFIED / FAILED]

3. ANALYSIS FINDINGS
   - File System: [NTFS/ext4/APFS]
   - Deleted Files: [Count]
   - Recovered Files: [Count]
   - Keywords Found: [List]
   - Timeline: [Summary]

4. CONCLUSION
   - [Summary of findings]

5. ATTACHMENTS
   - Hash logs
   - Timeline CSV
   - Screenshots
═══════════════════════════════════════════════════════════════
```

---

## ⚠️ Pro-Tips & Anti-Patterns

| ❌ Jangan                     | ✅ Lakukan                                      |
| ----------------------------- | ----------------------------------------------- |
| Mount original device RW      | Selalu mount read-only atau pakai write-blocker |
| Skip hashing                  | Hash sebelum & sesudah imaging WAJIB            |
| Kerja langsung di drive rusak | Always imaging dulu, analysis dari image        |
| Lupa catat Chain of Custody   | Dokumentasikan setiap sentuhan                  |
| Panik saat I/O error          | Gunakan ddrescue, sabar, bisa resume            |
| Recovery tanpa backup image   | Image dulu, recovery dari image                 |

### Thermal & Handling

- **Suhu aman HDD saat imaging:** < 45°C
- **Jika > 50°C:** Hentikan, dinginkan dengan fan, lanjutkan
- **Click of Death:** STOP! Jangan force spin-up, bawa ke lab

---

> [!CAUTION] **Forensic Golden Rule:** _"You only get ONE chance with original evidence. Do it right the first time."_
