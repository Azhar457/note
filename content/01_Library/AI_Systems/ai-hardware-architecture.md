---
title: 'AI Hardware — Deep Dive: NPU, TPU, GPU, ASIC, In-Memory Computing, AI Accelerator
  Architecture'
tags:
- ai-hardware
- npu
- tpu
- accelerator
- ml-infrastructure
- hardware
created: '2026-07-18'
updated: '2026-07-18'
status: pending
cssclasses:
- wide-table
---

# 🔩 AI Hardware — Deep Dive: NPU, TPU, GPU, ASIC, In-Memory Computing, AI Accelerator Architecture

> Panduan komprehensif hardware khusus AI — dari GPU general-purpose sampai ASIC dedicated. Mencakup NPU (Neural Processing Unit) di mobile SoC (Apple Neural Engine, Qualcomm Hexagon, Samsung NPU, MediaTek APU), TPU (Tensor Processing Unit) Google untuk training & inference, GPU sebagai AI accelerator (NVIDIA H100/B200, AMD MI300X), ASIC custom (Cerebras Wafer-Scale, Groq, SambaNova, Tenstorrent), in-memory computing (memristor, ReRAM, PIM), dan metrik perbandingan (TOPS, TFLOPS, TOPS/W, latency, throughput). Vault udah punya [[gpu-programming-parallel-compute]] (CUDA/ROCm programming) dan [[embedded-systems]] (IoT hardware) — catatan ini melengkapi dari sisi AI accelerator silicon.

> [!info] Posisi di Vault
> Catatan ini terkait dengan [[gpu-programming-parallel-compute]] (GPU arsitektur & programming — GPU adalah AI accelerator paling umum), [[production-model-serving-optimization]] (inference optimization di berbagai hardware), [[edge-computing-iot-security-architecture]] (NPU di edge device), [[computer-vision-deepdive]] (computer vision di embedded NPU), [[embedded-systems]] (SoC architecture), dan [[platform-technologies-overview]] (teknologi platform berkinerja tinggi).

---

## Daftar Isi

- [[#Taxonomy AI Accelerator]]
- [[#GPU untuk AI]]
- [[#TPU — Tensor Processing Unit (Google)]]
- [[#NPU — Neural Processing Unit (Mobile/Edge)]]
- [[#ASIC Custom — Cerebras, Groq, SambaNova]]
- [[#In-Memory Computing]]
- [[#Metrik Perbandingan]]
- [[#Choosing Hardware]]
- [[#Koneksi ke Vault]]

---

## Taxonomy AI Accelerator

```
                    AI Accelerator
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
      GPU              NPU              ASIC
  (NVIDIA, AMD)   (Apple, Qualcomm)  (Google, Cerebras)
        │                 │                 │
   ┌────┴────┐      ┌─────┴────┐      ┌─────┴────┐
Training  Inference  Mobile     Edge   Training  Inference
(H100)    (T4/L4)    (ANE)     (NPU)   (TPUv5)   (Edge TPU)
```

### Perbedaan Fundamental

| Aspek | GPU | NPU | TPU | ASIC Custom |
|-------|-----|-----|-----|-------------|
| **Tujuan** | General-purpose parallel compute | AI inference di mobile/edge | AI training & inference (Google) | AI-specific (satu arsitektur) |
| **Flexibility** | Tinggi (CUDA, ROCm, any workload) | Rendah (fixed function AI ops) | Sedang (XLA-compiled models) | Sangat rendah (model-specific) |
| **Programming** | CUDA, ROCm, PyTorch, TF | Vendor SDK (CoreML, QNN) | XLA (JAX, TF) | Custom SDK |
| **Power** | 300-700W | 0.5-15W | 200-450W | 15-15000W (wafer-scale) |
| **Best For** | Datacenter training | On-device inference | Google-scale training | Niche high-performance |

## GPU untuk AI

### Generasi GPU AI

| GPU | Arsitektur | FP32 TFLOPS | FP16 TFLOPS | INT8 TOPS | Memory | Harga |
|-----|-----------|------------|-------------|-----------|--------|-------|
| **NVIDIA H100 SXM** | Hopper | 67 | 1,979 (sparse) | 3,958 | 80GB HBM3 | ~$30K |
| **NVIDIA B200** | Blackwell | 90 | 4,500 (sparse) | 9,000 | 192GB HBM3e | ~$50K |
| **NVIDIA A100** | Ampere | 19.5 | 312 (sparse) | 624 | 80GB HBM2e | ~$15K |
| **AMD MI300X** | CDNA3 | 81 | 1,307 | 2,614 | 192GB HBM3 | ~$15K |
| **NVIDIA RTX 4090** | Ada Lovelace | 82 | 165 | 330 | 24GB GDDR6X | ~$1.6K |
| **NVIDIA RTX 6000 Ada** | Ada Lovelace | 91 | 182 | 364 | 48GB GDDR6 | ~$6.8K |

### GPU untuk Training vs Inference

| Aspek | Training GPU | Inference GPU |
|-------|-------------|---------------|
| **Prioritas** | Throughput (TFLOPS) | Latency (ms) |
| **Memory** | Besar (80GB+) | Medium (16-48GB) |
| **Precision** | FP16/BF16/FP8 | INT8/FP8/FP4 |
| **Batch Size** | Besar (256-4096) | Kecil (1-32) |
| **Contoh** | H100, A100, MI300X | L4, T4, RTX 4090 |
| **Kuantitas** | Beberapa (4-256) | Banyak (100+) |

## TPU — Tensor Processing Unit (Google)

### Generasi TPU

| Generasi | Tahun | Compute | Memory | Interconnect | Use Case |
|----------|-------|---------|--------|-------------|----------|
| **TPUv1** | 2015 | 92 TOPS (INT8) | 8MB SRAM | — | Inference only |
| **TPUv2** | 2017 | 45 TFLOPS (BF16) | 16GB HBM | 2D torus | Training + inference |
| **TPUv3** | 2018 | 123 TFLOPS (BF16) | 32GB HBM | 2D torus 2x | Training |
| **TPUv4** | 2021 | 275 TFLOPS (BF16) | ~48GB HBM | SparseOCS | Training (Poda) |
| **TPUv5e** | 2023 | 196 TFLOPS (BF16) | ~64GB HBM | — | Cost-efficient |
| **TPUv5p** | 2023 | 459 TFLOPS (BF16) | ~96GB HBM | 2D torus | Training flagship |
| **Edge TPU** | 2019 | 4 TOPS (INT8) | 8MB SRAM | USB/PCIe | Edge inference |

### Arsitektur TPU
```
MXU (Matrix Multiply Unit) — systolic array 128x128
  → Satu instruksi = satu matmul 128x128
  → Didesain untuk matmul-dominated workload (Transformer)

HBM Memory — ~900 GB/s bandwidth (TPUv3)
  → Cukup untuk men-stream weight + activation

Interconnect — 2D Torus (TPUv2+)
  → All-reduce gradient tanpa bottleneck network
```

### Kenapa TPU Cepat untuk ML?
1. **Systolic array** — compute matmul tanpa fetch instruksi tiap siklus
2. **BF16 native** — tanpa konversi FP32→FP16 overhead
3. **2D torus interconnect** — all-reduce secepat intra-chip bandwidth
4. **XLA compiler** — optimasi graph level TPU

## NPU — Neural Processing Unit (Mobile/Edge)

### NPU di Mobile

| SoC | NPU | TOPS | Process | Fitur AI |
|-----|-----|------|---------|----------|
| **Apple A18 Pro** | Neural Engine 18-core | ~38 TOPS | 3nm | On-device LLM, image processing |
| **Apple M4** | Neural Engine 18-core | ~38 TOPS | 3nm | Mac AI, local model |
| **Qualcomm Snapdragon 8 Gen 3** | Hexagon NPU | ~45 TOPS | 4nm | On-device gen AI |
| **Samsung Exynos 2400** | NPU | ~12 TOPS | 4nm | Galaxy AI features |
| **MediaTek Dimensity 9300** | APU 790 | ~33 TOPS | 4nm | Edge LLM |
| **Google Tensor G4** | TPU (Edge) | ~10 TOPS | 4nm | Pixel AI features |

### NPU vs GPU di Mobile

| Aspek | NPU | GPU (Mobile) |
|-------|-----|--------------|
| **Power Efficiency** | Sangat tinggi (0.5-3W) | Sedang (3-10W) |
| **Throughput** | Tinggi untuk fixed ops | Tinggi tapi boros |
| **Flexibility** | Fixed function (conv, matmul, activation) | Programmable (any compute) |
| **Use Case** | Always-on AI (camera, voice, translate) | Gaming, rendering, compute |
| **Programming** | CoreML, QNN, TFLite Delegate | Metal/Vulkan, OpenCL |

### Edge NPU (Standalone)

| Chip | TOPS | Power | Interface | Use Case |
|------|------|-------|-----------|----------|
| **Google Edge TPU** (Coral) | 4 | 2W | USB/PCIe | Vision, ML inference |
| **Intel Movidius** | 1 | 1W | USB | Vision inference |
| **Hailo-8** | 26 | 2.5W | M.2/PCIe | Edge real-time AI |
| **NVIDIA Jetson Orin NX** | 70 (GPU+DLAs) | 15-25W | Module | Edge autonomous |
| **Rockchip NPU** (RK3588) | 6 | <5W | SoC integrated | Embedded AI |

## ASIC Custom — Cerebras, Groq, SambaNova

### Cerebras Wafer-Scale Engine (WSE-3)

| Spesifikasi | Value |
|------------|-------|
| **Transistors** | 4 trillion |
| **Cores** | 900,000 |
| **On-chip SRAM** | 44 GB |
| **Fabric Bandwidth** | 214 Petabits/s |
| **Process** | 5nm |
| **Power** | ~15,000W |

**Keunggulan:** Eliminasi komunikasi inter-chip. Satu wafer = satu chip. Training model besar tanpa pipeline/tensor parallelism.

### Groq LPU (Language Processing Unit)

| Spesifikasi | Value |
|------------|-------|
| **Architecture** | Tensor Streaming Processor |
| **Memory** | SRAM-only (230MB/chip) — no HBM |
| **Latency** | < 1ms per token (LLM inference) |
| **Throughput** | ~500 tok/s per chip (Llama 2 70B) |
| **Best For** | Inference latency-critical |

**Keunggulan:** Arsitektur deterministic — tidak ada cache miss, tidak ada memory bottleneck. Predictable latency.

### SambaNova SN40L

| Spesifikasi | Value |
|------------|-------|
| **Architecture** | Reconfigurable Dataflow Unit (RDU) |
| **Memory** | 64MB on-chip SRAM + 64GB HBM |
| **Precision** | Custom mixed-precision |
| **Best For** | Training + inference (model-specific optimization) |

## In-Memory Computing

### Von Neumann Bottleneck
```
Memory (HBM/DRAM) ↔️ Compute (ALU) — bus terbatas (1-2 TB/s)
CPU/GPU idle saat nunggu data dari memory
```

### In-Memory Architecture
```
Compute terjadi di memory cell — tanpa data movement
```

### Teknologi

| Teknologi | Status | Kecepatan vs HBM | Density | Maturity |
|-----------|--------|-----------------|---------|----------|
| **ReRAM** (Resistive RAM) | Prototipe | 10-100x | 4x | Low — masih lab |
| **PIM** (Processing-in-Memory) | Samsung HBM-PIM | 2x | Sama | Medium — Samsung product |
| **CXL Memory Pooling** | Production | 1-2x | N/A | High — datacenter |
| **Near-Memory Compute** | Production (H100) | 1.5x | N/A | High — GPU + HBM |

### PIM (Processing-in-Memory) Samsung
- Menambahkan ALU di dekat bank memory HBM
- Eliminasi data movement antara HBM dan compute die
- ~2x performance boost untuk bandwidth-bound workload
- Kompatibel dengan existing GPU (driver update)

## Metrik Perbandingan

| Metrik | Arti | Penting Untuk |
|--------|------|---------------|
| **TFLOPS** | Floating-point operations per second | Training (FP16/BF16) |
| **TOPS** | Integer operations per second | Inference (INT8) |
| **Memory Bandwidth** | GB/s — data movement speed | Memory-bound workload |
| **Memory Capacity** | GB — max model size | Model fit check |
| **Interconnect** | Chip-to-chip bandwidth (NVLink, CXL) | Distributed training |
| **TOPS/W** | Performance per watt | Edge, mobile, cost |
| **Latency p50/p99** | Time per inference | Production serving |
| **Thermal Design Power** | Heat dissipation | Cooling cost, form factor |

### Rule of Thumb

| Task | Minimum | Recommended | Optimal |
|------|---------|-------------|---------|
| **LLM Training (7B)** | 4x A100 80GB | 8x A100 80GB | 64x H100 |
| **LLM Training (70B)** | 16x H100 | 64x H100 | 256x H100+ |
| **LLM Inference (7B)** | 1x RTX 4090 | 1x L40S | 4x L40S (redundancy) |
| **LLM Inference (70B)** | 1x H100 (INT8) | 2x H100 (FP8) | 8x H100 (FP16) |
| **Vision (CNN)** | 1x RTX 3060 | 1x RTX 4090 | 4x A100 |
| **Mobile Inference** | NPU 10+ TOPS | NPU 20+ TOPS | NPU 40+ TOPS |

---

## Koneksi ke Vault

- [[gpu-programming-parallel-compute]] — GPU arsitektur & programming — AI accelerator paling umum
- [[production-model-serving-optimization]] — Inference optimization: quantization, TensorRT, hardware-aware serving
- [[edge-computing-iot-security-architecture]] — Edge AI — NPU untuk on-device inference
- [[computer-vision-deepdive]] — Computer vision di embedded NPU (Jetson, Coral, Rockchip)
- [[embedded-systems]] — SoC architecture — NPU sebagai IP core dalam SoC
- [[platform-technologies-overview]] — Teknologi platform: CXL, DPU, RISC-V
- [[hierarchy-classical-ml-algorithms]] — ML model — hardware menentukan feasibility training