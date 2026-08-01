---
title: Browser Engine Architecture — Parsing, Rendering Pipeline, and V8 Execution
tags:
  - browser-architecture
  - rendering-pipeline
  - javascript-engine
  - v8
  - webassembly
  - frontend
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Memahami bagaimana peramban (_browser_) merender halaman web dan mengeksekusi JavaScript adalah dasar penting bagi pengembang web dan peneliti keamanan. Catatan ini membedah arsitektur rendering engine (Blink/WebKit) dan execution engine (V8), melengkapi pembahasan [[browser-security-exploitation-deepdive]] dan [[http-protocol-deepdive]].

## Daftar Isi

1. [Alur Rendering Engine (HTML s.d Pixels)](#1-alur-rendering-engine-html-sd-pixels)
2. [Penyusunan DOM, CSSOM, dan Render Tree](#2-penyusunan-dom-cssom-dan-render-tree)
3. [Layout, Paint, dan GPU Compositing](#3-layout-paint-dan-gpu-compositing)
4. [Arsitektur JS Engine V8 (Ignition & TurboFan)](#4-arsitektur-js-engine-v8-ignition--turbofan)
5. [Integrasi WebAssembly (Wasm) & Batas Keamanan](#5-integrasi-webassembly-wasm--batas-keamanan)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Alur Rendering Engine (HTML s.d Pixels)

Proses konversi data biner HTML yang diterima dari jaringan menjadi piksel visual pada layar monitor melewati serangkaian tahapan pipeline yang sangat terstruktur:

```
[HTML Biner] ──> [DOM Tree] ──┐
                              ├─> [Render Tree] ──> [Layout] ──> [Paint] ──> [Composite] ──▶ GPU
[CSS Biner]  ──> [CSSOM Tree] ┘
```

---

## 2. Penyusunan DOM, CSSOM, dan Render Tree

### 2.1 DOM (Document Object Model)

Prosesor HTML memindai karakter teks dan mengubahnya menjadi simpul (_nodes_) objek C++ di dalam struktur pohon DOM. Proses ini bersifat inkremental (browser dapat merender bagian awal dokumen sebelum seluruh file HTML selesai diunduh).

### 2.2 CSSOM (CSS Object Model)

Browser memindai stylesheet untuk membangun CSSOM. Berbeda dengan DOM, pembuatan CSSOM **tidak bisa dilakukan secara parsial**. Browser harus mengunduh dan menganalisis seluruh file CSS sebelum melanjutkan ke tahap berikutnya (_render-blocking nature_), untuk mencegah fenomena tampilan visual rusak (_Flash of Unstyled Content_ - FOUC).

### 2.3 Render Tree

Merupakan gabungan dari DOM dan CSSOM. Render Tree hanya berisi elemen-elemen yang benar-benar akan digambar di layar.

- Simpul dengan aturan CSS `display: none` **tidak akan dimasukkan** ke dalam Render Tree.
- Elemen dengan aturan `visibility: hidden` tetap dimasukkan ke dalam Render Tree karena mereka masih membutuhkan ruang tata letak fisik (_layout space_) di layar.

---

## 3. Layout, Paint, dan GPU Compositing

### 3.1 Layout (Reflow)

Pada tahap ini, browser menghitung geometri fisik (posisi koordinat $x, y$ serta lebar dan tinggi) dari setiap objek dalam Render Tree. Perhitungan ini dimulai dari elemen root (`<html>`) ke bawah secara rekursif.

- **Pemicu Reflow**: Perubahan ukuran layar, manipulasi DOM yang merubah ukuran, atau pembacaan properti geometri seperti `offsetWidth` via JavaScript.

### 3.2 Paint (Rasterization)

Mengonversi elemen-elemen tata letak menjadi instruksi menggambar piksel (warna, garis, bayangan). Browser menggunakan pustaka grafis 2D khusus (seperti Skia pada Chrome) untuk menggambar instruksi ini menjadi bitmap memori.

### 3.3 Compositing (GPU Acceleration)

Daripada menggambar seluruh halaman sebagai satu bitmap tunggal, browser modern membagi halaman menjadi beberapa lapisan (_layers_) fisik yang independen (misalnya untuk elemen dengan properti CSS `transform`, `will-change`, atau `<video>`).

- Setiap lapisan di-raster secara terpisah menjadi tekstur memori.
- Tekstur dikirim ke **GPU (Graphics Processing Unit)**.
- GPU menggabungkan (_composite_) seluruh lapisan tersebut di layar secara instan.
- **Kelebihan**: Animasi berbasis transformasi CSS (seperti `translate3d`) sangat cepat karena tidak memicu siklus _Layout_ atau _Paint_ ulang di CPU; GPU hanya menggeser posisi koordinat tekstur yang sudah ada di memori VRAM.

---

## 4. Arsitektur JS Engine V8 (Ignition & TurboFan)

Mesin V8 (digunakan oleh Node.js dan Chrome) mengeksekusi JavaScript menggunakan teknik kompilasi **Just-In-Time (JIT)**.

```
                  ┌───────────────────────────────┐
                  │        JavaScript Code        │
                  └──────────────┬────────────────┘
                                 │
                                 ▼ (Parser)
                  ┌───────────────────────────────┐
                  │    AST (Abstract Syntax Tree) │
                  └──────────────┬────────────────┘
                                 │
                                 ▼
                  ┌───────────────────────────────┐
                  │      Ignition Interpreter     │ ◀─── (Eksekusi bytecode cepat)
                  └──────────────┬────────────────┘
                                 │
                                 ├─ Profiling (Mendeteksi fungsi sering dipanggil / Hot)
                                 ▼
                  ┌───────────────────────────────┐
                  │      TurboFan JIT Compiler    │ ─── (Optimasi kode mesin)
                  └───────────────────────────────┘
                                 │
                                 ▼ Deoptimasi (Jika asumsi tipe data meleset)
```

### 4.1 Ignition Interpreter

Menerjemahkan AST menjadi kode bytecode menengah yang ringkas. Keuntungannya adalah startup aplikasi instan dengan konsumsi memori overhead minimal.

### 4.2 TurboFan Compiler

Mendeteksi fungsi yang sering dipanggil (_hot functions_) selama eksekusi berjalan. TurboFan akan mengompilasi bytecode fungsi tersebut secara langsung menjadi kode mesin tingkat rendah yang dioptimalkan secara agresif berdasarkan tipe data historis yang dilewatkan.

### 4.3 Hidden Classes (Shapes) & Inline Caching (IC)

JavaScript adalah bahasa dinamis tanpa deklarasi tipe data statis. Untuk mempercepat akses properti objek, V8 membuat **Hidden Classes** secara internal di memori C++:

```javascript
function Point(x, y) {
  this.x = x
  this.y = y
}
const p1 = new Point(1, 2)
const p2 = new Point(3, 4) // p1 dan p2 berbagi hidden class yang sama (Shape A)
```

- **Inline Caching (IC)**: V8 mengingat offset memori fisik dari properti `x` pada objek dengan _Shape A_. Pada pemanggilan berikutnya, V8 langsung membaca offset memori tersebut tanpa melakukan pencarian hash tabel properti yang lambat.
- **Deoptimasi**: Jika tipe data input mendadak berubah (misal: objek baru memiliki struktur properti berbeda), TurboFan terpaksa membuang kode mesin hasil optimasi (_deoptimize_) dan kembali ke interpreter Ignition (_bailout_), menurunkan performa eksekusi secara dramatis.

---

## 5. Integrasi WebAssembly (Wasm) & Batas Keamanan

WebAssembly (Wasm) menyediakan format instruksi biner dengan performa mendekati native untuk dijalankan di dalam sandbox browser.

### 5.1 Pipeline Eksekusi Wasm

Wasm dieksekusi menggunakan modul khusus di dalam V8:

1. **Liftoff**: Compiler dasar (_baseline compiler_) Wasm yang menghasilkan kode mesin dalam milidetik tanpa optimasi (kecepatan startup tinggi).
2. **TurboFan**: Mengambil alih untuk mengompilasi ulang fungsi Wasm menjadi kode mesin dengan performa optimal.

### 5.2 Sandbox Security Boundary

Keamanan WebAssembly dijamin oleh arsitektur memori terisolasi:

- **Linear Memory**: Wasm tidak memiliki akses ke pointer memori JavaScript atau sistem operasi. Seluruh akses memori Wasm dibatasi di dalam sebuah array byte terisolasi (_ArrayBuffer_) yang besar ukurannya ditentukan saat inisialisasi.
- **No Direct DOM Access**: Wasm tidak dapat mengakses DOM secara langsung. Semua interaksi harus melewati perantara fungsi JavaScript (melalui WebAssembly System Interface - WASI atau jembatan JS binding).
- **Control Flow Integrity (CFI)**: Alamat lompatan eksekusi fungsi dibatasi keras hanya ke tabel fungsi yang dideklarasikan saat kompilasi, mencegah eksploitasi perusakan memori tingkat rendah (_buffer overflow_) untuk membajak pointer eksekusi.

---

## 6. Koneksi ke Vault

| Catatan                                    | Hubungan                                                                                    |
| ------------------------------------------ | ------------------------------------------------------------------------------------------- |
| [[browser-security-exploitation-deepdive]] | Eksploitasi kerentanan memori pada V8 (seperti _Type Confusion_) untuk keluar dari sandbox. |
| [[compiler-design-deepdive]]               | Teori parser, lexer, AST, dan optimasi JIT yang diimplementasikan pada V8.                  |
| [[http-protocol-deepdive]]                 | Penanganan data biner HTML/CSS yang dikirim melalui jalur HTTP TCP/IP.                      |
