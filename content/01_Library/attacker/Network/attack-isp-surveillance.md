---
title: Attack Perspective — ISP Surveillance (Red Team Counter)
tags: [attack,red-team,isp,surveillance,metadata,dpi,encryption]
source: isp-surveillance-privacy-deepdive.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# ISP Surveillance — Perspektif Penyerang

> ISP melihat: DNS query, SNI, metadata, traffic pattern. Red team counter: full encryption (DoH/DoQ/ECH), traffic shaping, domain fronting, protocol mimicry.

## 1. What ISP Sees

| Layer | Data Terlihat | Enkripsi? | Red Team Counter |
|-------|--------------|-----------|------------------|
| **DNS** | Query domain (plaintext) | Tidak (default) | DoH/DoQ/DoT → encrypted DNS |
| **TLS SNI** | Target domain (TLS 1.2) | Tidak | ECH (TLS 1.3) → encrypted SNI |
| **IP Dest** | Destination IP | Tidak | CDN front → legit edge |
| **Metadata** | Timestamp, size, duration | Tidak | Traffic shaping → blend |
| **Payload** | Content (if plaintext) | Ya (TLS) | Full TLS 1.3 |
| **DPI** | Protocol signature | Partial | Mimicry → below detect |

## 2. ISP DPI Bypass

```
DPI: Inspect header + payload signature
    ↓
Bypass:
  ├── Full encryption: TLS 1.3 (no visible payload)
  ├── ECH: encrypted SNI (TLS 1.3.0+)
  ├── DoH: DNS over HTTPS (no plaintext DNS)
  ├── QUIC: UDP 443 (no TCP fingerprint)
  └── Traffic shaping: match legit pattern (size, rate)
    ↓
Result: ISP melihat: IP → CDN edge + encrypted blob
  ├── No domain (ECH)
  ├── No payload (TLS 1.3)
  ├── No DNS (DoH)
  └→ Metadata only → blend
```

## 3. Metadata Mitigation

| Metadata | ISP Inferensi | Red Team Counter |
|----------|---------------|------------------|
| Connection time | Business hour pattern | Jitter, random session |
| Packet size | File type, protocol | Chunk variable size |
| Duration | Streaming/upload | Short session, break |
| Frequency | Beaconing | Random interval |
| Volume | Bulk exfil | Cap, spread, chunk |
| Peer IP | C2 domain | CDN edge, flux |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **DoH (Firefox/Cloudflare)** | Encrypted DNS |
| **ECH browser (Firefox Nightly)** | Encrypted SNI |
| **WireGuard** | Encrypted tunnel (VPN) |
| **Oblivious DNS** | DNS privacy |
| **Scapy (custom)** | Traffic shaping test |

## 5. Referensi
- ECH (RFC 8744) — https://datatracker.ietf.org/doc/html/rfc8744
- DoH (RFC 8484) — https://datatracker.ietf.org/doc/html/rfc8484
- QUIC (RFC 9000) — https://datatracker.ietf.org/doc/html/rfc9000
- ISP Surveillance — https://ssd.eff.org/en/module/...