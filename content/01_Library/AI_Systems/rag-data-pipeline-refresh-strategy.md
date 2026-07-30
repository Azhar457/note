---
title: RAG Data Pipeline & Refresh Strategy
tags:
  - rag
  - data-pipeline
  - etl
  - refresh
  - incremental-indexing
  - dedup
created: "2026-07-16"
updated: "2026-07-16"
status: pending
---

## Daftar Isi

1. [Problem: RAG Static Knowledge Base](#1-problem-rag-static-knowledge-base)
2. [Arsitektur Data Pipeline](#2-arsitektur-data-pipeline)
3. [Incremental Indexing](#3-incremental-indexing)
4. [Deduplication](#4-deduplication)
5. [Staleness Detection](#5-staleness-detection)
6. [Re-chunking Strategy](#6-re-chunking-strategy)
7. [Change Data Capture (CDC)](#7-change-data-capture-cdc)
8. [Scheduling & Orchestration](#8-scheduling--orchestration)
9. [Monitoring & Alerting](#9-monitoring--alerting)

---

## 1. Problem: RAG Static Knowledge Base

Sebagian besar implementasi RAG punya pola yang sama:

```
Day 1:  Parse 1000 docs → chunk → embed → index   ✅
Day 2-30:  ... no updates ...                      ❌
Day 31: Ada 50 dokumen baru.          → full re-index ❌ (waste)
         Ada 20 dokumen lama diedit.  → gak terdeteksi ❌ (stale)
         Ada 10 dokumen dihapus.      → tetap di index ❌ (ghost)
```

**Masalah:**

- **Staleness:** Knowledge base makin lama makin outdated
- **Cost waste:** Full re-index setiap kali ada perubahan = compute mahal
- **Ghost docs:** Dokumen udah dihapus tapi embeddings masih di vector store
- **Drift:** Semantic content berubah → embedding lama gak relevan
- **Versioning:** User tanya "info terbaru" tapi dapet yang lama

**Solusi:** Data pipeline dengan incremental update, CDC, dan refresh scheduling.

---

## 2. Arsitektur Data Pipeline

```
┌──────────────────────┐
│   Source Systems      │
│ ┌────┐ ┌────┐ ┌────┐ │
│ │S3  │ │DB  │ │API │ │
│ └──┬─┘ └──┬─┘ └──┬─┘ │
└───┼──────┼───────┼───┘
    │      │       │
┌───▼──────▼───────▼───────┐
│    Change Detection       │ ← poll / webhook / CDC
│   ┌───────────────────┐   │
│   │  File Watcher      │   │ ← inotify / S3 events
│   │  DB Poller         │   │ ← periodic query
│   │  Webhook Receiver  │   │ ← real-time push
│   └────────┬──────────┘   │
└────────────┼──────────────┘
             │
┌────────────▼──────────────┐
│    Ingestion Pipeline      │
│                            │
│  ┌────────┐  ┌────────┐   │
│  │ Parse  │→│ Chunk  │   │
│  └────────┘  └───┬────┘   │
│                  │        │
│           ┌──────▼──────┐ │
│           │  Embed      │ │
│           └──────┬──────┘ │
│                  │        │
│           ┌──────▼──────┐ │
│           │  Index      │ │
│           └──────┬──────┘ │
└──────────────────┼────────┘
                   │
┌──────────────────▼────────┐
│     Vector Store          │
│  (Qdrant / Milvus / PG)   │
│                            │
│  ┌────┐ ┌────┐ ┌────┐    │
│  │New │ │Upd │ │Del │    │
│  │Doc │ │Doc │ │Doc │    │
│  └────┘ └────┘ └────┘    │
└───────────────────────────┘
```

### Komponen Data Pipeline

| Komponen              | Fungsi                      | Tools                                 |
| --------------------- | --------------------------- | ------------------------------------- |
| **Source connector**  | Ambil perubahan dari source | Fivetran, Airbyte, Debezium           |
| **Change detector**   | Deteksi file baru/modified  | inotify, S3 EventBridge, git diff     |
| **Parser**            | Extract text dari raw file  | PyMuPDF, Trafilatura, Unstructured.io |
| **Chunker**           | Split text jadi chunks      | LangChain text splitters, custom      |
| **Embedder**          | Generate embeddings         | BGE, text-embedding-3, Jina           |
| **Indexer**           | Insert ke vector store      | Qdrant client, Milvus SDK             |
| **Garbage collector** | Remove deleted docs         | Periodic cleanup job                  |

---

## 3. Incremental Indexing

**Ide:** Jangan re-index semua. Cuma index dokumen yang berubah.

### 3.1 Strategy: Content-Addressable Indexing

```python
class IncrementalIndexer:
    """
    Index cuma dokumen yang hash-nya berubah.
    Simpan hash tiap dokumen di metadata.
    """

    def __init__(self, store: VectorStore, embedding_model: EmbeddingModel):
        self.store = store
        self.embedder = embedding_model

    def _content_hash(self, content: str) -> str:
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def sync_document(self, doc: Document) -> IndexResult:
        # Cek hash doc yang tersimpan
        existing = self.store.get_doc(doc.id)
        new_hash = self._content_hash(doc.content)

        if existing and existing.metadata.get("content_hash") == new_hash:
            return IndexResult.skipped("content unchanged")

        # Hapus chunks lama kalo ada
        if existing:
            self.store.delete_doc(doc.id)

        # Proses baru
        chunks = Chunker().chunk(doc)
        embeddings = self.embedder.embed([c.content for c in chunks])

        # Simpan dengan metadata hash
        self.store.upsert_chunks([
            VectorRecord(
                id=f"{doc.id}_chunk_{i}",
                vector=embeddings[i],
                payload={
                    "doc_id": doc.id,
                    "content": c.content,
                    "content_hash": new_hash,
                    "updated_at": now(),
                    "chunk_index": i
                }
            )
            for i, c in enumerate(chunks)
        ])

        return IndexResult.updated(len(chunks), new_hash)
```

### 3.2 Batch Incremental

```python
class BatchIncrementalSync:
    """Sync seluruh folder/file secara incremental."""

    def sync_all(self, base_path: str) -> SyncReport:
        report = SyncReport()

        for file_path in self.walk_files(base_path):
            doc_id = self.path_to_doc_id(file_path)
            content = read_file(file_path)

            result = self.indexer.sync_document(Document(
                id=doc_id,
                content=content,
                metadata={"source_path": file_path, "file_mtime": os.path.getmtime(file_path)}
            ))

            report.add(result)

        # Handle deleted files
        self.cleanup_deleted_docs(base_path)

        return report
```

### 3.3 Tradeoff Tiap Strategy

| Strategy            | Kelebihan                | Kekurangan                 | Cocok Untuk        |
| ------------------- | ------------------------ | -------------------------- | ------------------ |
| **Full re-index**   | Simple, guaranteed fresh | Mahal, slow                | <1K docs weekly    |
| **Hash-based**      | Akurat, efficient        | Butuh store hash           | General purpose    |
| **Timestamp-based** | Simple                   | Gak detect rollback/rename | File-based sources |
| **CDC + log**       | Real-time, no polling    | Complex setup              | Database source    |

---

## 4. Deduplication

**Problem:** Dokumen/chunk yang sama bisa masuk berkali-kali lewat berbagai source (contoh: markdown di GitHub + Obsidian + web). Hasilnya: retrieval flood dengan duplikasi.

### 4.1 Content-level Dedup

```python
class Deduplicator:
    def __init__(self, threshold: float = 0.92):
        self.threshold = threshold  # cosine similarity threshold

    def find_duplicates(self, candidate: str, existing_chunks: list[str]) -> list[str]:
        """Cari chunk existing yang terlalu mirip dengan candidate."""
        candidate_emb = self.embedder.embed([candidate])[0]
        existing_embs = self.embedder.embed(existing_chunks)

        similarities = cosine_similarity([candidate_emb], existing_embs)[0]
        duplicates = [
            existing_chunks[i]
            for i, sim in enumerate(similarities)
            if sim > self.threshold
        ]
        return duplicates

    def should_skip(self, chunk: str, existing: list[str]) -> bool:
        """Skip kalau duplikat ditemukan."""
        dups = self.find_duplicates(chunk, existing)
        if dups:
            logger.info(f"Duplicate found (sim={max_sim:.3f}), skipping")
            return True
        return False
```

### 4.2 MinHash LSH — Massive Scale Dedup

Untuk >1M chunks, cosine similarity O(N²) gak feasible. Pake **MinHash LSH**:

```python
from datasketch import MinHash, MinHashLSH

class MinHashDedup:
    def __init__(self, threshold=0.85, num_perm=128):
        self.lsh = MinHashLSH(threshold=threshold, num_perm=num_perm)
        self.seen = set()

    def is_duplicate(self, text: str, doc_id: str) -> bool:
        m = MinHash(num_perm=128)
        for token in set(text.lower().split()):
            m.update(token.encode())

        # Cari candidate duplikat
        candidates = self.lsh.query(m)

        if doc_id in self.seen:
            return True

        # Exact verification for candidates
        for cand_id in candidates:
            if self.jaccard_similarity(text, self.doc_texts[cand_id]) > 0.85:
                return True

        self.lsh.insert(doc_id, m)
        self.seen.add(doc_id)
        self.doc_texts[doc_id] = text
        return False
```

### 4.3 Fingerprint-based (Near-exact)

```python
def generate_fingerprint(text: str) -> str:
    """Simhash — near-duplicate detection."""
    # Normalize dulu: lowercase, strip whitespace, sort sentences
    normalized = normalize_text(text)
    return simhash(normalized)

# Store fingerprint di metadata:
payload = {
    "content": chunk,
    "simhash": generate_fingerprint(chunk),
}

# Cek pas retrieval — skip chunks dengan simhash yang sama
```

**Pendekatan layer:**

| Layer                  | Metode              | Scale     | False Positive |
| ---------------------- | ------------------- | --------- | -------------- |
| **Level 1 (fast)**     | Simhash / MinHash   | Miliar    | Medium         |
| **Level 2 (accurate)** | Cosine similarity   | Jutaan    | Rendah         |
| **Level 3 (exact)**    | Hash256 exact match | Unlimited | Zero           |

---

## 5. Staleness Detection

Dokumen gak berubah format, tapi isinya obsolete. Contoh: "presiden Indonesia 2019 adalah Jokowi" → setelah 2024, info ini obsolete.

### 5.1 Time-based Expiry

```python
@dataclass
class DocExpiryPolicy:
    """Kebijakan kedaluwarsa berdasarkan tipe dokumen."""
    doc_type_expiry = {
        "news": timedelta(days=1),
        "blog": timedelta(days=30),
        "tutorial": timedelta(days=180),
        "reference": timedelta(days=365),
        "book_note": timedelta(days=730),  # 2 tahun
    }

    def is_stale(self, doc_metadata: dict) -> bool:
        doc_type = doc_metadata.get("doc_type", "reference")
        max_age = self.doc_type_expiry.get(doc_type, timedelta(days=365))

        updated_at = doc_metadata.get("updated_at") or doc_metadata.get("created_at")
        if not updated_at:
            return False

        return now() - updated_at > max_age

    def get_expired_docs(self, store: VectorStore) -> list[str]:
        expired_ids = []
        for doc in store.scan():
            if self.is_stale(doc.metadata):
                expired_ids.append(doc.id)
        return expired_ids
```

### 5.2 Semantic Drift Detection

Deteksi konten yang secara semantik udah gak relevan:

```python
class DriftDetector:
    """Deteksi embedding drift — kalau embedding dokumen berubah signifikan."""

    def detect_drift(self, doc_id: str, current_embedding: list[float]) -> bool:
        stored = self.store.get_doc(doc_id)
        if not stored:
            return False

        old_emb = stored.vector
        similarity = cosine_similarity([current_embedding], [old_emb])[0][0]

        # Threshold rendah = high sensitivity
        return similarity < 0.85  # embedding berubah >15%
```

### 5.3 Active Re-fresh

```python
class RefreshScheduler:
    """Jadwalkan re-index periodic berdasarkan prioritas."""

    def __init__(self):
        self.priority_queue = PriorityQueue()

    def schedule_refresh(self, doc_id: str, priority: int):
        """priority 1 = urgent, 10 = low."""
        self.priority_queue.put((priority, doc_id, now()))

    async def run_refresh_cycle(self):
        while True:
            priority, doc_id, scheduled_at = self.priority_queue.get()

            # Re-process dokumen
            doc = self.source.get_doc(doc_id)
            new_embed = self.embedder.embed([doc.content])[0]

            # Check drift
            if self.drift_detector.detect_drift(doc_id, new_embed):
                # True drift — re-index
                self.indexer.sync_document(doc)
                logger.info(f"Re-indexed {doc_id} due to drift detection")
            else:
                # No drift — just update timestamp
                self.store.update_metadata(doc_id, {"verified_at": now()})

            await asyncio.sleep(1)  # rate limit
```

---

## 6. Re-chunking Strategy

**Problem:** Chunking strategy yang dipilih di awal mungkin gak optimal setelah lihat real usage pattern.

### 6.1 Kapan Butuh Re-chunking

| Sinyal                                | Indikasi                                                          |
| ------------------------------------- | ----------------------------------------------------------------- |
| **Avg retrieval score rendah**        | Chunk terlalu besar → noise, atau terlalu kecil → missing context |
| **Banyak chunk irrelevant di top-5**  | Boundary strategy salah — potong di tengah kalimat penting        |
| **Context assembly sering truncated** | Chunk terlalu besar → gak muat di context window                  |
| **Low faithfulness di RAGAS**         | Chunk gak mengandung evidence yang cukup untuk jawaban            |

### 6.2 Re-chunking Pipeline

```python
class RechunkingPipeline:
    """
    Re-chunk dokumen dengan parameter baru,
    simpan mapping antara chunk lama dan baru.
    """

    def rechunk(self, doc_id: str, new_config: ChunkConfig) -> RechunkResult:
        # 1. Dapatkan raw dokumen
        raw_doc = self.source.get_raw_doc(doc_id)

        # 2. Chunk dengan konfigurasi baru
        new_chunks = Chunker(new_config).chunk(raw_doc)

        # 3. Hapus chunks lama dari vector store
        old_chunks = self.store.get_doc_chunks(doc_id)
        self.store.delete_chunks([c.id for c in old_chunks])

        # 4. Embed & index chunks baru
        new_embeddings = self.embedder.embed([c.content for c in new_chunks])
        self.store.upsert_chunks([
            VectorRecord(id=f"{doc_id}_v2_{i}", vector=emb, payload=c.metadata)
            for i, (c, emb) in enumerate(zip(new_chunks, new_embeddings))
        ])

        # 5. Simpan version history (buat rollback kalo perlu)
        self.version_history.save_version(doc_id, new_config, timestamp=now())

        return RechunkResult(
            doc_id=doc_id,
            old_chunks=len(old_chunks),
            new_chunks=len(new_chunks),
            config=new_config
        )
```

### 6.3 Adaptive Chunking

Chunk size yang optimal bisa berbeda per dokumen:

```python
class AdaptiveChunker:
    def optimal_chunk_size(self, doc: Document) -> int:
        """Tentukan chunk size berdasarkan karakteristik dokumen."""
        content = doc.content

        if self.is_code(content):
            return 100  # kode pendek-pendek
        elif self.is_academic(content):
            return 512  # paper akademik butuh konteks
        elif self.is_chat(content):
            return 256  # percakapan per exchange
        else:
            return 384  # default

    def chunk(self, doc: Document) -> list[Chunk]:
        size = self.optimal_chunk_size(doc)
        return RecursiveCharacterTextSplitter(
            chunk_size=size,
            chunk_overlap=size // 5,
            separators=["\n## ", "\n### ", "\n\n", "\n", ". ", " "]
        ).split_text(doc.content)
```

---

## 7. Change Data Capture (CDC)

Untuk source database (PostgreSQL, MySQL, dll), CDC lebih efisien daripada polling.

### 7.1 PostgreSQL CDC via Logical Replication

```python
import psycopg2
from psycopg2.extras import LogicalReplicationConnection

class PGCDC:
    """Capture changes from PostgreSQL WAL via logical replication slot."""

    def __init__(self, dsn: str, slot_name: str = "rag_indexer"):
        self.conn = psycopg2.connect(dsn, connection_factory=LogicalReplicationConnection)
        self.slot_name = slot_name

    def start_consuming(self):
        # Baca perubahan dari WAL
        cur = self.conn.cursor()
        cur.start_replication(
            slot_name=self.slot_name,
            decode=True,
        )

        def on_change(data):
            if data.payload:
                change = json.loads(data.payload)
                match change["action"]:
                    case "INSERT" | "UPDATE":
                        doc = self.row_to_document(change["new"])
                        self.indexer.sync_document(doc)
                    case "DELETE":
                        self.store.delete_doc(change["old"]["id"])

            data.cursor.send_feedback(flush_lsn=data.data_start)

        cur.consume_stream(on_change)
```

### 7.2 File System CDC (inotify)

```python
import inotify.adapters

class FileSystemCDC:
    """Monitor perubahan file di folder vault."""

    def watch(self, path: str):
        i = inotify.adapters.Inotify()
        i.add_watch(path)

        for event in i.event_gen(yield_nones=False):
            (_, type_names, path, filename) = event

            if "IN_CLOSE_WRITE" in type_names or "IN_MOVED_TO" in type_names:
                full_path = os.path.join(path, filename)
                doc = self.parse_file(full_path)
                self.indexer.sync_document(doc)

            elif "IN_DELETE" in type_names or "IN_MOVED_FROM" in type_names:
                doc_id = self.path_to_doc_id(os.path.join(path, filename))
                self.store.delete_doc(doc_id)
```

### 7.3 Git-based CDC (untuk vault Obsidian)

```python
class GitCDC:
    """Deteksi perubahan dari git diff."""

    def get_changed_files(self, since_commit: str = "HEAD~1") -> list[GitChange]:
        result = subprocess.run(
            ["git", "diff", "--name-status", since_commit],
            capture_output=True, text=True
        )

        changes = []
        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            status, path = line.split("\t", 1)
            changes.append(GitChange(status=status, path=path))

        return changes

    def process_git_changes(self, repo_path: str):
        changes = self.get_changed_files()

        for change in changes:
            match change.status:
                case "A" | "M":  # Added or Modified
                    doc = self.parse_file(os.path.join(repo_path, change.path))
                    self.indexer.sync_document(doc)
                case "D":  # Deleted
                    doc_id = self.path_to_doc_id(change.path)
                    self.store.delete_doc(doc_id)
```

---

## 8. Scheduling & Orchestration

### 8.1 Job Queue Airflow-style

```python
# DAG sederhana untuk refresh pipeline
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'rag',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'rag_refresh_pipeline',
    schedule_interval='0 */4 * * *',  # every 4 hours
    catchup=False,
    default_args=default_args,
) as dag:

    def detect_changes():
        return git_cdc.get_changed_files()

    def index_changes(**context):
        changes = context['ti'].xcom_pull(task_ids='detect_changes')
        for change in changes:
            incremental_indexer.process_change(change)

    def refresh_expired():
        expired = expiry_policy.get_expired_docs(store)
        for doc_id in expired:
            incremental_indexer.sync_document(source.get_doc(doc_id))

    def run_eval():
        eval_result = daily_eval.run()
        if eval_result.faithfulness < 0.8:
            alert("Faithfulness drop detected")

    detect = PythonOperator(task_id='detect_changes', python_callable=detect_changes)
    index = PythonOperator(task_id='index_changes', python_callable=index_changes)
    refresh = PythonOperator(task_id='refresh_expired', python_callable=refresh_expired)
    eval = PythonOperator(task_id='run_eval', python_callable=run_eval)

    detect >> index >> refresh >> eval
```

### 8.2 Cron-based (Sederhana)

```bash
#!/bin/bash
# refresh-rag.sh — jalan tiap 6 jam via cron

# 1. Git pull vault
cd /mnt/data_d/Documents/Wide\ Note/Note && git pull

# 2. Deteksi file yang berubah sejak last run
CHANGED=$(git diff --name-only HEAD@{1} HEAD)

# 3. Index cuma yang berubah
for file in $CHANGED; do
    python run_indexer.py --file "$file" --incremental
done

# 4. Expired docs refresh
python run_indexer.py --refresh-expired --max-age 30

# 5. Eval
python run_eval.py --sample 50

# 6. Log
echo "$(date): Indexed $CHANGED files" >> /var/log/rag-refresh.log
```

### 8.3 Re-index Campaign Planning

| Skenario                      | Frekuensi           | Method                 |
| ----------------------------- | ------------------- | ---------------------- |
| **Vault Obsidian sync**       | Real-time (inotify) | Incremental hash-based |
| **PDF baru di upload folder** | Setiap 5 menit      | Poll + hash            |
| **Full re-index**             | Mingguan (off-peak) | Full                   |
| **Chunk config change**       | On-demand (manual)  | Re-chunk pipeline      |
| **Embedding model upgrade**   | On-demand           | Full re-embed          |

---

## 9. Monitoring & Alerting

### 9.1 Metrics Wajib

```python
RAG_PIPELINE_METRICS = {
    # Pipeline health
    "indexer.last_run_duration_seconds": "Durasi indexing terakhir",
    "indexer.total_docs": "Total dokumen di vector store",
    "indexer.total_chunks": "Total chunks",
    "indexer.changes_pending": "Jumlah perubahan yang antri",

    # Freshness
    "indexer.stale_docs_count": "Dokumen expired yang belum di-refresh",
    "indexer.avg_doc_age_days": "Rata-rata umur dokumen (hari)",
    "indexer.ghost_docs": "Dokumen di index tapi source udah dihapus",

    # Quality
    "eval.faithfulness": "RAGAS faithfulness score",
    "eval.context_precision": "RAGAS context precision",
    "eval.hallucination_rate": "Proporsi jawaban halusinasi",

    # Operations
    "indexer.dedup_rate": "Persentase chunks yang di-skip karena duplikat",
    "indexer.errors": "Error count in last cycle",
}
```

### 9.2 Alert Rules

```yaml
alerts:
  - name: HighStaleness
    condition: indexer.stale_docs_count > 100
    action: "Notify #rag channel — more than 100 docs expired"

  - name: PipelineFailure
    condition: indexer.errors > 0
    action: "Page on-call engineer"

  - name: FaithfulnessDrop
    condition: eval.faithfulness < 0.75
    action: "Auto-trigger full re-index + notify"

  - name: GhostDocAccumulation
    condition: indexer.ghost_docs > 50
    action: "Run garbage collector"
```

### 9.3 Dashboard

```
┌─────────────────────────────────────────────────────────┐
│  RAG Pipeline Health ────────────── Last 24h             │
├─────────────┬───────────────┬──────────────┬────────────┤
│ Documents   │ Chunks        │ Stale Docs   │ Dedup Rate  │
│ 12,847      │ 48,291        │ 23 (0.2%)    │ 3.1%        │
├─────────────┴───────────────┴──────────────┴────────────┤
│ Faithfulness: 0.87 │ Context Precision: 0.82 │ Halluc: 4% │
├─────────────────────────────────────────────────────────┤
│ Last refresh: 10 min ago │ Next: in 3h 50min │ Status: ✅│
└─────────────────────────────────────────────────────────┘
```

---

## Referensi

- [[rag-pipeline-end-to-end-guide]] — Implementasi RAG pipeline lengkap
- [[document-parsing-for-rag]] — Teknik parsing dokumen
- [[advanced-chunking-strategies-deepdive]] — Detail chunking strategy
- [[embedding-model-selection-finetuning]] — Pilihan embedding model
- [[rag-evaluation-framework]] — Evaluation metric RAGAS
- [Airbyte — Open-source CDC & EL](https://airbyte.com)
- [Debezium — Kafka-based CDC](https://debezium.io)
- [MinHash LSH — Datasketch](https://github.com/ekzhu/datasketch)

---

_Dibuat: 16 Juli 2026 — Panduan maintain RAG knowledge base dari incremental indexing sampai monitoring._
