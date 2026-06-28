---
tags:
  - roadmap
  - agentic-ai
  - mcp
  - ai-agents
  - llm-tool-use
  - multi-agent
  - autonomous-systems
aliases:
  - Roadmap Agentic AI & MCP
  - Roadmap AI Agent Engineering
  - Roadmap Model Context Protocol
  - Roadmap Autonomous AI Systems
created: 2026-05-29
status: active
cssclasses:
  - wide-table
---

# 🤖 Roadmap Agentic AI & MCP — From Script to Autonomous Swarm

> [!tip] **Filosofi:** Jangan hanya "prompt" — kamu harus bisa "orchestrate." Bedanya besar: chat dengan ChatGPT itu 5 menit, tapi membangun agent yang bisa sense → plan → act → observe secara loop, dengan tool use, memory, dan self-correction, itu skill yang ditanya waktu interview. Rekruter akan tanya: "Oke, agent-mu stuck di infinite loop saat tool call gagal — apa yang terjadi?" Kalau kamu jawab: "Agent punya max_iterations guard, fallback strategy ke human-in-the-loop, dan observability log setiap reasoning step via Langfuse" — itu yang menutup pertanyaan.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

- **Stack**: Python 3.11+, Node.js 20+, Ollama / LM Studio (local LLM) atau NVIDIA NIM free tier
- **Jalur**: AI Agent Engineer / Autonomous Systems Developer
- **Spek**: i7 Gen7, 16GB RAM minimum (⚠️ 32GB+ direkomendasikan untuk multi-agent + embedding)
- **Target Karir**: AI Engineer → Agent Architect → Autonomous Systems Lead

**Homelab Strategy untuk 16GB RAM:**

- Fase 1-2: Single agent, Ollama 7B model, local embedding (fastembed), SQLite vector store
- Fase 3-4: Multi-agent (2-3 agents), Ollama 14B model, ChromaDB / Qdrant, MCP server local
- Fase 5-6: Agent swarm, cloud VPS untuk model besar (NVIDIA NIM free tier), distributed memory
- Prioritas: Belajar agent loop & tool use dulu, scale horizontal belakangan

**Urutan belajar:**

- **Fase 1 (foundation)**: LLM API → Prompt engineering → Structured output (JSON mode)
- **Fase 2 (tool use)**: Function calling → Tool definition → ReAct loop → Error handling
- **Fase 3 (memory)**: Short-term (conversation) → Long-term (vector DB) → Semantic memory
- **Fase 4 (MCP)**: MCP server build → MCP client → Tool discovery → Multi-server orchestration
- **Fase 5 (multi-agent)**: Agent delegation → Conflict resolution → Shared state → Swarm pattern
- **Fase 6 (autonomous)**: Self-reflection → Goal decomposition → Human-in-the-loop → Observability

> [!warning] Aturan Emas
> **Satu agent dulu.** Selesaikan sampai agent-mu bisa handle edge case (tool failure, hallucination, context overflow) tanpa crash, baru loncat ke multi-agent. Agentic AI adalah tumpukan kartu — fondasi goyang, semua runtuh.

---

## Fase 1 — LLM Foundation & Structured Output (Minggu 1–4)

> **Goal:** Kuasai komunikasi dengan LLM secara programmatic. JSON mode, streaming, dan system prompt engineering adalah fondasi segalanya.
> **RAM Impact:** Ollama 7B ~4-6GB, Python ~512MB. Total aman untuk 16GB.

| Tool/Stack                | RAM    | Yang Dipelajari                                                                                          | Combo A+B yang Membuktikan                                                                    |
| ------------------------- | ------ | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Ollama / LM Studio**    | ~4-6GB | Local LLM serving, model quantization (Q4_K_M, Q8_0), context length tuning, GPU offloading              | Ollama + **custom Modelfile** = kamu bisa serve model dengan context 64k+ tanpa cloud API     |
| **OpenAI-compatible SDK** | ~256MB | Chat completion API, streaming, JSON mode, system/user/assistant roles, temperature/top_p tuning         | SDK + **structured output schema** = LLM output selalu valid JSON, parseable tanpa regex hack |
| **Pydantic**              | ~128MB | Data validation, schema definition, type hints integration                                               | Pydantic + **JSON mode** = output LLM langsung jadi Python object dengan type safety          |
| **Prompt Engineering**    | N/A    | System prompt design, few-shot prompting, chain-of-thought, role definition, output format specification | Prompt + **Pydantic schema** = LLM yang "berpikir" dalam format yang kamu tentukan            |

> [!tip] Cara Belajar Fase 1
> Build 1 script Python yang: (1) load Ollama model, (2) kirim system prompt dengan Pydantic schema, (3) parse output jadi object, (4) validate dengan Pydantic. Ulangi dengan 10 skema berbeda (summarization, classification, extraction). **Ulangi sampai tidak perlu buka dokumentasi.**

**Proyek Portofolio Fase 1:**
`Structured Output Engine — Local LLM` — repo Python dengan: Ollama Modelfile custom, 5+ Pydantic schema (summary, classify, extract, generate, translate), streaming handler, error retry logic. Sertakan benchmark: "100 requests, 98% valid JSON output."

---

## Fase 2 — Tool Use & ReAct Loop (Minggu 5–8)

> **Goal:** Agent tidak hanya chat — dia bisa "berbuat." Function calling adalah jembatan dari language ke action.
> **RAM Impact:** Ollama 7B ~4-6GB, tools (calculator, search, file ops) ~512MB. Total ~7GB.

| Tool/Stack                 | RAM    | Yang Dipelajari                                                                                                                  | Combo A+B yang Membuktikan                                                          |
| -------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Function Calling**       | N/A    | Tool definition (OpenAI format), `tools` parameter, parallel tool calls, tool result injection kembali ke context                | Function calling + **Pydantic schema** = tool argument selalu typed dan validated   |
| **ReAct Pattern**          | N/A    | Reasoning → Action → Observation loop, max_iterations guard, early termination, self-correction                                  | ReAct + **structured logging** = setiap reasoning step terdokumentasi dan auditable |
| **Custom Tools**           | ~256MB | Build tool dari Python function: file read/write, web search (DuckDuckGo API), calculator, date/time, system command (sandboxed) | Custom tools + **error handling** = agent survive waktu tool gagal, tidak crash     |
| **LangChain / LlamaIndex** | ~512MB | Agent executor, tool binding, memory integration, callback system                                                                | LangChain + **custom ReAct** = agent framework yang extensible, bukan black box     |

> [!warning] Critical
> **Error handling adalah beda script dan agent.** Script crash kalau API gagal. Agent harus: retry dengan exponential backoff, fallback ke tool alternatif, atau escalate ke human. Tanpa ini, itu hanya chatbot dengan extra steps.

**Proyek Portofolio Fase 2:**
`ReAct Agent with Tool Suite` — agent yang bisa: (1) baca file dari path, (2) search web, (3) kalkulasi, (4) tulis summary ke file. Semua dengan ReAct loop, max 10 iterations, error recovery, dan structured log setiap step. Sertakan demo video: "Agent handle 3 consecutive tool failures tanpa crash."

---

## Fase 3 — Memory Architecture (Minggu 9–12)

> **Goal:** Agent yang tidak punya memory adalah stateless API call. Memory adalah what makes an agent "personal" dan "contextual."
> **RAM Impact:** Ollama 7B ~4-6GB, ChromaDB ~512MB, embedding ~1GB. Total ~8GB.

| Tool/Stack                        | RAM    | Yang Dipelajari                                                                                                                   | Combo A+B yang Membuktikan                                                                   |
| --------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Short-term Memory**             | N/A    | Conversation buffer, sliding window, summarization when context overflow, token counting                                          | Buffer + **summarization trigger** = agent tidak pernah kehilangan thread meski chat panjang |
| **Vector DB (ChromaDB / Qdrant)** | ~512MB | Collection setup, embedding storage, similarity search, metadata filtering, persistence                                           | Vector DB + **semantic search** = agent ingat fakta dari 100+ conversation lalu              |
| **Embedding Model**               | ~1GB   | Local embedding (all-MiniLM, BGE, fastembed), dimensionality, cosine similarity, chunking strategy                                | Embedding + **chunking optimization** = retrieval accuracy >80% untuk dokumen teknis         |
| **Long-term Memory Pattern**      | N/A    | Entity memory (siapa, apa, kapan), episodic memory (event spesifik), procedural memory (cara kerja), semantic memory (fakta umum) | Memory layers + **retrieval strategy** = agent yang "mengenal" user dan konteks historis     |

> [!tip] Trik Memory
> Jangan simpan seluruh conversation mentah. Summarize per 5-10 turn, extract entities dan facts, store ke vector DB. Retrieval: semantic search + recency bias + importance scoring. **Ini bukan latihan, ini produksi.**

**Proyek Portofolio Fase 3:**
`Agent with Persistent Memory` — agent yang: (1) ingat fakta tentang user (nama, preferensi), (2) ingat task history, (3) bisa retrieve insight dari 50+ conversation lalu, (4) summarize conversation saat context penuh. Sertakan arsitektur diagram: memory flow dari input → process → store → retrieve.

---

## Fase 4 — Model Context Protocol (MCP) (Minggu 13–16)

> [!info] Integrasi Sistem Lokal
> Anda dapat melihat dokumentasi konfigurasi, skrip server, dan manajemen skill MCP lokal pada sistem Anda di [[agent/mcp-integration-guide|MCP Local Integration Guide]].

> **Goal:** MCP adalah "USB-C untuk AI tools." Standardize bagaimana agent discover, call, dan manage tools dari berbagai sumber.
> **RAM Impact:** Ollama 7B ~4-6GB, MCP servers ~512MB each, client ~256MB. Total ~8-10GB.

| Tool/Stack                | RAM    | Yang Dipelajari                                                                                                   | Combo A+B yang Membuktikan                                                                             |
| ------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **MCP Server (stdio)**    | ~256MB | Build MCP server dengan Python SDK: tool definition, resource exposure, prompt template, stdio transport          | MCP server + **3+ tools** = tool yang bisa dipakai oleh client apapun yang support MCP                 |
| **MCP Server (HTTP/SSE)** | ~256MB | HTTP transport, SSE streaming, multi-client support, authentication, rate limiting                                | HTTP MCP + **auth middleware** = production-ready tool server                                          |
| **MCP Client**            | ~256MB | Discover tools dari server, call tool via MCP protocol, handle resource URI, compose multi-server workflow        | MCP client + **2+ servers** = agent yang bisa pakai tool dari GitHub + filesystem + database sekaligus |
| **MCP Ecosystem**         | N/A    | Existing MCP servers: filesystem, GitHub, PostgreSQL, Brave Search, Slack, Puppeteer. Community servers registry. | Ecosystem + **custom server** = kamu bisa contribute ke MCP community, bukan cuma consume              |

> [!warning] Critical
> **MCP bukan cuma "wrapper API."** Bedanya: MCP server self-describe (tool schema, resource schema, prompt template). Client discover otomatis — tidak perlu hardcode tool definition di client. Tanpa pahami ini, itu hanya REST API dengan nama baru.

**Proyek Portofolio Fase 4:**
`MCP-Powered Agent with Multi-Server Orchestration` — build: (1) custom MCP server untuk vault Obsidian-mu (read note, search, write summary), (2) connect ke existing MCP server (filesystem, GitHub), (3) agent yang discover dan call tool dari semua server via MCP protocol. Sertakan: `mcp.json` config, server source code, client integration demo.

---

## Fase 5 — Multi-Agent & Swarm (Minggu 17–20)

> **Goal:** Satu agent bisa handle satu task. Tapi masalah nyata butuh dekomposisi: researcher → coder → reviewer → deployer.
> **RAM Impact:** Ollama 14B ~8-10GB, 3 agents ~512MB each, orchestrator ~256MB. Total ~12GB. Gunakan VPS untuk model besar.

| Tool/Stack           | RAM    | Yang Dipelajari                                                                                                           | Combo A+B yang Membuktikan                                                                   |
| -------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Agent Delegation** | N/A    | Parent agent decompose task → delegate ke child agent → collect result → synthesize. Task routing berdasarkan capability. | Delegation + **capability registry** = task selalu di-handle oleh agent yang paling kompeten |
| **Shared State**     | N/A    | Shared memory (blackboard pattern), message passing (actor model), event bus, state synchronization                       | Shared state + **conflict resolution** = multi-agent tidak overwrite kerjaan satu sama lain  |
| **CrewAI / AutoGen** | ~512MB | Multi-agent framework: role definition, task assignment, collaboration pattern, human-in-the-loop                         | CrewAI + **custom agent roles** = team AI yang mirror struktur team engineering nyata        |
| **Swarm Pattern**    | N/A    | Decentralized decision, emergent behavior, voting/consensus, load balancing, fault tolerance                              | Swarm + **self-healing** = sistem yang survive meski 1 agent mati                            |

> [!tip] Trik Multi-Agent
> Jangan buat 10 agent sekaligus. Mulai dari 2: Researcher + Writer. Researcher cari info, Writer rangkum. Lalu tambah Reviewer. Lalu tambah Fact-Checker. **Scale gradual, validate setiap layer.**

**Proyek Portofolio Fase 5:**
`Multi-Agent Content Pipeline` — 3 agent: (1) Researcher (search web + read file), (2) Writer (draft article), (3) Reviewer (fact-check + critique). Shared state via blackboard, human approval gate sebelum publish. Sertakan: agent interaction diagram, task decomposition log, final output comparison (single agent vs multi-agent).

---

## Fase 6 — Autonomous Operations & Observability (Minggu 21–24)

> **Goal:** Agent yang tidak hanya menunggu prompt, tapi bisa self-direct, self-reflect, dan self-improve. Plus: kamu bisa melihat apa yang dia pikirkan.
> **RAM Impact**: Ollama 14B ~8-10GB, Langfuse ~1GB, scheduler ~256MB. Total ~12GB. Gunakan VPS untuk produksi.

| Tool/Stack                               | RAM  | Yang Dipelajari                                                                                                                      | Combo A+B yang Membuktikan                                                                                    |
| ---------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **Self-Reflection**                      | N/A  | Agent evaluasi hasil kerjanya sendiri: "Apakah jawaban ini benar?" "Apakah ada yang terlewat?" Reflection prompt, confidence scoring | Self-reflection + **retry threshold** = agent yang tahu kapan output-nya tidak cukup baik                     |
| **Goal Decomposition**                   | N/A  | High-level goal → sub-goal → atomic task → execution. Hierarchical planning, dependency graph, rollback strategy                     | Decomposition + **dependency tracking** = agent yang bisa handle project kompleks tanpa human micromanagement |
| **Human-in-the-Loop**                    | N/A  | Approval gate, escalation trigger, feedback injection, correction mechanism, override capability                                     | HITL + **smart escalation** = agent autonomous tapi tidak out-of-control                                      |
| **Observability (Langfuse / LangSmith)** | ~1GB | Trace setiap reasoning step, token usage, latency, tool call success/failure, cost tracking, A/B prompt testing                      | Observability + **alerting** = kamu tahu agent-mu "sakit" sebelum user complain                               |

> [!warning] Critical
> **Autonomous != Unsupervised.** Agent yang self-direct tanpa observability adalah black box yang bisa menghasilkan garbage tanpa kamu tahu. Langfuse trace setiap step: input → reasoning → tool call → output. Tanpa ini, debugging agent adalah nightmare.

**Proyek Portofolio Fase 6:**
`Autonomous Knowledge Curator` — agent yang: (1) monitor folder sumber (PDF, web clip) setiap jam, (2) extract insight dan tulis ke knowledge base, (3) self-reflect: "Apakah insight ini sudah ada? Apakah ada kontradiksi?" (4) escalate ke human kalau confidence <70%, (5) observability dashboard di Langfuse. Sertakan: cron config, reflection prompt, trace screenshot, cost analysis.

---

## Roadmap Visual — Timeline 6 Bulan

| Bulan 1                      | Bulan 2                        | Bulan 3                           | Bulan 4                    | Bulan 5                   | Bulan 6                      |
| ---------------------------- | ------------------------------ | --------------------------------- | -------------------------- | ------------------------- | ---------------------------- |
| **FASE 1**<br>LLM Foundation | **FASE 2**<br>Tool Use & ReAct | **FASE 3**<br>Memory Architecture | **FASE 4**<br>MCP Protocol | **FASE 5**<br>Multi-Agent | **FASE 6**<br>Autonomous Ops |
| Ollama / LM Studio           | Function Calling               | Short-term Memory                 | MCP Server (stdio)         | Agent Delegation          | Self-Reflection              |
| OpenAI SDK                   | ReAct Loop                     | Vector DB (ChromaDB)              | MCP Server (HTTP)          | Shared State              | Goal Decomposition           |
| Pydantic Schema              | Custom Tools                   | Embedding Model                   | MCP Client                 | CrewAI / AutoGen          | Human-in-the-Loop            |
| Prompt Engineering           | LangChain Agent                | Long-term Pattern                 | MCP Ecosystem              | Swarm Pattern             | Observability (Langfuse)     |
| JSON Mode                    | Error Handling                 | Memory Retrieval                  | Multi-Server Orchestration | Blackboard Pattern        | Autonomous Scheduler         |
|                              |                                |                                   |                            |                           |                              |
| **Portfolio 1:**             | **Portfolio 2:**               | **Portfolio 3:**                  | **Portfolio 4:**           | **Portfolio 5:**          | **Portfolio 6:**             |
| Structured Output Engine     | ReAct Agent + Tools            | Agent + Persistent Memory         | MCP Multi-Server Agent     | Multi-Agent Pipeline      | Autonomous Knowledge Curator |

---

## Sertifikasi yang Cocok per Fase

| Fase           | Sertifikasi                                                         | Kenapa                                       |
| -------------- | ------------------------------------------------------------------- | -------------------------------------------- |
| Setelah Fase 1 | **OpenAI API Fundamentals** (unofficial, via course)                | Validasi fondasi LLM API & structured output |
| Setelah Fase 2 | **LangChain Certification** (unofficial, community)                 | Tool use & agent framework                   |
| Setelah Fase 3 | **Vector DB Certification** (Pinecone / Weaviate / Qdrant)          | Memory & retrieval architecture              |
| Setelah Fase 4 | **MCP Contributor** (community badge)                               | Build & publish MCP server                   |
| Setelah Fase 5 | **Multi-Agent Systems** (MIT OCW / Stanford CS)                     | Teori delegation & swarm                     |
| Setelah Fase 6 | **LLM Observability** (Langfuse / LangSmith)                        | Production monitoring & debugging            |
| Jangka panjang | **Google Cloud Professional ML Engineer** atau **AWS ML Specialty** | Cloud-scale AI deployment                    |

---

## Yang TIDAK Perlu Dipelajari Sekarang

> [!warning] Jangan Buang Waktu
>
> - ~~Fine-tuning LLM dari nol~~ — role ini agent orchestration, bukan model training. Gunakan pre-trained model (Ollama, API).
> - ~~Deep Learning theory (backprop, CNN, RNN)~~ — kamu operate LLM, bukan train neural network. Fokus pada inference & prompt engineering.
> - ~~Kubernetes untuk AI (Kubeflow, Ray)~~ — tidak disebutkan di stack awal; Docker Compose cukup untuk homelab.
> - ~~Computer Vision / Multimodal~~ — fokus text-based agent dulu. Vision agent adalah extension setelah text mastery.
> - ~~Blockchain / Web3 / DAO~~ — tidak relevan untuk agentic AI engineering path.
> - ~~Entry-level Python (variable, loop, function)~~ — asumsikan kamu sudah bisa Python intermediate. Kalau belum, kuasai dulu sebelum mulai roadmap ini.

---

## 🔗 Lihat Juga

- [[infrastructure-administrator|IT Systems Engineer Roadmap]] — Infrastructure yang men-support agent deployment
- [[endpoint-security|Endpoint Security]] — Security mindset untuk agent yang punya akses ke sistem
- [[underground-knowledge|Underground Knowledge]] — BYOVD & low-level thinking yang transferable ke agent architecture
- [[00_atlas/hierarchy-ai-levels|AI Levels]] — Hierarki AI dari Level 0 sampai Level 11 (Omega Point)
- [[01_library/ai_systems/system-design|Software Architecture]] — Design pattern untuk scalable agent systems

---

_Roadmap Agentic AI & MCP | Fase 1 (LLM Foundation) → Fase 6 (Autonomous Ops) · 6 Bulan Homelab · Local-First, API-Optional_
