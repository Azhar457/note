# 💽 SOP — The Data Lifesaver & Disk Refurbish

> **Status:** Recovery Mode (SystemRescue / Linux Bare-Metal)
> 
> **Target:** Seagate 2TB (Bad Sector / Dirty Bit Case)
> 
> **Goal:** Rescue Data → Wipe → Merge Partition → Resell

---
## 🚦 FASE 0: Inisiasi & Protokol Normal (Standard Operating)

Gunakan langkah ini untuk mengecek kondisi "sehat" sebelum menganggap drive bermasalah.

### 0.1 Verifikasi Deteksi Hardware

Pastikan kabel dan daya aman. Cek apakah Linux melihat piringan fisiknya.

Bash

```
# Menampilkan semua disk fisik secara ringkas
lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA
```

### 0.2 Audit Partisi & Sistem Berkas (Tanpa Mount)

Melihat "KTP" setiap partisi tanpa menyentuh isinya.

Bash

```
# -f untuk melihat FSTYPE (NTFS/FAT32), UUID, dan Label
lsblk -f /dev/sda
```

### 0.3 Uji Kesehatan Dasar (Pre-flight Check)

Melihat status kesehatan secara umum tanpa melakukan _stress test_.

Bash

```
# Cek apakah firmware HDD merasa dirinya sehat atau tidak
smartctl -H /dev/sda
```

### 0.4 Percobaan Mounting Normal (Automatis)

Coba lakukan _mount_ tanpa tambahan perintah aneh-aneh. Jika berhasil di sini, kamu beruntung.

Bash

```
# 1. Buat direktori (jika belum ada)
mkdir -p /mnt/normal_data

# 2. Coba mount standar (Read/Write)
mount /dev/sda2 /mnt/normal_data
```

---

> [!IMPORTANT] **Kapan Harus Pindah ke FASE 1 (Force)?** Jika pada **Fase 0.4** kamu mendapatkan pesan error seperti:
> 
> - `The disk contains an unclean file system`
>     
> - `Metadata kept in Windows cache, refused to mount`
>     
> - `I/O Error`
>     
> - `Structure needs cleaning`
>     
> 
> **JANGAN** dipaksa mount ulang secara normal. Segera lepaskan (`umount`) dan lanjut ke **Fase 2 (Force Ro)** atau **Fase 3 (Migration)** di bawah.
## 🔍 FASE 1: Identifikasi & Audit (Triage)

Langkah pertama setelah boot ulang untuk memastikan nama drive tidak berubah (misal dari `/dev/sda` ke `/dev/sdb`).

Bash

```
# 1. Cek daftar semua drive dan partisi
lsblk -f

# 2. Cek kesehatan SMART (Lihat Reallocated_Sector_Ct)
smartctl -a /dev/sda

# 3. Cek kapasitas terpakai di partisi yang masih sehat
# (Pastikan sudah di-mount dulu ke /mnt/data)
df -h /mnt/data
du -sh /mnt/data/*
```

---

## 🛡️ FASE 2: Mounting Paksa (Bypass Windows Error)

Gunakan ini jika Windows/Hiren's gagal membaca partisi atau muncul error `squashfs`.

Bash

```
# 1. Buat folder untuk mount point
mkdir -p /mnt/system
mkdir -p /mnt/data

# 2. Mount Partisi Data (sda2) - Mode Read-Only (Paling Aman)
mount -o ro,force /dev/sda2 /mnt/data

# 3. Mount Partisi Sistem (sda1) - Gunakan Driver ntfs-3g jika lsblk -f kosong
ntfs-3g -o ro,force /dev/sda1 /mnt/system

# 4. Jika tetap gagal mount sda1, intip sektor awal (Cek keberadaan data)
hexdump -C /dev/sda1 | head -n 20
```

---

## 🚀 FASE 3: Evakuasi Data (The Great Migration)

Gunakan `rsync` untuk pemindahan data besar karena bisa dilanjutkan jika koneksi terputus atau _freeze_.

Bash

```
# Perintah rsync (a=archive, v=verbose, P=progress & partial)
# Ganti /mnt/external/ dengan mount point HDD cadanganmu
rsync -avP /mnt/data/ /mnt/external/Backup_Seagate/
```

> [!CAUTION] **TEMBOK KEMATIAN LEVEL 4**
> 
> Jika `rsync` atau `cp` mendadak berhenti (I/O Error/Hang), segera hentikan! Gunakan `ddrescue` untuk menyedot data secara paksa.
> 
> Bash
> 
> ```
> ddrescue -f -n /dev/sda2 /mnt/external/sda2_backup.img /mnt/external/rescue.log
> ```

---

## 🛠️ FASE 4: Penyelamatan Tabel Partisi (Optional)

Gunakan jika partisi terbaca kosong tapi kamu butuh mengais file di dalamnya.

Bash

```
# Jalankan TestDisk
testdisk /dev/sda

# Urutan: [Analyse] -> [Quick Search] -> Tekan 'P' untuk list file.
# Jika ketemu, tekan 'C' untuk copy file/folder yang terpilih.
```

---

## 🧹 FASE 5: Sanitasi & Penggabungan (Persiapan Jual)

**LAKUKAN HANYA JIKA DATA SUDAH AMAN DI HDD LAIN!**

Bash

```
# 1. Hapus semua jejak partisi lama
wipefs -a /dev/sda

# 2. Hapus MBR/GPT Sektor awal
dd if=/dev/zero of=/dev/sda bs=1M count=100

# 3. Buat Partisi Baru Tunggal (fdisk)
# Urutan: 'g' (GPT) -> 'n' (New) -> Enter terus -> 'w' (Write)
fdisk /dev/sda

# 4. Format ke NTFS (Quick Format agar cepat)
mkfs.ntfs -f -L "SEAGATE_2TB" /dev/sda1
```

---

## 🩺 FASE 6: Sertifikasi Akhir

Pastikan barang yang dijual tidak "busuk" di tangan pembeli.

Bash

```
# Cek apakah status SMART masih PASSED
smartctl -H /dev/sda

# Uji kecepatan tulis sederhana
dd if=/dev/zero of=/mnt/data/testfile bs=1G count=1 oflag=direct
```

---

## 🔗 Referensi Perintah Cepat

| **Perintah**          | **Fungsi**                                          |
| --------------------- | --------------------------------------------------- |
| `umount -l /mnt/xxx`  | Lepas mount secara paksa (Lazy unmount)             |
| `reboot`              | Restart sistem                                      |
| `poweroff`            | Matikan total                                       |
| `dmesg \| tail -n 50` | Lihat pesan error kernel terakhir (Jika disk macet) |
|                       |                                                     |