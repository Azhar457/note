---
title: Attack Perspective — Network Security (Red Team / Adversary)
tags:
- attack
- red-team
- network
- osi
- c2
- lateral
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Network Security — Perspektif Penyerang per OSI Layer

> Setiap layer OSI punya vektor serangan spesifik. Red team tidak menyerang satu layer — mereka merangkai chain lintas layer (L2 pivot → L3 route → L7 exploit).

## 1. Attack Surface per OSI Layer

| OSI | Vektor Serangan | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|-----|----------------|----------|------------|---------|---------------|
| L1 Physical | Wiretap, EMP, fiber tap | T1590.004 | Tap fisik, TEMPEST | Akses fisik = tidak terdeteksi software | Physical security audit jarang |
| L2 Data Link | ARP spoof, MAC flood, VLAN hopping, STP root injection | T1557.002 | ettercap, Bettercap, Yersinia, dsniff | ARP spoof = silent MITM, VLAN hop = double tag 802.1Q | Port security/802.1X jarang di-enable di semua port |
| L3 Network | IP spoof, route hijack, ICMP redirect, BGP hijack | T1490 | scapy, BGP inject, RPKI bypass | IP spoof = hide origin, BGP hijack = traffic redirect | RPKI belum universal, BGP monitoring = expensive |
| L4 Transport | SYN flood, port scan, TCP RST inject, UDP flood | T1490 | hping3, nmap, masscan, slowloris | Distributed scan (low rate per IP) = below threshold | Rate limit hanya per-IP, distributed = bypass |
| L5 Session | Session hijack, session fixation, desync | T1557.001 | Burp Suite, request smuggling | HTTP/2 desync = proxy cache poison | WAF tidak inspeksi HTTP/2 framing |
| L6 Presentation | SSL stripping, cert spoof, downgrade attack | T1557 | sslstrip, MITMproxy, STARTTLS downgrade | HSTS bypass (preloaded list gap), cert pinning bypass | OCSP soft-fail = revocation tidak enforced |
| L7 Application | SQLi, XSS, SSRF, RCE, C2 beacon | T1190 | sqlmap, Burp, Cobalt Strike, Havoc | Encoding bypass, WAF evasion, JA3 spoof | Signature WAF = trivial bypass via encoding chain |

## 2. Lateral Movement Chain (L2 → L7)

```
L2 ARP Spoof (T1557.002) → intercept traffic → credential sniff
 ↓
L3 Route injection → redirect traffic ke attacker node
 ↓
L4 Port scan (T1595) → identify services → CVE selection
 ↓
L7 Exploit (T1190) → webshell / RCE → C2 beacon
 ↓
L7 C2 (T1071.001) → HTTPS + domain fronting → blend dengan legit traffic
 ↓
L7 Exfil (T1041) → chunked + AES-256-GCM → DNS tunnel atau cloud API
```

## 3. Detection Evasion Konkret

| Teknik | Implementasi | Deteksi Defender | Bypass |
|--------|-------------|-----------------|--------|
| ARP spoof silent | ettercap -T -q | ARP table monitoring | Jitter spoof, low frequency |
| VLAN hopping | double tag 802.1Q | trunk port audit | Trunk port misconfig umum |
| C2 over HTTPS | Cobalt Strike Malleable | JA3 fingerprinting | Custom JA3 match Chrome 120 |
| Beacon timing | Jitter 30-300s | Beaconing detection (Zeek) | Below threshold + business hours |
| DNS tunnel | dnscat2, iodine | DNS entropy analysis | High entropy = mirip CDN, hard distinguish |
| Request smuggling | HTTP/2 desync | WAF body inspect | H2 framing bypass = proxy blind |

## 4. CVE Prioritas Network (2024-2026)

| CVE | Target | Impact | Red Team Value |
|-----|--------|--------|----------------|
| CVE-2024-3400 | PAN-OS GlobalProtect | Pre-auth RCE | Gateway compromise → intercept traffic |
| CVE-2024-21410 | Exchange NTLM Relay | Relay → DA | Network-layer relay → domain compromise |
| CVE-2023-20273 | Cisco IOS XE | Web UI RCE | Router/switch implant → traffic redirect |

## 5. Referensi
- MITRE ATT&CK Network Tactics — https://attack.mitre.org/tactics/TA0002/
- Zeek Network Security Monitoring — https://zeek.org/
- Suricata IDS — https://suricata.io/
- Bettercap (MITM toolkit) — https://www.bettercap.org/
---

audited
---
