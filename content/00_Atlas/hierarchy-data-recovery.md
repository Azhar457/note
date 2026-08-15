---
title: Hierarchy Data Recovery
tags:
- atlas
- data-forensics
- data-recovery
- hardware
created: '2026-07-17'
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  
---


# 💾 HIERARKI DATA RECOVERY — Dari Sensorik Mata Telanjang (Level 0) sampai Kriptanalisis Kuantum (Level 7)

> Setiap drive yang gagal adalah teka-teki yang harus di-triage dari murah ke mahal. Hirarki data recovery adalah **geometri biaya eksponensial** — Level 0 gratis (mata & telinga), Level 7 butuh triliunan rupiah + fasilitas riset rahasia. Setiap level menyaring kasus yang bisa diselesaikan **di situ** sebelum eskalasi — loncat level = membuang uang dan waktu. Untuk tabel lengkap level + tools + kapan skip, lihat [[data-recovery]].

> [!info] Cara Baca
> Level 0 = biaya manusia + monitor saja. Level 7 = chip decryption di IBM Quantum. Baca kolom "Skip Jika…" untuk tahu kapan harus eskalasi; kolom "Jika Masih Ada Harapan…" menunjukkan langkah berikutnya. **Selalu mulai dari Level terendah**. Bukan saran — itu satu-satunya cara hemat.

---

## Tabel Utama — Level 0 sampai Level 7

| 💾 Level | 🧠 Zona & Alat | ⚡ Sweet Spot | ☠️ Tembok Kematian | 🎯 Cocok Untuk Siapa |
|---|---|---|---|---|
| **Level 0** — Sensorik Fisik & BIOS | Mata, telinga, indikator LED drive, BIOS POST screen | Triage 30 detik: drive hidup atau mati? Bunyi normal atau abnormal? BIOS baca kapasitas wajar atau `SATAFIRM S11` (firmware corrupt)? | Tidak bisa mendiagnosis internal cell health. Kalau drive bunyi click-of-death atau PCB gosong, mata gak bisa lihat lapisan dalam | Pembeli barang lelang, tukang servis cepat, siapa saja yang mau sortir cepat mana drive yang layak diselamatkan vs mana yang jadi kanibal |
| **Level 1** — OS-Level Software | Recuva, Disk Drill, TestDisk, PhotoRec (Windows LTSC / Linux live) | Mengais file terhapus dari Recycle Bin atau partisi terformat (RAW). Cepat, gratis, ribuan file bisa diselamatkan kalau level corruption rendah | Bergantung izin OS. Tidak bisa bypass corrupt filesystem berat. Kalau controller HDD error → Windows freeze atau BSOD | Pengguna rumahan yang tidak sengaja hapus foto, teknisi servis ringan, kasus "user salah klik" |
| **Level 2** — Pre-OS / WinPE | Hiren's BootCD PE, Victoria SSD/HDD, HD Sentinel dari PE | Triage 3 menit via SMART. Test surface scan kilat sortir HDD cepat vs lambat. **Punya akses langsung ke storage tanpa OS interference** | Tetap terikat driver bawaan. Bisa hang kalau sinyal drive sangat kacau | Teknisi servis barang lelang, fleet auditor storage, triage pra-investasi |
| **Level 3** — Bare-Metal Legacy | MHDD, HDAT2, Victoria di FreeDOS / UBCD via USB | Eksekusi logical bad sector membandel pada HDD SATA/IDE. Tembak langsung port I/O tanpa Windows intervening | Buta terhadap SSD M.2 NVMe. Tidak support UEFI modern | Perbaikan HDD lawas, servis workshop repair, owner data lama |
| **Level 4** — Bare-Metal Modern | HDDSuperClone via Rocky Linux / Ventoy, ddrescue, Atola | Cloning “kejam” dengan skip bad sector milidetik. Cocok SATA & NVMe. **Multi-pass cloning** dengan algoritma adaptif. **Bisa boot via Linux USB, gak butuh OS host** | Tidak bisa perbaiki firmware corrupt atau controller mati | Forensik profesional, recovery center, tim IR saat drive korban ransomware perlu dikloning sebelum dianalisa |
| **Level 5** — Hardware & Firmware | PC-3000 PCI-E (ACE Lab), Rusolut, DeepSpar | **God Mode**. Tulis ulang ROM/firmware, bypass ATA password, disable head rusak via command micro. Recovery drive yang di-declare "mati" oleh software | Tidak bisa perbaiki platter tergores (rotational scoring) atau silicon hancur | Recovery center profesional, forensik hukum (chain of custody penting), kasus data seharga bisnis |
| **Level 6** — Deep Nano-Physics | Focused Ion Beam (FIB), Magnetic Force Microscopy (MFM), chemical decapsulation, electron microscope | Baca sisa fluks magnetik platter atau iris atom silikon NAND untuk ekstrak elektron satu per satu. **Tingkat atom per atom** | **Hukum fisika**. Proses ini menghancurkan medium secara permanen. Kalau ada enkripsi AES-256 + chip mati = kode acak abadi | Nation-state intelligence, kasus forensik kelas dunia (black box pesawat), riset akademis |
| **Level 7** — Kriptanalisis Kuantum | Komputer kuantum (IBM, Google, D-Wave), Algoritma Grover / Shor | Matematika murni. Hancurkan tembok enkripsi AES-256/BitLocker/Apple T2 via brute-force kuantum kalau chip controller hangus sempurna | **Hukum termodinamika**. AES-256 masih kebal quantum computer hari ini. Butuh jutaan qubit stabil di suhu 0 Kelvin. Hampir mustahil dalam dekade ini | NSA, GCHQ, Mossad, dst. — negara adidaya dengan budget triliunan + akses ke fasilitas riset rahasia |

---

## Peta Visual — Geometri Biaya vs Kompleksitas

```
                        ↑ Biaya Eksponensial
                        ↑ Effort Meninggi
                        ↑
   Level 7 ─────────────┼──────── Kuantum kriptanalisis
                        │         └─ Budget negara adidaya
   Level 6 ─────────────┼──────── Nano-physics lab
                        │         └─ Puluhan miliar / kasus
   Level 5 ─────────────┼──────── PC-3000 / hardware tools
                        │         └─ Puluhan juta (one-time) + per kasus
   Level 4 ─────────────┼──────── Bare-metal cloning
                        │         └─ Gratis (Linux) s.d. beberapa juta (appliance)
   Level 3 ─────────────┼──────── Legacy bare-metal (FreeDOS)
                        │         └─ Gratis (download ISO)
   Level 2 ─────────────┼──────── WinPE boot
                        │         └─ Gratis (Hiren's)
   Level 1 ─────────────┼──────── OS-level software
                        │         └─ Gratis s.d. subscription (Recuva=RBD)
   Level 0 ─────────────┼──────── Mata, telinga, BIOS POST
                        │         └─ Rp 0 (sensorik)
                        ↓ Biaya Nol
                        ↓ Semakin Mudah Diakses Siapa Saja
```

> [!warning] Jangan Loncat Level
> Loncat dari Level 0 langsung ke Level 5 = membuang uang dan waktu. Contoh nyata: banyak servis center pemula yang langsung beli lisensi PC-3000 padahal 90% kasus mereka solvable di Level 1–3. Hormati hierarki: apapun drive, **mulai dari Level 0**, eskalasi hanya kalau yakin level sebelumnya sudah exhausted.

---

## Kenapa Hirarki Ini Penting

### 1. Setiap Drive Memiliki "Batas Yang Tidak Bisa Dilampaui"

Tidak ada tools — secanggih apapun — yang bisa membaca:
- Platter yang tergores parah (rotational scoring) → hukum fisika
- Cipher AES-256 kalau kunci hilang → hukum matematika
- Data yang sudah ditimpa (overwritten) → hukum informasi (Shannon entropy)

Hirarki bukan cuma "urutan ekskalasi" — dia juga jujur soal **kapan harus menyerah**. Level 6 bilang "proses ini menghancurkan medium." Level 7 bilang "butuh negara adidaya." Menerima kenyataan ini adalah skill profesional.

### 2. "Cheap" Bukan Berarti "Rendah Kualitas"

Level 0–3 terdengar murah — tapi **80% kasus data recovery solvable di sini**. Mata & telinga bisa sortir 80% barang lelang jadi kanibal vs restorable. WinPE Hiren's + Victoria menyelamatkan ribuan kasus yang toko lain "mati-in." Loncat ke Level 5 mungkin kelihatan impressive, tapi tidak selalu perlu.

### 3. Forensik vs Recovery Itu Berbeda

| Aspek | Data Recovery | Digital Forensics |
|---|---|---|
| **Tujuan** | Selamatkan data, apapun caranya | Selamatkan bukti **tanpa mengubah**, chain of custody utuh |
| **Hash integrity** | Tidak wajib penting | Wajib SHA-256 verified sebelum & sesudah |
| **Original drive** | Boleh ditulis-dulu | Tidak boleh disentuh — clone dulu, kerja di clone |
| **Tools** | Recuva → PC-3000 | ddrescue → EnCase / Autopsy → FTK |
| **Reporting** | Internal client | Chain of custody court-admissible |
| **Use case** | Hard drive pribadi | Kasus hukum, e-discovery, IR |

Hirarki untuk forensik di [[data-recovery|sheet forensics]] punya aturan lebih ketat tentang **non-modifikasi original evidence**. Hirarki di sini fokus ke recovery — tapi recovery center profesional biasanya bisa handle kedua mode.

### 4. Backup Mengubah Hierarki Seluruhnya

Kalau lo punya backup 3-2-1 rule (3 copies, 2 different media, 1 offsite) — Level 0–5 jadi **tidak relevan** untuk skenario disaster recovery. Lo cuma restore dari backup. Hirarki recovery baru relevan kalau:
- Backup corruption / incomplete
- Backup hilang
- Pre-incident state yang tidak pernah dibackup
- Forensik pasca-insiden saat backup sudah compromised

Hirarki data recovery = contingency untuk **ketika backup gagal**. Bukan replacement untuk backup strategy.

### 5. Ransomware Mengubah Prioritas Level

Setelah ransomware, hirarki recovery bergeser: backup adalah Level 0 (kembalikan tanpa bayar). Decryption tool adalah Level 1 (kalau ransomware punya flaw). Negeri ransomware terbaru sering **destroy backup** sebelum enkripsi — Sophos melaporkan 2024: 94% attack mencoba sabotase backup. Maka hirarki recovery ransomware bergeser ke **cold snapshot / immutable backup** — bukan hanya fast restore.

---

## Plot Twists

> [!danger] Plot Twist 1: Recovery Adalah Proses Destruktif
> Setiap kali lo menjalankan perintah seperti `ddrescue`, ATA Secure Erase, atau bahkan magnetic force microscopy — **lo menghancurkan medium itu** dalam proses. PC-3000 sering disable head rusak untuk melindungi platter, tapi platter tetap ter-putar di bawah head yang berbeda → **platter degradasi**. MFM di Level 6 secara harfiah mengiris atom silikon chip NAND untuk baca data sekali. Setelahnya chip itu jadi debu. **Recovery adalah one-way irreversible**. Inilah kenapa bekerja di **image clone** (`.dd` dari `ddrescue`) bukan original adalah best practice universal — kalau gagal, lo bisa coba lagi.

> [!danger] Plot Twist 2: SMART Data Tidak Pernah "Real"
> S.M.A.R.T. (Self-Monitoring, Analysis, and Reporting Technology) memberikan metrik seperti Reallocated Sector Count, Pending Sector, Uncorrectable Error. Tapi SMART adalah **self-report dari firmware drive** — drive bisa berbohong.SMART * Health pernah laporkan "OK" tapi head-nya aus parah. Vendor sengaja tweak threshold untuk **mengurangi false-positive warranty claim**. Maka SMART adalah **starting point triage** — bukan diagnosa final. Untuk data penting, gabungkan SMART + Victoria surface scan + TestDisk sebelum menyatakan "drive sehat."

> [!danger] Plot Twist 3: Overwriting Data Tidak 100% Aman (dan Tidak 100% Tidak Aman Juga)
> Mitos lama: "satu kali overwrite sudah cukup untuk hapus data." Mitos lama yang kedua: "NSA bisa membaca data setelah 7-pass overwrite." Kedua-duanya keliru konteks. Untuk HDD modern dengan areal density tinggi, bahkan satu pass overwrite membuat data **praktis tidak recoverable oleh software** — tapi dengan MFM di Level 6, **residual magnetic flux** di track yang berdekatan masih bisa dideteksi dengan effort tinggi. Untuk SSD, TRIM + garbage collection membuat recover **mustahil** setelah power-off singkat. Untuk NAND flash, wear-leveling berarti data tersebar di banyak chip. **Hirarki overwrite aman** = threat-model based, bukan kepercayaan buta seragam.

> [!tip] Plot Twist 4: Enkripsi = Teman Data Recovery (Kalau Kunci Aman)
> Buat banyak orang, enkripsi (BitLocker, FileVault, VeraCrypt) terasa menakutkan karena "kalau kunci hilang, data hilang." Tapi true cerita: enkripsi + kunci aman = **recovery jadi Level 0 untuk attacker** — dia cuma hadap ciphertext random. Tidak ada gunanya PC-3000 kalau BitLocker AES-256 aktif dengan TPM. Maka enkripsi bukan musuh data recovery — musuh data recovery adalah backup yang hilang ATAU enkripsi + kunci hilang. Dua-duanya procedure failure, bukan tools failure.

> [!info] Plot Twist 5: Cold Storage & Tape Adalah Teman Lama
> Sebelum cloud backup populer, **LTO tape** adalah standar enterprise backup. Tape tidak punya masalah platter rotational, tidak butuh listrik untuk maintain data, **murah per TB**, dan **immutable by design** (kalau gak ditulis ulang). Untuk data archival jangka panjang (10+ tahun), tape masih menang atas HDD spinning rust. Hirarki data recovery modern mengakui: kalau data lu critical long-term, **LTO tape offline** adalah Level -1 (di bawah Level 0 paling murah). Backup tape tidak butuh recovery hierarchy sama sekali — cuma butuh drive tape yang hidup.

---

## Decision Tree — Drive Masuk Drive Keluar

```
DRIVE MASUK
     │
     ▼
[Level 0] Cek fisik — BIOS baca normal? Suara wajar? LED spinner hidup?
     │ YA                    │ TIDAK → [Level 5+] Firmware/PCB repair
     ▼
[Level 2] Cek SMART — Health? Reallocated Sector?
     │ Sehat? ◄───── TIDAK ────── [Level 3/4] Bare-metal clone
     │ YA                              (HDDSuperClone/MHDD)
     ▼                                 │
[Level 1] Software recovery            │ Ada firmware corruption?
     │ (Recuva/TestDisk)              │ YA → [Level 5] PC-3000
     │ Berkhasil? ◄───── TIDAK ─────┘
     ▼
[Level 4] Image clone forensic-grade
(ddrescue / HDDSuperClone → .dd)
     │
     ▼
Analisis pakai Autopsy / R-Studio / FTK
     │
     ├─── Ditemukan — return data ke client
     │
     ├─── Enkripsi + kunci aman ── return data via decrypt
     │
     ├─── Enkripsi + kunci HILANG ── stop di sini
     │
     └─── Fisik hancur / platter ── [Level 5/6] Hardware tier
                                      atau [Level 7] Quantum
                                      (kasus nation-state)
```

Pohon keputusan ini yang membedakan **teknisi data recovery profesional** dari "tukang servis install ulang Windows." Masing-masing level punya exit criteria jelas.

---

## Perbandingan Pendekatan Recovery oleh Profil

| Profil | Tools Yang Realistically Dipakai | Capability Ceiling |
|---|---|---|
| **Personal / Rumahan** | Level 0–1 (BIOS + Recuva gratis) | Bisa recover file terhapus Recycle Bin |
| **Teknisi Servis / Tukang PC** | + Level 2 (Hiren's + Victoria) | Triage barang lelang, servis ringan |
| **Repair Workshop** | + Level 3 (FreeDOS + MHDD) | Handle HDD lawas membandel |
| **Recovery Center Profesional** | + Level 4 (Linux ddrescue) + Level 5 (PC-3000 + DeepSpar) | 90% kasus solvable, forensik chain of custody |
| **Forensik Hukum / Corporate** | + Level 5 + image-cli workflow + hashing SHA-256 + reporting court-admissible | Kasus hukum, e-discovery, IR investigation |
| **Government / Intelijen** | + Level 6 (FIB, MFM) + Level 7 (quantum decryption capability) | Kaspersky, Vault 7, Vault 8 leaks menunjukkan capability ini dipakai untuk ekstraksi data dari device target intelligence |

Profil umumnya berhenti di **Level 5**. Level 6–7 digunakan oleh badan intelijen dan entitas riset canggih.

---

## Sumber & Telusur Lebih Lanjut

- **Recovery Tools & Tabel Lengkap** → [[data-recovery]] (PC-3000 vs Dolphin Pro vs Atola vs HDDSuperClone)
- **PC-3000 Hardware God-Mode** → [[data-recovery]] Sheet Hardware
- **Forensik Imaging Workflow** → [[forensic-imaging-analysis]] (SOP chain of custody)
- **Backup Strategy 3-2-1** → [[storage-refurbishing]] (backup lifecycle)
- **Endpoint Forensik (RAM dump, persistence)** → [[endpoint-detection-playbook]]
- **Master Index** → [[master-index]]

---

> Hirarki data recovery bukan cuma urutan eskalasi — itu cara berpikir yang mengendalikan **ekspektasi**. Mulai murah, eskalasi hanya kalau perlu, dan jujur tentang kapan harus berhenti. Kasus recovery yang sukses adalah tentang **menemukan level minimum yang solvable**, bukan selalu mencapai Level 5 atau 7.

*Data Recovery Hierarchy | Level 0 (Sensorik) → Level 7 (Quantum Decryption) · Geometri Biaya Eksponensial*

audited
---
