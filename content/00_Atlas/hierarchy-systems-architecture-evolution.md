---
title: 🏗️ Systems Architecture Evolution — Dari Mainframe ke AI-Orchestrated Fabric
tags:
- hierarchy
- systems-architecture
- distributed-systems
- monolith
- microservices
- serverless
- event-driven
aliases:
- Systems Architecture Evolution
- Architecture Style Map
- Big System Design Hierarchy
- From Monolith to AI Orchestration
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 🏗️ Systems Architecture Evolution — Dari Mainframe ke AI-Orchestrated Fabric

> [!tip] Systems Architecture berevolusi dari **single mainframe** (1970) menuju **AI-orchestrated service mesh** (2026). Catatan ini memetakan 10 gaya arsitektur utama dalam 6 decade evolusi, dengan trade-off matrix per gaya, decision framework (tim size × domain complexity × scale requirement), dan timeline eksplisit. Setiap gaya dibahas dengan: kapan muncul, mengapa sukses/gagal, hingga di-replaced oleh apa.

---

## Daftar Isi

1. [[#1. Premise — Mengapa Arsitektur Selalu Berevolusi]]
2. [[#2. Decade-by-Decade Arsitektur Timeline]]
3. [[#3. Gaya 1 — Mainframe & Terminal]]
4. [[#4. Gaya 2 — Client-Server]]
5. [[#5. Gaya 3 — 3-Tier & Layered]]
6. [[#6. Gaya 4 — Service-Oriented Architecture (SOA)]]
7. [[#7. Gaya 5 — Microservices]]
8. [[#8. Gaya 6 — Serverless & FaaS]]
9. [[#9. Gaya 7 — Event-Driven Architecture]]
10. [[#10. Gaya 8 — Modular Monolith]]
11. [[#11. Gaya 9 — Edge-Cloud Hybrid]]
12. [[#12. Gaya 10 — AI-Orchestrated Fabric]]
13. [[#13. Decision Framework]]
14. [[#14. Trade-off Matrix]]
15. [[#15. Cross-Reference ke Vault]]
16. [[#References]]

---

## 1. Premise — Mengapa Arsitektur Selalu Berevolusi

Setiap decade, **tekanan** muncul yang menuntut arsitektur baru:

```
1970s: Computing mahal → centralized (mainframe)
1980s: PC murah → distributed (client-server)
1990s: Web butuh 3-tier → presentation/logic/data
2000s: Enterprise integration → SOA & ESB
2010s: Cloud + mobile scale → microservices
2015: Function economics → serverless
2020s: Real-time data → event-driven
2022s: Microservices overhead → modular monolith
2024: Latency critical → edge-cloud
2026: Complexity overwhelms → AI-orchestrated
```

**Prinsip dalang:** arsitektur bukan pilihan "free" — tiap gaya memecahkan masalah lama sambil menciptakan masalah baru. Vendor lock-in, distributed complexity, callback hell, fan-out fan-in overhead, telemetry noise — semuanya ada di tiap era.

**Kapan pilih gaya?** Ketika gaya sebelumnya **mulai gagal** di dimensi yang penting (tim productivity, scalability, time-to-market, latency).

---

## 2. Decade-by-Decade Arsitektur Timeline

```
┌──────┬────────────────────────────────────────────────────────┐
│ Era  │ Style yang dominant                                     │
├──────┼────────────────────────────────────────────────────────┤
│ 1960s│ Time-sharing mainframe                                  │
│ 1970s│ Mainframe + terminal cluster                            │
│ 1980s│ Client-server, PC network                               │
│ 1990s│ 3-tier, web-enabled                                     │
│ 2000s│ SOA, ESB                                                │
│ 2010s│ Microservices, cloud-native                             │
│ 2015s│ Serverless FaaS, container orchestration                │
│ 2020s│ Event-driven, CQRS, modular monolith, GraphQL          │
│ 2024+ │ Edge-cloud, AI-orchestrated, agent-orchestrated         │
│ 2026+ │ Self-healing infra, AI-native service mesh             │
└──────┴────────────────────────────────────────────────────────┘
```

---

## 3. Gaya 1 — Mainframe & Terminal

> Era 1965-1985: satu mainframe, banyak terminal dumb.

### 3.1 Karakteristik

```
┌──────────────────────────┐
│ Mainframe (single box)   │
│   ├─ Job scheduling      │
│   ├─ Time sharing        │
│   └─ Business logic      │
└──────┬───────────────────┘
       │ RS-232 / 3270 terminals
       ↓
   ┌────┐ ┌────┐ ┌────┐
   │Term│ │Term│ │Term│
   └────┘ └────┘ └────┘
```

**Kelebihan:**
- Compute efisien (resource split antar banyak user)
- Lisensi tunggal, IT terpusat
- Reliability tinggi (IBM mainframe 99.99% uptime)

**Kekurangan:**
- Vertical scaling mahal
- Tidak ada interactive computing
- Lock-in vendor satu
- Hanya batch processing

### 3.2 Sistem Khas
- IBM System/360, System/370
- DEC VAX
- Burroughs large systems

---

## 4. Gaya 2 — Client-Server

> Era 1985-2000: PC murah + Unix servers ubah komputasi.

### 4.1 Karakteristik

```
┌─────────┐                ┌─────────┐
│ Client  │ ── RPC/Network ─│ Server  │
│ (PC)    │                │ (Unix)  │
│ GUI app │                │ DB+Logic│
└─────────┘                └─────────┘
```

**Kelebihan:**
- Compute lokal di client (responsif UI)
- Independent deployment client/server
- PC murah = democratization

**Kekurangan:**
- Fat client → distribution problem
- Network failure = local cache inconsistency
- RPC versioning hell

### 4.2 Era's Stack

| Layer | Teknologi |
|-------|-----------|
| Client | Windows 3.1/95, Mac OS, X11 |
| Network | NetBEUI, IPX/SPX, TCP/IP |
| Server | Novell NetWare, Windows NT, Unix |
| Protocol | RPC, NetBIOS, SMB |
| Middleware | ODBC, CORBA |

---

## 5. Gaya 3 — 3-Tier & Layered

> Era 1995-2010: Web ubah segalanya. 3 lapis: presentation / logic / data.

### 5.1 Karakteristik

```
┌─────────────────────┐
│ Presentation Tier   │ ← HTML, JSP, ASP, Servlet
├─────────────────────┤
│ Business Logic Tier │ ← EJB, COM+, .NET
├─────────────────────┤
│ Data Tier           │ ← Oracle, SQL Server, PostgreSQL
└─────────────────────┘
```

**Prinsip:** Separation of concerns. Setiap tier punya tanggung jawab jelas.

**Kelebihan:**
- Independent scaling per tier
- Domain model testable tanpa UI
- DB scaling specialist bisa fokus

**Kekurangan:**
- Monolith di tier bisnis (perubahan satu modul = redeploy semua)
- Object-Relational impedance mismatch
- Hard untuk reuse asset antar aplikasi

### 5.2 Era Java EE / .NET

| Aspect | Java EE | .NET |
|--------|---------|-----|
| Container | App Server (WebLogic, JBoss) | IIS |
| Component | EJB, JPA, JMS | WebForms, WCF, ADO.NET |
| Transaction | JTA | MSDTC |
| Messaging | JMS (Tibco, MQ) | MSMQ |

---

## 6. Gaya 4 — Service-Oriented Architecture (SOA)

> Era 2002-2015: Reuse enterprise-wide via contract-first services.

### 6.1 Karakteristik

```
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│App 1 │ │App 2 │ │App 3 │ │Partner│
└──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘
   └────┬───┴───┬─────┴───┬────┘
        ↓       ↓         ↓
     ┌────────────────────────┐
     │ Enterprise Service Bus  │ ← Mediasi + transformasi
     └────────────────────────┘
              │
   ┌──────┐ ┌──────┐ ┌──────┐
   │Service A │ Service B │ Service C │ ← Reusable, contract-first
   └────────┘ └────────┘ └────────┘
```

### 6.2 Prinsip SOA

- **Contract-first** — WSDL mendahului implementasi
- **Loose coupling** — service contract stabil, impl bisa berubah
- **Reusability** — service dipakai banyak consumer
- **Composability** — service disusun jadi business process (BPEL)

### 6.3 Failure Modes

| Failure | Penyebab |
|---------|----------|
| ESB bottleneck | Semua traffic melalui hub |
| Protocol vendor lock-in (SAML/WS-*) | Standar kompleks, implementasi proprietary |
| BPEL spaghetti | Process kompleks jadi tidak maintainable |
| Service sprawl | 100 service tanpa owner jelas |

### 6.4 Lesson Learned

**Yang berhasil:**
- Standardisasi protokol (REST, JSON sukses menggantikan WS-*)
- Decoupling via message bus (Kafka, RabbitMQ sukses menggantikan ESB)
- Service ownership (Conway's Law: organisasi = arsitektur)

**Yang gagal:**
- Heavy WS-* stack (SOAP overhead)
- Centralized ESB bottleneck
- Spec-first tanpa observability

---

## 7. Gaya 5 — Microservices

> Era 2014-2025: Independen deploy + domain-aligned service.

### 7.1 Prinsip Microservices

| Prinsip | Penjelasan |
|---------|-----------|
| **Single Responsibility** | 1 service = 1 bounded context |
| **Independent Deploy** | Service deploy sendiri, tak ganggu service lain |
| **Decentralized Data** | Tiap service punya DB sendiri |
| **Smart Endpoints, Dumb Pipes** | Service berisi logic, transport sederhana |
| **Failure Isolation** | 1 service down ≠ total system down |
| **Observability** | Logging, metrics, traces by design |

### 7.2 Karakteristik Teknis

```
┌─────────────────┐  HTTP/REST or gRPC  ┌─────────────────┐
│ Order Service   │ ←────────────────→ │ User Service    │
│ (DB: Postgres)  │                    │ (DB: Postgres)  │
└────────┬────────┘                    └────────┬────────┘
         │ event                               │
         ↓                                     │ event
   ┌────────────┐                       ┌──────┴─────┐
   │ Kafka topic│                       │ Notification│
   └────────────┘                       └────────────┘
```

### 7.3 Trade-offs

| Pro | Con |
|-----|-----|
| Independent deployment | Distributed complexity |
| Polyglot (bahasa cocok per service) | Network latency / unreliable |
| Failure isolation | Data consistency harder |
| Domain-aligned teams | Operational overhead × N |

### 7.4 Lessons Learned (2025 Retrospektif)

- **Service mesh overhead** (Istio): banyak tim gagal, complexity tinggi
- **Distributed transactions**: Saga pattern replaces 2PC
- **Observability**: wajib di scale, mahal tapi untung
- **Micro frontend** symmetry (Module Federation, micro-frontends)
- **Conway's Law** tetap berlaku: tim alignment ≥ teknologi

---

## 8. Gaya 6 — Serverless & FaaS

> Era 2014-2026: Function-as-a-Service — deploy unit jadi function, infra auto-managed.

### 8.1 Karakteristik

```
┌──────────────────────────────────────────────────┐
│ API Gateway / Event Sources                       │
└────────┬─────────────┬───────────────┬────────────┘
         ↓             ↓               ↓
    ┌────────┐   ┌────────┐      ┌────────┐
    │Function│   │Function│  ... │Function│ ← Auto-scaled, pay-per-invoke
    │  /api  │   │  /img  │      │  /db   │
    └────────┘   └────────┘      └────────┘
         │             │               │
         └─────────────┴───────────────┘
                       ↓
              ┌─────────────────┐
              │ Managed Service │ ← DynamoDB, S3, RDS, SQS
              └─────────────────┘
```

### 8.2 Pro & Con

| Pro | Con |
|-----|-----|
| Zero ops — no servers managed | Cold start latency |
| Pay-per-invoke — cost zero untuk idle | Vendor lock-in (AWS Lambda → AWS ecosystem) |
| Auto-scaling tak terbatas | Function timeout (15 min) |
| Event-driven natively | Local testing kompleks |

### 8.3 Use Case Ideal

| Cocok | Kurang Cocok |
|-------|--------------|
| Event processor | Long-running processes |
| API endpoint stateless | WebSocket |
| Scheduled task (cron) | Stateful workflow |
| Glue code antara service | Hot-path latency-critical |

### 8.4 Trend 2026

- **Hybrid FaaS + container** — modal 70% FaaS, 30% container
- **WASM-based lambda** — instant cold start (<10ms)
- **GPU serverless** — ML inference pay-per-second
- **Edge functions** — Cloudflare Workers, Vercel Edge, Deno Deploy

---

## 9. Gaya 7 — Event-Driven Architecture

> Era 2018-2026: data sebagai stream, service sebagai reaction.

### 9.1 Prinsip

| Prinsip | Penjelasan |
|---------|-----------|
| **Event as source of truth** | Semua perubahan dicatat sebagai event |
| **Eventual consistency** | Service mungkin eventually consistent |
| **CQRS** | Separate read & write model |
| **Pub/Sub** | Producer tidak tau consumer |
| **Idempotency** | Receiver handles duplicate via event ID |

### 9.2 Topologi

```
[Producer] → [Event Bus (Kafka/Pulsar/RabbitMQ)] → [Consumer]
                       │
                       └──→ [Event Store] → [Replay] → [Audit]
```

### 9.3 Pattern Penting

| Pattern | Use Case |
|---------|----------|
| **Event Sourcing** | Replay-able history |
| **CQRS** | Different read/write scaling needs |
| **Saga** | Multi-service transaction |
| **Outbox** | Reliable event publish |
| **Choreography** | No orchestrator — emit + react |
| **Orchestration** | Central workflow engine (Temporal, Camunda, Step Functions) |

### 9.4 Trade-offs

| Pro | Con |
|-----|-----|
| Loose coupling — producer/consumer independent | Eventual consistency tricky |
| Replay-able history for audit/recovery | Schema evolution challenge |
| Natural for streaming analytics | Idempotency + dedup mandatory |
| Atomic single-source-o-truth | Higher complexity vs request/response |

### 9.5 Trend 2026

- **Streaming SQL** — Apache Flink, ksqlDB, Materialize
- **Lakehouse architecture** — Iceberg + Delta + Kafka
- **Event-driven cloud** — AWS EventBridge, Azure Event Grid

---

## 10. Gaya 8 — Modular Monolith

> Era 2022-2026: reaksi terhadap microservices overhead.

### 10.1 Karakteristik

```
┌──────────────────────────────────────────────────┐
│ Single Deployable                                 │
│   ├─ Billing Module    (well-bounded internally)   │
│   ├─ Inventory Module  (well-bounded internally)   │
│   ├─ User Module       (well-bounded internally)   │
│   └─ UI Module         (well-bounded internally)   │
│                                                    │
│ Single DB, separate schema per module             │
└──────────────────────────────────────────────────┘
```

### 10.2 Prinsip Kunci

- **Modular boundaries** — enforced by package structure (Maven, Cargo modules)
- **No cross-module DB access** — lewat API module lain
- **Single deploy unit** — semua module deploy bareng
- **Easy migration path** — module yang perlu scaling independen → extract ke service

### 10.3 Kapan Pilih

| Cocok | Kurang Cocok |
|-------|--------------|
| Tim size 5-30 | Tim size 100+ |
| Domain bounded complex tapi tidak meledak | Domain yang sudah meledak |
| Single-region deployment acceptable | Multi-region mandatory |
| Startup stages, time-to-market critical | Established high-scale |

### 10.4 Real-world Contoh

- **Shopify** — modular monolith Rails
- **GitHub** — (sekarang mendekati microservices)
- **Camping** (Ruby) — typical example

---

## 11. Gaya 9 — Edge-Cloud Hybrid

> Era 2024+: latency-critical workloads di edge, general di cloud.

### 11.1 Karakteristik

```
                           ┌──────────┐
                           │ Cloud    │
                           │ Heavy    │
                           │ Processing│
                           │ ML Train │
                           └───▲──────┘
                               │
                Burst, ack    │   Health
                               │
   ┌──────────────────────────┴──────────────────────┐
   ↓                       ↓                          ↓
┌───────────┐         ┌───────────┐            ┌───────────┐
│ Edge POP  │         │ Edge POP  │            │ Edge POP  │
│ (10ms RTT)│         │ (20ms RTT)│            │ (15ms RTT)│
│ Sub-ms proc│        │ Sub-ms    │            │           │
└───────────┘         └───────────┘            └───────────┘
```

### 11.2 Use Case

| Use Case | Edge Component | Cloud Component |
|---------|---------------|-----------------|
| Live video translation | Caption + translation | Heavy ML training |
| IoT predictive maintenance | Local classification | Fleet-wide learning |
| Multiplayer game | Sub-ms input | Matchmaking |
| CDN edge compute | Image opt, auth | Origin full app |

### 11.3 Trend 2026

- **CDN edge functions** — Cloudflare Workers, Vercel Edge
- **5G MEC** (Multi-access Edge Computing) — telco edge
- **Smart NIC offload** — network-level compute
- **Satellite edge** — Starlink compute nodes

---

## 12. Gaya 10 — AI-Orchestrated Fabric

> Era 2026+: services + infra dijalankan/dikoordinasikan oleh AI agents.

### 12.1 Karakteristik

```
┌──────────────────────────────────────────────────────────┐
│ User Intent (natural language / structured intent)       │
└─────────────┬────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────────────┐
│ Orchestrator Agent (LLM-powered)                         │
│   ├─ Plan: decompose task                                 │
│   ├─ Decide: pilih tool/service                           │
│   ├─ Execute: panggil service                              │
│   ├─ Verify: cek output                                    │
│   └─ Iterate: loop sampai goal achieved                   │
└─────────────┬────────────────────────────────────────────┘
              │
       ┌──────┼──────┬──────┬──────┐
       ↓      ↓      ↓      ↓      ↓
   [API] [Function] [DB tool] [SaaS] [Internal service]
```

### 12.2 MCP (Model Context Protocol)

Standardized protocol untuk agent-tool communication:
- **Tools** — agent-callable actions
- **Resources** — application-controlled context
- **Prompts** — user-controlled templates

### 12.3 Trend 2026

- **Persistent agent memory** — long-running context
- **Skills marketplace** — interface bagai plugin store
- **Multi-agent fabric** — agents collaborating
- **Self-healing infra** — AI mendeteksi + mitigasi anomali
- **Prompt-driven deployment** — intent → service graph otomatis

### 12.4 Risiko

| Risiko | Mitigasi |
|--------|----------|
| Hallucination → wrong action | Sandboxed execution + reversible actions |
| Cost blowup (LLM API calls) | Cost limiter, batching |
| Agent loop infinite | Max iteration + circuit breaker |
| Auditability | Logged action trace dengan reasoning |

**Koneksi ke Vault:**
- [[00_Atlas/hierarchy-llm-ai-systems]] — Layer 5 (Agentic)
- [[agentic-ai-mcp-architecture-deepdive]]
- [[meta-agent-orchestration]]

---

## 13. Decision Framework

### 13.1 Parameter Utama

```
Tim size     ───→  Architectural complexity
                    • 1-5: monolith
                    • 5-20: modular monolith
                    • 20-50: early microservices
                    • 50+: mature microservices / platform

Scale req    ───→  Distribution needs
                    • <10K RPS: monolith/edge
                    • 10K-100K: modular monolith
                    • 100K-1M: microservices
                    • >1M: microservices + edge

Domain       ───→  Modularity needs
                    • Simple CRUD: monolith
                    • Business complex: modular monolith
                    • Multi-tenant enterprise: microservices

Latency      ───→  Edge presence
                    • >100ms acceptable: cloud-only
                    • <50ms needed: edge-cloud hybrid
                    • <10ms: pure edge
```

### 13.2 Decision Tree

```
                    START
                      │
                  Latency <10ms?
                   /          \
                Yes             No
                │                │
            Pure Edge         \                        
            + Cloud Burst   Scale need?
                              /        \
                            >1M RPS     <1M RPS
                             │           │
                         Microservices   \
                            + Edge       Team size
                                            /     \
                                          <30       >30
                                           │         │
                                       Modular    Modular Mono
                                       Monolith   then extract
```

### 13.3 Anti-pattern Decision

| Anti-pattern | Tanda |
|--------------|-------|
| Distributed monolith | Microservices tightly coupled, deploy bareng |
| Big-bang microservices | Langsung extract dari monolith tanpa stabilitas |
| Premature FaaS | Cold-start hurts product |
| Edge-over-everything | Latency bukan bottleneck utama |
| Event-source everything | Read-before-write latency hurts |

---

## 14. Trade-off Matrix per Gaya

| Gaya | Complexity | Time-to-Market | Scalability | Vendor Lock | Team Size |
|------|:----------:|:--------------:|:-----------:|:-----------:|:---------:|
| Mainframe | High | Low | Vertical only | Total | 5-20 |
| Client-Server | Medium | Medium | Limited | Medium | 5-50 |
| 3-Tier | Low | High | Medium | Low | 5-100 |
| SOA | High | Low | Medium | High (ESB) | 50+ |
| Microservices | Very High | Medium (later fast) | Very High | Low | 50-500 |
| Serverless | Low | Very High | Auto | Very High | 1-50 |
| Event-Driven | High | Medium | Very High | Low | 20+ |
| Modular Monolith | Low-Medium | High | Medium | None | 5-30 |
| Edge-Cloud | High | Medium | High | Medium | 50+ |
| AI-Orchestrated | High | High (later fast) | Auto | Medium | Variable |

---

## 15. Cross-Reference ke Vault

| Layer | Catatan Vault |
|:-----:|---------------|
| Era 1-2 | [[hierarchy-operating-systems]], [[embedded-systems]] |
| Era 3 | [[cloud-infrastructure]] |
| Era 4 | [[00_Atlas/hierarchy-infrastructure-evolution]] (planned), [[distributed-systems]] |
| Era 5 | [[distributed-systems]], [[system-design]], [[container-kubernetes-security-deepdive]] |
| Era 6 | [[00_Atlas/hierarchy-infrastructure-evolution]], [[cloud-infrastructure]] |
| Era 7 | [[00_Atlas/hierarchy-llm-ai-systems]] (Layer 4 RAG), [[llmops-ai-infrastructure]] |
| Era 8 | [[00_Atlas/hierarchy-software-engineering-paradigm]] |
| Era 9 | [[00_Atlas/hierarchy-kernel-bypass-networking]] (smartNIC + edge compute) |
| Era 10 | [[00_Atlas/hierarchy-llm-ai-systems]], [[agentic-ai-mcp-architecture-deepdive]], [[ai-comm-protocol-deep-dive]] |

---

## References

1. F. Buschmann et al. *"Pattern-Oriented Software Architecture."* Wiley, 1996.
2. T. Erl. *"Service-Oriented Architecture: Concepts, Technology and Design."* 2005.
3. S. Newman. *"Building Microservices."* O'Reilly, 2021.
4. S. Newman. *"Monolith to Microservices."* O'Reilly, 2019.
5. C. Richardson. *"Microservices Patterns."* Manning, 2018.
6. M. Ford et al. *"Building Evolutionary Architectures."* O'Reilly, 2017.
7. C. Born. *"The Cloud-Native Attitude."* 2020.
8. AWS. *"Serverless Application Lens."* (2024).
9. M. Kleppmann. *"Designing Data-Intensive Applications."* O'Reilly, 2017.
10. A. Chakrabarti. *"Enterprise Service Bus."* 2009.
11. B. Stopford. *"Designing Event-Driven Systems."* Confluent, 2018.
12. S. Tilkov et al. *"Modular Monoliths."* (2023). https://simonbrown.je/
13. Microsoft. *"Azure Architecture Center."* https://learn.microsoft.com/azure/architecture/
14. Red Hat. *"What Is an Event-Driven Architecture."* (2024).
15. Gartner. *"Hype Cycle for Cloud Platform Services."* (2025).

audited
---
