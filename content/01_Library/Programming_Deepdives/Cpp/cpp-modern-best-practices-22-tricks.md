---
title: 'C++ Modern Best Practices — 22 Trik yang Wajib Dikuasai'
tags:
  - cpp
  - modern-cpp
  - best-practices
  - code-quality
  - productivity
aliases:
  - C++ Modern Best Practices 22 Trik
  - C++ 22 Trik
created: '2026-08-10'
updated: '2026-08-10'
status: complete
cssclasses:
  - wide-table
---

# 🧙 C++ MODERN BEST PRACTICES — 22 Trik yang Wajib Dikuasai

**Dari `auto` hingga `std::format`: Panduan Praktis C++ Modern dengan Contoh Kode Siap Pakai**

tags:
  - cpp
  - modern-cpp
  - best-practices
  - cpp-tricks
aliases:
  - C++ Modern Tricks
  - C++ Best Practices 2024
created: 2026-08-10
status: operational
cssclasses:
  - wide-table

---

> [!abstract] Tujuan Dokumen Ini
> Bukan sekadar daftar trik. Setiap trik disertai contoh kode yang bisa langsung dicompile, penjelasan komentar di dalam kode, serta catatan kapan harus digunakan, apa prasyaratnya, dan bagaimana trik ini berhubungan dengan trik lain. Kamu akan memahami bukan hanya *bagaimana*, tapi juga *mengapa* dan *kapan*.

---

## 🧭 Peta Dependensi Antar Trik

Beberapa trik saling bergantung. Gunakan tabel ini untuk melihat hubungannya.

| Trik # | Nama Trik | Butuh Trik # |
|--------|-----------|-------------|
| 9 | Structured Bindings | 8 (std::pair/tuple) |
| 11 | `emplace_back` | 12 (Move Semantics) |
| 12 | Move Semantics (`std::move`) | 2 (Rule of Five/Zero) |
| 14 | Lambda Modern | 1 (`auto` return type deduction) |
| 16 | `std::variant` + `std::visit` | 9 (Structured Bindings untuk visitor) |
| 18 | `constexpr if` | 3 (`constexpr` basics) |
| 19 | `std::span` | 4 (`std::string_view` konsep mirip) |
| 21 | `std::format` | (C++20 standalone) |
| 22 | `consteval` | 3 (`constexpr` dasar) |

---

## 1. `auto` — Type Deduction yang Aman

**C++ Version:** C++11 (diperbarui di C++14, C++17)  
**Dependencies:** Tidak ada

```cpp
#include <iostream>
#include <vector>

int main() {
    // auto untuk variabel biasa — compiler tentukan tipe dari initializer
    auto i = 42;         // int
    auto d = 3.14;       // double
    auto s = "hello";    // const char*

    // auto untuk iterator — hindari penulisan tipe panjang
    std::vector<int> v = {1, 2, 3};
    for (auto it = v.begin(); it != v.end(); ++it) {
        std::cout << *it << ' ';
    }
    std::cout << '\n';

    // auto untuk return type (C++14) — fungsi dengan return type otomatis
    auto add = [](int a, int b) { return a + b; }; // lambda
    std::cout << add(5, 3) << '\n';
}
```

**Mengapa Penting:**  
- Mengurangi penulisan tipe yang berulang dan panjang (misal, `std::vector<int>::iterator`).
- Mencegah pemotongan tipe secara tidak sengaja (misal, `float` vs `double`).

**Kapan Digunakan:**  
- Saat tipe jelas dari konteks atau initializer.
- Hindari `auto` jika tipe justru membuat kode sulit dibaca (gunakan dengan bijak).

**Best Practice:**  
- Selalu berikan inisialisasi langsung (`auto x = ...`).
- Gunakan `const auto&` untuk loop read-only agar tidak menyalin elemen.

---

## 2. Rule of Five / Zero — Manajemen Resource Otomatis

**C++ Version:** C++11  
**Dependencies:** Move Semantics (Trik 12)

```cpp
#include <iostream>
#include <memory>

// Rule of Zero: Gunakan tipe yang sudah mengelola resource (unique_ptr, vector)
// sehingga compiler-generated destructor/copy/move sudah benar.
class RuleOfZero {
    std::unique_ptr<int> data;
public:
    // Tidak perlu destructor, copy, move manual
    void set(int val) { data = std::make_unique<int>(val); }
    int get() const { return data ? *data : -1; }
};

// Rule of Five: Jika harus menulis salah satu (destructor, copy, move),
// tulis semuanya dengan = default atau = delete.
class RuleOfFive {
    int* data;
public:
    RuleOfFive() : data(new int(0)) {}
    ~RuleOfFive() { delete data; }                    // destructor
    RuleOfFive(const RuleOfFive& o) : data(new int(*o.data)) {} // copy
    RuleOfFive& operator=(const RuleOfFive& o) {      // copy assign
        *data = *o.data; return *this;
    }
    RuleOfFive(RuleOfFive&& o) noexcept : data(o.data) { o.data = nullptr; } // move
    RuleOfFive& operator=(RuleOfFive&& o) noexcept {  // move assign
        delete data; data = o.data; o.data = nullptr; return *this;
    }
};
```

**Mengapa Penting:**  
- Menghindari double-free, memory leak, dan masalah kepemilikan resource.
- Compiler akan otomatis mengelola resource jika kita menggunakan tipe standard library.

**Kapan Digunakan:**  
- Selalu gunakan Rule of Zero jika memungkinkan.
- Jika tidak, ikuti Rule of Five dengan `= default` atau `= delete`.

**Best Practice:**  
- Gunakan `std::unique_ptr`, `std::vector`, `std::string` untuk manajemen memori otomatis.

---

## 3. `constexpr` — Komputasi di Waktu Kompilasi

**C++ Version:** C++11 (ditingkatkan di C++14, C++17, C++20)  
**Dependencies:** Tidak ada

```cpp
#include <iostream>

// Fungsi constexpr — bisa dijalankan saat compile-time jika argumennya konstanta
constexpr int factorial(int n) {
    int result = 1;
    for (int i = 2; i <= n; ++i) result *= i;
    return result;
}

int main() {
    constexpr int fac5 = factorial(5); // dihitung saat compile! Nilai langsung jadi 120
    std::cout << fac5 << '\n';

    int n = 6;
    // factorial(n) — tetap bisa dipanggil, tapi dihitung runtime
    std::cout << factorial(n) << '\n';
}
```

**Mengapa Penting:**  
- Memindahkan komputasi dari runtime ke compile-time, meningkatkan performa.
- Memungkinkan penggunaan nilai di tempat yang membutuhkan konstanta (ukuran array, template arguments).

**Kapan Digunakan:**  
- Untuk fungsi murni (pure) yang hasilnya hanya bergantung pada input.
- Untuk konstanta global seperti tabel lookup.

**Best Practice:**  
- Tandai fungsi atau variabel sebagai `constexpr` jika memungkinkan.
- Gunakan `constexpr` untuk menghindari "magic numbers".

---

## 4. `std::string_view` — View String Tanpa Alokasi

**C++ Version:** C++17  
**Dependencies:** Tidak ada

```cpp
#include <iostream>
#include <string_view>
#include <string>

// Fungsi yang menerima berbagai jenis string tanpa alokasi baru
void print(std::string_view sv) {
    std::cout << sv << '\n';
}

int main() {
    std::string s = "Hello std::string";
    const char* cs = "Hello C-string";
    char arr[] = {'H','e','l','l','o','\0'};

    print(s);  // konversi dari std::string → string_view (murah)
    print(cs); // langsung dari const char* (tanpa alokasi)
    print(arr); // dari char array (tanpa alokasi)
}
```

**Mengapa Penting:**  
- Menghindari konstruksi `std::string` sementara yang mahal.
- Memungkinkan fungsi bekerja dengan semua jenis data string secara seragam.

**Kapan Digunakan:**  
- Sebagai parameter fungsi read-only untuk string.
- Saat parsing, substring, atau operasi view-only.

**Best Practice:**  
- Gunakan `std::string_view` untuk menggantikan `const std::string&` pada parameter input.
- Hati-hati: `string_view` tidak memiliki data, pastikan data aslinya masih hidup saat digunakan.

---

## 5. `std::optional` — Mengembalikan "Mungkin Tidak Ada Nilai"

**C++ Version:** C++17  
**Dependencies:** Tidak ada

```cpp
#include <iostream>
#include <optional>

std::optional<int> divide(int a, int b) {
    if (b == 0) return std::nullopt;  // tidak ada nilai
    return a / b;
}

int main() {
    auto result = divide(10, 2);
    if (result.has_value()) {  // atau cukup `if (result)`
        std::cout << "Hasil: " << result.value() << '\n';
    }

    auto bad = divide(10, 0);
    std::cout << "Hasil kedua: " << bad.value_or(-1) << '\n'; // fallback jika kosong
}
```

**Mengapa Penting:**  
- Menggantikan pointer `nullptr` atau sentinel seperti `-1` yang rawan bug.
- Menyatakan secara eksplisit bahwa suatu fungsi mungkin gagal tanpa exception.

**Kapan Digunakan:**  
- Ketika return value mungkin tidak ada (pencarian, parsing).
- Sebagai alternatif exception untuk error yang diharapkan.

**Best Practice:**  
- Gunakan `.value_or(default)` untuk memberikan fallback yang aman.
- Jangan panggil `.value()` tanpa pengecekan.

---

## 6. `std::variant` — Union yang Aman

**C++ Version:** C++17  
**Dependencies:** `std::visit` (Trik 7)

```cpp
#include <iostream>
#include <variant>
#include <string>

using Data = std::variant<int, double, std::string>;

int main() {
    Data d;
    d = 42;  // sekarang berisi int
    std::cout << std::get<int>(d) << '\n';

    d = "hello"; // sekarang berisi string
    if (auto pval = std::get_if<std::string>(&d)) {
        std::cout << *pval << '\n';
    }

    // Visit untuk menangani semua kemungkinan
    std::visit([](const auto& val) {
        std::cout << "Nilai: " << val << '\n';
    }, d);
}
```

**Mengapa Penting:**  
- Menggantikan `union` mentah dengan cara yang aman.
- Memungkinkan pola "salah satu dari beberapa tipe" tanpa inheritance.

**Kapan Digunakan:**  
- Saat suatu variabel bisa memiliki beberapa tipe berbeda yang diketahui pada compile-time.
- Sebagai return type dari fungsi yang bisa menghasilkan beberapa jenis hasil.

**Best Practice:**  
- Selalu gunakan `std::visit` untuk menangani semua kemungkinan secara eksplisit.
- Hindari `std::get` tanpa pengecekan indeks.

---

## 7. `std::visit` — Polimorfisme Tanpa Inheritance

**C++ Version:** C++17  
**Dependencies:** `std::variant` (Trik 6)

```cpp
#include <iostream>
#include <variant>
#include <vector>

using Shape = std::variant<Circle, Rectangle>;

struct Circle { double radius; };
struct Rectangle { double width, height; };

int main() {
    std::vector<Shape> shapes = {Circle{5.0}, Rectangle{4.0, 6.0}};
    
    for (const auto& s : shapes) {
        std::visit([](const auto& shape) {
            using T = std::decay_t<decltype(shape)>;
            if constexpr (std::is_same_v<T, Circle>) {
                std::cout << "Lingkaran, luas: " << 3.14 * shape.radius * shape.radius << '\n';
            } else {
                std::cout << "Persegi, luas: " << shape.width * shape.height << '\n';
            }
        }, s);
    }
}
```

**Mengapa Penting:**  
- Polimorfisme compile-time tanpa virtual function overhead.
- Memaksa penanganan semua kasus (exhaustive checking).

**Kapan Digunakan:**  
- Ketika hierarki kelas datar dan diketahui pada compile-time.
- Untuk menggantikan pola visitor tradisional.

**Best Practice:**  
- Gunakan lambda generik (`auto&&`) di dalam `std::visit`.
- Gunakan `if constexpr` untuk membedakan tipe di dalam visitor.

---

## 8. `std::pair` dan `std::tuple` — Pengelompokan Data Ringan

**C++ Version:** C++11 (tuple), C++17 (structured binding untuk akses)  
**Dependencies:** Structured Bindings (Trik 9)

```cpp
#include <iostream>
#include <tuple>
#include <string>

std::tuple<int, std::string, double> getData() {
    return {42, "Alice", 3.14};
}

int main() {
    // Cara lama: std::get
    auto data = getData();
    std::cout << std::get<0>(data) << ' ' << std::get<1>(data) << '\n';

    // C++17: Structured Bindings (Trik 9)
    auto [id, name, score] = getData();
    std::cout << id << ' ' << name << ' ' << score << '\n';
}
```

**Mengapa Penting:**  
- Membawa multiple return value tanpa struct manual.
- Basis untuk structured bindings.

**Kapan Digunakan:**  
- Saat ingin mengembalikan beberapa nilai dari fungsi.
- Untuk menyimpan pasangan kunci-nilai sementara.

**Best Practice:**  
- Gunakan `std::tuple` untuk data sementara, tetapi pertimbangkan struct jika nama field bermakna.

---

## 9. Structured Bindings — Membongkar Tuple/Pair/Struct

**C++ Version:** C++17  
**Dependencies:** `std::pair`/`std::tuple` atau struct publik

```cpp
#include <iostream>
#include <map>
#include <string>

struct Point { int x, y; };

int main() {
    Point p = {10, 20};
    auto [a, b] = p; // a = p.x, b = p.y
    std::cout << a << ", " << b << '\n';

    std::map<int, std::string> m = {{1, "satu"}, {2, "dua"}};
    for (const auto& [key, val] : m) {
        std::cout << key << ": " << val << '\n';
    }
}
```

**Mengapa Penting:**  
- Membaca kode lebih alami dan eksplisit.
- Menghindari `.first` dan `.second` yang tidak jelas.

**Kapan Digunakan:**  
- Iterasi map.
- Menerima return multiple value.
- Mengakses member struct.

**Best Practice:**  
- Gunakan `const auto&` di loop untuk menghindari copy.

---

## 10. `if` dengan Inisialisasi — Batasi Scope Variabel

**C++ Version:** C++17  
**Dependencies:** Tidak ada

```cpp
#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<int, std::string> m = {{1, "satu"}};

    // if dengan inisialisasi
    if (auto it = m.find(1); it != m.end()) {
        std::cout << "Ditemukan: " << it->second << '\n';
    } // 'it' mati di sini
}
```

**Mengapa Penting:**  
- Variabel pembantu tidak bocor ke scope luar.
- Menggabungkan deklarasi dan pengecekan dalam satu baris.

**Kapan Digunakan:**  
- Setiap kali perlu iterator, status code, atau lock guard dalam blok if.

**Best Practice:**  
- Gunakan untuk lock guard (`std::lock_guard`) agar terkunci hanya di scope if.

---

## 11. `emplace_back` vs `push_back` — Konstruksi In-Place

**C++ Version:** C++11  
**Dependencies:** Move Semantics (Trik 12) untuk mengerti kenapa efisien

```cpp
#include <iostream>
#include <vector>
#include <string>

struct Person {
    std::string name;
    int age;
    Person(std::string n, int a) : name(n), age(a) {
        std::cout << "Person dibuat: " << name << '\n';
    }
};

int main() {
    std::vector<Person> people;
    people.reserve(2); // alokasi di awal

    // push_back: buat objek sementara, copy/move
    people.push_back(Person("Alice", 30));

    // emplace_back: konstruksi langsung di dalam vektor
    people.emplace_back("Bob", 25); // tidak ada objek sementara!
}
```

**Mengapa Penting:**  
- Menghilangkan konstruksi dan destruksi objek sementara.
- Memungkinkan konstruksi objek dengan argumen langsung.

**Kapan Digunakan:**  
- Saat menambahkan elemen baru ke kontainer dengan argumen konstruktor.

**Best Practice:**  
- Selalu gunakan `emplace_back` daripada `push_back` jika memungkinkan.
- Gunakan `reserve()` untuk menghindari re-alokasi.

---

## 12. Move Semantics — `std::move` dan `noexcept`

**C++ Version:** C++11  
**Dependencies:** Rule of Five (Trik 2)

```cpp
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::string source = "data besar yang akan dipindahkan";
    // std::move: mentransfer kepemilikan, tanpa copy
    std::string target = std::move(source);
    // source sekarang dalam status "valid but unspecified" (biasanya kosong)
    std::cout << "Target: " << target << '\n';
}
```

**Mengapa Penting:**  
- Menghindari deep copy untuk objek yang mengelola resource heap.
- Kunci efisiensi C++ modern.

**Kapan Digunakan:**  
- Saat memindahkan kepemilikan ke fungsi lain.
- Saat mengembalikan objek lokal dari fungsi (compiler sering otomatis melakukan move).

**Best Practice:**  
- Jangan gunakan `std::move` pada objek yang masih akan dipakai.
- Tandai move constructor dan move assignment operator dengan `noexcept`.

---

## 13. Smart Pointers — `unique_ptr` dan `shared_ptr`

**C++ Version:** C++11  
**Dependencies:** Move Semantics (Trik 12) untuk `unique_ptr`

```cpp
#include <iostream>
#include <memory>

struct Resource {
    Resource() { std::cout << "Resource dibuat\n"; }
    ~Resource() { std::cout << "Resource dihancurkan\n"; }
    void doWork() { std::cout << "Bekerja\n"; }
};

int main() {
    // unique_ptr: kepemilikan eksklusif
    auto res = std::make_unique<Resource>();
    res->doWork();
    // Tidak perlu delete, otomatis saat keluar scope

    // shared_ptr: kepemilikan bersama
    auto sp = std::make_shared<Resource>();
    auto sp2 = sp; // dua pointer ke resource yang sama
}
```

**Mengapa Penting:**  
- Menggantikan `new`/`delete` manual dengan manajemen memori otomatis.
- Ekspresif tentang kepemilikan.

**Kapan Digunakan:**  
- `unique_ptr`: default untuk manajemen resource.
- `shared_ptr`: ketika kepemilikan dibagi.

**Best Practice:**  
- Selalu gunakan `std::make_unique` / `std::make_shared`.
- Jangan pernah tulis `new` atau `delete` secara manual.

---

## 14. Lambda Modern — Generic, Capture, dan `constexpr`

**C++ Version:** C++11 (generik di C++14)  
**Dependencies:** `auto` (Trik 1)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

int main() {
    // Lambda generik (C++14) — parameter auto
    auto print = [](const auto& x) { std::cout << x << ' '; };
    
    std::vector<int> v = {1, 2, 3, 4};
    std::for_each(v.begin(), v.end(), print);
    std::cout << '\n';

    // Capture by value (x) dan by reference (&y)
    int x = 10, y = 20;
    auto cap = [x, &y]() mutable { x++; y++; std::cout << x << ' ' << y << '\n'; };
    cap(); // x lokal lambda jadi 11, y jadi 21
    std::cout << "x luar: " << x << ", y luar: " << y << '\n'; // x tetap 10, y jadi 21
}
```

**Mengapa Penting:**  
- Menggantikan fungsi kecil yang hanya dipakai sekali.
- Menangkap konteks sekitar dengan aman.

**Kapan Digunakan:**  
- Callback, algoritma STL, threading.
- Penyesuaian perilaku pada fungsi generic.

**Best Practice:**  
- Gunakan capture `[&]` atau `[=]` hanya jika lambda sangat lokal.
- Hindari capture default di lambda yang keluar dari scope.

---

## 15. `enum class` — Enumerasi Aman

**C++ Version:** C++11  
**Dependencies:** Tidak ada

```cpp
#include <iostream>

enum class Color { Red, Green, Blue };
enum class TrafficLight { Red, Yellow, Green };

int main() {
    Color c = Color::Red;
    // if (c == TrafficLight::Red) // Error kompilasi: tipe berbeda
    std::cout << static_cast<int>(c) << '\n'; // 0
}
```

**Mengapa Penting:**  
- Mencegah perbandingan antar enum yang berbeda.
- Mencegah polusi namespace.

**Kapan Digunakan:**  
- Selalu gunakan `enum class` daripada `enum` biasa.

**Best Practice:**  
- Beri nama enum dengan jelas.
- Gunakan `static_cast` jika perlu konversi ke int.

---

## 16. CTAD (Class Template Argument Deduction) — Kurangi Penulisan Tipe

**C++ Version:** C++17  
**Dependencies:** Tidak ada

```cpp
#include <vector>
#include <utility>

int main() {
    std::vector v = {1, 2, 3}; // CTAD: std::vector<int>
    std::pair p = {1, "satu"}; // std::pair<int, const char*>
    // Tanpa CTAD harus tulis std::pair<int, const char*> p = ...
}
```

**Mengapa Penting:**  
- Mengurangi boilerplate yang membosankan.
- Kode lebih bersih tanpa mengorbankan keamanan tipe.

**Kapan Digunakan:**  
- Saat inisialisasi dengan daftar atau konstruktor yang jelas.

**Best Practice:**  
- Gunakan CTAD saat tipe jelas dari initializer.
- Jika ragu, tetap tulis tipe secara eksplisit.

---

## 17. Fold Expressions — Operasi pada Parameter Pack

**C++ Version:** C++17  
**Dependencies:** Variadic Templates (advanced)

```cpp
#include <iostream>

template<typename... Args>
auto sum(Args... args) {
    return (args + ...); // fold expression: (1 + (2 + (3 + 4)))
}

int main() {
    std::cout << sum(1, 2, 3, 4) << '\n'; // 10
}
```

**Mengapa Penting:**  
- Menyederhanakan operasi pada variadic template.
- Menghilangkan rekursi manual.

**Kapan Digunakan:**  
- Saat menulis fungsi template dengan jumlah argumen variabel.

**Best Practice:**  
- Gunakan fold expressions untuk operasi aritmatika, logika, atau koma.

---

## 18. `constexpr if` — Kompilasi Bercabang

**C++ Version:** C++17  
**Dependencies:** `constexpr` (Trik 3)

```cpp
#include <iostream>
#include <type_traits>

template<typename T>
void process(const T& val) {
    if constexpr (std::is_integral_v<T>) {
        std::cout << "Ini integer: " << val << '\n';
    } else if constexpr (std::is_floating_point_v<T>) {
        std::cout << "Ini float: " << val << '\n';
    } else {
        std::cout << "Tipe lain: " << val << '\n';
    }
}

int main() {
    process(10);    // integer
    process(3.14);  // float
    process("hi");  // tipe lain
}
```

**Mengapa Penting:**  
- Memilih cabang kode pada compile-time, bukan runtime.
- Mengurangi overhead percabangan dan memungkinkan optimasi lebih lanjut.

**Kapan Digunakan:**  
- Di dalam template untuk menangani tipe berbeda secara optimal.

**Best Practice:**  
- Gunakan `if constexpr` sebagai pengganti SFINAE yang rumit.

---

## 19. `std::span` — View Array Tanpa Kepemilikan

**C++ Version:** C++20  
**Dependencies:** Konsep mirip dengan `std::string_view` (Trik 4)

```cpp
#include <iostream>
#include <span>
#include <vector>

void print(std::span<int> data) {
    for (int v : data) std::cout << v << ' ';
    std::cout << '\n';
}

int main() {
    int arr[] = {1, 2, 3};
    std::vector<int> v = {4, 5, 6};

    print(arr); // dari array C
    print(v);   // dari vektor
}
```

**Mengapa Penting:**  
- Menyediakan antarmuka umum untuk array, vektor, dan contiguous container tanpa copy.
- Menghindari pointer + size manual yang rawan error.

**Kapan Digunakan:**  
- Sebagai parameter fungsi untuk menerima urutan data apa pun.

**Best Practice:**  
- Gunakan `std::span<const T>` untuk read-only.
- Hati-hati dengan lifetime data yang di-view.

---

## 20. `[[nodiscard]]` — Jangan Abaikan Return Value

**C++ Version:** C++17  
**Dependencies:** Tidak ada

```cpp
#include <iostream>

[[nodiscard]] bool connectToServer() {
    // ...
    return true;
}

int main() {
    connectToServer(); // Warning: return value diabaikan
    bool ok = connectToServer(); // Benar
}
```

**Mengapa Penting:**  
- Mencegah bug karena mengabaikan nilai balik yang penting (error, resource).

**Kapan Digunakan:**  
- Pada fungsi yang mengembalikan status, resource yang harus dikelola, atau hasil yang tidak boleh diabaikan.

**Best Practice:**  
- Gunakan `[[nodiscard]]` secara default untuk fungsi yang return value-nya penting.

---

## 21. `std::format` — String Format Modern

**C++ Version:** C++20  
**Dependencies:** Tidak ada

```cpp
#include <iostream>
#include <format>

int main() {
    int id = 42;
    std::string name = "Alice";
    // std::format — seperti Python f-string, aman dan ekspresif
    auto msg = std::format("User ID: {}, Name: {}", id, name);
    std::cout << msg << '\n';
}
```

**Mengapa Penting:**  
- Menggantikan `std::ostringstream` yang verbose dan lambat.
- Type-safe dan mendukung format specifier modern.

**Kapan Digunakan:**  
- Untuk semua operasi formatting string (log, UI, output).

**Best Practice:**  
- Gunakan `std::format` untuk semua formatting mulai dari C++20.
- Gunakan pustaka `{fmt}` jika compiler belum mendukung.

---

## 22. `consteval` — Fungsi yang Hanya Berjalan Saat Kompilasi

**C++ Version:** C++20  
**Dependencies:** `constexpr` (Trik 3)

```cpp
#include <iostream>

consteval int square(int n) {
    return n * n;
}

int main() {
    constexpr int val = square(5); // OK, komputasi compile-time
    // int x = 5; int y = square(x); // Error, x tidak constexpr
    std::cout << val << '\n';
}
```

**Mengapa Penting:**  
- Menjamin evaluasi pada compile-time, tanpa overhead runtime.
- Cocok untuk komputasi yang memang harus selesai sebelum program berjalan.

**Kapan Digunakan:**  
- Untuk tabel lookup, konstanta kompleks, atau validasi yang harus dijamin saat compile.

**Best Practice:**  
- Gunakan `consteval` untuk fungsi yang tidak boleh dipanggil saat runtime.

---

## 🔗 Dependensi Lengkap

Tabel di awal dokumen merangkum dependensi. Jika kamu mempelajari trik-trik ini secara berurutan, kamu akan siap menulis C++ modern yang aman, cepat, dan ekspresif.

---

*C++ Modern Best Practices | 22 Trik Wajib · auto, move, smart pointers, constexpr, structured bindings, coroutines*
