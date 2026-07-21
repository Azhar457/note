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
status: active
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
