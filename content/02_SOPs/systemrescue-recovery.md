---
title: Systemrescue Recovery
tags:
- sops
created: '2026-04-25'
updated: '2026-07-01'
status: pending
---

# 🔬 SOP RECOVERY — Open Source Only (SystemRescue / Kali Live)

> **Environment:** SystemRescue Live USB / Kali Linux Live / Parrot OS Live
> **Filosofi:** Semua tool gratis, semua open source, semua bisa dijalankan dari USB tanpa install.
> **Target:** HDD, SSD, NVMe, USB Flash, Memory Card, DVR/CCTV storage

> [!danger] Golden Rule — Tidak Boleh Dilanggar
> **JANGAN pernah kerja di drive original.**
> Imaging dulu → kerja di image. Satu kesalahan di drive rusak = data hilang permanen.

---

## Peta Alur Keseluruhan

```
DRIVE TARGET MASUK
        │
        ▼
[FASE 0] Identifikasi & Write-Block
        │
        ▼
[FASE 1] Imaging → hasilkan .dd
        │
        ├── Drive sehat → dd / dc3dd
        └── Drive rusak → ddrescue (bisa resume)
        │
        ▼
[FASE 2] Analisis Image
        │
        ├── File system intact → TestDisk / PhotoRec
        ├── Deleted file → fls (Sleuth Kit) / extundelete
        ├── DVR/CCTV video → FFmpeg + manual carving
        └── Deep scan → Autopsy / bulk_extractor
        │
        ▼
[FASE 3] Recovery & Output
        │
        └── Copy file yang berhasil ke drive destination
```

---

## Tools yang Tersedia di SystemRescue (Pre-installed)

| Tool | Fungsi | Sudah Ada di SystemRescue? |
|---|---|---|
| `ddrescue` | Imaging drive rusak, bisa resume | ✅ |
| `dd` | Imaging dasar | ✅ |
| `testdisk` | Recovery partisi + file | ✅ |
| `photorec` | File carving tanpa metadata | ✅ |
| `fsck` | Repair file system | ✅ |
| `fdisk` / `lsblk` | Identifikasi partisi | ✅ |
| `ntfs-3g` | Mount NTFS read-only | ✅ |
| `hexedit` | Hex editor manual | ✅ |
| `strings` | Ekstrak teks dari binary | ✅ |
| `grep` | Pattern search | ✅ |
| `ffmpeg` | Video repair & carving | ⚠️ Install dulu |
| `autopsy` | GUI forensik | ❌ Pakai Kali/Parrot |
| `bulk_extractor` | Scan data sensitif | ❌ Pakai Kali/Parrot |
| `foremost` | File carving | ⚠️ Install dulu |
| `scalpel` | File carving custom | ⚠️ Install dulu |

```bash
# Install tool tambahan di SystemRescue (session aktif, tidak persistent)
pacman -Sy --noconfirm ffmpeg foremost scalpel sleuthkit bulk-extractor
```

---

## FASE 0 — Identifikasi & Persiapan

### 0.1 Lihat Semua Drive yang Terdeteksi

```bash
# Tampilkan semua drive fisik
lsblk -d -o NAME,SIZE,MODEL,ROTA,TRAN
# ROTA=1 → HDD | ROTA=0 → SSD/NVMe

# Detail lengkap dengan serial number
lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINT

# Cek kondisi SMART
smartctl -a /dev/sdX
# Perhatikan: Reallocated_Sector_Ct, Pending_Sector, Uncorrectable_Sector
# Jika nilai ini tinggi → drive rusak, paksa ddrescue bukan dd biasa
```

### 0.2 Write-Block Software (Jika Tidak Punya Hardware Write-Blocker)

```bash
# Set drive target ke read-only SEBELUM apapun
blockdev --setro /dev/sdX

# Verifikasi — harus output: 1
blockdev --getro /dev/sdX

# Mount read-only jika perlu lihat isi
mkdir -p /mnt/target
mount -o ro /dev/sdX1 /mnt/target
```

### 0.3 Hash Baseline — Sidik Jari Drive Original

```bash
# Hash drive original sebelum imaging
sha256sum /dev/sdX | tee evidence_hash_original.txt

# Catat juga info drive
hdparm -I /dev/sdX | tee drive_info.txt
smartctl -a /dev/sdX | tee smart_report.txt
```

---

## FASE 1 — Imaging (Buat Salinan Forensik)

### 1A — Drive Sehat (Tidak Ada Bad Sector)

```bash
# Buat folder evidence
mkdir -p /mnt/evidence/CASE-001/

# Opsi 1: dd biasa (cepat, tidak ada error handling)
dd if=/dev/sdX \
   of=/mnt/evidence/CASE-001/disk.dd \
   bs=4M \
   status=progress \
   conv=noerror,sync

# Opsi 2: dc3dd (hashing on-the-fly, lebih forensic-grade)
dc3dd if=/dev/sdX \
      of=/mnt/evidence/CASE-001/disk.dd \
      hash=sha256 \
      log=/mnt/evidence/CASE-001/imaging.log
```

### 1B — Drive Rusak / Bad Sector (WAJIB ddrescue)

```bash
# Pass 1: Ambil semua yang bisa diambil tanpa retry
ddrescue -f -n \
  /dev/sdX \
  /mnt/evidence/CASE-001/disk.dd \
  /mnt/evidence/CASE-001/rescue.log

# Pass 2: Retry sektor yang gagal (lebih agresif, 3x retry)
ddrescue -d -r3 \
  /dev/sdX \
  /mnt/evidence/CASE-001/disk.dd \
  /mnt/evidence/CASE-001/rescue.log

# Pass 3: Jika masih ada yang gagal, coba dengan trim
ddrescue -d -r1 -T 30s \
  /dev/sdX \
  /mnt/evidence/CASE-001/disk.dd \
  /mnt/evidence/CASE-001/rescue.log

# Cek hasil — berapa sektor yang berhasil vs gagal
ddrescuelog -t /mnt/evidence/CASE-001/rescue.log
```

> [!tip] Kenapa ddrescue Bukan dd untuk Drive Rusak?
> `dd` dengan `conv=noerror` tetap maju linear — jika ketemu bad sector, dia isi dengan nol dan lanjut. Masalahnya: HDD rusak bisa **hang berjam-jam** di satu bad sector.
> `ddrescue` jauh lebih cerdas: skip area rusak dulu, ambil yang sehat, baru kembali retry area rusak. Bisa **resume** jika PC mati di tengah jalan via log file.

### 1C — Verifikasi Image

```bash
# Hash image yang sudah jadi
sha256sum /mnt/evidence/CASE-001/disk.dd | tee evidence_hash_image.txt

# Bandingkan — harus identik jika drive sehat
# Jika drive rusak, hash AKAN berbeda (bad sector diisi nol)
diff evidence_hash_original.txt evidence_hash_image.txt
```

---

## FASE 2A — Analisis General (File Recovery)

### 2A.1 Identifikasi Struktur Image

```bash
# Lihat partisi dalam image
fdisk -l /mnt/evidence/CASE-001/disk.dd

# Atau dengan mmls (Sleuth Kit) — lebih detail
mmls /mnt/evidence/CASE-001/disk.dd

# Identifikasi file system
file /mnt/evidence/CASE-001/disk.dd
fsstat -o [OFFSET] /mnt/evidence/CASE-001/disk.dd
```

### 2A.2 Mount Image untuk Analisis

```bash
# Hitung offset partisi (start sector × 512)
# Contoh: start sector 2048 → offset = 2048 × 512 = 1048576

mkdir -p /mnt/analysis/p1
mount -o ro,loop,offset=1048576 \
  /mnt/evidence/CASE-001/disk.dd \
  /mnt/analysis/p1

# Untuk multiple partisi — pakai kpartx
kpartx -av /mnt/evidence/CASE-001/disk.dd
# Hasilkan: /dev/mapper/loop0p1, loop0p2, dll
mount -o ro /dev/mapper/loop0p1 /mnt/analysis/p1
```

### 2A.3 TestDisk — Recovery Partisi & File Terhapus

```bash
# Jalankan TestDisk di image
testdisk /mnt/evidence/CASE-001/disk.dd
```

```
Menu TestDisk:
1. [Intel/PC] → partition table type
2. [Analyse] → scan struktur partisi
3. [Quick Search] → cari partisi yang hilang
4. [Deeper Search] → jika Quick Search gagal
5. [List] → browse file yang bisa direcovery
6. Tekan C untuk copy file → tentukan destination
```

### 2A.4 PhotoRec — File Carving (Tanpa Struktur Folder)

```bash
# Jalankan PhotoRec
photorec /mnt/evidence/CASE-001/disk.dd
```

```
Setting PhotoRec:
1. Pilih image
2. [File Opt] → pilih tipe file yang mau dicari
   Untuk DVR: aktifkan AVI, MP4, H264
3. [Search] → pilih file system type
4. Tentukan folder output
5. Tunggu — PhotoRec scan seluruh image
```

### 2A.5 Foremost / Scalpel — File Carving Custom

```bash
# Foremost — cari file spesifik
foremost -t jpg,pdf,doc,mp4,avi \
  -i /mnt/evidence/CASE-001/disk.dd \
  -o /mnt/analysis/foremost_out/

# Scalpel — carving dengan konfigurasi custom
# Edit /etc/scalpel/scalpel.conf untuk aktifkan tipe file
# Uncomment baris yang dibutuhkan
scalpel /mnt/evidence/CASE-001/disk.dd \
  -o /mnt/analysis/scalpel_out/
```

### 2A.6 Sleuth Kit — Analisis File System Level Rendah

```bash
# List semua file termasuk yang terhapus
fls -r -p -d /mnt/evidence/CASE-001/disk.dd > deleted_files.txt

# Extract file berdasarkan inode number
# (lihat inode dari output fls)
icat /mnt/evidence/CASE-001/disk.dd [INODE_NUMBER] > recovered_file.ext

# Statistik file system
fsstat /mnt/evidence/CASE-001/disk.dd

# Info inode spesifik
istat /mnt/evidence/CASE-001/disk.dd [INODE_NUMBER]
```

---

## FASE 2B — DVR / CCTV Video Recovery (Open Source)

> DVR menyimpan video dalam format proprietary — bukan MP4/AVI biasa. Tapi di level bytes, semua video H.264/H.265 punya **signature yang bisa dicari**.

### 2B.1 Identifikasi Format DVR

```bash
# Cek signature bytes di image — cari header video
# H.264 NAL unit start: 00 00 00 01
# H.264 SPS: 00 00 00 01 67
# H.265/HEVC: 00 00 00 01 40

hexdump -C /mnt/evidence/CASE-001/disk.dd | grep "00 00 00 01" | head -20

# Atau pakai strings untuk cari metadata
strings /mnt/evidence/CASE-001/disk.dd | grep -i "hikvision|dahua|xmeye|dvr|nvr" | head -20
```

### 2B.2 Scalpel — Custom Config untuk Video DVR

```bash
# Edit /etc/scalpel/scalpel.conf
# Tambahkan baris ini untuk H.264 raw stream:
nano /etc/scalpel/scalpel.conf
```

```
# H.264 raw stream (DVR format)
# Format: extension   case   size    header    footer
h264    y   500000000   \x00\x00\x00\x01\x67   \xff\xe0

# MP4 container
mp4     y   500000000   \x00\x00\x00\x20\x66\x74\x79\x70   \x00\x00\x00\x00

# AVI container (beberapa DVR pakai ini)
avi     y   500000000   RIFF....AVI\x20   \x00\x00\x00\x00

# MKV
mkv     y   500000000   \x1a\x45\xdf\xa3   \x00\x00\x00\x00
```

```bash
# Jalankan Scalpel dengan config custom
scalpel /mnt/evidence/CASE-001/disk.dd \
  -c /etc/scalpel/scalpel.conf \
  -o /mnt/analysis/dvr_carved/
```

### 2B.3 FFmpeg — Repair & Convert Video DVR

```bash
# Coba repair video yang corrupt
ffmpeg -i input_corrupt.mp4 \
  -c copy \
  -avoid_negative_ts make_zero \
  output_repaired.mp4

# Convert raw H.264 stream ke MP4
ffmpeg -f h264 \
  -i raw_stream.h264 \
  -c copy \
  output.mp4

# Extract video dari container DVR proprietary
ffmpeg -i dvr_file.dav \
  -c copy \
  output.mp4

# Repair dengan ignore error
ffmpeg -err_detect ignore_err \
  -i corrupt_video.mp4 \
  -c copy \
  output_fixed.mp4

# Batch convert semua file hasil carving
for f in /mnt/analysis/dvr_carved/h264/*.h264; do
  ffmpeg -f h264 -i "$f" -c copy "${f%.h264}.mp4" 2>/dev/null
done
```

### 2B.4 Manual Hex Carving — Last Resort DVR

```bash
# Cari offset awal video H.264 di image
grep -oaP "(?<=\x00\x00\x00\x01\x67)." /mnt/evidence/CASE-001/disk.dd \
  | hexdump -C | head

# Gunakan dd untuk ekstrak segmen tertentu
# Contoh: video dimulai di offset 1073741824 (1GB), ukuran ~500MB
dd if=/mnt/evidence/CASE-001/disk.dd \
   of=/mnt/analysis/segment.h264 \
   bs=1 \
   skip=1073741824 \
   count=524288000

# Convert hasil ekstrak
ffmpeg -f h264 -i /mnt/analysis/segment.h264 \
  -c copy /mnt/analysis/segment.mp4
```

### 2B.5 Bulk Extractor — Scan Cepat Seluruh Image

```bash
# Install dulu jika belum ada
pacman -Sy --noconfirm bulk-extractor

# Scan image — temukan semua data menarik
bulk_extractor \
  -o /mnt/analysis/bulk_out/ \
  /mnt/evidence/CASE-001/disk.dd

# Output yang dihasilkan:
# bulk_out/jpeg.txt → lokasi semua JPEG di image
# bulk_out/url.txt → semua URL yang pernah diakses
# bulk_out/email.txt → semua alamat email
# bulk_out/video.txt → referensi ke file video (jika ada)
```

---

## FASE 3 — Output & Dokumentasi

### 3.1 Copy File Recovery ke Destination

```bash
# Pastikan destination punya ruang cukup
df -h /mnt/destination/

# Copy dengan preserve timestamp
cp -a /mnt/analysis/recovered/ /mnt/destination/CASE-001-recovered/

# Atau rsync untuk progress yang jelas
rsync -av --progress \
  /mnt/analysis/recovered/ \
  /mnt/destination/CASE-001-recovered/
```

### 3.2 Generate Laporan Sederhana

```bash
# Buat laporan otomatis
cat > /mnt/evidence/CASE-001/report.txt << EOF
===================================
RECOVERY REPORT
===================================
Date    : $(date)
Case    : CASE-001
Tool    : SystemRescue + Open Source

DRIVE INFO:
$(cat drive_info.txt | grep -E "Model|Serial|Capacity")

SMART STATUS:
$(smartctl -H /dev/sdX | grep "overall-health")

HASH ORIGINAL  : $(cat evidence_hash_original.txt)
HASH IMAGE     : $(cat evidence_hash_image.txt)

IMAGING METHOD : ddrescue
RESCUE LOG     : $(ddrescuelog -t rescue.log 2>/dev/null)

FILES RECOVERED:
$(find /mnt/analysis/recovered/ -type f | wc -l) files

VIDEO FRAGMENTS:
$(find /mnt/analysis/dvr_carved/ -name "*.mp4" | wc -l) video segments
===================================
EOF

cat /mnt/evidence/CASE-001/report.txt
```

---

## Quick Reference — Cheat Sheet

```bash
# ═══ IDENTIFIKASI ═══
lsblk -d -o NAME,SIZE,MODEL,ROTA
smartctl -a /dev/sdX

# ═══ WRITE BLOCK ═══
blockdev --setro /dev/sdX

# ═══ IMAGING SEHAT ═══
dd if=/dev/sdX of=disk.dd bs=4M status=progress conv=noerror,sync

# ═══ IMAGING RUSAK ═══
ddrescue -f -n /dev/sdX disk.dd rescue.log   # Pass 1
ddrescue -d -r3 /dev/sdX disk.dd rescue.log  # Pass 2

# ═══ ANALISIS ═══
testdisk disk.dd              # Recovery partisi + file
photorec disk.dd              # File carving
fls -r -p -d disk.dd         # List deleted files

# ═══ DVR/CCTV ═══
foremost -t avi,mp4 -i disk.dd -o ./out/        # Carving video
ffmpeg -f h264 -i raw.h264 -c copy output.mp4   # Convert H264
ffmpeg -err_detect ignore_err -i bad.mp4 -c copy fixed.mp4  # Repair
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| `dd` langsung ke drive rusak tanpa log | `ddrescue` dengan log file — bisa resume |
| Mount drive original RW | `blockdev --setro` dulu, mount `-o ro` |
| Skip hashing | Hash sebelum dan sesudah imaging |
| Simpan image di drive yang sama | Image ke drive **berbeda** / eksternal |
| Panic saat I/O error | `ddrescue` dirancang untuk ini — biarkan jalan |
| PhotoRec langsung ke drive original | PhotoRec dari **image**, bukan original |

---

## 🔗 Lihat Juga

- [[data-recovery|Data Recovery]] — perbandingan tools commercial vs open source
- [[hpa-exorcism|SOP HPA Exorcism]] — prosedur HPA/DCO sebelum imaging
- [[application|Tools Penting]] — hierarki data recovery Level 0–7
- [[embedded-systems|Embedded Systems]] — flash forensics NAND level

---

*SOP Recovery Open Source | SystemRescue · ddrescue · TestDisk · PhotoRec · FFmpeg · DVR Carving*
