---
title: "🤖 Coding Agent Harness — Feedforward & Feedback Controls: Agent Skills sebagai
  Modular Instruction & Deterministic Quality Gates untuk Self-Correction"
tags:
  - agent-skills
  - feedback-sensors
  - coding-agent
  - harness-engineering
  - feedforward-control
  - feedback-control
  - thoughtworks-radar-vol-34
  - library
aliases:
  - coding-agent-harness-engineering
  - feedforward-feedback-control-coding-agent
created: "2026-07-19"
updated: "2026-07-19"
status: growing
cssclasses:
  - wide-table
---

# 🤖 Coding Agent Harness — Feedforward & Feedback Controls

**Agent Skills sebagai Modular Instructions & Deterministic Quality Gates untuk Self-Correction**

> Coding agents susut nilai ketika manusia keluar dari loop. Tapi terus-menerus mengawasi 24/7 juga tak realistis. Dua mekanisme — **feedforward** (Agent Skills: modular instructions injected sebelum aksi) dan **feedback** (deterministic sensors: linter/compiler/test yang trigger auto-correction setelah aksi) — membentuk **harness engineering** yang membuat agent tetap aman dan produktif. Catatan ini membedah keduanya, dari foundation control theory sampai implementasi Hermes skill system dan CI-level feedback loop, merujuk langsung ThoughtWorks Radar Vol.34 (April 2026) blip #7 Agent Skills dan #9 Feedback Sensors.

> [!info] Hubungan ke Vault
>
> - [[agentic-ai-mcp-architecture-deepdive]] — fondasi agent + MCP architecture; harness adalah lapis kontrol di atas MCP
> - [[meta-agent-orchestration]] — orchestrator sebagai pemilih skill sebelum invoke agent
> - [[cognitive-architecture-engineering]] — context engineering sebagai feedforward layer kognitif
> - [[ai-assisted-dev-workflow]] — workflow praktis Claude Code + skill loading di vault Azhar
> - [[prompt-engineering-patterns]] — pattern modular instruction sebagai unit skill
> - [[test-driven-development]] — TDD sebagai deterministic sensor paling jujur
> - [[formal-verification-deepdive]] — formal proof sebagai sensor tertinggi
> - [[multi-agent-orchestration-patterns]] — pipeline agent + sensor untuk konstrain tiap stage
> - [[agentic-ai-mcp-roadmap]] — roadmap karir yang menyebutkan harness
> - [[rag-evaluation-framework]] — eval loop sebagai feedback sensor untuk RAG

---

## Daftar Isi

1. [[#Foundation]]
2. [[#Technical Deep-Dive]]
3. [[#Advanced]]
4. [[#Case Studies]]
5. [[#Koneksi ke Vault]]
6. [[#Referensi]]
7. [[#Bottom Line]]

---

## Foundation

Control theory bicara soal dua mekanisme yang membuat sistem tetap di jalur yang diinginkan:

| Mekanisme       | Saat di-apply                             | Analogi Coding Agent                                                  | Mitigasi Kegagalan                                                                   |
| --------------- | ----------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Feedforward** | Sebelum aksi (sebelum agent menulis kode) | Agent Skills: modular instructions dimuat just-in-time                | Agent keluar domain → instructions kurang relevan/tak dimuat                         |
| **Feedback**    | Setelah aksi (kode udah di-generate)      | Deterministic sensors: compiler, linter, type-checker, test suite     | Sensor true-negative (test pass tapi logic salah) → over-reliance pada test coverage |
| **Open-loop**   | Tanpa kontrol                             | "Vibe coding" — agent generate, human ship                            | Drift, cognitive debt, codebase rot                                                  |
| **Closed-loop** | Input pada output                         | Agent + sensor + auto-correction, human review only on sensor failure | Sensor noise → agent repair phantom issues                                           |

**Plot twist pertama:** feedforward dan feedback bukan pesaing. Mereka **koma-kompositional** — feedforward mengurangi expected work, feedback mengeliminasi unexpected errors. Skip feedforward → agent banyak `trial-and-error` untuk masalah yang udah solved (instruction udah ada ditulis di skill). Skip feedback → agent `over-confidently ship broken code` meski skill udah di-load.

Analogi konkret: imagine mobil self-driving. High-definition map (ter-embed di route planning) = feedforward. Camera, lidar, IMU real-time = feedback. Map telat update → mobil butuh feedback sensor untuk deteksi kondisi baru; feedback sensor telat → mobil relu pada map tapi bisa salah ambil jembatan yang udah di-renovasi. Begitu pula coding agent: skill (feedforward) "ingatkan" dia soal project conventions; sensor (feedback) "cek" ulang setelah dia generate.

**ThoughtWorks Radar Vol.34 (April 2026) menempatkan keduanya di ring Trial** — bukan Adopt — karena **pergeseran adoptability** berkembang cepat tapi best-practice standar belum mature di seluruh industry. Let's deep-dive masing-masing.

---

## Technical Deep-Dive

### Agent Skills sebagai Feedforward Control

**Definisi (ThoughtWorks Radar Vol.34 blip #7):** _"Agent Skills—curated, modular sets of instructions that can be loaded into an agent's context on demand—have emerged as a major advancement. They allow teams to modularize instructions and conventions, loading them just in time rather than dumping everything into a single monolithic system prompt."_

#### Arsitektur: Monolithic System Prompt vs Modular Skills

```
LEGACY:            MODULAR (Agent Skills):
┌──────────┐       ┌──────────┐  ┌──────────┐  ┌──────────┐
│ System   │       │  System  │  │ Skill A  │  │ Skill B  │
│ Prompt   │       │  Prompt  │  │ (loaded  │  │ (loaded  │
│ (50KB)   │       │  (3KB)   │  │  JIT)    │  │  JIT)    │
│ +        │       │ +        │  │          │  │          │
│ every    │       │  Router  │  │  SKILL.md│  │  SKILL.md│
│ rule     │       └────┬─────┘  └────┬─────┘  └────┬─────┘
│          │            │             │             │
│  → slow  │            └─ router pick skill ───────┘
│  → token │
│    burn  │            ▼
└──────────┘       ┌──────────┐
                   │  Agent   │  ← rich context, low token burn
                   │  Action  │
                   └──────────┘
```

**Token math sederhana:** kalau system prompt 50KB ≈ 12K tokens, setiap inference call burn 12K tokens buat prompt overhead. Dengan skill modular (3KB system + 2KB skill), only 1.25K tokens — **~90% hemat** pada repetitive calls.

#### Anatomy of an Agent Skill

Sebuah Agent Skill punya 3 komponen wajib sesuai Hermes Agent & Anthropic Claude Code convention:

1. **`SKILL.md`** — frontmatter YAML + body markdown. Frontmatter fields:

| Field            | Required | Fungsi                                                                                     |
| ---------------- | -------- | ------------------------------------------------------------------------------------------ |
| `name`           | ✅       | Lowercase, hyphen-separated, max 64 char                                                   |
| `description`    | ✅       | Trigger condition sebagai natural language — agent router baca ini untuk match user intent |
| `platforms`      | no       | OS filter (linux/macos/windows)                                                            |
| `tags`           | no       | Multi-tag untuk discovery                                                                  |
| `metadata`       | no       | Extended attributes objek                                                                  |
| `related_skills` | no       | Cross-skill navigation hint                                                                |

```yaml
---
name: agent-skills-feedback-sensors
description: "Use when user wants to set up harness engineering, modular agent skills, or feedback-loop CI for coding agents"
tags: [coding-agent, harness, ci, quality-gates]
metadata:
  hermes:
    skill_version: "1.0.0"
    minimum_hermes_version: "2.x"
related_skills:
  - test-driven-development
  - claude-code
platforms: [linux]
---
```

2. **Body Markdown** — SKILL.md body berisi:
   - **Trigger conditions** (kapan invoke)
   - **Numbered steps** dengan exact commands (bukan vague "configure properly")
   - **Pitfalls section** (error messages yang sering muncul + fix)
   - **Verification steps** (bukan-asumsi check)

3. **Linked files** (fungsi modularitas):
   - `references/` — Dokumen pendukung (API specs, deep dives)
   - `templates/` — Boilerplate (`.env.example`, `CLAUDE.md.hbs`)
   - `scripts/` — Executable shell/Python (auto-verification, sync)
   - `assets/` — Static binary (icons, sample inputs)

### Feedback Sensors sebagai Deterministic Quality Gates

**Definisi (Radar blip #9):** _"To make coding agents more effective and reduce the need for human supervision, teams are integrating deterministic quality gates—compilers, linters, type checkers, and test suites—directly into agent workflows so failures trigger auto-correction before human review."_*

#### Taxonomy of Sensors

| Kategori                   | Mekanisme                              | Contoh                                          | Latensi       | False Positive        |
| -------------------------- | -------------------------------------- | ----------------------------------------------- | ------------- | --------------------- |
| **Static analysis**        | Parse AST tanpa execute                | Rust analyzer, ESLint, mypy, typer              | ms-second     | Rendah                |
| **Type check**             | Compile-time type inference            | cargo check, tsc, pyright                       | second        | Sangat rendah         |
| **Unit/Integration test**  | Execute code dengan fixtures           | pytest, cargo test, Jest                        | second-minute | Moderate (mock drift) |
| **Mutation testing**       | Inject bug ke codebase, cek test catch | cargo-mutants (Radar blip #71), mutmut, Stryker | minute-hour   | Tinggi (early signal) |
| **Fuzz testing**           | Generate malformed input               | WuppieFuzz (Radar blip #96), AFL, libFuzzer     | hour-day      | Tinggi (novel paths)  |
| **Static quality metrics** | Code complexity, duplication           | CodeScene (Radar blip #81), SonarQube           | second-minute | Moderate              |
| **Formal verification**    | Mathematical proof of property         | Dafny, Coq, Lean, Kani (Rust)                   | hour-day      | Sangat rendah         |

**Plot twist kedua:** Mutation testing lebih jujur dari coverage. Coverage 100% dengan weak assertions = theater. Mutation testing inject bug, jika test gak catch → assertion lemah. Ini yang membuat Radar Vol.34 meng-Adopt Mutation Testing (#11 Trial) sebagai bagian dari feedback sensor stack.

#### Code Example: Hermes Auto-Verification Pattern

```bash
# Hermes skill: write-file → auto syntax check → on-failure auto-repair
#!/usr/bin/env bash
# scripts/verify-and-repair.sh — Handcrafted pattern Hermes uses
set -euo pipefail

FILE="$1"                          # arg 1: file yang baru di-write
EXT="${FILE##*.}"

# 1. Syntax check by extension
case "$EXT" in
  py)  python3 -c "import ast; ast.parse(open('$FILE').read())" 2>&1 | head -5 ;;
  rs)  rustc --edition 2021 --crate-type lib "$FILE" -o /tmp/check 2>&1 | head -5 ;;
  ts)  tsc --noEmit "$FILE" 2>&1 | head -5 ;;
  go)  gofmt -l "$FILE" && gopls check "$FILE" 2>&1 | head -5 ;;
  *)   echo "skip: no sensor for $EXT" ;;
esac

# 2. Kalau failed, auto-prompt agent dengan error context
if [ -n "${SENSOR_ERR:-}" ]; then
  echo "SENSOR_FAILED"
  echo "$SENSOR_ERR"
  # Hermes akan re-prompt agent dengan error message + file content
  exit 2
fi

# 3. Functional smoke test kalau ada tests/fixture
if [ -f "tests/test_$(basename "$FILE" .py).py" ]; then
  pytest "tests/test_$(basename "$FILE" .py).py" -x --tb=short 2>&1 | tail -20
fi

exit 0
```

Pentingnya: `set -euo pipefail` — sensor **wajib fail-loud**. Silent sensor (`set +e`) bahaya besar karena agent akan assume semua OK dan lanjut.

#### Hermes Skill Mechanism (concrete)

Hermes Agent secara native mengimplementasikan Agent Skills. Setiap skill adalah directory `~/.hermes/skills/<name>/` dengan `SKILL.md`. Hermes inject deskripsi skill ke agent context; agent router `mcp__skill_router__list_available_skills()` meng-embat matching. Saat user prompt "set up Docker reverse proxy", router match ke skill `docker-patterns`, load `SKILL.md` full content ke context, lalu agent pake numbered steps + pitfalls dari skill.

### Harness Engineering — The Integration

**Harness engineering** (jadi Martin Fowler buat rubric artikel di martinfowler.com/articles/harness-engineering.html yang ThoughtWorks Radar refer dalam themes Vol.34) adalah istilah umum untuk **kombinasi feedforward + feedback controls** yang wrapping coding agent.

```
                ┌─────────────────────────────┐
                │                             │
   User ───────►│  FEEDFORWARD LAYER           │
   request      │  - System prompt            │
                │  - Agent Skills (JIT loaded) │
                │  - Spec-driven dev context   │
                └────────────┬────────────────┘
                             │
                             ▼
                ┌─────────────────────────────┐
                │  AGENT ACTION                │
                │  - Tool call / code write    │
                │  - Filesystem touch          │
                └────────────┬────────────────┘
                             │
                             ▼
                ┌─────────────────────────────┐
                │  FEEDBACK LAYER              │
                │  - Syntax check (fail-loud)  │
                │  - Type check (fail-fast)    │
                │  - Test suite (fail-honest)  │
                │  - Mutation test (fail-true) │
                └─────────┬───────────────────┘
                          │
                ┌─────────▼─────────┐
                │ Sensor outcome?   │
                └─────────┬─────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
       ┌──────────┐               ┌──────────┐
       │  PASS    │               │   FAIL   │
       │  → human │               │  → self- │
       │    review│               │    repair│
       │    only  │               │  (retry  │
       │          │               │   sensor)│
       └──────────┘               └──────────┘
```

**Key invariant:** human review **hanya** di-trigger kalau sensor PASS. Kalau sensor FAIL, agent **tidak** boleh bounce ke human; dia wajib self-correct (retry) dengan feedback sensor sebagai context baru. Ini yang disebut "putting coding agents on a leash" — ThoughtWorks Radar Vol.34 themes #4.

---

## Advanced

### Agent Instruction Bloat (Radar #34, Caution)

> _"Context files such as AGENTS.md and CLAUDE.md tend to grow organically, accumulating outdated instructions, contradictory directives, and scope creep. Over time, this degrades agent performance because the agent wastes tokens processing stale or irrelevant rules."_

**Mitigasi:** splits + aliases, bukan grow monolit. Vault Azhar pakai self-skill system:

- `~/.hermes/skills/hermes-agent/SKILL.md` — only hermes-agent mechanics
- `~/.hermes/skills/9router-web-fetch/SKILL.md` — only web fetch via specific platform
- Agent instruction hanya load skill spesifik saat trigger condition match

**Anti-pattern:** `CLAUDE.md` 8KB dengan bagian "Rust conventions" + "React conventions" + "Python conventions" + "deployment rules". Skill spindle: satu skill = satu trigger, satu domain.

### Progressive Context Disclosure (Radar #12, Trial)

> _"Progressive context disclosure is a technique within agent harness engineering where the agent receives minimal context initially, then requests or loads more as needed based on the task's progression."_

Ini mengubah Agent Skills dari "static load" ke "just-enough just-in-time" 2-arah:

1. Agent menerima trigger keyword + skill **name only** (summary)
2. Agent decide apakah skill relevant
3. Kalau relevant, agent invoke loader untuk dapat **full skill content**
4. Kalau perlu deeper, agent baca `references/` files on-demand

Hermes skill system sudah menerapkan pattern ini via `skill_view(name)` tanpa `file_path` (hanya SKILL.md), lalu agent baca linked files via `skill_view(name, file_path="./references/api-spec.md")` saat perlu.

### MCP by Default (Radar #40, Caution)

> _"As the Model Context Protocol (MCP) gains traction, teams reach for it as the default integration mechanism. But MCP exposes the agent to external systems and data — each tool is an attack surface. Not every integration needs to be an MCP server."_

**Agent Skills sebagai controlled alternative:**

- MCP server = **runtime integration**, agent bisa invoke external system anytime → lethal trifecta (private data + untrusted content + external action)
- Agent Skill = **compile-time instruction**, agent lebih constrained karena hanya baca, tidak invoke arbitrary external system

Untuk operasi yang **doesn't need runtime choice** (misal: "untuk install package selalu pake `uv pip install` bukan `pip install`"), Agent Skill is the better mechanism — no MCP server overhead, no runtime exposure.

### Skills as Executable Onboarding Documentation (Radar #28, Assess)

Skill bukan cuma untuk agent — bisa juga jadi single source of truth untuk onboarding human developer. Skill bernama `deploy-prod-checklist` yang nge-list numbered steps + pitfalls + verification = bisa dibaca oleh junior dev sebagai runbook yang sama persis yang agent pake.

**Double-duty pitfall:** kalau audience beda (human vs agent), mungkin perlu skill version terpisah. Audience human lebih butuh "kenapa" (reasoning), agent lebih butuh "apa" (command). Sebagian vault note Azhar (e.g. `ai-assisted-dev-workflow.md`) udah experiment dengan format ini.

---

## Case Studies

| Studi Kasus                                  | Konteks                                                                              | Temuan Kunci                                                                                                                                           | Mitigasi Diimplementasi                                                                                                                                                   |
| -------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hermes Agent `hermes-agent` skill            | Skill built-in yang laod setiap session untuk mendokumentasikan hermes CLI mechanics | Skill frontmatter description di-jadikan trigger untuk prompt soal "configuring hermes", "troubleshooting hermes tools"                                | Pemisahan `description` (trigger hint, 1 kalimat) vs body (numbered commands) — router match cepat, skill body loading just-in-time                                       |
| Superpowers + Claude Code plugin marketplace | ThoughtWorks Radar blip #72 (Trial) #115 Superpowers catalog                         | Distribusi skill via plugin marketplace → skill journey dari author → consumer. Testing skill requires sandboxed environment                           | Skill packaging dengan `manifest.json`, versioning semver, trust establishment via maintainer repo + checksum verification                                                |
| cargo-mutants in Rust CI loop                | ThoughtWorks Radar blip #71 (Trial) — mutation testing untuk Rust                    | Coverage 100% but weak assertions. cargo-mutants inject bug → identify test tidak catch. False positive tinggi early-stage, filter via baseline needed | Integration sebagai weekly CI job (bukan per-commit) untuk turunkan noise. Threshold: mutasi caught > 80%                                                                 |
| WuppieFuzz untuk REST API agent output       | ThoughtWorks Radar blip #96 (Assess) — fuzzer untuk REST APIs                        | Agent yang generate curl commands ke API butuh fuzzing untuk ensure response schema tidak hallucinated                                                 | WuppieFuzz sebagai post-action sensor: agent invoke API → WuppieFuzz re-invoke dengan mutated input → compare response, alert kalau mismatch                              |
| OpenClaw akibat Codebase Cognitive Debt      | ThoughtWorks Radar blip #97 (Caution) + #36 Codebase Cognitive Debt                  | Open-source autonomous agent proyek — kode di-generate cepat tapi gap pemahaman pengembang akumulasi → maintainer struggle debug                       | Force plugin marketplace dengan mandatory `RATIONALE.md` per submission; mutation testing untuk catch weak assertions; skills-based modularization bukan monolithic agent |

---

## Koneksi ke Vault

- [[agentic-ai-mcp-architecture-deepdive]] — fondasi agent + MCP; harness adalah lapis kontrol di atas MCP
- [[cognitive-architecture-engineering]] — context engineering sebagai feedforward kognitif layer
- [[agentic-ai-mcp-roadmap]] — roadmap karir pengembangan skill author → agent architect
- [[multi-agent-orchestration-patterns]] — pipeline agent + sensor untuk konstrain tiap stage
- [[meta-agent-orchestration]] — orchestrator sebagai pemilih skill sebelum invoke agent
- [[ai-assisted-dev-workflow]] — workflow Claude Code + skill loading di vault Azhar — concrete examples
- [[prompt-engineering-patterns]] — pattern modular instruction sebagai unit skill
- [[rag-evaluation-framework]] — eval loop sebagai feedback sensor untuk RAG
- [[test-driven-development]] — TDD sebagai deterministic sensor paling jujur, RED-GREEN-REFACTOR loop
- [[formal-verification-deepdive]] — formal proof sebagai sensor tertinggi (post-mutation)
- [[structured-output-llm-mcp-tool-calling-deepdive]] — JSON schema sebagai sensor контракт untuk tool calls
- [[sandboxed-execution-coding-agents-deepdive]] — isolasi sebelum sensor dijalankan untuk safety

---

## Referensi

1. ThoughtWorks Technology Radar Vol.34 (April 2026). https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2026/04/tr_technology_radar_vol_34_en.pdf
2. ThoughtWorks Radar blip #7 Agent Skills. https://www.thoughtworks.com/radar/techniques/agent-skills
3. ThoughtWorks Radar blip #9 Feedback Sensors for Coding Agents. https://www.thoughtworks.com/radar/techniques/feedback-sensors-for-coding-agents
4. ThoughtWorks Radar blip #34 Agent Instruction Bloat (Caution). https://www.thoughtworks.com/radar/techniques/agent-instruction-bloat
5. ThoughtWorks Radar blip #12 Progressive Context Disclosure. https://www.thoughtworks.com/radar/techniques/progressive-context-disclosure
6. ThoughtWorks Radar blip #28 Skills as Executable Onboarding Documentation. https://www.thoughtworks.com/radar/techniques/skills-as-executable-onboarding-documentation
7. ThoughtWorks Radar blip #40 MCP by Default (Caution). https://www.thoughtworks.com/radar/techniques/mcp-by-default
8. ThoughtWorks Radar blip #11 Mutation Testing — paling jujur signal. https://www.thoughtworks.com/radar/techniques/mutation-testing
9. ThoughtWorks Radar blip #71 cargo-mutants. https://www.thoughtworks.com/radar/tools/cargo-mutants
10. ThoughtWorks Radar blip #96 WuppieFuzz. https://www.thoughtworks.com/radar/tools/wuppiefuzz
11. ThoughtWorks Radar blip #81 CodeScene. https://www.thoughtworks.com/radar/tools/codescene
12. ThoughtWorks Radar blip #72 Claude Code plugin marketplace. https://www.thoughtworks.com/radar/tools/claude-code-plugin-marketplace
13. ThoughtWorks Radar blip #115 Superpowers. https://www.thoughtworks.com/radar/languages-and-frameworks/superpowers
14. ThoughtWorks Radar blip #97 OpenClaw (Caution). https://www.thoughtworks.com/radar/tools/openclaw
15. ThoughtWorks Radar blip #36 Codebase Cognitive Debt (Caution). https://www.thoughtworks.com/radar/techniques/codebase-cognitive-debt
16. Martin Fowler, "Harness Engineering: Putting Coding Agents on a Leash". https://martinfowler.com/articles/harness-engineering.html
17. Simon Willison, "The Lethal Trifecta". https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
18. Anthropic, "Agent Skills Documentation". https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills
19. Hermes Agent skill spec. https://hermes-agent.nousresearch.com/docs/skills
20. Model Context Protocol (MCP) Specification. https://modelcontextprotocol.io/
21. Hermes Agent — Skills router MCP. `mcp__skill_router__list_available_skills`
22. Anthropic, "Claude Code Plugin Marketplace — Protocol". https://docs.anthropic.com/en/docs/claude-code/plugins
23. OpenSpec Specification. https://github.com/openspec-dev/openspec
24. GitHub Spec-Kit. https://github.com/github/spec-kit
25. JarsWAF coding conventions (internal). [[rust-systems-programming-tooling-keamanan]]

---

> [!tip] Bottom Line
> Agent Skills + feedback sensors = harness engineering — kontrol ganda untuk coding agents yang produktif. Hanya pakai monolithic system prompt itu teknologi 2024; pakai modular skills yang loaded JIT itu konsep 2025; tapi **gabung feedforward (skill) dengan feedback (sensor) yang fail-loud** baru engineering disiplin 2026 ke atas. Mulai kecil: satu skill untuk satu pain domain, satu sensor untuk satu failure mode. Dari situ loop-powered self-correction akan tumbuh organik. Jangan lupa sensor yang baik = `set -euo pipefail`, bukan `set +e` silent-passer. Coverage tanpa mutation testing = theater; mutation testing tanpa human reason = noise. Kombinasi mereka — plus skill untuk pandu reasoning awalnya — itulah harness.
