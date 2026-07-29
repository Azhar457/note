---
title: Distance Metrics Comparison
tags:
  - cosine
  - euclidean
  - dot-product
  - embedding
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> Perbandingan distance metrics untuk embedding search.

| Metric      | Formula              | Range       | Best For                         |
| ----------- | -------------------- | ----------- | -------------------------------- |
| Cosine      | cos(theta) = A.B / ( | A           |                                  | B   | )   | [-1, 1] | Text embeddings, normalized vectors |
| Euclidean   | d = sqrt(sum(A-B)^2) | [0, inf)    | Dense vectors, magnitude matters |
| Dot Product | A.B = sum(AxB)       | (-inf, inf) | Unnormalized, speed-optimized    |

## When to Use

- Cosine: text search, document similarity, RAG (OpenAI embeddings)
- Euclidean: image similarity, clustering (k-means)
- Dot Product: fast search with normalized vectors
