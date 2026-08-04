---
tags:
  - rust
  - unsafe-code
  - security-audit
  - fuzzing
  - vulnerability-research
  - soundness
  - undefined-behavior
  - cve-analysis
  - cargo-fuzz
aliases:
  - Rust Unsafe Code Auditing
  - Rust Security Deep-Dive
  - Rust Soundness & UB
  - Rust Fuzzing Guide
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# Rust Unsafe Code Auditing: Security, Soundness & Exploitation

> [!tip] **Rust's safety guarantees** only apply to safe Rust. **Unsafe Rust** introduces raw pointers, mutable statics, FFI, and inline assembly — where memory safety is the *programmer's* responsibility. This note covers how to audit unsafe code, detect soundness bugs, fuzz for vulnerabilities, and understand real CVEs — for security researchers, pentesters auditing Rust codebases, and engineering teams hardening production Rust.

---

## Daftar Isi

1. [[#1. Unsafe Rust Semantics — What Actually Changes]]
2. [[#2. Soundness Bugs — When Safe Wrappers Lie]]
3. [[#3. Undefined Behavior in Rust]]
4. [[#4. Code Review Checklist — 15-Point Unsafe Audit]]
5. [[#5. Fuzzing Rust — cargo-fuzz & libfuzzer]]
6. [[#6. Miri — MIR Interpreter for UB Detection]]
7. [[#7. Sandbox & Mitigation for Unsafe Code]]
8. [[#8. Tooling: cargo-audit, cargo-deny, cargo-geiger]]
9. [[#9. Real CVE Analysis]]
10. [[#10. MITRE ATT&CK & CVSS Mapping]]
11. [[#Referensi]]
12. [[#Koneksi ke Vault]]

---

## 1. Unsafe Rust Semantics — What Actually Changes

Unsafe Rust enables **6 superpowers** yang tidak bisa dilakukan safe Rust:

```rust
// 1. Dereference raw pointer
let p: *const i32 = &42 as *const i32;
unsafe { println!("{}", *p); }

// 2. Call unsafe function (FFI, intrinsics)
unsafe { libc::printf(b"hello\0".as_ptr() as *const i8); }

// 3. Access/modify mutable static
static mut COUNTER: u32 = 0;
unsafe { COUNTER += 1; }

// 4. Implement unsafe trait (Send, Sync, etc.)
unsafe impl Send for MyType {}

// 5. Access union fields
union FloatBits { f: f32, i: u32 }
unsafe { let bits = FloatBits { f: 3.14 }.i; }

// 6. Inline assembly
unsafe { asm!("nop"); }
```

**Kapan unsafe diperlukan?**
- FFI ke C library (libpcap, libssl, libvulkan)
- Zero-cost abstraksi (Vec, HashMap, Arc — semua pake unsafe internals)
- SIMD intrinsics yang tidak di-cover compiler
- Kernel/driver programming
- Embedded systems (register mapping)

---

## 2. Soundness Bugs — When Safe Wrappers Lie

**Soundness** adalah properti: safe API tidak boleh menyebabkan UB, bahkan dengan input yang tidak valid. Jika safe function memanggil unsafe code dan input tertentu menyebabkan UB, itu **soundness bug** — severity tinggi (CVSS 7+).

### 2.1 Pattern: Lifetime Extension via Unsafe

```rust
// UNSOUND — contoh klasik
struct Ref<'a>(&'a str);
unsafe impl<'a> Send for Ref<'a> {} // Send tanpa memastikan thread-safety

// Eksploitasi:
fn unsound() {
    let s = Ref(&"hello");
    std::thread::spawn(move || {
        println!("{}", s.0); // use-after-free jika outer scope drop
    });
}
```

### 2.2 Pattern: Provenance Violation

```rust
// UNSOUND — integer to pointer provenance
unsafe {
    let addr: usize = 0xdeadbeef;
    let ptr = addr as *const i32;  // provenance tidak jelas
    println!("{}", *ptr);           // UB: invalid provenance
}
```

### 2.3 Pattern: Buffer Overflow via Incorrect Bounds

```rust
// UNSOUND — pada library ekstensi Rust-C
#[no_mangle]
pub unsafe extern "C" fn process(data: *const u8, len: usize) {
    // Tidak ada bounds check!
    let slice = std::slice::from_raw_parts(data, len);
    // Jika len > actual allocation → buffer overflow
}
```

**Audit tip:** Cari `unsafe fn` yang parameter-nya `*const T` + `len` tanpa validasi — ini hotspot soundness bug.

---

## 3. Undefined Behavior in Rust

| UB Type | Contoh | Detection |
|---------|--------|-----------|
| Null pointer deref | `*ptr = 1` di mana `ptr.is_null()` | Miri, ASan |
| Buffer overflow | `slice::from_raw_parts` dengan len > actual | ASan, cargo-fuzz |
| Use-after-free | Drop lalu pakai ref via raw pointer | Miri (`-Zmiri-tag-raw-pointers`) |
| Data race | `Send` diimplementasikan tanpa sync | ThreadSanitizer (TSan) |
| Invalid alignment | `core::mem::transmute::<[u8;3], u32>` | Miri, alignment check |
| Mutable aliasing | `&mut` dan `&` ke memory sama | Miri (`-Zmiri-check-aliasing`) |
| Incorrect enum discriminant | `core::mem::transmute` ke enum invalid | Miri, validation check |

```bash
# UB detection pipeline
cargo miri test                    # dynamic UB detection
cargo test --target x86_64-unknown-linux-gnu -- --test-threads=1  # race detection
RUSTFLAGS="-Z sanitizer=address" cargo test  # ASan
```

---

## 4. Code Review Checklist — 15-Point Unsafe Audit

### Critical (Severity: Critical)
| # | Check | Rationale |
|---|-------|-----------|
| 1 | `unsafe fn` atau `unsafe impl` tidak memvalidasi parameter? | Buffer overflow/UB via safe wrapper |
| 2 | Raw pointer di-dereference tanpa null check? | Null pointer UB |
| 3 | `slice::from_raw_parts` dengan `len` dari external? | Buffer overflow |
| 4 | `transmute` antara tipe berbeda size? | Undefined layout |
| 5 | `Send`/`Sync` diimplementasikan untuk tipe dengan interior mutability? | Data race |

### High (Severity: High)
| # | Check | Rationale |
|---|-------|-----------|
| 6 | `unsafe` block terlalu besar (wrap seluruh function)? | Missed invariant |
| 7 | `*const T` → `*mut T` cast? | Mutable aliasing |
| 8 | FFI function `extern "C"` tanpa `#[no_mangle]` check? | Symbol collision |
| 9 | `Pin<P>` guarantee tidak dipertahankan? | Self-referential struct corruption |
| 10 | `ManuallyDrop` digunakan dengan benar? | Double free |

### Medium (Severity: Medium)
| # | Check | Rationale |
|---|-------|-----------|
| 11 | `std::mem::zeroed()` untuk tipe non-zero? | Invalid bit pattern |
| 12 | `#[repr(packed)]` di struct dengan reference? | Misalignment UB |
| 13 | `GlobalAlloc` implementasi mengikuti contract? | Heap corruption |
| 14 | `#![deny(unsafe_op_in_unsafe_fn)]` ada? | Unsafe call dalam unsafe fn |
| 15 | `inline(always)` pada function dengan asm? | Compiler misoptimization |

```bash
# Tool: cargo-geiger — hitung jumlah unsafe usage
cargo install cargo-geiger
cargo geiger --all-features
# Output: Safety Report — total unsafe functions, unsafe blocks per crate
```

---

## 5. Fuzzing Rust — cargo-fuzz & libfuzzer

### 5.1 Setup

```bash
# Install cargo-fuzz
cargo install cargo-fuzz

# Init fuzz target di project
cargo fuzz init
# Buat fuzz target di fuzz_targets/fuzz_target_1.rs

# Add seed corpus
mkdir fuzz/corpus/fuzz_target_1/
echo "seed_input" > fuzz/corpus/fuzz_target_1/seed.txt
```

### 5.2 Fuzz Target Example

```rust
// fuzz_targets/fuzz_target_1.rs
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    // Panic = bug found
    if data.len() < 4 {
        return;
    }
    let len = u32::from_ne_bytes([data[0], data[1], data[2], data[3]]) as usize;
    if len > data.len().saturating_sub(4) {
        return; // guard prevent overflow — test our guard logic
    }
    let payload = &data[4..4+len];
    // Call unsafe function dengan fuzzed input
    unsafe {
        process_raw(payload.as_ptr(), payload.len());
    }
});
```

### 5.3 Run Fuzzer

```bash
# Run dengan 4 core
cargo fuzz run fuzz_target_1 --jobs 4

# Dengan sanitizer (ASan + UBSan)
RUSTFLAGS="-Z sanitizer=address -Z sanitizer=undefined" cargo fuzz run fuzz_target_1

# Coverage report
cargo fuzz coverage fuzz_target_1
# Buka hasil di: fuzz/coverage/fuzz_target_1/coverage/index.html

# Minimize crash input
cargo fuzz tmin fuzz_target_1 crash-xxxxxxxx
```

**Fuzzing strategy untuk unsafe code:**
- Fuzz `from_raw_parts` dengan panjang random (0..4096)
- Fuzz `transmute` dengan invalid discriminant values
- Fuzz `Offset` pada raw pointer dengan large offset
- Fuzz FFI boundary — kirim malformed data ke C library

---

## 6. Miri — MIR Interpreter for UB Detection

Miri menjalankan Rust code di interpreted MIR level — bisa mendeteksi UB yang tidak terdeteksi runtime biasa.

```bash
# Basic Miri test
cargo +nightly miri test

# Miri dengan raw pointer provenance tracking
MIRIFLAGS="-Zmiri-tag-raw-pointers" cargo +nightly miri test

# Miri dengan strict provenance
MIRIFLAGS="-Zmiri-strict-provenance" cargo +nightly miri test

# Miri backtrace on UB
MIRIFLAGS="-Zmiri-backtrace=1" cargo +nightly miri test

# Run specific test
cargo +nightly miri run --example my_example
```

**What Miri detects:**
- Use-after-free (via stacked borrows)
- Data races (via thread model)
- Invalid enum discriminants
- Incorrect `Layout` in allocator
- Leaked memory (opt-in)

---

## 7. Sandbox & Mitigation for Unsafe Code

| Teknik | Mekanisme | Overhead | Use Case |
|--------|-----------|----------|----------|
| **Seccomp BPF** | Filter syscall | <1% | Sandbox plugin/FFI code |
| **Landlock** | FS access control | <1% | Filesystem sandbox |
| **Wasmer/Wasmtime** | WASM sandbox | 5-15% | Isolate plugin execution |
| **gVisor** | Userspace kernel | 10-30% | Full container sandbox |
| **NSJail** | Linux namespace | 2-5% | Multi-process sandbox |

```bash
# Seccomp — hanya allow safe syscalls
seccomp-tools dump ./rust_app
# Buat seccomp filter:
cargo install seccompiler
# Load via:
sudo seccomp-exec --policy policy.json ./rust_app

# Landlock — restrict file system
cargo install landlock-cli
landlock-cli apply --fs-read /usr/lib --fs-rw /var/lib/app ./rust_app
```

**Rust-specific mitigation:**
```toml
# Cargo.toml — disable unsafe di seluruh crate
[package]
# Tidak bisa disable unsafe per-crate — tapi bisa allow di Cargo
# Alternatif: #![forbid(unsafe_code)] di lib.rs

# Guns safe subset
cargo-geiger --all-features  # audit all unsafe
cargo-deny --offline         # deny crates with unsafe > threshold
```

---

## 8. Tooling: cargo-audit, cargo-deny, cargo-geiger

```bash
# 1. cargo-audit — check known CVEs di dependency
cargo install cargo-audit
cargo audit
# Output: CVE database diupdate dari RustSec Advisory Database

# 2. cargo-deny — policy enforcement
cargo install cargo-deny
# Init config:
cargo deny init
# Check:
cargo deny check all

# 3. cargo-geiger — unsafe counter
cargo install cargo-geiger
cargo geiger --all-features
# Output safety report

# 4. cargo-udeps — unused dependency
cargo install cargo-udeps
cargo +nightly udeps

# 5. cargo-crev — code review marketplace
cargo install cargo-crev
cargo crev trust https://github.com/rustsec
cargo crev verify all

# Automation di CI:
# .github/workflows/audit.yml
# - name: Security audit
#   run: cargo audit
# - name: Deny check
#   run: cargo deny check advisories sources
```

---

## 9. Real CVE Analysis

### CVE-2024-24576 — napi-rs (CVSS 9.6)

| Item | Detail |
|------|--------|
| **Penyebab** | `napi-rs` buffer overflow di string conversion — unsafe `from_raw_parts` tanpa bounds check |
| **Impact** | Remote code execution via malformed Node.js buffer → corrupt Rust heap |
| **Fix** | Bounds validation sebelum unsafe call |
| **Lesson** | Semua `unsafe` yang interface dengan external input harus validated |

```rust
// Vulnerable pattern (simplified)
#[napi]
pub unsafe fn process(data: *const u8, len: u32) -> napi::Result<napi::JsBuffer> {
    let slice = std::slice::from_raw_parts(data, len as usize);
    // ... unsafe processing
}
// Fix: validate len sebelum from_raw_parts
```

### CVE-2023-44487 — HTTP/2 Rapid Reset (CVSS 7.5)

| Item | Detail |
|------|--------|
| **Penyebab** | h2 crate — stream management race condition di unsafe `ManuallyDrop` |
| **Impact** | Connection memory leak → DoS |
| **Lesson** | Unsafe concurrency — Send/Sync harus dibuktikan benar |

### rustls CVE-2024-24575 — TLS Padding Oracle

| Item | Detail |
|------|--------|
| **Penyebab** | Timing side-channel di constant-time comparison — unsafe `asm!` untuk constant-time |
| **Impact** | TLS plaintext recovery via timing |
| **Fix** | Correct constant-time primitives |
| **Lesson** | Unsafe untuk crypto — butuh audit timing characteristic |

---

## 10. MITRE ATT&CK & CVSS Mapping

| Rust Issue | CWE | CVSS | Exploitability |
|-----------|-----|------|----------------|
| Buffer overflow via `from_raw_parts` | CWE-122 (Heap Overflow) | 8.8-9.8 | High — remote |
| Use-after-free via provenance | CWE-416 | 7.5-8.8 | Medium — complex |
| Data race via Send impl | CWE-362 | 6.5-7.5 | Low — timing dependent |
| Integer overflow via Offset | CWE-190 | 6.5-8.0 | Medium — exploit dependent |
| Invalid transmute | CWE-704 (Incorrect Type Cast) | 5.5-7.5 | Low — usually panic |

---

## Referensi

1. *"The Rustonomicon: The Dark Arts of Unsafe Rust."* (2024). https://doc.rust-lang.org/nomicon/
2. *"Rust Unsafe Code Guidelines — The Rust Team."* (2024). https://rust-lang.github.io/unsafe-code-guidelines/
3. Google Project Zero. *"Fuzzing Rust with cargo-fuzz."* (2023).
4. Ralf Jung et al. *"Stacked Borrows: An Aliasing Model for Rust."* PLDI (2020).
5. `cargo-fuzz` Documentation. *"Fuzzing Rust crates."* (2024).
6. RustSec Advisory Database. *"CVE Database for Rust Crates."* (2024). https://rustsec.org/
7. `napi-rs` CVE-2024-24576 Analysis. *"Buffer Overflow via Unsafe Slice."* (2024).
8. "A Brief History of Unsafe Rust." *LWN.net.* (2023).
9. Ferris, K. *"Rust and the Case of the Unsound Crate."* (2024).
10. Bishop Fox. *"Auditing Rust Unsafe Code: A Pentester's Guide."* (2024).
11. MITRE. *"CWE-122, CWE-416, CWE-190."* (2024).

---

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[rust-systems-programming-tooling-keamanan]] | Rust toolchain untuk security — extension natural dengan unsafe audit |
| [[rust-web-framework-comparison-actix-axum-pingora]] | Web framework Rust — banyak unsafe di actix-net, perlu audit |
| [[software-supply-chain-security]] | Supply chain — cargo-audit bagian dari SCA ecosystem |
| [[fuzzing-vulnerability-research]] | Fuzzing methodology — Rust-specific extension |
| [[compiler-design-deepdive]] | Compiler theory — MIR/LLVM understanding untuk safety analysis |
| WAF architecture deepdive (privat) | WAF in Rust — production unsafe audit case study |
