---
title: 'TLS/SSL — Deep Dive: Handshake, Cipher Suites, Certificate Chain, Attacks
  & Detection'
tags:
- fundamentals
- networking
- tls
- ssl
- library
created: '2026-07-16'
updated: '2026-07-16'
status: pending
cssclasses:
---

# 🔒 TLS/SSL — Deep Dive: Handshake, Cipher Suites, Certificate Chain, Attacks & Detection

> Catatan ini adalah panduan komprehensif Transport Layer Security — dari sejarah SSL sampai TLS 1.3. Mencakup handshake step-by-step (TLS 1.2 vs 1.3), cipher suite anatomy, Certificate Authority hierarchy & chain validation, key exchange (RSA vs DH vs ECDHE), forward secrecy, session resumption, TLS fingerprinting (JA3/JA3S), TLS in HTTP/2 and HTTP/3, downgrade attacks (BEAST, CRIME, POODLE, ROBOT), dan practical detection of malicious TLS (C2 beaconing, encrypted traffic analysis). TLS adalah **perimeter baru** setelah network perimeter hilang.

> [!info] Posisi di Vault
> Catatan ini terkait dengan [[http-protocol-deepdive]] (HTTPS = HTTP + TLS), [[cryptography-biometrics]] (crypto primitives yang dipake TLS), [[networking-fundamentals-tcpip-bgp]] (TCP handshake yang terjadi sebelum TLS), [[waf-reverse-proxy-deepdive]] (TLS termination di reverse proxy), [[container-kubernetes-security-deepdive]] (mTLS di service mesh), [[cloudflare-ruleset-engine-phases]] (TLS inspection), [[cobalt-strike]] dan [[sliver]] (C2 HTTPS profiles, JA3 evasion), dan [[comprehensive-threat-directory]] (TLS attack taxonomy).

---

## Daftar Isi

- [[#Foundation]]
- [[#X.509 Certificate Chain]]
- [[#Cipher Suite Anatomy]]
- [[#TLS Handshake — Step by Step]]
- [[#TLS 1.3 — Simplified]]
- [[#Session Resumption]]
- [[#TLS in HTTP/2 & HTTP/3]]
- [[#TLS Fingerprinting — JA3 JA3S]]
- [[#TLS Attack Surface]]
- [[#Practical Detection of Malicious TLS]]
- [[#Hardening Checklist]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Timeline SSL → TLS

| Versi | Tahun | Status | Masalah |
|-------|-------|--------|---------|
| **SSL 1.0** | 1994 (Netscape) | 🔴 Tidak pernah rilis | Bugs parah |
| **SSL 2.0** | 1995 | 🔴 Deprecated (RFC 6176) | Multiple security flaws: same key for auth+encryption, MD5, weak MAC |
| **SSL 3.0** | 1996 | 🔴 Deprecated (RFC 7568) | POODLE attack (CVE-2014-3566) |
| **TLS 1.0** | 1999 (RFC 2246) | 🔴 Deprecated | BEAST (CVE-2011-3389), Lucky13 |
| **TLS 1.1** | 2006 (RFC 4346) | 🔴 Deprecated | CBC timing attacks |
| **TLS 1.2** | 2008 (RFC 5246) | 🟡 Masih dipake | Masih aman dengan konfigurasi benar (AES-GCM, ECDHE) |
| **TLS 1.3** | 2018 (RFC 8446) | 🟢 Recommended | Forward secrecy wajib, 1-RTT handshake, hapus cipher lemah |

### Kenapa TLS Bukan SSL?

SSL adalah nama lama (Netscape). Setelah diadopsi IETF, namanya diubah jadi TLS (Transport Layer Security). Tapi masyarakat umum masih nyebut "SSL" — makanya sertifikat disebut "SSL certificate" padahal sebenarnya TLS.

### What TLS Does (dan Tidak)

| Lapisan | Dilindungi TLS? | Catatan |
|---------|----------------|---------|
| **URI/Path** | ❌ Tidak | Hanya hostname yang di-enkripsi (SNI sebelumnya bocor, sekarang ECH/ESNI) |
| **Query Parameters** | ✅ Ya | Semua data HTTP body dan query di-enkripsi setelah TLS handshake |
| **Headers** | ✅ Ya | Setelah TLS handshake selesai, HTTP headers ter-enkripsi |
| **Server Certificate** | 🟡 Sebagian | Sertifikat server ter-enkripsi di TLS 1.3, bocor di TLS 1.2 |
| **Server IP** | ❌ Tidak | IP tujuan selalu kelihatan (harus pakai VPN/Tor) |
| **SNI (Server Name Indication)** | 🟡 Sebagian | ECH (Encrypted Client Hello) baru mulai diadopsi — sebelum itu SNI plaintext |
| **Traffic Length** | ❌ Tidak | Ukuran packet bocor — bisa dipakai traffic analysis (site fingerprinting) |
| **DNS Query** | ❌ Tidak | DNS biasanya plaintext (kecuali DNS over HTTPS/TLS) |

---

## X.509 Certificate Chain

### Hierarki Kepercayaan

```
┌──────────────────────────────┐
│      Root CA (Self-Signed)   │ ← Root store: ~150 CA di browser/OS
│   "ISRG Root X1"             │   Private key: offline, penyimpanan super aman
└──────────────┬───────────────┘
               │ Signed by Root CA
┌──────────────▼───────────────┐
│   Intermediate CA            │ ← Bisa beberapa level
│   "R3" (Let's Encrypt)       │   Private key: online, rotasi teratur
└──────────────┬───────────────┘
               │ Signed by Intermediate CA
┌──────────────▼───────────────┐
│   Leaf / End-Entity Cert     │ ← Yang dipasang di server
│   "*.example.com"            │   Private key: di server web
└──────────────────────────────┘
```

**Kenapa pake intermediate, bukan langsung dari Root?**
- Root CA private key disimpan offline (air-gapped) — jarang dipake
- Intermediate bisa di-revoke tanpa revoke Root
- Kalo intermediate compromised, Root masih aman — bisa revoke intermediate dan terbitkan baru

### Certificate Fields

| Field | Contoh | Fungsi |
|-------|--------|--------|
| **Subject** | `CN=*.example.com, O=Example Corp, C=US` | Identitas pemilik sertifikat |
| **Subject Alternative Names (SAN)** | `DNS:example.com, DNS:*.example.com` | **Domain yang dilindungi** — modern browser cuma lihat SAN, gak lihat CN |
| **Issuer** | `CN=R3, O=Let's Encrypt` | CA yang nerbitin |
| **Validity** | `Not Before: Jul 15 2026, Not After: Oct 15 2026` | Masa berlaku — 90 hari untuk Let's Encrypt (Auto Renew) |
| **Public Key** | `RSA 2048-bit` atau `ECDSA P-256` | Kunci publik milik server |
| **Signature Algorithm** | `sha256WithRSAEncryption` | Algoritma yang dipake CA untuk sign cert |
| **Key Usage** | `Digital Signature, Key Encipherment` | Cara kunci boleh dipake |
| **Extended Key Usage** | `TLS Web Server Authentication` | Konteks penggunaan |
| **CRL Distribution Points** | `http://crl.example.com/root.crl` | Lokasi daftar sertifikat yang di-revoke |
| **OCSP Responder** | `http://ocsp.example.com` | Endpoint pengecekan status real-time |
| **Fingerprint (SHA-256)** | `a1:b2:c3:...` | Hash sertifikat — identifier unik |

### Chain Validation

Browser saat connect ke `https://example.com`:

```
1. Server kirim: Leaf Cert + Intermediate Cert(s) (tapi gak kirim Root)
2. Browser:
   a. Verifikasi signature Leaf ← Intermediate
   b. Verifikasi signature Intermediate ← Root (Root ada di trust store browser)
   c. Cek validity period (belum expired)
   d. Cek hostname (SAN cocok dengan domain yang dikunjungi)
   e. Cek revocation status (CRL atau OCSP)
   f. Cek Key Usage / Extended Key Usage
3. Kalau semua lolos → 🔒 padlock hijau
```

### Certificate Validation Failures

| Error | Arti | Penyebab Umum |
|-------|------|---------------|
| **Self-signed cert** | Certificate Authority gak dikenal | Dev server, internal tools |
| **Hostname mismatch** | SAN gak cocok dengan domain di URL | Wildcard gak cover subdomain, cert buat server beda |
| **Expired cert** | Melewati Not After | Gak renew tepat waktu |
| **Revoked cert** | CA udah revoke | Private key compromised, domain ganti |
| **Incomplete chain** | Intermediate gak dikirim server | Server config salah |
| **Unknown issuer** | Root gak ada di trust store | Root CA baru, atau fake cert |

### Let's Encrypt & ACME Protocol

**Apa:** CA gratis yang otomatis nerbitin sertifikat via ACME protocol. 90 hari validity — auto-renewal.

```
1. Install certbot / acme.sh
2. Domain validation: HTTP-01 (file di /.well-known/acme-challenge/) atau DNS-01 (TXT record)
3. ACME server terbitkan cert + private key
4. Auto-renew: cron/systemd timer check tiap 60 hari
```

**Kenapa 90 hari?** Biar dampak kompromi terbatas. Kalo compromised, maksimal 90 hari dipake — bukan 2 tahun.

---

## Cipher Suite Anatomy

Cipher suite adalah kombinasi algoritma yang disepakati client & server untuk satu koneksi TLS.

### Format TLS 1.2

```
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
└──┘ └──┘ └──┘ └───┘ └─┘ └────┘
 1    2     3      4     5     6
```

| Komponen | Contoh | Fungsi | Opsi Umum |
|----------|--------|--------|-----------|
| **1. Protokol** | `TLS` | Protocol | TLS |
| **2. Key Exchange** | `ECDHE` | Pertukaran kunci — cara client & server sepakat session key | RSA, DH, DHE, ECDHE, PSK |
| **3. Authentication** | `RSA` | Autentikasi server — verifikasi identitas via cert | RSA, ECDSA, DSS |
| **4. Encryption** | `AES_128_GCM` | Enkripsi data setelah handshake | AES-GCM, AES-CBC, ChaCha20 |
| **5. MAC/Hash** | `SHA256` | Integrity check — verifikasi data gak diubah | SHA, SHA256, SHA384, Poly1305 |
| **6. Key Exchange** (opsional) | — | Beberapa format include `_` untuk variasi | — |

### TLS 1.3 — Simplified

TLS 1.3 hapus banyak opsi:

```
TLS_AES_128_GCM_SHA256
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
```

Hanya 5 cipher suite yang diizinkan — semuanya pake AEAD + HKDF. Gak ada RSA key exchange (gak ada forward secrecy tanpa), gak ada CBC mode, gak ada RC4.

### Forward Secrecy

**Konsep:** Kalo private key server bocor, session key koneksi **masa lalu** tetap aman.

**Cara kerja:** Session key diturunkan dari **ephemeral** key exchange (DHE atau ECDHE), bukan dari RSA private key. RSA key exchange: session key di-enkripsi dengan private key → kalo private key bocor, semua session masa lalu bisa di-dekripsi. ECDHE: tiap session pake temporary key baru, dihapus setelah session selesai.

**Status:** TLS 1.3 **mewajibkan** forward secrecy. TLS 1.2 dengan cipher ECDHE juga aman. Cipher RSA key exchange harus di-disable.

### AEAD — Authenticated Encryption with Associated Data

Kombinasi enkripsi + integrity check dalam satu operasi. Cegah padding oracle attack (CBC mode rentan). Contoh: AES-GCM, ChaCha20-Poly1305.

---

## TLS Handshake — Step by Step

### TLS 1.2 Full Handshake (2 RTT)

```
Client (browser)                               Server (nginx)
      │                                              │
      │────── 1. ClientHello ───────────────────────→│
      │    TLS version, cipher suites,               │
      │    random bytes, session ID                  │
      │                                              │
      │←──── 2. ServerHello ─────────────────────────│
      │    Chosen version, cipher suite,             │
      │    random bytes, session ID                  │
      │                                              │
      │←──── 3. Certificate ─────────────────────────│
      │    Server cert chain                         │
      │                                              │
      │←──── 4. ServerKeyExchange ───────────────────│
      │    ECDHE params (pubkey, signature)          │
      │                                              │
      │←──── 5. ServerHelloDone ─────────────────────│
      │    "Udah, giliran lo"                        │
      │                                              │
      │────── 6. ClientKeyExchange ─────────────────→│
      │    ECDHE client pubkey                       │
      │    → Kedua pihak compute shared secret       │
      │    → Turunkan session key                    │
      │                                              │
      │────── 7. ChangeCipherSpec ──────────────────→│
      │    "Mulai enkripsi"                          │
      │                                              │
      │────── 8. Finished (encrypted) ──────────────→│
      │    MAC of all handshake messages             │
      │                                              │
      │←──── 9. ChangeCipherSpec ────────────────────│
      │←──── 10. Finished (encrypted) ───────────────│
      │    Server verify handshake integrity         │
      │                                              │
      │←══════════════ Data (encrypted) ═════════════→│
```

**Total:** 2 RTT setelah TCP handshake (yang 1 RTT). Jadi HTTPS = TCP (1 RTT) + TLS 1.2 (2 RTT) = 3 RTT sebelum byte data pertama.

### Detail Message

**ClientHello:**
```yaml
Version: TLS 1.2 (0x0303)
Random: 32-byte random (client_random)
Session ID: (untuk resumption)
Cipher Suites: [TLS_AES_128_GCM_SHA256, TLS_CHACHA20_POLY1305, ...]
Compression: [null]  # null-satu-satunya yang aman
Extensions:
  - SNI: "example.com"
  - ALPN: ["h2", "http/1.1"]
  - Supported Groups: [x25519, secp256r1, secp384r1]  # ECDHE curves
  - Signature Algorithms: [rsa_pss_rsae_sha256, ecdsa_secp256r1_sha256]
  - Key Share (TLS 1.3): ...
```

**ServerHello:**
```yaml
Version: TLS 1.2
Random: 32-byte (server_random)
Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
Extensions:
  - ALPN: "h2"
```

### Key Generation

```
Pre-Master Secret = ECDHE(client_private, server_public)  # shared secret
                           ↓
Master Secret = PRF(Pre-Master Secret + client_random + server_random)
                           ↓
Session Key = PRF(Master Secret + "key expansion" + ...)
    ├── Client Write Key (encrypt data from client → server)
    ├── Server Write Key (encrypt data from server → client)
    ├── Client Write IV
    └── Server Write IV
```

**Kenapa random client & server ikut?** Biar kalo dua koneksi beda pake pre-master secret yang sama (sangat kecil kemungkinannya) tetap menghasilkan session key yang beda.

---

## TLS 1.3 — Simplified

### TLS 1.3 Handshake (1 RTT)

```
Client                                          Server
  │                                                  │
  │────── ClientHello ──────────────────────────────→│
  │    Key Share (ECDHE pubkey langsung!)             │
  │    Supported versions: [1.3, 1.2]                │
  │    Cipher suites: [TLS_AES_128_GCM_SHA256, ...]  │
  │                                                  │
  │←──── ServerHello ────────────────────────────────│
  │    Key Share (ECDHE pubkey)                      │
  │    → Kedua pihak compute shared secret           │
  │    → Turunkan handshake traffic key              │
  │                                                  │
  │←──── EncryptedExtensions ────────────────────────│
  │←──── Certificate (encrypted!) ───────────────────│
  │←──── CertificateVerify (encrypted!) ─────────────│
  │←──── Finished (encrypted!) ──────────────────────│
  │                                                  │
  │────── Finished (encrypted!) ────────────────────→│
  │                                                  │
  │←══════════════════ Data ═════════════════════════→│
```

**Perbedaan utama TLS 1.2 vs 1.3:**

| Aspek | TLS 1.2 | TLS 1.3 |
|-------|---------|---------|
| **Handshake RTT** | 2 RTT (full) | 1 RTT (full), 0-RTT (resumption) |
| **Certificate delivery** | Plaintext (bocor) | Encrypted |
| **Forward secrecy** | Opsional | ✅ **Wajib** |
| **Cipher suites** | 37+ kombinasi | 5 AEAD-only |
| **Key exchange** | RSA, DH, DHE, ECDHE | ECDHE, (EC)DHE only |
| **Algorithm negotiation** | ClientHello → ServerHello (sequential) | ClientHello → ServerHello + KeyShare (parallel) |
| **Session resumption** | Session ID, Session Ticket | PSK (Pre-Shared Key) |
| **Compression** | Ada (risk) | ❌ Dihapus |
| **Renegotiation** | Ada (risk) | ❌ Dihapus |
| **ChangeCipherSpec** | Explicit message | Implicit (hapus dari spec) |

### 0-RTT (Early Data)

Dengan TLS 1.3 + PSK (resumption), client bisa langsung kirim data di ClientHello **sebelum handshake selesai**:

```
Client (pernah connect sebelumnya)            Server
      │                                              │
      │────── ClientHello + PSK + Early Data ───────→│
      │    Data HTTP request LANGSUNG!                 │
      │                                              │
      │←──── ServerHello + Finished ─────────────────│
      │←──── Response (encrypted) ───────────────────│
```

**⚠️ Risiko 0-RTT:**
- **Replay attack** — attacker bisa intercept dan kirim ulang early data yang sama. Server harus implement replay protection (key idempotent request seperti GET, atau nonce).
- **Forward secrecy** — data 0-RTT dienkripsi dengan PSK, bukan ephemeral key. Kalo PSK bocor, data 0-RTT bisa di-dekripsi.

---

## Session Resumption

Biar gak perlu full handshake setiap kali:

### Session ID (TLS 1.2, stateful)

```
1. Handshake pertama: Server simpan session di memory, kirim Session ID
2. Handshake kedua: Client kirim Session ID → server cek memory → kalo cocok, pake session key lama
3. Server harus simpan session → masalah di load balancer (harus session store shared)
```

### Session Ticket (TLS 1.2, stateless)

```
1. Server kirim Session Ticket (encrypted blob — session key di-enkripsi server key)
2. Client simpan ticket
3. Handshake berikutnya: client kirim ticket → server decrypt → dapet session key
4. Lebih scalable (gak perlu shared store)
```

### PSK (TLS 1.3)

Evolusi dari session ticket. Client kirim PSK identity, server match, langsung 1-RTT atau 0-RTT.

---

## TLS in HTTP/2 & HTTP/3

### HTTP/2 + TLS

HTTP/2 **tidak mewajibkan** TLS secara spesifik (spec bilang "encryption optional"), tapi semua browser cuma implement HTTP/2 over TLS — jadi praktisnya HTTP/2 = HTTPS.

**ALPN (Application-Layer Protocol Negotiation):**
```
ClientHello: ALPN = ["h2", "http/1.1"]
ServerHello: ALPN = "h2"  → client & server pake HTTP/2
```

### HTTP/3 + QUIC

HTTP/3 = HTTP over QUIC. QUIC menggabungkan **TLS 1.3 built-in** — bukan layer terpisah:

```
┌──────────────────────┐
│      HTTP/3          │
├──────────────────────┤
│     QUIC Transport   │
│  ├── TLS 1.3 ────────┤  ← Built-in, bukan layer terpisah
│  └── UDP ────────────┤
├──────────────────────┤
│         UDP          │
└──────────────────────┘
```

---

## TLS Fingerprinting — JA3 JA3S

### Konsep

Setiap client TLS (browser, curl, Go net/http, Python requests, Cobalt Strike beacon) mengirim ClientHello dengan **kombinasi unik** dari:
- TLS version yang didukung
- Cipher suites (urutan)
- Extensions (tipe + urutan)
- Supported curves
- Elliptic curve formats
- Signature algorithms

Kombinasi ini → hash → **JA3 fingerprint**.

### Cara Kerja

```yaml
ClientHello dari Chrome 130:
  Version: 0x0303 (TLS 1.2)
  Cipher Suites: [0x1301, 0x1302, 0x1303, 0xc02b, 0xc02f, ...]  # 17 suites
  Extensions: [0x0000, 0x001b, 0x002d, 0x0033, 0x4469, ...]  # 10 extensions
  Supported Groups: [0x001d, 0x0017, 0x0018]
  → JA3 = "771,4865-4866-4867-49195-49199-...-52392,0-11-...-65281,29-23-24,0"
  → MD5 = efebb8252f524b7c4a2d6e7c1a4e8f2a
```

### Penggunaan Security

| Use Case | Cara |
|----------|------|
| **C2 detection** | Cobalt Strike HTTPS beacon punya JA3 signature yang dikenal (51c64c77f60c4b6b...). Block JA3 = block C2 |
| **Malware detection** | Malware pake library TLS sendiri → JA3 unik yang gak cocok browser normal |
| **Impersonation detection** | Attacker pake curl dengan user-agent "Chrome" tapi JA3 curl beda sama JA3 Chrome asli |
| **Bot detection** | Bot/scraper punya JA3 beda dari browser real |

**Keterbatasan:** 
- JA3 bisa diubah dengan memodifikasi TLS library (Cobalt Strike sudah support JA3 randomization sejak v4.7)
- JA3 yang sama dari dua tools berbeda bisa terjadi collision
- Private library bisa generate JA3 baru yang belum dikenal

### Implementation

```bash
# Capture JA3 dari pcap
# Di Suricata:
ja3-fingerprints: yes
# Di zeek:
@load protocols/ssl/ja3

# Custom detection command:
tshark -r capture.pcap -Y "tls.handshake.type == 1" -T fields \
  -e tls.handshake.ja3 -e tls.handshake.ja3s
```

---

## TLS Attack Surface

### Downgrade Attacks

| Attack | Target | Cara Kerja | TLS 1.3 Mitigasi? |
|--------|--------|-----------|-------------------|
| **POODLE** (SSL 3.0) | CBC mode | Exploit padding oracle di SSL 3.0 | ✅ (SSL 3.0 dihapus) |
| **BEAST** (TLS 1.0) | CBC mode | Predict IV via block chaining | ✅ (AEAD-only) |
| **CRIME** | Compression | Inject known plaintext → ukur perubahan ukuran kompresi | ✅ (kompresi dihapus) |
| **Lucky13** | CBC mode | Timing oracle dari CBC padding | ✅ (AEAD-only) |
| **Logjam** | DHE export | Force DHE ke export-grade (512-bit) | ✅ (export cipher dihapus) |
| **FREAK** | RSA export | Force RSA ke export-grade (512-bit) | ✅ (export cipher dihapus) |
| **ROBOT** | RSA key exchange | Return of Bleichenbacher oracle (CVE-2017-17305) | ✅ (RSA key exchange dihapus) |
| **Downgrade to TLS 1.2** | Protocol version | Forced downgrade via network MITM | 🟡 Sebagian (downgrade protection SCSV) |

**Mitigasi utama:** Nonaktifkan semua protokol sebelum TLS 1.2, pake cipher AEAD-only, disable compression, disable renegotiation (client-side renego).

### Certificate Attacks

| Attack | Cara | Mitigasi |
|--------|------|----------|
| **MITM dengan fake CA** | Install fake Root CA di device korban | Certificate Pinning, CRL, OCSP |
| **Certificate Spoofing** | Compromise CA → terbitkan cert palsu | Certificate Transparency (CT logs) — deteksi cert aneh |
| **OCSP Bypass** | Block OCSP responder → browser gak bisa cek status | OCSP Stapling (server yang ngasih timestamped OCSP response) |
| **Revoked cert masih dipake** | Browser offline → gak bisa OCSP | CRLSet (Chrome), OneCRL (Firefox) — distributed CRL |

### TLS Renegotiation Attack

Attacker inject plaintext di tengah session TLS — server kira itu bagian dari autentikasi client. Ditemukan 2009. TLS 1.3 sudah hapus renegotiation.

### Protocol Downgrade via SNI

Sebelum ECH (Encrypted Client Hello), SNI dikirim **plaintext** — attacker bisa lihat domain mana yang dikunjungi, bahkan di HTTPS. ECH fix ini dengan mengenkripsi seluruh ClientHello.

---

## Practical Detection of Malicious TLS

### Indicators of Malicious TLS

| Indicator | Kemungkinan | Detection |
|-----------|-------------|-----------|
| **JA3 tidak dikenal** | Custom TLS stack (malware, C2) | JA3 blocklist / allowlist (browser-only) |
| **Cipher suite tidak wajar** | Malware pake cipher tua (RC4, CBC) karena library lawas | Suricata: `tls.ciphers` rule |
| **TLS version tua** | Malware pake OpenSSL lama → TLS 1.0/1.1 | Log `tls.version` |
| **Self-signed cert** | C2 server pake self-signed | Alert `tls.certificate.self_signed` |
| **Certificate mismatch** | C2 domain gak cocok sama CN/SAN | Suricata: `tls.certificate.issuer` |
| **Unusual cert issuer** | C2 pake cert dari CA gak dikenal | Threat intel feed |
| **Beacon interval + TLS** | Koneksi TLS periodik ke IP asing | Zeek conn.log + time pattern |
| **TLS handshake ke IP (bukan domain)** | C2 langsung ke IP tanpa SNI | Suricata: `tls.sni` kosong |
| **Large cert** | Custom CA yang generate cert gede >2KB | `tls.certificate.length` |
| **No ALPN** | C2 gak negotiate HTTP/2 — langsung | `tls.alpn` kosong |

### Detection Tool

```bash
# Zeek — TLS logging
# conn.log: waktu, IP, port, bytes
# ssl.log: JA3, cipher, version, certificate chain, ALPN, SNI

# Query TLS ke IP tanpa SNI
cat ssl.log | zeek-cut ts server_name server_ip cipher | awk '$2 == "-"'

# Deteksi JA3 mencurigakan
cat ssl.log | zeek-cut ja3 | sort | uniq -c | sort -rn | head

# Python detection script
python3 << 'EOF'
import json
# Cek beacon interval: koneksi TLS periodik?
# Logika: group by IP, hitung interval rata-rata
# Kalo std dev rendah + interval tetap = beacon
EOF
```

### Suricata Rule — Deteksi C2 TLS

```yaml
alert tls $HOME_NET any -> $EXTERNAL_NET any (
    msg:"ET MALWARE Possible C2 - TLS to IP without SNI";
    flow:established,to_server;
    tls.sni; content:"|00|"; distance:0; within:1;
    tls.version; content:"|03 03|";  # TLS 1.2 minimum
    reference:url,attack.mitre.org/techniques/T1573/001;
    classtype:trojan-activity;
    sid:1000001; rev:1;
)
```

---

## Hardening Checklist

```
☐ TLS 1.2 minimum — disable TLS 1.0, TLS 1.1, SSL 3.0, SSL 2.0
☐ Cipher AEAD-only: TLS_AES_128_GCM_SHA256, TLS_CHACHA20_POLY1305_SHA256
☐ Forward secrecy wajib — disable RSA key exchange
☐ Disable compression (CRIME)
☐ Disable client-side renegotiation
☐ HPKP deprecated — jangan pake
☐ HSTS: max-age=31536000; includeSubDomains; preload
☐ OCSP Stapling: aktifkan dan monitor
☐ Certificate Transparency: pastiin cert terdaftar di CT logs
☐ Private key: 2048-bit RSA minimum, prefer ECDSA P-256
☐ ED25519 untuk SSH — bukan TLS (tapi good practice)
☐ ECH (Encrypted Client Hello): aktifkan kalo tersedia
☐ TLS 1.3 preferred — optimalkan konfigurasi untuk 1-RTT/0-RTT
☐ Monitor JA3 — detect unusual TLS fingerprint
☐ Automatic renewal: Let's Encrypt (90 hari) — prevent expired cert
☐ Revocation: pastiin OCSP responder reachable, fallback ke CRL
```

### OpenSSL Config Example

```nginx
# nginx TLS config — strong, modern
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;  # Client pilih (modern — sesuai rekomendasi Mozilla)
ssl_ecdh_curve X25519:secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
```

---

## Koneksi ke Vault

- [[http-protocol-deepdive]] — HTTPS = HTTP + TLS, baca ini dulu untuk paham layer di atas TLS
- [[cryptography-biometrics]] — crypto primitives (AES, ECDHE, SHA) yang TLS pake
- [[networking-fundamentals-tcpip-bgp]] — TCP handshake yang terjadi SEBELUM TLS handshake
- [[waf-reverse-proxy-deepdive]] — TLS termination di reverse proxy (nginx, Cloudflare)
- [[container-kubernetes-security-deepdive]] — mTLS Istio, service mesh TLS
- [[cloudflare-ruleset-engine-phases]] — TLS fingerprinting di Cloudflare, ECH/ESNI
- [[cobalt-strike]] dan [[sliver]] — C2 HTTPS beacon dengan JA3 evasion, custom TLS stack
- [[api-security-deep-dive]] — API authentication via mTLS dan OAuth2 over TLS
- [[comprehensive-threat-directory]] — taksonomi ancaman berbasis TLS
- [[zero-trust-security]] — TLS sebagai fondasi zero trust (mTLS everywhere)

---

## References

1. IETF. *RFC 8446: The Transport Layer Security (TLS) Protocol Version 1.3*. 2018. https://datatracker.ietf.org/doc/rfc8446/
2. IETF. *RFC 5246: The Transport Layer Security (TLS) Protocol Version 1.2*. 2008.
3. IETF. *RFC 6066: TLS Extensions (SNI, ALPN, etc)*. 2011.
4. IETF. *RFC 7301: ALPN*. 2014.
5. IETF. *RFC 8879: TLS Certificate Compression*. 2021.
6. Mozilla. *Security/Server Side TLS*. https://wiki.mozilla.org/Security/Server_Side_TLS
7. Mozilla. *SSL Configuration Generator*. https://ssl-config.mozilla.org/
8. Qualys SSL Labs. *SSL Server Test*. https://www.ssllabs.com/ssltest/
9. Qualys SSL Labs. *SSL/TLS Deployment Best Practices*. https://github.com/ssllabs/research/wiki/SSL-and-TLS-Deployment-Best-Practices
10. Cloudflare. *TLS 1.3 Overview*. https://www.cloudflare.com/learning-resources/tls-1-3/
11. Cloudflare. *What is SNI?* https://www.cloudflare.com/learning/ssl/what-is-sni/
12. Cloudflare. *ECH — Encrypted Client Hello*. https://blog.cloudflare.com/encrypted-client-hello/
13. Let's Encrypt. *ACME Protocol*. https://letsencrypt.org/docs/acme-protocol/
14. Certificate Transparency. *RFC 6962*. https://certificate.transparency.dev/
15. JA3. *JA3 Fingerprinting*. https://github.com/salesforce/ja3
16. Suricata. *TLS/SSL Detection Rules*. https://suricata.readthedocs.io/en/latest/rules/tls-keywords.html
17. Zeek. *SSL/TLS Logging*. https://docs.zeek.org/en/current/scripts/base/protocols/ssl/main.zeek.html
18. Cipherli.st. *Strong Ciphers for Apache, nginx, etc*. https://cipherli.st/
19. OpenSSL. *OpenSSL Documentation*. https://www.openssl.org/docs/
20. BoringSSL. *BoringSSL Documentation*. https://boringssl.googlesource.com/boringssl/
21. Google. *TLS 1.3 0-RTT Replay Attack*. https://www.rfc-editor.org/rfc/rfc9001.html
22. sslLabs. *SSL/TLS Attack History*. https://github.com/ssllabs/research/wiki/SSL-and-TLS-Attacks

> [!tip] Bottom Line
> TLS adalah **fondasi keamanan transport modern** — tapi bukan solusi ajaib. TLS mengamankan isi percakapan, tapi metadata (IP, panjang packet, timing) tetap bocor. Buat security engineer: (1) **Cipher suite pilih AEAD + ECDHE** — jangan sentuh CBC, jangan sentuh RSA key exchange. (2) **TLS 1.3 wajib** — lebih cepat, lebih aman, lebih sederhana. (3) **JA3 fingerprinting** adalah alat deteksi C2 yang powerful tapi harus dipahami keterbatasannya — attacker bisa JA3 randomization. (4) **Certificate Transparency** mengubah sertifikat dari "trust based on secrecy" menjadi "trust based on transparency" — setiap cert yang diterbitkan untuk domain lo tanpa sepengetahuan lo = indikasi compromise. (5) **Forward secrecy** mengubah dampak private key leakage dari "semua masa lalu terbaca" jadi "hanya masa depan" — ini bukan opsi, ini wajib.
