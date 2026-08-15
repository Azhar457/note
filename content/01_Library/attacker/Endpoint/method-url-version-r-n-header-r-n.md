---
title: HTTP Request Anatomy (Method URL Version Header)
tags: [security, web, http]
aliases: [method-url-version-r-n-header-r-n]
---
# HTTP Request Anatomy

Struktur request HTTP: **Method + URL + Version**, diikuti **Header** (Key: Value), diakhiri **CRLF (\r\n)** — baris kosong — lalu **Body** (optional). Pemahaman literal anatomi ini penting untuk pentest (request smuggling, header injection, parsing differential) dan debugging.

## Struktur Lengkap Request

```text
GET /path?query=1 HTTP/1.1

Host: example.com

User-Agent: Mozilla/5.0

Accept: */*

Cookie: session=abc123



(optional body)
```

- Request line: `METHOD SP URL SP HTTP/version CRLF`
- Setiap header: `Name: Value CRLF`
- Pemisah headers/body: **CRLF CRLF** (satu baris kosong).
- Header berakhir di baris kosong (CRLF CRLF); body dihitung dari Content-Length / Transfer-Encoding.

## CRLF dan Keamanan

**CRLF injection / header injection** — jika aplikasi memasukkan input user ke response header tanpa sanitasi, attacker bisa inject `\r\n` untuk menambah header sendiri atau memulai body:

```text
URL: /redirect?url=/login%0d%0aX-Injected: 1
Response header jadi:
Location: /login
X-Injected: 1
  ← attacker mengontrol header
```

Dampak: session fixation (Set-Cookie), cache poisoning, XSS (jika header body dianggap HTML), web cache deception.

**Defense**: jangan pernah memasukkan user input ke header tanpa validasi; encode CR/LF (`%0d%0a` di URL = jangan di-decode ke header); framework (HTTP library) biasanya menolak CRLF di header value.

## Parsing Differential (Request Smuggling Basis)

Proxy/backend beda cara parse → smuggling:

| Header | Frontend | Backend | Efek |
|--------|----------|---------|------|
| `Content-Length: 13` | pakai CL | pakai CL | normal |
| `Content-Length: 13` + `Transfer-Encoding: chunked` | pakai TE | pakai CL (TE tidak dikenal) | CL.TE smuggling |
| `Transfer-Encoding: chunked` + duplicate TE | pakai TE pertama | pakai TE kedua | TE.TE |
| HTTP/2 (tanpa CL) → backend HTTP/1.1 | h2 | h1 (body tersisa jadi request) | h2 downgrade smuggling |

Detail: lihat [[wiod-reverse-proxy-deepdive]].

## Header Penting untuk Pentest

| Header | Fungsi | Attack angle |
|--------|--------|--------------|
| `Host` | Virtual host routing | Host header injection, password reset poisoning |
| `Content-Length` | Body length | Smuggling, request splitting |
| `Transfer-Encoding` | Chunked body | Smuggling, obfuscation |
| `X-Forwarded-For` | Client IP | Spoof rate limit/ACL (jika dipercaya) |
| `X-Forwarded-Host` | Host asli | Cache poisoning (jika dipakai cache key) |
| `Origin` / `Referer` | CSRF check | CORS bypass, CSRF |
| `Cookie` | Session | Session hijack, fixation |
| `Authorization` | Token | JWT attacks |
| `Upgrade` | Protocol switch | WebSocket abuse, HTTP smuggling vector |
| `Expect: 100-continue` | 100-continue | Smuggling/body handling |

## Versi HTTP

| Versi | Karakteristik | Relevansi security |
|-------|---------------|--------------------|
| **HTTP/0.9** | Hanya GET, tanpa header | Legacy, rare |
| **HTTP/1.0** | Header, koneksi sekali (Connection: keep-alive non-standard) | Host header opsional (security: virtual host confusion) |
| **HTTP/1.1** | Standar: Host wajib, keep-alive, chunked | Smuggling utama (CL/TE) |
| **HTTP/2** | Binary framing, multiplex, HPACK header compression | h2 downgrade smuggling, HPACK bomb (DoS), `:path` abuse |
| **HTTP/3** | QUIC (UDP), TLS 1.3 embedded | Lebih aman, tapi observability/filtering beda (UDP) |

## Request Line Tactics

1. **Method override**: `X-HTTP-Method-Override: DELETE` — backend bisa treat; uji method smuggling (GET berprivilese?).
2. **Absolute URI**: `GET http://target/path HTTP/1.1` — proxy handling beda (SSRF angle).
3. **Path confusion**: `//`, `/./`, `%2e%2e`, `;`, `..%2f` — routing/bypass WAF; normalization proxy vs backend.
4. **Null byte**: `%00` — legacy filter bypass (jarang di parser modern, tapi backend lama).
5. **Case**: `GeT`, `gEt` — beberapa framework case-sensitive method → bypass filter.

## Body & Content-Type

- `application/x-www-form-urlencoded`, `multipart/form-data`, `application/json`, `application/xml`, `text/plain` — WAF/parser beda per type (JSON nesting bypass, multipart confusion).
- `Content-Type` tidak boleh dipercaya — sniff content (magic bytes) di server; browser MIME sniffing (X-Content-Type-Options: nosniff).
- Body besar: `Content-Length` limit (DoS/memory), chunked tanpa limit.

## Tools untuk Anatomi HTTP

- **Burp Repeater** — edit raw request manual.
- **netcat/curl**: `curl -v` (lihat raw), `nc -v host 80` manual.
- **Wireshark** — capture & follow stream (CRLF terlihat).
- **h2c smuggling tools** — untuk HTTP/2 test.
- **Smuggler** (PortSwigger) — automasi CL.TE/TE.CL.

## Checklist Audit (Parsing & Header)

- [ ] Input user tidak pernah masuk header tanpa sanitasi?
- [ ] CL/TE tidak duplikat; server menolak ambiguitas (400)?
- [ ] X-Forwarded-For di-strip & hanya dari proxy trusted?
- [ ] Host header divalidasi (allowlist)?
- [ ] Method override dinonaktifkan jika tidak perlu?
- [ ] Body size limit + content-type handling benar?
- [ ] HTTP/2 → backend conversion tested (smuggling)?
- [ ] Header security (HSTS, nosniff, X-Frame-Options) terpasang?



## Contoh Raw Request Manual (netcat)

```bash
printf 'GET /admin HTTP/1.1\r\nHost: target.com\r\nConnection: close\r\n\r\n' | nc target.com 80
```

## Deteksi Header Injection (Blue)

- Log response headers yang mengandung karakter mencurigakan (CR/LF hex `0d 0a`) — SIEM rule.
- Framework/load balancer menolak header dengan CRLF (test).
- Pentest: masukkan payload `%0d%0a` di parameter yang direfleksikan di header (redirect `Location`, error page).

## Case Study: Web Cache Deception via Header

1. Attacker kirim `GET /account/settings%0d%0aX-Foo: 1` — CDN cache key tidak termasuk header aneh → response disimpan dengan isi akun korban.
2. Korban (login) membuka URL yang sama via link → halaman akun korban di-cache sebagai halaman publik.
3. Attacker ambil halaman cache → data pribadi bocor.

Mitigasi: sanitasi header, cache key lengkap (path + query + host), Vary header, jangan cache halaman pribadi.

## Referensi Lanjutan

- RFC 7230/7231 (HTTP/1.1 message syntax).
- PortSwigger Research: HTTP request smuggling, cache poisoning.
- OWASP: HTTP splitting/response splitting, parameter pollution.

---

  audited
---