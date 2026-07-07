---
title: "Bonus Books – Refactoring Warisan, YDKJS & Knuth (Rekompletsasi Utuh)"
tags:
  - library
  - software-engineering
aliases:
  - "bonus-books-complete-expanded"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# 📚 Rujakan Buku Bonus – Refactoring Warisan, YDKJS & Knuth (Rekompesialisasi Utuh)

> **Tujuan:** Dokumen referensi lengkap yang mengintegrasikan _Working Effectively with Legacy Code_ (Michael Feathers), _You Don’t Know JS_ (Kyle Simpson), dan _The Art of Computer Programming_ (Donald Knuth) menjadi satu satuan referensi untuk vault. Dokumen ini ditulis dalam bahasa Indonesia, dibangun untuk pembacaan mendalam, penerapan praktis, serta referensi masa depan. Setiap bagian dilengkapi contoh konkret, potongan kode, serta daftar tindakan yang bisa langsung diambil.

---

## 1️⃣ Working Effectively with Legacy Code – Michael Feathers (Renum Detail)

### 1.1 Tesis Inti (Dineleh Ulangi)

> **Anda bisa mengubah kode yang tidak teruji dan tidak terdokumentasi dengan aman** melalui **pengesokan perubahan (seam)** dan **verifikasi perilaku** menggunakan _characterization tests_ sebelum melakukan refactor struktural.

### 1.2 Mengapa Konsep “Seam” Penting?

- **Seam** adalah tempat di mana perilaku dapat diubah **tanpa** memengaruhi sistem lain.
- Seam dapat berada pada:
  - **Batas metode** (public vs. private).
  - **Nilai konfigurasi** (variabel lingkungan, flag fitur).
  - **Titik I/O** (file, jaringan, koneksi database).
- Dengan membungkus seam, Anda dapat menyuntikkan _double test_, _proxy pencatatan_, atau implementasi staging.

### 1.3 Alur Refactor Langkah demi Langkah

| Langkah                 | Aktivitas                                                                                                                     | Alat / Perintah          | Contoh                                                                                                                                                                                                                                                     |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Identifikasi**     | Temukan _metode berisiko_ (besar, tidak teruji).                                                                              | `grep -R "def .*{" src/` | `def process_user_data(data): …`                                                                                                                                                                                                                           |
| **2. Karakterisasi**    | Tulis **characterization test** yang mencatat _output aktual_ untuk set input representatif.                                  | `unittest` / `pytest`    | `python\ndef test_process_user_data_char():\n    sample = {...}\n    captured = io.StringIO()\n    sys.stdout = captured\n    process_user_data(sample)\n    output = captured.getvalue()\n    with open('legacy_output.txt','w') as f: f.write(output)\n` |
| **3. Perkenalkan Seam** | Tambahkan _hook_ (biasanya argumen default `None`).                                                                           | Edit sumber              | `python\ndef process_user_data(data, logger=None):\n    if logger: logger.info('processing %s', data)\n    ...\n`                                                                                                                                          |
| **4. Bungkus**          | Sediakan **implementasi wrapper** yang memasukkan seam (mis. logger, atau double mock).                                       | N/A                      | `python\nclass TestLogger:\n    def info(self, msg): print('[TEST]', msg)\n\ndef process_user_data(data):\n    process_user_data(data, logger=TestLogger())\n`                                                                                             |
| **5. Refactor**         | Ubah logika internal _setelah_ seam tersedia; jalankan kembali characterization test untuk memastikan perilaku tidak berubah. | Refactoring IDE          | Rename variabel, extract method, dll.                                                                                                                                                                                                                      |
| **6. Verifikasi**       | Jalankan **suite tes penuh** (atau setidaknya characterization test) untuk memastikan tidak ada regresi.                      | `pytest`                 | `bash\npytest test_legacy.py\n`                                                                                                                                                                                                                            |

### 1.4 Teknik Penemuan Seam Lanjutan

| Teknik                               | Penjelasan                                                                                      | Contoh Praktis                                                                                                                                                                                                                                                             |
| ------------------------------------ | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Runtime Seam Injection**           | Monkey‑patch modul pada saat impor untuk menyisipkan mock.                                      | `python\nimport sys, types\nclass FakeDB:\n    def query(self, q): return []\n\ntypes.ModuleType('db')( 'query', FakeDB().query )\n`                                                                                                                                       |
| **Pemecahan Bergantung Kondisional** | Gunakan blok `#ifdef TEST`‑style (via `if __debug__`) untuk mengekspos seam hanya di build uji. | `python\nif __debug__:\n    def get_connection(): return TestConnection()\nelse:\n    def get_connection(): return RealConnection()\n`                                                                                                                                     |
| **Decorator‑Based Seam**             | Bungkus fungsi dengan decorator yang mencatat atau mengganti implementasi.                      | `python\nimport functools\n\ndef trace_and_maybe_replace(fn):\n    @functools.wraps(fn)\ndef wrapper(*args, **kw):\n        print('[TRACE]', fn.__name__)\n        return fn(*args, **kw)\n    return wrapper\n\n@trace_and_maybe_replace\ndef legacy_calc(x):\n    ...\n` |

### 1.5 refactor.com – Katalog Seam Berbasis Komunitas

- **Salamai**: katalog yang dapat dicari _seam_ yang umumnya muncul pada hampir semua bahasa pemrograman.
- Setiap entri mencantumkan **masalah**, **lokasi seam**, **polanya solusi**, serta **langkah refactor**.

### 1.6 Cheklist – “Legacy‑Code Refactor‑Ready”

- [ ] Identifikasi _metode berisiko_ (tidak ada tes, churn tinggi).
- [ ] Tulis **characterization test** untuk perilaku aktual.
- [ ] Temukan setidaknya satu **seam** (parameter, ketergantungan, I/O).
- [ ] Tambahkan **wrapper / mock** untuk memunculkan seam.
- [ ] Jalankan suite tes; Pastikan iya.
- [ ] Refactor secara internal; Ulangi tes.
- [ ] Dokumentasikan lokasi **seam** di ADR (lihat template ADR vault).

---

## 2️⃣ You Don’t Know JS – Kyle Simpson (Renum Detail)

### 2.1 Tesis inti (Dineleh Ulangi)

> \**Pengetahuan JavaScript memimpersiapkan pada _scope, closures, dan penanganan sinkron/asinkron_; pemahaman yang kuat pada tiga sumbu ini menghilangkan mayoritas “WAT?” serta memungkinkan kode yang _prediktabel_ dan *scaleable\*.

### 2.1.1 Pillar Pillars

#### 2.1.1 Lingkungan & Closures – Arsitektur Tak Terlihat

- **Lingkup Leksikal**: Variabel dipecahkan **statis** berdasarkan posisi _penulisan_, bukan di mana dijalankan.
- **Pembentukan Closure**: Ketika fungsi dibuat, interpreter **mengambil** lingkungan leksikal saat itu (sebuah _closure_) yang tetap hidup selama fungsi itu berumur.

```javascript
function makeGreeter(name) {
  return function () {
    // ← inner fungsi menghasilkan closure
    console.log("Hello " + name) // name diingat
  }
}
const greet = makeGreeter("Alice")
greet() // → "Hello Alice"
```

- **Cycle Closure**: Waspadai _reference cycles_ (mis. closure yang menyimpan referensi pada node DOM). Gunakan `WeakRef` (Node 20+) atau memecah siklus secara manual.

#### 2.2 Binding `this` – Kontak yang Menonjolkan

- **`this` bersifat dinamis**: Nilai **ditentukan pada saat panggilan**, bukan saat definisi.
- **4 Aturan Pembinding** (MDN):
  1. **Default**: Di _strict mode_, `this` adalah `undefined`; jika tidak, ia adalah _object global_.
  2. **Implicit**: `obj.method()` → `this = obj`.
  3. **Explicit**: `.call(val, …)` atau `.apply(val, args)` memaksa `this = val`.
  4. **New**: `new MyClass()` → `this = instance yang baru dibuat`.

```javascript
const obj = {
  count: 0,
  inc() {
    this.count++
    return this.count
  },
}

obj.inc() // → 1   (implicit binding)

const inc = obj.inc
inc() // → TypeError (this menjadi undefined/global di strict mode)
```

- **Solusi**:
  - **Explicit binding** (`inc.call(obj)`).
  - **Arrow functions** (`()=>{}`) yang menurunkan _lexical `this`_.
  - **Destructuring dengan default binding**: `const { inc } = obj; const boundInc = inc.bind(obj);`

#### 2.3 Penanganan Asynchronous – Dari Callbacks ke async/await

| Ära                 | Pola                                   | Karakteristik                                                                   |
| ------------------- | -------------------------------------- | ------------------------------------------------------------------------------- |
| **Callback Hell**   | Nested callbacks                       | Sulit dibaca, error tidak terkontrol.                                           |
| **Promises**        | `new Promise(r => r(resolve, reject))` | Promise‑first‑class, chainable (`then`), error handling (`catch`).              |
| **Async Functions** | `async function foo(){}`               | Syntaktis ringan wrapper promise; **selalu mengembalikan promise**.             |
| **Generators**      | `function* gen(){ yield ... }`         | Bisa pause/resume; dipakai untuk coroutine dan generator‑based async libraries. |

##### Contoh Deep – Konversi Chain Callbacks ke async/await

```javascript
// Style callback (NodeFS)
fs.readFile("data.txt", "utf8", (err, data) => {
  if (err) throw err
  const processed = process(data)
  fs.writeFile("out.txt", processed, (err) => {
    if (err) throw err
    console.log("Done")
  })
})

// Async/Await conversion
async function processFile() {
  try {
    const data = await fs.promises.readFile("data.txt", "utf8")
    const processed = process(data)
    await fs.promises.writeFile("out.txt", processed)
    console.log("Done")
  } catch (e) {
    console.error("Error:", e)
  }
}
processFile()
```

- **Keuntungan**: Alur kode menjadi linear; handling error menggunakan `try/catch`; tidak lagi “pyramid of doom”.

##### Ringkasan Mekanika Loop Event (Node.js)

- **Fasa**: `timers`, `pending callbacks`, `poll`, `check`, `close callbacks`.
- **Microtasks**: `.then` promise callbacks dijalankan setelah setiap _macro‑task_.
- **Scheduling Loop Event**:
  1. Eksekusi **timers** (`setTimeout`, `setInterval`).
  2. Eksekusi **I/O callbacks** (event I/O).
  3. Jalankan **poll** (beberapa I/O, lalu cek pending).
  4. **Check** fase (setImmediate).
  5. **Close** fase (socket close events).

> **Tip**: `process.nextTick` menunda kerja hingga _sebelum_ tick event loop selanjutnya; gunakan dengan hati‑hati agar tidak menghambat loop.

### 2.7 Praktik Checklist – “JS Mastery”

- [ ] **Demo Closure** – Buat counter yang terus bertambah dan tidak pernah reset.
- [ ] **`this` Investigation** – Simpan fungsi ke variabel, panggil dengan `.call()` dan `.apply()`; observasi binding.
- [ ] **Promise Chain** – Konversi callback ber‑nested menjadi _flat_ promise chain; tambahkan `.catch`.
- [ ] **Refactor ke async/await** – Ambil fungsi callback‑based lama dan tulis ulang pakai `async`.
- [ ] **Diagram Event Loop** – Gambar 6 fase; letakkan minimal tiga `setTimeout`, `fs.readFile`, dan `Promise.resolve().then` pada fase yang tepat.
- [ ] **Refactor Legacy Callback** – Ambil fungsi callback lama dari NodeJS dan tulis ulang pakai `async/await` sambil mempertahankan semantiknya.

---

## 3️⃣ The Art of Computer Programming – Donald Knuth (Renum Detail)

### 3.1 Tesis inti (Dineleh Ulangi)

> **Pemrograman adalah _seni matematika_; analisis algoritmik yang tepat, pembuatan kombinatorik, serta pembuktian formal kebenaran menjadi fondasi perangkat lunjut yang andalkan.**

### 3.2 Fondasi – Apa yang Harus Diketahui Setiap Engineer

| Konsep                     | Penjelasan                                                                              | Contoh                                                                                |
| -------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Pensée Algorithmique**   | pecah teks menjadi _langkah‑langkah atomik_ yang dapat dipindai secara induktif.        | Membuat _binary search_ dari array terurut.                                           |
| **Analisis Kompleksitas**  | **Big‑O** notation menyatakan batas atas operasi; mengabaikan konstan & suku bertenang. | `O(1)`, `O(log n)`, `O(n)`, `O(n log n)`, `O(n²)`, `O(2ⁿ)`.                           |
| **Bukti Kebenaran**        | _Loop invariant_, _matematisasi induksi_, _recurrence_; bukti bahwa algoritma bekerja.  | _Invariant loop_ pada binary search (lihat bagian 3.5).                               |
| **Generasi Kombinatorial** | Algoritma pembuatan permutasi, kombinasi, partisi; struktur data reusable.              | Algoritma _Johnson‑Trotter_ untuk urutan permutasi; Algoritma _Heap_ untuk heap sort. |

### 3.3 Algoritma Klasik (Edisi Vol 1‑3)

| Algoritma                    | Referensi (Vol.) | Tujuan                                  | Kompleksitas                           |
| ---------------------------- | ---------------- | --------------------------------------- | -------------------------------------- |
| **Binary Search**            | Vol 3, §3.2.1    | Cari elemen pada array terurut          | `O(log n)`                             |
| **Merge Sort**               | Vol 3, §5.1.1    | Sorting yang stabil, divide‑and‑conquer | `O(n log n)`                           |
| **QuickSelect**              | Vol 3, §5.2.1    | Temukan k‑th smallest elemen            | Rata‑rata `O(n)`                       |
| **Dijkstra’s Shortest Path** | Vol 3, §4.3      | Jalur terpendek pada graf berbobot      | `O((V+E) log V)` dengan Fibonacci heap |
| **Floyd’s Cycle Detection**  | Vol 3, §7.1.2    | Deteksi siklus pada linked list         | `O(n)` waktu, `O(1)` ruang             |

### 3.4 Analisis Matematika – Pembuktian Kecepatan

- **Rekursi**: `T(n) = a·T(n/b) + f(n)` → _Master Theorem_ untuk menemukan rata‑rata `T(n)`.
- **Invariant Loop**: _Loop invariant_ adalah properti yang harus memenuhi sebelum, selama, serta setelah setiap iterasi loop.

### 3.5 Contoh Bukti Kecepatan – Binary Search

```text
Invariant: Pada setiap iterasi, target (jika ada) berada dalam interval [lo, hi].
Bukti:
  1. Awalnya lo=0, hi=n‑1 → invariant tetap.
  2. Setiap iterasi menghitung mid = ⌊(lo+hi)/2⌋.
     • Jika target < A[mid] → hi = mid‑1 → interval baru tetap berisi target jika ada.
     • Jika target > A[mid] → lo = mid+1 → interval baru tetap berisi target jika ada.
     • Jika A[mid] == target → algorithm mengembalikan mid, invariant otomatis terpenuhi.
  3. Loop berakhir ketika lo > hi → invariant tidak lagi dapat dipenuhi → target tidak ada.
```

### 3.5 Generasi Kombinatorial (Knuth Vol. 4A)

- **Permutasi**: Algoritma _L_ (lexicographic generation).
- **Kombinasi**: Algoritma _H_ untuk k‑subsets.
- **Partisi**: Algoritma _Z_ untuk partisi set.

_Contoh_: Generate semua 3‑element subset dari `{1,2,3,4}` menggunakan Algorithm H:

```python
def combination_k(n, k):
    a = list(range(k))
    while True:
        yield a.copy()
        # Cari elemen kanan yang bisa di‑increment
        j = k-1
        while j >= 0 and a[j] == j + n - k:
            j -= 1
        if j < 0: break
        a[j] += 1
        for i in range(j+1, k):
            a[i] = a[i-1] + 1
        yield a.copy()
```

---

## 4️⃣ Integrasi Mindset Arkitektur Klik‑Kita

| Konsep                   | Feathers (Legacy)                            | Simpson (JS)                                       | Knuth                                                    | Aplikasi di Sistem Kita                                                                  |
| ------------------------ | -------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Seam / Hook**          | Characterization test → _replace_            | Closure‑based _module_ pattern → _inject_ behavior | **Strategy** pattern – interchangeable algorithm objects | Memungkinkan penggantian engine penyimpanan (B‑Tree ↔ LSM) tanpa memecah kode pemanggil. |
| **First‑Test**           | Characterization test → safety net           | Use **Jest** atau **Mocha** untuk uji async        | Unit‑test tiap algoritma sebelum commit                  | Menjamin bahwa setiap engine replikasi atau partisi baru berfungsi dengan benar.         |
| **Complexity Awareness** | Detect hot spots → refactor                  | Avoid _callback hell_ → gunakan promise            | Analisis time/space pada fungsi partisi                  | Pilih partisi berbasis hash vs. range bila skala menjadi miliaran kunci.                 |
| **Formal Reasoning**     | Write ADR documenting _why_ a seam was added | Write JSDoc + TSDoc for async functions            | Write **formal recurrence** for recursive DB queries     | Memungkinkan rekan masa depan _verify_ trade‑offs (linearizability vs. latency).         |

### 4.1 Contoh ADR – “Adopsi Seam‑Based Refactor untuk Penukaran Engine Penyimpanan”

```markdown
# ADR 004 – Seam‑Based Refactor untuk Penukaran Engine Penyimpanan

**Status:** Accepted  
**Date:** 2026‑07‑05  
**Decision‑Makers:** Backend Team

## Context

Sistem kami saat ini menggunakan **engine penyimpanan berbasis B‑Tree** untuk metadata pengguna. Forecast workload meningkat 10×, memerlukan penukaran ke **engine LSM‑Tree** untuk peningkatan write‑throughput.

## Consequences

- **Pros:** Lebih tinggi throughput tertulis, latency tertahan pada beban burst.
- **Cons:** Latensi baca mungkin meningkat pada look‑up titik; kompactions dapat menyebabkan I/O spike sementara.

## Alternatives Considered

1. **Scale B‑Tree vertically** (more IOPS). Rejected – hardware cost prohibitive.
2. **Hybrid Approach** (B‑Tree for reads, LSM for writes). Complexity high, operational risk.

## Rationale

- **Seam‑Based Refactor** memungkinkan injeksi antarmuka `StorageEngine` dengan dua implementasi (`BTreeEngine`, `LSMEngine`).
- Existing services call `store(key, value)` dan `load(key)`. Tidak ada perubahan kode selain penyedia implementasi konkret.
- Pendekatan ini mengikuti pola **seam** Feathers dan selaras dengan penekaran Knuth terhadap **transformasi progresif yang teruji**.

## Implementation Plan

1. Define `StorageEngine` abstract base class (JS/TS interface).
2. Implement `BTreeEngine` (current) dan `LSMEngine` (new).
3. Tulis **characterization tests** untuk `BTreeEngine` (covers semua pemanggilan API lama).
4. Swap implementasi lewat **dependency injection** pada startup service.
5. Run **full test suite**; monitor replication lag dan logs kompactions.

## Consequences for Knowledge Portfolio

- **Learning**: Mendalami strategi kompactions LSM (lihat Knuth Vol. 3, §5.5).
- **Teaching**: Dokumentasi pola seam ber‑gaya Pragmatic Programmer (DRY, responsibility).

---

## 5️⃣ Rujakan Praktis (5‑Hari Sprint)

| Hari       | Tujuan                                                                                       | Output Konkret                                             |
| ---------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Senin**  | **Audit Legacy‑Code** – temukan modul tanpa tes.                                             | Tambahkan **characterization test** (`legacy_test.js`).    |
| **Selasa** | **Refactor JS Asynchronous** – konversi callback‑based ke `async/await`.                     | Kirim PR dengan refactor async dan unit tes.               |
| **Rabu**   | **Mini‑Project Algoritmik** – implementasikan _binary search_ Knuth beserta bukti kecepatan. | Tambahkan `binary_search.py` beserta bukti kecepatan.      |
| **Kamis**  | **ADR Lintas** – buat ADR yang menghubungkan seam, async, dan algoritma analisis.            | Tambahkan `001‑seam‑async‑search.adoc` ke `docs/adr/`.     |
| **Jumat**  | **Pantau Pengethuan** – catat pencapaian mingguan di `[[knowledge‑log]]`.                    | Tanda‑kan tugas selesai, atur target membaca minggu depan. |

---

## 6️⃣ Ringkasan Ringkas (≤ 150 kata)

> Kekuatan _edisi expanded_ ini tidak hanya pada ukurannya, melainkan pada **disiplin aksi** yang dipaksakan: **uji‑first**, **seam‑aware**, **clean‑async**, **algorithm‑sound**. Saat Anda memperlakukan setiap perubahan kode sebagai _mini‑proyek_ yang diatur oleh prinsip‑prinsip ini, Anda mengubah kerumunan _warisan_ menjadi **sistem yang terenkode, dapat dikelola, serta tahan lama**. Memahami perdagangan antara **B‑Tree vs LSM**, **sinkron vs asinkron**, serta **analisis kompleksitas** memberi Anda kualitas untuk membangun sistem yang _scaleable_, _maintainable_, serta _future‑proof_.

---

_File lengkap kini berada di:_
```

/mnt/data_d/Documents/Wide Note/Note/01_Library/Software_Engineering/Bonus-Books-Complete-Expanded.md

```

Anda bisa membukanya dengan `read_file` atau langsung membuka di editor kotaak.
Butuh sesuatu lagi?
```
