---
title: "Functional Programming Deep-Dive"
tags: [functional-programming, programming-paradigm, software-engineering, type-system]
aliases: [FP Deep-Dive, Functional Programming, Pure Functions, Monads]
status: pending
created: 2026-08-04
updated: 2026-08-04
cssclasses:
  - wide-table
  - callout

---

> [!abstract]
> Catatan komprehensif tentang Functional Programming (FP) — paradigma pemrograman yang berpusat pada pure functions, immutability, dan composability. Mencakup fondasi matematis (lambda calculus), type systems (Hindley-Milner, algebraic data types), monads sebagai abstraction untuk effectful computation, serta trade-offs FP vs OOP di industri. Vault sudah punya [[object-oriented-programming-deepdive]] (paradigma pasangan) — catatan ini melengkapi dari sisi functional.

## Daftar Isi
1. [[#1. Fondasi: Lambda Calculus & FP Definition]]
2. [[#2. Pure Functions & Referential Transparency]]
3. [[#3. Immutability & Persistent Data Structures]]
4. [[#4. Higher-Order Functions, Currying & Partial Application]]
5. [[#5. Type Systems: Hindley-Milner & Algebraic Data Types]]
6. [[#6. Monads: Abstraction untuk Effectful Computation]]
7. [[#7. Lazy Evaluation vs Eager Evaluation]]
8. [[#8. FP vs OOP: Trade-off Matrix]]
9. [[#9. Adopsi FP di Industri]]
10. [[#10. FP di Rust: Hybrid Paradigm]]
11. [[#References]]
12. [[#Koneksi ke Vault]]

## 1. Fondasi: Lambda Calculus & FP Definition

Functional programming berakar pada lambda calculus — sistem formal matematika yang dikembangkan oleh Alonzo Church (1930-an) untuk komputasi berdasarkan function abstraction dan application. Setiap ekspresi dalam lambda calculus terdiri dari: variable, abstraction (λx.M), dan application (M N).

Secara praktis, FP adalah paradigma di mana **program adalah composition of pure functions** — bukan sequence of mutations dan state changes. Tidak ada side effects, tidak ada shared mutable state. Setiap fungsi menerima input, menghasilkan output, dan tidak mengubah apa pun di luar scope-nya.

| Konsep Lambda Calculus | Ekuivalen di FP |
|:-----------------------|:----------------|
| λx.M (abstraction) | Function definition `fn(x) -> M` |
| M N (application) | Function call `M(N)` |
| α-conversion | Variable renaming (scope hygiene) |
| β-reduction | Function application / evaluation |
| η-conversion | Extensionality (fn equivalence) |

## 2. Pure Functions & Referential Transparency

**Pure function** adalah fungsi yang memenuhi dua syarat:
1. **Deterministic**: output hanya bergantung pada input — panggil `f(x)` 1000 kali dengan `x` yang sama, hasilnya selalu identik
2. **No side effects**: tidak mengubah state eksternal, tidak melakukan I/O, tidak menulis ke disk, tidak memodifikasi argument

**Referential transparency** adalah properti ekspresi di mana ekspresi bisa diganti dengan nilai hasilnya tanpa mengubah behavior program. Ini konsekuensi langsung dari pure functions:

```
// Referential transparent:
let x = 5;
let y = x + x;    // bisa diganti dengan let y = 10;

// Tidak referential transparent:
let x = counter.increment();
let y = x + x;    // counter.increment() dipanggil 2x? atau 1x?
```

Keuntungan referential transparency: **equational reasoning** — programmer bisa membuktikan program benar dengan substitusi aljabar, bukan tracing runtime state.

## 3. Immutability & Persistent Data Structures

Dalam FP, data tidak pernah di-mutate. Setiap "modification" membuat struktur baru yang berbagi struktur internal yang tidak berubah dengan yang lama — disebut **persistent data structures**.

Contoh: immutable linked list di Haskell:
```haskell
list = [1, 2, 3]
newList = 0 : list    -- newList = [0, 1, 2, 3]
-- list masih [1, 2, 3], tidak berubah
-- newList berbagi ekor dengan list (O(1) prepend, bukan O(n) copy)
```

| Operasi | Mutable (OOP) | Immutable (FP) | Sharing |
|:--------|:--------------|:----------------|:--------|
| List prepend | O(1) | O(1) | Full tail sharing |
| Vector update | O(1) in-place | O(log n) tree | Path copying only |
| Map insert | O(1) amortized | O(log n) HAMT | Structural sharing |
| Set union | O(n) | O(log n) | Structural sharing |

Implementasi praktis: **HAMT (Hash Array Mapped Trie)** dipakai Clojure, Scala, Haskell, dan Rust (`im` crate). HAMT memberikan O(log32 n) effective O(1) untuk lookup/insert dengan structural sharing.

## 4. Higher-Order Functions, Currying & Partial Application

**Higher-order function (HOF)** adalah fungsi yang menerima atau mengembalikan fungsi lain. Ini inti composability di FP.

```haskell
-- Haskell: HOF alami karena currying built-in
map :: (a -> b) -> [a] -> [b]
filter :: (a -> Bool) -> [a] -> [a]
foldr :: (a -> b -> b) -> b -> [a] -> b
```

**Currying** adalah transformasi fungsi multi-argumen menjadi rantai fungsi single-argumen:
```
f(x, y, z) → f(x)(y)(z)
```

**Partial application** adalah mengikat beberapa argumen dan menghasilkan fungsi baru:
```python
# Python
from functools import partial
add = lambda x, y: x + y
add5 = partial(add, 5)     # add5(y) = 5 + y
add5(10)  # → 15
```

| Konsep | Definisi | Contoh |
|:------|:---------|:-------|
| Currying | f(a,b,c) → f(a)(b)(c) | Haskell built-in |
| Partial application | Fix some args, return new fn | `partial(f, 5)` |
| Composition | f∘g where (f∘g)(x) = f(g(x)) | `f . g` in Haskell |

## 5. Type Systems: Hindley-Milner & Algebraic Data Types

**Hindley-Milner (HM)** adalah type inference algorithm yang bisa menyimpulkan tipe semua ekspresi tanpa annotation. Dikembangkan oleh Roger Hindley (1969) dan Robin Milner (1978). HM adalah dasar type system ML, Haskell, Elm, dan PureScript.

Properti HM:
- **Principal type**: setiap ekspresi punya tipe paling general
- **Polymorphic**: `id :: a -> a` bekerja untuk semua tipe `a`
- **Sound**: jika HM menyimpulkan tipe T, maka program type-safe

**Algebraic Data Types (ADT)** adalah cara FP memodelkan data sebagai "algebra" dari produk dan jumlah:

```haskell
-- Product type (AND): record/struct
data Point = Point { x :: Double, y :: Double }

-- Sum type (OR): union/variant
data Shape = Circle Double              -- radius
           | Rectangle Double Double   -- width height
           | Triangle Double Double Double  -- sides

-- Recursive ADT
data List a = Nil | Cons a (List a)

-- Pattern matching untuk deconstruct
area :: Shape -> Double
area (Circle r)            = pi * r * r
area (Rectangle w h)       = w * h
area (Triangle a b c)      = heron a b c
```

| ADT Type | Symbol | Equivalen OOP | Contoh |
|:--------|:------:|:--------------|:-------|
| Product (AND) | `A × B` | Class with fields | `Point(x, y)` |
| Sum (OR) | `A + B` | Visitor pattern, sealed class, enum | `Shape = Circle \| Rectangle` |
| Exponential (function) | `A → B` | Interface/lambda | `f :: Int -> String` |

## 6. Monads: Abstraction untuk Effectful Computation

Monad adalah pattern untuk chaining computations yang punya "effect" (state, I/O, error, non-determinism) tanpa mengorbankan purity. Definisi formal:

```haskell
class Monad m where
  return :: a -> m a           -- lift pure value
  (>>=)  :: m a -> (a -> m b) -> m b  -- bind (chain)
```

| Monad | Effect | Use Case |
|:------|:-------|:---------|
| `Maybe a` | Potential failure | Safe division, null handling |
| `Either e a` | Failure with error | Error handling dengan detail |
| `IO a` | Side effects | I/O, mutation, real world |
| `State s a` | Mutable state | Pure state threading |
| `Reader r a` | Shared read environment | Dependency injection |
| `List a` | Non-determinism | Multiple results |

Contoh praktis di Rust (yang punya monad-like `Option` dan `Result`):
```rust
// Maybe monad equivalent
fn parse_and_double(s: &str) -> Option<i32> {
    s.parse::<i32>().ok().map(|x| x * 2)
}
// Chain: parse → map → result, None propagates automatically

// Either monad equivalent (Result)
fn read_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = serde_json::from_str(&content)?;
    Ok(config)
}
// ? operator = bind (>>=), propagates Err automatically
```

## 7. Lazy Evaluation vs Eager Evaluation

**Lazy evaluation** (call-by-need) mengevaluasi ekspresi hanya saat nilainya dibutuhkan. Haskell menggunakan lazy evaluation secara default:

```haskell
-- Infinite list, tapi hanya ambil 10
take 10 [1..]  → [1,2,3,4,5,6,7,8,9,10]

-- Short-circuit tanpa evaluator khusus
takeWhile (< 100) (map (^2) [1..])
```

| Property | Lazy (Haskell) | Eager (Python, Rust, JS) |
|:---------|:--------------|:------------------------|
| Evaluation timing | On-demand | Immediate |
| Infinite structures | ✅ Possible | ❌ Hangs |
| Memory | Can leak space (thunks) | Predictable |
| Performance | Unpredictable (spine strictness) | Predictable |
| Debugging | Harder (evaluation order obscure) | Easier (stack trace) |

## 8. FP vs OOP: Trade-off Matrix

| Dimension | FP | OOP |
|:----------|:---|:----|
| State | Immutable | Mutable, encapsulated |
| Composition | Function composition | Inheritance, composition |
| Abstraction unit | Function | Class/Object |
| Reusability | High (pure functions) | Medium (coupling via state) |
| Testing | Easy (pure functions) | Harder (mock state) |
| Concurrency | Excellent (no shared state) | Hard (locks, race conditions) |
| Learning curve | Steep (monads, ADT) | Gentle (intuitive state) |
| Industry adoption | Growing (Rust, Scala, F#) | Dominant (Java, C#, Python) |

## 9. Adopsi FP di Industri

| Language | FP Features | Industry |
|:---------|:-----------|:---------|
| Erlang | Pure FP, actor model, hot swap | WhatsApp (2M+ concurrent connections), Ericsson telecom |
| Haskell | Pure FP, lazy, strong types | Facebook (anti-spam Sigma), Standard Chartered (finance) |
| Clojure | FP on JVM, immutable by default | Walmart, Credit Suisse, Atlassian |
| Scala | Hybrid FP+OOP on JVM | Twitter, LinkedIn, Netflix |
| Rust | Hybrid FP+systems, ownership | Mozilla, Cloudflare, Microsoft |
| Elixir | FP on BEAM VM | Discord, Pinterest, Bleacher Report |
| F# | FP on .NET | Jet.com (Walmart), Microsoft Game Studios |

## 10. FP di Rust: Hybrid Paradigm

Rust mengadopsi fitur FP tanpa garbage collector:

| FP Feature | Rust Implementation |
|:-----------|:-------------------|
| Algebraic Data Types | `enum` + `struct` + pattern matching |
| Option/Maybe monad | `Option<T>` with `map`, `and_then` (bind) |
| Result/Either monad | `Result<T, E>` with `?` operator (bind) |
| Closures | `Fn`, `FnMut`, `FnOnce` traits |
| Iterators (lazy) | `iter().map().filter().collect()` |
| Immutability | `let` immutable by default, `mut` opt-in |
| Trait-based polymorphism | `trait` (type class, bukan inheritance) |

Rust TIDAK punya: garbage collector, inheritance, lazy evaluation default, higher-kinded types. Ini trade-off: safety + performance > purity.

## References

1. Church, A. (1936). "An unsolvable problem of elementary number theory." *American Journal of Mathematics*
2. Hindley, R. (1969). "The principal type-scheme of an object in combinatory logic." *JSL*
3. Milner, R. (1978). "A theory of type polymorphism in programming." *JCSS*
4. Wadler, P. (1992). "The essence of functional programming." *POPL*
5. Okasaki, C. (1999). *Purely Functional Data Structures*. Cambridge University Press
6. Wikipedia: [Functional Programming](https://en.wikipedia.org/wiki/Functional_programming)
7. Wikipedia: [Monad (functional programming)](https://en.wikipedia.org/wiki/Monad_(functional_programming))
8. Wikipedia: [Hindley-Milner type system](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system)
9. Wikipedia: [Referential transparency](https://en.wikipedia.org/wiki/Referential_transparency)
10. Learn You a Haskell: https://github.com/noelmarkham/learnyouahaskell (site asli mati; mirror GitHub)
11. Rust Book — Closures & Iterators: https://doc.rust-lang.org/book/ch13.html

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[object-oriented-programming-deepdive]] | Paradigma pasangan — trade-offs FP vs OOP |
| [[design-patterns-gof]] | GoF patterns vs FP combinators |
| [[clean-code-robert-martin]] | Clean code principles overlap dengan FP purity |
| [[the-pragmatic-programmer]] | Pragmatic FP adoption di industri |
| [[compiler-design-deepdive]] | Compiler implementation sering pakai FP |
| [[refactoring-martin-fowler]] | Refactoring ke immutability |
| [[00_Atlas/hierarchy-software-engineering-paradigm]] | Atlas paradigm pemrograman |
| [[pqc-implementation-rust]] | Rust FP features di praktik PQC |
---

audited
---
