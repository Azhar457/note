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

# 🧮 MATEMATIKA & ALGORITMA — Fondasi Semua CS

> Tiga pilar matematika yang menopang seluruh ilmu komputer: Algoritma & DS (cara berpikir efisien), Matematika Diskrit (bahasa logika komputer), Linear Algebra (bahasa machine learning). Tidak ada jalan pintas — ini fondasinya.

> [!info] Cara Baca
> Bukan hafalan rumus — tapi cara berpikir. Setiap konsep di sini punya koneksi langsung ke topik praktis di vault ini. Gunakan kolom koneksi untuk motivasi belajar.

---

## Sheet 1 — Algoritma & Struktur Data

| 🧩 Level & Konsep | ⚡ Isi & Sweet Spot | ☠️ Jebakan Umum | 🔗 Koneksi ke Topik Lain |
|---|---|---|---|
| **Level 0** — Kompleksitas & Big-O *(O(1), O(log n), O(n), O(n log n), O(n²), O(2ⁿ))* | Ukuran "seberapa lambat kode tumbuh seiring input membesar." O(1): konstan, terbaik. O(log n): binary search, sangat baik. O(n log n): sort optimal. O(n²): nested loop, berbahaya di data besar. O(2ⁿ): eksponensial, praktis unusable di n>30. | Mengoptimasi kode O(n²) yang dipanggil sekali vs membiarkan O(n) yang dipanggil jutaan kali. Premature optimization. Average case vs worst case. | Fondasi semua keputusan engineering, analisis performa exploit, kompleksitas kriptografi |
| **Level 1** — Array & Linked List *(dynamic array, singly/doubly linked, skip list)* | Array: O(1) random access, O(n) insert/delete di tengah. Linked list: O(1) insert/delete, O(n) access. Dynamic array (ArrayList/vector): amortized O(1) append via doubling strategy. Skip list: linked list berlapis untuk O(log n) search. | Linked list di cache-unfriendly — pointer chasing = banyak cache miss. Array lebih cepat dalam praktik meski kompleksitas sama karena locality. | Koneksi ke cache hierarchy (Architecture), fondasi implementasi buffer di kernel |
| **Level 2** — Tree & Graph *(BST, AVL, Red-Black, B-tree, trie, DFS, BFS, Dijkstra, A*)* | BST: O(log n) average, O(n) worst (degenerate). AVL/Red-Black: self-balancing, O(log n) guaranteed. B-tree: dioptimasi untuk disk I/O (dipakai database dan filesystem). Trie: prefix search O(m) dimana m = panjang string. Graph: DFS/BFS untuk traversal, Dijkstra untuk shortest path. | Lupa base case di recursive DFS → stack overflow. Dijkstra tidak bekerja untuk negative weight edge (pakai Bellman-Ford). | B-tree = fondasi Database Internals, Trie = fondasi DNS/routing table, Graph = fondasi OSINT network analysis |
| **Level 3** — Hash Table *(hash function, collision, chaining, open addressing, consistent hashing)* | O(1) average untuk insert/search/delete. Hash function map key → index. Collision: dua key → index sama. Chaining: collision ditangani linked list. Open addressing: probe slot berikutnya. Load factor: ratio isi/kapasitas, trigger resize. Consistent hashing: distribusi key di distributed system. | Worst case O(n) jika hash function buruk → semua collision. Hash DoS: attacker kirim payload yang sengaja collision (mitigasi: randomized hash seed). | Fondasi DNS cache, fondasi blockchain (Merkle tree), consistent hashing = fondasi distributed database |
| **Level 4** — Sorting & Searching *(quicksort, mergesort, heapsort, binary search, radix sort)* | Quicksort: O(n log n) average, O(n²) worst, in-place, cache-friendly → praktik tercepat. Mergesort: O(n log n) guaranteed, stable, butuh O(n) extra space → dipakai untuk external sort (data > RAM). Heapsort: O(n log n) guaranteed, in-place tapi cache-unfriendly. Radix: O(nk) linear untuk integer — kalahkan comparison-based sort. | Quicksort dengan pivot buruk (selalu max/min) → O(n²). Mergesort untuk linked list, quicksort untuk array. Stable sort penting jika sort by multiple key. | Fondasi database query execution, fondasi file system directory listing |
| **Level 5** — Dynamic Programming & Greedy *(memoization, tabulation, knapsack, LCS, Dijkstra)* | DP: pecah masalah jadi sub-problem yang overlap, simpan hasil (memoize) agar tidak hitung ulang. Greedy: pilihan lokal optimal di setiap step → harap optimal global (tidak selalu benar). Overlapping subproblem + optimal substructure = tanda DP cocok. | Greedy tidak selalu optimal (contoh: coin change dengan denominasi tertentu). DP dengan state besar = memory explosion. Bingung top-down vs bottom-up — keduanya equivalen, pilih yang lebih intuitif. | Fondasi network routing optimization, fondasi compiler optimization, fondasi sequence alignment bioinformatika |
| **Level 6** — Advanced Structures *(segment tree, Fenwick tree, union-find, bloom filter, HyperLogLog)* | Segment tree: range query + update O(log n). Fenwick/BIT: prefix sum update/query O(log n), simpler implementasi. Union-Find: konektivitas graph, O(α(n)) ≈ O(1) dengan path compression. Bloom filter: probabilistic set membership, O(1), no false negative tapi ada false positive. HyperLogLog: count distinct element dengan O(log log n) memory. | Bloom filter tidak bisa delete element (gunakan Counting Bloom Filter). Segment tree vs Fenwick: segment tree lebih general, Fenwick lebih simple untuk sum query. | Bloom filter = dipakai Cassandra, Redis, browser safe browsing. HyperLogLog = dipakai Redis, Spark untuk analytics |
| ☠️ **Level 7** — Algorithm Design Paradigms *(divide & conquer, randomization, approximation, amortized analysis)* | Divide & conquer: bagi masalah jadi sub-problem independen (quicksort, FFT, closest pair). Randomization: Las Vegas (selalu benar, random waktu) vs Monte Carlo (random benar, selalu cepat). Approximation: untuk NP-hard problem, cari solusi yang "cukup baik" dengan guarantee ratio. Amortized: analisis biaya operasi rata-rata across sequence, bukan worst case per operasi. | NP-hard ≠ tidak bisa diselesaikan — bisa dengan approximation atau heuristic. Bingung polynomial reduction. Randomized algorithm yang deterministic equivalent lebih disukai di security-critical system. | Fondasi cryptographic algorithm design, fondasi ML optimization, fondasi compiler theory |

---

## Sheet 2 — Matematika Diskrit

| 📐 Topik | ⚡ Isi & Sweet Spot | 🔗 Koneksi Langsung |
|---|---|---|
| **Logika Proposisional & Predikat** | AND, OR, NOT, implication, biconditional. Tautologi, kontradiksi, satisfiability. Predicate logic: quantifier ∀ (untuk semua) dan ∃ (ada). Dasar formal verification dan SAT solver. | Fondasi AI Level 0 (IF-THEN), fondasi formal verification software |
| **Teori Himpunan** | Union, intersection, complement, power set, Cartesian product. Relasi: reflexive, symmetric, transitive, equivalence relation. Fungsi: injective, surjective, bijective. | Fondasi database (relational algebra), fondasi type theory |
| **Kombinatorik & Counting** | Permutasi, kombinasi, pigeonhole principle, inclusion-exclusion. Generating function. Dasar analisis probabilitas algoritma. | Fondasi kriptografi (ukuran keyspace), fondasi complexity theory |
| **Teori Graf** | Graph, digraph, tree, spanning tree, Euler path, Hamiltonian cycle, planar graph, coloring. Network flow. Matching. | Fondasi network routing, fondasi OSINT link analysis, fondasi compiler (control flow graph) |
| **Teori Bilangan** | Divisibility, GCD (Euclidean algorithm), modular arithmetic, Fermat's little theorem, Euler's theorem, Chinese Remainder Theorem. Bilangan prima, uji primalitas. | **Fondasi langsung kriptografi RSA, DH, ECC** — tanpa ini crypto jadi magic |
| **Probabilitas Diskrit** | Sample space, event, conditional probability, Bayes' theorem, random variable, expected value, variance. Distribusi: Bernoulli, binomial, geometric. | Fondasi ML (naive Bayes, probabilistic model), fondasi analisis algoritma randomized |
| **Relasi Rekurensi** | T(n) = aT(n/b) + f(n) — Master Theorem untuk analisis divide & conquer. Fibonacci, Catalan number. | Fondasi analisis algoritma, fondasi DP |
| **Logika Boolean & Rangkaian** | Minimisasi fungsi Boolean (Karnaugh map, Quine-McCluskey). Sum of products, product of sums. | Fondasi digital circuit design (Computer Architecture Level 0) |

---

## Sheet 3 — Linear Algebra untuk CS

| 📊 Topik | ⚡ Isi & Sweet Spot | 🔗 Koneksi Langsung |
|---|---|---|
| **Vektor & Operasi** | Vector addition, scalar multiplication, dot product, cross product, norm (L1, L2). Cosine similarity = dot product normalized. | Fondasi information retrieval, TF-IDF, word embedding (NLP) |
| **Matriks & Operasi** | Matrix multiplication, transpose, inverse, determinant. Kenapa matrix multiply tidak commutative. Strassen algorithm O(n^2.807) vs naive O(n³). | Fondasi neural network (weight matrix), fondasi computer graphics (transformation) |
| **Sistem Persamaan Linear** | Gaussian elimination, LU decomposition. Overdetermined system (lebih banyak persamaan dari variable) → least squares. | Fondasi regression, fondasi computer vision (camera calibration) |
| **Eigenvalue & Eigenvector** | Av = λv. Matriks transformasi yang hanya scale vektor tertentu (eigenvector) tanpa rotate. Diagonalisasi. | **Fondasi PCA** (dimensionality reduction), fondasi Google PageRank, fondasi quantum computing |
| **Dekomposisi Matriks** | SVD (Singular Value Decomposition): setiap matriks bisa didekomposisi jadi U·Σ·Vᵀ. QR decomposition. Cholesky. | Fondasi recommender system (collaborative filtering), fondasi data compression, fondasi pseudoinverse |
| **Ruang Vektor & Transformasi Linear** | Span, basis, dimension, rank, nullspace. Linear map: preserves addition dan scalar multiplication. Change of basis. | Fondasi semua deep learning (setiap layer = linear transformation + non-linearity) |
| **Norma & Jarak** | L1 norm (Manhattan), L2 norm (Euclidean), L∞ norm. Matrix norm. Frobenius norm. | Fondasi regularization (L1=Lasso, L2=Ridge), fondasi distance metric dalam clustering |

---

## Peta Koneksi ke Semua Hierarki

```
MATEMATIKA DISKRIT
│
├── Teori Bilangan ──────────────────► Kriptografi (RSA, DH, ECC)
├── Teori Graf ──────────────────────► OSINT (network analysis)
│                                    ► Algoritma (DFS, BFS, Dijkstra)
├── Kombinatorik ────────────────────► Kriptografi (keyspace size)
│                                    ► Algoritma (complexity analysis)
└── Probabilitas ────────────────────► AI Level 1-2 (ML foundation)
                                     ► Research Methodology (statistics)

ALGORITMA & DS
│
├── B-tree ──────────────────────────► Database Internals
├── Hash Table ──────────────────────► Blockchain, DNS, Cache
├── Graph ───────────────────────────► Network routing, OSINT
└── DP / Greedy ─────────────────────► Compiler, Network optimization

LINEAR ALGEBRA
│
├── Matrix multiply ─────────────────► Neural Network (setiap layer)
├── Eigenvalue/SVD ──────────────────► PCA, Recommender System
├── Cosine similarity ───────────────► NLP, Search Engine
└── Transformasi linear ─────────────► Computer Graphics, Computer Vision
```

> [!tip] Urutan Belajar yang Direkomendasikan
> 1. **Matematika Diskrit** dulu — teori bilangan langsung unlock pemahaman kriptografi
> 2. **Algoritma & DS** — langsung praktek di LeetCode/HackerRank sambil belajar teori
> 3. **Linear Algebra** — mulai saat mulai menyentuh ML/AI Level 2 ke atas
>
> Resource terbaik: *3Blue1Brown* (YouTube) untuk visual intuisi Linear Algebra sebelum formal. *MIT OCW 6.042J* untuk Matematika Diskrit. *CLRS* (Introduction to Algorithms) sebagai referensi Algoritma.

> [!warning] Jebakan Mahasiswa IT
> Belajar syntax framework AI (TensorFlow, PyTorch) tanpa paham matematika di baliknya = bisa pakai tapi tidak bisa debug ketika hasilnya aneh. Model yang overfit, gradient explode, atau hasil tidak masuk akal — semua butuh math untuk diagnosis.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[computer-science-foundations|Computer Science Foundations]] — OS & Architecture
- [[cryptography-biometrics|Kriptografi & Biometrik]] — aplikasi teori bilangan
- [[hierarchy-ai-levels|AI Levels Hierarchy]] — aplikasi linear algebra
- [[research-methodology|Research Methodology]] — aplikasi probabilitas & statistik

---

*Matematika & Algoritma | Algoritma & DS + Matematika Diskrit + Linear Algebra · Fondasi Semua CS*
