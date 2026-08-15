---
title: Covert Channel Encyclopedia
tags:
  - covert-channel
  - data-exfiltration
  - steganography
  - detection
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[semantic-search-pipeline]]
  - [[ipv6-migration]]
related_notes:
  - [[covert-channel-encyclopedia|Covert Channel Encyclopedia]]
---

> Covert channels menyembunyikan komunikasi dalam traffic legitimate. Artikel ini membahas kategori, mekanisme deteksi, dan langkah mitigasi.

## 1. Ringkasan / Definisi
Covert channel adalah jalur komunikasi tersembunyi yang tidak dirancang oleh protokol atau sistem. Ia memanfaatkan field tidak terpakai, timing paket, atau payload yang terlihat normal untuk mengirim data — sering digunakan untuk data exfiltration, command & control (C2), atau bypass monitoring.

## 2. Kategori Covert Channel
| Kategori | Contoh | Keterangan |
|----------|--------|------------|
| Storage Channel | Header manipulation (IP ID, TCP SEQ, HTTP headers) | Menyisipkan data pada field yang jarang diperiksa. |
| Storage Channel | ICMP payload (ping tunnel) | Kirim data pada payload ICMP echo request/reply. |
| Storage Channel | DNS payload (txt record, NS lookup) | Exfiltrasi via DNS queries — sulit terdeteksi. |
| Timing Channel | Inter-packet delay modulation | Encode data dalam jeda antar paket. |
| Timing Channel | Packet reordering | Manipulasi urutan paket yang tampak acak. |
| Protocol Abuse | HTTP headers/cookies/URL | Menyembunyikan data dalam atribut HTTP. |
| Protocol Abuse | HTTPS TLS padding size | Data disembunyikan pada ukuran padding TLS. |
| Protocol Abuse | SSH channel stuffing | Menyisipkan data dalam channel SSH yang sah. |

## 3. Deteksi
> [!callout] ⚠️
> Steganografi dan covert channel sulit dideteksi — perlu kombinasi analisis statistik, anomaly detection, dan pemantauan traffic baseline.

**Teknik deteksi:**
- **Shannon entropy analysis**: Deteksi lonjakan entropi pada field yang biasanya polos (mis. IP ID, DNS TXT).
- **Protocol field anomaly detection**: Pantau nilai field yang tidak konsisten dengan spesifikasi protokol.
- **Time-series analysis**: Deteksi pola timing yang tidak wajar (mis. inter-packet delay reguler pada traffic yang seharusnya acak).
- **Deep packet inspection (DPI)**: Parsing payload dan header secara mendalam.
- **Behavioral analytics**: Deteksi sink hole DNS, frekuensi query abnormal, atau pola beaconing.

## 4. Checklist Mitigasi
- [ ] Aktifkan logging DNS dan kategori DNS tunneling.
- [ ] Terapkan firewall stateful dengan aturan egress ketat.
- [ ] Monitor volume query DNS per host (threshold anomaly).
- [ ] Lakukan audit berkala terhadap field header IP/TCP.
- [ ] Gunakan IDS/IPS berbasis machine learning untuk traffic anomaly.
- [ ] Batasi komunikasi ICMP kecuali diperlukan.
- [ ] Dokumentasikan baseline traffic normal untuk perbandingan berkala.

## 5. Referensi
- RFC 4949 – Internet Security Glossary (definisi covert channel)
- Buku: *Silent Spreadsheet* / paper "Covert Channels in the TCP/IP Protocol Suite"
- [[ipv6-migration]] – Risiko terkait tunneling yang bisa jadi covert channel.
- [[semantic-search-pipeline]] – Teknik analisis vektor untuk anomaly detection.
---

audited
---
