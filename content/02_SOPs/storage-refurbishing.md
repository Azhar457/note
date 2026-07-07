---
title: Storage Refurbishing
tags:
  - 02-sops
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

# 💽 Master SOP — Storage Recovery & Refurbish

> **Environment:** SystemRescue (Linux Bare-Metal / CLI)
> **Status:** Production Ready
> **Target:** HDD, SSD, NVMe (Bad Sector, Corrupt Partition, Sanitization)
> **Goal:** Data Rescue ↔️ Drive Refurbishment ↔️ Prep for Resale

---

## 🚦 FASE 0: Inisiasi, Triage & Audit (Standard Protocol)

Gunakan langkah ini untuk setiap unit yang masuk sebelum memutuskan apakah akan menyelamatkan data (**ALUR A**) atau melakukan perbaikan partisi (**ALUR B**).

### 0.1 Monitoring Hardware (Real-time)

Pantau log kernel sebelum dan saat mencolok drive untuk melihat "kesehatan" fisik koneksi.

```bash
dmesg -w
# Pantau error: "I/O Error", "failed to identify", "giving up", atau "reset failed".
```

### 0.2 Verifikasi Deteksi & Identifikasi

Pastikan nomor seri (SN) tercatat agar tidak salah eksekusi pada drive yang salah.

```bash
# Lihat daftar drive, model, dan nomor seri
lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA,TRAN
```

### 0.3 Audit Kesehatan SMART

Vonis awal berdasarkan laporan internal firmware drive.

```bash
# Cek status kesehatan singkat (PASSED/FAILED)
smartctl -H /dev/sdX

# Cek detail (Lihat Reallocated_Sector_Ct & Pending_Sector)
smartctl -a /dev/sdX
```

---

## 🛡️ ALUR A: Data Recovery Focus (Prioritas Data)

**PENTING:** Jika data sangat berharga, **HARAM** melakukan `format`, `wipefs`, atau `mklabel` sebelum data berhasil dievakuasi.

### FASE A1: Mounting Paksa (Bypass Error)

Gunakan jika Windows gagal membaca partisi karena _Dirty Bit_ atau _Unclean Shutdown_.

```bash
# 1. Buat folder untuk mount point
mkdir -p /mnt/recovery_data

# 2. Mount Partisi - Mode Read-Only (Paling Aman)
mount -o ro,force /dev/sdXn /mnt/recovery_data

# 3. Jika tetap gagal, gunakan driver ntfs-3g
ntfs-3g -o ro,force /dev/sdXn /mnt/recovery_data

# NOTE: Jika partisi terkunci BitLocker, gunakan 'dislocker' sebelum mounting.
```

### FASE A2: Evakuasi & Migrasi Data

Gunakan `rsync` untuk pemindahan biasa, atau `ddrescue` jika drive mulai "sekarat" (sering macet).

```bash
# Opsi 1: rsync (Data terbaca normal)
rsync -avP /mnt/recovery_data/ /mnt/external/Backup_Drive/

# Opsi 2: ddrescue (Jika sering I/O Error / Hang)
# Membuat image dari partisi yang rusak ke drive sehat
ddrescue -f -n /dev/sdXn /mnt/external/partition_backup.img /mnt/external/rescue.log
```

### FASE A3: Penyelamatan Tabel Partisi (TestDisk)

Gunakan jika partisi terbaca kosong atau RAW, namun fisik drive masih stabil.

```bash
testdisk /dev/sdX
# Urutan: [Analyse] -> [Quick Search] -> Tekan 'P' (List file) -> 'C' (Copy).
```

---

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

### FASE B2: Rekonstruksi Struktur Partisi

Membangun ulang label drive (GPT sangat disarankan untuk modernitas).

```bash
# 1. Bangun ulang tabel partisi (GPT)
parted /dev/sdX mklabel gpt && partprobe /dev/sdX

# 2. Buat Partisi Baru Tunggal (fdisk)
# Urutan: 'n' (New) -> Enter terus -> 'w' (Write)
fdisk /dev/sdX
```

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

---

## 💡 Pro-Tips & Reference

### 1. SSD vs HDD

- **SSD:** Gunakan `blkdiscard` sesering mungkin untuk menjaga kesehatan sel NAND.
- **HDD:** Jika terdengar suara klik keras (**Click of Death**), langsung cabut! Jangan paksa _spin-up_.
- **Thermal Management:** Jika saat `ddrescue` atau `rsync` suhu HDD tembus **50°C**, arahkan kipas angin langsung ke unit atau hentikan proses sementara. Panas berlebih mempercepat kematian _head_ yang sekarat.

### 2. Penanganan Triage Cepat

| **Gejala**           | **Kategori**  | **Tindakan**               | **Resiko**     |
| -------------------- | ------------- | -------------------------- | -------------- |
| Kapasitas 0 GB       | 🟥 **MERAH**  | Rongsok / Kanibal          | **Total Loss** |
| I/O Error (Sektor 0) | 🟧 **ORANGE** | Coba `sgdisk` / `ddrescue` | **High Risk**  |
| Invalid GPT Header   | 🟩 **HIJAU**  | `sgdisk --zap-all`         | **Low Risk**   |

### 3. Referensi Perintah Cepat

- **Parkir & Cabut Safe:** `sync && echo 1 > /sys/block/sdX/device/delete`
- **Lazy Unmount:** `umount -l /mnt/xxx` (Gunakan jika disk macet/hang)
- **Rescan SATA:** `for scan in /sys/class/scsi_host/host*/scan; do echo "- - -" > $scan; done`

---

> [!CAUTION] **Truth over Comfort:** Drive yang pernah mengeluarkan `I/O Error` di level kernel (`dmesg`) adalah "bom waktu". Gunakan hanya untuk data sekunder (game/temp), jangan pernah untuk OS Utama atau Backup Tunggal.
