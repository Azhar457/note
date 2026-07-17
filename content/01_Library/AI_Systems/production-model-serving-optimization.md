---
title: "Production Model Serving & Inference Optimization"
tags:
  - llm
  - serving
  - vllm
  - tgi
  - quantization
  - inference
aliases:
  - "production-model-serving-optimization"
created: "2026-07-16"
updated: "2026-07-16"
status: growing
---

## Daftar Isi

1. [Overview: Gap Train → Serve](#1-overview-gap-train--serve)
2. [Inference Engines](#2-inference-engines)
3. [Quantization](#3-quantization)
4. [KV Cache Optimization](#4-kv-cache-optimization)
5. [Continuous Batching](#5-continuous-batching)
6. [Serving Architecture](#6-serving-architecture)
7. [Hard Sizing & GPU Selection](#7-hard-sizing--gpu-selection)
8. [Benchmarking & Monitoring](#8-benchmarking--monitoring)

---

## 1. Overview: Gap Train → Serve

Vault punya `llm-finetuning-toolchain.md` yang detail dari LoRA sampai RLHF. Tapi fine-tuning cuma setengah perjalanan — model yang udah di-tune harus **di-serve** biar bisa dipakai. Gap-nya:

| Fase         | Tool                               | Tantangan                         |
| ------------ | ---------------------------------- | --------------------------------- |
| **Train**    | PyTorch, FSDP, DeepSpeed, Axolotl  | Throughput training, memory GPU   |
| **Export**   | safetensors, GGUF, ONNX, TensorRT  | Format conversion, loss precision |
| **Serve**    | vLLM, TGI, TensorRT-LLM, llama.cpp | **Latency, throughput, memory**   |
| **Optimize** | Quantization, KV cache, batching   | Tradeoff quality vs speed         |

**Target serving:** throughput tinggi (requests/detik), latency rendah (TTFT, TPOT), memory efisien (muat di GPU terbatas).

---

## 2. Inference Engines

### 2.1 vLLM

**Paling populer 2024-2026.** Dibuat oleh UC Berkeley, sekarang di-production oleh banyak perusahaan.

**Core innovation — PagedAttention:**

- **Problem:** KV cache di model standard dialokasikan secara contiguous — external fragmentation & wasted memory
- **Solution:** PagedAttention — KV cache di-split jadi blocks (pages) seperti virtual memory OS
- **Hasil:** memory utilization >95% (vs ~60% standard), throughput naik 2-4×

```python
# vLLM — simplest production setup
from vllm import LLM, SamplingParams

llm = LLM(
    model="mistralai/Mistral-7B-Instruct-v0.3",
    tensor_parallel_size=1,          # 1 GPU
    max_model_len=8192,              # max context window
    dtype="auto",                     # FP16 default
    gpu_memory_utilization=0.90,     # sisa buat KV cache
    enable_chunked_prefetch=True,    # prefetch optimize
)

sampling_params = SamplingParams(
    temperature=0.3,
    top_p=0.9,
    max_tokens=1024,
    stop=["</s>", "User:"],
)

output = llm.generate(["ceritakan tentang RAG"], sampling_params)
```

**Kelebihan:**

- ✅ PagedAttention — memory efisien
- ✅ Continuous batching — tidak perlu nunggu batch penuh
- ✅ Prefix caching — kalau prompt sama, shared KV cache
- ✅ OpenAI-compatible API — drop-in replacement
- ✅ FP8 support di Hopper GPU
- ✅ **Best all-rounder untuk production**

### 2.2 TGI (Text Generation Inference) — HuggingFace

Dibuat oleh HuggingFace, integrasi langsung dengan HF ecosystem.

```bash
# TGI — Docker deployment
docker run -d --gpus all \
  -p 8080:80 \
  -v /models:/data \
  ghcr.io/huggingface/text-generation-inference:3.0 \
  --model-id meta-llama/Llama-3.1-8B-Instruct \
  --max-total-tokens 8192 \
  --num-shard 1 \
  --quantize awq
```

**Kelebihan:**

- ✅ Integrasi HuggingFace flawless (tokenizer, pipeline, model hub)
- ✅ Messages API native (chat template)
- ✅ Speculative decoding built-in
- ✅ Rust backend — compiled, fast
- ❌ throughput lebih rendah dari vLLM di high concurrency

### 2.3 TensorRT-LLM — NVIDIA

**Paling cepat — tapi paling kompleks.** Optimasi spesifik NVIDIA GPU.

```
Kecepatan: TensorRT-LLM > vLLM > TGI > raw PyTorch
Kompleksitas: raw PyTorch < TGI < vLLM << TensorRT-LLM
```

```python
# TensorRT-LLM — butuh build engine dulu
trtllm-build \
  --model_dir /models/llama-8b \
  --dtype float16 \
  --use_gpt_attention_plugin float16 \
  --use_gemm_plugin float16 \
  --max_batch_size 64 \
  --max_input_len 4096 \
  --max_output_len 1024 \
  --output_dir /engines/llama-8b
```

**Kelebihan:**

- ✅ **Fastest inference** — sampai 3× vLLM di A100
- ✅ In-flight batching
- ✅ PagedAttention (dari vLLM, sudah diadopsi)
- ✅ FP8, INT4, INT8 quantized engine
- ❌ **Build time lama** — 1-2 jam buat engine 70B
- ❌ Vendor lock-in NVIDIA
- ❌ Ops complex — maintain engine versioning

### 2.4 llama.cpp

Untuk CPU / edge / GPU terbatas. Format GGUF.

```bash
# llama.cpp server
./llama-server \
  -m models/mistral-7b-instruct-q4_k_m.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --n-gpu-layers 32 \
  -c 4096 \
  --no-mmap
```

**Kelebihan:**

- ✅ **CPU inference feasible** — dengan quantization
- ✅ Ukuran model kecil (7B Q4 = ~4GB)
- ✅ Portable — satu binary cross-platform
- ✅ Metal API untuk Apple Silicon
- ❌ Throughput rendah buat production tinggi
- ❌ Gak ada continuous batching (sampai versi terbaru mulai ada)

### Perbandingan Engine

| Engine           | Throughput | Latency    | Memory     | Setup | Best For               |
| ---------------- | ---------- | ---------- | ---------- | ----- | ---------------------- |
| **vLLM**         | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐ | Mudah | **Default production** |
| **TGI**          | ⭐⭐⭐     | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | Mudah | HF ecosystem           |
| **TensorRT-LLM** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Sulit | NVIDIA-only, max perf  |
| **llama.cpp**    | ⭐⭐       | ⭐⭐⭐     | ⭐⭐⭐⭐⭐ | Mudah | Edge, CPU, personal    |

---

## 3. Quantization

Quantization = representasi weight dengan bit lebih rendah. Tujuan: model lebih kecil, inference lebih cepat.

### 3.1 Level Quantization

| Type           | Bits | Size 7B | Size 70B | Quality Loss | Speedup  |
| -------------- | ---- | ------- | -------- | ------------ | -------- |
| **FP16**       | 16   | 14 GB   | 140 GB   | Baseline     | 1×       |
| **INT8**       | 8    | 7 GB    | 70 GB    | Minimal      | 1.2-1.5× |
| **INT4**       | 4    | 3.5 GB  | 35 GB    | Sedikit      | 1.5-2×   |
| **INT3 / NF3** | 3    | 2.6 GB  | 26 GB    | Moderate     | 2-3×     |
| **INT2**       | 2    | 1.8 GB  | 18 GB    | Signifikan   | 3-4×     |

### 3.2 Teknik Quantization

#### GPTQ — Weight-only quantization

- **Post-training:** butuh calibration dataset (sekitar 128 samples)
- **Metode:** Optimal Brain Quantization — cari quantization yang minim error per weight
- **Format:** `.gptq` (tapi sering disimpan sebagai safetensors biasa)
- **Use case:** GPU production — weight di-quant, activations tetap FP16

```bash
# GPTQ quantization dengan auto-gptq
from auto_gptq import AutoGPTQForCausalLM

model = AutoGPTQForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B",
    quantize_config=BaseQuantizeConfig(
        bits=4,
        group_size=128,     # kelompok weight per 128
        damp_percent=0.01,  # dampening
    )
)
```

#### AWQ — Activation-Aware Weight Quantization

- **Lebih baik dari GPTQ** — aware bahwa weight tertentu lebih penting dari yang lain
- **Metode:** scale up weight yang penting (aktifasi tinggi), scale down yang lain
- **Hasil:** quality lebih tinggi dari GPTQ di bit yang sama
- **Diadopsi oleh:** vLLM, TGI, TensorRT-LLM

```python
# vLLM + AWQ — 2 baris
llm = LLM(
    model="casperhansen/llama-3.1-8b-instruct-awq",
    quantization="awq",  # otomatis pake AWQ
    dtype="auto",
)
```

#### GGUF — llama.cpp format

- **Kuantisasi weight + sebagian aktivasi**
- **Metode:** Q2_K, Q3_K, Q4_K_M, Q5_K_M, Q6_K, Q8_0 — varian quality/size tradeoff
- **K_K_M:** recommended — K-quant dengan half-integer representation
- **Use case:** CPU / Apple Silicon / edge

```
Q4_K_M = sweet spot: ~4.5 bit effective, quality hampir sama FP16
Q2_K   = sangat kecil, cocok buat 70B di 16GB RAM
Q8_0   = hampir lossless, tapi size masih 8GB buat 7B
```

### Tradeoff Guide

```
Priority quality:  FP16 > INT8 > Q8_0 > Q6_K > AWQ-4 > GPTQ-4 > Q4_K_M > Q3_K > Q2_K
Priority speed:    Q2_K > Q4_K_M > GPTQ-4 > AWQ-4 > Q6_K > Q8_0 > INT8 > FP16
Priority size:     Q2_K (1.8GB 7B) > Q3_K > Q4_K_M > INT4 > Q6_K > INT8 > Q8_0 > FP16
```

**Rekomendasi pragmatic:**

- **GPU ≥ 24GB:** FP16 atau AWQ-4 (vLLM)
- **GPU 8-12GB:** AWQ-4 atau Q4_K_M (llama.cpp)
- **CPU only:** Q4_K_M atau Q5_K_M (llama.cpp)
- **Production API dengan GPU:** AWQ-4 via vLLM — kualitas tinggi, throughput gede

---

## 4. KV Cache Optimization

### 4.1 Kenapa KV Cache Jadi Bottleneck

Di inference autoregressive, tiap token baru butuh KV cache dari semua token sebelumnya:

```
Memory KV cache = 2 × n_layers × n_heads × d_head × n_tokens × precision_bytes × batch_size

LLaMA-3.1 70B, FP16, 32K context, batch=1:
  2 × 80 × 64 × 128 × 32768 × 2 × 1 ≈ 80 GB  ← satu request!
```

### 4.2 Strategi Optimasi

| Teknik                    | Penghematan                        | Implementasi                       |
| ------------------------- | ---------------------------------- | ---------------------------------- |
| **PagedAttention**        | ~40%                               | vLLM (built-in)                    |
| **KV cache quantization** | 50% (FP16→INT8)                    | vLLM, TensorRT-LLM                 |
| **Prefix caching**        | 30-80% (bergantung prompt overlap) | vLLM (enable_prefix_caching=True)  |
| **Sliding window**        | Variable                           | Mistral, TGI                       |
| **Multi-Query Attention** | ~80% (vs MHA)                      | Ada di model (LLaMA-2 70B, Falcon) |
| **MLA (DeepSeek)**        | 75-90%                             | Hanya DeepSeek                     |
| **Sparsity / eviction**   | ~50%                               | Riset — H2O, StreamingLLM          |

### 4.3 Implementasi di vLLM

```python
# vLLM — konfigurasi KV cache
llm = LLM(
    model="meta-llama/Llama-3.1-8B-Instruct",

    # PagedAttention block size
    block_size=16,                    # default; 16 biasanya optimal

    # KV cache quantization (vLLM ≥ 0.6)
    kv_cache_dtype="fp8_e5m2",        # FP8 KV cache — 50% less memory

    # Prefix caching
    enable_prefix_caching=True,       # cache prompt yang sama (chat template)

    # Max model length
    max_model_len=32768,              # limit biar KV cache gak overcommit

    # Memory budget
    gpu_memory_utilization=0.85,      # sisakan 15% untuk activations + overhead
)
```

### 4.4 Prefix Caching — Use Case

Cocok kalau banyak request dengan prefix sama:

- **Chat template system prompt:** sama untuk semua user
- **RAG prefix:** "Jawab berdasarkan konteks berikut: ..."
- **Few-shot prompts:** contoh-contoh di awal

```python
# vLLM automatic prefix caching
# Request 1: [system prompt + "siapa presiden Indonesia?"] → cache bagian system prompt
# Request 2: [system prompt + "apa ibu kota Jepang?"] → reuse cache!
```

---

## 5. Continuous Batching

### 5.1 Static Batching vs Continuous Batching

**Static batching (traditional):**

- Kumpulin N request → jalankan bersama → selesai semua → return
- **Waste:** request cepat nunggu yang lambat
- **Memory waste:** padding tokens

**Continuous batching (vLLM, TGI, TRT-LLM):**

- Tiap request masuk langsung diproses
- Request yang selesai duluan langsung return — gak nunggu yang lain
- Iteration-level scheduling: tiap langkah decoding, scheduler atur mana request yang lanjut

```
Static:  |AAAAAA|BBBBBBBB|CCCC|  → nunggu batch selesai
Dynamic: |A|B|C|A|B|A|B|A|B|A|B|C| → request cepat selesai duluan
```

### 5.2 Throughput Gain

| Batch Size | Static (req/s) | Continuous (req/s) | Gain |
| ---------- | -------------- | ------------------ | ---- |
| 1          | 10             | 10                 | 1×   |
| 8          | 25             | 45                 | 1.8× |
| 32         | 40             | 120                | 3×   |
| 128        | 50             | 250                | 5×   |

Continuous batching scaling hampir linear dengan batch size — selama GPU memory cukup.

---

## 6. Serving Architecture

### 6.1 Single GPU — Small Scale

```yaml
# docker-compose.yml — 1 GPU, 1 model
version: "3.8"
services:
  vllm:
    image: vllm/vllm-openai:latest
    command:
      - "--model"
      - "meta-llama/Llama-3.1-8B-Instruct"
      - "--quantization"
      - "awq"
      - "--max-model-len"
      - "8192"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--enable-prefix-caching"
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
```

### 6.2 Multi-GPU — Tensor Parallel

```python
# vLLM — tensor parallel = shard model across GPUs
llm = LLM(
    model="mistralai/Mixtral-8x22B-Instruct",  # 141B MoE
    tensor_parallel_size=4,      # 4 × A100 80GB
    pipeline_parallel_size=1,    # pipeline = 1 karena TP cukup
    max_model_len=16384,
)
```

### 6.3 Multi-Node — untuk 70B+

```bash
# Tensor parallel across nodes (vLLM)
# Node 1:
vllm serve meta-llama/Llama-3.1-70B-Instruct \
  --tensor-parallel-size 8 \
  --distributed-executor-backend ray \
  --ray-address <ray-head>:6379

# Node 2-4: join ray cluster, vLLM handle sisanya
```

### 6.4 Inference Router — Multiple Models

```python
from openai import AsyncOpenAI
import aiohttp

class InferenceRouter:
    """Route requests to model berdasarkan task complexity."""

    def __init__(self):
        self.fast_client = AsyncOpenAI(base_url="http://vllm-sm:8000/v1")
        self.strong_client = AsyncOpenAI(base_url="http://vllm-70b:8000/v1")

    async def generate(self, prompt: str, complexity: str = "auto"):
        if complexity == "auto":
            # Simple heuristic: short prompt + simple task → small model
            if len(prompt) < 500 and not self.is_complex(prompt):
                return await self.fast_client.chat.completions.create(...)
            else:
                return await self.strong_client.chat.completions.create(...)

        return await {
            "fast": self.fast_client,
            "strong": self.strong_client,
        }[complexity].chat.completions.create(...)
```

---

## 7. Hard Sizing & GPU Selection

### 7.1 Model Size → GPU Requirement

| Model                       | FP16   | AWQ-4 | Q4_K_M | GPU Minimum          |
| --------------------------- | ------ | ----- | ------ | -------------------- |
| **1.5B** (Qwen2.5)          | 3 GB   | 1 GB  | 1.2 GB | RTX 3060 / M1        |
| **7-8B** (LLaMA-3, Mistral) | 14 GB  | 4 GB  | 4.5 GB | RTX 3090 / A10       |
| **13B**                     | 26 GB  | 7 GB  | 8 GB   | A100 40GB / 2×3090   |
| **30B**                     | 60 GB  | 16 GB | 18 GB  | A100 80GB / 2×A10    |
| **70B**                     | 140 GB | 35 GB | 40 GB  | 2×A100 80GB / 8×3090 |
| **120B+** (Mixtral 8x22B)   | 240 GB | 60 GB | 70 GB  | 4×A100 / H100        |

**Formula:**

```
VRAM needed = model_size (billions) × bytes_per_param + KV_cache + overhead

FP16:  params × 2 bytes + context × layers × heads × d_head × 2
AWQ:   params × 0.5 bytes + KV_cache (sama tapi weights lebih kecil)
Overhead: ~10-15%
```

### 7.2 GPU Cost Efficiency

| GPU           | VRAM  | Harga          | Cocok Untuk                         |
| ------------- | ----- | -------------- | ----------------------------------- |
| **RTX 3090**  | 24 GB | ~$700 (used)   | **Best value** — 7-8B FP16, 13B AWQ |
| **RTX 4090**  | 24 GB | ~$1600         | Sama 3090 tapi 2× lebih cepat       |
| **A10**       | 24 GB | ~$2500 (cloud) | Enterprise, 7-8B reliable           |
| **A100 80GB** | 80 GB | ~$15000        | 70B AWQ, multi-model                |
| **H100**      | 80 GB | ~$30000        | **Best** — FP8 support, 2.5× A100   |
| **L40S**      | 48 GB | ~$10000        | Mid-range, 70B INT4                 |

**Paling cost-efficient buat production 2024-2026:**

- **7B model:** 1× RTX 3090 (24GB) — AWQ quantization → 500+ req/s
- **70B model:** 2× A100 80GB — TP2, AWQ → 100+ req/s
- **Budget:** RunPod / Vast.ai sewa GPU per jam

---

## 8. Benchmarking & Monitoring

### 8.1 Metrics Penting

| Metric           | Arti                  | Target                       |
| ---------------- | --------------------- | ---------------------------- |
| **TTFT**         | Time to First Token   | < 500ms                      |
| **TPOT**         | Time per Output Token | < 30ms/token                 |
| **Throughput**   | Requests per second   | > 10 (7B), > 1 (70B)         |
| **ITL**          | Inter-token Latency   | < 50ms                       |
| **Decode speed** | Tokens per second     | > 50 tok/s (user perception) |

### 8.2 Benchmark Tool

```bash
# Benchmark vLLM
python -m vllm.benchmarks.benchmark_serving \
  --model meta-llama/Llama-3.1-8B-Instruct \
  --dataset ShareGPT \
  --num-prompts 500 \
  --request-rate 10 \
  --port 8000

# Output:
# Request rate: 10.0 req/s
# TTFT (P99): 342ms
# TPOT (P50): 18.5ms
# Throughput: 9.8 req/s
# Output tokens/s: 452.3
```

### 8.3 Production Monitoring

```python
# Prometheus metrics dari vLLM
# vLLM expose metrics di /metrics endpoint

METRICS = {
    "vllm:num_requests_running": "Current inflight",
    "vllm:num_requests_waiting": "Queued requests",
    "vllm:gpu_cache_usage": "KV cache usage (%)",
    "vllm:avg_prompt_throughput": "Prompt tokens/s",
    "vllm:avg_generation_throughput": "Generation tokens/s",
    "vllm:time_to_first_token_seconds": "TTFT histogram",
    "vllm:time_per_output_token_seconds": "TPOT histogram",
}
```

**Alert rules:**

```yaml
# prometheus-rules.yml
groups:
  - name: inference
    rules:
      - alert: HighTTFT
        expr: histogram_quantile(0.95, vllm_time_to_first_token_seconds) > 1
        for: 5m
        annotations:
          summary: "TTFT > 1s — model overloaded or GPU throttling"

      - alert: GPUOOM
        expr: vllm_gpu_cache_usage > 0.95
        for: 2m
        annotations:
          summary: "KV cache nearly full — scale or reduce concurrency"

      - alert: ThroughputDrop
        expr: rate(vllm_avg_generation_throughput[5m]) < 100
        for: 10m
        annotations:
          summary: "Generation throughput dropped below 100 tok/s"
```

---

## Referensi

- [[llm-finetuning-toolchain]] — Fine-tuning sebelum serving
- [[advanced-ai-algorithms-breakthroughs]] — Flash Attention, MLA (bagian 1 & 2)
- [[vector-database-internals-optimization]] — Analogi indexing untuk serving optimization
- [vLLM Docs](https://docs.vllm.ai)
- [TGI Docs](https://huggingface.co/docs/text-generation-inference)
- [TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM)
- [AWQ Paper](https://arxiv.org/abs/2306.00978)
- [PagedAttention Paper](https://arxiv.org/abs/2309.06180)
- [LLM Inference Performance Guide](https://www.anyscale.com/blog/llm-inference-performance-engineering-best-practices)

---

_Dibuat: 16 Juli 2026 — Panduan serving model LLM dari engine selection sampai monitoring._
