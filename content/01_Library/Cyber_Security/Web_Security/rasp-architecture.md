---
title: RASP (Runtime Application Self-Protection) Architecture — Rust Hooking & Application
  Shielding
tags:
  - rasp
  - runtime-security
  - application-shielding
  - rust
  - instrumentation
  - web-security
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Sementara Web Application Firewall (WAF) menganalisis ancaman secara eksternal pada layer HTTP data plane, **RASP (Runtime Application Self-Protection)** berjalan **di dalam** proses runtime aplikasi untuk memantau eksekusi kode secara langsung. Catatan ini mendefinisikan arsitektur integrasi RASP dengan [[waf-reverse-proxy-deepdive]] untuk perlindungan menyeluruh.

## Daftar Isi

1. [Arsitektur RASP vs WAF](#1-arsitektur-rasp-vs-waf)
2. [Instrumentasi Tingkat Sistem (Rust LD_PRELOAD Hooking)](#2-instrumentasi-tingkat-sistem-rust-ld_preload-hooking)
3. [Instrumentasi Panggilan Fungsi Aplikasi (Exec/Eval/SQL)](#3-instrumentasi-panggilan-fungsi-aplikasi-execevalsql)
4. [Integrasi WAF + RASP Feedback Loop](#4-integrasi-waf--rasp-feedback-loop)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Arsitektur RASP vs WAF

WAF memeriksa payload dari luar sebelum mencapai aplikasi (_inspection at perimeter_), sehingga rentan dilewati oleh teknik _obfuscation_ atau serangan yang memanfaatkan modifikasi state internal aplikasi. RASP ditempelkan langsung ke dalam proses aplikasi untuk mendeteksi apakah payload tersebut memicu aksi berbahaya di dalam CPU/Memory runtime (_inspection at execution_).

```
Client Request
      │
      ▼
┌──────────────┐
│     WAF      │  (Menganalisis payload HTTP terenkripsi/obfuskasi)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Web Server  │  (Node.js / JVM / Python / Go)
│  ┌────────┐  │
│  │  RASP  │  │  (Menangkap call stack runtime dari fungsi sensitif)
│  │  Agent │  │
│  └────────┘  │
│      │       │
│      ▼       │
│  App Logic   │  ──> Akses database / System call `execve`
└──────────────┘
```

---

## 2. Instrumentasi Tingkat Sistem (Rust LD_PRELOAD Hooking)

Untuk bahasa yang di-compile secara native atau interpreter yang memanggil library dinamis C, RASP dapat di-inject tanpa memodifikasi kode sumber aplikasi menggunakan mekanisme pemuatan dinamis `LD_PRELOAD`.

Berikut adalah contoh agen RASP kecil (<10MB) berbasis Rust yang meng-override fungsi sistem `execve` untuk mendeteksi _Command Injection_.

### 2.1 Konfigurasi `Cargo.toml`

```toml
[package]
name = "jarswaf-rasp-agent"
version = "0.1.0"
edition = "2021"

[lib]
name = "jarswaf_rasp"
crate-type = ["cdylib"] # Mengompilasi menjadi .so dinamis

[dependencies]
libc = "0.2"
lazy_static = "1.4"
```

### 2.2 Kode Sumber Hooking (`src/lib.rs`)

```rust
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use lazy_static::lazy_static;

// Definisikan tipe tanda tangan untuk fungsi asli `execve`
type ExecveFn = unsafe extern "C" fn(*const c_char, *const *const c_char, *const *const c_char) -> c_int;

lazy_static! {
    // Cari alamat memori dari fungsi `execve` asli di libc menggunakan dlsym
    static ref ORIGINAL_EXECVE: ExecveFn = unsafe {
        let fn_name = CString::new("execve").unwrap();
        let original = libc::dlsym(libc::RTLD_NEXT, fn_name.as_ptr());
        std::mem::transmute(original)
    };
}

#[no_mangle]
pub unsafe extern "C" fn execve(
    pathname: *const c_char,
    argv: *const *const c_char,
    envp: *const *const c_char,
) -> c_int {
    let path = CStr::from_ptr(pathname).to_string_lossy();

    // Analisis perilaku berbahaya (Mendeteksi shell spawn ilegal dari web server)
    if path.contains("/bin/sh") || path.contains("/bin/bash") {
        eprintln!("[RASP WARNING] Deteksi eksekusi shell mencurigakan: {}", path);

        // Pilihan RASP: Blokir langsung eksekusi sistem dengan mengembalikan error ijin ditolak
        *libc::__errno_location() = libc::EACCES;
        return -1;
    }

    // Teruskan ke fungsi `execve` asli jika dianggap aman
    (*ORIGINAL_EXECVE)(pathname, argv, envp)
}
```

Kompilasi dan jalankan aplikasi web dengan menyuntikkan library RASP:

```bash
cargo build --release
# Injeksi ke proses aplikasi Node.js/Python
LD_PRELOAD=./target/release/libjarswaf_rasp.so node server.js
```

---

## 3. Instrumentasi Panggilan Fungsi Aplikasi (Exec/Eval/SQL)

Untuk runtime bahasa tingkat tinggi (managed runtimes), agen RASP meng-override API internal (Monkey Patching) untuk menangkap eksekusi fungsi rentan:

- **Node.js (V8 Engine)**: Meng-override fungsi `child_process.exec`, `eval`, dan `vm.runInContext`.
- **Python (CPython VM)**: Menggunakan `sys.settrace()` atau membungkus fungsi `os.system` dan `subprocess.Popen`.
- **Java (JVM)**: Menggunakan **Java Agent (Bytecode Manipulation)** via library ASM atau ByteBuddy untuk mendeteksi panggilan JDBC query SQL, memvalidasi input sebelum diteruskan ke database driver.

---

## 4. Integrasi WAF + RASP Feedback Loop

Menggabungkan WAF di perimeter dan RASP di runtime menciptakan sistem pertahanan adaptif (_Adaptive Threat Intelligence_):

1. **Telemetry Sharing**: RASP mendeteksi upaya SQLi yang berhasil lolos dari filter WAF (misal karena pengkodean khusus). RASP mengirimkan telemetri anomali beserta query yang terpicu ke WAF.
2. **Auto-Blocking**: WAF menerima sinyal deteksi dari RASP, menganalisis IP asal request tersebut, lalu secara otomatis memasukkan IP tersebut ke dalam _distributed blocklist_ jarsWAF (menggunakan Gossip protocol) untuk diblokir total di tingkat edge node sebelum request masuk kembali.
3. **Double Verification**: Jika WAF mendeteksi request dengan tingkat kecurigaan menengah (_medium confidence anomaly score_), WAF dapat menyematkan header tak terlihat `X-jarsWAF-Trace: verify` ke downstream. RASP yang melihat header ini akan memperketat kebijakan deteksi (_strict auditing mode_) pada alur pemrosesan request tersebut di memori aplikasi.

---

## 5. Koneksi ke Vault

| Catatan                        | Hubungan                                                                                     |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| [[waf-reverse-proxy-deepdive]] | Data plane jarsWAF yang bekerja sama dengan RASP agent untuk memblokir IP penyerang.         |
| [[hardware-hacking-re]]        | Teknik modifikasi runtime dan reverse engineering biner serupa.                              |
| [[jarswaf-plan]]               | Dokumen perencanaan utama jarsWAF tempat subsistem RASP dideklarasikan sebagai prioritas #8. |
