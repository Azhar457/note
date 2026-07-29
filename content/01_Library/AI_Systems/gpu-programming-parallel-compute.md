---
title: "GPU Programming & Parallel Compute — Deep Dive: CUDA, ROCm, Vulkan Compute,
  GPU Architecture, CUDA Cores vs Tensor Cores"
tags:
  - gpu
  - cuda
  - rocm
  - parallel-compute
  - ml-infrastructure
  - high-performance
created: "2026-07-18"
updated: "2026-07-18"
status: pending
cssclasses:
  - wide-table
---

# 🎮 GPU Programming & Parallel Compute — Deep Dive: CUDA, ROCm, Vulkan Compute, GPU Architecture, CUDA Cores vs Tensor Cores

> Panduan komprehensif GPU sebagai compute engine — dari arsitektur hardware (SM, warp, memory hierarchy) sampai programming model (CUDA, ROCm, Vulkan Compute, OpenCL, SYCL). Mencakup GPU architecture (Ampere, Hopper, RDNA3), memory hierarchy (global, shared, local, constant, texture), parallel programming patterns (grid-stride loop, reduction, scan, tiling), CUDA/ROCm programming model (kernel, grid, block, thread, shared memory), GPU-accelerated ML training (mixed precision, tensor cores, distributed training), GPU compute untuk non-ML (hashcat, password cracking, signal processing, rendering), dan perbandingan platform GPU (NVIDIA CUDA vs AMD ROCm vs Intel oneAPI vs Apple Metal). Vault punya [[hierarchy-classical-ml-algorithms]] dan berbagai AI notes yang bergantung pada GPU — catatan ini adalah fondasi hardware compute-nya.

> [!info] Posisi di Vault
> Ini adalah **fondasi hardware compute** untuk semua catatan yang bergantung pada GPU. Baca ini dulu sebelum [[hierarchy-classical-ml-algorithms]] (training ML), [[attention-mechanism-deepdive]] (Transformer — butuh GPU), [[llm-finetuning-toolchain]] (fine-tuning LLM — GPU-intensive), [[production-model-serving-optimization]] (inference optimization — GPU serving), dan [[adversarial-machine-learning]] (adversarial attack compute-heavy). Juga relevan dengan [[military-sigint-deepdive]] (SDR processing GPU-accelerated) dan [[side-channel-analysis]] (GPU timing side-channel).

---

## Daftar Isi

- [[#GPU Architecture]]
- [[#Memory Hierarchy]]
- [[#CUDA Programming Model]]
- [[#Parallel Programming Patterns]]
- [[#GPU untuk ML Training]]
- [[#GPU untuk Non-ML Compute]]
- [[#Platform Comparison]]
- [[#Performance Optimization]]
- [[#Koneksi ke Vault]]

---

## GPU Architecture

### Paradigma: SIMT (Single Instruction, Multiple Threads)

CPU = beberapa core kuat → sequential task
GPU = ribuan core lemah → parallel task (data-parallel)

### Arsitektur NVIDIA (Ampere / Hopper / Blackwell)

| Level                                 | Jumlah                   | Fungsi                                                            |
| ------------------------------------- | ------------------------ | ----------------------------------------------------------------- |
| **GPU**                               | 1                        | Full chip                                                         |
| **GPC** (Graphics Processing Cluster) | 8-12                     | Group SM dengan shared L2 slice                                   |
| **SM** (Streaming Multiprocessor)     | 80-144 (Ampere 3090: 82) | Compute unit — execute warps                                      |
| **CUDA Core**                         | 128 per SM (Ampere)      | FP32/INT32 arithmetic unit                                        |
| **Tensor Core**                       | 4 per SM (4th gen)       | Mixed-precision matrix multiply (FP16, BF16, INT8, FP4)           |
| **Warp**                              | 32 threads               | Execution unit — semua thread di warp execute instruksi yang sama |

### Arsitektur AMD (RDNA3 / CDNA3)

| Level                          | Fungsi                                              |
| ------------------------------ | --------------------------------------------------- |
| **GCD** (Graphics Compute Die) | Setara GPC — compute unit cluster                   |
| **CU** (Compute Unit)          | Setara SM — 64 stream processors + 1 AI accelerator |
| **Stream Processor**           | Setara CUDA Core — FP32/INT32                       |
| **AI Accelerator**             | Setara Tensor Core — matrix multiply                |

### Perbandingan GPU Generasi

| Arsitektur              | SM/CU       | Core/SM | Tensor Core    | Mem BW    | Best For            |
| ----------------------- | ----------- | ------- | -------------- | --------- | ------------------- |
| NVIDIA Ampere (3090)    | 82 SM       | 128     | 4th gen        | 936 GB/s  | Gaming, DL training |
| NVIDIA Hopper (H100)    | 132 SM      | 128     | 5th gen        | 3.35 TB/s | Enterprise training |
| NVIDIA Blackwell (B200) | 160 SM      | 128     | 6th gen        | 8 TB/s    | Frontier AI         |
| AMD CDNA3 (MI300X)      | 304 CU      | 64      | AI accelerator | 5.2 TB/s  | HPC, inference      |
| Intel Ponte Vecchio     | 128 Xe-core | 16 EU   | XMX            | 2 TB/s    | HPC                 |

## Memory Hierarchy

### Level Memory GPU

```
Register (per-thread)        ~256KB/SM         ~0 cycle latency
    ↓
L1/Shared Memory (per-SM)    ~128-256KB/SM     ~10-30 cycles
    ↓
L2 Cache (per-GPC)           ~6-40MB/GPU       ~200 cycles
    ↓
HBM/HBM2/HBM3 (global)       ~24-144GB         ~400-800 cycles
    ↓
CPU Host RAM                 Unlimited         PCIe (~12-64 GB/s)
```

### Shared Memory vs Global Memory

| Aspek     | Shared Memory          | Global Memory          |
| --------- | ---------------------- | ---------------------- |
| Scope     | Per block (SM)         | Seluruh grid           |
| Latency   | ~5-10 cycle            | ~400-800 cycle         |
| Size      | ~48-164 KB/SM          | Up to 80 GB            |
| Coherence | Manual (__syncthreads) | No coherence guarantee |
| Caching   | L1 cache               | L2 cache               |

### Memory Access Pattern (Coalescing)

GPU paling efisien saat thread dalam warp mengakses memory yang contiguous → **coalesced access**

```
✅ Coalesced: thread 0 → addr 0, thread 1 → addr 4, thread 2 → addr 8...
   Satu memory transaction untuk 32 thread

❌ Strided: thread 0 → addr 0, thread 1 → addr 128, thread 2 → addr 256...
   32 memory transaction (sangat lambat)
```

## CUDA Programming Model

### Struktur Program

```cpp
// Kernel definition — runs on GPU
__global__ void vector_add(float *a, float *b, float *c, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        c[idx] = a[idx] + b[idx];
    }
}

// Host code — runs on CPU
int main() {
    dim3 grid(256);    // 256 blocks
    dim3 block(256);   // 256 threads per block

    vector_add<<<grid, block>>>(d_a, d_b, d_c, n);
    cudaDeviceSynchronize();
}
```

### Execution Model

```
Grid → Blocks → Warps → Threads
  │        │        │       │
 1 GPU    N SM   32 thrd  1 thread
```

### Thread Hierarchy

| Level     | Identifier | Typical Size      |
| --------- | ---------- | ----------------- |
| **Grid**  | blockIdx   | 1 - 2^31 blocks   |
| **Block** | threadIdx  | 32 - 1024 threads |
| **Warp**  | (implicit) | 32 threads        |

### Key CUDA Functions

```cpp
cudaMalloc(&d_ptr, size);        // Alokasi GPU memory
cudaMemcpy(d_ptr, h_ptr, size, cudaMemcpyHostToDevice);  // H2D transfer
cudaMemcpy(h_ptr, d_ptr, size, cudaMemcpyDeviceToHost);  // D2H transfer
__syncthreads();                 // Barrier dalam block
__shared__ float cache[256];     // Shared memory
atomicAdd(&counter, 1);          // Atomic operation
```

## Parallel Programming Patterns

### 1. Grid-Stride Loop

```cpp
// Handle arbitrary size dengan fixed grid
__global__ void saxpy(float *x, float *y, float a, int n) {
    for (int i = blockIdx.x * blockDim.x + threadIdx.x;
         i < n;
         i += gridDim.x * blockDim.x) {  // stride = total threads
        y[i] = a * x[i] + y[i];
    }
}
```

### 2. Reduction (Parallel Sum)

```cpp
__global__ void reduce_sum(float *input, float *output, int n) {
    extern __shared__ float sdata[];
    int tid = threadIdx.x;
    int i = blockIdx.x * blockDim.x + tid;

    sdata[tid] = (i < n) ? input[i] : 0;
    __syncthreads();

    // Tree reduction — O(log n) steps
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) sdata[tid] += sdata[tid + s];
        __syncthreads();
    }

    if (tid == 0) output[blockIdx.x] = sdata[0];
}
```

### 3. Tiling (Matrix Multiply)

```cpp
// Gunakan shared memory untuk cache tile
#define TILE_SIZE 32
__global__ void matmul_tiled(float *A, float *B, float *C, int N) {
    __shared__ float As[TILE_SIZE][TILE_SIZE];
    __shared__ float Bs[TILE_SIZE][TILE_SIZE];

    int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    int col = blockIdx.x * TILE_SIZE + threadIdx.x;
    float sum = 0.0f;

    for (int t = 0; t < N / TILE_SIZE; t++) {
        As[threadIdx.y][threadIdx.x] = A[row * N + t * TILE_SIZE + threadIdx.x];
        Bs[threadIdx.y][threadIdx.x] = B[(t * TILE_SIZE + threadIdx.y) * N + col];
        __syncthreads();

        for (int k = 0; k < TILE_SIZE; k++)
            sum += As[threadIdx.y][k] * Bs[k][threadIdx.x];
        __syncthreads();
    }
    C[row * N + col] = sum;
}
```

## GPU untuk ML Training

### Mixed Precision Training (FP16 / BF16 / FP8)

| Precision  | Bits | Mantissa | Exponent | Range  | Accuracy           | Speedup vs FP32 |
| ---------- | ---- | -------- | -------- | ------ | ------------------ | --------------- |
| FP32       | 32   | 23       | 8        | 3.4e38 | 7 decimal digits   | 1x (baseline)   |
| TF32       | 19   | 10       | 8        | 3.4e38 | 3 decimal digits   | ~2x             |
| FP16       | 16   | 10       | 5        | 65504  | 3 decimal digits   | 2-4x            |
| BF16       | 16   | 7        | 8        | 3.4e38 | 2 decimal digits   | 2-4x            |
| FP8 (E4M3) | 8    | 3        | 4        | 448    | ~1 decimal digit   | 8x              |
| FP8 (E5M2) | 8    | 2        | 5        | 57344  | ~0.5 decimal digit | 8x              |

### Tensor Core Usage

Tensor Core = specialized hardware untuk matrix multiply-accumulate (D = A × B + C).
Akses via:

- `cublasGemmEx` — cuBLAS API
- `torch.matmul` — PyTorch otomatis pake Tensor Core kalau precision cocok
- `__hmma_m16n16k16` — inline PTX (low-level)

### Distributed Training

```
Data Parallel: tiap GPU punya model copy penuh, batch dibagi
  → Gradient all-reduce setelah tiap step

Tensor Parallel: 1 layer dibagi ke beberapa GPU
  → Komunikasi setiap forward/backward

Pipeline Parallel: layer dibagi, tiap GPU pegang contiguous layers
  → Micro-batching untuk overlap compute + communication
```

### Framework Comparison

| Framework         | CUDA Support | ROCm Support | Mixed Precision    | Distributed      | Best For              |
| ----------------- | ------------ | ------------ | ------------------ | ---------------- | --------------------- |
| PyTorch           | ✅ Native    | ✅ 5.7+      | ✅ AMP + FSDP      | ✅ DDP/FSDP/HF   | Research, production  |
| TensorFlow        | ✅ Native    | ✅ (limited) | ✅ Mixed precision | ✅ Mirrored + PS | Production pipeline   |
| JAX               | ✅ Native    | ❌ No        | ✅ Native          | ✅ pmap + pjit   | Research, performance |
| MosaicML Composer | ✅           | ❌           | ✅                 | ✅ FSDP          | Training efficiency   |

## GPU untuk Non-ML Compute

| Aplikasi                  | Tool             | GPU Speedup vs CPU | Notes                          |
| ------------------------- | ---------------- | ------------------ | ------------------------------ |
| **Password Cracking**     | hashcat          | 100-1000x          | MD5: ~100 GH/s on RTX 4090     |
| **Signal Processing**     | cuFFT, GNU Radio | 10-100x            | FFT, FIR filter, convolution   |
| **Video Encoding**        | NVENC, FFmpeg    | 10-50x             | H.264/H.265 hardware encoder   |
| **Ray Tracing**           | OptiX, Vulkan RT | Real-time          | Global illumination, caustics  |
| **Scientific Compute**    | cuBLAS, cuSOLVER | 10-100x            | Linear algebra, sparse solvers |
| **Database Acceleration** | HeavyDB, RAPIDS  | 10-50x             | SQL query GPU-accelerated      |
| **Genomics**              | GATK, Parabricks | 10-50x             | DNA sequencing alignment       |

## Platform Comparison

| Aspek                  | NVIDIA CUDA            | AMD ROCm                     | Intel oneAPI     | Apple Metal            |
| ---------------------- | ---------------------- | ---------------------------- | ---------------- | ---------------------- |
| **Hardware**           | GeForce, Quadro, Tesla | Radeon, Instinct             | Arc, Flex, Max   | Apple Silicon          |
| **Programming**        | CUDA C++               | HIP C++                      | SYCL, DPC++      | Metal Shading Language |
| **ML Framework**       | PyTorch, TF, JAX       | PyTorch (5.7+), TF (limited) | PyTorch (oneDNN) | CoreML, MPS            |
| **CUDA Compatibility** | ✅ Native              | ⚠️ HIP porting layer         | ❌ No            | ❌ No                  |
| **Ecosystem Maturity** | Sangat matang          | Growing                      | Limited          | Mature for Apple       |
| **Best For**           | ML, HPC, gaming        | HPC, AMD ecosystem           | Intel ecosystem  | Apple ecosystem        |

> **Reality Check:** NVIDIA CUDA adalah standar de facto untuk ML. ROCm growing cepat (MI300X kompetitif) tapi masih ada gap. oneAPI dan Metal terbatas di ekosistem masing-masing.

---

## Koneksi ke Vault

- [[hierarchy-classical-ml-algorithms]] — ML training butuh GPU — fondasi parallel compute
- [[attention-mechanism-deepdive]] — Transformer: GPU adalah satu-satunya cara praktis training
- [[llm-finetuning-toolchain]] — Fine-tuning LLM — GPU memory management
- [[production-model-serving-optimization]] — Inference optimization — quantization, TensorRT, GPU serving
- [[adversarial-machine-learning]] — Adversarial attack & defense — GPU-accelerated compute
- [[computer-vision-deepdive]] — CNN, computer vision — GPU native workload
- [[military-sigint-deepdive]] — SDR signal processing — GPU acceleration memungkinkan real-time FFT
