---
title: Multi-Agent Orchestration Patterns — Routing, Parallel, Supervisor
tags:
- agent
- orchestration
- multi-agent
- patterns
- mcp
created: '2026-07-16'
updated: '2026-07-16'
status: pending
cssclasses:
  - wide-table
  - callout

---

## Daftar Isi

1. [Kenapa Multi-Agent?](#1-kenapa-multi-agent)
2. [Pattern 1: Router (Single-turn)](#2-pattern-1-router-single-turn)
3. [Pattern 2: Parallel (Fan-out / Map)](#3-pattern-2-parallel-fan-out--map)
4. [Pattern 3: Supervisor (Hierarchical)](#4-pattern-3-supervisor-hierarchical)
5. [Pattern 4: Pipeline (Sequential)](#5-pattern-4-pipeline-sequential)
6. [Pattern 5: Debate / Reflection](#6-pattern-5-debate--reflection)
7. [Pattern 6: Swarm (Dynamic)](#7-pattern-6-swarm-dynamic)
8. [Tools & Frameworks](#8-tools--frameworks)
9. [Decision Matrix — Kapan Pake Pattern Apa](#9-decision-matrix--kapan-pake-pattern-apa)

---

## 1. Kenapa Multi-Agent?

Single LLM call punya limitasi fundamental:

| Limitasi | Single LLM | Multi-Agent |
|----------|-----------|-------------|
| **Context window** | Satu prompt terbatas | Split across agents → efektif ∞ |
| **Specialization** | Satu model buat semua tugas | Agent spesifik per domain |
| **Debias** | Satu perspektif | Multiple agents → cross-check |
| **Tool access** | Tool terbatas per call | Setiap agent punya toolset sendiri |
| **Fault tolerance** | Satu error → gagal total | Redisign / fallback antar agent |
| **Observability** | Satu trace | Sub-traces per agent |

**Prinsip: Jangan bikin agent yang ngelakuin semuanya. Bikin agent spesifik yang di-orchestrate.**

---

## 2. Pattern 1: Router (Single-turn)

**Paling sederhana.** Satu router agent yang menentukan agent mana yang menangani request, lalu delegasikan.

```
              ┌──────────────┐
              │   Request    │
              └──────┬───────┘
                     │
              ┌──────▼───────┐
              │   Router     │ ← LLM + classification
              │  (Classifier)│
              └──┬───┬───┬──┘
                 │   │   │
      ┌──────────┘   │   └──────────┐
      ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Agent   │  │  Agent   │  │  Agent   │
│  Coding  │  │  Writing │  │  RAG     │
└──────────┘  └──────────┘  └──────────┘
```

### Implementasi

```python
class Router:
    """Route task ke agent specialized berdasarkan intent."""
    
    SYSTEM_PROMPT = """Kamu adalah router. Dari input user, tentukan agent yang handle:
- coding: pertanyaan programming, debugging, code review
- writing: menulis, editing, summarization
- rag: pertanyaan tentang knowledge base
- general: sisanya

Output hanya 1 kata: nama agent."""

    def route(self, query: str) -> Agent:
        classification = self.llm.generate(
            system=self.SYSTEM_PROMPT,
            user=query,
            max_tokens=10,
            temperature=0  # deterministic
        ).strip().lower()
        
        return self.agents[classification]
    
    async def handle(self, query: str) -> str:
        agent = self.route(query)
        return await agent.run(query)
```

### Kelebihan
- ✅ **Simple** — satu LLM call untuk routing, satu untuk eksekusi
- ✅ **Latency rendah** — 2 sequential calls
- ✅ **Isolation** — agent gak saling ganggu
- ✅ **Easy to debug** — jelas agent mana yang salah

### Kekurangan
- ❌ Router error → request salah tangan
- ❌ Gak bisa handle task yang butuh multiple domain (coding + writing)
- ❌ Router gak punya context dari agent — klasifikasi pure dari query awal

### Kapan Pake
- Support ticket routing
- Intent-based chatbot
- API gateway dengan backend LLM berbeda

---

## 3. Pattern 2: Parallel (Fan-out / Map)

**Eksekusi simultan oleh beberapa agent.** Hasil dikumpulkan dan digabung (reduce/merge).

```
              ┌──────────────┐
              │   Request    │
              │  "Bandingkan │
              │  X dan Y"    │
              └──────┬───────┘
                     │
           ┌─────────▼──────────┐
           │   Orchestrator     │
           │  (split task)      │
           └──┬───┬───┬───┬───┬┘
              │   │   │   │   │
      ┌───────┘   │   │   │   └───────┐
      ▼           ▼   ▼   ▼           ▼
  ┌────────┐ ┌────────┐  ┌────────┐ ┌────────┐
  │ Agent  │ │ Agent  │… │ Agent  │ │ Agent  │
  │ Tugas1 │ │ Tugas2 │  │ TugasN │ │ TugasN │
  └───┬────┘ └───┬────┘  └───┬────┘ └───┬────┘
      │         │            │         │
      └─────────┴────────────┴─────────┘
                        │
                 ┌──────▼──────┐
                 │   Reducer   │
                 │  (merge)    │
                 └─────────────┘
```

### Implementasi

```python
import asyncio

class ParallelOrchestrator:
    async def run_parallel(self, query: str, agents: list[Agent]) -> str:
        # Fan-out: jalankan semua agent concurrently
        tasks = [agent.run(query) for agent in agents]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Handle partial failures
        successes = []
        for agent, result in zip(agents, results):
            if isinstance(result, Exception):
                logging.error(f"Agent {agent.name} failed: {result}")
                successes.append(f"[{agent.name}]: ERROR — {str(result)}")
            else:
                successes.append(f"[{agent.name}]: {result}")
        
        # Reduce: gabung semua hasil jadi satu
        return self.reducer.merge(successes)
```

### Kelebihan
- ✅ **Cepat** — total latency = agent paling lambat (bukan total)
- ✅ **Coverage** — semua aspek di-cover
- ✅ **Fault tolerant** — agent gagal, yang lain tetap jalan

### Kekurangan
- ❌ **Context fragmentation** — tiap agent cuma lihat sebagian
- ❌ **Merge complexity** — hasil dari agent bisa kontradiksi
- ❌ **Cost** — N× token usage (tiap agent full LLM call)

### Kapan Pake
- Research: cari info dari multiple source sekaligus
- Analisis dari berbagai perspektif (pro/contra, tech/business)
- Parallel validation — cross-check fakta dari berbagai angle

**Ponytail:** Kalau task independent dan bisa di-split jelas, parallel pattern selalu lebih cepat dari sequential.

---

## 4. Pattern 3: Supervisor (Hierarchical)

**Supervisor agent yang manage sub-agents.** Supervisor menentukan kapan panggil agent mana, evaluasi hasil, dan decide next action — loop sampai task selesai.

```
              ┌───────────────────┐
              │    Supervisor     │ ← orchestrator
              │  (decision loop) │
              └──┬───┬───┬───┬───┘
                 │   │   │   │
      ┌──────────┘   │   │   └──────────┐
      ▼              ▼   ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Agent   │  │  Agent   │  │  Agent   │
│  Search  │  │  Analyze │  │  Write   │
└──────────┘  └──────────┘  └──────────┘
```

### Implementasi

```python
class Supervisor:
    """Supervisor agent — menentukan langkah demi langkah."""
    
    SYSTEM_PROMPT = """Kamu adalah supervisor agent. Tugasmu mengelola sub-agents untuk menyelesaikan task kompleks.

Agents available:
- search: mencari informasi terbaru
- analyze: menganalisis data/informasi
- code: menulis atau mengecek kode
- write: menulis output final

Setiap langkah, output JSON:
{"next": "nama_agent", "input": "...", "reason": "kenapa langkah ini"}

Jika task selesai, output:
{"done": true, "final_answer": "..."}"""

    async def run(self, task: str) -> str:
        messages = [{"role": "system", "content": self.SYSTEM_PROMPT},
                    {"role": "user", "content": task}]
        
        max_steps = 10
        for step in range(max_steps):
            # Supervisor decide
            decision = self.llm.generate(messages, response_format="json")
            
            if decision.get("done"):
                return decision["final_answer"]
            
            # Execute sub-agent
            agent = self.agents[decision["next"]]
            result = await agent.run(decision["input"])
            
            # Give result back to supervisor
            messages.append({"role": "assistant", "content": str(decision)})
            messages.append({"role": "user", "content": f"Result: {result}"})
        
        return "Max steps reached tanpa selesai."
```

### Kelebihan
- ✅ **Flexible** — bisa handle task kompleks yang gak terstruktur
- ✅ **Dynamic** — langkah ditentukan saat runtime, bukan fixed pipeline
- ✅ **Error recovery** — supervisor bisa redirect kalau agent gagal
- ✅ **Observability** — tiap langkah jelas kenapa

### Kekurangan
- ❌ **Laten** — sequential loop, N langkah = N LLM calls
- ❌ **Supervisor bottleneck** — supervisor decision error cascade ke bawah
- ❌ **Token cost tinggi** — tiap loop bawa full history

### Kapan Pake
- Task kompleks dengan sub-task interdependent
- Research task yang butuh iterative refinement
- Coding task: search → analyze → implement → test → fix

---

## 5. Pattern 4: Pipeline (Sequential)

**Output agent pertama = input agent kedua.** Linear chain. Cocok kalau task punya urutan jelas.

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Agent   │───→│  Agent   │───→│  Agent   │───→│  Output  │
│  Search  │    │  Analyze │    │  Write   │    │  Final   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Implementasi

```python
class Pipeline:
    def __init__(self, stages: list[Agent]):
        self.stages = stages
    
    async def run(self, initial_input: str) -> str:
        current_input = initial_input
        for i, agent in enumerate(self.stages):
            logger.info(f"Pipeline stage {i}: {agent.name}")
            current_input = await agent.run(current_input)
        return current_input
```

### Kelebihan
- ✅ **Deterministic** — predictable flow
- ✅ **Easy to debug** — tiap stage terdefinisi
- ✅ **Simple** — implementasi paling mudah
- ✅ **Testable** — tiap stage bisa di-test sendiri

### Kekurangan
- ❌ **Rigid** — gak bisa skipping atau backtrack
- ❌ **Latency cumulative** — N stages = N× latency
- ❌ **Single point of failure** — stage gagal, pipeline berhenti

### Kapan Pake
- RAG pipeline (rewrite → retrieve → rerank → generate)
- Content generation pipeline (outline → draft → edit → format)
- ETL pipeline dengan LLM (extract → transform → summarize → load)

---

## 6. Pattern 5: Debate / Reflection

**Multiple agents saling kritik.** Satu agent generate output, agent lain review. Iterasi sampai konsensus.

```
              ┌──────────┐
              │  Agent A │ ← generate answer
              └────┬─────┘
                   │
              ┌────▼─────┐
              │  Agent B │ ← critique A's answer
              └────┬─────┘
                   │
              ┌────▼─────┐
              │  Agent A │ ← revise based on critique
              └────┬─────┘
                   │
              ┌────▼─────┐
              │  Agent B │ ← approve? or iterate again
              └──────────┘
```

### Implementasi

```python
class DebateAgent:
    async def generate_with_reflection(self, task: str, rounds: int = 3) -> str:
        generator = Agent("generator", "you are a creative problem solver")
        critic = Agent("critic", "you are a harsh but fair critic")
        
        answer = await generator.run(task)
        
        for i in range(rounds):
            # Critic
            critique = await critic.run(f"Task: {task}\n\nAnswer: {answer}\n\nCritique:")
            
            # Decide if done
            if "APPROVED" in critique:
                return answer
            
            # Generator revise
            answer = await generator.run(
                f"Task: {task}\nYour previous answer: {answer}\nCritique: {critique}\n\nRevised answer:"
            )
        
        return answer
```

### Variasi: Multi-Agent Debate

```
Agent A: "Menurut saya solusi X"  ──┐
                                    ├──→ Synthesis Agent → final answer
Agent B: "Tapi X punya risiko Y"  ──┘
```

Efektif untuk:
- **Factual checking** — 2 agent verifikasi dari sumber berbeda
- **Decision making** — agent pro vs kontra
- **Code review** — agent nulis code, agent lain review security

### Kapan Pake
- **High-stakes decisions** — butuh cross-check
- **Quality critical output** — yang gak bisa di-review manual
- **Red-teaming** — satu agent attack, satu defend

---

## 7. Pattern 6: Swarm (Dynamic)

**Agent bisa spawn agent lain.** Tidak ada hierarki tetap — agent bisa me-delegate ke agent lain berdasarkan keputusan sendiri.

```
         ┌──────────┐
    ┌────│  Agent A │────┐
    │    └──────────┘    │
    ▼                    ▼
┌──────────┐    ┌──────────┐
│  Agent B │    │  Agent C │
│  (spawn  │    │  (spawn  │
│   by A)  │    │   by A)  │
└────┬─────┘    └────┬─────┘
     │               │
     ▼               ▼
┌──────────┐    ┌──────────┐
│  Agent D │    │  Agent E │
│  (spawn  │    │  (spawn  │
│   by B)  │    │   by C)  │
└──────────┘    └──────────┘
```

**Contoh framework:** OpenAI Swarm, AutoGen, CrewAI.

```python
# OpenAI Swarm — lightweight multi-agent
from swarm import Swarm, Agent

client = Swarm()

def transfer_to_billing():
    return billing_agent

def transfer_to_support():
    return support_agent

support_agent = Agent(
    name="Support",
    instructions="Kamu support agent. Handle technical issues.",
    functions=[transfer_to_billing],
)

billing_agent = Agent(
    name="Billing",
    instructions="Kamu billing agent. Handle payment & invoices.",
    functions=[transfer_to_support],
)

# Dynamic handoff — agent decide sendiri kapan transfer
response = client.run(
    agent=support_agent,
    messages=[{"role": "user", "content": "Saya mau complain tagihan"}],
)
# Support → automatically transfer ke billing_agent
```

### Kelebihan
- ✅ **Highly flexible** — arsitektur tumbuh sesuai kebutuhan
- ✅ **Scalable** — agent bisa spawn sub-agent buat sub-task
- ✅ **Natural** — mirror organisasi manusia (delegasi)

### Kekurangan
- ❌ **Hard to debug** — graph bisa tumbuh unpredictable
- ❌ **Loop risk** — agent A panggil B, B panggil A lagi → infinite loop
- ❌ **Cost unpredictable** — jumlah agent calls gak terbatas
- ❌ **Control problem** — siapa yang ngehandle kalau swarm diverging?

### Kapan Pake
- Complex customer support (handoff antar department)
- Autonomous coding agent yang bisa nulis file → run test → debug → fix
- Research agent yang eksplorasi banyak jalur paralel

---

## 8. Tools & Frameworks

### Perbandingan Framework Multi-Agent

| Framework | Pattern Support | Bahasa | Kompleksitas | Best For |
|-----------|---------------|--------|-------------|----------|
| **LangChain / LangGraph** | Router, Supervisor, Pipeline, Parallel | Python | Medium | Production-grade, MCP integration |
| **OpenAI Swarm** | Swarm (handoff) | Python | Rendah | Eksperimen cepat, prototyping |
| **AutoGen (Microsoft)** | Supervisor, Debate, Swarm | Python | Medium | Multi-agent conversation |
| **CrewAI** | Router, Pipeline, Parallel, Swarm | Python | Rendah | Role-based agent teams |
| **Semantic Kernel** | Router, Pipeline | C#/Python | Medium | Enterprise Microsoft stack |
| **MCP (Model Context Protocol)** | Router (tool-based) | Any | Medium | Tool-agnostic agent communication |

### LangGraph — Supervisor Pattern

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Literal

class AgentState(TypedDict):
    messages: list
    next_agent: str
    done: bool

def supervisor_node(state: AgentState):
    """LLM memutuskan agent mana yang jalan selanjutnya."""
    decision = llm.invoke([
        system_prompt,
        *state["messages"],
        "Siapa agent yang handle langkah ini?"
    ])
    return {"next_agent": decision.content}

workflow = StateGraph(AgentState)

workflow.add_node("supervisor", supervisor_node)
workflow.add_node("search_agent", search_node)
workflow.add_node("rag_agent", rag_node)
workflow.add_node("writer_agent", writer_node)

workflow.set_entry_point("supervisor")
workflow.add_conditional_edges(
    "supervisor",
    lambda state: state["next_agent"],
    {
        "search": "search_agent",
        "rag": "rag_agent",
        "write": "writer_agent",
        "FINISH": END,
    }
)

# Agent nodes kembali ke supervisor setelah selesai
for agent in ["search_agent", "rag_agent", "writer_agent"]:
    workflow.add_edge(agent, "supervisor")
```

---

## 9. Decision Matrix — Kapan Pake Pattern Apa

### Flowchart Cepat

```
Apakah task bisa di-split menjadi sub-task independent?
├── YES → Apakah sub-task perlu urutan tertentu?
│   ├── YES → Pipeline
│   └── NO  → Parallel
└── NO → Apakah task butuh iterative refinement?
    ├── YES → Apakah butuh validasi silang?
    │   ├── YES → Debate / Reflection
    │   └── NO  → Supervisor (hierarchical)
    └── NO → Apakah routing sudah jelas dari awal?
        ├── YES → Router
        └── NO  → Swarm (dynamic delegation)
```

### Table Summary

| Pattern | Latency | Cost | Flexibility | Fault Tolerance | Complexity |
|---------|---------|------|-------------|-----------------|------------|
| **Router** | Rendah | Rendah | Rendah | Medium | **Sangat rendah** |
| **Parallel** | Medium† | Tinggi | Medium | **Tinggi** | Rendah |
| **Supervisor** | Tinggi | Tinggi | **Tinggi** | Tinggi | Medium |
| **Pipeline** | Medium | Rendah | Rendah | Rendah | **Sangat rendah** |
| **Debate** | Tinggi | **Sangat tinggi** | Medium | **Tinggi** | Medium |
| **Swarm** | **Sangat tinggi** | **Sangat tinggi** | **Sangat tinggi** | Medium | **Tinggi** |

† Latency parallel = agent paling lambat, bukan total.

### Rekomendasi Mulai

1. **Mulai dengan Router** — 90% use case cukup dengan router sederhana
2. **Kalau butuh multiple perspective → tambah Parallel**
3. **Kalau task kompleks dengan banyak langkah → Supervisor (LangGraph)**
4. **Hanya pake Swarm kalau agent count >5 dan dinamik**

**Prinsip:** Jangan over-engineer. Multi-agent paling sederhana yang solve problem = yang terbaik.

---

## Referensi

- [[agentic-ai-mcp-architecture-deepdive]] — Arsitektur MCP & tool use
- [[swarm-ai-imam-robandi]] — Swarm AI dari perspektif akademik
- [[ai-comm-protocol-deep-dive]] — MCP protocol detail
- [[meta-agent-orchestration]] — Meta-agent orchestration
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [OpenAI Swarm](https://github.com/openai/swarm)
- [AutoGen (Microsoft)](https://github.com/microsoft/autogen)
- [CrewAI](https://docs.crewai.com/)

---

*Dibuat: 16 Juli 2026 — Panduan praktis multi-agent orchestration dari pattern sampai implementasi.*
---

audited
---
