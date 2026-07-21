---
title: Edge Computing & IoT Security Architecture
tags:
- iot
- edge-computing
- embedded-security
- iot-architecture
- ot-security
- library
aliases:
- iot-security-edge-deepdive
- edge-computing-architecture-tiers
- ot-industrial-iot-security
created: '2026-07-15'
updated: '2026-07-15'
status: draft
cssclasses:
- wide-table
---

# ⚙️ Edge Computing & IoT Security Architecture

> Vault punya [[embodied-ai-robotics]] yang fokus ke robotics + AI di edge, dan [[wireless-security-deepdive]] yang bahas RF attacks (Zigbee, BLE, WiFi). Tapi belum ada yang ngejembatin antara **IoT device fisik, edge gateway, dan cloud backend** dari sudut pandang arsitektur dan security. Catatan ini bahas edge computing secara vertikal: dari sensor constrained (ESP32, nRF52) yang jalan di baterai selama setahun, sampe edge gateway (Jetson, Raspberry Pi) yang jalanin ML inference, sampe cloud backend yang aggregate data. Setiap tier punya attack surface sendiri-sendiri — firmware signing, secure boot, OTA update, network segmentation buat OT/IIoT, dan supply chain security.

> [!info] Posisi di Vault
> Ini adalah **jembatan** antara [[embodied-ai-robotics]] (robotics AI), [[wireless-security-deepdive]] (RF communication), [[firmware-reverse-engineering-deepdive]] (firmware security), [[autonomous-system-design]] (autonomous systems), dan [[container-kubernetes-security-deepdive]] (cloud backend). Baca ini setelah paham dasar networking [[networking-fundamentals-tcpip-bgp]] dan sebelum mendalami hardware hacking [[hardware-hacking-re]].

---

## Daftar Isi

- [[#1. Edge Computing Arsitektur — 3 Tier]]
- [[#2. Tier 1 — Constrained Devices (Sensors & Actuators)]]
- [[#3. Tier 2 — Edge Gateway]]
- [[#4. Tier 3 — Cloud / Data Center]]
- [[#5. IoT Communication Protocols]]
- [[#6. Firmware Security — Secure Boot & Signing]]
- [[#7. OTA Update Security]]
- [[#8. Network Segmentation untuk IIoT/OT]]
- [[#9. Edge AI — Inferensi di Edge]]
- [[#10. Supply Chain Security untuk IoT]]
- [[#11. Perbandingan Platform Edge Computing]]
- [[#🔗 Koneksi ke Catatan Lain]]
- [[#✅ Checklist]]
- [[#Roadmap Belajar]]

---

## 1. Edge Computing Arsitektur — 3 Tier

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: CLOUD / DATA CENTER                                    │
│                                                                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                │
│  │ ML Ops  │ │ Data    │ │ Dashboard│ │ API     │                │
│  │ Training│ │ Lake    │ │ Grafana  │ │ Gateway │                │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘                │
│         ▲           ▲           ▲           ▲                     │
│         │           │           │           │                     │
│  ┌──────┴───────────┴───────────┴───────────┴──────┐              │
│  │     Cloud Ingress (Load Balancer, WAF, mTLS)    │              │
│  └───────────────────────┬─────────────────────────┘              │
│                          │ WAN (4G/5G/Satellite)                  │
├──────────────────────────┼──────────────────────────────────────┤
│  TIER 2: EDGE GATEWAY    │                                       │
│                          │                                       │
│  ┌───────────────────────▼─────────────────────────┐              │
│  │  Edge Gateway                                   │              │
│  │  ├── MQTT Broker (Mosquitto/NanoMQ)             │              │
│  │  ├── Local Processing (Python/Rust)              │              │
│  │  ├── AI Inference (ONNX/TensorRT)                │              │
│  │  ├── Data Buffer (SQLite/RocksDB)                │              │
│  │  └── OTA Manager                                 │              │
│  └───────────────────────┬─────────────────────────┘              │
│                          │ LAN (Zigbee/BLE/WiFi)                  │
├──────────────────────────┼──────────────────────────────────────┤
│  TIER 1: CONSTRAINED     │                                       │
│                          │                                       │
│  ┌──────┐ ┌──────┐ ┌────▼───┐ ┌──────┐ ┌──────┐                │
│  │Sensor│ │Sensor│ │Sensor  │ │Sensor│ │Sensor│                │
│  │Temp  │ │Humid │ │Motion  │ │Gas   │ │Vibration│             │
│  └──────┘ └──────┘ └────────┘ └──────┘ └────────┘               │
│                                                                  │
│  Microcontroller-based (ESP32, nRF52, STM32)                     │
│  Battery-powered, sleep-cycle, constrained (KB memory)           │
└─────────────────────────────────────────────────────────────────┘
```

**Data flow:**
1. Sensor → MQTT/CoAP → Edge Gateway (LAN)
2. Edge Gateway → MQTT/TLS → Cloud (WAN, periodic)
3. Cloud → OTA update → Edge Gateway → sensor firmware update

### 1.1 Karakteristik Tiap Tier

| Aspek | Tier 1 — Sensors | Tier 2 — Gateway | Tier 3 — Cloud |
|-------|-----------------|------------------|----------------|
| Hardware | ESP32, nRF52, STM32 | RPi, Jetson, x86 | VM, K8s cluster |
| OS | RTOS (FreeRTOS, Zephyr) | Linux (Yocto, Ubuntu) | Linux, server-grade |
| Memory | 256KB - 4MB | 1GB - 16GB | 16GB - 1TB+ |
| Power | Battery (1-5 years) | Mains / Solar | Mains |
| Network | BLE, Zigbee, LoRaWAN | WiFi, 4G/5G, Ethernet | Fiber, WAN |
| Update cycle | Months | Weeks | Days |
| Security | Hardware-limited | Moderate | Full stack |

---

## 2. Tier 1 — Constrained Devices (Sensors & Actuators)

### 2.1 Hardware Landscape

| Chip | Core | RAM | Flash | Radio | Sleep Current | Use Case |
|------|------|-----|-------|-------|---------------|----------|
| **ESP32** | Xtensa LX6 | 520KB | 4MB | WiFi, BLE | 5µA | General IoT, prototyping |
| **ESP32-C6** | RISC-V | 512KB | 4MB | WiFi6, BLE5, Zigbee, Thread | 2.5µA | Matter-compatible |
| **nRF52840** | Cortex-M4F | 256KB | 1MB | BLE5, Thread, Zigbee | 0.4µA | Battery-operated sensors |
| **STM32L4** | Cortex-M4 | 128KB | 1MB | Optional external | 0.1µA | Industrial, low-power |
| **SAMD21** | Cortex-M0+ | 32KB | 256KB | Optional | 1µA | Simple sensors |

### 2.2 Security Constraints

**Masalah: constrained devices gak bisa jalani security full-stack:**
- TLS 1.3 handshake butuh ~50KB RAM — mungkin untuk ESP32, mustahil untuk SAMD21
- Public key crypto (Ed25519 verify) butuh ~10K cycles — bertahan di baterai
- Secure boot butuh hardware OTP (One-Time Programmable) memory — gak semua chip punya

**Solusi tier-based security:**

| Security Measure | Tier 1 (ESP32) | Tier 1 (nRF52) | Tier 1 (SAMD21) |
|-----------------|----------------|----------------|-----------------|
| **Secure boot** | ✅ (ESP32 Secure Boot v2) | ❌ (no HW OTP) | ❌ |
| **Flash encryption** | ✅ (AES-XTS-128) | ❌ | ❌ |
| **TLS** | ✅ (mbedTLS, 50KB heap) | 🟡 (tROP — tiny TLS) | ❌ (CoAP + DTLS) |
| **Attestation** | ❌ (no TPM) | ❌ | ❌ |
| **Firmware encryption** | ✅ (NVS encryption) | 🟡 (soft AES) | ❌ |
| **Physical tamper** | ❌ (no shield) | ❌ | ❌ |

### 2.3 Power-Saving vs Security Trade-off

```
Deep sleep (10µA) ←→ Active (100mA)
  - Deep sleep = CPU off, RAM retention minimal
  - Wake on interrupt (sensor threshold, timer)
  - Security check: hanya di active window

Attack window: ketika device aktif mengirim data (ms)
  - Attacker punya limited time untuk inject malformed packet
  - Tapi replay attack masih mungkin kapan saja
  - Solusi: sequence number + timestamp di tiap message
```

---

## 3. Tier 2 — Edge Gateway

### 3.1 Fungsi Edge Gateway

Edge gateway bukan sekadar "router" — dia adalah **otak dari edge deployment**:

```
Edge Gateway Services:
  ┌─────────────────────────────────────┐
  │  MQTT Broker    │ NanoMQ, Mosquitto  │
  │  Local DB       │ SQLite, RocksDB     │
  │  Rule Engine    │ eKuiper, Node-RED   │
  │  AI Inference   │ ONNX Runtime, TFLite│
  │  VPN/ZeroTier   │ Tailscale, WireGuard│
  │  OTA Agent      │ Hawkbit, RAUC       │
  │  Container Host │ Docker, Podman      │
  └─────────────────────────────────────┘
```

### 3.2 Hardware untuk Edge Gateway

| Platform | CPU | RAM | Storage | GPU | Power | Use Case |
|----------|-----|-----|---------|-----|-------|----------|
| **Raspberry Pi 5** | Cortex-A76 (4x) | 8GB | microSD | VideoCore VII | 15W | General edge |
| **Jetson Orin Nano** | Cortex-A78AE (6x) | 8GB | SSD | 40 TOPS Ampere | 15W | AI inference |
| **Intel NUC** | i5/i7 | 16-64GB | NVMe | Iris Xe | 65W | Heavy compute |
| **Rockchip RK3588** | Cortex-A76 (4x) + A55 (4x) | 16GB | eMMC | Mali G610 | 10W | Cost-effective |

### 3.3 Edge Gateway Security Checklist

```
✅ OS Hardening:
  - Read-only root filesystem (squashfs/EROFS)
  - No SSH password auth (key only)
  - Fail2ban untuk SSH
  - Auditd untuk system call monitoring

✅ Network:
  - WireGuard VPN ke cloud
  - mTLS antara gateway dan sensor
  - Rate limiting per-device

✅ Application:
  - Drop privileges (run as non-root container)
  - Seccomp profile untuk Docker/Podman
  - Read-only container filesystem

✅ Updates:
  - A/B partition update (RAUC / Mender)
  - Signed update bundle
  - Rollback otomatis jika boot gagal
```

---

## 4. Tier 3 — Cloud / Data Center

### 4.1 Cloud Architecture untuk IoT

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Message     │────→│  Stream      │────→│  Database    │
│  Broker      │     │  Processor   │     │  (TSDB)      │
│  (MQTT/AMQP) │     │  (Flink/Kafka│     │  InfluxDB/   │
│  EMQX/VerneMQ│     │   Streams)   │     │  TimescaleDB │
└──────────────┘     └──────────────┘     └──────────────┘
       │                                        │
       │                                  ┌─────▼──────┐
       │                                  │  Data Lake  │
       │                                  │  (S3/MinIO) │
       │                                  └─────────────┘
       │
  ┌────▼──────┐     ┌──────────────┐
  │  Device   │     │  Dashboard   │
  │  Registry │     │  (Grafana)   │
  │  + Shadow │     │  + Alerts    │
  └───────────┘     └──────────────┘
```

### 4.2 Device Identity & Authentication

Setiap IoT device harus punya **identity unik** yang terverifikasi:

```json
{
  "device_id": "sensor-temp-042",
  "factory_id": "batch-2026-03",
  "public_key": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
  "attestation": {
    "manufacturer": "Acme Sensors Inc.",
    "model": "TEMP-2000",
    "firmware_version": "2.1.4",
    "security_level": "TLS-1.3",
    "issued_at": "2026-03-15T00:00:00Z",
    "expires_at": "2027-03-15T00:00:00Z"
  }
}
```

**Cloud-side validation flow:**

```
1. Device connect → kirim certificate (X.509 atau raw public key)
2. Cloud verifikasi signature dari device attestation
3. Cloud cek certificate revocation list (CRL)
4. Jika valid → allow MQTT publish/subscribe ke topic tertentu
5. Jika invalid → drop connection, log alert, block IP
```

### 4.3 IoT Cloud Platforms Comparison

| Platform | MQTT | Stream | Device Shadow | Free Tier | Self-Host |
|----------|------|--------|---------------|-----------|-----------|
| **AWS IoT Core** | ✅ | ✅ Kinesis | ✅ | 250K msg/mo | ❌ |
| **Azure IoT Hub** | ✅ | ✅ Stream Analytics | ✅ | 8K msg/day | ❌ |
| **EMQX + Kafka** | ✅ (self-host) | ✅ | ❌ | Unlimited | ✅ |
| **Mosquitto + Node-RED** | ✅ | 🟡 Custom | ❌ | Unlimited | ✅ |

---

## 5. IoT Communication Protocols

### 5.1 Protocol Stack

```
Layer           Protocol Options
─────           ─────────────────────────────────────
Application     MQTT, CoAP, HTTP, gRPC, AMQP
Security        TLS 1.3, DTLS 1.3, OSCORE
Transport       TCP, UDP, QUIC
Network         IPv6 (6LoWPAN), IPv4, Thread
Link            WiFi, BLE, Zigbee, LoRaWAN, NB-IoT, LTE-M
Physical        2.4GHz, Sub-1GHz, 868/915MHz, Cellular
```

### 5.2 MQTT — #1 untuk IoT

```python
# Publish sensor data via MQTT (ESP32 Micropython)
import network
import umqtt.simple as mqtt
import json
import time

# Connect WiFi
wlan = network.WLAN(network.STA_IF)
wlan.connect("ssid", "password")

# MQTT connect
client = mqtt.MQTTClient(
    client_id="sensor-temp-042",
    server="edge-gateway.local",
    port=8883,
    ssl=True,
    ssl_params={"certfile": "/cert/device.crt", "keyfile": "/cert/device.key"}
)
client.connect()

# Publish every 5 minutes
while True:
    payload = json.dumps({
        "temperature": 25.3,
        "humidity": 65.2,
        "battery": 3.7
    })
    client.publish(b"factory/zone-a/sensor-temp-042", payload, qos=1)
    time.sleep(300)

# MQTT topic design:
#   factory/{zone}/{device_id}/{metric}
#   factory/zone-a/sensor-temp-042/temperature
#   ACL: device cuma bisa publish ke topic sendiri
```

### 5.3 Protocol Perbandingan

| Aspek | MQTT | CoAP | HTTP | gRPC |
|-------|------|------|------|------|
| Transport | TCP | UDP | TCP | HTTP/2 |
| Model | Pub/Sub | Request/Response | Request/Response | RPC |
| Header size | 2-14 bytes | 4 bytes | > 100 bytes | ~ 50 bytes |
| QoS | 3 levels | Confirmable/Non | N/A | N/A |
| TLS | ✅ | ✅ (DTLS) | ✅ | ✅ |
| Constrained | 🟡 | 🟢 | ❌ | ❌ |
| Use case | Sensor → Gateway | Device → Device | Gateway → Cloud | Internal microservices |

---

## 6. Firmware Security — Secure Boot & Signing

### 6.1 Secure Boot Chain

```
ROM Bootloader → Bootloader 1 → Bootloader 2 → Kernel → Rootfs
     │               │              │            │         │
  Verify ROM      Verify BL1     Verify BL2   Verify    Verify
  (hardware)      (public key)   (public key)  kernel    rootfs
                                               signature signature
```

**ESP32 Secure Boot v2 Flow:**

```
1. ROM: load bootloader dari flash
2. Bootloader: verify signature menggunakan public key di eFuse
3. Jika valid → boot aplikasi
4. Jika invalid → panic (tidak bisa boot)
5. Public key di-burn di eFuse (write-once, tidak bisa diubah)
```

**Konsekuensi:**
- Tanpa secure boot → attacker bisa flash firmware custom → ambil alih device
- Dengan secure boot → hanya firmware yang di-sign pabrik yang bisa boot
- **Tapi** secure boot gak cegah side-channel attack (glitching, power analysis)

### 6.2 Firmware Signing

```bash
# Generate signing key
openssl ecparam -genkey -name prime256v1 -out firmware.key
openssl ec -in firmware.key -pubout -out firmware.pub

# Sign firmware binary
openssl dgst -sha256 -sign firmware.key -out firmware.bin.sig firmware.bin

# Verify (di device)
# 1. Hash firmware.bin → SHA256
# 2. Verify signature dengan public key dari eFuse
# 3. Jika valid → boot
```

### 6.3 Common Firmware Vulnerabilities

| Vulnerability | Dampak | Contoh |
|---------------|--------|--------|
| **Hardcoded credentials** | Akses ke device, cloud, atau backend | Username:password di firmware binary |
| **Unencrypted storage** | Ekstraksi data sensitif dari flash | WiFi password, API key di plaintext |
| **No signature verification** | Firmware arbitrary upload | Attacker flash backdoor firmware |
| **Debug interface enabled** | Akses via JTAG/SWD ke CPU | UART dengan root shell |
| **Default credentials** | SSH/telnet dengan default password | root:root |

Lihat [[firmware-reverse-engineering-deepdive]] untuk teknik extract dan analisis firmware.

---

## 7. OTA Update Security

### 7.1 OTA Architecture

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Build   │────→│  Sign   │────→│  Upload │
│  Server  │     │  Server │     │  (S3)   │
│  (CI/CD) │     │  (HSM)  │     │         │
└─────────┘     └─────────┘     └────┬────┘
                                     │
                               ┌─────▼──────┐
                               │  OTA Server │
                               │  (Hawkbit)  │
                               │  / RAUC     │
                               └─────┬──────┘
                                     │
                          ┌──────────┴──────────┐
                          │                     │
                    ┌─────▼─────┐         ┌─────▼─────┐
                    │  Edge     │         │  Edge     │
                    │  Gateway  │         │  Gateway  │
                    │  A        │         │  B        │
                    └─────┬─────┘         └─────┬─────┘
                          │                     │
                    ┌─────▼─────┐         ┌─────▼─────┐
                    │ Sensors   │         │ Sensors   │
                    │  (OTA via  │         │  (OTA via  │
                    │  BLE/WiFi) │         │  BLE/WiFi) │
                    └───────────┘         └───────────┘
```

### 7.2 OTA Security Threats

| Threat | Deskripsi | Mitigasi |
|--------|-----------|----------|
| **Rollback attack** | Paksa device pake firmware lama yang vulnerable | Version counter di secure storage |
| **Firmware interception** | Man-in-the-middle saat download firmware | TLS + signature verification |
| **Malicious update server** | Attacker tiru update server | Certificate pinning |
| **Partial update** | Firmware corrupt sebagian | A/B partition + CRC check |
| **Supply chain attack** | Kompromi di build server | SLSA framework, signed builds |

### 7.3 A/B Partition Update

```
Slot A (current): [Bootloader] [Kernel A] [Rootfs A]
Slot B (update):                               [Kernel B] [Rootfs B]

Update flow:
1. Download firmware ke slot B (inactive)
2. Verifikasi signature
3. Set boot flag ke slot B
4. Reboot
5. Jika boot gagal → rollback otomatis ke slot A
6. Konfirmasi sukses → slot A jadi target update berikutnya
```

```bash
# RAUC (Robust Auto-Update Controller) — A/B update untuk embedded Linux
# rauc/system.conf
[system]
compatible=my-edge-device
bootloader=uboot

[slot.rootfs.0]
device=/dev/mmcblk0p2
type=ext4
bootname=system-a

[slot.rootfs.1]
device=/dev/mmcblk0p3
type=ext4
bootname=system-b

# Update command
rauc install update-bundle.raucb
```

---

## 8. Network Segmentation untuk IIoT/OT

### 8.1 Purdue Model untuk OT Security

Purdue Enterprise Reference Architecture (PERA) adalah standar de facto untuk Industrial Control System (ICS) segmentation:

```
Level 5: Enterprise Network (ERP, email, internet)
    │ Firewall (DMZ)
Level 4: Site Business Operations (historian, asset mgmt)
    │ Firewall (industrial DMZ)
Level 3: Site Operations (SCADA, control center)
    │ Firewall
Level 2: Control (PLC programming, HMI)
    │
Level 1: Basic Control (PLC, RTU)
    │
Level 0: Process (sensors, actuators, motor)
```

**Implementasi di homelab:**

```
IoT VLAN (192.168.10.0/24)   — Tier 1 sensors
  ├── Hanya bisa MQTT ke gateway (port 8883)
  ├── Rate limit: 10 packets/s per device
  ├── DHCP lease: 1 hour
  └── Firewall: reject all inbound from other VLANs

Edge VLAN (192.168.20.0/24)  — Tier 2 gateways
  ├── Bisa MQTT ke cloud (via VPN)
  ├── SSH dari management VLAN only
  ├── DNS hanya ke internal resolver
  └── Firewall: allow outbound MQTT to cloud

Management VLAN (10.0.100.0/24) — Admin access
  ├── SSH bastion host
  ├── VPN termination (WireGuard)
  └── Firewall: allow SSH from VPN only
```

### 8.2 IIoT Security Checklist

```bash
# 1. Segmentasi jaringan — jangan campur IoT dengan corporate network
# 2. Device authentication — setiap device punya X.509 certificate
# 3. Network monitoring — Suricata/Zeeks di mirror port switch
# 4. Firmware version tracking — inventaris semua device + versi
# 5. Vulnerability scanning — Nessus/OpenVAS untuk known CVEs
# 6. Incident response plan — "ada sensor rogue, apa yang dilakukan?"
# 7. Physical security — jangan biarkan device fisik gak terkunci
```

---

## 9. Edge AI — Inferensi di Edge

### 9.1 Kenapa Inferensi di Edge?

- **Latency:** <10ms response (gak bisa nunggu cloud round-trip)
- **Bandwidth:** ngirim 1KB data inferensi vs 1MB raw video
- **Privacy:** data sensitif gak perlu ke cloud
- **Offline:** tetap jalan walau internet putus

### 9.2 Inference Engine Comparison

| Engine | Format | Platform | Performance | Use Case |
|--------|--------|----------|-------------|----------|
| **ONNX Runtime** | ONNX | CPU/GPU/TPU | 🟢 | General purpose |
| **TensorRT** | ONNX → TRT | NVIDIA GPU | 🟢🟢 (max perf) | Jetson |
| **TFLite** | TFLite | CPU/GPU/Edge TPU | 🟡 | Mobile, RPi |
| **OpenVINO** | IR | Intel CPU/GPU/VPU | 🟢 | Intel hardware |
| **MediaPipe** | TFLite | CPU/GPU | 🟡 | Vision pipelines |

### 9.3 Example: People Counting di Edge

```python
# ONNX Runtime — edge inference
import onnxruntime as ort
import cv2
import numpy as np
import json

# Load model
session = ort.InferenceSession("yolov8n.onnx")
input_name = session.get_inputs()[0].name

cap = cv2.VideoCapture(0)
while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Preprocess
    input_tensor = cv2.resize(frame, (640, 640))
    input_tensor = input_tensor.transpose(2, 0, 1)[np.newaxis, ...].astype(np.float32) / 255.0
    
    # Inference
    outputs = session.run(None, {input_name: input_tensor})
    
    # Postprocess — count people
    detections = outputs[0][0]
    people_count = sum(1 for d in detections if d[4] > 0.5 and int(d[5]) == 0)
    
    # Publish MQTT (only if count changed)
    payload = json.dumps({"people_count": people_count, "zone": "entrance"})
    client.publish(b"factory/zone-a/camera-01/people", payload)
```

---

## 10. Supply Chain Security untuk IoT

### 10.1 Supply Chain Threats

```
1. Design phase: IP theft, malicious hardware backdoor
2. Manufacturing: counterfeit chips, firmware injection
3. Distribution: tampered packaging, swapped devices
4. Deployment: rogue device claiming legitimate identity
5. Decommission: data extraction from decommissioned devices
```

### 10.2 Mitigation

| Phase | Mitigation | Standard |
|-------|-----------|----------|
| **Manufacturing** | Hardware root of trust (TPM, eFuse) | TCG DICE |
| **Firmware** | Signed firmware, reproducible builds | SLSA Level 3+ |
| **Identity** | X.509 certificate at manufacturing | IDevID |
| **Deployment** | Network admission control (NAC) | 802.1X |
| **Monitoring** | Anomaly detection (behavior baseline) | NIST SP 800-183 |

---

## 11. Perbandingan Platform Edge Computing

| Platform | Tier 1 | Tier 2 | Tier 3 | Open Source | Learning Curve |
|----------|--------|--------|--------|-------------|----------------|
| **AWS IoT Greengrass** | ❌ | ✅ | ✅ AWS | 🟡 | Sedang |
| **Azure IoT Edge** | ❌ | ✅ | ✅ Azure | 🟡 | Sedang |
| **KubeEdge** | ❌ | ✅ K8s | ✅ K8s | ✅ CNCF | Tinggi |
| **EMQX + Neuron** | 🟡 | ✅ | ✅ EMQX | ✅ | Sedang |
| **Home Assistant** | 🟡 | ✅ | 🟡 Cloud | ✅ | Rendah |
| **Custom (Docker + Mosquitto + Node-RED)** | 🟡 | ✅ | ✅ Custom | ✅ | Sedang |

---

## 🔗 Koneksi ke Catatan Lain

- [[embodied-ai-robotics]] — robotics AI + edge computing, overlapping di Tier 2
- [[wireless-security-deepdive]] — RF attacks di Zigbee, BLE, WiFi (Tier 1 communication)
- [[firmware-reverse-engineering-deepdive]] — RE firmware untuk audit keamanan device
- [[autonomous-system-design]] — autonomous system = edge AI + real-time control
- [[hardware-hacking-re]] — physical access attack ke embedded device
- [[container-kubernetes-security-deepdive]] — cloud backend (Tier 3) security
- [[networking-fundamentals-tcpip-bgp]] — network segmentation & routing untuk IoT VLAN
- [[waf-reverse-proxy-deepdive]] — API gateway & WAF untuk IoT cloud API
- [[ebpf-beyond-security]] — eBPF untuk network monitoring di edge gateway
- [[observability-stack-prometheus-grafana]] — monitoring edge devices metrics

---

## ✅ Checklist

- [ ] Paham 3-tier edge architecture dan karakteristik tiap tier
- [ ] Bisa jelasin trade-off keamanan di constrained device
- [ ] Paham perbedaan MQTT vs CoAP vs HTTP untuk IoT
- [ ] Bisa setup MQTT broker + TLS + ACL di edge gateway
- [ ] Paham secure boot chain dari ROM → bootloader → kernel
- [ ] Bisa implementasi A/B partition OTA update
- [ ] Paham Purdue model untuk OT/IIoT segmentation
- [ ] Bisa design VLAN segmentation untuk IoT deployment
- [ ] Paham supply chain security threats untuk IoT device

---

## Roadmap Belajar

```
HARI 1: Edge Architecture
  - Baca dokumen ini sampai selesai
  - Gambar arsitektur 3-tier untuk use case lo
  - Identifikasi attack surface tiap tier

HARI 2: Tier 1 — Constrained Devices
  - Setup ESP32 dengan Micropython atau ESP-IDF
  - Implementasi MQTT publish dengan TLS
  - Tes deep sleep + wake cycle, ukur power consumption

HARI 3: Tier 2 — Edge Gateway
  - Setup Raspberry Pi sebagai edge gateway
  - Install Mosquitto MQTT broker + TLS
  - Setup Node-RED untuk rule engine
  - ONNX Runtime untuk inferensi

HARI 4: Firmware Security
  - Implementasi secure boot dengan ESP32 Secure Boot v2
  - Setup A/B partition OTA dengan RAUC
  - Tes: flash firmware unsigned → harus gagal boot

HARI 5: Full Stack
  - Deploy EMQX + Kafka di cloud (docker compose)
  - Hubungkan edge gateway → cloud
  - Setup monitoring (Prometheus + Grafana)
  - Tulis incident response plan untuk compromised device
```

> [!warning] Bottom Line
> Edge computing dan IoT bukan hanya soal hardware kecil — ini soal **membangun trust dari chip ke cloud**. Setiap tier punya attack surface sendiri: Tier 1 diserang via side-channel dan physical tamper, Tier 2 via OS dan software supply chain, Tier 3 via API dan cloud misconfiguration. Security edge yang baik bukan soal satu teknologi ajaib — tapi soal **defense in depth** yang dimulai dari secure boot di chip, berlanjut ke signed OTA updates, network segmentation, sampe ke cloud-side monitoring. Kelemahan di satu tier mengkompromikan seluruh sistem.

> [!tip] Ponytail
> Catatan ini belum mencakup Matter protocol (smart home interoperability standard), LwM2M (Lightweight M2M — device management protocol), TPM/HSM untuk edge device, dan federated learning (AI training terdistribusi di edge tanpa centralize data). Tambahkan ketika implementasi Matter atau butuh hardware security module.
