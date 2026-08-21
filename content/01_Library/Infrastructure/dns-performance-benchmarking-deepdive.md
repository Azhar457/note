---
title: DNS Performance Engineering, Latency Decomposition, and Large-Scale Benchmarking Deep Dive
tags:
  - infrastructure
  - networking
  - dns
  - performance
  - benchmarking
  - deepdive
aliases:
  - dns-performance-benchmarking-deepdive
  - dns-performance-latency-benchmarking
  - grc-dns-benchmark-deepdive
created: 2026-08-21
updated: 2026-08-21
status: operational
cssclasses:
  - wide-table
---

# **01_Library: Rekayasa Performa DNS, Dekomposisi Latensi, Analisis GRC Benchmark, dan Metodologi Skala Besar**

Dokumen ini merupakan panduan teknis mendalam mengenai rekayasa performa Domain Name System (DNS), dekomposisi fisika dan matematika latensi jaringan, metodologi benchmarking beban tinggi (*stress testing* open-loop), penyusunan dataset kueri berbasis distribusi Zipfian, analisis mekanika internal **GRC DNS Benchmark** (Cached, Uncached, DotCom), metodologi kustomisasi regional Indonesia (IIX / OpenIXP), penyetelan kernel Linux tingkat lanjut (*low-level network tuning*), komparasi protokol transport modern, serta deteksi anomali protokol jaringan.

---

## 1. Fisika dan Dekomposisi Matematika Latensi Resolusi DNS

Latensi total resolusi DNS ($L_{\text{total}}$) adalah fungsi dari perambatan fisik sinyal, waktu serialisasi, penundaan antrean pada perangkat jaringan, beban komputasi CPU pada server, serta biaya kriptografi:

$$L_{\text{total}} = T_{\text{prop}} + T_{\text{trans}} + T_{\text{queue}} + T_{\text{proc}} + T_{\text{crypto}}$$

```text
[ Klien (Stub) ] ──(L1/L2)──► [ Edge Router ] ──(Fiber WAN)──► [ Anycast PoP ] ──(Kernel/NIC)──► [ DNS Engine ]
      │                              │                               │                              │
      ├─ OS Context Switch           ├─ Queueing Delay               ├─ BGP AS-Path Latency         ├─ Hash Table Lookup
      └─ IPC to systemd-resolved     └─ Serialization                └─ Speed of Light in Fiber     ├─ DNSSEC Verification
                                                                        (~5 μs/km)                  └─ Response Assembly
```

### A. Komponen Penundaan Waktu

1. **Propagation Delay ($T_{\text{prop}}$):** Ditentukan oleh kecepatan cahaya di dalam serat optik kaca ($v \approx 200.000\text{ km/s}$ atau $\approx 5\ \mu\text{s per km}$). Jarak fisik antara klien dan node server Anycast merupakan batas bawah absolut latensi yang tidak dapat dimampatkan oleh optimasi perangkat lunak.
2. **Transmission & Serialization Delay ($T_{\text{trans}}$):** Waktu yang diperlukan untuk mendorong seluruh bit paket ke media transmisi:

$$T_{\text{trans}} = \frac{\text{Packet Size (bits)}}{\text{Link Bandwidth (bps)}}$$

   Pada paket UDP kecil (100–500 bytes), nilai ini dapat diabaikan ($< 1\ \mu\text{s}$). Namun, pada respon DNSSEC berukuran besar ($> 1232\text{ bytes}$) yang memicu *TCP fallback* atau fragmentasi, nilai ini meningkat signifikan.
3. **Queueing & Scheduling Delay ($T_{\text{queue}}$):** Waktu tunggu paket di dalam *ring buffer* kartu jaringan (NIC RX Ring) dan antrean soket sistem operasi sebelum diproses oleh thread aplikasi.
4. **Processing & Caching Delay ($T_{\text{proc}}$):** Waktu eksekusi pencarian pada struktur data memori (*in-memory hash table* atau *Radix Tree*).
   - **Cache Hit:** $T_{\text{proc}} \approx 10\text{ ns} - 50\ \mu\text{s}$.
   - **Cache Miss (Iterative Traversal):** $T_{\text{proc}} = \sum (\text{RTT}_{\text{Root}} + \text{RTT}_{\text{TLD}} + \text{RTT}_{\text{Authoritative}}) \approx 50\text{ ms} - 300\text{ ms}$.
5. **Cryptographic Overhead ($T_{\text{crypto}}$):** Biaya komputasi verifikasi tanda tangan digital DNSSEC (ECDSA / Ed25519) dan handshake enkripsi (TLS 1.3 / QUIC).

### B. Analisis Ekor Latensi (Tail Latency & Percentiles)

Rata-rata latensi (*Mean Latency*) adalah metrik yang menyesatkan dalam evaluasi performa DNS karena menyembunyikan anomali ekor (*tail events*):

- **P50 (Median):** Menggambarkan performa kueri dominan saat terjadi *Cache Hit* lokal.
- **P90 & P99 (The Long Tail):** Menggambarkan kueri yang mengalami *Cache Miss*, *packet loss* pada UDP yang memicu *timeout* dan *retransmission* (default Linux stub resolver: 1.000–5.000 ms), atau resolusi iteratif berantai ke server otoritatif yang lambat di belahan dunia lain.

---

## 2. Arsitektur Internal GRC DNS Benchmark

GRC DNS Benchmark dirancang sebagai instrumen audit performa dan integritas resolver DNS sisi klien (*client-side resolver profiler*). Berbeda dari pengujian kueri tunggal sintetis, GRC menerapkan pendekatan statistik multivariat untuk memisahkan latensi murni jaringan dari efisiensi komputasi mesin resolver.

```text
                                  [ ARSITEKTUR EVALUASI GRC DNS BENCHMARK ]
                                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
  [ METRIK 1: CACHED ]                     [ METRIK 2: UNCACHED ]                     [ METRIK 3: DOTCOM ]
  * Kueri 1: Warm-up RAM                   * Kueri Subdomain Acak                     * Kueri Khusus TLD .com
  * Kueri 2: Pengukuran Waktu              * Memaksa Rekursi Iteratif                 * Evaluasi Pipa Verisign
  * Menguji RTT & Kecepatan RAM            * Menguji Egress Peering Global            * Bobot 70% Lalu Lintas Web
```

### Prinsip Pengukuran Berbasis Waktu (Milidetik vs Detik)

Pada antarmuka GRC DNS Benchmark, seluruh pembacaan latensi direpresentasikan dalam format detik dengan presisi 3 digit desimal:

$$\text{Nilai } 0.020 = 20\text{ ms} \quad \text{vs.} \quad \text{Nilai } 0.100 = 100\text{ ms}$$

- **Prinsip Utama:** Semakin kecil angka milidetik (ms), semakin cepat dan responsif server DNS tersebut.
- Latensi $0.020\text{ detik}$ ($20\text{ ms}$) merepresentasikan kecepatan lima kali lebih cepat dibanding $0.100\text{ detik}$ ($100\text{ ms}$).
- Dalam konteks web modern yang memuat puluhan aset pihak ketiga, selisih $80\text{ ms}$ per kueri mengakibatkan perbedaan total render halaman (*Page Load Time*) hingga beberapa detik.

### Dekomposisi 3 Metrik Inti: Cached, Uncached, dan DotCom

```text
+----------------------------------------------------------------------------------------------------+
| 1. CACHED (Bar Merah / Merah Muda)                                                                 |
| Klien ──(Kueri 1: google.com)──► Resolver ──(Simpan ke RAM)──► Respon                             |
| Klien ──(Kueri 2: google.com)──► Resolver ──(Langsung dari RAM)──► Respon [ Diukur ]               |
| Fokus Evaluasi: RTT Jaringan Klien-ke-Resolver + Kecepatan Hash Table Lookup RAM Resolver          |
+----------------------------------------------------------------------------------------------------+
| 2. UNCACHED (Bar Hijau)                                                                            |
| Klien ──(Kueri: rand-98124.target.com)──► Resolver (Cache Miss)                                   |
|                                             │                                                      |
|                                             ├─► Tanya Root (.)                                     |
|                                             ├─► Tanya TLD (.com)                                   |
|                                             └─► Tanya Auth NS (target.com)                         |
| Klien ◄─────────────────────────────────────┴── Respon Final [ Diukur ]                            |
| Fokus Evaluasi: Kualitas Pipa Transit WAN Resolver ke Internet Otoritatif Global                   |
+----------------------------------------------------------------------------------------------------+
| 3. DOTCOM / .com (Bar Biru)                                                                        |
| Klien ──(Kueri: rand-xyz.com)──► Resolver ──(Tanya Verisign Root/gTLD)──► Respon [ Diukur ]       |
| Fokus Evaluasi: Latensi Khusus ke Infrastruktur TLD .com (Infrastruktur Inti Web Dunia)            |
+----------------------------------------------------------------------------------------------------+
```

1. **Cached Performance (Bar Merah):** Kueri pertama mengisi memori (*warm-up*), kueri kedua mengukur RTT murni Layer 3/4 ditambah efisiensi struktur data (*hash table / radix tree lookup*). Nilai ideal serat optik lokal adalah $< 15\text{ ms}$.
2. **Uncached Performance (Bar Hijau):** Menggunakan string acak unik (*cache-busting random FQDN*) untuk memaksa resolusi iteratif penuh (Root $\rightarrow$ TLD $\rightarrow$ Authoritative). Menguji kualitas *peering* dan bandwidth transit internasional penyedia DNS.
3. **DotCom Performance (Bar Biru):** Menguji kecepatan resolver mengontak server gTLD Verisign (`a.gtld-servers.net` hingga `m.gtld-servers.net`), merepresentasikan $> 50\% - 70\%$ lalu lintas web harian.

---

## 3. Metodologi Benchmarking Berbasis Regional (Local Domain Optimization)

Secara default, GRC DNS Benchmark menggunakan dataset 50 domain terpopuler di Amerika Serikat. Bagi pengguna di Indonesia dan Asia Tenggara, pengujian default menghasilkan bias pengukuran yang tidak mencerminkan kenyataan.

```text
================================================================================
          MASALAH PENGUJIAN DEFAULT AS VS PENGUJIAN REGIONAL LOKAL
================================================================================
1. Default GRC (Domain Populer AS):
   Klien (ID) ──► Resolver ──► Authoritative Server di Virginia/California (AS)
   Hasil: Latensi Uncached tampak tinggi (200-300 ms) karena jarak fisik fiber optik Pasifik.

2. Regional Custom List (Domain Populer Indonesia):
   Klien (ID) ──► Resolver ──► Authoritative / CDN Server di Jakarta / IIX / OpenIXP
   Hasil: Latensi Uncached mencerminkan rute domestik riil (10-40 ms).
```

### Mengapa Benchmarking Regional Jauh Lebih Akurat?

1. **Pemanfaatan CDN & IIX Lokal:** Layanan perbankan, portal berita, dan platform e-commerce nasional memiliki server Authoritative DNS dan CDN yang terhubung langsung ke **Indonesia Internet Exchange (IIX)** atau **OpenIXP** di Cyber Building Jakarta.
2. **Eliminasi RTT Lintas Benua:** Menguji domain lokal memastikan pengukuran berfokus pada efisiensi *peering* domestik ISP, bukan hambatan kabel bawah laut antar-benua.

---

## 4. SOP: Kustomisasi Dataset Regional pada GRC DNS Benchmark

GRC membaca file konfigurasi teks `DNSBENCH.INI` yang diletakkan di direktori yang sama dengan executable `DNSBench.exe`.

### A. Dataset Kurasi Domain Top Indonesia (`custom_id_domains.txt`)

```text
# Domain Perbankan & Finansial Indonesia
bca.co.id
klikbca.com
bankmandiri.co.id
mandiriserbank.co.id
bni.co.id
bri.co.id
cimbniaga.co.id

# Domain E-Commerce & Layanan Digital
tokopedia.com
shopee.co.id
bukalapak.com
blibli.com
lazada.co.id
gojek.com
grab.com
traveloka.com

# Domain Media & Informasi Publik
detik.com
kompas.com
tribunnews.com
tempo.co
liputan6.com
kaskus.co.id
vidio.com

# Domain Pemerintahan & Pendidikan (.go.id & .ac.id)
indonesia.go.id
kemkes.go.id
pajak.go.id
kominfo.go.id
ui.ac.id
itb.ac.id
ugm.ac.id
telkom.co.id
```

### B. Skrip Python Otomasi Ekstraksi Domain Regional

```python
import os

def create_grc_custom_ini(domain_list, output_file="DNSBENCH.INI"):
    header = (
        "; GRC DNS Benchmark Custom Regional Configuration\n"
        "; Wilayah: Indonesia & Asia Tenggara (IIX / OpenIXP Optimized)\n"
        "[CustomDomains]\n"
    )
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(header)
        for idx, domain in enumerate(domain_list, 1):
            f.write(f"Domain{idx}={domain.strip()}\n")
            
    print(f"[+] Berhasil membuat file konfigurasi {output_file} dengan {len(domain_list)} domain regional.")

if __name__ == "__main__":
    domains = [
        "bca.co.id", "klikbca.com", "bankmandiri.co.id", "tokopedia.com",
        "shopee.co.id", "detik.com", "kompas.com", "telkom.co.id",
        "indonesia.go.id", "kemkes.go.id", "ui.ac.id", "itb.ac.id",
        "ugm.ac.id", "gojek.com", "blibli.com", "traveloka.com"
    ]
    create_grc_custom_ini(domains)
```

---

## 5. Metodologi Benchmarking Standar Industri Skala Besar

Pengujian performa DNS skala produksi menuntut metodologi ilmiah yang ketat untuk menghindari kesalahan pengukuran sistematis (*Coordinated Omission*).

```text
+-----------------------------------------------------------------------------------------------+
| MASALAH COORDINATED OMISSION (Gil Tene Model)                                                 |
| Jika generator beban menunggu respon kueri sebelumnya sebelum mengirim kueri berikutnya,       |
| maka saat server mengalami jeda (stall/freeze) selama 1 detik, kueri terjadwal tidak terkirim.|
| Hasil pengukuran latensi akan tampak artificially rendah (bias positif).                      |
| [ Solusi ]: Open-Loop Benchmark Architecture (Kirim kueri secara strictly timed independen)    |
+-----------------------------------------------------------------------------------------------+
```

### Closed-Loop vs. Open-Loop Benchmarking

- **Closed-Loop Testing:** Klien mengirim $N$ kueri konkuren. Kueri baru hanya dikirim setelah kueri lama menerima respon. Metode ini cacat untuk benchmarking batas kapasitas, karena laju pengiriman kueri otomatis melambat saat server mulai kewalahan.
- **Open-Loop Testing (`dnsperf` & `flamethrower`):** Klien menghasilkan kueri pada laju konstan atau kurva bertingkat ($Q\text{ queries/second}$) secara independen dari respon server. Kueri tak terjawab dihitung secara akurat sebagai *timeout/loss*.

### Tooling Standar Pengujian DNS

| Alat | Pengembang | Protokol Didukung | Kegunaan Utama |
|:---|:---|:---|:---|
| **`dnsperf` / `resperf`** | ISC | Plain UDP, Plain TCP | Pengujian throughput QPS batas saturasi authoritative & recursive cache |
| **`flamethrower`** | DNS-OARC | UDP, TCP, DoT, DoH | Generator beban asynchronous berkinerja tinggi berbasis C++/Rust |
| **`dnsping`** | DNSDiag | Plain UDP, TCP, TLS | Pengukuran berkala RTT, jitter, dan packet loss mirip ICMP ping |

---

## 6. Penyusunan Dataset Kueri (Workload Synthesis)

Hasil benchmarking ditentukan oleh karakteristik dataset kueri yang digunakan.

```text
================================================================================
DISTRIBUSI KUERI INTERNET AKTUAL (ZIPFIAN DISTRIBUTION - PARETO 80/20)
================================================================================
Probabilitas Kueri P(r)
  │ 
1.0 █
    █
0.5 █ █
    █ █ █
0.1 █ █ █ █ █ ▄ ▄ ▄ ▂ ▂ ▂ ▂ ▂ ▂ ▂ ▂ ▂   (Long Tail: Jutaan domain unik jarang diakses)
  └───────────────────────────────────── Rank Domain (r)
     Top 1.000 Domain     Domain Acak / Subdomain Dinamis
```

### Skrip Generator Dataset Berbasis Python

```python
import random
import string

def generate_dnsperf_dataset(filename="query_dataset.txt", num_queries=500000, hot_cache_ratio=0.8):
    hot_domains = [f"service-{i}.production.internal" for i in range(100)]
    qtypes = ["A", "AAAA", "TXT", "HTTPS"]

    with open(filename, "w", encoding="utf-8") as f:
        for _ in range(num_queries):
            if random.random() < hot_cache_ratio:
                # 80% Kueri mengarah ke domain populer (Hot Cache)
                domain = random.choice(hot_domains)
            else:
                # 20% Kueri mengarah ke domain acak unik (Cold Cache)
                rand_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=12))
                domain = f"host-{rand_str}.labsec.id"
            
            qtype = random.choice(qtypes)
            f.write(f"{domain} {qtype}\n")

    print(f"[+] Berhasil membuat {num_queries} record di {filename}")

if __name__ == "__main__":
    generate_dnsperf_dataset()
```

---

## 7. Penyetelan Kernel Linux & Optimasi Low-Level Network Stack

```text
[ Paket Masuk ] ──► [ NIC Ring Buffer ] ──► [ Kernel Socket Queue ] ──► [ User-Space DNS Buffer ]
                           ▲                          ▲                           ▲
                     ethtool rx 4096            sysctl rmem_max             SO_RCVBUF Tuning
```

### A. Penyetelan Parameter Kernel (`/etc/sysctl.conf`)

```ini
# Memperbesar buffer penerima dan pengirim jaringan global (Maksimum 64 MB)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432

# Memperbesar batas buffer khusus protokol UDP
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# Memperpanjang antrean backlog perangkat jaringan sebelum diproses kernel
net.core.netdev_max_backlog = 100000

# Memperbesar antrean koneksi TCP (untuk DoT/DoH/Zone Transfer)
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# Mengizinkan penggunaan kembali port soket secara instan
net.ipv4.tcp_tw_reuse = 1

# Memperbanyak rentang port lokal untuk kueri keluar resolver (Mencegah Port Exhaustion)
net.ipv4.ip_local_port_range = 1024 65535
```

Terapkan konfigurasi: `sysctl -p`.

### B. Penyetelan Kartu Jaringan (NIC Ring Buffers & IRQ Affinity)

```bash
# Melihat kapasitas maksimum ring buffer NIC:
ethtool -g eth0

# Memaksimalkan antrean RX dan TX:
ethtool -G eth0 rx 4096 tx 4096
```

Atur *IRQ Affinity* melalui daemon `irqbalance` atau konfigurasi manual pada `/proc/irq/<IRQ_NUM>/smp_affinity` agar beban interupsi kartu jaringan tersebar merata ke seluruh core CPU fisik.

---

## 8. Arsitektur Internal DNS Engine & Algoritma Caching

| DNS Engine | Struktur Data Zona | Model Concurrency | Karakteristik Utama |
|:---|:---|:---|:---|
| **Knot DNS** | Adaptive Radix Tree (ART) | RCU (Read-Copy-Update) | Kinerja memori tertinggi; operasi lookup *lock-free* murni. |
| **BIND 9.18+** | Red-Black Tree / RBT | Multi-Thread Worker Ring | Standar industri terlengkap; I/O async berbasis `libuv`. |
| **Unbound** | Hash Table Terpartisi (Slabs) | Threaded Memory Slabs | Caching rekursif cepat; minim lock contention via partitioning. |
| **CoreDNS** | In-Memory Go Maps | Goroutine Worker Pool | Berbasis Go; arsitektur modular via plugin; memori relatif lebih besar. |

### Mekanisme Optimistic Prefetching

Jika sebuah rekor menerima kueri saat sisa masa aktifnya berada di bawah $10\%$ dari nilai TTL aslinya, resolver mengirimkan kueri latar belakang secara proaktif (*asynchronous prefetch*) ke server otoritatif sebelum TTL habis. Klien selalu mendapatkan respon *Cache Hit* dengan latensi $< 1\text{ ms}$.

---

## 9. Komparasi Efisiensi Protokol Transport Modern

```text
+-----------------------------------------------------------------------------------------------+
| PERBANDINGAN RTT HANDSHAKE INISIASI KONEKSI                                                    |
+-----------------------------------------------------------------------------------------------+
| 1. Plain UDP (Port 53):                                                                       |
|    Kueri ────────────────────────────────────────────────────────► Respon [ 1 RTT ]           |
+-----------------------------------------------------------------------------------------------+
| 2. DoT (TLS 1.3 over TCP):                                                                    |
|    TCP SYN ──► TCP ACK ──► TLS ClientHello ──► TLS Finished ──► Kueri DNS ──► Respon [ 4 RTT ]|
+-----------------------------------------------------------------------------------------------+
| 3. DoQ (DNS over QUIC / RFC 9250):                                                            |
|    QUIC Initial (Crypto + Kueri DNS) ────────────────────────────► Respon [ 1 RTT / 0-RTT ]    |
+-----------------------------------------------------------------------------------------------+
```

- **Plain UDP:** Throughput tertinggi ($> 1.000.000\text{ QPS}$ per node) karena bersifat *stateless*.
- **DoT / DoH (HTTP/2):** Throughput berkurang $40\% - 70\%$ akibat alokasi memori *TLS Session State*, beban enkripsi simetris (AES-GCM / ChaCha20), dan stateful TCP.
- **DoQ (QUIC):** Kecepatan setara UDP dengan enkripsi TLS 1.3 dan bebas *Head-of-Line (HoL) Blocking* pada *packet loss* parsial.

---

## 10. Deteksi Anomali & Fitur Diagnostik Lanjutan

```text
================================================================================
          DETEKSI ANOMALI PROTOKOL OLEH GRC DNS BENCHMARK
================================================================================
1. Hijacking / Redirection (DNS Spoofing ISP)
   Gejala: Kueri domain yang sengaja dimatikan (non-existent domain) tetap mengembalikan IP.
   Diagnostik: GRC menandai status "Hijacks Non-Existent Domains (NXDOMAIN)".

2. DNS Rebinding Vulnerability
   Gejala: Resolver mengembalikan IP privat (127.0.0.1 / 192.168.x.x) untuk domain publik.
   Diagnostik: GRC memberikan peringatan "Vulnerable to DNS Rebinding Attacks".

3. DNSSEC Authentication Support
   Gejala: Bit DO (DNSSEC OK) divalidasi dan signature rusak ditolak dengan SERVFAIL.
   Diagnostik: GRC menandai status "Validates DNSSEC Signatures".
```

---

## 11. SOP: Eksekusi Benchmark Mandiri dengan `dnsperf`

### Langkah 1: Instalasi Perangkat Pengujian

```bash
apt-get update
apt-get install -y dnsperf bind9-utils python3
```

### Langkah 2: Menyiapkan Resolver Berperforma Tinggi (`/etc/unbound/unbound.conf`)

```text
server:
    interface: 127.0.0.1
    port: 53
    access-control: 127.0.0.0/8 allow
    
    # Threading & Slabs Scaling
    num-threads: 4
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4
    
    # Buffer Memori Maksimal
    so-rcvbuf: 8m
    so-sndbuf: 8m
    msg-cache-size: 128m
    rrset-cache-size: 256m
    
    # Proaktif Prefetching
    prefetch: yes
    prefetch-key: yes
```

Restart service: `systemctl restart unbound`.

### Langkah 3: Eksekusi Uji Beban

```bash
# Menjalankan uji performa selama 60 detik dengan target 20.000 QPS
dnsperf -s 127.0.0.1 -p 53 -d query_dataset.txt -c 20 -l 60 -Q 20000
```

### Langkah 4: Interpretasi Output Benchmark

```text
Statistics:
  Queries sent:         1200000 queries
  Queries completed:    1199982 queries (100.00%)
  Queries lost:         18 queries (0.00%)
  Response codes:       NOERROR 1150000 (95.83%), NXDOMAIN 49982 (4.17%)
  Run time (s):         60.000000 seconds
  Queries per second:   19999.700000 qps

  Latency Statistics:
    Average latency:    0.000412 seconds (0.412 ms)
    Minimum latency:    0.000085 seconds (0.085 ms)
    Maximum latency:    0.045120 seconds (45.120 ms)

  Latency Distribution:
    Latency < 1 ms:     1185000 queries (98.75%)
    Latency < 5 ms:     14000 queries (1.17%)
    Latency < 10 ms:    900 queries (0.08%)
    Latency < 50 ms:    82 queries (0.01%)
```

---

## 12. Matriks Evaluasi & Keputusan Pemilihan DNS Terbaik

| Skenario Hasil Benchmark | Profil Kinerja | Rekomendasi Tindakan |
|:---|:---|:---|
| **Cached Rendah ($< 10\text{ ms}$), Uncached Rendah ($< 60\text{ ms}$), 0% Loss** | **Optimal Sempurna** (PoP Anycast lokal + peering IIX cepat). | Tetapkan sebagai **Primary DNS** pada router/kartu jaringan. |
| **Cached Sangat Rendah ($< 5\text{ ms}$), Uncached Tinggi ($> 300\text{ ms}$)** | **Resolver Lokal Terisolasi** (Server dekat, namun pipa transit internasional lambat). | Cocok untuk browsing domestik, kurang optimal untuk akses server global. |
| **Cached Sedang ($20 - 40\text{ ms}$), Uncached Stabil ($< 80\text{ ms}$), DNSSEC Aktif** | **Enterprise / Privacy-Focused** (Cloudflare `1.1.1.1` atau Quad9 `9.9.9.9`). | Direkomendasikan untuk keamanan maksimal dan bebas pembajakan NXDOMAIN. |
| **Garis Merah/Oranye Putus-putus (*Packet Drop / Timeout*)** | **Infrastruktur Tidak Stabil** (Buffer socket penuh / UDP throttling). | **Dilarang digunakan** karena memicu lag dan error *ERR_NAME_NOT_RESOLVED*. |
