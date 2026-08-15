---
title: Rust Systems Programming untuk Tooling Keamanan
tags:
- rust
- systems-programming
- security-tooling
- no-std
- wasm
- library
aliases:
- rust-security-tooling-deepdive
- rust-untuk-pentest-engineer
- systems-programming-modern
created: '2026-07-15'
updated: '2026-07-15'
status: pending
cssclasses:
---

# 🦀 Rust Systems Programming untuk Tooling Keamanan

> Python bagus buat prototyping — cepat ditulis, banyak library. Tapi untuk tooling security yang butuh **performa tinggi, low-level access, atau cross-compilation ke embedded**, Python mulai reach limit-nya. Rust menempati niche yang dulu cuma diisi C/C++: systems programming dengan memory safety. Sekarang tool-tool seperti Ripgrep, fd, bottom, Firecracker (AWS microVM), Pingora (Cloudflare proxy), dan bahkan sebagian kernel Linux udah mulai pake Rust. Catatan ini dari setup toolchain sampe studi kasus konkret: bikin network tool, parser binary, dan integrasi dengan eBPF.

> [!info] Posisi di Vault
> Catatan ini terhubung dengan [[csapp-bryant-ohallaron]] (computer systems, memory model), [[ebpf-kernel-security]] (Rust + eBPF), [[ebpf-beyond-security]] (aya-rs — Rust eBPF library), [[firmware-reverse-engineering-deepdive]] (no_std Rust untuk bare-metal), dan [[browser-security-exploitation-deepdive]] (Servo browser engine di Rust).

---

## Daftar Isi

- [[#1. Kenapa Rust untuk Security Tooling?]]
- [[#2. Toolchain & Setup]]
- [[#3. Ownership, Borrowing, Lifetime untuk Engineer]]
- [[#4. Unsafe Rust — Kapan & Kenapa]]
- [[#5. Network Tooling — TCP Scanner Async]]
- [[#6. Binary Parsing — Zero-Copy dengan nom]]
- [[#7. Rust + eBPF — Kernel-Level Tooling]]
- [[#8. Cross-Compilation — Satu Kode, Banyak Platform]]
- [[#9. no_std — Embedded & Firmware Tooling]]
- [[#10. Perbandingan Rust vs C vs Go untuk Security]]
- [[#🔗 Koneksi ke Catatan Lain]]
- [[#✅ Checklist]]
- [[#Roadmap Belajar]]

---

## 1. Kenapa Rust untuk Security Tooling?

### 1.1 Masalah C di Tooling Keamanan

```
C adalah bahasa dominan untuk tooling keamanan selama 30+ tahun.
Masalah:
  - 70% CVE di Microsoft adalah memory safety bugs (source: MSRC)
  - Buffer overflow, use-after-free, double free — masih #1 attack vector
  - Manual memory management → human error
  - Tidak ada thread safety guarantee (data race)
```

### 1.2 Rust Menjawab

| Aspek | Python | C | Rust |
|-------|--------|---|------|
| Memory safety | ✅ GC | ❌ Manual | ✅ Compiler-checked |
| Performance | 🟡 Interpreted | 🟢 Native | 🟢 Native |
| Concurrency | ❌ GIL | 🟡 Manual locks | ✅ Send + Sync traits |
| Cross-compilation | 🟡 (limited) | 🟢 (painful) | 🟢 (rustup target) |
| Ecosystem | 🟢 Besar | 🟡 Legacy | 🟡 Tumbuh cepat |
| Zero-cost abstraction | ❌ | 🟢 Pointer | 🟢 Traits, generics |
| No_std / bare-metal | ❌ | 🟢 | 🟢 |

### 1.3 Tools Security Populer di Rust

| Tool | Fungsi | Kenapa Rust? |
|------|--------|-------------|
| **Ripgrep** | Grep alternatif | 5-10x lebih cepat dari grep |
| **fd** | find alternatif | UX lebih baik, performa |
| **bottom (btm)** | htop alternatif | Multi-threaded, GPU monitoring |
| **Firecracker** | AWS microVM | Security isolation + speed |
| **Pingora** | Cloudflare proxy | Connection reuse > 90% dari 40M req/s |
| **Aya** | eBPF library | Rust-native, gak perlu LLVM/Clang |
| **rustls** | TLS implementation | Memory safe, no OpenSSL drama |
| **Suricata 7+** | IDS/IPS | Rust modules di framework C |
| **Cargo-geiger** | Security audit unsafe code | Analisis unsafe di dependency |

---

## 2. Toolchain & Setup

### 2.1 Installasi

```bash
# Rustup — toolchain manager
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Default toolchain (stable)
rustc --version  # 1.85+ (2026)
cargo --version

# Tambah target
rustup target add x86_64-pc-windows-gnu    # Windows cross-compile
rustup target add aarch64-unknown-linux-gnu # ARM64
rustup target add wasm32-unknown-unknown    # WebAssembly

# Komponen penting
rustup component add clippy          # Linter
rustup component add rust-analyzer   # LSP untuk IDE/editor
rustup component add llvm-tools      # Code coverage, profiling

# Init project
cargo new --bin my-tool
cd my-tool
```

### 2.2 Dependencies untuk Security Tooling

```toml
# Cargo.toml — contoh untuk network security tool
[package]
name = "tcp-probe"
version = "0.1.0"
edition = "2024"

[dependencies]
# CLI argument parsing
clap = { version = "4", features = ["derive"] }

# Async runtime
tokio = { version = "1", features = ["full"] }

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# Packet capture
pcap = "2"           # libpcap binding
pnet = "0.35"        # Packet construction & parsing

# Logging & tracing
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json"] }

# HTTP
reqwest = { version = "0.12", features = ["native-tls"] }

# TLS
rustls = "0.23"

# Binary parsing
nom = "8"
binread = "2"

[profile.release]
opt-level = 3        # Max optimization
lto = true           # Link-time optimization
codegen-units = 1    # Slower compile, better optimization
```

### 2.3 Common Commands

```bash
# Build
cargo build              # Debug (fast compile)
cargo build --release    # Release (optimized)

# Run
cargo run -- -t 10.0.0.1 -p 80,443

# Check (no artifact, fast)
cargo check

# Lint
cargo clippy

# Test
cargo test
cargo test -- --nocapture  # show println! in tests

# Format
cargo fmt

# Audit
cargo audit              # Cargo-geiger: check for unsafe dependencies
cargo udeps              # Find unused dependencies

# Documentation
cargo doc --open
```

---

## 3. Ownership, Borrowing, Lifetime —  untuk Engineer

### 3.1 Ownership Rules

```rust
// Rule 1: Setiap nilai punya SATU owner
// Rule 2: Owner bisa meminjam (&) atau pindah (move)
// Rule 3: Owner di-drop ketika keluar scope

// MOVED (transfer ownership)
let s1 = String::from("hello");
let s2 = s1;  // s1 MOVED ke s2 → s1 gak valid lagi
// println!("{s1}");  // ❌ ERROR: borrow of moved value

// BORROWED (reference, temporary)
let s1 = String::from("hello");
let s2 = &s1;  // s2 BORROW s1 (immutable reference)
println!("{s1}");  // ✅ s1 masih valid
println!("{s2}");  // ✅ s2 juga valid (shared reference)

// MUTABLE BORROW (hanya satu)
let mut s1 = String::from("hello");
let s2 = &mut s1;  // Mutable borrow
println!("{s2}");   // ✅ s2 bisa modify s1
// println!("{s1}"); // ❌ s1 di-borrow sebagai mutable — gak bisa dibaca
```

### 3.2 Lifetime — Annotation

```rust
// Lifetime = "seberapa lama reference ini valid"
// Sering gak perlu explicit — compiler infer (elision rules)

// Explicit lifetime: function return reference dari parameter
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// 'static = whole program lifetime
let s: &'static str = "hello";  // string literal = 'static
```

### 3.3 Send & Sync — Thread Safety

```rust
// Send = boleh dipindah antar thread
// Sync = boleh di-share antar thread (via reference)

struct MySafeType {
    value: u32,
}
// Otomatis Send + Sync

struct MyUnsafeType {
    ptr: *mut u8,  // raw pointer — NOT Send
}
// ❌ NOT Send — compiler akan tolak kalau dikirim ke thread lain
```

---

## 4. Unsafe Rust — Kapan & Kenapa

### 4.1 Kapan Perlu unsafe?

```rust
// unsafe = "Compiler, percaya saya — saya jamin ini aman"
// Use cases:
//   1. FFI (call C functions)
//   2. Raw pointer dereference
//   3. Access/modify mutable static
//   4. Implement unsafe trait

unsafe fn read_from_pointer(ptr: *const u32) -> u32 {
    *ptr  // dereference raw pointer — hanya di unsafe block
}

// Pattern aman: wrap unsafe di safe API
mod safe_wrapper {
    use std::ptr;
    
    pub struct Buffer {
        data: Vec<u8>,
    }
    
    impl Buffer {
        pub fn new(size: usize) -> Self {
            Self {
                data: vec![0; size],  // safe allocation
            }
        }
        
        pub fn as_ptr(&self) -> *const u8 {
            self.data.as_ptr()  // raw pointer allowed di safe
        }
        
        // Semua unsafe detail di sini — caller pake safe API
        pub unsafe fn write_at(&mut self, offset: usize, value: u8) {
            if offset >= self.data.len() {
                panic!("out of bounds");  // safety check!
            }
            ptr::write(self.data.as_mut_ptr().add(offset), value);
        }
    }
}
```

### 4.2 Safety Invariants

```rust
// Invariant yang HARUS dijaga:
// 1. No null pointer dereference
// 2. No dangling pointer
// 3. No buffer overflow
// 4. No data race (Send/Sync)
// 5. No invalid enum value
// 6. No use-after-free

// unsafe ≠ "tidak ada checking"
// unsafe = "compiler gak bisa verify — lo tanggung jawab"
```

---

## 5. Network Tooling — TCP Scanner Async

### 5.1 TCP Port Scanner — Async Tokio

```rust
use std::time::Duration;
use tokio::net::TcpStream;
use tokio::time::timeout;

async fn scan_port(target: &str, port: u16) -> bool {
    let addr = format!("{target}:{port}");
    match timeout(Duration::from_millis(300), TcpStream::connect(&addr)).await {
        Ok(Ok(_)) => true,   // Port open
        _ => false,           // Closed, filtered, or timeout
    }
}

#[tokio::main]
async fn main() {
    let target = std::env::args().nth(1).expect("Need target IP");
    let ports: Vec<u16> = if let Some(range) = std::env::args().nth(2) {
        let parts: Vec<&str> = range.split('-').collect();
        let start: u16 = parts[0].parse().unwrap();
        let end: u16 = parts.get(1).unwrap_or(&parts[0]).parse().unwrap();
        (start..=end).collect()
    } else {
        (1..=1024).collect()
    };

    // Concurrent scanning with bounded concurrency
    let semaphore = std::sync::Arc::new(tokio::sync::Semaphore::new(100));
    let mut handles = vec![];

    for port in ports {
        let permit = semaphore.clone().acquire_owned().await.unwrap();
        let target = target.clone();
        handles.push(tokio::spawn(async move {
            let _permit = permit;
            if scan_port(&target, port).await {
                println!("OPEN: {port}");
            }
        }));
    }

    for handle in handles {
        handle.await.unwrap();
    }
}
```

**Ponytail:** Ini scanner TCP connect — terdeteksi. Buat SYN stealth scan, perlu raw socket via `pnet` crate. Tambahin service fingerprint (banner grab), output JSON, rate limiting.

### 5.2 Packet Capture & Injection

```rust
use pcap::{Capture, Device};
use pnet::packet::{
    Packet,
    ip::IpNextHeaderProtocols,
    tcp::TcpPacket,
    ipv4::Ipv4Packet,
    ethernet::{EtherTypes, EthernetPacket},
};

fn capture_tcp_syn() -> Result<(), Box<dyn std::error::Error>> {
    let device = Device::from("eth0")?;
    let mut cap = Capture::from_device(device)?
        .promisc(true)
        .snaplen(65535)
        .timeout(1000)
        .open()?;

    while let Ok(packet) = cap.next_packet() {
        if let Some(eth) = EthernetPacket::new(packet.data) {
            if eth.get_ethertype() == EtherTypes::Ipv4 {
                if let Some(ip) = Ipv4Packet::new(eth.payload()) {
                    if ip.get_next_level_protocol() == IpNextHeaderProtocols::Tcp {
                        if let Some(tcp) = TcpPacket::new(ip.payload()) {
                            if tcp.get_flags() & 0x02 != 0 {  // SYN flag
                                println!("SYN from {}:{} → {}:{}",
                                    ip.get_source(),
                                    tcp.get_source(),
                                    ip.get_destination(),
                                    tcp.get_destination());
                            }
                        }
                    }
                }
            }
        }
    }
    Ok(())
}
```

---

## 6. Binary Parsing — Zero-Copy dengan nom

### 6.1 nom — Zero-Copy Parser

Untuk reverse engineering firmware atau protocol binary (lihat [[firmware-reverse-engineering-deepdive]]):

```rust
use nom::{
    IResult,
    bytes::complete::{tag, take},
    number::complete::{le_u16, le_u32, be_u32},
    sequence::tuple,
};

#[derive(Debug)]
struct ElfHeader {
    magic: [u8; 4],         // \x7fELF
    class: u8,              // 1=32-bit, 2=64-bit
    endian: u8,             // 1=little, 2=big
    version: u8,
    os_abi: u8,
    padding: [u8; 8],
    entry: u32,             // Entry point address
    phoff: u32,             // Program header offset
    shoff: u32,             // Section header offset
    flags: u32,
    ehsize: u16,            // ELF header size
    phentsize: u16,         // Program header entry size
    phnum: u16,             // Number of program headers
    shentsize: u16,         // Section header entry size
    shnum: u16,             // Number of section headers
    shstrndx: u16,          // Section header string table index
}

fn parse_elf32_header(input: &[u8]) -> IResult<&[u8], ElfHeader> {
    let (input, (magic, class, endian, version, os_abi, padding)) = 
        tuple((tag(b"\x7fELF"), take(1u8), take(1u8), take(1u8), take(1u8), take(8u8)))(input)?;
    
    let (input, (entry, phoff, shoff, flags)) = 
        tuple((le_u32, le_u32, le_u32, le_u32))(input)?;
    
    let (input, (ehsize, phentsize, phnum, shentsize, shnum, shstrndx)) = 
        tuple((le_u16, le_u16, le_u16, le_u16, le_u16, le_u16))(input)?;
    
    Ok((input, ElfHeader {
        magic: [magic[0], magic[1], magic[2], magic[3]],
        class: class[0],
        endian: endian[0],
        version: version[0],
        os_abi: os_abi[0],
        padding: [padding[0], padding[1], padding[2], padding[3], padding[4], padding[5], padding[6], padding[7]],
        entry, phoff, shoff, flags,
        ehsize, phentsize, phnum, shentsize, shnum, shstrndx,
    }))
}

fn main() {
    let data = std::fs::read("/usr/bin/ls").unwrap();
    match parse_elf32_header(&data) {
        Ok((_, header)) => println!("ELF entry point: 0x{:x}", header.entry),
        Err(e) => eprintln!("Parse error: {e}"),
    }
}
```

---

## 7. Rust + eBPF — Kernel-Level Tooling

### 7.1 Aya — Rust eBPF Library

```rust
// eBPF program di Rust (aya-rs)
use aya::Bpf;
use aya::programs::Xdp;
use std::net::Ipv4Addr;

fn main() -> Result<(), anyhow::Error> {
    let mut bpf = Bpf::load(include_bytes_aligned!("path/to/ebpf.o"))?;
    
    let program: &mut Xdp = bpf.program_mut("xdp_drop").unwrap().try_into()?;
    program.load()?;
    program.attach("eth0", XdpFlags::default())?;
    
    // Maps — share data antara eBPF dan userspace
    let mut blocklist: aya::maps::HashMap<_, u32, u32> = 
        bpf.map_mut("BLOCKLIST").unwrap().try_into()?;
    
    // Block IP 10.0.0.1
    let ip = u32::from(Ipv4Addr::new(10, 0, 0, 1));
    blocklist.insert(ip, 1, 0)?;
    
    println!("eBPF loaded — blocking traffic");
    loop { std::thread::sleep(std::time::Duration::from_secs(1)); }
}
```

**Kenapa Rust + eBPF?** Lihat [[ebpf-beyond-security]] untuk detail.

---

## 8. Cross-Compilation — Satu Kode, Banyak Platform

### 8.1 Target Matrix

```bash
# Linux → Windows (static)
rustup target add x86_64-pc-windows-gnu
cargo build --release --target x86_64-pc-windows-gnu

# Linux → ARM64 (Raspberry Pi, Cloud ARM)
rustup target add aarch64-unknown-linux-gnu
cargo build --release --target aarch64-unknown-linux-gnu

# Linux → ARMv7 (Raspberry Pi 32-bit)
rustup target add armv7-unknown-linux-gnueabihf
cargo build --release --target armv7-unknown-linux-gnueabihf

# Untuk static linking (no libc dependency)
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
# Hasil: binary static ~5MB, jalan di ANY Linux (alpine, distro lama)
```

### 8.2 Config Example

```toml
# .cargo/config.toml
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"

[target.x86_64-unknown-linux-musl]
rustflags = ["-C", "target-feature=+crt-static"]
```

---

## 9. no_std — Embedded & Firmware Tooling

### 9.1 Kapan Pakai no_std?

```rust
// no_std = tanpa standard library (allocator, I/O, filesystem)
// Untuk: firmware, bootloader, kernel module, embedded

#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Bare-metal entry point — no OS
    let gpio_addr = 0xFE200000 as *mut u32;
    unsafe {
        gpio_addr.write_volatile(0x01);  // Set GPIO pin
    }
    loop {}
}
```

### 9.2 Rust Embedded Ecosystem

```
Chip                    Crate
├── ESP32              esp-hal, esp-idf-hal
├── STM32              stm32-f4xx-hal, embassy-stm32
├── nRF52840           nrf52840-hal, embassy-nrf
├── RISC-V             esp32c3-hal
└── RP2040 (RPi Pico)  rp2040-hal, embassy-rp
```

Lihat [[firmware-reverse-engineering-deepdive]] untuk analisis firmware.

---

## 10. Perbandingan Rust vs C vs Go untuk Security

### Benchmark Sintaksis

| Task | Rust Lines | C Lines | Go Lines |
|------|-----------|---------|----------|
| TCP server | 30 | 80 | 25 |
| Binary parser | 40 | 100 | 60 |
| HTTP client | 15 | 120 | 15 |
| Thread pool | 50 | 200 | 20 |

### Performance

| Tool | Rust | C | Go |
|------|------|---|----|
| HTTP throughput | 🟢 | 🟢 | 🟡 (GC pause) |
| Memory safety | 🟢 (compile time) | 🔴 (valgrind) | 🟡 (GC) |
| Binary size (static) | 2-5 MB | 0.5-1 MB | 8-15 MB |
| Startup time | 1-5ms | <1ms | 5-50ms |
| Compile time | 30s - 5m | 10s - 2m | 5-30s |

---

## 🔗 Koneksi ke Catatan Lain

- [[csapp-bryant-ohallaron]] — memory model & systems concepts yang Rust abstraksikan dengan aman
- [[ebpf-kernel-security]] — eBPF (C) + Rust userspace = kombinasi kernel-level tooling
- [[ebpf-beyond-security]] — aya-rs Rust eBPF library, XDP drop programs
- [[firmware-reverse-engineering-deepdive]] — no_std Rust untuk bare-metal RE tool
- [[browser-security-exploitation-deepdive]] — Servo browser engine written in Rust
- [[software-engineering]] — best practices software engineering, Rust sebagai bahasa baru
- [[waf-reverse-proxy-deepdive]] — Pingora (Rust), Coraza (Go), perbandingan WAF engine
- [[design-patterns-gof]] — trait-based design patterns (Strategy, Builder, Iterator via iterator trait)

---

## ✅ Checklist

- [ ] Setup Rust toolchain + cargo + clippy
- [ ] Paham ownership, borrowing, lifetime
- [ ] Bisa bedain safe vs unsafe Rust
- [ ] Setup async project dengan tokio
- [ ] Bisa bikin TCP scanner atau HTTP client concurrent
- [ ] Paham cross-compilation ke Windows/ARM
- [ ] Bisa bikin binary parser dengan nom
- [ ] Paham kapan pake Rust vs Go vs Python
- [ ] Setup embedded Rust (no_std) untuk basic GPIO

---

## Roadmap Belajar

```
HARI 1: Fundamentals
  - Baca dokumen ini
  - Install Rust, setup project "hello world" + clap CLI
  - Pelajari ownership (buku "The Rust Book" Bab 4)

HARI 2: Network Tooling
  - Bikin async TCP port scanner dengan tokio
  - Tambah: concurrent semaphore, banner grab, JSON output
  - Bandingkan kecepatan dengan nmap

HARI 3: Binary Internals
  - Parsing ELF header dengan nom
  - Ekstrak section names, symbols
  - Integrasi dengan [[firmware-reverse-engineering-deepdive]]

HARI 4: Systems Programming
  - Cross-compile tool ke ARM64 dan musl
  - Setup Aya eBPF: XDP drop program
  - Baca [[ebpf-kernel-security]] untuk integrasi

HARI 5: Production Tool
  - Pilih satu tool security yang sering lo pake di Python
  - Port ke Rust dengan fitur yang sama
  - Bandingkan: memory usage, speed, binary size
  - Deploy sebagai static binary di Docker (scratch image)
```

> [!warning] Bottom Line
> Rust bukan "next big thing" — dia **udah big thing**. AWS, Cloudflare, Google, Microsoft — semua investasi besar di Rust untuk infrastruktur kritis. Untuk security engineer, Rust adalah **force multiplier**: lo bisa bikin tool yang performa seperti C, aman seperti Python, dan bisa di-cross-compile ke embedded/Windows/ARM dalam hitungan menit. Investasi 1-2 minggu untuk belajar ownership model akan terbayar berkali-kali lipat ketika lo butuh tool yang reliable dan cepat.

> [!tip] Ponytail
> Catatan ini belum mencakup Rust WebAssembly (wasm-pack untuk browser tooling), Rust untuk kernel module (kernel 6.14+ eksperimental), Rust untuk GPU computing (wgpu, cubecl), dan async Rust advanced patterns (actor model via Actix, async streams). Tambahkan seiring kebutuhan.
---

audited
---
