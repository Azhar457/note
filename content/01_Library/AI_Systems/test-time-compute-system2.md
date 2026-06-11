---
tags:
  - test-time-compute
  - system-2
  - reasoning
  - chain-of-thought
  - tree-of-thought
  - inference-time
  - alignment
  - jailbreak
  - o1
  - process-reward-model
aliases:
  - Test-Time Compute
  - System 2 Thinking
  - Inference-Time Scaling
  - Reasoning Hierarchy
  - Hidden Chain of Thought
created: 2026-05-29
status: operational
cssclasses:
  - wide-table
---

# ⚡ TEST-TIME COMPUTE / SYSTEM 2 — Reasoning Hierarchy & Inference-Time Scaling

> System 1 bereaksi. System 2 berpikir. Tapi System 2 bisa diserang saat sedang berpikir — dan serangan itu terjadi di dalam pikiran itu sendiri.

> [!info] Cara Baca
> Level = Kedalaman reasoning. Kolom Blue Team = mekanisme kontrol dan alignment. Kolom Red Team = cara mengeksploitasi atau memanipulasi reasoning tersebut. Baca dari bawah (System 1 / Direct) ke atas (Meta-Cognitive) untuk memahami eskalasi kompleksitas kognitif.

---

## Tabel Reasoning per Level & Compute Stage

| Lapisan | Inference Stage / Reasoning Ring | ⚡ Mekanisme & Kemampuan | 🔵 Blue Team (Alignment & Control) | 🔴 Red Team (Exploit & Manipulation) |
| -------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Meta-Cognitive Architecture** | Level **7** _(Reasoning tentang reasoning)_ | Router model, System 1/2 arbitrator, dynamic compute allocation, cognitive architecture (Soar/ACT-R inspired), recursive oversight | Meta-alignment, architectural invariants, reasoning policy enforcement, recursive monitoring, capability control | Meta-manipulation ("kamu tidak perlu berpikir lama"), architecture confusion, System 1 override, recursive jailbreak |
| **Test-Time Scaling (o1-style)** | Level **6** _(Hidden chain, massive compute budget)_ | Hidden CoT, RL-at-inference, compute-optimal scaling, token scaling laws, long unmonitored reasoning chains | Output-only alignment, behavioral constraints, compute budget caps, sandboxing, refusal training on final output | Hidden thought extraction (think-tag leakage), compute exhaustion attacks, reasoning trace side-channel (timing/token count), obfuscated jailbreak via hidden reasoning |
| **Verification / PRM** | Level **5** _(External judgment, step-level scoring)_ | Process Reward Model (PRM), Outcome Reward Model (ORM), step-level verification, critique model, debate | Verifier robustness, reward model ensemble, adversarial training on verifiers, human-in-the-loop, conservative scoring | Reward model overoptimization, verifier deception, fake step justification, length exploitation (longer = higher reward), process reward hacking |
| **Reflection / Self-Correction** | Level **4** _(Meta-cognitive critique, iterative refinement)_ | Generate → Critique → Revise loop, error detection in own output, self-correction prompt, iterative refinement | Critique model alignment, revision bounds, rollback mechanisms, correction audit trails, maximum iteration guards | Reflection manipulation ("kritikmu salah"), infinite loop injection, correction fatigue, critique hijacking, "ignore all previous corrections" |
| **Self-Consistency / Ensemble** | Level **3** _(Parallel sampling, majority voting)_ | Multiple CoT samples, aggregate answers, confidence scoring, consistency threshold, outlier rejection | Divergence detection, outlier filtering, consistency threshold tuning, cross-check mechanisms, uncertainty quantification | Consistency exploitation (wrong answer made consistent), majority vote poisoning, confidence calibration attacks, self-confirming bias injection |
| **Tree-of-Thought (ToT)** | Level **2** _(Branching search, exploration)_ | Generate multiple reasoning paths, evaluate states, backtrack, BFS/DFS over reasoning space, deliberate search | Branch evaluation scoring, pruner alignment, search tree monitoring, consensus validation, exploration budget limit | Branch poisoning, evaluation function manipulation, reward hacking in pruner, dead-end injection, search space exhaustion |
| **Chain-of-Thought (CoT)** | Level **1** _(Linear reasoning, single path)_ | Step-by-step token generation, "Let's think step by step", intermediate reasoning tokens, arithmetic decomposition | CoT monitoring, step-wise alignment, reasoning trace audit, thought sanitization, step-level refusal training | CoT injection ("Ignore previous steps..."), reasoning hijacking, step-wise manipulation, distraction injection mid-reasoning, "suddenly the answer is..." |
| **System 1 / Direct Inference** | Level **0** _(Instant response, zero reasoning)_ | Pattern matching, cached response, next-token prediction, zero-shot completion, reflexive answer | Input filtering, prompt moderation, output classifier, refusal training, blocklist, embedding guardrails | Direct injection, character-level bypass, base64/rot13 encoding, translation attacks, prompt smuggling, suffix attacks (GCG) |

---

## Peta Posisi Reasoning — Test-Time Compute

```
Level 7  │ Meta-Cognitive Architecture  → Router + arbitrator + recursive oversight
Level 6  │ Test-Time Scaling (o1-style) │ Hidden CoT, massive compute, RL-at-inference
Level 5  │ Verification / PRM           │ Process Reward Model, step-level judge
Level 4  │ Reflection / Self-Correction │ Generate → Critique → Revise loop
Level 3  │ Self-Consistency / Ensemble  │ Parallel samples, majority vote
Level 2  │ Tree-of-Thought (ToT)      │ Branching search, BFS/DFS reasoning
Level 1  │ Chain-of-Thought (CoT)     │ Linear step-by-step reasoning
Level 0  │ System 1 / Direct          → Instant pattern matching, zero deliberation
```

> [!warning] Hidden Chain Extraction
> Model seperti o1/o3 dan DeepSeek R1 menyembunyikan reasoning chain. Tapi side-channel masih mungkin: token count yang tidak wajar, latency pattern, atau output yang mengindikasikan reasoning tertentu. Lebih berbahaya: **reasoning-aware jailbreak** yang memanipulasi hidden thought sebelum output final dibuat — defender tidak bisa melihat apa yang sedang dipikirkan.

---

## Koneksi: System 2 ↔ AI Levels ↔ Agentic AI

```
Test-Time Compute Level 6 (o1-style)
        │
        └── KONSEP IDENTIK ──► AI Levels Level 11 (Omega Point)
                               AI Levels Level 10 (Self-Improving)
                               ← ini bukan kebetulan: Test-Time Compute adalah
                                 jembatan dari static model ke dynamic reasoning

Chain-of-Thought Level 1 → ToT Level 2 → Reflection Level 4
        │
        └── DIPAKAI OLEH ───► Agentic AI (ReAct loop)
                              Hermes Agent (reasoning + tool use)
                              MCP orchestration (multi-step planning)
                              ← semua agent framework membutuhkan reasoning hierarchy

Process Reward Model Level 5
        │
        └── DIPAKAI OLEH ───► Alignment research (RLHF, DPO, KTO)
                              Red Teaming LLM (jailbreak via reasoning manipulation)
                              ← PRM adalah senjata ganda: alignment tool dan attack surface
```

> [!tip] Framework Berpikir: Dual-Use Reasoning
> Hampir semua teknik Test-Time Compute adalah dual-use:
> - **CoT monitoring** bisa dipakai untuk audit, tapi juga untuk extraction of hidden IP / secrets
> - **Self-consistency** meningkatkan accuracy, tapi juga bisa dipakai untuk generate multiple attack variants
> - **Reflection** memperbaiki jawaban, tapi juga bisa direkayasa untuk "meyakinkan diri sendiri" akan jawaban yang salah
>
> Pertanyaan sebelum deploy reasoning model:
> - Apakah reasoning trace bisa diakses attacker (via prompt injection atau side-channel)?
> - Apakah compute budget bisa di-exhaust via adversarial input (DoS reasoning)?
> - Apakah self-correction bisa di-hijack untuk meyakinkan model akan harmful output?

---

## 🔗 Lihat Juga

- [[index|Master Index]]
- [[ai-levels|AI Levels]] — Hierarki AI dari Level 0 (IF-THEN) sampai Level 11 (Omega Point)
- [[agentic-ai-mcp|Agentic AI & MCP]] — ReAct loop, tool use, dan multi-agent orchestration
- [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] — Prompt injection, jailbreak, dan alignment bypass
- [[cyber-security|Cyber Security]] — Blue Team vs Red Team mindset yang transferable
- [[underground-knowledge|Underground Knowledge]] — Dual-use knowledge framework

---

*Test-Time Compute / System 2 | Level 0 (Direct) → Level 7 (Meta-Cognitive) · Reasoning Hierarchy · Inference-Time Scaling*
