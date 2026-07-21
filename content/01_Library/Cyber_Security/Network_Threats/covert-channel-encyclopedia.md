---
title: Covert Channel Encyclopedia
tags:
- covert-channel
- data-exfiltration
- steganography
- detection
created: '2026-07-19'
updated: '2026-07-19'
status: seedling
---

> Covert channels menyembunyikan komunikasi dalam traffic legitimate.

## Categories
### Storage Channels
- Header manipulation (IP ID, TCP SEQ, HTTP headers)
- ICMP payload (ping tunnel)
- DNS payload (txt record, NS lookup)

### Timing Channels
- Inter-packet delay modulation
- Packet reordering
- Kernel timing side-channels

### Protocol Abuse
- HTTP (hidden in headers, cookies, URL)
- HTTPS (TLS padding size)
- SSH (channel stuffing)

## Detection
- Shannon entropy analysis
- Protocol field anomaly detection
- Time-series analysis for timing channels