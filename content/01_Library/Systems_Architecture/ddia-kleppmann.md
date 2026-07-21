---
title: Designing Data-Intensive Applications (DDIA)
tags:
- library
- systems-architecture
created: '2026-07-05'
updated: '2026-07-05'
status: active
---
# 🌐 Designing Data-Intensive Applications
> Martin Kleppmann — 2017

**Tesis:** Buku paling penting soal **sistem backend modern**. Data is at the center — storage, replication, partitioning, transactions, consistency, batch/stream processing. Bukan hype-driven — *fundamental trade-offs* yang tetep relevan kapanpun.

## 📌 Kenapa Penting

- Jawab kenapa database no-SQL muncul, kenapa CAP theorem gak sederhana
- **Trade-offs** > silver bullets — Kleppmann nunjukkin konsekuensi tiap pilihan arsitektur
- Referensi #1 untuk system design interview

Contoh konsekuensi dari pilihan arsitektur adalah ketika memilih antara *single-leader* dan *multi-leader* replication. *Single-leader* replication memiliki kelebihan dalam hal konsistensi data, tetapi memiliki kekurangan dalam hal failover yang tricky. Sementara itu, *multi-leader* replication memiliki kelebihan dalam hal availability, tetapi memiliki kekurangan dalam hal conflict resolution yang pain.

## 🎯 Key Takeaways

**1. Storage Engines**
- **LSM-Trees** (LevelDB, Cassandra, RocksDB) vs **B-Trees** (MySQL, Postgres)
  - LSM: write-optimized, compaction overhead
  - B-Tree: read-optimized, stable performance
- **Row-oriented vs Column-oriented** — analytics vs OLTP

Contoh implementasi LSM-Tree adalah Cassandra, yang menggunakan LSM-Tree untuk menyimpan data. Sementara itu, contoh implementasi B-Tree adalah MySQL, yang menggunakan B-Tree untuk menyimpan data.

**2. Replication**
- **Single-leader** — standard, but failover tricky
- **Multi-leader** — conflict resolution pain (CRDTs help)
- **Leaderless** (Dynamo-style) — quorum reads/writes, but stale reads
- **Synchronous vs Asynchronous** — durability vs latency trade-off

Contoh implementasi single-leader replication adalah MySQL, yang menggunakan single-leader replication untuk menyimpan data. Sementara itu, contoh implementasi multi-leader replication adalah Cassandra, yang menggunakan multi-leader replication untuk menyimpan data.

**3. Partitioning (Sharding)**
- By key range — hotspot risk
- By hash of key — even distribution, but range queries suffer
- Rebalancing — jangan pake hash mod N (pakai consistent hashing)

Contoh implementasi partitioning adalah Cassandra, yang menggunakan partitioning untuk menyimpan data. Cassandra menggunakan consistent hashing untuk melakukan rebalancing data.

**4. Transactions — the Truth**
- ACID is a spectrum, not a binary switch
- **Isolation levels:**
  - Read Committed (default Postgres/Oracle)
  - Snapshot Isolation / Repeatable Read
  - Serializable — hardest, slowest, but correct
- **Race conditions:** dirty reads, dirty writes, read skew, lost updates, write skew, phantom reads

Contoh implementasi isolation level adalah Postgres, yang menggunakan Read Committed sebagai default isolation level. Sementara itu, contoh implementasi Serializable adalah MySQL, yang menggunakan Serializable sebagai isolation level untuk melakukan transaksi.

**5. Distributed Transactions**
- Two-Phase Commit (2PC) — coordinator = single point of failure, blocking
- **Linearizability vs Eventual Consistency** — trade-off real di distributed systems
- CAP: Choose 2 of 3 — tapi realitanya lebih nuanced (partition tolerance gak optional)

Contoh implementasi distributed transaction adalah Google's Spanner, yang menggunakan Two-Phase Commit (2PC) untuk melakukan transaksi.

**6. Batch Processing (MapReduce)**
- MapReduce + Spark: "Bring computation to data, not data to computation"
- **Join strategies:** sort-merge, broadcast hash, partitioned hash

Contoh implementasi batch processing adalah Hadoop, yang menggunakan MapReduce untuk melakukan batch processing.

**7. Stream Processing**
- Kafka, Flink, Samza — unbounded data, processing with state
- **Exactly-once semantics** — achievable but complex
- Stream-table joins — materialized views real-time

Contoh implementasi stream processing adalah Kafka, yang menggunakan stream processing untuk melakukan real-time processing.

**8. Consistency Models**
- **Strong consistency** → correct, slow
- **Eventual consistency** → fast, but stale reads possible
- **Causal consistency** → sweet spot (what CRDTs give)
- **Linearizability** → gold standard, expensive

Contoh implementasi consistency model adalah Cassandra, yang menggunakan eventual consistency sebagai default consistency model.

## 📖 Bab Penting

| Bab | Judul | Mengapa |
|-----|-------|---------|
| 2 | Data Models and Query Languages | Relational vs Document vs Graph — kapan pilih apa |
| 5 | Replication | **Wajib** — paling sering ditanya interview |
| 6 | Partitioning | Kapan, gimana, rebalancing |
| 7 | Transactions | Isolation levels + race conditions |
| 8 | The Trouble with Distributed Systems | Clock, crashes, network — *things always go wrong* |
| 10 | Batch Processing | MapReduce + Spark fundamentals |
| 11 | Stream Processing | Kafka, Flink, exactly-once |

## ⚠️ Tantangan

- Tebal 600+ hal — dense, but clearer dari textbook akademik
- Butuh dasar distributed systems (kalo fresh, baca OSTEP Part OS dulu)
- Contoh-contoh konkret (Cassandra, MongoDB, Kafka, Postgres, etc.) — tapi gak perlu hafal implementasi detail

## 🔗 Koneksi

- [[ostep-three-easy-pieces]] — concurrency + OS fundamentals untuk distributed systems
- [[systems-design-interview-alex-xu]] — ringkasan praktis, DDIA adalah *deep theory*-nya
- [[site-reability-engineering]] — SRE = run system di buku DDIA di production

## ✅ Checklist

- [ ] Paham B-Tree vs LSM-Tree bedanya apa
- [ ] Bisa jelasin kapan pilih single-leader vs leaderless replication
- [ ] Isolation levels: definisiin + kasus race condition tiap level
- [ ] Konsistensi model: eventual → causal → linearizable
- [ ] Gampang2nya system design interview pakai konsep dari buku ini

### Implementasi Contoh

Berikut adalah contoh implementasi dari beberapa konsep yang dibahas di atas:

#### Contoh Implementasi LSM-Tree

```python
import os
import struct

class LSMTree:
    def __init__(self, db_path):
        self.db_path = db_path
        self.log_file = os.path.join(db_path, 'log.dat')
        self.tree_file = os.path.join(db_path, 'tree.dat')

    def write(self, key, value):
        with open(self.log_file, 'ab') as f:
            f.write(struct.pack('!I', len(key)) + key + struct.pack('!I', len(value)) + value)

    def read(self, key):
        with open(self.log_file, 'rb') as f:
            while True:
                key_len = struct.unpack('!I', f.read(4))[0]
                k = f.read(key_len)
                value_len = struct.unpack('!I', f.read(4))[0]
                value = f.read(value_len)
                if k == key:
                    return value
                if not f.read():
                    break
        return None

# Example usage:
db = LSMTree('/tmp/db')
db.write(b'key1', b'value1')
print(db.read(b'key1'))  # prints b'value1'
```

#### Contoh Implementasi B-Tree

```python
import os
import struct

class BTree:
    def __init__(self, db_path):
        self.db_path = db_path
        self.tree_file = os.path.join(db_path, 'tree.dat')

    def insert(self, key, value):
        with open(self.tree_file, 'ab') as f:
            f.write(struct.pack('!I', len(key)) + key + struct.pack('!I', len(value)) + value)

    def search(self, key):
        with open(self.tree_file, 'rb') as f:
            while True:
                key_len = struct.unpack('!I', f.read(4))[0]
                k = f.read(key_len)
                value_len = struct.unpack('!I', f.read(4))[0]
                value = f.read(value_len)
                if k == key:
                    return value
                if not f.read():
                    break
        return None

# Example usage:
db = BTree('/tmp/db')
db.insert(b'key1', b'value1')
print(db.search(b'key1'))  # prints b'value1'
```

### Troubleshooting

Berikut adalah beberapa tips untuk melakukan troubleshooting pada sistem yang menggunakan konsep-konsep di atas:

*   Pastikan bahwa sistem memiliki cukup ruang penyimpanan dan sumber daya untuk menangani beban kerja.
*   Periksa log sistem untuk mengetahui apakah ada error atau peringatan yang dapat membantu dalam melakukan troubleshooting.
*   Gunakan tool-tool seperti `top` atau `htop` untuk memantau penggunaan sumber daya sistem dan mendeteksi jika ada proses yang menggunakan sumber daya secara berlebihan.
*   Periksa konfigurasi sistem untuk memastikan bahwa semua parameter telah dikonfigurasi dengan benar.
*   Lakukan testing pada sistem untuk memastikan bahwa sistem berfungsi dengan benar dan dapat menangani beban kerja yang diharapkan.

Dengan mengikuti tips di atas, Anda dapat melakukan troubleshooting pada sistem yang menggunakan konsep-konsep di atas dan memastikan bahwa sistem berfungsi dengan baik dan efisien.