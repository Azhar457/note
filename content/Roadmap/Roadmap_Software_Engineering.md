---
tags:
  - roadmap
  - software-engineering
  - backend
  - fullstack
  - api
  - database
  - architecture
aliases:
  - Roadmap Software Engineer
  - Roadmap Backend Developer
  - Jalur Karir Backend
created: 2026-04-25
status: active
cssclasses:
  - wide-table
---

# 💻 Roadmap Software Engineering — Backend Developer

> **Filosofi:** Kalau kamu cuma bisa bikin CRUD API, itu artinya kamu bisa nulis code. Tapi kalau kamu bisa bikin CRUD + authentication + rate limiting + caching + automated testing + CI/CD deploy, itu artinya kamu bisa membangun production system — dan itu yang ditanya waktu interview. Rekruter akan tanya "oke, API kamu jalan, terus gimana handle 1000 request/detik?" Kalau kamu jawab "ada Redis cache layer di depan database, rate limiter per IP, dan horizontal scaling via load balancer" — itu yang menutup pertanyaan.

> [!important] Jalur Universal
> Backend engineering adalah **fondasi semua jalur IT**. Apapun spesialisasimu nanti (DevOps, Security, Data), kemampuan membangun dan memahami software dari dalam sangat berharga. Ini juga jalur dengan **variasi lowongan terbanyak** — dari startup hingga FAANG.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

```
Stack       : Local machine (Windows/WSL2 atau Ubuntu VM)
Jalur       : Backend Developer → Full-stack → Software Architect
Spek        : i7 Gen7, 8GB RAM (cukup untuk development)
Target Karir: Junior Backend → Mid Backend → Tech Lead / Architect

Urutan belajar:
  Fase 1 (fondasi)      : Bahasa (Go/Python/Node) + Git + SQL
  Fase 2 (web backend)  : REST API + Auth + Database Design + Testing
  Fase 3 (production)   : Caching + Queue + Monitoring + Deploy
  Fase 4 (architecture) : System Design + Microservices + DDD

Next step: Pilih satu bahasa (rekomendasi: Go atau Python), setup dev environment
```

---

## Fase 1 — Fondasi Programming & Data (Minggu 1–8)

> **Goal:** Kuasai satu bahasa dengan deep, bukan banyak bahasa secara dangkal.
> **Pilihan Bahasa:** Go (paling demand di startup Indonesia), Python (paling versatile), Node.js/TypeScript (full-stack friendly).

| Skill | Yang Dipelajari | Combo A+B yang Membuktikan |
|-------|-----------------|---------------------------|
| **Bahasa Utama** | Syntax, data structures, concurrency model, error handling, package management | Bahasa + **project nyata** = kamu bukan cuma belajar tutorial |
| **Git Workflow** | Branching, PR review, conventional commits, conflict resolution | Git + **open source contribution** = kamu paham collaboration |
| **SQL Deep** | JOIN, subquery, indexing, explain plan, transaction, ACID | SQL + **query optimization** = kamu paham kenapa API lambat |
| **Data Structures & Algo** | Array, HashMap, Tree, Graph, Big-O, sorting | DSA + **LeetCode medium** = kamu bisa pass technical interview |
| **Linux CLI** | File system, process, shell scripting, ssh, package management | Linux + **server deployment** = kamu bisa deploy tanpa GUI |

> [!tip] Pilih Bahasa Berdasarkan Target
> - **Go** → startup, microservices, high-performance backend. Gojek, Tokopedia, Shopee pakai Go.
> - **Python** → versatile. Backend (FastAPI/Django), data science, automation. Entry barrier rendah.
> - **Node.js/TS** → full-stack jika kamu juga mau frontend. Banyak dipakai di startup early-stage.
> - **Java/Kotlin** → enterprise, banking, fintech. Lowongan banyak tapi entry barrier tinggi.
> - **Laravel/PHP** → paling banyak lowongan di Indonesia untuk junior/freelance.

**Proyek Portofolio Fase 1:**
`CLI Tool yang Berguna` — bukan todo app. Contoh: CLI untuk monitor harga crypto, scraper berita, atau file organizer. Deploy ke GitHub dengan README yang bagus, unit test, dan CI.

---

## Fase 2 — Web Backend & API Development (Minggu 9–18)

> **Goal:** Bangun API yang layak production — bukan tutorial CRUD.

| Skill/Tool | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----------------|---------------------------|
| **REST API Design** | HTTP methods, status codes, versioning, pagination, filtering, HATEOAS | REST + **OpenAPI spec** = kamu bisa design API sebelum coding |
| **Authentication** | JWT, OAuth2, session, bcrypt, refresh token, RBAC | Auth + **multi-role system** = kamu paham access control end-to-end |
| **Database Design** | Normalization (3NF), indexing strategy, migration, ORM vs raw SQL | DB Design + **migration workflow** = kamu bisa evolve schema tanpa downtime |
| **PostgreSQL** | Indexing (B-tree, GIN, GiST), EXPLAIN ANALYZE, partitioning, JSONB | Postgres + **performance tuning** = kamu bisa diagnose slow query |
| **Testing** | Unit test, integration test, mocking, test coverage, TDD mindset | Testing + **CI integration** = kamu bisa refactor tanpa takut break |
| **Docker** | Dockerfile, compose, multi-stage build, dev vs prod config | Docker + **containerized development** = consistent environment everywhere |

> [!warning] Jangan Skip Testing
> 80% junior developer tidak menulis test. Ini yang paling mudah membedakanmu. Interview question: "berapa coverage test kamu?" Kalau jawabannya "saya tidak menulis test" — red flag.

**Proyek Portofolio Fase 2:**
`Full API Backend — Sistem Nyata` — bukan todo app. Contoh: sistem reservasi, inventory management, atau e-wallet. Harus punya: auth (JWT + refresh token), RBAC (admin/user), CRUD lengkap, pagination, search/filter, unit + integration test, Dockerfile, API docs (Swagger). **Deploy ke VPS kamu.**

---

## Fase 3 — Production-Grade Backend (Minggu 19–28)

> **Goal:** Dari "jalan di laptop saya" → "jalan di production tanpa saya yang jaga."

| Skill/Tool | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----------------|---------------------------|
| **Redis** | Caching (TTL, invalidation), session store, rate limiter, pub/sub | Redis + **cache layer di API** = kamu bisa jawab "gimana handle load?" |
| **Message Queue** | RabbitMQ/Redis Queue: async processing, retry, dead letter, fanout | Queue + **background job** = kamu paham decoupling |
| **CI/CD** | GitHub Actions: lint → test → build → deploy otomatis | CI/CD + **zero-downtime deploy** = kamu punya professional workflow |
| **Monitoring** | Prometheus metrics, structured logging, error tracking (Sentry) | Monitoring + **alert** = kamu tau sebelum user complain |
| **Security Basics** | Input validation, SQL injection prevention, CORS, rate limiting, helmet | Security + **OWASP Top 10 check** = kamu bisa bilang "saya sudah mitigasi" |

> [!tip] Redis Adalah Senjata Rahasia
> Hampir setiap interview backend senior menanyakan caching. "API kamu latency 500ms, gimana turunin ke 50ms?" Jawaban: "Redis cache dengan TTL 60s untuk data yang jarang berubah." Simple, tapi sangat banyak yang tidak bisa menjawab ini.

**Proyek Portofolio Fase 3:**
`Production-Ready API dengan Monitoring` — API dari Fase 2, sekarang dengan: Redis caching, rate limiter, background job processing (email notification via queue), CI/CD pipeline, Prometheus metrics + Grafana dashboard, structured logging. **Ini level mid-senior.**

---

## Fase 4 — Architecture & System Design (Minggu 29–40)

> **Goal:** Dari coder → architect. Ini yang menentukan salary ceiling.

| Skill | Yang Dipelajari | Combo A+B yang Membuktikan |
|-------|-----------------|---------------------------|
| **System Design** | Load balancer, CDN, database sharding, replication, CAP theorem | System Design + **diagram + tradeoff analysis** = kamu bisa lead architecture decision |
| **Microservices** | Service decomposition, API gateway, service mesh, distributed tracing | Microservices + **inter-service communication** = kamu paham distributed systems |
| **Event-Driven** | Event sourcing, CQRS, saga pattern, eventual consistency | Event-driven + **implementation** = kamu paham beyond CRUD |
| **DDD (Domain-Driven Design)** | Bounded context, aggregate, entity, value object, repository pattern | DDD + **real domain model** = kamu bisa model complex business logic |
| **Clean Architecture** | Dependency inversion, hexagonal, ports & adapters, SOLID | Clean arch + **testable codebase** = kamu bisa maintain large codebase |

**Proyek Portofolio Fase 4:**
`Microservices E-Commerce` — 3+ services (user, product, order) dengan: API gateway, async communication (event bus), database-per-service, distributed tracing (Jaeger), saga pattern untuk checkout flow. **Ini proyek yang membuat senior engineer mengangguk.**

---

## Roadmap Visual — Timeline 10 Bulan

```
Bulan 1-2         Bulan 3-5         Bulan 6-7         Bulan 8-10
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ FASE 1        │ │ FASE 2        │ │ FASE 3        │ │ FASE 4        │
│               │ │               │ │               │ │               │
│ Bahasa Utama  │ │ REST API      │ │ Redis Cache   │ │ System Design │
│ Git Workflow  │ │ Auth (JWT)    │ │ Message Queue │ │ Microservices │
│ SQL Deep      │ │ PostgreSQL    │ │ CI/CD         │ │ Event-Driven  │
│ DSA Basic     │ │ Testing       │ │ Monitoring    │ │ DDD           │
│ Linux         │ │ Docker        │ │ Security      │ │ Clean Arch    │
│               │ │               │ │               │ │               │
│ ► CLI Tool    │ │ ► Full API    │ │ ► Prod-Ready  │ │ ► Microsvcs   │
│   + Tests     │ │   Backend     │ │   API + Obs   │ │   E-Commerce  │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
```

---

## Sertifikasi & Credential Alternatif

| Fase | Credential | Kenapa |
|------|-----------|--------|
| Setelah Fase 1-2 | **GitHub Profile** yang solid | Recruiter cek GitHub. 5 repo dengan test + CI > 50 repo kosong |
| Setelah Fase 2 | **freeCodeCamp Backend Cert** (gratis) | Validasi dasar, bagus untuk CV entry-level |
| Setelah Fase 3 | **AWS Developer Associate** | Cloud deployment skill — banyak diminta |
| Setelah Fase 4 | **System Design Interview Prep** (book/course) | Bukan sertifikasi, tapi WAJIB untuk senior role |

---

## Tech Stack Recommendations per Target Market

| Target | Bahasa | Framework | Database | Why |
|--------|--------|-----------|----------|-----|
| **Startup Indonesia** | Go | Gin / Echo | PostgreSQL | Gojek, Tokopedia stack. Demand tinggi |
| **Enterprise/Banking** | Java | Spring Boot | Oracle/PostgreSQL | Stable, banyak lowongan corporate |
| **Freelance/Agency** | PHP | Laravel | MySQL | Paling banyak project freelance |
| **Full-stack Startup** | TypeScript | NestJS / Next.js | PostgreSQL | Frontend + backend 1 bahasa |
| **Data-Heavy** | Python | FastAPI / Django | PostgreSQL | Versatile, ML-ready |

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[SYSTEM_DESIGN]] — Database Internals + Software Architecture hierarchy
- [[FONDASI_CS]] — OS Internals & Computer Architecture fondasi
- [[MATEMATIKA_ALGORITMA]] — DSA & Discrete Math untuk interview
- [[Roadmap_DevOps]] — CI/CD & deploy skill overlap besar
- [[Roadmap_Data_Engineering]] — Backend → Data pipeline natural transition

---

*Roadmap Software Engineering Backend | Fase 1 (Bahasa) → Fase 4 (Architecture) · 10 Bulan*
