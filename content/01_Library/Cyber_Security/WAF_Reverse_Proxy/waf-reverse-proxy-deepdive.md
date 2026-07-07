---
tags:
  - WAF
  - reverse-proxy
  - modsecurity
  - CRS
  - nginx
  - pingora
  - haproxy
  - envoy
  - api-gateway
  - rate-limiting
  - load-balancing
  - TLS
  - web-security
aliases:
  - WAF Deep Dive
  - Reverse Proxy Architecture
  - Web Application Firewall
  - API Gateway
  - Layer 7 Proxy
created: 2026-07-02
status: operational
cssclasses:
  - wide-table
title: Web Application Firewall & Reverse Proxy Deepdive
updated: "2026-07-02"
---

# 🛡️ WEB APPLICATION FIREWALL & REVERSE PROXY — Deep Dive: Dari ModSecurity sampai Pingora

> WAF dan Reverse Proxy adalah dua komponen yang **saling melengkapi** — Reverse Proxy mengatur lalu lintas di Layer 7 (routing, load balancing, TLS termination), sementara WAF menginspeksi dan memfilter konten berbahaya di dalam lalu lintas tersebut. Di era arsitektur mikroservis dan API-first, memahami keduanya secara bersamaan bukan lagi opsional — ini adalah **fondasi security infrastructure modern**. Dokumen ini membedah setiap aspek dari ModSecurity/CRS, Nginx/HAProxy/Envoy, Pingora, dan API Gateway, dari teori sampai implementasi.

> [!info] Hubungan ke Vault
> Ini adalah deep dive utama untuk WAF & Reverse Proxy ecosystem. Terkait erat dengan [[software-supply-chain-security-deepdive|Supply Chain Security]] (WAF rule lifecycle), [[web-hacking-exploitation|Web Hacking]] (attack vectors yang diblok WAF), [[cicd-shiftleft-shiftright|CI/CD Pipeline]] (WAF testing di pipeline), dan [[software-supply-chain-security-deepdive|SLSA framework]] (build provenance untuk WAF rules). Juga terhubung dengan custom WAF project [[Pingora vs jarsWAF|jarsWAF]] yang dibangun dengan Pingora.

---

## Daftar Isi

- [[#Arsitektur Reverse Proxy]]
- [[#Fungsi Reverse Proxy — Layer 4 vs Layer 7]]
- [[#Reverse Proxy]]
- [[#Pingora — Cloudflare Next-Gen Proxy Framework]]
- [[#Connection Pooling & Keep-Alive]]
- [[#Load Balancing Algorithms]]
- [[#TLS Termination & Certificate Management]]
- [[#WebSocket & HTTP/2 Proxying]]
- [[#Web Application Firewall — Arsitektur]]
- [[#ModSecurity — The Old Guard]]
- [[#OWASP CRS — Paranoia Level 0-4]]
- [[#WAF Detection vs Blocking Mode]]
- [[#Rule Engine Internals — Regex, Tokenizer, AST]]
- [[#WAF Bypass Techniques — Evasion 101]]
- [[#Normalization Engine]]
- [[#Rate Limiting Algorithms]]
- [[#API Gateway — Kong, APISIX, Tyk]]
- [[#Service Mesh & mTLS — Istio, Cilium, Linkerd]]
- [[#Observability & Logging]]
- [[#Deploy Pattern — Inline, Out-of-Band, Tap]]
- [[#Homelab Build]]
- [[#Perbandingan Tooling]]
- [[#Koneksi ke Project jarsWAF]]
- [[#Roadmap Belajar]]

---

## Arsitektur Reverse Proxy

```
                    INTERNET
                        │
                  ┌─────┴─────┐
                  │   DNS      │
                  └─────┬─────┘
                        │
                  ┌─────┴─────┐
                  │   CDN      │
                  │(Cloudflare)│
                  └─────┬─────┘
                        │
                  ┌─────┴─────┐
                  │   WAF      │ ◄─── Mode: Blocking / Detection
                  │ (ModSec)   │
                  └─────┬─────┘
                        │
                  ┌─────┴─────┐
                  │  Reverse   │
                  │   Proxy    │ ◄─── Routing, LB, TLS
                  └─────┬─────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
     ┌─────┴────┐ ┌─────┴────┐ ┌─────┴────┐
     │ Backend  │ │ Backend  │ │ Backend  │
     │  App 1   │ │  App 2   │ │  API     │
     └──────────┘ └──────────┘ └──────────┘
```

**Pola ini (CDN → WAF → Reverse Proxy → Backend) adalah standar industrial.**

---

## Fungsi Reverse Proxy — Layer 4 vs Layer 7

### Layer 4 (TCP/UDP)

```
FUNGSI:
  - Meneruskan koneksi berdasarkan IP + port
  - Tidak melihat isi paket HTTP
  - Lebih cepat (kernel-level forwarding)

CONTOH:
  HAProxy in TCP mode
  Nginx stream module
  iptables DNAT

USE CASE:
  - Load balancing database (MySQL read replica)
  - Game server forwarding
  - SSH gateway
  - Generic TCP tunnel
```

### Layer 7 (HTTP/HTTPS)

```
FUNGSI:
  - Inspeksi HTTP header, method, path, body
  - Routing berdasarkan Host, Path, Cookie, Header
  - TLS termination, rewriting, caching
  - Authentication passthrough (JWT, OAuth)
  - Rate limiting per endpoint

CONTOH:
  Nginx http context, HAProxy http mode
  Envoy, Traefik, Pingora, Kong

USE CASE:
  - Microservices API gateway
  - Single Page App routing
  - A/B testing (cookie-based canary)
  - WAF integration
```

| Aspek        | Layer 4                  | Layer 7                     |
| ------------ | ------------------------ | --------------------------- |
| Kecepatan    | 🟢 Sangat cepat (kernel) | 🟡 Lebih lambat (userspace) |
| Visibilitas  | ❌ Buta terhadap konten  | ✅ Full HTTP inspection     |
| Routing      | IP:Port                  | Host, Path, Header, Cookie  |
| TLS          | Passthrough              | Termination + re-encrypt    |
| Kompleksitas | Rendah                   | Tinggi                      |
| Use case     | DB, game, VPN            | Web apps, API, SPA          |

---

## Reverse Proxy: Nginx, HAProxy, Envoy, Traefik

### Nginx

```
KEKUATAN:
  - Mature (sejak 2004)
  - Konfigurasi declaratif
  - Event-driven, non-blocking
  - Ekosistem module besar (ModSecurity, ngx_lua, PageSpeed)
  - Static file serving terbaik

KELEMAHAN:
  - Hot reload kadang crash (graceful tapi tidak atomic)
  - Dynamic configuration terbatas (perlu Lua/OpenResty)
  - Load balancing sederhana (round-robin, least_conn, ip_hash)

KONFIGURASI DASAR:

server {
    listen 443 ssl http2;
    server_name app.example.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    location /api/ {
        proxy_pass http://backend_api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Rate limiting
        limit_req zone=api_limit burst=20 nodelay;
    }

    location / {
        proxy_pass http://frontend:8080;
    }
}
```

### HAProxy

```
KEKUATAN:
  - Paling cepat di antara proxy tradisional
  - Load balancing canggih (leastconn, uri, hdr, rdp-cookie)
  - Health check sangat granular (active + passive)
  - ACL engine powerful
  - Stats UI built-in

KELEMAHAN:
  - Konfigurasi verbose (tiap fitur butuh directive terpisah)
  - Tidak bisa serve static files
  - Ekosistem module terbatas

KONFIGURASI DASAR:

frontend web_front
    bind *:80
    bind *:443 ssl crt /etc/haproxy/certs/
    mode http

    # ACL-based routing
    acl is_api path_beg /api/
    acl is_static path_beg /static/

    use_backend api_servers if is_api
    use_backend static_servers if is_static
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 10.0.0.1:8080 check fall 3 rise 2
    server web2 10.0.0.2:8080 check fall 3 rise 2
```

### Envoy

```
KEKUATAN:
  - Service mesh native (Istio, Consul Connect)
  - xDS API untuk dynamic configuration
  - Filter chain architecture (L3-L7)
  - HTTP/2, gRPC, WebSocket native
  - Observability kelas dunia (access log, tracing, metrics)

KELEMAHAN:
  - Kompleksitas tinggi
  - Butuh control plane untuk dynamic config
  - Resource usage lebih besar dari Nginx/HAProxy

ARSITEKTUR FILTER:

Listener → Filter Chain → Network Filters (L4) → HTTP Filter Chain (L7)
                                                          │
                          ┌─────────────────────────────────┼─────────────────┐
                          │ Router │  RBAC │  Buffer │  Fault │  CORS │  WAF  │
                          └────────┴───────┴────────┴───────┴───────┴───────┘
```

### Traefik

```
KEKUATAN:
  - Auto-discovery (Docker, Kubernetes, Consul, etcd)
  - Let's Encrypt otomatis
  - Middleware chain (RateLimit, BasicAuth, CircuitBreaker, Retry)
  - Dashboard UI built-in
  - Konfigurasi via label/annotations

KELEMAHAN:
  - Performa di bawah Nginx/HAProxy pada high throughput
  - Kurang cocok untuk non-container deployment
  - Edukasi lebih sedikit karena relatif baru

KONFIGURASI DOCKER:

# docker-compose.yml
services:
  traefik:
    image: traefik:v3.0
    labels:
      - "traefik.http.routers.api.rule=Host(`app.example.com`)"
      - "traefik.http.services.api.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
      - "traefik.http.routers.api.middlewares=ratelimit@docker"
```

### Perbandingan

| Aspek          | Nginx       | HAProxy        | Envoy        | Traefik   |
| -------------- | ----------- | -------------- | ------------ | --------- |
| Performa       | 🟢          | 🟢🟢           | 🟡           | 🟡        |
| Dynamic Config | ❌ (native) | ❌             | ✅ xDS       | ✅        |
| Service Mesh   | ❌          | ❌             | ✅           | 🟡        |
| Let's Encrypt  | Plugin      | ❌ (3rd party) | ❌           | ✅ Native |
| WAF Module     | ModSecurity | ❌             | Wasm/Lua     | Plugin    |
| Hot Reload     | 🟡 SIGHUP   | 🟢 Graceful    | ✅ Lame duck | ✅ Native |
| Learning Curve | 🟢          | 🟢             | 🔴           | 🟢        |
| Static Files   | ✅ Best     | ❌             | ❌           | ❌        |
| gRPC           | 🟡          | 🟡             | ✅ Native    | ✅        |

---

## Pingora — Cloudflare Next-Gen Proxy Framework

```
PENGERTIAN:
  Pingora adalah FRAMEWORK (bukan aplikasi) untuk membangun proxy server
  di Rust, digunakan Cloudflare untuk menangani 40M+ request/detik.
  Bukan "Nginx killer" — melainkan "building block" untuk custom proxy.

ARSITEKTUR:
```

```
┌──────────────────────────────────────────────┐
│  Your Code (ProxyHttp trait implementation)   │
├──────────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐        │
│  │request_ │ │upstream_│ │response │ logging │
│  │filter   │ │peer     │ │filter   │         │
│  └─────────┘ └─────────┘ └─────────┘        │
├──────────────────────────────────────────────┤
│  Pingora Core                                 │
│  ├─ Async runtime (tokio-based)              │
│  ├─ Connection pooling (reuse: 90%+)         │
│  ├─ TLS (rustls + boringssl)                  │
│  ├─ HTTP/1.x, HTTP/2, WebSocket              │
│  └─ Load balancing + health check            │
├──────────────────────────────────────────────┤
│  TCP/TLS (via rustls, hyper, tokio)           │
└──────────────────────────────────────────────┘
```

### ProxyHttp Lifecycle

| Phase | Hook                  | Use Case                                          |
| ----- | --------------------- | ------------------------------------------------- |
| 1     | `request_filter`      | Blacklist IP, rate limit, fast signature check    |
| 2     | `upstream_peer`       | VHost routing, backend selection, SNI             |
| 3     | `upstream_filter`     | Inject headers (X-Forwarded-For), remove internal |
| 4     | `request_body_filter` | Body inspection, DLP, SQLi pattern                |
| 5     | `response_filter`     | Security headers, response body filter            |
| 6     | `logging`             | Async logging, metrics, audit trail               |
| 7     | `fail_to_connect`     | Backend failure handling, circuit breaker         |
| 8     | `error_response`      | Custom error page, challenge page                 |

### Kenapa Pingora?

```
KEUNGGULAN DARI CLOUDFLARE:
  - Connection reuse rate > 90% (dibanding ~70% Nginx)
  - Memory safety (Rust — no buffer overflow, use-after-free)
  - Full control atas tiap fase request
  - Zero-cost abstractions (Rust trait tanpa overhead runtime)
  - TLS via rustls (memory safe, no OpenSSL drama)

KEKURANGAN:
  - Harus coding Rust (tidak bisa konfigurasi via file)
  - Ekosistem module belum seluas Nginx
  - Dokumentasi masih terbatas
  - Tidak cocok untuk yang butuh quick config
```

### Minimal Pingora Proxy

```rust
use pingora::prelude::*;
use async_trait::async_trait;

struct MyProxy;

#[async_trait]
impl ProxyHttp for MyProxy {
    type CTX = ();
    fn new_ctx(&self) -> () { () }

    // Phase: routing
    async fn upstream_peer(&self, _session: &mut Session, _ctx: &mut ())
        -> Result<Box<HttpPeer>>
    {
        let peer = HttpPeer::new("127.0.0.1:8080", false, "myapp.local");
        Ok(Box::new(peer))
    }

    // Phase: block list
    async fn request_filter(&self, session: &mut Session, _ctx: &mut ())
        -> Result<bool>
    {
        let ip = session.client_addr();
        if ip.is_loopback() {
            return Ok(true); // block
        }
        Ok(false) // allow
    }
}

#[tokio::main]
async fn main() {
    let mut server = Server::new(Some(Opt::default())).unwrap();
    server.bootstrap();
    let mut lb = load_balancer::RoundRobin::new(&["https://backend:443"]).unwrap();
    server.add_service(lb);
    server.run_forever();
}
```

---

## Connection Pooling & Keep-Alive

```
MASALAH:
  Setiap request ke backend = buka koneksi TCP baru
  → 3-way handshake (1 RTT) + TLS handshake (2 RTT)
  → Latensi tambahan 2-3 RTT per request

SOLUSI: Connection Pool
  Reverse proxy maintain pool koneksi ke backend
  Request复用 koneksi yang sudah ada
```

### Pooling Strategies

| Strategy               | Cara Kerja                                                 | Cocok Untuk        |
| ---------------------- | ---------------------------------------------------------- | ------------------ |
| **Keep-Alive timeout** | Koneksi tetap hidup selama N detik setelah request selesai | General            |
| **Max connections**    | Batasi total koneksi per backend (mencegah overload)       | High traffic       |
| **Max idle**           | Pertahankan N idle koneksi siap pakai                      | Flash traffic      |
| **Connection TTL**     | Reset koneksi setelah N detik (untuk load distribution)    | Long-lived         |
| **LIFO pool**          | Last-In-First-Out — reuse koneksi terbaru                  | Consistent latency |

### Pingora Connection Pool

```rust
// Pingora connection reuse out-of-the-box
// Konfigurasi default sudah optimal
HttpPeer::new("backend:8080", false, "hostname")

// Dengan connection timeout
HttpPeer::new("backend:8080", false, "hostname")
    .set_connection_timeout(Some(Duration::from_secs(5)))
```

### Nginx Keep-Alive

```nginx
upstream backend {
    server 10.0.0.1:8080;
    keepalive 32;                 # max idle koneksi
    keepalive_requests 1000;      # reset setelah 1000 req
    keepalive_timeout 60s;        # idle timeout
}

server {
    location / {
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_pass http://backend;
    }
}
```

---

## Load Balancing Algorithms

| Algorithm             | Cara Kerja                                     | Use Case                      |
| --------------------- | ---------------------------------------------- | ----------------------------- |
| **Round Robin**       | Giliran rata ke tiap backend                   | Backend uniform, simple       |
| **Least Connections** | Kirim ke backend dengan koneksi paling sedikit | Backend heterogeneous         |
| **IP Hash**           | Hash IP client → backend tetap                 | Session sticky (tanpa cookie) |
| **URI Hash**          | Hash URL → backend tetap                       | Cache hit ratio tinggi        |
| **Weighted**          | Bobot berbeda per backend                      | Kapasitas backend berbeda     |
| **Random**            | Random selection                               | Testing, canary               |
| **Least Time**        | Kirim ke backend dengan response time terendah | Latency-sensitive             |

```
IMPLEMENTASI DI PINGORA:
  Pingora punya pingora-load-balancing crate:
  - RoundRobin
  - LeastConnected (default karena paling optimal)
  - Ketemu: pingora-load-balancing/src/lib.rs di source
```

---

## TLS Termination & Certificate Management

### TLS Termination vs Passthrough

```
TLS TERMINATION:
  Reverse Proxy → decrypt TLS → inspeksi HTTP → re-encrypt ke backend
  ✅ WAF bisa inspect request body
  ✅ Header manipulation (X-Forwarded-*)
  ✅ Backend tidak perlu handle TLS
  ❌ Proxy bisa lihat plaintext (internal trust required)

TLS PASSTHROUGH:
  Proxy → forward TLS stream tanpa decrypt
  ✅ Backend handle sendiri TLS (end-to-end encryption)
  ❌ WAF tidak bisa inspect content (hanya IP/port)
  ❌ Tidak bisa routing berdasarkan HTTP header

HYBRID (rekomendasi):
  TLS termination di proxy → WAF inspect → backend via mTLS
  ✅ WAF bisa inspect
  ✅ Backend-to-proxy traffic aman (mTLS)
  ✅ Backend tidak perlu public cert
```

### ACME Auto-Provision (Let's Encrypt)

```nginx
# Nginx + certbot
server {
    listen 80;
    server_name app.example.com;
    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }
}

# Setelah certbot
server {
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;
}
```

```yaml
# Traefik — otomatis
labels:
  - "traefik.http.routers.app.tls.certResolver=letsencrypt"
```

---

## WebSocket & HTTP/2 Proxying

### WebSocket

```
CHALLENGE:
  WebSocket = long-lived connection, bidirectional
  Proxy harus support upgrade handshake + keep connection open

SOLUSI:
  - Nginx: proxy_set_header Upgrade + Connection
  - HAProxy: option http-server-close + timeout tunnel
  - Pingora: WebSocket support built-in (async)
  - Envoy: native WebSocket via HTTP filter
```

```nginx
# Nginx WebSocket proxy
location /ws/ {
    proxy_pass http://ws_backend:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400s;  # long-lived
}
```

### HTTP/2

```
KEUNTUNGAN:
  - Multiplexing: banyak stream dalam satu koneksi
  - Header compression (HPACK)
  - Server push
  - Binary protocol (lebih efisien parse)

CATATAN:
  - HTTP/2 antara client→proxy
  - HTTP/1.1 antara proxy→backend (kecuali backend support h2c)
  - Pingora: HTTP/2 built-in
  - Envoy: HTTP/2 antara proxy→backend via `http2_protocol_options`
```

---

## Web Application Firewall — Arsitektur

```
LOKASI WAF DALAM STACK:

                  ┌──────────────────┐
                  │    INTERNET      │
                  └────────┬─────────┘
                           │
                  ┌────────▼─────────┐
         ┌───────│  REVERSE PROXY    │───────┐
         │       │  (routing, TLS)   │       │
         │       └────────┬─────────┘       │
         │                │                  │
         │       ┌────────▼─────────┐       │
         │       │   WAF ENGINE      │       │
         │       │  ┌─────────────┐  │       │
         │       │  │Normalisasi  │  │       │
         │       │  └──────┬──────┘  │       │
         │       │  ┌──────▼──────┐  │       │
         │       │  │ Rule Engine │  │       │
         │       │  │ PL0-PL4     │  │       │
         │       │  └──────┬──────┘  │       │
         │       │  ┌──────▼──────┐  │       │
         │       │  │ Anomaly     │  │       │
         │       │  │ Scoring     │  │       │
         │       │  └──────┬──────┘  │       │
         │       └────────┬─────────┘       │
         │                │                  │
         │       ┌────────▼─────────┐       │
         │       │    BACKEND       │       │
         │       └──────────────────┘       │
         │                                  │
         └──────────────────────────────────┘
```

### Modes

| Mode          | Deskripsi                     | Use Case                |
| ------------- | ----------------------------- | ----------------------- |
| **Detection** | Log & alert, tidak block      | Tuning, monitoring awal |
| **Blocking**  | Block request yang match rule | Produksi stabil         |
| **Learning**  | Auto-learn traffic pattern    | ML-based WAF            |
| **Bypass**    | Nonaktif sementara            | Emergency, debugging    |

---

## ModSecurity — The Old Guard

```
SEJARAH:
  - 2002: Dibuat Ivan Ristić (Breach Security)
  - 2012: Trustwave akuisisi → open source core diabaikan
  - 2022: Trustwave merilis versi "closed source" (ModSecurity 3)
  - 2024: OWASP dan komunitas fork → "ModSecurity Core" (open)

SAAT INI (2026):
  - ModSecurity 2.x (Apache module, Nginx via第三方) — mature
  - ModSecurity 3 (libmodsecurity) — rewritten, performa lebih baik
  - CRS (Core Rule Set) v4.28 — standar de facto WAF rules
  - Alternatif: Coraza (Go), Pingora (Rust), lua-resty-waf (OpenResty)
```

### Arsitektur ModSecurity

```
REQUEST FLOW:

  Request → Phase 1 (Request Headers)
             ↓
           Phase 2 (Request Body)
             ↓
           Phase 3 (Response Headers)
             ↓
           Phase 4 (Response Body)
             ↓
           Phase 5 (Logging)
             ↓
  Response/Block/Pass

TIAP PHASE:
  - SecRules berjalan di phase tertentu
  - Rules bisa skip (skipAfter), chain, atau disrupt (deny, redirect, pass)
  - Anomaly scoring: akumulasi skor per request
  - Threshold: block jika skor > ambang batas
```

### Konfigurasi Dasar

```nginx
# Nginx + ModSecurity
server {
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/main.conf;
}
```

```apache
# main.conf
SecRuleEngine On

# Detection mode — log only, no blocking
# SecRuleEngine DetectionOnly

# Anomaly scoring
SecDefaultAction "phase:1,pass,log,tag:'Inbound'"
SecDefaultAction "phase:2,pass,log,tag:'Inbound'"

# CRS inclusion
Include /etc/nginx/modsec/crs/crs-setup.conf.example
Include /etc/nginx/modsec/crs/rules/*.conf
```

---

## OWASP CRS — Paranoia Level 0-4

```
CRS v4.28 — 700+ rules, terbagi dalam 4 paranoia level:

PL0: Rules dasar — tidak ada false positive (hanya aturan framework)
     Contoh: initialization, exclusion rules

PL1: Rules agresif — false positive minimal
     Contoh: SQLi dasar, XSS dasar, LFI, RFI, RCE
     → Recommended untuk produksi

PL2: Rules lebih ketat — false positive moderate
     Contoh: SQLi bypass lanjutan, XSS encoding, path traversal
     → Cocok untuk aplikasi internal

PL3: Rules sangat ketat — butuh tuning
     Contoh: out-of-band detection, chained rules
     → Untuk high-security environment

PL4: Rules paranoid — false positive tinggi
     Contoh: semua karakter non-ASCII = suspicious
     → Hanya untuk militer/classified
```

### Anomaly Scoring System

```
Setiap rule yang match memberikan skor:

TIPE SKOR:
  - Critical:   5 skor (SQLi, RCE, LFI)
  - Error:      4 skor (Java attack, session fixation)
  - Warning:    3 skor (XSS, RFI)
  - Notice:     2 skor (scanner detection, protocol violation)

THRESHOLD:
  - Inbound Anomaly Score: 5-10 (default: block jika > 5)
  - Outbound Anomaly Score: 4-5 (block jika > 4)

KEUNTUNGAN:
  - Satu request bisa match multiple rules → akumulasi
  - False positive langka tidak langsung block
  - Paranoia level naik = threshold tetap → lebih banyak rule match
```

### Rule Categories

| File Prefix | Kategori             | Jumlah Rule |
| ----------- | -------------------- | ----------- |
| REQUEST-901 | Initialization       | Framework   |
| REQUEST-905 | Common Exceptions    | Whitelist   |
| REQUEST-911 | Method Enforcement   | 9           |
| REQUEST-913 | Scanner Detection    | 9           |
| REQUEST-920 | Protocol Enforcement | 97          |
| REQUEST-921 | Protocol Attack      | 22          |
| REQUEST-922 | Multipart Attack     | 6           |
| REQUEST-930 | LFI                  | 14          |
| REQUEST-931 | RFI                  | 10          |
| REQUEST-932 | RCE                  | 59          |
| REQUEST-933 | PHP Attack           | 27          |
| REQUEST-934 | Generic Injection    | 19          |
| REQUEST-941 | XSS                  | 33          |
| REQUEST-942 | SQLi                 | 65          |
| REQUEST-943 | Session Fixation     | 12          |
| REQUEST-944 | Java Attack          | 23          |
| REQUEST-949 | Blocking Evaluation  | 27          |

---

## WAF Detection vs Blocking Mode

### Detection Mode (Log Only)

```
KEUNTUNGAN:
  - Aman untuk deploy pertama (tidak ada false positive block)
  - Bisa analisis traffic real untuk tuning
  - Metrics: request yang akan di-block jika mode blocking

IMPLEMENTASI:
SecRuleEngine DetectionOnly
# atau di CRS:
SecDefaultAction "phase:1,pass,log"
```

### Blocking Mode

```
IMPLEMENTASI:
SecRuleEngine On
# atau dengan threshold:
SecAction "id:900001,phase:1,pass,nolog,setvar:tx.blocking_threshold=5"
```

### Rekomendasi Transisi

```
Minggu 1-2: DetectionOnly → log analysis → tune exclusion rules
Minggu 3:   Blocking PL1 → monitor false positive
Minggu 4:   Blocking PL1 + specific PL2 rules
Bulan 2:    Blocking PL2 → monitor
Bulan 3+:   PL3 selective untuk critical endpoints

JANGAN PERNAH langsung PL4 di produksi.
```

---

## Rule Engine Internals — Regex, Tokenizer, AST

### Regex-Based Detection

```
KEKUATAN:
  - Cepat untuk pattern sederhana
  - Mudah di-debug
  - Portabel

KELEMAHAN:
  - Catastrophic backtracking (ReDoS)
  - Tidak bisa detect logical structure (SQL grammar)
  - Encoding bypass sulit

CONTOH (CRS SQLi detection):

# Detect UNION-based injection
SecRule ARGS "@rx (?i)(\bunion\b.{0,100}?\bselect\b)" \
    "id:942200,phase:2,block,msg:'SQL Injection: UNION attack detected'"
```

### Tokenizer/AST-Based Detection

```
KEKUATAN:
  - Parse input sebagai grammar → deteksi anomaly
  - Tidak kena encoding bypass (parse setelah normalisasi)
  - False positive lebih rendah

CONTOH (libinjection approach):
  Input:  1' OR '1'='1
  Token:  [NUM] [OP] [STR] [OP] [STR]
  Tree:   Comparison(1, OR, Comparison('1', =, '1'))
  Verdict: SQLi (score: 0.98)

IMPLEMENTASI DI JARSWAF:
  jarsWAF punya AST semantic tokenizer di rule engine.
  Ini lebih advanced dari CRS regex-only.
```

### Hybrid Approach (Best Practice)

```
┌─────────────┐
│ Input        │
└──────┬──────┘
       ↓
┌─────────────┐
│ Normalisasi  │ ← recursive decode, Unicode normalize, lowercase
└──────┬──────┘
       ↓
   ┌───┴───┐
   │       │
   ↓       ↓
┌────────┐ ┌─────────┐
│ Regex  │ │ Tokenize│ ← parallel
│ Fast   │ │ AST     │
│ Rules  │ │ Deep    │
└───┬────┘ └────┬────┘
   │            │
   └────┬───────┘
        ↓
┌─────────────┐
│ Anomaly     │
│ Scoring     │
│ & Decision  │
└─────────────┘
```

---

## WAF Bypass Techniques — Evasion 101

### Encoding Bypass

```
TEKNIK:
  - Double URL encode: %253c → %3c → <
  - Unicode encoding: %uff1c → < (UTF-16)
  - Mixed case: SeLeCt * FrOm
  - NULL byte injection: select%00from
  - HTML entity: &lt;script&gt;

MITIGASI:
  - Recursive URL decode (jarsWAF: malicious input normalisation)
  - Unicode normalization (NFKC)
  - Case normalization
```

### HTTP Parameter Pollution (HPP)

```
TEKNIK:
  ?id=1&id=1' OR '1'='1
  → Backend bisa parse parameter berbeda dari WAF

MITIGASI:
  - WAF harus tahu bagaimana backend parse parameter
  - Test: parameter terakhir vs pertama yang dipakai?

### HTTP Smuggling

TEKNIK:
  CL.TE: Content-Length vs Transfer-Encoding beda interpretasi
  WAF lihat Content-Length (body aman)
  Backend lihat Transfer-Encoding (body = request kedua berbahaya)

MITIGASI:
  - HTTP/2 (hilangkan ambiguity)
  - Normalize TE header
  - Pingora/Envoy: strictly follow RFC
```

### Logic Bypass

```
TEKNIK:
  WAF mendeteksi pattern, tapi attacker bypass dengan logika:
  - Menggunakan fungsi database yang legitimate
  - Time-based blind (no visible payload)
  - Out-of-band (DNS exfil — WAF harus inspect DNS)

MITIGASI:
  - Behavioral detection (bukan cuma signature)
  - Rate limiting untuk brute force
  - Outbound connection monitoring
```

---

## Normalization Engine

```
PROSES NORMALISASI:

Input Raw → URL Decode → HTML Entity Decode → Unicode NFKC → Lowercase → Trim
     ↓           ↓              ↓                   ↓             ↓        ↓
  %253c        %3c            &lt;               \u003c         <         <

HASIL AKHIR: semua variant input → bentuk kanonikal → rule matching

PENTING:
  - Urutan normalisasi mempengaruhi deteksi
  - NFKC normalize: ℜ (1 karakter) → R + e (2 karakter) → tetap terdeteksi
  - Recursive decode: ulang hingga tidak ada perubahan (max 5 iterasi)
```

---

## Rate Limiting Algorithms

### Token Bucket

```
PRINSIP:
  - Bucket: kapasitas maksimal token
  - Rate: token per detik
  - Request: ambil 1 token
  - Jika bucket kosong → block

COCOK UNTUK:
  - Burst traffic (bucket absorbs burst)
  - Rata-rata stabil

IMPLEMENTASI JARSWAF:
  // rules.rs: TokenBucket
  fn check_rate_limit_token(ip: &str, rate: u64, burst: u64) -> bool {
      // waktu sekarang → hitung token yang direfill
      // jika token >= 1 → allow, kurangi bucket
      // jika token < 1 → block
  }
```

### Leaky Bucket

```
PRINSIP:
  - Queue: request antri (bisa overflow)
  - Rate: process rate tetap
  - Overflow → drop

COCOK UNTUK:
  - Processing rate yang predictable
  - Backend protection (tidak overload)
```

### Sliding Window

```
PRINSIP:
  - Window: N detik (misal 60s)
  - Counter: jumlah request dalam window
  - Setiap detik, window geser

COCOK UNTUK:
  - API rate limiting granular
  - Lebih akurat dari fixed window (tidak ada spike di reset)
```

### Rate Limiting Placement

```
LAYER 4: iptables + connlimit → block by IP:PORT
LAYER 7: WAF / Reverse Proxy → block by path, token, session
APPLICATION: Backend logic → block by user tier, feature flag

JANGAN cuma andalkan satu layer.
Rate limiting di proxy + backend + WAF.
```

---

## API Gateway — Kong, APISIX, Tyk

```
API GATEWAY = Reverse Proxy + WAF + Rate Limiting + Auth + Transformation

FITUR UMUM:
  - Authentication (JWT, OAuth2, API Key, OIDC)
  - Rate limiting & quota management
  - Request/response transformation
  - API versioning
  - Developer portal
  - Analytics & billing
```

### Perbandingan API Gateway

| Aspek       | Kong               | APISIX                  | Tyk              |
| ----------- | ------------------ | ----------------------- | ---------------- |
| Engine      | Nginx + Lua        | Nginx + Lua             | Go (native)      |
| Plugin      | 200+               | 100+                    | 50+              |
| Performance | 🟡                 | 🟢                      | 🟡               |
| WAF         | ModSecurity plugin | ModSecurity + WASM      | Custom           |
| Discovery   | DNS, Consul, K8s   | DNS, Consul, Nacos, K8s | DNS, Consul, K8s |
| Hot Reload  | 🟡                 | 🟢 Atomic               | 🟢               |
| Cost        | Open Source + EE   | Open Source             | Open Source + EE |

---

## Service Mesh & mTLS — Istio, Cilium, Linkerd

```
SERVICE MESH = Reverse Proxy + Security + Observability per-service

ARSITEKTUR:
  Sidecar proxy (Envoy) → inject di tiap pod/container
  Control plane → konfigurasi semua sidecar
  mTLS → encrypt traffic antar service
  WAF/Policy → OPA, Kyverno
```

### Istio

```yaml
# AuthorizationPolicy — WAF-like rules
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata: name: waf-policy
spec:
  rules:
  - to:
    - operation:
        paths: ["/api/*"]
        methods: ["POST"]
    when:
    - key: request.headers[X-Forwarded-For]
      notValues: ["*external*"]
```

### Cilium (eBPF-based)

```
CILIUM MENGGUNAKAN eBPF → performa kernel-level:
  - NetworkPolicy via eBPF (lebih cepat dari iptables)
  - mTLS via envoy (opsional, bisa pure eBPF)
  - WAF via Tetragon (eBPF-based security observability)

KONEKSI KE JARSWAF:
  jarsWAF punya eBPF XDP drop module (/jarswaf-ebpf)
  Ini mirror dari Cilium concept — DDoS mitigation di kernel
```

---

## Observability & Logging

### Metrics Penting

| Metric                 | Arti                    | Alert Threshold |
| ---------------------- | ----------------------- | --------------- |
| `waf.requests.total`   | Total request           | N/A (baseline)  |
| `waf.blocked.count`    | Request diblok          | Spike > 200%    |
| `waf.anomaly_score`    | Rata-rata anomaly score | > 3             |
| `waf.latency`          | WAF processing time     | > 50ms          |
| `waf.false_positive`   | False positive rate     | > 1%            |
| `upstream.5xx`         | Backend error           | > 1%            |
| `upstream.latency.p99` | Backend latency         | > 500ms         |

### Log Format (JSON)

```json
{
  "timestamp": "2026-07-02T12:00:00Z",
  "client_ip": "203.0.113.1",
  "method": "POST",
  "path": "/api/login",
  "status": 403,
  "blocked": true,
  "anomaly_score": 15,
  "matched_rules": [
    { "id": 942100, "msg": "SQL Injection", "paranoia": "PL1", "severity": "CRITICAL" },
    { "id": 941100, "msg": "XSS Detection", "paranoia": "PL1", "severity": "CRITICAL" }
  ],
  "upstream_latency_ms": 0,
  "waf_latency_ms": 2.3
}
```

---

## Deploy Pattern — Inline, Out-of-Band, Tap

| Pattern         | Deskripsi                    | Kelebihan              | Kekurangan           |
| --------------- | ---------------------------- | ---------------------- | -------------------- |
| **Inline**      | WAF di path request langsung | Block real-time        | Latency added, SPoF  |
| **Out-of-Band** | Mirror traffic ke WAF        | No latency impact      | Tidak bisa block     |
| **Tap/Passive** | Copy traffic via network TAP | Forensik saja          | Detection only       |
| **API-based**   | Backend panggil WAF API      | Granular, per-endpoint | Butuh modifikasi app |

### Rekomendasi

```
PRODUKSI:  Inline + Out-of-Band (detection) paralel
           Inline: PL1 blocking → proteksi dasar
           Out-of-band: PL3 detection → analisis false positive
HOMELAB:   Inline PL1 → langsung berguna
```

---

## Homelab Build: Nginx + ModSecurity + CRS

```bash
# 1. Install Nginx + ModSecurity
sudo apt install nginx libnginx-mod-modsecurity

# 2. Download CRS
cd /etc/nginx/modsec
sudo git clone https://github.com/coreruleset/coreruleset.git
sudo cp coreruleset/crs-setup.conf.example crs-setup.conf

# 3. Konfigurasi CRS
sudo tee -a /etc/nginx/modsec/main.conf << 'EOF'
SecRuleEngine DetectionOnly
Include /etc/nginx/modsec/crs-setup.conf
Include /etc/nginx/modsec/coreruleset/rules/*.conf
EOF

# 4. Aktifkan di site
sudo tee /etc/nginx/sites-available/waf-site << 'EOF'
server {
    listen 80;
    server_name app.example.com;

    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/main.conf;

    location / {
        proxy_pass http://localhost:3000;
    }
}
EOF

# 5. Test
#   curl -H "Host: app.example.com" http://localhost/?id=1'+OR+'1'='1
#   tail -f /var/log/modsec_audit.log
```

---

## Perbandingan Tooling

### WAF Engine

| Engine          | Bahasa   | Performa | Ekosistem          | Aktif     |
| --------------- | -------- | -------- | ------------------ | --------- |
| ModSecurity 2.x | C        | 🟡       | CRS terbesar       | 🟡 Legacy |
| ModSecurity 3   | C++      | 🟢       | CRS                | 🟢        |
| **Coraza**      | **Go**   | 🟢       | **CRS compatible** | **🟢🟢**  |
| **jarsWAF**     | **Rust** | **🟢🟢** | **Custom rules**   | **🟢**    |
| lua-resty-waf   | Lua      | 🟢       | Limited            | 🟡        |
| Naxsi           | C        | 🟢       | Own rule format    | 🟡        |

### Reverse Proxy

| Tool        | Bahasa   | Throughput      | Config       | Use Case         |
| ----------- | -------- | --------------- | ------------ | ---------------- |
| Nginx       | C        | 100K req/s      | Static files | General web      |
| HAProxy     | C        | 150K req/s      | TCP/HTTP     | Load balancer    |
| Envoy       | C++      | 80K req/s       | Dynamic/xDS  | Service mesh     |
| Traefik     | Go       | 40K req/s       | Auto         | K8s native       |
| **Pingora** | **Rust** | **200K+ req/s** | **Code**     | **Custom proxy** |

---

## Koneksi ke Project jarsWAF

```
JARSWAF MENGGUNAKAN:
  - Pingora sebagai reverse proxy framework (ProxyHttp trait)
  - Tokenizer AST untuk SQLi/XSS detection (advanced dari CRS regex)
  - eBPF XDP untuk DDoS mitigation di kernel
  - Token bucket rate limiting
  - GeoIP blocking via MaxMind
  - CRS rules bisa diintegrasikan sebagai signature layer

PERBEDAAN JARSWAF DARI WAF TRADISIONAL:
  - Memory safe (Rust > C/CPP)
  - AST semantic parser > regex-only (false positive lebih rendah)
  - Connection reuse Pingora > 90% (lebih efisien dari Nginx)
  - eBPF XDP drop di kernel level
```

### Integrasi CRS ke jarsWAF

```
CRS rules (ModSecurity SecRule format) bisa di-parse dan dikonversi
ke format jarsWAF. Strategi:
  1. Parse .conf → extract id, msg, pattern, phase, paranoia
  2. Simpan di HashMap<RuleId, RuleConfig>
  3. Load saat runtime dengan ArcSwap (lock-free update)
  4. Match menggunakan regex engine Rust (regex crate) + custom AST untuk kompleks

waf-knowledge MCP server sudah mengindex 382 CRS rules untuk
referensi cepat saat develop jarsWAF.
```

---

## Roadmap Belajar

```
HARI 1: Fundamentals
  - Baca dokumen ini sampai selesai
  - Setup Nginx + ModSecurity + CRS di homelab (docker)
  - Mode DetectionOnly → inject SQLi → lihat log

HARI 2: Deep Dive WAF
  - Pelajari CRS rule format (buka REQUEST-942-*.conf)
  - Tes bypass techniques (encoding, HPP, smuggling)
  - Pahami anomaly scoring system

HARI 3: Reverse Proxy Architecture
  - Bandingkan Nginx vs HAProxy vs Envoy di homelab
  - Setup TLS + ACME
  - Pelajari connection pooling metrics

HARI 4: API Gateway & Service Mesh
  - Deploy Kong/APISIX (docker compose)
  - Setup rate limiting + JWT auth
  - Baca Istio AuthorizationPolicy

HARI 5: Build & Operasi
  - Implementasi custom WAF rule (dari atau untuk jarsWAF)
  - Metrics + monitoring (Prometheus)
  - Tuning CRS: exclusion rules, false positive handling
```

> [!warning] Bottom Line
> WAF tanpa tuning adalah **noise generator**. CRS PL1 adalah starting point yang baik, tapi butuh 2-4 minggu monitoring untuk mencapai false positive rate < 0.1%. Reverse proxy bukan sekadar "forwarder" — ia adalah titik kontrol strategis untuk security, observability, dan reliability. Kombinasi **Pingora (kecepatan) + jarsWAF (AST detection) + CRS (signature) + eBPF (kernel-level)** adalah stack modern yang memanfaatkan kelebihan tiap pendekatan.

> [!tip] Lanjutan
> Dokumen ini terkait dengan:
>
> - [[software-supply-chain-security-deepdive]] — SBOM & SLSA untuk WAF rules
> - [[web-hacking-exploitation]] — attack vectors yang dicegat WAF
> - [[cicd-shiftleft-shiftright]] — CI/CD testing WAF rules
> - [[ebpf-kernel-security]] — eBPF connection dengan XDP/jarsWAF
