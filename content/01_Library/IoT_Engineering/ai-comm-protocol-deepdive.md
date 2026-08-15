---
title: AI Comm Protocol Deepdive
tags: [iot, ai, protocol]
aliases: [ai-comm-protocol-deepdive]
---
# AI Communication Protocol — Deepdive

Protokol komunikasi untuk AI/IoT edge: (1) **MQTT** — publish/subscribe, broker (Mosquitto), QoS 0-2, TLS opsional (sering di-skip — celah); (2) **CoAP** — UDP-based REST-like, DTLS, cocok constrained device; (3) **gRPC** — HTTP/2, protobuf, low latency, bidirectional stream — cocok inference service; (4) **WebSocket** — realtime bidirectional; (5) **AMQP** — enterprise messaging (RabbitMQ).

Konteks AI: edge inference (TinyML — TensorFlow Lite Micro), model update over-the-air (OTA — sign payload!), telemetry data pipeline. Keamanan: (1) TLS/DTLS wajib; (2) mutual auth (mTLS / device cert); (3) payload signing untuk update; (4) rate limit & quota broker; (5) audit log. Red-team: MQTT tanpa auth = read/write semua topic (Shodan: port 1883 open).
## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[raspberry-pi-5-nvme-boot-troubleshooting]] | Hardware SBC untuk edge AI communication |
| [[iot-protocols-mqtt-coap-lwm2m]] | Protokol komunikasi IoT — fondasi yang sama |
| [[robotics-autonomous-systems]] | Edge AI di sistem robotik |

---

  audited
---