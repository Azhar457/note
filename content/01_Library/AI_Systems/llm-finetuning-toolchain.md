---
title: "LLM Fine-Tuning Toolchain"
tags:
  - ai-systems
  - library
aliases:
  - "llm-finetuning-toolchain"
created: "2026-07-05"
updated: "2026-07-06"
status: evergreen
author: "Hermes Agent → Azhar"
---

# LLM Fine-Tuning Toolchain

## 1. Ekosistem Fine-Tuning (4 Layer)

Ada 4 layer dalam toolchain fine-tuning — masing-masing beda fungsi, gak saling ganti, bisa dipake bareng.

```
┌──────────────────────────────────────┐
│         LLaMA-Factory                │ ← Framework (wrapper)
│  CLI + WebUI + API + Dataset mgmt    │
├──────────────────────────────────────┤
│    Unsloth      │    DeepSpeed       │ ← Optimizer + Engine
│  (kernel CUDA)  │  (distributed)     │
├──────────────────────────────────────┤
│          PEFT (LoRA / QLoRA)         │ ← Method
├──────────────────────────────────────┤
│     Base Model (Llama, Qwen, dll)    │ ← Yang dilatih
└──────────────────────────────────────┘
```

### 1A. PEFT — Parameter-Efficient Fine-Tuning

**Apa:** Library HuggingFace. Berisi implementasi LoRA, QLoRA, IA³, AdaLoRA, Prefix Tuning.

**Cara kerja:**

- Bekukan 99%+ bobot model asli (fp16/bf16)
- Sisipkan adapter `A × B` kecil di layer attention
- Training cuma update adapter itu — parameter jauh lebih sedikit

**Rumus:** `Output = W·x + (B·A)·x`

**LoRA rank (r):**

| r   | Parameter baru | VRAM tambahan (7B) | Kapan                       |
| --- | -------------- | ------------------ | --------------------------- |
| 8   | ~0.25%         | ~200MB             | Task sederhana, klasifikasi |
| 16  | ~0.5%          | ~400MB             | **Default** — most tasks    |
| 32  | ~1%            | ~800MB             | Creative, coding, nuanced   |
| 64  | ~2%            | ~1.6GB             | Full task adaptation        |

**QLoRA:** LoRA + 4-bit NormalFloat quantization. Load model di 4-bit, adapter tetap fp16. Hemat VRAM ~4x.

```bash
pip install peft bitsandbytes transformers accelerate
```

Contoh implementasi PEFT:

```python
from peft import PeftModel, PeftConfig
from transformers import AutoModelForCausalLM, AutoTokenizer

# Load model dan tokenizer
model_name = "qwen2.5-7b"
model = AutoModelForCausalLM.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Buat konfigurasi PEFT
peft_config = PeftConfig(
    adapter_name="lora",
    lora_r=16,
    target_modules=[model.transformer.h],
    initializer="default",
)

# Buat model PEFT
peft_model = PeftModel.from_pretrained(model, peft_config)
```

### 1B. Unsloth — Kernel Optimization

**Apa:** Tulis ulang operasi CUDA pake kernel Triton custom untuk LoRA/QLoRA. **2x lebih cepat, 50% lebih hemat VRAM.**

**Yang dioptimasi:**

- Linear layer tanpa materialisasi weight untuk LoRA
- Attention kernel lebih efisien
- 4-bit NF4 quantization-aware loading

**Keunggulan unik:** Bisa save ke GGUF langsung — hasil fine-tune + merge + export tanpa tool tambahan.

```python
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    "unsloth/Qwen2.5-7B-bnb-4bit",
    load_in_4bit=True,
)
model = FastLanguageModel.get_peft_model(model, r=16)
# ... train ...
model.save_pretrained_gguf("my-model-gguf", tokenizer, quantization_method="q4_k_m")
```

Contoh implementasi Unsloth:

```python
import torch

# Load model Unsloth
model = FastLanguageModel.from_pretrained("unsloth/Qwen2.5-7B-bnb-4bit")

# Training dengan Unsloth
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# ... training code ...
```

### 1C. DeepSpeed — Distributed Engine

**Apa:** Engine training dari Microsoft. Optimasi memori multi-GPU via ZeRO.

| ZeRO | Simpan                  | Hemat VRAM | Minimal GPU |
| :--: | ----------------------- | :--------: | :---------: |
|  1   | Optimizer state terbagi |    ~4x     |      2      |
|  2   | + Gradien terbagi       |    ~8x     |      2      |
|  3   | + Bobot terbagi         |   ~16x+    |      2      |

**ZeRO-Offload:** Pindahin state ke CPU RAM → VRAM gratis, throughput turun.

```bash
deepspeed --num_gpus=4 train.py --deepspeed ds_z3.json
```

Contoh implementasi DeepSpeed:

```python
import deepspeed

# Load model dan tokenizer
model_name = "qwen2.5-7b"
model = AutoModelForCausalLM.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Buat konfigurasi DeepSpeed
deepspeed_config = {
    "train_micro_batch_size_per_gpu": 32,
    "gradient_accumulation_steps": 4,
    "fp16": True,
}

# Buat model DeepSpeed
deepspeed_model = deepspeed.initialize(model, deepspeed_config)
```

### 1D. LLaMA-Factory — All-in-One Framework

**Apa:** Wrapper CLI + WebUI yang nyatuin PEFT + Unsloth + DeepSpeed.

```bash
# Unsloth (1 GPU)
llamafactory-cli train --trainer unsloth --method lora --model Qwen/Qwen2.5-7B

# DeepSpeed (4 GPU)
llamafactory-cli train --trainer deepspeed --deepspeed ds_z3.json --method lora
```

**Install:**

```bash
git clone https://github.com/hiyouga/LLaMA-Factory.git
cd LLaMA-Factory && pip install -e ".[torch,metrics]"
```

## 2. Spek Kentang — Low-End Fine-Tuning

Batas real di tiap VRAM (QLoRA + gradient checkpoint):

| VRAM | Maks model | Waktu training (7B, 1k samples, 1 epoch) |
| :--: | :--------: | :--------------------------------------: |
| 4GB  |    1-3B    |                    —                     |
| 6GB  |     7B     |                  ~2 jam                  |
| 8GB  |   7-14B    |                  ~1 jam                  |
| 12GB |   14-32B   |                ~45 menit                 |
| 24GB |    70B+    |                ~20 menit                 |

### Pipeline Kentang (6-8GB VRAM + 16GB RAM)

```bash
# 1. Install
pip install unsloth peft bitsandbytes transformers

# 2. Train & export
python3 << 'EOF'
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    "unsloth/Qwen2.5-7B-bnb-4bit",
    load_in_4bit=True,
    device_map="auto",
)
model = FastLanguageModel.get_peft_model(model, r=8)
# training code...
model.save_pretrained_gguf("kentang-model", tokenizer, "q4_k_m")
EOF

# 3. Serve via Ollama
ollama create kentang-model -f Modelfile
ollama run kentang-model
```

### Tips Kentang

| Masalah             | Solusi                                               |
| ------------------- | ---------------------------------------------------- |
| OOM (out of memory) | Turunin `r` ke 8, matiin flash-attention, pake QLoRA |
| Training lambat     | Batch size = 1, gradient accumulation = 4            |
| RAM penuh           | Swap file 32GB+, atau DeepSpeed ZeRO-3 offload       |
| Storage             | Simpan cuma GGUF final, hapus checkpoint tengah      |

## 3. Export + Serve Ollama

### Unsloth → GGUF (satu langkah)

```python
model.save_pretrained_gguf("output-dir", tokenizer, "q4_k_m")
```

Level kuantisasi GGUF:

|   Level    | Ukuran (7B) |   Kualitas   |
| :--------: | :---------: | :----------: |
|    q2_k    |   ~2.5GB    |   Lumayan    |
|   q3_k_m   |   ~3.5GB    |      OK      |
| **q4_k_m** | **~4.5GB**  | **Default**  |
|   q5_k_m   |   ~5.5GB    |    Bagus     |
|    q6_k    |   ~6.5GB    | Original (±) |

### Ollama serve

```bash
ollama create my-model -f Modelfile
ollama run my-model
# API: localhost:11434/v1
```

## 4. 9Router — AI Gateway + Load Balancer

**Apa:** Proxy router yang duduk di antara AI CLI tools dan provider AI. Bisa routing ke Ollama lokal, pake FREE provider, auto-fallback.

### Install

```bash
npm install -g 9router
9router
# Dashboard: localhost:20128
```

### Docker

```bash
docker run -d -p 20128:20128 -v 9router-data:/app/data decolua/9router
```

### Hubungin ke Ollama

```bash
mkdir -p ~/.9router
```

```json
{
  "providers": [
    {
      "name": "ollama-local",
      "baseUrl": "http://localhost:11434/v1",
      "apiKey": "ollama",
      "models": {
        "kentang-model": "kentang-model:latest",
        "qwq": "qwq:latest"
      },
      "priority": 1
    }
  ],
  "routing": {
    "default": ["ollama-local", "kiro-free", "opencode-free"]
  }
}
```

### Flow End-to-End

```
Fine-tune (Unsloth QLoRA kentang 6GB)
    ↓ GGUF export
Ollama serve (localhost:11434)
    ↓ daftarin di config
9Router proxy (localhost:20128)
    ↓ panggil model "kentang-model"
Claude Code / Codex / Antigravity / Cline
```

## 5. Integrasi ke Hermes

Di `~/.hermes/config.yaml`:

```yaml
providers:
  nine-router:
    type: openai
    base_url: "http://localhost:20128/v1"
    api_key: "9r_lh_xxx"
    models:
      default: "kentang-model"
      fallback: "kiro/claude-sonnet"
```

Atau pake 9Router sebagai proxy Hermes langsung:

```yaml
providers:
  openai-api:
    base_url: "http://localhost:20128/v1"
    api_key: "9r_lh_xxx"
    models:
      default: "kentang-model"
```

## 6. Anatomi Biaya (Spek Kentang)

| Komponen               | Biaya                    |
| ---------------------- | ------------------------ |
| GPU Cloud (6GB, 1 jam) | ~$0.20 (RunPod, Vast.ai) |
| Colab Pro (T4, 4 jam)  | $10/bulan                |
| Lokal (listrik, 8 jam) | ~$0.50                   |
| Ollama + 9Router       | Gratis                   |

Total fine-tune 7B sekali training: **~$0.20–1.00**. Serve unlimited via Ollama + 9Router: **$0**.

## Hubungan Antar Tools (TL;DR)

| Tool              | Level     | Fungsi                                |
| ----------------- | --------- | ------------------------------------- |
| **PEFT**          | Method    | Fine-tuning ringan lewat LoRA         |
| **Unsloth**       | Kernel    | Bikin LoRA/QLoRA 2x lebih cepat       |
| **DeepSpeed**     | Engine    | Multi-GPU, ZeRO hemat VRAM            |
| **LLaMA-Factory** | Framework | Wrapper all-in-one                    |
| **Ollama**        | Server    | Serve model lokal via API             |
| **9Router**       | Proxy     | Routing + autofallback + load balance |

Quest yang paling stabil buat spek kentang:

```
LLaMA-Factory + Unsloth → GGUF → Ollama → 9Router → Hermes/Claude Code
```
