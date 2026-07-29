---
title: "Hierarchy Network Forensics & PCAP Analysis"
tags:
  - atlas
  - network-forensics
  - pcap
  - traffic-analysis
  - forensic-investigation
aliases:
  - "hierarchy-network-forensics"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
---

# 🌐 HIERARCHY NETWORK FORENSICS & PCAP ANALYSIS — Dari Wire-Level Bits sampai Application-Layer Reconstruction

> Network forensics adalah **cabang forensik yang menganalisis lalu lintas jaringan untuk mengungkap aktivitas attacker, exfiltration data, dan pola komunikasi** — tanpa membutuhkan akses ke endpoint yang dikompromi. Berbeda dari endpoint forensik (analisis disk/memory), network forensics **tidak perlu akses ke komputer korban** — cukup tangkapan lalu lintas (PCAP) dari switch/router/SIEM. Hirarki ini memetakan evolusi analisis dari **Level 0 (raw bits di kabel)** sampai **Level 6 (cross-session threat reconstruction)** — semakin tinggi levelnya, semakin abstrak analisisnya dan semakin besar kesimpulan yang bisa ditarik.

> [!info] Cara Baca Atlas Ini
> Mulai dari **Level 0** untuk memahami data paling mentah (physical layer). Loncat ke **Level 3–4** kalau tujuan Anda adalah CTF forensic (PCAP analysis, exfiltration detection). Level 5–6 untuk IR profesional yang merekonstruksi APT campaign. Untuk tools per level, lihat [[ctf-tool-arsenal-universal]] → Network Forensic section. Untuk metodologi praktis, lihat [[network-forensics-pcap-analysis]].

---

## Tabel Utama — Level 0 sampai Level 6

| 🌐 Level                                             | 🧠 Layer Analisis                           | 📦 Bentuk Data                                                       | ⚡ Tools                                                                         | 🎯 Pertanyaan yang Dijawab                                                                     |
| ---------------------------------------------------- | ------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Level 0** — Raw Wire / Physical                    | Physical layer — bit mentah di kabel/udara  | Radio frequency, electrical signal, optical pulse                    | Wireshark (raw capture), tcpdump, libpcap, RF receiver (HackRF, USRP)            | "Apakah ada data yang lewat?" — deteksi sinyal, frame synchronization                          |
| **Level 1** — Data Link / Ethernet                   | Layer 2 — frame MAC, ARP, VLAN, STP         | Ethernet frame header + payload, ARP packet, 802.1Q tag              | tcpdump -e, Wireshark (Ethernet II), tshark -Y "arp", macof                      | "Siapa yang bicara dengan siapa di switch ini?" — MAC spoofing, ARP spoofing, STP manipulation |
| **Level 2** — Network / IP                           | Layer 3 — IP header, routing, fragmentation | IPv4/IPv6 packet, ICMP, IPsec, TTL, fragmentation offset             | Wireshark (IPv4), tshark -Y "ip", nmap, Scapy                                    | "Dari mana ke mana paket ini?" — IP spoofing, traceroute, TTL analysis, fragmentation attack   |
| **Level 3** — Transport / TCP-UDP                    | Layer 4 — port, sequence number, flow state | TCP segment (SYN/ACK/RST), UDP datagram, window size, SACK           | Wireshark (TCP), tshark -z io,stat, Zeek conn.log, tcptrace                      | "Apakah koneksi ini legitimate?" — SYN flood, port scan, TCP hijack, sequence prediction       |
| **Level 4** — Application Protocol                   | Layer 5–7 — protokol aplikasi, payload      | HTTP request/response, DNS query, TLS handshake, FTP data, SMTP mail | Wireshark (HTTP/DNS/SMTP), tshark --export-objects, Zeek http.log, dns.log       | "Apa yang dikirim user?" — SQL injection in HTTP, C2 beacon DNS, exfiltration via HTTP         |
| **Level 5** — Session & Behavior                     | Multi-protocol, multi-connection            | Correlated sessions (5+ menit), user-agent chain, timing analysis    | Zeek (conn.log + weird.log), RITA (Rare Incident Traffic Analysis), Elastic SIEM | "Siapa attacker-nya?" — C2 beacon detection, data exfiltration pattern, DDoS profile           |
| **☠️ Level 6** — Threat Reconstruction & Attribution | Cross-session, cross-host, cross-time       | Campaign timeline, TTP mapping, kill chain visualization             | MISP, TheHive, Elastic SIEM, ATT&CK Navigator, Plaso timeline + network          | "Apa yang sebenarnya terjadi?" — Full intrusion reconstruction, attribution assessment         |

---

## Peta Visual — Abstraksi vs Kedalaman Insight

```
Kedalaman Insight ↑
                 │  L6 ─ Threat Reconstruction               ●●●   Attribution
                 │  L5 ─ Session & Behavior                  ●●●●  C2, exfil
                 │  L4 ─ Application Protocol                ●●●●● Payload analysis
                 │  L3 ─ Transport / TCP-UDP                ●●●●   Flow analysis
                 │  L2 ─ Network / IP                      ●●●     Routing, spoof
                 │  L1 ─ Data Link / Ethernet              ●●      MAC, ARP
                 │  L0 ─ Raw Wire / Physical              ●        Signal
                 │       └────────────────────────────────→ Abstraksi Meningkat
                 │
                 └──────────────────────────────────→ Tools Complexity
```

---

## Kenapa Hirarki Ini Penting

### 1. Network Forensic ≠ Endpoint Forensic

| Aspek                | Endpoint Forensic            | Network Forensic                                          |
| -------------------- | ---------------------------- | --------------------------------------------------------- |
| **Sumber data**      | Hard disk, RAM, log          | PCAP, netflow, SIEM log                                   |
| **Volatilitas**      | Relatif stabil (kecuali RAM) | Sangat volatil — data lenyap begitu capture berhenti      |
| **Volume data**      | GB–TB per device             | TB–PB per hari (enterprise)                               |
| **Retensi**          | Bertahun-tahun               | Biasanya 30–90 hari (sesuai kebijakan)                    |
| **Anti-forensik**    | File wiping, encryption      | Traffic encryption (TLS), ephemeral port, domain fronting |
| **Chain of custody** | Satu device fisik            | Bisa ribuan device, tersebar geografis                    |

### 2. Urutan Analisis PCAP — Bottom-Up

```
Level 0 → 1 → 2 → 3 → 4 → 5 → 6
   ↓        ↓       ↓       ↓
Validasi   Filter   Flow    Intent
capture    noise    triage  analysis
```

**Praktiknya:** Jangan mulai dari Level 4 langsung. Validasi dulu integritas PCAP (L0), filter noise (L1-L2), baru analisis aplikasi (L4+).

### 3. Skill Progression

| Level  | Skill                                | Waktu Belajar |    CTF Relevance     |
| :----: | ------------------------------------ | :-----------: | :------------------: |
|   L0   | Baca hex dump, pahami Ethernet frame |    1–2 jam    |        Jarang        |
| L1–L2  | Filter IP/MAC, cari scan             |    2–4 jam    |        Kadang        |
|   L3   | Flow analysis, port scan detection   |    4–8 jam    |        Sering        |
| **L4** | **HTTP/DNS/TLS payload extraction**  | **8–16 jam**  | **❤️ Paling sering** |
|   L5   | C2 beacon, exfil pattern             |   2–5 hari    |        Tim IR        |
|   L6   | Full campaign reconstruction         | Minggu–bulan  | Hanya live exercise  |

---

## PCAP Analysis — Universal Workflow

### Step-by-Step: Dari PCAP Mentah ke Flag

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. Identifikasi PCAP (L0–L1)                                     │
│    capinfos file.pcap → durasi, packet count, size               │
│    tshark -r file.pcap -T fields -e frame.protocols | sort -u    │
├──────────────────────────────────────────────────────────────────┤
│ 2. Statistik Dasar (L1–L3)                                       │
│    tshark -r file.pcap -z io,stat,0.1                            │
│    tshark -r file.pcap -z conv,ip                                │
│    tshark -r file.pcap -z endpoints,ip                           │
├──────────────────────────────────────────────────────────────────┤
│ 3. Cari Anomali (L3–L4)                                          │
│    Banyak SYN → port scan                                        │
│    DNS TXT besar → exfiltration                                  │
│    HTTP POST ke IP → data exfil                                  │
│    TLS ke IP (bukan domain) → C2                                 │
├──────────────────────────────────────────────────────────────────┤
│ 4. Export Objects (L4)                                           │
│    tshark --export-objects http,output/                          │
│    tshark --export-objects smb,output/                           │
│    Wireshark: File → Export Objects → HTTP/SMB/TFTP              │
├──────────────────────────────────────────────────────────────────┤
│ 5. Follow Stream (L4)                                            │
│    tshark -r file.pcap -z follow,tcp,ascii,0                    │
│    Wireshark: Right-click TCP → Follow → TCP Stream              │
├──────────────────────────────────────────────────────────────────┤
│ 6. Cari Flag (L4+)                                               │
│    strings capture.pcap | grep -i "CTF\|flag"                    │
│    tshark -r file.pcap -Y "http contains flag"                   │
│    tshark -r file.pcap -Y "dns contains CTF"                     │
└──────────────────────────────────────────────────────────────────┘
```

### Tooling Matrix

| Task                  | CLI Tool                            | GUI / Alternatif                     |
| --------------------- | ----------------------------------- | ------------------------------------ |
| PCAP info             | `capinfos`                          | Wireshark Statistics                 |
| Filter & search       | `tshark`, `tcpdump`                 | Wireshark display filter             |
| Conversation analysis | `tshark -z conv,...`                | Wireshark Statistics → Conversations |
| HTTP extraction       | `tshark --export-objects http,...`  | File → Export Objects → HTTP         |
| DNS analysis          | `tshark -Y dns`                     | Zeek dns.log                         |
| TLS metadata          | `tshark -Y tls.handshake`           | Zeek ssl.log                         |
| File extraction       | `foremost file.pcap`, `binwalk -Me` | NetworkMiner                         |
| Flow correlation      | `Zeek conn.log`                     | RITA, Elastic                        |

---

## Common Network Attacks & Forensic Signature

### 🔴 Reconnaissance & Scanning

| Teknik                | PCAP Signature                                        | Cara Deteksi                                                               |
| --------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| **SYN scan**          | SYN → SYN-ACK → RST (tidak ever completed connection) | `tshark -Y "tcp.flags.syn==1 and tcp.flags.ack==0 and tcp.flags.reset==1"` |
| **Full connect scan** | SYN → SYN-ACK → ACK → RST                             | `tshark -Y "tcp.flags==0x0017"` (SYN+ACK, port terbuka)                    |
| **FIN scan**          | FIN (bukan SYN) langsung kirim                        | `tshark -Y "tcp.flags.fin==1 and tcp.flags.syn==0"`                        |
| **NULL scan**         | TCP tanpa flag                                        | `tshark -Y "tcp.flags==0"`                                                 |
| **Xmas scan**         | FIN+PSH+URG                                           | `tshark -Y "tcp.flags.fin==1 and tcp.flags.psh==1 and tcp.flags.urg==1"`   |
| **ACK scan**          | ACK flood — map firewall rule                         | `tshark -Y "tcp.flags.ack==1 and tcp.flags.syn==0"`                        |
| **UDP scan**          | ICMP Port Unreachable response                        | `tshark -Y "icmp.type==3 and icmp.code==3"`                                |

### 🔴 Man-in-the-Middle

| Teknik            | PCAP Signature                                                               | Cara Deteksi                                                   |
| ----------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **ARP spoofing**  | Dua MAC untuk satu IP                                                        | `tshark -Y "arp"` → lihat MAC ganda per IP dalam waktu singkat |
| **DNS spoofing**  | DNS reply tanpa query, atau reply pertama dari attacker (sebelum legitimate) | Cari DNS answer yang tidak match dengan query                  |
| **DHCP spoofing** | Multiple DHCP server offering per request                                    | `tshark -Y "dhcp.option.dhcp==2"` → DHCP Offer dari IP berbeda |
| **STP hijack**    | BPDU dari port yang seharusnya bukan root                                    | `tshark -Y "stp"` → lihat Root Bridge ID yang berubah          |

### 🔴 DDoS

| Teknik                | PCAP Signature                          | Cara Deteksi                                                              |
| --------------------- | --------------------------------------- | ------------------------------------------------------------------------- |
| **SYN flood**         | SYN tanpa SYN-ACK → backlog penuh       | `tshark -Y "tcp.flags.syn==1 and tcp.flags.ack==0"` + filter by source IP |
| **UDP flood**         | UDP flood ke port random                | `tshark -Y "udp"` + statistik source IP                                   |
| **ICMP flood**        | Ping flood                              | `tshark -Y "icmp"`                                                        |
| **HTTP flood**        | GET flood dari IP berbeda               | `tshark -Y "http.request"` + statistik user-agent                         |
| **DNS amplification** | Source IP palsu, DNS dengan EDNS0 besar | Cari DNS response size > 512 bytes dengan source IP random                |

### 🔴 C2 & Exfiltration

| Teknik                     | PCAP Signature                                                  | Cara Deteksi                                                                     |
| -------------------------- | --------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **DNS tunneling**          | DNS TXT/AAAA query ke domain aneh, subdomain panjang (>30 char) | `tshark -Y "dns.txt"` → cari TXT record dengan data non-teks                     |
| **HTTP beacon**            | GET periodik ke endpoint yang sama setiap N detik               | Wireshark IO Graph dengan interval 1 detik — lonjakan periodik                   |
| **HTTPS to IP**            | TLS handshake langsung ke IP (bukan domain)                     | `tshark -Y "tls.handshake.type==1 and not tls.handshake.extensions_server_name"` |
| **ICMP tunneling**         | ICMP echo data berisi data biner                                | `tshark -Y "icmp"` + follow ICMP data                                            |
| **DNS exfiltration**       | DNS query dengan hostname mengandung data terenkripsi           | Cari subdomain dengan entropy tinggi                                             |
| **HTTP POST exfiltration** | POST berisi data ke endpoint tidak dikenal                      | `tshark -Y "http.request.method==POST"` → cek panjang content                    |
| **Stego in images**        | Gambar diunggah ke image hosting                                | HTTP POST dengan Content-Type image/ — ukuran tidak wajar                        |

---

## Plot Twists

> [!danger] Plot Twist 1: Enkripsi Membunuh Forensik Jaringan — Tapi Metadata Tetap Ada
> TLS 1.3 mewajibkan enkripsi handshake — Anda tidak bisa lihat certificate atau SNI tanpa decrypt. **Tapi metadata tetap terlihat:** source/destination IP, port, ukuran paket, timing, dan frekuensi. Untuk C2 detection, metadata cukup. Untuk content extraction (flag dalam HTTP body) — Anda butuh decrypt key atau PCAP sebelum TLS.

> [!tip] Plot Twist 2: WireGuard & QUIC Membuat Identifikasi C2 Sulit
> WireGuard tidak punya header protokol yang recognizable — semua paket terlihat seperti random UDP. QUIC (HTTP/3) menggabungkan handshake + data dalam satu round trip — koneksi legitimate pun susah dibedakan dari beacon. **Behavior-based detection** (periodicity, packet size, timing) jadi satu-satunya cara.

> [!info] Plot Twist 3: Netflow/Sflow ≠ PCAP
> PCAP merekam **semua data** — payload, header lengkap, timing. Netflow hanya merekam **metadata:** src/dst IP, port, protocol, ukuran, timestamp. **Netflow tidak bisa extract flag atau rekonstruksi file.** Di kompetisi CTF, soal pasti pake PCAP. Di dunia nyata (enterprise), mayoritas hanya punya netflow karena ukuran PCAP terlalu besar.

> [!warning] Plot Twist 4: Timeline PCAP Bisa Dipalsukan
> Wireshark/tcpdump mencatat timestamp dari sistem operasi. Attacker bisa:
>
> - Inject paket dengan timestamp palsu (pcapr)
> - Hapus paket dari tengah capture
> - Edit PCAP header dengan `bittwist` atau `tcprewrite`
>
> **Mitigasi:** Cek kontinuitas sequence number, cek gap timestamp, cek delta antara paket consecutive. Jika ada lompatan besar → kemungkinan PCAP telah dimodifikasi.

> [!danger] Plot Twist 5: Loopback & Container Traffic Tidak Tertangkap di PCAP
> Jika Anda capture di eth0 — traffic antar container (bridge network) tidak muncul. Jika aplikasi client-server di localhost yang sama — traffic tidak lewat wire sama sekali. **Capture harus di interface yang benar:** `docker0`, `br-xxx`, `lo`, atau mirror port di switch.

---

## Sumber Data Network Forensics

| Sumber            | Level | Kelebihan                         | Kekurangan                             |
| ----------------- | :---: | --------------------------------- | -------------------------------------- |
| **PCAP penuh**    | L0–6  | Semua data ada                    | Ukuran besar, butuh storage besar      |
| **NetFlow/IPFIX** | L3–5  | Ringan, scalable                  | Tanpa payload, tidak bisa extract file |
| **SIEM logs**     | L4–6  | Sudah terkorelasi, alert built-in | Tertinggal real-time, butuh tuning     |
| **Proxy logs**    | L4–5  | Semua HTTP tercatat               | Hanya HTTP/HTTPS — protokol lain tidak |
| **DNS logs**      | L4–5  | DNS query tercatat sempurna       | Hanya DNS — tidak capture traffic lain |
| **Zeek logs**     | L3–6  | Multi-protocol, metadata kaya     | Butuh dedicated server                 |
| **WAF logs**      |  L4   | Attack payload terekam            | Hanya traffic yang lewat WAF           |

---

## Cross-Link

- **Tool Arsenal (Network Forensic Section)** → [[ctf-tool-arsenal-universal]]
- **PCAP Analysis Praktis** → [[network-forensics-pcap-analysis]]
- **Digital Evidence Hierarchy (OoV)** → [[hierarchy-digital-evidence-acquisition]]
- **CTF Methodology (Forensic Flow)** → [[ctf-competition-methodology-strategy]]
- **Incident Response Framework** → [[incident-response-framework]]
- **Endpoint Detection (Network + Endpoint)** → [[hierarchy-endpoint-security]]
- **Master Index** → [[master-index]]

---

_Network Forensics Hierarchy | Level 0 (Raw Wire) → Level 6 (Threat Reconstruction) · Metadata Tetap Ada Meski Encrypted · PCAP = Gold Standard · Netflow = Ringan Tapi Buta Payload_
