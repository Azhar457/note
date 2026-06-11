---
tags:
  - Laptop
  - QC
  - Procurement
  - Hardware
  - Windows
  - Technician
  - Shopping-Guide
aliases:
  - Panduan QC Laptop
  - Laptop Procurement Guide
  - Field Technician Buying Guide
created: 2026-05-11
status: operational
---

# 💻 LAPTOP QC & PROCUREMENT — Field Technician Buying Guide

> **Environment:** Windows 10/11 Native (CMD/PowerShell) & Portable Tools
> **Filosofi:** Assume Breach — Anggap semua klaim penjual salah sampai terbukti benar oleh data.
> **Target:** Laptop Baru, Bekas, Open Box, Ex-Display, & Ex-Leasing

> [!danger] Golden Rule — Tidak Boleh Dilanggar
> **JANGAN bayar sebelum QC selesai.**
> Sekali uang pindah tangan, cacat kosmetik atau fungsional seringkali dianggap "kelalaian pembeli".

---

## Peta Alur Keseluruhan

```
UNIT LAPTOP MASUK / DILIHAT
        │
        ▼
[FASE 0] Identifikasi & Persiapan (Filosofi "Assume Breach")
        │
        ▼
[FASE 1] Inspeksi Cepat (CLI) — Cek Jeroan, RAM, & Lisensi
        │
        ▼
[FASE 2] QC Hardware Mendalam — Screen, Disk, Battery, Thermal
        │
        ▼
[FASE 3] Analisis Harga vs Strategi Procurement
        │
        ▼
[FASE 4] Mitigasi Risiko & Post-Purchase (Trade-In / Home Server)
```

---

## Tools Checklist (Portable & Native)

| Tool | Fungsi | Sudah Ada di Windows? |
|---|---|---|
| `wmic` / `cmd` | Identifikasi serial, RAM, Motherboard | ✅ |
| `powercfg` | Battery health report | ✅ |
| `CrystalDiskInfo` | Cek jam terbang (POH) & kesehatan SSD | ❌ Portable |
| `HWMonitor` | Cek suhu idle & load | ❌ Portable |
| `Dead Pixel Test` | Cek kecacatan panel layar | 🌐 Online |
| `CrystalDiskMark` | Benchmark kecepatan SSD | ❌ Portable |
| `CPU-Z` | Detail arsitektur CPU & RAM | ❌ Portable |
| `Cinebench` | Stress test performa & thermal | ❌ Portable |

---

## FASE 0 — Identifikasi & Persiapan

### 0.1 Filosofi "Assume Breach" dalam Procurement
Banyak dealer memanfaatkan **information gap** untuk menaikkan harga secara tidak wajar. Toolkit ini memberikan **bukti objektif** yang tidak bisa dibantah.

| Klaim Penjual | Bukti yang Harus Diminta | Tools Verifikasi |
|---|---|---|
| "Baru gres" | Power On Hours, Power On Count | CrystalDiskInfo |
| "Windows & Office Original" | OA3xOriginalProductKey, stiker OHS | `wmic`, Microsoft Store |
| "Garansi resmi" | Serial Number check di website | `wmic bios get serialnumber` |
| "Spek tinggi" | Task Manager, `wmic`, CPU-Z | Native Windows + portable |

---

## FASE 1 — Inspeksi Cepat via Command Line (CLI)

> [!tip] Efek Psikologis
> Ngetik command di depan penjual punya efek psikologis "ahli IT" yang kuat — dan hasilnya tidak bisa dipalsukan.

### 1.1 Identifikasi RAM & Motherboard
```cmd
# Cek Kapasitas RAM Maksimal Motherboard
wmic memphysical get maxcapacity
# Hasil (bytes) ÷ 1048576 = GB (Contoh: 67108864 = 64GB)

# Cek Detail RAM Terpasang (Speed, Manufacturer)
wmic memorychip get capacity, speed, manufacturer, partnumber

# Cek Info Motherboard (Vendor & Version)
wmic baseboard get product, manufacturer, version
```

### 1.2 Lisensi & Keaslian (Skakmat Dealer)
```cmd
# Cek Windows Product Key (OEM)
wmic path softwarelicensingservice get OA3xOriginalProductKey

# Cek Serial Number untuk Verifikasi Garansi
wmic bios get serialnumber
```
> [!tip] Tips Nego
> "Mas, Windows Ori-nya kan sudah bawaan pabrik (nempel di BIOS). Jadi tidak perlu bayar tambahan jasa instalasi ya."

### 1.3 Performa CPU
```cmd
# Cek Nama CPU, Core, & Max Clock
wmic cpu get name, numberofcores, numberoflogicalprocessors, maxclockspeed
```

---

## FASE 2 — QC Hardware Mendalam

### 2.1 Sektor Layar & Visual
| ✅ Item | 🛠️ Method | ⚠️ Red Flag |
|---|---|---|
| Dead Pixel | Dead Pixel Test (website) | Ada pixel mati atau stuck |
| Backlight Bleed | Layar hitam pekat (gelap) | Cahaya bocor di pinggiran panel |
| Engsel | Buka tutup perlahan | Bunyi, miring, atau longgar |

### 2.2 Sektor Storage & Battery
```cmd
# Generate Battery Report
powercfg /batteryreport
```
*   **Battery Health:** `(FULL CHARGE ÷ DESIGN CAPACITY) × 100%`
*   **SSD Health:** Cek via CrystalDiskInfo (Status "Caution" = Tolak).
*   **Jam Terbang:** Power On Hours > 100 jam untuk unit "baru" = Unit Ex-Display.

### 2.3 Sektor Performa & Thermal
*   **Idle Temp:** > 60°C (Mungkin fan kotor atau paste kering).
*   **Load Temp:** > 95°C sustained (Thermal Throttling parah).
*   **Fan Noise:** Bunyi kasar atau tidak berputar saat load.

---

## FASE 3 — Analisis Harga & Strategi Procurement

### 3.1 Reality Check: Harga Wajar (Studi Kasus 2026)
| Budget | Seharusnya Dapat | Jangan Terima |
|---|---|---|
| **Rp 6-8 jt** | Core i3 Gen 12/13, 8GB, 256GB, IPS | TN panel, HDD, 4GB RAM |
| **Rp 8-10 jt** | Core i5 Gen 12/13, 8GB, 512GB, IPS 100% sRGB | i3 dengan klaim "gaming" |
| **Rp 10-13 jt** | Core i5 Gen 13/14, 16GB, 512GB NVMe, OLED | i3 + RAM 8GB |

### 3.2 Jalur Pembelian Terbaik
1.  **Official Store:** Harga SRP, aman, garansi penuh.
2.  **Master Dealer (BEC, dll):** Bisa nego, stok melimpah, perlu QC ketat.
3.  **Refurbished Resmi:** Hemat 30-40%, garansi masih ada.
4.  **Second Ex-Leasing:** ThinkPad/Dell Latitude bekas kantor (Tangguh).

---

## FASE 4 — Mitigasi Risiko & Post-Purchase

### 4.1 Red Flags & Bom Waktu
*   **Computrace / LoJack:** Masuk BIOS → Security. Jika **Active**, JANGAN BELI. Laptop bisa terkunci permanen jika dianggap dicuri oleh perusahaan asal.
*   **RAM Soldered:** Jika tidak bisa upgrade, pastikan kapasitas awal sudah cukup (min 16GB untuk 2026).

### 4.2 Trade-In vs Home Server
*   **Trade-In Resmi:** Biasanya dihargai rendah (receh).
*   **Home Server Conversion:** Laptop tua dengan baterai soak adalah **Server dengan UPS built-in**. Ideal untuk Proxmox, AdGuard Home, atau Pi-hole.

---

## Quick Reference — Cheat Sheet

```cmd
# ═══ IDENTIFIKASI DASAR ═══
wmic bios get serialnumber              # Cek Garansi
wmic cpu get name, numberofcores        # Verifikasi Spek
wmic baseboard get product              # Info Motherboard

# ═══ RAM & LISENSI ═══
wmic memphysical get maxcapacity        # Limit Upgrade
wmic memorychip get capacity, speed     # RAM Detail
wmic path softwarelicensingservice get OA3xOriginalProductKey # Windows Key

# ═══ DISK & BATTERY ═══
wmic diskdrive get model, size, status  # Kondisi Disk
powercfg /batteryreport                 # Report Baterai (HTML)
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Percaya klaim "Baru" tanpa cek POH | Cek CrystalDiskInfo (Power On Hours) |
| Bayar dulu baru QC di rumah | QC di toko, jika cacat minta ganti unit |
| Beli i3 Gen terbaru tapi layar TN | Prioritaskan layar IPS/OLED untuk mata |
| Beli laptop "Gaming" harga i3 | Lebih baik i5 standar daripada i3 "maksa" gaming |
| Abaikan status Computrace di BIOS | Wajib Deactivated/Disabled |

---

## 🔗 Lihat Juga

- [[Technician-Toolkit-Standard]] — Flashdisk toolkit teknisi (Ventoy, Strelec)
- [[endpoint-security-hierarchy (Open Source & Freeware Edition)]] — Keamanan endpoint
- [[storage-refurbishing]] — Refurbishing HDD/SSD
- [[Application]] — 🛠️ Master Interactive Tool Arsenal
  - [Cyber Security](https://azhar457.github.io/Application/Application_Cyber_Security.html)
  - [Forensics & Data Recovery](https://azhar457.github.io/Application/Application_Forensics_Recovery.html)

---

## Changelog

| Versi | Tanggal | Perubahan |
|---|---|---|
| v1.0 | 2026-05-11 | Dokumen awal dari RAW chat |
| v1.1 | 2026-05-12 | Reformatting ke template SystemRescue (Phased Structure, Cheat Sheet, Anti-Pattern) |

---

*SOP Laptop QC & Procurement | wmic · Battery Report · CrystalDiskInfo · Field Guide*