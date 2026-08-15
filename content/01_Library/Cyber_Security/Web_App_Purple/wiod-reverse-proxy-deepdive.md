---
title: Wiod Reverse Proxy Deepdive
tags: [security, web, proxy, purple]
aliases: [wiod-reverse-proxy-deepdive]
---
# Reverse Proxy Deepdive (Wiod)

Reverse proxy berdiri di depan backend: menerima request client, meneruskan ke server internal. Fungsi: caching, load balancing, TLS termination, WAF, hiding internal topology. File ini membedah arsitektur reverse proxy dari sudut purple team — attack & defense.

## Arsitektur Umum

```
Client → [TLS terminator] → [Reverse Proxy (Nginx/HAProxy/Envoy)]
       → [WAF layer (opsional)] → [Backend pool]
                ↓
          [Cache server (Redis/Varnish)]
```

- **TLS termination** — proxy meng-decrypt, backend terima plaintext (harus di network internal yang aman).
- **Load balancing** — round-robin, leastconn, IP hash (session stickiness).
- **Caching** — static assets, API responses (dengan cache-control yang benar).
- **Header handling** — X-Forwarded-For, X-Real-IP, Host normalization.

## Header Trust & Spoofing (Kerapuhan)

### X-Forwarded-For (XFF) Trust
- Backend yang memakai `request.headers['x-forwarded-for']` untuk logging/rate-limit/policy tampa validasi → attacker bisa spoof `X-Forwarded-For: 127.0.0.1` → bypass IP-based rate limit, bypass IP address allowlist.
- Cara aman: proxy harus (1) strip XFF dari client, (2) append client IP pakai `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;` di Nginx; backend hanya percaya header jika request datang dari proxy tersangka (typo) — validasi di firewall/port.
- Envoy dalam kube: `xff_num_trusted_hops` — jumlah hop trusted.

### Host Header Injection
- Backend vhost/routing berdasarkan `Host:` — attacker set `Host: admin.internal` → routing salah/SSRF request internal.
- Perlindungan: allowlist host di server block (`server_name`), reject host tidak dikenal (default_server return 444).

## Request Smuggling (CL.TE / TE.CL)

Perbedaan parsing `Content-Length` vs `Transfer-Encoding` antara proxy & backend memungkinkan smuggling:
1. **CL.TE** — frontend pakai Content-Length, backend pakai Transfer-Encoding.
2. **TE.CL** — sebaliknya.
3. **TE.TE** — obfuscasi header TE (`Transfer-Encoding: xchunked`).
4. **HTTP/2 downgrade** — request di frontend HTTP/2 memiliki header rahasia (h2 smuggling), backend HTTP/1.1 membaca sebagai body.

Dampak: poison cache (cache poisoning), request to backend ter-blacklist/skip WAF, session hijack, SSRF.

### Mitigasi
- Update proxy (patch CVE-2023-36845? — sebenarnya FortiGate; untuk Nginx: bugfix berkala).
- Normalisasi header: reject duplicate Content-Length/TE, batasi nilai (Nginx: `http_version 1.0`? tidak — gunakan `chunked_transfer_encoding off` terkontrol).
- Gunakan proxy modern yang robust (Envoy lebih aman untuk HTTP/2 → 1.1 conversion: teduh config `normalize_path`, `merge_slashes`).
- Test: tools PortSwigger Smuggler, HTTP Request Smuggling Python script.

## Configuration Hardening (Nginx Example)

```nginx
# Reject unknown hosts
server { listen 80 default_server; server_name _; return 444; }

# TLS only + strong ciphers
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;

# Header sanitization
proxy_set_header X-Forwarded-For $remote_addr;  # jangan $proxy_add (append trustful saja)
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header Host $host;

# Limit request (DoS/mitm)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
client_max_body_size 1m;
client_body_timeout 5s;

# Security headers
add_header X-Frame-Options SAMEORIGIN always;
add_header X-Content-Type-Options nosniff always;
add_header Referrer-Policy strict-origin-when-cross-origin always;
add_header Content-Security-Policy "default-src 'self'" always;
```

## Logging & Observability di Proxy

- Log format: client IP (real, bukan spoofed), XFF, method, path, status, response time, upstream.
- Structured logs (JSON) → aggregator (ELK/Loki) → SIEM rules: rate anomalies, blocked request (WAF), 4xx spikes.
- Metrics: QPS, latency percentiles, upstream errors, cache hit ratio.
- Tracing: `X-Request-Id` injected di proxy → correlation end-to-end.
- Audit: log header authority untuk forensik.

## Purple Team Testing

### Attack (red)
1. Spoof `X-Forwarded-For: 127.0.0.1` → bypass rate limit / admin IP restriction.
2. Host header injection → route ke internal app.
3. Request smuggling (CL.TE/TE.CL) → poison cache / bypass WAF.
4. Cache poisoning: `X-Forwarded-Host`, `X-Original-URL`, path conflicting.
5. Path normalization: `//`, `%2e%2e`, `;` → routing bypass.
6. TLS misconfig: old protocol, weak cipher, cert issues.

### Defense (blue)
1. Strip & only-trust proxy headers dari trusted source.
2. Normalize headers: duplicate CL/TE reject; hash HSTS.
3. Cache key: sertakan scheme+host+path (jangan header tidak tepercaya).
4. Patch proxy rutin; subscribe security advisories (Nginx/Envoy/Caddy).
5. Test suite: regenerated payload smuggling + cache poisoning tiap rilis.

## Reference

- PortSwigger Web Security Academy — HTTP request smuggling.
- Nginx docs — ngx_http_proxy_module, limit_req, geo.
- Envoy docs — HTTP connection manager, request smuggling handling.
- OWASP — Server Side Request Forgery (SSRF) & proxy security.



## Studi Kasus: Request Smuggling Nyata

**H2.CL smuggling (PortSwigger 2021)** — frontend menerima HTTP/2 (tanpa CL/TE), backend HTTP/1.1 memproses body tersisa sebagai request baru. Dampak: bypass auth, poison cache, SSRF. Contoh CVE di server populer: CVE-2022-1388 (F5 BIG-IP iControl REST unauthenticated) — berkaitan dengan pemrosesan header internal.

**Mitigasi praktis:**
- Envoy sejak versi tertentu menolak request HTTP/2 dengan header CL (connection manager config `http2_protocol_options` + `stream_error_on_invalid_http_message`).
- Nginx: pastikan tidak ada TLS termination dengan HTTP/1.1 backend yang bisa di-smuggle — gunakan versi terbaru dan uji dengan toolkit.
- Selalu uji dengan payload CL.TE/TE.CL setelah upgrade proxy.

## Header Security di Proxy (Default Checklist)

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY (atau frame-ancestors via CSP)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Content-Security-Policy: (lihat [[csp-best-practices]])
```

Pastikan di semua response (error page, 404, static) — jangan cuma halaman utama.

## Proxy Logging untuk Forensik (Field Penting)

- `$remote_addr` (client real), `$http_x_forwarded_for`, `$host`, `$request_method`, `$request_uri`, `$status`, `$body_bytes_sent`, `$request_time`, `$upstream_addr`, `$upstream_status`, `$http_user_agent`, `$http_referer`.
- Simpan JSON ke buffer → daily rotation → archive 90+ hari.
- Anomali: request method aneh (CONNECT/TRACE), 4xx flood dari satu IP, pattern smuggling (CL+TE bersama), user-agent mencurigakan (sqlmap, nikto, nuclei).

---

  audited
---