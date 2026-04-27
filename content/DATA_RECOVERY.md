---
tags:
  - data-recovery
  - forensics
  - hardware
  - hdd
  - ssd
  - clean-room
aliases:
  - Data Recovery
  - Recovery Hierarchy
  - Partition Recovery
created: 2026-04-25
status: operational
cssclasses:
  - wide-table
---

# 💾 DATA RECOVERY — Partition & Recovery Hierarchy

> Urutan triage dari mata telanjang sampai fisika kuantum. **Selalu mulai dari Level terendah** — jangan loncat langsung ke Level tinggi. Setiap level menyaring masalah yang bisa diselesaikan di situ sebelum eskalasi ke level yang lebih mahal.

> [!info] Cara Baca
> Level 0 = gratis (mata & telinga). Level 7 = budget negara adidaya. Baca kolom "SKIP Jika…" untuk tahu kapan harus eskalasi. Kolom "Jika Masih Ada Harapan…" menunjukkan level berikutnya.

---

## Tabel Recovery — Level 0 sampai Level 7

| Level & Alat                                                                               | Fungsi Utama & Sweet Spot                                                                                                                                  | ☠️ Tembok Kematian                                                                                                                         | 💀 SKIP Jika...                                                                                                                               | 🛠️ Jika Masih Ada Harapan...                                                                                                                                      |
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

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[ENDPOINT_SECURITY]] — CPU Ring & Boot Chain Threat
- [[NETWORK_SECURITY]] — OSI Layer 1–8 Blue/Red Team
- [[EMBEDDED_SYSTEMS]] — Flash Drive Forensics & NAND Internals
- [[SOP_HPA_Exorcism]] — SOP destruktif HPA/DCO Reset
- [[SOP — The Data Lifesaver & Disk Refurbish]] — SOP recovery + refurbish HDD
- [[KRIPTOGRAFI_BIOMETRIK]] — Enkripsi yang jadi tembok di Level 6–7

---

*Data Recovery | Level 0 (Sensorik Fisik) sampai Level 7 (Kriptanalisis Kuantum) · Recovery Hierarchy*
