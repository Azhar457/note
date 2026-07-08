---
title: "Systems Design Interview — Alex Xu"
tags:
  - library
  - systems-architecture
aliases:
  - "systems-design-interview-alex-xu"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# 🧩 Systems Design Interview — An Insider's Guide

> Alex Xu — 2021

## 📌 Kenapa Penting

System design merupakan salah satu bagian paling menantang dalam proses interview, karena soal yang diberikan seringkali memiliki ambiguity dan tidak ada jawaban yang benar. Oleh karena itu, buku ini hadir untuk memberikan template, langkah-langkah konkret, dan trade-offs yang dapat membantu dalam menghadapi system design interview. Selain itu, buku ini juga dapat digunakan sebagai referensi untuk non-interview, karena design thinking yang diajarkan dapat membantu dalam mengembangkan arsitektur real-world.

## 🎯 Key Takeaways

**1. Framework 4 Langkah**

Framework 4 langkah adalah sebuah metode yang dapat membantu dalam menghadapi system design interview. Berikut adalah langkah-langkahnya:

1. **Understand the problem** — clarifikasi requirements (functional vs non-functional)
2. **High-level design** — diagram kotak + panah, pilih core components
3. **Deep dive** — detail bottlenecks, trade-offs
4. **Wrap up** — what would you add with more time

Contoh implementasi framework 4 langkah dapat dilihat pada contoh berikut:

```markdown
# Contoh Implementasi Framework 4 Langkah

## 1. Understand the problem

- Apa yang ingin dicapai?
- Apa yang dibutuhkan?

## 2. High-level design

- Diagram kotak + panah
- Pilih core components

## 3. Deep dive

- Detail bottlenecks
- Trade-offs

## 4. Wrap up

- What would you add with more time?
```

Misalnya, kita ingin mendesain sistem untuk sebuah aplikasi e-commerce. Pada langkah pertama, kita perlu memahami apa yang ingin dicapai, yaitu menciptakan sistem yang dapat menangani transaksi online dengan aman dan efisien. Pada langkah kedua, kita perlu membuat diagram high-level design yang mencakup komponen-komponen utama seperti load balancer, web server, database, dan payment gateway.

**2. Core Components Set**

Berikut adalah beberapa core components yang sering digunakan dalam system design:

- **Load balancer** (HAProxy, Nginx, ELB — layer 4 vs 7)
- **CDN** (CloudFront, CloudFlare)
- **Database** — SQL vs NoSQL, replication, sharding
- **Cache** (Redis, Memcached — cache aside, write-through, write-back)
- **Message queue** (Kafka, RabbitMQ, SQS)
- **Blob storage** (S3, GCS)

Contoh implementasi core components dapat dilihat pada contoh berikut:

```python
# Contoh Implementasi Core Components

import redis

# Load balancer
load_balancer = "HAProxy"

# CDN
cdn = "CloudFront"

# Database
database = "MySQL"

# Cache
cache = redis.Redis(host="localhost", port=6379, db=0)

# Message queue
message_queue = "Kafka"

# Blob storage
blob_storage = "S3"
```

Misalnya, kita ingin menggunakan load balancer HAProxy untuk mendistribusikan traffic ke beberapa web server. Kita perlu mengkonfigurasi HAProxy untuk melakukan load balancing dan mengarahkan traffic ke web server yang tersedia.

## 📊 Troubleshooting

Troubleshooting adalah proses untuk mengidentifikasi dan memecahkan masalah yang terjadi dalam sistem. Berikut adalah beberapa contoh masalah yang sering terjadi dalam sistem dan cara untuk memecahkannya:

- **Masalah 1: Load balancer tidak berfungsi**

* Gejala: Traffic tidak terdistribusi dengan baik ke web server
* Penyebab: Konfigurasi load balancer yang salah atau tidak lengkap
* Solusi: Periksa konfigurasi load balancer dan pastikan bahwa semua web server telah terdaftar dan dapat diakses

- **Masalah 2: Database tidak dapat diakses**

* Gejala: Aplikasi tidak dapat terhubung ke database
* Penyebab: Konfigurasi database yang salah atau tidak lengkap
* Solusi: Periksa konfigurasi database dan pastikan bahwa semua parameter telah diatur dengan benar

## 📈 Key Design Patterns

Berikut adalah beberapa key design patterns yang sering digunakan dalam system design:

| Problem           | Approach                                   |
| ----------------- | ------------------------------------------ |
| URL shortener     | Base62 encoding + key generation service   |
| Chat system       | WebSocket + message sync + presence        |
| Notification      | Event bus + fan-out + rate limiting        |
| News feed         | Fan-out on write vs on read                |
| Rate limiter      | Token bucket, leaky bucket, sliding window |
| Proximity service | QuadTree / Geohash                         |
| Distributed ID    | Snowflake (timestamp + worker + seq)       |

Contoh implementasi key design patterns dapat dilihat pada contoh berikut:

```java
// Contoh Implementasi Key Design Patterns

// URL shortener
public class URLShortener {
    public String shortenURL(String url) {
        // Base62 encoding + key generation service
        return "http://short.url/" + base62Encode(url);
    }

    private String base62Encode(String url) {
        // Implementasi base62 encoding
    }
}

// Chat system
public class ChatSystem {
    public void sendMessage(String message) {
        // WebSocket + message sync + presence
        // Implementasi WebSocket
    }
}
```

Misalnya, kita ingin mendesain sistem URL shortener yang dapat menghasilkan URL yang pendek dan unik. Kita perlu menggunakan base62 encoding untuk mengencode URL asli dan menghasilkan URL yang pendek.

## 📊 Back-of-the-envelope

Back-of-the-envelope adalah sebuah metode untuk melakukan estimasi cepat dan kasar. Berikut adalah beberapa contoh back-of-the-envelope:

- Daily active users → requests/second
- Storage growth per day/month/year
- Bandwidth estimation
- **Useful constants:**
  - 1 request/sec = ~86K requests/day
  - 1 GB/day = ~12KBps continuous
  - MySQL ~2000 reads/sec per node
  - Redis ~100000 ops/sec per node

Contoh implementasi back-of-the-envelope dapat dilihat pada contoh berikut:

```python
# Contoh Implementasi Back-of-the-envelope

# Daily active users → requests/second
daily_active_users = 100000
requests_per_second = daily_active_users / 86400

# Storage growth per day/month/year
storage_growth_per_day = 100MB
storage_growth_per_month = storage_growth_per_day * 30
storage_growth_per_year = storage_growth_per_day * 365

# Bandwidth estimation
bandwidth_estimation = 100KBps
```

Misalnya, kita ingin mengestimasi jumlah requests per second untuk aplikasi e-commerce. Kita perlu menggunakan rumus `requests_per_second = daily_active_users / 86400` untuk menghasilkan estimasi yang kasar.

## 📖 Bab Penting

Berikut adalah beberapa bab penting dalam buku ini:

| Bab | Soal                       | Pelajaran                   |
| --- | -------------------------- | --------------------------- |
| 1   | URL Shortener              | Base62, key gen, 301 vs 302 |
| 2   | Web Crawler                | BFS, politeness, dedup      |
| 5   | Design Consistent Hashing  | **Wajib** — fundamental     |
| 7   | Design Unique ID Generator | Snowflake                   |
| 10  | Design Notification System | Fan-out, event bus          |
| 12  | Design Chat System         | WebSocket, presence, sync   |
| 13  | Design Search Autocomplete | Trie                        |

Contoh implementasi bab penting dapat dilihat pada contoh berikut:

```java
// Contoh Implementasi Bab Penting

// Bab 1: URL Shortener
public class URLShortener {
    public String shortenURL(String url) {
        // Base62 encoding + key generation service
        return "http://short.url/" + base62Encode(url);
    }
}

// Bab 2: Web Crawler
public class WebCrawler {
    public void crawl(String url) {
        // BFS, politeness, dedup
        // Implementasi BFS
    }
}
```

Misalnya, kita ingin mendesain sistem URL shortener yang dapat menghasilkan URL yang pendek dan unik. Kita perlu menggunakan base62 encoding untuk mengencode URL asli dan menghasilkan URL yang pendek.

## ⚠️ Keterbatasan

Buku ini memiliki beberapa keterbatasan, yaitu:

- **Interview-focused** — depth kurang untuk real production
- Beberapa solusi oversimplified (cuma 2 server + 1 database)
- **Pair with DDIA** untuk depth — DDIA theory, Alex Xu framework
- Edisi 2 (2022) nambah design Twitter, YouTube, Google Drive

## 🚦 Cara Baca

Berikut adalah cara baca buku ini:

1. Baca **chapter 1-5** buat framework + komponen dasar
2. Lompat ke soal yang relevant (interview target)
3. Coba _design yourself_ sebelum baca solusi — baru bandingkan

## 🔗 Koneksi

Berikut adalah beberapa koneksi yang dapat membantu dalam memahami buku ini:

- [[ddia-kleppmann]] — depth theory distributed systems
- [[sre-google]] — production reliability
- [[clrs-introduction-to-algorithms]] — consistent hashing, trie

## ✅ Checklist

Berikut adalah beberapa checklist yang dapat membantu dalam memahami buku ini:

- [ ] Hafal framework 4 langkah + tahu cara pake
- [ ] Latih 3 soal: URL shortener, chat, news feed
- [ ] Back-of-the-envelope: estimasi storage + bandwidth
- [ ] Diagram tools: Figma / Excalidraw / draw.io

Dengan memahami buku ini, Anda dapat meningkatkan kemampuan Anda dalam menghadapi system design interview dan memahami konsep-konsep penting dalam system design. Selamat membaca!
