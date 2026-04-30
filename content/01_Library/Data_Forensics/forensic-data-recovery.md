---
tags:
  - data-recovery
  - forensik
  - tools
  - DVR
  - CCTV
  - imaging
aliases:
  - Data Recovery Forensik
  - Recovery Tools Comparison
created: 2026-04-25
status: operational
---

# 💾 DATA RECOVERY & FORENSIK — Perbandingan Tools

> Peta lengkap ekosistem tools data recovery dan forensik digital. Dari software logis untuk file terhapus hingga hardware god-mode untuk firmware corrupt dan DVR/CCTV recovery.

> [!info] Workflow Profesional — Urutan Wajib
> Expert selalu jadikan **disk image (.dd) dulu** sebelum menyentuh apapun.
> `dd` / `ddrescue` / Atola → hasilkan `.dd` → baru analisis pakai Autopsy / R-Studio / dsb.
> Alasan: kerja di copy, bukan di original — jika salah, original tetap aman.

---

## Tabel 1 — PC-3000 vs Dolphin Video Pro

> Dua tool hardware God-Mode dari dua negara berbeda, spesialisasi berbeda.

| Fitur                  | **PC-3000** _(Rusia — ACE Lab)_                                               | **Dolphin Video Pro Business** _(China)_                                            |
| ---------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Kekuatan Utama**     | Perbaikan Firmware & Hardware HDD/SSD — paling powerful di kelasnya           | Pemulihan file video & rekaman DVR/CCTV — paling spesifik di kelasnya               |
| **Spesialisasi**       | Firmware corrupt, kapasitas 0MB, head mati sebagian, bypass password hardware | Video fragmen, rekaman DVR yang tertimpa, file video korup, format CCTV proprietary |
| **DVR/CCTV Recovery**  | Bisa, tapi bukan fokus utama                                                  | ✅ Spesialis — bisa recovery rekaman bulan lalu meski sudah tertimpa rekaman baru   |
| **Perbaikan Firmware** | ✅ God Mode — tulis ulang ROM, bypass SA track                                | Terbatas — lebih ke scan logis                                                      |
| **Deep Scan**          | ✅ Hardware level — langsung ke platter/NAND                                  | ✅ Untuk video fragment reconstruction                                              |
| **Gaya Kerja**         | Manual, butuh pengetahuan teknis tinggi                                       | Lebih otomatis — wizard-based untuk video                                           |
| **Target User**        | Lab data recovery besar, spesialis firmware                                   | Teknisi forensik, polisi, lab recovery menengah                                     |
| **Harga**              | $2.000–$8.000+                                                                | $500–$2.000                                                                         |
| **Asal**               | Rusia (ACE Lab)                                                               | China                                                                               |

> [!tip] Kenapa DVR Bulan September Bisa Balik Padahal Sudah Desember?
> DVR/CCTV pakai sistem overwrite circular — saat storage penuh, rekaman lama ditimpa rekaman baru. Tapi **sektor yang sudah "ditimpa" tidak langsung terhapus sempurna di level NAND/platter** — ada residual data yang bisa direkonstruksi. Dolphin Video Pro spesialis rekonstruksi fragment video dari sektor-sektor ini, bahkan dari format DVR proprietary yang tidak terdokumentasi.

---

## Tabel 2 — Spesialisasi Tools Recovery & Forensik

| 🛠️ Nama Alat             | 🎯 Spesialisasi Utama        | ⚡ Fitur Unggulan                                                                                                                  | 👤 Target User                   |
| ------------------------ | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| **R-Studio** _(R-Tools)_ | Dokumen & File System        | Pemulihan dokumen (.docx, .pdf, .xlsx) dari partisi diformat/rusak. Support hampir semua file system (NTFS, FAT, APFS, Ext4).      | Teknisi pro & perusahaan         |
| **UFS Explorer**         | RAID & Server                | Rajanya rekonstruksi RAID (0, 1, 5, 6, dll). Sangat kuat untuk NAS/SAN dan file virtualisasi (.vmdk, .vhd).                        | Spesialis server & data center   |
| **Magnet AXIOM**         | Forensik & Artefak Digital   | Mencari jejak digital: riwayat chat, dokumen tersembunyi, bukti aktivitas user. Fokus integritas hukum — chain of custody.         | Polisi & auditor IT              |
| **Cellebrite UFED**      | Mobile (HP/Tablet)           | Menembus keamanan Android/iOS untuk ambil data chat, foto, dokumen terhapus langsung dari chip memori.                             | Tim forensik digital             |
| **Atola TaskForce**      | Imaging & Diagnosa Hardware  | Hardware imager tercepat. Diagnosa kerusakan hardware otomatis sebelum data ditarik ke software logis. Hasilkan .dd / .E01.        | Lab recovery skala besar         |
| **DMDE**                 | Manual Hex Editing           | "Pisau bedah" manual. Edit tabel partisi langsung, sangat akurat jika software otomatis gagal. Murah tapi maut.                    | Expert / opreker hardcore        |
| **RapidSpar**            | Cloud-Based Firmware Repair  | Hardware terhubung ke cloud untuk perbaiki firmware HDD/SSD otomatis tanpa perlu jadi ahli firmware.                               | Toko komputer / teknisi menengah |
| **Autopsy**              | Forensik Digital Open Source | Frontend GUI untuk The Sleuth Kit. Analisis disk image (.dd / .E01), timeline activity, keyword search, hash verification. Gratis. | Investigator, mahasiswa forensik |
| **Dolphin Video Pro**    | DVR/CCTV Video Recovery      | Recovery rekaman DVR yang tertimpa, format CCTV proprietary, rekonstruksi video fragmen.                                           | Teknisi forensik, polisi         |
| **PC-3000** _(ACE Lab)_  | Firmware & Hardware God Mode | Tulis ulang ROM/firmware, bypass password ATA, matikan head rusak secara mikro, kapasitas 0MB.                                     | Lab data recovery tier atas      |

---

## Tabel 3 — Workflow Forensik Profesional

```
DISK / STORAGE TARGET
        │
        ▼
[FASE 1 — IMAGING] ← JANGAN SKIP INI
Atola TaskForce / ddrescue / dc3dd
        │
        │ Output: file .dd atau .E01 (disk image)
        │ Original tidak disentuh lagi setelah ini
        ▼
[FASE 2 — ANALISIS]
        │
        ├── File recovery umum  → R-Studio / DMDE
        ├── Forensik digital    → Autopsy / Magnet AXIOM
        ├── RAID/NAS            → UFS Explorer
        ├── Mobile              → Cellebrite UFED
        └── DVR/CCTV video      → Dolphin Video Pro
        │
        ▼
[FASE 3 — HARDWARE INTERVENTION]
(jika firmware/hardware bermasalah — dilakukan SEBELUM imaging)
        │
        ├── Firmware corrupt    → PC-3000
        ├── Head mati           → PC-3000 + Clean Room
        └── Kapasitas 0MB       → PC-3000 / RapidSpar
```

> [!warning] Urutan yang Sering Salah
> Banyak teknisi langsung colok drive rusak ke software recovery tanpa imaging dulu. Jika drive dalam kondisi degraded (bad sector, head lemah), setiap akses read tambahan memperburuk kondisi fisik. **Imaging dulu dengan ddrescue / Atola = selamatkan semua yang bisa diselamatkan sebelum drive mati total.**

---

## Format Image yang Dipakai

| Format           | Tools               | Keterangan                                      |
| ---------------- | ------------------- | ----------------------------------------------- |
| `.dd` / `.img`   | dd, ddrescue, dc3dd | Raw bit-for-bit copy, paling universal          |
| `.E01`           | EnCase, FTK Imager  | Forensik standard, ada metadata + hash built-in |
| `.AFF`           | AFFLIB              | Open source forensik format                     |
| `.vmdk` / `.vhd` | Virtualisasi        | Untuk mount sebagai virtual disk                |

---

## 🛠️ Interactive Tool List — Forensics & Data Recovery

<iframe src="https://azhar457.github.io/Application/Application_Forensics_Recovery.html" width="100%" height="600px" frameborder="0"></iframe>

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[TOOLS_PENTING]] — hierarki data recovery Level 0–7
- [[SOP_HPA_Exorcism]] — prosedur destruktif HPA/DCO/MBR
- [[RE_HARDWARE_HACKING]] — chip-off dan flash dump

---

_Data Recovery & Forensik Tools | PC-3000 · Dolphin · Autopsy · Workflow .dd Imaging_
