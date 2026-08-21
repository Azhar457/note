---
title: "SDR Cell Tower Detection Evasion"
tags:
- signal-intelligence
- sdr
- cellular-security
- evasion-techniques
- red-team
aliases:
- SDR Evasion Counter-Detection
- Cell Tower Detection Evasion
- Counter-Reconnaissance SDR
created: 2026-08-15
updated: 2026-08-15
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Analisis teknik **counter-reconnaissance** yang digunakan rogue BTS / operator IMSI catcher untuk menghindari deteksi oleh pipeline SDR (CellSearch, FALCON, spektrum analisis). Sepuluh teknik evasion — dari spectral blending hingga detection-of-detection — dipetakan bersama counter-measure blue team untuk tiap lapisan. Catatan ini adalah sisi ofensif/analitis dari [[sdr-cell-tower-stingray-detection]]; pemahaman kedua sisi diperlukan untuk membangun pertahanan yang realistis. Konten bersifat **edukasional dan defensif** — pengoperasian rogue BTS ilegal di hampir semua yurisdiksi.

# 🛡️ SDR Cell Tower Detection Evasion — Counter-Reconnaissance

## Daftar Isi

1. [[#1. Overview — Threat Model & Evasion Principles]]
2. [[#2. Teknik 1 — Spectral Blending (Clone Legitimate Cells)]]
3. [[#3. Teknik 2 — Power Management]]
4. [[#4. Teknik 3 — Temporal Evasion (Burst Transmission)]]
5. [[#5. Teknik 4 — Frequency Hopping & Band Avoidance]]
6. [[#6. Teknik 5 — RNTI Manipulation]]
7. [[#7. Teknik 6 — Protocol-Level Evasion]]
8. [[#8. Teknik 7 — Physical Security (Anti-Triangulation)]]
9. [[#9. Teknik 8 — Spectrum Masking & Noise Floor Raising]]
10. [[#10. Teknik 9 — Counter-FALCON Specific]]
11. [[#11. Teknik 10 — Detection of Detection]]
12. [[#12. Complete Evasion Configuration]]
13. [[#13. Blue Team Counters]]
14. [[#14. Kerangka Legal]]
15. [[#15. Referensi]]
16. [[#16. Koneksi ke Vault]]

---

## 1. Overview — Threat Model & Evasion Principles

### Threat Model

- **Adversary memiliki:** HackRF, LimeSDR, RTL-SDR, DragonOS, CellSearch, FALCON, Wireshark
- **Adversary dapat:** Scan spektrum, decode PDCCH, ekstrak RNTI, triangulasi arah
- **Adversary tidak dapat:** (dengan mudah) memecahkan AES-256, spoof GPS timing, atau mendeteksi sinyal sub-thermal

### Evasion Principles

| Prinsip | Deskripsi |
|---------|-----------|
| **LPI** (Low Probability of Intercept) | Minimalkan RF signature: power, durasi, bandwidth |
| **Blending** | Tiru parameter sel legitimate secara persis |
| **Mobility** | Jangan pernah diam cukup lama untuk triangulasi |
| **Timing Discipline** | Operasi hanya saat adversary tidak mungkin scanning |
| **Spectrum Discipline** | Hindari band yang sedang dimonitor adversary |

> [!tip] Inti permainan: **signal vs. noise**. Rogue BTS menang jika ia tidak bisa dibedakan dari noise atau dari sel legitimate — siapa yang mengontrol noise floor, dialah yang menang.

---

## 2. Teknik 1 — Spectral Blending (Clone Legitimate Cells)

### Clone Parameter Sel Legitimate

```python
# Ekstrak parameter sel asli dulu (fase recon)
# Gunakan CellSearch untuk memetakan semua menara legitimate di area target

# Lalu konfigurasi rogue BTS dengan parameter IDENTIK:
rogue_config = {
    "earfcn": 6300,           # Sama dengan menara legitimate
    "cell_id": 123,           # CID sama (collision membingungkan scanner)
    "tac": 456,               # Sama Tracking Area Code
    "mcc": 310,               # Sama Mobile Country Code
    "mnc": 260,               # Sama Mobile Network Code
    "bandwidth": 10,          # Sama bandwidth (MHz)
    "pci": 42,                # Sama Physical Cell ID
}
```

**Kenapa bekerja:**
- CellSearch melihat CID sama di frekuensi sama → menganggap sektor yang sama
- FALCON melihat distribusi RNTI normal → tidak ada anomaly flag
- Adversary harus menggunakan signal strength differential untuk mendeteksi

**Counter-counter:** Antena directional + pemetaan signal strength mengungkap dua sumber pada freq/CID yang sama.

### Partial Parameter Spoofing

Daripada meng-clone semuanya, clone hanya field kritis dan variasi halus lainnya:

```python
# EARFCN sama, CID beda (terlihat seperti sektor baru)
# MCC/MNC sama, TAC beda (terlihat seperti roaming)
# PCI beda tapi frekuensi sama (terlihat seperti neighbor cell)
```

---

## 3. Teknik 2 — Power Management

### Transmit Power Budgeting

```
Sinyal menara legitimate di lokasi target: -85 dBm (khas)
Sinyal rogue BTS di lokasi target:       -95 dBm (10 dB di bawah)
    |
    v
Ponsel target tetap connect (roaming preference, forced handover)
SDR scanner 100m away: -105 dBm (di bawah noise floor, tak terdeteksi)
```

### Implementasi

```bash
# Kontrol power srsENB
srsenb --rf.tx_gain 30  # Alih-alih 80 (maks)
# Sesuaikan sampai ponsel target connect tapi scanner di 100m tidak melihat apa-apa
```

### Directional Transmission

- Gunakan antena directional (Yagi, panel) yang diarahkan HANYA ke target
- Beamwidth: 30–60 derajat
- Side lobes: -20 dB down
- Hasil: scanner di luar main lobe melihat sinyal -20 dB lebih lemah

```
        Scanner (undetected)
                                 Target  ←——[===]——→  (rogue BTS dengan antena directional)
    (connected)    |
              Side lobe: -20 dB
              Main lobe: 0 dB (diarahkan ke target)
```

---

## 4. Teknik 3 — Temporal Evasion (Burst Transmission)

### Pulsed Operation

```
Timeline:
0s     → Rogue BTS power ON
0.5s   → Ponsel target connect, IMSI tertangkap
1.0s   → Rogue BTS power OFF
60s    → Ulangi siklus

Total RF exposure: 1 detik per menit
Siklus scan CellSearch: 5-30 detik per band
Probabilitas deteksi: ~3%
```

### Event-Triggered Activation

```python
# Monitor koneksi legitimate ponsel target
# Saat target masuk geofence tertentu:
    # Power ON rogue BTS
    # Force handover (via power lebih tinggi atau fake paging)
    # Capture IMSI / intercept trafik
    # Power OFF setelah 30 detik
```

### Time-Division Evasion

Operasi hanya saat:
- **Rush hours** (beban jaringan tinggi, banyak sel, noise floor scanner naik)
- **Malam hari** (lebih kecil kemungkinan ada yang menjalankan CellSearch)
- **Saat cuaca buruk** (hujan melemahkan sinyal, jangkauan scanner berkurang)

---

## 5. Teknik 4 — Frequency Hopping & Band Avoidance

### Hindari Band yang Dimonitor

```python
# Pre-recon: Scan dengan RTL-SDR untuk menemukan apa yang dimonitor adversary
# Jika adversary scanning Band 2 (1900 MHz), operasikan di:
    # Band 28 (700 MHz) — penetrasi lebih rendah, lebih sulit dideteksi dari jarak
    # Band 40 (2300 MHz TDD) — scanner yang support TDD lebih jarang
    # Band unlicensed dengan LTE-U / LAA — gray area legal, tak terduga
```

### Dynamic Frequency Selection

```python
# Setiap 5 menit, ganti EARFCN
# Ponsel mengikuti via handover command
# Scanner harus rescan seluruh band setiap kali

earfcn_pool = [6300, 6400, 6500, 6600, 6700]  # Kanal valid yang dipilih
while operating:
    current_earfcn = random.choice(earfcn_pool)
    configure_bts(earfcn=current_earfcn)
    time.sleep(300)  # 5 menit dwell
```

---

## 6. Teknik 5 — RNTI Manipulation

### Masalahnya

FALCON menandai Stingray karena hanya menunjukkan **1–3 RNTI** vs **10–50** pada sel normal.

### Synthetic RNTI Injection

```python
# Generate RNTI palsu untuk mengisi histogram
# FALCON melihat 20-30 RNTI → menganggap sel normal

for i in range(25):
    fake_rnti = random.randint(0x0001, 0xFFF3)
    # Kirim fake DCI untuk RNTI ini
    # Alokasikan minimal resource block (1 RB masing-masing)
    # FALCON menghitungnya sebagai UE aktif
```

**Implementasi di srsENB:**

```cpp
// Patch MAC layer srsENB untuk inject DCI sintetis
// File: srsenb/src/stack/mac/mac.cc

void inject_fake_dcis() {
    for (int i = 0; i < 25; i++) {
        uint16_t fake_rnti = 0x0001 + (rand() % 0xFFF0);
        // Buat dummy DCI dengan alokasi 1 RB
        // Schedule di PDCCH
        // FALCON decode dan menghitung sebagai UE aktif
    }
}
```

### RNTI Rotation

```python
# Ganti RNTI UE target setiap 10 detik
# FALCON melihat churn RNTI konstan, tidak bisa melacak satu device
# Terlihat seperti area mobilitas tinggi (highway, stasiun kereta)
```

---

## 7. Teknik 6 — Protocol-Level Evasion

### Suppress SIB Broadcast

```python
# Sel legitimate broadcast SIB (System Information Blocks) setiap 80ms
# SIB berisi identitas sel, PLMN, tracking area
# Scanner menggunakan SIB untuk mengidentifikasi dan katalog sel

# Evasion: Disable broadcast SIB1/SIB2
# Hasil:
#   - CellSearch: mungkin melewatkan sel (tergantung deteksi sinyal sinkronisasi)
#   - Ponsel: tidak bisa camp tanpa SIB (tapi bisa via directed handover)
#   - FALCON: masih bisa decode PDCCH jika tersinkronisasi
```

### Encrypted Control Channel (Non-Standard)

```python
# LTE standar: PDCCH tidak dienkripsi (harus bisa didecode semua UE)
# Modifikasi non-standar: Encrypt PDCCH dengan shared key
#   - Hanya UE target (dengan key) yang bisa decode
#   - FALCON melihat PDCCH scrambled, tidak bisa ekstrak RNTI
#   - UE lain melihat garbage, mengabaikan sel

# PERINGATAN: Melanggar spesifikasi 3GPP. Ponsel mungkin tidak connect.
# Workaround: Ponsel target menjalankan firmware baseband modifikasi.
```

### Fake Handover Rejection

```python
# Saat ponsel adversary mencoba connect:
#   Kirim RRC Connection Reject dengan waitTime=16 detik
#   Ponsel adversary menunggu, retry
#   Setelah 3 penolakan, ponsel blacklist sel selama 300 detik
#   Hasil: adversary tidak bisa connect untuk analisis, tapi ponsel target (whitelist) bisa
```

---

## 8. Teknik 7 — Physical Security (Anti-Triangulation)

### Mobile Deployment

```
Rogue BTS berbasis kendaraan:
    - Melaju 30-50 km/jam di area target
    - Capture IMSI dalam window 10-20 detik
    - Tidak pernah diam cukup lama untuk triangulasi
    - Antena directional selalu diarahkan ke belakang (berlawanan arah laju)

Drone-mounted (eksperimental):
    - Ketinggian 100m
    - Hover 5 detik per target
    - Terbang sebelum scanner bisa mengunci arah
```

### Multi-Node Deception

```
Deploy 3 rogue BTS dalam formasi segitiga:
    BTS-A: Power tinggi, fake CID=100
    BTS-B: Power medium, fake CID=101
    BTS-C: Power rendah, fake CID=102 (target asli)

Scanner triangulasi BTS-A (sinyal terkuat)
    → Buang waktu di decoy
BTS-C capture target pada power rendah, tak terdeteksi
```

---

## 9. Teknik 8 — Spectrum Masking & Noise Floor Raising

### Broadband Noise Injection

```python
# Transmit white noise di 10-20 MHz band
# Menaikkan noise floor 10-15 dB
# Perhitungan SNR CellSearch terdegradasi
# Error rate blind decoding FALCON meningkat

# Gunakan RTL-SDR murah sebagai noise source:
#   rtl_sdr -f 1860e6 -s 20e6 - | transmit_noise.py
```

### Harmonic Interference

```python
# Transmit sinyal kuat pada harmonik LO scanner
# Menyebabkan intermodulation di front-end HackRF/RTL-SDR
# Scanner melihat ghost signals, tidak bisa membedakan nyata vs artefak
```

---

## 10. Teknik 9 — Counter-FALCON Specific

### CCE Allocation Randomization

```python
# FALCON menggunakan recursive shortcut decoding berdasarkan lokasi CCE (Control Channel Element)
# Randomize aggregation level dan starting position CCE setiap subframe
# Depth-first search FALCON menjadi computationally infeasible

# Di konfigurasi PDCCH:
pdcch_cce_randomization = True  # Non-standard, butuh modifikasi baseband
```

### DCI Format Obfuscation

```python
# FALCON mengharapkan format DCI standar (0, 1, 1A, 1C, 2, 2A, 3, 3A)
# Gunakan format DCI vendor-specific (non-standard)
# FALCON tidak bisa decode, menganggap noise
```

---

## 11. Teknik 10 — Detection of Detection

### Scanner Detection

```python
# Monitor untuk signature SDR:
#   - Wideband noise (20 MHz) dari HackRF
#   - Frequency hopping periodik (pola CellSearch)
#   - USB ID signature: 0x1d50:0x6089 (HackRF), 0x1d50:0x6108 (LimeSDR)

# Jika scanner terdeteksi:
#   1. Turunkan power ke minimum
#   2. Ganti frekuensi segera
#   3. Tunggu 30 menit
#   4. Resume di band berbeda
```

### RF Fingerprinting of Scanners

```python
# Setiap SDR memiliki RF fingerprint unik:
#   - Frekuensi/phase noise LO leakage
#   - I/Q imbalance
#   - DC offset
#
# Bangun database fingerprint scanner yang dikenal
# Deteksi scanner sebelum scanner mendeteksi Anda
```

---

## 12. Complete Evasion Configuration

```ini
# Konfigurasi srsENB yang dioptimalkan untuk evasion
[rf]
dl_earfcn = 6300              # Match sel legitimate
tx_gain = 35                  # 10 dB di bawah tipikal (-95 dBm di 100m)
rx_gain = 40

[enb]
cell_id = 123                 # Clone CID legitimate
tac = 456                     # Clone TAC legitimate
mcc = 310
mnc = 260
pci = 42                      # Clone PCI legitimate
bandwidth = 10                # Match

[expert]
# Patch non-standard:
inject_fake_rntis = 25        # Populasi histogram FALCON
rnti_rotation_interval = 10   # Detik
sib_broadcast = false         # Suppress SIB (stealth mode)
cce_randomization = true      # Counter shortcut decoding FALCON
dci_format = "vendor_custom"  # Obfuscate control channel

[evasion]
burst_duration = 1.0          # Detik ON
burst_interval = 60.0         # Detik OFF
directional_antenna = true
beamwidth = 30                # Derajat
scanner_detection = true      # Auto-shutdown jika scanner terdeteksi
```

---

## 13. Blue Team Counters

Jika Anda mencurigai teknik evasion:

| Teknik Evasion | Counter-Measure |
|----------------|-----------------|
| Spectral blending | Antena directional + pemetaan signal strength multi-titik |
| Power management | Mendekat, gunakan antena gain lebih tinggi (parabolic, 24 dBi) |
| Burst transmission | Continuous monitoring dengan SDR (tanpa scanning, always-on) |
| Frequency hopping | Parallel multi-band monitoring (3+ SDR) |
| RNTI injection | Analisis pola perilaku RNTI (fake RNTI punya alokasi seragam) |
| SIB suppression | Deteksi via sinyal sinkronisasi PSS/SSS saja (tanpa SIB) |
| CCE randomization | Brute-force semua lokasi CCE (computationally expensive) |
| Mobile deployment | Stasiun monitoring tetap + unit mobile |

---

## 14. Kerangka Legal

- **Mengoperasikan rogue BTS** ilegal di hampir semua yurisdiksi (FCC Part 15, regulasi ITU, hukum telekomunikasi nasional)
- **IMSI catching tanpa warrant** melanggar hukum privasi dan regulasi telekomunikasi
- **Jamming/interference** adalah felony terpisah di kebanyakan negara
- Panduan ini untuk **riset defensif, red-teaming, dan memahami kemampuan adversary**

---

## 15. Referensi

1. FALCON paper: *FALCON: An Accurate Real-time Monitor for Client-based Mobile Traffic* — https://arxiv.org/pdf/1907.10110
2. FALCON GitHub — https://github.com/falkenber9/falcon
3. LTE-Cell-Scanner GitHub — https://github.com/JiaoXianjun/LTE-Cell-Scanner
4. srsRAN Project — https://github.com/srsran/srsRAN
5. EFF. *Stingray: The Most Common Cell Phone Surveillance Device* (2019)
6. ACLU. *Stingray Tracking Devices: Who's Got Them?* (2018)
7. 3GPP TS 33.102 — *Security Architecture for 3G/4G/5G*
8. FCC Part 15 — *Regulasi emisi RF di AS*
9. Karsten Nohl et al. *A5/1 Cracking and GSM Security* — https://srlabs.de

---

## 16. Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[sdr-cell-tower-stingray-detection]] | Sisi deteksi — pipeline SDR yang digunakan blue team; catatan ini adalah sisi evasion/counter-reconnaissance |
| [[imsi-catcher]] | Teori & arsitektur IMSI catcher/Stingray — konteks perangkat yang teknik evasion-nya dibahas di sini |
| [[hierarchy-wireless]] | Peta hierarki spektrum nirkabel — tier tactical SDR |
| [[wireless-security-deepdive]] | Fundamental keamanan wireless + serangan berbasis SDR |
| [[hierarchy-osint-rf]] | OSINT & RF signal hierarchy — konteks SIGINT |
| [[military-sigint-deepdive]] | SIGINT militer — perspektif taktis counter-reconnaissance |
