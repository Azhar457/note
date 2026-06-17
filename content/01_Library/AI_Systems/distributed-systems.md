---
tags:
  - distributed-systems
  - system-design
  - cloud-native
  - scalability
  - consistency
aliases:
  - Distributed Systems
  - Sistem Terdistribusi
  - Distributed Computing
created: 2026-06-11
status: draft
cssclasses:
  - wide-table
---

# 🌐 DISTRIBUTED SYSTEMS — Koordinasi Skala Besar

> Distributed Systems adalah kumpulan komputer independen yang berkomunikasi lewat jaringan untuk terlihat seperti satu sistem terpadu.  
> Inti masalahnya bukan cuma “jalan”, tapi bagaimana sistem tetap konsisten, scalable, dan tahan gagal saat komponen tersebar di banyak mesin.

---

## Peta Besar

```text
                         DISTRIBUTED SYSTEMS
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
   MODEL DASAR              SIFAT UTAMA               PROBLEM INTI
   ───────────              ───────────              ────────────
   · Node                  · Scalability            · Partial failure
   · Message passing       · Availability           · Network partition
   · RPC / gRPC            · Consistency            · Clock skew
   · Shared-nothing        · Fault tolerance        · Coordination
        │                         │                         │
        └─────────────────────────┼─────────────────────────┘
                                  │
                         MEKANISME NYATA
                         ───────────────
                         · Replication
                         · Sharding
                         · Consensus
                         · Leader election
                         · Load balancing
                         · Caching
                         · Observability
```

---

## Definisi Inti

Distributed systems adalah sistem yang terdiri dari banyak mesin atau node yang bekerja sama lewat jaringan dan bertindak seolah-olah satu kesatuan.  
Yang membuatnya menarik adalah kenyataan bahwa failure itu normal, bukan anomali.  
Karena itu, desainnya harus siap menghadapi latensi, packet loss, node mati, dan state yang tidak selalu sinkron.

---

## Kenapa Sulit

### Partial Failure

Di sistem terdistribusi, satu bagian bisa gagal sementara bagian lain masih hidup.  
Ini beda dari single machine, karena kamu tidak bisa menganggap semua komponen akan crash atau recover secara bersamaan.  
Akibatnya, debug, recovery, dan reasoning jadi jauh lebih sulit.

### Network Partition

Jaringan bisa terputus atau melambat tanpa warning.  
Saat itu sistem harus memilih: tetap melayani request, atau menahan operasi demi menjaga konsistensi.  
Inilah alasan distributed systems selalu penuh trade-off, bukan jawaban absolut.

### Time Is Hard

Waktu antar mesin tidak benar-benar seragam.  
Clock drift kecil saja bisa bikin urutan event jadi ambigu.  
Makanya distributed systems sering lebih percaya pada message order dan log daripada waktu lokal.

---

## Tiga Pilar

### Scalability
Sistem harus bisa tumbuh dari puluhan ke ribuan node tanpa desain ulang total.  
Skalabilitas bukan cuma soal menambah server, tapi juga soal membagi kerja secara efisien.

### Fault Tolerance
Kalau satu node mati, sistem tetap harus berfungsi.  
Biasanya dicapai lewat replication, failover, retry, dan quorum.

### Consistency
Semua node perlu punya aturan yang jelas tentang kapan data dianggap valid dan kapan belum.  
Di sinilah muncul model konsistensi yang berbeda-beda, dari strong consistency sampai eventual consistency.

---

## CAP Dan Trade-off

| Aspek | Arti | Implikasi |
|---|---|---|
| Consistency | Semua client melihat state yang sama | Update bisa lebih lambat |
| Availability | Sistem tetap merespons request | Data bisa belum paling baru |
| Partition tolerance | Sistem tetap jalan saat jaringan terpisah | Trade-off harus dipilih saat partition terjadi |

CAP theorem menyatakan bahwa sistem terdistribusi tidak bisa memaksimalkan consistency, availability, dan partition tolerance sekaligus dalam kondisi partition.  
Karena partition itu pasti bisa terjadi, keputusan arsitektur biasanya berputar di sekitar consistency vs availability.

---

## Mekanisme Penting

### Replication
Data disalin ke beberapa node agar tahan gagal dan lebih cepat diakses.  
Replication membantu availability, tapi juga menambah kompleksitas sinkronisasi.

### Sharding
Data dibagi ke beberapa node supaya beban tidak menumpuk di satu mesin.  
Ini penting untuk scaling, tapi query lintas shard jadi lebih rumit.

### Consensus
Node-node harus sepakat tentang satu nilai atau urutan tindakan.  
Consensus muncul di replicated state machine dan sistem yang butuh keputusan tunggal yang benar.

### Leader Election
Satu node dipilih sebagai pemimpin untuk mengatur log atau koordinasi.  
Kalau leader mati, sistem harus cepat memilih pengganti.

---

## Protocol Yang Perlu Tahu

- **Raft**: dirancang supaya mudah dipahami dan dipakai di sistem nyata.
- **Paxos**: klasik, kuat, tapi terkenal sulit dipahami.
- **PBFT**: dipakai saat ada kemungkinan node berperilaku jahat atau tidak dapat dipercaya.

### Perbandingan Singkat

| Protocol | Fokus | Kelebihan | Kekurangan |
|---|---|---|---|
| Raft | Consensus praktis | Lebih mudah dipahami | Tetap kompleks saat diimplementasikan |
| Paxos | Consensus teoritis | Sangat kuat secara teori | Sulit dipelajari |
| PBFT | Byzantine tolerance | Tahan node berbahaya | Lebih berat dan kompleks |

---

## Building Blocks

- RPC dan gRPC.
- Service discovery.
- Load balancing.
- Retry dan backoff.
- Idempotency.
- Message queue.
- Event streaming.
- Distributed locks.
- Quorum read/write.
- Observability.

---

## Hubungan Ke Topik Lain

### Database Internals
Distributed systems menjadi fondasi replication, partitioning, dan query distribution.  
Banyak database modern sebenarnya adalah distributed system dengan storage semantics yang lebih ketat.

### Cloud Infrastructure
Kubernetes, service mesh, dan control plane modern sangat bergantung pada koordinasi terdistribusi.  
Tanpa konsep distributed systems, cloud tidak akan stabil di skala besar.

### Observability
Tracing, logs, dan metrics dipakai untuk memahami perilaku sistem yang tersebar di banyak node.  
Semakin terdistribusi sistem, semakin penting observability.

---

## Real World Shape

Contoh sistem yang sangat dekat dengan distributed systems:
- Kubernetes.
- Kafka.
- etcd.
- Cassandra.
- CockroachDB.
- Spanner-style architecture.
- Microservices platform.

---

## Roadmap Belajar

1. Pahami node, network, dan message passing.
2. Pelajari failure model.
3. Kenali replication dan sharding.
4. Dalami consistency model.
5. Masuk ke consensus.
6. Pelajari leader election dan quorum.
7. Hubungkan ke database dan cloud.
8. Baca observability dan debugging di sistem nyata.

---

## Kenapa Penting

Distributed systems itu bukan sekadar subjek system design.  
Ini adalah cara berpikir tentang bagaimana banyak komponen yang rapuh bisa tetap bekerja sebagai satu kesatuan.  
Kalau kamu paham ini, banyak topik lain jadi terasa nyambung, dari database sampai AI infra.

---

*Distributed Systems | Scalability · Consistency · Fault Tolerance · Consensus · Cloud Native*