---
title: "IoT Engineering — MQTT, CoAP, LwM2M & Communication Protocols"
tags:
  - iot
  - protocols
  - mqtt
  - coap
  - lwm2m
  - embedded
  - library
aliases:
  - "iot-protocols-guide"
  - "mqtt-coap-deepdive"
  - "iot-communication-protocols"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# 📡 IoT Engineering — MQTT, CoAP, LwM2M & Communication Protocols

> Vault punya [[edge-computing-iot-security-architecture]] yang fokus ke security arsitektur IoT, dan [[embedded-systems]] untuk sistem embedded secara umum. Tapi belum ada yang bedah **communication protocols yang menjadi tulang punggung IoT: bagaimana device dengan resource terbatas (baterai, CPU, bandwidth) bisa berkomunikasi secara efisien dan reliable**. Catatan ini mencakup MQTT, CoAP, LwM2M, LPWAN, mesh protocols, dan serialization — dari teori sampai implementasi.

> [!info] Posisi di Vault
> Ini adalah **protocol layer** IoT yang melengkapi [[edge-computing-iot-security-architecture]] (security) dan [[embedded-systems]] (hardware). Juga terhubung dengan [[networking-fundamentals-tcpip-bgp]] (network layer), [[api-protocols-deepdive]] (API protocols secara umum), dan [[wireless-security-deepdive]] (wireless security).

---

## Daftar Isi

- [[#1. IoT Architecture Overview]]
- [[#2. MQTT — Message Queue Telemetry Transport]]
- [[#3. CoAP — Constrained Application Protocol]]
- [[#4. LwM2M — Lightweight Machine to Machine]]
- [[#5. LPWAN — LoRaWAN, NB-IoT, LTE-M]]
- [[#6. Mesh Protocols — Zigbee, Z-Wave, Thread, Matter]]
- [[#7. Serialization — CBOR, Protobuf, MessagePack]]
- [[#8. Security — DTLS, OSCORE, Secure Boot]]
- [[🔗 Koneksi ke Catatan Lain]]
- [[✅ Checklist]]
- [[Roadmap Belajar]]

---

## 1. IoT Architecture Overview

### 1.1 Four-Layer Architecture

```
┌──────────────────────────────────────────────────┐
│  APPLICATION LAYER                                │
│  Data analytics, dashboard, ML inference          │
├──────────────────────────────────────────────────┤
│  MIDDLEWARE LAYER                                 │
│  Message broker, device registry, rule engine     │
├──────────────────────────────────────────────────┤
│  NETWORK / PROTOCOL LAYER                         │
│  MQTT, CoAP, HTTP, LwM2M, LoRaWAN                │
├──────────────────────────────────────────────────┤
│  PERCEPTION / DEVICE LAYER                        │
│  Sensors, actuators, microcontroller, radio       │
└──────────────────────────────────────────────────┘
```

### 1.2 IoT Protocol Stack vs Internet Stack

| Layer       | Internet Stack  | IoT Stack                       |
| :---------- | :-------------- | :------------------------------ |
| Application | HTTP, WebSocket | **MQTT**, **CoAP**, LwM2M, gRPC |
| Transport   | TCP, UDP        | TCP, UDP, QUIC                  |
| Network     | IPv4, IPv6      | IPv6, 6LoWPAN, RPL              |
| Link        | Ethernet, Wi-Fi | **LoRa**, NB-IoT, BLE, Zigbee   |
| Physical    | Copper, Fiber   | RF 868/915MHz, 2.4GHz, Sub-GHz  |

### 1.3 Protocol Selection Matrix

| Protocol      | Transport | Model                  |       QoS       | Overhead | Power  | Use Case                     |
| :------------ | :-------- | :--------------------- | :-------------: | :------: | :----: | :--------------------------- |
| **MQTT**      | TCP       | Pub/Sub                |    3 levels     | Minimal  | Medium | Sensor telemetry, push notif |
| **CoAP**      | UDP       | Req/Response + Observe |   Confirmable   | Minimal  |  Low   | Constrained device REST      |
| **HTTP/2**    | TCP       | Req/Response           | Stream priority |  Tinggi  |  High  | Gateway-to-cloud             |
| **gRPC**      | HTTP/2    | Streaming              |  Bidirectional  |  Sedang  |  High  | High-throughput IoT          |
| **WebSocket** | TCP       | Full-duplex            |      None       |  Sedang  |  High  | Real-time UI                 |

---

## 2. MQTT — Message Queue Telemetry Transport

### 2.1 MQTT Architecture

```
┌────────┐    ┌──────────┐    ┌────────┐
│Publisher│───→│  Broker  │───→│Subscriber│
│(sensor) │    │ (Mosquitto) │    │ (app)   │
└────────┘    └──────────┘    └────────┘
                   │
              ┌────▼────┐
              │Subscriber│
              │ (logger) │
              └─────────┘
```

MQTT menggunakan **publish/subscribe** pattern — publisher gak tahu siapa subscriber, subscriber gak tahu siapa publisher. Semua routing dilakukan oleh **broker** berdasarkan topic hierarchy.

### 2.2 Topic & Wildcard

```text
Topic: home/kitchen/temperature
         ↑     ↑       ↑
      domain  room  measurement

Wildcards:
  + (single level):  home/+/temperature  → home/kitchen/temperature, home/bedroom/temperature
  # (multi level):   home/#              → home/kitchen/temperature, home/garage/door/status

Example topics:
  sensor/temperature/room-01
  sensor/humidity/room-01
  actuator/light/room-01/set     ← command topic
  actuator/light/room-01/status  ← status response
  system/alert/+                  ← all alert topics
```

### 2.3 QoS Levels

|  QoS  | Delivery Guarantee | Packet                              | Use Case                      |
| :---: | :----------------- | :---------------------------------- | :---------------------------- |
| **0** | At most once       | PUBLISH (fire & forget)             | Sensor read non-kritis (temp) |
| **1** | At least once      | PUBLISH + PUBACK                    | Must deliver, duplicate OK    |
| **2** | Exactly once       | PUBLISH + PUBREC + PUBREL + PUBCOMP | Payment, critical command     |

```bash
# QoS impact on throughput (test with Mosquitto)
mosquitto_pub -t test -m "hello" -q 0  # ~50,000 msg/sec
mosquitto_pub -t test -m "hello" -q 1  # ~15,000 msg/sec
mosquitto_pub -t test -m "hello" -q 2  # ~5,000 msg/sec
```

### 2.4 MQTT 5.0 Improvements

| Feature                  |     MQTT 3.1.1     | MQTT 5.0                  |
| :----------------------- | :----------------: | :------------------------ |
| Session expiry           | Clean session only | Session expiry interval   |
| Reason codes             |        None        | Full reason codes in ACK  |
| User properties          |        None        | Custom metadata in header |
| Topic alias              |        None        | Reduce topic size         |
| Flow control             |        None        | Receive maximum           |
| Server disconnect reason |        None        | Reason string             |

### 2.5 MQTT Broker Comparison

| Broker        | Language | Max Connections | Clustering  | Protocols                    |
| :------------ | :------- | :-------------: | :---------- | :--------------------------- |
| **Mosquitto** | C        |      ~100K      | ❌          | MQTT 5.0, WebSocket          |
| **EMQX**      | Erlang   |      10M+       | ✅ Native   | MQTT, CoAP, WebSocket, Stomp |
| **VerneMQ**   | Erlang   |       ~1M       | ✅ Native   | MQTT 3.1.1/5.0               |
| **NanoMQ**    | C        |       ~1M       | ✅ via EMQX | MQTT 5.0, ZeroMQ, WebSocket  |
| **HiveMQ**    | Java     |      ~500K      | ✅          | MQTT 5.0, Sparkplug          |

### 2.6 Practical MQTT with ESP32

```cpp
// ESP32 + MQTT — sensor publish
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
    client.setServer("mqtt.example.com", 1883);
    client.setCallback(callback);
}

void loop() {
    if (!client.connected()) reconnect();
    client.loop();

    float temp = readTemperature();
    char msg[50];
    snprintf(msg, 50, "{"temp": %.2f, "hum": %.2f}", temp, readHumidity());

    // QoS 1 — at least once, sufficient for sensor data
    client.publish("sensor/temperature/living-room", msg, true);  // retain = true
    delay(30000);  // report every 30s
}
```

---

## 3. CoAP — Constrained Application Protocol

### 3.1 CoAP vs HTTP

CoAP adalah **REST-like protocol untuk constrained device** — mirip HTTP tapi di atas UDP, dengan overhead minimal.

```
HTTP:  GET /temperature → TCP + TLS → Header ~800 bytes
CoAP: GET /temperature → UDP + DTLS → Header ~4 bytes

CoAP Message Format:
  0                   1                   2                   3
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 ├─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤─┤
 │Ver│T│  TKL  │      Code     │          Message ID             │
 ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 │   Token (if any, TKL bytes) ...                                │
 ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
 │   Options (if any) ...                                         │
 ├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
 │1 1 1 1 1 1 1 1│    Payload (if any) ...                       │
 └───────────────────────────────────────────────────────────────┘
```

### 3.2 CoAP Methods vs HTTP

| HTTP   | CoAP        | Behavior                      |
| :----- | :---------- | :---------------------------- |
| GET    | GET         | Retrieve resource             |
| POST   | POST        | Create/update                 |
| PUT    | PUT         | Update resource               |
| DELETE | DELETE      | Delete resource               |
| -      | **OBSERVE** | Subscribe to resource changes |
| -      | **FETCH**   | Retrieve with request body    |
| -      | **PATCH**   | Partial update                |

### 3.3 Confirmable vs Non-Confirmable

```text
CON (Confirmable):
  Request → ACK timeout → retransmit (max 4×)
  Exponential backoff: 2s, 4s, 8s, 16s
  → Reliable delivery, but higher latency

NON (Non-Confirmable):
  Fire-and-forget — no ACK expected
  → Unreliable, but low latency & power

RST (Reset):
  Receiver doesn't understand message → sender stop retransmit
```

### 3.4 Observe Pattern (CoAP Subscription)

```text
Client                                  Server
  │                                       │
  ├──── GET /temperature (Observe=0) ────→│
  │←──── 2.05 Content (token=0x42) ─────┤
  │                                       │
  │         (temperature changes)         │
  │←──── 2.05 Content (token=0x42) ─────┤
  │                                       │
  │         (another change)              │
  │←──── 2.05 Content (token=0x42) ─────┤
  │                                       │
  ├──── GET /temperature (Observe=1) ────→│  ← cancel observation
  │←──── 2.05 Content                     │
```

---

## 4. LwM2M — Lightweight Machine to Machine

### 4.1 LwM2M Architecture

LwM2M adalah protocol **device management** di atas CoAP — bukan cuma komunikasi data, tapi juga remote management:

```
┌──────────────────┐      CoAP/DTLS       ┌──────────────────┐
│   LwM2M Client   │◄───────────────────►│  LwM2M Server    │
│   (sensor, mote) │                      │  (cloud/backend) │
└──────────────────┘                      └──────────────────┘
       ▲                                         ▲
       │ Bootstrap                               │
       ▼                                         ▼
┌──────────────────┐                      ┌──────────────────┐
│ Bootstrap Server │                      │  Smartphone App  │
└──────────────────┘                      └──────────────────┘
```

### 4.2 LwM2M Interfaces

| Interface                                  | Fungsi                                   | Contoh                    |
| :----------------------------------------- | :--------------------------------------- | :------------------------ |
| **Bootstrap**                              | Initial config (server URL, credentials) | First-time device setup   |
| **Device Registration**                    | Register ke LwM2M server                 | `Register /rd`            |
| **Device Management & Service Enablement** | Read/Write/Execute resources             | Reboot, firmware update   |
| **Information Reporting**                  | Observe resource changes                 | Sensor value notification |

### 4.3 Object/Resource Model

```
LwM2M Object = kumpulan resources yang mewakili satu fungsi
LwM2M Resource = parameter individual dalam object

Standard Objects (di define IPSO Alliance):
  /0: LwM2M Security      → Server URI, credentials
  /1: LwM2M Server        → Lifetime, binding, notification
  /2: Access Control      → ACL per object
  /3: Device              → Manufacturer, model, firmware version
  /4: Connectivity Monitoring → Network bearer, signal strength
  /5: Firmware Update     → Package URI, update state, result
  /6: Location            → Latitude, longitude, altitude
  /3303: Temperature      → Sensor value, units, range

Example:
  /3303/0/5700  → Temperature sensor 0, resource 5700 (sensor value)
  /3/0/0        → Device object 0, resource 0 (manufacturer)
  /5/0/1        → Firmware Update, resource 1 (package URI)
```

### 4.4 Firmware Update (LwM2M OTA)

```text
Step 1: Server write firmware URI ke /5/0/1 (Package URI)
Step 2: Client download firmware (CoAP block-wise transfer)
Step 3: Client update state: /5/0/3 (Update State) → Downloading → Downloaded → Updating
Step 4: Client reboot dengan firmware baru
Step 5: Client register ulang — cek update result /5/0/5
```

---

## 5. LPWAN — LoRaWAN, NB-IoT, LTE-M

### 5.1 LPWAN Comparison

| Teknologi   |       Frequency       |  Range  |  Bandwidth  |  Battery  | Cost Module |
| :---------- | :-------------------: | :-----: | :---------: | :-------: | :---------: |
| **LoRaWAN** | Sub-GHz (868/915 MHz) | 2-15 km | 0.3-50 kbps | 10+ years |    $2-5     |
| **NB-IoT**  |     LTE licensed      | 1-10 km |  200 kbps   | 5+ years  |    $5-10    |
| **LTE-M**   |     LTE licensed      | 1-10 km |   1 Mbps    | 3+ years  |    $8-15    |

### 5.2 LoRaWAN Architecture

```
┌──────┐    LoRa RF     ┌──────────┐    IP Backhaul    ┌───────────┐
│ Node │◄──────────────►│ Gateway  │◄─────────────────►│ Network   │
│ (end │                 │ (concentrator) │              │ Server    │
│ device)                └──────────┘                    └───────────┘
                                                            │
                                                      ┌─────┴─────┐
                                                      │ App Server │
                                                      └───────────┘
```

---

## 🔗 Koneksi ke Catatan Lain

| Catatan                                      | Koneksi                         |
| :------------------------------------------- | :------------------------------ |
| [[edge-computing-iot-security-architecture]] | IoT security architecture       |
| [[embedded-systems]]                         | Sistem embedded untuk IoT       |
| [[networking-fundamentals-tcpip-bgp]]        | Network layer fundamentals      |
| [[api-protocols-deepdive]]                   | API protocol comparison         |
| [[wireless-security-deepdive]]               | Wireless communication security |
| [[cloud-infrastructure]]                     | IoT cloud backend               |

---

## ✅ Checklist

- [ ] Paham perbedaan MQTT, CoAP, LwM2M
- [ ] Bisa setup MQTT broker (Mosquitto/EMQX)
- [ ] Paham QoS levels MQTT dan trade-off masing-masing
- [ ] Tau kapan pake CON vs NON di CoAP
- [ ] Paham LwM2M object/resource model untuk device management
- [ ] Bisa bedain LoRaWAN vs NB-IoT vs LTE-M
- [ ] Tau protocol serialization yang cocok untuk constrained device
- [ ] Paham DTLS vs TLS untuk IoT security

---

## Roadmap Belajar

```
HARI 1: MQTT
  - Setup Mosquitto broker di Docker
  - Publish/subscribe dengan mosquitto_pub/sub
  - Test QoS 0, 1, 2 — lihat perbedaan throughput

HARI 2: CoAP
  - Test CoAP dengan libcoap / coap-client
  - Bandingkan latency CoAP vs HTTP
  - Setup Observe pattern

HARI 3: LwM2M
  - Deploy Leshan (LwM2M server open source)
  - Simulasi device registration + firmware update
  - Test Bootstrap sequence

HARI 4: LPWAN & Mesh
  - Baca spec LoRaWAN 1.1
  - Setup ChirpStack (LoRaWAN network server)
  - Bandingkan Thread vs Zigbee untuk mesh

HARI 5: Security & Production
  - Setup DTLS antara CoAP client dan server
  - Test OSCORE untuk end-to-end encryption
  - Audit security IoT architecture
```

> [!warning] Bottom Line
> IoT protocols bukan cuma soal "pilih yang paling ringan". MQTT bagus untuk sensor telemetry dengan broker, CoAP lebih cocok untuk device-to-device langsung tanpa infrastruktur, LwM2M essential kalau butuh remote device management. Jangan lupa **DTLS untuk CoAP, TLS untuk MQTT** — IoT tanpa enkripsi = botnet menunggu waktu.

> [!tip] Lanjutan
> Catatan ini fokus ke communication protocols. Untuk security IoT, baca [[edge-computing-iot-security-architecture]]. Untuk embedded implementation, baca [[embedded-systems]]. Untuk wireless security, baca [[wireless-security-deepdive]].
