---
title: "Technician Toolkit Standard"
tags:
  - library
  - other
aliases:
  - "technician-toolkit-standard"
created: "2026-05-11"
updated: "2026-07-01"
status: operational
source: ""
---

# Technician Toolkit Standard — Field Service Arsenal

> **Ringkasan:** Panduan standarisasi flashdisk toolkit teknisi servis komputer & laptop. Mencakup OS bootable, diagnosis storage, recovery data, password bypass, driver management, dan hardware programming — semua dalam satu flashdisk portabel.
> **Scope:** Teknisi servis, penjual elektronik bekas, sysadmin lapangan, dan pengoprek hardware.
> **Level:** Ring 3 (User Space) → Pre-Boot (Firmware) — tools berjalan di luar OS target.

---

## Daftar Isi

- [[#1. Konteks & Filosofi Toolkit]]
- [[#2. Struktur Flashdisk Servis]]
- [[#3. Level 0 — Bootable Foundation]]
- [[#4. Level 1 — Diagnosis & Honesty Tools]]
- [[#5. Level 2 — Data Recovery & Partition]]
- [[#6. Level 3 — Password & Access Bypass]]
- [[#7. Level 4 — Driver & System Deployment]]
- [[#8. Level 5 — Hardware Programming]]
- [[#9. Level 6 — Network & Remote Tools]]
- [[#10. Workflow Servis Lengkap]]
- [[#11. Gallery & Visual Reference]]

---

## 1. Konteks & Filosofi Toolkit

### Prinsip "Kejujuran adalah Koentji"

Di pasar barang bekas, transparansi adalah aset paling mahal. Toolkit ini dirancang bukan cuma untuk "perbaiki", tapi untuk **membuktikan** kondisi unit secara objektif:

- Screenshot SMART → bukti kesehatan storage
- Battery report → bukti kondisi baterai
- Surface scan → bukti tidak ada bad sector tersembunyi

### Arsitektur Single-Flashdisk

Semua tools di bawah ini muat dalam **satu flashdisk 128GB** dengan partisi:

- **Partition 1 (FAT32, 32GB):** Ventoy + ISO bootable
- **Partition 2 (NTFS, 96GB):** Tools portable, driver database, script

---

## 2. Struktur Flashdisk Servis

```text
💾 FLASHDISK TEKNISI (128GB)
│
├── 📁 [BOOT] Ventoy Partition (FAT32)
│   ├── 🖥️ ISO_WinPE/
│   │   ├── Sergei_Strelec_WinPE.iso
│   │   ├── Hiren_BootCD_PE.iso
│   │   ├── SystemRescue.iso
│   │   └── AIORescue.iso
│   ├── 🖥️ ISO_OS/
│   │   ├── Win10_Pro.iso
│   │   ├── Win11_Pro.iso
│   │   └── Ubuntu_LTS.iso
│   └── 🖥️ ISO_Misc/
│       └── MemTest86.iso
│
├── 📁 [DATA] NTFS Partition
│   ├── 🛠️ Tools_Portable/
│   │   ├── Diagnosis/
│   │   ├── Recovery/
│   │   ├── Password/
│   │   └── Network/
│   ├── 🎮 Drivers/
│   │   └── SDIO_Database/
│   ├── 📋 Scripts/
│   │   ├── debloat.ps1
│   │   └── battery-report.bat
│   └── 📁 Attachments/
│       └── (foto dokumentasi servis)
│
└── 📄 README.txt
    └── "Cara boot: Restart → F12 → Pilih USB → Pilih ISO di Ventoy"
```

---

## 3. Level 0 — Bootable Foundation

> **Fungsi:** Sistem operasi minimal yang bisa boot dari USB untuk akses penuh ke disk target tanpa bergantung pada OS yang terinstall.

| 🔐 Tool                  | ⚡ Fungsi                                                                                           | ☠️ Batasan                                  | 🎯 Gunakan Saat                                  |
| ------------------------ | --------------------------------------------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------ |
| **Ventoy**               | Multiboot manager — copy ISO langsung tanpa burn ulang                                              | Butuh UEFI/BIOS support USB boot            | Setup awal flashdisk, boot ke berbagai ISO       |
| **Sergei Strelec WinPE** | "Swiss Army Knife" teknisi modern. Driver NVMe terbaru, tools recovery pre-install, network support | Hanya Windows-based                         | Recovery, imaging, password reset, diagnosis     |
| **Hiren's BootCD PE**    | Klasik, tapi sudah jarang update. Masih reliable untuk tools legacy                                 | Driver NVMe lama, tidak support SSD terbaru | Legacy systems, old HDD recovery                 |
| **SystemRescue**         | Linux-based, command-line power. Support filesystem Linux & Windows                                 | Learning curve tinggi untuk user Windows    | Filesystem repair, RAID recovery, network rescue |
| **AIORescue**            | All-in-One rescue environment dengan GUI                                                            | Kurang dikenal, komunitas lebih kecil       | Alternatif Strelec jika butuh variasi            |

> [!tip]
> **Kenapa Ventoy wajib?** Tanpa Ventoy, lu harus format ulang flashdisk tiap mau ganti tool. Dengan Ventoy, tinggal copy-paste file ISO baru. Support persistence (simpan data antar boot) untuk Linux ISO.

---

## 4. Level 1 — Diagnosis & Honesty Tools

> **Fungsi:** Bukti objektif kondisi hardware untuk konsumen. Jangan cuma bilang "sehat" — tunjukkan angkanya.

### 4.1 Storage Diagnosis

| 🔐 Tool                | ⚡ Fungsi                                                                                | ☠️ Batasan                                  | 🎯 Gunakan Saat                              |
| ---------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------------- |
| **CrystalDiskInfo**    | SMART standard — health status, temperature, power-on hours, start-stop count            | Tidak deteksi bad sector latency            | Cek cepat kesehatan HDD/SSD                  |
| **Victoria HDD/SSD**   | Surface scan per-sektor dengan latency map. Orange/Red = sektor lemot meski SMART "Good" | Butuh waktu lama untuk full scan            | Jual HDD/SSD bekas — bukti kualitas          |
| **Hard Disk Sentinel** | Estimasi "Remaining Life" dalam hari. Paling komunikatif untuk orang awam                | Pro version berbayar untuk fitur penuh      | Kasih liat ke pembeli: "Sisa umur 847 hari"  |
| **CrystalDiskMark**    | Benchmark kecepatan read/write sequential & random                                       | Tidak menunjukkan kesehatan, hanya performa | Verifikasi SSD NVMe Gen 3/4                  |
| **ChipGenius**         | Baca controller USB flashdisk/SSD tanpa bongkar fisik                                    | Hanya identifikasi, tidak repair            | Cari MPTool yang tepat untuk flashdisk rusak |

### 4.2 Battery & Power Diagnosis

| 🔐 Tool / Command         | ⚡ Fungsi                                                                  | ☠️ Batasan                                 | 🎯 Gunakan Saat                          |
| ------------------------- | -------------------------------------------------------------------------- | ------------------------------------------ | ---------------------------------------- |
| `powercfg /batteryreport` | Generate HTML report: design capacity vs full charge capacity, cycle count | Hanya Windows                              | Cek laptop "baru" — ex-display detection |
| `powercfg /energy`        | Analisis efisiensi daya & deteksi proses yang menghabiskan baterai         | Report dalam 60 detik, butuh idle          | Laptop cepat habis baterai               |
| HWMonitor                 | Monitor voltase, temperature, wattage real-time                            | Hanya monitoring, tidak diagnosis otomatis | Stress test thermal                      |

### 4.3 Display & Physical Diagnosis

| 🔐 Tool / Method          | ⚡ Fungsi                                            | ☠️ Batasan                          | 🎯 Gunakan Saat        |
| ------------------------- | ---------------------------------------------------- | ----------------------------------- | ---------------------- |
| Dead Pixel Test (website) | Layar penuh warna (hitam, putih, merah, hijau, biru) | Butuh mata teliti                   | Cek laptop baru/second |
| Backlight Bleed Test      | Layar hitam pekat di ruangan gelap                   | Subjektif, tergantung sudut pandang | Cek panel IPS          |
| Engsel Test               | Buka tutup perlahan, dengar bunyi                    | Tidak ada tool digital              | Cek fisik mechanical   |

---

## 5. Level 2 — Data Recovery & Partition

> **Fungsi:** Selamatkan data dari disk yang terhapus, terformat, atau filesystem corrupt.

| 🔐 Tool                  | ⚡ Fungsi                                                                                     | ☠️ Batasan                                   | 🎯 Gunakan Saat                               |
| ------------------------ | --------------------------------------------------------------------------------------------- | -------------------------------------------- | --------------------------------------------- |
| **R-Studio**             | The Gold Standard recovery. File signature kuat, support RAID, network recovery, encrypted FS | Berbayar (mahal), learning curve             | Data kritikal, RAID failure, partition hancur |
| **DMDE**                 | Disk Editor + Recovery mungil tapi mematikan. Balikin partisi hilang dalam detik              | UI intimidatif untuk pemula                  | Partisi hilang tiba-tiba, table corrupt       |
| **TestDisk**             | Command-line, repair partition table (MBR/GPT), recover boot sector                           | No GUI (kecuali QPhotorec)                   | Boot sector corrupt, partition table rusak    |
| **PhotoRec**             | File carver — abaikan filesystem, cari signature file (JPG, PDF, ZIP) dari disk rusak         | Tidak recover nama file & struktur folder    | Disk RAW, filesystem tidak terbaca            |
| **DiskDrill**            | GUI user-friendly, scan cepat, preview file sebelum recovery                                  | Free version limit 500MB recovery            | User awam yang panic data hilang              |
| **EaseUS Data Recovery** | Iklan banyak, tapi dikenal luas                                                               | Free version limit, sering nag screen        | Alternatif DiskDrill untuk user biasa         |
| **Rescuezilla**          | Clone disk/partisi sector-by-sector. GUI berbasis Clonezilla                                  | Butuh storage target lebih besar dari source | Backup disk sebelum operasi berisiko          |
| **Macrium Reflect**      | Disk imaging & cloning dengan kompresi. Reliable untuk SSD migration                          | Free version cukup untuk cloning             | Clone HDD ke SSD (upgrade storage)            |

> [!warning]
> **Aturan Emas Recovery:**
>
> 1. **STOP** menggunakan disk yang terkena segera setelah kehilangan data.
> 2. **JANGAN** install recovery software ke disk yang sama dengan data hilang.
> 3. **ALWAYS** clone dulu ke disk cadangan sebelum recovery.
> 4. **SSD TRIM:** Kalau SSD sudah trigger TRIM (terhapus beberapa hari), data kemungkinan besar sudah tidak bisa diselamatkan.

---

## 6. Level 3 — Password & Access Bypass

> **Fungsi:** Akses unit yang terkunci password Windows atau BIOS — untuk servis, bukan kriminal.

### 6.1 Windows Password Bypass

| 🔐 Tool                     | ⚡ Fungsi                                                             | ☠️ Batasan                                  | 🎯 Gunakan Saat                      |
| --------------------------- | --------------------------------------------------------------------- | ------------------------------------------- | ------------------------------------ |
| **NTPWEdit**                | Edit file SAM langsung — unlock/change password Windows local account | Tidak work untuk akun Microsoft (online)    | Akun lokal terlupakan                |
| **PCUnlocker**              | Legendaris — nembus Windows 10/11 dengan akun Microsoft               | Berbayar untuk fitur penuh                  | Laptop bekas borongan dengan akun MS |
| **Lazesoft Recovery Suite** | Alternatif gratis, user-friendly                                      | Fitur terbatas vs PCUnlocker                | Pemula yang butuh GUI jelas          |
| **Kon-Boot**                | Bypass password tanpa mengubahnya — login langsung                    | Berbayar, tidak work di semua build Windows | Forensik cepat tanpa modifikasi SAM  |

### 6.2 BIOS Password Bypass

| 🔐 Tool / Method                  | ⚡ Fungsi                                            | ☠️ Batasan                                            | 🎯 Gunakan Saat                               |
| --------------------------------- | ---------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------- |
| **bios-pw.org**                   | Generate master password dari kode "System Disabled" | Tidak work di semua model (terutama ThinkPad baru)    | Laptop consumer (Dell, HP, Sony, Samsung)     |
| **CMOS De-Animator**              | Reset CMOS via software dari dalam Windows           | Hit or miss di motherboard terbaru                    | Laptop lama, BIOS password sederhana          |
| **Cabut Baterai CMOS**            | Klasik — hilangkan daya CMOS 5 menit                 | **TIDAK WORK** di laptop bisnis (EEPROM non-volatile) | Desktop, laptop lama (pre-2015)               |
| **CH341A Programmer + SOP8 Clip** | Flash EEPROM BIOS langsung dengan firmware bersih    | Butuh skill hardware, risk brick                      | Laptop bisnis (ThinkPad, EliteBook, Latitude) |

> [!caution]
> **Disclaimer Etik:** Tools ini hanya untuk unit yang **milik sendiri** atau **dengan surat kuasa tertulis**. Mengakses device orang lain tanpa izin adalah **tindak pidana** sesuai UU ITE.

---

## 7. Level 4 — Driver & System Deployment

> **Fungsi:** Deploy OS baru, install driver, dan bersihkan sistem dari bloatware.

| 🔐 Tool                                   | ⚡ Fungsi                                                         | ☠️ Batasan                               | 🎯 Gunakan Saat                          |
| ----------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| **Snappy Driver Installer Origin (SDIO)** | Database driver offline, scan & install otomatis. Tidak ada iklan | Database besar (butuh storage eksternal) | Install driver 50+ laptop tanpa internet |
| **DDU — Display Driver Uninstaller**      | Bersihkan driver GPU (NVIDIA/AMD/Intel) total tanpa sisa          | Harus di Safe Mode untuk hasil maksimal  | Jual GPU bekas, ganti kartu grafis       |
| **WizTree / WinDirStat**                  | Visualisasi penggunaan disk — temukan file besar & cache          | Hanya analisis, tidak auto-cleanup       | "HDD penuh padahal gak nyimpen apa-apa"  |
| **Windows Debloat Script**                | Hapus bloatware Windows (Candy Crush, Xbox, OneDrive)             | Bisa break fitur jika terlalu agresif    | Setup laptop baru untuk konsumen         |
| **O&O ShutUp10++**                        | Privacy tweaker — disable telemetry, Cortana, ads                 | Hanya Windows 10/11                      | Hardening privacy laptop baru            |

---

## 8. Level 5 — Hardware Programming

> **Fungsi:** Perbaikan level chip — flash EEPROM, repair firmware, dan kanibalan komponen.

| 🔐 Tool                 | ⚡ Fungsi                                                    | ☠️ Batasan                         | 🎯 Gunakan Saat                    |
| ----------------------- | ------------------------------------------------------------ | ---------------------------------- | ---------------------------------- |
| **CH341A Programmer**   | Flash/read EEPROM BIOS, SPI flash chip                       | Butuh identifikasi chip yang benar | BIOS corrupt, remove password BIOS |
| **SOP8 Test Clip**      | Jepit chip EEPROM tanpa solder — non-destructive             | Tidak semua package chip support   | Laptop dengan chip soldered        |
| **TL866II Plus**        | Universal programmer — support lebih banyak chip dari CH341A | Harga lebih mahal                  | Servis intensif EEPROM             |
| **Bus Pirate / FT232H** | JTAG/SPI/I2C interface untuk debugging hardware              | Learning curve sangat tinggi       | Reverse engineering hardware       |

---

## 9. Level 6 — Network & Remote Tools

> **Fungsi:** Diagnosis jaringan, remote access, dan bypass AP Isolation untuk servis jarak jauh.

| 🔐 Tool                | ⚡ Fungsi                                          | ☠️ Batasan                                      | 🎯 Gunakan Saat                             |
| ---------------------- | -------------------------------------------------- | ----------------------------------------------- | ------------------------------------------- |
| **Wireshark**          | Capture & analisis packet network real-time        | Butuh promiscuous mode                          | Deteksi C2 beaconing, analisis traffic aneh |
| **nmap / Zenmap**      | Port scanner, OS fingerprinting, service detection | Bisa dianggap hostile oleh firewall target      | Mapping jaringan lokal                      |
| **Angry IP Scanner**   | Fast IP & port scanner dengan GUI                  | Simpler dari nmap, kurang detail                | Cek device aktif di LAN                     |
| **AnyDesk / RustDesk** | Remote desktop gratis untuk support jarak jauh     | Butuh internet, security risk jika tidak dijaga | Support konsumen remote                     |
| **Putty / KiTTY**      | SSH/Telnet client                                  | Hanya terminal                                  | Remote ke server/router                     |

---

## 10. Workflow Servis Lengkap

### 10.1 Skenario A: Laptop Baru Datang (QC)

```text
[UNIT BARU DATANG]
│
▼
┌─────────────────────────────┐
│ 1. FISIK                    │
│    - Cek engsel, port, bodi │
│    - Cek dead pixel         │
│    - Cek backlight bleed    │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 2. STORAGE (CrystalDiskInfo)│
│    - Power On Count < 10    │
│    - Power On Hours = 0     │
│    - Health Status = Good   │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 3. BATTERY (powercfg)       │
│    - Design vs Full Charge  │
│    - Selisih < 1%           │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 4. PERFORMANCE              │
│    - CrystalDiskMark        │
│    - HWMonitor (thermal)    │
│    - Cinebench (opsional)   │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 5. DEBLOAT & SETUP          │
│    - Hapus bloatware        │
│    - Update Windows         │
│    - Install driver (SDIO)  │
└──────────────┬──────────────┘
│
▼
[DOCUMENTASI & SERAHKAN]
```

### 10.2 Skenario B: Data Recovery (Emergency)

```text
[KONSUMEN: "DATA HILANG!"]
│
▼
┌─────────────────────────────┐
│ 1. ANAMNESA                 │
│    - Apa yang terjadi?      │
│    - Sejak kapan?           │
│    - Apakah masih dipakai?  │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 2. ASSESSMENT               │
│    - Boot dari Strelec      │
│    - CrystalDiskInfo cek    │
│    - Jangan boot ke OS!     │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 3. CLONE (Rescuezilla)      │
│    - Clone ke disk cadangan │
│    - Kerja dari clone!      │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 4. RECOVERY                 │
│    - R-Studio (kritikal)    │
│    - DMDE (partisi hilang)  │
│    - PhotoRec (last resort) │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 5. VERIFIKASI               │
│    - Cek file recovered     │
│    - Cek corrupt/tidak      │
│    - Copy ke media konsumen │
└──────────────┬──────────────┘
│
▼
[INVOICE & EDUKASI BACKUP]
```

### 10.3 Skenario C: Laptop Terkunci (Password)

```text
[UNIT TERKUNCI]
│
▼
┌─────────────────────────────┐
│ 1. IDENTIFIKASI LOCK        │
│    - Windows password?      │
│    - BIOS password?         │
│    - Microsoft account?     │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 2. WINDOWS PASSWORD         │
│    - Boot Strelec           │
│    - NTPWEdit → SAM file    │
│    - Unlock/Change password │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 3. BIOS PASSWORD            │
│    - Coba bios-pw.org       │
│    - Cabut CMOS (lama)      │
│    - CH341A (bisnis)        │
└──────────────┬──────────────┘
│
▼
┌─────────────────────────────┐
│ 4. MICROSOFT ACCOUNT        │
│    - PCUnlocker (berbayar)  │
│    - Atau reset via email   │
│    - Disclaimer: data?      │
└──────────────┬──────────────┘
│
▼
[RESET & SERAHKAN]
```

---

## 11. Gallery & Visual Reference

> [!info]
> Placeholder untuk gambar-gambar yang akan ditambahkan:

| No  | Nama File                     | Deskripsi                                     | Prioritas |
| --- | ----------------------------- | --------------------------------------------- | --------- |
| 1   | `ventoy-menu.png`             | Tampilan menu boot Ventoy dengan multiple ISO | Tinggi    |
| 2   | `strelec-desktop.png`         | Desktop Sergei Strelec WinPE                  | Tinggi    |
| 3   | `crystaldiskinfo-good.png`    | Screenshot SMART status "Good"                | Tinggi    |
| 4   | `crystaldiskinfo-caution.png` | Screenshot SMART status "Caution"             | Tinggi    |
| 5   | `victoria-scan.png`           | Surface scan Victoria dengan map warna        | Sedang    |
| 6   | `r-studio-recovery.png`       | Interface R-Studio saat scan                  | Sedang    |
| 7   | `ntpwedit-sam.png`            | NTPWEdit membuka file SAM                     | Sedang    |
| 8   | `ch341a-setup.png`            | CH341A + SOP8 clip terpasang di chip          | Sedang    |
| 9   | `sdio-driver-scan.png`        | Snappy Driver Installer scan result           | Rendah    |
| 10  | `battery-report-html.png`     | Hasil powercfg /batteryreport                 | Rendah    |

---

## Connected Notes

- [[printer-maintenance-reset]] — Servis printer inkjet (Epson, Canon, Brother, HP)
- [[endpoint-security-freeware]] — Arsitektur keamanan endpoint (Ring -3 sampai Ring 3)
- [[storage-refurbishing]] — Refurbishing HDD/SSD untuk dijual kembali
- [[laptop-qc-procurement|TEMA-C-Laptop-QC-Procurement]] — QC laptop & procurement guide
- [[application]] — 🛠️ Master Interactive Tool Arsenal (GitHub Pages)
  - [Forensics & Data Recovery](https://azhar457.github.io/application/Application_Forensics_Recovery.html) — 49 tools
  - [Cyber Security](https://azhar457.github.io/application/Application_Cyber_Security.html) — 62 tools
  - [Cyber Offense](https://azhar457.github.io/application/Application_Cyber_Offense.html) — 68 tools

---

## Changelog

| Versi | Tanggal    | Perubahan                                                           |
| ----- | ---------- | ------------------------------------------------------------------- |
| v1.0  | 2026-05-11 | Dokumen awal dari RAW chat, mapping ke Arsenal Forensics & Recovery |

---

_End of Document — Technician Toolkit Standard | Dari Ventoy sampai CH341A | Field Service Arsenal_
