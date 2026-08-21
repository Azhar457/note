---
title: "DNS Architecture and Security Hierarchy"
tags:
  - atlas
  - hierarchy
  - dns
  - networking
  - security
  - dnssec
  - cryptography
aliases:
  - hierarchy-dns-architecture-security
  - hierarchy-dns-ecosystem
  - dns-hierarchy-level-0-7
created: 2026-08-21
updated: 2026-08-21
status: operational
cssclasses:
  - wide-table
---

# **00_Atlas: Arsitektur Ekosistem DNS, Protokol, Kriptografi, dan Hierarki Keamanan (Level 0 – Level 7)**

Dokumen ini menyusun taksonomi hierarkis dan arsitektur komprehensif dari ekosistem Domain Name System (DNS), mulai dari lapisan transmisi fisik dan perutean BGP Anycast pada perangkat keras, format biner protokol pada tingkat byte, mesin caching rekursif, arsitektur zona otoritatif, protokol enkripsi transport modern, kriptografi integritas DNSSEC, matriks eksploitasi dan pertahanan siber, hingga arsitektur desentralisasi spekulatif dan post-quantum.

---

## Ringkasan Matriks Hierarki (Overview)

```text
[ Level 7: Decentralized & Post-Quantum Naming ] ── ENS, Handshake, P2P DHT, Post-Quantum DNSSEC
[ Level 6: Adversarial Exploitation & Defense  ] ── Cache Poisoning, Tunneling C2, DNS Rebinding, RRL, RPZ
[ Level 5: Cryptographic Trust (DNSSEC)        ] ── Chain of Trust, KSK/ZSK, NSEC/NSEC3/White Lies, CDS/CDNSKEY
[ Level 4: Modern Transport & Privacy Layer    ] ── DoT, DoH, DoQ, ODoH, RFC 9460 HTTPS/SVCB & ECH
[ Level 3: Authoritative Control & Replication ] ── Zone Transfers (AXFR/IXFR), TSIG, Dynamic DNS, Apex Flattening
[ Level 2: Recursive Resolution & Cache Engine ] ── Stub Resolver, Caching Mechanics, TTL Clamping, QNAME Minimization
[ Level 1: Wire Format & Protocol Parser       ] ── RFC 1035 Wire Format, Header Flags, EDNS0 OPT RR, UDP/TCP 53
[ Level 0: Physical, BGP Anycast & Kernel      ] ── Fiber/Radio, BGP Anycast Routing, SO_REUSEPORT, eBPF/XDP
```

---

## Taksonomi Struktural Ekosistem DNS Global

Domain Name System (DNS) beroperasi sebagai sistem basis data terdistribusi berskala global dengan model konsistensi bertahap (*eventual consistency*).

```text
                              [ Root Zone: . ]
                 (13 Identitas Root: a.root-servers.net s/d m.root-servers.net)
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
   [ gTLD: .com, .net ]       [ ccTLD: .id, .jp ]       [ sTLD: .gov, .edu ]
         │                           │                           │
         ▼                           ▼                           ▼
[ Second-Level Domain ]     [ Second-Level Domain ]     [ Second-Level Domain ]
   (example.com)               (labsec.id)                 (agency.gov)
         │                           │                           │
         └───────────────────────────┼───────────────────────────┘
                                     ▼
                    [ Authoritative Nameservers (NS) ]
                                     ▲
                                     │ (Iterative Queries)
                                     ▼
                  [ Recursive Resolver (ISP / Public DNS) ]
                                     ▲
                                     │ (Recursive Query)
                                     ▼
                   [ Stub Resolver / Client Operating System ]
```

### Komponen Struktural & Mekanika Resolusi

1. **Root Zone (`.`):** Puncak pohon hierarki DNS yang dikelola oleh IANA/ICANN. Terdapat 13 identitas server logis (`a.root-servers.net` hingga `m.root-servers.net`) yang dioperasikan berbagai institusi independen dan didistribusikan ke ribuan lokasi fisik melalui BGP Anycast.
2. **Top-Level Domains (TLD):** Terbagi atas *generic TLD* (gTLD: `.com`, `.net`, `.org`), *country-code TLD* (ccTLD: `.id`, `.uk`, `.de`), dan *sponsored TLD* (sTLD: `.gov`, `.mil`). Server TLD menyimpan catatan delegasi (*NS records*) ke domain tingkat kedua (*Second-Level Domains*).
3. **Authoritative Nameservers:** Server yang memiliki otoritas sah atas file zona tertentu (*zone file*). Memegang jawaban pasti (*Authoritative Answer / AA flag*) terhadap rekor DNS (`A`, `AAAA`, `CNAME`, `MX`, `TXT`, `SRV`, `SOA`, `NS`).
4. **Recursive Resolvers:** Server penengah (seperti `1.1.1.1`, `8.8.8.8`, atau resolver ISP) yang menerima permintaan dari klien akhir, melakukan penelusuran iteratif ke seluruh tingkatan hierarki, mengelola cache lokal berbasis TTL (*Time to Live*), dan mengembalikan jawaban akhir ke klien.
5. **Stub Resolvers:** Pustaka klien ringan pada sistem operasi (`systemd-resolved` pada Linux, `DNS Client Service` pada Windows) yang bertugas meneruskan kueri ke Recursive Resolver.
6. **Recursive vs Iterative Query:**
   - **Recursive Query:** Terjadi antara Stub Resolver dan Recursive Resolver (`RD=1` / *Recursion Desired*). Klien menuntut resolver mencari jawaban sampai tuntas atau mengembalikan status error (`NXDOMAIN` / `SERVFAIL`).
   - **Iterative Query:** Terjadi antara Recursive Resolver dengan Root, TLD, dan Authoritative Nameservers. Server yang ditanya mengembalikan rujukan (*referral*) ke tingkat di bawahnya jika tidak memegang data definitif.

---

## LEVEL 0: Physical Transmission, BGP Anycast & Kernel-Level Processing

Level 0 mencakup infrastruktur fisik dan mekanisme perutean paket pada lapisan terendah sebelum paket DNS diproses oleh stack aplikasi.

### 1. BGP Anycast Infrastructure & AS-Path Routing

Infrastruktur DNS modern tidak berada pada satu mesin tunggal, melainkan didistribusikan melalui ribuan *Point of Presence* (PoP) di seluruh dunia.

```text
                                  [ BGP ANYCAST ROUTING ]
                                     IP: 198.51.100.1
                                     /      |      \
                                    /       |       \
               [ PoP Jakarta ] <────        |        ────> [ PoP Tokyo ]
                      ▲                     │                     ▲
                      │                     ▼                     │
               [ Klien Indonesia ]    [ PoP Frankfurt ]    [ Klien Jepang ]
```

- **Autonomous System Number (ASN) & BGP Peering:** Alamat IP Anycast diumumkan secara simultan oleh router perbatasan (*Edge Routers*) di berbagai benua menggunakan protokol *Border Gateway Protocol* (BGP).
- **Mekanisme Perutean:** Router transit internet mengarahkan paket ke PoP terdekat berdasarkan metrik *AS-Path shortest length*.
- **Vektor Kegagalan & Fenomena BGP Flapping:** Jika terjadi ketidakstabilan rute (*route flap*), paket UDP dari satu kueri dapat terlempar ke PoP yang berbeda (*Anycast Flapping*). Meskipun UDP toleran terhadap pergantian rute antar kueri, koneksi TCP (seperti zone transfer atau DoT) akan terputus karena status stateful TCP tidak tersinkronisasi antar PoP.
- **BGP Hijacking:** Penyerang yang menguasai router BGP nakal dapat mengumumkan rute prefiks yang lebih spesifik (misal `/24` atas blok `/23` korban) untuk membelokkan lalu lintas DNS global ke server palsu.
- **BGP Anycast vs GeoDNS:**

| Parameter | BGP Anycast (Network Layer) | GeoDNS (Application Layer) |
|:---|:---|:---|
| **Prinsip Kerja** | Satu alamat IP diumumkan oleh banyak router di berbagai lokasi via BGP. | Satu domain memiliki banyak alamat IP yang dipilih berdasarkan lokasi penanya. |
| **Titik Penentu** | Tabel routing Internet (BGP AS-Path, peering, policy). | Perangkat lunak DNS Server yang membaca basis data GeoIP. |
| **Kecepatan Failover** | Otomatis melalui konvergensi BGP jika satu PoP mati. | Bergantung pada sisa TTL rekor pada resolver klien (lambat jika TTL panjang). |
| **Kelemahan** | Potensi rute sub-optimal akibat peering lokal buruk (*BGP tromboning*). | Salah deteksi lokasi jika resolver klien menggunakan IP publik lintas negara tanpa ECS. |

### 2. Kernel-Level Ingress & Socket Sharding (`SO_REUSEPORT`)

Pada server dengan beban hingga jutaan kueri per detik (QPS), arsitektur *single-socket* menjadi hambatan performa akibat perebutan kunci antrean memori (*mutex lock contention*).

- **Socket Sharding:** Mengaktifkan flag kernel Linux `SO_REUSEPORT` memungkinkan setiap thread pekerja (*worker thread*) membuka socket UDP port 53 independen pada port yang sama.
- **4-Tuple Hashing:** Kernel mendistribusikan paket masuk secara deterministik berdasarkan hash `(Src IP, Src Port, Dst IP, Dst Port)` ke masing-masing antrean core CPU.

### 3. Kernel Bypass & eBPF/XDP Filtering

Untuk menangani serangan DDoS DNS berskala terabit (*DNS Amplification* atau *Water Torture Attack*), pemrosesan dilakukan sebelum paket dialokasikan ke memori kernel (`struct sk_buff`).

```text
[ Paket Jaringan Masuk (10/40/100 Gbps) ]
                   │
        [ Driver NIC / RX Ring ]
                   │
        ( eBPF / XDP Hook ) ───[ Paket Anomali / Amplifikasi ]───► [ XDP_DROP ]
                   │
            [ XDP_PASS ]
                   │
        [ Linux Network Stack ]
                   │
      [ SO_REUSEPORT Socket Ring ]
       ┌───────────┼───────────┐
       ▼           ▼           ▼
   [Core 0]    [Core 1]    [Core 2]  (Worker Threads BIND / Knot / Unbound)
```

Snippet program C eBPF/XDP untuk filtering paket DNS anomali di ring buffer NIC:

```c
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>

SEC("xdp_dns_filter")
int dns_filter_main(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;

    // Parsing Ethernet Header
    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end) return XDP_PASS;
    if (eth->h_proto != __constant_htons(ETH_P_IP)) return XDP_PASS;

    // Parsing IPv4 Header
    struct iphdr *ip = data + sizeof(*eth);
    if ((void *)(ip + 1) > data_end) return XDP_PASS;
    if (ip->protocol != IPPROTO_UDP) return XDP_PASS;

    // Parsing UDP Header
    struct udphdr *udp = (void *)ip + (ip->ihl * 4);
    if ((void *)(udp + 1) > data_end) return XDP_PASS;

    // Memeriksa Port Tujuan DNS (53)
    if (udp->dest == __constant_htons(53)) {
        unsigned char *dns_payload = (void *)(udp + 1);
        if ((void *)(dns_payload + 12) > data_end) return XDP_PASS;

        // Inspeksi DNS Header: Menolak Query ANY (QTYPE = 255 / 0x00FF)
        // yang sering disalahgunakan dalam serangan DNS Amplification
    }
    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
```

---

## LEVEL 1: Wire Format, Byte Flags & Protocol Parsing

Level 1 mendefinisikan struktur biner paket DNS pada lapisan transmisi sesuai spesifikasi **RFC 1035** dan ekstensi **RFC 6891 (EDNS0)**.

```text
+-------------------------------------------------------------------+
| 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15                     |
+-------------------------------------------------------------------+
|                      Transaction ID (16 bit)                      |
+----+----------------+--+--+--+--+-----+---------------------------+
| QR | Opcode (4 bit) |AA|TC|RD|RA|  Z  | RCODE (4 bit: 0=OK,3=NX)  |
+----+----------------+--+--+--+--+-----+---------------------------+
|                    QDCOUNT (Jumlah Pertanyaan)                    |
+-------------------------------------------------------------------+
|                     ANCOUNT (Jumlah Jawaban)                      |
+-------------------------------------------------------------------+
|                   NSCOUNT (Jumlah Record Otoritas)                |
+-------------------------------------------------------------------+
|                  ARCOUNT (Jumlah Record Tambahan)                 |
+-------------------------------------------------------------------+
```

### 1. Dekomposisi Header DNS (12 Bytes)

- **Transaction ID (16-bit):** Identifier acak untuk mencocokkan kueri dengan respons (target serangan *Cache Poisoning*).
- **QR (1-bit):** `0` untuk Query, `1` untuk Response.
- **Opcode (4-bit):** `0` = QUERY, `1` = IQUERY, `2` = STATUS, `4` = NOTIFY (RFC 1996), `5` = UPDATE (RFC 2136).
- **AA (1-bit):** *Authoritative Answer*. Bernilai `1` jika server penanggap adalah pemilik sah zona domain.
- **TC (1-bit):** *Truncated*. Bernilai `1` jika respons melebihi kapasitas buffer UDP, menginstruksikan klien melakukan fallback ke TCP port 53.
- **RD (1-bit):** *Recursion Desired*. Diset oleh klien untuk meminta pencarian rekursif penuh.
- **RA (1-bit):** *Recursion Available*. Diset oleh server untuk menandakan kesediaan melakukan rekursi.
- **RCODE (4-bit):** Kode respon (`0` = NOERROR, `1` = FORMERR, `2` = SERVFAIL, `3` = NXDOMAIN, `5` = REFUSED).

### 2. Ekstensi EDNS0 (RFC 6891) & Pseudo-Record `OPT`

Untuk mengatasi limit buffer UDP 512-byte era awal internet, EDNS0 menambahkan pseudo-record `OPT` (Type 41) pada *Additional Section*:

- **UDP Payload Size (16-bit):** Mengumumkan kapasitas buffer penerima klien (standar modern: 1232 bytes).
- **Extended RCODE & Flags:** Menambahkan bit `DO` (*DNSSEC OK*) pada bit ke-15 bit flag, menandakan kesiapan menerima record `RRSIG` dan `DNSKEY`.
- **Option Data (TLV Format):** Menampung opsi dinamis seperti *EDNS Client Subnet (ECS / RFC 7871)*, *DNS Cookie (RFC 7873)*, dan *Extended DNS Errors (EDE / RFC 8914)*.

---

## LEVEL 2: Recursive Resolution, Caching Dynamics & Privacy Engineering

Level 2 merepresentasikan logika internal *Recursive Resolver* yang menjembatani klien lokal dengan server otoritatif global.

### 1. Algoritma Penelusuran Iteratif

1. Menerima kueri dengan flag `RD=1`.
2. Memeriksa *in-memory cache*. Jika ditemukan rekor valid ($T_{\text{sekarang}} < T_{\text{expire}}$), langsung kembalikan respons dengan nilai $\text{TTL} = T_{\text{expire}} - T_{\text{sekarang}}$.
3. Jika *cache miss*, resolver memulai kueri iteratif berantai:
   - Kueri ke Root Hint (`.`) $\rightarrow$ Delegasi TLD NS.
   - Kueri ke TLD NS $\rightarrow$ Delegasi Authoritative NS dan rekor DS.
   - Kueri ke Authoritative NS $\rightarrow$ Rekor final beserta tanda tangan RRSIG.
4. Menyimpan seluruh himpunan RRSet ke dalam cache dan mengembalikan jawaban ke klien.

### 2. Caching Engines & Anomali Memori

- **TTL Clamping:** Praktik resolver menimpa batas TTL ekstrem. Batas minimum dipaksa (misal minimal 60 detik) untuk mencegah banjir kueri, dan batas maksimum dipaksa (misal maksimal 86400 detik) untuk menjamin kesegaran data.
- **Negative Caching (RFC 2308):** Menyimpan status ketiadaan domain (`NXDOMAIN` atau `NODATA`) berdasarkan nilai parameter `MINIMUM` pada record SOA zona target.
- **Serve-Stale (RFC 8767):** Mekanisme ketahanan di mana resolver tetap menyajikan record kedaluwarsa (*stale cache*) jika Authoritative Server target sedang mengalami pemadaman total atau timeout.
- **Ghost Domain Names Vulnerability:** Celah di mana domain berbahaya yang telah dicabut dari TLD tetap hidup di cache resolver karena penyerang terus memperbarui kueri subdomain baru sebelum cache resolver kedaluwarsa.

### 3. QNAME Minimization (RFC 9156)

Mekanisme pengamanan privasi dengan memangkas label domain yang tidak relevan saat menghubungi server tingkat atas:

$$\text{Query Klien: } \texttt{secret.dev.labsec.id}$$
$$\text{Kueri ke Root: } \texttt{QTYPE=NS, QNAME=.id}$$
$$\text{Kueri ke TLD .id: } \texttt{QTYPE=NS, QNAME=labsec.id}$$
$$\text{Kueri ke Authoritative: } \texttt{QTYPE=A, QNAME=secret.dev.labsec.id}$$

---

## LEVEL 3: Authoritative Control, Zone Architecture & Replication

Level 3 mengatur pengelolaan file zona definitif, replikasi data antar server primer-sekunder, dan administrasi rekor tingkat lanjut.

### 1. Replikasi Zona: AXFR & IXFR

- **AXFR (Authoritative Zone Transfer - RFC 5936):** Transfer salinan penuh seluruh isi file zona melalui protokol TCP port 53. Dipicu oleh perubahan nomor serial pada rekor SOA.
- **IXFR (Incremental Zone Transfer - RFC 1995):** Mentransmisikan perubahan selisih (*diff*) penambahan dan penghapusan record sejak serial terakhir, menghemat bandwidth pada zona besar.
- **NOTIFY Protocol (RFC 1996):** Server Primer mengirimkan pesan *NOTIFY* instan ke seluruh Server Sekunder saat file zona diperbarui, mengeliminasi penundaan interval refresh SOA.

### 2. Keamanan Transfer Zona via TSIG (RFC 8945)

Menggunakan kunci simetris (*shared secret*) dengan algoritma `hmac-sha256` untuk mencegah pihak asing mengunduh isi zona atau mengirimkan update palsu:

```text
key "transfer-key.labsec.id." {
    algorithm hmac-sha256;
    secret "h8K9fJ...[Base64 Key]...";
};

server 192.168.10.11 {
    keys { "transfer-key.labsec.id."; };
};
```

### 3. Dynamic DNS (RFC 2136) & Apex Flattening

- **RFC 2136 UPDATE:** Memungkinkan mesin klien, DHCP server, atau Kubernetes ExternalDNS menambah/menghapus rekor DNS secara real-time via paket biner terotentikasi TSIG.
- **Zone Apex CNAME Flattening:** Spesifikasi RFC 1034 melarang keberadaan CNAME bersamaan dengan record SOA/NS pada root domain (`@` atau `domain.id`). Rekor sintetis (`ALIAS` / `ANAME`) menyelesaikan IP target CNAME secara internal dan menerbitkannya sebagai rekor `A`/`AAAA` statis.

---

## LEVEL 4: Modern Transport, Application Protocols & Privacy Layer

Level 4 mentransformasikan protokol DNS dari format teks polos tak terotentikasi menjadi saluran terenkripsi berkinerja tinggi.

```text
+----------------------------------------------------------------------------------------------------+
| 1. DoT (RFC 7858 - Port 853)                                                                       |
| [ Client ] ───( TLS 1.3 Handshake )───► [ Resolver:853 ] ───( Terisolasi di Port Khusus )          |
+----------------------------------------------------------------------------------------------------+
| 2. DoH (RFC 8484 - Port 443)                                                                       |
| [ Client ] ───( HTTP/2 & HTTP/3 Frame POST /dns-query )───► [ Resolver:443 (Menyatu Web Traffic) ] |
+----------------------------------------------------------------------------------------------------+
| 3. DoQ (RFC 9250 - Port 853 UDP)                                                                   |
| [ Client ] ───( QUIC Streams, 0-RTT, Anti Head-of-Line Blocking )───► [ Resolver:853 ]             |
+----------------------------------------------------------------------------------------------------+
| 4. ODoH (RFC 9230 - Oblivious DoH)                                                                 |
| [ Client ] ──(Terenkripsi HPKE)──► [ Proxy ] ──(Relay)──► [ Target Resolver ]                      |
| (Proxy tahu IP Klien, Target tahu Kueri; Tidak ada satu entitas pun yang mengetahui keduanya)       |
+----------------------------------------------------------------------------------------------------+
```

Matriks karakteristik transport modern:

| Protokol | Port | Transport | Karakteristik Teknis & Keamanan |
|:---|:---|:---|:---|
| **Plain DNS** | 53 | UDP / TCP | Format biner mentah; tanpa enkripsi; rentan spoofing |
| **DoT (RFC 7858)** | 853 | TLS over TCP | Enkripsi TLS murni; port terdedikasi (mudah diblokir firewall) |
| **DoH (RFC 8484)** | 443 | HTTP/2 & HTTP/3 | Kueri menyatu dengan web traffic; sulit diblokir |
| **DoQ (RFC 9250)** | 853 | QUIC (UDP) | Bebas Head-of-Line Blocking; 0-RTT Handshake |
| **ODoH (RFC 9230)** | 443 | HPKE + Proxy | IP klien terpisah dari isi kueri via arsitektur Target & Proxy |

### Service Binding & HTTPS Records (RFC 9460)

Rekor **`HTTPS` (Resource Record Type 65)** dan **`SVCB` (Type 64)** mengubah paradigma inisiasi koneksi web modern:

1. **0-RTT Protocol Bootstrapping:** Menggabungkan resolusi alamat IP (`A`/`AAAA`), parameter ALPN (`h2`, `h3`), dan konfigurasi port dalam satu transaksi kueri tunggal sebelum koneksi TCP/TLS dibuka ke server web.
2. **Encrypted Client Hello (ECH):** Memuat konfigurasi kunci publik kriptografi server web. Peramban mengenkripsi Server Name Indication (SNI) pada *ClientHello* TLS 1.3 sehingga ISP transit tidak dapat melihat nama domain web yang diakses pengguna.

Contoh deklarasi record HTTPS via dig:

```text
labsec.id.  300 IN HTTPS 1 . (
    alpn="h3,h2"
    ipv4hint=192.168.10.100
    ech="AEn+DQBF...[Base64 Encrypted Client Hello Config]..."
)
```

---

## LEVEL 5: Cryptographic Trust, Key Lifecycle & DNSSEC

Level 5 menegakkan jaminan integritas kriptografis (*integrity*) dan keaslian asal data (*authenticity*) menggunakan rantai tanda tangan digital global.

```text
                  [ Root Zone: . ]
                  KSK Tag: 20326 (Validasi via Root Trust Anchor Klien)
                         │
                    (Menandatangani RRSet DNSKEY & DS .id)
                         ▼
                  [ TLD Zone: .id ]
                  DS Tag: 45892 (Hash KSK Anak)
                         │
                    (Menandatangani RRSet DNSKEY & DS labsec.id)
                         ▼
                  [ Child Zone: labsec.id ]
                  KSK Tag: 2371 (Algoritma 13 ECDSA-P256)
                         │ (Menandatangani DNSKEY)
                  ZSK Tag: 61402 (Algoritma 13 ECDSA-P256)
                         │ (Menandatangani Data RRSet)
                         ▼
                  [ Data Record: A labsec.id = 192.168.10.100 ]
                  [ Tanda Tangan: RRSIG A 13 2 300 ... ]
```

### 1. Komponen Rantai Kriptografi (Chain of Trust)

- **Root Trust Anchor:** Kunci publik Root KSK yang tertanam permanen pada perangkat lunak recursive resolver di seluruh dunia.
- **KSK (Key Signing Key - Flag 257):** Pasangan kunci asimetris tingkat tinggi untuk menandatangani himpunan kunci publik (`DNSKEY`). Hash KSK dipublikasikan ke parent zone sebagai record `DS`.
- **ZSK (Zone Signing Key - Flag 256):** Kunci asimetris operasional untuk menandatangani seluruh data record (`A`, `AAAA`, `MX`, dll.) menghasilkan record `RRSIG`.
- **RRSIG (Resource Record Signature):** Record tanda tangan digital kriptografis yang menyertai setiap RRSet, memuat masa berlaku (*inception* & *expiration time*), label count, dan signature biner.
- **Algoritma Modern:** Standar modern mewajibkan **Algoritma 13 (ECDSA P-256)** atau **Algoritma 15 (Ed25519)** dengan ukuran signature ringkas (~64 bytes) dibanding RSA-2048 (~256 bytes), mengeliminasi risiko fragmentasi paket IP.

### 2. Authenticated Denial of Existence

- **NSEC (RFC 4034):** Menyambungkan seluruh nama domain secara terurut dalam linked list. Rentan terhadap serangan **Zone Walking** (membocorkan seluruh daftar subdomain internal).
- **NSEC3 (RFC 5155):** Mengaburkan nama record menggunakan salted hash. Berdasarkan rekomendasi **RFC 9276**, jumlah iterasi hash **wajib diset ke 0** untuk mencegah serangan kehabisan siklus CPU (*CPU DoS*) pada recursive resolver.
- **White Lies / Minimally-Covering NSEC (RFC 4470):** Membuat record NSEC sintetis secara dinamis yang hanya mencakup rentang alfabetis sempit di sekitar kueri, menghentikan zone walking tanpa overhead hashing berulang.

### 3. State Machine Rollover Kunci & Otomasi via CDS/CDNSKEY

```text
================================================================================
          FASE ZSK ROLLOVER (SKEMA PRE-PUBLISH - PERIODE 60 HARI)
================================================================================
Waktu (T)   Status DNSKEY Set              Status RRSIG Data            Keterangan
---------   -----------------              -----------------            ----------
T0          [ ZSK-1 (Aktif) ]              Signed by: ZSK-1             Operasi Normal
T1          [ ZSK-1 (Aktif), ZSK-2 (Pub) ] Signed by: ZSK-1             Pre-Publish ZSK-2
            (Tunggu durasi: TTL DNSKEY + Waktu Propagasi Global)
T2          [ ZSK-1 (Ret), ZSK-2 (Aktif) ] Signed by: ZSK-2             Aktivasi Signing ZSK-2
            (Tunggu durasi: TTL RRSIG + Waktu Propagasi Global)
T3          [ ZSK-2 (Aktif) ]              Signed by: ZSK-2             Pencabutan ZSK-1
```

- **Otomasi KSK Rollover (RFC 7344 / RFC 8078):** Authoritative server menerbitkan record `CDS` (*Child DS*) dan `CDNSKEY` (*Child DNSKEY*) di dalam zonanya yang ditandatangani oleh KSK lama. Registry TLD secara periodik memindai, memverifikasi tanda tangan, dan memperbarui record `DS` di level parent secara mandiri tanpa intervensi manual.

---

## LEVEL 6: Adversarial Exploitation & Defense Engineering

Level 6 menganalisis taktik penyerangan siber terhadap infrastruktur DNS beserta arsitektur pertahanan aktif (*Detection & Defense Engineering*).

```text
================================================================================
          VEKTOR SERANGAN DNS VS ARSITEKTUR PERTAHANAN DEFENSIVE
================================================================================
Vektor Eksploitasi (Offensive)              Arsitektur Mitigasi (Defensive)
---------------------------------------     ------------------------------------
1. Kaminsky Cache Poisoning (TxID Guess) ──► Port Randomization + DNSSEC Validation
2. DNS Amplification DDoS (Any/DNSKEY)   ──► Response Rate Limiting (RRL) + eBPF/XDP
3. DNS Rebinding (Same-Origin Bypass)   ──► Anti-DNS Rebinding Proxy + Host Validation
4. DNS Tunneling C2 (Iodine/dnscat2)    ──► Entropy Analysis + RPZ Threat Intelligence
5. NXNSAttack / TsuNAME Amplification    ──► Max Delegation Limits + Query Throttling
```

### 1. Analisis Vektor Eksploitasi Mendalam

- **Kaminsky DNS Cache Poisoning:** Penyerang mengirimkan kueri acak (`rand1.target.com`) ke recursive resolver target sambil membanjiri resolver dengan ribuan paket respon palsu yang memalsukan IP Authoritative Server. Jika Transaction ID (16-bit) dan UDP Source Port (16-bit) cocok sebelum jawaban asli tiba, penyerang dapat menyuntikkan delegasi NS baru untuk menguasai domain secara permanen.
- **DNS Rebinding Attack:** Teknik membobol *Same-Origin Policy* (SOP) pada peramban web korban dengan TTL pendek (1 detik). Domain awalnya merujuk ke IP publik penyerang untuk memuat JavaScript, kemudian resolusi dialihkan ke IP lokal intranet korban (`127.0.0.1` atau `192.168.1.1`) untuk mengeksploitasi layanan lokal.
- **DNS Tunneling & C2 Exfiltration:** Penyerang mengenkapsulasi perintah botnet atau payload data rahasia (Base32/Base64) ke dalam kueri subdomain:

$$\texttt{kueri: } \underbrace{\text{eJzt2tkNgCAMANDWOpKBqO...}}_{\text{Data Terenkripsi}}.\texttt{c2.attacker.com}$$

### 2. Arsitektur Pertahanan Aktif (Defense Engineering)

- **Response Policy Zone (RPZ - RFC 9499):** *DNS Firewall* berbasis langganan feed intelijen ancaman. Resolver secara dinamis memblokir, mengarahkan ke halaman isolasi (*walled garden*), atau mengembalikan `NXDOMAIN` untuk domain yang terindikasi malware, phishing, atau C2.
- **Entropy & Volume Anomaly Detection:** Menganalisis nilai entropi informasi Shannon pada label subdomain. Kueri normal memiliki entropi rendah, sedangkan payload data tunneling memiliki variasi karakter acak yang tinggi ($H(X) > 3.8$).
- **Response Rate Limiting (RRL):** Mengelompokkan kueri masuk dari subnet peminta yang sama. Jika permintaan terhadap record identik melebihi ambang batas (misal 50 respon/detik), server otoritatif membatasi respon atau mengembalikan paket terpotong (`TC=1`) untuk memaksa verifikasi alamat IP via koneksi TCP.
- **DNS Cookies (RFC 7873 / RFC 9018):** Autentikasi ringan dua arah pada transport UDP. Client Cookie (8 bytes) dan Server Cookie (8-32 bytes berbasis HMAC-SHA256) memverifikasi bahwa kueri tidak dipalsukan IP-nya.
- **The 1232-Byte Rule:** Konfigurasi `edns-buffer-size` diset ke 1232 bytes ($1280\text{ IPv6 MTU} - 40\text{ IPv6 Header} - 8\text{ UDP Header}$) untuk mencegah fragmentasi IP di Layer 3 yang rentan dieksploitasi melalui *Fragment Injection Attack*.

---

## LEVEL 7: Decentralized Naming, P2P Resolution & Post-Quantum Architectures

Level 7 mencakup arsitektur resolusi masa depan yang mengeliminasi ketergantungan pada otoritas terpusat (ICANN/Root) dan mempersiapkan ketahanan terhadap komputasi kuantum.

```text
[ Level 7.1: Blockchain & Decentralized Name Systems ]
  * Ethereum Name Service (ENS - .eth via Smart Contract ERC-721/1155)
  * Handshake (HNS - Root Zone Terdesentralisasi berbasis Proof-of-Work UTXO)
  * Namecoin (.bit - Merged-mined Blockchain Name System)

[ Level 7.2: Peer-to-Peer DHT & Darknet Resolution ]
  * Kademlia Distributed Hash Table (IPFS / libp2p name routing)
  * Tor Onion v3 Addresses (ed25519 Public Key terenkode Base32 sebagai domain)
  * I2P B32/LeaseSet Encryption Network

[ Level 7.3: Post-Quantum Cryptography (PQC) DNSSEC ]
  * NIST PQC Standards: ML-DSA (Dilithium) & SLH-DSA (SPHINCS+)
  * Tantangan MTU & Fragmentasi: Ukuran Signature PQC (1.3 KB - 8 KB)
  * Transisi Hybrid Post-Quantum Key Exchange (X25519Kyber768 pada DoT/DoH/DoQ)
```

### 1. Decentralized & Blockchain Naming Systems

- **Ethereum Name Service (ENS):** Resolusi nama menggunakan smart contract pada blockchain Ethereum. Kepemilikan domain berbasis token NFT (ERC-721), dipetakan ke alamat wallet, hash konten IPFS, atau record DNS tradisional via EIP-137.
- **Handshake (HNS):** Menggantikan 13 Root Server terpusat dan file root zone ICANN dengan konsensus blockchain Proof-of-Work. Klien Handshake menanyakan delegasi TLD langsung ke node blockchain lokal, mengeliminasi risiko sensor atau penyitaan domain di tingkat TLD.

### 2. Kriptografi Post-Quantum (PQC) pada DNSSEC

Algoritma Shor pada komputer kuantum masa depan akan mematahkan kriptografi ECDSA dan RSA yang digunakan DNSSEC saat ini.

- **Standar NIST PQC:** Migrasi ke algoritma berbasis kisi (*lattice-based*) seperti **ML-DSA (Dilithium)** atau berbasis hash stateful seperti **SLH-DSA (SPHINCS+)**.
- **Hambatan Utama (The MTU Problem):**
  - Signature ECDSA P-256: **64 bytes** (muat dalam 1 paket UDP 1232-byte).
  - Signature ML-DSA-44: **2.420 bytes**.
  - Signature SPHINCS+-SHA2-128s: **7.856 bytes**.
- **Implikasi Jaringan:** Penggunaan PQC pada DNSSEC akan memaksa seluruh kueri DNS berpindah secara permanen ke protokol transport berbasis koneksi terenkripsi (**DoT**, **DoQ**, atau **TCP dengan DNS Cookies**) karena payload signature kuantum melampaui batas transmisi aman paket UDP.

---

## Standard Operating Procedure (SOP) Deployment

### A. SOP Authoritative DNSSEC Signing (BIND 9.18+)

Implementasi deklaratif modern pada BIND 9.18+:

#### 1. Konfigurasi Kebijakan di `/etc/bind/named.conf.options`

```text
options {
    directory "/var/cache/bind";
    recursion no;
    listen-on { any; };
    listen-on-v6 { any; };
    allow-transfer { none; };
    edns-udp-size 1232;
    max-udp-size 1232;
};

dnssec-policy "standard-ecdsa" {
    keys {
        ksk key-directory lifetime unlimited algorithm 13;
        zsk key-directory lifetime 60d algorithm 13;
    };
    signatures-validity 14d;
    signatures-refresh 3d;
    signatures-jitter 12h;
    publish-safety 2h;
    retire-safety 2h;
};
```

#### 2. Konfigurasi Zona di `/etc/bind/named.conf.local`

```text
zone "labsec.id" {
    type primary;
    file "/etc/bind/zones/db.labsec.id";
    key-directory "/var/lib/bind/keys";
    dnssec-policy "standard-ecdsa";
    inline-signing yes;
};
```

#### 3. Inisialisasi Kunci & Ekstraksi DS Record

```bash
mkdir -p /var/lib/bind/keys
chown -R bind:bind /var/lib/bind/keys
chmod 700 /var/lib/bind/keys

named-checkconf
systemctl restart named

# Ekstraksi DS record untuk didaftarkan ke Registrar / TLD
cd /var/lib/bind/keys
dnssec-dsfromkey Klabsec.id.*.key
```

### B. SOP Hardened Validating Recursive Resolver (Unbound)

Konfigurasi pengerasan resolver pada `/etc/unbound/unbound.conf`:

```text
server:
    interface: 0.0.0.0
    interface: ::0
    port: 53
    access-control: 192.168.0.0/16 allow
    access-control: 127.0.0.0/8 allow

    # Validasi Kriptografi DNSSEC
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    val-clean-additional: yes
    val-permissive-mode: no
    harden-dnssec-stripped: yes
    harden-below-nxdomain: yes
    harden-referral-path: yes

    # Privasi & Pengurangan Informasi
    qname-minimisation: yes
    qname-minimisation-strict: no
    hide-identity: yes
    hide-version: yes

    # Optimasi Buffer & Socket
    edns-buffer-size: 1232
    so-reuseport: yes
    num-threads: 4
    msg-cache-slabs: 4
    rrset-cache-slabs: 4
    infra-cache-slabs: 4
    key-cache-slabs: 4
```

---

## Matriks Koreksi Miskonsepsi Teknis

| Miskonsepsi Populer | Fakta & Koreksi Teknis Riil |
|:---|:---|
| *DNSSEC mengenkripsi isi komunikasi DNS pengguna.* | DNSSEC murni menyediakan autentikasi dan integritas (*zero confidentiality*). Kerahasiaan data hanya dapat dicapai melalui DoT, DoH, atau DoQ. |
| *Koneksi DNS hanya beroperasi di atas protokol UDP.* | Implementasi DNS wajib mendukung TCP port 53 untuk transfer zona (AXFR/IXFR), respons terpotong (`TC=1`), dan negosiasi fallback DNSSEC. |
| *DNS cache pasti kedaluwarsa tepat sesuai durasi TTL.* | Resolver menerapkan kebijakan *TTL Clamping* (batas minimum/maksimum yang dipaksakan) atau *Serve-Stale* (RFC 8767) saat server otoritatif mengalami kendala. |
| *Semua resolver Anycast merespons dari server yang sama.* | BGP mengarahkan lalu lintas ke PoP terdekat secara independen. Gangguan rute (*route flap*) dapat melempar kueri antar PoP secara dinamis. |
