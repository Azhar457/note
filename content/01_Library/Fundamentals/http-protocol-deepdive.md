---
title: "HTTP Protocol — Deep Dive: Message Structure, Status Codes, Headers, Caching, HTTP/2, HTTP/3"
tags:
  - fundamentals
  - networking
  - http
  - library
aliases:
  - "http-protocol-deepdive"
created: "2026-07-16"
updated: "2026-07-16"
status: operational
cssclasses:
  - wide-table
---

# 🌐 HTTP Protocol — Deep Dive: Message Structure, Status Codes, Headers, Caching, HTTP/2, HTTP/3

> Panduan komprehensif Hypertext Transfer Protocol dari wire format sampai modern HTTP/3. Mencakup message structure (request/response), status codes 1xx–5xx beserta semantics, headers (general, request, response, entity), caching mechanisms (ETag, Cache-Control, Vary), connection management (Keep-Alive, pipelining, multiplexing), content negotiation, HTTP/2 frames & HPACK compression, HTTP/3 QUIC fundamentals, dan attack surface di setiap layer HTTP. Nota ini adalah **fondasi** untuk semua catatan web security, API security, dan WAF di vault — karena tanpa paham HTTP, lo cuma pake tool buta.

> [!info] Posisi di Vault
> Ini adalah **fondasi layer 7** untuk semua catatan security yang bergantung pada HTTP. Baca ini dulu sebelum [[web-hacking-exploitation]] (eksploitasi web), [[api-security-deep-dive]] (API security), [[waf-reverse-proxy-deepdive]] (WAF & reverse proxy), [[cobalt-strike]] dan [[sliver]] (C2 HTTP profiles), [[cloudflare-ruleset-engine-phases]] (Cloudflare WAF rules), serta [[api-protocols-deepdive]] (perbandingan protokol API). [[networking-fundamentals-tcpip-bgp]] adalah prasyarat layer 4 (TCP).

---

## Daftar Isi

- [[#Foundation — Arsitektur HTTP]]
- [[#Message Structure — Request & Response]]
- [[#Status Codes]]
- [[#Headers — General, Request, Response, Entity]]
- [[#Content Negotiation]]
- [[#Caching]]
- [[#Connection Management]]
- [[#Cookies & Session Management]]
- [[#CORS]]
- [[#HTTP/2]]
- [[#HTTP/3 — QUIC]]
- [[#Attack Surface]]
- [[#Practical Tooling]]
- [[#Checklist]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation — Arsitektur HTTP

### Model Client-Server

```
┌──────────┐   Request (method, URI, headers, body)    ┌──────────┐
│  Client  │ ────────────────────────────────────────→  │  Server  │
│ (Browser │ ←──────────────────────────────────────── │ (nginx)  │
│  / curl) │          Response (status, headers, body)  │          │
└──────────┘                                           └──────────┘
```

HTTP adalah **stateless protocol** — server tidak menyimpan state client antar request. State dikelola di layer lain: cookies, session tokens, JWT.

### Karakteristik Dasar

| Properti        | HTTP/1.0                 | HTTP/1.1                     | HTTP/2             | HTTP/3           |
| --------------- | ------------------------ | ---------------------------- | ------------------ | ---------------- |
| **RFC**         | 1945 (1996)              | 2616 → 7230-35 (1999 → 2014) | 7540 (2015)        | 9114 (2022)      |
| **Koneksi**     | Satu request per koneksi | Keep-Alive default           | Multiplexed stream | QUIC (UDP-based) |
| **Header**      | Plaintext                | Plaintext                    | HPACK compressed   | QPACK compressed |
| **Prioritas**   | —                        | —                            | Stream priority    | Stream priority  |
| **Server Push** | —                        | —                            | ✅ (deprecated!)   | —                |
| **Transport**   | TCP                      | TCP                          | TCP                | QUIC (UDP)       |

### Uniform Resource Identifier (URI)

```
  ┌──────────────────┐ ┌──────┐ ┌────────┐ ┌──────┐ ┌──────────┐
  https://user:pass@api.example.com:8443/path/to/res?query=val#frag
  └─┬──┘ └──┬──┘└───┬────┘ └─┬─┘ └────┬────┘ └───┬───┘
  Scheme    User    Host      Port     Path      Query
```

| Komponen      | Contoh                 | Keterangan                                                             |
| ------------- | ---------------------- | ---------------------------------------------------------------------- |
| **Scheme**    | `https`, `http`, `ftp` | Protokol. HTTPS = HTTP over TLS                                        |
| **User Info** | `user:pass@`           | Deprecated. Jangan dipake — kredensial di URL adalah security risk     |
| **Host**      | `api.example.com`      | Domain atau IP. **Wajib** di HTTP/1.1 via Host header                  |
| **Port**      | `:8443`                | Default: 80 (HTTP), 443 (HTTPS)                                        |
| **Path**      | `/path/to/res`         | Hierarki resource. Bisa di-encode (URL encoding)                       |
| **Query**     | `?query=val`           | Key-value pairs. `?` separator, `&` antar pair, `=` antara key & value |
| **Fragment**  | `#frag`                | Tidak dikirim ke server — hanya client-side (browser scroll)           |

---

## Message Structure — Request & Response

### HTTP Request

```
METHOD /path HTTP/version\r\n
Header1: value\r\n
Header2: value\r\n
\r\n
body
```

**Contoh konkret:**

```
GET /api/users?page=1 HTTP/1.1\r\n
Host: api.example.com\r\n
User-Agent: curl/8.0\r\n
Accept: application/json\r\n
Authorization: Bearer eyJhbGci...\r\n
\r\n
```

### HTTP Response

```
HTTP/version status_code reason_phrase\r\n
Header1: value\r\n
Header2: value\r\n
\r\n
body
```

**Contoh konkret:**

```
HTTP/1.1 200 OK\r\n
Content-Type: application/json\r\n
Content-Length: 42\r\n
Cache-Control: max-age=3600\r\n
\r\n
{"users":[],"page":1,"total_pages":0}
```

### Transfer Modes

| Mode                 | Cara Kirim Body                                                                                         | Kelebihan                               | Kekurangan                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------- | ----------------------------------------------------------- |
| **Content-Length**   | Header `Content-Length: N` — server baca N bytes                                                        | Sederhana, compatible semua versi       | Wajib tahu panjang sebelum kirim — gak cocok buat streaming |
| **Chunked Transfer** | Header `Transfer-Encoding: chunked` — body dipecah jadi chunk, tiap chunk dikirim dengan ukuran sendiri | Bisa streaming tanpa tahu panjang total | Overhead per chunk, tidak di HTTP/2 (pakai DATA frame)      |
| **Multipart**        | `Content-Type: multipart/form-data; boundary=---`                                                       | Kirim file + field dalam satu body      | Parsing lebih kompleks                                      |

---

## Status Codes

### 1xx — Informational

| Code    | Name                | Makna                                                                | Penggunaan                                  |
| ------- | ------------------- | -------------------------------------------------------------------- | ------------------------------------------- |
| **100** | Continue            | Server udah terima headers, client boleh kirim body                  | Biar gak kirim body besar cuma buat ditolak |
| **101** | Switching Protocols | Server setuju upgrade protokol (WebSocket, HTTP/2 upgrade)           | WebSocket handshake, HTTP/2 Upgrade header  |
| **102** | Processing (WebDAV) | Server masih proses, jangan timeout                                  | WebDAV long operations — jarang dipake      |
| **103** | Early Hints         | Server kirim hints sebelum response final (Link header buat preload) | HTTP/2 dan HTTP/3 — optimasi loading        |

### 2xx — Success

| Code    | Name            | Makna                                           | Kapan Pake                              |
| ------- | --------------- | ----------------------------------------------- | --------------------------------------- |
| **200** | OK              | Request berhasil, body berisi resource          | GET berhasil, POST sukses               |
| **201** | Created         | Resource baru berhasil dibuat                   | POST ke /users → user baru              |
| **202** | Accepted        | Request diterima tapi belum diproses (async)    | Job queue, background task              |
| **204** | No Content      | Berhasil tapi gak ada body yang dikirim         | DELETE sukses, PUT update tanpa balikan |
| **206** | Partial Content | Hanya sebagaian resource dikirim (Range header) | Video streaming, download resume        |

### 3xx — Redirection

| Code    | Name               | Makna                                                | Kapan Pake                                             |
| ------- | ------------------ | ---------------------------------------------------- | ------------------------------------------------------ |
| **301** | Moved Permanently  | URL udah pindah permanen — browser ganti bookmark    | Domain migration, HTTP→HTTPS redirect                  |
| **302** | Found              | URL pindah sementara — jangan ganti bookmark         | Post/Redirect/Get pattern, login redirect              |
| **303** | See Other          | Redirect ke URL lain, method HARUS jadi GET          | Form submission redirect                               |
| **304** | Not Modified       | Resource gak berubah — pake cache                    | Conditional request (If-None-Match, If-Modified-Since) |
| **307** | Temporary Redirect | Sama kayak 302 tapi method & body TIDAK BOLEH diubah | PATCH redirect                                         |
| **308** | Permanent Redirect | Sama kayak 301 tapi method & body TIDAK BOLEH diubah | API permanent migration                                |

**⚠️ 301 vs 302 vs 307 vs 308:**

- 301/302 — browser BOLEH ganti POST → GET (banyak implementasi broken)
- 307/308 — method & body WAJIB dipertahankan. Pake ini buat API redirect!

### 4xx — Client Error

| Code    | Name                            | Makna                                                          | Kapan Pake                                                 |
| ------- | ------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------- |
| **400** | Bad Request                     | Server gak paham request — format salah                        | Validation error, malformed JSON                           |
| **401** | Unauthorized                    | Belum login / token gak valid                                  | Missing/Wrong Authorization header                         |
| **403** | Forbidden                       | Udah login tapi gak punya akses                                | RBAC deny, IP block, geo-restriction                       |
| **404** | Not Found                       | Resource gak ada                                               | Endpoint salah, resource dihapus                           |
| **405** | Method Not Allowed              | Method gak diizinkan untuk endpoint ini                        | POST ke endpoint yang cuma terima GET                      |
| **406** | Not Acceptable                  | Server gak bisa kasih format yang client minta (Accept header) | Client minta `application/xml` tapi server cuma punya JSON |
| **408** | Request Timeout                 | Client terlalu lama kirim data                                 | Timeout konfigurasi server                                 |
| **409** | Conflict                        | State resource bentrok dengan request                          | Concurrent edit, duplicate entry                           |
| **410** | Gone                            | Resource udah dihapus permanen (beda sama 404)                 | API deprecation                                            |
| **413** | Content Too Large               | Body melebihi batas server                                     | Upload file terlalu gede                                   |
| **415** | Unsupported Media Type          | Content-Type gak didukung                                      | Kirim XML ke endpoint yang cuma terima JSON                |
| **422** | Unprocessable Entity            | Body format bener tapi isinya salah                            | Validasi semantik (WebDAV, REST API umum)                  |
| **429** | Too Many Requests               | Rate limit exceeded                                            | API Gateway rate limiting                                  |
| **431** | Request Header Fields Too Large | Header kegedean                                                | Cookie overflow attack                                     |

### 5xx — Server Error

| Code    | Name                  | Makna                                                | Kapan Pake                                           |
| ------- | --------------------- | ---------------------------------------------------- | ---------------------------------------------------- |
| **500** | Internal Server Error | Server error generic — jangan kasih detail ke client | Catch-all server error                               |
| **501** | Not Implemented       | Method belum didukung server                         | Fitur belum dibuat                                   |
| **502** | Bad Gateway           | Upstream server balikin response invalid             | Proxy/gateway error dari backend                     |
| **503** | Service Unavailable   | Server sementara gak bisa                            | Maintenance, overload, rate limiting di level server |
| **504** | Gateway Timeout       | Upstream server gak balik tepat waktu                | Backend slow, database timeout                       |

> [!tip] Best Practice Status Codes
>
> - Response error WAJIB sertakan body deskriptif + error code spesifik untuk debugging
> - Jangan expose stack trace di 500 error — security risk
> - 422 lebih tepat untuk validation error daripada 400

---

## Headers — General, Request, Response, Entity

### General Headers (berlaku untuk request & response)

| Header              | Contoh                                      | Fungsi                                        |
| ------------------- | ------------------------------------------- | --------------------------------------------- |
| `Date`              | `Date: Wed, 15 Jul 2026 10:00:00 GMT`       | Timestamp server — wajib di response          |
| `Connection`        | `Connection: keep-alive` (default HTTP/1.1) | Kontrol koneksi: keep-alive vs close          |
| `Cache-Control`     | `Cache-Control: no-cache`                   | Directive caching (detail di section caching) |
| `Transfer-Encoding` | `Transfer-Encoding: chunked`                | Encoding transfer — bukan content encoding    |

### Request Headers

| Kategori        | Header                           | Contoh                                             | Fungsi                                                   |
| --------------- | -------------------------------- | -------------------------------------------------- | -------------------------------------------------------- |
| **Identity**    | `Host`                           | `Host: api.example.com`                            | **WAJIB di HTTP/1.1** — nama server virtual              |
| **Auth**        | `Authorization`                  | `Authorization: Bearer eyJhbG...`                  | Credential / token — Basic, Bearer, Digest               |
| **Auth**        | `Proxy-Authorization`            | Sama format                                        | Auth ke proxy                                            |
| **Client**      | `User-Agent`                     | `User-Agent: curl/8.0.0`                           | Identitas client — sering dipalsukan oleh bot/C2         |
| **Client**      | `Referer`                        | `Referer: https://site.com/page`                   | Halaman asal — privacy risk (bocorin URL)                |
| **Client**      | `From`                           | `From: user@example.com`                           | Email — jarang dipake                                    |
| **Content**     | `Content-Type`                   | `Content-Type: application/json`                   | Tipe body — WAJIB kalo ada body                          |
| **Content**     | `Content-Length`                 | `Content-Length: 42`                               | Ukuran body dalam bytes                                  |
| **Content**     | `Content-Encoding`               | `Content-Encoding: gzip`                           | Kompresi yang dipake di body                             |
| **Negotiation** | `Accept`                         | `Accept: application/json, text/plain`             | Format response yang diterima client                     |
| **Negotiation** | `Accept-Encoding`                | `Accept-Encoding: gzip, deflate, br`               | Kompresi yang didukung                                   |
| **Negotiation** | `Accept-Language`                | `Accept-Language: id, en;q=0.9`                    | Bahasa preferensi                                        |
| **Negotiation** | `Accept-Charset`                 | (deprecated)                                       | Charset — jarang dipake modern                           |
| **Conditional** | `If-Modified-Since`              | `If-Modified-Since: Wed, 15 Jul 2026 10:00:00 GMT` | Conditional GET — cache validation                       |
| **Conditional** | `If-None-Match`                  | `If-None-Match: "abc123"`                          | ETag matching — cache validation                         |
| **Conditional** | `If-Match`                       | `If-Match: "abc123"`                               | Untuk optimistic concurrency (PUT)                       |
| **Conditional** | `If-Unmodified-Since`            | Timestamp                                          | Same — update cuma kalo gak diubah sejak                 |
| **Range**       | `Range`                          | `Range: bytes=100-199`                             | Partial request                                          |
| **CORS**        | `Origin`                         | `Origin: https://site.com`                         | Asal request — basis CORS                                |
| **CORS**        | `Access-Control-Request-Method`  | `OPTIONS`                                          | Preflight — method yang diminta                          |
| **CORS**        | `Access-Control-Request-Headers` | `X-Custom`                                         | Preflight — custom headers                               |
| **Security**    | `Cookie`                         | `Cookie: session=abc; theme=dark`                  | Session cookie — detail di section cookies               |
| **Security**    | `DNT`                            | `DNT: 1`                                           | Do Not Track — tidak diwajibkan browser implement        |
| **Cache**       | `Pragma`                         | `Pragma: no-cache`                                 | HTTP/1.0 backward compatibility — pake Cache-Control aja |
| **Cache**       | `Expect`                         | `Expect: 100-continue`                             | Client nunggu 100 Continue sebelum kirim body besar      |

### Response Headers

| Kategori     | Header                             | Contoh                                                           | Fungsi                                        |
| ------------ | ---------------------------------- | ---------------------------------------------------------------- | --------------------------------------------- |
| **Identity** | `Server`                           | `Server: nginx/1.24`                                             | Identitas server — bisa disembunyikan         |
| **Auth**     | `WWW-Authenticate`                 | `WWW-Authenticate: Bearer realm="api"`                           | Tantangan auth — dikirim bareng 401           |
| **Auth**     | `Proxy-Authenticate`               | Sama format                                                      | Tantangan proxy auth                          |
| **CORS**     | `Access-Control-Allow-Origin`      | `Access-Control-Allow-Origin: *`                                 | Origin yang diizinkan                         |
| **CORS**     | `Access-Control-Allow-Methods`     | `GET, POST, PUT, DELETE`                                         | Method yang diizinkan                         |
| **CORS**     | `Access-Control-Allow-Headers`     | `Content-Type, Authorization`                                    | Headers yang diizinkan                        |
| **CORS**     | `Access-Control-Allow-Credentials` | `true`                                                           | Apakah kredensial boleh dikirim cross-origin  |
| **CORS**     | `Access-Control-Max-Age`           | `86400`                                                          | Cache preflight response (detik)              |
| **CORS**     | `Access-Control-Expose-Headers`    | `X-RateLimit-*`                                                  | Header non-standar yang boleh dibaca JS       |
| **Security** | `Strict-Transport-Security`        | `Strict-Transport-Security: max-age=31536000; includeSubDomains` | HSTS — paksa HTTPS                            |
| **Security** | `Content-Security-Policy`          | `Content-Security-Policy: default-src 'self'`                    | CSP — cegah XSS                               |
| **Security** | `X-Content-Type-Options`           | `X-Content-Type-Options: nosniff`                                | Cegah MIME sniffing                           |
| **Security** | `X-Frame-Options`                  | `X-Frame-Options: DENY`                                          | Cegah clickjacking                            |
| **Security** | `X-XSS-Protection`                 | `X-XSS-Protection: 1; mode=block`                                | Legacy — browser modern gak pake              |
| **Security** | `Referrer-Policy`                  | `Referrer-Policy: strict-origin-when-cross-origin`               | Kontrol isi Referer header                    |
| **Security** | `Permissions-Policy`               | `Permissions-Policy: camera=(), microphone=()`                   | Kontrol API browser                           |
| **Security** | `Set-Cookie`                       | `Set-Cookie: session=abc; HttpOnly; Secure; SameSite=Lax`        | Set cookie — detail di section cookies        |
| **Location** | `Location`                         | `Location: https://new-url.com`                                  | Redirect target — bareng 3xx                  |
| **Retry**    | `Retry-After`                      | `Retry-After: 120`                                               | Kapan client boleh coba lagi — bareng 429/503 |
| **Cache**    | `Age`                              | `Age: 3600`                                                      | Umur cache hit di proxy                       |
| **Info**     | `Warning`                          | (deprecated)                                                     | Informasi tambahan                            |
| **Timing**   | `Timing-Allow-Origin`              | `Timing-Allow-Origin: *`                                         | Resource Timing API access                    |

### Entity Headers (tentang body)

| Header                | Contoh                                                   | Fungsi                                       |
| --------------------- | -------------------------------------------------------- | -------------------------------------------- |
| `Content-Type`        | `Content-Type: application/json; charset=utf-8`          | Tipe media + encoding                        |
| `Content-Length`      | `Content-Length: 128`                                    | Ukuran dalam bytes                           |
| `Content-Encoding`    | `Content-Encoding: gzip`                                 | Kompresi (diterapkan setelah Content-Type)   |
| `Content-Language`    | `Content-Language: id`                                   | Bahasa konten                                |
| `Content-Location`    | `Content-Location: /api/users?page=1`                    | URL alternatif resource ini                  |
| `Content-Disposition` | `Content-Disposition: attachment; filename="report.pdf"` | Kontrol cara browser nampilin konten         |
| `Content-Range`       | `Content-Range: bytes 100-199/1000`                      | Posisi partial response                      |
| `ETag`                | `ETag: "abc123"`                                         | Identifier unik versi resource — untuk cache |
| `Last-Modified`       | `Last-Modified: Wed, 15 Jul 2026 10:00:00 GMT`           | Timestamp update terakhir                    |
| `Expires`             | `Expires: Thu, 16 Jul 2026 10:00:00 GMT`                 | Waktu kadaluarsa — HTTP/1.0                  |

---

## Content Negotiation

Proses client & server negotiate format terbaik untuk resource yang sama.

### Server-Driven (Paling Umum)

Client kirim `Accept` headers → server pilih format terbaik:

```http
GET /api/users HTTP/1.1
Accept: application/json;q=0.9, application/xml;q=0.5, text/html;q=0.1
```

- `q` = quality value (prioritas 0–1). Default: `q=1.0`
- Server pilih format dengan q tertinggi yang didukung
- Kalau gak ada yang cocok → 406 Not Acceptable

### Agent-Driven (Jarang)

Server balikin 300 Multiple Choices dengan daftar format → client pilih.

### Proactive Content Negotiation in HTTP/2 & HTTP/3

Sama konsepnya — header yang sama dipake di frame headers.

---

## Caching

Caching adalah mekanisme HTTP yang paling sering **salah konfigurasi** dan menyebabkan security issue.

### Freshness Model

```
Resource dibuat              Cache expires
    │                             │
    ├──────── FRESH ──────────────┤──── STALE ────→
    │                             │
    │←────── Cache HIT ──────────→│
                                  │←── Cache MISS (revalidate) ──→
```

### Cache-Control Directives

| Directive                | Contoh                         | Fungsi                                                                                 |
| ------------------------ | ------------------------------ | -------------------------------------------------------------------------------------- |
| `max-age=N`              | `max-age=3600`                 | Resource fresh selama N detik setelah server generate                                  |
| `s-maxage=N`             | `s-maxage=3600`                | Sama, tapi khusus shared cache (CDN, proxy) — override max-age                         |
| `no-cache`               | `no-cache`                     | Jangan pake cache tanpa revalidate — masih boleh store, tapi musti tanya server dulu   |
| `no-store`               | `no-store`                     | **Jangan simpan sama sekali** — buat data sensitif (banking, token)                    |
| `must-revalidate`        | `must-revalidate`              | Begitu stale, WAJIB revalidate — gak boleh kirim stale                                 |
| `proxy-revalidate`       | Sama                           | Sama tapi khusus shared cache                                                          |
| `private`                | `private, max-age=3600`        | Cuma browser client yang boleh cache — proxy jangan                                    |
| `public`                 | `public, max-age=3600`         | Boleh di-cache siapa aja (CDN, proxy, browser)                                         |
| `immutable`              | `immutable`                    | Resource gak akan berubah selama max-age — browser gak usah revalidate (static assets) |
| `stale-while-revalidate` | `stale-while-revalidate=86400` | Boleh kirim stale sambil fetch ulang di background                                     |
| `stale-if-error`         | `stale-if-error=86400`         | Kalo server error, kirim stale aja daripada error                                      |

### ETag & Conditional Request

**ETag** = identifier unik versi resource (hash, timestamp, atau version number):

```http
# Response
HTTP/1.1 200 OK
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

# Request berikutnya (If-None-Match)
GET /resource HTTP/1.1
If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

# Response kalo gak berubah
HTTP/1.1 304 Not Modified
# (no body — pake cache)
```

**Last-Modified + If-Modified-Since:**

```http
Response: Last-Modified: Wed, 15 Jul 2026 10:00:00 GMT
Request:  If-Modified-Since: Wed, 15 Jul 2026 10:00:00 GMT
Response: 304 Not Modified  # atau 200 dengan resource baru
```

**Prioritas:** ETag lebih akurat daripada Last-Modified (bisa deteksi perubahan dalam <1 detik).

### Caching Security Issues

| Issue                       | Penyebab                                                                       | Dampak                                       |
| --------------------------- | ------------------------------------------------------------------------------ | -------------------------------------------- |
| **Sensitive data di cache** | Response dengan data pribadi gak pake `no-store`                               | Data pasien, token, API key bocor dari cache |
| **Cache poisoning**         | Attacker inject response malicious → cache → semua user dapet response jahat   | XSS massal, redirect ke phishing             |
| **Cache key confusion**     | Header `Vary` gak lengkap → dua user dapet response yang sama padahal beda     | Data bocor antar user                        |
| **Web Cache Deception**     | Attacker trick app untuk cache response sensitif dengan tambahin `.css` di URL | Data sensitif jadi public di CDN             |

---

## Connection Management

HTTP/1.1 menggunakan **persistent connections** (Keep-Alive) secara default.

### HTTP/1.1 Keep-Alive

```http
Connection: keep-alive  # default, bisa explicit
# atau
Connection: close       # Server: "setelah ini, tutup"
```

**Cara kerja:**

```
Client: [ SYN → SYN-ACK → ACK ]
Client: [ Request 1 → Response 1 ]  ← dalam satu koneksi TCP
Client: [ Request 2 → Response 2 ]  ← koneksi yang sama
Client: [ Request 3 → Response 3 ]
Client: [ FIN → ... ]               ← tutup koneksi
```

Tanpa Keep-Alive (HTTP/1.0), tiap request buka koneksi baru → 3-way handshake + slow start TCP = **lambat**.

### Pipelining (Deprecated)

Kirim banyak request tanpa nunggu response. Bermasalah karena **HOL blocking** (satu response lambat nahan semua response di belakangnya) dan implementasi proxy yang broken.

### HTTP/2 Multiplexing (Solusi HOL Blocking)

Lihat section HTTP/2.

### Timeouts & Limits

| Parameter               | Default (nginx) | Fungsi                                       |
| ----------------------- | --------------- | -------------------------------------------- |
| `keepalive_timeout`     | 65s             | Berapa lama koneksi idle boleh hidup         |
| `keepalive_requests`    | 1000            | Maks request per koneksi (cegah memory leak) |
| `client_body_timeout`   | 60s             | Timeout baca body client                     |
| `client_header_timeout` | 60s             | Timeout baca header client                   |
| `send_timeout`          | 60s             | Timeout kirim response ke client             |

---

## Cookies & Session Management

### Cookie Attributes

```http
Set-Cookie: sessionId=abc123; Domain=.example.com; Path=/; Max-Age=86400; HttpOnly; Secure; SameSite=Lax
```

| Attribute                 | Fungsi                                                        | Security Implication                                                |
| ------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------- |
| **`Domain=.example.com`** | Cookie dikirim ke domain & subdomain                          | Terlalu lebar = subdomain yang compromised bisa baca cookie         |
| **`Path=/`**              | Cookie dikirim untuk path ini & sub-path                      | `Path=/admin` lebih ketat dari `/`                                  |
| **`Max-Age=N`**           | Cookie hidup N detik. `Max-Age=0` = hapus                     | Cookie tanpa expiry = session cookie (hapus saat browser tutup)     |
| **`Expires=date`**        | Sama, HTTP/1.0 style                                          | —                                                                   |
| **`HttpOnly`**            | JavaScript gak bisa baca cookie via `document.cookie`         | **WAJIB** untuk session cookie — cegah XSS cookie theft             |
| **`Secure`**              | Cookie cuma dikirim via HTTPS                                 | **WAJIB** — cegah泄露 di HTTP plaintext                             |
| **`SameSite`**            | Kontrol pengiriman cookie cross-site: `Strict`, `Lax`, `None` | Cegah CSRF. `Lax` = default modern browser. `None` = butuh `Secure` |

### SameSite Explained

| Value             | Link (click) | Form POST dari site lain | Fetch/XHR cross-site | Iframe       |
| ----------------- | ------------ | ------------------------ | -------------------- | ------------ |
| **Strict**        | ❌ No cookie | ❌ No cookie             | ❌ No cookie         | ❌ No cookie |
| **Lax** (default) | ✅ Send      | ❌ No cookie             | ❌ No cookie         | ❌ No cookie |
| **None**          | ✅ Send      | ✅ Send                  | ✅ Send              | ✅ Send      |

`Lax` adalah kompromi keamanan vs usability — ngirim cookie waktu navigasi GET normal (link), tapi gak ngirim buat POST/background request.

---

## CORS

### Cara Kerja

1. Browser deteksi request **cross-origin** (beda scheme, host, atau port)
2. Kalo request sederhana (GET, POST with form content-type) → kirim `Origin` header
3. Kalo request kompleks (PUT, DELETE, custom header, non-form content-type) → kirim **preflight** `OPTIONS` dulu
4. Server balikin `Access-Control-Allow-*` headers
5. Browser cek: kalo gak cocok → block (JS error), kalo cocok → izinkan

### Simple Request vs Preflight

**Simple Request:** Method = GET/HEAD/POST, Content-Type = application/x-www-form-urlencoded atau multipart/form-data atau text/plain, gak ada custom headers → langsung kirim request, gak perlu preflight.

**Preflight Request:**

```http
OPTIONS /api/resource HTTP/1.1
Origin: https://malicious-site.com
Access-Control-Request-Method: PUT
Access-Control-Request-Headers: X-Custom-Header
```

**Preflight Response:**

```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://trusted-site.com
Access-Control-Allow-Methods: PUT, POST, GET
Access-Control-Allow-Headers: X-Custom-Header
Access-Control-Max-Age: 86400
```

### Common Mistakes

| Mistake                                                   | Dampak                                                                                                                                |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `Access-Control-Allow-Origin: *` dengan credentials: true | **Invalid** — browser block. Kalo pake credentials, origin WAJIB spesifik                                                             |
| `Access-Control-Allow-Origin: null`                       | Origin `null` bisa dari sandbox iframe — bikin CORS bypass                                                                            |
| Reflecting origin tanpa validasi                          | Attacker bisa pake `Origin: https://evil.com` → server balikin `Access-Control-Allow-Origin: https://evil.com` → browser izinin akses |
| Gak validasi preflight                                    | Attacker bisa abuse OPTIONS untuk bypass auth                                                                                         |

---

## HTTP/2

### Binary Framing Layer

HTTP/2 mengubah HTTP dari **textual** (baca: ASCII) ke **binary** — bukan perubahan format biasa, ini fundamental redesign:

```
HTTP/1.1:
  GET /resource HTTP/1.1
  Host: server.com
  → di-parse line by line sebagai ASCII text

HTTP/2:
  HEADERS frame (stream 1):
    :method: GET
    :path: /resource
    :authority: server.com
  → binary, pre-parsed, dikirim dalam frame
```

### Frame Types

| Frame Type        | Fungsi                                      |
| ----------------- | ------------------------------------------- |
| **HEADERS**       | Header HTTP (request atau response)         |
| **DATA**          | Body                                        |
| **SETTINGS**      | Parameter koneksi (konfigurasi peer)        |
| **PRIORITY**      | Prioritas stream                            |
| **RST_STREAM**    | Batalkan stream (tidak perlu tutup koneksi) |
| **GOAWAY**        | Inisiasi shutdown koneksi                   |
| **PING**          | Keep-alive + RTT measurement                |
| **WINDOW_UPDATE** | Flow control — update window size           |

### Streams, Messages, Frames

```
┌──────────────────────────────────────────┐
│          1 TCP Connection                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Stream 1│  │ Stream 3│  │ Stream 5│  │
│  │ GET /a  │  │ POST /b │  │ GET /c  │  │
│  │ (HEADERS)│  │(HEADERS)│  │ (HEADERS)│  │
│  └─────────┘  │ (DATA)  │  └─────────┘  │
│               └─────────┘               │
└──────────────────────────────────────────┘
```

### HPACK — Header Compression

Tanpa kompresi, header HTTP bisa 400-800 bytes per request. HPACK kompres jadi ~30 bytes:

```
Index Table (static — 61 entries predefined):
+-------+-----------------------+
| Index | Header Name & Value   |
+-------+-----------------------+
| 2     | :method: GET          |
| 3     | :method: POST         |
| 5     | :path: /index.html    |
| 7     | :authority:           |
| ...   | ...                   |
+-------+-----------------------+

Index Table (dynamic — built during session):
Makin banyak request → makin banyak entry di-cache
→ makin kecil ukuran header
```

### Server Push (Deprecated)

Chrome 106+ (Sept 2022) menghapus HTTP/2 Server Push karena adopsi rendah dan masalah performa. Gantinya: **103 Early Hints** dan **preload links**.

### HOL Blocking in HTTP/2?

TCP-level HOL blocking tetap ada: kalo 1 packet TCP hilang, **semua stream** nunggu retransmit. Ini yang diperbaiki HTTP/3 dengan pindah ke QUIC (UDP).

---

## HTTP/3 — QUIC

HTTP/3 adalah HTTP over QUIC (Quick UDP Internet Connections), bukan TCP.

### Key Differences

| Aspek                    | HTTP/2 (TCP)                               | HTTP/3 (QUIC)                                |
| ------------------------ | ------------------------------------------ | -------------------------------------------- |
| **Transport**            | TCP                                        | QUIC (UDP)                                   |
| **Handshake**            | TCP (1 RTT) + TLS (1 RTT) = 2 RTT          | QUIC (0-RTT atau 1-RTT)                      |
| **HOL blocking**         | Ya (TCP packet loss → semua stream nunggu) | Tidak (setiap stream independent)            |
| **Connection migration** | Tidak (putus kalo pindah jaringan)         | Ya (connection ID — pindah WiFi tanpa putus) |
| **Encryption**           | Opsional (HTTPS via TLS)                   | **Wajib** (built-in)                         |
| **Implementation**       | nginx, h2o, Caddy                          | Cloudflare, Google, nginx (experimental)     |

### QUIC Connection Establishment

```
Client                                          Server
  │                                                │
  │───── QUIC Initial (ClientHello + data) ───────→│  0-RTT (kalo pernah connect sebelumnya)
  │←─── QUIC Handshake (ServerHello + data) ───────│
  │←─── QUIC Initial (done) ───────────────────────│
  │←═══════════ Data ══════════════════════════════→│  1-RTT total vs 2-3 RTT TCP+TLS
```

### Connection Migration

```
Client di WiFi:
  [Connection ID: CID-ABC] → Server

Client pindah ke 4G:
  [Connection ID: CID-ABC] (IP baru!) → Server
  Server kenali dari CID → lanjut tanpa handshake ulang
```

Ini penting buat mobile: pindah WiFi ↔ 4G tanpa putus streaming atau download.

---

## Attack Surface

### HTTP Request Smuggling

Eksploitasi perbedaan parsing Content-Length vs Transfer-Encoding antara frontend (proxy/CDN) dan backend:

```http
POST / HTTP/1.1
Host: vulnerable-server.com
Content-Length: 13
Transfer-Encoding: chunked

0

GET /admin HTTP/1.1
Host: internal-admin.com
```

Frontend parse `Transfer-Encoding: chunked` → baca `0\r\n` sebagai end of message. Backend parse `Content-Length: 13` → baca `13` bytes → `GET /admin...` adalah **request berikutnya** dalam koneksi yang sama.

### Cache Poisoning

Attacker inject response dengan header `X-Forwarded-Host: evil.com` → server generate redirect ke `evil.com` → CDN cache → semua user kena redirect.

### HTTP Parameter Pollution (HPP)

```http
GET /search?q=term&q=malicious HTTP/1.1
```

Backend beda-beda parse priority: nginx = pertama, Python = terakhir, PHP = terakhir. Bisa bypass validation.

### Host Header Attack

```http
GET / HTTP/1.1
Host: evil.com
```

Kalo aplikasi pake `Host` header buat generate link (password reset, redirect), attacker bisa bikin link phishing.

### CRLF Injection

```http
GET /%0d%0aSet-Cookie:%20session=evil HTTP/1.1
```

Newline yang di-encode → server inject header. Modern framework sudah prevent ini.

### Insecure Methods

| Method      | Risk                                                  |
| ----------- | ----------------------------------------------------- |
| **TRACE**   | Cross-Site Tracing (XST) — bocorin cookie via headers |
| **PUT**     | Upload file → RCE                                     |
| **DELETE**  | Hapus resource                                        |
| **OPTIONS** | Info metode yang didukung — informasi recon           |

**Mitigasi:** Disable TRACE, PUT, DELETE untuk public endpoint.

### HTTP/2 Rapid Reset Attack (CVE-2023-44487)

Attack 2023 yang memanfaatkan fitur HTTP/2 `RST_STREAM`:

- Kirim banyak request → langsung cancel stream
- Server alloc resource per stream → client cancel terus → resource exhaustion
- **Dampak:** DDoS record 398M rps via Cloudflare
- **Mitigasi:** Rate limit stream creation + cancel per koneksi

---

## Practical Tooling

### cURL — HTTP Debugging

```bash
# Lihat full request-response
curl -v https://api.example.com

# Cuma headers
curl -I https://example.com

# Custom method + body
curl -X PUT -H "Content-Type: application/json" -d '{"key":"val"}' https://api.example.com/resource

# With cookie
curl -b "session=abc" https://api.example.com

# Follow redirects
curl -L http://example.com

# HTTP/2
curl --http2 https://http2.example.com

# HTTP/3
curl --http3 https://http3.example.com

# Measure timing
curl -w "\nTime: %{time_total}s\nHTTP: %{http_version}\n" -o /dev/null -s https://example.com
```

### Python http.client — Wire Level

```python
import http.client

conn = http.client.HTTPConnection("example.com", 80)
conn.request("GET", "/", headers={"Host": "example.com"})
resp = conn.getresponse()
print(resp.status, resp.reason)
print(resp.headers)
print(resp.read().decode())
conn.close()
```

### HTTP/2 Frame Inspector (nghttp2)

```bash
# Install
apt install nghttp2-client

# Lihat HTTP/2 frames
nghttp -v https://nghttp2.org

# Output:
# [  0.000] send HEADERS frame <stream=1>
#           ; END_STREAM | END_HEADERS
#           (:method: GET)
#           (:path: /)
#           (:scheme: https)
#           (:authority: nghttp2.org)
# [  0.068] recv SETTINGS frame <stream=0>
# [  0.068] recv HEADERS frame <stream=1>
#           ; END_HEADERS
#           (:status: 200)
#           (server: nghttp2)
```

---

## Checklist

```
☐ Paham HTTP message structure (request line, headers, body)
☐ Hafal status codes: 2xx (success), 3xx (redirect), 4xx (client error), 5xx (server error)
☐ Bisa bedain 301 vs 302 vs 307 vs 308 — mana yang boleh ganti method
☐ Paham Content-Type vs Content-Encoding (apa isi vs bagaimana dikirim)
☐ Cache-Control: tau beda no-cache (store tapi revalidate) vs no-store (jangan simpan)
☐ Paham ETag + conditional request (If-None-Match, If-Match)
☐ Bisa baca tcpdump HTTP traffic dan kenali handshake + transfer
☐ Cookie: HttpOnly, Secure, SameSite — wajib paham fungsinya
☐ CORS: kenapa preflight, cara kerja origin check, common mistakes
☐ HTTP/2: binary framing, multiplexing, HPACK
☐ HTTP/3: QUIC, 0-RTT, connection migration
☐ Attack surface: request smuggling, cache poisoning, host header, CRLF injection
```

---

## Koneksi ke Vault

- [[networking-fundamentals-tcpip-bgp]] — prasyarat layer 4 TCP yang jadi transport HTTP/1.x dan HTTP/2
- [[web-hacking-exploitation]] — teknik exploitasi yang memanipulasi HTTP (SQLi, XSS, SSRF)
- [[api-security-deep-dive]] — keamanan REST/GraphQL API yang berbasis HTTP
- [[api-protocols-deepdive]] — perbandingan HTTP dengan gRPC, GraphQL, WebSocket
- [[waf-reverse-proxy-deepdive]] — WAF yang menginspeksi HTTP di layer 7
- [[cloudflare-ruleset-engine-phases]] — Cloudflare WAF rules yang bekerja di phase HTTP
- [[cobalt-strike]] dan [[sliver]] — C2 HTTP/S profiles yang fake HTTP untuk evasion
- [[browser-security-exploitation-deepdive]] — keamanan browser dan HTTP interaction
- [[comprehensive-threat-directory]] — taksonomi ancaman berbasis HTTP

---

## References

1. IETF. _RFC 9110: HTTP Semantics_. 2022. https://httpwg.org/specs/rfc9110.html
2. IETF. _RFC 9111: HTTP Caching_. 2022. https://httpwg.org/specs/rfc9111.html
3. IETF. _RFC 9112: HTTP/1.1_. 2022. https://httpwg.org/specs/rfc9112.html
4. IETF. _RFC 9113: HTTP/2_. 2022. https://httpwg.org/specs/rfc9113.html
5. IETF. _RFC 9114: HTTP/3_. 2022. https://httpwg.org/specs/rfc9114.html
6. IETF. _RFC 7541: HPACK: Header Compression for HTTP/2_. 2015.
7. IETF. _RFC 6265: HTTP State Management Mechanism (Cookies)_. 2011.
8. IETF. _RFC 6454: The Web Origin Concept_. 2011.
9. WHATWG. _Fetch Standard (CORS)_. https://fetch.spec.whatwg.org/
10. Mozilla MDN. _HTTP Documentation_. https://developer.mozilla.org/en-US/docs/Web/HTTP
11. Mozilla MDN. _CORS_. https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
12. Mozilla MDN. _HTTP Caching_. https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
13. PortSwigger. _HTTP Request Smuggling_. https://portswigger.net/web-security/request-smuggling
14. PortSwigger. _Web Cache Poisoning_. https://portswigger.net/web-security/web-cache-poisoning
15. PortSwigger. _HTTP Parameter Pollution_. https://portswigger.net/kb/issues/00100400_http-parameter-pollution
16. nginx. _NGINX HTTP Configuration_. https://nginx.org/en/docs/http/ngx_http_core_module.html
17. Cloudflare. _HTTP/2 Rapid Reset Attack_. https://blog.cloudflare.com/technical-breakdown-http2-rapid-reset-ddos-attack/
18. Google. _QUIC Protocol_. https://quicwg.org/
19. curl. _curl man page_. https://curl.se/docs/manpage.html
20. httpbin.org. _HTTP Request & Response Service_. https://httpbin.org/

> [!tip] Bottom Line
> HTTP adalah **bahasa internet** — setiap request, response, header, dan status code punya makna spesifik yang bisa dieksploitasi atau dilindungi. Tanpa paham HTTP secara fundamental, lo cuma bisa pake tool (Burp, curl, WAF) secara buta — gak bisa bedain mana yang normal, mana yang attack. Fokus utama buat security engineer: (1) **Cache semantics** — misconfigured cache adalah sumber data breach paling umum. (2) **CORS** — origin validation yang salah = jalan buat CSRF dan data exfil. (3) **Connection management** — smuggled request bisa bypass WAF. (4) **HTTP/2 Rapid Reset** — bukti bahwa bahkan protokol modern punya attack surface baru. Status code 304? Itu bukan cuma "not modified" — itu **cache oracle** buat attacker.
