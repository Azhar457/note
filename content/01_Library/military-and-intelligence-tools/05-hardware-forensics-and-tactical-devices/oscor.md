---
title: Oscor
tags:
  - 05-hardware-forensics-and-tactical-devices
  - library
  - military-and-intelligence-tools
created: "2026-06-28"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> Oscor dan ANDRE adalah peralatan TSCM (Technical Surveillance Counter-Measures) profesional yang diproduksi oleh Research Electronics International (REI), AS. Alat ini digunakan untuk mendeteksi perangkat pengawasan tersembunyi (bug, kamera, pemancar). Informasi di bawah berasal dari dokumentasi publik, materi pelatihan TSCM, serta literatur keamanan fisik. Pembahasan ini murni **edukasional dan defensif**. Tujuannya agar defender memahami cara melindungi ruang percakapan sensitif dari penyadapan.

---

## 🧬 Apa Itu Oscor & ANDRE?

Oscor (Omni-Spectral Correlator) dan ANDRE (Advanced Near-field Detection Receiver) adalah dua perangkat TSCM profesional yang membentuk **duo deteksi bug**:

| Perangkat | Fungsi Utama                                                                                    | Jangkauan                                     |
| --------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **Oscor** | Spectrum analyzer broadband (24 GHz) untuk mendeteksi semua transmisi RF di ruangan             | 10 kHz – 24 GHz (near-field hingga far-field) |
| **ANDRE** | Near-field receiver untuk mendeteksi sinyal sangat lemah (bug yang tertanam di dinding/perabot) | 10 kHz – 6 GHz (near-field, < 1 meter)        |

Bersama, Oscor dan ANDRE dapat menemukan hampir semua jenis bug elektronik — dari pemancar RF standar hingga perangkat pasif yang hanya memancar saat diaktifkan.

### Mengapa Underrated?

TSCM jarang dibahas di komunitas teknis umum karena:

- **Harga sangat mahal** (Oscor: $30.000+, ANDRE: $15.000+).
- **Penjualan dibatasi** untuk lembaga pemerintah dan korporasi tertentu.
- **Informasi teknis terbatas** (vendor tidak mempublikasikan spesifikasi lengkap).
- **Tidak "seksi"** seperti offensive tools — padahal ini pertahanan kritis.

---

## 🏗️ Arsitektur Teknis

### 1. Oscor (Omni-Spectral Correlator)

Oscor adalah **spectrum analyzer broadband portabel** yang dirancang khusus untuk TSCM. Ia menggabungkan:

| Komponen              | Fungsi                                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Wideband Receiver** | Menangkap sinyal dari 10 kHz hingga 24 GHz — mencakup hampir semua frekuensi komunikasi (AM/FM, GSM, WiFi, Bluetooth, satelit, microwave). |
| **Antenna Kit**       | Beberapa antena untuk berbagai rentang frekuensi: whip, loop, log-periodic, horn, near-field probe.                                        |
| **Correlator Engine** | Membandingkan sinyal yang diterima di beberapa antena untuk memisahkan sinyal asli dari pantulan dan noise.                                |
| **Demodulator**       | Mendemodulasi sinyal untuk mendengarkan audio (AM, FM, SSB, CW, digital).                                                                  |
| **Display & GUI**     | Layar sentuh dengan waterfall spectrum, persistence display, dan signal database.                                                          |
| **Storage**           | Menyimpan snapshot spektrum untuk baseline dan perbandingan historis.                                                                      |

**Mode Operasi Oscor:**

| Mode                    | Fungsi                                                                             |
| ----------------------- | ---------------------------------------------------------------------------------- |
| **Full Spectrum Sweep** | Memindai seluruh 10 kHz – 24 GHz dan menampilkan semua sinyal.                     |
| **Band Sweep**          | Fokus pada rentang frekuensi spesifik (misal: hanya WiFi/Bluetooth 2.4 GHz).       |
| **Differential Mode**   | Membandingkan spektrum saat ini dengan baseline — sinyal baru langsung terdeteksi. |
| **Audio Demodulation**  | Mendemodulasi sinyal untuk mendengarkan audio yang ditransmisikan bug.             |
| **Direction Finding**   | Menggunakan antena directional untuk menemukan lokasi fisik pemancar.              |

### 2. ANDRE (Advanced Near-field Detection Receiver)

ANDRE adalah **near-field receiver ultra-sensitif** yang mendeteksi emisi elektromagnetik sangat lemah dari perangkat elektronik — termasuk bug yang dimatikan sementara atau dalam mode sleep.

| Komponen                      | Fungsi                                                                                                     |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Near-field Probe**          | Antena loop kecil untuk mendeteksi medan magnet/E dekat (beberapa cm dari sumber).                         |
| **Ultra-low Noise Amplifier** | Memperkuat sinyal sangat lemah tanpa menambah noise.                                                       |
| **Frequency Converter**       | Mengkonversi sinyal ke IF (Intermediate Frequency) untuk analisis.                                         |
| **Headphone Output**          | Output audio untuk mendengar demodulasi sinyal (seringkali terdengar sebagai dengung, klik, atau osilasi). |
| **Visual Indicator**          | LED bar graph menunjukkan kekuatan sinyal relatif.                                                         |

**Keunggulan ANDRE:**

- **Mendeteksi bug yang tidak memancar**: Osilator lokal, clock processor, power supply — semua komponen elektronik memancarkan emisi elektromagnetik lemah. ANDRE bisa mendeteksinya.
- **Tidak memerlukan bug aktif**: Bahkan jika bug dalam mode sleep atau dikendalikan jarak jauh (hanya aktif saat diperintah), ANDRE bisa menemukannya dari emisi pasif.
- **Penetrasi dinding**: Sinyal near-field bisa menembus dinding tipis, memungkinkan sweeping tanpa merusak.

---

## 🔬 Metodologi TSCM Sweeping

Proses sweeping profesional dengan Oscor + ANDRE:

### Fase 1: Baseline & Spectrum Analysis (Oscor)

1. **Matikan semua perangkat yang sah** di ruangan (WiFi, Bluetooth, ponsel, laptop).
2. **Jalankan full spectrum sweep** dengan Oscor dan rekam baseline.
3. **Identifikasi sinyal yang tidak dikenal**: frekuensi, modulasi, pola (continuous, burst, periodic).
4. **Demodulasi sinyal mencurigakan** untuk mendengarkan apakah ada audio/video yang ditransmisikan.

### Fase 2: Near-Field Sweeping (ANDRE)

1. **Telusuri seluruh ruangan** dengan ANDRE: dinding, lantai, langit-langit, perabot, stop kontak, lampu, lukisan, telepon, komputer.
2. **Dengarkan anomali** melalui headphone: dengung 50/60 Hz (power supply), osilasi (osilator), klik periodik (transmisi burst).
3. **Tandai area mencurigakan** untuk inspeksi fisik.

### Fase 3: Inspeksi Fisik

1. Buka stop kontak, sakelar, dan panel dinding.
2. Periksa di balik perabot, di dalam pot tanaman, di balik lukisan.
3. Gunakan borescope atau fiber optic camera untuk ruang sempit.

### Fase 4: Direction Finding (Oscor)

1. Untuk sinyal yang kuat, gunakan antena directional Oscor.
2. Lakukan triangulasi: pindahkan antena ke beberapa posisi, catat arah sinyal terkuat.
3. Titik perpotongan adalah lokasi pemancar.

---

## 🕵️‍♂️ Jenis Bug yang Dapat Dideteksi

| Jenis Bug                   | Karakteristik                                             | Terdeteksi Oleh                                  |
| --------------------------- | --------------------------------------------------------- | ------------------------------------------------ |
| **RF Transmitter (FM/AM)**  | Memancar terus-menerus di frekuensi VHF/UHF               | Oscor (far-field), ANDRE (near-field)            |
| **GSM/3G/4G Bug**           | Menggunakan jaringan seluler, sulit dibedakan dari ponsel | Oscor (sinyal TDMA/LTE), ANDRE                   |
| **WiFi Bug**                | Terhubung ke WiFi lokal, transmisi TCP/IP                 | Oscor (2.4/5 GHz), ANDRE                         |
| **Bluetooth Bug**           | Jarak pendek, frequency hopping                           | Oscor (deteksi hopping pattern)                  |
| **Voice Recorder (Non-RF)** | Tidak memancar, hanya merekam                             | ANDRE (emisi clock/prosesor)                     |
| **Camera Pinhole (Wired)**  | Tidak memancar, kabel ke DVR                              | Inspeksi fisik, lens detection                   |
| **Passive Resonator**       | Tidak ada elektronik, hanya membran akustik               | Inspeksi fisik (sulit dideteksi elektronik)      |
| **Laser Microphone**        | Tidak ada bug di ruangan; laser dipantulkan dari jendela  | Tidak terdeteksi Oscor/ANDRE (butuh IR detector) |

---

## 🛡️ Countermeasures — Melindungi dari Deteksi

Jika Anda adalah defender yang memasang bug untuk pengawasan sah (dengan warrant), Anda harus tahu bagaimana bug bisa terdeteksi:

| Metode Deteksi            | Cara Bug Menghindar                                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Oscor Spectrum Sweep**  | Gunakan **frequency hopping**, **spread spectrum**, atau **burst transmission** (hanya aktif beberapa milidetik per jam). |
| **ANDRE Near-Field**      | Gunakan **shielding** (logam) di sekitar bug. Tanam deep di dalam perabot logam.                                          |
| **Audio Demodulation**    | Enkripsi audio sebelum transmisi.                                                                                         |
| **Direction Finding**     | Gunakan **relay** — bug kecil yang meneruskan ke pemancar lebih besar di luar ruangan.                                    |
| **Differential Baseline** | Bug harus sudah terpasang SEBELUM baseline dibuat (supply chain implant).                                                 |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

TSCM Sweeping             Forensik Investigasi      Kontra-Intelijen
│                         │                        │
Melindungi ruang          Menemukan bug di         Menemukan dan
rapat korporasi/          TKP setelah              menganalisis bug
pemerintah dari           kejahatan untuk          musuh untuk
penyadapan                mengidentifikasi         mempelajari TTP
│                         pelaku                   │
│                         │                        │
│                         │                        ▼
▼                         ▼                        Ofensif balik:
Security team             Penegak hukum            menanam bug
proaktif                  (chain of custody)       sendiri setelah
                                                   memetakan TSCM
                                                   musuh
```

---

## 🔗 Koneksi dalam Vault

- [[imsi-catcher]] — IMSI Catcher adalah alat ofensif; Oscor/ANDRE adalah defensif. Keduanya beroperasi di domain RF.
- [[hack5-suite]] — Alat Hak5 untuk physical intrusion; Oscor/ANDRE untuk mendeteksi physical bug.
- RF & SIGINT — Oscor pada dasarnya adalah spectrum analyzer; terkait erat dengan SDR, analisis spektrum, dan RF forensics.
- [[cellebrite-ufed]] — UFED untuk ekstraksi data digital; Oscor/ANDRE untuk ekstraksi data analog (sinyal RF).
- [[drfm]] — Digital RF Memory untuk jamming; Oscor bisa mendeteksi emisi DRFM.

---

## 📚 Referensi

- Research Electronics International (REI). _Oscor & ANDRE Technical Overview_.
- E-Space. _TSCM Professional Training Manual_.
- NIST SP 800-53 Rev 5: _Physical and Environmental Protection Controls_.
- ASIS International. _TSCM: Technical Surveillance Countermeasures Standards_.

---

_Oscor / ANDRE Deep Dive | TSCM Bug Detection & Counter-Surveillance | Physical Security RF Sweeping_
