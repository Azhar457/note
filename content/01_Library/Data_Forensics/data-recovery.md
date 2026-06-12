---
tags:
  - data-recovery
  - forensics
  - hardware
  - disk-refurbishing
aliases:
  - Data Recovery & Forensics
  - Pemulihan Data
created: 2026-06-12
status: operational
---

# 💾 DATA RECOVERY & FORENSIK — Panduan Komprehensif

> Penggabungan dari dasar-dasar pemulihan data hingga taktik forensik tingkat lanjut.

---

> Urutan triage dari mata telanjang sampai fisika kuantum. **Selalu mulai dari Level terendah** — jangan loncat langsung ke Level tinggi. Setiap level menyaring masalah yang bisa diselesaikan di situ sebelum eskalasi ke level yang lebih mahal.

> [!info] Cara Baca
> Level 0 = gratis (mata & telinga). Level 7 = budget negara adidaya. Baca kolom "SKIP Jika…" untuk tahu kapan harus eskalasi. Kolom "Jika Masih Ada Harapan…" menunjukkan level berikutnya.

---

## Tabel Recovery — Level 0 sampai Level 7

| Level & Alat                                                                               | Fungsi Utama & Sweet Spot                                                                                                                                  | ☠️ Tembok Kematian                                                                                                                         | 💀 SKIP Jika...                                                                                                                               | 🛠️ Jika Masih Ada Harapan...                                                                                                                                       |
| ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Level 0** — Sensorik Fisik & BIOS _(Mata, Telinga, PC BIOS)_                             | Pemilahan barang lelang super kilat (0–30 detik). Memisahkan bangkai total dari barang potensial.                                                          | Hanya mendeteksi respons listrik dasar. Tidak bisa melihat kesehatan sel memori internal.                                                  | Pin SATA gosong/patah, HDD bunyi klik/menderu kasar (Click of Death), atau BIOS membaca kapasitas aneh (0MB atau `SATAFIRM S11`).             | Jika BIOS membaca nama/kapasitas dengan benar dan suara HDD halus → segera masuk ke **Level 2** (WinPE/Hiren's) untuk cek S.M.A.R.T.                               |
| **Level 1** — OS-Level Software _(Disk Drill, Recuva di Windows LTSC)_                     | Mengais data dari partisi yang tidak sengaja terformat (RAW) atau file terhapus dari Recycle Bin.                                                          | Sangat bergantung pada izin dan stabilitas Kernel Windows.                                                                                 | Controller HDD mulai membanjiri Windows dengan error → PC freeze, Not Responding, atau BSOD saat di-scan.                                     | Jika OS Windows menyerah → bypass OS dengan booting ke lingkungan ringan. Gunakan **Level 2** (Hiren's BootCD PE).                                                 |
| **Level 2** — Pre-OS / WinPE RAM _(Victoria, HD Sentinel via Hiren's)_                     | Triage 3 Menit. Membaca S.M.A.R.T. Uji surface scan kilat untuk menyortir HDD lelang yang lambat vs cepat.                                                 | Terikat pada driver Windows bawaan. Tetap bisa hang jika sinyal dari drive terlalu kacau.                                                  | S.M.A.R.T Health di bawah 30% dengan Reallocated Sector ribuan, atau scan 2 menit pertama di Victoria penuh blok Biru (ERR) & Merah.          | Jika Victoria hang/freeze tapi drive masih terbaca di BIOS → butuh akses langsung ke port I/O. Gunakan **Level 3** (UnderDOS) atau **Level 4** (Linux Bare-Metal). |
| **Level 3** — Bare-Metal Legacy _(MHDD, HDAT2 via FreeDOS / UBCD)_                         | Mengeksekusi Logical Bad Sector membandel pada HDD SATA/IDE lawas tanpa takut PC hang (langsung tembak Port I/O).                                          | Buta total terhadap SSD M.2 NVMe (PCIe) dan sistem Pure UEFI modern.                                                                       | Head pembaca sudah mati fisik (bunyi cetek-cetek) atau drive tidak merespons perintah ATA tingkat rendah sama sekali.                         | Jika drive yang sakit adalah M.2 NVMe, atau butuh fitur Multi-Pass Cloning cerdas → wajib bermigrasi ke **Level 4** (HDDSuperClone).                               |
| **Level 4** — Bare-Metal Modern _(HDDSuperClone via Rocky Linux / USB Ventoy)_             | Penerus UnderDOS. Cloning kejam untuk SATA & NVMe dengan fitur lompat (skip) bad sector dalam hitungan milidetik.                                          | Tidak bisa memperbaiki firmware bawaan pabrik yang sudah corrupt atau microcontroller mati.                                                | Fase 1 (Fast Read) di HDDSuperClone berjalan sangat lambat, indikator "Skips" meroket tajam, dan estimasi waktu berbulan-bulan.               | Jika drive sangat berharga dan firmware-nya mati total (terbaca 0MB) → butuh intervensi perangkat keras di **Level 5** (PC-3000).                                  |
| **Level 5** — Hardware & Firmware _(PC-3000 PCI-E Card by ACE Lab)_                        | **God Mode.** Menulis ulang ROM/Firmware, bypass password ATA, mematikan head rusak secara mikro.                                                          | Tidak bisa memperbaiki kerusakan fisik piringan atau silikon memori yang retak.                                                            | Piringan HDD mengalami Rotational Scoring (tergores cincin parah) atau cip silikon NAND pada SSD retak secara fisik (micro-fracture).         | Jika controller hancur, cip dikunci enkripsi hardware kelas militer, atau piringan tergores dan data seharga nyawa → lempar ke **Level 6**.                        |
| **Level 6** — Deep Nano-Physics _(FIB, MFM, Chemical Decapsulation)_                       | Membaca sisa fluks magnetik (platter) atau mengiris atom silikon (NAND die) untuk mengekstrak elektron satu per satu.                                      | Hukum Alam & Kriptografi Modern. Proses menghancurkan medium secara permanen.                                                              | Kunci dekripsi AES-256 mati total bersama cipnya (data terbaca sebagai kode acak abadi), atau silikon sudah hancur jadi abu.                  | **TIDAK ADA.** Ikhlaskan, seduh kopi, dan move on ke drive lelang berikutnya. Wkwkwk.                                                                              |
| **Level 7** — Kriptanalisis Kuantum _(Komputer Kuantum, Algoritma Grover/Shor — Tier NSA)_ | Matematika Murni. Menghancurkan tembok enkripsi (BitLocker/Apple T2) secara brute-force kuantum ketika chip controller atau kunci aslinya hangus sempurna. | Hukum Termodinamika & Kapasitas Qubit. AES-256 masih kebal terhadap komputer kuantum saat ini. Butuh jutaan qubit stabil di suhu 0 Kelvin. | Anda bukan negara adidaya dengan budget triliunan rupiah dan akses ke fasilitas riset rahasia berpendingin nitrogen cair (IBM/Google/D-Wave). | Anda bukan negara adidaya dengan budget triliunan rupiah dan akses ke fasilitas riset rahasia berpendingin nitrogen cair (IBM/Google/D-Wave).                      |

---

## Diagram Alur Keputusan Recovery

```
DRIVE MASUK
     │
     ▼
[Level 0] Cek fisik — BIOS baca normal? Suara wajar?
     │ YA                    │ TIDAK
     ▼                       ▼
[Level 2] Cek SMART       SKIP / Kanibal
     │ Sehat?
     │ YA → [Level 1] Software recovery (Disk Drill)
     │ NO → SMART parah?
            │ YA → [Level 3/4] Bare-metal (MHDD / HDDSuperClone)
            │       │ Firmware mati?
            │       │ YA → [Level 5] PC-3000 God Mode
            │       │       │ Fisik hancur?
            │       │       │ YA → [Level 6] Lab Nano-Physics
            │       │       │       │ Enkripsi + kunci hangus?
            │       │       │       │ YA → [Level 7] Quantum / Ikhlas ☕
```

> [!warning] Jangan Loncat Level
> Loncat dari Level 0 langsung ke Level 5 = membuang uang dan waktu. Setiap level menyaring masalah yang bisa diselesaikan di situ sebelum eskalasi ke level yang lebih mahal.

---

## 3. Alat Forensik Profesional & Perbandingan

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

---

## 🔗 Lihat Juga

- [[02_SOPs/storage-refurbishing|SOP Storage Recovery / Data Lifesaver]]
- [[02_SOPs/forensic-imaging-analysis|SOP Forensic Imaging]]
- [[🗺️Master-Index|Master Index]]
