---
title: RAG Pipeline End-to-End Implementation Guide
tags:
  - rag
  - pipeline
  - implementation
  - production
created: "2026-07-16"
updated: "2026-07-16"
status: pending
---

## Daftar Isi

1. [Arsitektur Overview](#1-arsitektur-overview)
2. [Ingestion Pipeline](#2-ingestion-pipeline)
3. [Indexing & Storage](#3-indexing--storage)
4. [Retrieval Pipeline](#4-retrieval-pipeline)
5. [Generation Pipeline](#5-generation-pipeline)
6. [Orkestrasi & API Layer](#6-orkestrasi--api-layer)
7. [Deployment Blueprint](#7-deployment-blueprint)
8. [Monitoring & Observability](#8-monitoring--observability)

---

## 1. Arsitektur Overview

Pipeline RAG produksi bukan cuma "chunk → embed → retrieve → LLM". Ada 6 layer yang harus jalan:

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                        │
│              (Chat UI / API / Slack bot)                 │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              Orchestration Layer                         │
│    Query Routing │ Context Assembly │ Guardrails        │
└──────┬─────────────────────────────┬────────────────────┘
       │                             │
┌──────▼──────┐            ┌─────────▼──────────────────┐
│  Retrieval  │            │      Generation             │
│  Pipeline   │            │  LLM + Prompt Template      │
│  ─────────  │            │  ───────────────────        │
│  Multi-Query│            │  Streaming, Citations       │
│  Hybrid     │            │  Re-ranking di output       │
│  Reranking  │            └─────────────────────────────┘
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────────────────┐
│                 Index / Vector Store                     │
│   Qdrant / Milvus / pgvector + BM25 (Elastic/Meilisearch)│
└──────┬──────────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────────┐
│              Ingestion Pipeline                          │
│   Parse → Chunk → Embed → Index → Metadata Extraction   │
└─────────────────────────────────────────────────────────┘
```

### Komponen Kunci

- **Ingestion Pipeline:** dokumen → chunks → embeddings → vector store
- **Index Layer:** vector DB untuk semantic search + inverted index untuk keyword
- **Retrieval Pipeline:** query → retrieve → rerank → context assembly
- **Generation:** prompt template + LLM + output formatting
- **Orchestration:** routing logic, fallback, multi-turn memory
- **Monitoring:** trace setiap hop, eval quality, alert drift

---

## 2. Ingestion Pipeline

Ingestion adalah step paling underrated — quality in = quality out.

### 2.1 Document Parsing

Dari berbagai source:

```python
# Pseudo-architecture ingestion
class DocumentParser:
    def parse(self, file: BinaryIO) -> list[Document]:
        match file.type:
            case "pdf":
                return PyMuPDFLoader(file).load()      # structured text + tables
            case "html":
                return TrafilaturaExtractor(file).extract()
            case "docx":
                return DocxLoader(file).load()           # python-docx
            case "code":
                return TreeSitterParser(file).parse()    # AST-aware chunking
            case "image":
                return OCRProcessor(file).textract()     # PaddleOCR / Tesseract
```

**Pertimbangan:**

- PDF: PyMuPDF (fitz) lebih cepat dari PyPDF2 — handle embedded tables & images
- HTML: Trafilatura > BeautifulSoup — extract konten utama, buang navbar/footer
- Markdown: split by heading (natural boundary)

### 2.2 Chunking Strategy

Bukan satu strategi — **hirarki chunking**:

```python
class HierarchicalChunker:
    """
    Level 0: Document (raw)
    Level 1: Sections (by heading — )
    Level 2: Chunks (256-512 tokens, with 20% overlap)
    Level 3: Sentences (for reranking)
    """
    def chunk(self, doc: Document) -> ChunkResult:
        sections = self.section_splitter(doc)      # markdown headers
        chunks = self.token_splitter(sections)      # recursive character
        sentences = self.sentence_splitter(chunks)  # NLTK / spaCy
        return ChunkResult(chunks, sentences)
```

**Strategi overlap:**

- Sliding window: 256 tokens, 50 overlap (≈20%)
- Boundary-aware: potong di akhir kalimat terdekat, bukan tengah kata
- Metadata: tiap chunk bawa source doc + section + page number

### 2.3 Embedding

```python
class EmbeddingPipeline:
    def __init__(self, model_name: str = "BAAI/bge-m3"):
        self.model = AutoModel.from_pretrained(model_name)
        self.dimension = 1024  # bge-m3 output

    def embed(self, chunks: list[str]) -> list[list[float]]:
        # Batch inference
        embeddings = self.model.encode(chunks, batch_size=32)

        # Optional: Matryoshka dimension reduction
        if self.normalize:
            embeddings = normalize(embeddings, dim=-1)  # cosine similarity ready

        return embeddings.tolist()
```

**Pilihan embedding:**

| Model                  | Dimensi              | Ukuran | Cocok Untuk             |
| ---------------------- | -------------------- | ------ | ----------------------- |
| text-embedding-3-small | 512 (via Matryoshka) | Kecil  | General purpose, budget |
| bge-m3                 | 1024                 | Sedang | Multilingual + hybrid   |
| jina-embeddings-v3     | 1024                 | Sedang | LoRA fine-tuning        |
| voyage-2               | 1024                 | API    | Production tanpa GPU    |

### 2.4 Metadata Extraction

Metadata penting untuk filtering & hybrid search:

```python
metadata = {
    "source": "ddia-summary.md",
    "section": "Chapter 5: Replication",
    "chunk_id": 42,
    "page": 142,
    "doc_type": "book_note",
    "created_at": "2026-07-01",
    "tags": ["distributed-systems", "consistency"],
    "embedding_model": "bge-m3",
    "token_count": 312
}
```

---

## 3. Indexing & Storage

### 3.1 Vector Store — Perbandingan

| Feature                | Qdrant                   | Milvus               | pgvector                  | Elasticsearch          |
| ---------------------- | ------------------------ | -------------------- | ------------------------- | ---------------------- |
| **Deploy**             | Docker / Cloud           | K8s native           | Extension                 | Docker / Cloud         |
| **Scalability**        | Horizontal               | Horizontal           | Vertical                  | Horizontal             |
| **Hybrid**             | Dense + Sparse           | Dense + Sparse       | Dense + BM25 via tsvector | Dense + BM25 built-in  |
| **Filtering**          | Payload index            | Scalar index         | SQL WHERE                 | ESG filter             |
| **Sync**               | REST/gRPC                | REST/gRPC            | SQL                       | REST                   |
| **Self-hosted effort** | Low                      | Medium               | Low                       | Medium                 |
| **Best for**           | **Mid-scale production** | **Large scale >10M** | **Small <1M docs**        | **Full-text + vector** |

**Pilihan pragmatic:**

- **Indie/homelab:** pgvector + PostgreSQL (gak usah maintain DB terpisah)
- **Mid production:** Qdrant (simple, fast, REST API langsung)
- **Enterprise >10M docs:** Milvus atau Elasticsearch

### 3.2 Hybrid Index

```sql
-- pgvector setup
CREATE EXTENSION vector;

CREATE TABLE chunks (
    id SERIAL PRIMARY KEY,
    doc_id INTEGER REFERENCES documents(id),
    content TEXT NOT NULL,
    embedding vector(1024),
    metadata JSONB,
    tsvector_content tsvector GENERATED ALWAYS AS (to_tsvector('indonesian', content)) STORED
);

CREATE INDEX chunks_embedding_idx ON chunks
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX chunks_tsv_idx ON chunks USING GIN (tsvector_content);
```

### 3.3 Index Optimasi

- **HNSW (Hierarchical Navigable Small World):** default buat Qdrant/Milvus — recall tinggi di dimensi <1024
- **IVF + PQ:** untuk >10M vectors — kompresi Product Quantization, sacrifice sedikit recall
- **IVFFlat:** pgvector only — kualitas OK buat <1M docs
- **DiskANN:** Microsoft — disk-based, buat miliaran vectors

---

## 4. Retrieval Pipeline

### 4.1 Query Processing

```python
class QueryProcessor:
    def process(self, query: str, history: list[dict]) -> ProcessedQuery:
        # 1. Query rewriting based on history
        if history:
            query = self.rewrite_with_context(query, history)

        # 2. Multi-Query expansion
        queries = self.generate_variations(query)  # 3-5 variants

        # 3. HyDE — hypothetical document embedding
        hyde_doc = self.generate_hypothetical_doc(query)

        return ProcessedQuery(
            original=query,
            variations=queries,
            hyde_embedding=self.embed(hyde_doc) if use_hyde else None
        )
```

**Trick:**

- **Multi-Query:** generate 3-5 variasi pertanyaan, retrieve dari masing-masing, dedup hasilnya
- **HyDE:** generate dokumen hipotetis yang "seharusnya" jadi jawaban → embed dokumen itu → cari chunks yang mirip
- **Step-Back:** kalau pertanyaan spesifik, generate dulu pertanyaan yang lebih umum → retrieve konteks umum + spesifik

### 4.2 Hybrid Search

```python
class HybridRetriever:
    def retrieve(self, query: str, k: int = 20) -> list[Chunk]:
        # Dense retrieval (semantic)
        query_embedding = self.embed_model.encode(query)
        dense_results = self.vector_store.search(
            query_embedding, k=k*2
        )  # ambil lebih banyak untuk reranking

        # Sparse retrieval (keyword)
        sparse_results = self.bm25_search(query, k=k*2)

        # Fusion via RRF (Reciprocal Rank Fusion)
        all_results = self.rrf_fusion(
            [dense_results, sparse_results],
            weights=[0.6, 0.4],  # dense lebih dominan
            k=60  # RRF constant
        )

        # Rerank
        reranked = self.reranker.rerank(query, all_results[:k*2])
        return reranked[:k]
```

### 4.3 Reranking

Step paling kritis setelah retrieval — tanpa reranker, context window penuh noise:

```python
class Reranker:
    def __init__(self, model: str = "BAAI/bge-reranker-v2-m3"):
        self.model = CrossEncoder(model)  # cross-encoder > bi-encoder

    def rerank(self, query: str, candidates: list[Chunk]) -> list[Chunk]:
        pairs = [[query, c.content] for c in candidates]
        scores = self.model.predict(pairs)

        # Sort by score descending
        scored = sorted(zip(candidates, scores), key=lambda x: -x[1])
        return [c for c, s in scored]
```

**Kenapa reranker penting:**

- Bi-encoder (embedding) → query & dokumen di-encode terpisah → fast tapi kurang akurat
- Cross-encoder → query & dokumen di-proses bareng → akurat tapi lambat (hanya buat top-20)
- **Hasil:** precision naik 15-25% di top-3

### 4.4 Context Assembly

```python
def assemble_context(chunks: list[Chunk], max_tokens: int = 4000) -> str:
    """
    Susun retrieved chunks jadi context yang rapi.
    Prioritaskan chunks dengan score tinggi, potong yang melebihi max_tokens.
    """
    # Urut berdasarkan source + position (preserve dokumen coherence)
    chunks = sort_by_source_position(chunks)

    context_parts = []
    current_tokens = 0

    for chunk in chunks:
        header = f"[Source: {chunk.metadata['source']} — {chunk.metadata['section']}]"
        block = f"{header}\n{chunk.content}\n"
        block_tokens = count_tokens(block)

        if current_tokens + block_tokens > max_tokens:
            break

        context_parts.append(block)
        current_tokens += block_tokens

    return "\n\n".join(context_parts)
```

---

## 5. Generation Pipeline

### 5.1 Prompt Template

```python
RAG_PROMPT = """Kamu adalah asisten yang menjawab berdasarkan konteks yang diberikan.

INSTRUKSI:
- Jawab berdasarkan KONTEKS di bawah. Jika konteks tidak cukup, bilang "tidak ditemukan dalam sumber yang ada"
- Cantumkan sumber untuk setiap klaim dalam format [Sumber: nama_file]
- Jika pengguna bertanya di luar konteks, arahkan ke topik yang relevan

KONTEKS:
{context}

RIWAYAT PERCAKAPAN:
{history}

PERTANYAAN: {query}
JAWABAN:"""
```

### 5.2 Response Generation

```python
class RAGGenerator:
    def __init__(self, model: str = "llama-3-8b"):
        self.llm = LLMClient(model)
        self.max_context = 4000
        self.max_new_tokens = 1024

    def generate(self, query: str, chunks: list[Chunk], history: list) -> Response:
        context = assemble_context(chunks, self.max_context)
        prompt = RAG_PROMPT.format(
            context=context,
            history=format_history(history),
            query=query
        )

        response = self.llm.generate(
            prompt=prompt,
            max_tokens=self.max_new_tokens,
            temperature=0.3,       # rendah untuk factual
            top_p=0.9,
            stream=True
        )

        return Response(
            content=response.text,
            sources=[c.metadata for c in chunks[:3]],  # top-3 sources
            usage=self.llm.usage,
            latency=response.latency
        )
```

### 5.3 Output Validation

```python
def validate_response(response: str, chunks: list[Chunk]) -> ValidationResult:
    issues = []

    # 1. Cek hallucination — apakah ada klaim yang gak didukung chunks?
    claims = extract_claims(response)
    for claim in claims:
        if not any(claim_supported(claim, c.content) for c in chunks):
            issues.append(f"Unsupported claim: {claim}")

    # 2. Cek source citation — apakah sumber dicantumkan?
    if not has_citations(response):
        issues.append("Missing source citations")

    # 3. Cek answer relevance
    relevance = compute_relevance(response, original_query)
    if relevance < 0.7:
        issues.append(f"Low relevance score: {relevance:.2f}")

    return ValidationResult(
        passed=len(issues) == 0,
        issues=issues,
        score=relevance
    )
```

---

## 6. Orkestrasi & API Layer

### 6.1 RAG Pipeline API

```python
@dataclass
class RAGConfig:
    retrieval: RetrievalConfig
    generation: GenerationConfig
    guards: GuardConfig

class RAGPipeline:
    """Single entry point — orchestrates seluruh pipeline."""

    def query(self, request: QueryRequest) -> QueryResponse:
        # 1. Input guard
        if self.guards.check_harmful(request.query):
            return QueryResponse(error="Query rejected by guardrails")

        # 2. Context retrieval
        chunks = self.retriever.retrieve(
            request.query,
            k=request.top_k or 5
        )

        # 3. If no relevant chunks found
        if not chunks or max(chunks.scores) < 0.3:
            return QueryResponse(
                content="Maaf, tidak ada informasi yang relevan dalam knowledge base.",
                sources=[],
                fallback=True
            )

        # 4. Generate
        response = self.generator.generate(
            request.query,
            chunks,
            request.history
        )

        # 5. Output guard
        validation = validate_response(response.content, chunks)

        return QueryResponse(
            content=response.content,
            sources=response.sources,
            validation=validation,
            latency=response.latency
        )
```

### 6.2 Streaming Response

```python
@app.post("/v1/chat/completions")
async def chat_completion(request: ChatRequest):
    rag = RAGPipeline(config)

    # Retrieve dulu (blocking)
    chunks = rag.retriever.retrieve(request.query, k=5)

    # Stream generation
    async def generate():
        yield f"data: {json.dumps({'type': 'sources', 'sources': chunks[:3]})}\n\n"

        async for token in rag.generator.stream(request.query, chunks, request.history):
            yield f"data: {json.dumps({'type': 'token', 'content': token})}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

### 6.3 Multi-Turn Memory

```python
class ConversationMemory:
    def __init__(self, store: Redis):
        self.store = store
        self.max_turns = 10

    def add_turn(self, session_id: str, query: str, response: str, chunks: list):
        turn = {
            "query": query,
            "response": response,
            "chunks": [c.id for c in chunks],
            "timestamp": now()
        }
        self.store.lpush(f"session:{session_id}", turn)
        self.store.ltrim(f"session:{session_id}", 0, self.max_turns - 1)

    def get_context(self, session_id: str) -> list[dict]:
        turns = self.store.lrange(f"session:{session_id}", 0, -1)
        return [{"role": "user", "content": t["query"]},
                {"role": "assistant", "content": t["response"]}
                for t in turns]
```

---

## 7. Deployment Blueprint

### 7.1 Docker Compose — Produksi Kecil

```yaml
version: "3.8"
services:
  qdrant:
    image: qdrant/qdrant:v1.12
    volumes:
      - ./data/qdrant:/qdrant/storage
    environment:
      - QDRANT__SERVICE__GRPC_PORT=6334
    ports:
      - "6333:6333"

  milvus:
    image: milvusdb/milvus:v2.4
    # Untuk production >10M docs

  reranker:
    image: ghcr.io/huggingface/text-embeddings-inference
    command: --model-id BAAI/bge-reranker-v2-m3
    ports:
      - "8080:80"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1

  api:
    build: ./rag-api
    ports:
      - "8000:8000"
    depends_on:
      - qdrant
      - reranker
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - QDRANT_URL=http://qdrant:6333
      - RERANKER_URL=http://reranker:80
```

### 7.2 Scaling Consideration

| Scale          | Docs     | Latency Budget | Stack                                       |
| -------------- | -------- | -------------- | ------------------------------------------- |
| **Homelab**    | <10K     | <5s            | pgvector + ollama + BGE                     |
| **Small Prod** | 10K-500K | <3s            | Qdrant + TGI/vLLM + Reranker                |
| **Medium**     | 500K-10M | <2s            | Qdrant cluster + vLLM + FlashRank           |
| **Large**      | >10M     | <1s            | Milvus + TensorRT-LLM + custom CUDA kernels |

### 7.3 Langfuse — Tracing

Setiap hop harus di-trace:

```python
from langfuse import Langfuse

langfuse = Langfuse()

class RAGPipeline:
    def query(self, request):
        trace = langfuse.trace(name="rag-query")

        with trace.span(name="retrieval") as span:
            chunks = self.retriever.retrieve(request.query)
            span.set_output({"n_chunks": len(chunks), "top_score": chunks[0].score})

        with trace.span(name="rerank") as span:
            chunks = self.reranker.rerank(request.query, chunks)

        with trace.span(name="generation") as span:
            response = self.generator.generate(request.query, chunks)
            span.set_output({"tokens": response.usage, "latency": response.latency})

        return response
```

---

## 8. Monitoring & Observability

### 8.1 Metrics Utama

```python
# Yang wajib di-monitor:
METRICS = {
    "retrieval_recall@5": "Apakah dokumen relevan ada di top-5?",
    "mrr@10": "Mean Reciprocal Rank — peringkat dokumen pertama yang relevan",
    "ndcg@10": "Normalized Discounted Cumulative Gain — quality ranking",
    "faithfulness": "Apakah jawaban didukung konteks?",
    "answer_relevancy": "Apakah jawaban menjawab pertanyaan?",
    "context_precision": "Apakah konteks yang diretrieve relevan?",
    "latency_p95": "Latency percentil 95 — user experience",
    "hallucination_rate": "Proporsi jawaban dengan klaim tidak didukung",
    "citation_accuracy": "Apakah sumber yang disebut benar sesuai konten?"
}
```

### 8.2 Eval Harian — Automatic

```python
class DailyEval:
    """Jalanin setiap malam via cron — RAGAS + DeepEval."""

    def run(self):
        # Ambil sample queries dari log (100 random dari hari ini)
        log_queries = self.get_daily_logs(limit=100)

        # Generate jawaban + retrieve
        results = []
        for q in log_queries:
            chunks = retriever.retrieve(q)
            answer = generator.generate(q, chunks)
            results.append({
                "query": q,
                "answer": answer.content,
                "contexts": [c.content for c in chunks],
                "ground_truth": get_ground_truth(q)  # dari supervised log
            })

        # RAGAS evaluation
        from ragas import evaluate
        score = evaluate(results)

        # Alert if drop
        if score.faithfulness < 0.8:
            alert("#faithfulness_drop", score.faithfulness)

        return score
```

---

## Referensi

- [[advanced-chunking-strategies-deepdive]] — Detail chunking
- [[embedding-model-selection-finetuning]] — Embedding models
- [[vector-database-internals-optimization]] — Vector DB internals
- [[hybrid-search-vector-keyword]] — Dense + sparse fusion
- [[query-transformation-rag]] — Query rewriting
- [[hallucination-mitigation-grounding]] — Hallucination guard
- [[rag-evaluation-framework]] — RAGAS & evaluation
- [Langfise Tracing Docs](https://langfuse.com/docs)

---

_Dibuat: 16 Juli 2026 — Blueprint implementasi RAG end-to-end dari ingestion sampai monitoring._
