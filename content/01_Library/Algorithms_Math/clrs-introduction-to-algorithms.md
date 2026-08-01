---
title: Introduction to Algorithms (CLRS)
tags:
  - algorithms-math
  - library
created: "2026-07-05"
updated: "2026-07-05"
status: pending
---

# Introduction to Algorithms

> Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, Clifford Stein — 1990 (4th ed 2022)

**Tesis:** Algoritma adalah _heartbeat_ dari computer science. Kuasai fundamental — sorting, searching, graph, dynamic programming — dan kamu bisa analyze **any** algorithm's correctness + efficiency.

## Kenapa Penting

- Standard textbook algoritma di universitas top dunia
- Bukan "implementasi di Python" — fokus ke **analisis matematis** kompleksitas
- Algoritma = bahasa universal wawancara + system design

Algoritma juga menjadi fondasi bagi banyak bidang ilmu komputer, seperti kecerdasan buatan, ilmu data, dan sistem operasi. Oleh karena itu, memahami algoritma dengan baik sangat penting bagi siapa saja yang ingin berkarir di bidang teknologi informasi.

## Key Takeaways

**1. Foundations — Running Time**

- Big O, Θ, Ω — _notasi yang sama dipake di mana-mana_
- Recurrences: substitution, recursion-tree, master method
- **Wajib paham** sebelum lompat ke bab lain

Pemahaman tentang notasi Big O, Θ, dan Ω sangat penting karena digunakan untuk menganalisis kompleksitas algoritma. Notasi ini membantu kita memahami seberapa baik algoritma dapat menangani input yang besar.

**Contoh:**

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

Fungsi di atas memiliki kompleksitas O(2^n) karena setiap panggilan fungsi memicu dua panggilan fungsi lagi.

**2. Sorting and Order Statistics**

- **Merge Sort** → O(n log n), divide & conquer klasik
- **Quicksort** → O(n²) worst case tapi rata-rata O(n log n) — fastest in practice
- **Heapsort** → O(n log n), in-place, priority queue
- Order statistics: mencari median — O(n) expected, O(n) worst via SELECT

Merge Sort, Quicksort, dan Heapsort adalah contoh algoritma sorting yang populer. Masing-masing memiliki kelebihan dan kekurangan. Merge Sort memiliki kompleksitas O(n log n) namun memerlukan ruang ekstra untuk menyimpan hasil sorting. Quicksort memiliki kompleksitas rata-rata O(n log n) namun dapat memiliki kompleksitas O(n²) dalam kasus terburuk. Heapsort memiliki kompleksitas O(n log n) dan dapat diimplementasikan in-place.

**Contoh Implementasi Merge Sort:**

```python
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    while len(left) > 0 and len(right) > 0:
        if left[0] <= right[0]:
            result.append(left.pop(0))
        else:
            result.append(right.pop(0))
    result.extend(left)
    result.extend(right)
    return result
```

**3. Data Structures**

- Hash tables — O(1) average (collision resolution: chaining vs open addressing)
- Binary Search Trees — O(h), h bisa n kalau skewed → Red-Black Trees (balanced)
- B-Trees — fundamental untuk databases (disk-based)

Struktur data yang tepat dapat sangat mempengaruhi efisiensi algoritma. Hash tables, Binary Search Trees, dan B-Trees adalah contoh struktur data yang umum digunakan.

**Contoh Implementasi Hash Table:**

```python
class HashTable:
    def __init__(self, size):
        self.size = size
        self.table = [[] for _ in range(size)]

    def _hash(self, key):
        return hash(key) % self.size

    def insert(self, key, value):
        index = self._hash(key)
        for pair in self.table[index]:
            if pair[0] == key:
                pair[1] = value
                return
        self.table[index].append([key, value])

    def get(self, key):
        index = self._hash(key)
        for pair in self.table[index]:
            if pair[0] == key:
                return pair[1]
        return None
```

**4. Advanced Design Techniques**

- **Dynamic Programming** — optimal substructure + overlapping subproblems
  - Rod cutting, matrix chain, LCS, knapsack
- **Greedy Algorithms** — local optimum → global optimum
  - Activity selection, Huffman coding, fractional knapsack

Dynamic Programming dan Greedy Algorithms adalah teknik desain algoritma yang lebih maju. Dynamic Programming digunakan untuk memecahkan masalah yang memiliki struktur optimal dan submasalah yang tumpang tindih. Greedy Algorithms digunakan untuk memecahkan masalah yang dapat dipecahkan dengan memilih solusi lokal yang optimum.

**Contoh Implementasi Dynamic Programming untuk Rod Cutting:**

```python
def rod_cutting(p, n):
    s = [0] * (n + 1)
    for i in range(1, n + 1):
        max_val = float('-inf')
        for j in range(1, i + 1):
            max_val = max(max_val, p[j] + s[i - j])
        s[i] = max_val
    return s[n]
```

**5. Graph Algorithms**

- BFS/DFS — traversal fundamental
- Shortest Path: Dijkstra (non-negative), Bellman-Ford (negative weights), Floyd-Warshall (all pairs)
- Minimum Spanning Tree: Kruskal (union-find), Prim (priority queue)
- Max Flow: Ford-Fulkerson, Edmonds-Karp

Algoritma grafik digunakan untuk memecahkan masalah yang terkait dengan struktur data grafik. BFS dan DFS adalah contoh algoritma traversal grafik yang fundamental. Algoritma Shortest Path, Minimum Spanning Tree, dan Max Flow digunakan untuk memecahkan masalah yang terkait dengan jaringan dan sistem transportasi.

**Contoh Implementasi BFS:**

```python
from collections import deque

def bfs(graph, start):
    visited = set()
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node not in visited:
            visited.add(node)
            queue.extend(neighbor for neighbor in graph[node] if neighbor not in visited)
    return visited
```

**6. NP-Completeness (Chapter 34)**

- P vs NP — milestone teori
- Reduction: bagaimana membuktikan problem itu NP-complete
- Approximation algorithms untuk NP-hard problems

NP-Completeness adalah konsep yang sangat penting dalam teori komputasi. P vs NP adalah pertanyaan yang sangat penting dan masih belum terpecahkan. reduction adalah metode yang digunakan untuk membuktikan bahwa suatu masalah adalah NP-complete. Approximation algorithms digunakan untuk memecahkan masalah yang NP-hard.

## Bab Penting

| Bab   | Judul                             | Wajib?                                    |
| ----- | --------------------------------- | ----------------------------------------- |
| 3     | Growth of Functions               | **WAJIB** — Big O, Θ, Ω                   |
| 7     | Quicksort                         | **WAJIB** — analysis + randomized version |
| 15    | Dynamic Programming               | **WAJIB** — skill paling transferable     |
| 22-26 | Graph Algorithms                  | **WAJIB** — fundamental system design     |
| 21    | Data Structures for Disjoint Sets | Union-Find — penting                      |
| 34    | NP-Completeness                   | Pahami konsep, detail bukti gak wajib     |

## Strategi Baca

1. **Part I (Ch 1-5)**: Growth, recurrences, sorting — pondasi
2. **Ch 6**: Heapsort + priority queue
3. **Ch 12**: Binary Search Trees
4. **Ch 15**: Dynamic Programming — latihan kerjain minimal 3 soal
5. **Ch 22-24**: Graph — BFS/DFS + Dijkstra + Bellman-Ford
6. **Sisanya**: referensial — baca pas butuh

## Checklist

- [ ] Hafal notasi Big O + master method recurrence
- [ ] Implementasi sorting: merge, quick, heap (di bahasa apapun)
- [ ] Implementasi BFS/DFS + Dijkstra
- [ ] Kerjakan 5 soal DP (rod cutting, LCS, knapsack, coin change, edit distance)
- [ ] Kenali NP-Complete: apa bedanya P, NP, NP-Complete, NP-Hard

Dengan memahami konsep-konsep dasar dan maju dalam algoritma, kita dapat meningkatkan kemampuan kita dalam menganalisis dan memecahkan masalah yang kompleks. Oleh karena itu, penting untuk memahami algoritma dengan baik dan terus mengembangkan kemampuan kita dalam bidang ini.
