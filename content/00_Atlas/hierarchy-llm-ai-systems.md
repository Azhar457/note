---
title: 🤖 LLM AI Systems Hierarchy — The Complete Production Stack
tags:
- hierarchy
- ai-systems
- llm
- rag
- mcp
- agent
- fine-tuning
- inference
aliases:
- LLM AI Systems Hierarchy
- LLM Stack Layers
- AI Systems Map
- LLM Production Stack
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 🤖 LLM AI Systems Hierarchy — The Complete Production Stack

> [!tip] Vault QuCrypto punya 55 catatan tentang AI/LLM/RAG/Agent/MCP — tapi tidak ada satu dokumen pun yang menunjukkan **layer architecture** lengkapnya. Catatan ini memetakan stack LLM modern ke dalam **7 lapisan fungsional** (dari hardware sampai product), dengan timeline evolusi 2020-2026, trade-off matriks per layer, dan diagram koneksi ke setiap catatan terkait di vault.

---

## Daftar Isi

1. [[#1. Premise — Mengapa Hierarchy Ini Penting]]
2. [[#2. The Seven-Layer Model]]
3. [[#3. Layer 0 — Hardware Foundation]]
4. [[#4. Layer 1 — Model Foundation (Pre-training)]]
5. [[#5. Layer 2 — Model Adaptation (Fine-tuning)]]
6. [[#6. Layer 3 — Inference Infrastructure]]
7. [[#7. Layer 4 — Context Engineering (RAG, Prompts, Memory)]]
8. [[#8. Layer 5 — Agentic Layer (Tools, MCP, Multi-Agent)]]
9. [[#9. Layer 6 — Evaluation & Observability]]
10. [[#10. Layer 7 — Product/UX Surface]]
11. [[#11. Timeline 2020-2026 — Bagaimana Kita Sampai di Sini]]
12. [[#12. Trade-off Matrix per Layer]]
13. [[#13. Cross-Reference ke Vault]]
14. [[#References]]

---

## 1. Premise — Mengapa Hierarchy Ini Penting

LLM bukan satu produk — ia adalah **tumpukan 7 lapisan** yang masing-masing punya disiplin sendiri:

```
┌─────────────────────────────────────────────────┐
│ Layer 7: Product/UX Surface                      │ ← Yang dilihat user
├─────────────────────────────────────────────────┤
│ Layer 6: Evaluation & Observability              │ ← Bagaimana kita tau ini jalan?
├─────────────────────────────────────────────────┤
│ Layer 5: Agentic Layer                           │ ← Tools, MCP, planning
├─────────────────────────────────────────────────┤
│ Layer 4: Context Engineering                     │ ← RAG, prompts, memory
├─────────────────────────────────────────────────┤
│ Layer 3: Inference Infrastructure               │ ← Serving, batching, KV-cache
├─────────────────────────────────────────────────┤
│ Layer 2: Model Adaptation                       │ ← Fine-tuning, LoRA, adapters
├─────────────────────────────────────────────────┤
│ Layer 1: Model Foundation                       │ ← Pre-training, architecture
├─────────────────────────────────────────────────┤
│ Layer 0: Hardware Foundation                    │ ← GPU, TPU, memory, interconnect
└─────────────────────────────────────────────────┘
```

**Mengapa 7 layer?** Karena setiap layer punya **trade-off independen**: hardware menentukan model mana yang bisa dilatih, model menentukan inference pattern, fine-tuning menentukan capability, dst. Salah optimasi di salah satu layer = sia-sia di layer lain.

**Mengapa vault butuh hierarchy ini?** Karena catatan AI_Systems di vault (`hierarchy-kernel-bypass-networking`, `llm-finetuning-toolchain`, `agentic-ai-mcp-architecture-deepdive`, dll.) membahas layer-layer individual tapi tidak ada yang **memetakan semua layer dalam satu diagram**. Catatan ini jadi peta.

---

## 2. The Seven-Layer Model

### 2.1 Definisi Setiap Layer

| Layer | Fungsi | Owner | Failure Mode Tipikal |
|:-----:|--------|-------|----------------------|
| **0** | Hardware | NVIDIA, AMD, TPUs, custom ASIC | GPU out of memory, interconnect bottleneck |
| **1** | Model foundation | OpenAI, Anthropic, Meta, DeepSeek | Loss tidak konvergen, hallucination |
| **2** | Adaptation | Downstream teams | Catastrophic forgetting, overfit |
| **3** | Inference | Ops/DevOps | TTFT p99 > 3s, cost per token meledak |
| **4** | Context | AI/ML engineers | Retrieval recall <80%, prompt injection |
| **5** | Agentic | Application devs | Infinite loop, tool hallucination |
| **6** | Evaluation | QA + research | Regression drift silent, rogue eval |
| **7** | Product/UX | Designers + PM | User trust eroded, churn |

### 2.2 Layer Dependency

```
[Layer N] ←————————————————— depends on ————————————————→ [Layer N-1]

Layer 7 butuh             → Layer 6 (metrics) + Layer 5 (agent flow)
Layer 6 butuh             → Layer 3 (traces) + Layer 5 (decision logs)
Layer 5 butuh             → Layer 4 (context) + Layer 3 (latency budget)
Layer 4 butuh             → Layer 3 (inference cost) + Layer 2 (capability)
Layer 3 butuh             → Layer 2 (model) + Layer 1 (weights) + Layer 0 (GPU)
Layer 2 butuh             → Layer 1 (base model)
Layer 1 butuh             → Layer 0 (compute cluster)
```

**Prinsip:** Optimasi di Layer N tidak bisa mengkompensasi kelemahan di Layer N-1. Contoh: prompt yang indah di Layer 4 tidak akan menyelamatkan model yang cacat di Layer 1.

---

## 3. Layer 0 — Hardware Foundation

> GPU/TPU + memory hierarchy + interconnect yang menentukan throughput.

### 3.1 Komponen Kritis

| Subsystem | Spesifikasi | Vendor | Throughput |
|-----------|-------------|--------|------------|
| Compute | H100, H200, B200 (NVIDIA) — MI300X (AMD) — TPU v5p (Google) | NVIDIA dominates 88% | 1-4 PFLOPs FP8 |
| Memory | HBM3, HBM3e (up to 192 GB/stack) | SK Hynix, Samsung, Micron | 3-6 TB/s |
| Interconnect | NVLink (900 GB/s), InfiniBand (400 Gbps), PCIe Gen5 | NVIDIA, Mellanox | 600-900 GB/s per node |
| Storage | NVMe SSD, parallel filesystem (Lustre, GPFS) | Pure Storage, WEKA | 100+ GB/s read |
| Networking | RoCE, RoCEv2, custom Ethernet | Arista, Mellanox | 800 Gbps rollout |

### 3.2 Compute Hierarchy

```
Single GPU            = H100 SXM
Node (8 GPU NVLink)   = 1.6 PFLOPs FP8 full mesh
Pod (32 nodes)        = 1024 GPU, NVLink + IB
Cluster (>1000 GPU)   = Training run skala GPT-4
Hyperscale (>100K GPU)= Frontier training (MosaicML, xAI Colossus)
```

**Koneksi ke Vault:**
- [[hardware-architecture]] — GPU microarchitecture detail
- [[00_Atlas/hierarchy-kernel-bypass-networking]] — Layer 3 (RDMA, GPU Direct)
- [[embedded-systems]] — Edge inference constraint

### 3.3 Kenapa Layer 0 Penting

Setiap optimasi Layer 1 (pre-training) **dibatasi oleh Layer 0**. Contoh: arsitektur Mixture-of-Experts (MoE) hemat komputasi activation, tapi **memperburuk memory pressure** di inference. Cluster kecil → batch kecil → throughput rendah. Ini sebabnya vendor kecil seperti Mistral fokus di model dense < 70B yang muat di single node.

---

## 4. Layer 1 — Model Foundation (Pre-training)

> Arsitektur model + tokenizer + pre-training objective + dataset curation.

### 4.1 Arsitektur yang Dominan

| Arsitektur | Tahun | Inovasi | Use Case |
|------------|:-----:|---------|----------|
| GPT-1 (decoder-only) | 2018 | Transformer decoder, causal masking | Generative |
| BERT (encoder-only) | 2018 | Bidirectional MLM | Classification, embedding |
| T5 (encoder-decoder) | 2019 | Unified text-to-text | Translation, summarization |
| GPT-3 (scaling) | 2020 | In-context learning emerges at 13B+ | Few-shot generalist |
| Switch Transformer | 2021 | Mixture of Experts (MoE) | Sparse compute |
| Chinchilla | 2022 | Compute-optimal scaling law | 70B trained on 1.4T tokens |
| Llama 2/3 | 2023-24 | Open weights, RLHF | Chat, instruction following |
| DeepSeek-R1 | 2025 | RL-first reasoning model | Math, code, reasoning |
| Claude 3.7+ | 2025 | Long context (200K-1M tokens) | Document analysis |

### 4.2 Pre-training Objective

**Next-token prediction** (GPT-style):

$$ \mathcal{L} = -\sum_{t=1}^{T} \log p_\theta(x_t \mid x_{<t}) $$

Justru objective yang sangat sederhana ini, dalam arsitektur yang tepat dengan cukup compute, menghasilkan **emergent capabilities** (in-context learning, chain-of-thought) yang tidak diprogram secara eksplisit.

### 4.3 Dataset Curation

| Data Source | Rasio Tipikal | Karakteristik |
|-------------|:-------------:|---------------|
| Web crawl (Common Crawl) | 60-80% | Sangat besar tapi noisy |
| Books (Books3, BooksCorpus) | 5-15% | High-quality narrative |
| Code (GitHub, Stack) | 5-15% | Struktural, dapat diuji |
| Wikipedia | 2-5% | Factual, multilingual |
| Scientific papers | 1-3% | Domain-specific |
| Synthetic (GPT-4 generated) | 5-10% | Curated instruction data |

**Filter pipeline:** Quality → Deduplication → Toxicity → PII removal → Length filtering. Total data yang dipakai = ~10% dari raw crawl.

**Koneksi ke Vault:**
- [[math-and-algorithms]] — Transformer attention math
- [[attention-mechanism-deepdive]] — Self-attention details
- [[backpropagation-deepdive]] — Gradient descent for LLM
- [[llm-finetuning-toolchain]] — Layer 1 → Layer 2 transition
- [[rag-data-pipeline-refresh-strategy]] — Document corpus untuk RAG

---

## 5. Layer 2 — Model Adaptation (Fine-tuning)

> Mengubah perilaku/capability model untuk kasus spesifik dengan biaya komputasi yang jauh lebih rendah dari pre-training.

### 5.1 Teknik Fine-tuning

| Teknik | Tahun | Parameter Update | Compute vs Full FT | Memori GPU |
|--------|:-----:|:----------------:|:------------------:|:----------:|
| **Full fine-tuning** | 2017 | 100% Semua parameter | 1× | 100% |
| **LoRA** | 2021 | ~0.1% (rank decomposition) | ~3× lebih murah | ~10% |
| **QLoRA** | 2023 | LoRA + 4-bit quantization | ~10× lebih murah | ~3% |
| **Adapter (Houlsby)** | 2019 | ~5% (small modules injected) | ~5× lebih murah | ~15% |
| **Prompt tuning** | 2021 | 0% (soft prompt trained) | Negligible | <1% |
| **Prefix tuning** | 2021 | 0% + KV prefix learned | Negligible | <1% |
| **DoRA** | 2024 | LoRA enhanced (magnitude + direction) | ~3.5× | ~12% |
| **Full FT (MoE expert tuning)** | 2025 | ~10% | ~2× | ~25% |

### 5.2 Algoritma Fine-tuning Modern

**RLHF (Reinforcement Learning from Human Feedback):**

```
┌────────────┐    ┌───────────────┐    ┌────────────┐    ┌──────────────┐
│ Pre-trained│ →  │ SFT (Supervised│ → │ Reward Model│ → │ PPO          │
│ Model      │    │ Fine-tuning)   │    │ (Human-ranked│    │ (RL)         │
│            │    │                │    │ preferences)│    │              │
└────────────┘    └───────────────┘    └────────────┘    └──────────────┘
```

**DPO (Direct Preference Optimization)** — 2024, lebih sederhana dari PPO, tanpa reward model terpisah:

$$ \mathcal{L}_{\text{DPO}} = -\log\sigma\left( \beta \log\frac{\pi_\theta(y_w|x)}{\pi_{\text{ref}}(y_w|x)} - \beta \log\frac{\pi_\theta(y_l|x)}{\pi_{\text{ref}}(y_l|x)} \right) $$

Dimana $y_w$ = preferred, $y_l$ = rejected, $\pi_\theta$ = policy yang dilatih.

### 5.3 Dataset untuk Fine-tuning

| Jenis | Format | Contoh |
|-------|--------|--------|
| **SFT** | `(instruction, response)` pairs | Alpaca, Dolly, OASST |
| **Preference** | `(prompt, chosen, rejected)` | HH-RLHF, UltraFeedback |
| **Reasoning** | `(problem, step-by-step)` | OpenMath, GSM8K-CoT |
| **Tool use** | `(query, tool_call, result)` | ToolBench, Hermes |

**Koneksi ke Vault:**
- [[llm-finetuning-toolchain]] — Complete LoRA/QLoRA pipeline
- [[reinforcement-learning-deepdive]] — RL foundations
- [[neurosymbolic-ai]] — Symbolic vs connectionist trade-off

---

## 6. Layer 3 — Inference Infrastructure

> Bagaimana model yang sudah dilatih disajikan ke pengguna — dengan latency, throughput, dan biaya yang optimal.

### 6.1 Tantangan Inference LLM

Inference LLM punya **profile yang unik**:

```
Pre-training  : Latency tidak penting (perlu waktu)
Fine-tuning   : Latency tidak penting (perlu waktu)
Inference     : Latency P99 < 2s MUTLAK
              : Throughput tinggi (1000-10000 req/s)
              : Biaya per token minimal
```

Perbedaan fundamental dengan inference tradisional:
1. **Memory-bound, bukan compute-bound** — kv-cache memenuhi seluruh GPU memory
2. **Sequence length variable** — TTFT dan TPOT berbeda
3. **Statelessness terbatas** — context window besar berarti stateful

### 6.2 Teknik Serving Modern

| Teknik | Fungsi | Throughput Impact | Latency Impact |
|--------|--------|:-----------------:|:--------------:|
| **Continuous batching** | Dynamic gap-filling | 5-20× | -50% TTFT |
| **PagedAttention (vLLM)** | Memory paging untuk kv-cache | 10-24× | -30% TPOT |
| **Speculative decoding** | Draft model + verification | 2-3× | -60% TPOT |
| **Prefix caching** | Cache common system prompts | 10× untuk RAG | -90% TTFT |
| **Quantization (FP8/INT4)** | Reduce memory bandwidth | 2-4× | -40% TTFT |
| **Multi-LoRA serving** | Serve many adapters in one GPU | 4× | +20% TTFT |
| **Disaggregated inference** | Separate prefill vs decode | 2-3× | -50% P99 |
| **Tensor parallelism** | Shard besar ke banyak GPU | - | -70% latency per token |
| **Pipeline parallelism** | Multi-node sharding | - | Communication bound |

### 6.3 Production Stack

```
┌─────────────────────────────────────────────────┐
│ Application Layer (prompt → stream response)    │
├─────────────────────────────────────────────────┤
│ Scheduler (rate limiting, queue, SLO)           │
├─────────────────────────────────────────────────┤
│ Inference Engine (vLLM / TGI / TensorRT-LLM)    │
├─────────────────────────────────────────────────┤
│ Model Optimizer (compiler, quantizer, pruner)   │
├─────────────────────────────────────────────────┤
│ GPU Runtime (CUDA / ROCm, MIG/MPS)              │
└─────────────────────────────────────────────────┘
```

**Production Choice Matrix (2025):**

| Engine | Throughput (tok/s/GPU) | Hardware | Bahasa |
|--------|:---------------------:|----------|--------|
| vLLM | 8000-15000 | NVIDIA, AMD | Python/CUDA |
| TGI (HuggingFace) | 6000-12000 | NVIDIA | Rust/Python |
| TensorRT-LLM | 12000-25000 | NVIDIA | Python/C++/Triton |
| SGLang | 15000-30000 | NVIDIA | Python/Rust |
| llama.cpp (CPU) | 50-500 | CPU-only | C++ |
| MLX (Apple Silicon) | 800-3000 | M-series | Python/C++ |

**Koneksi ke Vault:**
- [[llmops-ai-infrastructure]] — Ops untuk LLM
- [[gpu-programming-parallel-compute]] — GPU programming primitives
- [[production-model-serving-optimization]] — Serving optimization
- [[00_Atlas/hierarchy-kernel-bypass-networking]] — RDMA, GPU Direct untuk inference cluster

---

## 7. Layer 4 — Context Engineering (RAG, Prompts, Memory)

> Memberikan model informasi yang relevan untuk menjawab query — melampaui apa yang ada di parameter.

### 7.1 The Context Engineering Stack

```
┌────────────────────────────────────────────────────┐
│ User Query + History + State                       │
├────────────────────────────────────────────────────┤
│ Query Transformation                               │
│ (rewrite, decompose, HyDE, step-back)              │
├────────────────────────────────────────────────────┤
│ Retrieval (BM25 + dense + hybrid + reranker)       │
├────────────────────────────────────────────────────┤
│ Context Assembly                                   │
│ (windowing, hierarchy, lost-in-the-middle)         │
├────────────────────────────────────────────────────┤
│ Prompt Composition                                 │
│ (system + retrieved + user)                        │
├────────────────────────────────────────────────────┤
│ Response Generation                                │
└────────────────────────────────────────────────────┘
```

### 7.2 RAG Stages

| Stage | Teknik | Trade-off |
|-------|--------|-----------|
| **Ingestion** | Chunker, embedder, metadata extractor | Chunk size vs recall |
| **Query transform** | Rewrite, query expansion, HyDE | Recall vs latency |
| **Retrieval** | BM25 / dense / hybrid / multi-vector | Recall vs precision |
| **Reranking** | Cross-encoder, LLM-based, ColBERT | Latency vs MRR |
| **Generation** | LLM final answer with context | Context window vs accuracy |

### 7.3 Chunking Strategies

| Strategy | Chunk Size | Overlap | Recall | Speed |
|----------|:----------:|:-------:|:------:|:-----:|
| Fixed-size | 256-1024 | 0-100 | Sedang | Cepat |
| Recursive splitter | 256-1024 | 0-100 | Bagus | Cepat |
| Semantic | Variable | 0 | Terbaik | Lambat |
| Document-aware | Variable | 0 | Terbaik | Sedang |

### 7.4 Advanced RAG Patterns

- **Self-RAG:** Model decide sendiri apakah perlu retrieval
- **Corrective RAG (CRAG):** Hasil retrieval di-grade, lalu re-retrieve jika buruk
- **Agentic RAG:** Multi-hop retrieval dengan planning
- **GraphRAG:** Graph-based retrieval untuk relationship queries
- **Multi-modal RAG:** Text + image + audio + video dalam satu sistem

**Koneksi ke Vault:**
- [[rag-pipeline-end-to-end-guide]]
- [[advanced-chunking-strategies-deepdive]]
- [[query-transformation-rag]]
- [[embedding-model-selection-finetuning]]
- [[00_Atlas/hierarchy-classical-ml-algorithms]] — BM25 di sini
- [[hybrid-search-vector-keyword]] — Fusion strategy
- [[00_Atlas/hierarchy-binary-quantization-hamming-popcount]] — Seperti binary caching tapi untuk konteks
- [[00_Atlas/hierarchy-metric-transition-theory]] — Cosine→Hamming untuk retrieval

---

## 8. Layer 5 — Agentic Layer (Tools, MCP, Multi-Agent)

> Memberi model kemampuan untuk **bertindak di dunia** dengan memanggil tools, multi-step planning, dan kolaborasi multi-agent.

### 8.1 Tool Use Evolution

| Evolusi | Pattern | Contoh |
|---------|---------|--------|
| 1.0 | ReAct (Reason + Act) | LangChain agents 2022 |
| 2.0 | Tool calling (native) | OpenAI function calling 2023 |
| 3.0 | Structured output | JSON Mode, Pydantic, Zod |
| 4.0 | MCP (Model Context Protocol) | Anthropic/Khúc 2024 |
| 5.0 | Multi-agent collaboration | AutoGen, CrewAI 2024 |
| 6.0 | Autonomous coding | Claude Code, Codex, Devin |
| 7.0 | Persistent memory + Skills | Hermes agents 2025-26 |

### 8.2 MCP Architecture

```
┌──────────────┐  protocol   ┌──────────────┐  calls   ┌────────────┐
│ LLM Host     │ ←─JSON-RPC─→│ MCP Server   │ ──────→  │ External   │
│ (Claude Code)│              │ (Filesystem) │          │ Service    │
│              │              │              │          │            │
│ Tools: list  │              │ Tools: read  │          │            │
│ Resources:   │              │ Resources:   │          │            │
│  list        │              │  list        │          │            │
│ Prompts:     │              │ Prompts:     │          │            │
│  list        │              │  templates   │          │            │
└──────────────┘              └──────────────┘          └────────────┘
```

Three primitives:
1. **Tools** — model-controlled actions
2. **Resources** — application-controlled context
3. **Prompts** — user-controlled templates

### 8.3 Multi-Agent Patterns

| Pattern | Agen | Use Case |
|---------|------|----------|
| **Supervisor-Worker** | 1 supervisor + N workers | Task decomposition |
| **Peer-to-Peer** | N agen setara | Debate, voting |
| **Hierarchical** | Tree of agents | Complex workflows |
| **Blackboard** | Shared memory | Specialist collaboration |
| **Swarm** | Lightweight coordination | Ephemeral tasks |
| **Crew** | Role-based team | Software dev (CrewAI) |

**Koneksi ke Vault:**
- [[agentic-ai-mcp-architecture-deepdive]]
- [[ai-comm-protocol-deep-dive]]
- [[meta-agent-orchestration]]
- [[multi-agent-orchestration-patterns]]
- [[autonomous-system-design]]
- [[ai-evaluation-framework]] — Tool hallucination detection

---

## 9. Layer 6 — Evaluation & Observability

> Bagaimana kita tahu kalau sistem AI kita **sesuai spec** dan **tetap sesuai spec** seiring waktu.

### 9.1 Three-Layer Evaluation

```
┌─────────────────────────────────────┐
│ Layer C: User Feedback              │ ← Real users (thumbs up/down)
├─────────────────────────────────────┤
│ Layer B: Online Metrics             │ ← Production traces (TTFT, tokens, refusal)
├─────────────────────────────────────┤
│ Layer A: Offline Evals              │ ← Curated datasets (accuracy, bias, safety)
└─────────────────────────────────────┘
```

### 9.2 Offline Evaluation Categories

| Kategori | Metrik | Contoh |
|----------|--------|--------|
| **Capability** | MMLU, GSM8K, HumanEval | General skill |
| **Domain** | MedQA, LegalBench | Specialist |
| **Safety** | HarmBench, AdvBench | Adversarial inputs |
| **Bias** | BBQ, StereoSet | Fairness |
| **Reasoning** | ARC, BBH | Multi-step |
| **Instruction following** | IFEval, Multi-IF | Format adherence |
| **Retrieval** | nDCG@10, Recall@10 | Untuk RAG |
| **Agent** | Tool accuracy, task success | Tool use |

### 9.3 Observability Stack

```
┌─────────────────────────────────────┐
│ Distributed Tracing (OpenTelemetry) │
├─────────────────────────────────────┤
│ Token usage & cost analytics         │
├─────────────────────────────────────┤
│ LLM-as-judge for automated eval     │
├─────────────────────────────────────┤
│ Drift detection (embedding + output)│
├─────────────────────────────────────┤
│ Cost guardrails + rate limiting     │
└─────────────────────────────────────┘
```

**Koneksi ke Vault:**
- [[ai-evaluation-framework]]
- [[rag-evaluation-framework]]
- [[rag-data-pipeline-refresh-strategy]] — Drift response
- [[test-time-compute-system2]] — Reasoning eval at inference
- [[llm-security-red-teaming-attack-surface-ai-layer]] — Adversarial eval

---

## 10. Layer 7 — Product/UX Surface

> Bagaimana AI disajikan ke user akhir — chat box, voice, autonomous action, atau bentuk lainnya.

### 10.1 UX Patterns

| Pattern | Latency Budget | Use Case | Contoh |
|---------|:--------------:|----------|--------|
| **Streaming chat** | TTFT <500ms | Conversational | ChatGPT, Claude |
| **Voice (live)** | TTFT <200ms | Spoken conversation | ElevenLabs, Gemini Live |
| **Batch async** | Tidak real-time | Long document analysis | NotebookLM |
| **Agent async** | Minutes-hours | Autonomous coding | Devin, Claude Code |
| **Inline assist** | <100ms | Code completion | Copilot, Cursor |
| **Predictive** | <50ms | Auto-complete | Smart reply |
| **Multi-modal** | <1s | Realtime vision/audio | GPT-4o realtime |

### 10.2 Trust & Safety Surface

Setiap layer harus transparan ke user:
- **Citations** (Layer 4)
- **Confidence display** (Layer 6)
- **Action preview** (Layer 5)
- **Reasoning trace** (Layer 5 eval)
- **Cost display** (Layer 3 + 6)

**Koneksi ke Vault:**
- [[llm-security-red-teaming-attack-surface-ai-layer]]
- [[hallucination-mitigation-grounding]]
- [[ai-governance-ethics]]

---

## 11. Timeline 2020-2026 — Bagaimana Kita Sampai di Sini

```
┌─────────────────────────────────────────────────────────┐
│ Year │ Major Milestone                                    │
├──────┼──────────────────────────────────────────────────┤
│ 2020 │ GPT-3 (175B) — in-context learning emerges       │
│ 2021 │ Codex, Copilot — coding becomes mainstream       │
│ 2022 │ ChatGPT (RLHF), Stable Diffusion, Whisper        │
│      │ → Layer 5 Architecture stabilizes                 │
│ 2023 │ GPT-4, Claude 2, Llama 2 — multimodal, long ctx  │
│      │ → Layer 1-3 production-grade                      │
│      │ → RAG becomes default pattern (Layer 4)          │
│      │ → Function calling native (Layer 5 v2)            │
│ 2024 │ Claude 3.5 Sonnet, Llama 3, DeepSeek-V3          │
│      │ → MCP protocol standardized                      │
│      │ → Multi-agent frameworks mature                   │
│      │ → QLoRA democratizes Layer 2                     │
│      │ → Continuous batching di vLLM (Layer 3)           │
│ 2025 │ Claude 4, GPT-5, DeepSeek-R1 — reasoning models  │
│      │ → Test-time compute scaling (chain-of-thought)    │
│      │ → Long context >1M tokens                        │
│      │ → Agentic coding mainstream                       │
│      │ → Reasoning tokens visible (CoT)                  │
│ 2026 │ Multi-modal real-time, persistent memory         │
│      │ → Skills marketplace emerging                     │
│      │ → Self-improving agents (RL on production)        │
│      │ → MCP 2.0 — federated agent networks              │
└─────────────────────────────────────────────────────────┘
```

---

## 12. Trade-off Matrix per Layer

Setiap layer punya trade-off **Cost vs Capability vs Latency**:

| Layer | Cost Driver | Capability Lever | Latency Lever |
|-------|-------------|------------------|----------------|
| 0 | GPU hours × $/hour | Model size | Cluster interconnect |
| 1 | Training tokens × energy | Architecture innovation | N/A (offline) |
| 2 | Adapter size × dataset | Dataset quality | Training compute |
| 3 | GPU-seconds × batch size | Model quality | Batching strategy |
| 4 | Embedding + LLM call | Reranker quality | Index structure |
| 5 | Tool calls × cost | Planning depth | Max iterations |
| 6 | Eval sampling rate | Eval dataset diversity | Caching strategy |
| 7 | User satisfaction | Surface clarity | Streaming |

**Kontradiksi utama:**
- Layer 3 (inference cost) ♥ tekanan dari Layer 7 (latency) tapi ✗ konflik dengan Layer 4 (recall)
- Layer 5 (agent capability) ♥ keinginan Layer 7 (autonomy) tapi ✗ konflik dengan Layer 6 (predictability)
- Layer 2 (capability) ♥ keinginan Layer 4 (retrieval quality) tapi ✗ konflik dengan Layer 3 (latency)

---

## 13. Cross-Reference ke Vault

Vault QuCrypto sudah punya catatan di masing-masing layer. Daftar berikut memetakan vault notes → layer:

| Layer | Catatan Vault |
|:-----:|---------------|
| **0** | [[gpu-programming-parallel-compute]], [[ai-hardware-architecture]], [[00_Atlas/hierarchy-kernel-bypass-networking]] |
| **1** | [[attention-mechanism-deepdive]], [[backpropagation-deepdive]], [[math-and-algorithms]] |
| **2** | [[llm-finetuning-toolchain]], [[neurosymbolic-ai]], [[reinforcement-learning-deepdive]] |
| **3** | [[llmops-ai-infrastructure]], [[production-model-serving-optimization]], [[ollama-vllm-self-hosting-deployment]] |
| **4** | [[rag-pipeline-end-to-end-guide]], [[advanced-chunking-strategies-deepdive]], [[query-transformation-rag]], [[embedding-model-selection-finetuning]], [[hybrid-search-vector-keyword]], [[rag-evaluation-framework]] |
| **5** | [[agentic-ai-mcp-architecture-deepdive]], [[ai-comm-protocol-deep-dive]], [[meta-agent-orchestration]], [[multi-agent-orchestration-patterns]], [[autonomous-system-design]] |
| **6** | [[ai-evaluation-framework]], [[llm-security-red-teaming-attack-surface-ai-layer]], [[rag-evaluation-framework]] |
| **7** | [[hallucination-mitigation-grounding]], [[ai-governance-ethics]], [[llm-security-red-teaming-attack-surface-ai-layer]] |
| **Cross-cutting** | [[computer-vision-deepdive]], [[document-parsing-for-rag]], [[differential-privacy-praktik]], [[ai-quality-offline-moc]] |

---

## References

1. Vaswani et al. *"Attention Is All You Need."* NeurIPS 2017.
2. Brown et al. *"Language Models are Few-Shot Learners."* arXiv:2005.14165 (2020).
3. Hu et al. *"LoRA: Low-Rank Adaptation of Large Language Models."* ICLR 2022.
4. Dettmers et al. *"QLoRA: Efficient Finetuning of Quantized LLMs."* NeurIPS 2023.
5. Ouyang et al. *"Training Language Models to Follow Instructions with Human Feedback."* (2022).
6. Rafailov et al. *"Direct Preference Optimization."* NeurIPS 2023.
7. Kwon et al. *"Efficient Memory Management for Large Language Model Serving with PagedAttention."* SOSP 2023.
8. Anthropic. *"Model Context Protocol Specification."* (2024). https://modelcontextprotocol.io/
9. Park et al. *"Generative Agents: Interactive Simulacra of Human Behavior."* UIST 2023.
10. Kapoor et al. *"AI Evaluations: A Taxonomy of What to Evaluate."* Stanford HAI (2024).
11. Anthropic. *"Claude 3.7 System Card."* (2025).
12. DeepSeek Team. *"DeepSeek-R1: Incentivizing Reasoning Capability."* (2025).
13. S. Borgeaud et al. *"Improving Language Models by Retrieving from Trillions of Tokens."* ICML 2022.
14. J. Wei et al. *"Chain-of-Thought Prompting Elicits Reasoning in Large Language Models."* NeurIPS 2022.
15. Patrick Lewis et al. *"Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks."* NeurIPS 2020.
