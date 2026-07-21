---
title: WASM Plugin System for WAF — Proxy-WASM & Sandboxed Extensibility
tags:
  - jarswaf
  - webassembly
  - proxy-wasm
  - sandboxing
  - rust
  - extensibility
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Menulis kode kustom langsung ke dalam data plane reverse proxy membutuhkan kompilasi ulang (recompilation) dan restart server yang memicu downtime. Catatan ini membahas arsitektur ekstensibilitas jarsWAF menggunakan plugin WebAssembly (WASM) berbasis spesifikasi **Proxy-WASM ABI**, melengkapi bahasan [[waf-reverse-proxy-deepdive]].

## Daftar Isi

1. [Spesifikasi Proxy-WASM ABI](#1-spesifikasi-proxy-wasm-abi)
2. [Menulis Filter WAF dengan Rust & Proxy-WASM SDK](#2-menulis-filter-waf-dengan-rust--proxy-wasm-sdk)
3. [Mekanisme Hot-Loading Tanpa Restart](#3-mekanisme-hot-loading-tanpa-restart)
4. [Isolasi Keamanan Sandbox WASM](#4-isolasi-keamanan-sandbox-wasm)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Spesifikasi Proxy-WASM ABI

**Proxy-WASM** adalah Application Binary Interface (ABI) standar yang mendefinisikan interaksi antara host proxy (seperti Envoy, Pingora, Nginx) dengan modul WASM eksternal. ABI ini memungkinkan modul WASM ditulis dalam bahasa apa pun (Rust, Go, C++) untuk di-load langsung di jalur request HTTP.

```
       Host Proxy (jarsWAF)                 WASM Virtual Machine
┌─────────────────────────────────┐       ┌──────────────────────┐
│  Request Header Received        │ ───>  │  on_http_request_h() │
│  (Host memory, raw pointers)    │       │  (Read request, filter)│
│                                 │       │                      │
│     *Proxy-WASM Host Functions* │       │  *Proxy-WASM Imports*│
│  - get_http_request_header()    │ <───  │  - get_header_val()  │
│  - resume_http_request()        │ <───  │  - block_action()    │
└─────────────────────────────────┘       └──────────────────────┘
```

---

## 2. Menulis Filter WAF dengan Rust & Proxy-WASM SDK

Berikut adalah contoh filter WAF sederhana berbasis Rust yang memindai header `X-Custom-Bypass` untuk mendeteksi bypassing upaya ilegal.

### 2.1 Konfigurasi `Cargo.toml`

Untuk meng-compile menjadi modul WASM, gunakan tipe library `cdylib`:

```toml
[package]
name = "jarswaf-custom-filter"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
proxy-wasm = "0.2.1" # SDK resmi Proxy-WASM untuk Rust
log = "0.4"
```

### 2.2 Kode Sumber Filter (`src/lib.rs`)

```rust
use log::info;
use proxy_wasm::traits::*;
use proxy_wasm::types::*;

proxy_wasm::main!({{
    proxy_wasm::set_log_level(LogLevel::Info);
    proxy_wasm::set_root_context(|_| -> Box<dyn RootContext> {
        Box::new(WafRootContext)
    });
}});

struct WafRootContext;

impl Context for WafRootContext {}

impl RootContext for WafRootContext {
    fn create_http_context(&self, _context_id: u32) -> Option<Box<dyn HttpContext>> {
        Some(Box::new(WafHttpContext))
    }

    fn get_type(&self) -> Option<ContextType> {
        Some(ContextType::HttpContext)
    }
}

struct WafHttpContext;

impl Context for WafHttpContext {}

impl HttpContext for WafHttpContext {
    fn on_http_request_headers(&mut self, _num_headers: usize, _end_of_stream: bool) -> Action {
        // Ambil header spesifik menggunakan SDK Proxy-WASM
        if let Some(bypass_val) = self.get_http_request_header("X-Custom-Bypass") {
            if bypass_val == "malicious-bypass-attempt" {
                info!("Modul WASM mendeteksi bypass ilegal. Memblokir request.");
                // Kirim respons 403 langsung dari Sandbox WASM
                self.send_http_response(
                    403,
                    vec![("Content-Type", "text/plain"), ("X-Protected-By", "jarsWAF-Wasm")],
                    Some(b"Forbidden: Malicious Bypass Attempt Blocked by WASM Filter.\n"),
                );
                return Action::Pause; // Hentikan pemrosesan request selanjutnya
            }
        }
        Action::Continue // Izinkan request diteruskan ke filter/upstream berikutnya
    }
}
```

### 2.3 Kompilasi Modul WASM

Lakukan kompilasi ke target arsitektur `wasm32-wasi` atau `wasm32-unknown-unknown`:

```bash
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
# Hasil biner berada di target/wasm32-wasi/release/jarswaf_custom_filter.wasm
```

---

## 3. Mekanisme Hot-Loading Tanpa Restart

Kemampuan utama dari arsitektur WASM di jarsWAF adalah **hot-loading**—memperbarui atau memuat filter kustom baru ke dalam memori tanpa mematikan koneksi TCP yang sedang aktif.

1. **File Watcher**: jarsWAF memantau direktori khusus `/var/lib/jarswaf/plugins/` untuk mendeteksi file `.wasm` baru atau yang dimodifikasi.
2. **Dynamic Instantiation**: Menggunakan runtime WASM (Wasmtime atau Wasmer), jarsWAF mengompilasi biner WASM baru ke mesin instruksi native (JIT) dan menginisialisasi instance engine virtual baru.
3. **Atomic State Transition**: Koneksi HTTP baru diarahkan ke instance virtual baru melalui mekanisme penukaran pointer atomik, sementara koneksi lama yang masih memproses request tetap dilayani oleh instance modul lama hingga selesai (_graceful draining_).

---

## 4. Isolasi Keamanan Sandbox WASM

Menjalankan kode pihak ketiga berisiko tinggi. Namun, WebAssembly memberikan isolasi yang kuat melalui pendekatan _software-based fault isolation_ (SFI):

- **Memory Sandboxing**: Modul WASM hanya memiliki akses ke memori linier miliknya sendiri yang didefinisikan oleh host. Modul WASM tidak dapat membaca atau menulis ke memori proses host jarsWAF (menghindari kerentanan _buffer overflow_ atau _out-of-bounds read_ pada level proxy).
- **System Call Restriction**: Secara default, WASM tidak memiliki akses ke sistem operasi (file system, network sockets, env vars). Semua interaksi harus melalui fungsi host yang dideklarasikan secara ketat dalam Proxy-WASM ABI. Modul filter tidak bisa membuka koneksi keluar sendiri tanpa izin host.
- **Resource Limits (Watchdog)**: Host membatasi konsumsi memori dan waktu eksekusi CPU modul WASM. Jika plugin WASM mengalami infinite loop, interpreter JIT host akan menghentikan eksekusi secara paksa setelah melewati alokasi instruksi maksimum (_gas limit_), mencegah serangan DoS internal.

---

## 5. Koneksi ke Vault

| Catatan                            | Hubungan                                                                           |
| ---------------------------------- | ---------------------------------------------------------------------------------- |
| [[waf-reverse-proxy-deepdive]]     | Platform proxy utama yang mengintegrasikan subsystem WASM runtime ini.             |
| [[platform-technologies-overview]] | Rincian arsitektur virtualisasi tingkat rendah dan perbandingan WASM vs Container. |
| [[jarswaf-plan]]                   | Rencana integrasi sistem plugin WASM sebagai prioritas #3.                         |
