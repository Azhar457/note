---
title: "File Carving & Data Recovery — Advanced Techniques"
tags:
  - file-carving
  - data-recovery
  - forensic-investigation
  - disk-forensics
  - dfir
aliases:
  - "file-carving-data-recovery-advanced"
created: '2026-07-28'
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  - callout

---

# 🧩 File Carving & Data Recovery — Advanced Techniques

> **File carving adalah teknik merekonstruksi file dari raw data tanpa metadata filesystem** — berguna ketika filesystem corrupt, file sudah dihapus, atau Anda hanya punya blok mentah (dd image) tanpa tabel partisi. Ini adalah **teknik paling vital dalam digital forensic** karena file yang dihapus sering menyimpan bukti paling penting — malware yang sudah dibersihkan, dokumen yang dihapus attacker, atau flag yang ditinggalkan di unallocated space. Dari [[hierarchy-digital-evidence-acquisition]], ini ada di **Level 4 — active persistent storage** dan **Level 3 — transient files**.

> [!tip] Prinsip Emas Carving
> **"Deleted ≠ Gone."** File yang dihapus tidak hilang — hanya inode/entrinya yang ditandai sebagai tersedia. Data fisik tetap ada di media sampai ditimpa file baru. Dengan tool carving yang tepat, file yang "dihapus" 5 tahun lalu pun bisa direcover — selama belum ditimpa.

---

## Daftar Isi

- [[#Teori Dasar — Bagaimana File Bisa Di-recover]]
- [[#File Signature — Magic Bytes]]
- [[#Carving Tools — Benchmark & Use Case]]
- [[#Advanced Carving — Fragmented File Recovery]]
- [[#SSD & TRIM — Musuh Besar Carving]]
- [[#Recovery by File Type]]
- [[#Anti-Forensics & Counter-Measures]]
- [[#Carving in CTF Context]]
- [[#Cheat Sheet — Command Matrix]]

---

## Teori Dasar — Bagaimana File Bisa Di-recover

### Struktur File di Disk

```
┌─────────────────────────────────────────────────────────┐
│  $MFT Entry (alokasi file)                              │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │ Header  │ │ Filename │ │ Metadata │ │ Data Runs   │ │
│  │ (0x46)  │ │ Namaku.txt│ │ size, ts │ │ cluster 100→│ │
│  └─────────┘ └──────────┘ └──────────┘ └──────┬──────┘ │
│                                                 │
└─────────────────────────────────────────────────┼───────┘
                                                   │
                    ┌──────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────┐
│  Cluster 100-105 (Data Run)                             │
│  ┌──────┬──────┬──────┬──────┬──────┬──────┐           │
│  │HDR   │DATA  │DATA  │DATA  │DATA  │DATA  │           │
│  │0xFFDB│Namaku│...   │...   │...   │...   │           │
│  └──────┴──────┴──────┴──────┴──────┴──────┘           │
└─────────────────────────────────────────────────────────┘
```

**Saat file dihapus:**
1. $MFT entry ditandai `not in use` (byte pertama = 0x00)
2. Data cluster **tidak dihapus** — hanya ditandai sebagai tersedia (available)
3. File Name di Recycle Bin dipindahkan, tapi data asli tetap di cluster asli
4. SSD TRIM → cluster benar-benar dikosongkan (diisi 0x00)

### Konsep Carving

```
┌─────────────────────────────────────────────────────┐
│  Unallocated Space (raw bytes)                      │
│  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐│
│  │0xFF│0xD8│0xFF│0xE0│0x00│0x10│0x4A│0x46│... │0xFF││
│  │    │ ^^^^^^^ JPEG Header ^^^^^^^^^^    │  │0xD9││
│  │    │ ────────── JPEG Data ─────────────   │    ││
│  └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘│
│                                                    │
│  Carving: cari magic bytes → baca sampai footer     │
│  → extract cluster → file utuh                      │
└─────────────────────────────────────────────────────┘
```

**Carving tidak menggunakan metadata filesystem.** Ia hanya mencari pola bytes (magic number) di raw data, lalu mengikuti struktur file untuk membaca seluruh konten hingga footer.

### Carving vs File System Recovery

| Aspek | File System Recovery | File Carving |
|-------|---------------------|--------------|
| **Metode** | Rekonstruksi $MFT / inode table | Cari magic bytes |
| **Butuh metadata** | Ya — butuh entry utuh | Tidak |
| **File terfragmentasi** | Bisa recover (ada di metadata data runs) | Sulit — hanya contiguous |
| **SSD TRIM** | Tidak bisa | Tidak bisa |
| **File overwrite** | Tidak bisa | Sebagian — file rusak |
| **Tools** | TestDisk, R-Studio, GetDataBack | foremost, scalpel, photorec |

---

## File Signature — Magic Bytes

### Universal Signatures

Setiap format file punya **magic bytes** — byte pertama yang unik. Carving tool menggunakan database signature ini.

```bash
# Signatures built-in di foremost:
/etc/foremost.conf

# Signatures built-in di scalpel:
/etc/scalpel/scalpel.conf

# Cari sendiri — cek header file
xxd file.jpg | head -1
# Output: 00000000: ffd8 ffe0 0010 4a46 4946 0001 ...  → JPEG
```

### Magic Bytes Reference (Paling Sering di CTF)

| Format | Magic Bytes (Hex) | Offset | Footer (Hex) |
|--------|-------------------|:------:|--------------|
| **JPEG** | `FF D8 FF E0` atau `FF D8 FF E1` | 0 | `FF D9` |
| **PNG** | `89 50 4E 47 0D 0A 1A 0A` | 0 | `49 45 4E 44 AE 42 60 82` |
| **GIF** | `47 49 46 38 37 61` atau `38 39 61` | 0 | `00 3B` |
| **BMP** | `42 4D` | 0 | — |
| **TIFF** | `49 49 2A 00` atau `4D 4D 00 2A` | 0 | — |
| **PDF** | `25 50 44 46` (*%PDF*) | 0 | `25 25 45 4F 46` (%%EOF) |
| **ZIP** | `50 4B 03 04` | 0 | `50 4B 05 06` (EOCD) |
| **RAR** | `52 61 72 21 1A 07 00` | 0 | — |
| **7z** | `37 7A BC AF 27 1C` | 0 | — |
| **GZIP** | `1F 8B 08` | 0 | — |
| **BZ2** | `42 5A 68` | 0 | — |
| **ELF** | `7F 45 4C 46` (*.ELF*) | 0 | — |
| **RIFF (AVI/WAV)** | `52 49 46 46 xx xx xx xx 41 56 49` | 0 | — |
| **MP3 (ID3v2)** | `49 44 33` (*ID3*) | 0 | — |
| **MP4** | `00 00 00 18 66 74 79 70` | 0 | — |
| **DOCX/XLSX (ZIP)** | `50 4B 03 04 14 00 06 00` | 0 | `50 4B 05 06` |
| **Mach-O** | `FE ED FA CE` atau `FE ED FA CF` | 0 | — |

### Custom Signature — Cari Flag Manual

```bash
# Cari string CTF/flag di raw image
strings disk.dd | grep -i "CTF\|flag\|KEY\|secret"

# Cari di unallocated space khusus
# Gunakan blkls dari Sleuth Kit
blkls -s disk.dd > unallocated.raw
strings unallocated.raw | grep -i "CTF\|flag"

# Cari magic bytes manual dengan xxd
xxd disk.dd | grep "ffd8 ffe0"  # Cari JPEG header di raw
```

---

## Carving Tools — Benchmark & Use Case

### Foremost (Tier 1 — Default)

**Kelebihan:** Cepat, default signatures built-in, mudah.
**Kekurangan:** Tidak bisa fragmented file recovery, konfigurasi terbatas.

```bash
# Basic carving — cari semua tipe file
foremost -i disk.dd -o output/

# Carving dengan tipe spesifik — cuma JPEG + PDF
foremost -t jpeg,pdf -i disk.dd -o output/

# Verbose + quiet mode
foremost -v -q -i disk.dd -o output/

# Config file
foremost -c /etc/foremost.conf -i disk.dd -o output/
```

**Output structure:**
```
output/
├── audit.txt       # Log carving: file ditemukan, size, offset
├── jpg/            # Recovered JPEG files
│   ├── 00000001.jpg
│   ├── 00000002.jpg
│   └── ...
├── pdf/
├── zip/
└── ...
```

### Scalpel (Tier 2 — More Configurable)

**Kelebihan:** Konfigurasi signature sangat detail, bisa custom header/footer.
**Kekurangan:** Config file perlu diedit dulu — tidak langsung jalan.

```bash
# Edit /etc/scalpel/scalpel.conf — uncomment tipe file yang dicari
# Contoh:
# jpeg    y       200000000     \xff\xd8\xff\xe0\x00\x10\x4a\x46\x49\x46\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xfe\x00\x3c\x43\x52\x45\x41\x54\x4f\x52\x3a\x20\x47\x64\x6a\x70\x65\x67\x20\x76\x65\x72\x20\x31\x2e\x30\x0a\xff\xdb\x00\x43\x00\x03\x02\x02\x03\x02\x02\x03\x03\x03\x03\x04\x03\x03\x04\x05\x08\x05\x05\x04\x04\x05\x0a\x07\x07\x06\x08\x0c\x0a\x0c\x0c\x0b\x0a\x0b\x0b\r\x0e\x12\x10\x0d\x0e\x11\x0e\x0b\x0b\x10\x16\x10\x11\x13\x14\x15\x15\x15\x0c\x0f\x17\x18\x16\x14\x18\x12\x14\x15\x14

# Jalankan carving
scalpel -i disk.dd -o output/
```

### PhotoRec (Tier 1 — Most File Types)

**Kelebihan:** Mendukung 480+ file signature, bisa photRec dari partisi yang tidak dikenal.
**Kekurangan:** Interactive (bukan CLI murni), lambat untuk file besar.

```bash
# PhotoRec adalah interactive — harus pilih disk, partisi, output
sudo photorec /path/to/disk.dd
# Pilih file type → [File Opt] → Select all
# Pilih destination → [Search]
```

### Bulk Extractor (Tier 2 — Feature Extraction)

**Kelebihan:** Mengekstrak **feature** bukan file — URL, email, credit card, hash, DNA sequences. Sampai ribuan feature per detik.
**Kekurangan:** Tidak menghasilkan file utuh — hanya ekstrak feature.

```bash
bulk_extractor -o output/ disk.dd
# Output: url.txt, email.txt, telephone.txt, etc.
# Di CTF: cari flag.txt, base64.txt

# Cari flag di hasil bulk_extractor
grep -i "CTF\|flag" output/*.txt
```

### ddrescue (Tier 2 — Damaged Media)

**Kelebihan:** Bisa recover data dari disk yang mulai rusak (bad sector).
**Kekurangan:** Butuh waktu lama — mencoba baca ulang sector berkali-kali.

```bash
# Clone disk yang rusak — log bad sector ke mapfile
ddrescue -d -r3 /dev/sdb disk_image.dd rescue.log

# Retry bad sector dengan backtrack
ddrescue -d -r3 -R /dev/sdb disk_image.dd rescue.log
```

---

## Advanced Carving — Fragmented File Recovery

### 4.1 The Fragmentation Problem

```
Contiguous file (mudah):
┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
│HDR  │D1   │D2   │D3   │D4   │D5   │D6   │D7   │D8   │D9   │ → utuh
└────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘

Fragmented file (sulit):
┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
│HDR  │D1   │  OTHER │  FILE  │D2   │D3   │D4   │D5   │
└────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
                  ^^^^^^^^^^^ data file lain menyela
```

**Fragmented file adalah tantangan terbesar carving.** Sebagian besar tool hanya bisa recover file yang **contiguous** (blok datanya berurutan). File terfragmentasi butuh teknik khusus:

### 4.2 Bifragment Gap Carving (BGC)

Untuk file yang **terpecah menjadi 2 bagian** dengan celah di tengah:

```bash
# Tool: smartmontools + custom script
# Atau gunakan scalpel dengan konfigurasi multi-segment

# Prinsip: cari header → baca N bytes → cek apakah footer tercapai
# Jika tidak → ada gap → cari sisa setelah gap
```

**BGC hanya untuk 2 fragment — untuk 3+ fragment, carving sangat sulit bahkan dengan tool mahal.**

### 4.3 Object-Based Carving

Bukan cari header/footer file, tapi cari **struktur internal file**. Contoh untuk ZIP:

```bash
# ZIP central directory (EOCD) — bisa recover file ZIP walaupun terfragmentasi
# Tools: zip, unzip, custom Python parser

# ZIP file walau fragmented bisa di-recover kalau EOCD-nya utuh
# EOCD ada di END file — mencari dari offset terakhir disk

# Foremost bisa recover ZIP fragmented dengan config khusus
# Edit /etc/foremost.conf → maksimum carving size dinaikkan
```

### 4.4 Machine Learning Carving (Advanced)

Beberapa tool baru pakai ML untuk mendeteksi perbatasan file — tapi **jarang di CTF** karena resource heavy. Relevan untuk penelitian forensik.

---

## SSD & TRIM — Musuh Besar Carving

### Bagaimana TRIM Bekerja

```
┌─────────────────────────────────────────────────────────┐
│  TRIM Command Sequence:                                  │
│                                                         │
│  1. File dihapus                                        │
│  2. OS kirim TRIM ke SSD controller                     │
│     ("cluster 100-200 sudah tidak dipakai")             │
│  3. SSD controller kosongkan cluster tersebut           │
│     (diisi 0x00 secara internal)                        │
│  4. Data ASLI HILANG PERMANEN — tidak bisa direcover   │
│     (berbeda dari HDD yang hanya tandai sebagai kosong) │
└─────────────────────────────────────────────────────────┘
```

**HDD vs SSD:**

| Aspek | HDD | SSD |
|-------|-----|-----|
| **File dihapus — bisa carving?** | ✅ Ya — data tetap ada | ❌ Tidak — TRIM hapus instan |
| **Format cepat — bisa carving?** | ✅ Ya | ❌ TRIM triggered |
| **Overwrite — data hilang?** | ❌ Bisa recover 1-2 overwrite | ✅ Sekali overwrite = hilang |
| **File slack** | ✅ Ada — data file sebelumnya | ❌ Tidak ada (SSD nulis per page) |

### Mitigasi TRIM — Forensic Write Blocker

```bash
# Write blocker HARDWARE (Tableau, WiebeTech)
# Mencegah SSD menerima TRIM command dari OS

# Atau software write blocker:
# Linux: mount -o ro,noatime,nodiratime
# Gunakan dd dengan oflag=direct,noatime
dd if=/dev/sdb of=/evidence/ssd.dd bs=4M conv=noerror,sparse iflag=fullblock,noatime
```

**Di CTF:** Jika soal memberikan file `.dd` atau `.e01`, biasanya **TRIM sudah tidak relevan** karena image sudah diambil sebelum analisis. Tapi awareness penting — jangan kaget kalau soal dengan SSD image tidak punya file carved dari unallocated space.

---

## Recovery by File Type

### 1. Gambar (JPEG / PNG / GIF)

```bash
# Foremost — signature already included
foremost -t jpeg -i disk.dd -o carved_jpg/

# Cek metadata gambar yang di-recover
exiftool carved_jpg/00000001.jpg

# Cek steganografi — gambar bisa nampung hidden data!
zsteg carved_jpg/00000001.png
steghide extract -sf carved_jpg/00000001.jpg

# Cari flag dalam gambar — strings juga
strings carved_jpg/*.jpg | grep -i "CTF\|flag"
```

**CTF Pattern:** Gambar sering dijadikan container steganografi — cek LSB, metadata, dan embedded ZIP.

### 2. Dokumen (PDF)

```bash
# Foremost — PDF signature default
foremost -t pdf -i disk.dd -o carved_pdf/

# Ekstrak teks
pdftotext carved_pdf/00000001.pdf output.txt

# Cari metadata
pdfinfo carved_pdf/00000001.pdf

# Cari embedded file dalam PDF
pdfdetach -list carved_pdf/00000001.pdf
pdfdetach -save 1 carved_pdf/00000001.pdf
```

### 3. Archive (ZIP / RAR)

```bash
# ZIP carving — butuh EOCD (End of Central Directory) intact
foremost -t zip -i disk.dd -o carved_zip/

# Coba buka semua file yang di-recover
for f in carved_zip/*.zip; do
    unzip -l "$f" 2>/dev/null && echo "=== $f OK ===" || echo "=== $f CORRUPT ==="
done
```

### 4. Office Documents (DOCX / XLSX — Actually ZIP)

DOCX/XLSX adalah **ZIP yang berisi XML**. Carving = ZIP carving.

```bash
# Setelah di-recover sebagai ZIP:
unzip recovered.docx -d docx_extracted/
cat docx_extracted/word/document.xml | grep -i "CTF\|flag"
# Atau parse content langsung
strings recovered.docx | grep -i "CTF\|flag"
```

### 5. Executable (EXE / ELF)

```bash
# PE (Windows) — magic bytes: MZ (4D 5A)
foremost -t exe -i disk.dd -o carved_exe/

# ELF (Linux) — magic bytes: 7F 45 4C 46
# Tidak ada pada foremost default — tambahkan ke config:
echo -e "elf\ty\t200000000\t\\x7f\x45\x4c\x46" >> /etc/foremost.conf
```

### 6. Database (SQLite)

```bash
# SQLite magic bytes: 53 51 4C 69 74 65 20 66 6F 72 6D 61 74 20 33 00
# Tidak di default foremost — tambahkan di config:
echo -e "sqlite\ty\t200000000\t\\x53\x51\x4c\x69\x74\x65\x20\x66\x6f\x72\x6d\x61\x74\x20\x33\x00" >> /etc/foremost.conf

# Setelah di-recover:
sqlite3 recovered.db ".tables"
sqlite3 recovered.db "SELECT * FROM flag;"
```

---

## Anti-Forensics & Counter-Measures

### Anti-Forensics Techniques

| Teknik | Efek | Cara Kerja |
|--------|------|------------|
| **Secure Deletion (shred, srm)** | Overwrite file dengan random data | Baca file → tulis 0xFF → hapus → data asli hilang |
| **DoD 5220.22-M** | 7-pass overwrite | 3x random + 1x complement + 3x random — standar militer |
| **Disk Wiping (DBAN, nwipe)** | Hapus seluruh disk | Write 0x00/0xFF/random ke semua sector |
| **TRIM & NVMe Format** | Instant wipe SSD | NVMe format command hapus seluruh NAND dalam detik |
| **File Shredding** | Fragmentasi + rename | Potong file kecil-kecil, rename random, sebar ke berbagai folder |
| **Metadata Wiping** | Hapus exif, timestamp, $MFT entry | `exiftool -all=` atau `SetMACE` |
| **Steganography** | Sembunyiin file di media lain | Data dikodekan di LSB gambar/audio — tidak ketahuan carving |
| **Encryption** | File terlihat random | Data encrypted tidak punya magic bytes — carving tidak mendeteksi |

### Counter Anti-Forensics

```bash
# 1. Cari file shredding → cari file tiny (1-5 KB) dalam jumlah besar
find recovered/ -type f -size -5k | wc -l

# 2. Cari hidden stream (NTFS ADS)
# NTFS alternate data stream
find . -type f -exec stream_query {} \;

# 3. Cari file dengan nama random
ls output/ | grep -E "^[a-z0-9]{20,}\."

# 4. Cek slack space — data sisa dari file sebelumnya
# Menggunakan blkls
blkls -s disk.dd > slack.raw
strings slack.raw | grep -i "CTF\|flag"

# 5. Cari file terenkripsi — detect entropy tinggi
# Gunakan binwalk entropy analysis
binwalk -E disk.dd
# Output: entropy plot — puncak tinggi = compressed/encrypted data
```

---

## Carving in CTF Context

### Flowchart Soal Carving

```
Dapet file image (.dd/.e01/.img)
    │
    ├── Cek tipe image: file image.dd
    ├── Cek strings dulu: strings image.dd | grep -i "CTF\|flag"
    ├── Mount (jika bisa): mount -o loop,ro image.dd /mnt
    │   └── Cari flag langsung di filesystem
    │
    └── Mount gagal atau tidak ada file? → Carving
        │
        ├── blkls -s image.dd > unallocated.raw (unallocated space)
        ├── foremost -i unallocated.raw -o carved/
        ├── Cek hasil: ls carved/*/
        │   ├── Ada file? → cari flag di file yang di-recover
        │   └── Tidak ada? → cek dengan scalpel / photorec
        │
        └── Cari hidden data
            ├── bulk_extractor
            ├── binwalk -Me
            └── strings + grep
```

### Cold Start — Jika Baru Dapat Soal Carving

```
1. strings image.dd | grep -i "CTF\|flag"
   ✅ Jika dapat → submit. Selesai.

2. file image.dd + strings + exiftool
   → Cek tipe, metadata, deskripsi

3. foremost -T -i image.dd -o output/
   → Cek output: file apa yang muncul? Gambar? ZIP? PDF?

4. strings output/*/* | grep -i "CTF\|flag"
   → Cari flag di semua file yang di-recover

5. binwalk -Me image.dd
   → Cari embedded file yang tidak ketahuan foremost

6. bulk_extractor -o bulk/ image.dd
   → Cari pattern: base64, hex, URL, email
```

**Jika 1-6 tidak dapat flag → cari hidden sector, slack space, atau NTFS ADS.**

---

## Cheat Sheet — Command Matrix

```bash
# === CARVING QUICK START ===
foremost -T -i image.dd -o output/           # Carving semua tipe
foremost -t jpeg,pdf,zip -i image.dd -o out/  # Tipe spesifik
scalpel -i image.dd -o output/                # Scalpel (edit config dulu)
photorec image.dd                             # Interactive

# === UNALLOCATED SPACE ===
blkls -s image.dd > unallocated.raw           # Extract unallocated
blkls -f image.dd > slack.raw                 # Extract slack space

# === FILE ANALYSIS ===
file recovered.jpg                            # Cek tipe file
strings recovered.jpg | grep -i "flag"        # Cari string dalam file
exiftool recovered.jpg                        # Metadata
binwalk -Me recovered.jpg                     # Embedded file

# === HIDDEN DATA ===
bulk_extractor -o bulk/ image.dd              # Feature extraction
binwalk -E image.dd                           # Entropy analysis

# === CUSTOM SIGNATURE ===
# Add custom magic bytes to foremost config:
echo -e "sqlite\ty\t200000000\t\\x53\\x51\\x4c\\x69\\x74\\x65" >> /etc/foremost.conf

# === DISK CLONE ===
dd if=/dev/sdb of=image.dd bs=4M status=progress
dcfldd if=/dev/sdb of=image.dd bs=4M hash=sha256
ddrescue -d -r3 /dev/sdb image.dd rescue.log  # Damaged media

# === FILE FOUND → VERIFY ===
sha256sum recovered/*
file recovered/*
strings recovered/* | grep -i "CTF\|flag"
```

---

## Cross-Link

- **Atlas Digital Evidence** → [[hierarchy-digital-evidence-acquisition]]
- **Windows Forensics (artifact extraction)** → [[windows-forensics-artifact-analysis]]
- **Network Forensics (carving dari PCAP)** → [[network-forensics-pcap-analysis]]
- **Memory Forensics (Volatility)** → [[memory-forensics-volatility-deepdive]]
- **CTF Methodology (Forensic Flow)** → [[ctf-competition-methodology-strategy]]
- **Tool Arsenal** → [[ctf-tool-arsenal-universal]]
- **Data Recovery (existing)** → [[data-recovery]]
- **Master Index** → [[master-index]]

---

*File Carving & Data Recovery · Deleted ≠ Gone · Magic Bytes = Kunci · TRIM = Musuh SSD · Foremost + Scalpel + PhotoRec = Holy Trinity · Strings Dulu, Carving Kemudian · Fragmented File = Tantangan Besar*