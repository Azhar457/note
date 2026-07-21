---
title: 'Prompt Engineering & LLM Interaction Patterns — Deep Dive: Zero-Shot sampai
  Reflexion, ReAct, Agent Loop'
tags:
- ai
- llm
- prompt-engineering
- agentic-ai
- react
- cot
created: '2026-07-18'
updated: '2026-07-18'
status: operational
cssclasses:
- wide-table
---

# 🧠 Prompt Engineering & LLM Interaction Patterns — Deep Dive: Zero-Shot sampai Reflexion, ReAct, Agent Loop

> Panduan komprehensif teknik interaksi dengan LLM — dari zero-shot prompt sampai multi-step agent loop. Mencakup system prompt design, few-shot in-context learning, Chain-of-Thought (CoT), structured output (JSON/function calling), ReAct pattern untuk tool-calling, context management multi-turn, dan advanced patterns (Reflexion, Self-Critique, Plan-and-Execute). Vault udah punya arsitektur agentic AI di [[agentic-ai-mcp-architecture-deepdive]], LLM security di [[llm-security-red-teaming-attack-surface-ai-layer]], dan test-time compute di [[test-time-compute-system2]] — tapi belum ada catatan yang membahas **cara bicara ke LLM secara efektif** dari sisi prompt. Catatan ini adalah jembatan antara API call mentah dan agent otonom.

> [!info] Posisi di Vault
> Ini adalah **fondasi interaksi** untuk semua catatan AI di vault. Baca ini dulu sebelum [[agentic-ai-mcp-architecture-deepdive]] (implementasi MCP tool server), [[llm-security-red-teaming-attack-surface-ai-layer]] (dark side: prompt injection & jailbreak), [[test-time-compute-system2]] (CoT dari sisi model, bukan prompt), [[ai-evaluation-framework]] (evaluasi output LLM), dan [[meta-agent-orchestration]] (multi-agent prompt chaining).

---

## Daftar Isi

- [[#Foundation — Dari Prompt ke Agent]]
- [[#Level 0 — Zero-Shot & System Prompt Design]]
- [[#Level 1 — Few-Shot & In-Context Learning]]
- [[#Level 2 — Chain-of-Thought (CoT)]]
- [[#Level 3 — Structured Output (JSON Mode / Function Calling)]]
- [[#Level 4 — Tool-Calling Loop & ReAct Pattern]]
- [[#Level 5 — Multi-Turn Context Management]]
- [[#Level 6 — Advanced Patterns (Reflexion, Self-Critique, Plan-and-Execute)]]
- [[#Perbandingan Pattern]]
- [[#Koneksi ke Vault]]

---

## Foundation — Dari Prompt ke Agent

### Evolusi Interaksi LLM

```
Level 0: Input Text -> Output Text          (Prompt mentah)
Level 1: Input + Examples -> Output         (In-Context Learning)
Level 2: Input + Reasoning -> Output        (Chain-of-Thought)
Level 3: Input + Schema -> JSON             (Structured Output)
Level 4: Input + Tools -> Action -> Observe -> Repeat (ReAct Agent)
Level 5: Multi-turn Context -> Stateful Agent (Conversation)
Level 6: Self-Improving Loop                (Reflexion)
```

Setiap level menambah **kompleksitas**, **kemampuan**, dan **potential failure mode**.

| Level | Kemampuan Tambahan | Failure Mode Baru |
|-------|-------------------|-------------------|
| 0 | Jawab pertanyaan | Ambigu, hallucination, format tidak konsisten |
| 1 | Ikuti format contoh | Contoh bias, negative examples |
| 2 | Reasoning logis | Multi-hop error, contradiction |
| 3 | Machine-parsable output | JSON malformed, schema violation |
| 4 | Eksekusi aksi | Tool error, wrong tool, infinite loop |
| 5 | Stateful conversation | Context drift, memory leak |
| 6 | Self-correction | Over-correction, compute cost |

## Level 0 — Zero-Shot & System Prompt Design

### Anatomi System Prompt Efektif

```
[ROLE]          Kamu adalah [peran spesifik] dengan [N tahun] pengalaman di [domain]
[CONTEXT]       Konteks situasi: [latar belakang, tujuan, audiens]
[CONSTRAINTS]   Constraints: [format, panjang, tone, hal yang tidak boleh dilakukan]
[TASK]          Tugas spesifik: [satu intent, jelas, terukur]
[OUTPUT]        Output yang diharapkan: [format, struktur]
```

### Contoh System Prompt
```
Kamu adalah senior DevOps engineer dengan 10 tahun pengalaman di Kubernetes dan cloud-native.

Konteks: Tim sedang migrasi dari Docker Swarm ke K8s. Developer familiar dengan docker-compose tapi belum pernah pegang K8s.

Constraints:
- Jawab dalam Bahasa Indonesia campur Inggris
- Maksimal 3 paragraf
- Sertakan 1 contoh YAML yang relevan
- Jangan gunakan jargon yang tidak dijelaskan

Tugas: Jelaskan perbedaan Pod dan Deployment di K8s dengan analogi docker-compose services.

Output: Format markdown dengan bagian "TL;DR" di atas.
```

### Anti-Pattern Zero-Shot

| ❌ Anti-Pattern | Kenapa Gagal | ✅ Solusi |
|----------------|-------------|-----------|
| Prompt terlalu pendek ("Jelaskan kernel") | LLM gak tau depth yang diinginkan | Tambah konteks: audiens, scope, format |
| Multitask dalam 1 prompt | LLM fokus di tengah, lupa ujung | Satu prompt = satu intent |
| Instruksi di akhir prompt | Positional bias: LLM lebih ingat awal & akhir | Instruksi utama di **awal**, detail di akhir |
| Tone tidak dispesifikasi | Output terlalu formal/kaku untuk konteks | Explicit: "Gaya ngobrol santai, kayak temen" |

## Level 1 — Few-Shot & In-Context Learning

### Teknik Few-Shot

| Teknik | Cara Kerja | Kapan Pakai |
|--------|-----------|-------------|
| **Fixed Few-Shot** | 2-5 contoh statis sebelum query | Format output rigid, classification task |
| **Dynamic Few-Shot** | Pilih contoh relevan dari vector DB tiap query | Production RAG — lebih akurat |
| **Many-Shot** | 50-100+ contoh dalam konteks | Pattern extraction, style matching |
| **Negative Examples** | Sertakan contoh yang SALAH + kenapa salah | Klasifikasi dengan boundary jelas |

### Aturan Emas Few-Shot
1. Contoh harus **diverse** — jangan 5 contoh yang mirip
2. Contoh harus **edge-case-aware** — sertakan 1 kasus batas
3. Format konsisten: Input → Reasoning (opsional) → Output
4. Label dengan jelas mana contoh dan mana query real
5. **Negative examples** > positive examples untuk boundary cases

### Template Few-Shot
```
Berikut adalah contoh format yang diinginkan:

Input: "Jelaskan perbedaan TCP dan UDP"
Output:
  TL;DR: TCP = reliable tapi lambat. UDP = cepat tapi lossy.
  Detail:
    - TCP: connection-oriented, 3-way handshake, retransmission
    - UDP: connectionless, fire-and-forget, no ack

Input: "Apa itu Kubernetes?"
Output:
  TL;DR: Orchestrator container — kayak Docker Compus tapi untuk banyak server.
  Detail:
    - ...

Input: {user_query}
Output:
```

## Level 2 — Chain-of-Thought (CoT)

### Tingkatan CoT

| Teknik | Prompt | Efek | Cost |
|--------|--------|------|------|
| **Zero-Shot CoT** | "Mari berpikir langkah demi langkah" | +10-30% accuracy | 0 (cuma tambah 1 kalimat) |
| **Few-Shot CoT** | Contoh dengan reasoning chain | +20-40% | Sedang (beberapa contoh) |
| **Structured CoT** | "Output dengan format: 1. Analisis... 2. Langkah... 3. Kesimpulan" | Output terstruktur + reasoning | Minimal |
| **Self-Consistency** | Generate N chain → voting jawaban paling konsisten | +5-15% dari CoT biasa | Tinggi (Nx API call) |
| **CoT with Confidence** | "Setelah berpikir, beri confidence score 0-1" | Trust calibration | Minimal |

### Kapan CoT Efektif?
✅ Matematika, logika, debugging, multi-hop QA, planning
❌ Fakta sederhana, kreativitas, summarization — CoT malah bikin verbose

> [!tip] CoT = Murah Meriah
> Zero-shot CoT gak perlu training, gak perlu fine-tune, cuma tambah 1 kalimat di prompt. Efeknya dramatis di reasoning task. Dulu GSM8K benchmark: 18% accuracy → 79% hanya dengan menambahkan "Let's think step by step."

## Level 3 — Structured Output (JSON Mode / Function Calling)

### Cara Kerja
LLM menghasilkan output yang bisa diparsing mesin — bukan teks bebas.

### Metode 1: Prompt-based JSON
```
Output dalam format JSON valid:
{
  "kesimpulan": "...",
  "confidence": 0-1,
  "alasan": ["...", "..."]
}
Jangan sertakan markdown, hanya JSON.
```

### Metode 2: Function Calling (API-level)
OpenAI, Anthropic, Google, OpenRouter — semua support `tools` parameter.
```json
{
  "name": "search_knowledge_base",
  "description": "Cari dokumen relevan dari vault",
  "parameters": {
    "type": "object",
    "properties": {
      "query": {"type": "string"},
      "limit": {"type": "integer", "default": 5}
    }
  }
}
```

### Metode 3: Constrained Decoding (JSON-mode API)
Beberapa provider punya `response_format: {"type": "json_object"}` yang memaksa output JSON valid di level decoding, bukan prompt.

| Metode | Jaminan JSON Valid | Kecepatan | Dukungan Provider |
|--------|-------------------|-----------|-------------------|
| Prompt-based | ❌ Kadang gagal | Cepat | Semua |
| Function Calling | ✅ High, tapi bisa skipped | Sedang | OpenAI, Anthropic, Gemini |
| Constrained Decoding | ✅✅ Almost 100% | Lambat | OpenAI, Together, Fireworks |

## Level 4 — Tool-Calling Loop & ReAct Pattern

ReAct = **Reasoning + Acting** — siklus kognitif yang memungkinkan LLM menggunakan tools eksternal.

### Flow Satu Siklus
```
1. Thought: LLM menganalisis situasi dan menentukan langkah
2. Action: LLM memilih tool + argumen (dalam format JSON)
3. Observation: Hasil eksekusi tool dikembalikan ke LLM
4. Repeat: Kembali ke Thought — apakah sudah cukup atau perlu langkah lagi
5. Final Answer: LLM memberikan jawaban final berdasarkan semua observasi
```

### Contoh Siklus
```
Thought: Saya perlu tahu CVE terbaru untuk kernel Linux
Action: search_cve(query="Linux kernel critical 2025")
Observation: [CVE-2025-XXXX, CVE-2025-XXXX — use-after-free di netfilter]
Thought: Saya punya data CVE. Sekarang saya perlu rekomendasi mitigasi
Action: query_knowledge_base(topic="netfilter mitigation")
Observation: [Patch di versi 6.8.5, backport available]
Final Answer: Berikut CVE kritis kernel Linux 2025 beserta mitigasi...
```

### Infinite Loop Detection
Tool-calling agent bisa stuck dalam loop. Mitigasi:
1. **Max iteration** — hard limit (biasanya 10-25 langkah)
2. **Repetition detection** — jika LLM generate action yang sama >2x
3. **Timeout** — batas waktu total siklus
4. **Thought diversity check** — jika thought gak berkembang, force final answer

> **Koneksi:** Implementasi MCP tool server ada di [[agentic-ai-mcp-architecture-deepdive]]. Catatan ini fokus pada prompt-level interaction, bukan infrastruktur.

## Level 5 — Multi-Turn Context Management

### Masalah Konteks

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| **Context Window Overflow** | Konteks terlalu panjang setelah N turn | Summarization historis: compress N turn jadi 1 paragraf |
| **Positional Bias** | LLM lupa informasi di tengah konteks | Instruksi paling penting di **awal** dan **akhir** prompt |
| **Hallucination karena konflik** | Data baru override data lama secara implisit | Explicit conflict resolution: "Data terbaru override data lama" |
| **Tool Call History** | Hasil tool call memenuhi konteks | Simpan hanya hasil relevan, hapus intermediate error |
| **Attention Sink** | Model terdistraksi oleh informasi paling baru | Prioritaskan ulang konteks berdasarkan relevansi |

### Strategi Ringkasan (Summarization) untuk Long Conversation
```
System: Kamu adalah asisten yang membantu.
[10 turn percakapan sebelumnya — terlalu panjang]

Alternatif — compress:
System: Kamu adalah asisten yang membantu.
[Ringkasan: User bertanya tentang K8s deployment. Sudah dibahas: rolling update, probe, resource limits.]
User: Sekarang gimana caranya setup HPA?
```

## Level 6 — Advanced Patterns (Reflexion, Self-Critique, Plan-and-Execute)

| Pattern | Cara Kerja | Kelebihan | Kekurangan | Use Case |
|---------|-----------|-----------|------------|----------|
| **Reflexion** | Generate → evaluasi output sendiri → refine berdasarkan evaluasi | Self-improving, kualitas naik tiap iterasi | Butuh 2-3x API call | Coding, writing, complex analysis |
| **Self-Critique** | Minta LLM critique jawabannya | Deteksi error sendiri, factual accuracy | LLM kadang gak bisa critique output sendiri | Fact-checking, code review |
| **Plan-and-Execute** | Step 1: buat rencana (sub-task list). Step 2: eksekusi tiap sub-task | Task decomposition, traceable | Plan bisa salah (garbage in, garbage out) | Multi-step research, complex workflow |
| **Tree-of-Thoughts (ToT)** | Branching reasoning — explore multiple paths simultan | Eksplorasi kreatif, optimasi | Mahal (N path x M depth) | Creative problem solving, optimization |

### Contoh Reflexion Prompt
```
[ROUND 1] Generate jawaban untuk query
[ROUND 2] Evaluasi jawaban:
  - Apakah ada factual error?
  - Apakah format sesuai spec?
  - Apakah ada konteks yang terlewat?
  Beri skor 1-10 untuk setiap aspek.
[ROUND 3] Refine jawaban berdasarkan evaluasi
```

---

## Perbandingan Pattern

| Pattern | Complexity | Cost (API calls) | Best For |
|---------|-----------|-------------------|----------|
| Zero-Shot | Rendah | 1 | Simple QA, creative writing |
| Few-Shot | Rendah | 1 + prep | Classification, format-specific |
| CoT | Rendah | 1 (+N untuk self-consistency) | Reasoning, math, logic |
| Structured Output | Rendah-Sedang | 1 | Data extraction, API integration |
| ReAct Tool Loop | Sedang | N (tergantung tools) | Research, multi-step tasks |
| Reflexion | Tinggi | 3-5 per cycle | High-quality output required |
| Plan-and-Execute | Tinggi | 1 (plan) + N (execute) | Complex multi-step |

---

## Koneksi ke Vault

- [[agentic-ai-mcp-architecture-deepdive]] — Implementasi MCP tool server & agent loop (Level 4+)
- [[test-time-compute-system2]] — CoT & inference-time scaling dari sisi model (Level 2)
- [[llm-security-red-teaming-attack-surface-ai-layer]] — Dark side: prompt injection, jailbreak, exfiltration
- [[ai-evaluation-framework]] — Evaluasi kualitas output LLM (RAGAS, LLM-as-Judge)
- [[meta-agent-orchestration]] — Multi-agent chaining — prompt engineering di scale multi-agent
- [[ai-comm-protocol-deep-dive]] — MCP protocol, tool use internals