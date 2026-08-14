---
title: 'Networking Fundamentals: TCP/IP, Routing & BGP untuk Security Engineer'
tags:
- networking
- tcpip
- bgp
- routing
- osi-layer
- fundamentals
- library
aliases:
- tcpip-deepdive-security
- bgp-routing-attack-surface
created: '2026-07-15'
updated: '2026-07-15'
status: pending
cssclasses:
---

# 🌐 Networking Fundamentals: TCP/IP, Routing & BGP untuk Security Engineer

> Vault ini punya banyak catatan security — [[dns-tunneling-deepdive]], [[arp-spoofing-incident-addendum]], [[cgnat-attribution-deepdive]], [[ids-ips-waf-nsm-comparison]] — tapi semuanya berasumsi lo udah paham layer 3/4. Pada kenyataannya, sebagian besar attack vector keamanan jaringan berakar pada celah di TCP state machine, IP fragmentation, atau BGP route leaks. Catatan ini nge-fill gap itu: dari packet flow di kernel, TCP state machine untuk detection, sampe BGP hijacking yang jadi attack vector nyata di wild internet. Tanpa fondasi ini, lo cuma pake tool tanpa ngerti kenapa tool itu bisa detect — atau lebih parah, gak bisa bedain false positive dari serangan real.

> [!info] Posisi di Vault
> Catatan ini adalah **fondasi layer 3/4** untuk semua catatan security networking di vault. Baca ini dulu sebelum [[network-security]], [[dns-tunneling-deepdive]], atau [[ids-ips-waf-nsm-comparison]]. Juga terhubung dengan [[infrastructure-administrator]] (ops networking) dan [[ebpf-beyond-security]] (kernel-level packet introspection).

---

## Daftar Isi

- [[#1. TCP/IP Stack — Packet Lifecycle]]
- [[#2. IP Fragmentation, MTU & Evasion]]
- [[#3. TCP State Machine untuk Detection]]
- [[#4. UDP — The Invisible Attack Surface]]
- [[#5. Routing Fundamentals — OSPF, IS-IS, BGP]]
- [[#6. BGP Attack Vectors — Hijacking & Route Leaks]]
- [[#7. Network Segmentation & Microsegmentation]]
- [[#8. NAT, CGNAT & Carrier-Grade Tracking]]
- [[#9. iptables/nftables — Packet Filtering dari Layer 3]]
- [[#10. Tools untuk Network Security Engineer]]
- [[#Homelab: Packet Analysis Playground]]
- [[#Tabel Perbandingan]]
- [[#🔗 Koneksi ke Catatan Lain]]
- [[#✅ Checklist]]
- [[#Roadmap Belajar]]

---

## 1. TCP/IP Stack — Packet Lifecycle

### 1.1 Dari Wire ke Application

```
[Wire] → [NIC Driver] → [Kernel (Netfilter/XDP)] → [Socket] → [Application]
    |           |               |                      |            |
 Layer 1     Layer 2        Layer 3-4               Layer 5     Layer 7
 (Signal)   (Ethernet)    (IP/TCP/UDP)             (Session)   (HTTP/DNS)
```

Tiap layer punya **headers** yang ditambahkan (encapsulation) dan **attack surface** sendiri:

| Layer | Protocol | Header Size | Attack Vector Umum |
|-------|----------|-------------|-------------------|
| L2 — Ethernet | MAC | 14 byte | MAC spoofing, ARP poison, STP manipulation |
| L3 — IP | IPv4/IPv6 | 20-60 byte | IP spoofing, fragmentation overlap, TTL abuse |
| L4 — TCP | TCP | 20-60 byte | SYN flood, RST injection, sequence prediction |
| L4 — UDP | UDP | 8 byte | UDP flood, DNS amplification, SSRF |
| L7 — App | HTTP/DNS/... | Variable | SQLi, XSS, RCE (ini urusan WAF) |

### 1.2 Linux Kernel Packet Processing

```nginx
          ┌────────────────────────────────┐
          │         Application            │
          │  (nginx, python, curl)         │
          └──────────────┬─────────────────┘
                         │ Socket API (syscall)
          ┌──────────────▼─────────────────┐
          │        TCP/UDP Layer           │
          │  (kernel: tcp_v4_rcv, udp_rcv) │
          └──────────────┬─────────────────┘
                         │
          ┌──────────────▼─────────────────┐
          │     IP Layer (netfilter)       │
          │  PREROUTING → FORWARD → POSTR. │
          │  INPUT → LOCAL → OUTPUT        │
          └──────────────┬─────────────────┘
                         │
          ┌──────────────▼─────────────────┐
          │     Network Driver (NIC)       │
          │  RX ring → IRQ → NAPI poll     │
          └────────────────────────────────┘
```

**Poin penting untuk security engineer:**
- **Netfilter hooks** — tempat iptables/nftables bekerja. Lima hook: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING. Setiap hook bisa dipasangi rule untuk DROP, REJECT, LOG, atau NAT.
- **XDP (eXpress Data Path)** — hook sebelum netfilter, di BPF program. Bisa drop packet di level driver, sebelum kernel menyentuhnya. Ini yang dipake [[ebpf-kernel-security]] dan [[ebpf-beyond-security]] untuk DDoS mitigation kecepatan tinggi.
- **TLS** — terjadi di application layer (OpenSSL, rustls), kernel gak lihat isi. WAF harus terminate TLS dulu baru bisa inspect.

### 1.3 TCP Three-Way Handshake — Anatomi

```
CLIENT                    SERVER
   |                         |
   |────── SYN (seq=x) ──────→|  LISTEN
   |                         |
   |←── SYN-ACK (seq=y, ack=x+1)──|  SYN_RCVD
   |                         |
   |────── ACK (seq=x+1, ack=y+1)──→|  ESTABLISHED
   |                         |
   |←─────── Data ──────────→|  ESTABLISHED
```

**Kenapa ini penting buat detection:**
- **SYN flood** — attacker kirim banyak SYN tanpa pernah completing handshake. Server allocates resources (TCB) buat tiap SYN → exhaustion. Mitigasi: SYN cookies (kernel default), rate limiting, XDP drop.
- **Sequence number prediction** — jika attacker bisa predict seq number, dia bisa inject RST atau data palsu ke dalam koneksi. Kernel modern pake RFC 5961 (challenge ACK) untuk mitigasi.
- **TCP Fast Open (TFO)** — kirim data di SYN packet. Legitimate untuk latency reduction, tapi bisa dipake buat data exfiltration via SYN packet yang gak dilog dengan baik.

### 1.4 TCP State Transition Diagram

```
                    ┌──────────┐
                    │  CLOSED  │
                    └────┬─────┘
                         │ passive open
                    ┌────▼─────┐
                    │  LISTEN  │
                    └────┬─────┘
                         │ active open (SYN)
                    ┌────▼─────┐         ┌──────────┐
          ┌─────────│ SYN_SENT │         │ SYN_RCVD │←──────────┐
          │         └────┬─────┘         └────┬──────┘          │
          │              │ SYN+ACK            │ ACK             │
          │         ┌────▼────────────────────▼──────┐          │
          │         │         ESTABLISHED            │          │
          │         └────┬───────────────────┬───────┘          │
          │              │ close             │ close            │
          │         ┌────▼─────┐        ┌────▼──────┐           │
          │         │ FIN_WAIT1│        │ CLOSE_WAIT│           │
          │         └────┬─────┘        └────┬──────┘           │
          │              │ ACK               │ close            │
          │         ┌────▼─────┐        ┌────▼──────┐           │
          │         │ FIN_WAIT2│        │  LAST_ACK │           │
          │         └────┬─────┘        └────┬──────┘           │
          │              │ FIN               │ ACK              │
          │         ┌────▼─────┐        ┌────▼──────┐           │
          │         │ TIME_WAIT│────────│   CLOSED  │           │
          │         └────┬─────┘  timeout             (back to top)
          │              │ 2*MSL
          │              ▼
          │         ┌──────────┐
          └────────→│  CLOSED  │
                     └──────────┘
```

**Setiap state transition adalah potensi detection signal:**

| Signal | Pattern | Kemungkinan |
|--------|---------|-------------|
| SYN → RST (tanpa SYN-ACK) | Port scan (stealth SYN scan) | 🟥 High — hampir pasti scan |
| SYN → SYN-SENT → timeout | Host down atau firewall block | 🟨 Medium — bisa juga network issue |
| Banyak SYN_SENT ke port berbeda | Horizontal port scan | 🟥 High |
| Banyak SYN ke port sama dari IP beda | DDoS atau distributed scan | 🟥 High |
| FIN_WAIT1 dalam jumlah besar | Attacker kirim FIN tanpa ACK | 🟨 Medium |
| ESTABLISHED tiba-tiba → RST | Session hijack / RST injection | 🟧 Medium-High |

---

## 2. IP Fragmentation, MTU & Evasion

### 2.1 Mekanisme Fragmentasi

Ketika packet melebihi MTU (Maximum Transmission Unit) dari suatu link, IP layer akan memecahnya menjadi fragment:

```
Original: [IP hdr (20)] [TCP hdr (20)] [Data (1500)] = 1540 byte
  ↓ MTU = 1500 via ethernet

Fragment 1: [IP hdr (20)] [More Fragments=1] [Offset=0]   [TCP hdr (20)] [Data (1460)] = 1480
Fragment 2: [IP hdr (20)] [More Fragments=0] [Offset=185] [Data (40)]                  = 60
```

**Field kunci di IP header fragment:**
- **Identification** (16-bit) — semua fragment dari packet yang sama punya ID sama
- **More Fragments (MF)** — 1 = ada fragment berikutnya, 0 = fragment terakhir
- **Fragment Offset** (13-bit) — posisi fragment ini dalam packet original (diukur dalam 8-byte unit)

### 2.2 Fragmentation Attack Vectors

| Attack | Cara Kerja | Deteksi |
|--------|-----------|---------|
| **Tiny Fragment** | Fragment pertama terlalu kecil untuk muat TCP header → firewall lewatin | Firewall harus reassemble sebelum rule matching |
| **Fragment Overlap** | Fragment kedua menimpa data fragment pertama (overwrite TCP header) | IDS harus deteksi overlap via reassembly |
| **Fragment Flood** | Kirim banyak fragment tanpa fragment terakhir (MF=1 terus) → target habis memory nunggu | Rate limit per source, timeout reassembly |
| **Teardrop** | Fragment overlap yang salah (offset inconsistent) → crash stack | Patched sejak kernel 2.0.x, tapi masih muncul di IoT |

**Mitigasi modern:**
- **Path MTU Discovery (PMTUD)** — kernel detect MTU path otomatis. Tapi sering broken karena ICMP "Fragmentation Needed" diblok firewall.
- **TCP MSS Clamping** — proxy ngatur MSS (Maximum Segment Size) biar gak perlu fragmentasi.
- **DF (Don't Fragment) bit** — set DF → kernel kirim ICMP "too big" instead of fragmenting. Problem: ICMP sering diblok.

```nginx
# Nginx TCP MSS clamping
server {
    listen 443 ssl;
    tcp_nodelay on;
    # Proxy ngirim MSS 1400 → gak perlu fragmentasi
    proxy_connect_timeout 60;
}
```

### 2.3 Fragmentasi vs IDS/IPS

Ini **masalah klasik** buat security engineer:

```
WAF/IDS melihat:
  Fragment 1: GET /index.html HTTP/1.1
  Fragment 2: Host: evil.com%00payload

Masalah:
  - IDS harus reassemble sebelum match rule
  - Reassembly butuh memory → bisa di-exhaust
  - Overlap fragment → tergantung reassembly policy (BSD, Linux, Windows beda)
```

Teknik ini disebut **IP Fragmentation Attack** atau **FragRoute** (tool klasik). [[ids-ips-waf-nsm-comparison]] bahas lebih detail tentang reassembly policy.

---

## 3. TCP State Machine untuk Detection

### 3.1 Connection Tracking (conntrack)

Kernel Linux punya **conntrack** — tabel yang melacak semua koneksi TCP/UDP/ICMP. Ini fondasi dari stateful firewall.

```bash
# Lihat tabel conntrack
conntrack -L | head -20

# Statistik
conntrack -S

# Contoh output:
# tcp      6 431999 ESTABLISHED src=10.0.0.1 dst=10.0.0.2 sport=443 dport=54321 ...
# udp      17 174 src=10.0.0.1 dst=8.8.8.8 sport=53000 dport=53 ...
```

**State table untuk stateful firewall:**

| State | Arti | Firewall Action |
|-------|------|-----------------|
| NEW | Packet pertama, belum lihat response | Allow? (tapi hati-hati) |
| ESTABLISHED | Bagian dari koneksi existing | ✅ Allow |
| RELATED | Terkait koneksi existing (ICMP error, FTP data) | ✅ Allow (dengan caution) |
| INVALID | Paket corrupted atau state gak cocok | ❌ Drop — biasanya attack |
| UNTRACKED | Lewat dari rule NOTRACK | Tergantung rule |

### 3.2 SYN Cookies — Defense Against SYN Flood

Saat SYN flood terjadi, kernel bisa enable SYN cookies:

```bash
# Cek status
sysctl net.ipv4.tcp_syncookies
# Aktifkan
sysctl -w net.ipv4.tcp_syncookies=1
```

**Cara kerja:** Alih-alih alloc TCB (Transmission Control Block) buat setiap SYN, kernel encode informasi koneksi di sequence number SYN-ACK. Jika ACK balik, kernel decode dan alloc TCB hanya untuk koneksi legitimate.

**Trade-off:** SYN cookies mengorbankan beberapa fitur TCP (large window scaling, SACK, TFO) demi defense.

### 3.3 Practical Detection Script

```bash
#!/bin/bash
# Detect TCP scan via /proc/net/tcp
# Pola: banyak SYN_RECV dari IP berbeda ke port yang sama

echo "SYN_RECV connections:"
cat /proc/net/tcp | awk '{print $2, $3, $4}' | grep "0A"  # 0A = SYN_RECV state

# Deteksi port scan via tcpdump
tcpdump -i eth0 -nn 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) == 0' \
  | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn | head -10
```

---

## 4. UDP — The Invisible Attack Surface

### 4.1 UDP vs TCP untuk Security

| Aspek | TCP | UDP |
|-------|-----|-----|
| Stateful | ✅ Ya (sequence, ack) | ❌ Tidak (fire-and-forget) |
| Connection tracking | Mudah (conntrack) | Sulit (timeout-based) |
| Spoofing | Sulit (seq num) | Mudah (source IP bisa palsu) |
| Amplification | Tidak mungkin | ✅ Mungkin (DNS, NTP, Memcached) |
| Fragmentasi | Hanya setelah handshake | Kapan saja |

### 4.2 UDP Amplification Attack

Ini **attack vector paling merusak** di internet:

```
Attacker            DNS Server (open resolver)            Victim
   |                         |                               |
   |── spoofed src=victim ──→|                               |
   |   query: ANY isc.org    |                               |
   |    (60 bytes)           |                               |
   |                         |── response: 3500 bytes ──────→|
   |                         |   (58x amplification!)        |
```

**Mitigasi:**
- **BCP38** — jangan forward packet dengan source IP yang bukan milik jaringan lo (ingress filtering)
- **Rate limit per source IP** untuk DNS/NTP response
- **Disable open resolvers** — jangan biarkan DNS server lo menjawab query dari arbitrary source

### 4.3 DNS over UDP vs TCP

```nginx
# DNS biasanya UDP port 53
# Tapi kalo response > 512 byte → fallback ke TCP (sejak EDNS0)
# DNS over TCP == lebih susah spoof, tapi lebih lambat

# Detection: spike di DNS TCP paket volume
# Bisa berarti: DNS tunneling, zone transfer, atau amplification attempt
```

[[dns-tunneling-deepdive]] bahas ini lebih dalam.

---

## 5. Routing Fundamentals — OSPF, IS-IS, BGP

### 5.1 IGP vs EGP

```
IGP (Interior Gateway Protocol)         EGP (Exterior Gateway Protocol)
  Dalam satu AS                            Antar AS
  ├── OSPF (link-state, Dijkstra)         └── BGP (path-vector)
  ├── IS-IS (link-state, ISO CLNP)
  └── EIGRP (Cisco proprietary, hybrid)
```

**Untuk security engineer:** IGP attacks biasanya internal (rogue router advertisement), sedangkan BGP attacks bisa mempengaruhi routing global.

### 5.2 OSPF — Link State Routing

OSPF menggunakan **LSA (Link State Advertisement)** yang didistribusikan ke semua router di area:

```
Keamanan OSPF:
  - OSPF authentication (MD5/HMAC-SHA)
  - Tanpa auth → attacker inject LSA palsu → blackhole routing
  - Passive interface → jangan kirim OSPF hello ke segmen yang gak perlu
```

### 5.3 BGP — The Internet's Routing Protocol

BGP adalah **path-vector protocol** — bukan berdasarkan metric seperti OSPF, tapi berdasarkan **path attributes** yang menentukan path selection.

```
BGP Decision Process (urutan prioritas):
  1. Weight (Cisco proprietary, tertinggi menang)
  2. LOCAL_PREF (tertinggi menang)
  3. Originate (route yang di-generate sendiri)
  4. AS_PATH (terpendek menang)
  5. ORIGIN (IGP < EGP < INCOMPLETE)
  6. MED (terendah menang)
  7. eBGP > iBGP
  8. IGP metric ke next-hop (terendah menang)
  9. Router ID (terendah menang, tiebreaker)
```

**BGP Message Types:**

| Type | Function | Size |
|------|----------|------|
| OPEN | Establish session | ~30 bytes |
| UPDATE | Advertise/withdraw routes | Variable (up to 4096) |
| NOTIFICATION | Error reporting | ~20 bytes |
| KEEPALIVE | Session liveness | 19 bytes |
| ROUTE-REFRESH | Request re-advertisement | ~23 bytes |

### 5.4 BGP Session Protection

```bash
# Konfigurasi BGP di FRRouting (frr)
router bgp 64501
  bgp router-id 10.0.0.1
  neighbor 10.0.0.2 remote-as 64502
  neighbor 10.0.0.2 password mysecret   # TCP MD5 signature
  neighbor 10.0.0.2 timers 10 30         # keepalive 10s, hold 30s
  !
  address-family ipv4 unicast
    network 203.0.113.0/24
    neighbor 10.0.0.2 prefix-list PL-IMPORT import
    neighbor 10.0.0.2 prefix-list PL-EXPORT export
  exit-address-family
!
ip prefix-list PL-IMPORT seq 5 deny 0.0.0.0/0 le 8      # Jangan terima /1-/8
ip prefix-list PL-IMPORT seq 10 permit 0.0.0.0/0 ge 24   # Hanya /24+
```

**Best practice security BGP:**
- **TTL Security (GTSM)** — set TTL=255, drop kalo <254 (cegah remote injection)
- **Prefix filtering** — jangan advertise prefix yang bukan milik lo, jangan terima prefix yang seharusnya gak lewat
- **Max prefix limit** — putus session jika neighbor advertise > N prefix
- **RPKI (Resource Public Key Infrastructure)** — validasi origin AS dari prefix
- **BGPsec** — path validation cryptographic (masih limited deployment)

---

## 6. BGP Attack Vectors — Hijacking & Route Leaks

### 6.1 BGP Hijacking

Attacker (rogue AS) mengumumkan prefix yang bukan miliknya, lalu traffic dialihkan:

```
Normal Route:
  Client → AS1 → AS2 → AS5 → AS7 → Server (203.0.113.0/24)

Hijacked Route:
  Client → AS1 → AS3 → Attacker (203.0.113.0/24 via AS3)
  Attacker → proxy → AS7 → Server (forward traffic, man-in-the-middle)
```

**Real incidents:**
- **2008 — Pakistan YouTube block** — Pakistan Telecom advertise /22 YouTube prefix; traffic global dialihkan
- **2018 — MyEtherWallet** — AWS DNS server BGP hijack → DNS redirect ke phishing site
- **2019 — China Telecom hijack** — 37 menit route leak via Google, Amazon, Akamai traffic
- **2024 — CBE (Ethiopia)** — BGP hijack mencuri traffic cryptocurrency exchange

### 6.2 Route Leak

Route leak terjadi ketika AS mengumumkan route ke ISP upstream yang seharusnya hanya untuk internal/transit:

```
Leak pattern:
  AS64501 (customer) ← AS64502 (transit) ← AS64503 (large ISP)
  
  Leak: AS64501 advertise route "I can reach anything" via default route ke AS64502
  → AS64502 percaya → semua traffic ke 0.0.0.0/0 lewat AS64501
  → AS64501 overload, traffic drop
```

### 6.3 Mitigation Techniques

| Technique | Deskripsi | Coverage |
|-----------|-----------|----------|
| **RPKI (ROA)** | Signed object yang bind prefix → origin AS | 40% global (tumbuh) |
| **BGPsec** | Sign tiap AS hop dalam path | < 1% deployment |
| **IRR (Internet Routing Registry)** | Database rute legit, masih manual | Outdated sering |
| **Prefix lists** | Filter manual by AS + prefix | Best effort |
| **AS_PATH filtering** | Jangan terima prefix dengan AS_PATH yang suspicious | Manual setup |
| **BGP community** | Tag route dengan community → filter otomatis | Operational agreement |

```bash
# RPKI validation dengan Routinator
docker run -p 3323:3323 nlnetlabs/routinator --strict --rtr 3323

# Di FRR:
router bgp 64501
  neighbor 10.0.0.2 rpki             # Enable RPKI untuk neighbor
  rpki table 10.0.0.3 3323           # Routinator server
  !
  route-map RPKI-FILTER permit 10
    match rpki valid                  # Hanya terima route yang valid
  route-map RPKI-FILTER deny 20
    match rpki invalid                # Tolak yang invalid
```

---

## 7. Network Segmentation & Microsegmentation

### 7.1 Traditional Segmentation (VLAN)

```
VLAN 10 — Management (10.0.10.0/24)
  ├── SSH, RDP, IPMI — hanya dari jumpbox
  └── Firewall: allow only from VLAN 100

VLAN 20 — Production (10.0.20.0/24)
  ├── Web servers, API servers
  └── Firewall: allow 80/443 from WAN, allow DB access to VLAN 30

VLAN 30 — Database (10.0.30.0/24)
  ├── PostgreSQL, Redis, MongoDB
  └── Firewall: allow only from VLAN 20 on port 5432/6379/27017

VLAN 100 — Admin/Jumpbox (10.0.100.0/24)
  ├── SSH bastion, VPN termination
  └── Firewall: allow SSH from WAN via VPN only
```

### 7.2 Microsegmentation (Zero Trust)

Prinsip: **setiap host adalah segmen sendiri**. Dipake di [[zero-trust-security]]:

```nginx
# Di level hypervisor (Proxmox/VMware):
# Setiap VM punya firewall sendiri
# Rules: allow specific L4 flows only

# Contoh: Web VM → DB VM hanya port 5432 TCP
#   Web VM (10.0.20.5): allow out TCP 5432 to 10.0.30.5
#   DB VM (10.0.30.5): allow in TCP 5432 from 10.0.20.5
#   DB VM (10.0.30.5): deny all other inbound
```

**Tools:** [[ebpf-beyond-security]] (Cilium), Istio (sidecar), Calico (K8s)

---

## 8. NAT, CGNAT & Carrier-Grade Tracking

### 8.1 NAT Types

| Type | Behavior | Use Case |
|------|----------|----------|
| **SNAT (Source NAT)** | Ganti source IP + port outbound | Internet access dari LAN |
| **DNAT (Destination NAT)** | Ganti dest IP + port inbound | Port forwarding |
| **MASQUERADE** | SNAT tapi source IP dinamis (PPPoE) | Home router |
| **CGNAT (Carrier-Grade)** | NAT di ISP level, satu IP publik ribuan pelanggan | IPv4 exhaustion |

### 8.2 CGNAT Problem untuk Attribution

```
Satu IP publik (203.0.113.1) → digunakan oleh 1000+ pelanggan
  └── Berdasarkan IP aja, gak bisa bedain siapa yang melakukan request
  └── Butuh log CGNAT (port + timestamp + subscriber ID)
  └── Ini yang dibahas di [[cgnat-attribution-deepdive]]
```

### 8.3 NAT Traversal untuk Security

**STUN/TURN/ICE** — protokol untuk NAT traversal, penting buat [[content-remote-using-webrtc]]:

```
STUN: "What's my public IP:port?"
TURN: "Relay my traffic through your server" (fallback)
ICE: "Pick the best path between STUN and TURN"
```

Dari sisi security: TURN relay bisa jadi **lubang firewall** kalau gak dikonfigurasi dengan baik — relay server bisa dipake buat traffic exfiltration.

---

## 9. iptables/nftables — Packet Filtering dari Layer 3

### 9.1 iptables Chain Flow

```
                    ┌───────────┐
                    │  Routing  │
                    │ Decision  │
                    └─────┬─────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼────┐     ┌────▼────┐     ┌─────▼────┐
    │PREROUTING│     │  INPUT  │     │  FORWARD  │
    └────┬────┘     └────┬────┘     └─────┬────┘
         │               │                │
    ┌────▼────┐     ┌────▼────┐     ┌─────▼────┐
    │ Routing │     │  Local  │     │ Routing  │
    │ Decision│     │Process  │     │ Decision │
    └────┬────┘     └─────────┘     └─────┬────┘
         │                               │
    ┌────▼────┐                      ┌────▼────┐
    │  INPUT  │                      │POSTROUTING│
    └────┬────┘                      └────┬────┘
         │                               │
    ┌────▼────┐                      ┌────▼────┐
    │  Local  │                      │   Out   │
    │Process  │                      │  Wire   │
    └─────────┘                      └─────────┘
```

### 9.2 Practical Rule Set

```bash
# Contoh stateful firewall untuk server web
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH from management VLAN only
iptables -A INPUT -p tcp --dport 22 -s 10.0.100.0/24 -j ACCEPT

# HTTP/HTTPS from anywhere
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Rate limit SSH (prevents brute force)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min -j ACCEPT

# Log and drop everything else
iptables -A INPUT -j LOG --log-prefix "FW-DROP: "
iptables -A INPUT -j DROP
```

### 9.3 eBPF-based Filtering

```c
// XDP program — drop at driver level (sebelum netfilter)
// Ini yang dipake [[ebpf-kernel-security]]
SEC("xdp")
int xdp_drop_ddos(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    struct ethhdr *eth = data;
    
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;
    
    // Drop traffic from known bad IPs
    if (eth->h_proto == htons(ETH_P_IP)) {
        struct iphdr *ip = data + sizeof(*eth);
        if ((void *)(ip + 1) > data_end)
            return XDP_PASS;
        if (ip->saddr == 0x0100007f)  // 127.0.0.1
            return XDP_DROP;
    }
    return XDP_PASS;
}
```

---

## 10. Tools untuk Network Security Engineer

| Tool | Fungsinya | Layer |
|------|-----------|-------|
| **tcpdump** | Packet capture & analysis | L2-L7 |
| **tshark** | CLI Wireshark, protocol dissection | L2-L7 |
| **nmap** | Port scan, service detection | L3-L4 |
| **masscan** | High-speed port scan (10M pps) | L3-L4 |
| **Scapy** | Python packet crafting & injection | L2-L4 |
| **netstat/ss** | Socket statistics | L4-L7 |
| **conntrack** | Connection tracking table | L3-L4 |
| **iptables/nftables** | Packet filtering & NAT | L3-L4 |
| **tc** | Traffic control (QoS, shaping) | L3 |
| **iftop/nload** | Bandwidth monitoring | L2-L4 |
| **BGP.tools** | BGP route lookup & history | L3 |
| **RIPE RIS / RouteViews** | Global routing table | L3 |

---

## Homelab: Packet Analysis Playground

```bash
# 1. Capture TCP handshake
sudo tcpdump -i eth0 -nn 'tcp port 80' -c 10 -X

# 2. Detect SYN flood
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) == 0' \
  | tshark -T fields -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport

# 3. Check fragment overlap (Fragroute-style)
sudo tcpdump -i eth0 -nn 'ip[6] & 0x20 != 0 or ip[6:2] & 0x1fff != 0'

# 4. BGP session monitoring
sudo tcpdump -i eth0 -nn 'tcp port 179'

# 5. DNS amplification check
sudo tcpdump -i eth0 -nn 'udp port 53 and greater 512'
```

---

## Tabel Perbandingan

### Layer 4 vs Layer 7 Filtering

| Aspek | Layer 4 (iptables) | Layer 7 (WAF/Proxy) |
|-------|-------------------|---------------------|
| Kecepatan | 🟢 Kernel level | 🟡 Userspace |
| Visibilitas | ❌ IP:Port only | ✅ Full content |
| State tracking | ✅ conntrack | ✅ Session management |
| Attacker evade | 🟡 IP spoof | ❌ HTTP manipulation |
| Resource usage | Sangat rendah | Moderate to high |
| Contoh tools | iptables, nftables, eBPF | Nginx, ModSecurity, Envoy |

### Routing Protocols

| Aspek | OSPF | IS-IS | BGP |
|-------|------|-------|-----|
| Type | Link-state | Link-state | Path-vector |
| Metric | Cost (bandwidth) | Metric (default 10) | Path attributes |
| Convergence | Fast | Fast | Slow |
| Scalability | Area-based | Level-based | AS-based |
| Auth | MD5/HMAC | HMAC-SHA | TCP MD5 |
| Attack surface | LSA injection | Similar to OSPF | Route hijack/leak |

---

## 🔗 Koneksi ke Catatan Lain

- [[network-security]] — top-level, catatan ini jadi fondasi layer 3/4-nya
- [[dns-tunneling-deepdive]] — butuh paham TCP/UDP port + DNS over TCP
- [[cgnat-attribution-deepdive]] — CGNAT = NAT di layer 3, butuh paham IP masquerade
- [[ids-ips-waf-nsm-comparison]] — semua detection tool ini kerja di layer 3-7
- [[waf-reverse-proxy-deepdive]] — WAF duduk di antara layer 3 (routing) dan layer 7 (HTTP)
- [[ebpf-beyond-security]] — XDP/eBPF hook di layer 2-3, mitigation kernel-level
- [[ebpf-kernel-security]] — packet filtering via eBPF, deep dive kernel network stack
- [[infrastructure-administrator]] — admin networking sehari-hari
- [[dns-fundamentals-bind9]] — DNS di layer 7, tapi transportnya UDP/TCP
- [[wireless-security-deepdive]] — RF layer (L1-L2), beririsan di L3 routing
- [[zero-trust-security]] — microsegmentation = layer 3-4 zero trust implementation
- [[arp-spoofing-incident-addendum]] — ARP = L2, tapi berakibat ke L3 routing

---

## ✅ Checklist

- [ ] Paham TCP 3-way handshake + sequence number + flags
- [ ] Bisa baca tcpdump output dan bedain SYN, SYN-ACK, ACK, RST, FIN
- [ ] Paham conntrack states (NEW, ESTABLISHED, RELATED, INVALID)
- [ ] Bisa setup iptables stateful rule untuk server web
- [ ] Paham perbedaan stateful vs stateless firewall
- [ ] Bisa jelasin IP fragmentation & overlap attack
- [ ] Paham BGP path selection: LOCAL_PREF → AS_PATH → MED
- [ ] Tahu cara detect BGP hijack (RIPE RIS, BGPMon, Cloudflare Radar)
- [ ] Bisa setup prefix list / AS_PATH filter di FRRouting
- [ ] Paham NAT types + CGNAT attribution problem

---

## Roadmap Belajar

```
HARI 1: TCP/IP Fundamentals
  - Baca dokumen ini sampai selesai
  - Capture handshake dengan tcpdump, analisis dengan Wireshark
  - Setup iptables stateful firewall

HARI 2: Advanced TCP Detection
  - Setup suricata/zeek di homelab, lihat alert TCP anomaly
  - Tes SYN flood dengan hping3, lihat SYN cookies effect
  - Analisis fragment overlap dengan Fragroute

HARI 3: Routing & BGP
  - Setup FRRouting di 2 VM, konfigurasi BGP
  - Inject prefix, test path selection
  - Baca RIPE RIS untuk melihat global routing table

HARI 4: BGP Security
  - Setup Routinator (RPKI) di docker
  - Tes BGP hijack dengan prefix yang lo miliki di lab
  - Pelajari IRR and RPKI validation

HARI 5: Integration
  - Setup packet capture pipeline: tcpdump → Suricata → Elasticsearch
  - Tulis Python script dengan Scapy untuk packet injection
  - Review [[ebpf-kernel-security]] untuk kernel-level filtering
```

> [!warning] Bottom Line
> Networking adalah **foundational skill** yang memisahkan security engineer biasa dari yang exceptional. Tanpa paham TCP state machine, lo gak bisa bedain SYN flood dari legitimate traffic spike. Tanpa paham BGP, lo gak akan ngerti kenapa 37 menit route leak bisa mengalihkan traffic Google ke China. Investasi waktu di layer 3/4 adalah **force multiplier** untuk semua skill security lainnya — setiap catatan di vault ini yang menyentuh networking jadi lebih masuk akal setelah lo paham material ini.

> [!tip] Ponytail
> Catatan ini belum mencakup IPv6 secara detail (header format, Neighbor Discovery, RA guard, SLAAC security), MPLS (L3VPN, L2VPN, segment routing), SDN/OpenFlow (controller-based routing), dan VXLAN/GENEVE (network virtualization). Ketika lo udah deploy IPv6 atau bekerja di data center dengan VXLAN, tambahkan catatan terpisah untuk masing-masing topik.
