---
tags:
  - network-security
  - blue-team
  - red-team
  - osi
  - firewall
  - social-engineering
aliases:
  - Network Security
  - OSI Layer Hierarchy
  - Network OSI
created: 2026-04-25
status: operational
cssclasses:
  - wide-table
---

# 🌐 NETWORK SECURITY — OSI Layer 1–8

> OSI Model (Layer 1–7) + Layer 8 tidak resmi yang justru paling sering jebol. Setiap layer punya threat, defender, dan attacker masing-masing. Satu serangan bisa menembus satu layer dan cascade ke layer lain.

> [!info] Cara Baca
> Layer 1 = paling fisik (kabel). Layer 7 = paling abstrak (aplikasi). Layer 8 = manusia. Kolom Blue Team = pertahanan. Kolom Red Team = serangan. Baca dari bawah ke atas untuk memahami attack surface secara sistematis.

---

## Tabel Threat per OSI Layer

| OSI Layer      | Nama Layer             | ☣️ Threat yang Bersarang                                                               | 🔵 Blue Team (Defender)                                                                                | 🔴 Red Team (Attacker)                                                        |
| -------------- | ---------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| **Layer 1**    | Physical               | Tap kabel fisik, hardware keylogger, evil maid attack, rogue device ditempel ke switch | Physical security, tamper-evident seal, port lock USB, CCTV rack server                                | LAN Tap (Throwing Star), USB Rubber Ducky, O.MG Cable                         |
| **Layer 2**    | Data Link              | ARP Poisoning, MAC Spoofing, VLAN Hopping, rogue switch                                | 802.1X NAC, Dynamic ARP Inspection (DAI), port security, private VLAN                                  | Ettercap, Bettercap, Yersinia (VLAN attack)                                   |
| **Layer 3**    | Network                | IP Spoofing, BGP Hijack, ICMP Tunnel (data exfil lewat ping), route poisoning          | Firewall stateful, BCP38 ingress filtering, BGP route filtering (RPKI)                                 | Scapy, BGP hijack nation-state (China Telecom incidents), iodine (DNS tunnel) |
| **Layer 4**    | Transport              | TCP SYN Flood, port scanning, session hijacking, UDP amplification DDoS                | IPS/IDS (Suricata, Snort), rate limiting, SYN Cookie, Anycast DDoS mitigation                          | Nmap, Masscan, hping3, Mirai botnet                                           |
| **Layer 5–6**  | Session / Presentation | SSL Stripping, TLS Downgrade Attack, rogue certificate, cert pinning bypass            | HSTS Preload, certificate pinning, TLS 1.3 enforcement, CT log monitoring                              | SSLstrip2, MITM frameworks, Burp Suite (cert spoof)                           |
| **Layer 7**    | Application            | SQLi, XSS, RCE, API abuse, SSRF, deserialisasi berbahaya, Log4Shell                    | WAF (ModSecurity, Cloudflare), SAST/DAST, bug bounty, patch management                                 | Burp Suite Pro, SQLmap, Nuclei, ffuf, exploit-db                              |
| ☠️ **Layer 8** | Human _(tidak resmi)_  | Phishing, Spear Phishing, Vishing, Pretexting, BEC (Business Email Compromise)         | Security awareness training, MFA wajib, anti-phishing gateway (Proofpoint), simulasi phishing internal | GoPhish, Social Engineering Toolkit (SET), OSINT (Maltego, SpiderFoot)        |

> [!tip] Layer 8 adalah Layer Paling Berbahaya
> Tidak ada firewall yang bisa memblokir manusia yang sudah ditipu. Social engineering melewati semua kontrol teknis di Layer 1–7 sekaligus.

---

## Peta Posisi Threat — Network

```
Layer 1  │ Physical          → Tap kabel, rogue device
Layer 2  │ Data Link         → ARP Poison, VLAN Hop
Layer 3  │ Network           → IP Spoof, BGP Hijack
Layer 4  │ Transport         → SYN Flood, DDoS
Layer 5-6│ Session/Present.  → SSL Strip, TLS Downgrade
Layer 7  │ Application       → SQLi, XSS, RCE, Log4Shell
Layer 8  │ ← MANUSIA DI SINI → Phishing bypass semua layer di atas
```

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[ENDPOINT_SECURITY]] — CPU Ring & Boot Chain Threat
- [[DATA_RECOVERY]] — Partition & Data Recovery Level 0–7
- [[OSINT_RF_HIERARCHY]] — OSINT & RF yang melintas di atas jaringan
- [[INFRASTRUKTUR_CLOUD]] — Cloud networking & Zero Trust
- [[KRIPTOGRAFI_BIOMETRIK]] — Enkripsi yang melindungi Layer 5–7
- [[Search Hierarchy]] — Information Access via jaringan

---

_Network Security | OSI Layer 1–8 · Blue Team vs Red Team per Layer_
