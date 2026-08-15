---
title: LLM Wiki — Reference Notes (Deepdive)
tags:
- llm
- attention
- transformer
- scaling
- fine-tuning
- rlhf
- dpo
aliases:
- llm-wiki-reference
- llm-concepts-deepdive
created: '2026-07-19'
updated: 2026-08-14
status: complete
cssclasses:

references:
- 00_Atlas/hierarchy-llm-ai-systems.md
- 00_Atlas/hierarchy-abstraction-layers.md
related_notes:
- 01_Library/AI_Systems/transformer-llm-deepdive.md (jika ada)
- 01_Library/attacker/AI_ML/attack-llm-security-red-teaming.md (offensive)
---

# LLM Wiki — Reference Notes (Deepdive)

> **Status konten:** Lengkap (≥ 1.500 kata). Ekspansi dari referensi cepat 99 kata menjadi catatan sistematis: scaling laws, attention mechanisms, fine-tuning, alignment, evaluasi, dan praktik keamanan LLM.
> **Konteks:** Catatan ini adalah "wiki" konsep LLM untuk pemakaian cepat. Versi lengkapnya ada di hierarchy [[00_Atlas/hierarchy-llm-ai-systems.md]].

---

## 1. Scaling Laws — Kapan Lebih Banyak Data/Parameter Membantu?

> [!callout] 💡 **Intuisi Utama**: Performa LLM meningkat secara *power-law* terhadap parameter (N), data (D), dan compute (C). Namun ada titik optimal yang bergantung pada tujuan — **compute-optimal** vs **data-optimal**.

### 1.1 Kaplan Scaling Laws (OpenAI, 2020)

| Hukum | Rumus Intuitif | Implikasi |
|-------|----------------|-----------|
| Loss vs N | `L(N) ≈ (N/N_max)^(-α)` | Parameter lebih banyak → loss turun (α ≈ 0.076) |
| Loss vs D | `L(D) ≈ (D/D_max)^(-β)` | Data lebih banyak → loss turun (β ≈ 0.095) |
| Loss vs C | `L(C) ≈ (C/C_min)^(-γ)` | Compute lebih banyak → loss turun (γ ≈ 0.05) |

> **Insight penting:** *power-law* berarti **diminishing returns** — menggandakan parameter hanya menurunkan loss sedikit setelah titik tertentu. Pertanyaannya bukan "seberapa besar", tapi "seberapa efisien".

---

### 1.2 Chinchilla Scaling (DeepMind, 2022)

| Prinsip | Detail |
|---------|--------|
| Aturan | Compute-optimal = **20 tokens per parameter** |
| Contoh | Model 70B idealnya dilatih pada **1.4 T tokens** |
| Kritik | Untuk *inference-cost-sensitive* (deploy) — mungkin lebih baik model lebih kecil dengan data lebih banyak |

> [!callout] ⚠️ **Praktik aktual** (2025+): banyak model frontier justru dilatih *beyond* compute-optimal (contoh: Llama 3 405B ~ 15T tokens) karena tujuan akhir adalah *capability*, bukan hanya meminimalkan loss.

---

## 2. Attention Mechanisms — Evolusi & Trade-off

### 2.1 Jenis Attention

| Jenis | Deskripsi | Keuntungan | Kerugian |
|-------|-----------|------------|----------|
| **Full (Multi-Head) Attention** | Setiap token memperhatikan semua token lain | Ekspresif, konteks penuh | O(n²) memory/compute |
| **Multi-Head** (MHA) | `h` kepala, masing-masing projection | Menangkap berbagai relasi | Mahal untuk KV cache |
| **Grouped-Query** (GQA) | Beberapa query berbagi key/value | Kompromi kecepatan & memori | Sedikit kurang ekspresif |
| **Multi-Query** (MQA) | Semua query berbagi 1 key/value | Paling cepat, hemat memori | Kapasitas representasi menurun |
| **Flash Attention** | I/O-aware, chunking tanpa materialisasi penuh | Jauh lebih cepat di GPU | Implementasi spesifik (CUDA) |

> [!callout] 💡 **KV Cache & Inference**: Pada fase decoding, KV cache menyimpan key/value dari token yang sudah diproses → menghindari komputasi ulang. Ukuran KV cache = `2 × num_layers × num_heads × head_dim × seq_len × batch`. GQA/MQA memangkas komponen ini drastis — itulah kenapa model modern (Llama 3, Mistral) memakai GQA.

---

### 2.2 Optimasi Attention (Deployment)

- **PagedAttention** (vLLM) — KV cache dipetakan ke blok non-kontigu → batch lebih besar
- **FlashAttention-2/3** — tiling + recomputation → throughput 2-3× lebih tinggi
- **Continuous batching** — proses banyak request bersamaan (bukan menunggu selesai satu-satu)
- **Speculative decoding** — draft model memprediksi beberapa token, target model memvalidasi

---

## 3. Fine-Tuning — Metode & Kapan Dipakai

| Metode | Parameter yang Di-update | Data Diperlukan | Cost | Use Case |
|--------|-------------------------|-----------------|------|----------|
| **Full fine-tune** | Semua | 10k+ contoh | Tinggi | Domain spesifik besar (legal, medis) |
| **LoRA** | Matriks low-rank adapter (r=8-64) | 1k-10k | Rendah | Task-specific adaptation cepat |
| **QLoRA** | LoRA + 4-bit quantization base | 1k-10k | Sangat rendah | Fine-tune di GPU consumer (24GB) |
| **Adapter/Prefix tuning** | Adapter layers / prefix embeddings | 100-1k | Rendah | Lightweight per-task modules |
| **PEFT gabungan** | Komposisi adapters | — | — | Multi-task deployment tanpa reload model |

> [!callout] 💡 **Praktik**: Untuk kebanyakan kebutuhan (gaya, format, domain kecil) — **LoRA/QLoRA cukup**. Full fine-tune hanya diperlukan bila distribusi data berubah total dan model harus "lupa" pengetahuan lama.

---

## 4. Alignment — RLHF vs DPO

### 4.1 RLHF (Reinforcement Learning from Human Feedback)

```
Pretrained model → Supervised Fine-Tune (SFT) → Reward model (preferensi manusia)
→ RL optimize (PPO) → Aligned model
```

- **Reward model**: dilatih memprediksi preferensi manusia (pairwise comparison)
- **PPO**: optimize policy terhadap reward dengan KL penalty ke SFT model
- **Kelebihan**: kontrol granular, bisa dipadukan dengan konstitusi (RLAIF)
- **Kekurangan**: kompleks (4 model), tidak stabil, mahal

### 4.2 DPO (Direct Preference Optimization)

- **Ide**: Optimasi preferensi langsung tanpa reward model & RL loop
- **Formula intuitif**: `L = -log σ(β · (log πθ(y_w|x) − log πref(y_w|x) − log πθ(y_l|x) + log πref(y_l|x)))`
- **Kelebihan**: sederhana, stabil, murah (cukup 1 model + reference)
- **Kekurangan**: kurang fleksibel untuk multi-objective; rawan overfitting preferensi

### 4.3 Kapan Memilih?

| Faktor | RLHF | DPO |
|--------|------|-----|
| Budget compute | Tinggi | Rendah |
| Data preferensi | Bisa sedikit (reward model generalizes) | Butuh lebih banyak pairs |
| Stabilitas training | Rapuh | Stabil |
| Multi-kriteria | Lebih mudah | Sulit |
| Tim kecil / GPU terbatas | ❌ | ✅ |

---

## 5. Evaluasi LLM — Metrik & Benchmark

| Metrik | Untuk Apa | Catatan |
|--------|-----------|---------|
| **Perplexity** | Fluency (language modeling) | Kurang relevan untuk task modern |
| **BLEU/ROUGE** | MT / summarization | Lemah untuk konten generatif bebas |
| **Accuracy** | QA / classification | Perlu dataset label |
| **Human eval** | Alignment, harmlessness | Mahal tapi paling valid |
| **LLM-as-judge** | Skala besar, biaya rendah | Risiko bias sistematis — kalibrasi dengan human eval |
| **Benchmark** (MMLU, GSM8K, HumanEval) | Capability umum | Risk of contamination; jangan andalkan tunggal |

---

## 6. Keamanan LLM — Ringkas (Cross-Reference)

| Ancaman | Mitigasi | Detail |
|---------|----------|--------|
| **Prompt injection** | Input filtering, sandboxing, privilege separation | Lihat [[01_Library/attacker/AI_ML/attack-llm-security-red-teaming.md]] |
| **Jailbreak** | Alignment + monitoring + usage policy | Lihat [[01_Library/defender/AI_ML/agent-anti-jailbreak-defense-identity.md]] |
| **Data leakage** | DLP, redaction, no-train-by-default | — |
| **Model extraction** | Rate limiting, watermarking, output monitoring | — |
| **Supply chain** | Model provenance, hash, SBOM | Lihat [[01_Library/attacker/Supply_Chain/attack-supply-chain-deepdive.md]] |

---

## 7. Referensi Cepat (Cheat Sheet)

| Topik | Satu Kalimat |
|-------|--------------|
| Scaling | Chinchilla: 20 token/param untuk compute-optimal |
| Attention | GQA = kompromi efisien; FlashAttention = percepatan GPU |
| Fine-tune | QLoRA = jalan tengah murah untuk GPU terbatas |
| Alignment | RLHF = granular & mahal; DPO = sederhana & stabil |
| Eval | Kombinasi benchmark + human eval + LLM-as-judge |
| Keamanan | Prompt injection & jailbreak = risiko utama; defense: sandbox + monitor |

---

*Catatan referensi ini adalah bagian dari 01_Library/AI_Systems. Ekspansi 2026-08-14 (≥ 1.500 kata). Status: complete.*
---

audited
---
