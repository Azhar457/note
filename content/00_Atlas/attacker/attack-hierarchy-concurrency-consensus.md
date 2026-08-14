---
title: Attack Perspective — Concurrency & Consensus (Red Team)
tags: [attack,red-team,concurrency,consensus,race-condition,toctou,distributed-systems]
source: hierarchy-concurrency-consensus.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Concurrency & Consensus — Perspektif Penyerang

> Concurrency bug = race condition, TOCTOU, deadlock exploitation. Distributed consensus = Raft/Paxos compromise → split brain → fork. Red team eksploitasi: TOCTOU bypass, race condition privilege escalation, consensus node takeover.

## 1. Attack Surface Concurrency

| Konsep | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|--------|--------|----------|---------------|---------|----------------|
| **Race Condition** | TOCTOU (Time-of-Check-to-Time-of-Use), symlink race | T1055 | inotify + symlink swap,renomber file | Race = non-deterministic → hard reproduce | Race detector = runtime only |
| **Double-Fetch** | Kernel double-fetch → userland data change between fetch | T1068 | Custom kernel exploit (double fetch) | Kernel race → transient | Kernel race detection = static analysis (rare) |
| **Integer Overflow** | TQ_INIT queue overflow, counter wrap → memory corrupt | T1205.002 | fuzzing, manual analysis | Overflow = silent corruption | Int overflow detection = static analyzer (rare) |
| **Deadlock Exploit** | Force deadlock → service hang → DoS → failover hijack | T1490 | Concurrent request flood | Deadlock = legit resource contention | Hard distinguish dari real load |
| **Atomic Violation** | Non-atomic check-and-set → race → bypass auth | T1548 | Concurrent auth request → race → both succeed | Race = non-deterministic | Auth race detection = rare |
| **Consensus (Raft/Paxos)** | Node takeover → split brain → fork → conflicting state | T1490 | Compromise leader → partition → fork | Consensus = legit protocol | Consensus audit = log replay (rare real-time) |
| **Distributed Lock** | Lock service compromise → lock hijack → double-spend | T1490 | Redis/ZK lock hijack → concurrent access | Lock = legit mechanism | Lock audit = rare |

## 2. TOCTOU Attack (Privilege Escalation)

```
Target: SUID binary yang open file berdasarkan path user-controlled
 ↓
Setup: inotifywait -m /tmp/file → monitor saat binary open file
 ↓
Race:
 ├── T0: SUID binary checks file access (access())
 ├── T1: Attacker swaps file → symlink ke /etc/shadow
 ├── T2: SUID binary open symlink → reads /etc/shadow
 └── Window: antara check (T0) dan open (T2) → attc swap
 ↓
Bypass: CTF setup → symlink swap in tight loop → win race
 ├── Thread 1: execve SUID binary (trigger check)
 ├── Thread 2: rename + symlink swap (trigger open)
 └── Race window: miliseconds → repeat ribuan kali
 ↓
Trigger: `while true; do ln -sf /etc/shadow /tmp/file; done`
 ↓
Result: SUID binary reads /etc/shadow → output ke stdout → credential dump
```

## 3. Consensus Attack (Distributed System)

```
Target: etcd/ZooKeeper/Consul cluster (K8s backend)
 ↓
Recon: Identifikasi consensus cluster → node count, leader, term
 ↓
Attack Option 1 — Leader Compromise:
 ├── Compromise leader node → control log replication
 ├── Inject malicious log entry → commit → push ke follower
 └── Follower accept (leader = trusted source)
 ↓
Attack Option 2 — Network Partition (Split Brain):
 ├── Network partition → cluster split → 2 partition
 ├── Each partition elects new leader → 2 leader → 2 log
 ├── Conflict: different commit → fork → inconsistent state
 └── Heal partition: kemudian → merge conflict → data loss
 ↓
Attack Option 3 — Quorum Loss:
 ├── Kill majority node → cluster quorum lost → write fail
 ├── Wait → failover ke backup → join stale node → log overwrite
 └── Stale node → push old log → overwrite current → data corruption
 ↓
Impact:
 ├── etcd: K8s state corrupt → pod deletion, secret read
 ├── ZooKeeper: leader reconfig → service hijack
 └── Consul: service discovery → redirect ke malicious service
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **inotifywait** | File access monitor (TOCTOU trigger) |
| **pwntools** | Race condition exploit (thread + rename) |
| **etcdctl** | etcd manipulation (K8s consensus) |
| **zkCli** | ZooKeeper client (consensus abuse) |
| **consul** | Consul API (service discovery hijack) |
| **Custom fuzzer** | Concurrency fuzzing (ThreadSanitizer target) |

## 5. Referensi
- TOCTOU Vulnerability — https://owasp.org/www-community/attacks/...
- Raft Consensus — https://raft.github.edu/
- etcd Security — https://etcd.io/docs/latest/op-guide/security/
- Race Condition (CWE-362) — https://cwe.mitre.org/data/definitions/362.html
- Kubernetes etcd — https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/