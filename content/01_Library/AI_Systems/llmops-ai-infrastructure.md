---
title: 'LLMOps & AI Infrastructure — Deep Dive: Langfuse, Prompt Management, Vector DB Ops, Cost Tracking, LLM Observability'
tags:
- llmops
- ai-infrastructure
- langfuse
- observability
- cost-optimization
- rag-ops
created: '2026-07-18'
updated: '2026-07-18'
status: pending
cssclasses:
  - wide-table
  - callout


---
[]()# 🔧 LLMOps & AI Infrastructure — Deep Dive: Langfuse, Prompt Management, Vector DB Ops, Cost Tracking, LLM Observability

> Panduan komprehensif operasional LLM di production — dari observability (Langfuse, LangSmith, W&B Prompts), prompt versioning & management, vector database operations (indexing strategy, reindex, pruning), cost tracking & optimization (model routing, caching, batching), LLM caching (semantic cache, KV cache), dan production deployment patterns (guardrails, rate limiting, canary deploy). Vault udah punya [[ai-evaluation-framework]] (evaluasi RAG — RAGAS, LLM-as-Judge), [[vector-database-internals-optimization]] (HNSW, IVF, quantization), [[production-model-serving-optimization]] (inference serving), dan [[ai-engineering-stack-roadmap]] (AI stack high-level). Catatan ini mengisi gap: **operational layer** — bagaimana menjalankan LLM di production dengan monitoring, cost control, dan prompt management.

> [!info] Posisi di Vault
> Catatan ini terkait dengan [[ai-evaluation-framework]] (RAG evaluation, RAGAS, langfuse evaluation), [[vector-database-internals-optimization]] (HNSW/IVF index, quantization, index maintenance), [[production-model-serving-optimization]] (vLLM, TensorRT, inference optimization), [[ai-engineering-stack-roadmap]] (posisi LLMOps dalam AI stack), [[rag-pipeline-end-to-end-guide]] (LLM pipeline production), [[hallucination-mitigation-grounding]] (guardrails & grounding), dan [[query-transformation-rag]] (query rewrite, routing).

---

## Daftar Isi

- [[#LLM Observability Stack]]
- [[#Prompt Management & Versioning]]
- [[#Vector Database Operations]]
- [[#Cost Tracking & Optimization]]
- [[#LLM Caching]]
- [[#Production Deployment]]
- [[#Tool Comparison]]
- [[#Koneksi ke Vault]]

---

## LLM Observability Stack

### Kenapa Observability untuk LLM Berbeda dari App Biasa?

| Dimensi | App Biasa | LLM App |
|---------|-----------|---------|
| **Error** | 500, timeout, exception | ✅ Halusinasi ❌ tidak ada exception |
| **Latency** | ms (predictable) | Detik (stochastic — tergantung token) |
| **Cost** | CPU/memory (fixed) | Per-token (variable — tergantung output length) |
| **Quality** | Functional correctness | Semantic correctness (subjective) |
| **Security** | Injection, XSS | Prompt injection, jailbreak, data exfiltration |

### Observability Tools

| Tool | Open Source | Hosted | Fitur Kunci | Best For |
|------|------------|--------|-------------|----------|
| **Langfuse** | ✅ Yes | ✅ | Tracing, prompt management, evaluation, cost tracking | Production LLM stack |
| **LangSmith** | ❌ | ✅ | Tracing, dataset, annotation, A/B testing | LangChain-heavy stack |
| **W&B Prompts** | ❌ | ✅ | Prompt versioning, model comparison | ML research teams |
| **Helicone** | ✅ Yes | ✅ | Proxy-based logging, cost analytics | Simple setup, proxy |
| **Arize Phoenix** | ✅ Yes | ✅ | LLM tracing, embedding drift, RAG analysis | Embedding-focused |
| **SigNoz** | ✅ Yes | ✅ | APM + LLM tracing | All-in-one observability |
| **OpenObserve** | ✅ Yes | ✅ | Log, metrics, traces — LLM support | SRE teams |

### Langfuse: Core Concepts

```
Application → Langfuse SDK → Langfuse Backend (self-host / cloud)
                  │
            ┌─────┼─────┐
            │     │     │
         Trace  Span  Observation

Trace = satu request (e.g., "Jawab pertanyaan user")
  Span = satu langkah (e.g., RAG retrieval, LLM call, tool call)
    Observation = metric tambahan (token count, latency, cost)
```

### Tracing Flow
```
User Query → [Trace start]
  │
  ├─ [Span: RAG Retrieval]
  │    Observation: top_k=5, latency=45ms, source=dense+bm25
  │
  ├─ [Span: LLM Call]
  │    Observation: model=gpt-4, tokens=423, cost=$0.012, latency=1.2s
  │    Input: system + context + query
  │    Output: generated answer
  │
  └─ [Span: Guardrail Check]
       Observation: passed=true, categories checked=[toxicity, PII]
       Score: 0.95

→ [Trace end] total_latency=1.3s, total_cost=$0.013
```

### What to Trace (Minimum)

| Component | Track | Why |
|-----------|-------|-----|
| **LLM Call** | Model, prompt, response, token count, latency, cost | Billing, quality, debug |
| **RAG Retrieval** | Query, top-k, source scores, document IDs | Debug retrieval quality |
| **Tool Call** | Tool name, args, result, latency | Debug agent loop |
| **Guardrail** | Check type, passed/failed, score | Safety monitoring |
| **User Feedback** | Thumbs up/down, rating 1-5 | Quality metrics |

## Prompt Management & Versioning

### Masalah tanpa Prompt Management
- Prompt ada di **codebase** — ganti prompt = deploy ulang (slow)
- Tidak ada **version history** — "siapa yang ngubah prompt kemarin?"
- Tidak ada **A/B testing** — "apakah prompt baru lebih bagus?"
- Prompt berantakan — inline string panjang di Python file

### Prompt Management Tools

| Tool | Versioning | A/B Test | Deploy Rollback | API | Self-host |
|------|-----------|----------|-----------------|-----|-----------|
| **Langfuse Prompts** | ✅ Git-like | ✅ | ✅ | ✅ REST/SDK | ✅ |
| **LangSmith Hub** | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Portkey** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Agenta** | ✅ | ✅ | ✅ | ✅ | ✅ |

### Prompt Engineering Workflow di Production
```
Dev:     Tulis prompt di Langfuse UI atau code → test dengan dataset
Review:  Bandingkan output old vs new prompt
Deploy:  Publish version baru — SDK tarik versi terbaru secara real-time
Monitor: Bandingkan skor evaluasi antara prompt version
Rollback: Rollback ke versi sebelumnya 1 klik (tanpa deploy code)
```

## Vector Database Operations

### Index Maintenance

| Operation | Frequency | Impact | Notes |
|-----------|-----------|--------|-------|
| **Index Build** | Once (initial) | Full rebuild — semua data | Pakai IVFFlat untuk fast build pertama |
| **Incremental Insert** | Continuous | Minimal — HNSW support dynamic insert | Tidak perlu rebuild |
| **Index Optimize** | Weekly / after bulk insert | Medium — rebuild HNSW graph | Vacuum + optimize |
| **Reindex** (full) | Monthly / schema change | High — downtime | Swap index, not rebuild in-place |
| **Prune** (delete) | As needed | Medium — tombstone segments | Rebuild after many deletes |

### Indexing Strategy

| Strategy | Write Volume | Query Latency | Memory | Best For |
|----------|-------------|---------------|--------|----------|
| **Immediate index** | Low | Low | High | Production, <100K docs |
| **Batch index** (interval) | High | Medium | Medium | Streaming pipeline |
| **Hybrid** (immediate + batch) | Variable | Low-Medium | High | Production, any scale |
| **Separate indexes** (hot/warm) | N/A | Hot=Low, Warm=Medium | Optimized | Tiered storage (SSD+HDD) |

### Monitoring Vector DB

| Metric | What It Tells | Action If Bad |
|--------|--------------|---------------|
| **Recall@k** | Fraction of relevant results in top-k | Reindex, check embedding model |
| **Index fullness** | % of capacity used | Scale up or prune |
| **Avg query latency** | Search speed | Optimize HNSW ef_construction, ef_search |
| **Index size on disk** | Storage cost | Quantization (SQ/PC) |
| **Delete/update throughput** | Churn rate | Schedule rebuild during low traffic |

## Cost Tracking & Optimization

### LLM Cost Breakdown

| Component | % of Total | Optimization |
|-----------|-----------|-------------|
| **LLM API calls** | 60-80% | Model routing, caching, prompt compression |
| **Vector DB** | 5-10% | Index optimization, tiered storage |
| **Embedding** | 5-15% | Cache embeddings, batch embed |
| **GPU serving** (self-host) | 10-30% | vLLM, quantization, batching |
| **Infrastructure** (network, k8s) | 5-10% | Reserved instances, spot |

### Cost Optimization Strategies

#### 1. Model Routing
```python
# Cheap model untuk simple task, expensive untuk complex
route = {
    "classification": "gpt-4o-mini",    # $0.15/1M tokens
    "summarization": "claude-3-haiku",   # $0.25/1M
    "complex_reasoning": "claude-3-opus", # $15/1M
    "code_generation": "deepseek-v4",    # $1/1M
}
```

#### 2. Semantic Caching
Cache response untuk query yang semantically **mirip** (bukan exact match).
```
Query: "Apa itu Kubernetes?"
Cached: "Jelaskan K8s" → similarity 0.92 > threshold 0.85 → return cached response
```

#### 3. Prompt Compression
- **Prefix caching** — cache system prompt + fixed context
- **Context pruning** — hapus dokumen RAG dengan relevance score rendah
- **LLMLingua** — compress prompt dengan lossy compression
- **Chain of thought distillation** — short CoT → even shorter CoT

#### 4. Batching
```python
# ❌ Buruk: 10 API call sequential
for q in queries:
    llm.call(q)

# ✅ Baik: 1 batch call (disk10-30%)
response = llm.batch(queries, max_tokens=512)  # 1 call, 10 queries
```

#### 5. Self-Hosting GPU
| Model | GPU Needed | Approx Cost/Month (on-prem) | API Cost/Month @ 1M tokens/day |
|-------|-----------|---------------------------|-------------------------------|
| Llama 3 8B | 1x RTX 4090 | $200 | $300-500 |
| Llama 3 70B | 2x A100 | $2,000 | $3,000-5,000 |
| DeepSeek V3 | 8x H100 | $15,000 | $10,000-20,000 |

## LLM Caching

### Types of LLM Cache

| Cache Type | Granularity | Hit Rate | Implementation |
|-----------|------------|----------|----------------|
| **Exact match** | Full input | Low (10-20%) | Redis: key=hash(input), value=response |
| **Semantic** | Query meaning | Medium (20-40%) | Embed query → nearest neighbor → check similarity |
| **KV Cache** | Per token (self-attention) | High (80%+) | GPU memory — vLLM, TensorRT-LLM |
| **Prefix Cache** | System prompt | High (50%+) | Cache compute prefix across requests |

### KV Cache (Production LLM)
```
Tanpa KV cache: tiap token baru recompute semua attention → O(n²)
Dengan KV cache: simpan Key/Value dari token sebelumnya → O(n)

Ukuran KV cache per request:
  2 (key+value) × n_layers × d_model × seq_len × precision
  Llama 70B: ~1.5GB per request pada seq_len=4096
```

## Production Deployment

### Architecture Reference
```
User → Load Balancer → Guardrails → Router → LLM Provider
                              │
                     ┌────────┴────────┐
                     │                 │
               Cache Hit         Cache Miss
                     │                 │
               Return Cache      RAG Pipeline
                                    │
                              Vector DB Query
                                    │
                              LLM Call + Observability
                                    │
                              Response + Cost Log
                                    │
                              Return to User
```

### Guardrails

| Guardrail | Function | Implementation |
|-----------|----------|----------------|
| **Input guard** | Deteksi prompt injection, jailbreak | LLM-as-judge, regex, ML classifier |
| **Output guard** | Deteksi PII, toxic content, hallucination | PII masking, toxicity classifier, factual consistency |
| **Rate limit** | Batasi requests/user | Token bucket, sliding window |
| **Cost limit** | Budget per user/session/day | Langfuse cost tracking + alert |

### Canary Deploy untuk LLM
```
1. 90% traffic → model v1 (stable)
2. 10% traffic → model v2 (new)
3. Bandingkan metrics: latency, cost, user feedback score
4. Evaluasi: apakah v2 > v1?
5. Jika ya: roll out 25% → 50% → 100%
6. Jika tidak: rollback ke v1, debug, repeat
```

## Tool Comparison

| Fungsinya | Tools | Best For |
|-----------|-------|----------|
| **LLM Observability** | Langfuse, LangSmith, W&B Prompts | Production tracing & monitoring |
| **Prompt Management** | Langfuse Prompts, Portkey, Agenta | Versioning & deploy prompts |
| **Vector DB Ops** | Qdrant, Weaviate, Milvus, pgvector | Indexing, CRUD, scale |
| **Model Serving** | vLLM, TGI, TensorRT-LLM, Ollama | Self-hosted inference |
| **Cost Tracking** | Langfuse, Helicone, Portkey | Budget & billing |
| **Guardrails** | Guardrails AI, NVIDIA NeMo, Azure AI Content Safety | Safety & compliance |
| **Evaluation** | RAGAS, DeepEval, Langfuse Eval | Automated quality metrics |

---

## Koneksi ke Vault

- [[ai-evaluation-framework]] — RAG evaluation, RAGAS, LLM-as-Judge — komponen evaluasi dalam LLMOps
- [[vector-database-internals-optimization]] — HNSW/IVF, quantization — index maintenance strategies
- [[production-model-serving-optimization]] — vLLM, TensorRT, continuous batching — inference serving
- [[ai-engineering-stack-roadmap]] — Posisi LLMOps dalam AI engineering stack
- [[rag-pipeline-end-to-end-guide]] — RAG pipeline production deployment
- [[hallucination-mitigation-grounding]] — Guardrails & grounding techniques
- [[query-transformation-rag]] — Query routing, rewite — bagian dari LLMOps optimization
- [[embedding-model-selection-finetuning]] — Embedding model ops & maintenance
