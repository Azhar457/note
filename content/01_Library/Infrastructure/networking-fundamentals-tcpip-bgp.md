---
title: "Networking Fundamentals: TCP/IP, Routing & BGP untuk Security Engineer"
tags:
  - networking
  - tcpip
  - bgp
  - routing
  - osi-layer
  - fundamentals
aliases:
  - "networking-fundamentals"
  - "tcpip-deepdive"
  - "bgp-routing"
created: "2026-07-15"
updated: "2026-07-15"
status: draft
cssclasses:
  - wide-table
---

> [!abstract] Kenapa Security Engineer Wajib Paham Networking
> Vault ini punya banyak catatan security — DNS tunneling, ARP spoofing, CGNAT attribution, WAF, IDS/IPS — tapi semuanya berasumsi lo udah paham layer 3/4. Catatan ini nge-fill gap itu: dari packet flow di kernel sampai BGP hijacking yang jadi attack vector nyata. Tanpa ini, lo cuma pake tool tanpa ngerti kenapa tool itu bisa detect sesuatu.

---

## 🧱 1. TCP/IP Stack — Bukan Sekadar "Layer 4"

### 1.1 Packet Lifecycle

```
[Application] → [Transport] → [Network] → [Link] → Wire
     ↑              ↑              ↑           ↑
   HTTP/TLS       TCP/UDP        IP+ICMP     Ethernet/WiFi
```

**Yang sering dilupain security engineer:**

- **TCP state machine** — SYN, SYN-ACK, ACK, FIN, RST. Setiap state bisa diexploit: SYN flood, RST injection, TCP reset attack.
- **Window scaling & SACK** — Digunakan buat evading IDS. Attacker bisa fragment TCP stream biar signature detection gagal.
- **TFO (TCP Fast Open)** — Bisa dipake buat data exfiltration via SYN packet.

### 1.2 IP Fragmentation & MTU

```
Ethernet MTU: 1500 bytes
IP frag offset: 13-bit field → max 8192 fragments per packet
```

**Attack vector:** IP fragmentation overlap → IDS/IPS gagal reassemble → packet bypass. Lihat [[ids-ips-waf-nsm-comparison]] untuk deteksi fragmentation attack.

### 1.3 TCP State Machine untuk Detection

```
CLOSED → SYN_SENT → ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → TIME_WAIT → CLOSED
         → LISTEN → SYN_RCVD → ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED
```

Setiap state transition bisa dimonitor. Tools seperti [[ebpf-beyond-security]] bisa hook TCP state changes buat detect:

- **SYN flood** — banyak SYN_SENT tanpa ESTABLISHED
- **Port scan** — SYN → RST pattern dari satu source
- **Connection hijack** — RST injection dengan sequence number tebakan

---

## 🌐 2. Routing & BGP — Attack Surface yang Jarang Dibahas

### 2.1 BGP Basics

BGP = path-vector protocol. Bedanya dengan OSPF/EIGRP: BGP gak pake metric, tapi **path attributes** (AS_PATH, LOCAL_PREF, MED).

```
AS 64501 ── BGP ── AS 64502 ── BGP ── AS 64503
   |                    |                    |
  ISP A               ISP B               ISP C
```

### 2.2 BGP Attack Vectors

| Attack            | Mekanisme                            | Real Case                                 |
| ----------------- | ------------------------------------ | ----------------------------------------- |
| **BGP Hijacking** | Advertise prefix yang bukan milik lo | 2018 — MyEtherWallet DNS via BGP hijack   |
| **Route Leak**    | AS_PATH manipulation                 | 2019 — Google traffic lewat China Telecom |
| **RPKI bypass**   | Attacker publish ROA palsu           | Belum banyak, tapi growing                |

**Mitigasi:** RPKI + BGPsec + IRR filtering. Lihat [[dns-fundamentals-bind9]] untuk DNS layer defense.

---

## 🔗 3. Koneksi ke Catatan Lain

- [[network-security]] — top-level security, catatan ini jadi fondasi layer 3/4-nya
- [[dns-tunneling-deepdive]] — butuh paham TCP/UDP port + DNS over TCP
- [[cgnat-attribution-deepdive]] — CGNAT = NAT di layer 3, butuh paham IP masquerade
- [[ids-ips-waf-nsm-comparison]] — semua detection tool ini kerja di layer 3-7
- [[waf-reverse-proxy-deepdive]] — WAF duduk di antara layer 3 (routing) dan layer 7 (HTTP)

## ✅ Checklist

- [ ] Bisa explain TCP 3-way handshake + sequence number
- [ ] Bisa bedain TCP vs UDP kapan pake yang mana
- [ ] Paham BGP path selection (AS_PATH, LOCAL_PREF, MED)
- [ ] Tahu cara detect BGP hijack (BGPMon, RIPE RIS)
- [ ] Bisa setup iptables/nftables rules based on layer 3/4
