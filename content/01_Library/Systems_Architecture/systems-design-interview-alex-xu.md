---
title: "Systems Design Interview — Alex Xu"
tags:
  - system-design
  - interview
  - architecture
  - scalability
aliases:
  - "System Design Interview Alex Xu"
  - "Alex Xu"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🧩 Systems Design Interview — An Insider's Guide

> Alex Xu — 2021

**Tesis:** Buku praktis buat lolos system design interview — _frameworks, trade-offs, dan blueprints_ untuk 15+ soal klasik (design Twitter, YouTube, URL shortener, dll). Bukan soal hafal — soal _structured thinking_.

---

## 📌 Kenapa Penting

- System design = interview paling ditakuti — soal ambiguity, gak ada jawaban benar
- Buku ini kasih **template** + **langkah-langkah konkret** + trade-offs
- Bahkan buat non-interview: _design thinking_ buat arsitektur real-world

## 🎯 Key Takeaways

**1. Framework 4 Langkah**

1. **Understand the problem** — clarify requirements (functional vs non-functional)
2. **High-level design** — diagram kotak + panah, pilih core components
3. **Deep dive** — detail bottlenecks, trade-offs
4. **Wrap up** — what would you add with more time

**2. Core Components Set**

- **Load balancer** (HAProxy, Nginx, ELB — layer 4 vs 7)
- **CDN** (CloudFront, CloudFlare)
- **Database** — SQL vs NoSQL, replication, sharding
- **Cache** (Redis, Memcached — cache aside, write-through, write-back)
- **Message queue** (Kafka, RabbitMQ, SQS)
- **Blob storage** (S3, GCS)

**3. Key Design Patterns**

| Problem           | Approach                                   |
| ----------------- | ------------------------------------------ |
| URL shortener     | Base62 encoding + key generation service   |
| Chat system       | WebSocket + message sync + presence        |
| Notification      | Event bus + fan-out + rate limiting        |
| News feed         | Fan-out on write vs on read                |
| Rate limiter      | Token bucket, leaky bucket, sliding window |
| Proximity service | QuadTree / Geohash                         |
| Distributed ID    | Snowflake (timestamp + worker + seq)       |

**4. Back-of-the-envelope**

- Daily active users → requests/second
- Storage growth per day/month/year
- Bandwidth estimation
- **Useful constants:**
  - 1 request/sec = ~86K requests/day
  - 1 GB/day = ~12KBps continuous
  - MySQL ~2000 reads/sec per node
  - Redis ~100000 ops/sec per node

## 📖 Bab Penting

| Bab | Soal                       | Pelajaran                   |
| --- | -------------------------- | --------------------------- |
| 1   | URL Shortener              | Base62, key gen, 301 vs 302 |
| 2   | Web Crawler                | BFS, politeness, dedup      |
| 5   | Design Consistent Hashing  | **Wajib** — fundamental     |
| 7   | Design Unique ID Generator | Snowflake                   |
| 10  | Design Notification System | Fan-out, event bus          |
| 12  | Design Chat System         | WebSocket, presence, sync   |
| 13  | Design Search Autocomplete | Trie                        |

## ⚠️ Keterbatasan

- **Interview-focused** — depth kurang untuk real production
- Beberapa solusi oversimplified (cuma 2 server + 1 database)
- **Pair with DDIA** untuk depth — DDIA theory, Alex Xu framework
- Edisi 2 (2022) nambah design Twitter, YouTube, Google Drive

## 🚦 Cara Baca

1. Baca **chapter 1-5** buat framework + komponen dasar
2. Lompat ke soal yang relevant (interview target)
3. Coba _design yourself_ sebelum baca solusi — baru bandingkan

## 🔗 Koneksi

- [[ddia-kleppmann]] — depth theory distributed systems
- [[sre-google]] — production reliability
- [[clrs-introduction-to-algorithms]] — consistent hashing, trie

## ✅ Checklist

- [ ] Hafal framework 4 langkah + tahu cara pake
- [ ] Latih 3 soal: URL shortener, chat, news feed
- [ ] Back-of-the-envelope: estimasi storage + bandwidth
- [ ] Diagram tools: Figma / Excalidraw / draw.io
