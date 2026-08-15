---
title: Printer Maintenance Reset
tags:
- sops
created: '2026-05-11'
updated: '2026-07-01'
status: pending
source: ''
cssclasses:
  - wide-table
  - callout

---
# Printer Maintenance & Reset — Complete Technician Guide

> **Ringkasan:** Panduan komprehensif perawatan dan reset printer inkjet (Epson, Canon, Brother, HP) untuk teknisi servis. Mencakup identifikasi masalah, prosedur reset waste ink counter, service mode, dan mitigasi risiko kerusakan.
> **Scope:** Teknisi printer, penjual elektronik bekas, dan pengguna advanced yang melakukan self-service.
> **Level:** Ring 3 (User Space Hardware) — tidak memerlukan akses kernel/OS.

---

## Daftar Isi

- [[#1. Konteks & Safety First]]
- [[#2. Klasifikasi Printer & Identifikasi Cepat]]
- [[#3. Reset Waste Ink Counter — Epson L-Series]]
- [[#4. Service Mode & Reset — Canon]]
- [[#5. Reset Fisik & Alternatif Brand Lain]]
- [[#6. Workflow Servis Standar]]
- [[#7. Tools & Software Arsenal]]
- [[#8. Mitigasi Risiko & Peringatan Kritis]]
- [[#9. Gallery & Visual Reference]]

---

## 1. Konteks & Safety First

### Mengapa Reset Diperlukan?

Printer inkjet menyimpan "sisa tinta" dari proses cleaning head ke dalam **Waste Ink Pad** (busa penampung) di bagian bawah printer. Setelah batas tertentu, printer akan **menolak mencetak** dan menampilkan indikator lampu berkedip bergantian (orange/hijau).

> [!warning]
> **Fakta Kritis:** Reset software **HANYA** mengembalikan counter digital ke 0%. Busa fisik tetap penuh. Jika tidak dicuci/diganti, tinta akan meluber dan bisa memicu **korsleting** pada mesin.

### Safety Checklist Sebelum Servis

| ⚡ Langkah | 🎯 Tujuan | ☠️ Risiko Jika Dilewati |
|---|---|---|
| Cabut kabel power | Prevent shock & short | Tersetrum atau motherboard rusak |
| Siapkan tissue & wadah | Tampung tumpahan tinta | Noda permanen pada meja/lantai |
| Gunakan sarung tangan | Lindungi kulit dari tinta | Tinta sulit dibersihkan, iritasi kulit |
| Foto kondisi awal | Dokumentasi untuk klaim | Disalahkan atas kerusakan pre-existing |

---

## 2. Klasifikasi Printer & Identifikasi Cepat

### 2.1 Epson L-Series (Generasi & Rumpun Mesin)

| 🔐 Generasi | ⚡ Model Contoh | ☠️ Resetter Kompatible | 🎯 Ciri Fisik |
|---|---|---|---|
| **Gen Awal** (Tangki Eksternal) | L100, L110, L120, L200, L210, L220, L300, L310, L350, L360, L365, L380, L385 | AdjProg L110-L210-L300-L350-L355 / L120 standalone / L310-L220-L360-L365 | Tangki tinta terpisah di samping, selang terlihat |
| **Gen Transisi** (Tangki Depan) | L1110, L3110, L3150, L4150, L4160, L5190 | AdjProg L3110 (sering kompatibel L1110, L3150) | Tangki terintegrasi di depan bodi, anti-tumpah |
| **Gen EcoTank Terbaru** | L1210, L1250, L3210, L3250, L4260, L5290 | AdjProg L3210 (kompatibel L1210, L3250, L5290) | Desain sama dengan Gen Transisi, firmware baru, perlindungan panas head |
| **Seri Foto (6 Warna)** | L800, L805, L850 | AdjProg khusus seri foto | 6 tabung tinta (CMYK + Light Cyan + Light Magenta) |
| **Format A3** | L1300 (4 warna), L1800 (6 warna), L8180 | AdjProg khusus A3 | Bodi lebih lebar, support kertas A3 |

> [!tip]
> **Identifikasi Cepat:** Lihat model di stiker bawah printer. L3110 = paling populer & sering masuk servis. L3210 = generasi pengganti, hati-hati firmware update bisa memblokir resetter lama.

### 2.2 Canon (Seri & Karakteristik)

| 🔐 Seri | ⚡ Model Contoh | ☠️ Mekanisme Reset | 🎯 Ciri Khas |
|---|---|---|---|
| **Single Function (iP)** | iP2770, iP2870, iP7270, iP8770 | Service Tool V3400 + ritual tombol | Hanya print, sering dimodifikasi infus manual |
| **Multifungsi (MP/MG/E)** | MP237, MP287, MG2570, MG2570S, E410, E400, E510 | Service Tool V3400/V4720 + ritual tombol | Cartridge kecil, tinta di dalam head |
| **MegaTank Gen 1 (G)** | G1000, G2000, G3000, G4000 | Service Tool V4720/V4905 + ritual tombol | Tangki tinta pabrikan, saingan Epson L |
| **MegaTank Gen 2** | G1010, G2010, G3010 | Service Tool V4905/V5103 + ritual tombol | Ada layar, perbaikan sistem |
| **MegaTank Gen 3** | G1020, G2020, G3020, G3060 | **Maintenance Cartridge MC-G02** (fisik!) | Tidak perlu software, tinggal ganti kotak |

### 2.3 Kompetitor Utama

| 🔐 Brand | ⚡ Kelebihan | ☠️ Kelemahan | 🎯 Model Populer |
|---|---|---|---|
| **Brother** | Bandel untuk teks massal, self-cleaning otomatis | Warna matte/dull, kurang tajam untuk foto | DCP-T310, T420W, T520W, T720DW |
| **HP** | Build solid, HP Smart App paling mulus | Cartridge mahal (seri Ink Advantage), tank series masih baru | Smart Tank 515, 580, 750 |

---

## 3. Reset Waste Ink Counter — Epson L-Series

### 3.1 Diagnosis Awal

**Tanda-tanda Waste Ink Penuh:**
- Lampu tinta & kertas berkedip **bergantian** (orange ↔ hijau)
- Printer menolak mencetak meski tinta masih penuh
- Pesan di PC: "Service Required" atau "Parts inside printer have reached end of service life"

> *Gambar 1: Contoh indikator lampu berkedip pada Epson L3110 (kiri: normal, kanan: error waste ink)*

### 3.2 Opsi Reset

#### Opsi A: Adjustment Program (AdjProg) — Spesifik Per Rumpun

| 🔐 Versi AdjProg | ⚡ Model Cover | ☠️ Risiko | 🎯 Kapan Dipakai |
|---|---|---|---|
| AdjProg L110-L210-L300-L350-L355 | L100, L110, L120, L130, L200, L210, L220, L300, L310, L350, L355 | Salah pilih port = brick EEPROM | Gen awal & klasik |
| AdjProg L120 | L120 standalone | Sama seperti di atas | L120 only |
| AdjProg L310-L220-L360-L365 | L310, L220, L360, L365 | Sama seperti di atas | Gen transisi awal |
| AdjProg L3110 | L3110, L1110, L3150 | Firmware V20 (Chrome v127+) bisa memblokir | Gen transisi paling populer |
| AdjProg L3210 | L3210, L1210, L3250, L5290 | Sama, perhatikan firmware version | Gen EcoTank terbaru |

> [!caution]
> **Peringatan Keamanan Software:** AdjProg yang beredar gratis di internet (Nesabamedia, Kuyhaa, iLoadZone) sering disusupi **Trojan/Ransomware**. Jalankan SELALU di **Virtual Machine** atau sandbox. Jangan pernah disable antivirus di host utama.

#### Opsi B: WIC Reset Utility — Universal & Lebih Aman

| 🔐 Aspek | ⚡ Detail |
|---|---|
| **Cakupan** | Hampir semua Epson L100 — L8180 dalam satu software |
| **Keuntungan** | Bersih dari virus, cek status waste ink gratis, UI jelas |
| **Kekurangan** | Reset ke 0% memerlukan **Reset Key berbayar** (kode aktivasi) |
| **Cara Kerja** | 1. Download WIC dari vendor resmi → 2. Cek status (gratis) → 3. Beli key → 4. Execute reset |

### 3.3 Guide Step-by-Step: AdjProg (Untuk Teknisi)

> [!info]
> Dokumen ini asumsikan teknisi sudah memiliki file AdjProg yang **diverifikasi bersih** (via sandbox/VM).

#### Step 1: Persiapan

1. **Matikan printer** (tekan tombol power, cabut kabel power dari stopkontak)
2. **Cabut kabel USB** dari PC
3. **Siapkan AdjProg** yang sesuai model printer

#### Step 2: Entry Service Mode

1. **Tahan tombol STOP/MAINTENANCE** (tombol segitiga) pada printer
2. **Sambil menahan, tekan dan tahan tombol POWER**
3. **Tunggu 3 detik**, lepas tombol STOP sambil POWER tetap ditekan
4. **Tekan STOP sebanyak 5 kali** (untuk sebagian besar model)
5. **Lepas tombol POWER**
6. Printer akan masuk mode siaga (lampu diam, tidak kedap-kedip)

!*(gambar epson)*
> *Gambar 2: Posisi tombol STOP dan POWER pada Epson L3110*

#### Step 3: Eksekusi AdjProg

1. **Sambungkan kabel USB** ke PC
2. **Jalankan AdjProg.exe** (di dalam VM/sandbox)
3. **Pilih model printer** dari dropdown (PASTIKAN BENAR!)
4. **Pilih port** (biasanya USB001 atau auto-detect)
5. Klik tab **"Waste Ink Pad Counter"**
6. Klik **"Check"** untuk melihat persentase saat ini
7. Centang kotak **"Main Pad Counter"** dan **"Platen Pad Counter"**
8. Klik **"Initialization"** atau **"Reset"**
9. Tunggu proses selesai (indikator progress bar)
10. **Matikan printer** menggunakan tombol power
11. **Tunggu 10 detik**, lalu nyalakan kembali

#### Step 4: Verifikasi

1. Lampu error harus **mati total**
2. Printer siap menerima perintah cetak
3. Coba print test page dari PC

```text
[FLOWCHART: AdjProg Reset]
			   │
			   ▼
┌─────────────────────────────┐
│ 1. Printer OFF, Cabut USB   │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 2. Entry Service Mode       │
│  (STOP 5x + POWER ritual)   │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 3. Sambung USB, Jalankan    │
│    AdjProg di VM            │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 4. Pilih Model & Port       │
│    ⚠️ SALAH = BRICK!        │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 5. Check → Centang Counter  │
│    → Initialization         │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 6. Power OFF → 10s → ON     │
│    → Test Print             │
└─────────────────────────────┘
```

### 3.4 Guide Step-by-Step: WIC Reset Utility

1. **Download WIC** dari website resmi (wic-reset.com)
2. **Install & jalankan** (versi trial bisa cek status)
3. **Sambungkan printer** via USB
4. Klik **"Read Waste Counters"** — akan muncul persentase
5. Jika ≥ 100%, klik **"Reset Waste Counters"**
6. **Masukkan Reset Key** (beli dari website, biasanya ~$10-15)
7. Proses reset otomatis, printer akan restart

---

## 4. Service Mode & Reset — Canon

### 4.1 Perbedaan Fundamental dengan Epson

| 🔐 Aspek | ⚡ Epson | ⚡ Canon |
|---|---|---|
| **Entry Mode** | Tombol ritual (STOP + POWER) | Tombol ritual (Resume + POWER) |
| **Software** | AdjProg | Service Tool (V3400, V4720, V4905, V5103, V5302) |
| **Reset Fisik** | Tidak ada (kecuali ganti busa) | Ada! Maintenance Cartridge MC-G02 (Gen 3) |
| **Risiko Brick** | Salah port/model = EEPROM rusak | Salah mode = EEPROM lock permanen |

### 4.2 Ritual Service Mode Canon

> [!warning]
> **Sangat Penting:** Jumlah tekanan tombol STOP/Resume **HARUS TEPAT**. Salah hitung = masuk mode salah = EEPROM lock.

#### Prosedur Umum (iP2770, MP287, G1000-G3010):

1. **Printer OFF, kabel power tetap tersambung**
2. **Tahan tombol Resume/Stop** (logo segitiga)
3. **Sambil menahan Resume, tekan dan tahan POWER**
4. **Lepas Resume** (POWER tetap ditekan)
5. **Tekan Resume sebanyak 5 kali** (untuk G-series terbaru bisa 5-6 kali)
6. **Lepas kedua tombol bersamaan**
7. **Indikator sukses:** Lampu hijau **DIAM** (tidak kedap-kedip) + PC mendeteksi "Found New Hardware"

!*(gambar service-mode)*
> *Gambar 3: Urutan tekan tombol Canon untuk masuk Service Mode*

#### Catatan Kejujuran:

| ☠️ Kesalahan | ⚡ Konsekuensi |
|---|---|
| Tekan 4x atau 2x | Masuk mode salah |
| Reset dalam mode salah | **EEPROM LOCK** — tidak bisa direset lagi |
| Lock EEPROM | Harus ganti IC fisik atau ganti motherboard |

### 4.3 Eksekusi Service Tool

1. **Pastikan printer dalam Service Mode** (lampu hijau diam)
2. **Jalankan Service Tool** yang sesuai generasi:
   - **V3400**: iP2770, MP287 (generasi lama)
   - **V4720 / V4905**: G1010, G2010, G3010 (generasi 2)
   - **V5103 / V5302**: Generasi terbaru
3. **Pilih tab "Main"** atau "Absorber Clear"
4. Klik **"Set"** atau **"Clear"** pada bagian Waste Ink Counter
5. **Tunggu konfirmasi** "OK"
6. **Matikan printer**, tunggu 10 detik, nyalakan kembali

### 4.4 Canon Gen 3 — Maintenance Cartridge (Solusi Fisik)

Pada seri **G1020, G2020, G3020, G3060**, Canon menggunakan **MC-G02 Maintenance Cartridge**:

| 🔐 Aspek | ⚡ Detail |
|---|---|
| **Harga** | ~Rp 150.000 — 200.000 |
| **Cara** | Cabut cartridge lama → Pasang cartridge baru → Printer auto reset |
| **Keuntungan** | Tidak perlu software, tidak perlu ritual tombol, tidak ada risiko brick |
| **Ketersediaan** | Tersedia di marketplace & toko sparepart resmi |

!*(gambar cartridge)*
> *Gambar 4: Maintenance Cartridge MC-G02 Canon (kiri: penuh, kanan: baru)*

---

## 5. Reset Fisik & Alternatif Brand Lain

### 5.1 Brother DCP-T Series

| 🔐 Aspek | ⚡ Detail |
|---|---|
| **Mekanisme** | Tidak ada software resetter publik |
| **Solusi** | Ganti **Ink Absorber Kit** (sparepart resmi) |
| **Ciri** | Tampilan error "Unable to Print 50" atau "Ink Absorber Full" |
| **Prosedur** | Bongkar casing bawah → Ganti busa absorber → Reset counter via hidden menu (kombinasi tombol spesifik per model) |

> [!tip]
> **Brother Secret Menu:** Tekan Menu → Mono Start → Mono Start → Up Arrow → 8 → 0. Ini menu maintenance tersembunyi. Gunakan dengan hati-hati.

### 5.2 HP Smart Tank Series

| 🔐 Aspek | ⚡ Detail |
|---|---|
| **Mekanisme** | HP menggunakan **Printhead Cleaning Kit** dan firmware-based counter |
| **Solusi** | HP Smart App → Printer Maintenance → Clean Printhead / Align Printhead |
| **Reset Counter** | Tidak tersedia untuk publik, harus ke service center resmi |
| **Alternatif** | Beberapa model support reset via **HP Service Tool** (internal, bocor di forum teknisi) |

### 5.3 Xprinter Thermal (Bonus)

| 🔐 Aspek | ⚡ Detail |
|---|---|
| **Mekanisme** | Tombol reset fisik tersembunyi |
| **Prosedur** | Tekan dan tahan tombol FEED sambil nyalakan printer → Lepas setelah 7 kedipan |
| **Ciri** | Printer thermal POS/kasir, sering error "Cutter Jam" atau "Paper End" |

---

## 6. Workflow Servis Standar

### 6.1 Alur Kerja Teknisi (Dari Konsumen Masuk)

```text
[KONSUMEN DATANG]
              │
			  ▼
┌─────────────────────────────┐
│ 1. ANAMNESA (Wawancara)     │
│    - Jenis printer?         │
│    - Gejala? (lampu/error)  │
│    - Sejak kapan?           │
│    - Pernah diservis?       │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 2. DIAGNOSIS FISIK          │
│    - Cek lampu indikator    │
│    - Cek kertas macet       │
│    - Cek level tinta visual │
│    - Cek bocor/tumpah       │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 3. DIAGNOSIS DIGITAL        │
│    - Sambung ke PC          │
│    - Cek status driver      │
│    - Print test page        │
│    - Cek error code         │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 4. IDENTIFIKASI MASALAH     │
│    ├─ Waste Ink Full?       │
│    ├─ Head Clogged?         │
│    ├─ Mechanical Jam?       │
│    └─ Board/EEPROM?         │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 5. EKSEKUSI PERBAIKAN       │
│    ├─ Reset Counter         │
│    ├─ Cleaning Head         │
│    ├─ Ganti Absorber        │
│    └─ Flash EEPROM (last)   │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 6. VERIFIKASI & TESTING     │
│    - Print test page        │
│    - Print nozzle check     │
│    - Cek tidak ada bocor    │
└──────────────┬──────────────┘
			   │
			   ▼
┌─────────────────────────────┐
│ 7. EDUKASI KONSUMEN         │
│    - Penyebab masalah       │
│    - Tips perawatan         │
│    - Estimasi umur absorber │
└──────────────┬──────────────┘
			   │
			   ▼
[SELESAI / INVOICE]
```

### 6.2 Checklist Penerimaan Unit (QC Masuk)

| ✅ Item               | 📝 Detail                             | ⚠️ Catatan                 |
| -------------------- | ------------------------------------- | -------------------------- |
| ☐ Fisik Body         | Cek retak, penyok, bocor              | Foto sebelum bongkar       |
| ☐ Kelengkapan        | Unit, kabel power, kabel USB, dus     | Kurang = disclaimer        |
| ☐ Catridge/Tinta     | Cek level, cek kering, cek asli/palsu | Tinta palsu = void garansi |
| ☐ Test Print Sebelum | Cetak sebelum disentuh                | Bukti kondisi awal         |
| ☐ Error Code         | Catat kode error yang muncul          | Referensi untuk diagnosis  |

---

## 7. Tools & Software Arsenal

### 7.1 Software Resetter

| Nama Tool | Fungsi | Platform | Lisensi | Risiko |
|---|---|---|---|---|
| **AdjProg** (Epson) | Reset waste ink counter | Windows | Gratis (bocoran) | ⚠️ Tinggi — sering disusupi malware |
| **WIC Reset Utility** | Universal Epson resetter | Windows/Mac | Freemium (reset berbayar) | ✅ Rendah — dari vendor resmi |
| **Service Tool** (Canon) | Reset waste ink + service functions | Windows | Gratis (bocoran) | ⚠️ Tinggi — versi bajakan |
| **PrintHelp** | Diagnostic tool Epson | Windows | Freeware | ✅ Aman |
| **Canon Service Tool** (official) | Full service functions | Windows | Internal (SC only) | N/A |

### 7.2 Hardware Tools

| Nama Tool | Fungsi | Harga Estimasi |
|---|---|---|
| **Soldering Iron** | Ganti EEPROM, repair board | Rp 50.000 — 200.000 |
| **CH341A Programmer** | Flash EEPROM, backup firmware | Rp 50.000 — 100.000 |
| **SOP8 Clip** | Jepit chip EEPROM tanpa solder | Rp 20.000 — 50.000 |
| **Multimeter** | Cek tegangan board, short | Rp 50.000 — 150.000 |
| **Head Cleaning Kit** | Pembersih head printer | Rp 30.000 — 80.000 |
| **Waste Ink Pad** | Busa penampung pengganti | Rp 20.000 — 60.000 |

### 7.3 Sumber File (Dengan Peringatan)

| Sumber | Jenis File | Peringatan |
|---|---|---|
| Nesabamedia | AdjProg, Service Tool | Shortlink bertumpuk, iklan, risiko malware |
| Kuyhaa | Software bajakan | Repack sering corrupt, password palsu |
| iLoadZone | File hosting | Etalase, file asli dari forum luar |
| TestCopy (forum) | Original tools | Lebih straightforward, tapi butuh akun |
| flashboot.ru | MPTool, firmware | Spesifik flashdisk/SSD, bukan printer |

---

## 8. Mitigasi Risiko & Peringatan Kritis

### 8.1 Risiko Software (Malware)

> [!danger]
> **Fenomena "False Positive" vs "True Malware":**
> Resetter sering dideteksi sebagai virus karena teknik **obfuscation** (mirip malware). TAPI, sering ada **"penumpang gelap"** — backdoor yang disisipkan oleh uploader.
> 
> **Aturan Emas:**
> 1. Download hanya jika ABSOLUTELY NECESSARY
> 2. Scan dengan **VirusTotal** sebelum ekstrak
> 3. Jalankan di **VM/sandbox** — JANGAN pernah di host utama
> 4. Jangan disable antivirus demi jalanin resetter
> 5. Setelah selesai, **hapus VM** atau revert snapshot

### 8.2 Risiko Hardware (Brick)

| ☠️ Kesalahan | ⚡ Konsekuensi | 🛡️ Pencegahan |
|---|---|---|
| Salah pilih model di AdjProg | EEPROM rusak, printer mati total | Double-check model, foto layar sebelum klik |
| Salah hitung tombol Service Mode (Canon) | EEPROM lock permanen | Hitung dengan suara, jangan buru-buru |
| Flash firmware corrupt | Motherboard hang | Backup firmware asli dulu via programmer |
| Ganti absorber tanpa reset counter | Printer tetap error | Reset counter SETELAH ganti absorber |

### 8.3 Risiko Legal & Etik

> [!caution]
> - **Lisensi Software:** AdjProg dan Service Tool adalah **internal tools** milik Epson/Canon. Penggunaan tanpa izin berada di zona abu-abu legally.
> - **Garansi:** Reset counter sendiri biasanya **membatalkan garansi resmi**.
> - **Tanggung Jawab:** Selalu beri tahu konsumen risiko sebelum eksekusi. Dokumentasikan persetujuan.

---

## 9. Gallery & Visual Reference

> [!info]
> Placeholder untuk gambar-gambar yang akan ditambahkan:
> - Foto indikator lampu error (Epson & Canon)
> - Screenshot interface AdjProg
> - Screenshot interface WIC Reset
> - Foto ritual tombol service mode
> - Foto maintenance cartridge Canon
> - Foto waste ink pad (busa) dalam kondisi penuh vs baru
> - Foto CH341A programmer & SOP8 clip
> - Diagram anatomi printer (head, cartridge, absorber)

### Daftar Gambar yang Perlu Dibuat/Dicari:

| No  | Nama File                         | Deskripsi                               | Prioritas |
| --- | --------------------------------- | --------------------------------------- | --------- |
| 1   | `indicator-lamp-epson.png`        | Perbandingan lampu normal vs error      | Tinggi    |
| 2   | `adjprog-interface.png`           | Screenshot UI AdjProg dengan penjelasan | Tinggi    |
| 3   | `wic-reset-ui.png`                | Screenshot WIC Reset Utility            | Sedang    |
| 4   | `service-mode-epson.png`          | Posisi tombol & urutan tekan            | Tinggi    |
| 5   | `service-mode-canon.png`          | Ritual tombol Canon                     | Tinggi    |
| 6   | `maintenance-cartridge-canon.png` | MC-G02 fisik                            | Sedang    |
| 7   | `waste-ink-pad-comparison.png`    | Busa penuh vs baru                      | Sedang    |
| 8   | `ch341a-programmer.png`           | Alat flash EEPROM                       | Rendah    |
| 9   | `printer-anatomy-diagram.png`     | Head, cartridge, absorber               | Sedang    |
| 10  | `technician-workflow.png`         | Infografis alur servis                  | Rendah    |

---

## Connected Notes

- [[endpoint-security-freeware]] — Referensi arsitektur keamanan endpoint
- [[technician-toolkit-standard|TEMA-B-Technician-Toolkit-Standard]] — Flashdisk servis lengkap (Ventoy, Strelec, recovery tools)
- [[laptop-qc-procurement|TEMA-C-Laptop-QC-Procurement]] — QC laptop & perangkat elektronik lain
- `sop-windows-browser-hardening` — Keamanan browser & mitigasi infostealer
- [[storage-refurbishing]] — Refurbishing HDD/SSD untuk dijual kembali

---

## Changelog

| Versi | Tanggal | Perubahan |
|---|---|---|
| v1.0 | 2026-05-11 | Dokumen awal dari RAW chat, strukturasi ulang dengan template Obsidian |

---

_End of Document — Printer Maintenance & Reset | Dari L100 sampai MC-G02 | Teknisi Field Guide_
audited
