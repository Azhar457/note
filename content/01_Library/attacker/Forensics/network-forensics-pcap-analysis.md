---
title: "Network Forensics — PCAP Analysis & Traffic Investigation"
tags:
  - network-forensics
  - pcap
  - traffic-analysis
  - wireshark
  - tshark
  - zeek
  - c2-detection
aliases:
  - "network-forensics-pcap-analysis"
created: '2026-07-28'
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  

---

# 🌐 Network Forensics — PCAP Analysis & Traffic Investigation

> **Panduan praktis analisis PCAP** untuk CTF, incident response, dan kompetisi keamanan siber. Dari statistik dasar sampai rekonstruksi serangan multi-protokol. **Semua command sudah siap copy-paste.** Untuk gambaran besar network forensics, lihat [[hierarchy-network-forensics]].

> [!tip] Golden Rule PCAP
> **Start with statistics, end with stream analysis.** Jangan langsung follow TCP stream — Anda bakal tersesat di ribuan paket. Mulai dari `capinfos` → statistik → filter → baru stream.

---

## Daftar Isi

- [[#Fase 1 — PCAP Validation & Overview]]
- [[#Fase 2 — Conversation & Endpoint Analysis]]
- [[#Fase 3 — Protocol-Specific Analysis]]
- [[#Fase 4 — File Extraction & Carving]]
- [[#Fase 5 — C2 & Exfiltration Detection]]
- [[#Fase 6 — Scapy untuk Manipulasi & Analisis]]
- [[#Zeek Framework untuk Logging]]
- [[#Cheat Sheet — TShark Filter per Skenario]]
- [[#Common CTF Soal Pattern]]

---

## Fase 1 — PCAP Validation & Overview

### 1.1 Cek integritas PCAP

```bash
# Info dasar — durasi, packet count, size, aplikasi
capinfos capture.pcap

# Output penting:
#   File size, Packet count, Duration, Protocol types
#   Timestamps: first/last packet
#   Capture application (Wireshark/tcpdump/Zeek?)
```

**Yang harus dicatat:**
- ⏱️ **Durasi**: detik? jam? — konteks serangan
- 📦 **Packet count**: sedikit (CTF) atau banyak (real traffic)
- 🧬 **Protocols**: hanya HTTP? DNS? SMB? — petunjuk kategori soal
- 🕒 **Timeline**: kapan capture dimulai? — sinkronisasi dengan log lain

### 1.2 Cek protocol hierarchy

```bash
# Distribusi protokol
tshark -r capture.pcap -z io,phs

# Output:
#   Ethernet: 100%
#     IPv4: 95.2%
#       TCP: 80.1%
#         HTTP: 45.3%
#         TLS: 30.2%
#       UDP: 15.1%
#         DNS: 10.5%
```

**Yang dicari:**
- Protocol anomali — ada `data` fragment? ICMP dalam jumlah besar?
- Traffic tidak wajar — UDP tiba-tiba 50%? itu DNS tunneling
- HTTP vs HTTPS ratio — apakah kebanyakan sudah dienkripsi?

### 1.3 IO Graph — visualisasi traffic

```bash
# Grafik packet rate per detik
tshark -r capture.pcap -z io,stat,1

# Output: detik ke N = jumlah paket
# Cari lonjakan (spike) — itu serangan atau exfil

# Wireshark: Statistics → IO Graph
# X-axis: time, Y-axis: packet count atau bytes
```

**Lonjakan signifikan (1000% dari baseline) → selidiki di detik itu.**

---

## Fase 2 — Conversation & Endpoint Analysis

### 2.1 Conversations

```bash
# Semua TCP conversations — sorted by duration/bytes
tshark -r capture.pcap -z conv,tcp

# Output: IP A:port ←→ IP B:port, packets, bytes, duration

# Conversations per protocol
tshark -r capture.pcap -z conv,udp
tshark -r capture.pcap -z conv,ip  # Only network layer
```

**Yang dicari:**
- Pasangan IP dengan **bytes tertinggi** — itu transfer file
- Koneksi **durasi sangat panjang** — itu beacon/C2
- Koneksi **port tidak biasa** (4444, 1337, 31337) — itu reverse shell

### 2.2 Endpoints

```bash
# Endpoints aktif
tshark -r capture.pcap -z endpoints,ip

# Siapa yang bicara paling banyak? (top talker)
tshark -r capture.pcap -z endpoints,ip -z io,stat,1 | sort -k2 -rn | head -10

# Endpoints berdasarkan MAC
tshark -r capture.pcap -z endpoints,eth
```

**Yang dicari:** Satu IP yang bicara ke banyak port → port scan. Satu IP yang menerima data dari banyak sumber → DDoS target.

### 2.3 Expert Info (Wireshark)

```bash
# Wireshark: Analyze → Expert Information
# Atau CLI:
tshark -r capture.pcap -z expert
```

**Yang dicari:**
- ⚠️ **Warning**: Checksum error, TCP retransmission, zero window
- ❌ **Error**: Malformed packet, reassembly failure
- 📝 **Note**: TCP keep-alive, duplicate ACK, SYN flood

---

## Fase 3 — Protocol-Specific Analysis

### 3.1 HTTP Analysis

```bash
# Semua HTTP request
tshark -r capture.pcap -Y "http.request" -T fields \
  -e http.request.method -e http.request.uri -e http.host

# Semua HTTP response dengan status code
tshark -r capture.pcap -Y "http.response" -T fields \
  -e http.response.code -e http.response.phrase -e http.content_length

# Cari HTTP POST (upload / form submission)
tshark -r capture.pcap -Y "http.request.method==POST" -T fields \
  -e http.request.uri -e http.content_type -e http.content_length

# Cari HTTP request mengandung "flag" atau "login"
tshark -r capture.pcap -Y "http.request.uri contains flag or http.request.uri contains login"

# Extract cookies
tshark -r capture.pcap -Y "http.cookie" -T fields -e http.cookie

# User-agent analysis — apa device/browser yang dipake?
tshark -r capture.pcap -Y "http.user_agent" -T fields -e http.user_agent | sort -u
```

**HTTP CTF Pattern:**
| Filter | Yang Dicari |
|--------|-------------|
| `http.request.method==POST` | Flag submission, login form, file upload |
| `http.response.code==302` | Redirect — mungkin after login? |
| `http.request.uri contains /admin` | Admin page access |
| `http.content_type contains "image"` | Image upload — steganography? |
| `http.request.uri contains ".php?"` | Parameter in URL — SQLi / LFI |

### 3.2 DNS Analysis

```bash
# Semua DNS query
tshark -r capture.pcap -Y "dns.flags.response==0" -T fields \
  -e dns.qry.name -e dns.qry.type | sort | uniq -c | sort -rn

# Cari DNS TXT record (sering untuk tunneling)
tshark -r capture.pcap -Y "dns.txt" -T fields -e dns.txt

# Cari subdomain panjang — DNS tunneling?
tshark -r capture.pcap -Y "dns.qry.name.len > 30" -T fields -e dns.qry.name

# Cari query ke domain aneh (bukan google.com, bukan cloudflare)
tshark -r capture.pcap -Y "dns.flags.response==0" -T fields \
  -e dns.qry.name | grep -v "\.com\|\.net\|\.org\|\.id" | sort -u

# DNS query ke IP (bukan domain name)
tshark -r capture.pcap -Y "dns.qry.type==1 and dns.qry.name matches '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$'"

# Cek DNS response — jawaban dari server mana?
tshark -r capture.pcap -Y "dns.flags.response==1" -T fields \
  -e dns.resp.addr -e dns.resp.name

# Resolved IP — mapping domain ke IP
tshark -r capture.pcap -Y "dns.flags.response==1 and dns.resp.type==1" \
  -T fields -e dns.qry.name -e dns.resp.addr | sort -u
```

**DNS CTF Pattern:**

| Filter | Indikasi |
|--------|----------|
| `dns.qry.name.len > 40` | **🚨 DNS Tunneling** — subdomain panjang penuh base64 |
| `dns.txt` | TXT record — data exfil atau command |
| `dns.qry.type==16` (TXT) | TXT query — sering untuk tunneling |
| `dns.qry.type==28` (AAAA) | AAAA flood — DNS amplification DDoS |
| Domain dalam 2 menit pertama > 50 unik | Domain Generation Algorithm (DGA) |

### 3.3 TLS / SSL Analysis

```bash
# Semua TLS handshake
tshark -r capture.pcap -Y "tls.handshake.type==1" -T fields \
  -e tls.handshake.ciphersuite -e tls.handshake.extensions_server_name

# Cari TLS ke IP (bukan domain — mencurigakan!)
tshark -r capture.pcap -Y "tls.handshake.type==1 and not tls.handshake.extensions_server_name"

# TLS version yang dipake
tshark -r capture.pcap -Y "tls.handshake.version" -T fields -e tls.handshake.version | sort -u

# Certificate issuer — siapa yang nerbitin?
tshark -r capture.pcap -Y "tls.handshake.certificate" -T fields -e tls.handshake.certificate.issuer

# Cari sertifikat self-signed (bukan dari CA resmi)
tshark -r capture.pcap -Y "tls.handshake.certificate" -T fields \
  -e tls.handshake.certificate.issuer -e tls.handshake.certificate.subject | grep -v "Let's Encrypt\|DigiCert\|GlobalSign\|Comodo"

# JA3 fingerprint — identifikasi client TLS
# Ekstrak JA3 hash dari handshake
tshark -r capture.pcap -Y "tls.handshake.type==1" -T fields \
  -e tls.handshake.ja3 -e tls.handshake.ja3s
```

**TLS CTF Pattern:**
- **Self-signed cert** → C2 server
- **TLSv1.0/1.1** → legacy/obsolete — mungkin ada exploit
- **No SNI** → koneksi ke IP langsung — bukan akses web normal
- **JA3 dikenal** → C2 framework (Meterpreter, Cobalt Strike, Mythic)

### 3.4 ICMP Analysis

```bash
# Semua ICMP
tshark -r capture.pcap -Y "icmp" -T fields -e ip.src -e ip.dst -e icmp.type

# ICMP echo request + reply (ping)
tshark -r capture.pcap -Y "icmp.type==8 or icmp.type==0" -T fields \
  -e ip.src -e ip.dst -e data.len

# ICMP dengan data di payload — ICMP tunneling?
tshark -r capture.pcap -Y "icmp and data.len > 100" -T fields -e data.data

# ICMP unreachable — port scan?
tshark -r capture.pcap -Y "icmp.type==3"
```

**ICMP CTF Pattern:**
- ICMP packet dengan payload besar (>100 bytes) → **ICMP tunneling**
- Banyak ICMP unreachable dari IP yang sama → **UDP scan** ke IP itu

### 3.5 SMB / NetBIOS Analysis (Windows File Sharing)

```bash
# SMB2 — file access
tshark -r capture.pcap -Y "smb2.cmd" -T fields -e smb2.cmd -e smb2.filename

# SMB file read
tshark -r capture.pcap -Y "smb2.cmd==8" -T fields -e smb2.filename

# SMB file write
tshark -r capture.pcap -Y "smb2.cmd==9" -T fields -e smb2.filename

# Export file via SMB
tshark -r capture.pcap --export-objects smb,output/
```

### 3.6 FTP Analysis

```bash
# FTP request
tshark -r capture.pcap -Y "ftp.request" -T fields -e ftp.request.command -e ftp.request.arg

# FTP response
tshark -r capture.pcap -Y "ftp.response" -T fields -e ftp.response.code -e ftp.response.arg

# FTP login credential
tshark -r capture.pcap -Y "ftp.request.command==USER or ftp.request.command==PASS" \
  -T fields -e ftp.request.command -e ftp.request.arg

# Export objects via FTP
tshark -r capture.pcap --export-objects ftp,output/
```

### 3.7 SMTP / Email Analysis

```bash
# SMTP conversations
tshark -r capture.pcap -Y "smtp.req.command" -T fields -e smtp.req.command -e smtp.req.parameter

# SMTP data content — email body
tshark -r capture.pcap -Y "smtp" -x | head -100

# Extract email attachment
# Biasanya base64 encoded dalam SMTP DATA
tshark -r capture.pcap -Y "smtp" -V | grep -A 50 "Content-Type:"
```

---

## Fase 4 — File Extraction & Carving

### 4.1 Export Objects via Protocol

```bash
# HTTP
tshark -r capture.pcap --export-objects http,output_http/

# SMB
tshark -r capture.pcap --export-objects smb,output_smb/

# TFTP
tshark -r capture.pcap --export-objects tftp,output_tftp/

# FTP-DATA
tshark -r capture.pcap --export-objects ftp,output_ftp/

# IMAP (email)
tshark -r capture.pcap --export-objects imap,output_imap/
```

**Setelah export,** ls output folder — cek file yang tidak wajar (.exe, .zip, .pdf, .doc). Biasanya flag ada di sana.

### 4.2 Manual File Carving from PCAP

```bash
# Extract TCP stream ke file
tshark -r capture.pcap -z follow,tcp,ascii,0 > tcp_stream_0.txt

# Extract raw bytes stream
tshark -r capture.pcap -q -z follow,tcp,hex,1 > raw_stream_1.txt

# Carving file dari raw PCAP dengan foremost
foremost -T -i capture.pcap -o carved_output/

# Atau dengan binwalk
binwalk -Me capture.pcap
```

### 4.3 Extract Data dari HTTP POST

```bash
# Cari POST data yang panjang — mungkin flag upload?
tshark -r capture.pcap -Y "http.request.method==POST" -T fields \
  -e http.file_data

# Atau hex dump
tshark -r capture.pcap -Y "http.request.method==POST" -x | grep -v "0000  47 45 54\|0000  48 54 54 50"
```

---

## Fase 5 — C2 & Exfiltration Detection

### 5.1 Beacon Detection

C2 beacon adalah **koneksi periodik** ke IP/domain yang sama. Ciri-ciri:

| Ciri | Deskripsi |
|------|-----------|
| **Interval tetap** | Setiap 60.000 ± 1 second — script timer, bukan user |
| **Packet size konsisten** | Setiap beacon ukuran request = sama persis |
| **Data minimal** | GET request, response 200, content-type text/html tapi body pendek |
| **Tidak ada interaksi user** | Tidak ada gambar, CSS, JS yang dimuat seperti browsing normal |

```bash
# Step 1: Cari TCP streams dengan komunikasi dua arah teratur
# Filter: HTTP request ke satu host dengan interval teratur
tshark -r capture.pcap -Y "http.request" -T fields \
  -e frame.time_relative -e http.request.uri -e ip.dst | head -50

# Step 2: Hitung delta antar request
# Di Wireshark: Statistics → Flow Graph → TCP
# Atau IO Graph dengan filter ip.dst==X.X.X.X

# Step 3: Cek HTTP response size
tshark -r capture.pcap -Y "http.response" -T fields \
  -e frame.time_relative -e http.response.code -e http.content_length | head -50
```

**Rumus deteksi beacon:**
```
Rata-rata delta antar request < 2 detik variasi → Browsing normal
Rata-rata delta antar request = 0 ± 1 detik variasi → Bot/script
```

### 5.2 Data Exfiltration Detection

```bash
# Cari HTTP POST dengan content > 1MB — upload file?
tshark -r capture.pcap -Y "http.request.method==POST and http.content_length > 1000000" \
  -T fields -e http.request.uri -e http.content_length

# Cari DNS TXT query dengan response > 512 bytes — DNS tunneling?
tshark -r capture.pcap -Y "dns.txt and dns.len > 512" \
  -T fields -e dns.qry.name -e dns.len

# Cari koneksi dengan bytes keluar (src→dst) tidak proporsional
# Normal: request kecil, response besar
# Exfil: request besar, response kecil
tshark -r capture.pcap -z conv,tcp | sort -t' ' -k5 -rn | head -10

# Cek ICMP echo request payload — ada data?
tshark -r capture.pcap -Y "icmp.type==8 and data.len > 0"
```

### 5.3 Domain Generation Algorithm (DGA) Detection

```bash
# Ekstrak semua domain dari DNS query
tshark -r capture.pcap -Y "dns.flags.response==0" -T fields \
  -e dns.qry.name | sort -u > domains.txt

# Cek entropy tinggi — DGA?
cat domains.txt | while read d; do
    echo "$d $(echo $d | grep -oE "[a-z]{10,}" | head -1 | \
        python3 -c "import sys,math; [print(sum(1 for c in s)/len(s)) for s in sys.stdin]")"
done 2>/dev/null
```

**DGA Ciri:**
- Domain seperti `jkasdhfkjhasdf.xyz` — alfanumerik tanpa arti
- Banyak NXDOMAIN (domain tidak ada) — DNS query gagal
- Rata-rata panjang 8–20 karakter

---

## Fase 6 — Scapy untuk Manipulasi & Analisis

Scapy bisa **membaca, memanipulasi, dan membuat paket** langsung dari Python.

```python
from scapy.all import *

# Baca PCAP
packets = rdpcap('capture.pcap')

# Statistik
print(f"Total packets: {len(packets)}")
print(f"Duration: {packets[-1].time - packets[0].time:.2f}s")

# Filter by protocol
tcp_packets = [p for p in packets if TCP in p]
http_packets = [p for p in packets if TCP in p and p[TCP].dport == 80]

# Ekstrak HTTP layer
for p in http_packets:
    if p[TCP].payload:
        print(bytes(p[TCP].payload).decode(errors='ignore'))

# Cari string dalam semua paket
for p in packets:
    raw = bytes(p)
    if b'CTF{' in raw or b'flag{' in raw.lower():
        print(f"[!] Found in packet {p.time}: {raw}")

# Export TCP stream
for i, p in enumerate(packets):
    if TCP in p and Raw in p:
        with open(f'stream_{i}.bin', 'wb') as f:
            f.write(bytes(p[TCP].payload))
```

---

## Zeek Framework untuk Logging

Zeek (dulu Bro) mengubah PCAP menjadi **log terstruktur** — jauh lebih mudah dicari daripada raw PCAP.

```bash
# Install
sudo apt install zeek

# Run Zeek on PCAP
zeek -r capture.pcap

# Output files:
#   conn.log      — semua koneksi TCP/UDP/ICMP
#   dns.log       — semua DNS query + response
#   http.log      — semua HTTP request + response
#   ssl.log       — semua TLS handshake
#   smtp.log      — email SMTP
#   ftp.log       — FTP session
#   weird.log     — anomali protokol
#   files.log     — file yang diekstrak

# Query dengan zeek-cut
cat conn.log | zeek-cut uid proto service duration orig_bytes resp_bytes

# Cari koneksi mencurigakan
cat conn.log | zeek-cut id.orig_h id.resp_h proto service duration | grep -v "-"

# Cari HTTP POST besar
cat http.log | zeek-cut uid method uri resp_mime_types request_body_len | \
  awk -F'\t' '$4 > 100000 {print}'
```

---

## Cheat Sheet — TShark Filter per Skenario

| Skenario | Filter `-Y` |
|----------|-------------|
| **Port scan** (banyak SYN ke port berbeda) | `tcp.flags.syn==1 and tcp.flags.ack==0` lalu group by dst port |
| **DNS tunneling** | `dns.qry.name.len > 30` atau `dns.txt` |
| **HTTP file upload** | `http.request.method==POST and http.content_length > 10000` |
| **HTTPS ke IP langsung** | `tls.handshake.type==1 and not tls.handshake.extensions_server_name` |
| **ARP spoofing** | `arp.duplicate-address-detected` atau `arp.opcode==2` |
| **ICMP tunneling** | `icmp and data.len > 64` |
| **SMB lateral movement** | `smb2.cmd==5` (SMB2 create — file access) |
| **Email exfiltration** | `smtp.req.command` atau `imap` |
| **C2 beacon** | `http.request` lalu IO Graph per source IP |
| **Flag di HTTP** | `http contains "CTF{" or http contains "flag{"` |
| **Flag di DNS** | `dns contains "CTF" or dns.qry.name contains "flag"` |
| **Kerberos attack** | `kerberos` |
| **RDP connection** | `rdp` |

### Multi-Step TShark Quick Commands

```
# 1. Info PCAP
capinfos file.pcap

# 2. Protocol distribution
tshark -r file.pcap -z io,phs

# 3. Top talkers
tshark -r file.pcap -z endpoints,ip | sort -k4 -rn | head-10

# 4. Conversations by bytes
tshark -r file.pcap -z conv,tcp | sort -k5 -rn | head-10

# 5. HTTP requests
tshark -r file.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# 6. DNS — cari domain aneh
tshark -r file.pcap -Y "dns.flags.response==0" -T fields -e dns.qry.name | sort | uniq -c | sort -rn

# 7. Export objects
tshark -r file.pcap --export-objects http,./exported/

# 8. Flag search
strings file.pcap | grep -iE "CTF\{|flag\{|key\{|secret" | head-20
```

---

## Common CTF Soal Pattern

| Pattern | Ciri | Solusi |
|---------|------|--------|
| **Flag di HTTP body** | Satu HTTP request dengan response berisi string | `tshark -Y "http contains CTF"` atau follow TCP stream |
| **Flag di DNS TXT** | TXT record aneh dengan base64 string | `tshark -Y "dns.txt"` + base64 decode |
| **Flag di gambar** | File JPEG/PNG diexport dari PCAP | `tshark --export-objects http,./` → cari gambar → strings/gambar |
| **Flag di FTP** | FTP credential + transfer | `tshark -Y "ftp"` → extract credential → download file |
| **Flag di email** | SMTP attachment | `tshark -Y "smtp"` → cari Content-Type → extract attachment |
| **Stego in image** | Gambar di-download, flag di metadata/LSB | Export image → exiftool/zsteg/steghide |
| **C2 exfiltration** | Beacon + POST dengan base64 data | Extract POST body → base64 decode → flag |
| **ICMP tunnel** | Ping dengan data besar | `tshark -Y "icmp" -x` → ICMP payload berisi flag |
| **WiFi capture** | .cap file dengan WPA handshake | aircrack-ng + wordlist crack |
| **USB capture** | .pcap dari USB — keyboard keystroke | UsbKeyboardData HID parser → flag dari keyboard stroke |

---

## Cross-Link

- **Atlas Network Forensics** → [[hierarchy-network-forensics]]
- **Tool Arsenal (Network Section)** → [[ctf-tool-arsenal-universal]]
- **Atlas Digital Evidence** → [[hierarchy-digital-evidence-acquisition]]
- **CTF Methodology** → [[ctf-competition-methodology-strategy]]
- **Incident Response Framework** → [[incident-response-framework]]
- **Master Index** → [[master-index]]

---

*PCAP Analysis · Statistik Dulu, Stream Kemudian · C2 = Periodik · Exfil = Bytes Tidak Proporsional · Scapy & Zeek = Power Tools · CTF = Follow Stream + Export Object + Strings*
---

audited
---
