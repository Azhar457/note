---
title: "Math and Algorithms"
tags:
  - fundamentals
  - library
aliases:
  - "math-and-algorithms"
created: "2026-04-25"
updated: "2026-07-01"
status: active
---

# 🧮 MATEMATIKA & ALGORITMA — Fondasi Semua Computer Science

> Tiga pilar matematika yang menopang seluruh ilmu komputer: Algoritma & Struktur Data (cara berpikir efisien), Matematika Diskrit (bahasa logika dan kriptografi), Linear Algebra (bahasa machine learning dan grafik). Tidak ada jalan pintas — ini adalah fondasi yang memungkinkan Anda melihat menembus abstraksi.

> [!info] Mengapa Matematika?
> Matematika bukan sekadar alat bantu. Ia adalah **bahasa yang digunakan alam semesta untuk mengeksekusi hukum-hukumnya**. Dalam konteks CS, matematika adalah alat diagnostik: saat model ML overfit, saat algoritma enkripsi jebol, atau saat database query lambat — matematika adalah kunci untuk memahami _mengapa_.

---

## 📜 Fondasi Historis: Dari Turing ke Shannon

Matematika bukan pelengkap ilmu komputer. Ia adalah **rahim yang melahirkannya**. Sebelum komputer elektronik pertama dinyalakan, fondasinya sudah diletakkan oleh ahli matematika murni.

- **1936 — Alan Turing & Entscheidungsproblem:** Mesin Turing adalah abstraksi matematis sebelum menjadi mesin fisik. Pita tak terbatas, head baca-tulis, dan tabel transisi adalah definisi formal pertama dari "komputasi". Semua bahasa pemrograman modern adalah _syntactic sugar_ di atasnya.
- **1930-an — Alonzo Church & Lambda Calculus:** Notasi matematis untuk mendefinisikan fungsi dan komputasi. Inilah kakek moyang dari semua bahasa fungsional (Haskell, Lisp) dan konsep closure/anonymous function di Python/JavaScript.
- **1948 — Claude Shannon & Information Theory:** Shannon menikahkan probabilitas dengan komunikasi. Bit, entropi, dan kapasitas kanal adalah fondasi matematis dari kompresi data, kriptografi, dan transmisi data. Setiap kali Anda mengirim pesan terenkripsi, Anda menggunakan matematika Shannon.

**Refleksi:** Ketika Anda menulis `def factorial(n): return 1 if n == 0 else n * factorial(n-1)`, Anda sedang menggunakan rekursi, konsep yang pertama kali diformalkan dalam lambda calculus. Setiap kali Anda mendengar "bandwidth" atau "bit rate", Anda menggunakan teori Shannon. Matematika bukan sejarah usang — ia adalah **DNA dari setiap bit yang mengalir di CPU Anda**.

---

## 🧩 Bagian I: Algoritma & Struktur Data (A&DS)

Bagian ini bukan sekadar katalog solusi, tetapi **kerangka berpikir untuk memecahkan masalah secara efisien.** Setiap struktur data dan algoritma adalah jawaban atas pertanyaan: "Dengan sumber daya terbatas (waktu dan memori), bagaimana saya menyelesaikan masalah ini sebaik mungkin?"

### Level 0: Kompleksitas & Big-O (Bahasa Efisiensi)

Big-O adalah termometer untuk mengukur "demam" algoritma. Ia mengabaikan konstanta dan hanya peduli pada laju pertumbuhan saat input membesar.

| Notasi         | Nama         | Intuisi                                               | Contoh Nyata                                                          |
| -------------- | ------------ | ----------------------------------------------------- | --------------------------------------------------------------------- |
| **O(1)**       | Konstan      | Sekejap, tak peduli seberapa besar data.              | Akses array `arr[5]`, cek apakah hash table kosong.                   |
| **O(log n)**   | Logaritmik   | Membagi masalah menjadi dua setiap langkah.           | Binary search di 1 miliar data hanya butuh 30 langkah.                |
| **O(n)**       | Linear       | Waktu tumbuh sebanding dengan input.                  | Mencari elemen di array tak terurut.                                  |
| **O(n log n)** | Linearitmik  | `n` kerja dikali `log n` pembagian.                   | Algoritma sorting terbaik (mergesort, heapsort, quicksort rata-rata). |
| **O(n²)**      | Kuadratik    | Setiap elemen berinteraksi dengan setiap elemen lain. | Bubble sort, nested loop sederhana.                                   |
| **O(2ⁿ)**      | Eksponensial | Malapetaka. Setiap tambahan input menggandakan waktu. | Brute-force password 8 karakter (26⁸).                                |

**Analisis Praktis:**

```python
# O(n) - Linear
def find_max(arr):
    max_val = arr[0]
    for x in arr[1:]:
        if x > max_val: max_val = x
    return max_val

# O(n²) - Kuadratik (Nested Loop)
def has_duplicates(arr):
    for i in range(len(arr)):
        for j in range(i+1, len(arr)):
            if arr[i] == arr[j]:
                return True
    return False
```

**Koneksi ke Vault:** Kompleksitas waktu adalah jantung dari analisis performa exploit ([[hierarchy-offensive|Offensive Security]]). Serangan brute-force dengan O(2ⁿ) pada password 256-bit adalah batasan alam semesta — secara fisik tidak mungkin, bukan karena teknologi, tetapi karena matematika.

---

### Level 1: Array & Linked List — Fondasi Memori

Dua filosofi penyimpanan yang bertolak belakang, mencerminkan trade-off paling fundamental dalam CS: **akses acak vs. fleksibilitas ukuran.**

| Fitur                       | Array (Static/Dynamic)                            | Linked List (Singly/Doubly)                                          |
| --------------------------- | ------------------------------------------------- | -------------------------------------------------------------------- |
| **Memori**                  | Satu blok kontigu. RAM-friendly (cache locality). | Node tersebar di mana-mana. Setiap node punya pointer ke berikutnya. |
| **Akses (Read)**            | **O(1)** — langsung lompat ke indeks.             | **O(n)** — harus telusuri dari kepala.                               |
| **Insert/Delete di tengah** | **O(n)** — harus geser semua elemen setelahnya.   | **O(1)** — jika sudah ada pointer ke node target.                    |
| **Pencarian**               | **O(n)** (unsorted) / **O(log n)** (sorted).      | **O(n)** — tidak peduli sorted.                                      |

**Mengapa Array Lebih Cepat dalam Praktik?** Linked list secara teori unggul di insert/delete. Namun di dunia nyata, CPU memiliki **cache** (L1, L2, L3). Array memanfaatkan _cache locality_ (data ditarik dalam blok), sementara linked list menyebabkan _pointer chasing_ (melompat-lompat ke alamat acak) yang mahal. Di sinilah [[computer-science-foundations|Computer Architecture]] bertemu dengan algoritma — akses memori yang _terlihat_ O(1) bisa berbeda 100x lipat dalam kecepatan nyata.

**Implementasi Dynamic Array (List di Python):**

```python
# Python list adalah dynamic array.
# "Amortized O(1) append" dicapai dengan strategi penggandaan kapasitas.
import sys
arr = []
print(f"Size: {sys.getsizeof(arr)} bytes") # 56 (overhead)
arr.append(1)
print(f"Size: {sys.getsizeof(arr)} bytes") # 88 (alokasi awal)
for _ in range(10):
    arr.append(_)
    print(f"Len: {len(arr)}, Capacity est: {sys.getsizeof(arr)}")
# Kapasitas melompat: 88 -> 120 -> 184 -> 248... (strategi overallokasi)
```

---

### Level 2: Pohon & Graf — Navigasi Hubungan

#### Pohon (Tree): Hierarki yang Terstruktur

- **BST (Binary Search Tree):** Kiri < Akar < Kanan. Idealnya O(log n), tetapi bisa degenerasi jadi linked list (O(n)) jika data terurut.
- **Self-Balancing Trees (AVL, Red-Black):** Menjaga keseimbangan dengan rotasi otomatis. Biaya insert/delete sedikit lebih mahal, tetapi **menjamin** O(log n) untuk semua operasi.
- **B-Tree:** Pohon "gemuk" dengan banyak anak per node. Dirancang untuk **meminimalkan disk I/O**. Setiap node berukuran satu halaman disk (4KB-16KB). Fondasi dari semua database relasional ([[data-recovery|Database Internals]]).
- **Trie (Prefix Tree):** Pohon di mana setiap tepi adalah karakter. Pencarian kata "kunci" adalah O(m) di mana m adalah panjang kata. Fondasi dari autocomplete, spell checker, dan tabel routing IP ([[network-security|Network Security]]).

#### Graf (Graph): Jaringan yang Saling Terhubung

- **DFS (Depth-First Search):** "Jelajah sedalam mungkin, baru mundur." Menggunakan stack (rekursi). Cocok untuk deteksi siklus, topological sort.
- **BFS (Breadth-First Search):** "Jelajah lapis per lapis." Menggunakan queue. Menemukan jalur terpendek untuk graf tak berbobot.
- **Dijkstra's Algorithm:** BFS untuk graf berbobot dengan bobot positif. Menggunakan priority queue. Fondasi dari GPS navigation ([[hierarchy-osint-rf|OSINT & SIGINT]] untuk analisis jaringan).

**Contoh:**

```python
# Representasi Graf: Adjacency List
graph = {
    'A': ['B', 'C'],
    'B': ['D', 'E'],
    'C': ['F'],
    'D': [], 'E': ['F'], 'F': []
}
def dfs(node, visited=set()):
    if node not in visited:
        visited.add(node)
        for neighbor in graph[node]:
            dfs(neighbor, visited)
    return visited
```

---

### Level 3: Hash Table — Sihir O(1) dan Jeratnya

Hash table adalah bunglon: dalam rata-rata kasus, insert/search/delete O(1) — kilat. Dalam kasus terburuk, O(n) — menjadi linked list mahal.

**Mekanisme:** `index = hash(key) % capacity`. Dua kunci berbeda bisa menghasilkan indeks sama (kolisi).

- **Chaining:** Setiap bucket adalah linked list.
- **Open Addressing:** Mencari slot kosong berikutnya (linear probing, quadratic probing, double hashing).

**Hash DoS (Denial of Service):** Attacker dapat menemukan banyak kunci yang menghasilkan kolisi, memaksa hash table ke worst-case O(n). Mitigasi: **randomized hash seed** (Python, Ruby). Ini adalah contoh di mana [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] bertemu dengan algoritma dasar — injection bisa terjadi di level struktur data.

**Consistent Hashing:** Fondasi dari distributed database dan CDN. Meminimalkan remapping kunci saat server ditambah/dikurangi. Konsep ini adalah jembatan antara struktur data dan arsitektur sistem terdistribusi ([[ddia-summary|Designing Data-Intensive Applications]]).

---

### Level 4: Sorting & Searching — Optimasi Tanpa Henti

**Sorting:**

- **Quicksort:** Raja di dunia nyata. Memilih pivot, mempartisi. Cache-friendly. O(n²) worst case tapi bisa dihindari dengan randomized pivot.
- **Mergesort:** Stabil, O(n log n) terjamin. "Divide and conquer" klasik. Ideal untuk linked list (tidak butuh random access) dan external sorting (data > RAM).
- **Radix Sort:** Untuk integer, lebih cepat dari comparison-based sort (O(nk)). Fondasi sorting di GPU.

**Binary Search (Pencarian Biner):** Fondasi dari segala pencarian cepat. Di setiap langkah, tebak di tengah. Hanya butuh 32 langkah untuk mencari di 4 miliar data.

**Koneksi ke Vault:** Sorting adalah inti dari eksekusi query database ([[data-recovery|Database Internals]]). Binary search adalah fondasi dari Memory Forensics — mencari artefak di dump memori yang besar.

---

### Level 5: Dynamic Programming (DP) & Greedy

**Dynamic Programming (DP):**

- **Overlapping Subproblems:** Masalah besar bisa dipecah menjadi submasalah yang sama berulang kali.
- **Optimal Substructure:** Solusi optimal bisa dibangun dari solusi optimal submasalah.
- **Memoization (Top-Down):** Simpan hasil fungsi rekursif dalam cache (dictionary).
- **Tabulation (Bottom-Up):** Bangun solusi secara iteratif dari kasus terkecil ke terbesar.
  Contoh: Fibonacci dengan DP O(n) vs O(2ⁿ) naif.

**Greedy:**

- Ambil keputusan terbaik lokal saat ini, berharap berujung global optimal. Contoh: Dijkstra.
- Tidak selalu optimal. Contoh: Coin change problem dengan pecahan 1, 3, 4. Greedy (4 dulu) gagal untuk 6 (butuh 2 koin 3, bukan 4+1+1).
- DP memberikan optimal guarantee, Greedy memberikan kecepatan.

**Koneksi ke Vault:** DP adalah fondasi dari alignment sequence di bioinformatika dan dynamic programming untuk routing di jaringan ([[hierarchy-osint-rf|OSINT & SIGINT]]). Algoritma DP di balik banyak tool forensik untuk rekonstruksi file.

---

### Level 6: Advanced Structures — Probabilistik & Spesialis

- **Bloom Filter:** Struktur data probabilistik untuk uji keanggotaan. Menjawab: "Apakah elemen ini _mungkin_ ada?" atau "Pasti tidak ada." Tidak ada false negative, tapi ada false positive (sekian persen). Menggunakan bit array + beberapa hash function. Dipakai di Cassandra, Redis, browser (Safe Browsing). Koneksi langsung ke [[ai-engineering-stack-roadmap|AI Engineering Stack]] — dipakai untuk deduplikasi data training.
- **HyperLogLog:** Menghitung jumlah elemen unik dalam stream data dengan memori yang sangat kecil (O(log log n)). Dipakai di Redis (PFCOUNT), Spark, untuk analytics.
- **Union-Find (Disjoint Set Union):** Mengelola himpunan yang saling lepas. Operasi `find` dan `union` dengan _path compression_ dan _union by rank_ hampir O(1). Fondasi dari Kruskal's algorithm untuk Minimum Spanning Tree.

---

### Level 7: Paradigma Desain Algoritma

- **Divide & Conquer:** Pecah jadi subproblem independen, selesaikan, gabungkan. (Mergesort, FFT, Strassen). Inti dari komputasi paralel.
- **Randomization:** Las Vegas (selalu benar, waktu acak — Quicksort randomized) vs. Monte Carlo (waktu tetap, benar dengan probabilitas — primality testing Miller-Rabin).
- **Amortized Analysis:** Rata-rata waktu operasi dalam satu sekuens. Append dynamic array: sesekali O(n) untuk resize, tapi rata-rata O(1). Dasar dari "capacity planning" di SRE ([[site-reability-engineering|SRE]]).

---

## 🔢 Bagian II: Matematika Diskrit

| 📐 Topik                       | ⚡ Isi & Sweet Spot                                                                                                                                                                                                                                       | 🔗 Koneksi Langsung                                                                                   |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Teori Bilangan**             | GCD (Euclid), Aritmatika Modular, Fermat's Little Theorem: `a^(p-1) ≡ 1 (mod p)`. Chinese Remainder Theorem (CRT). Akar primitif. **Fondasi Kriptografi:** RSA, DH, ECC semuanya dibangun dari sini. Tanpa teori bilangan, crypto adalah sulap.           | [[cryptography-biometrics]], [[llm-security-red-teaming-attack-surface-ai-layer]] (enkripsi dalam ML) |
| **Logika & Bukti**             | Logika Proposisional (AND, OR, NOT, Implikasi), Logika Predikat (∀, ∃). Tabel kebenaran. Teknik pembuktian: langsung, kontrapositif, kontradiksi, induksi matematika. **Fondasi Formal Verification:** Memastikan perangkat lunak benar secara matematis. | [[software-engineering]], debugging kritis                                                            |
| **Teori Graf**                 | Graf Euler vs. Hamiltonian. Mewarnai graf (coloring) — dipakai di register allocation compiler. Network flow (Max-Flow Min-Cut) — dipakai di segmentasi gambar.                                                                                           | [[network-security]], [[hierarchy-osint-rf]]                                                          |
| **Kombinatorik**               | Permutasi, Kombinasi, Stars and Bars, Inclusion-Exclusion. **Menghitung kemungkinan:** Ukuran keyspace kriptografi (2^256), kompleksitas brute-force.                                                                                                     | [[cryptography-biometrics]], [[hierarchy-offensive]]                                                  |
| **Rekursi & Relasi Rekurensi** | `T(n) = aT(n/b) + f(n)` → Master Theorem. Analisis performa divide & conquer.                                                                                                                                                                             | Setiap analisis algoritma rekursif, seperti quicksort.                                                |
| **Automata & Formal Language** | DFA, NFA, Regular Expression, CFG (Context-Free Grammar), Turing Machine. **Fondasi Compiler & Interpreter:** Lexer & Parser dibangun dari sini. Setiap regex yang Anda tulis adalah automata.                                                            | [[hierarchy-programming-language]], [[ebpf-kernel-security]]                                          |

**Contoh Kriptografi RSA (Miniatur Python):**

```python
# Konsep Matematika Diskrit di Balik RSA
import math

# 1. Pilih dua prima (rahasia)
p, q = 61, 53
n = p * q # 3233
phi = (p-1) * (q-1) # 3120

# 2. Kunci publik e (biasanya 65537, coprime dengan phi)
e = 17 # 17 coprime dengan 3120
d = pow(e, -1, phi) # 2753 (modular inverse, kunci privat)

# 3. Enkripsi & Dekripsi
pesan = 65 # Misal 'A'
ciphertext = pow(pesan, e, n) # Enkripsi: 65^17 mod 3233 = 2790
plaintext = pow(ciphertext, d, n) # Dekripsi: 2790^2753 mod 3233 = 65
print(f"Pesan: {pesan}, Terenkripsi: {ciphertext}, Terdekripsi: {plaintext}")
# Keamanan: memfaktorkan n (3233) ke p dan q mudah, tapi untuk 2048-bit tidak.
```

---

## 📊 Bagian III: Linear Algebra (Untuk ML, Grafik, & Data)

Linear Algebra adalah matematika dari **ruang dan transformasi**. Untuk seorang computer scientist, ini adalah toolkit untuk:

- **Memanipulasi data multidimensi.**
- **Memahami dan membangun model Machine Learning.**
- **Mengerjakan grafik komputer, simulasi fisika, dan optimasi.**

| 📊 Topik                               | ⚡ Isi & Sweet Spot                                                                                                                                                           | 🔗 Koneksi Langsung                                                                                                                          |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Vektor**                             | `v = [x, y]`. Dot product `v·w` mengukur seberapa "searah". Cosine similarity: `cos(θ) = (v·w) / (                                                                            |                                                                                                                                              | v   |     |     |     | w   |     | )`. | NLP Search Engine, [[llm-security-red-teaming-attack-surface-ai-layer]] (embedding attack) |
| **Matriks**                            | Array 2D. `A·B` adalah transformasi. **PENTING:** `A·B ≠ B·A` (tidak komutatif). Transpos `Aᵀ`, invers `A⁻¹`.                                                                 | Setiap layer di Neural Network adalah perkalian matriks `Y = f(W·X + b)`.                                                                    |
| **Ruang Vektor**                       | Span, basis, dimensi, rank. **Intuisi:** Basis adalah "seperangkat arah independen" yang bisa menjangkau seluruh ruang. Rank adalah "jumlah arah informatif" dalam data Anda. | Kompresi gambar (SVD), reduksi dimensi (PCA).                                                                                                |
| **Eigenvalues & Eigenvectors**         | `A·v = λ·v`. Matriks A, ketika dikali vektor eigen v, hanya meregangkannya sebesar λ (nilai eigen).                                                                           | Google PageRank (vektor eigen utama dari graf web). Quantum Computing (nilai eigen Hamiltonian).                                             |
| **SVD (Singular Value Decomposition)** | `A = U·Σ·Vᵀ`. **Teorema fundamental Linear Algebra.** Setiap matriks bisa didekomposisi menjadi rotasi (U, Vᵀ) dan scaling (Σ).                                               | **Recommender System** (Netflix Prize). **PCA** (Principal Component Analysis). **Pseudoinverse** untuk menyelesaikan overdetermined system. |
| **Gradient Descent**                   | Algoritma optimasi iteratif. `x_new = x_old - η·∇f(x_old)`. Mengikuti arah turunan paling curam untuk mencari minimum.                                                        | **Inti dari training semua Neural Network.** [[test-time-compute-system2]] — reasoning di inference time juga terkadang menggunakan ini.     |

**Contoh SVD dengan Python (NumPy) & Aplikasi Kompresi Gambar:**

```python
import numpy as np
import matplotlib.pyplot as plt

# Anggap 'img_gray' adalah matriks 2D (grayscale)
# img_gray = plt.imread('image.jpg')[:,:,0] # contoh
# Kita akan gunakan data dummy
np.random.seed(0)
img_gray = np.random.rand(200, 200)

# SVD
U, S, VT = np.linalg.svd(img_gray, full_matrices=False)

# Rekonstruksi dengan hanya k singular values teratas (kompresi)
k = 20
compressed = U[:, :k] @ np.diag(S[:k]) @ VT[:k, :]

# Hitung rasio kompresi (dalam hal penyimpanan)
original_size = img_gray.shape[0] * img_gray.shape[1]
compressed_size = k * (img_gray.shape[0] + img_gray.shape[1] + 1)
print(f"Kompresi dari {original_size} menjadi {compressed_size} angka.")
# Visualisasi kualitas hanya dengan 20 nilai singular dari 200.
```

---

## 🧠 Peta Koneksi & Urutan Belajar

Matematika ini bukan pulau-pulau terpencil. Semua konsep saling terhubung dan menjadi fondasi bagi pilar lain di vault Anda.

| Jika Anda ingin menguasai...          | Anda WAJIB menguasai...                                   | Karena...                                                                                |
| ------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Kriptografi & Keamanan**            | Teori Bilangan, Probabilitas, Aljabar Abstrak             | RSA, ECC, DH semuanya adalah teorema dalam bentuk kode.                                  |
| **Machine Learning / AI**             | Linear Algebra, Kalkulus (Gradient), Probabilitas (Bayes) | Setiap model adalah fungsi matematika yang dioptimalkan.                                 |
| **Database Internals**                | B-Tree, Hash Table, Sorting, Kompleksitas I/O             | Kecepatan query ditentukan oleh seberapa baik struktur data meminimalkan akses disk.     |
| **Reverse Engineering / Eksploitasi** | Aritmatika Modulo, Automata, Graf (call graph)            | Shellcode, buffer overflow, dan analisis malware adalah teka-teki logika dan matematika. |
| **Jaringan & OSINT**                  | Teori Graf, Algoritma Shortest Path, Probabilitas         | Internet adalah graf terbesar di dunia. Routing adalah algoritma di atasnya.             |

> [!tip] Urutan Belajar yang Direkomendasikan
>
> 1. **Matematika Diskrit (Teori Bilangan, Logika, Graf):** Langsung memberikan intuisi untuk kriptografi dan struktur diskrit. Mulai dengan _"Mathematics for Computer Science"_ (MIT OCW 6.042J).
> 2. **Algoritma & Struktur Data:** Praktek bersamaan di LeetCode/Codewars. Buku wajib: _"Introduction to Algorithms" (CLRS)_ sebagai referensi.
> 3. **Linear Algebra:** Mulai dengan visualisasi dari _3Blue1Brown_ ("Essence of Linear Algebra"). Lanjutkan ke _"Linear Algebra and Its Applications" (Gilbert Strang)_. Kunci untuk terjun ke ML.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[computer-science-foundations|Computer Architecture & OS]] — Di mana algoritma bertemu perangkat keras.
- [[cryptography-biometrics|Kriptografi & Biometrik]] — Aplikasi murni dari Teori Bilangan.
- [[hierarchy-ai-levels|AI Levels Hierarchy]] — Aplikasi murni dari Linear Algebra & Probabilitas.
- [[swarm-ai-imam-robandi|Swarm Intelligence]] — Aplikasi dari Algoritma Optimasi.
- [[site-reability-engineering|SRE]] — Di mana analisis kompleksitas bertemu dengan operasi.

---

_Matematika & Algoritma | Algoritma & DS + Matematika Diskrit + Linear Algebra · Fondasi Semua CS · Bahasa Alam Semesta_
