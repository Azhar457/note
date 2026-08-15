---
title: "Structure and Interpretation of Computer Programs (SICP)"
tags:
  - functional-programming
  - abstraction
  - mit
  - programming-language
  - metacircular-evaluator
aliases:
  - "SICP"
  - "Wizard Book"
created: 2026-07-05
updated: 2026-07-05
status: pending
cssclasses:
  - wide-table
  

---

# 🔬 Structure and Interpretation of Computer Programs
> Harold Abelson & Gerald Jay Sussman (MIT) — 1985

**Tesis:** Programming bukan soal syntax — tentang **abstraksi, composition, dan metamorfosis data/makna tugas**.

---

## 📌 Kenapa Penting

- Bukan buku "cara pake X" — *fundamental CS thinking*
- Metacircular evaluator: interpreter Lisp in Lisp — pemahaman terdalam soal "gimana bahasa programming jalan"
- Baca buku ini → mindset berubah selamanya soal desain, abstraksi, dan state

## 🎯 Key Takeaways

**1. Abstraksi dengan Procedures**
- Higher-order procedures: fungsi yang nerima/return fungsi
- *Lambda the ultimate* — closure, lexical scoping
- Baris kode lebih sedikit, lebih deklaratif, lebih general

**2. Abstraksi dengan Data**
- Data is "procedures with a contract" — pareng-prinsip apung
- Representasi data abstrak — jangan expose implementasi
- Tagged data + dispatch = polymorphism sebelum OOP

**3. Modularitas, Object, dan State**
- Assignment (set!) ngasih power tapi ngerusak referential transparency
- **Stream** sebagai infinite data structure — lazy evaluation
- Mengganti state dengan stream menghilangkan waktu

**4. Metacircular Evaluator**
- Bikin interpreter Lisp sendiri — cuma ~100 baris
- Paham: eval → apply cycle, environment model, special forms

**5. Register Machines**
- Kompiler → implementasi di level mesin
- Bikin compiler dari Lisp ke register machine
- Lihat sendiri gimana *abstraction* di-compile ke *mechanical steps*

## 📖 Bab Penting

| Bab | Judul | Mengapa |
|-----|-------|---------|
| 1 | Building Abstractions with Procedures | Rekursive process vs iterative, higher-order functions — wajib |
| 2 | Building Abstractions with Data | Data abstraction, closures, symbolic data |
| 3 | Modularity, Objects, and State | Assignment + stream — filosofi state management |
| 4 | Metacircular Evaluator | **Pièce de résistance** — gimana interpreter kerja |
| 5 | Computing with Register Machines | Compiler — full stack dari Lisp ke hardware |

## ⚠️ Tantangan

- **Bahasa:** Scheme (dialek Lisp). Kalo belum pernah functional → kurva curam
- **Math-heavy** — ekspektasi familiar sama matematika diskrit
- **Buku teks** — butuh komitmen, bukan beach read
- **Source:** Free online alias, di mitpress.mit.edu/sicp/

## 🚦 Strategi Baca

1. Jangan dibaca cover-to-cover kaya novel
2. **Chapter 1** + latihan — fondasi
3. **Chapter 2 (2.1-2.3)** — data abstraction
4. **Chapter 4** — metacircular evaluator (mind-blowing moment)
5. Latihan kunci: ex 1.11-1.13 (recursive vs iterative), ex 2.4-2.6 (Church numerals), ex 4.3-4.7 (variants of eval)

## 🔗 Koneksi

- [[clrs-introduction-to-algorithms]] — sama-sama soal pemikiran komputasional
- [[clean-code-robert-martin]] — prinsip abstraksi di SICP keliatan di kata' Uncle Bob

## ✅ Checklist

- [ ] Kerjakan minimal 10 latihan dari Chapter 1
- [ ] Baca metacircular evaluator (Chapter 4) — run through sample sesi jeda
- [ ] Terapkan higher-order functions di codebase harian
- [ ] Abstraction retrofit: cari kode yang "leaky abstraction" dan perbaiki
## Deepdive — SICP: Konsep Kunci & Implementasi

### 1. Tiga Pilar SICP

| Pilar | Konsep | Example |
|-------|--------|---------|
| **Abstraksi Prosedur** | Fungsi sebagai black box | `(define (square x) (* x x))` |
| **Abstraksi Data** | Data diakses via interface | `(cons 1 2)` → pair |
| **Metalinguistic Abstraction** | Bahasa di atas bahasa | Evaluator = interpreter |

### 2. Evaluator (Bab 4) — Interpreter Mini

```scheme
;; Evaluator inti (metacircular)
(define (eval exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((lambda? exp) (make-procedure
                         (lambda-parameters exp)
                         (lambda-body exp) env))
        ((begin? exp) (eval-sequence (begin-actions exp) env))
        ((application? exp)
         (apply (eval (operator exp) env)
                (list-of-values (operands exp) env)))
        (else (error "Unknown expression type" exp))))
```

### 3. Environment Model (Bab 3)

```
Global env
  ├── + → primitive
  ├── square → procedure
  └── a → 1

Procedure call: new frame (parameter binding)
  └── parent = definisi env
    ↓
Lexical scoping: variabel dicari di frame → parent → ... → global
```

### 4. Streams & Lazy Evaluation

```scheme
;; Stream = list tak hingga (lazy)
(define (integers-starting-from n)
  (cons-stream n (integers-starting-from (+ n 1))))
(define integers (integers-starting-from 1))

;; Stream filter (contoh: prime)
(define (stream-filter pred stream)
  (cond ((stream-null? stream) the-empty-stream)
        ((pred (stream-car stream))
         (cons-stream (stream-car stream)
                      (stream-filter pred (stream-cdr stream))))
        (else (stream-filter pred (stream-cdr stream)))))
```

### 5. Concurrency (Bab 3.4)

| Issue | Deskripsi | Solusi |
|-------|-----------|--------|
| **Race condition** | 2 proses ubah shared state | Mutex, atomic op |
| **Deadlock** | Saling tunggu lock | Ordering, timeout |
| **Serializability** | Sequence harus konsisten | Serializer (queue) |

### 6. Register Machine (Bab 5)

```
Compiler target: register machine
  ├── Registers: continue, val, proc, argl, env
  ├── Stack: save/restore
  └→ Controller: instruksi (assign, test, branch)

Evolusi: interpreter → compiler → machine code
  ├── Interpreter: eval langsung (loop)
  ├── Compiler: translate ke instruksi (static)
  └→ Machine: eksekusi hardware
```

## Referensi
- SICP (Buku) — https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book.html
- SICP Lecture (MIT 6.001) — https://ocw.mit.edu/courses/6-001-structure-and-interpretation-of-computer-programs-spring-2005/
- SICP in Python — https://composingprograms.com/

### 7. SICP Modern Relevance

| Konsep SICP | Modern Equivalent |
|-------------|-------------------|
| **Metacircular evaluator** | Compiler, interpreter design |
| **Environment model** | Closure, lexical scoping (JS/Python) |
| **Message passing** | OOP, actor model (Erlang/Akka) |
| **Stream** | Generator (Python), lazy seq (Haskell/Clojure) |
| **Register machine** | VM, bytecode, WASM |
| **Concurrency (serializer)** | Mutex, lock, CAS (atomic) |
| **Lazy evaluation** | Thunk, promise, async/await |

### 8. Exercise Key Answers

1. Exercise 1.16: Iterative exponentiation (log n) — gunakan invariant quantity.
2. Exercise 2.18: reverse list (iterative, tail recursion).
3. Exercise 3.1: make-accumulator (closure + mutable state).
4. Exercise 4.1: evaluator left-to-right vs right-to-left ordering.

## Referensi Tambahan
- SICP Solutions — https://github.com/zv/SICP
- SICP Clojure — https://github.com/sicp
- Structure and Interpretation (MIT 6.001 video) — https://ocw.mit.edu/

### 9. SICP dalam Bahasa Indonesia

SICP (Structure and Interpretation of Computer Programs) adalah buku legendaris MIT yang mengajarkan fundamental computation: bagaimana membangun abstraksi, cara mengevaluasi ekspresi, bagaimana state dan environment bekerja, dan bagaimana bahasa pemrograman dibangun dari primitif. Meskipun menggunakan Scheme (Lisp), konsepnya universal: closure, lexical scope, lazy evaluation, metacircular evaluator, register machine.

### 10. Mengapa SICP Masih Relevan (2026)

1. Foundation: framework moderne (React hooks, effect system, compiler design) semua punya root di SICP.
2. Abstraksi: jembatan antara matematika (lambda calculus) dan engineering (compiler).
3. Metalinguistic: "program yang menulis program" = macro, codegen, LLM prompt.
4. Model: environment model = scope chain JavaScript; stream = generator Python.
---

audited
---
