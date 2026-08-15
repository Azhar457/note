---
title: Object-Oriented Programming Deep Dive — Dari Prinsip ke Praktik
tags:
  - oop
  - programming-paradigm
  - solid
  - inheritance
  - polymorphism
  - design
aliases:
  - object-oriented-programming-deepdive
created: '2026-08-04'
updated: '2026-08-04'
status: pending
cssclasses:
  - wide-table
  

---

# 🧩 Object-Oriented Programming Deep Dive — Dari Prinsip ke Praktik

> **Bedah OOP bukan sekadar 4 pilar (encapsulation, inheritance, polymorphism, abstraction) — tapi *mengapa* paradigma ini lahir, *kapan* cocok, dan *kapan* justru salah alat.** Termasuk perbandingan dengan FP (functional programming), masalah inheritance vs composition, SOLID, dan trade-off di dunia nyata. Untuk peta paradigma, lihat [[00_Atlas/hierarchy-software-engineering-paradigm]]. Untuk pola desain, lihat [[design-patterns-gof]].

---

## Daftar Isi

- [[#1. Kenapa OOP Ada — Masalah yang Mau Diselesaikan]]
- [[#2. Empat Pilar — Anatomi Sebenarnya]]
- [[#3. Inheritance vs Composition — Kontroversi Abadi]]
- [[#4. SOLID — Lima Prinsip yang (Sering) Disalahpahami]]
- [[#5. OOP vs FP — Bukan Perang, Tapi Spektrum]]
- [[#6. Polimorfisme dalam Praktek]]
- [[#7. Anti-Pattern yang Umum]]
- [[#8. Kapan OOP Justru Salah]]
- [[#9. Roadmap Belajar]]

---

## 1. Kenapa OOP Ada — Masalah yang Mau Diselesaikan

### 1.1 Sejarah Singkat

```text
1950s: Assembly — no abstraction
1960s: Procedural (C) — fungsi + data terpisah
1970s: Simula 67 — konsep "class" pertama (simulasi)
1980s: Smalltalk — OOP murni, message passing
1985+: C++ — OOP + performa
1990s: Java — OOP "wajib", enterprise adoption
2000s+: Python/Ruby/JS — OOP fleksibel + FP features
2010s+: Rust/Go — composition-first, OOP "tanpa inheritance"
```

**Masalah yang OOP jawab:** prosedural gagal saat program > 100K LOC — data terpisah dari fungsi → siapa yang ubah state ini? Siapa yang validasi? OOP **bind state + behavior** dalam satu unit (object) → modularity, reusability, maintainability.

### 1.2 Analogi Mental yang Tepat

```text
BUKAN: "OOP = dunia nyata, class Kucing turunan class Hewan"
TAPI:  "OOP = kontrak + state + behavior dalam satu boundary"

┌─────────────────────────────┐
│  BankAccount (boundary)     │
│  ─────────────────────────  │
│  state: balance: f64        │
│  behavior: deposit(x)       │
│           withdraw(x)       │
│           get_balance()     │
│  ─────────────────────────  │
│  invariant: balance >= 0    │
└─────────────────────────────┘
        ▲
        │ 1 class = 1 boundary
        │ invariant dijaga di dalam
```

**Kunci:** OOP itu tentang **boundary + invariant**, bukan tentang meniru alam.

---

## 2. Empat Pilar — Anatomi Sebenarnya

### 2.1 Encapsulation — Bukan Sekadar `private`

```java
// ❌ Salah paham: private field = encapsulation
public class User {
    private String name;
    public String getName() { return name; }
    public void setName(String n) { this.name = n; }  // setter tanpa validasi!
}

// ✅ Encapsulation = invariant dijaga
public class User {
    private String name;
    public User(String name) {
        if (name == null || name.isBlank())
            throw new IllegalArgumentException("Name required");
        this.name = name;
    }
    public String getName() { return name; }
    // TIDAK ADA setName — name immutable setelah konstruksi
}
```

**Encapsulation =** menyembunyikan representasi internal + **menjaga invariant** di satu tempat. Getter/setter generik BUKAN encapsulation — itu field publik berjubah.

### 2.2 Inheritance — Pewarisan dengan Hati-Hati

```java
// Kapan inheritance OK:
// 1. IS-A benar-benar berlaku (subclass substitutable)
// 2. Behavioral extension (template method)
// 3. Shared immutable contract

abstract class PaymentProcessor {
    public final Result process(Payment p) {
        validate(p);            // hook
        Result r = execute(p);  // abstract — subclass implement
        notify(p);              // hook
        return r;
    }
    abstract Result execute(Payment p);
}
```

### 2.3 Polymorphism — Satu Interface, Banyak Perilaku

```java
interface PaymentMethod {
    void pay(Money amount);
}
class CreditCard implements PaymentMethod { public void pay(Money m) { /* cc logic */ } }
class GoPay implements PaymentMethod     { public void pay(Money m) { /* gopay logic */ } }
class QRIS implements PaymentMethod      { public void pay(Money m) { /* qris logic */ } }

// Caller gak perlu tau detail — DIP (Dependency Inversion)
void checkout(PaymentMethod method, Money amount) {
    method.pay(amount);  // dispatch dinamis
}
```

### 2.4 Abstraction — Kontrak, Bukan Implementasi

```text
Abstraction = "apa yang dilakukan" (contract)
Implementation = "bagaimana melakukannya"

Client code → interface → implementation
   ↓                ↓            ↓
 checkout()     PaymentMethod   CreditCard.goPay()
```

---

## 3. Inheritance vs Composition — Kontroversi Abadi

### 3.1 Masalah Klasik Inheritance

```java
// ❌ Deep hierarchy — fragile, rigid, opaque
class Bird { void fly() {} }
class Penguin extends Bird {}  // Penguin gak bisa fly! LSP violation
class Ostrich extends Bird {}  // sama

// ❌ Diamond problem (C++)
class A { void f() {} }
class B extends A {}
class C extends A {}
class D extends B, C {}  // f() mana yang dipakai?
```

**"Favor composition over inheritance" (GoF):**

```java
// ✅ Composition
class Penguin {
    private final Movement movement;  // inject behavior
    Penguin(Movement m) { this.movement = m; }
}

interface Movement { void move(); }
class Swim implements Movement { public void move() { /* swim */ } }
class Fly  implements Movement { public void move() { /* fly */ } }
class Walk implements Movement { public void move() { /* walk */ } }
```

### 3.2 Matrix Keputusan

| Skenario | Pilih | Kenapa |
|----------|-------|--------|
| Subclass **memang** subtype (Cat → Animal) + behavior extends | Inheritance | IS-A valid, template method |
| Cuma mau pakai ulang method | **Composition** | Decouple, testable |
| Behavior berubah runtime | **Composition** | Strategy pattern |
| Deep hierarchy (>3 level) | **Composition** | Fragile base class |
| Framework callback (Android Activity, React component) | Inheritance (forced) | Framework contract |

---

## 4. SOLID — Lima Prinsip yang (Sering) Disalahpahami

| Prinsip | Nama | Inti | Sering Disalahpahami Sebagai |
|---------|------|------|------------------------------|
| **S** | Single Responsibility | 1 class = 1 alasan berubah | "1 class = 1 fungsi" ❌ |
| **O** | Open/Closed | Extend tanpa modify | "Harus pakai inheritance" ❌ |
| **L** | Liskov Substitution | Subclass substitutable | "Subclass harus punya semua method" ❌ |
| **I** | Interface Segregation | Client jangan dipaksa depend ke method yang gak dipakai | "1 method per interface" ❌ |
| **D** | Dependency Inversion | Depend ke abstraction, bukan concrete | "Harus pakai DI framework" ❌ |

### 4.1 S — Contoh Benar

```java
// ❌ 3 alasan berubah: format, persistence, validation
class ReportService {
    void generateReport() { /* format */ }
    void saveToDb()       { /* persistence */ }
    void validate()       { /* validation */ }
}

// ✅ 3 class, 3 alasan berubah
class ReportFormatter { String format(Data d); }
class ReportRepository { void save(Report r); }
class ReportValidator { void validate(Data d); }
```

### 4.2 L — Contoh Benar

```java
// LSP: subclass harus bisa menggantikan parent tanpa break behavior
class Rectangle { void setWidth(int w); void setHeight(int h); }
class Square extends Rectangle {  // ❌ Square setWidth juga ubah height → LSP violation
    void setWidth(int w) { super.setWidth(w); super.setHeight(w); }
}

// ✅ Solusi: jangan paksa hierarki. Square bukan Rectangle (dari sisi mutable behavior)
class Shape { abstract int area(); }
class Rectangle extends Shape { /* w,h */ }
class Square extends Shape { /* s */ }
```

---

## 5. OOP vs FP — Bukan Perang, Tapi Spektrum

| Aspek | OOP | Functional |
|-------|-----|------------|
| State | Mutable, encapsulated | Immutable, explicit |
| Unit | Object (state+behavior) | Function (pure) |
| Data flow | Message passing | Pipeline / composition |
| Side effects | Dikendalikan per class | Dikarantina (IO monad) |
| Concurrency | Shared state + lock | Immutable → lock-free |
| Testing | Mock dependency | Pure function = trivial |
| Bahasa | Java, C++, Python, Ruby | Haskell, Elixir, Clojure |
| Hybrid | — | Rust, Scala, Kotlin, JS/TS, modern Python |

**Realita 2026:** Hampir semua codebase produksi **hybrid**. Contoh: Rust = struct + trait (OOP-ish) tapi ownership/borrow (FP-ish); TypeScript = class + functional utility; Python = class + dataclass + functools.

---

## 6. Polimorfisme dalam Praktek

### 6.1 Dispatch Mechanism

```text
Static dispatch (compile-time):
  C++ templates, Rust generics, Java generics (erasure)
  → Zero overhead, tapi binary bloat

Dynamic dispatch (runtime):
  C++ virtual, Java interface, Rust trait objects (dyn Trait)
  → vtable lookup, 1 indirection, fleksibel

```

### 6.2 Contoh Rust — Trait (OOP Tanpa Inheritance)

```rust
trait Payment {
    fn pay(&self, amount: u64);
}

struct CreditCard { number: String }
impl Payment for CreditCard {
    fn pay(&self, amount: u64) { /* cc */ }
}

struct GoPay { balance: u64 }
impl Payment for GoPay {
    fn pay(&self, amount: u64) { /* gopay */ }
}

// Static dispatch (generics)
fn checkout_static<P: Payment>(p: &P, amount: u64) { p.pay(amount); }

// Dynamic dispatch (trait object)
fn checkout_dyn(p: &dyn Payment, amount: u64) { p.pay(amount); }
```

---

## 7. Anti-Pattern yang Umum

| Anti-Pattern | Gejala | Fix |
|--------------|--------|-----|
| **God Object** | 1 class ngurus segalanya | SRP → pecah |
| **Bean Class** | Class cuma getter/setter tanpa behavior | Domain logic masuk ke class |
| **Deep Hierarchy** | 5+ level inheritance | Composition |
| **Circle Dependency** | A→B→A | Interface + DI container |
| **Anemic Domain Model** | Entity tanpa method, logic di service | Domain model enrichment |
| **Premature Abstraction** | Interface 1 implementasi | YAGNI — tambah interface saat butuh 2 impl |
| **Sequential Coupling** | Method harus dipanggil urutan tertentu | Builder pattern / state machine |

---

## 8. Kapan OOP Justru Salah

```text
✅ OOP cocok:
- Domain kompleks dengan state + invariant (bank, e-commerce, game)
- Long-lived codebase yang butuh maintainability
- Tim besar dengan boundary jelas

❌ OOP berlebihan:
- Script/CLI sekali pakai → prosedural cukup
- Data pipeline / ETL → FP pipeline lebih jelas
- High-performance hot loop → struct of arrays, bukan object graph
- Stateless microservice → function handler cukup
```

---

## 9. Roadmap Belajar

```text
L1: Syntax (class, object, method) → buat CRUD sederhana
L2: 4 pilar + getter/setter vs encapsulation → refactor kode lama
L3: Composition vs inheritance → pola Strategy, Template
L4: SOLID → review codebase real, identifikasi violation
L5: Design patterns (GoF) → pola per masalah
L6: Architecture (DDD, hexagonal) → boundary di level sistem
```

---

## Cross-Link

- **Paradigma** → [[00_Atlas/hierarchy-software-engineering-paradigm]]
- **Design Patterns** → [[design-patterns-gof]]
- **Clean Code** → [[clean-code-robert-martin]], [[the-pragmatic-programmer]]
- **Refactoring** → [[refactoring-martin-fowler]]
- **Master Index** → [[master-index]]

---

*OOP Deep Dive · Boundary > Alam Nyata · Encapsulation = Invariant · Inheritance = Hati-Hati · Composition First · SOLID = Konteks · Hybrid = Realita · YAGNI = Abstraksi*
---

audited
---
