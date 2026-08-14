---
title: Attack Perspective — Computer Networks (Red Team)
tags:
- attack
- red-team
- network
- tcp-ip
- dns
- bgp
- vpn
- firewall-bypass
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Computer Networks — Perspektif Penyerang

> Network protocol = foundation dari komunikasi. Red team eksploitasi protocol weakness: TCP RST injection, DNS hijack, BGP hijack, VPN tunnel abuse, firewall bypass.

## 1. Attack Surface Network Protocol

| Protokol | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **TCP** | RST injection, session hijack, SYN flood, desync | T1490 | hping3, scapy, nmap | Spoofed source (blind inject) | IDS detect — tapi spoof = hard attribute |
| **DNS** | DNS hijack, cache poison (Kaminsky), zone transfer, tunneling | T1071.004 | dnscat2, iodine, dnsmasq spoof | DNS tunnel = high entropy → mimic CDN | DNS audit jarang real-time |
| **BGP** | Route hijack, AS path injection, RPKI bypass | T1490 | BGP inject, FRRouting | Traffic redirect = silent | RPKI belum universal |
| **HTTP/2** | Request smuggling (H2 desync), stream abuse | T1190 | Burp Suite, manual | H2 framing bypass = proxy blind | WAF tidak inspeksi H2 framing |
| **TLS** | Downgrade, MITM (cert spoof), SNI abuse, domain fronting | T1557 | sslstrip, MITMproxy | Domain fronting = legit CDN edge | NGFW SSL inspect — tapi CDN = bypass |
| **VPN (WireGuard/IPsec)** | Key exchange downgrade, PSK brute, client config theft | T1557 | WireGuard config extract, hashcat -m 12900 | Config theft → silent connect | VPN audit = connection event only |
| **SSH** | Key theft, agent forwarding abuse, known_hosts pivot | T1021.004 | ssh-keygen, ssh-agent hijack | Stolen key = legit auth | SSH audit = connection only |
| **SMTP** | Open relay, spoof, phishing relay, DKIM/SPF bypass | T1566 | swaks, sendemail | Spoof via open relay | SPF/DKIM = partial (not enforced everywhere) |
| **ICMP** | Tunnel (ICMP payload), ping sweep hidden | T1571 | icmptunnel, ptunnel | ICMP tunnel = mimic ping | IDS jarang monitor ICMP payload |

## 2. DNS Attack Chain

```
Recon: DNS enum → subdomain, MX, TXT, NS, SOA
 ├── dig axfr target.com (zone transfer — jika di-enable)
 ├── dnsenum, fierce, amass → subdomain brute
 └── SecurityTrails → DNS history
 ↓
Attack Option 1 — Cache Poisoning (Kaminsky):
 ├── Spoof DNS response → cache → inject malicious record
 └── Race legitimate response → victim cache → redirect
 ↓
Attack Option 2 — DNS Tunneling (C2):
 ├── dnscat2 → encode C2 data di subdomain
 ├── query: [base32 payload].c2.attacker.com → attacker DNS server
 └── Response: TXT record → command back
 ↓
Attack Option 3 — Domain Fronting (C2):
 ├── SNI = legitimate CDN domain (Cloudflare, Azure)
 ├── Host header = redirector domain (C2)
 └── CDN edge → forward ke C2 → target return = CDN IP
 ↓
Persistence: DNS record backdoor (if domain admin) → CNAME → attacker
```

## 3. BGP Hijack Chain

```
Target: Specifik prefix → traffic redirect
 ↓
Preparation:
 ├── Compromise router (CVE-2023-20273 Cisco IOS XE)
 ├── Atau: upayakan AS yang tidak dipakai (unused AS number)
 └── Atau: RPKI-invalid prefix (jika RPKI tidak di-enforce)
 ↓
Announce: BGP announce target prefix dari attacker AS
 ├── AS path pendek → attract traffic
 └── Traffic yang menuju target prefix → redirect ke attacker
 ↓
Intercept: Attacker = MITM
 ├── Pass-through (transparent MITM) → traffic tembe ke target
 ├── Downgrade TLS → strip SNI → inject cert
 └── Hijack specific destination → exploit server
 ↓
Evasion: BGP hijack = silent (routing protocol legit) — RPKI gap = no alert
 ↓
Rollback: Withdraw BGP announcement → traffic kembali normal → no trace
```

## 4. Firewall/VPN Bypass

| Kontrol Defender | Red Team Bypass | Teknik |
|-------------------|----------------|--------|
| **Firewall (port block)** | Tunnel via allowed port (443, 53, 80) | WireGuard, dnscat2, icmptunnel |
| **NGFW (DPI + SSL inspect)** | Domain fronting + TLS 1.3 ECH | SNI = CDN, Host = C2, ECH = encrypt SNI |
| **Proxy (explicit)** | PAC file hijack, proxy bypass via CDN | Browse via CDN-hosted proxy |
| **VPN (split tunnel)** | DNS leak, metadata leak via allowed domain | Data exfil via allowed domain API |
| **DLP (Data Loss Prevention)** | Steganography, encoding, chunked exfil | Data embed di image/audio, base32 chunk DNS |
| **Outbound whitelist** | Cloud API exfil (AWS S3, Azure Blob) | rclone → cloud storage → legit domain |
| **DNS sinkhole** | Alternative DNS resolver (DoH/DoT) | curl --doh-url, Firefox DoH |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **scapy** | Packet crafting (TCP, DNS, ICMP, custom protocol) |
| **hping3** | TCP flood, RST inject, SYN flood |
| **dnscat2** | DNS tunnel C2 |
| **iodine** | DNS tunnel (IP-over-DNS) |
| **icmptunnel** | ICMP tunnel |
| **WireGuard** | VPN tunnel (UDP, port 51820 atau custom) |
| **Chisel / ligolo-ng** | TCP tunnel over HTTP/WebSocket (bypass firewall) |
| **BGP tooling** | FRRouting, exabgp (BGP announce/inject) |

## 6. Referensi
- scapy — https://scapy.net/
- dnscat2 — https://github.com/iagox86/dnscat2
- iodine — https://github.com/yarrick/iodine
- Domain Fronting — https://www.cobaltstrike.com/help-malleable-c2
- BGP Hijacking — https://www.caida.org/catalog/papers/2014_bgp_hijacking/