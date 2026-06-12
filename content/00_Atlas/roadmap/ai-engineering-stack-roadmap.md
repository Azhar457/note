---
tags:
  - ai-engineering
  - mlops
  - llm-ops
  - on-prem
  - bare-metal
  - homelab
  - roadmap
  - model-serving
  - rag
  - evaluation
aliases:
  - Roadmap AI Engineer
  - Roadmap MLOps / LLMOps
  - Roadmap On-Prem AI Stack
created: 2026-05-29
status: active
cssclasses:
  - wide-table
---

# 🧠 Roadmap AI Engineering Stack — Bare-Metal On-Prem & Homelab

> [!quote] Filosofi
> Jangan hanya "fine-tune di Colab" — kamu harus bisa "operate." Bedanya besar: menjalankan `ollama run llama3` itu 2 menit, tapi operate multi-model gateway dengan KV cache optimization, RAG reranking, hallucination tracking, dan automated red-team pipeline itu skill yang membedakan engineer dari notebook hobbyist. Rekruter akan tanya: "Latency melonjak 400ms saat context window penuh, apa yang terjadi di backend dan bagaimana kamu mitigasi tanpa ganti hardware?" Kalau kamu jawab: "KV cache eviction policy diaktifkan, speculative decoding di-disable untuk prioritas throughput, fallback ke smaller quantized model via LiteLLM router, dan Langfuse trace menunjukkan bottleneck di embedding retrieval, bukan LLM inference" — itu yang menutup pertanyaan.

## 🎯 Checkpoint Awal — Sebelum Mulai

- **Stack:** Ollama / vLLM (single-node) → FastAPI → PostgreSQL + pgvector / Qdrant
- **Jalur:** AI Engineer → MLOps/LLMOps Engineer → AI Infrastructure Lead
- **Spek Dasar:** i7 Gen7, 8GB RAM, GTX 1050 (⚠️ VRAM 2GB sangat terbatas. Kuantisasi 4-bit/8-bit, CPU offload, atau cloud GPU spot instance wajib untuk fase 3+)
- **Target Karir:** AI Systems Engineer → AI Platform Lead → MLOps Architect

### Homelab Strategy untuk VRAM/RAM Terbatas

- **Fase 1-2:** CPU inference + Q4_K_M quantization, model ≤ 3B, Docker resource limits ketat.
- **Fase 3-4:** RAG pipeline jalankan terpisah dari inference server, gunakan SQLite/Chroma dulu sebelum Qdrant untuk hemat RAM.
- **Fase 5-6:** Cloud GPU trial (RunPod / Vast.ai ~$0.20/jam) hanya untuk evaluation benchmark & red-team stress test.
- **Prioritas:** Data pipeline reproducibility → Serving latency control → Evaluation metrics → Security guardrails.

### Urutan Belajar

1.  **Fase 1 (Foundation):** Local serving + quantization + OpenAI-compatible API
2.  **Fase 2 (Data):** Ingestion pipeline + chunking strategy + vector DB + embedding selection
3.  **Fase 3 (Architecture):** Advanced RAG + reranking + agent state machine + caching
4.  **Fase 4 (MLOps):** Experiment tracking + DVC + CI/CD for AI + versioned prompts
5.  **Fase 5 (Observe & Secure):** Tracing + evaluation framework + guardrails + automated red team
6.  **Fase 6 (Operate & Scale):** Multi-model routing + inference optimization + AI compliance + cost control

**Next step:** Install Ollama/vLLM, pull Qwen2.5-1.5B-Q4_K_M, expose OpenAI-compatible API via FastAPI, ukur tokens/sec dan TTFT (Time To First Token).

> [!warning] Aturan Emas
> Satu pipeline dulu. Selesaikan sampai bisa reproduce experiment, track version, monitor latency, dan block malicious prompt secara otomatis, baru loncat ke layer berikutnya. AI infrastructure adalah rantai probabilistik — jika satu link lemah (data, cache, guardrail), seluruh output jadi tidak trustworthy.

---

## Fase 1 — Local Model Serving & Quantization (Minggu 1–4)

**Goal:** Kuasai inference engine, quantization trade-off, dan API standardization.
**Resource Impact:** vLLM/Ollama ~2GB RAM + VRAM tergantung model. Q4_K_M 3B model ≈ 2GB VRAM aman.

| Tool/Stack           | Resource               | Yang Dipelajari                                                                                                         | Combo A+B yang Membuktikan                                                                                       |
| :------------------- | :--------------------- | :---------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------- |
| **Ollama / vLLM**    | Host ~1–2GB RAM + VRAM | PagedAttention, KV cache management, quantization formats (GGUF/AWQ), continuous batching, OpenAI API compatibility     | **vLLM + benchmarking script** = kamu bisa ukur throughput (tokens/sec) vs context length secara empiris         |
| **FastAPI**          | ~256MB                 | Async routing, request validation (Pydantic), streaming response (SSE), health check, rate limiting middleware          | **FastAPI + vLLM backend** = kamu punya production-ready inference endpoint dalam <50 line kode                  |
| **Docker / Compose** | ~512MB                 | Multi-stage build, resource limits (CPU/RAM/VRAM passthrough), network isolation, volume management untuk model weights | **Docker + reproducible inference** = setup berjalan identik di laptop, server, atau cloud tanpa dependency hell |
| **PyTorch Basics**   | ~1GB                   | Tensor shape, device placement, model loading, `torch.no_grad()`, memory profiling (`torch.cuda.memory_summary`)        | **PyTorch + memory audit** = kamu paham kenapa OOM terjadi dan cara debug tanpa tebak-tebakan                    |

> [!tip] Cara Belajar Fase 1
> Deploy vLLM di bare metal. Expose OpenAI-compatible API. Kirim 100 concurrent request. Ukur TTFT (Time To First Token), P99 latency, dan GPU utilization. Ganti quantization Q4 → Q8 → FP16. Dokumentasikan trade-off. Ulangi sampai pipeline tidak crash saat context window penuh.

**Proyek Portofolio Fase 1:** `Bare-Metal LLM Inference Server` — dokumentasi lengkap: vLLM config, quantization benchmark table, Docker Compose file, FastAPI streaming endpoint, load test result (k6/Locust) dengan grafik latency vs concurrency.

---

## Fase 2 — Data Pipeline & Vector Infrastructure (Minggu 5–8)

**Goal:** Bangun ingestion pipeline yang reproducible, kuasai chunking strategy, dan implement vector search.
**Resource Impact:** Embedding model ~1GB VRAM, Vector DB ~512MB–1GB RAM, ETL tools ~256MB.

| Tool/Stack                      | Resource | Yang Dipelajari                                                                                                | Combo A+B yang Membuktikan                                                                                             |
| :------------------------------ | :------- | :------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------- |
| **MinIO / Local Storage**       | ~256MB   | S3-compatible API, versioning, lifecycle policy, TLS for data at rest                                          | **MinIO + structured dataset version** = raw data tidak pernah hilang atau teroverwrite tanpa audit trail              |
| **pgvector / Qdrant**           | ~512MB   | HNSW index, cosine vs dot product, metadata filtering, ANN vs exact search trade-off                           | **pgvector + recall@K metric** = kamu bisa justify kenapa index tertentu dipilih berdasarkan query pattern             |
| **LangChain / LlamaIndex Core** | ~256MB   | Document loaders, text splitters (recursive, semantic, markdown), embedding pipeline, vector store integration | **LlamaIndex + chunking benchmark** = kamu bisa tunjukkan recall improvement dari 300-token fixed vs semantic chunking |
| **Unstructured / DuckDB**       | ~512MB   | OCR pipeline, table extraction, schema validation, SQL-on-JSON/Parquet                                         | **Unstructured + DuckDB ETL** = kamu bisa transform PDF/HTML menjadi structured records tanpa regex hack               |

> [!warning] Realita Chunking
> Ukuran chunk bukan parameter ajaib. Strategi chunking menentukan recall lebih besar daripada model size. Chunk terlalu kecil = context hilang. Chunk terlalu besar = noise masuk. Selalu ukur recall@K dan precision sebelum deploy.

**Proyek Portofolio Fase 2:** `Document Ingestion & Vector Search Pipeline` — diagram data flow, chunking strategy comparison table, embedding model benchmark (speed vs quality), pgvector index config, search API dengan recall/precision metrics.

---

## Fase 3 — Advanced RAG & Agent Architecture (Minggu 9–12)

**Goal:** Implement hybrid search, reranking, query rewriting, dan agent loop dengan state machine yang deterministic.
**Resource Impact:** Reranker model ~1GB VRAM, Cache/Agent ~512MB RAM, Redis ~256MB.

| Tool/Stack                           | Resource | Yang Dipelajari                                                                                                         | Combo A+B yang Membuktikan                                                                                 |
| :----------------------------------- | :------- | :---------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------- |
| **Advanced RAG Patterns**            | ~256MB   | Hybrid search (BM25 + vector), query expansion, self-query, context compression, reranking (Cross-Encoder)              | **Reranker + precision@3 metric** = kamu bisa tunjukkan peningkatan relevansi tanpa tambah context window  |
| **LangGraph / Custom State Machine** | ~512MB   | Finite state machine for agents, tool routing, human-in-the-loop, checkpoint/rollback, deterministic vs stochastic flow | **LangGraph + tool failure recovery** = agent tidak hang atau loop tak terbatas saat tool error            |
| **Redis / Memcached**                | ~256MB   | Semantic cache, TTL management, cache invalidation strategy, hit-rate monitoring                                        | **Redis + semantic cache** = kamu reduce API call 40% tanpa degrade response quality                       |
| **Nginx / HAProxy**                  | ~128MB   | API routing, request buffering, timeout management, circuit breaker pattern                                             | **HAProxy + fallback routing** = traffic otomatis switch ke smaller model saat primary latency > threshold |

> [!tip] Agent Tanpa State Machine = Chaos
> Framework agent yang mengandalkan "LLM memutuskan sendiri kapan stop" tidak production-ready. Selalu gunakan explicit state graph, define retry limits, dan instrument setiap transition. Determinism > autonomy di production.

**Proyek Portofolio Fase 3:** `Production RAG Agent` — architecture diagram (retriever → reranker → generator → tool executor), cache hit-rate dashboard, state machine config, latency breakdown per component, failure recovery log.

---

## Fase 4 — MLOps, Experiment Tracking & CI/CD for AI (Minggu 13–16)

**Goal:** Version control data, model, dan prompt. Otomasi evaluasi dan deployment pipeline.
**Resource Impact:** MLflow/DVC ~512MB, CI Runner ~1GB, Monitoring ~256MB.

| Tool/Stack                     | Resource | Yang Dipelajari                                                                                       | Combo A+B yang Membuktikan                                                                |
| :----------------------------- | :------- | :---------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------- |
| **MLflow / Weights & Biases**  | ~512MB   | Experiment tracking, model registry, artifact versioning, parameter logging, comparison UI            | **MLflow + reproducible run** = kamu bisa rollback ke experiment spesifik dalam 1 command |
| **DVC (Data Version Control)** | ~256MB   | Data pipeline tracking, remote storage sync, pipeline DAG, metric logging                             | **DVC + Git** = data dan kode selalu sinkron, tidak ada "model ini pakai data yang mana?" |
| **GitHub Actions**             | N/A      | AI-specific CI: lint prompts, run evaluation suite, build Docker, push to registry, deploy to staging | **GitHub Actions + automated eval** = model tidak deploy jika hallucination rate > 5%     |
| **Evidently AI / Prometheus**  | ~512MB   | Data drift detection, concept drift, feature distribution shift, alerting integration                 | **Evidently + drift alert** = kamu detect degradation sebelum user komplain               |

> [!warning] Prompt Adalah Kode
> Jika prompt tidak di-version control, di-review, dan di-test, itu technical debt yang menunggu waktu. Treat prompt seperti production config. Simpan di Git, review via PR, test via automated eval.

**Proyek Portofolio Fase 4:** `AI Model & Prompt CI/CD Pipeline` — repo structure, DVC pipeline YAML, MLflow experiment dashboard screenshot, GitHub Actions workflow (eval → gate → deploy), prompt versioning history, rollback procedure.

---

## Fase 5 — Observability, Evaluation & Security (Minggu 17–20)

**Goal:** Ukur hallucination, latency, cost, dan implement guardrail + automated red team.
**Resource Impact:** Langfuse/Otel ~512MB, Garak/PyRIT ~1GB, Guardrails ~512MB.

| Tool/Stack                     | Resource | Yang Dipelajari                                                                                      | Combo A+B yang Membuktikan                                                                          |
| :----------------------------- | :------- | :--------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| **Langfuse / OpenLLMetry**     | ~512MB   | Distributed tracing, span annotation, cost tracking, user feedback loop, session replay              | **Langfuse + trace correlation** = kamu bisa debug hallucination dari raw prompt sampai final token |
| **DeepEval / Ragas**           | ~256MB   | Automated evaluation metrics: faithfulness, answer relevancy, context precision, hallucination score | **Ragas + CI gate** = deploy diblokir otomatis jika faithfulness < 85%                              |
| **Garak / PyRIT / LlamaGuard** | ~1GB     | Automated red teaming, prompt injection testing, safety classification, guardrail integration        | **Garak + LlamaGuard** = kamu punya pre-deploy security audit report yang terdokumentasi            |
| **NeMo Guardrails**            | ~512MB   | Input/output flow definition, regex + LLM-based filters, dynamic policy update, fallback routing     | **NeMo + Colang flows** = prompt injection ter-block tanpa matiin seluruh endpoint                  |

> [!tip] Evaluasi Tanpa Baseline = Teater
> Jangan percaya angka "accuracy 95%" tanpa tahu baseline, dataset composition, dan edge cases. Selalu bandingkan dengan deterministic baseline (keyword search, rule-based system) dan dokumentasikan failure mode.

**Proyek Portofolio Fase 5:** `AI Observability & Security Dashboard` — Langfuse trace example, Ragas evaluation report, Garak scan output, NeMo guardrail config, hallucination trend chart, incident response playbook untuk AI failure.

---

## Fase 6 — Advanced Optimization, Scale & Compliance (Minggu 21–24)

**Goal:** Model routing, inference optimization, AI governance, dan cost-aware operation.
**Resource Impact:** Router/Proxy ~256MB, Optimization tools ~512MB, Compliance docs ~N/A.

| Tool/Stack                               | Resource | Yang Dipelajari                                                                                            | Combo A+B yang Membuktikan                                                                  |
| :--------------------------------------- | :------- | :--------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| **LiteLLM / OpenRouter Proxy**           | ~256MB   | Multi-model routing, cost/latency balancing, fallback chains, API key rotation, rate limit distribution    | **LiteLLM + cost tracker** = kamu route request ke model termurah yang masih memenuhi SLA   |
| **vLLM Advanced / Speculative Decoding** | ~1GB     | Draft-verify pipeline, KV cache optimization, continuous batching tuning, tensor parallelism konsep        | **Speculative decoding + throughput chart** = latency turun 30% tanpa akurasi hilang        |
| **AI Compliance & Audit**                | N/A      | EU AI Act mapping, NIST AI RMF, data privacy (GDPR/PII redaction), model card documentation, bias audit    | **Compliance pack + automated PII check** = kamu siap audit tanpa manual gathering          |
| **Cost & Resource Management**           | ~256MB   | GPU utilization monitoring, auto-scaling logic, spot instance strategy, egress cost control, cache hit ROI | **Prometheus + cost dashboard** = kamu bisa justify infra spend berdasarkan ROI per request |

**Proyek Portofolio Fase 6:** `Multi-Model AI Gateway + Compliance Pack` — routing config, speculative decoding benchmark, EU AI Act control mapping table, PII redaction test result, cost/latency optimization report, audit trail sample.

---

## 🗺️ Roadmap Visual — Timeline 6 Bulan

| Bulan 1                                             | Bulan 2                                                   | Bulan 3                                          | Bulan 4                                        | Bulan 5                                              | Bulan 6                                                 |
| :-------------------------------------------------- | :-------------------------------------------------------- | :----------------------------------------------- | :--------------------------------------------- | :--------------------------------------------------- | :------------------------------------------------------ |
| **FASE 1**<br>Serving & Quant                       | **FASE 2**<br>Data & Vector                               | **FASE 3**<br>RAG & Agent                        | **FASE 4**<br>MLOps & CI/CD                    | **FASE 5**<br>Observe & Secure                       | **FASE 6**<br>Scale & Comply                            |
| vLLM                                                | MinIO                                                     | LangGraph                                        | MLflow                                         | Langfuse                                             | LiteLLM                                                 |
| FastAPI                                             | pgvector                                                  | Reranker                                         | DVC                                            | DeepEval                                             | Speculative Dec                                         |
| Docker                                              | LlamaIndex                                                | Redis Cache                                      | GitHub Actions                                 | Garak                                                | AI Compliance                                           |
| PyTorch                                             | Unstructured                                              | HAProxy                                          | Evidently                                      | NeMo Guard                                           | Cost Tracking                                           |
| Benchmark                                           | Chunking Strategy                                         | State Machine                                    | Prompt Versioning                              | Red Team Report                                      | Routing Policy                                          |
| **Portfolio 1:**<br>Inference Server<br>+ Load Test | **Portfolio 2:**<br>Ingestion Pipeline<br>+ Vector Search | **Portfolio 3:**<br>RAG Agent<br>+ Cache + State | **Portfolio 4:**<br>AI CI/CD<br>+ DVC + MLflow | **Portfolio 5:**<br>Observe Dashboard<br>+ Guardrail | **Portfolio 6:**<br>Multi-Model Gateway<br>+ Compliance |

---

## 🎓 Sertifikasi yang Cocok per Fase

| Fase               | Sertifikasi / Milestone                               | Kenapa                                                                    |
| :----------------- | :---------------------------------------------------- | :------------------------------------------------------------------------ |
| **Setelah Fase 1** | NVIDIA DLI: Fundamentals of Accelerated Computing     | Validasi pemahaman GPU memory management & inference basics               |
| **Setelah Fase 2** | Databricks: Data Engineering Associate                | Pipeline reproducibility, ETL best practice, vector DB foundation         |
| **Setelah Fase 3** | Linux Foundation: MLOps Fundamentals                  | Agent architecture, caching, routing, production patterns                 |
| **Setelah Fase 4** | MLflow Certified Practitioner (atau portfolio setara) | Experiment tracking, model registry, CI/CD for AI adalah standar industri |
| **Setelah Fase 5** | OWASP AI Security & MITRE ATLAS Awareness             | Guardrail, red teaming, observability, hallucination tracking             |
| **Setelah Fase 6** | NIST AI RMF Compliance Mapping (self-audit)           | Governance, cost control, multi-model routing, audit readiness            |
| **Jangka Panjang** | Kubernetes AI/ML Operator / Custom Platform           | Scale-out, distributed inference, enterprise AI platform architecture     |

---

## ⛔ Yang TIDAK Perlu Dipelajari Sekarang

> [!warning] Jangan Buang Waktu
>
> - **Cloud-managed AI penuh** (SageMaker, Vertex AI, Azure ML) — fokus stack ini on-prem/bare-metal, kontrol penuh > kemudahan terkelola.
> - **Training model dari nol** (pre-training/fine-tuning besar) — ini track Research/ML Engineer, bukan AI/Platform Engineer. Fokus pada serving, RAG, MLOps, security.
> - **Frontend/UI framework** (React, Streamlit, Gradio) — kamu build backend pipeline & infrastructure, bukan dashboard. UI adalah konsumen, bukan core stack.
> - **Chasing SOTA paper tanpa deployment context** — paper penting untuk referensi, tapi production mengutamakan latency, cost, reproducibility, dan reliability.
> - **Prompt engineering kursus "rahasia"** — prompt adalah config, bukan skill mistis. Pelajari versioning, testing, dan guardrail.
> - **Entry-level data cleaning / manual labeling** — otomasi ingestion, chunking, dan evaluation. Engineer tidak label data manual di production.
> - **CISSP / Compliance umum tanpa AI context** — fokus pada EU AI Act, NIST AI RMF, dan data privacy spesifik untuk LLM/AI.

---

## 🔗 Lihat Juga

- [[llm-security-red-teaming-attack-surface-ai-layer]] — LLM Attack Surface, Prompt Injection, Red Teaming, Guardrails
- [[infrastructure-administrator]] — Bare-metal foundation, observability, HA, compliance
- [[Note/01_Library/Cyber_Security/network-security]] — API gateway, rate limiting, supply chain validation
- [[endpoint-security]] → BYOVD → BYOM (Bring Your Own Model) security pattern overlap

_Roadmap AI Engineering | Fase 1 (Serving) → Fase 6 (Scale & Compliance) · 6 Bulan Homelab · Bare-Metal On-Prem Focus_
