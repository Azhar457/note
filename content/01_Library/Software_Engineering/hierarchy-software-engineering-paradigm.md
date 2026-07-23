---
tags:
  - hierarchy
  - software-engineering
  - programming-paradigm
  - architecture
  - methodology
  - design-pattern
aliases:
  - Software Engineering Paradigm Hierarchy
  - SE Stack Layers
  - Code to Production Path
  - Engineering Discipline Map
status: seedling
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🧱 Software Engineering Hierarchy — Paradigma, Pola, dan Tahapan dari Kode ke Produksi

> [!tip] Software engineering bukan cuma "menulis kode". Ia adalah **8 lapisan disiplin** dari algoritma (matematis murni) sampai observability production (real-world feedback). Catatan ini memetakan evolusi dari **pemikiran prosedural** dewiketu (1960-an) sampai **AI-assisted coding agentic** (2026), dengan setiap lapisan dijelaskan: kapan muncul, trade-off, tools, dan kapan memilihnya. Ini adalah "peta industri" yang tidak ada di catatan manapun di vault SE.

---

## Daftar Isi

1. [[#1. Premise — Mengapa SE Bukan Hanya Kode]]
2. [[#2. Eight-Layer SE Hierarchy]]
3. [[#3. Layer 0 — Algorithmic Foundation (Pure Math)]]
4. [[#4. Layer 1 — Programming Paradigm]]
5. [[#5. Layer 2 — Language & Runtime]]
6. [[#6. Layer 3 — Design Pattern]]
7. [[#7. Layer 4 — Architecture Style]]
8. [[#8. Layer 5 — Engineering Process (Methodology)]]
9. [[#9. Layer 6 — Quality Engineering (Testing + Review)]]
10. [[#10. Layer 7 — Production Operations (DevOps/Platform)]]
11. [[#11. Layer 8 — AI-Assisted Engineering]]
12. [[#12. Timeline 1960-2026 — Evolusi Paradigma]]
13. [[#13. Trade-off Matrix per Paradigm]]
14. [[#14. Cross-Reference ke Vault]]
15. [[#References]]

---

## 1. Premise — Mengapa SE Bukan Hanya Kode

Kode hanyalah manifestasi terakhir dari **8 lapisan keputusan**:

```
[Coding]   ← apa yang ditulis developer
[Pattern]  ← bagaimana struktur kelas/modul
[Arch]     ← bagaimana service/component tersusun
[Process]  ← bagaimana tim berkolaborasi
[Quality]  ← bagaimana kita yakini benar
[Ops]      ← bagaimana jalan di production
[AI-Assist]← bagaimana AI bantu tiap lapisan
[Lang]     ← bahasa apa
[Paradigm]← model komputasi apa
[Algo]     ← matematika di bawahnya
```

Setiap lapisan punya evolusi sendiri — dan **salah satu bisa jadi bottleneck**:

- Algoritma terbaik tapi paradigm-nya salah = nggak scalable
- Paradigm ideal tapi pattern-nya nggak diterapkan = spaghetti
- Pattern clean tapi arch-nya monolith = deployment nightmare
- Arch modern tapi process-nya chaotic = merge hell

Catatan ini memetakan setiap lapisan dalam satu diagram, dengan trade-off matrix, dan cross-link ke catatan vault SE.

---

## 2. Eight-Layer SE Hierarchy

### 2.1 Definisi Setiap Layer

|   #   | Layer                   | Fungsi                                        | Failure Mode Tipikal                    |
| :---: | ----------------------- | --------------------------------------------- | --------------------------------------- |
| **0** | Algorithmic             | Solusi matematis murni                        | Algoritma salah asymptotic              |
| **1** | Paradigm                | Model komputasi (imperatif/fungsional/logika) | Salah paradigm = skalabilitas hilang    |
| **2** | Language & Runtime      | Bahasa konkret + ecosystem                    | Bahasa tepat tapi library salah         |
| **3** | Design Pattern          | Solusi template untuk masalah berulang        | Pattern over-applied = over-engineering |
| **4** | Architecture Style      | Struktur top-level service                    | Architecture mismatch dengan tim size   |
| **5** | Process                 | Metodologi tim (Waterfall → Agile → DevOps)   | Process overhead besar, output kecil    |
| **6** | Quality Engineering     | Testing, code review, QA                      | Test pyramid terbalik = coverage rendah |
| **7** | Operations              | CI/CD, observability, on-call                 | Deploy failure, alert fatigue           |
| **8** | AI-Assisted Engineering | LLM-powered tools, agents                     | AI-generated spaghetti dependency       |

### 2.2 Dependency Direction

```
        Layer 8 (AI-Assist)  ← bantuan di SEMUA layer
        Layer 7 (Ops)        ← produksi observability
        Layer 6 (Quality)    ← verifikasi
        Layer 5 (Process)    ← koordinasi
        Layer 4 (Arch)       ← struktur
        Layer 3 (Pattern)    ← template
        Layer 2 (Lang)       ← ekspresi
        Layer 1 (Paradigm)   ← model
        Layer 0 (Algo)       ← matematika
```

**Prinsip penting:** Lapisan bawah memberi BATAS (kalon semantik), lapisan atas memberi BATAS LAIN (tim, ekosistem). Pilih bahasa tanpa paradigma benar = sia-sia. Pilih paradigm tanpa algoritma benar = sia-sia.

---

## 3. Layer 0 — Algorithmic Foundation (Pure Math)

> Matematika murni — analisis kompleksitas, struktur data, teori graf, calculus of variations.

### 3.1 Komponen

| Komponen            | Contoh                                                       | Penting Karena                                 |
| ------------------- | ------------------------------------------------------------ | ---------------------------------------------- |
| Asymptotic Analysis | O, Ω, Θ notation                                             | Bandingkan algoritma independent dari hardware |
| Struktur Data       | Hash maps, B-trees, segment trees, LSM, bloom filters, ropes | Pilih struktur = 10-1000× speedup              |
| Algoritma           | Sort, search, graph, DP, greedy, divide-and-conquer          | Library implementasi yang baik                 |
| Teori Bilangan      | Modular arithmetic, primality testing                        | Kriptografi                                    |
| Teori Probabilitas  | Expected value, Markov, Bayesian                             | ML, performance modeling                       |
| Teori Graf          | Centrality, shortest path, spanning tree                     | Network, social graph, dependency              |
| Calculus            | Derivative, gradient, optimization                           | ML training                                    |

### 3.2 Big-O Ranges yang Penting

| Kompleksitas | Nama         | Scale                           | Cocok untuk                 |
| ------------ | ------------ | ------------------------------- | --------------------------- |
| O(1)         | Konstan      | hashtable lookup                | Cache, hash join            |
| O(log n)     | Logaritmik   | BST, B-tree, binary search      | Sorted array, balanced tree |
| O(√n)        | Sub-linear   | Sieve                           | n ≤ 10^7                    |
| O(n)         | Linear       | scan, simple search             | Untungnya processor-bound   |
| O(n log n)   | Lin-log      | quicksort, mergesort, FFT       | General purpose sort        |
| O(n²)        | Kuadratik    | bubble sort, naive string match | n ≤ 10^3                    |
| O(n^k)       | Polinomial   | naive matrix mult               | n ≤ 10^2                    |
| O(2^n)       | Eksponensial | subset sum, brute crypto        | n ≤ 20                      |
| O(n!)        | Faktorial    | traveling salesman naive        | n ≤ 10                      |

**Koneksi ke Vault:**

- [[math-and-algorithms]]
- [[computer-science-foundations]]
- [[encoding-serialization-compression-deepdive]]

---

## 4. Layer 1 — Programming Paradigm

> Cara kita **memodelkan komputasi** — menentukan bagaimana solusi diekspresikan.

### 4.1 Empat Paradigma Klasik

| Paradigm                   | Inti                                       | Bahasa Khas                  | Use Case                           |
| -------------------------- | ------------------------------------------ | ---------------------------- | ---------------------------------- |
| **Imperatif (Procedural)** | Langkah demi langkah, mutasi state         | C, Pascal, Fortran           | OS kernel, embedded                |
| **Object-Oriented (OOP)**  | Kelas + objek + inheritance + polymorphism | Java, C#, C++, Python        | Aplikasi enterprise besar          |
| **Functional (FP)**        | Pure functions, no mutable state           | Haskell, Clojure, Erlang, F# | Concurrent systems, data pipelines |
| **Logic**                  | Definisi fakta + rules → inferensi         | Prolog, Datalog, Mercury     | AI, knowledge base, rule engine    |

### 4.2 Paradigma Modern

| Paradigm             |   Tahun   | Inti                                       | Bahasa                            |
| -------------------- | :-------: | ------------------------------------------ | --------------------------------- |
| **Reactive**         |   2010    | Stream processing, back-pressure           | RxJS, RxJava, Reactive Streams    |
| **Dataflow**         |   2012    | Computation graph, async                   | Apache Beam, TensorFlow graphs    |
| **Actor Model**      | 1973-2020 | Message-passing concurrency                | Erlang, Akka (Scala), Elixir      |
| **Capability-based** |   2010s   | Token/pass-based security                  | RWKV, capability-secure languages |
| **Array-first**      |   2020    | Numpy/Julia-style vectorized ops           | Julia, MATLAB                     |
| **Probabilistic**    |   2015    | Bayesian inference built-in                | Gen.jl, Turing.jl, Pyro           |
| **Effect-typed**     |   2020s   | Compile-tracked effects (IO, state, error) | Koka, Eff, Roc                    |

### 4.3 Polyglot & Multi-paradigm

Realitanya, hampir semua bahasa modern adalah **multi-paradigm**:

- Python: OOP + procedural + functional (librari) + array-first (numpy)
- Rust: OOP-like + functional (closures, immutability) + ownership
- C++: OOP + procedural + functional (lambdas) + template metaprogramming
- Scala: OOP + functional (collectivist style)

**Kapan pilih paradigma?**

- High-frequency trading → FP (immutability = race-free)
- Game engine → OOP (entity component) atau ECS
- ML research → Array-first (Julia) atau Python+NumPy
- Distributed systems → Actor (Erlang) atau Reactive (Akka)
- OS kernel → Imperatif (C)
- Data pipeline → Dataflow (Beam)

**Koneksi ke Vault:**

- [[hierarchy-programming-language]] — PL evolution
- [[rust-systems-programming-tooling-keamanan]] — OOP+FP+Ownership

---

## 5. Layer 2 — Language & Runtime

> Bahasa konkret — sintaks, type system, memory model, runtime.

### 5.1 Klasifikasi Bahasa

| Generasi | Karakteristik         | Contoh                    |
| -------- | --------------------- | ------------------------- |
| 1GL      | Machine code          | biner                     |
| 2GL      | Assembly              | x86, ARM, RISC-V          |
| 3GL      | High-level prosedural | C, Pascal, Fortran        |
| 4GL      | Domain-specific       | SQL, R, SAS, MATLAB       |
| 5GL      | Logic-based           | Prolog                    |
| 6GL      | Visual/AI-assisted    | Scratch, MIT App Inventor |

### 5.2 Type System

| Type System        | Bahasa Contoh                       | Trade-off                                  |
| ------------------ | ----------------------------------- | ------------------------------------------ |
| **Static strong**  | Rust, Java, C#, TypeScript, Haskell | Compile-time safety, less friction runtime |
| **Static weak**    | C, C++                              | Powerful tapi undefined behavior           |
| **Dynamic strong** | Python, Ruby, Erlang                | Expressive, runtime errors                 |
| **Dynamic weak**   | JavaScript, PHP                     | Ekstrem permisif, surprise hidden          |
| **Gradual**        | TypeScript, Python (typing)         | Best of both, transisi mulus               |
| **Linear** (Rust)  | Rust                                | Memori aman, belajar susah                 |
| **Dependent**      | Idris, Lean, Coq                    | Prove-correct, learning curve extreme      |
| **Effect**         | Koka, Roc                           | Compile-track IO/state/error               |

### 5.3 Runtime Model

| Model                     | Bahasa                       | Karakteristik                                 |
| ------------------------- | ---------------------------- | --------------------------------------------- |
| Compiled to native        | C, C++, Rust, Go             | Fast startup, no runtime needed               |
| Compiled to bytecode + VM | Java, C#, Scala              | JIT optimization, GC                          |
| Interpreted               | Python, Ruby, Perl           | Dynamic, slower startup                       |
| JIT all-the-way           | Julia (via LLVM), LuaJIT     | Fast ramp up                                  |
| Transpiled                | TypeScript→JS, Kotlin→native | Multi-target output                           |
| WebAssembly               | Rust/C++→Wasm                | Universal runtime (browser, server, embedded) |
| Native interactive        | Lisp, Smalltalk              | Modify running program                        |

**Koneksi ke Vault:**

- [[hierarchy-programming-language]]
- [[rust-systems-programming-tooling-keamanan]]

---

## 6. Layer 3 — Design Pattern

> Solusi template untuk masalah yang berulang — Gang of Four dan seterusnya.

### 6.1 GoF (Gang of Four) Original

| Kategori       | Pattern                                                                                                     |
| -------------- | ----------------------------------------------------------------------------------------------------------- |
| **Creational** | Singleton, Factory, Abstract Factory, Builder, Prototype                                                    |
| **Structural** | Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy                                             |
| **Behavioral** | Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer, State, Strategy, Template, Visitor |

### 6.2 Pattern Modern

| Pattern                   | Use Case                  | Bahasa Khas                      |
| ------------------------- | ------------------------- | -------------------------------- |
| **Dependency Injection**  | Loose coupling framework  | Java (Spring), C# (.NET), Kotlin |
| **Repository**            | Data access abstraction   | Enterprise OOP                   |
| **Service Locator**       | Late binding              | Java                             |
| **Middleware**            | Request pipeline          | Express, Gin, FastAPI            |
| **Pub-Sub**               | Loose-coupled event       | Kafka, RabbitMQ                  |
| **CQRS**                  | Separate read/write model | Event-sourced systems            |
| **Saga**                  | Distributed transaction   | Microservices                    |
| **Outbox**                | Reliable event publish    | Event-driven architecture        |
| **Strangler Fig**         | Migrasi incremental       | Mengganti legacy                 |
| **Anti-Corruption Layer** | Isolasikan domain         | Microservices, monolith→service  |

### 6.3 Pattern Pitfalls

**Over-patterning (over-engineering):**

```python
# Bad: Singleton dependency dalam factory builder strategy observator
class FooFactorySingleton: ...

# Good: simple function
def make_foo(): return Foo()
```

**Under-patterning (spaghetti):**

- Business logic tercampur dengan IO
- Tidak ada abstraction layer
- Code reuse rendah

**Sweet spot:** Pattern dipakai kalau masalahnya benar berulang. Setiap pattern memecahkan masalah konkret — kalau masalahnya tidak konkret, pattern tidak membantu.

---

## 7. Layer 4 — Architecture Style

> Struktur top-level — bagaimana komponen disusun menjadi sistem utuh.

### 7.1 Evolusi Arsitektur

| Era   | Style                                    | Trade-off                                  |
| ----- | ---------------------------------------- | ------------------------------------------ |
| 1970s | **Monolith** (single program)            | Simplicity, single deploy unit             |
| 1990s | **Layered** (presentation/business/data) | Separation tapi tightly coupled            |
| 2000s | **SOA** (Service-Oriented Architecture)  | Reuse, contract-first                      |
| 2010s | **Microservices**                        | Independent deploy, distributed complexity |
| 2015s | **Serverless**                           | No-ops, vendor lock-in                     |
| 2020s | **Event-Driven**                         | Loose-coupled, eventual consistency        |
| 2022+ | **Modular Monolith**                     | Best of both worlds                        |
| 2024+ | **Hybrid edge-cloud**                    | Latency + scale                            |
| 2026+ | **AI-Orchestrated**                      | Agents composing services                  |

### 7.2 Decision Matrix

| Bisnis Characteristic                          | Architecture Style               |
| ---------------------------------------------- | -------------------------------- |
| Single team, narrow domain, simpel             | Modular Monolith                 |
| Multiple teams, single domain, scaling traffic | Microservices                    |
| Variable load, periodic spikes                 | Serverless (event-driven)        |
| Real-time critical                             | Event-Driven + Stream Processing |
| Latency-critical (sub-100ms)                   | Hybrid edge-cloud                |
| Frequent feature deployment                    | Microservices                    |
| Complex business logic, low coupling needed    | Modular Monolith                 |
| Geo-distributed users                          | Edge + Cloud burst               |

### 7.3 Distributed System Sub-Style

- **Client-Server** (1970s+)
- **3-tier** (Web 1.0)
- **N-tier** (Enterprise)
- **Peer-to-Peer** (BitTorrent, blockchain)
- **Event Bus** (Kafka, RabbitMQ)
- **CQRS** (Read/write separate)
- **Lambda Architecture** (batch + speed layer)
- **Kappa Architecture** (stream-only)

**Koneksi ke Vault:**

- [[hierarchy-systems-architecture-evolution]]
- [[distributed-systems]]
- [[system-design]]

---

## 8. Layer 5 — Engineering Process (Methodology)

> Bagaimana **tim** berkolaborasi — bukan kode individual.

### 8.1 Evolusi Metodologi

| Tahun | Metodologi                     | Inti                                          |
| :---: | ------------------------------ | --------------------------------------------- |
| 1970  | Waterfall                      | Sequential phases                             |
| 1986  | Spiral                         | Iterative, risk-driven                        |
| 2001  | **Agile Manifesto**            | 4 values, 12 principles                       |
| 2001  | Scrum                          | Sprint, role, ceremony                        |
| 2001  | XP (Extreme Programming)       | TDD, pair programming, continuous integration |
| 2005  | Kanban (popularized by Toyota) | Flow, WIP limit, pull system                  |
| 2009  | DevOps                         | Dev + Ops integrated                          |
| 2013  | GitOps                         | Git as source of truth for ops                |
| 2015  | Continuous Delivery            | Deploy anytime                                |
| 2018  | SRE (SRE book)                 | Error budget, toil reduction                  |
| 2020  | Platform Engineering           | Internal developer platform                   |
| 2024  | AI-Assisted Engineering        | LLM integrated dalam setiap step              |

### 8.2 Scrum Framework

| Role          | Fungsi                   |
| ------------- | ------------------------ |
| Product Owner | Prioritaskan backlog     |
| Scrum Master  | Fasilitor, hapus blocker |
| Dev Team      | Sprint delivery          |

| Ceremony           |  Durasi   | Fungsi                  |
| ------------------ | :-------: | ----------------------- |
| Sprint Planning    |   4-8h    | Pilih work untuk sprint |
| Daily Standup      | 15min/24h | Sinkronasi harian       |
| Sprint Review      |   1-4h    | Demo ke stakeholder     |
| Retrospective      |   1-3h    | Improve process         |
| Backlog Refinement |   1-2h    | Prepare next sprint     |

### 8.3 SRE Pillars

| SLO                  | Tiap service punya target                  |
| -------------------- | ------------------------------------------ |
| SLI                  | Indikator actual vs SLO                    |
| Error Budget         | Toleransi failure per quarter              |
| Toil                 | Repetitive manual work (target: <50% time) |
| Blameless Postmortem | Belajar, bukan salahkan                    |

### 8.4 Modern Trends

- **Trunk-based development** (vs long-lived feature branches)
- **Continuous deployment** (auto-merge to production)
- **Internal Developer Platforms (IDP)** — Backstage, etc.
- **Platform Engineering** — providing paved road to devs
- **AI pair programming** — Copilot, Cursor, Cline

**Koneksi ke Vault:**

- [[hierarchy-devops-cicd]] (kalau ada)

---

## 9. Layer 6 — Quality Engineering (Testing + Review)

> Bagaimana kita **yakin** bahwa perangkat lunak bekerja sesuai spec.

### 9.1 Test Pyramid

```
            ╱╲         E2E tests (sedikit, lambat)
           ╱  ╲        Integration tests (medium)
          ╱    ╲
         ╱──────╲      Unit tests (banyak, cepat)
        ╱        ╲
       ╱──────────╲    Static analysis, lint, type check
      ╱            ╲
     ╱──────────────╲  Type/syntax (compile-time)
```

**Anti-pattern: Ice-Cream Cone**

```
        ────────    E2E (banyak)
       ─────────
      ───────────   Integration
     ─────────────
    ──────────────  Unit (sedikit!)
    ──────────────  Manual/UI testing
```

Terlalu banyak E2E test = lambat, fragile, unfocused.

### 9.2 Jenis Testing

| Layer                 | Apa                          | Tools                         |   Speed   |
| --------------------- | ---------------------------- | ----------------------------- | :-------: |
| **Unit**              | Function/method in isolation | pytest, JUnit, Go test        |  <1s/run  |
| **Integration**       | Multi-component interaction  | Testcontainers, Docker        | ~min/run  |
| **Contract**          | API conforms to schema       | Pact, Spring Cloud Contract   | <30s/run  |
| **E2E**               | Full user journey            | Playwright, Selenium, Cypress | ~hour/run |
| **Performance**       | Load, latency                | k6, JMeter, Gatling           |   hours   |
| **Chaos**             | Failure injection            | Chaos Mesh, Litmus            | variable  |
| **Property-based**    | Random/shrunk input          | Hypothesis, QuickCheck        | <min/run  |
| **Fuzz**              | Mutation input               | libFuzzer, AFL, OWASP ZAP     | variable  |
| **Visual regression** | Screenshot comparison        | Percy, Playwright snapshots   |  minutes  |
| **Mutation**          | Validate test strength       | PIT, Stryker, Mutmut          |   slow    |

### 9.3 Code Review Best Practice

| Prinsip                       | Penjelasan                                  |
| ----------------------------- | ------------------------------------------- |
| Small PR                      | <300 lines changed                          |
| Single concern                | 1 PR = 1 purpose                            |
| Self-review first             | Author batasi sendiri                       |
| Comment rationale, not person | "kita bisa extract ini?" bukan "kamu salah" |
| Use tooling                   | ESLint, ruff, Clippy — bukan manual         |
| Iteration limit               | 2-3 rounds max                              |
| Approve != ship               | Setiap round reviewer bisa gate             |

**Koneksi ke Vault:**

- [[hierarchy-llm-ai-systems]] — Layer 6 (Evaluation in AI context)
- [[test-driven-development]]

---

## 10. Layer 7 — Production Operations

> CI/CD, observability, on-call, SLO compliance.

### 10.1 CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────┐
│ Source (Git)                                             │
├─────────────────────────────────────────────────────────┤
│ CI: Build, Test, Static, SBOM, Sign                      │
├─────────────────────────────────────────────────────────┤
│ Container Registry / Artifact Store                      │
├─────────────────────────────────────────────────────────┤
│ CD: Staging, Canary, Production                          │
├─────────────────────────────────────────────────────────┤
│ Continuous Verification (Observability)                  │
└─────────────────────────────────────────────────────────┘
```

### 10.2 Deployment Strategies

| Strategy                               | Complexity | Rollback Speed |         Risk          |
| -------------------------------------- | :--------: | :------------: | :-------------------: |
| **Recreate** (kill old, start new)     |    Low     | Slow (rebuild) |     High downtime     |
| **Rolling** (gradual replace)          |   Medium   |      Slow      |       Low risk        |
| **Blue-Green** (parallel infra switch) |    High    |    Instant     | Low risk, double cost |
| **Canary** (% traffic then ramp)       |   Medium   |      Fast      |       Low risk        |
| **Feature Flags** (runtime toggle)     |    High    |    Instant     |      Lowest risk      |
| **A/B Test** (statistical comparison)  |    High    | Configuration  |      Statistical      |

### 10.3 Observability Three Pillars

```
┌─────────────────────────────────────────────┐
│ Metrics (numerical, aggregated)              │ ← Prometheus, Datadog
├─────────────────────────────────────────────┤
│ Logs (discrete events)                       │ ← Loki, ELK, Splunk
├─────────────────────────────────────────────┤
│ Traces (request flow across services)        │ ← Jaeger, Zipkin, Tempo
└─────────────────────────────────────────────┘
       + Synthetic + Real User Monitoring
```

### 10.4 On-Call & Incident Response

| Fase       | Kegiatan                |
| ---------- | ----------------------- |
| Detection  | Alert firing            |
| Triage     | Severity classification |
| Mitigation | Stop the bleeding       |
| Resolution | Restore service         |
| Postmortem | Learning + action items |

**Koneksi ke Vault:**

- [[hierarchy-devops-cicd]] (planned)
- [[llmops-ai-infrastructure]]

---

## 11. Layer 8 — AI-Assisted Engineering

> **Layer tertinggi dan terbaru** — AI augmenting setiap layer di bawahnya.

### 11.1 Capability Spectrum

```
[AI-augmented] → [AI-collaborative] → [AI-autonomous]

Tab autocomplete → Pair programming → Agents executing tasks
(Copilot 2021)   (Cursor/Cline)       (Devin/Claude Code 2026)
```

### 11.2 Tooling Landscape (2026)

| Tool           |             Layer              | Specialty               |
| -------------- | :----------------------------: | ----------------------- |
| GitHub Copilot | Layer 2 (suggestion in editor) | Inline completion       |
| Cursor         |   Layer 2-3 (editor + chat)    | Multi-file edit         |
| Cline          | Layer 3-5 (editor + codebase)  | Open-source alternative |
| Claude Code    |   Layer 5-7 (terminal + ops)   | Long-running agents     |
| Codex CLI      |      Layer 2-3 (terminal)      | Code generation         |
| Continue.dev   |     Layer 2-3 (IDE plugin)     | Open source assistant   |
| Aider          |   Layer 3-4 (terminal pair)    | Git-aware changes       |
| v0 / Bolt      |     Layer 8 (UI prototype)     | Full-stack prototype    |

### 11.3 Risiko dan Mitigasi

| Risiko                       | Mitigasi                                         |
| ---------------------------- | ------------------------------------------------ |
| Generated code hallucination | Code review wajib, test coverage                 |
| License contamination        | License scanner, SDLC policy                     |
| Security regression          | SAST, dependency check                           |
| Dependency confusion         | Generative lebih suka library baru — verify SBOM |
| Model lock-in                | Portability, multi-model support                 |
| Skipped learning             | Developer tetap harus verify, understand         |

### 11.4 Trend 2026

- **Autonomous agents** for bug triage, test generation, doc sync
- **Multi-agent code review** — agents debate quality trade-offs
- **AI-generated infrastructure** — IaC dari task deskripsi
- **LLM as code reviewer** — supplementary reviewer untuk PR
- **AI-aware observability** — LLM-anomaly detection dalam production traces

**Koneksi ke Vault:**

- [[hierarchy-llm-ai-systems]]
- [[agentic-ai-mcp-architecture-deepdive]]
- [[ai-comm-protocol-deep-dive]]

---

## 12. Timeline 1960-2026 — Evolusi Paradigma

```
┌─────────────────────────────────────────────────────────────────┐
│ Era          │ Major Shift                                       │
├──────────────┼────────────────────────────────────────────────────┤
│ 1960s        │ Imperatif dominan (Fortran, ALGOL, C)            │
│ 1970s        │ OOP awal (Smalltalk), structured programming      │
│ 1980s        │ C++ (OOP mainstream), Unix philosophy            │
│ 1990s        │ Java (virtual machine, garbage collected)         │
│ 2000s        │ Agile (Scrum/XP), .NET, scripting (Python, Ruby)  │
│ 2010s        │ Microservices, cloud-native, reactive, FP revival  │
│              │ → Haskell in production (Facebook), Elixir + Phoenix |
│ 2015s        │ Rust stabilizes (1.0+), Kotlin, Go mainstream     │
│              │ → Microservices monolith debate                   │
│ 2020s        │ Serverless, edge, AI-assisted (Copilot)           │
│              │ → WebAssembly took off, assistants everywhere     │
│ 2024-2026    │ Agentic coding, multi-agent code review           │
│              │ → LLMs dominate code generation                   │
│              │ → Developer focus shifts ke design+architecture   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 13. Trade-off Matrix per Paradigm

| Paradigm    | Code Clarity | Concurrency Safety | Performance | Learning Curve |     Industry Fit     |
| ----------- | :----------: | :----------------: | :---------: | :------------: | :------------------: |
| Imperatif   |    Medium    |       Manual       |   Highest   |      Low       |     OS, embedded     |
| OOP         |  Medium-Low  |       Manual       |   Medium    |     Medium     |  Enterprise, games   |
| Functional  |     High     |    Default-safe    |   Medium    |  Medium-High   |    Data, finance     |
| Logic       |     High     |    Default-safe    |    Slow     |      High      |   AI, rule engine    |
| Reactive    |    Medium    |    Default-safe    |    High     |      High      |    Streaming, UI     |
| Actor       |    Medium    |    Default-safe    |    High     |      High      | Distributed, telecom |
| Array-first |  Very High   |       Manual       |   Highest   |     Medium     |    ML, numerical     |

### 13.1 Pitfalls per Paradigm

| Paradigm           | Typical Pitfall                                |
| ------------------ | ---------------------------------------------- |
| OOP                | God class, deep inheritance, leaky abstraction |
| FP                 | Monadic ceremony, premature generalization     |
| Reactive           | Back-pressure mismanagement, callback hell     |
| Actor              | Mailbox unbounded growth, akka anti-pattern    |
| Logic              | Compute explosion, infinite loop               |
| OOP+Functional mix | Split identity — class sekaligus accumulator   |

---

## 14. Cross-Reference ke Vault

|      Layer       | Catatan Vault                                                                                                      |
| :--------------: | ------------------------------------------------------------------------------------------------------------------ |
|   **0 (Algo)**   | [[math-and-algorithms]], [[computer-science-foundations]], [[encoding-serialization-compression-deepdive]]         |
| **1 (Paradigm)** | [[hierarchy-programming-language]], [[rust-systems-programming-tooling-keamanan]]                                  |
|   **2 (Lang)**   | [[hierarchy-programming-language]], [[hierarchy-software-engineering-paradigm]] (file ini)                         |
| **3 (Pattern)**  | (bisa ditambahkan), [[object-oriented-programming-deepdive]] (jika ada)                                            |
|   **4 (Arch)**   | [[hierarchy-systems-architecture-evolution]], [[distributed-systems]], [[system-design]], [[cloud-infrastructure]] |
| **5 (Process)**  | [[hierarchy-devops-cicd]] (planned)                                                                                |
| **6 (Quality)**  | [[test-driven-development]], [[e2e-testing]] (jika ada), [[software-supply-chain-security-deepdive]]               |
|   **7 (Ops)**    | [[hierarchy-infrastructure-evolution]], [[hierarchy-devops-cicd]]                                                  |
|    **8 (AI)**    | [[hierarchy-llm-ai-systems]], [[agentic-ai-mcp-architecture-deepdive]]                                             |

---

## References

1. E. Gamma et al. _"Design Patterns: Elements of Reusable Object-Oriented Software."_ (1994).
2. R. C. Martin. _"Clean Architecture."_ (2017).
3. M. Fowler. _"Patterns of Enterprise Application Architecture."_ (2002).
4. K. Beck. _"Test-Driven Development by Example."_ (2003).
5. E. Evans. _"Domain-Driven Design."_ (2003).
6. S. Newman. _"Building Microservices."_ (2021).
7. B. Beyer et al. _"Site Reliability Engineering."_ Google, 2016.
8. N. Ford et al. _"Building Evolutionary Architectures."_ (2017).
9. J. Highsmith. _"Adaptive Leadership."_ (2013).
10. M. Kim et al. _"The Phoenix Project."_ (2013).
11. H. Khononov. _"Learning Domain-Driven Design."_ (2021).
12. A. Cockcroft et al. _"Migrating to Cloud-Native Application Architectures."_ O'Reilly, 2015.
13. J. Willis. _"Beyond DevOps."_ (2017).
14. P. Sbarski. _"Serverless Development on AWS."_ (2017).
15. Andrew Ng. _"AI for Everyone."_ Coursera (2019-2025).
