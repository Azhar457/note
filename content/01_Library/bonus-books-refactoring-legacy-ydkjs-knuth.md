---
title: "Bonus Books — Refactoring, Legacy Code, Soft Skills, YDKJS, TAoCP"
tags:
  - library
aliases:
  - "bonus-books-refactoring-legacy-ydkjs-knuth"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# Bonus Books — Ringkasan

Pentingnya membaca buku sebagai seorang pengembang perangkat lunak tidak dapat diabaikan. Buku-buku yang akan dibahas di sini adalah beberapa contoh dari banyak buku yang dapat membantu Anda dalam pengembangan perangkat lunak.

## Refactoring — Martin Fowler (1999, 2nd ed 2018)

Refactoring adalah proses mengubah struktur internal kode tanpa mengubah behavior eksternal. Bukan rewrite. Martin Fowler dalam bukunya "Refactoring" memberikan katalog lebih dari 100 teknik konkrit untuk melakukan refactoring, seperti Extract Method, Rename Variable, Move Field, dan Replace Conditional with Polymorphism.

### Kunci Refactoring

- **Catalog of Refactorings**: Katalog yang berisi teknik-teknik konkrit untuk melakukan refactoring.
- **Test before Refactor**: Pentingnya melakukan testing sebelum melakukan refactoring untuk memastikan bahwa kode masih berfungsi dengan benar.
- **Code Smells**: Indikator kapan perlu melakukan refactoring, seperti long method, switch statements, dan shotgun surgery.

### Contoh Refactoring

```python
# Sebelum refactoring
def calculate_total(price, tax_rate):
    total = price * 1.1
    if tax_rate == 0.1:
        total *= 1.1
    elif tax_rate == 0.2:
        total *= 1.2
    return total

# Setelah refactoring
def calculate_total(price, tax_rate):
    tax_multiplier = get_tax_multiplier(tax_rate)
    return price * tax_multiplier

def get_tax_multiplier(tax_rate):
    if tax_rate == 0.1:
        return 1.1
    elif tax_rate == 0.2:
        return 1.2
```

Dalam contoh di atas, kita melakukan refactoring dengan memisahkan logika perhitungan pajak ke dalam fungsi terpisah, sehingga kode menjadi lebih mudah dibaca dan dipahami.

### Troubleshooting Refactoring

- **Masalah**: Kode menjadi lebih kompleks setelah refactoring.
  - **Penyebab**: Refactoring tidak dilakukan dengan benar, atau kode tidak dipisahkan dengan baik.
  - **Solusi**: Lakukan refactoring dengan lebih hati-hati, dan pastikan kode dipisahkan dengan benar.
- **Masalah**: Kode tidak berfungsi dengan benar setelah refactoring.
  - **Penyebab**: Refactoring tidak dilakukan dengan benar, atau kode tidak diuji dengan benar.
  - **Solusi**: Lakukan testing sebelum dan setelah refactoring, dan pastikan kode berfungsi dengan benar.

## Working Effectively with Legacy Code — Michael Feathers (2004)

Legacy code adalah kode yang tidak memiliki test. Michael Feathers dalam bukunya "Working Effectively with Legacy Code" memberikan cara untuk membuat legacy code menjadi testable tanpa harus melakukan rewrite.

### Kunci Legacy Code

- **Characterization Tests**: Test yang digunakan untuk menangkap behavior yang ada dalam kode.
- **Seams**: Titik di mana kita bisa melakukan injeksi test tanpa mengubah kode.
- **Breaking Dependencies**: Cara untuk memisahkan kode yang terkait dengan dependensi lain.
- **Sprout Method / Sprout Class**: Cara untuk menambahkan kode baru dalam wrapper yang testable.
- **Wrap Method / Wrap Class**: Cara untuk memwrap kode yang ada dengan wrapper yang testable.

### Contoh Legacy Code

```java
// Sebelum
public class PaymentProcessor {
    public void processPayment(Payment payment) {
        // kode yang complex dan sulit diuji
    }
}

// Setelah
public class PaymentProcessor {
    public void processPayment(Payment payment) {
        PaymentWrapper wrapper = new PaymentWrapper(payment);
        wrapper.processPayment();
    }
}

public class PaymentWrapper {
    private Payment payment;

    public PaymentWrapper(Payment payment) {
        this.payment = payment;
    }

    public void processPayment() {
        // kode yang lebih sederhana dan mudah diuji
    }
}
```

Dalam contoh di atas, kita melakukan penyisipan wrapper untuk memisahkan logika pembayaran, sehingga kode menjadi lebih mudah dibaca dan dipahami.

### Troubleshooting Legacy Code

- **Masalah**: Kode legacy tidak dapat diuji dengan baik.
  - **Penyebab**: Kode legacy tidak memiliki test, atau kode tidak dipisahkan dengan baik.
  - **Solusi**: Buat characterization tests untuk menangkap behavior yang ada dalam kode, dan pastikan kode dipisahkan dengan benar.
- **Masalah**: Kode legacy sulit dimodifikasi.
  - **Penyebab**: Kode legacy tidak dipisahkan dengan baik, atau kode tidak memiliki dependensi yang jelas.
  - **Solusi**: Lakukan breaking dependencies untuk memisahkan kode yang terkait dengan dependensi lain, dan pastikan kode memiliki dependensi yang jelas.

## Soft Skills: The Software Developer's Life Manual — John Sonmez (2014)

Jadi developer bukan cuma tentang coding. John Sonmez dalam bukunya "Soft Skills: The Software Developer's Life Manual" memberikan tips dan trik untuk meningkatkan kemampuan dan karir sebagai seorang developer.

### Kunci Soft Skills

- **Personal Brand**: Pentingnya memiliki personal brand yang kuat untuk meningkatkan karir.
- **Freelancing**: Cara untuk meningkatkan pendapatan dan fleksibilitas sebagai seorang developer.
- **Learning how to Learn**: Cara untuk meningkatkan kemampuan belajar dan meningkatkan karir.
- **Marketing**: Cara untuk mempromosikan diri sendiri sebagai seorang developer.
- **Financial Independence**: Cara untuk mencapai kebebasan finansial sebagai seorang developer.

### Contoh Soft Skills

```markdown
# Personal Brand

- Buat blog untuk membagikan pengetahuan dan pengalaman
- Buat portfolio untuk membagikan proyek yang telah dikerjakan
- Buat profil di media sosial untuk membagikan informasi tentang diri sendiri
```

Dalam contoh di atas, kita melakukan pembuatan personal brand dengan membuat blog, portfolio, dan profil di media sosial, sehingga kita dapat meningkatkan karir dan pendapatan.

### Troubleshooting Soft Skills

- **Masalah**: Karir tidak maju-maju.
  - **Penyebab**: Tidak memiliki personal brand yang kuat, atau tidak memiliki kemampuan belajar yang baik.
  - **Solusi**: Buat personal brand yang kuat, dan pastikan memiliki kemampuan belajar yang baik.
- **Masalah**: Pendapatan tidak cukup.
  - **Penyebab**: Tidak memiliki freelance, atau tidak memiliki kemampuan marketing yang baik.
  - **Solusi**: Lakukan freelance, dan pastikan memiliki kemampuan marketing yang baik.

## You Don't Know JS (book series) — Kyle Simpson

JavaScript bukan bahasa "kecil" — punya mekanika dalam yang gak banyak dipahami. Kyle Simpson dalam seri bukunya "You Don't Know JS" memberikan penjelasan yang mendalam tentang JavaScript.

### Kunci YDKJS

- **Scope & Closures**: Penjelasan tentang lexical scope, hoisting, IIFE, dan closure.
- **this & Object Prototypes**: Penjelasan tentang `this` binding, `new`, `Object.create`.
- **Types & Grammar**: Penjelasan tentang coercion, type checking.
- **Async & Performance**: Penjelasan tentang callback hell, Promise, async/await, web workers.
- **ES6 & Beyond**: Penjelasan tentang let/const, arrow, modules, iterators.

### Contoh YDKJS

```javascript
// Contoh scope
function foo() {
  var bar = 1
  function baz() {
    console.log(bar) // 1
  }
  baz()
}

// Contoh closure
function foo() {
  var bar = 1
  return function baz() {
    console.log(bar) // 1
  }
}
var baz = foo()
baz() // 1
```

Dalam contoh di atas, kita melakukan pembuatan contoh tentang scope dan closure, sehingga kita dapat memahami konsep-konsep dasar dalam JavaScript.

### Troubleshooting YDKJS

- **Masalah**: Kode JavaScript tidak berfungsi dengan benar.
  - **Penyebab**: Tidak memahami konsep-konsep dasar dalam JavaScript, atau kode tidak diuji dengan benar.
  - **Solusi**: Lakukan pembelajaran tentang konsep-konsep dasar dalam JavaScript, dan pastikan kode diuji dengan benar.

## The Art of Computer Programming — Donald Knuth (1968, ongoing)

Buku terpenting soal algoritma — tapi bukan textbook biasa. Donald Knuth dalam bukunya "The Art of Computer Programming" memberikan penjelasan yang mendalam tentang algoritma dan struktur data.

### Kunci TAoCP

- **Fundamental Algorithms**: Penjelasan tentang algoritma dasar seperti sorting, searching, dan graph.
- **Seminumerical Algorithms**: Penjelasan tentang algoritma numerik seperti floating-point dan integer.
- **Sorting and Searching**: Penjelasan tentang algoritma sorting dan searching.
- **Combinatorial Algorithms**: Penjelasan tentang algoritma kombinatorial seperti permutasi dan kombinasi.

### Contoh TAoCP

```python
# Contoh algoritma sorting
def bubble_sort(arr):
    n = len(arr)
    for i in range(n-1):
        for j in range(n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr

# Contoh algoritma searching
def binary_search(arr, target):
    low, high = 0, len(arr)-1
    while low <= high:
        mid = (low + high) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return -1
```

Dalam contoh di atas, kita melakukan pembuatan contoh tentang algoritma sorting dan searching, sehingga kita dapat memahami konsep-konsep dasar dalam algoritma.

### Troubleshooting TAoCP

- **Masalah**: Algoritma tidak berfungsi dengan benar.
  - **Penyebab**: Tidak memahami konsep-konsep dasar dalam algoritma, atau kode tidak diuji dengan benar.
  - **Solusi**: Lakukan pembelajaran tentang konsep-konsep dasar dalam algoritma, dan pastikan kode diuji dengan benar.

## Checklist Ringkasan

- [ ] **Refactoring** — baca catalog, cari 1 code smell di codebase
- [ ] **Legacy Code** — karakterisasi test untuk modul tanpa test
- [ ] **Soft Skills** — buat personal brand plan
- [ ] **YDKJS** — baca Scope & Closures, kerjain contohnya
- [ ] **TAoCP** — cukup pahami kontennya, baca pas butuh aja

Dengan memahami dan menerapkan konsep-konsep yang ada dalam buku-buku di atas, kita dapat meningkatkan kemampuan dan karir sebagai seorang pengembang perangkat lunak.
