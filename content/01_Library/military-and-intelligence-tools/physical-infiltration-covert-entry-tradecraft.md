---
tags:
  [
    physical-security,
    covert-entry,
    lock-picking,
    rfid-cloning,
    tailgating,
    hardware-implant,
    tradecraft,
    access-control,
  ]
aliases: [PICT, Physical Infiltration, Covert Entry Deep Dive]
status: complete
created: 2026-07-31
updated: 2026-07-31
cssclasses: [wide-table, math-render]
---

> [!abstract] Physical Infiltration & Covert Entry Tradecraft
> Dunia digital tidak ada tanpa dunia fisik. Server berada di data center, kunci API disimpan di laptop, dan manusia adalah Layer 8 dari setiap stack keamanan. Catatan ini mendokumentasikan teknik covert entry dari perspektif operational security: lock picking mekanik, RFID/NFC cloning, tailgating & piggybacking, hardware implant (bug GSM, keylogger), dan building access control bypass (magstripe, Wiegand, OSDP). Setiap teknik disertai formula mekanik, perhitungan probabilitas, dan proof-of-concept.

---

## Daftar Isi

1. [[#1. Lock Picking — Mekanik Pin Tumbler, Wafer, Dimple]]
2. [[#2. RFID & NFC Cloning — Proxmark3, MIFARE, DESFire]]
3. [[#3. Tailgating & Piggybacking — Social Engineering Fisik]]
4. [[#4. Hardware Implant — Bug GSM, Keylogger USB/PS2, O.MG Cable]]
5. [[#5. Building Access Control Bypass — Magstripe, Wiegand, OSDP]]
6. [[#6. Physical Security Assessment Framework]]
7. [[#7. Countermeasures & Detection]]
8. [[#8. References]]

---

## 1. Lock Picking — Mekanik Pin Tumbler, Wafer, Dimple

### 1.1 Pin Tumbler Lock — Mekanika

Kunci pin tumbler menggunakan **shear line** sebagai mekanisme keamanan. Silinder (plug) berisi keyway; setiap pin stack terdiri dari **driver pin** (atas, spring-loaded) dan **key pin** (bawah, sesuai biting kunci).

**Kondisi terkunci:**

```
Setiap pin stack: key_pin[i] + driver_pin[i] = total_height[i]
Shear line: batas antara plug dan housing
Terkunci: setidaknya satu pin memiliki shear line yang tidak rata (misaligned)
```

**Kondisi terbuka:**

```
Semua pin stack memiliki shear line yang rata (aligned)
Plug bisa berputar bebas
```

**Matematika shear line:**

```
Let H_i = total height pin stack ke-i
Let K_i = height key pin ke-i (ditentukan oleh biting kunci)
Let D_i = height driver pin ke-i

H_i = K_i + D_i  (constant per stack)

Shear line aligned jika: K_i = biting[i] (kunci benar)
Atau saat picking: K_i terangkat oleh pick ke posisi shear line
```

### 1.2 Single Pin Picking (SPP) — Binding Order

Pin tidak semua terkunci secara merata. **Binding order** adalah urutan pin yang terkunci paling keras ke paling ringan, ditentukan oleh toleransi manufaktur.

**Probabilitas binding order random:**

```
Untuk lock dengan n pin stacks:
Jumlah kemungkinan binding order = n!

Untuk 5-pin lock: 5! = 120 kemungkinan
Untuk 6-pin lock: 6! = 720 kemungkinan
```

**Waktu rata-rata SPP (experienced picker):**

```
T_SPP ≈ binding_order_discovery + pin_setting_time
        ≈ 30s (5-pin standard) sampai 5 menit (high-security)
```

### 1.3 Raking — Probabilistik Attack

Raking menggunakan pick dengan profil bergigi (bogota, city, snake) untuk mengangkat multiple pin secara simultan dengan gerakan cepat.

**Probabilitas sukses raking:**

```
P(success | raking, n pins, standard toleransi) ≈ 0.15-0.40
P(success | raking, n pins, tight toleransi) ≈ 0.02-0.10
```

**Formula probabilitas:**

```
P = Π P(pin_i aligned | raking motion)

Untuk gerakan sinusoidal: P(pin_i aligned) = f(amplitude, frequency, pin spacing)
```

### 1.4 Bumping — Energy Transfer

Bump key memiliki semua biting di posisi maksimum (9), dengan sedikit material yang dihapus di shoulder untuk memungkinkan impact.

**Fisika bumping:**

```
E_impact = 0.5 · m_hammer · v²
E_transfer = η · E_impact  (η ≈ 0.3-0.6 untuk metal-on-metal)

Driver pin menerima impulse: F·Δt = Δp
Driver pin terangkat: h = (v_driver²) / (2g)

Target: h > K_i (key pin height) → driver pin terangkat di atas shear line
```

**Probabilitas sukses bumping:**

```
P(success | bumping, 5-pin, standard) ≈ 0.70-0.90
P(success | bumping, security pins) ≈ 0.10-0.30
```

### 1.5 Security Pins — Spool, Serrated, Mushroom

Security pins dirancang untuk **false set** — picker merasa pin sudah di posisi benar, padahal belum.

**Spool pin:**

```
Profil: hourglass (lebar di tengah, sempit di ujung)
Mekanisme: saat di shear line, spool "tersangkut" di housing
          → plug bisa berputar sedikit (false set)
          → picker harus mengangkat sedikit lebih untuk melewati spool
```

**Serrated pin:**

```
Profil: multiple ridges kecil
Mekanisme: setiap ridge bisa memberikan "click" palsu
          → picker harus merasakan perbedaan click valid vs invalid
```

**Counter-picking formula:**

```
T_pick(security_pins) = T_pick(standard) × (1 + α·n_security)
α ≈ 0.5-1.0 (penalti per security pin)

Untuk 5-pin dengan 3 spool: T ≈ 2.5× T_standard
```

### 1.6 Wafer Lock — Automotive & Furniture

Wafer lock menggunakan **flat wafers** (bukan pin silinder). Setiap wafer memiliki slot yang harus align dengan shear line.

**Matematika wafer:**

```
N wafers, masing-masing dengan 2 posisi possible (left/right slot)
Kombinasi kunci: m^N (m = jumlah biting height)

Untuk wafer lock mobil (N=8, m=4): 4^8 = 65,536 kombinasi
Brute force dengan Lishi 2-in-1: ~2 menit
```

### 1.7 Dimple Lock — Mul-T-Lock, Abloy

Dimple lock menggunakan **horizontal key** dengan dimple (lekukan) di berbagai depth dan posisi horizontal.

**Parameter:**

```
N rows × M columns = total pin positions
Depth levels per pin: D
Kombinasi teoritis: D^(N×M)

Mul-T-Lock Classic: 5 rows × 2 columns × 5 depth = 5^10 = 9,765,625
Abloy Protec2: rotating disc, 11 discs × 2 posisi = 2^11 = 2,048 (tapi mekanisme berbeda)
```

---

## 2. RFID & NFC Cloning — Proxmark3, MIFARE, DESFire

### 2.1 RFID Frequency Bands

| Band |  Frekuensi  | Range  | Aplikasi                          |
| :--- | :---------: | :----: | :-------------------------------- |
| LF   | 125-134 kHz | <10 cm | Access control (HID Prox, EM4100) |
| HF   |  13.56 MHz  |  <1 m  | NFC, MIFARE, DESFire, payment     |
| UHF  | 860-960 MHz | 1-12 m | Supply chain, asset tracking      |

### 2.2 Proxmark3 — Swiss Army Knife RFID

Proxmark3 adalah SDR (Software Defined Radio) khusus RFID dengan:

```
FPGA: real-time signal processing
ARM MCU: protocol handling
Antenna: tuneable 125kHz / 13.56MHz
```

**Komando Proxmark3 untuk HID Prox:**

```
lf search          → auto-detect tag type
lf hid read        → read raw Wiegand data
lf hid sim raw     → simulate tag
lf hid clone       → write to T5577 (rewritable LF tag)
```

### 2.3 MIFARE Classic — Crypto1 Broken

MIFARE Classic menggunakan **Crypto1 stream cipher** (48-bit state). Dibobol oleh Nohl (2008) dan Garcia (2009).

**Crypto1 weakness:**

```
State: 48-bit LFSR
Output: 1 bit per clock (keystream)
Keystream dipakai untuk XOR plaintext

Attack: known-plaintext → recover keystream → reverse LFSR → recover key
```

**Nested Authentication Attack:**

```
1. Baca sector trailer (known key A/B untuk sector 0)
2. Autentikasi ke sector 0 → sniffer capture nonce + keystream
3. Gunakan known keystream untuk derive key untuk sector lain
4. Complexity: O(2^16) per sector → ~1 detik di Proxmark3
```

**Darkside Attack (for unknown keys):**

```
1. Kirim autentikasi dengan key random
2. Card response dengan encrypted nonce (4 bytes)
3. Collect banyak responses untuk statistical analysis
4. Recover key dengan parity leak
5. Complexity: O(2^32) → ~10 menit di Proxmark3
```

### 2.4 MIFARE DESFire — AES-128/3DES

DESFire EV2/EV3 menggunakan **AES-128** atau **3DES** dengan:

```
Mutual authentication (challenge-response)
Session keys (unique per session)
Secure messaging (encrypted + MAC)
```

**Security level:**

```
P(break DESFire AES-128) ≈ 2^-128 (computationally infeasible)
P(side-channel | power analysis) ≈ 2^-40 (dengan equipment lab)
```

**Tapi:** DESFire sering di-deploy dengan **default key** (0x00...00) atau **weak diversification**.

### 2.5 NFC Payment Cloning — Contactless Skimming

**Skimming range HF (13.56MHz):**

```
Theoretical max: λ/2π ≈ 3.5m (tapi praktis <10cm untuk NFC)
Dengan antenna besar + amplifier: ~30-50cm
Dengan relay attack: unlimited range
```

**Relay Attack:**

```
Alice (korban) → Reader (legitimate POS)
            ↕
      Relay device (Mole 1) ←→ Relay device (Mole 2, near POS)
            ↕
            Reader (POS) → thinks Alice is present
```

**Waktu round-trip maksimum untuk relay:**

```
NFC timeout: 5ms (ISO 14443)
Max relay distance: c × 5ms / 2 ≈ 750km (theoretical)
Practical dengan latency < 2ms: ~300km
```

### 2.6 Cloning Hardware Cost

| Tag Type            |  Reader/Cloner Cost   |  Clone Time  | Difficulty |
| :------------------ | :-------------------: | :----------: | :--------: |
| EM4100 (LF)         |   $5 (T5577 writer)   |      2s      |  Trivial   |
| HID Prox (LF)       | $30 (Proxmark3 Easy)  |      5s      |    Easy    |
| MIFARE Classic (HF) |    $60 (Proxmark3)    |      1s      |    Easy    |
| MIFARE DESFire (HF) | $300 (Proxmark3 RDV4) | N/A (secure) |    Hard    |
| iCLASS (HF)         |    $60 (Proxmark3)    |     30s      |   Medium   |
| Legic Prime (HF)    |  $200 (specialized)   |     10s      |   Medium   |

---

## 3. Tailgating & Piggybacking — Social Engineering Fisik

### 3.1 Model Threat

Access control mekanik (pintu, turnstile) dirancang untuk **single entry per credential**. Tailgating adalah eksploitasi terhadap asumsi ini.

**Probabilitas sukses tailgating:**

```
P(success) = P(victim holds door) × P(no challenge) × P(no guard)

Faktor yang meningkatkan P:
- Waktu sibuk (rush hour): P(victim holds door) ≈ 0.85
- Korporate culture (politeness): P(no challenge) ≈ 0.70
- Guard absence: P(no guard) ≈ 0.60

P(total) ≈ 0.85 × 0.70 × 0.60 ≈ 0.36 (36% per attempt)
```

### 3.2 Teknik Tailgating

**1. The Coffee Tray:**

```
Attacker membawa tray kopi (atau kotak besar)
→ Tangan tidak bisa mengakses badge
→ Victim secara otomatis menahan pintu
→ "Thanks!"
```

**2. The Smoker's Exit:**

```
Designated smoking area di luar building
→ Smoker keluar setiap 1-2 jam
→ Door tidak fully close (atau smoker hold door untuk re-entry)
→ Attacker menyusul
```

**3. The Delivery Person:**

```
Attacker mengenakan uniform delivery (UPS, FedEx, pizza)
→ Carrying large package
→ "Can you help me with the door?"
→ P(success) ≈ 0.90 di korporat
```

### 3.3 Piggybacking vs Tailgating

| Aspek             | Tailgating | Piggybacking                |
| :---------------- | :--------- | :-------------------------- |
| Relasi            | Stranger   | Known/Authorized            |
| Intent victim     | Unaware    | Aware (socially engineered) |
| Detection         | Hard       | Harder (victim complicit)   |
| Legal implication | Trespass   | Conspiracy                  |

### 3.4 Mantrap & Anti-Tailgating

**Mantrap (security vestibule):**

```
Pintu A → Ruang kecil (1 orang) → Pintu B
Sensor: weight, IR, video analytics
Jika >1 orang terdeteksi: lockdown kedua pintu
```

**Probabilitas bypass mantrap:**

```
P(bypass) = P(sensor failure) + P(social engineering guard)
          ≈ 0.05 + 0.15 = 0.20

Tapi dengan tailgating detection AI (computer vision):
P(bypass) ≈ 0.02-0.05
```

---

## 4. Hardware Implant — Bug GSM, Keylogger USB/PS2, O.MG Cable

### 4.1 Bug GSM — Audio Surveillance

**Komponen:**

```
GSM module (SIM800L, A6): $3-5
Microphone electret: $0.50
LiPo battery 500mAh: $2
PCB custom: $1
Total BOM: ~$7
```

**Operasional:**

```
1. Implant disembunyikan di ruangan target
2. Dial ke nomor SIM card → auto-answer
3. Audio streaming via GSM voice channel
4. Battery life: ~24-72 jam (depends on call duration)
```

**Deteksi:**

```
RF detector (wideband): $50-200
Sweeper frequency 800-1900MHz
Signal strength: -60dBm (nearby) to -90dBm (distant)
```

### 4.2 Keylogger USB — Hardware

**USB Keylogger (inline):**

```
Form factor: USB-A male → USB-A female (dongle)
Storage: 2-16MB flash
Logging: semua keystroke via USB HID protocol
Retrieval: physical access + key combination
```

**Protocol USB HID:**

```
Report ID: 1 byte
Modifier keys: 1 byte (Ctrl, Shift, Alt, GUI)
Reserved: 1 byte
Keycodes: 6 bytes (up to 6 simultaneous keys)
```

**Keylogger intercept:**

```
USB Host → Keylogger MCU → USB Device (keyboard)
MCU sniff semua IN transfers (keyboard → host)
Data disimpan di flash internal
```

### 4.3 O.MG Cable — Covert Implant

O.MG Cable adalah kabel USB/Lightning yang terlihat identik dengan kabel asli, tapi berisi:

```
WiFi MCU (ESP8266): hidden AP
Payload injection: keystroke injection via USB HID
Geofencing: aktif hanya di area tertentu
Remote trigger: via WiFi
```

**Attack vector:**

```
1. Attacker swap kabel korban dengan O.MG Cable
2. Korban plug ke laptop → O.MG Cable terdaftar sebagai HID device
3. Attacker connect ke hidden AP
4. Remote keystroke injection:
   - Open terminal
   - Download payload
   - Execute
   - Clear history
```

**Deteksi:**

```
USBDeview: cek vendor ID yang tidak dikenal
Physical inspection: O.MG Cable sedikit lebih tebal (tapi hampir identik)
Cost: $120-200 per kabel
```

### 4.4 LAN Turtle / Packet Squirrel — Network Implant

**LAN Turtle:**

```
Form factor: USB stick (tapi Ethernet passthrough)
OS: OpenWrt
Capability: MITM, DNS spoofing, reverse shell, VPN tunnel
Power: dari port USB host atau PoE
```

**Deployment:**

```
1. Attacker colok LAN Turtle ke switch/printer/komputer
2. Ethernet passthrough: network tetap jalan
3. Attacker dapat remote access via VPN/SSH
4. Persistence: auto-start script di OpenWrt
```

---

## 5. Building Access Control Bypass — Magstripe, Wiegand, OSDP

### 5.1 Magstripe Cards — ISO/IEC 7811

**Track format:**

```
Track 1: IATA (79 chars, 7-bit + parity)
Track 2: ABA (40 chars, 5-bit + parity)
Track 3: Thrift (107 chars, 5-bit + parity)
```

**Data encoding:**

```
F2F (Aiken Biphase): 1 = flux reversal di tengah bit cell
                     0 = flux reversal di edge bit cell
Clock: ~210 bpi (bits per inch)
```

**Skimming:**

```
Magstripe reader (MSR605): $150
Read all 3 tracks
Clone ke blank card: 5 detik
```

### 5.2 Wiegand Protocol — Raw Data

Wiegand adalah **unencrypted serial protocol** antara card reader dan controller.

**Wiegand 26 (most common):**

```
Format: 26 bits total
  Bit 1: Even parity (first 12 bits)
  Bits 2-13: Facility code (12 bits, 0-4095)
  Bits 14-25: Card number (12 bits, 0-4095)
  Bit 26: Odd parity (last 12 bits)
```

**Sniffing Wiegand:**

```
Wiegand menggunakan 2 data lines: D0 (logic 0) dan D1 (logic 1)
Pulse width: 20-100 μs
Inter-bit gap: 200-2000 μs

Sniffer: logic analyzer atau Arduino
Connect ke D0/D1 lines (di belakang reader)
```

**Protokol tidak ada encryption:**

```
Data transmitted in plaintext
Replay attack: capture → replay ke controller
P(success | replay) = 1.0 (jika tidak ada timestamp check)
```

### 5.3 OSDP (Open Supervised Device Protocol) — Encrypted

OSDP adalah **encrypted replacement** untuk Wiegand:

```
Physical layer: RS-485 (2-wire differential)
Protocol: master-slave polling
Security: AES-128 encryption + Secure Channel
Features: device authentication, integrity check, tamper detection
```

**OSDP Secure Channel handshake:**

```
1. PD (peripheral device) sends CHLNG (8-byte random)
2. CP (control panel) responds dengan SCRYPT (encrypted response)
3. Mutual authentication via AES-128-CMAC
4. Session key derived untuk enkripsi selanjutnya
```

**Bypass OSDP:**

```
P(bypass | OSDP with Secure Channel) ≈ 2^-128 (infeasible)
P(bypass | OSDP without Secure Channel) ≈ 1.0 (same as Wiegand)

Real-world: banyak installasi OSDP tidak enable Secure Channel
```

### 5.4 Controller-Level Attack

**HID VertX / Edge Controller:**

```
Default credential: admin/admin atau root/hid
Web interface: HTTP (not HTTPS)
API: undocumented, tapi bisa di-reverse
```

**Attack:**

```
1. Scan network untuk HID controller
2. Coba default credentials
3. Jika masuk: add new card, grant access, download card database
4. Delete access log
```

---

## 6. Physical Security Assessment Framework

### 6.1 DREAD untuk Physical Security

| Factor          | Formula                | Skala                     |
| :-------------- | :--------------------- | :------------------------ |
| Damage          | Impact × Asset value   | 0-10                      |
| Reproducibility | P(success per attempt) | 0-10                      |
| Exploitability  | Skill + Tool + Time    | Level Rating / Kejarangan | 0-10 |
| Affected users  | Number of people       | 0-10                      |
| Discoverability | P(detection)           | 0-10                      |

**Risk Score:**

```
DREAD = (D + R + E + A + Dd) / 5

High risk: >7
Medium: 4-7
Low: <4
```

### 6.2 Layered Physical Security

```
Layer 1: Perimeter (fence, gate, CCTV)
Layer 2: Building exterior (doors, windows, roof)
Layer 3: Lobby/entrance (reception, mantrap, badge)
Layer 4: Internal zones (elevator access, floor locks)
Layer 5: Secure areas (server room, vault, SCIF)
Layer 6: Asset (cable lock, tamper-evident seal)
```

**Bypass cost per layer:**

```
C_total = C_layer1 + C_layer2 + ... + C_layerN
Dengan N=6: C_total ≈ 50× C_single_layer
```

---

## 7. Countermeasures & Detection

### 7.1 Anti-Cloning

| Threat         | Countermeasure                     | Efektivitas |
| :------------- | :--------------------------------- | :---------: |
| RFID cloning   | MIFARE DESFire + rolling code      |     95%     |
| Magstripe skim | EMV chip + PIN                     |     99%     |
| Tailgating     | Mantrap + AI vision                |     90%     |
| Keylogger      | USB port lock + regular inspection |     80%     |
| Wiegand sniff  | OSDP with Secure Channel           |     95%     |

### 7.2 TSCM (Technical Surveillance Counter-Measures)

**Equipment:**

```
NLJD (Non-Linear Junction Detector): $5,000-15,000
  → Deteksi semiconductor (bug, keylogger) di dinding/furniture

Spectrum Analyzer: $10,000-50,000
  → Deteksi RF transmission (GSM, WiFi, Bluetooth)

Thermal Camera: $3,000-8,000
  → Deteksi heat signature dari active device

X-Ray: $20,000+
  → Visual inspection tanpa destructive analysis
```

---

## 8. References

1. Tobias, M. W. (2003). _Locks, Safes and Security: An International Police Reference_ (2nd ed.). Charles C Thomas. — Comprehensive lock mechanism reference.

2. Nohl, K., & Plotz, H. (2007). "MIFARE: Little Security, Despite Obscurity." _24th Chaos Communication Congress_. — Crypto1 analysis.

3. Garcia, F. D., de Koning Gans, G., Muijrers, R., van Rossum, P., Verdult, R., Schreur, R. W., & Jacobs, B. (2008). "Dismantling MIFARE Classic." _ESORICS 2008_. — Nested & darkside attacks.

4. Verdult, R. (2015). "The (in)security of Proprietary Cryptography." _PhD Thesis, Radboud University_. — Proxmark3 & RFID security.

5. OS2I. (2020). _OSDP Secure Channel Implementation Guide_. SIA. — OSDP protocol deep dive.

6. Grunwald, L. (2017). _The Hacker's Hardware Toolkit_. No Starch Press. — Hardware implant & SDR.

7. Kuhn, M. G., & Anderson, R. J. (1998). "Soft Tempest: Hidden Data Transmission Using Electromagnetic Emanations." _Information Hiding_. — TEMPEST & side-channel.

8. Mitnick, K. D., & Simon, W. L. (2002). _The Art of Deception_. Wiley. — Social engineering & tailgating.

## Koneksi ke Vault

| Catatan                       | Koneksi                                                    |
| :---------------------------- | :--------------------------------------------------------- |
| [[endpoint-security]]         | Physical access = initial vector untuk endpoint compromise |
| [[hardware-hacking-re]]       | RFID/NFC adalah hardware hacking domain                    |
| [[network-security]]          | LAN Turtle = network layer attack                          |
| [[osint-resource-index]]      | Physical reconnaissance adalah OSINT operational           |
| [[digital-privacy-anonymity]] | Counter-surveillance melindungi dari physical tracking     |
