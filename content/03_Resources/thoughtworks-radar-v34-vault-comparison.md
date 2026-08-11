# Perbandingan ThoughtWorks Radar Vol.34 vs Vault QuCrypto

**47 blips** (Adopt + Trial) dari 118 total — 23% coverage, 76% gap.

## Status Coverage

| Status | Jumlah | Detail |
|--------|--------|--------|
| ✅ Dedicated note | 1 | Zero Trust Architecture |
| 🟡 Passing mention | 10 | Context engineering, DORA metrics, Claude Code, React Native, Svelte, Langfuse, SigNoz, DeepEval, LangGraph, LiteLLM |
| ❌ Tidak ada | 36 | Gap |

---

## Covered — Dedicated Note (1)

| # | Nama | Ring | Quadrant | File |
|---|------|------|----------|------|
| 6 | **Zero Trust Architecture** | Adopt | Techniques | `01_Library/Cyber_Security/zero-trust-security.md` |

## Covered — Passing Mention Only (10)

Passing mention = disebut sebagai referensi di catatan lain, bukan topik utama.

| # | Nama | Ring | Quadrant | Dimana disebut |
|---|------|------|----------|----------------|
| 1 | **Context engineering** | Adopt | Techniques | cognitive-architecture-engineering.md (bagian dari cognitive arch) |
| 3 | **DORA metrics** | Adopt | Techniques | cicd-shiftleft-shiftright.md (konteks CI/CD) |
| 67 | **Claude Code** | Adopt | Tools | ai-assisted-dev-workflow.md, context7-mcp-deepdive.md, llm-finetuning-toolchain.md |
| 101 | **React Native** | Adopt | L&F | how-context7-works.md (sebagai contoh cross-platform) |
| 102 | **Svelte** | Adopt | L&F | 5 file — pragmatic-programmer, context7-mcp-deepdive, how-context7-works |
| 46 | **Langfuse** | Trial | Platforms | 9 file — rag-pipeline, master-index, cognition |
| 49 | **SigNoz** | Trial | Platforms | llmops-ai-infrastructure.md |
| 105 | **DeepEval** | Trial | L&F | 9 file — cognitive-architecture, autonomous-system-design |
| 108 | **LangGraph** | Trial | L&F | 3 file — ai-engineering-stack-roadmap, multi-agent-orchestration, ai-driven-osint |
| 109 | **LiteLLM** | Trial | L&F | ai-engineering-stack-roadmap.md |

---

## Gap — Tidak Ada di Vault (36 blips)

### Adopt — Gap (10)

| # | Nama | Quadrant | Kenapa penting? |
|---|------|----------|-----------------|
| 2 | **Curated shared instructions** | Techniques | Instructions sbg artefak team — corelate dgn Agent Skills |
| 4 | **Passkeys** | Techniques | FIDO2 authentication — IAM gap |
| 5 | **Structured output from LLMs** | Techniques | JSON mode / constrained decoding — foundational utk tool calling |
| 66 | **Axe-core** | Tools | Accessibility testing — security? limited relevance |
| 68 | **Cursor** | Tools | AI coding editor — competitor Claude Code |
| 69 | **Kafbat UI** | Tools | Kafka UI — data-engineering tapi spesifik tool |
| 70 | **mise** | Tools | Rust-based dev env manager — asdf alternative |
| 98 | **Apache Iceberg** | L&F | Open table format — data lakehouse |
| 99 | **Declarative Automation Bundles** | L&F | Declarative infra pattern |
| 100 | **React JS** | L&F | Vault security-heavy, React blm ada dedicated note — low priority |

### Trial — Gap (26)

| # | Nama | Quadrant | Kenapa penting? |
|---|------|----------|-----------------|
| 7 | **Agent Skills** ⭐ | Techniques | **Prioritas #1** — modular instruction utk coding agents. Relevan langsung dgn Hermes skills system + sbg controlled alternative ke MCP |
| 8 | **Browser-based component testing** | Techniques | Component testing pattern |
| 9 | **Feedback sensors for coding agents** ⭐ | Techniques | **Prioritas #1** — quality gates deterministic (linter, compiler, test suite) sbg auto-correction sensors. Integrasi Hermes workflow |
| 10 | **Mapping code smells to refactoring** | Techniques | vault ada refactoring-martin-fowler tp blm mapping spesifik |
| 11 | **Mutation testing** | Techniques | Testing quality — bisa fusion dgn software-quality note |
| 12 | **Progressive context disclosure** | Techniques | UX pattern — relevan utk prompt design |
| 13 | **Sandboxed execution for coding agents** ⭐ | Techniques | **Prioritas #2** — isolasi eksekusi agent code. Relevan dgn container-security |
| 14 | **Semantic layer** | Techniques | Data abstraction |
| 15 | **Server-driven UI** | Techniques | Dynamic UI rendering |
| 42 | **AG-UI Protocol** | Platforms | Protocol agent ↔ UI communication — relevan utk Hermes plugin UI |
| 43 | **Apache APISIX** ⭐ | Platforms | **Prioritas #3** — API Gateway. vault ada api-security tapi APISIX spesifik blm |
| 44 | **AWS Bedrock AgentCore** | Platforms | AWS agentic platform — low priority (non-AWS stack) |
| 45 | **Graphiti** | Platforms | Temporal knowledge graph — vault ada graph db di note lain |
| 47 | **Port** | Platforms | Internal Developer Portal — IDP |
| 48 | **Replit** | Platforms | Cloud IDE |
| 71 | **cargo-mutants** ⭐ | Tools | **Prioritas #3** — Rust mutation testing. Langsung relevan dgn jarswaf Rust stack |
| 72 | **Claude Code plugin marketplace** ⭐ | Tools | **Prioritas #2** — plugin distribution ecosystem. Relevan dgn Agent Skills + skill curation |
| 73 | **Dev Containers** | Tools | Containerized dev env — vault ada container-kubernetes tp Dev Containers spesifik blm |
| 74 | **Figma Make** | Tools | Frontend prototyping |
| 75 | **OpenAI Codex** | Tools | Coding agent — perbandingan dgn Claude Code |
| 76 | **Typst** | Tools | Typesetting — relevan utk vault math rendering (LaTeX alternative) |
| 103 | **Typer** | Tools | Python CLI builder — relevan utk scripting pattern |
| 104 | **Agent Development Kit (ADK)** ⭐ | L&F | **Prioritas #3** — Google agent framework. Perbandingan dgn LangGraph/Mastra di vault |
| 106 | **Docling** ⭐ | L&F | **Prioritas #2** — document parsing. vault ada document-parsing-for-rag.md — bisa fusion/expand |
| 107 | **LangExtract** | L&F | LLM data extraction |
| 110 | **Modern.js** | L&F | React meta-framework |

---

## Prioritas Deep-Dive

### 🔴 P1 — Relevan Langsung dgn Stack-mu

| # | Blip | Ring | Kenapa |
|---|------|------|--------|
| 7 | **Agent Skills** | Trial | Mekanisme modular instruction untuk coding agents — corelate langsung dgn Hermes Agent skills system + disebut di themes sbg "controlled alternative to MCP". Ini yang paling krusial |
| 9 | **Feedback sensors for coding agents** | Trial | Deterministic quality gates (compiler, linter, test suite) sebagai feedback loop — bisa diintegrasikan ke Hermes cron workflow utk auto-verification |

### 🟡 P2 — High Relevance

| # | Blip | Ring | Kenapa |
|---|------|------|--------|
| 5 | **Structured output from LLMs** | Adopt | Foundational utk tool calling MCP — padahal dipake di Hermes tiap hari |
| 13 | **Sandboxed execution for coding agents** | Trial | Isolasi keamanan eksekusi agent-generated code — relevan dgn container-kubernetes-security |
| 72 | **Claude Code plugin marketplace** | Trial | Plugin distribution — relevan dgn Agent Skills curation |
| 106 | **Docling** | Trial | Document parsing — bisa di-expand dari document-parsing-for-rag.md yg sudah ada |

### 🟢 P3 — Nice to Have

| # | Blip | Ring | Kenapa |
|---|------|------|--------|
| 68 | **Cursor / 75. OpenAI Codex** | Adopt/Trial | Perbandingan AI coding tools (dgn Claude Code yg sudah ada di vault) |
| 104 | **Agent Development Kit (ADK)** | Trial | Google's agent framework — bisa dibandingkan dgn LangGraph |
| 71 | **cargo-mutants** | Trial | Rust mutation testing — relevan dgn jarswaf |
| 43 | **Apache APISIX** | Trial | API Gateway — vault ada api-security-deep-dive tapi APISIX spesifik blm |
| 76 | **Typst** | Trial | Alternative LaTeX typesetting — relevan utk vault math rendering issues |

---

## Rekomendasi Paling Efisien

**Bikin 1 catatan baru** `agent-skills-feedback-loop-deepdive.md` yg mencakup **Agent Skills + Feedback Sensors** sebagai satu kesatuan — karena keduanya saling melengkapi: Agent Skills sebagai feedforward control, Feedback Sensors sebagai feedback control. Ini langsung jadi tema "Putting coding agents on a leash" dari Radar.

Then expand:
2. `structured-output-llm-mcp-tool-calling.md` — structured output sebagai foundational layer
3. Update `document-parsing-for-rag.md` dengan Docling comparison
4. Bikin `sandboxed-execution-coding-agents.md` — security isolation untuk agent-generated code