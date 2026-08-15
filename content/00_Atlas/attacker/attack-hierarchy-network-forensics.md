---
title: Attack Perspective — Network Forensics (Red Team Anti-Forensics)
tags:
- attack
- red-team
- network-forensics
- anti-forensics
- pcap
- zeek
- traffic-shaping
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Network Forensics — Perspektif Anti-Forensics (Red Team)

> Network forensics (defender) = pcap, Zeek, Suricata, flow analysis. Red team pakai anti-forensics = **traffic shaping, encryption, protocol mimicry, log tampering** supaya network activity tidak terlihat.

## 1. Network Anti-Forensics Layer

| Layer Forensics | Defender Teknik | Red Team Anti-Forensics | Tool / Teknik | Evasion |
|-----------------|----------------|----------------------|---------------|---------|
| **Packet Capture (pcap)** | tcpdump, Wireshark, NetworkMiner | Encryption (TLS 1.3, AES-256-GCM) → payload tidak bisa di-inspect | C2 malleable profile, encrypted payload | DPI bypass by encryption |
| **Flow Analysis (NetFlow)** | nfdump, SiLK, flow correlation | Traffic shaping → jitter, bandwidth cap, business hours → below threshold | Cobalt Strike jitter, custom delay | Low-volume + jitter = below beaconing threshold |
| **DNS Analysis** | dnscap, passive DNS, DNS sinkhole | DNS tunnel (dnscat2) — high entropy, mimik CDN traffic | dnscat2, iodine, dnstt | High entropy DNS = mirip legitimate DNS |
| **TLS Fingerprinting (JA3)** | JA3/JA3S matching → C2 framework ID | Custom Malleable profile → JA3 match Chrome/Firefox | Cobalt Strike profile, custom Go/Rust TLS client | JA3 spoof = blend with browser |
| **Zeek/Suricata (IDS)** | Signature + behavioral detection | Protocol mimicry (HTTP/2, gRPC, QUIC framing) → behavioral tidak match | Custom C2, Sliver, Mythic | Mimicry = signature miss, behavioral = below threshold |
| **SIEM Correlation** | Multi-source log correlation (firewall + IDS + EDR) | Fragment TTP across time/hosts → no single correlation window | Slow operation, multi-host pivot | Time gap = correlation window miss |
| **Log Forwarding** | Log audit, forward-only (WORM) | Block log forwarding (firewall rule), disable logging (auditctl) | iptables block SIEM, auditctl -e 0 | Log gap = no evidence |

## 2. C2 Traffic Evasion Chain

```
C2 Beacon → HTTPS (T1071.001)
 ↓
Malleable Profile:
 ├── JA3 = match Chrome 120 (TLS fingerprint)
 ├── User-Agent = Chrome 120 string
 ├── Cookie/Referer = legitimate header
 └── Body = legitimate-looking HTML/JSON
 ↓
Traffic Shaping:
 ├── Jitter: 30-300 detik random delay
 ├── Bandwidth: max 100KB/s (low)
 ├── Business hours: 9-17 (target timezone)
 └── Session: short burst (5-10s) → close
 ↓
Domain Fronting:
 ├── SNI = legitimate CDN domain (Cloudflare, Azure)
 ├── Host header = redirector domain (C2)
 └── CDN edge IP = same edge untuk legit dan C2
 ↓
Alternative Channel (if HTTPS blocked):
 ├── DNS Tunnel: dnscat2 → subdomain encoding → high entropy
 ├── Cloud API: AWS/Azure API → legit service traffic
 ├── WebSocket: full duplex → bypass HTTP inspect
 └── Social Media: GitHub commit, Twitter DM, Telegram bot API
```

## 3. Beaconing Detection Bypass

| Defender Detection | Red Team Bypass |
|---------------------|----------------|
| Fixed interval beacon (consistent delta) | Jitter 30-300s random → delta inconsistent |
| Consistent packet size | Variable chunk size → 100B, 500B, 2KB random |
| High volume traffic | Bandwidth cap (max 100KB/s) → below threshold |
| Off-hours activity | Business hours only (9-17 target timezone) |
| Single destination IP | CDN edge (multiple IP) → domain fronting |
| TLS JA3 mismatch (malware fingerprint) | Custom Malleable → JA3 match Chrome 120 |
| DNS high-volume query (tunnel detection) | DNS tunnel: slow rate (1 query per 30s) → below threshold |

## 4. Tool Stack Network Anti-Forensics

| Tool | Use |
|------|-----|
| **Cobalt Strike Malleable C2** | Custom profile (JA3, UA, cookie, body, jitter) |
| **Havoc** | C2 framework (open source — custom profile support) |
| **Sliver** | C2 implant (Go — custom TLS, JA3 spoof) |
| **dnscat2** | DNS tunnel C2 (subdomain encoding, high entropy) |
| **Chisel / ligolo-ng** | Tunnel pivot (encrypted, multi-hop) |
| **rclone** | Cloud exfil (legit service, encrypted) |
| **Modlishka** | Reverse proxy (AiTM, traffic relay) |

## 5. Referensi
- Zeek (Network Monitoring) — https://zeek.org/
- Suricata IDS — https://suricata.io/
- Cobalt Strike Malleable C2 — https://www.cobaltstrike.com/help-malleable-c2
- RITA (Real Intelligence Threat Analytics) — https://github.com/activecm/rita
-dnscat2 — https://github.com/iagox86/dnscat2
---

audited
---
