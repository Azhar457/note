---
title: "Rust Systems Programming untuk Tooling Keamanan"
tags:
  - rust
  - systems-programming
  - security-tooling
  - no-std
  - wasm
aliases:
  - "rust-security-tooling"
  - "rust-systems-programming"
  - "rust-untuk-pentest"
created: "2026-07-15"
updated: "2026-07-15"
status: draft
cssclasses:
  - wide-table
---

> [!abstract] Bahasa Baru untuk Tooling Baru
> Python bagus buat prototyping, tapi untuk tooling security yang butuh performance, low-level access, atau cross-compilation — Rust makin dominan. Ripgrep, fd, bottom, Firecracker, Pingora, bahkan sebagian kernel Linux udah mulai pake Rust. Catatan ini: dari setup toolchain sampai bikin network tool sederhana.

---

## 🦀 1. Kenapa Rust buat Security Tooling?

| Bahasa     | Kelebihan                            | Kelemahan                          |
| ---------- | ------------------------------------ | ---------------------------------- |
| **Python** | Cepat bikin, banyak library          | Lambat, GIL, gak bisa bare-metal   |
| **C**      | Kontrol penuh, performa              | Memory bugs → 70% CVE di Microsoft |
| **Rust**   | Zero-cost abstraction, memory safety | Learning curve, compile lama       |

**Poin:**

- **Memory safety tanpa GC** — gak ada use-after-free, buffer overflow, double free
- **Zero-cost abstraction** — iterator, closure, trait digerakin tanpa overhead
- **Cross-compilation** — compile dari Linux ke Windows/macOS/ARM gampang
- **`no_std`** — bisa jalan di bare-metal/firmware ([[firmware-reverse-engineering-deepdive]])

---

## ⚙️ 2. Toolchain & Setup

```bash
# Install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-pc-windows-gnu  # cross-compile
rustup component add clippy rust-analyzer

# Project baru
cargo new --bin tcp-probe
cd tcp-probe && cargo build --release
```

**Dependencies umum buat security tooling:**

- `clap` — CLI argument parsing
- `tokio` — async runtime (network I/O)
- `pcap` / `pnet` — packet capture & injection
- `serde` — serialization (JSON/YAML config)
- `openssl` / `rustls` — TLS

---

## 🧪 3. Contoh: Simple TCP Port Scanner

```rust
use std::net::{SocketAddr, TcpStream};
use std::time::Duration;

fn scan(addr: SocketAddr) -> bool {
    TcpStream::connect_timeout(&addr, Duration::from_millis(300)).is_ok()
}

fn main() {
    let target = "10.0.0.1";
    for port in 1..=1024 {
        let addr: SocketAddr = format!("{target}:{port}").parse().unwrap();
        if scan(addr) {
            println!("OPEN: {port}");
        }
    }
}
```

**Ponytail:** Ini versi blocking. Buat scanning 10k+ port, pake `tokio::net::TcpStream` async + connection pooling. Tambahin juga: SYN scan (raw socket via `pnet`), service fingerprint, output JSON.

---

## 🔗 Koneksi

- [[csapp-bryant-ohallaron]] — memory model & systems concepts yang Rust abstraksikan dengan aman
- [[ebpf-kernel-security]] — eBPF (C) + Rust userspace = kombinasi powerful
- [[ebpf-beyond-security]] — tooling kayak `aya` (Rust eBPF library)
- [[firmware-reverse-engineering-deepdive]] — `no_std` Rust buat bare-metal RE tool
- [[browser-security-exploitation-deepdive]] — browser engine (Servo) written in Rust
