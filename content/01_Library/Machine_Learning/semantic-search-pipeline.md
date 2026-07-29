---
title: Semantic Search Pipeline
tags:
  - semantic-search
  - embedding
  - retrieval
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> Semantic search menggunakan meaning (embedding) bukan keyword matching.

## Pipeline

```
Query -> Embedding -> Vector Search -> Rerank -> Response
                BM25 (keyword fallback)
```

## Components

| Component      | Tool                   | Purpose                 |
| -------------- | ---------------------- | ----------------------- |
| Embedding      | text-embedding-3-small | Convert query to vector |
| Vector Search  | sqlite-vec / FAISS     | ANN nearest neighbor    |
| Keyword Search | BM25 / Tantivy         | Exact match fallback    |
| Fusion         | RRF                    | Hybrid ranking merge    |
| Rerank         | Cohere/cross-encoder   | Re-rank top-K           |
