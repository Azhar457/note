---
title: 🛡️ Hallucination Mitigation & Grounding — CRAG, Self-RAG, dan Verifikasi Faktual
tags:
- hallucination
- rag
- grounding
- crag
- self-rag
- library
created: '2026-07-16'
updated: '2026-07-16'
status: pending
cssclasses:
  - wide-table
  

---
# 🛡️ Hallucination Mitigation & Grounding — CRAG, Self-RAG, dan Verifikasi Faktual

> Hallucination adalah masalah #1 RAG di production — LLM menjawab dengan informasi yang tidak ada di konteks, atau kontradiksi dengan konteks. Dokumen ini membahas penyebab hallucination, teknik mitigasi dari level retrieval (chunking, reranking) hingga level generation (CRAG, Self-RAG, prompt engineering), dengan fokus pada **Corrective RAG** yang sudah diimplementasikan di vault-rag.

> [!info] Hubungan ke Vault
> vault-rag punya **CRAG (Corrective RAG)** di `scripts/corrective_rag.py`. Catatan ini menjelaskan teori di belakangnya plus alternatif. Terkait dengan [[query-transformation-rag]] (CRAG bisa trigger query rewrite), [[advanced-chunking-strategies-deepdive]] (parent-child chunking mengurangi hallucination dengan konteks lebih lengkap), dan [[rag-evaluation-framework]] (evaluasi faithfulness).

---

## Daftar Isi

- [[#1. Kenapa LLM Hallucinate di RAG?]]
- [[#2. Teknik Mitigasi]]
- [[#3. Corrective RAG — Implementasi vault-rag]]
- [[#4. Perbandingan]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Kenapa LLM Hallucinate di RAG?

| Penyebab | Penjelasan | Contoh |
|----------|-----------|--------|
| **Context Ignorance** | LLM gak baca/peduli konteks yang dikasih | Konteks bilang "SYN flood = layer 4" tapi jawaban bilang "layer 7" |
| **Retrieval Gap** | Konteks gak cukup untuk jawab, LLM "nambahin" | Pertanyaannya spesifik, tapi cuma dapet konteks umum |
| **Chunk Fragmentation** | Konteks kepotong, LLM nebak sisanya | Child chunk tanpa parent context |
| **Parametric Bias** | LLM lebih percaya internal knowledge daripada konteks | LLM udah "tahu" jawaban dari training data, malah ngaco kalo konteks beda |
| **Instruction Drift** | Prompt gak cukup kuat untuk grounding | "Jawab berdasarkan konteks" vs "Jawab dengan detail" — kontradiksi |

### 1.1 Jenis Hallucination di RAG

```
Input: "Apa itu SYN flood?"
Konteks: [Artikel tentang TCP handshake dan SYN flood mitigation]

✅ Faithful: "SYN flood adalah serangan DoS layer 4 yang mengirim banyak SYN..."
❌ Input Conflict: "SYN flood adalah serangan SQL injection..." (kontradiksi konteks)
❌ Context Conflict: "SYN flood adalah serangan yang terjadi di layer 7..." (salah interpretasi)
❌ Fabrication: "SYN flood ditemukan oleh John Smith pada 1998..." (gak ada di konteks)
```

---

## 2. Teknik Mitigasi

### 2.1 Retrieval-Level

| Teknik | Cara | Efek |
|--------|------|------|
| **Parent-Child Chunking** | Child untuk search, parent untuk context | ✅ Konteks lebih lengkap |
| **Reranking** | Filter chunk yang relevan sebelum dikirim ke LLM | ✅ Noise berkurang |
| **Hybrid Search** | Dense + BM25 — lebih banyak sinyal | ✅ Coverage meningkat |
| **Query Transformation** | Multi-Query, HyDE — improve retrieval | ✅ Context lebih relevan |

### 2.2 Generation-Level

| Teknik | Cara | Efek |
|--------|------|------|
| **Prompt Grounding** | "Hanya jawab dari konteks. Jika gak ada, bilang tidak tahu." | ✅ Sederhana, cukup efektif |
| **CRAG** | Self-evaluasi relevansi → rewrite kalo gagal | ✅ Adaptive |
| **Self-RAG** | Generate + evaluasi sendiri — "apakah jawaban didukung konteks?" | ✅ Lebih akurat |
| **Chain-of-Verification** | Generate dulu → verifikasi tiap klaim → revisi | ✅ Paling akurat, tapi 3x latency |

---

## 3. Corrective RAG — Implementasi vault-rag

### 3.1 Alur CRAG

```
[Query] → [Retrieve] → [Evaluate Relevance] → [Confidence Score]
                                                   │
                    ┌───────────────────────────────┼───────────────┐
                    ▼                               ▼               ▼
              ✅ Correct                        ❌ Incorrect     ⚠️ Ambiguous
              (skor > 0.7)                      (skor < 0.3)    (0.3-0.7)
                    │                               │               │
                    ▼                               ▼               ▼
             Generate answer                 [Rewrite Query]   [Hybrid: generate
                                              → retrieve ulang   + search web]
              [Return result]                      │
                                                   ▼
                                             Generate answer
                                              [Return result]
```

### 3.2 Implementasi vault-rag

```python
# scripts/corrective_rag.py (simplified)
def corrective_rag(query, llm, retriever):
    # 1. Retrieve
    docs = retriever.search(query)

    # 2. Evaluate relevance
    score = llm.evaluate(f"Is this context relevant to: {query}?\nContext: {docs}")

    if score > 0.7:
        # Langsung generate
        return llm.generate(f"Answer from context:\nContext: {docs}\nQuery: {query}")

    elif score < 0.3:
        # Rewrite query & retrieve ulang
        rewritten = llm.generate(f"Rewrite this query for better search: {query}")
        docs = retriever.search(rewritten)
        return llm.generate(f"Answer from context:\nContext: {docs}\nQuery: {query}")

    else:
        # Partial relevance — generate with caution
        answer = llm.generate(f"Answer from context. If unsure, say so.\nContext: {docs}\nQuery: {query}")
        return f"{answer}\n\n⚠️ Disclaimer: Partially relevant context."
```

---

## 4. Perbandingan

| Teknik | Kompleksitas | Latency | Akurasi | vault-rag |
|--------|-------------|---------|---------|-----------|
| **Prompt grounding** | 🟢 Rendah | 🟢 +0ms | 🟡 70% | ✅ Prompt template |
| **Parent-Child** | 🟡 Sedang | 🟢 +0ms | 🟢 85% | ✅ Implemented |
| **Reranking** | 🟡 Sedang | 🟡 +200ms | 🟢 85% | ✅ Ada (opsional) |
| **CRAG** | 🔴 Tinggi | 🔴 +500ms | 🟢 90% | ✅ `scripts/corrective_rag.py` |
| **Self-RAG** | 🔴 Tinggi | 🔴 +1s | 🟢 93% | ❌ Belum |
| **Chain-of-Verification** | 🔴 Sangat Tinggi | 🔴 +3s | 🟢 95% | ❌ Belum |

---

## Koneksi ke Vault

- [[query-transformation-rag]] — CRAG rewrite query saat retrieval gagal
- [[advanced-chunking-strategies-deepdive]] — Parent-child chunking = mitigasi hallucination via konteks lengkap
- [[rag-evaluation-framework]] — Evaluasi faithfulness score
- `../vault-rag/scripts/corrective_rag.py` — Implementasi CRAG loop
- `../vault-rag/scripts/query.py` — Prompt grounding: "If context has NOTHING relevant: say No relevant information found"

---

## References

1. CRAG Paper. *S. Yan et al. (2024)*. https://arxiv.org/abs/2401.15884
2. Self-RAG. *A. Asai et al. (2023)*. https://arxiv.org/abs/2310.11511
3. Chain-of-Verification. *S. Dhuliawala et al. (2023)*. https://arxiv.org/abs/2309.11495
4. RAGAS Hallucination. https://docs.ragas.io/en/latest/concepts/metrics/faithfulness.html

> [!tip] Bottom Line
> Hallucination di RAG disebabkan oleh 4 hal: retrieval gap, chunk fragmentation, context ignorance, parametric bias. vault-rag udah mitigasi 2 dari 4: **parent-child chunking** (konteks lengkap) dan **CRAG** (self-evaluate + rewrite). Prompt grounding yang kuat ("Jika konteks gak relevan, bilang tidak tahu") adalah safety net termurah dengan ROI tertinggi. Next step: implementasi Self-RAG untuk akurasi lebih tinggi.
---

audited
---
