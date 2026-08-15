---
title: Refactoring Principles and Catalog — Martin Fowler's Patterns
tags:
- refactoring
- martin-fowler
- code-quality
- software-engineering
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Refactoring adalah proses restrukturisasi kode internal perangkat lunak tanpa mengubah perilaku eksternal (*external behavior*). Catatan ini membedah prinsip utama refactoring, siklus aman berbasis TDD, serta katalog pola Fowler yang paling sering digunakan, melengkapi bahasan [[clean-code-robert-martin]] dan [[ai-assisted-dev-workflow]].

## Daftar Isi

1. [Prinsip Utama & Siklus Aman Refactoring (TDD)](#1-prinsip-utama--siklus-aman-refactoring-tdd)
2. [Katalog Pola: Extract Method vs Inline Method](#2-katalog-pola-extract-method-vs-inline-method)
3. [Katalog Pola: Replace Temp with Query](#3-katalog-pola-replace-temp-with-query)
4. [Katalog Pola: Replace Conditional/Switch with Polymorphism](#4-katalog-pola-replace-conditionalswitch-with-polymorphism)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Prinsip Utama & Siklus Aman Refactoring (TDD)

Refactoring tidak boleh dilakukan secara serampangan. Aturan emas dari Martin Fowler adalah **memisahkan topi penulisan fitur baru dengan topi refactoring**:
- Saat menulis fitur baru: Jangan merubah kode lama, hanya tambahkan test dan kode fungsional.
- Saat melakukan refactoring: Jangan tambahkan fitur baru, hanya rapikan struktur kode lama dan pastikan seluruh test tetap lulus.

### 1.1 Siklus TDD Refactoring (Safety Net)
Sebelum menyentuh satu baris kode pun, pastikan Anda memiliki jaring pengaman (*safety net*) berupa automated unit tests.

```
                  ┌──────────────┐
                  │ Write Test   │
                  └──────┬───────┘
                         ▼
                  ┌──────────────┐
                  │  Run Test    │ ◀─── (Red: Test gagal)
                  └──────┬───────┘
                         ▼
                  ┌──────────────┐
                  │ Write Code   │
                  └──────┬───────┘
                         ▼
                  ┌──────────────┐
                  │  Run Test    │ ◀─── (Green: Test lulus)
                  └──────┬───────┘
                         ▼
           ┌───────────────────────────┐
      ───▶ │   Apply Refactoring       │ (Lakukan modifikasi kecil, bertahap)
     │     └─────────────┬─────────────┘
     │                   ▼
     │            ┌──────────────┐
     │            │  Run Test    │ ─── (Green?) ───▶ Sukses / Commit
     └────────────┴──────────────┘
```

---

## 2. Katalog Pola: Extract Method vs Inline Method

### 2.1 Extract Method
*Smell*: Sebuah fungsi terlalu panjang (*Long Method*) atau memiliki bagian yang memerlukan komentar penjelasan untuk dipahami.
*Tindakan*: Ekstrak bagian berkode tersebut menjadi fungsi mandiri dengan nama yang menjelaskan tujuan fungsinya (*intent-revealing name*).

#### Sebelum Refactoring
```javascript
function printOwing(invoice) {
  let outstanding = 0;
  
  console.log("*************************");
  console.log("**** Customer Owes ****");
  console.log("*************************");

  // Hitung outstanding
  for (const o of invoice.orders) {
    outstanding += o.amount;
  }

  // Cetak detail
  console.log(`Name: ${invoice.customer}`);
  console.log(`Amount: ${outstanding}`);
}
```

#### Setelah Refactoring
```javascript
function printOwing(invoice) {
  printBanner();
  const outstanding = calculateOutstanding(invoice);
  printDetails(invoice, outstanding);
}

function printBanner() {
  console.log("*************************");
  console.log("**** Customer Owes ****");
  console.log("*************************");
}

function calculateOutstanding(invoice) {
  return invoice.orders.reduce((sum, order) => sum + order.amount, 0);
}

function printDetails(invoice, outstanding) {
  console.log(`Name: ${invoice.customer}`);
  console.log(`Amount: ${outstanding}`);
}
```

---

## 3. Katalog Pola: Replace Temp with Query

*Smell*: Penggunaan variabel temporer lokalis untuk menampung hasil perhitungan rumus matematika. Variabel temporer memaksa fungsi menjadi lebih panjang dan sulit diekstrak.
*Tindakan*: Ubah perhitungan variabel tersebut menjadi fungsi query khusus.

#### Sebelum Refactoring
```javascript
function calculateTotal(quantity, itemPrice) {
  const basePrice = quantity * itemPrice; // Variabel temporer
  
  if (basePrice > 1000) {
    return basePrice * 0.95;
  } else {
    return basePrice * 0.98;
  }
}
```

#### Setelah Refactoring
```javascript
function calculateTotal(quantity, itemPrice) {
  if (basePrice(quantity, itemPrice) > 1000) {
    return basePrice(quantity, itemPrice) * 0.95;
  }
  return basePrice(quantity, itemPrice) * 0.98;
}

// Diekstrak menjadi fungsi query murni (pure function)
function basePrice(quantity, itemPrice) {
  return quantity * itemPrice;
}
```
*Note*: Khawatir dengan performa akibat pemanggilan fungsi berulang? Compiler modern (JIT) dan optimasi caching tingkat lanjut hampir selalu melakukan *inlining* secara otomatis sehingga dampak penurunan performa tidak terasa, sementara keterbacaan kode naik drastis.

---

## 4. Katalog Pola: Replace Conditional/Switch with Polymorphism

*Smell*: Anda memiliki struktur percabangan `switch` atau `if-else` bertingkat yang memeriksa tipe objek untuk melakukan aksi yang berbeda. Jika ada tipe baru, Anda terpaksa merubah semua blok switch di seluruh sistem.
*Tindakan*: Buat kelas-kelas turunan berbasis polimorfisme (*Polymorphism*).

#### Sebelum Refactoring
```javascript
class Bird {
  constructor(type, voltage) {
    this.type = type;
    this.voltage = voltage;
  }

  getSpeed() {
    switch (this.type) {
      case "EUROPEAN":
        return 35;
      case "AFRICAN":
        return 40 - 2 * this.numberOfCocoanuts;
      case "NORWEGIAN_BLUE":
        return this.isNailed ? 0 : 10 + this.voltage / 10;
      default:
        return 0;
    }
  }
}
```

#### Setelah Refactoring
```javascript
// Kelas dasar (Base Class)
class Bird {
  getSpeed() {
    return 0;
  }
}

// Subclass spesifik menggunakan polimorfisme
class EuropeanBird extends Bird {
  getSpeed() {
    return 35;
  }
}

class AfricanBird extends Bird {
  constructor(numberOfCocoanuts) {
    super();
    this.numberOfCocoanuts = numberOfCocoanuts;
  }
  getSpeed() {
    return 40 - 2 * this.numberOfCocoanuts;
  }
}

class NorwegianBlueBird extends Bird {
  constructor(isNailed, voltage) {
    super();
    this.isNailed = isNailed;
    this.voltage = voltage;
  }
  getSpeed() {
    return this.isNailed ? 0 : 10 + this.voltage / 10;
  }
}

// Pabrik pembuat objek (Factory Pattern)
function createBird(type, details) {
  switch (type) {
    case "EUROPEAN":
      return new EuropeanBird();
    case "AFRICAN":
      return new AfricanBird(details.numberOfCocoanuts);
    case "NORWEGIAN_BLUE":
      return new NorwegianBlueBird(details.isNailed, details.voltage);
    default:
      return new Bird();
  }
}
```

---

## 5. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[clean-code-robert-martin]] | Prinsip rancangan SOLID (khususnya *Single Responsibility* & *Open-Closed Principle*) yang dicapai melalui refactoring polimorfisme. |
| [[design-patterns-gof]] | Katalog pola desain GoF yang sering kali menjadi target akhir dari proses refactoring. |
| [[ai-assisted-dev-workflow]] | Panduan menginstruksikan AI untuk melakukan refactoring kode secara aman tanpa merusak fungsionalitas. |
---

audited
---
