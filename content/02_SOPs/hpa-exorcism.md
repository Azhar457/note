---
aliases:
  - HPA
created: 2026-04-23
tags:
  - SOP
  - HDD/SDD
---
# 🔪 SOP — The Safe Exorcist

> **HPA Unlock › DCO Reset › MBR Wipe › Zero-Fill Total**

> [!danger] PERINGATAN KRITIS Dokumen ini berisi prosedur **destruktif permanen**. Salah memilih drive = kehilangan data selamanya. Baca seluruh SOP sebelum eksekusi. **Jangan jalankan di drive OS utama.**

---

## ⚙️ Prasyarat & Persiapan

|Item|Detail|
|---|---|
|**OS**|SystemRescue Live USB _(boot terpisah, bukan dari disk target)_|
|**Tools wajib**|`hdparm` `dd` `lsblk` `blockdev`|
|**Koneksi drive**|USB-to-SATA adapter — **JANGAN** colok langsung ke SATA motherboard|

> [!info] Rocky Linux? Jalankan dulu: `sudo dnf install hdparm util-linux coreutils` Pastikan boot dari **Live USB**, bukan dari installed OS.

---

## Fase 1 — Identifikasi Target & Status

### 1.1 Tampilkan semua drive fisik

`ROTA=1` → HDD | `ROTA=0` → SSD/NVMe

```bash
lsblk -d -o NAME,SIZE,MODEL,ROTA
```

### 1.2 Pastikan drive target tidak ter-mount

```bash
umount /dev/sdX* 2>/dev/null
```

> [!warning] Mount = Bahaya Jika drive masih ter-mount dan kamu jalankan `dd` → korupsi bisa menyebar ke disk lain yang terpasang bersamaan.

---

## Fase 2 — Reset DCO (Device Configuration Overlay)

> [!tip] Kenapa DCO Dulu? DCO duduk **di bawah** HPA. Jika DCO tidak direset dulu, perintah unlock HPA bisa gagal total atau tidak persistent setelah power cycle.

### 2.1 Cek apakah ada DCO yang dimanipulasi

```bash
hdparm --dco-identify /dev/sdX
```

### 2.2 Reset DCO ke bawaan pabrik

```bash
hdparm --dco-restore /dev/sdX
```

### 2.3 Paksa kernel baca ulang geometri

```bash
blockdev --rereadpt /dev/sdX
```

---

## Fase 3 — Interogasi & Buka Kunci HPA

### 3.1 Cek status HPA

```bash
hdparm -N /dev/sdX
```

**Contoh output:**

```
max sectors   = 900000/976773168, HPA is enabled
               ==^^====/^====^^==
               current   native_max  ← AMBIL ANGKA INI
```

> Catat angka **Native Max** = angka **kedua setelah tanda `/`** Contoh di atas: `976773168`

### 3.2 Buka gembok HPA secara paksa

Tambahkan huruf `p` di depan angka Native Max:

```bash
hdparm -N p976773168 /dev/sdX
#         ^
#         p = persistent (survive power cycle)
```

### 3.3 Paksa kernel baca ulang kapasitas baru

```bash
blockdev --rereadpt /dev/sdX
```

### 3.4 Konfirmasi HPA sudah terbuka

```bash
hdparm -N /dev/sdX
# ✅ Sukses = kedua angka sama + output: "HPA is disabled"
```

> [!success] HPA Terbuka Jika output berbunyi `HPA is disabled` dan kedua angka identik → seluruh kapasitas fisik disk kini terekspos dan siap di-zero-fill.

---

## Fase 4 — Eksekusi Kematian (Zero-Fill Total)

> [!danger] POINT OF NO RETURN Setelah perintah ini dieksekusi, **tidak ada yang bisa diselamatkan**. Semua partisi, data, HPA, DCO, MBR, Bootkit, Rootkit, dan virus akan terhapus sempurna.

### 4.1 Konfirmasi nama drive sekali lagi

```bash
lsblk -d -o NAME,SIZE,MODEL,SERIAL /dev/sdX
```

### 4.2 Eksekusi Zero-Fill

```bash
dd if=/dev/zero of=/dev/sdX bs=4M conv=noerror,sync status=progress
```

|Parameter|Fungsi|
|---|---|
|`bs=4M`|Chunk besar → kecepatan optimal|
|`conv=noerror`|Lanjut meski ada bad sector _(kritis untuk HDD rusak)_|
|`conv=sync`|Isi bad sector dengan nol, bukan dilewati|
|`status=progress`|Tampilkan progress real-time|

**Estimasi waktu:**

|Drive|Ukuran|Estimasi|
|---|---|---|
|HDD|250 GB|~20–30 menit|
|HDD|500 GB|~40–60 menit|
|HDD|1 TB|~90–120 menit|
|SSD|250 GB|~5–15 menit|

---

## ✅ Hasil Setelah Zero-Fill Selesai

- [x] MBR/Bootkit terhapus sempurna
- [x] Area HPA ter-zero-fill (tidak bisa reload ulang)
- [x] DCO dikembalikan ke kapasitas pabrik
- [x] Semua partisi dan data hilang
- [x] Drive bersih seperti baru dari pabrik

Drive kini siap dipartisi ulang dan diinstall OS baru.

---

## 🗺️ Peta Lokasi Si Parasit (Referensi)

```
[Sektor 0 — 512 byte]
│
├── MBR ←─────────────── Bootkit duduk di sini (Fase 3–4 bunuh ini)
│    └── Jump ke kode jahat di Unallocated Space dekat sektor 0
│
├── Partisi C: (Windows)   ← Antivirus biasa hanya melihat di sini
├── Partisi D: (Data)
├── Unallocated Space      ← Tubuh utama rootkit bersembunyi
│
└── [Sektor Terakhir — area tersembunyi]
     │
     └── HPA ←──────────── Cadangan infeksi / OEM Recovery
          ├── Berisi OEM recovery bersih  = Teori A murni
          └── Berisi kode executable aneh = Teori A + B hybrid ⚠️
```

---

## ⚡ Quick Reference — Urutan Wajib

```bash
# [1] Isolasi fisik → USB adapter + Live USB terpisah

# [2] Identifikasi
lsblk -d -o NAME,SIZE,MODEL,ROTA
umount /dev/sdX* 2>/dev/null

# [3] DCO Reset (SEBELUM HPA!)
hdparm --dco-restore /dev/sdX
blockdev --rereadpt /dev/sdX

# [4] HPA Unlock
hdparm -N /dev/sdX                  # catat native_max
hdparm -N p{native_max} /dev/sdX    # buka paksa
blockdev --rereadpt /dev/sdX

# [5] Zero-Fill
dd if=/dev/zero of=/dev/sdX bs=4M conv=noerror,sync status=progress
```

---

## 🔗 Lihat Juga

- [Script Exorcist](D:\Documents\Obsidian Vault\REPAIR\Exorcist.sh)
- [[01_Library/Data_Forensics/data-recovery|Data Recovery]] — Recovery Level 0–7
- [[endpoint-security|Endpoint Security]] — CPU Ring & Boot Chain
- [[network-security|Network Security]] — OSI Layer 1–8

---

_The Safe Exorcist v2.0 — HPA/DCO/MBR Elimination Protocol_