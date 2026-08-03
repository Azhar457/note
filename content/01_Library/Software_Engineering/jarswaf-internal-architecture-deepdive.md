---
tags:
  - software-engineering
  - rust
  - proxy
  - waf
  - pingora
  - ebpf
  - wasmtime
  - onnx
aliases:
  - JarsWAF Internal Architecture
  - JarsWAF Deepdive
  - WAF Architecture
status: pending
created: 2026-07-21
updated: 2026-07-21
---

# JarsWAF: Arsitektur Internal High-Performance WAF Berbasis Pingora & eBPF

> [!tip] **JarsWAF** adalah Web Application Firewall (WAF) & L7 Reverse Proxy berkinerja tinggi untuk Homelab. Dirancang menggunakan **Rust + Pingora Engine (Cloudflare)** untuk hot path proxy, **eBPF XDP** via **Aya** untuk mitigasi DDoS kernel-space, **Wasmtime** untuk modul plugin sandboxing, serta **Tract-ONNX** untuk evaluasi model deteksi ancaman berbasis machine learning secara real-time.

---

## 1. Topologi Arsitektur Multilayer JarsWAF

JarsWAF membagi pertahanan menjadi beberapa layer untuk menyaring request dari level paket jaringan terendah hingga lapisan aplikasi teratas:

```
[ Incoming Network Packets ]
             │
             ▼ (Layer 2/3 - eBPF XDP) ──> DROP (DDoS Attack / IP Block)
     ┌──────────────────────┐
     │   jarswaf-ebpf (XDP) │
     └──────────┬───────────┘
                │
                ▼ (Layer 7 - Pingora Proxy)
     ┌──────────────────────┐
     │   proxy_engine.rs    │ <───> [ Wasmtime Runtime ] (Wasm Plugins)
     └──────────┬───────────┘
                │
                ├─> [ Rules Engine ] ──> AST Tokenizer & 300+ Regex Signatures
                ├─> [ Rate Limiter ] ──> Token Bucket (Local / Distributed Redis)
                ├─> [ RAG Validator ] ──> Query to Jina Reranker v3 (AI Anomaly)
                │
                ▼ (Zero-Copy Forwarding)
     [ Backends (Nginx/Laravel/LXC) ]
```

---

## 2. L7 Proxy Core: Pingora Integration

JarsWAF menggunakan framework **Pingora** dari Cloudflare untuk menggantikan Nginx sebagai engine reverse proxy utama. 

### Keunggulan Pingora dalam JarsWAF
*   **Asynchronous Multi-threading**: Dibangun di atas runtime **Tokio**, menangani jutaan koneksi konkuren dengan latensi sub-milidetik.
*   **Zero-Copy Proxying**: Header dan payload diteruskan langsung ke backend tanpa alokasi memori tambahan (*zero-copy forwarding*).
*   **Dynamic Reconfiguration**: Route virtual hosts (`vhost.rs`) dan backend pools dapat dimuat ulang secara dinamis tanpa me-restart proses proxy.

### Implementasi Hot Path Proxy (`src/proxy_engine.rs`)
Hot path proxy mengimplementasikan trait `ProxyHttp` dari Pingora:

```rust
use async_trait::async_trait;
use pingora_core::upstreams::peer::HttpPeer;
use pingora_proxy::{ProxyHttp, Session};
use std::sync::Arc;

pub struct JarsWafProxy {
    pub rules_engine: Arc<RulesEngine>,
    pub rate_limiter: Arc<RateLimiter>,
}

#[async_trait]
impl ProxyHttp for JarsWafProxy {
    type CTX = ();
    fn new_ctx(&self) -> Self::CTX {}

    async fn request_filter(&self, session: &mut Session, _ctx: &mut Self::CTX) -> pingora_core::Result<bool> {
        let req_header = session.req_header();
        
        // 1. Rate Limiting Check
        let ip = session.client_addr().map(|a| a.ip()).unwrap_or_else(|| "127.0.0.1".parse().unwrap());
        if !self.rate_limiter.check_rate(ip).await {
            session.respond_error(429).await?;
            return Ok(true); // Stop request propagation
        }

        // 2. Inspection: Rules Engine & AST Tokenizer
        let path = req_header.uri.path();
        let query = req_header.uri.query().unwrap_or("");
        
        if self.rules_engine.detect_attack(path, query) {
            session.respond_error(403).await?;
            return Ok(true); // Drop request (Forbidden)
        }

        Ok(false) // Continue request forwarding
    }

    async fn upstream_peer(&self, session: &mut Session, _ctx: &mut Self::CTX) -> pingora_core::Result<Box<HttpPeer>> {
        // Dynamic upstream selection
        let peer = Box::new(HttpPeer::new("127.0.0.1:8080", false, "".to_string()));
        Ok(peer)
    }
}
```

---

## 3. L3/L4 DDoS Mitigation: eBPF XDP (`jarswaf-ebpf`)

Untuk menangani serangan banjir paket (DDoS), JarsWAF mengintegrasikan program **eBPF XDP (eXpress Data Path)** menggunakan pustaka **Aya** Rust-native.

### Mekanisme Kerja
1.  Biner WAF utama bertindak sebagai userspace control plane yang memantau anomali koneksi.
2.  Jika anomali terdeteksi, IP penyerang didorong ke dalam **eBPF Map (Hash Map)**.
3.  Program XDP di kernel-space membandingkan IP paket yang masuk dengan isi map. Jika cocok, paket langsung dibuang dengan aksi `XDP_DROP` sebelum menyentuh stack jaringan Linux / CPU userspace.

```c
// Kode program kernel space jarswaf-ebpf
SEC("xdp")
int jarswaf_xdp_filter(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    // Parse IP Header
    struct ethhdr *eth = data;
    if ((void*)(eth + 1) > data_end) return XDP_PASS;
    
    if (eth->h_proto == bswap(ETH_P_IP)) {
        struct iphdr *ip = (void*)(eth + 1);
        if ((void*)(ip + 1) > data_end) return XDP_PASS;
        
        // Cek apakah IP pengirim diblokir dalam eBPF Map
        __u32 *blocked = bpf_map_lookup_elem(&BLOCKED_IPS_MAP, &ip->saddr);
        if (blocked) {
            return XDP_DROP; // Paket dibuang langsung di NIC driver level!
        }
    }
    return XDP_PASS;
}
```

---

## 4. Extensibility: Wasmtime Plugin Runtime & ML Engine

### A. Wasmtime Integration (Sandboxed Plugins)
JarsWAF memungkinkan developer membuat aturan filter kustom menggunakan bahasa apa pun (Rust, Go, TypeScript) yang dikompilasi ke WebAssembly (Wasm).
*   Menggunakan **Wasmtime v29** untuk isolasi runtime yang ketat (*sandboxed linear memory*).
*   Plugin dapat membaca request headers tanpa risiko merusak memory core JarsWAF (*no panic propagation*).

### B. Machine Learning Engine (Tract-ONNX)
Untuk mendeteksi ancaman non-signature (seperti pola kueri aneh), JarsWAF meload model deep learning eksternal menggunakan **Tract-ONNX**.
*   Model dievaluasi secara asinkron di dalam hot path proxy untuk memberikan klasifikasi skor anomali.

---

## 5. RAG Integration: Dynamic AI Threat Filter

Selain regex statis, JarsWAF dapat ditingkatkan untuk melakukan validasi payload mencurigakan yang lolos saringan regex dengan menembakkannya ke **RAG & Jina Reranker v3**.

```
[ Suspicious Payload ] ──> [ WAF RAG Database (SQLite-Vec) ]
                                      │
                                      ▼ (Akurasi Tinggi, Bebas False Positive)
                          [ Jina Reranker v3 ] ──> Score > 0.85 ──> Block IP
```

*   **Implementasi**: Payload request yang memiliki struktur anomali tinggi disimpan ke dalam RAG, diverifikasi menggunakan kueri semantik terhadap dokumen threat-signature database, lalu dinilai secara listwise menggunakan Jina Reranker v3. Jika terindikasi ancaman nyata, IP langsung didorong ke eBPF blocklist.

---

## 🔗 Referensi & Catatan Terkait
- [[linux-performance-debugging-toolkit]] — Toolkit Diagnosis Bottleneck untuk JarsWAF
- [[rust-web-framework-comparison-actix-axum-pingora]] — Perbandingan Actix vs Axum vs Pingora
- [[jina-reranker-v3-deepdive]] — Integrasi Jina Reranker v3 pada Security Filtering
- [[ebpf-runtime-security-auditing]] — SOP Audit System Calls dengan eBPF kprobe
