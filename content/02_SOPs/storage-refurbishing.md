---
title: "Storage Refurbishing"
tags:
  - sops
aliases:
  - "storage-refurbishing"
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

# 💽 Master SOP — Storage Recovery & Refurbish
## 🚦 FASE 0: Inisiasi, Triage & Audit (Standard Protocol)
Gunakan langkah ini untuk setiap unit yang masuk sebelum memutuskan apakah akan menyelamatkan data (**ALUR A**) atau melakukan perbaikan partisi (**ALUR B**).

### 0.1 Monitoring Hardware (Real-time)
Pantau log kernel sebelum dan saat mencolok drive untuk melihat "kesehatan" fisik koneksi.
```bash
dmesg -w
# Pantau error: "I/O Error", "failed to identify", "giving up", atau "reset failed".
```
Selain itu, pastikan untuk memeriksa suhu drive menggunakan perintah `smartctl --health` untuk mendeteksi adanya masalah suhu yang dapat memperburuk keadaan. Contoh output `dmesg -w` dapat dilihat di bawah ini:
```
[  123.456789] sd 2:0:0:0: [sdb] 976773168 512-byte logical blocks: (500 GB/465 GiB)
[  123.456790] sd 2:0:0:0: [sdb] Write Protect is off
[  123.456791] sd 2:0:0:0: [sdb] Mode Sense: 00 3a 00 00
[  123.456792] sd 2:0:0:0: [sdb] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
```
Dari contoh di atas, kita dapat melihat bahwa drive `sdb` telah terdeteksi dan siap digunakan.

### 0.2 Verifikasi Deteksi & Identifikasi
Pastikan nomor seri (SN) tercatat agar tidak salah eksekusi pada drive yang salah.
```bash
# Lihat daftar drive, model, dan nomor seri
lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA,TRAN
```
Periksa juga tipe drive (HDD, SSD, atau NVMe) untuk menentukan langkah-langkah yang tepat. Contoh output `lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA,TRAN` dapat dilihat di bawah ini:
```
NAME    SIZE MODEL            SERIAL      ROTA TRAN
sda   476.9G ST500DM002-1BD142  WDC-WMAW30443953    1    0
sdb   465.8G WDC-WD5000AZLX-22  WDC-WD-WX31D1401391    1    0
```
Dari contoh di atas, kita dapat melihat bahwa ada dua drive yang terdeteksi, yaitu `sda` dan `sdb`. `sda` memiliki ukuran 476,9 GB, model ST500DM002-1BD142, dan nomor seri WDC-WMAW30443953. `sdb` memiliki ukuran 465,8 GB, model WDC-WD5000AZLX-22, dan nomor seri WDC-WD-WX31D1401391.

### 0.3 Audit Kesehatan SMART
Vonis awal berdasarkan laporan internal firmware drive.
```bash
# Cek status kesehatan singkat (PASSED/FAILED)
smartctl -H /dev/sdX

# Cek detail (Lihat Reallocated_Sector_Ct & Pending_Sector)
smartctl -a /dev/sdX
```
Periksa juga nilai `Spin_Retry_Count` dan `Current_Pending_Sector` untuk menentukan tingkat keparahan masalah. Contoh output `smartctl -H /dev/sdX` dapat dilihat di bawah ini:
```
=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED
```
Dari contoh di atas, kita dapat melihat bahwa drive `sdX` memiliki status kesehatan yang baik.

## 🛡️ ALUR A: Data Recovery Focus (Prioritas Data)
**PENTING:** Jika data sangat berharga, **HARAM** melakukan `format`, `wipefs`, atau `mklabel` sebelum data berhasil dievakuasi.

### FASE A1: Mounting Paksa (Bypass Error)
Gunakan jika Windows gagal membaca partisi karena *Dirty Bit* atau *Unclean Shutdown*.
```bash
# 1. Buat folder untuk mount point
mkdir -p /mnt/recovery_data

# 2. Mount Partisi - Mode Read-Only (Paling Aman)
mount -o ro,force /dev/sdXn /mnt/recovery_data

# 3. Jika tetap gagal, gunakan driver ntfs-3g
ntfs-3g -o ro,force /dev/sdXn /mnt/recovery_data

# NOTE: Jika partisi terkunci BitLocker, gunakan 'dislocker' sebelum mounting.
```
Selain itu, pastikan untuk memeriksa atribut file yang disembunyikan oleh Windows menggunakan perintah `lsattr` untuk memastikan tidak ada data penting yang tersembunyi. Contoh output `lsattr` dapat dilihat di bawah ini:
```
-----a-------e-- /mnt/recovery_data/file1.txt
-----a-------e-- /mnt/recovery_data/file2.txt
```
Dari contoh di atas, kita dapat melihat bahwa ada dua file yang disembunyikan oleh Windows, yaitu `file1.txt` dan `file2.txt`.

### FASE A2: Evakuasi & Migrasi Data
Gunakan `rsync` untuk pemindahan biasa, atau `ddrescue` jika drive mulai "sekarat" (sering macet).
```bash
# Opsi 1: rsync (Data terbaca normal)
rsync -avP /mnt/recovery_data/ /mnt/external/Backup_Drive/

# Opsi 2: ddrescue (Jika sering I/O Error / Hang)
# Membuat image dari partisi yang rusak ke drive sehat
ddrescue -f -n /dev/sdXn /mnt/external/partition_backup.img /mnt/external/rescue.log
```
Pastikan untuk memeriksa integritas data yang dipindahkan menggunakan perintah `md5sum` atau `sha256sum` untuk memastikan tidak ada korupsi data. Contoh output `md5sum` dapat dilihat di bawah ini:
```
md5sum: /mnt/external/Backup_Drive/file1.txt: OK
md5sum: /mnt/external/Backup_Drive/file2.txt: OK
```
Dari contoh di atas, kita dapat melihat bahwa integritas data yang dipindahkan tetap baik.

### FASE A3: Penyelamatan Tabel Partisi (TestDisk)
Gunakan jika partisi terbaca kosong atau RAW, namun fisik drive masih stabil.
```bash
testdisk /dev/sdX
# Urutan: [Analyse] -> [Quick Search] -> Tekan 'P' (List file) -> 'C' (Copy).
```
Selain itu, pastikan untuk memeriksa strukuktur file yang dipulihkan menggunakan perintah `fsck` untuk memastikan integritas file system. Contoh output `fsck` dapat dilihat di bawah ini:
```
fsck: /dev/sdXn: 12 files, 1234/4567 blocks
```
Dari contoh di atas, kita dapat melihat bahwa file system pada partisi `sdXn` memiliki 12 file dan 1234/4567 blocks yang digunakan.

## 🧹 ALUR B: Partition Repair & Refurbish (Prioritas Unit)

**WARNING:** Langkah ini bersifat **DESTRUKTIF**. Semua data akan hilang permanen. Gunakan hanya jika unit disiapkan untuk penggunaan ulang atau dijual.

### FASE B1: Sanitasi & Pembersihan Total
Menghapus semua metadata, tabel partisi, dan mengembalikan performa (khusus SSD).
```bash
# 1. HANCURKAN (Destructive)
sgdisk --zap-all /dev/sdX && wipefs -a /dev/sdX

# 2. SSD ONLY: Kembalikan Performa (TRIM)
blkdiscard -v /dev/sdX

# 3. HDD ONLY: Hapus sektor awal (MBR/GPT)
dd if=/dev/zero of=/dev/sdX bs=1M count=100
```
Pastikan untuk memeriksa kondisi drive setelah proses sanitasi menggunakan perintah `smartctl --health` untuk memastikan tidak ada masalah yang tersisa. Contoh output `smartctl --health` dapat dilihat di bawah ini:
```
=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED
```
Dari contoh di atas, kita dapat melihat bahwa kondisi drive tetap baik setelah proses sanitasi.

### FASE B2: Rekonstruksi Struktur Partisi
Membangun ulang label drive (GPT sangat disarankan untuk modernitas).
```bash
# 1. Bangun ulang tabel partisi (GPT)
parted /dev/sdX mklabel gpt && partprobe /dev/sdX

# 2. Buat Partisi Baru Tunggal (fdisk)
# Urutan: 'n' (New) -> Enter terus -> 'w' (Write)
fdisk /dev/sdX
```
Pastikan untuk memeriksa struktur partisi yang dibuat menggunakan perintah `lsblk` untuk memastikan tidak ada kesalahan. Contoh output `lsblk` dapat dilihat di bawah ini:
```
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda       8:0    0 476.9G  0 disk
├─sda1    8:1    0   512M  0 part /boot
├─sda2    8:2    0     1G  0 part [SWAP]
└─sda3    8:3    0 475.4G  0 part /
```
Dari contoh di atas, kita dapat melihat bahwa struktur partisi pada drive `sda` memiliki tiga partisi, yaitu `sda1`, `sda2`, dan `sda3`.

### FASE B3: Formatting & Final Certification
Memberi label dan memastikan unit layak dijual/dipakai.
```bash
# 1. Format ke NTFS (Quick Format)
mkfs.ntfs -f -L "REFURBISH_DRIVE" /dev/sdX1

# 2. Uji Kecepatan Tulis (Simple Benchmark)
# Pastikan mount dulu agar tidak membakar RAM/System Drive!
mkdir -p /mnt/temp_bench && mount /dev/sdX1 /mnt/temp_bench
dd if=/dev/zero of=/mnt/temp_bench/testfile bs=1G count=1 oflag=direct
umount /mnt/temp_bench
```
Pastikan untuk memeriksa kondisi drive setelah proses formatting menggunakan perintah `smartctl --health` untuk memastikan tidak ada masalah yang tersisa. Contoh output `smartctl --health` dapat dilihat di bawah ini:
```
=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED
```
Dari contoh di atas, kita dapat melihat bahwa kondisi drive tetap baik setelah proses formatting.

## 💡 Pro-Tips & Reference

### 1. SSD vs HDD
- **SSD:** Gunakan `blkdiscard` sesering mungkin untuk menjaga kesehatan sel NAND.
- **HDD:** Jika terdengar suara klik keras (**Click of Death**), langsung cabut! Jangan paksa *spin-up*.
- **Thermal Management:** Jika saat `ddrescue` atau `rsync` suhu HDD tembus **50°C**, arahkan kipas angin langsung ke unit atau hentikan proses sementara. Panas berlebih mempercepat kematian *head* yang sekarat.

### 2. Penanganan Triage Cepat
| **Gejala** | **Kategori** | **Tindakan** | **Resiko** |
| --- | --- | --- | --- |
| Kapasitas 0 GB | 🟥 **MERAH** | Rongsok / Kanibal | **Total Loss** |
| I/O Error (Sektor 0) | 🟧 **ORANGE** | Coba `sgdisk` / `ddrescue` | **High Risk** |
| Invalid GPT Header | 🟩 **HIJAU** | `sgdisk --zap-all` | **Low Risk** |

### 3. Referensi Perintah Cepat
- **Parkir & Cabut Safe:** `sync && echo 1 > /sys/block/sdX/device/delete`
- **Lazy Unmount:** `umount -l /mnt/xxx` (Gunakan jika disk macet/hang)
- **Rescan SATA:** `for scan in /sys/class/scsi_host/host*/scan; do echo "- - -" > $scan; done`

### 4. Troubleshooting
- **Error pada `ddrescue`:** Periksa log rescue untuk mengetahui penyebab error.
- **Error pada `rsync`:** Periksa log rsync untuk mengetahui penyebab error.
- **Error pada `testdisk`:** Periksa log testdisk untuk mengetahui penyebab error.

### 5. Preventif
- **Backup data:** Lakukan backup data secara teratur untuk mencegah kehilangan data.
- **Periksa kesehatan drive:** Lakukan periksa kesehatan drive secara teratur untuk mencegah kerusakan drive.
- **Gunakan perangkat yang tepat:** Gunakan perangkat yang tepat untuk tugas yang tepat untuk mencegah kerusakan perangkat.

Dengan mengikuti langkah-langkah di atas, Anda dapat melakukan recovery data dan refurbish drive dengan aman dan efektif. Pastikan untuk selalu melakukan backup data dan memeriksa kesehatan drive secara teratur untuk mencegah kehilangan data.