---
title: MOC — Software Engineering & CS Learning Path
tags:
- library
created: '2026-07-05'
updated: '2026-07-05'
status: pending
cssclasses:
  - wide-table
  - callout

---
# MOC — Software Engineering & Computer Science
## 📂 Vault Structure

Struktur vault yang disajikan di atas membagi konten menjadi beberapa kategori utama, yaitu:
- `01_Library/`: Berisi koleksi buku yang terorganisir ke dalam beberapa sub-kategori seperti `Software_Engineering`, `Systems_Architecture`, `Algorithms_Math`, `Productivity_Career`, dan lain-lain.
- `Software_Engineering/`: Fokus pada prinsip-prinsip pengembangan perangkat lunak, seperti coding, desain, dan refactoring. Beberapa buku yang terdaftar di sini adalah [[clean-code-robert-martin]], [[design-patterns-gof]], dan [[the-pragmatic-programmer]].
- `Systems_Architecture/`: Mencakup topik-topik terkait arsitektur sistem, termasuk sistem terdistribusi, sistem operasi, dan reliability. Buku-buku seperti [[ddia-kleppmann]], [[site-reability-engineering]], [[csapp-bryant-ohallaron]], [[ostep-three-easy-pieces]], dan [[systems-design-interview-alex-xu]] menjadi referensi utama.
- `Algorithms_Math/`: Berfokus pada fondasi teoretis algoritma dan matematika, dengan buku seperti [[sicp-abelson-sussman]] dan [[clrs-introduction-to-algorithms]].
- `Productivity_Career/`: Membahas tentang mindset, fokus, dan strategi karier, termasuk buku [[deep-work-and-so-good-newport]].
- Kategori-kategori lain seperti [[Software_Engineering/bonus-books-refactoring-legacy-ydkjs-knuth]], `Swarm_AI/`, `Kualitas_Perangkat_Lunak/`, dan `Internet_Offline/` juga disediakan untuk memperluas cakupan topik.

## 🔗 Cross-Reference

Bagian ini menyajikan beberapa tabel yang memfasilitasi cross-referencing antara berbagai topik dan buku yang relevan.

### Software Engineering → Systems

Tabel berikut menunjukkan keterkaitan antara keterampilan di bidang Software Engineering dan kebutuhan akan pengetahuan Sistem Operasi:

| SE Skill | Butuh OS Knowledge |
|----------|-------------------|
| Concurrency bugs | OSTEP threading + CS:APP cache coherence |
| Performance tuning | CS:APP memory hierarchy + OSTEP scheduling |
| System design interview | DDIA + OSTEP + Alex Xu framework |

Dari tabel di atas, terlihat bahwa untuk menangani concurrency bugs, seseorang perlu memahami threading dari OSTEP dan cache coherence dari CS:APP. Sementara itu, untuk performance tuning, pengetahuan tentang memory hierarchy dari CS:APP dan scheduling dari OSTEP sangat penting.

### Contoh Kode: Memahami Concurrency dengan Python
```python
import threading

def print_numbers():
    for i in range(10):
        print(i)

def print_letters():
    for letter in 'abcdefghij':
        print(letter)

# Membuat thread
thread1 = threading.Thread(target=print_numbers)
thread2 = threading.Thread(target=print_letters)

# Menjalankan thread
thread1.start()
thread2.start()

# Menunggu thread selesai
thread1.join()
thread2.join()
```
Kode di atas menunjukkan contoh sederhana tentang concurrency menggunakan Python. Dua thread dibuat untuk mencetak angka dan huruf secara bersamaan, menunjukkan bagaimana mereka dapat berjalan paralel.

### Theory → Practice

Tabel berikut menghubungkan antara buku-buku teori dengan buku-buku praktis:

| Theory Book | Practice Book |
|-------------|---------------|
| CLRS (algoritma) | CS:APP (hardware exec), DDIA (distributed) |
| SICP (abstraksi) | Clean Code (naming/functions), Design Patterns (reusable) |
| OSTEP (OS) | SRE (production ops), CS:APP (debug perf) |

Misalnya, untuk menerapkan algoritma dari CLRS, seseorang dapat merujuk pada CS:APP untuk eksekusi hardware dan DDIA untuk konsep distribusi.

### Contoh Kode: Implementasi Algoritma Sorting
```python
def merge_sort(arr):
    if len(arr) <= 1:
        return arr

    mid = len(arr) // 2
    left_half = arr[:mid]
    right_half = arr[mid:]

    return merge(merge_sort(left_half), merge_sort(right_half))

def merge(left, right):
    merged = []
    left_index = 0
    right_index = 0

    while left_index < len(left) and right_index < len(right):
        if left[left_index] <= right[right_index]:
            merged.append(left[left_index])
            left_index += 1
        else:
            merged.append(right[right_index])
            right_index += 1

    merged.extend(left[left_index:])
    merged.extend(right[right_index:])

    return merged

# Menggunakan algoritma sorting
arr = [64, 34, 25, 12, 22, 11, 90]
sorted_arr = merge_sort(arr)
print(sorted_arr)
```
Kode di atas menunjukkan implementasi algoritma sorting (merge sort) yang dibahas di CLRS, dan bagaimana itu dapat diterapkan dalam praktik.

### Tabel Perbandingan Sistem Operasi
| Sistem Operasi | Kelebihan | Kekurangan |
| --- | --- | --- |
| Windows | Mudah digunakan, banyak aplikasi | Kurang aman, biaya lisensi |
| Linux | Aman, open-source, dapat disesuaikan | Kurang user-friendly, kurang aplikasi |
| macOS | Stabil, aman, integrasi baik dengan perangkat Apple | Biaya lisensi, kurang aplikasi |

Tabel di atas membandingkan beberapa sistem operasi populer, menunjukkan kelebihan dan kekurangan masing-masing.

## 📋 Suggested Learning Order

Berikut adalah urutan belajar yang disarankan, dibagi menjadi tiga jalur:

### Track 1: Immediate ROI (3 bulan)
```
Clean Code → Pragmatic Programmer → Refactoring (Fowler)
→ Design Patterns (katalog) → Alex Xu (system design)
```
Jalur ini dirancang untuk menghasilkan ROI (Return on Investment) yang cepat dengan memfokuskan pada keterampilan pengembangan perangkat lunak yang penting seperti Clean Code, Pragmatic Programmer, Refactoring, Design Patterns, dan System Design.

### Track 2: Deep Foundation (6-12 bulan)
```
CLRS (Ch 1-6, 15, 22-24) → CS:APP (Ch 3, 5, 6, 9, 12)
→ OSTEP (scheduling, memory, concurrency, file systems)
→ DDIA (replication, partitioning, transactions, stream processing)
```
Jalur ini berfokus pada membangun fondasi yang kuat dengan mempelajari algoritma dari CLRS, sistem komputer dari CS:APP, sistem operasi dari OSTEP, dan sistem terdistribusi dari DDIA.

### Track 3: Mind Expansion (berkelanjutan)
```
SICP → TAoCP (bila perlu) → YDKJS (bila working with JS)
```
Jalur ini ditujukan untuk memperluas wawasan dan pengetahuan dengan mempelajari konsep-konsep dasar pemrograman dari SICP, algoritma lanjutan dari TAoCP, dan JavaScript dari YDKJS.

## ✅ Master Checklist

Berikut adalah daftar checklist yang membagi bahan-bahan pembelajaran menjadi tiga kategori: Must-Read, Should-Read, dan Good-to-Read.

### Must-Read (bisa lompat per bab)
- [ ] **Clean Code** — naming, functions, tests (Ch 2, 3, 10)
- [ ] **DDIA** — replication, partitioning, transactions (Ch 5-8)
- [ ] **CLRS** — Big O, sorting, DP, graphs (Ch 3, 7, 15, 22-24)
- [ ] **OSTEP** — CPU vrit, memory virt, concurrency (Ch 4-8, 13-16, 26-31)

### Troubleshooting: Menangani Masalah Concurrency
1. **Identifikasi Sumber Masalah**: Pastikan untuk mengidentifikasi dengan benar sumber masalah concurrency, apakah itu karena thread yang tidak sinkron atau kesalahan dalam mengakses variabel bersama.
2. **Gunakan Alat Bantu**: Utilitas seperti debugger atau profiler dapat membantu dalam menganalisis dan memahami perilaku program.
3. **Implementasi Solusi**: Terapkan solusi yang sesuai, seperti menggunakan lock atau semaphore untuk sinkronisasi thread, atau memperbaiki kode untuk menghindari akses bersamaan ke resource yang sama.

### Should-Read
- [ ] **Pragmatic Programmer** — mindset, DRY, orthogonality
- [ ] **Design Patterns** — Strategy, Observer, Factory, Singleton
- [ ] **CS:APP** — assembly, cache, virtual memory
- [ ] **SRE** — error budget, SLI/SLO, incident response

### Good-to-Read
- [ ] **SICP** — metacircular evaluator (Ch 4)
- [ ] **Alex Xu** — interview framework
- [ ] **Deep Work + So Good** — career strategy

### Reference / Catalog
- [ ] **Refactoring** — lookup code smell → fix
- [ ] **Legacy Code** — survival guide for old projects
- [ ] **YDKJS** — JS specific scope/closures
- [ ] **TAoCP** — deepest algorithms reference
- [ ] **Soft Skills** — career management

Dengan memahami struktur vault, cross-referencing, dan urutan belajar yang disarankan, serta memanfaatkan daftar checklist dan contoh kode yang disediakan, diharapkan pembaca dapat memperoleh pengetahuan yang komprehensif dan terstruktur di bidang Software Engineering dan Computer Science.

## 📊 Contoh Kasus: Mengembangkan Sistem Terdistribusi

Berikut adalah contoh kasus mengembangkan sistem terdistribusi menggunakan konsep-konsep yang dipelajari:
1. **Definisikan Kebutuhan**: Identifikasi kebutuhan sistem, seperti skalabilitas, ketersediaan, dan keamanan.
2. **Desain Arsitektur**: Desain arsitektur sistem terdistribusi, termasuk komponen-komponen yang terkait dan komunikasi antar komponen.
3. **Implementasi**: Implementasikan sistem terdistribusi menggunakan bahasa pemrograman yang sesuai, seperti Java atau Python.
4. **Testing**: Lakukan testing sistem terdistribusi untuk memastikan bahwa sistem berjalan dengan benar dan stabil.

### Contoh Kode: Implementasi Sistem Terdistribusi dengan Python
```python
import threading
import socket

class Node:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def connect(self):
        self.socket.connect((self.host, self.port))

    def send(self, message):
        self.socket.sendall(message.encode())

    def receive(self):
        return self.socket.recv(1024).decode()

# Membuat node
node1 = Node('localhost', 8080)
node2 = Node('localhost', 8081)

# Menghubungkan node
node1.connect()
node2.connect()

# Mengirimkan pesan
node1.send('Hello, node2!')
print(node2.receive())

# Menutup koneksi
node1.socket.close()
node2.socket.close()
```
Kode di atas menunjukkan contoh sederhana implementasi sistem terdistribusi menggunakan Python dan socket.

Dengan demikian, diharapkan pembaca dapat memperoleh pengetahuan yang komprehensif dan terstruktur di bidang Software Engineering dan Computer Science, serta dapat mengembangkan sistem terdistribusi yang stabil dan efisien.
