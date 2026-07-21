---
title: Backpropagation Learning Roadmap — From Calculus to Custom Autograd Engine
tags:
- machine-learning
- deep-learning
- neural-networks
- calculus
- roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Memahami algoritma *backpropagation* secara mendalam membutuhkan transisi dari persamaan matematika murni ke baris kode implementasi nyata. Catatan ini dirancang sebagai peta jalan belajar (*roadmap*) untuk menguasai mekanisme aliran balik gradien dari dasar, menjadi pasangan praktis dari berkas teoritis [[backpropagation-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Fondasi Matematika (Kalkulus & Turunan Berantai)](#2-fase-1-fondasi-matematika-kalkulus--turunan-berantai)
3. [Fase 2: Membangun Engine Autograd Kustom di Python](#3-fase-2-membangun-engine-autograd-kustom-di-python)
4. [Fase 3: Menyusun Multi-Layer Perceptron (MLP) dari Scratch](#4-fase-3-menyusun-multi-layer-perceptron-mlp-dari-scratch)
5. [Fase 4: Verifikasi & Benchmark Menggunakan PyTorch](#5-fase-4-verifikasi--benchmark-menggunakan-pytorch)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan ini memandu Anda membangun pemahaman intuitif dan praktis mengenai gradien:

```
[Fase 1: Kalkulus] ──> [Fase 2: Autograd Engine] ──> [Fase 3: Custom MLP] ──> [Fase 4: PyTorch Audit]
- Aturan Rantai      - Graf Komputasi            - Forward & Backward     - Gradient Checking
- Turunan Parsial    - Operasi Backprop          - Update Bobot (SGD)     - Profiling VRAM
```

---

## 2. Fase 1: Fondasi Matematika (Kalkulus & Turunan Berantai)

Sebelum menulis kode, Anda harus memahami **Aturan Rantai (Chain Rule)** secara intuitif. Aturan rantai menyatakan bahwa jika sebuah variabel $z$ bergantung pada $y$, yang kemudian bergantung pada $x$, maka turunan $z$ terhadap $x$ adalah perkalian turunan keduanya:

$$\frac{dz}{dx} = \frac{dz}{dy} \cdot \frac{dy}{dx}$$

Dalam graf komputasi neural network, jika kita memiliki fungsi loss $L$, output node $y$, dan input bobot $w$:
$$\frac{\partial L}{\partial w} = \frac{\partial L}{\partial y} \cdot \frac{\partial y}{\partial w}$$
Bobot diperbarui menggunakan algoritma Gradient Descent:
$$w_{\text{new}} = w_{\text{old}} - \eta \cdot \frac{\partial L}{\partial w}$$
Dimana $\eta$ adalah *learning rate*.

---

## 3. Fase 2: Membangun Engine Autograd Kustom di Python

Pada fase ini, Anda akan membangun sebuah graf komputasi dinamis berbasis Node (*Scalar*) yang mampu merekam operasi matematika dan melakukan penelusuran balik (*topological sort*) untuk menghitung turunan secara otomatis.

Berikut adalah implementasi Python sederhana dari autograd engine:

```python
class Value:
    def __init__(self, data, _children=(), _op='', label=''):
        self.data = data
        self.grad = 0.0 # Menyimpan nilai turunan akumulatif (dL/dValue)
        self._prev = set(_children)
        self._op = _op
        self.label = label
        self._backward = lambda: None

    def __add__(self, other):
        other = other if isinstance(other, Value) else Value(other)
        out = Value(self.data + other.data, (self, other), '+')
        
        def _backward():
            self.grad += 1.0 * out.grad
            other.grad += 1.0 * out.grad
        out._backward = _backward
        return out

    def __mul__(self, other):
        other = other if isinstance(other, Value) else Value(other)
        out = Value(self.data * other.data, (self, other), '*')
        
        def _backward():
            self.grad += other.data * out.grad
            other.grad += self.data * out.grad
        out._backward = _backward
        return out

    def relu(self):
        out = Value(max(0.0, self.data), (self,), 'ReLU')
        
        def _backward():
            self.grad += (1.0 if out.data > 0 else 0.0) * out.grad
        out._backward = _backward
        return out

    def backward(self):
        # Jalankan topological sort untuk mengurutkan node graf komputasi
        topo = []
        visited = set()
        def build_topo(v):
            if v not in visited:
                visited.add(v)
                for child in v._prev:
                    build_topo(child)
                topo.append(v)
        build_topo(self)
        
        # Set gradien awal untuk node root (dL/dL = 1.0)
        self.grad = 1.0
        # Panggil fungsi _backward dari akhir ke awal
        for v in reversed(topo):
            v._backward()
```

---

## 4. Fase 3: Menyusun Multi-Layer Perceptron (MLP) dari Scratch

Gunakan kelas `Value` yang telah Anda buat di Fase 2 untuk menyusun sebuah jaringan saraf tiruan sederhana yang memiliki neuron, layer, dan fungsi forward-backward.

```python
import random

class Neuron:
    def __init__(self, nin):
        # Inisialisasi bobot (weights) dan bias secara acak
        self.w = [Value(random.uniform(-1, 1)) for _ in range(nin)]
        self.b = Value(random.uniform(-1, 1))

    def __call__(self, x):
        # Formula: Act(sum(w_i * x_i) + b)
        act = sum((wi * xi for wi, xi in zip(self.w, x)), self.b)
        return act.relu()

    def parameters(self):
        return self.w + [self.b]

class Layer:
    def __init__(self, nin, nout):
        self.neurons = [Neuron(nin) for _ in range(nout)]

    def __call__(self, x):
        outs = [n(x) for n in self.neurons]
        return outs[0] if len(outs) == 1 else outs

    def parameters(self):
        return [p for neuron in self.neurons for p in neuron.parameters()]

class MLP:
    def __init__(self, nin, nouts):
        sz = [nin] + nouts
        self.layers = [Layer(sz[i], sz[i+1]) for i in range(len(nouts))]

    def __call__(self, x):
        for layer in self.layers:
            x = layer(x)
        return x

    def parameters(self):
        return [p for layer in self.layers for p in layer.parameters()]
```

---

## 5. Fase 4: Verifikasi & Benchmark Menggunakan PyTorch

Setelah membuat autograd sendiri, Anda harus memvalidasi keakuratan gradien yang dihasilkan menggunakan kalkulasi otomatis dari **PyTorch** (*gradient checking*).

```python
import torch

# 1. Verifikasi dengan PyTorch Autograd
x_torch = torch.tensor([-4.0], dtype=torch.float64, requires_grad=True)
z_torch = (x_torch * 2) + 5
loss_torch = torch.nn.functional.relu(z_torch)
loss_torch.backward()

# 2. Verifikasi dengan Engine Kustom kita
x_custom = Value(-4.0)
z_custom = (x_custom * 2) + 5
loss_custom = z_custom.relu()
loss_custom.backward()

# Bandingkan hasil gradien keduanya
assert abs(x_torch.grad.item() - x_custom.grad) < 1e-9
print("Gradien COCOK! Autograd kustom terbukti valid secara matematika.")
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Diberikan fungsi komputasi $f(x, y) = x \cdot y + y^2$. Jika nilai awal $x = 3.0$ dan $y = -2.0$:
1. Hitung nilai output forward pass.
2. Turunkan nilai gradien parsial $\frac{\partial f}{\partial x}$ dan $\frac{\partial f}{\partial y}$ secara manual menggunakan aturan rantai.
3. Buktikan menggunakan kode engine `Value` Anda.

**Solusi**

Kalkulasi manual:
- Forward pass: $f(3.0, -2.0) = (3.0 \cdot -2.0) + (-2.0)^2 = -6.0 + 4.0 = -2.0$.
- Gradien parsial:
  - $\frac{\partial f}{\partial x} = y = -2.0$
  - $\frac{\partial f}{\partial y} = x + 2y = 3.0 + 2(-2.0) = 3.0 - 4.0 = -1.0$

Kode pembuktian:
```python
x = Value(3.0)
y = Value(-2.0)
f = x * y + y * y
f.backward()

print(f"Forward output: {f.data}") # -2.0
print(f"df/dx: {x.grad}")          # -2.0
print(f"df/dy: {y.grad}")          # -1.0
```

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[backpropagation-deepdive]] | Dasar teori, representasi graf komputasi, dan kalkulus balik *backward pass*. |
| [[attention-mechanism-deepdive]] | Penerapan aliran balik gradien pada arsitektur matriks perkalian dot-product. |
| [[machine-learning-classical-hierarchy]] | Peta klasifikasi algoritma pembelajaran terawasi berbasis gradien. |
