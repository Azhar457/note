---
title: '🧩 15 DSA Patterns — Deep Dive: Mastering Algorithmic Problem Solving'
tags:
- dsa
- algorithms
- data-structures
- coding-patterns
- leetcode
- interview-prep
- problem-solving
aliases:
- DSA Patterns
- 15 Algorithm Patterns
- Coding Interview Patterns
- LeetCode Patterns
created: 2026-07-09
updated: 2026-07-09
status: pending
cssclasses:
  - wide-table
---
# 🧩 15 DSA Patterns — Deep Dive: Mastering Algorithmic Problem Solving

> Ringkasan satu-paragraf menjelaskan bahwa 15 DSA (Data Structures & Algorithms) patterns adalah kumpulan pola fundamental yang muncul berulang kali dalam coding interviews dan competitive programming. Menguasai pola-pola ini memungkinkan programmer untuk mengidentifikasi solusi optimal dalam waktu singkat, mengurangi kompleksitas waktu dari O(n²) ke O(n) atau O(log n), dan menyelesaikan masalah yang tampaknya sulit dengan pendekatan yang terstruktur dan teruji.

> [!info] Hubungan ke Vault
> Catatan ini terkait dengan [[system-design]] untuk kompleksitas algoritmik dalam arsitektur sistem, [[comprehensive-threat-directory]] untuk analisis kompleksitas serangan kriptografis, serta [[devops]] untuk optimasi performa pipeline.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa Itu DSA Patterns?

DSA Patterns adalah pola-pola berulang yang muncul dalam masalah algoritmik. Alih-alih menghafal solusi spesifik untuk setiap soal, programmer yang menguasai pola ini dapat:

- **Mengidentifikasi pattern** dari deskripsi masalah dalam hitungan detik
- **Memilih struktur data** yang tepat berdasarkan karakteristik masalah
- **Menentukan kompleksitas** solusi sebelum menulis satu baris kode
- **Mengoptimalkan** dari brute force ke solusi optimal secara sistematis

### Perbandingan: Pattern-Based vs Problem-Based Learning

| Aspek | Problem-Based (Naive) | Pattern-Based (Strategis) |
|-------|----------------------|--------------------------|
| **Pendekatan** | Menghafal solusi per soal | Mengidentifikasi pola umum |
| **Waktu Identifikasi** | 10-30 menit per soal | 30 detik - 2 menit per soal |
| **Transfer Knowledge** | Rendah (soal baru = blank) | Tinggi (pola sama = solusi sama) |
| **Kompleksitas Awal** | O(n²) atau O(2ⁿ) | Langsung optimal O(n) atau O(log n) |
| **Scalability** | Sulit untuk soal baru | Mudah untuk variasi soal |
| **Interview Readiness** | Butuh 200+ soal | Cukup 50-100 soal per pattern |

---

## Technical Deep-Dive

### Pattern 1: Two Pointers

**Kapan Digunakan:** Array/string yang terurut atau perlu membandingkan elemen dari dua ujung.

**Intuisi:** Dua pointer bergerak menuju satu sama lain atau dalam arah yang sama dengan kecepatan berbeda.

**Contoh Masalah:**
- Two Sum II (sorted array)
- 3Sum
- Container With Most Water
- Valid Palindrome

**Implementasi:**

```python
def two_sum_sorted(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    
    while left < right:
        current_sum = nums[left] + nums[right]
        
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1  # Butuh sum yang lebih besar
        else:
            right -= 1  # Butuh sum yang lebih kecil
    
    return []  # Tidak ditemukan
```

**Kompleksitas:** Time O(n), Space O(1)

**Kapan Gagal:** Array tidak terurut, perlu akses acak (gunakan hash map).

---

### Pattern 2: Sliding Window

**Kapan Digunakan:** Subarray/substring kontinu dengan kondisi tertentu (sum, karakter unik, dll).

**Intuisi:** Jendela yang "meluncur" melintasi array, memperluas dari kanan dan menyusut dari kiri.

**Contoh Masalah:**
- Maximum Sum Subarray of Size K
- Longest Substring Without Repeating Characters
- Minimum Window Substring
- Fruit Into Baskets

**Implementasi (Fixed Size):**

```python
def max_sum_subarray(nums: list[int], k: int) -> int:
    window_sum = sum(nums[:k])
    max_sum = window_sum
    
    for i in range(k, len(nums)):
        window_sum += nums[i] - nums[i - k]
        max_sum = max(max_sum, window_sum)
    
    return max_sum
```

**Implementasi (Dynamic Size):**

```python
def longest_substring_no_repeat(s: str) -> int:
    char_index = {}  # char -> last seen index
    max_length = 0
    window_start = 0
    
    for window_end in range(len(s)):
        right_char = s[window_end]
        
        # Jika char sudah ada dalam window, geser start
        if right_char in char_index:
            window_start = max(window_start, char_index[right_char] + 1)
        
        char_index[right_char] = window_end
        max_length = max(max_length, window_end - window_start + 1)
    
    return max_length
```

**Kompleksitas:** Time O(n), Space O(min(m, n)) — m = charset size

---

### Pattern 3: Binary Search

**Kapan Digunakan:** Array terurut, mencari elemen target, atau mencari boundary condition.

**Intuisi:** Membagi search space menjadi dua setiap iterasi — eliminasi setengah ruang pencarian.

**Contoh Masalah:**
- Classic Binary Search
- Search in Rotated Sorted Array
- Find Minimum in Rotated Sorted Array
- Find Peak Element
- Search a 2D Matrix

**Implementasi (Template):**

```python
def binary_search(nums: list[int], target: int) -> int:
    left, right = 0, len(nums) - 1
    
    while left <= right:
        mid = left + (right - left) // 2  # Hindari overflow
        
        if nums[mid] == target:
            return mid
        elif nums[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return -1  # Tidak ditemukan
```

**Varian Binary Search:**

| Varian | Kondisi Loop | Update Rule | Return |
|--------|-------------|-------------|--------|
| **Classic** | `left <= right` | `left = mid + 1`, `right = mid - 1` | `mid` atau `-1` |
| **Lower Bound** | `left < right` | `left = mid + 1`, `right = mid` | `left` |
| **Upper Bound** | `left < right` | `left = mid + 1`, `right = mid` | `left - 1` |
| **Rotated Array** | `left <= right` | Cek sorted half, eliminasi yang lain | `mid` |

**Kompleksitas:** Time O(log n), Space O(1)

---

### Pattern 4: Frequency Counting (Hash Map)

**Kapan Digunakan:** Mencari duplikat, anagram, frequency analysis, two-sum (unsorted).

**Intuisi:** Menggunakan hash map untuk menyimpan frekuensi atau indeks elemen, mengubah pencarian dari O(n) menjadi O(1).

**Contoh Masalah:**
- Two Sum (unsorted)
- Group Anagrams
- Top K Frequent Elements
- Longest Consecutive Sequence
- Subarray Sum Equals K

**Implementasi:**

```python
def two_sum(nums: list[int], target: int) -> list[int]:
    seen = {}  # value -> index
    
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    
    return []

def group_anagrams(strs: list[str]) -> list[list[str]]:
    groups = {}
    
    for s in strs:
        # Key: sorted characters (atau character count tuple)
        key = tuple(sorted(s))
        groups.setdefault(key, []).append(s)
    
    return list(groups.values())
```

**Kompleksitas:** Time O(n) atau O(n log n), Space O(n)

---

### Pattern 5: Matrix Traversal

**Kapan Digunakan:** Grid 2D, image processing, game board, maze.

**Intuisi:** Traversal dengan arah tetap (spiral, diagonal) atau berbasis kondisi (DFS/BFS).

**Contoh Masalah:**
- Spiral Matrix
- Rotate Image
- Set Matrix Zeroes
- Number of Islands (DFS/BFS)
- Word Search

**Implementasi (Spiral Order):**

```python
def spiral_order(matrix: list[list[int]]) -> list[int]:
    if not matrix:
        return []
    
    result = []
    top, bottom = 0, len(matrix) - 1
    left, right = 0, len(matrix[0]) - 1
    
    while top <= bottom and left <= right:
        # Traverse right
        for col in range(left, right + 1):
            result.append(matrix[top][col])
        top += 1
        
        # Traverse down
        for row in range(top, bottom + 1):
            result.append(matrix[row][right])
        right -= 1
        
        # Traverse left (if still valid)
        if top <= bottom:
            for col in range(right, left - 1, -1):
                result.append(matrix[bottom][col])
            bottom -= 1
        
        # Traverse up (if still valid)
        if left <= right:
            for row in range(bottom, top - 1, -1):
                result.append(matrix[row][left])
            left += 1
    
    return result
```

**Kompleksitas:** Time O(m × n), Space O(1) — tidak termasuk output

---

### Pattern 6: Monotonic Stack/Queue

**Kapan Digunakan:** Mencari next greater/smaller element, sliding window maximum, histogram.

**Intuisi:** Stack/queue yang elemennya selalu monotonik (increasing atau decreasing), memungkinkan O(n) untuk masalah yang tampaknya butuh O(n²).

**Contoh Masalah:**
- Next Greater Element
- Daily Temperatures
- Largest Rectangle in Histogram
- Sliding Window Maximum
- Trapping Rain Water

**Implementasi (Next Greater Element):**

```python
def next_greater_element(nums: list[int]) -> list[int]:
    n = len(nums)
    result = [-1] * n
    stack = []  # menyimpan indices
    
    for i in range(n):
        # Pop semua elemen yang lebih kecil dari current
        while stack and nums[stack[-1]] < nums[i]:
            result[stack.pop()] = nums[i]
        stack.append(i)
    
    return result
```

**Implementasi (Sliding Window Maximum):**

```python
from collections import deque

def max_sliding_window(nums: list[int], k: int) -> list[int]:
    result = []
    dq = deque()  # menyimpan indices, monotonic decreasing
    
    for i in range(len(nums)):
        # Remove elements outside window
        while dq and dq[0] < i - k + 1:
            dq.popleft()
        
        # Remove elements smaller than current
        while dq and nums[dq[-1]] < nums[i]:
            dq.pop()
        
        dq.append(i)
        
        # Window sudah penuh
        if i >= k - 1:
            result.append(nums[dq[0]])
    
    return result
```

**Kompleksitas:** Time O(n), Space O(n)

---

### Pattern 7: Prefix Sum

**Kapan Digunakan:** Subarray sum queries, range sum, equilibrium point, subarray dengan sum tertentu.

**Intuisi:** Menyimpan cumulative sum untuk O(1) range sum query. Kombinasi dengan hash map untuk subarray sum equals k.

**Contoh Masalah:**
- Range Sum Query
- Subarray Sum Equals K
- Contiguous Array (equal 0s and 1s)
- Product of Array Except Self

**Implementasi:**

```python
def subarray_sum_equals_k(nums: list[int], k: int) -> int:
    count = 0
    prefix_sum = 0
    sum_frequency = {0: 1}  # prefix_sum -> frequency
    
    for num in nums:
        prefix_sum += num
        
        # Jika prefix_sum - k ada, berarti ada subarray dengan sum = k
        if prefix_sum - k in sum_frequency:
            count += sum_frequency[prefix_sum - k]
        
        sum_frequency[prefix_sum] = sum_frequency.get(prefix_sum, 0) + 1
    
    return count

def range_sum_query(prefix: list[int], left: int, right: int) -> int:
    # prefix[i] = sum of nums[0..i-1]
    return prefix[right + 1] - prefix[left]
```

**Kompleksitas:** Time O(n), Space O(n)

---

### Pattern 8: Overlapping Intervals

**Kapan Digunakan:** Meeting rooms, merge intervals, non-overlapping intervals, interval insertion.

**Intuisi:** Sort by start time, kemudian iterate dan merge/greedy-select berdasarkan overlap.

**Contoh Masalah:**
- Merge Intervals
- Insert Interval
- Meeting Rooms II
- Non-overlapping Intervals
- Minimum Number of Arrows to Burst Balloons

**Implementasi (Merge Intervals):**

```python
def merge_intervals(intervals: list[list[int]]) -> list[list[int]]:
    if not intervals:
        return []
    
    # Sort by start time
    intervals.sort(key=lambda x: x[0])
    
    merged = [intervals[0]]
    
    for current in intervals[1:]:
        last = merged[-1]
        
        if current[0] <= last[1]:  # Overlap
            last[1] = max(last[1], current[1])
        else:
            merged.append(current)
    
    return merged
```

**Implementasi (Meeting Rooms II — Min Heap):**

```python
import heapq

def min_meeting_rooms(intervals: list[list[int]]) -> int:
    if not intervals:
        return 0
    
    # Sort by start time
    intervals.sort(key=lambda x: x[0])
    
    # Min heap of end times
    rooms = [intervals[0][1]]
    
    for start, end in intervals[1:]:
        # Jika meeting paling awal selesai sebelum meeting ini mulai
        if rooms[0] <= start:
            heapq.heappop(rooms)
        
        heapq.heappush(rooms, end)
    
    return len(rooms)
```

**Kompleksitas:** Time O(n log n), Space O(n)

---

### Pattern 9: Greedy

**Kapan Digunakan:** Optimization problems dengan local optimal choice yang menghasilkan global optimal.

**Intuisi:** Membuat pilihan terbaik pada setiap langkah tanpa melihat ke depan. Perlu proof bahwa greedy works.

**Contoh Masalah:**
- Coin Change (unlimited coins, min coins)
- Activity Selection / Interval Scheduling
- Jump Game
- Gas Station
- Assign Cookies

**Implementasi (Activity Selection):**

```python
def max_activities(activities: list[list[int]]) -> int:
    # Sort by finish time (greedy: pilih yang selesai paling cepat)
    activities.sort(key=lambda x: x[1])
    
    count = 1
    last_finish = activities[0][1]
    
    for start, finish in activities[1:]:
        if start >= last_finish:
            count += 1
            last_finish = finish
    
    return count
```

**Kapan Gagal:** Coin Change dengan coins tertentu (butuh DP), Knapsack (butuh DP).

---

### Pattern 10: Top K Elements (Heap)

**Kapan Digunakan:** Mencari K elemen terbesar/terkecil, median, frequent elements.

**Intuisi:** Min-heap untuk top K largest, max-heap untuk top K smallest. Heap size selalu K.

**Contoh Masalah:**
- Kth Largest Element
- Top K Frequent Elements
- Find Median from Data Stream
- Merge K Sorted Lists
- K Closest Points to Origin

**Implementasi (Kth Largest):**

```python
import heapq

def find_kth_largest(nums: list[int], k: int) -> int:
    # Min heap of size k
    min_heap = nums[:k]
    heapq.heapify(min_heap)
    
    for num in nums[k:]:
        if num > min_heap[0]:
            heapq.heapreplace(min_heap, num)
    
    return min_heap[0]

def top_k_frequent(nums: list[int], k: int) -> list[int]:
    from collections import Counter
    
    freq = Counter(nums)
    # Heap of (frequency, num), keep k largest
    return heapq.nlargest(k, freq.keys(), key=freq.get)
```

**Kompleksitas:** Time O(n log k), Space O(k)

---

### Pattern 11: Backtracking

**Kapan Digunakan:** Permutation, combination, subset, constraint satisfaction, maze, sudoku.

**Intuisi:** Eksplorasi semua kemungkinan secara rekursif dengan "undo" (backtrack) saat mencapai dead end.

**Contoh Masalah:**
- Permutations
- Subsets
- N-Queens
- Combination Sum
- Word Search
- Sudoku Solver

**Implementasi (Subsets):**

```python
def subsets(nums: list[int]) -> list[list[int]]:
    result = []
    
    def backtrack(start: int, current: list[int]):
        result.append(current[:])  # Copy current subset
        
        for i in range(start, len(nums)):
            current.append(nums[i])
            backtrack(i + 1, current)
            current.pop()  # Backtrack
    
    backtrack(0, [])
    return result
```

**Implementasi (N-Queens):**

```python
def solve_n_queens(n: int) -> list[list[str]]:
    result = []
    board = [['.' for _ in range(n)] for _ in range(n)]
    
    def is_safe(row: int, col: int) -> bool:
        # Check column
        for i in range(row):
            if board[i][col] == 'Q':
                return False
        
        # Check diagonal kiri atas
        for i, j in zip(range(row, -1, -1), range(col, -1, -1)):
            if board[i][j] == 'Q':
                return False
        
        # Check diagonal kanan atas
        for i, j in zip(range(row, -1, -1), range(col, n)):
            if board[i][j] == 'Q':
                return False
        
        return True
    
    def backtrack(row: int):
        if row == n:
            result.append([''.join(r) for r in board])
            return
        
        for col in range(n):
            if is_safe(row, col):
                board[row][col] = 'Q'
                backtrack(row + 1)
                board[row][col] = '.'  # Backtrack
    
    backtrack(0)
    return result
```

**Kompleksitas:** Time O(2ⁿ) atau O(n!), Space O(n) — untuk recursion stack

---

### Pattern 12: Binary Tree Traversal

**Kapan Digunakan:** Tree problems, expression evaluation, serialization, validation.

**Intuisi:** Rekursif atau iteratif (stack) traversal dengan urutan yang berbeda: inorder, preorder, postorder, level order.

**Contoh Masalah:**
- Invert Binary Tree
- Maximum Depth
- Diameter of Binary Tree
- Lowest Common Ancestor
- Serialize and Deserialize
- Validate BST

**Implementasi (Iterative Inorder):**

```python
class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def inorder_traversal(root: TreeNode) -> list[int]:
    result = []
    stack = []
    current = root
    
    while current or stack:
        # Go as left as possible
        while current:
            stack.append(current)
            current = current.left
        
        # Process node
        current = stack.pop()
        result.append(current.val)
        
        # Go right
        current = current.right
    
    return result
```

**Implementasi (Level Order — BFS):**

```python
from collections import deque

def level_order(root: TreeNode) -> list[list[int]]:
    if not root:
        return []
    
    result = []
    queue = deque([root])
    
    while queue:
        level_size = len(queue)
        level = []
        
        for _ in range(level_size):
            node = queue.popleft()
            level.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        
        result.append(level)
    
    return result
```

**Kompleksitas:** Time O(n), Space O(h) — h = height of tree

---

### Pattern 13: Depth-First Search (DFS)

**Kapan Digunakan:** Graph/tree traversal, connected components, cycle detection, topological sort.

**Intuisi:** Eksplorasi sejauh mungkin sebelum backtracking. Bisa rekursif (stack implisit) atau iteratif (stack eksplisit).

**Contoh Masalah:**
- Number of Islands
- Clone Graph
- Course Schedule (cycle detection)
- Pacific Atlantic Water Flow
- Word Ladder

**Implementasi (Number of Islands):**

```python
def num_islands(grid: list[list[str]]) -> int:
    if not grid:
        return 0
    
    rows, cols = len(grid), len(grid[0])
    islands = 0
    
    def dfs(r: int, c: int):
        if r < 0 or r >= rows or c < 0 or c >= cols or grid[r][c] == '0':
            return
        
        grid[r][c] = '0'  # Mark as visited
        
        # 4-directional
        dfs(r + 1, c)
        dfs(r - 1, c)
        dfs(r, c + 1)
        dfs(r, c - 1)
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '1':
                islands += 1
                dfs(r, c)
    
    return islands
```

**Kompleksitas:** Time O(V + E), Space O(V) — V = vertices, E = edges

---

### Pattern 14: Breadth-First Search (BFS)

**Kapan Digunakan:** Shortest path (unweighted graph), level-order traversal, nearest neighbor.

**Intuisi:** Eksplorasi semua neighbor pada level yang sama sebelum ke level berikutnya. Queue-based.

**Contoh Masalah:**
- Shortest Path in Binary Matrix
- Word Ladder
- Rotting Oranges
- Minimum Knight Moves
- Snake and Ladders

**Implementasi (Shortest Path Binary Matrix):**

```python
from collections import deque

def shortest_path_binary_matrix(grid: list[list[int]]) -> int:
    n = len(grid)
    
    if grid[0][0] == 1 or grid[n-1][n-1] == 1:
        return -1
    
    directions = [(-1,-1), (-1,0), (-1,1), (0,-1), (0,1), (1,-1), (1,0), (1,1)]
    queue = deque([(0, 0, 1)])  # (row, col, distance)
    grid[0][0] = 1  # Mark visited
    
    while queue:
        r, c, dist = queue.popleft()
        
        if r == n - 1 and c == n - 1:
            return dist
        
        for dr, dc in directions:
            nr, nc = r + dr, c + dc
            
            if 0 <= nr < n and 0 <= nc < n and grid[nr][nc] == 0:
                grid[nr][nc] = 1  # Mark visited
                queue.append((nr, nc, dist + 1))
    
    return -1
```

**Kompleksitas:** Time O(V + E), Space O(V)

---

### Pattern 15: Dynamic Programming (DP)

**Kapan Digunakan:** Optimization problems dengan overlapping subproblems dan optimal substructure.

**Intuisi:** Menyimpan hasil subproblem untuk menghindari perhitungan ulang. Bottom-up (tabulation) atau top-down (memoization).

**Contoh Masalah:**
- Fibonacci
- Climbing Stairs
- Longest Common Subsequence
- Edit Distance
- 0/1 Knapsack
- Coin Change
- Longest Increasing Subsequence

**Implementasi (Bottom-Up Fibonacci):**

```python
def fibonacci(n: int) -> int:
    if n <= 1:
        return n
    
    dp = [0] * (n + 1)
    dp[1] = 1
    
    for i in range(2, n + 1):
        dp[i] = dp[i - 1] + dp[i - 2]
    
    return dp[n]

# Space-optimized

def fibonacci_optimized(n: int) -> int:
    if n <= 1:
        return n
    
    prev2, prev1 = 0, 1
    
    for _ in range(2, n + 1):
        current = prev1 + prev2
        prev2 = prev1
        prev1 = current
    
    return prev1
```

**Implementasi (0/1 Knapsack):**

```python
def knapsack(weights: list[int], values: list[int], capacity: int) -> int:
    n = len(weights)
    # dp[i][w] = max value using first i items with capacity w
    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
    
    for i in range(1, n + 1):
        for w in range(capacity + 1):
            # Don't take item i-1
            dp[i][w] = dp[i - 1][w]
            
            # Take item i-1 (if it fits)
            if weights[i - 1] <= w:
                dp[i][w] = max(dp[i][w], 
                              values[i - 1] + dp[i - 1][w - weights[i - 1]])
    
    return dp[n][capacity]

# Space-optimized (1D array)

def knapsack_optimized(weights: list[int], values: list[int], capacity: int) -> int:
    dp = [0] * (capacity + 1)
    
    for w, v in zip(weights, values):
        # Traverse backwards to avoid using updated values
        for c in range(capacity, w - 1, -1):
            dp[c] = max(dp[c], v + dp[c - w])
    
    return dp[capacity]
```

**Kompleksitas:** Time O(n × capacity), Space O(capacity) — untuk optimized version

---

## Advanced

### Pattern Selection Decision Tree

```
START
 │
 ▼
┌─────────────────────────────────────────┐
│  Apakah data terurut?                   │
└─────────────────────────────────────────┘
    │
    ▼ YES
┌─────────────────────────────────────────┐
│  Cari elemen / boundary?                │
└─────────────────────────────────────────┘
    │
    ▼ YES → BINARY SEARCH (Pattern 3)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Subarray kontinu dengan constraint?     │
└─────────────────────────────────────────┘
    │
    ▼ YES → SLIDING WINDOW (Pattern 2)
    │
    ▼ NO → TWO POINTERS (Pattern 1)
    │
    ▼ NO (data tidak terurut)
┌─────────────────────────────────────────┐
│  Graph / Tree / Grid?                   │
└─────────────────────────────────────────┘
    │
    ▼ YES
┌─────────────────────────────────────────┐
│  Shortest path (unweighted)?            │
└─────────────────────────────────────────┘
    │
    ▼ YES → BFS (Pattern 14)
    │
    ▼ NO → DFS (Pattern 13) atau 
           TREE TRAVERSAL (Pattern 12)
    │
    ▼ NO (bukan graph)
┌─────────────────────────────────────────┐
│  Optimization dengan subproblems?       │
└─────────────────────────────────────────┘
    │
    ▼ YES → DYNAMIC PROGRAMMING (Pattern 15)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Eksplorasi semua kemungkinan?          │
└─────────────────────────────────────────┘
    │
    ▼ YES → BACKTRACKING (Pattern 11)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Frekuensi / duplikat / anagram?        │
└─────────────────────────────────────────┘
    │
    ▼ YES → FREQUENCY COUNTING (Pattern 4)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Range / interval overlap?              │
└─────────────────────────────────────────┘
    │
    ▼ YES → OVERLAPPING INTERVALS (Pattern 8)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  K elemen terbesar/terkecil?            │
└─────────────────────────────────────────┘
    │
    ▼ YES → TOP K ELEMENTS (Pattern 10)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Next greater / smaller element?        │
└─────────────────────────────────────────┘
    │
    ▼ YES → MONOTONIC STACK (Pattern 6)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Subarray sum / range query?            │
└─────────────────────────────────────────┘
    │
    ▼ YES → PREFIX SUM (Pattern 7)
    │
    ▼ NO
┌─────────────────────────────────────────┐
│  Local optimal = global optimal?        │
└─────────────────────────────────────────┘
    │
    ▼ YES → GREEDY (Pattern 9)
    │
    ▼ NO → Reconsider, mungkin butuh 
            kombinasi pattern atau 
            advanced technique
```

### Complexity Cheat Sheet

| Pattern | Time | Space | Kapan Gagal |
|---------|------|-------|-------------|
| Two Pointers | O(n) | O(1) | Data tidak terurut, perlu akses acak |
| Sliding Window | O(n) | O(k) atau O(n) | Subarray tidak kontinu, perlu kombinasi |
| Binary Search | O(log n) | O(1) | Data tidak terurut, search space tidak monotonik |
| Frequency Counting | O(n) | O(n) | Memory constraint ketat, data terlalu besar |
| Matrix Traversal | O(m×n) | O(1) | Pathfinding dengan constraint kompleks |
| Monotonic Stack | O(n) | O(n) | Pattern tidak monotonik, perlu random access |
| Prefix Sum | O(n) | O(n) | Update dinamis (gunakan Fenwick Tree / Segment Tree) |
| Overlapping Intervals | O(n log n) | O(n) | Interval dengan weight/priority berbeda |
| Greedy | O(n log n) | O(1) atau O(n) | Optimal substructure tidak terpenuhi |
| Top K Elements | O(n log k) | O(k) | k ≈ n (lebih baik sort langsung) |
| Backtracking | O(2ⁿ) atau O(n!) | O(n) | Constraint terlalu longgar → terlalu banyak kemungkinan |
| Tree Traversal | O(n) | O(h) | Tree tidak balance (h → n) |
| DFS | O(V+E) | O(V) | Shortest path (gunakan BFS) |
| BFS | O(V+E) | O(V) | Weighted graph (gunakan Dijkstra) |
| Dynamic Programming | O(n²) atau O(n×W) | O(n) atau O(W) | State space terlalu besar (curse of dimensionality) |

---

## Case Studies

| Studi Kasus | Pattern | Masalah | Solusi | Kompleksitas |
|-------------|---------|---------|--------|--------------|
| **Two Sum (LeetCode 1)** | Frequency Counting | Cari dua angka yang sum = target | Hash map untuk complement | Time O(n), Space O(n) |
| **3Sum (LeetCode 15)** | Two Pointers | Cari triplet yang sum = 0 | Sort + two pointers | Time O(n²), Space O(1) |
| **Longest Substring Without Repeating Characters (LeetCode 3)** | Sliding Window | Panjang substring tanpa duplikat | Expand/shrink window dengan hash set | Time O(n), Space O(min(m,n)) |
| **Search in Rotated Sorted Array (LeetCode 33)** | Binary Search | Cari target di rotated array | Modified binary search, cek sorted half | Time O(log n), Space O(1) |
| **Merge Intervals (LeetCode 56)** | Overlapping Intervals | Gabungkan interval yang overlap | Sort + iterate + merge | Time O(n log n), Space O(n) |
| **Largest Rectangle in Histogram (LeetCode 84)** | Monotonic Stack | Area rectangle terbesar di histogram | Monotonic increasing stack | Time O(n), Space O(n) |
| **Subarray Sum Equals K (LeetCode 560)** | Prefix Sum | Jumlah subarray dengan sum = k | Prefix sum + hash map | Time O(n), Space O(n) |
| **Meeting Rooms II (LeetCode 253)** | Overlapping Intervals | Minimum ruangan meeting yang dibutuhkan | Sort + min heap untuk end times | Time O(n log n), Space O(n) |
| **N-Queens (LeetCode 51)** | Backtracking | Tempatkan N ratu di papan N×N | Recursive backtracking dengan pruning | Time O(n!), Space O(n) |
| **Number of Islands (LeetCode 200)** | DFS/BFS | Hitung pulau di grid | DFS/BFS untuk connected components | Time O(m×n), Space O(m×n) |
| **Longest Common Subsequence (LeetCode 1143)** | Dynamic Programming | Panjang subsequence umum terpanjang | 2D DP table | Time O(m×n), Space O(min(m,n)) |
| **Kth Largest Element (LeetCode 215)** | Top K Elements | Elemen ke-k terbesar | Min heap size k | Time O(n log k), Space O(k) |

---

## Koneksi ke Vault

- [[system-design]] — Kompleksitas algoritmik dalam arsitektur sistem (Big O analysis untuk scalability).
- [[comprehensive-threat-directory]] — Analisis kompleksitas serangan kriptografis (brute force → polynomial time reduction).
- [[devops]] — Optimasi performa pipeline, caching strategies, dan resource scheduling.
- [[threat-modeling-deepdive]] — Analisis worst-case scenarios dan mitigation strategies (analog dengan Big O worst-case analysis).
- [[network-security]] — Graph traversal untuk network topology analysis dan pathfinding.

---

## Referensi

1. algomaster.io. *DSA was HARD until I learned these 15 PATTERNS*. Instagram Reels, 2025.
2. LeetCode. *Top Interview 150*. https://leetcode.com/studyplan/top-interview-150/
3. LeetCode. *LeetCode 75*. https://leetcode.com/studyplan/leetcode-75/
4. Educative.io. *Grokking the Coding Interview: Patterns for Coding Questions*. 2020.
5. NeetCode. *NeetCode 150*. https://neetcode.io/roadmap
6. Cracking the Coding Interview (McDowell). *6th Edition*. CareerCup, 2015.
7. Elements of Programming Interviews (Aziz, Lee, Prakash). *The Insiders' Guide*. 2012.
8. GeeksforGeeks. *Data Structures and Algorithms*. https://www.geeksforgeeks.org/dsa-tutorial-learn-data-structures-and-algorithms/
9. MIT OpenCourseWare. *Introduction to Algorithms (6.006)*. https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/
10. Stanford Lagunita. *Algorithms: Design and Analysis*. https://lagunita.stanford.edu/courses/course-v1:Engineering+Algorithms1+SelfPaced/about

> [!tip] Bottom Line
> Menguasai 15 DSA patterns bukan tentang menghafal kode — ini tentang mengembangkan intuisi algoritmik. Setiap kali menghadapi masalah baru, tanyakan: "Pattern apa yang paling mirip?" "Constraint apa yang menentukan pilihan data structure?" "Apakah ada substructure yang bisa di-optimize?" Dengan latihan yang konsisten (50-100 soal per pattern), pattern recognition akan menjadi otomatis, dan waktu identifikasi solusi akan turun dari menit ke detik.
---

audited
---
