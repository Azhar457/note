---
title: 'Rust Web Framework Comparison: Actix Web, Axum, dan Pingora dalam Konteks Production Proxy'
tags:
- software-engineering
- rust
- web-framework
- axum
- actix-web
- pingora
aliases:
- Rust Web Framework Comparison
- Actix vs Axum vs Pingora
- Web Framework Comparison
created: 2026-07-21
updated: 2026-07-21
status: pending
cssclasses:
  - wide-table
  - callout
---

# Rust Web Framework Comparison: Actix Web, Axum, dan Pingora dalam Konteks Production Proxy

> [!tip] Pengembangan aplikasi backend dan infrastruktur jaringan di Rust didominasi oleh tiga ekosistem besar: **Actix Web**, **Axum**, dan **Pingora**. Memilih framework yang tepat membutuhkan pemahaman mendalam tentang kebutuhan aplikasi (apakah itu server API tingkat tinggi, mikrososial asinkron, atau reverse proxy/WAF berkinerja ekstrem).

---

## 1. Profil & Filosofi Desain

```
┌────────────────────────────────────────────────────────────────────────┐
│                        RUST ECOSYSTEM FRAMEWORKS                       │
└──────────────┬─────────────────────┬─────────────────────┬─────────────┘
               │                     │                     │
               ▼                     ▼                     ▼
        [ Actix Web ]             [ Axum ]            [ Pingora ]
      Actor-based Model       Tokio-native / Tower   Service Engine / L7 Proxy
      High-level API          Flexible Router        Zero-copy, Pool Conn
```

### A. Actix Web (The Mature Champion)
*   **Arsitektur**: Menggunakan model *actor-based* (`actix` crate) di bawah kap mesin untuk manajemen concurrency, meskipun versi terbarunya telah menyembunyikan sebagian besar kompleksitas aktor di belakang handler asinkron biasa.
*   **Filosofi**: Framework berfitur lengkap (*opinionated*) yang menyediakan server HTTP mandiri, sistem routing bawaan, websocket support, dan engine middleware terintegrasi.
*   **Penggunaan Ideal**: Monolithic REST API, sistem microservices konvensional yang membutuhkan kestabilan tinggi.

### B. Axum (The Modern Tokio Ergonomic)
*   **Arsitektur**: Dibangun oleh tim pengembang **Tokio** (runtime asinkron standar Rust). Mengintegrasikan ekosistem **Tower** (middleware) dan **Hyper** (parser HTTP).
*   **Filosofi**: Sangat modular (*unopinionated*). Routing didasarkan pada makro extractor yang type-safe. Anda bebas memasangkan middleware apa pun dari ekosistem Tower.
*   **Penggunaan Ideal**: API Gateway, backend asinkron modern, dashboard real-time dengan WebSocket (seperti kontrol panel WAF).

### C. Pingora (The Production Proxy Engine)
*   **Arsitektur**: Dikembangkan oleh Cloudflare untuk menggantikan Nginx dalam melayani traffic global. Didesain khusus untuk bertindak sebagai proxy dan load balancer.
*   **Filosofi**: Bukan framework web umum. Fokus pada manipulasi header HTTP tingkat rendah, manajemen pooling koneksi TCP upstream, integrasi TLS/OpenSSL, dan zero-copy packet forwarding.
*   **Penggunaan Ideal**: Reverse proxy, WAF (seperti WAF), API load balancer, CDN edge nodes.

---

## 2. Perbandingan Fitur Utama (Comparison Matrix)

| Fitur / Parameter | Actix Web | Axum | Pingora |
|---|---|---|---|
| **Runtime Engine** | Custom Actix Runtime | Tokio | Tokio |
| **HTTP Parser** | Custom Parser | Hyper | Pingora-HTTP (Hyper-based) |
| **Model Concurrency** | OS Thread per Worker | Work-stealing Scheduler | Work-stealing Scheduler |
| **Manajemen Koneksi** | HTTP Keep-Alive biasa | HTTP Keep-Alive biasa | Upstream Connection Pool |
| **Overhead Memori** | Rendah (~15 MB idle) | Sangat Rendah (~10 MB idle) | Ekstrem Rendah (~5 MB idle) |
| **Maturity / Ekosistem** | Sangat Tinggi (Sejak 2017) | Tinggi | Sedang (Stabil untuk Proxy) |

---

## 3. Analisis Kualitatif: Mengapa WAF Memakai Pingora untuk L7 Proxy?

Meskipun Axum sangat mudah digunakan untuk membuat API Dashboard WAF, engine proxy utama (`proxy_engine.rs`) harus ditulis menggunakan **Pingora**. Berikut justifikasi teknisnya:

### A. Upstream Connection Pooling (Penting untuk Latensi)
Saat reverse proxy menerima request, ia harus membuka koneksi ke backend (misal: Node.js/Laravel).
*   **Axum/Actix**: Membuka dan menutup koneksi TCP baru (atau menggunakan client HTTP biasa yang overhead pooling-nya terbatas).
*   **Pingora**: Memiliki sistem pooling koneksi tingkat lanjut bawaan (*Keep-Alive connection pools* ke upstream). Ini mengeliminasi latensi jabat tangan TCP/TLS (*TCP handshake*) untuk request berikutnya, menghemat waktu $\approx 5\text{ ms} - 20\text{ ms}$ per transaksi.

### B. Zero-Copy Header Modification
Pingora memungkinkan kita membaca dan mengubah header HTTP (seperti menyuntikkan header `X-Forwarded-For` atau membersihkan payload aneh) langsung pada buffer mentah tanpa melakukan alokasi string baru (`String::clone()`). Ini mencegah pembuangan memori di hot path proxy.

### C. Graceful Reloading & Health Check
Pingora menyediakan struktur `Server` yang mendukung penggantian biner secara dinamis (*graceful upgrade*) tanpa memutuskan koneksi klien yang sedang aktif, serta sistem pengujian kesehatan upstream (*active/passive health checks*) yang berjalan di background thread.

---

## 4. Contoh Integrasi Hibrida: Axum + Pingora di WAF

WAF memanfaatkan kekuatan kedua framework tersebut secara bersamaan:

```
[ Incoming Traffic (Port 80/443) ] ──> [ Pingora Proxy Engine ] (Filtering & Routing)
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼ (Traffic Aplikasi Publik)                                   ▼ (Traffic Dashboard Kontrol)
       [ Upstream Web Servers ]                                        [ Axum Dashboard Engine ] (Port 8080)
```

1.  **Pingora** mendengarkan di port publik (`80` / `443`), menjalankan aturan WAF (`rules.rs`), menyaring serangan, dan meneruskan trafik aman ke backend.
2.  **Axum** mendengarkan di port internal (`8080`), menyediakan REST API untuk dashboard kontrol admin, dan melayani WebSocket koneksi untuk visualisasi peta serangan secara real-time.

---

## 🔗 Referensi & Catatan Terkait
- WAF architecture deepdive (privat) — Detail Implementasi Trait Pingora di WAF
- [[linux-performance-debugging-toolkit]] — Pemantauan Latensi Handshake TCP/TLS
- [[model-context-protocol-specification]] — Pengamanan API Endpoint Axum di WAF
---

audited
---
