---
tags:
  - victoria
  - hdd
  - ssd
  - data-recovery
  - hardware-forensics
  - dual-use
aliases:
  - Victoria HDD/SSD
  - Victoria for Windows
  - Victoria Diagnostic Tool
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!warning] Konteks Etis & Legal  
> Victoria adalah alat diagnostik dan pemulihan hard drive/SSD yang sah, banyak digunakan oleh teknisi, laboratorium forensik, dan spesialis data recovery. Seluruh informasi berasal dari dokumentasi publik, forum teknis, dan pengalaman profesional. Pembahasan ini murni edukasional dan defensif. Penggunaan untuk merusak atau memanipulasi data tanpa otorisasi adalah ilegal. Tujuannya agar defender, investigator, dan teknisi memahami kemampuan dan batasan alat ini.

## 🧬 Apa Itu Victoria HDD?

Victoria (sering disebut **Victoria for Windows** atau **Victoria HDD/SSD**) adalah **software diagnostik dan pemulihan drive tingkat rendah** untuk hard disk drive (HDD) dan solid-state drive (SSD) yang berjalan di sistem operasi Windows. Dikembangkan oleh programmer Belarusia **Sergey Kazansky** sejak awal 2000-an, Victoria telah menjadi alat standar di kalangan teknisi perbaikan komputer, laboratorium forensik digital, dan perusahaan data recovery di seluruh dunia.

Tidak seperti alat diagnostik pabrikan (SeaTools, WD Dashboard) yang hanya memberikan informasi SMART dan tes permukaan terbatas, Victoria memberikan **kontrol langsung ke controller drive** melalui port ATA/SATA/NVMe, memungkinkan operasi yang biasanya hanya bisa dilakukan oleh pabrikan:

- Membaca dan menulis sektor individual.
- Mengukur waktu akses setiap sektor (surface scan dengan grafik).
- Remapping sektor buruk (bad sector).
- Menghapus data secara aman (secure erase / sanitize).
- Mengakses dan memodifikasi firmware drive (HPA, DCO, password ATA).
- Membaca dan menghapus Host Protected Area (HPA) dan Device Configuration Overlay (DCO).
- Menangani drive dengan firmware rusak (melalui port COM/terminal untuk HDD tertentu).

### Perbandingan dengan Alat Diagnostik Lain

| Fitur                            | Victoria                    | MHDD (DOS)    | HDAT2 (DOS)   | SeaTools (Seagate)   | WD Dashboard  |
| -------------------------------- | --------------------------- | ------------- | ------------- | -------------------- | ------------- |
| **Surface scan + timing**        | ✅ Sangat detail            | ✅            | ✅            | ❌ (hanya pass/fail) | ❌            |
| **Akses PIO/UDMA langsung**      | ✅                          | ✅            | ✅            | ❌                   | ❌            |
| **Remap bad sector**             | ✅                          | ✅            | ✅            | ✅ (terbatas)        | ✅ (terbatas) |
| **HPA/DCO detection & removal**  | ✅                          | ✅            | ✅            | ❌                   | ❌            |
| **SSD support**                  | ✅ (NVMe/ATA)               | ❌ (HDD only) | ❌ (HDD only) | ✅                   | ✅            |
| **Windows GUI**                  | ✅                          | ❌ (DOS)      | ❌ (DOS)      | ✅                   | ✅            |
| **Secure Erase**                 | ✅                          | ✅            | ✅            | ✅                   | ✅            |
| **Firmware terminal access**     | ✅ (via COM port emulation) | ❌            | ❌            | ❌                   | ❌            |
| **GRD (Graphic Result Display)** | ✅ Visual                   | ❌            | ❌            | ❌                   | ❌            |

---

## 🏗️ Arsitektur & Cara Kerja Victoria

Victoria beroperasi pada level **hardware register** drive, melewati Windows storage stack untuk mendapatkan akses langsung ke controller. Cara kerjanya:

### Mode Akses Drive

| Mode                           | Deskripsi                                                                                                | Kelebihan                                                                                      | Kekurangan                                                   |
| ------------------------------ | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| **PIO (Programmed I/O)**       | Akses sektor melalui port I/O ATA/SATA menggunakan instruksi CPU. Paling primitif dan paling kompatibel. | Bekerja pada drive yang tidak terdeteksi oleh BIOS/OS. Bisa akses drive dengan firmware rusak. | Sangat lambat (2-10 MB/s). Membutuhkan driver kernel khusus. |
| **UDMA (Ultra DMA)**           | Akses sektor via bus mastering DMA controller. Lebih cepat.                                              | Kecepatan bagus (50-133 MB/s).                                                                 | Tidak bisa untuk drive rusak parah.                          |
| **Pass-through (API Windows)** | Menggunakan Windows storage API (`CreateFile`/`DeviceIoControl`). Mode default.                          | Aman, tidak perlu driver khusus.                                                               | Tidak bisa untuk operasi tingkat rendah (firmware commands). |

Untuk operasi forensik seperti deteksi HPA/DCO atau firmware terminal, Victoria menggunakan **driver kernel kustom** (`victoria.sys`) yang memberikan akses register ATA langsung.

### Surface Scan: Deteksi Fisik Sektor

Fitur paling terkenal dari Victoria adalah **surface scan** dengan pengukuran waktu akses setiap sektor. Cara kerjanya:

1. Victoria mengirim perintah **READ SECTOR(S) EXT** ke setiap LBA (Logical Block Address) secara berurutan.
2. Mengukur waktu yang dibutuhkan untuk mendapatkan respons dari drive (dalam mikrodetik atau milidetik).
3. Mewarnai setiap LBA berdasarkan kecepatan respons:
   - **Abu-abu/putih** (<10 ms): Sektor sehat.
   - **Hijau** (10-50 ms): Penurunan ringan.
   - **Oranye** (50-200 ms): Mulai bermasalah.
   - **Merah** (200-1000 ms): Sektor buruk (bad sector) yang masih bisa dibaca.
   - **Biru/hitam** (>1000 ms atau timeout): Sektor tidak bisa dibaca (UNC error).

4. Hasil scan divisualisasikan dalam grid grafis (GRD) yang menunjukkan distribusi fisik bad sector pada permukaan platter (HDD) atau chip NAND (SSD).

**Mengapa ini penting untuk forensik?**

- Sebelum imaging drive untuk bukti, investigator harus tahu kondisi fisiknya.
- Jika banyak bad sector, imaging mungkin memerlukan hardware imager khusus (seperti PC-3000) atau skip sector.

### Remap: Mengganti Sektor Buruk

Jika bad sector ditemukan, Victoria dapat melakukan **remap**:

1. Mengirim perintah **REASSIGN BLOCKS** ke firmware HDD.
2. Firmware menambahkan LBA yang buruk ke **defect list** (G-list).
3. LBA tersebut dipetakan ke sektor cadangan di area khusus (spare sectors).
4. Data di sektor asli mungkin hilang (jika tidak bisa dibaca), tetapi drive menjadi "sehat" kembali.

Remap hanya berfungsi jika HDD masih memiliki spare sectors. Jika defect list penuh, drive tidak bisa diremap.

### HPA & DCO: Area Tersembunyi pada Drive

**HPA (Host Protected Area)** adalah fitur ATA yang memungkinkan firmware drive melaporkan kapasitas lebih kecil ke OS. Area di luar HPA tidak terlihat oleh sistem operasi tetapi dapat berisi data. Sering digunakan oleh:

- Pabrikan untuk menyimpan tools diagnostik.
- Penjahat untuk menyembunyikan data (steganografi forensik).
- Beberapa BIOS OEM untuk recovery partition.

**DCO (Device Configuration Overlay)** mirip dengan HPA tetapi lebih dalam: membatasi kapabilitas drive (kecepatan transfer, jumlah sector, dll.) dan menyembunyikan area dari OS.

Victoria dapat:

- **Mendeteksi** HPA/DCO dengan membandingkan kapasitas asli vs yang dilaporkan.
- **Menghapus sementara** (HPA UNLOCK) untuk mengakses area tersembunyi.
- **Menghapus permanen** (HPA REMOVE) untuk mengembalikan kapasitas penuh.

Untuk forensik, deteksi HPA/DCO adalah langkah kritis sebelum imaging. Jika drive memiliki HPA, investigator harus mengaksesnya untuk memastikan tidak ada data tersembunyi.

---

## ☠️ Victoria dalam Konteks Military & Intelligence

### Forensik Pra-Imaging (Pre-Forensic Verification)

Sebelum investigator forensik melakukan imaging drive bukti, mereka HARUS memverifikasi integritas media. Victoria digunakan untuk:

1. **Surface scan penuh**: Mengetahui lokasi bad sector. Ini menentukan apakah imaging bisa dilakukan dengan software biasa atau membutuhkan PC-3000 / DeepSpar Disk Imager.
2. **HPA/DCO detection**: Memastikan tidak ada area tersembunyi yang akan terlewatkan oleh imaging.
3. **SMART analysis**: Melihat kesehatan drive, jumlah bad sector yang sudah diremap, jam operasional, dll.
4. **Secure erase detection**: Memastikan tidak ada upaya penghapusan bukti (dari SMART attributes seperti "Erase Count", "Total LBA Written").

### Operasi Klandestin & Anti-Forensik

Di sisi ofensif, Victoria dapat digunakan untuk:

- **Menyembunyikan data di HPA**: Agen intelijen atau penjahat dapat membuat HPA, menyimpan data di dalamnya, lalu menguncinya. Pemeriksa forensik yang tidak memeriksa HPA akan melewatkan data ini.
- **Secure Erase**: Menghapus seluruh drive secara permanen (termasuk bad sector) dengan perintah ATA SECURITY ERASE UNIT.
- **Merusak drive secara selektif**: Dengan menulis berulang-ulang ke sektor tertentu hingga rusak (forced bad sector), drive bisa dirusak sehingga sulit dibaca tetapi masih terlihat berfungsi.

---

## 🔬 Teknik Forensik dengan Victoria

### Mendeteksi HPA

1. Jalankan Victoria, pilih drive target.
2. Buka tab **Standard** dan catat **Total LBA**.
3. Buka tab **SMART** dan cari atribut **Max LBA** (atau "Native Max LBA").
4. Bandingkan Total LBA dengan Max LBA. Jika Max LBA > Total LBA, ada HPA.
5. Gunakan perintah **HPA > Show Native** untuk melihat ukuran asli.
6. Untuk mengakses area tersembunyi: gunakan **HPA > Unlock** atau **HPA > Remove**.

### Verifikasi Sebelum Imaging

1. Jalankan **surface scan** dengan mode READ (bukan write!).
2. Perhatikan peta GRD. Jika ada area merah/hitam besar, imaging mungkin gagal di area tersebut.
3. Catat LBA yang bermasalah untuk referensi saat imaging.
4. Jika bad sector terlalu banyak, pertimbangkan hardware imager (PC-3000, DeepSpar).

### Menemukan Upaya Anti-Forensik

- **SMART attribute "Erase Count"**: Jika tinggi, mungkin secure erase dilakukan.
- **SMART attribute "Power-On Hours" vs "Total LBA Written"**: Jika jam operasional rendah tapi TBW (Total Bytes Written) sangat tinggi, mungkin ada operasi penulisan intensif (penghancuran bukti).
- **SMART attribute "Reallocated Sectors" melonjak tiba-tiba**: Bisa menandakan forced bad sector.
- **HPA/DCO presence**: Selalu curigai HPA pada drive bukti, terutama jika drive pernah dimiliki oleh tersangka yang melek teknologi.

---

## ↔️ Dual-Use Spectrum

text

DEFENSE ◄──────────────────────────────────────────► OFFENSE
Teknisi Perbaikan Forensik Digital Anti-Forensik
│ │ │
Memperbaiki drive Memverifikasi Menyembunyikan
pelanggan dengan integritas bukti data di HPA/DCO
remap bad sector sebelum imaging │
│ │ │
│ │ ▼
▼ ▼ Penghancuran
Data recovery Penegakan hukum: bukti dengan
komersial mengakses data secure erase
tersembunyi dan forced
bad sector

---

## 🔗 Koneksi dalam Vault

- [[pc-3000]] — Victoria adalah alat software; PC-3000 adalah hardware+software yang lebih canggih untuk akses firmware drive. Keduanya saling melengkapi.
- [[cellebrite-ufed]] — UFED untuk mobile, Victoria untuk HDD/SSD. Di laboratorium forensik, keduanya digunakan paralel (mobile + storage).
- [[graykey]] — GrayKey membuka passcode iPhone; Victoria memeriksa kesehatan HDD sebelum imaging. Satu rantai forensik.
- [[shodan]] — Tidak langsung, tetapi drive yang terhubung ke server cloud bisa berisi data dari perangkat yang ditemukan di Shodan.

---

## 📚 Referensi

- Kazansky, S. *Victoria for Windows Documentation* (2005-2024)
- NIST SP 800-86: *Guide to Integrating Forensic Techniques into Incident Response* (2006)
- SWGDE: *Best Practices for Computer Forensics: Hard Drive Imaging*
- Carrier, B. (2005). *File System Forensic Analysis*. Addison-Wesley.
- ATA/ATAPI Command Set - 4 (ACS-4), T13 Technical Committee

---

_Victoria HDD Deep Dive | Hard Drive Diagnostic & Forensic Verification | Dual-Use Storage Tool_
