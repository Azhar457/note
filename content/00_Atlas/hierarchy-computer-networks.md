---
title: "Computer Networks Hierarchy"
tags:
- hierarchy
- computer-networks
- networking
- osi
- tcpip
- routing
- switching
aliases:
- Computer Networks Hierarchy
- OSI Model
- TCP/IP Stack
- Fundamental Networking Map
- From Physical to Application
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 🌐 Computer Networks — Dari Physical Layer ke Application

> [!tip] Jaringan komputer adalah **fondasi dari setiap sistem digital modern**. Catatan ini memetakan **7 lapisan OSI model + 4 lapisan TCP/IP** — bukan dari lensa keamanan (sudah ada hierarchy-network-security), tapi sebagai **fondasi** yang menjelaskan bagaimana bit bergerak dari satu mesin ke mesin lain. Layer 1-4 adalah domain yang sama sekali belum terpetakan vault.

---

## Daftar Isi

1. [[#1. Premise — Networking Adalah Sistem Transportasi Digital]]
2. [[#2. OSI Model vs TCP/IP Stack]]
3. [[#3. Layer 1 — Physical Layer]]
4. [[#4. Layer 2 — Data Link Layer]]
5. [[#5. Layer 3 — Network Layer (IP)]]
6. [[#6. Layer 4 — Transport Layer (TCP/UDP)]]
7. [[#7. Layer 5 — Session Layer]]
8. [[#8. Layer 6 — Presentation Layer]]
9. [[#9. Layer 7 — Application Layer]]
10. [[#10. Routing & Switching]]

---

## 1. Premise — Networking Adalah Sistem Transportasi Digital

Setiap byte yang dikirim melalui jaringan melewati **transformasi 7 lapisan** sebelum mencapai tujuannya:

```
[Application] → HTTP request → ...
[Presentation] → Encryption, encoding
[Session] → Connection management
[Transport] → TCP segments
[Network] → IP packets
[Data Link] → Ethernet frames
[Physical] → Electrical/optical signals
```

**Kenapa ini BOLEV besar di vault:**
- Ada `hierarchy-network-security` (firewall, IDS, WAF) — tapi tidak ada **hierarchy-computer-networks** (bagaimana network BEKERJA)
- Semua attack vector (ARP spoof, MitM, DDoS) membutuhkan pemahaman OSI layers
- 68 hits di vault merujuk ke networking — tertinggi domain fundamental

---

## 2. OSI Model vs TCP/IP Stack

### 2.1 Tujuh Lapisan OSI

| Layer | Nama | Fungsi | PDU | Contoh Hardware/Protocol |
|:-----:|------|--------|:---:|-------------------------|
| **L7** | Application | Antarmuka ke aplikasi | Data | HTTP, SMTP, FTP, DNS, SSH |
| **L6** | Presentation | Encoding, encryption, compression | Data | TLS, SSL, JPEG, ASCII, MIME |
| **L5** | Session | Sesi komunikasi, checkpoint | Data | NetBIOS, RPC, SIP, SOCKS |
| **L4** | Transport | End-to-end reliability | Segment | TCP, UDP, QUIC, SCTP |
| **L3** | Network | Routing, logical addressing | Packet | IP, ICMP, OSPF, BGP, IPsec |
| **L2** | Data Link | Framing, MAC addressing | Frame | Ethernet, Wi-Fi, PPP, ARP |
| **L1** | Physical | Bit transmission | Bit | Coaxial, Fiber, RS-232, 10BASE-T |

### 2.2 TCP/IP Model (4 Lapisan)

```
+----------------------+
| Application (L5-L7)  |  ← HTTP, SMTP, DNS, SSH, TLS
+----------------------+
| Transport (L4)       |  ← TCP, UDP, QUIC
+----------------------+
| Internet (L3)        |  ← IP, ICMP, ARP
+----------------------+
| Network Access (L1-2) |  ← Ethernet, Wi-Fi, PPP
+----------------------+
```

### 2.3 OSI vs TCP/IP

| Aspek | OSI Model | TCP/IP Model |
|-------|-----------|--------------|
| **Layers** | 7 | 4 |
| **Status** | Referensi (teoretis) | Implementasi (aktual) |
| **Kelebihan** | Detail, konseptual | Praktis, real-world |
| **Penggunaan** | Teaching, troubleshooting | Engineering, deployment |

---

## 3. Layer 1 — Physical Layer

### 3.1 Media Transmisi

| Media | Bandwidth Max | Jarak | Interference |
|-------|:-------------:|:-----:|:------------:|
| **Twisted Pair (Cat 5e/6/6a/8)** | 40 Gbps | 30-100 m | Moderate |
| **Coaxial** | 10 Gbps | 500 m | Low |
| **Multi-mode Fiber (MMF)** | 100 Gbps | 550 m | None |
| **Single-mode Fiber (SMF)** | 800 Gbps+ | 40 km+ | None |
| **Wireless (5 GHz)** | 1-9.6 Gbps | 30-100 m | High (walls, noise) |
| **Wireless (60 GHz)** | 20 Gbps | < 10 m | Very high |

### 3.2 Signaling

| Teknik | Mekanisme | Digunakan Oleh |
|--------|-----------|----------------|
| **NRZ (Non-Return-to-Zero)** | Voltage high = 1, low = 0 | Ethernet (10BASE-T) |
| **Manchester** | Transition mid-bit = clock | Legacy Ethernet |
| **PAM-4** | 4 amplitude levels = 2 bit/symbol | 200G/400G Ethernet |
| **QAM-64/256** | Amplitude + phase modulation | Wi-Fi 6/7, DOCSIS |
| **OFDM** | Multiple subcarriers | Wi-Fi, 4G/5G, DSL |

**Key insight:** Semakin tinggi frekuensi → semakin pendek jarak → semakin rentan terhadap noise.

---

## 4. Layer 2 — Data Link Layer

### 4.1 Ethernet Frame Structure

```
Preamble (7B) | SFD (1B) | Dest MAC (6B) | Src MAC (6B) | EtherType (2B) | Payload (46-1500B) | FCS (4B)
```

**Keterangan:**
- **Preamble** — 7 byte sinkronisasi
- **SFD (Start Frame Delimiter)** — 1 byte tanda mulai frame
- **MAC Address** — 6 byte per alamat (48-bit)
- **EtherType** — 0x0800 = IPv4, 0x86DD = IPv6, 0x0806 = ARP
- **Payload** — 46-1500 byte (MTU, MTU = Maximum Transmission Unit)
- **FCS (Frame Check Sequence)** — CRC32

### 4.2 MAC Address dan ARP

**MAC Address Format:** `00:1A:2B:3C:4D:5E`
- OUI (24-bit) = vendor (Cisco, Intel, ...)
- NIC-specific (24-bit) = perangkat

**ARP (Address Resolution Protocol):** L3 address (IP) → L2 address (MAC)
```
Host A: "Who has 192.168.1.2? Tell 192.168.1.1" (broadcast)
Host B: "192.168.1.2 is at 00:1A:2B:3C:4D:5E" (unicast)
```

**ARP Spoofing:** Host jahat bisa menjawab untuk IP orang lain → membuat traffic dialihkan ke dirinya.

### 4.3 Switching

| Teknik Switching | Latency | Error Check |
|-----------------|:-------:|:-----------:|
| **Store-and-forward** | Penuh (seluruh frame diterima) | ✅ Sebelum forward |
| **Cut-through** | Minimal (dest MAC saja) | ❌ |
| **Fragment-free** | Menunggu 64 byte pertama | Partial |

**Switch internals:**
- MAC Address Table — mapping MAC → Port
- CAM Table — ternary content-addressable memory (TCAM)
- Spanning Tree Protocol (STP) — mencegah loop

---

## 5. Layer 3 — Network Layer (IP)

### 5.1 IPv4 Packet Structure

```
Version (4) | IHL (4) | DSCP (6) | ECN (2) | Total Length (16) | ID (16) | Flags (3) | Fragment Offset (13) | TTL (8) | Protocol (8) | Header Checksum (16) | Src IP (32) | Dest IP (32) | Options | Payload
```

**Field penting:**
- **TTL (Time To Live)** — maksimal hop sebelum packet dibuang
- **Protocol** — 1=ICMP, 6=TCP, 17=UDP
- **Fragment Offset** — fragmentasi di level IP (ketika MTU < paket)
- **Checksum** — hanya header, bukan payload

### 5.2 IPv6 — Alasan dan Perbedaan

| Aspek | IPv4 | IPv6 |
|-------|:----:|:----:|
| **Alamat** | 32-bit (4.3 milyar) | 128-bit (340 undecillion) |
| **Format** | 192.168.1.1 | 2001:db8::1 |
| **Header** | 20-60 byte (variable) | 40 byte (fixed) |
| **Checksum** | Ada | ❌ Tidak ada |
| **Fragmentasi** | Router bisa fragment | Hanya host asal |
| **Broadcast** | ✅ ARP broadcast | ✅ No ARP (multicast instead) |
| **NAT** | Wajib (IP shortage) | Tidak perlu |

### 5.3 Subnetting

```
IPv4: 192.168.1.0/24
├─ Network: 192.168.1.0
├─ Broadcast: 192.168.1.255
├─ Hosts: 192.168.1.1 - 192.168.1.254 (254 hosts)
└─ Subnet mask: 255.255.255.0 (/24)
```

**Subnet prefix lengths:**
| CIDR | Mask | Hosts | Use Case |
|:----:|:----:|:-----:|----------|
| /16 | 255.255.0.0 | 65,534 | Large org |
| /24 | 255.255.255.0 | 254 | Standard LAN |
| /27 | 255.255.255.224 | 30 | Small team |
| /30 | 255.255.255.252 | 2 | Point-to-point link |
| /128 | — | 1 | Loopback (IPv6) |

---

## 6. Layer 4 — Transport Layer (TCP/UDP)

### 6.1 TCP Segment

```
Src Port (16) | Dst Port (16) | Seq Num (32) | Ack Num (32) | Offset (4) | Flags (12) | Window (16) | Checksum (16) | Urgent Pointer (16) | Options | Payload
```

**Flags:**
- **SYN** — Mulai koneksi (three-way handshake)
- **ACK** — Acknowledgment
- **FIN** — Akhiri koneksi
- **RST** — Reset koneksi
- **PSH** — Push data ke aplikasi
- **URG** — Urgent data

### 6.2 TCP 3-Way Handshake

```
CLIENT                    SERVER
   │                        │
   │   SYN (seq=x)         │
   │ ───────────────────────> │
   │                        │
   │   SYN-ACK (seq=y, ack=x+1)│
   │ <─────────────────────── │
   │                        │
   │   ACK (seq=x+1, ack=y+1)│
   │ ───────────────────────> │
   │                        │
```

### 6.3 TCP vs UDP

| Aspek | TCP | UDP |
|-------|:---:|:---:|
| **Connection** | Connection-oriented | Connectionless |
| **Reliability** | ✅ Retransmission + ACK | ❌ No ACK |
| **Ordering** | ✅ Sequence numbers | ❌ No ordering |
| **Flow control** | ✅ Sliding window | ❌ |
| **Congestion control** | ✅ AIMD, CUBIC | ❌ |
| **Header size** | 20-60 bytes | 8 bytes |
| **Use cases** | HTTP, SMTP, SSH, FTP | DNS, streaming, VoIP, gaming |

### 6.4 TCP Congestion Control

| Algoritma | Approach | Throughput | Fairness |
|-----------|----------|:----------:|:--------:|
| **CUBIC** (default Linux) | Cubic function, RTT-independent | Tinggi untuk high-BDP | 🟡 |
| **BBR** (Google) | Model-based (bandwidth + RTT) | Sangat tinggi | ✅ |
| **NewReno** | AIMD: +1 per ACK, /2 di loss | Moderate | ✅ |
| **DCTCP** | ECN-based | Tinggi (datacenter) | ✅ |

---

## 7. Layer 5 — Session Layer

Tanggung jawab: **mengelola sesi komunikasi** (establish, maintain, terminate).

### Protokol Session

| Protocol | Fungsi | Lapisan OSI |
|----------|--------|:-----------:|
| **SOCKS5** | Proxy session establishment | L5 |
| **RPC** | Remote procedure call session | L5/L7 |
| **NetBIOS** | Session service (legacy Windows) | L5 |
| **TLS Handshake** | Session key exchange + crypto parameters | L5/L6 |

---

## 8. Layer 6 — Presentation Layer

### 8.1 Encoding

| Format | Type | Contoh |
|--------|------|--------|
| **Character** | ASCII, UTF-8, UTF-16 | Text encoding |
| **Image** | JPEG, PNG, WebP, AVIF | Visual data |
| **Video** | H.264, VP9, AV1 | Moving visual |
| **Audio** | AAC, MP3, Opus, FLAC | Sound |
| **Serialization** | JSON, XML, Protobuf, Avro | Structured data |

### 8.2 Compression

| Algorithm | Type | Ratio | Speed |
|-----------|:----:|:----:|:-----:|
| **gzip** (deflate) | Lossless | 2-5× | Fast |
| **brotli** | Lossless | 3-8× | Medium |
| **zstd** | Lossless | 2-10× | Fast |
| **JPEG** | Lossy | 10-50× | Fast |
| **H.264** | Lossy video | 100-1000× | Complex |

### 8.3 Encryption (Presentation Layer Role)

- TLS menyediakan **session encryption** — namun berada di L5/L6
- X.509 certificates — autentikasi server
- Perfect Forward Secrecy (PFS) — setiap sesi punya kunci berbeda

---

## 9. Layer 7 — Application Layer

Protokol aplikasi paling penting:

| Protocol | Port | Transport | Fungsi |
|----------|:----:|:---------:|--------|
| **HTTP/1.1** | 80 | TCP | Web |
| **HTTPS (HTTP/2)** | 443 | TCP | Web aman |
| **HTTP/3** | 443 | QUIC (UDP) | Web low-latency |
| **DNS** | 53 | UDP (query) / TCP (zone) | Name resolution |
| **DHCP** | 67/68 | UDP | IP assignment |
| **SMTP** | 25/587 | TCP | Email delivery |
| **SSH** | 22 | TCP | Remote shell |
| **FTP** | 20/21 | TCP | File transfer |

---

## 10. Routing & Switching

### 10.1 Routing Protocols

| Protocol | Type | Algorithm | Metric | Convergence |
|----------|:----:|-----------|:------:|:-----------:|
| **OSPF** | Link-state | SPF (Dijkstra) | Cost/bw | Fast |
| **IS-IS** | Link-state | SPF | Cost/bw | Fast |
| **EIGRP** | Hybrid | DUAL | Composite | Very fast |
| **RIP** | Distance-vector | Bellman-Ford | Hops | Slow |
| **BGP** | Path-vector | Path selection | AS path + policies | Slow (intentional) |

### 10.2 Routing vs Switching

| Aspek | Switching (L2) | Routing (L3) |
|-------|:--------------:|:------------:|
| **Unit** | Frame | Packet |
| **Address** | MAC | IP |
| **Decision** | MAC table → port | Routing table → next hop |
| **Domain** | Single broadcast domain | Multiple subnets |
| **Loop prevention** | STP/RSTP | TTL + routing protocol |
| **Hardware** | ASIC (hardware forwarding) | ASIC + CPU |

---

## 11. Cross-Reference ke Vault

| Lapisan | Catatan Vault |
|:-------:|---------------|
| **L2 (ARP)** | [[hierarchy-network-security]] — ARP spoofing mitigation |
| **L3 (IP)** | [[hierarchy-wireless]] — IP mobility |
| **L3 (Routing)** | [[ebpf-runtime-security-auditing]] — eBPF routing |
| **L4 (TCP)** | [[server-hardening-playbook]] — TCP tuning |
| **L4 (UDP)** | [[00_Atlas/hierarchy-data-engineering]] — UDP streaming |
| **L7 (HTTP)** | [[cli-pr-review-guide]] — HTTP debugging |
| **Cross-layer** | [[hierarchy-abstraction-layers]] — Network layer as abstraction L5 |

---

## References

1. Kurose, J. & Ross, K. *"Computer Networking: A Top-Down Approach."* 8th ed., Pearson, 2021.
2. Stevens, W. R. *"TCP/IP Illustrated, Vol. 1: The Protocols."* 2nd ed., Addison-Wesley, 2011.
3. Fall, K. & Stevens, W. R. *"TCP/IP Illustrated, Vol. 2."* 2012.
4. Tanenbaum, A. & Wetherall, D. *"Computer Networks."* 6th ed., Pearson, 2021.
5. Postel, J. *"RFC 791: Internet Protocol."* IETF, 1981.
6. Postel, J. *"RFC 793: Transmission Control Protocol."* IETF, 1981.
7. Deering, S. & Hinden, R. *"RFC 2460: Internet Protocol, Version 6."* IETF, 1998.
8. Perlman, R. *"Interconnections: Bridges, Routers, Switches."* 2nd ed., Addison-Wesley, 2000.
9. Jacobson, V. *"Congestion Avoidance and Control."* SIGCOMM 1988.
10. Cardwell, N. et al. *"BBR: Congestion-Based Congestion Control."* CACM 2017.
11. Varghese, G. *"Network Algorithmics."* Morgan Kaufmann, 2005.

audited
---
