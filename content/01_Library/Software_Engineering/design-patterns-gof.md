---
title: Design Patterns — GoF (Gamma, Helm, Johnson, Vlissides)
tags:
- library
- software-engineering
created: '2026-07-05'
updated: '2026-07-05'
status: pending
cssclasses:
  - wide-table
  - callout

---
# 🧠 Design Patterns: Elements of Reusable OO Software
> Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides (Gang of Four) — 1994

**Tesis:** GoF mendokumentasikan 23 solusi umum untuk masalah desain OOP yang muncul berulang-ulang di proyek berbeda. Bukan *copy-paste code* — ini *blueprint* yang kamu adaptasi ke konteksmu. Menguasai pola ini artinya kamu gak perlu *reinvent the wheel* tiap kali nemu masalah yang sama. Lebih penting lagi: pola memberi **vocabulary bersama** — bilang "pakai Observer" lebih cepat daripada jelasin pub/sub 5 menit.

**Tapi hati-hati:** Pola bukan tujuan. Jangan paksa pola ke masalah yang gak cocok. GoF sendiri bilang: pilih pola berdasarkan **apa yang berubah** di desainmu, bukan karena keren. Akronim *Gang of Four* sendiri diambil dari nama keempat penulis: Gamma, Helm, Johnson, Vlissides — bukan geng kriminal.

---

## 📌 Kenapa Penting

- **Bahasa universal tim.** "Pakai Factory method, bukan switch statement" = komunikasi 5 detik. Tanpa pola: jelasin 5 menit + gambar diagram + 3 kali ulang.
- **Pola lahir dari pengalaman, bukan teori.** Setiap pola ditemukan karena orang menghadapi masalah yang sama berkali-kali dan nemuin solusi yang works. *Battle-tested* di puluhan bahasa dan domain.
- **Framework modern = implementasi pola.** Spring → Factory + Proxy + Template. React → Observer + Composite + Strategy. Django → Template Method + Command. Tanpa sadar kamu mungkin udah pake pola tiap hari.
- **Antidote untuk kode kaku.** Pola ngajarin *favor composition over inheritance* — prinsip yang bikin kode gampang diubah tanpa ngerusak yang lain.
- **Jembatan antara requirement dan implementasi.** "Saya perlu nambah behavior tanpa edit class asli" → otak langsung loncat ke Decorator atau Strategy.

## 3 Kategori Pola

### 1. Creational (5) — Urusan buat object

**Prinsip:** Pisahkan *apa* yang dibuat dari *bagaimana* cara membuatnya. Client gak perlu tahu class konkrit.

| Pola | Guna | Contoh | Kode singkat |
|------|------|--------|-------------|
| **Singleton** | Satu instance global | DB connection, logger | `class Logger { static getInstance() { ... } }` |
| **Factory Method** | Subclass menentukan class | Framework hook | `class Dialog { createButton() }` → `class WindowsDialog { createButton() { return new WinButton() } }` |
| **Abstract Factory** | Family of related objects | UI toolkit (Windows vs Mac) | `class GUIFactory { createButton(); createCheckbox() }` → 2 implementasi |
| **Builder** | Complex object construction | Query builder, StringBuilder | `new PizzaBuilder().setSize(12).addCheese().build()` |
| **Prototype** | Clone object | Cell duplication spreadsheet | `cell.clone() // deep copy, lalu modifikasi` |

**Kapan pilih yang mana:**
- **Singleton** — pas butuh *shared state* (config, cache). **Tapi hati-hati:** bikin test susah karena global state.
- **Factory Method** — pas framework mau ngasih hook buat client override.
- **Abstract Factory** — pas produk harus konsisten satu keluarga (jangan Windows Button + Mac Checkbox).
- **Builder** — pas constructor butuh 10+ parameter atau ada variasi konfigurasi.
- **Prototype** — pas bikin object dari scratch mahal (query DB, network call).

### 2. Structural (7) — Urusan komposisi class/object

**Prinsip:** Gunakan komposisi dan pewarisan buat nyusun struktur yang fleksibel.

| Pola | Guna | Contoh | Analogi |
|------|------|--------|---------|
| **Adapter** | Make incompatible interfaces work | Charger EU ke colokan AS | Adaptor listrik |
| **Bridge** | Abstraksi terpisah dari implementasi | Remote TV (abstrak) → Sony/Samsung TV (implementasi) | Remote universal |
| **Composite** | Treat individual & composition uniformly | File system: file vs folder | Kotak di dalam kotak |
| **Decorator** | Add behavior dynamically (wrap) | Java I/O: `new BufferedInputStream(new FileInputStream())` | Baju lapis-lapis |
| **Facade** | Simplified interface to subsystem | `Computer.start()` → urus CPU, RAM, GPU di dalem | Resepsionis hotel |
| **Flyweight** | Share fine-grained objects (save memory) | Rendering font: char 'a' di-share semua paragraph | Kolam renang publik |
| **Proxy** | Control access to another object | Lazy loading gambar, auth proxy, caching | Asisten pribadi |

**Kapan pilih yang mana:**
- **Adapter** — punya class lama dengan interface beda, tapi butuh dipake di system baru.
- **Bridge** — abstraksi DAN implementasi sama-sama bisa berubah (misal: mau ganti TV brand DAN ganti remote model).
- **Composite** — struktur pohon di mana leaf dan composite harus dipanggil sama (file/folder, UI tree).
- **Decorator** — butuh nambah behavior tanpa ubah class, dan kombinasinya banyak (logging + caching + auth).
- **Facade** — subsystem kompleks tapi client cuma butuh 2-3 operasi.
- **Flyweight** — object kecil jumlahnya ribuan dan state intrinsiknya bisa di-share.
- **Proxy** — butuh kontrol akses, lazy init, atau logging tanpa ubah class asli.

### 3. Behavioral (11) — Urusan interaksi & komunikasi antar object

**Prinsip:** Atur alur komunikasi biar object-object gak saling tahu detail internal satu sama lain.

| Pola | Guna | Contoh | Analogi |
|------|------|--------|---------|
| **Strategy** | Family algorithms, interchangeable | Validator berbed-beda: regex, length, custom | Pilih jenis kopi (espresso, latte, manual brew) |
| **Observer** | One-to-many notification (pub/sub) | Event listener, store subscribe | YouTube subscriber — uploader notify semua subscriber |
| **Command** | Encapsulate request as object | Undo/redo, queue task, macro | Pesanan di restoran: waiter → koki (waiter gak masak sendiri) |
| **Iterator** | Sequential access, hide structure | foreach loop, database cursor | Remote AC next channel |
| **Template Method** | Skeleton algorithm, subclasses fill steps | `DataProcessor.parse()->extract()->transform()->load()` | Resep masakan: "rebus air" tetap, "bumbu" opsional |
| **State** | Behavior changes when state changes | Vending machine: tunggu koin → pilih → deliver | Lampu lalu lintas: merah → ijo → kuning |
| **Visitor** | New operation without changing elements | AST visitor, export ke HTML/PDF/JSON | Kurir: beda rumah beda perlakuan |
| **Mediator** | Reduce chaotic coupling | Chat room → semua pesan lewat room, gak langsung ke orang | Tower bandara ngatur pesawat landing/takeoff |
| **Chain of Resp** | Multiple handlers for one request | Middleware Express.js: auth → logging → cache → route | CS: "saya bisa bantu?" → supervisor → manager |
| **Memento** | Capture & restore internal state (undo) | Ctrl+Z di editor, save game checkpoint | Save point di game |
| **Interpreter** | Grammar for simple language | Regex engine, SQL parser, DSL sederhana | Penerjemah bahasa isyarat |

**Kapan pilih yang mana:**
- **Strategy** — banyak cara ngelakuin hal yang sama, dan klien milih salah satu di runtime.
- **Observer** — satu perubahan butuh notify banyak object, tapi gak mau tight coupling.
- **Command** — butuh queue, retry, undo, atau log tiap request.
- **Template Method** — algoritma sama, langkah-langkah tertentu bisa di-*override* subclass.
- **State** — object berubah perilaku drastis tergantung state internal (gak pake if/else raksasa).
- **Visitor** — struktur object stabil tapi operasi yang bisa ditambah terus.
- **Mediator** — banyak object saling komunikasi, udah mulai chaotic.
- **Chain of Resp** — gak tahu handler mana yang bakal proses request, atau handler bisa ditambah kapan aja.
- **Memento** — butuh save/restore state tanpa ngebreak encapsulation.

## 📖 Bab Penting & Porsi Bacaan

| Bab | Judul | Prioritas | Waktu baca |
|-----|-------|-----------|------------|
| 1 | Introduction | ✅ Wajib | ~30 menit — paham klasifikasi pola & kapan pakai |
| 2 | Case Study: Text Editor | ⭐ Rekomendasi | ~45 menit — lihat pola in action |
| Creational (ch. 3-5) | 5 pola | ✅ Wajib (Factory + Abstract Factory) | ~1 jam |
| Structural (ch. 6-9) | 7 pola | ⭐ Rekomendasi (Composite + Decorator) | ~1.5 jam |
| Behavioral (ch. 10-13) | 11 pola | ✅ Wajib (Strategy + Observer) | ~2 jam |
| Appendix | Referensi | 📖 Pelengkap | Lompat aja |

**Strategi baca:**
1. Baca Bab 1 dulu — paham kategorisasi
2. Loncat ke Strategy + Observer — paling sering dipake
3. Baca pola pas butuh aja (just-in-time learning)
4. Jangan baca cover-to-cover — ini katalog, bukan novel

## ⚠️ Kritik & Konteks

| Kritik | Penjelasan | Kapan Diabaikan |
|--------|------------|-----------------|
| Kode contoh C++/Smalltalk | Bahasa contoh udah 30 tahun. Banyak polanya sekarang built-in di framework modern. | Baca pseudocode di Wikipedia — lebih mudah dipahami |
| Over-pattern | Gara-gara baca GoF, orang jadi paksa *Singleton* buat class yang cuma instansiasi 1x padahal gak perlu | Pola adalah alat, bukan identitas. Kalo masalahmu selesai dengan if-else, ya pake if-else |
| Bahasa OOP-centric | Pola di GoF asumsikan inheritance mutlak. Di JS/Go/Rust implementasinya beda | Adaptasi ke bahasa: closure bisa ganti Strategy, channel bisa ganti Observer |
| Banyak pola overlap | Strategy vs State beda intent tapi struktur classnya mirip | Fokus ke *kapan* dan *kenapa*, bukan *bagaimana struktur class-nya* |
| Catalog format membosankan | 23 pola × 10 halaman = bacaan kering | Baca 1 pola per hari, gak perlu buru-buru |

**Konteks 2026:** Dari 23 pola, yang benar-benar dipake tiap hari di proyek modern sekitar 8-10 pola. Sisanya relevan di kasus spesifik. Prioritasin yang paling sering muncul:

- **High frequency:** Singleton, Factory Method, Adapter, Observer, Strategy, Template Method, Composite, Decorator
- **Medium:** Abstract Factory, Builder, Command, State, Proxy, Facade
- **Low (tapi penting tau):** sisanya — pahamin konsep, detail implementasi cari pas butuh

## 🚦 Learning Path

```
1. Strategy + Observer ──────► paham OOP composition
         │
2. Factory Method + Singleton ──► paham object creation
         │
3. Adapter + Decorator ────► paham wrapping
         │
4. Composite + Iterator ─────► paham tree structure
         │
5. Command + State + Template ──► paham behavior changes
         │
6. Visitor + Mediator ─────► paham complex interactions
         │
7. Proxy + Facade + Chain ─────► paham access control
```

## 🔗 Koneksi ke Vault Lain

- [[clean-code-robert-martin]] — pola adalah salah satu alat buat clean code. Solid principles terinspirasi dari GoF.
- [[the-pragmatic-programmer]] — DRY adalah pola paling dasar: jangan duplikasi pengetahuan.
- [[refactoring-martin-fowler]] — banyak refactoring menghasilkan pola. *Replace Conditional with Strategy*.
- [[systems-design-interview-alex-xu]] — pattern di level arsitektur: Strategy → sharding, Observer → event-driven.
- [[ddia-kleppmann]] — distributed systems patterns (Leader Election, Quorum) = GoF di level sistem.

## ✅ Checklist Praktik

- [ ] Baca Bab 1 GoF — paham klasifikasi pola
- [ ] Identifikasi 1 pola yang dipake framework yang kamu gunakan tiap hari
- [ ] Refactor 1 kode: ganti `if-else` panjang dengan Strategy
- [ ] Refactor 1 kode: ganti `switch` object creation dengan Factory Method
- [ ] Cari *Singleton abuse* di codebase — ganti dengan dependency injection
- [ ] Implementasi Observer sederhana (manual, tanpa library)
- [ ] Implementasi Decorator: wrapping function dengan logging/caching
- [ ] Pilih 1 pola baru per bulan — baca, implementasi, tulis catatan
- [ ] Buat *cheatsheet* pribadi: 1 file markdown per pola (3-5 baris + contoh kode)
---

audited
---
