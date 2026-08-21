---
title: "SDR Cell Tower Reconnaissance and Stingray Detection"
tags:
- signal-intelligence
- sdr
- cellular-security
- stingray-detection
- blue-team
aliases:
- SDR Cell Tower Reconnaissance
- Stingray Detection Guide
- CellSearch FALCON Pipeline
created: 2026-08-15
updated: 2026-08-15
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Panduan operasional lengkap deteksi menara seluler (cell tower) dan identifikasi **IMSI Catcher / Stingray** menggunakan Software Defined Radio (SDR). Pipeline utama: **DragonOS → CellSearch (discovery) → CellTracker (lock-on) → FALCON (ekstraksi RNTI) → Wireshark (analisis paket) → triangulasi**. Semua teknik bersifat *passive receive-only* — legal untuk riset, edukasi, dan verifikasi keamanan pribadi. Catatan ini melengkapi sisi praktis dari [[imsi-catcher]] (teori perangkat) dan terhubung ke [[hierarchy-wireless]] serta [[wireless-security-deepdive]].

# 📡 SDR Cell Tower Reconnaissance & Stingray Detection

## Daftar Isi

1. [[#1. Overview — Hardware & Software Stack]]
2. [[#2. DragonOS Setup]]
3. [[#3. Step 1 — Initial Reconnaissance dengan CellSearch]]
4. [[#4. Step 2 — Baseline & Anomaly Detection]]
5. [[#5. Step 3 — Targeted Monitoring dengan CellTracker]]
6. [[#6. Step 4 — Deep Analysis dengan FALCON (PDCCH Decoder)]]
7. [[#7. Step 5 — Packet Capture dengan Wireshark]]
8. [[#8. Step 6 — Directional Antenna & Triangulation]]
9. [[#9. IMSI Catcher Detection Checklist]]
10. [[#10. GSM IMSI Catcher — Budget Build]]
11. [[#11. Tools Reference]]
12. [[#12. Catatan Legal & Keselamatan]]
13. [[#13. Referensi]]
14. [[#14. Koneksi ke Vault]]

---

## 1. Overview — Hardware & Software Stack

Deteksi menara seluler dan IMSI catcher pada dasarnya adalah **RF reconnaissance**: memindai spektrum untuk menemukan base station, menganalisis control channel LTE, dan mencari anomali yang menandakan perangkat penyamar (rogue BTS). Perangkat seperti Stingray memaksa ponsel di sekitarnya terhubung ke dirinya alih-alih menara operator asli — sehingga mempelajari *fingerprint* perilakunya adalah kunci pertahanan.

### Hardware Stack

| Komponen | Peran | Rentang Frekuensi | Catatan |
|----------|-------|-------------------|---------|
| **HackRF One** | SDR wideband | 1 MHz – 6 GHz | Half-duplex, bandwidth 20 MHz |
| **LimeSDR** | SDR full-duplex | 100 kHz – 3.8 GHz | Dibutuhkan untuk analisis mendalam FALCON |
| **Antena Parabola** | Gain directional | Tergantung desain | Fokus penerimaan, mereduksi noise; 15–24 dBi |
| **RTL-SDR** | Opsi budget | 24 MHz – 1.766 GHz | Terbatas ke GSM / band LTE bawah |

### Software Stack

| Tool | Fungsi | OS |
|------|--------|-----|
| **DragonOS** | Distro Linux khusus SDR (Debian-based) | Linux |
| **LTE-Cell-Scanner** | Scan frekuensi, menemukan cell tower | DragonOS / Linux |
| **CellTracker** | Monitor cell tower spesifik secara kontinu | DragonOS / Linux |
| **FALCON** | Decode PDCCH, ekstraksi RNTI, visualisasi | Linux |
| **Wireshark** | Analisis paket (MAC layer, RRC) | Cross-platform |
| **GQRX / SDR#** | Spectrum analyzer | Cross-platform |

> [!tip] Analogi: CellSearch untuk spektrum RF adalah seperti `nmap` untuk jaringan IP — fase discovery yang memetakan "host" (menara) sebelum analisis lebih dalam.

---

## 2. DragonOS Setup

DragonOS adalah distribusi Debian-based dengan tooling SDR yang sudah terpasang — menghemat berjam-jam resolusi dependency.

```bash
# Download DragonOS FocalX (terbaru) dari:
# https://cemaxecuter.com/

# Flash ke USB / SD card:
sudo dd if=dragonos_focalx.iso of=/dev/sdX bs=4M status=progress

# Boot dari USB. Persistent storage opsional.
```

### Lokasi Tools Utama

```
/usr/src/LTE-Cell-Scanner/     # CellSearch, CellTracker, LTE-Tracker
/usr/src/falcon/               # FALCON PDCCH decoder
/usr/bin/                      # GQRX, CubicSDR, GNU Radio
```

---

## 3. Step 1 — Initial Reconnaissance dengan CellSearch

CellSearch memindai pita frekuensi LTE untuk menemukan cell tower aktif, Cell ID (CID), dan parameter sinyal.

### Pita Frekuensi LTE (Umum)

| Band | Downlink (MHz) | Uplink (MHz) | Region |
|------|----------------|--------------|--------|
| B2 (1900) | 1930–1990 | 1850–1910 | Americas |
| B4 (AWS-1) | 2110–2155 | 1710–1755 | Americas |
| B5 (850) | 869–894 | 824–849 | Americas |
| B12 (700) | 729–746 | 699–716 | Americas |
| B13 (700) | 746–756 | 777–787 | Americas |
| B20 (800) | 791–821 | 832–862 | Europe |
| B28 (700) | 758–803 | 703–748 | Global |
| B3 (1800) | 1805–1880 | 1710–1785 | Europe/Asia |
| B1 (2100) | 2110–2170 | 1920–1980 | Global |
| B7 (2600) | 2620–2690 | 2500–2570 | Europe/Asia |

### Perintah CellSearch

```bash
cd /usr/src/LTE-Cell-Scanner/build/src

# Basic scan: band 700 MHz (Band 12/13/28)
./CellSearch --freq-start 699000000 --freq-end 801000000 -g 50

# Scan 1.7–2.3 GHz (band urban: B1, B3, B4, B7)
./CellSearch --freq-start 1700e6 --freq-end 2300e6 -g 50

# Full spectrum sweep (lambat, berjam-jam)
./CellSearch --freq-start 600e6 --freq-end 3800e6 -g 50

# Scan dengan device spesifik (HackRF)
./CellSearch_hackrf --freq-start 800e6 --freq-end 900e6 -g 50

# Scan dengan RTL-SDR
./CellSearch_rtlsdr --freq-start 800e6 --freq-end 900e6 -g 50

# Simpan raw signal untuk analisis offline
./CellSearch --freq-start 1860e6 --recbin capture.bin
./CellSearch --loadbin capture.bin  # replay
```

### Contoh Output CellSearch

```
Found 4 cells:
  Frequency: 719.5 MHz, Cell ID: 123, FDD, SNR: +32 dB
  Frequency: 731.5 MHz, Cell ID: 456, FDD, SNR: +28 dB
  Frequency: 731.5 MHz, Cell ID: 457, FDD, SNR: +25 dB  ← frekuensi sama, sektor berbeda
  Frequency: 739.0 MHz, Cell ID: 789, FDD, SNR: +18 dB
```

**Data points kunci:**
- **Frequency** — frekuensi transmit menara
- **Cell ID (CID)** — identifier unik per sektor
- **FDD/TDD** — mode duplexing
- **SNR** — kualitas sinyal (negatif = lemah/noisy, +20 sampai +50 = sehat)

---

## 4. Step 2 — Baseline & Anomaly Detection

Prinsip deteksi Stingray adalah **membangun baseline lalu mencari penyimpangan**. Menara legitimate memiliki pola stabil; rogue BTS hampir selalu memunculkan anomali pada salah satu dimensi berikut.

### Membangun Baseline

```bash
# Jalankan CellSearch setiap hari di lokasi tetap selama 1 minggu
# Log: frequency, CID, SNR, timestamp
# Simpan di: ~/cell_baseline.log

# Contoh script logging:
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
./CellSearch_hackrf --freq-start 600e6 --freq-end 3800e6 -g 50 > ~/baseline_$DATE.log 2>&1
```

### Indikator Anomali (Stingray / Rogue BTS)

| Indikator | Deskripsi | Confidence |
|-----------|-----------|------------|
| **CID baru** | Cell ID yang tidak pernah ada di baseline | Medium |
| **SNR tinggi, CID tak dikenal** | Sinyal sangat kuat dari menara tak dikenal | High |
| **CID dikenal hilang** | Menara legitimate menghilang, digantikan yang tak dikenal | High |
| **Frekuensi collision** | Frekuensi sama dengan menara legitimate, CID beda | High |
| **Tidak ada SIB broadcast** | Menara tidak memancarkan System Information Blocks | Medium |
| **Anomali TA (Timing Advance)** | Perhitungan jarak yang tidak wajar | Medium |
| **LAC/TAC mismatch** | Location/Tracking Area Code tidak cocok dengan carrier | High |
| **Spike RxLev** | Kenaikan sinyal mendadak +20–30 dBm | High |

### Heuristik Deteksi

```
IF (CID baru AND SNR > +40 dB AND tidak ada di database carrier)
    → FLAG: Potential rogue BTS
IF (CID dikenal hilang AND CID baru muncul di frekuensi sama dalam 24 jam)
    → FLAG: Possible Stingray takeover
IF (menara meminta IMSI tanpa fallback TMSI)
    → FLAG: IMSI catcher behavior
```

---

## 5. Step 3 — Targeted Monitoring dengan CellTracker

Setelah menemukan frekuensi/CID mencurigakan, CellTracker dipakai untuk pemantauan kontinu.

```bash
# Monitor frekuensi spesifik
./CellTracker_hackrf -f 719500000 -g 50

# Monitor dengan RTL-SDR
./CellTracker_rtlsdr -f 719500000 -g 50

# Output: update kontinu CID, SNR, RSRP, RSRQ
```

**Contoh output CellTracker:**

```
Cell ID: 123, SNR: +32 dB, RSRP: -85 dBm, RSRQ: -10 dB
Cell ID: 456, SNR: +28 dB, RSRP: -92 dBm, RSRQ: -12 dB
```

Yang diamati: **instabilitas SNR**, **perintah handover terlalu sering**, dan fluktuasi RSRP/RSRQ yang tidak wajar.

---

## 6. Step 4 — Deep Analysis dengan FALCON (PDCCH Decoder)

FALCON (**F**ast **A**nalysis of **L**TE **C**ontrol ch**a**nnels) adalah tool kritis — decoder Physical Downlink Control Channel (PDCCH) yang mengungkap setiap perangkat aktif yang terhubung ke menara melalui **RNTI** (Radio Network Temporary Identifier).

FALCON didasarkan pada library srsLTE dan **sinkronisasi pasif** ke sel — mendecode DCI (Downlink Control Information) tanpa pernah attach ke jaringan. Ini yang membedakannya dari pendekatan aktif yang berisiko terdeteksi.

### Konsep Teknis Kunci

**PDCCH (Physical Downlink Control Channel):**
- Membawa pesan DCI setiap 1 ms (per subframe)
- DCI memberi tahu setiap UE (ponsel) resource block mana yang dipakai
- Setiap DCI di-scramble dengan RNTI UE (16-bit ID)

### Jenis RNTI

| RNTI | Value | Tujuan |
|------|-------|--------|
| SI-RNTI | 0xFFFF | System Information |
| P-RNTI | 0xFFFE | Paging |
| RA-RNTI | 0x0001–0x003C | Random Access Response |
| C-RNTI | 0x0001–0xFFF3 | Connected UE identifier |
| Temp C-RNTI | Dynamic | Temporary saat connection setup |

### FALCON vs OWL

| Fitur | OWL | FALCON |
|-------|-----|--------|
| Discovery RNTI | Re-encoding (sensitif noise) | **RNTI histograms + shortcut decoding** |
| Monitoring jangka pendek | Buruk | **Excellent** |
| Kondisi non-ideal | Butuh sinyal sempurna | **Robust** |

> [!note] Inovasi FALCON (dari paper arXiv:1907.10110): (1) **RNTI histograms** — melacak frekuensi kemunculan tiap RNTI; (2) **recursive shortcut decoding** — depth-first search lokasi CCE untuk memvalidasi RNTI yang belum terlihat selama blind decoding; (3) **PRACH tracking** — menangkap UE baru yang bergabung ke sel.

### Instalasi & Penggunaan FALCON

```bash
# Prerequisites (Ubuntu/Debian)
sudo apt-get install cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev \
    libconfig++-dev libsctp-dev libuhd-dev libsoapysdr-dev

# Clone dan build
git clone https://github.com/falkenber9/falcon.git
cd falcon
mkdir build && cd build
cmake ..
make -j$(nproc)

# Run FALCON recorder (butuh LimeSDR atau USRP B210)
./FalconRecorder -f 1860e6 -g 40 --rf-args "driver=lime"

# Run FALCON decoder (offline dari file rekaman)
./FalconEye -f 1860e6 --load-recording capture.bin

# Run FALCON live (dengan GUI)
./FalconEye -f 1860e6 -g 40 --rf-args "driver=lime"
```

### Interpretasi GUI FALCON

```
[Waterfall]      [DL Resource Blocks]      [UL Resource Blocks]
    |                  |                         |
Signal magnitude    Color-coded per RNTI      Color-coded per RNTI
    |                  |                         |
Shows cell signal   Setiap warna = 1 device   Setiap warna = 1 device
strength over time  Width = allocated RBs     Width = allocated RBs
```

### Deteksi Stingray via FALCON

- **Sel normal:** 10–50 RNTI aktif (tergantung kepadatan urban)
- **Stingray:** sering menunjukkan hanya **1–3 RNTI** (target + decoy), atau pola alokasi abnormal
- **Forced handover:** RNTI turun mendadak, RNTI baru muncul di sel berbeda

---

## 7. Step 5 — Packet Capture dengan Wireshark

### Pipeline srsRAN + Wireshark

```bash
# srsRAN eNB dengan MAC layer logging
srsenb --pcap.enable=true --pcap.filename=mac_capture.pcap

# Atau srsUE untuk capture sisi client
srsue --pcap.enable=true --pcap.filename=ue_capture.pcap

# Buka di Wireshark
wireshark mac_capture.pcap
```

### Filter Wireshark untuk Analisis LTE

```wireshark
# Filter by RNTI
lte_mac.rnti == 0x0046

# Filter by LCID (Logical Channel ID)
lte_mac.lcid == 3

# Filter RAR messages (Random Access Response)
lte_mac.rar

# Filter paging messages
lte_rrc.pcch_message

# Filter SIB (System Information Block)
lte_rrc.bcch_bch
```

### Paket Kunci yang Dimonitor

| Tipe Paket | Indikator | Tanda Stingray |
|------------|-----------|----------------|
| RAR (Random Access Response) | Assign Temp C-RNTI | Re-assignment cepat |
| SecurityModeCommand | Setup enkripsi | Hilang atau tertunda |
| Paging | Paging berbasis TMSI | Paging berbasis IMSI (mencurigakan) |
| RRC Connection Release | Disconnect normal | Forced release berulang |

---

## 8. Step 6 — Directional Antenna & Triangulation

### Setup Antena Parabola

```
Antena Parabola
    ├── Gain: 15-24 dBi (tergantung ukuran)
    ├── Beamwidth: 5-15 derajat
    └── Penggunaan: arahkan ke menara tersangka, kurangi interferensi

Setup:
1. Mount di tripod dengan penyesuaian azimuth/elevation
2. Hubungkan ke HackRF/LimeSDR via coax low-loss (<3m)
3. Gunakan CellTracker untuk menemukan peak signal sambil memutar
4. Catat azimuth dari 2+ lokasi
5. Triangulasi di peta
```

### Metode Triangulasi

```
Location A: GPS(lat1, lon1), Azimuth ke menara: 45°
Location B: GPS(lat2, lon2), Azimuth ke menara: 120°
    |
    v
Tarik garis dari A dan B pada azimuth yang dicatat
Perpotongan = lokasi menara
Akurasi meningkat dengan jarak A-B (>500m)
```

---

## 9. IMSI Catcher Detection Checklist

### Deteksi Aktif (Anda memindai mereka)

```bash
# 1. Bangun baseline
CellSearch_full_spectrum > baseline.log

# 2. Perbandingan harian
diff baseline.log current_scan.log | grep "^>" > new_cells.log

# 3. Investigasi sel baru
for freq_cid in $(cat new_cells.log); do
    CellTracker -f $freq -g 50 &
    # Monitor 30 menit, log stabilitas SNR
    # Cek apakah CID ada di database carrier
    # Query opencellid.org atau cellmapper.net
done

# 4. Analisis mendalam pada sel mencurigakan
FalconEye -f $freq -g 40 --rf-args "driver=lime"
# Amati: <5 RNTI, tanpa SIB, forced handovers
```

### Deteksi Pasif (Anda mendeteksi sedang ditarget)

| Gejala | Kemungkinan Penyebab | Verifikasi |
|--------|---------------------|------------|
| Ponsel turun 4G → 2G tanpa alasan | Stingray memaksa downgrade (2G lebih mudah disadap) | Cek indikator network type |
| Baterai boros mendadak | Ponsel bekerja lebih keras menjaga koneksi ke rogue BTS | Statistik penggunaan baterai |
| SMS/panggilan tertunda | Trafik dirutekan lewat interceptor | Bandingkan dengan ponsel lain di carrier sama |
| Tidak ada indikator enkripsi | A5/0 (tanpa enkripsi) dipaksa | Cek engineering mode |
| Banyak "cell tower" dengan CID sama | BTS spoofed | Cross-reference dengan database carrier |

### Engineering Mode (Android)

```
*#*#4636#*#*      → Phone information → Cek network type
*#0011#           → Service mode → Lihat parameter sel
*#*#197328640#*#* → Debug mode → Informasi RF
```

---

## 10. GSM IMSI Catcher — Budget Build

Khusus GSM (2G), SDR murah sudah cukup:

```bash
# Hardware: RTL-SDR v3 (~$20)
# Software: gr-gsm + Wireshark

# Install
sudo apt-get install gr-gsm

# Cari frekuensi downlink GSM
grgsm_scanner

# Capture paket GSM
grgsm_livemon -f 935.4M  # Contoh: GSM900 downlink

# Lihat di Wireshark
# Filter: gsmtap
```

**Keterbatasan:**
- GSM only (2G). 3G/4G/5G butuh SDR lebih advanced (HackRF/LimeSDR/USRP)
- Enkripsi A5/1 bisa dipecahkan dengan rainbow tables (Kraken)
- 4G/5G pakai enkripsi lebih kuat, tapi Stingray bisa **memaksa downgrade ke 2G**

---

## 11. Tools Reference

| Tool | Install | Tujuan |
|------|---------|--------|
| DragonOS | cemaxecuter.com | Distro SDR all-in-one |
| LTE-Cell-Scanner | github.com/JiaoXianjun/LTE-Cell-Scanner | Cell tower scanning |
| FALCON | github.com/falkenber9/falcon | PDCCH decoding, ekstraksi RNTI |
| srsRAN | github.com/srsran/srsRAN | Stack 4G/5G + ekspor PCAP |
| gr-gsm | apt install gr-gsm | Analisis GSM |
| GQRX | apt install gqrx-sdr | Spectrum analyzer |
| Wireshark | apt install wireshark | Analisis paket |
| kalibrate-rtl | github.com/steve-m/kalibrate-rtl | Kalibrasi frekuensi |

---

## 12. Catatan Legal & Keselamatan

- **Transmitting** pada frekuensi seluler tanpa lisensi ilegal di hampir semua yurisdiksi
- **Passive receiving** (scanning, decoding) umumnya legal untuk riset/edukasi
- **Deteksi Stingray** untuk keamanan pribadi adalah legal
- **Interception** komunikasi yang bukan untuk Anda adalah ilegal
- Selalu cek regulasi lokal sebelum mengoperasikan peralatan SDR

---

## 13. Referensi

1. FALCON paper: *FALCON: An Accurate Real-time Monitor for Client-based Mobile Traffic* — https://arxiv.org/pdf/1907.10110
2. FALCON GitHub — https://github.com/falkenber9/falcon
3. LTE-Cell-Scanner GitHub — https://github.com/JiaoXianjun/LTE-Cell-Scanner
4. srsRAN Project — https://github.com/srsran/srsRAN
5. DragonOS SDR distro — https://cemaxecuter.com/
6. EFF. *Stingray: The Most Common Cell Phone Surveillance Device* (2019)
7. ACLU. *Stingray Tracking Devices: Who's Got Them?* (2018)
8. 3GPP TS 33.102 — *Security Architecture for 3G/4G/5G*
9. OpenCellID — https://opencellid.org
10. CellMapper — https://cellmapper.net

---

## 14. Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[imsi-catcher]] | Teori, arsitektur, dan produsen IMSI catcher/Stingray — catatan ini menambahkan pipeline deteksi praktisnya |
| [[sdr-cell-tower-evasion-countermeasures]] | Sisi evasion — teknik yang digunakan rogue BTS untuk menghindari pipeline ini (counter-reconnaissance) |
| [[hierarchy-wireless]] | Peta hierarki spektrum nirkabel — SDR cellular ada di tier tactical |
| [[wireless-security-deepdive]] | Fundamental keamanan wireless 802.11/BLE/Zigbee + serangan berbasis SDR |
| [[hierarchy-osint-rf]] | OSINT & RF signal hierarchy — konteks SIGINT yang lebih luas |
| [[military-sigint-deepdive]] | SIGINT militer — konteks taktis dari pemantauan sinyal seluler |
