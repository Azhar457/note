---
title: Attack Perspective — Embedded Systems (Red Team)
tags: [attack,red-team,embedded,iot,rtos,safety-critical,firmware]
source: hierarchy-embedded-systems.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Embedded Systems — Perspektif Penyerang

> Embedded system = IoT, RTOS, sensor, actuator, safety-critical (IEC 61508). Red team serang: firmware extraction, hardcoded creds, physical debug, RTOS exploit, OTA hijack.

## 1. Attack Surface Embedded

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **Firmware** | Dump SPI flash → hardcoded creds → modify | T1602 | CH341A, flashrom, binwalk | No detection — physical access | Firmware audit jarang |
| **RTOS** | Memory corruption, task overflow, privilege task hijack | T1068 | GDB + JTAG, custom exploit | RTOS = no ASLR, no DEP, real-time | RTOS monitoring = rare |
| **OTA Update** | Hijack update server → malicious firmware push | T1195 | Custom update server, DNS hijack | Signed binary (weak signing atau no verify) | Signature verification jarang enforced |
| **Physical Debug** | UART → root shell, JTAG → memory read/write | T1542 | FT232, JLink, OpenOCD | No detection — physical interface | Physical security audit jarang |
| **Sensor Spoof** | Inject false data → system reaction | T1557 | SDR, hardware bridge, analog inject | Active — but device tidak tahu sensor = fake | Sensor validation jarang |
| **Network (IoT)** | Telnet/SSH default creds, UPnP abuse, MQTT no-auth | T1078 | nmap, metasploit, mqtt enumeration | Default creds = legit login attempt | IoT logging = minimal atau tidak ada |
| **Safety-Critical** | Fault injection → bypass safety check (IEC 61508) | T1542 | ChipWhisperer, voltage glitch | Glitch = transient, no persistent artifact | Safety system tidak expect cyber attack |

## 2. IoT Attack Chain

```
Recon: Shodan/Censys → exposed IoT (port 23 Telnet, 1883 MQTT, 8883 MQTTS, 80 web)
 ↓
Network: Default creds (admin:admin, root:root, support:support)
 ├── Ya → shell → dump firmware → pivot
 └── Tidak → web exploit (RCE via CGI, command injection)
 ↓
Firmware: SPI flash dump (CH341A) atau vendor download
 ↓
Extraction: binwalk → filesystem → hardcoded creds, API keys, certs, source code
 ↓
Modifikasi: Add backdoor, remove auth, add C2 → reflash
 ↓
OTA Hijack: DNS hijack → fake update server → push malicious firmware
 ↓
Botnet:_DEVICE → recruit ke botnet (Mirai, Mozi) → DDoS / crypto mine
```

## 3. RTOS Exploit (Real-Time Operating System)

| RTOS | Vulnerability | Attack |
|------|-------------|--------|
| **FreeRTOS** | TCP/IP stack buffer overflow (CVE-2021-31500) | RCE via crafted TCP packet |
| **Zephyr RTOS** | Memory protection bypass (no MMU) | Task overflow → kernel corrupt |
| **VxWorks** | Debug service exposed (CVE-2019-12256) | RCE via IP fragmentation |
| **ThreadX** | Default wireless stack vulnerability | WiFi exploit → code execution |
| **NuttX** | Stack buffer overflow (no stack canary) | Classic stack overflow → RCE |

## 4. Safety-Critical Attack (IEC 61508)

| Safety Level | Target | Attack | Impact |
|-------------|--------|--------|--------|
| **SIL 1** | Basic sensor | Spoof sensor data → false reading | Minor — system tolerates |
| **SIL 2** | Industrial controller (PLC) | Modbus inject → override setpoint | Process deviation |
| **SIL 3** | Medical device (insulin pump) | Bluetooth exploit → overdose | Injury or death |
| **SIL 4** | Nuclear/avionics | Fault injection → bypass interlock | Catastrophic — but extremely hard |

## 5. Tool Stack Embedded

| Tool | Use | Harga |
|------|-----|-------|
| **CH341A + SOIC8 clip** | SPI flash read/write | $5 |
| **FT232 / CP2102** | UART debug | $3 |
| **JLink / ST-Link** | JTAG/SWD debug | $20 (clone) |
| **binwalk** | Firmware extraction | Free |
| **flashrom** | SPI flash tool | Free |
| **OpenOCD** | JTAG debug | Free |
| **Slipstream** | OTA firmware modification | Free |
| **Bettercap** | BLE/IoT MITM | Free |

## 6. Referensi
- binwalk — https://github.com/ReFirmLabs/binwalk
- flashrom — https://flashrom.org/
- FreeRTOS TCP/IP CVE — https://nvd.nist.gov/vuln/detail/CVE-2021-31500
- VxWorks Vulnerability — https://www.armis.com/vxrisk/
- IEC 61508 — https://www.iec.ch/standards/