---
title: "DNS Fundamentals BIND9"
tags:
  - infrastructure
  - networking
  - dns
  - bind9
  - homelab
aliases:
  - "DNS Self-Hosting"
  - "BIND9 Nameserver"
  - "Domain Name System Deep Dive"
created: "2026-07-11"
updated: "2026-07-11"
status: pending
cssclasses: ""
---

# 🌐 DNS Fundamentals & BIND9 Self-Hosting

> **Filosofi:** DNS adalah hal pertama yang harus working sebelum service apapun jalan. Tapi juga hal paling sering dianggap remeh — sampai ada outage dan semua app "Connection refused" karena resolver gak bisa resolve.

---

## DNS Resolution Flow

```
Browser Anda
    │
    ▼
┌──────────────────┐    1     ┌──────────────────┐
│  Stub Resolver    │────────▶│  Recursive        │
│  (/etc/resolv.conf)│         │  Resolver (ISP/   │
│  192.168.1.1      │◀────────│  8.8.8.8/1.1.1.1) │
└──────────────────┘    6     └────────┬─────────┘
                                        │ 2
                                        ▼
                                ┌──────────────────┐
                                │  Root Nameserver  │
                                │  (.)              │
                                └────────┬─────────┘
                                        │ 3 — "ask .id"
                                        ▼
                                ┌──────────────────┐
                                │  TLD Nameserver   │
                                │  (.id)            │
                                └────────┬─────────┘
                                        │ 4 — "ask ns1.domain.com"
                                        ▼
                                ┌──────────────────┐
                                │  Authoritative    │◀── BIND9 HERE
                                │  Nameserver       │
                                │  (BIND9)          │
                                └──────────────────┘
                                    │ 5 — "A record: 203.x.x.x"
                                    │
                                    ▼
                              Answer to client
```

---

## Record Types — Yang Sering Dipakai

| Record | Fungsi | Contoh |
|--------|--------|--------|
| **A** | IPv4 address | `domain.com. IN A 203.0.113.1` |
| **AAAA** | IPv6 address | `domain.com. IN AAAA 2001:db8::1` |
| **CNAME** | Alias ke domain lain | `www IN CNAME domain.com.` |
| **MX** | Mail server priority | `domain.com. IN MX 10 mail.domain.com.` |
| **TXT** | Teks (SPF, DKIM, verification) | `domain.com. IN TXT "v=spf1 mx ~all"` |
| **NS** | Nameserver delegation | `domain.com. IN NS ns1.domain.com.` |
| **SOA** | Start of Authority — master data | Wajib di setiap zone |
| **SRV** | Service location | `_sip._tcp IN SRV 10 5 5060 sip.domain.com` |

> [!tip] TTL Strategy
> TTL rendah (60-300s) untuk record yang sering berubah (failover, CDN). TTL tinggi (3600-86400s) untuk MX, NS, TXT.

---

## Authoritative vs Recursive

| Aspek | Authoritative | Recursive |
|------|-------------|-----------|
| **Tugas** | Jawab query untuk zone yang di-manage | Cari jawaban dari rantai resolver |
| **Data** | Zone file lokal — source of truth | Hasil cache dari upstream |
| **Contoh** | BIND9 sebagai primary/secondary | Unbound, systemd-resolved, 8.8.8.8 |
| **Homelab use** | Host domain sendiri | Lebih baik pake upstream (Cloudflare/Google) |

> [!warning] Jangan Campur
> BIND9 bisa jadi authoritative + recursive sekaligus. Tapi **jangan**. Authoritative harus bisa diakses publik. Recursive cuma boleh untuk internal. Campur = open resolver → DDoS amplification vector.

---

## BIND9 — Basic Setup (Authoritative Only)

### Install

```bash
apt install bind9 bind9utils bind9-doc
```

### Zone File Example — `db.domain.com`

```dns
$TTL 3600
@   IN  SOA     ns1.domain.com. admin.domain.com. (
                2026071101  ; serial (YYYYMMDDNN)
                3600        ; refresh
                900         ; retry
                86400       ; expire
                600 )       ; minimum TTL

; Nameservers
@       IN  NS      ns1.domain.com.
@       IN  NS      ns2.domain.com.

; Records
@       IN  A       203.0.113.10
ns1     IN  A       203.0.113.10
ns2     IN  A       203.0.113.20
www     IN  CNAME   @
mail    IN  A       203.0.113.10
@       IN  MX 10   mail.domain.com.
@       IN  TXT     "v=spf1 mx -all"
```

### Named.conf — `named.conf.local`

```nginx
zone "domain.com" {
    type master;
    file "/etc/bind/db.domain.com";
    allow-transfer { 203.0.113.20; };   // secondary NS
    also-notify { 203.0.113.20; };
};
```

### Testing

```bash
# Verifikasi config
named-checkconf
named-checkzone domain.com /etc/bind/db.domain.com

# Query test
dig @localhost domain.com A
dig @localhost domain.com MX
dig @localhost domain.com TXT
```

---

## Homelab Use Cases

| Skenario | Setup | Complexity |
|----------|-------|-----------|
| **Local dev domains** (`*.test`) | BIND9 + dnsmasq | Mudah |
| **Ad blocking** | Pi-hole (DNS sinkhole) | Mudah |
| **Internal service discovery** | BIND9 + SRV records | Medium |
| **Public nameserver** | BIND9 + DDNS + monitoring | Advanced |
| **Secondary (slave)** | BIND9 zone transfer | Medium |

---

## Failure Mode — Ketika DNS Gagal

| Gejala | Kemungkinan | Test |
|--------|-------------|------|
| **"ping: name not resolved"** | Resolver broken | `dig @1.1.1.1 domain.com` |
| **Website buka, email gak bisa** | MX record salah | `dig domain.com MX` |
| **Lambat banget buka web** | Resolver slow/loss | `dig +stats domain.com` |
| **"SERVFAIL"** | Authoritative NS error | `dig +trace domain.com` |
| **Port 53 filtered** | Firewall block | `nmap -sU -p 53 -Pn host` |
| **Serial mismatch** | Zone transfer gagal | Cek serial di SOA vs secondary |

---

---

## 🧠 Berpikir — Metodologi Penyusunan Catatan

Catatan ini disusun melalui proses berpikir terstruktur sebagai berikut:

### 1. Thinking Type yang Digunakan

| Type | Kenapa | Bagian |
|------|--------|--------|
| **Cognitive Thinking** | Membangun fondasi pemahaman DNS dari resolusi flow — siapa yang ngomong sama siapa, urutannya gimana | DNS Resolution Flow diagram |
| **Analytical Thinking** | Memecah record types berdasarkan fungsi dan use case — kapan pake A vs CNAME vs MX vs SRV | Record Types table |
| **Systems Thinking** | Menganalisis Authoritative vs Recursive — bagaimana koneksi keduanya, kenapa bahaya kalau digabung | Authoritative vs Recursive |
| **Concrete Thinking** | BIND9 setup step-by-step — install, zone file, named.conf, testing | BIND9 Basic Setup |
| **Futures Thinking** | Failure mode analysis — apa yang terjadi ketika DNS gagal di tiap layer | Failure Mode table |

### 2. Background Knowledge (Pra-Penulisan)

- **DNS resolution chain**: stub → recursive → root → TLD → authoritative. 7 hops minimal
- **SOA fields**: serial (YYYYMMDDNN — wajib increment), refresh/retry/expire/TTL — hubungan satu sama lain
- **Open resolver danger**: pengalaman BIND9 config salah → recursive terbuka → jadi DDoS amplifier
- **dig diagnostic**: `+trace` buat debug rantai, `+stats` buat ukur latency, `+short` buat output bersih
- **TTL strategy**: MX dan NS sebaiknya TTL tinggi — jarang berubah, dan caching membantu stability
- **Serial number convention**: format YYYYMMDDNN — NN untuk multiple changes dalam sehari. Git hook bisa auto-increment

### 3. RAG Vault — Dokumen yang Dikonsultasi

| Dokumen | Kontribusi |
|---------|-----------|
| [[network-security\|Network Security]] | OSI layer context, port UDP 53, TCP 53 untuk zone transfer |
| [[infrastructure-administrator\|Infrastructure Administrator]] | Server layout — namespace atau VM dedicated untuk BIND9 |
| [[podman-networking-ufw\|Podman Networking & UFW]] | Port exposure untuk BIND9 — UFW allow 53, routing rules |

### 4. Sintesis — Bagaimana Bagian Bergabung

```
Background Knowledge (DNS protocol + BIND9 ops + dig diagnostics)
    │
    ▼
RAG Vault (server architecture context)
    │
    ▼
Cognitive:   Resolution flow → siapa ngomong sama siapa
    │
    ▼
Analytical:  Record types → decompose per function → comparison table
    │
    ▼
Systems:     Auth vs Recursive → kenapa gabung itu bahaya → DDoS amplification
    │
    ▼
Concrete:    BIND9 config → install → zone file → named.conf → testing
    │
    ▼
Futures:     Failure modes → tiap gejala → diagnosis → fix
```

### 5. Sequential Thinking Steps

```
Thought 1 (Cognitive):   "DNS resolution flow: stub → recursive → root → TLD → authoritative → answer."
                           "Butuh diagram urutan biar jelas."
Thought 2 (Analytical):  "Ada 8 record types yang sering dipakai. Masing-masing punya format dan use case beda."
                           "A untuk IPv4, AAAA untuk IPv6, CNAME untuk alias, MX untuk mail."
Thought 3 (Systems):     "Authoritative = punya data. Recursive = cari data. Kalau digabung = open resolver."
                           "Open resolver = DDoS amplification vector. Jangan."
Thought 4 (Concrete):    "BIND9 config: install → zone file → named.conf → named-checkconf → dig test."
                           "Exact file content, bukan placeholder."
Thought 5 (Critical):    "Serial number lupa di-increment = zone transfer gak jalan, slave serve stale data."
                           "Ini bug paling sering dan paling silent."
Thought 6 (Futures):     "Kalau DNS down, apa yang terjadi? 'name not resolved', MX fail, SERVFAIL."
                           "Bikin table gejala → kemungkinan → test → fix."
```

---

## 🔗 Lihat Juga

- [[network-security|Network Security]] — OSI layer, port knowledge
- [[infrastructure-administrator|Infrastructure Administrator]] — Server setup
- [[podman-networking-ufw|Podman Networking & UFW]] — Port exposure pattern
---

audited
---
