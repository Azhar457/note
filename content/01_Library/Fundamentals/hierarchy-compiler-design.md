---
tags:
  - hierarchy
  - compiler
  - programming-language
  - llvm
  - parser
  - optimization
aliases:
  - Compiler Design Hierarchy
  - Compiler Architecture
  - From Source to Machine Code
  - Compiler Pipeline Stack
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🧊 Compiler Design — Dari Source Code ke Machine Code

> [!tip] Compiler adalah jembatan antara manusia dan mesin — menerjemahkan bahasa tingkat tinggi (C, Rust, Java, Go) menjadi instruksi mesin (x86, ARM, RISC-V). Catatan ini memetakan **6 fase kompilasi klasik + 1 fase modern** dari lexing hingga machine code generation, backend optimasi (LLVM, GCC), dan teknik frontend/backend yang membedakan compiler production-grade. Ini adalah domain yang **sama sekali belum tersentuh di vault** — sebuah dasar Computer Science yang hilang.

---

## Daftar Isi

1. [[#1. Premise — Compiler: Penerjemah Paling Rumit yang Pernah Dibuat]]
2. [[#2. Seven-Phase Compiler Pipeline]]
3. [[#3. Fase 1 — Lexical Analysis (Scanner)]]
4. [[#4. Fase 2 — Syntax Analysis (Parser)]]
5. [[#5. Fase 3 — Semantic Analysis]]
6. [[#6. Fase 4 — Intermediate Representation (IR)]]
7. [[#7. Fase 5 — Optimization]]
8. [[#8. Fase 6 — Code Generation]]
9. [[#9. Fase 7 — Modern: JIT & Runtime Compilation]]
10. [[#10. Compiler Architecture: GCC vs LLVM]]
11. [[#11. Trade-off Matrix per Fase]]
12. [[#12. Cross-Reference ke Vault]]
13. [[#References]]

---

## 1. Premise — Compiler: Penerjemah Paling Rumit yang Pernah Dibuat

Setiap baris kode yang kamu tulis melewati **7 fase transformasi** sebelum menjadi instruksi mesin:

```
Source Code
    ↓
[Lexer]  → Token stream
    ↓
[Parser]  → AST (Abstract Syntax Tree)
    ↓
[Semantic] → Annotated AST / Symbol Table
    ↓
[IR Gen]  → Intermediate Representation
    ↓
[Optimizer] → Optimized IR
    ↓
[Code Gen] → Assembly / Machine Code
```

**Fakta mencengangkan:**
- GCC ~15 juta baris kode (setara kernel Linux versi 2.6)
- LLVM ~5 juta baris kode
- Compiler pertama ditulis Grace Hopper (1952) — A-0 compiler
- Ken Thompson: compiler adalah **the ultimate backdoor** (Thompson Hack 1984) — kompromi compiler bisa mengkompromi setiap program yang dikompilasi

---

## 2. Seven-Phase Compiler Pipeline

| Fase | Input | Output | Tugas Utama |
|:----:|-------|--------|-------------|
| **1. Lexer** | Source code string | Token stream | Pisahkan string menjadi token: keyword, identifier, operator, literal |
| **2. Parser** | Token stream | AST | Bangun pohon sintaks berdasarkan grammar (CFG) |
| **3. Semantic** | AST | Annotated AST | Type checking, scope resolution, symbol table |
| **4. IR Gen** | Annotated AST | IR (e.g., LLVM IR, GIMPLE, Three-Address Code) | Turunkan AST ke bentuk intermediate yang lebih rendah level |
| **5. Opt** | IR | Optimized IR | Transformasi: constant folding, dead code elimination, inlining, loop unrolling |
| **6. CodeGen** | IR | Assembly / Machine Code | Pilih instruksi, alokasi register, jadwalkan instruksi |
| **7. (Modern) JIT** | IR/Bytecode | Runtime machine code | Kompilasi pada saat runtime, adaptif |

---

## 3. Fase 1 — Lexical Analysis (Scanner)

### 3.1 Apa yang Dilakukan

Lexer membaca source code sebagai **raw string** dan mengelompokkan karakter menjadi **tokens**.

**Contoh:**
```c
int x = 42 + y;
```
Menjadi:
```
KEYWORD[int]  IDENTIFIER[x]  OPERATOR[=]  LITERAL[42]  OPERATOR[+]  IDENTIFIER[y]  SEMICOLON[;]
```

### 3.2 Token Types

| Token Type | Contoh |
|------------|--------|
| Keyword | `if`, `while`, `return`, `int`, `fn`, `let` |
| Identifier | `variable_name`, `functionName`, `x` |
| Literal | `42`, `"hello"`, `3.14`, `true` |
| Operator | `+`, `-`, `*`, `/`, `==`, `&&` |
| Delimiter | `{`, `}`, `;`, `(`, `)`, `[`, `]` |
| Comment | `// ...`, `/* ... */` |

### 3.3 Teknik Implementasi

| Pendekatan | Tools | Use Case |
|------------|-------|----------|
| **Manual** (hand-written) | Nothing | Performance-critical, error messages bagus |
| **Generator-based** | lex (Flex), re2c, Ragel | Grammar stabil, perubahan minimal |
| **Regex-based** | Any regex engine | Prototyping, scripting language |
| **DFA-based** | Automaton | Deterministic — O(n) guarantee |

**State machine internal:**
```
Start → [a-zA-Z_] → Identifier (any alphanumeric + underscore)
      → [0-9] → Integer (0-9)*
      → '"' → StringLiteral (any char except '"')*
      → '/' → Comment (if next char '/' or '*')
```

### 3.4 Pitfalls

| Pitfall | Contoh |
|---------|--------|
| Maximal munch | `++i` — lexer ambil `++` bukan `+ +` |
| Unicode/UTF-8 | Identifiers bisa UTF-8 (Python 3, Golang) |
| String interpolation | `"x = {x}"` — parser bukan lexer |
| Regex ambiguity | Lexer harus deterministic |

---

## 4. Fase 2 — Syntax Analysis (Parser)

### 4.1 Apa yang Dilakukan

Parser menerima **token stream** dan membangun **Abstract Syntax Tree (AST)** berdasarkan grammar bahasa.

**Grammar = Context-Free Grammar (CFG):**
```
Expression  → Term ('+' Term)*
Term        → Factor ('*' Factor)*
Factor      → NUMBER | IDENTIFIER | '(' Expression ')'
```

**AST untuk `2 + 3 * 4`:**
```
      ┌───────┐
      │   +   │
      ├───┬───┤
      │ 2 │ * │
          ├───┤
          │3 4│
          └───┘
```

### 4.2 Parsing Strategies

| Strategy | Contoh Tools | Kelebihan | Kekurangan |
|----------|-------------|-----------|------------|
| **Recursive Descent** (top-down) | Hand-written (Rust, Go) | Error messages bagus, mudah di-debug | Perlu left-factoring |
| **LL(k)** | ANTLR, JavaCC | Linear time, lookahead k tokens | Grammar restriction |
| **LR(1)** | Yacc/Bison, LALR(1) | Powerfull grammar, shift-reduce | Error messages jelek |
| **GLL / GLR** | Elkhound, SGLR | Ambiguous grammar support | Slow, kompleks |
| **Parser Combinator** | Nom (Rust), Parsec (Haskell) | Ekspresif, composable | Performa lebih lambat |

### 4.3 AST vs CST (Concrete Syntax Tree)

| Aspek | CST (Parse Tree) | AST (Abstract Syntax Tree) |
|-------|:----------------:|:--------------------------:|
| Terminals | ✅ Termasuk semua | ❌ Tidak termasuk (semikolon, kurung) |
| Non-terminals | ✅ Semua aturan | ✅ Hanya yang relevan |
| Size | Besar (redundan) | Kecil (esensial) |
| Use | Language spec | Compiler internal |

---

## 5. Fase 3 — Semantic Analysis

### 5.1 Apa yang Dilakukan

Memastikan program **bermakna secara logis** — bukan hanya sintaks benar.

**Pemeriksaan:**
- **Type checking** — `"hello" + 42`? ❌ (kebanyakan bahasa)
- **Scope resolution** — variabel dideklarasikan sebelum dipakai
- **Borrow checking** — Rust: reference tidak outlive owner
- **Lifetime analysis** — Rust: dangling pointer di compile-time
- **Name resolution** — fungsi dipanggil dengan jumlah argumen tepat
- **Constant folding** — `2 + 3` → `5` (early optimization)

### 5.2 Type Systems (dari compiler perspective)

| Type System | Bahasa | Compiler Action |
|-------------|--------|-----------------|
| **Static** | C, Rust, Java, Go | Semua tipe diketahui di compile-time |
| **Dynamic** | Python, Ruby, JS | Type checking di runtime |
| **Gradual** | TypeScript, Python (mypy) | Static check + dynamic fallback |
| **Hindley-Milner** | Haskell, OCaml, SML | Inference: compiler bisa menentukan tipe tanpa anotasi |

### 5.3 Symbol Table

Struktur data paling penting di fase ini:
```
┌──────────────────────┐
│ Global Scope         │
│   ├─ function: main  │
│   │   └─ params: []  │
│   └─ var: x (int)    │
├──────────────────────┤
│ Function: main       │
│   └─ local: y (int)  │
└──────────────────────┘
```

---

## 6. Fase 4 — Intermediate Representation (IR)

### 6.1 Mengapa IR?

Compiler N bahasa × M arsitektur = N×M frontend+backend. Dengan IR:
```
  Input: C, Rust, Go, Swift, Kotlin
           ↓  ↓     ↓   ↓      ↓
         [Frontend × N]
           ↓  ↓     ↓   ↓      ↓
              [IR — satu format]
           ↓  ↓     ↓   ↓      ↓
         [Backend × M] (x86, ARM, RISC-V, WASM)
```

Total kompleksitas: N + M (bukan N×M).

### 6.2 Bentuk IR

| IR Type | Contoh | Level | Size |
|---------|--------|:-----:|:----:|
| **Three-Address Code (TAC)** | `t1 = a + b; t2 = t1 * c` | Low | ~3× AST |
| **SSA (Static Single Assignment)** | LLVM IR | Low-Med | ~4× AST |
| **GIMPLE** | GCC IR | Medium | — |
| **RTL (Register Transfer Language)** | GCC RTL | Very Low | — |
| **Stack-based bytecode** | JVM `.class`, WASM | Low | Compact |
| **Control Flow Graph (CFG)** | Semua optimizer | Meta | Nodes = basic blocks |

### 6.3 SSA Form — Inovasi Kunci

Setiap variabel **hanya di-assign sekali**:
```llvm
%0 = add i32 %a, %b
%1 = mul i32 %0, %c
%2 = icmp sgt i32 %1, 10
```

Dengan φ-function di join point:
```llvm
%phi = phi i32 [%val1, %bb_true], [%val2, %bb_false]
```

SSA menyederhanakan optimasi secara drastis — **setiap use memiliki single reaching definition**.

### 6.4 IR Comparison: LLVM vs GCC

| Aspek | LLVM IR | GCC GIMPLE |
|-------|---------|------------|
| Format | Textual (`.ll`), Binary (`.bc`) | Internal |
| SSA | ✅ All-pass | ✅ Some passes |
| Type system | First-class (i32, float, ptr) | Less expressive |
| Metadata | Debug, profile, TBAA | Limited |
| Modularity | Per-function at module | Per-function only |

---

## 7. Fase 5 — Optimization

### 7.1 Klasifikasi Optimasi

| Kategori | Contoh | Efek |
|----------|--------|:----:|
| **Local** (basic block) | Constant folding, copy propagation | 5-10% |
| **Global** (function-wide) | Dead code elimination, loop invariant | 10-30% |
| **Inter-procedural** (cross-function) | Inlining, IPO, devirtualization | 10-50% |
| **Profile-guided (PGO)** | Hot/cold splitting, branch prediction | 5-20% |
| **Link-time (LTO)** | Cross-module inlining, alias analysis | 5-15% |

### 7.2 Optimasi Penting

| Optimasi | Mekanisme | Typical Speedup |
|----------|-----------|:---------------:|
| **Constant folding** | `3 + 4` → `7` saat compile | Minimal |
| **Constant propagation** | `const int x = 5; y = x + 2` → `y = 7` | Minimal |
| **Dead code elimination** | Hapus kode yang tidak pernah dijalankan | 1-5% |
| **Loop unrolling** | Duplikasi body loop untuk mengurangi overhead iterasi | 2-10% |
| **Inlining** | Ganti function call dengan body function | 5-20% |
| **Vectorization** | SIMD: proses 4 int sekaligus | 2-4× |
| **Strength reduction** | `x * 2` → `x << 1` | Marginal |
| **Common subexpression** | Hitung `a + b` sekali, reuse | 1-5% |

### 7.3 Trade-off Optimasi

| Level GCC/Clang | Waktu Kompilasi | Kinerja Runtime | Debuggability |
|:--------------:|:---------------:|:---------------:|:-------------:|
| O0 | Tercepat | Terlambat | ✅ Full |
| O1 | Cepat | Medium | ✅ Mostly |
| O2 | Medium | Tinggi | 🟡 Partial |
| O3 | Lambat | Tertinggi | ❌ |
| Os | Medium | Medium (size) | 🟡 |
| Oz | Lambat | Rendah (size kecil) | ❌ |

---

## 8. Fase 6 — Code Generation

### 8.1 Tugas

Convert IR ke **target-specific assembly/machine code**:

1. **Instruction selection** — pilih instruksi yang cocok untuk IR
2. **Register allocation** — mapping infinite virtual registers → finite physical registers
3. **Instruction scheduling** — urutkan instruksi untuk pipeline efficiency

### 8.2 Register Allocation — Masalah NP-Hard

**Teknik:**
| Teknik | Quality | Speed |
|--------|:-------:|:-----:|
| **Graph coloring** (Chaitin) | High | Slow (NP-hard approximation) |
| **Linear scan** | Medium | Fast (O(n)) |
| **PBQP** | Very high | Slow |
| **Greedy** (LLVM default) | High | Fast |

**Efek:** Buruknya register allocation bisa menyebabkan **spill** — variabel dibuang ke memory dan di-load kembali. Spill cost = 100-200 cycles per load/store.

### 8.3 Peephole Optimization

Optimasi kecil pada jendela 3-5 instruksi berurutan:
```asm
; Before peephole
mov eax, 0
; After peephole
xor eax, eax    ; 1 byte vs 5 byte
```

---

## 9. Fase 7 — Modern: JIT & Runtime Compilation

### 9.1 AOT vs JIT

| Aspek | AOT (Ahead-of-Time) | JIT (Just-in-Time) |
|-------|:-------------------:|:------------------:|
| Waktu kompilasi | Sebelum run | Selama run |
| Startup | Instant | Lambat (kompilasi awal) |
| Optimalisasi | Global | Adaptif (hot paths) |
| Contoh | GCC, Rustc, Go | V8, JVM, LuaJIT |
| Portability | Satu binary per arch | Satu bytecode semua arch |

### 9.2 JIT Pipeline

```
Source → Bytecode → Interpreter (warmup)
                              ↓
                    Hot function detection (tier 1)
                              ↓
                    Simple JIT (tier 2)
                              ↓
                    Optimizing JIT (tier 3)
                              ↓
                    Deoptimization jika asumsi salah
```

**Contoh tier:**
- V8: Ignition (interpreter) → Sparkplug (baseline) → Turbofan (optimizing)
- JVM: Interpreter → C1 (client) → C2 (server, Graal)

### 9.3 Deoptimization

Ketika optimizer membuat **asumsi** (tipe class, monomorphic call) yang ternyata salah di runtime:
- Stack harus "kembali" ke interpreter state
- Semua optimized code yang bergantung pada asumsi itu dibuang

---

## 10. Compiler Architecture: GCC vs LLVM

### 10.1 Perbandingan Arsitektur

| Aspek | GCC | LLVM |
|-------|-----|------|
| **Frontend** | Ada per bahasa (C, C++, Fortran, Ada, D, Go) | Clang (C/C++), rustc (Rust), Swift, flang (Fortran) |
| **IR** | GIMPLE (high) → RTL (low) | LLVM IR (SSA-based) |
| **Optimizer** | Per-pass dengan GIMPLE/RTL | Per-pass pipeline (opt) |
| **Backend** | Target-specific .md files | Target-specific (TableGen) |
| **Lisensi** | GPLv3 | Apache 2.0 (with LLVM exceptions) |
| **Plugin** | GPL-only (GCC plugin) | BSD-friendly |
| **Library** | Monolithic (cc1) | Library-based (libLLVM) |

### 10.2 LLVM Toolchain

```
┌──────────────────────────────────────────────────────┐
│ clang (frontend)                                      │
│   ├─ libclang (C API)                                 │
│   ├─ AST matchers / tooling (clang-tidy, clang-format) │
│   └─ Static analysis (clang-tidy, clangd)             │
├──────────────────────────────────────────────────────┤
│ opt (optimizer)                                       │
│   └─ libLLVM passes                                   │
├──────────────────────────────────────────────────────┤
│ llc (codegen)                                         │
│   ├─ Instruction selection (DAG->DAG)                 │
│   ├─ Register allocation (greedy)                     │
│   └─ Instruction scheduling                           │
├──────────────────────────────────────────────────────┤
│ lld (linker)                                          │
│   ├─ LTO (Link-Time Optimization)                     │
│   └─ ThinLTO (distributed LTO)                        │
├──────────────────────────────────────────────────────┤
│ compiler-rt (runtime)                                 │
│   ├─ Sanitizers (ASan, TSan, UBSan, MSan)             │
│   └─ Profile-guided optimization runtime              │
└──────────────────────────────────────────────────────┘
```

### 10.3 GCC vs LLVM: Trade-off

| Kriteria | Pilih GCC | Pilih LLVM |
|----------|-----------|------------|
| Performance (SPEC) | Slightly better (1-3%) | Slightly better (1-3%) |
| Error messages | Good | Excellent (Clang) |
| Compile speed | Slower | Faster |
| Binary size | Smaller (with -Os) | Slightly larger |
| Cross-compilation | Complex | Simple (single sysroot) |
| Tools ecosystem | Limited | Rich (clangd, clang-tidy, Asan) |
| Language support | C/C++/Fortran/Ada/D/Go | C/C++/Rust/Swift/Kotlin/Haskell |

---

## 11. Trade-off Matrix per Fase

| Fase | Complexity | Debug Cost | Optimasi Potensial | Bottleneck |
|:----:|:----------:|:----------:|:------------------:|:----------:|
| **Lexer** | Low | Low | None | UTF-8 processing |
| **Parser** | Medium | Low | None (must be correct) | Recursive descent overflow |
| **Semantic** | Medium-High | Medium | Type errors catch early | Template monomorphization |
| **IR Gen** | Medium | Medium | IR quality affects all later passes | Memory (IR bloat) |
| **Opt** | Very High | Very High | 2-10× performance | Compile time (O3) |
| **CodeGen** | High | High | 1-3× performance | Register allocation |
| **JIT** | Very High | Very High | Adaptive 10×+ | Deoptimization overhead |

---

## 12. Cross-Reference ke Vault

| Konsep | Catatan Vault |
|--------|---------------|
| **Programming Language Evolution** | [[hierarchy-programming-language]] — Evolusi bahasa yang dikompilasi |
| **Type Systems** | [[hierarchy-software-engineering-paradigm]] — Paradigma dan type system |
| **WebAssembly (WASM)** | [[hierarchy-package-managers]] — WASM sebagai target baru compiler |
| **Compiler Security (Thompson Hack)** | [[hierarchy-cybersecurity-defense-architecture]] — Supply chain attack |
| **Rust Compiler** | [[rust-systems-programming-tooling-keamanan]] — Rustc sebagai LLVM frontend |
| **Optimization & Performance** | [[hierarchy-memory-storage]] — Cache hierarchy dan optimasi |
| **eBPF Verification** | [[ebpf-kernel-security]] — eBPF verifier sebagai compiler mini |

---

## References

1. Aho, A., Sethi, R., Ullman, J. *"Compilers: Principles, Techniques, and Tools (The Dragon Book)."* 2nd ed., Pearson, 2006.
2. Muchnick, S. *"Advanced Compiler Design and Implementation."* Morgan Kaufmann, 1997.
3. Appel, A. *"Modern Compiler Implementation in ML/Java/C."* Cambridge, 1998.
4. Lattner, C. *"LLVM: An Infrastructure for Multi-Stage Optimization."* Master's Thesis, 2002.
5. Cooper, K. & Torczon, L. *"Engineering a Compiler."* 3rd ed., Morgan Kaufmann, 2022.
6. Cytron, R. et al. *"Efficiently Computing Static Single Assignment Form."* TOPLAS, 1991.
7. Chaitin, G. *"Register Allocation via Coloring."* 1982.
8. Wimmer, C. & Mössenböck, H. *"Linear Scan Register Allocation on SSA Form."* 2005.
9. GCC Team. *"GNU Compiler Collection Internals."* 2024.
10. LLVM Project. *"LLVM Language Reference Manual."* 2024.
11. Thompson, K. *"Reflections on Trusting Trust."* Turing Award Lecture, 1984.
12. Aycock, J. *"A Brief History of Just-in-Time."* ACM Computing Surveys, 2003.
13. Hopper, G. *"The Education of a Computer."* 1952 — first compiler.
