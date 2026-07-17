---
title: "Clean Code — Robert C. Martin"
tags:
  - library
  - software-engineering
aliases:
  - "clean-code-robert-martin"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# 🚀 Clean Code

> Robert C. Martin ("Uncle Bob") — 2008

**Tesis:** Kode yang bersih bukan soal estetika — soal **survival** proyek. Kode kotor bikin tim lambat, utang teknikal numpuk, akhirnya rewrite. Kode bersih _reads like well-written prose_ — kode yang orang lain baca dan langsung ngerti tanpa mikir.

---

## 📌 Kenapa Penting

- **Kode dibaca ~10x lebih sering daripada ditulis.** Waktu luang developer 60% buat baca kode, cuma 20% nulis. Jadi _readability_ bukan opsional.
- **Efek kumulatif.** Kode kotor dikit per hari, setahun jadi utang yang bikin kecepatan tim turun drastis. Tim kompeten di kode kotor bisa lebih lambat dari tim baru di kode bersih.
- **Boy Scout Rule:** _Leave the campground cleaner than you found it_. Setiap sentuh file, tinggalkan lebih rapi — walau cuma rename 1 variabel jelek.
- **Kualitas kode = tanggung jawab setiap developer**, bukan cuma tech lead. Tech lead bikin standar, developer jaga disiplin.

> [!tip] **Analogi:** Kode kotor itu kayak kamar kost yang setiap hari ditambah barang baru tanpa beresin. Minggu pertama masih rapi. Minggu ketiga cari kunci motor butuh 10 menit. Bulan ketiga — pindah kost.

---

## 🎯 Meaningful Names — Paling Fundamental

### Nama Harus _Reveal Intent_

```python
# Buruk — butuh komentar karena namanya gak jelas
d = 0  # elapsed time in days since last modification

# Baik — nama langsung bilang semuanya
elapsed_time_in_days = 0
```

**Tes:** Kalau masih butuh komentar buat jelasin variabel, namanya jelek.

### Avoid Disinformation

```python
# Buruk — tipenya Set, tapi dikasih nama List
user_account_list = set()

# Baik
user_accounts = set()
```

### Searchable Names

- Satu huruf (`i`, `j`, `k`) hanya untuk loop counter yang scope-nya ≤ 5 baris.
- Nama panjang untuk konsep penting: `MAX_RETRY_ATTEMPTS` lebih mudah dicari daripada `7`.

### Konvensi

| Elemen   | Aturan                    | Contoh                                 |
| -------- | ------------------------- | -------------------------------------- |
| Class    | Noun                      | `Customer`, `PaymentProcessor`         |
| Method   | Verb atau verb phrase     | `pay()`, `validateEmail()`             |
| Variable | Noun atau short phrase    | `total_price`, `is_ready`              |
| Constant | UPPER_SNAKE_CASE          | `MAX_FILE_SIZE`                        |
| Boolean  | `is`, `has`, `can` prefix | `isActive`, `hasPermission`, `canEdit` |

### Peringatan Tambahan

- **Jangan singkat tanpa alasan.** `usr_cnt` vs `user_count` — yang kedua langsung jelas, tanpa tebak-tebakan.
- **Jangan bedain cuma dari casing.** `Customer`, `customer`, `CUSTOMER` di file yang sama itu resep bencana.
- **Jangan pake noise words.** `Info` dan `Data` di akhir nama — `ProductInfo` vs `ProductData` gak beda arti. Pilih 1.

---

## 🎯 Functions — Aturan Emas

### 1. Harus Kecil

Target: **< 20 baris.** Kalo lebih, curigai. Fungsi yang baik bisa dibaca sekilas dan langsung paham alurnya.

### 2. Do One Thing (DOT)

Satu fungsi = satu level abstraksi. Tesnya: coba tulis deskripsi fungsi dalam 1 kalimat. Kalo ada "dan" di tengah — fungsi lu ngelakuin > 1 hal.

```python
# Buruk — 3 tanggung jawab: parse + prosses + logging
def process_file(path):
    with open(path, 'r') as f:
        data = json.load(f)
    result = data['value'] * 2
    logger.info(f"Processed {path}: {result}")
    return result

# Baik — 3 fungsi, masing-masing 1 urusan
def read_json(path):
    with open(path, 'r') as f:
        return json.load(f)

def transform_value(value):
    return value * 2

def process_file(path):
    data = read_json(path)
    result = transform_value(data['value'])
    log_processing(path, result)
    return result
```

### 3. No Side Effects

Fungsi yang bilang "hitung total" tapi dalamnya nulis ke database — itu side effect. Kejutan gak enak buat pemanggil.

```python
# Buruk — side effect gak terduga
def get_total_price(item_ids):
    total = calculate_sum(item_ids)
    save_to_history(item_ids, total)  # ⚠️ gak ada yang nyangka ini nulis DB
    return total

# Baik — jelas: pisah query dari command
def get_total_price(item_ids):
    return calculate_sum(item_ids)

def save_order_history(item_ids, total):
    ...
```

### 4. One Level of Abstraction Per Function

Jangan campur detail teknis (SQL query, file I/O) sama logika bisnis (menghitung diskon, validasi rule).

```python
# Buruk — campur abstraksi rendah & tinggi
def process_order(order):
    db.execute("INSERT INTO orders VALUES (?)", order.id)  # detail SQL
    total = order.items * order.price  # logika bisnis
    send_email(order.email, total)  # detail infrastruktur

# Baik — setiap fungsi di level sendiri
def process_order(order):
    persist_order(order)
    total = calculate_total(order)
    notify_customer(order.email, total)
```

### 5. Arguments

Idealnya **0 argumen**. 1 argumen masih oke. 2 agak riskan. 3 — hampir selalu bisa di-refactor.

```python
# Buruk — 3 argumen, urutan susah diingat
create_user("azhar", "azhar@mail.com", True)

# Baik — 1 argumen (object), gak perlu hapal urutan
opts = UserOptions(name="azhar", email="azhar@mail.com", is_active=True)
create_user(opts)
```

### 6. DRY (Don't Repeat Yourself)

Duplikasi = 2 tempat harus diubah kalo requirement berubah. 1 lupa = bug.

---

## 🎯 Comments — Makin Sedikit Makin Baik

### Comment yang _Tidak_ Boleh

```python
# Buruk: komentar basi yang jelas dari kode
x = x + 1  # increment x

# Buruk: komentar journaling (siapa nulis, kapan)
# 2026-07-01: Azhar added this loop (tapi lupa hapus)

# Buruk: komentar yang gak sinkron sama kode
# Fungsi ini return total price
def get_count():  # ⚠️ namanya get_count tapi komentar bilang price
    ...
```

### Comment yang Boleh

```python
# 1. Legal (copyright, license)
# Copyright 2026 Azhar — MIT License

# 2. Informative (intent, kenapa bukan gimana)
# Pakai binary search karena array sudah terurut

# 3. Warning (konsekuensi)
# Hati-hati: timeout ini blok thread, jangan panggil main loop

# 4. TODO (tapi harus ada dateline)
# TODO: ganti hardcode 100 dengan config — sebelum deploy v2
```

### Prinsip: Kode yang baik adalah self-documenting. Kalo butuh komentar buat jelasin _apa_ yang dilakukan — berarti kodenya jelek. Komentar cuma buat jelasin _kenapa_.

---

## 🎯 Error Handling

### Pakai Exceptions, Jangan Return Codes

```python
# Buruk — return code, pemanggil harus ngecek tiap kali
result = delete_user(id)
if result == -1:
    print("User not found")
elif result == -2:
    print("Database error")

# Baik — exception, gak perlu ngecek manual
try:
    delete_user(id)
except UserNotFoundError:
    print("User not found")
except DatabaseError:
    print("Database error")
```

### Wrap Third-Party APIs

API external (library, service) bisa berubah kapan aja. Bungkus dengan wrapper biar gak bocor ke domain code.

```python
# Buruk — panggil external API langsung di business logic
def send_notification(email, message):
    mailgun_client = MailgunClient(api_key)
    mailgun_client.send(email, message)  # kalo Mailgun berubah API, ini bocor ke mana-mana

# Baik — wrapper isolasi
class EmailService:
    def __init__(self):
        self.client = MailgunClient(api_key)

    def send(self, email, message):
        self.client.send(email, message)

def send_notification(email, message):
    service = EmailService()
    service.send(email, message)
```

### Don't Pass Null, Don't Return Null

Null return = pemanggil harus null-check tiap kali. Kalo lupa → NullPointerException.

```python
# Buruk — return None
def find_user(id):
    if not exists(id):
        return None
    ...

user = find_user(5)
print(user.name)  # TypeError kalo user None

# Alternatif — return Optional / raise exception
def find_user(id):
    if not exists(id):
        raise UserNotFoundError(id)
    ...

# Atau — Null Object Pattern
def find_user(id):
    if not exists(id):
        return User.anonymous()
    ...
```

---

## 🎯 TDD — Red-Green-Refactor (Detail)

Ini siklus inti Test-Driven Development. Bukan cuma "test dulu baru coding" — ada makna di tiap langkah.

### 🔴 RED — Tulis Test yang Gagal

1. Sebelum nulis _satu baris kode produksi_, tulis test dulu.
2. Test harus spesifik — apa yang diharapkan dari kode yang BELUM ditulis.
3. Test harus **gagal** (red). Kalo test lulus saat belum ada implementasi, testnya salah.

```python
# Test ditulis SEBELUM ada fungsi make_itinerary
def test_make_itinerary_simple():
    # Arrange
    flights = ["CGK-DPS", "DPS-UPG"]
    hotel = "Grand Bali"

    # Act
    result = make_itinerary(flights, hotel)

    # Assert
    assert result == "CGK-DPS → DPS-UPG\n🏨 Grand Bali"

# ⚠️ Test ini pasti gagal — fungsi make_itinerary belum ada
```

**Kenapa harus gagal?**

- Bukti bahwa test benar-benar nguji sesuatu yang belum ada.
- Kalau test lulus tanpa implementasi, test mungkin gak ngecek apa-apa (false positive).
- Test yang gagal juga nge-verifikasi _interface_ — kamu liat dari error apakah parameter/return type sudah cocok.

### 🟢 GREEN — Bikin Test Lulus Secepat Mungkin

1. Tulis implementasi paling minimal yang bikin test lulus.
2. **Jangan pikir elegant.** Pikir "beres dulu".
3. Kalo perlu hardcode return value — silakan. Nanti refactor.

```python
# Implementasi paling minimal
def make_itinerary(flights, hotel):
    return "CGK-DPS → DPS-UPG\n🏨 Grand Bali"

# Test lulus ✅
```

**"Hardcode?! Beneran?"**
Beneran. Ini fase GREEN. Yang penting test lulus. Nanti REFACTOR yang bikin kode jadi proper. Hardcode di sini cuma buat validasi: "apakah test saya benar dan konsisten dengan ekspektasi?"

### 🔵 REFACTOR — Perbaiki Tanpa Ubah Perilaku

1. Sekarang kode sudah berfungsi (test green). Waktunya polish.
2. Hapus hardcode, bikin logika beneran.
3. Pastikan test tetap lulus setelah refactor.

```python
# Refactor — kode proper
def make_itinerary(flights, hotel):
    flights_summary = " → ".join(flights)
    return f"{flights_summary}\n🏨 {hotel}"

# Test tetap lulus ✅ — perilaku sama, kode lebih rapih
```

### Kenapa TDD Kuat?

| Manfaat                 | Penjelasan                                                        |
| ----------------------- | ----------------------------------------------------------------- |
| **Design feedback**     | Test yang susah ditulis = pertanda kode terlalu kompleks          |
| **Regression safety**   | Refactor takut rusak sesuatu? Tinggal jalanin test                |
| **Zero debugging time** | Kalau test gagal, tahu persis bagian mana yang salah              |
| **Documentation hidup** | Test = dokumentasi yang selalu sinkron — kalo berubah, test merah |
| **Courage**             | Berani refactor tanpa takut — safety net-nya test                 |

### Satu Assert Per Test

```python
# Ideal
def test_total_with_discount():
    cart = Cart()
    cart.add(Item(price=100))
    result = cart.total_with_discount(10)  # 10% discount
    assert result == 90

# Bukan
def test_total():
    cart = Cart()
    cart.add(Item(price=100))
    assert cart.total_with_discount(0) == 100
    assert cart.total_with_discount(100) == 0
    assert cart.total_with_discount(10) == 90  # ❌ multiple assert
```

Satu assert per test = tiap test punya 1 alasan untuk gagal. Kalau test dengan 3 assert gagal, kamu gak langsung tahu yang mana.

### F.I.R.S.T — 5 Aturan Test Baik

| Huruf               | Arti             | Maksud                                                                     |
| ------------------- | ---------------- | -------------------------------------------------------------------------- |
| **F**ast            | Cepat            | Test butuh milidetik. Yang butuh 10 detik — orang males jalanin.           |
| **I**ndependent     | Mandiri          | Test A gak boleh bergantung test B. Jalankan urutan apa aja hasilnya sama. |
| **R**epeatable      | Bisa diulang     | Jalanin 10x hasilnya sama. Gak boleh tergantung waktu/network/file system. |
| **S**elf-Validating | Validasi sendiri | Output: lulus/gagal. Gak perlu manual cek file log.                        |
| **T**imely          | Tepat waktu      | Test ditulis _tepat sebelum_ kode produksi (sesuai TDD).                   |

**Contoh Test yang Gak FIRST:**

```python
# ❌ Gak INDEPENDENT: butuh database nyata
def test_create_user():
    db = connect_to_production_db()  # ❌
    db.delete_all_users()
    create_user("test")
    count = db.count_users()
    assert count == 1  # bakal gagal kalo ada user lain

# ❌ Gak SELF-VALIDATING: hasil di print manual
def test_payment():
    result = process_payment(100)
    print(f"Result: {result}")  # ❌ harus dibaca manual
```

---

## 🎯 Classes — SRP & Cohesion

### Single Responsibility Principle (SRP)

**Satu class = satu alasan untuk berubah.** Bukan "satu file = satu fungsi" — lebih ke: kalo ada perubahan requirement, berapa banyak class yang kena?

```python
# ❌ Buruk — 3 alasan untuk berubah
class InvoiceManager:
    def calculate_total(self, items): ...
    def save_to_db(self, invoice): ...
    def send_email(self, invoice): ...

# ✅ Baik — terpisah, tiap class 1 alasan berubah
class InvoiceCalculator:
    def calculate_total(self, items): ...

class InvoiceRepository:
    def save(self, invoice): ...

class InvoiceMailer:
    def send(self, invoice): ...
```

**Tes SRP sederhana:** Jelaskan classmu dalam 1 kalimat. Kalau ada "dan" atau "serta" — langgar SRP.

### High Cohesion + Low Coupling

- **Kohesi tinggi:** Method di 1 class harus saling terkait. Class `Order` punya method `add_item()` dan `remove_item()` — kohesif. Tapi `Order` punya method `send_to_printer()` — gak kohesif.
- **Coupling rendah:** 1 class harus tahu sedikit mungkin tentang class lain.

### Prefer Many Small Classes Over One God Class

God class = class yang > 1000 baris dan ngatur semuanya. Mimpi buruk maintenance. Refactor bertahap: petik bagian yang independen, pindahin ke class baru.

---

## 🎯 Boundaries — Batas Antara Kode Kita & Pihak Ketiga

Third-party library: kamu gak punya kontrol. API bisa berubah, bisa deprecated, bisa ganti lisensi.

### Prinsip:

1. **Jangan bocor ke domain.** Kode bisnis gak boleh panggil library langsung. Bungkus (wrap).
2. **Learning tests.** Sebelum pake library baru, tulis test kecil yang belajar API-nya. Ini dokumentasi live.
3. **Adapter pattern.** Ganti library tinggal ganti adapter, domain code zero change.

```python
# Boundary dengan adapter
class PaymentGateway:
    """Adapter untuk payment library — ganti provider tinggal ganti class ini"""
    def __init__(self):
        self.provider = StripeAPI(secret_key)

    def charge(self, amount, token):
        return self.provider.charge(amount, token)

# Domain code — gak tahu Stripe atau Midtrans
def process_checkout(order, payment_token):
    gateway = PaymentGateway()
    result = gateway.charge(order.total, payment_token)
    ...
```

---

## 📖 Bab Penting & Porsi Bacaan

| Bab     | Judul                       | Prioritas      | Waktu baca |
| ------- | --------------------------- | -------------- | ---------- |
| 2       | Meaningful Names            | ✅ Wajib       | ~20 menit  |
| 3       | Functions                   | ✅ Wajib       | ~30 menit  |
| 5       | Formatting                  | ⭐ Rekomendasi | ~15 menit  |
| 6       | Objects and Data Structures | ⭐ Rekomendasi | ~20 menit  |
| 7       | Error Handling              | ✅ Wajib       | ~20 menit  |
| 10      | Classes                     | ✅ Wajib       | ~15 menit  |
| 15      | JUnit Internals             | 🔧 Case study  | ~30 menit  |
| 11      | Systems                     | 🔧 Lanjutan    | ~15 menit  |
| Lainnya | —                           | 📖 Pelengkap   | Skip dulu  |

---

## ⚠️ Kritik & Konteks — Jangan Ditelan Mentah-mentah

| Kritik               | Penjelasan                                       | Kapan Diabaikan                                               |
| -------------------- | ------------------------------------------------ | ------------------------------------------------------------- |
| Terlalu dogmatis     | "Functions must be < 20 lines" kadang butuh > 20 | Saat readability justru lebih baik dengan fungsi agak panjang |
| Java-oriented (2008) | Contoh pake Java tanpa lambda/stream             | Prinsip tetap valid, adaptasi syntax ke bahasa lu             |
| Over-SRP             | Terlalu kecil bikin file 100 file                | SRP yang wajar: 1 class ~100-200 baris                        |
| TDD mahal            | Nulis 2x (test + kode) butuh waktu               | Di proyek kompleks TDD ngirit waktu debug 5x lipat            |

**Prinsip sehat:** Ambil esensinya — naming, SRP, testability, error handling. Adaptasi sisanya sesuai bahasa, framework, dan tim.

---

## 🔗 Koneksi ke Vault Lain

- [[the-pragmatic-programmer]] — mindset overlap: DRY, TDD, knowledge portfolio, broken window theory
- [[design-patterns-gof]] — banyak design pattern yang jawab "gimana bikin kode bersih" (adapter, strategy, factory)
- [[refactoring-martin-fowler]] — teknik konkret: extract method, rename variable, move field
- [[clean-code-robert-martin]] (refactoring pattern) — strategi bersihin kode warisan yang gak punya test
- [[ddia-summary]] — clean code di level sistem: boundaries, isolation, SRP di arsitektur

---

## ✅ Checklist Praktik

- [ ] Baca kode lama tiap hari — cari 1 pelanggaran naming, refactor langsung
- [ ] Terapkan TDD di 1 fitur kecil per sprint — rasain feedback loop-nya
- [ ] Refactor 1 function per hari tanpa ngubah perilaku — ekstrak, rename, sederhanakan
- [ ] Boy Scout Rule: setiap sentuh file, tinggalkan lebih bersih
- [ ] Bikin wrapper untuk third-party API sebelum integrasi ke domain code
- [ ] Cek SRP: kalo ada kelas > 300 baris, curigai dan refactor
- [ ] Ganti 1 komentar basi per hari dengan kode yang lebih jelas
- [ ] Pastikan setiap test di project bisa jalan tanpa internet
