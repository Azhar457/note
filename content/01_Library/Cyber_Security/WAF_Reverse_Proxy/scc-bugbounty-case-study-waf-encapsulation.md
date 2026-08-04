---
title: SCC Bug Bounty Case Study — WAF Invisibility & Server Encapsulation
tags:
  - cyber-security
  - bug-bounty
  - waf
  - shodan
  - waf
  - recon
  - library
aliases:
  - Bug Bounty Shodan Gap
  - WAF Server Encapsulation
  - SSC Security Challenge
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# 🎯 SCC Bug Bounty Case Study — WAF Invisibility, Shodan Blindspot & Server Encapsulation

> Studi kasus dari SEVIMA Security Challenge (SSC) 2026 — bug bounty terhadap platform akademik berbasis web. Catatan ini bukan laporan temuan (lihat `challange_sevima/`), melainkan analisis soal gaps coverage Shodan terhadap platform yang dilindungi WAF, fenomena duplikasi temuan antar tim, dan konsep **server encapsulation** yang menjadi visi pengembangan WAF modern.

> [!tip] Relevance untuk WAF Developers
> Kasus ini memvalidasi bahwa kombinasi reverse proxy + WAF + CDN mampu membuat server asal tidak terdeteksi oleh scanning massal (Shodan/Censys). Namun, targeted attack yang mengetahui origin IP dari sumber lain (DNS history, certificate transparency) masih dapat melewati layer ini. Tantangan inilah yang mendorong konsep server encapsulation.

## Daftar Isi

1. [[#1. Latar Belakang — SSC 2026]]
2. [[#2. Shodan Blindspot — Platform Tidak Terindex]]
3. [[#3. Analisis — Mengapa Platform Invisible?]]
4. [[#4. Duplikasi Temuan — Realita Bug Bounty]]
5. [[#5. Konsep Server Encapsulation]]
6. [[#6. Roadmap Implementasi]]
7. [[#7. Referensi]]

---

## 1. Latar Belakang — SSC 2026

SSC (SEVIMA Security Challenge) 2026 adalah security challenge tertutup yang menargetkan platform **EdLink** — sebuah sistem akademik berbasis web untuk perguruan tinggi. Pengujian dilakukan secara black-box, tanpa autentikasi awal, dengan fokus pada endpoint API, SSO, dan platform Computer-Based Test (CBT).

### Scope Target

| Target | Jenis | Metode Pengujian |
|--------|-------|------------------|
| API Gateway | REST API (RESTful) | Black-box, unauthenticated |
| Frontend SPA | Nuxt.js SPA | JS bundle reverse engineering |
| SSO | OAuth2 + MFA | Login flow testing |
| CBT | Platform ujian online | Authenticated testing |

### Tim dan Metodologi

Pengujian dilakukan oleh tim yang terdiri dari 3 orang, terbagi dalam 2 fase:

- **Phase 1:** Unauthenticated API testing — endpoint mapping dari JavaScript bundle, parameter fuzzing, dan analisis response untuk menemukan informasi sensitif.
- **Phase 2:** Authenticated testing — login flow, MFA/OTP bypass, IDOR, dan role escalation menggunakan kredensial resmi yang diberikan penyelenggara.

Tools utama yang digunakan: Burp Suite, curl, Python scripting untuk OTP brute-force, dan analisis manual JavaScript bundle.

---

## 2. Shodan Blindspot — Platform Tidak Terindex

Salah satu observasi paling menarik selama proses reconnaissance: **platform target tidak memiliki catatan apapun di Shodan.**

```bash
# Query yang digunakan (domain di-redact)
shodan search "[DOMAIN_REDACTED]"
shodan search "ssl:[DOMAIN_REDACTED]"
# Result: 0 matches — tidak ada server yang terdeteksi
```

### Daftar Periksa Shodan Coverage

| Aspek | Hasil | Keterangan |
|-------|:-----:|------------|
| Domain search | ❌ 0 hasil | Tidak ditemukan |
| SSL certificate search | ❌ 0 hasil | Cert tidak terindex atau dibalik CDN |
| Port scan (top 1000) | ❌ Tidak ada port terbuka | Semua filtered |
| Subdomain enumeration | ❌ Tidak ada subdomain terindex | DNS tidak bocor |
| Historical data | ❌ Tidak ada record | Mungkin domain baru atau dilindungi |

### Verifikasi Manual

Untuk memastikan bahwa hasil ini bukan karena Shodan terbatas, dilakukan verifikasi menggunakan beberapa pendekatan:

```bash
# Verifikasi port langsung
nc -zv [DOMAIN_REDACTED] 443
# Output: Connection refused atau timeout

# Cek HTTP response headers
curl -sI https://[DOMAIN_REDACTED]/ | grep -i "server\|cf-ray\|cloudflare"
# Output: cf-ray header terdeteksi — mengkonfirmasi Cloudflare di depan server

# Censys sebagai comparison
censys search "[DOMAIN_REDACTED]"
# Result: 0 matches — konsisten dengan Shodan
```

---

## 3. Analisis — Mengapa Platform Invisible?

Invisibilitas dari Shodan bukanlah kebetulan, melainkan hasil dari kombinasi beberapa faktor keamanan:

### 3.1. Cloudflare Proxy

Seluruh traffic melewati Cloudflare CDN. Shodan hanya melihat IP Cloudflare, bukan origin server. Ini adalah mekanisme yang sama yang digunakan oleh banyak platform untuk menyembunyikan origin IP.

```
Request:  [Attacker] → [Cloudflare IP] → [WAF] → [Origin Server]
Shodan:   [Scanner]  → [Cloudflare IP]  ✗ (Origin tidak terlihat)
```

### 3.2. Struktur Domain

Platform menggunakan subdomain dengan prefiks acak (`[random].platform.com`), yang membuatnya tidak terdeteksi melalui pencarian domain umum. Shodan membutuhkan query spesifik dengan domain lengkap untuk menemukan host — tanpa pengetahuan tentang struktur domain, scanning tidak efektif.

### 3.3. Port Filtering

Hanya port 443 (HTTPS) yang terbuka. Seluruh port lain difilter, sehingga scanning port massal yang dilakukan Shodan hanya menemukan port standar tanpa informasi layanan yang berarti.

### 3.4. WAF Layer

Cloudflare WAF secara aktif memblokir probe scanner sebelum mencapai origin server. Probe yang mencurigakan (seperti user-agent scanner, request pattern anomali) di-drop di edge.

### Implikasi untuk WAF Development

| Protected From | NOT Protected From |
|----------------|-------------------|
| Internet-scale scanning (Shodan, Censys) | Targeted attack yang tahu origin IP |
| Port scanning massal | Historical DNS records |
| Automated vulnerability scanner | Certificate transparency logs |
| Random reconnaissance | Social engineering / insider threat |

**Kesimpulan:** WAF + reverse proxy effectif untuk pencegahan scanning massal, tetapi tidak cukup untuk menutup seluruh vektor kebocoran origin IP. Diperlukan pendekatan tambahan — yang disebut dengan **server encapsulation**.

---

## 4. Duplikasi Temuan — Realita Bug Bounty

Dari beberapa temuan yang dilaporkan, sejumlah di antaranya merupakan **duplikat** dari tim lain. Ini adalah fenomena umum dalam bug bounty — dikenal sebagai parallel discovery.

### 4.1. Mengapa Duplikasi Terjadi?

Semua tim peserta memulai pengujian dari sumber yang sama: JavaScript bundle SPA. Proses yang identik menghasilkan endpoint mapping yang serupa:

```
JS Bundle Analysis → Endpoint Mapping → Testing → Findings
       ↑                      ↑              ↑
    Semua tim            Endpoint sama    Temuan overlap
```

### 4.2. Akar Masalah

| Faktor | Dampak |
|--------|--------|
| **Surface area terbatas** | Semua tim menguji target yang sama |
| **Methodologi seragam** | JS bundle analysis adalah langkah pertama |
| **First come, first served** | Tim yang lebih cepat mapping endpoint memiliki keuntungan |
| **Validasi tidak tuntas** | Beberapa temuan belum fully exploited — perlu chain exploit penuh untuk validasi |

### 4.3. Lessons Learned

1. **Kecepatan reconnaissance** sangat menentukan — endpoint mapping harus dilakukan secepat mungkin
2. **Validasi exploit chain** diperlukan sebelum report — temuan yang hanya setengah jalan rentan dianggap invalid
3. **Dokumentasi real-time** membantu tracking mana endpoint yang sudah di-test dan mana yang belum
4. **Komunikasi tim** penting untuk menghindari overlap internal

---

## 5. Konsep Server Encapsulation

Server encapsulation adalah visi arsitektur WAF di mana server backend sepenuhnya **terenkapsulasi** — tidak ada rute langsung dari internet ke server, dan origin server tidak dapat diidentifikasi melalui teknik reconnaissance apapun.

### 5.1. Arsitektur Saat Ini VS Target

**Lapisan Saat Ini:**
```
[Internet] → [WAF/Proxy] → [Origin Server]
                    ↑
           Origin dapat dilacak melalui:
           - DNS history (SecurityTrails, VirusTotal)
           - Certificate Transparency (crt.sh)
           - SSH key fingerprint scanning
           - Reverse IP lookup
```

**Target Encapsulation:**
```
[Internet] → [WAF/Proxy] ══> [Origin Server]
                    ↑
           Tidak ada rute langsung ke origin.
           Origin hanya dikenal oleh WAF.
           Semua vektor kebocoran ditutup.
```

### 5.2. Vektor Kebocoran Origin IP

| Vektor | Tingkat Kesulitan | Mitigasi |
|--------|:-----------------:|----------|
| DNS Historical (SecurityTrails) | Sangat mudah | Gunakan IP acak yang berubah secara periodik |
| Certificate Transparency (crt.sh) | Sangat mudah | Wildcard cert + rotasi |
| SSH Key Fingerprint (Shodan) | Mudah | Non-standar port + jump box |
| Reverse DNS | Mudah | Konfigurasi PTR yang tidak terkait |
| Email Header Analysis | Sedang | Jangan gunakan origin IP untuk pengiriman email |
| Side-channel (timing, error message) | Sulit | Uniform error response |
| Social Engineering ISP | Sangat sulit | Di luar kendali teknis |

### 5.3. Komponen yang Dibutuhkan

| Komponen | Status | Prioritas |
|----------|:------:|:---------:|
| L7 WAF rule engine | ✅ Production | P0 |
| L4 reverse proxy (Pingora) | ✅ Production | P0 |
| Anomaly scoring + behavioral | 🟡 Development | P1 |
| eBPF/XDP packet filtering | 🟡 Experimental | P2 |
| Origin IP rotation | ❌ Belum | P3 |
| DNS history protection | ❌ Belum | P3 |
| Full encapsulation | ❌ Konsep | P4 |

---

## 6. Roadmap Implementasi

### Jangka Pendek (P0-P1): Memperkuat Rule Engine

- Menambah coverage rules untuk SQLi, XSS, LFI, dan DLP
- Mengembangkan anomaly scoring engine berbasis behavioral analysis
- Mengurangi false positive rate melalui fine-tuning rule parameter

### Jangka Menengah (P2): Memperluas Layer Proteksi

- Membawa eBPF/XDP ke production — packet filtering pada kernel level
- Implementasi IP reputation engine dengan multi-feed (AbuseIPDB, IPQS)
- TLS fingerprint detection (JA3)

### Jangka Panjang (P3-P4): Server Encapsulation

- Origin IP rotation — alamat origin berubah secara periodik
- DNS history protection — pastikan tidak ada historical record yang membocorkan IP
- Wireless attack surface mitigation — menangani skenario di mana attacker berada pada jaringan yang sama

---

## 7. Referensi

### Terkait Shodan & Reconnaissance

1. Shodan Search Engine — https://www.shodan.io/
2. Censys Search — https://search.censys.io/
3. SecurityTrails DNS History — https://securitytrails.com/
4. crt.sh Certificate Search — https://crt.sh/

### Terkait WAF & Server Protection

5. Cloudflare WAF Documentation — https://developers.cloudflare.com/waf/
6. OWASP Coraza WAF — https://coraza.io/
7. ModSecurity Reference — https://github.com/owasp-modsecurity/ModSecurity
8. Pingora — https://github.com/cloudflare/pingora

### Terkait Bug Bounty Methodology

9. Bugcrowd Methodology — https://www.bugcrowd.com/bug-bounty-hackers/
10. HackerOne CTF — https://ctf.hacker101.com/

### Vault Cross-Reference

| Catatan | Koneksi |
|---------|---------|
| [[waf-reverse-proxy-deepdive]] | Arsitektur WAF — posisi encapsulation di reverse proxy layer |
| [[hierarchy-search]] | Information access hierarchy — Shodan ada di level OSINT |
| [[browser-security-exploitation-deepdive]] | JS bundle analysis sebagai teknik recon |
| [[server-hardening-playbook]] | Hardening server — hubungannya dengan mengurangi attack surface |
