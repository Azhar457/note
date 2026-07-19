---
title: "Compiler Design and Language Engineering Deep-Dive — Lexers, Parsers, LLVM, and JIT/AOT"
tags:
  - compiler-design
  - programming-languages
  - llvm
  - software-engineering
  - compilation
aliases:
  - "compiler-design-deepdive"
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Penerjemahan kode dari bahasa tingkat tinggi manusia ke instruksi mesin sirkuit silikon adalah hasil rekayasa perangkat lunak paling kompleks. Catatan ini membedah arsitektur compiler, dari analisis leksikal, representasi sintaksis (AST), optimasi SSA, hingga backend LLVM, melengkapi pembahasan [[hierarchy-programming-language]] dan [[refactoring-martin-fowler]].

## Daftar Isi

1. [Fase Kompilasi Kontemporer](#1-fase-kompilasi-kontemporer)
2. [Analisis Leksikal & Sintaksis (Lexing, Parsing, AST)](#2-analisis-leksikal--sintaksis-lexing-parsing-ast)
3. [Intermediate Representation (IR) & SSA Form](#3-intermediate-representation-ir--ssa-form)
4. [Optimasi Kode & LLVM Internals](#4-optimasi-kode--llvm-internals)
5. [Manajemen Memori Otomatis: GC vs Borrow Checker](#5-manajemen-memori-otomatis-gc-vs-borrow-checker)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Fase Kompilasi Kontemporer

Arsitektur compiler modern dipisah secara tegas menjadi dua bagian utama untuk mendukung modularitas multi-bahasa dan multi-arsitektur CPU:

```
                  ┌───────────────────────────────┐
                  │          Source Code          │
                  └──────────────┬────────────────┘
                                 │
   Frontend                      ▼ (Analisis Sintaksis & Leksikal)
                  ┌───────────────────────────────┐
                  │    AST (Abstract Syntax Tree) │
                  └──────────────┬────────────────┘
                                 │
                                 ▼ (Semantic Analysis)
                  ┌───────────────────────────────┐
                  │  IR (Intermediate Rep) / SSA  │
                  └──────────────┬────────────────┘
                                 │
   Optimizer                     ▼ (Dead Code Elim, Loop Unroll, dll)
                  ┌───────────────────────────────┐
                  │          Optimized IR         │
                  └──────────────┬────────────────┘
                                 │
   Backend                       ▼ (Target Code Gen: x86/ARM/RISC-V)
                  ┌───────────────────────────────┐
                  │         Machine Code          │
                  └───────────────────────────────┘
```

- **Frontend**: Menganalisis kode sumber, memvalidasi tipe data, dan memetakan struktur kode menjadi Representasi Perantara (_Intermediate Representation_ - IR).
- **Optimizer**: Mengubah IR menjadi bentuk yang lebih efisien (lebih cepat dieksekusi, konsumsi RAM minimum) tanpa mengubah logika semantiknya.
- **Backend**: Menerjemahkan IR hasil optimasi menjadi bahasa instruksi mesin spesifik untuk CPU target (seperti assembly x86, ARM, atau RISC-V).

---

## 2. Analisis Leksikal & Sintaksis (Lexing, Parsing, AST)

### 2.1 Lexical Analysis (Lexer)

Lexer memindai karakter mentah kode sumber dari kiri ke kanan dan mengelompokkannya menjadi token bermakna menggunakan ekspresi reguler (Regex) yang dikonversi ke **DFA (Deterministic Finite Automata)** secara internal.

```
Kode Mentah: "let x = 10;"
Token: [LET, IDENTIFIER("x"), ASSIGN, NUMBER(10), SEMICOLON]
```

### 2.2 Syntax Analysis (Parser)

Parser mengambil token-token hasil lexing dan membangun struktur hierarki pohon yang mewakili struktur tata bahasa pemrograman tersebut, yang dinamakan **AST (Abstract Syntax Tree)**.

Parser modern menggunakan algoritma penguraian rekursif:

- **LL(k)**: Parser _top-down_ yang memproses token dari kiri ke kanan dengan melihat ke depan sebanyak $k$ token untuk memprediksi arah penguraian.
- **LR(k) / LALR**: Parser _bottom-up_ yang menggunakan stack untuk menggeser (_shift_) dan mereduksi (_reduce_) token menjadi ekspresi gramatikal yang valid.

Visualisasi AST dari ekspresi `x = 5 + 3`:

```
       Assign (=)
      /          \
  Identifier (x)  Plus (+)
                 /        \
             Number(5)   Number(3)
```

---

## 3. Intermediate Representation (IR) & SSA Form

**SSA (Static Single Assignment)** adalah bentuk IR di mana setiap variabel wajib dideklarasikan tepat **satu kali saja**, dan setiap variabel harus didefinisikan sebelum digunakan. SSA mempermudah optimasi compiler karena dependensi data terlihat jelas secara topologi.

### 3.1 Contoh Transformasi ke SSA Form

Sebelum SSA (Variabel `x` diubah berulang kali):

```
x = 5
x = x + 2
y = x * 2
```

Sesudah SSA (Setiap assignment memiliki nomor versi indeks unik):

```
x1 = 5
x2 = x1 + 2
y1 = x2 * 2
```

### 3.2 Fungsi PHI ($\phi$-node)

Pada percabangan logika (_control flow graph_), variabel dapat menerima nilai dari jalur eksekusi yang berbeda. SSA menggunakan fungsi matematis $\phi$ untuk memilih versi variabel yang benar:

```
// Control Flow
if (condition) {
    x1 = 10
} else {
    x2 = 20
}
x3 = \phi(x1, x2) // Memilih nilai x3 berdasarkan jalur percabangan yang dilalui
```

---

## 4. Optimasi Kode & LLVM Internals

### 4.1 Katalog Optimasi Kunci

- **Dead Code Elimination (DCE)**: Menghapus blok instruksi atau variabel yang tidak pernah digunakan/diakses selama eksekusi sistem.
- **Loop Unrolling**: Menduplikasi badan perulangan secara sequential untuk meminimalkan beban komputasi lompatan instruksi kondisional (_branch overhead_) dan memaksimalkan pemanfaatan cache CPU.
- **Common Subexpression Elimination (CSE)**: Menghindari perhitungan ulang ekspresi matematika yang sama dengan menyimpan hasilnya dalam variabel temporer.

### 4.2 LLVM Internals

**LLVM** adalah infrastruktur compiler modular terpopuler di dunia.

- Frontends seperti **Clang** (C/C++), **rustc** (Rust), atau **swiftc** (Swift) menerjemahkan kode masing-masing ke format **LLVM IR** (bahasa assembly universal abstrak).
- LLVM IR dioptimasi secara agnostik menggunakan ratusan pustaka optimasi LLVM.
- Backend LLVM menerjemahkan LLVM IR yang dioptimasi ke dalam instruksi arsitektur hardware target (x86_64, AArch64, WebAssembly).

---

## 5. Manajemen Memori Otomatis: GC vs Borrow Checker

Bahasa pemrograman tingkat tinggi harus membersihkan data tidak terpakai dari memori Heap agar RAM tidak penuh (_out of memory_).

### 5.1 Garbage Collection (GC)

- **Mark-and-Sweep**: Menelusuri seluruh objek aktif dari root (stack/global variables). Menandai objek yang masih terhubung (_Mark_), lalu memindai seluruh heap untuk menghapus objek yang tidak ditandai (_Sweep_). Algoritma ini memicu jeda aplikasi (_Stop-the-World latency_).
- **Reference Counting**: Setiap objek melacak jumlah referensi yang mengarah kepadanya. Ketika counter mencapai nol, memori objek langsung dibebaskan.
  - _Kelemahan_: Gagal menangani siklus melingkar (_circular references_ - A menunjuk B, B menunjuk A).

### 5.2 Rust Borrow Checker (Kompilasi Tanpa GC)

Rust membuang seluruh kebutuhan runtime GC dan manual `free()` dengan menerapkan sistem kepemilikan memori (_Ownership & Lifetimes_) yang diverifikasi ketat saat proses kompilasi (_compile-time_):

```rust
fn main() {
    let s1 = String::from("jarsWAF"); // s1 adalah pemilik memori heap
    let s2 = s1; // Kepemilikan (ownership) berpindah ke s2

    // println!("{}", s1);
    // ERROR COMPILER! s1 sudah tidak valid lagi dan memorinya tidak bisa diakses.
} // Memorinya dibebaskan secara instan saat s2 keluar dari scope (drop).
```

---

## 6. Koneksi ke Vault

| Catatan                            | Hubungan                                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- |
| [[hierarchy-programming-language]] | Pemetaan dari tingkatan instruksi silikon hingga bahasa tingkat tinggi.                           |
| [[refactoring-martin-fowler]]      | Penataan ulang struktur kode yang mempermudah compiler melakukan optimasi inlining.               |
| [[regular-expressions-deepdive]]   | Dasar matematika regex yang dikonversi menjadi DFA untuk mesin leksikal (lexer).                  |
| [[software-supply-chain-security]] | Kerentanan kompilasi (compiler backdoors/Ken Thompson hack) dan pentingnya _reproducible builds_. |
