---
title: Attack Perspective — ISP Surveillance (Red Team Counter)
tags:
- attack
- red-team
- isp
- surveillance
- metadata
- dpi
- encryption
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

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

## Konkret — ISP Surveillance Bypass (Testable)

### DPI Evasion (Deep Packet Inspection)

```bash
# 1. TLS 1.3 (ESNI / ECH) → SNI encrypted
# 2. Domain fronting (CDN) → DPI lihat legit domain
# 3. Fragmentation: TLS ClientHello split → DPI miss pattern
#    Tool: Geneva (Genetic Evasion)
python3 geneva.py --strategy "[TCP:flags:PA]-fragment-\{\}-"

# 4. Shadowsocks / V2Ray
#    Proxy yang mimic HTTPS traffic → DPI tidak distinguish
#    Server: shadowsocks-libev -c config.json
#    Client: shadowsocks-local -c config.json
#    Browsing → SS local → SS server → target → direct
```

### DNS Hijack Bypass

```bash
# ISP sering hijack DNS (redirect NX domain ke ad page)
# 1. Use DNS over HTTPS (DoH)
#    Firefox: network.trr.mode = 2 (TRR preferred, fallback)
#    atau via systemd-resolved:
sudo sed -i 's/#DNS=.*/DNS=1.1.1.1 8.8.8.8/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# 2. DNSCrypt
dnscrypt-proxy -config dnscrypt.toml
# 3. Custom DoH endpoint (self-hosted)
#    dnsdist + DoH → custom server → ISP tidak intercept
```

### Metadata Strip

```bash
# 1. Email metadata: PGP/MIME tidak encrypt header
# 2. Photo EXIF → GPS, camera serial, timestamp
exiftool -all= photo.jpg                  # strip all
exiftool -all= *.jpg                       # batch strip

# 3. Document metadata
exiftool -all= document.pdf
mat2 document.pdf                          # metadata anonymization framework
```
---

audited
---
