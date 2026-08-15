---
title: Attack Perspective — Failure Modes & Resilience (Red Team)
tags:
- attack
- red-team
- failure-modes
- resilience
- cascading-failure
- chaos-engineering
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Failure Modes & Resilience — Perspektif Penyerang

> Red team tidak hanya eksploitasi vulnerability — mereka **memicu failure mode sistem** untuk meng-create cascading failure. Chaos engineering (attacker perspective) = identifikasi single point of failure yang bisa weaponized.

## 1. Attack → Failure Mode Mapping

| Failure Mode | Trigger Serangan | MITRE ID | Teknik | Impact | Detection Gap |
|-------------|-----------------|----------|--------|--------|----------------|
| **Cascading Failure** | Overload satu service → dependency chain crash | T1490 | Resource exhaustion (connection pool, thread pool) | Multi-service failure | Rate limit = per-IP, not per-service |
| **Split Brain** | Network partition → consensus diverge → data corruption | T1490 | Network partition (BGP/DNS) → etcd/ZK split | Data inconsistency → data loss | Consensus audit = log replay (rare real-time) |
| **Resource Exhaustion** | Memory/CPU/connection exhaustion → OOM kill → service crash | T1490 | Fork bomb, memory bomb, slowloris | Service denial → failover hijack | Resource monitoring = threshold, not pattern |
| **Deadlock** | Force concurrent request → deadlock → service hang | T1490 | Concurrent lock contention → deadlock | Service hang → DoS | Deadlock detection = runtime only |
| **Thundering Herd** | Trigger simultaneous wake → resource storm | T1490 | Cache expiry → all client → simultaneous refresh | Stampede → overload → crash | Cache stampede detection = rare |
| **Backpressure Failure** | Downstream slow → upstream queue → overflow → crash | T1490 | Slowloris → slow response → upstream queue overflow | Upstream → downstream crash | Queue monitoring = partial |
| **DNS Failure** | DNS exhaustion → resolution fail → all service down | T1490 | DNS flood → resolver overload → resolution timeout | Global service failure → DoS | DNS monitoring = basic |

## 2. Cascading Failure Attack Chain

```
Recon: Identifikasi dependency chain (service → DB → cache → queue)
 ↓
Target: Single point of failure (SPOF)
 ├── Database connection pool → if full → all service fail
 ├── Redis cache → if down → all service → direct DB → DB crash
 ├── Message queue (Kafka/RabbitMQ) → if overload → all consumer fail
 └── Identity provider (Okta/AD) → if down → all auth fail
 ↓
Trigger:
 ├── Exhaust connection pool: concurrent request → pool full → service hang
 ├── Kill Redis: poison cache → invalid key → cache stampede → DB overload
 ├── Flood Kafka: large message → queue backlog → consumer OOM
 └── DoS IdP: overload Okta → all auth timeout → global access failure
 ↓
Cascading:
 ├── Service A fail → Service B (dependency A) fail → C (dependency B) fail
 ├── Database crash → semua service → crash
 └→ Identity down → semua auth → deny → semua service → fail
 ↓
Failover Hijack:
 ├── Failed service → failover ke backup → backup tidak siap → crash
 ├── DNS failover → redirect ke attacker → MITM → credential harvest
 └→ Chaos → confusion → blue team overload → red team operate
 ↓
Impact: Multi-service cascading failure → DoS → data loss → failover hijack
```

## 3. Resilience Bypass

| Resilience Kontrol | Red Team Bypass | Teknik |
|---------------------|----------------|--------|
| **Rate Limiting** | Distributed request (botnet, low rate per IP) | IP rotation, proxy chain |
| **Circuit Breaker** | Slow request → circuit open → deny legitimate | Slowloris → trigger circuit |
| **Retry with Backoff** | Force retry storm → amplify load | Trigger error → client retry → amplify |
| **Bulkhead Isolation** | Exhaust all pool → all bulkhead → degrade | Multi-pool exhaustion |
| **Health Check** | Spoof health (200 OK) → service not restarted | Health endpoint = trivial |
| **Failover** | Compromise backup → primary fail → backup (attacker) | Pre-position di backup |
| **Graceful Degradation** | Force non-critical failure → degrade → critical failure | Chain non-critical → critical |

## 4. Chaos Engineering (Attacker Perspective)

| Chaos Teknik | Weaponized | Konkret |
|-------------|----------|--------|
| **Network latency injection** | Ya → slowloris → backpressure → cascade | tc qdisc delay add |
| **Pod kill** | Ya → controller overload → cascading | kubectl delete pod → controller storm |
| **DNS failure** | Ya → global resolution fail → cascade | DNS flood → resolver down |
| **CPU stress** | Ya → resource exhaustion → OOM kill | stress-ng → rival resource |
| **Network partition** | Ya → split brain → consensus diverge | iptables DROP → partition |
| **Disk latency** | Ya → I/O wait → service timeout cascade | dd → fill disk → I/O stress |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **stress-ng** | Resource exhaustion (CPU, memory, I/O) |
| **Slowloris** | Slow HTTP → connection pool exhaustion |
| **hping3** | TCP flood → resource exhaustion |
| **astisbo/distaster** | Chaos engineering toolkit |
| **Chaos Mesh** | K8s chaos (pod kill, network partition, latency) |
| **Gremlin** | Managed chaos engineering (commercial) |

## 6. Referensi
- Chaos Engineering — https://principlesofchaos.org/
- Chaos Mesh — https://chaos-mesh.org/
- Cascading Failure — https://en.wikipedia.org/wiki/Cascading_failure
- SPOF (Single Point of Failure) — https://en.wikipedia.org/wiki/Single_point_of_failure
---

audited
---
