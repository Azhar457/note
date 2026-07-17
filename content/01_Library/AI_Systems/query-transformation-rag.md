---
title: "🔄 Query Transformation — Multi-Query, HyDE, Step-Back, dan RAG-Fusion"
tags:
  - query-transformation
  - rag
  - retrieval
  - hyde
  - multi-query
  - library
aliases:
  - "query-transformation-rag"
created: "2026-07-16"
updated: "2026-07-16"
status: operational
cssclasses:
  - wide-table
---

# 🔄 Query Transformation — Multi-Query, HyDE, Step-Back, dan RAG-Fusion

> Query transformation adalah teknik untuk **memperbaiki retrieval dengan memperbaiki query** — sebelum query dikirim ke vector search. Ide dasarnya: user jarang nulis query yang sempurna. Query pendek ("TCP handshake"), ambigu ("jelasin"), atau terlalu spesifik ("gimana cara kerja sequence number di SYN-ACK?") bisa di-rewrite, diperluas, atau diabstraksi untuk retrieval yang lebih baik. Dokumen ini membahas 4 teknik: Multi-Query, HyDE, Step-Back Prompting, dan RAG-Fusion.

> [!info] Hubungan ke Vault
> vault-rag punya **Corrective RAG (CRAG)** — self-evaluating loop. Query transformation adalah langkah SEBELUM CRAG. Catatan ini terhubung dengan [[hallucination-mitigation-grounding]] (transformation yang salah = hallucination), [[hybrid-search-vector-keyword]] (query expansion untuk dense + BM25), dan `../vault-rag/scripts/corrective_rag.py` (implementasi CRAG).

---

## Daftar Isi

- [[#1. Masalah Query]]
- [[#2. Multi-Query]]
- [[#3. HyDE]]
- [[#4. Step-Back]]
- [[#5. Perbandingan]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Masalah Query

### 1.1 Kenapa Query Perlu Diubah?

| Masalah              | Contoh User Query                                       | Masalah buat Retrieval                                                             |
| -------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Terlalu pendek**   | "syn flood"                                             | Embedding gak punya cukup konteks untuk similarity                                 |
| **Ambigu**           | "jelasin"                                               | Apa yang dijelasin? Konsep? Cara kerja? Dampak?                                    |
| **Terlalu spesifik** | "gimana cara detect syn flood dengan suricata di linux" | Mungkin cuma dapet artikel Suricata, bukan artikel SYN flood detection secara umum |
| **Istilah beda**     | "TCP handshake" tapi dokumen pake "three-way handshake" | Embedding harus cukup kuat untuk hubungin sinonim                                  |

### 1.2 Pipeline Transformation

```
[User Query] → [Transformer] → [Improved Query] → [Vector Search] → [Reranker] → [Generation]
                      │
              ┌───────┼───────────┐
              ▼       ▼           ▼
         Multi-     HyDE      Step-Back
         Query    (Generate   (Abstract)
         (Expand)   Answer)
```

---

## 2. Multi-Query — Perluas Cakupan

### 2.1 Cara Kerja

Generate N varian query dari query asli → search semua → gabung hasilnya → deduplikasi.

```python
def multi_query(original_query, llm, n=5):
    prompt = f"""Given the user query, generate {n} different search queries
that cover the same information need from different angles.

Original: {original_query}

Generate {n} queries, one per line:"""

    response = llm.generate(prompt)
    queries = response.strip().split("\n")[:n]

    # Search semua varian
    all_results = []
    for q in [original_query] + queries:
        results = vector_search(q)
        all_results.extend(results)

    # Deduplikasi & sort
    return rerank_and_deduplicate(all_results)
```

### 2.2 Contoh

```
Query asli: "SYN flood mitigation"
  Varian 1: "Cara mencegah SYN flood attack"
  Varian 2: "SYN cookies implementation"
  Varian 3: "TCP SYN flood protection techniques"
  Varian 4: "Rate limiting SYN packets"
  Varian 5: "Kernel SYN flood defense"

→ Dapet article: "SYN Cookies", "TCP state machine", "Linux kernel network hardening"
  (yang mungkin gak ter-retrieve kalo cuma pake query asli)
```

---

## 3. HyDE — Hypothetical Document Embeddings

### 3.1 Cara Kerja

Alih-alih search pake query, **generate dokumen hipotetis** yang menjawab query → search pake embedding dokumen itu.

```
Query: "Apa itu SYN flood?"
          │
          ▼
[LLM Generate] → "SYN flood adalah serangan denial-of-service..."
          │
          ▼
[Embed Dokumen Hipotetis] → [0.23, -0.45, ...]
          │
          ▼
[Vector Search] → dapet dokumen yang mirip secara SEMANTIK
```

### 3.2 Kenapa Efektif?

Embedding query pendek ("SYN flood") kurang informatif buat cosine similarity. Embedding dokumen hipotetis ("SYN flood adalah serangan DoS yang mengirim banyak SYN...") lebih kaya konteks → similarity lebih akurat.

```python
def hyde(query, llm):
    prompt = f"""Write a detailed paragraph that answers the following question.
The paragraph should be factual and informative, written in the style of a technical documentation.

Question: {query}

Answer:"""

    hypothetical_doc = llm.generate(prompt)
    # Embed dokumen (bukan query!)
    emb = embed(hypothetical_doc)
    return search_dense(emb)
```

### 3.3 Risiko

HyDE bisa **memperkuat hallucination**: kalo LLM generate dokumen hipotetis yang salah → search nyari dokumen yang mirip sama informasi yang salah → hasil retrieval ikut salah. Mitigasi: pake model LLM yang akurat + verifikasi hasil generation dengan CRAG.

---

## 4. Step-Back Prompting — Abstraksi Query

### 4.1 Cara Kerja

Query yang terlalu spesifik sulit di-retrieve karena terlalu narrow. Step-Back **mengabstraksi** query ke pertanyaan yang lebih umum → search yang umum → ambil konteks → baru jawab yang spesifik.

```
Query: "Bagaimana cara setting conntrack di iptables buat anti SYN flood?"
          │
          ▼ (Step-Back)
"Bagaimana cara kerja conntrack untuk proteksi SYN flood?"
          │
          ▼ (Step-Back lagi)
"Apa itu SYN flood dan bagaimana stateful firewall mendeteksinya?"
          │
          ▼ Search abstraksi → dapet konteks umum
          ▼ Search query asli → dapet konteks spesifik
          ▼ Gabung → jawab
```

### 4.2 Implementasi

```python
def step_back(query, llm):
    # Step 1: Generate abstract question
    sb_prompt = f"""
Given the specific question, generate a more general/abstract question
that covers the core concept. This helps retrieve broader context.

Specific: {query}
General abstract question:"""

    abstract_query = llm.generate(sb_prompt)

    # Step 2: Search both
    general_context = search(abstract_query)   # konteks luas
    specific_context = search(query)           # konteks spesifik

    # Step 3: Gabung
    return merge(general_context, specific_context)
```

---

## 5. Perbandingan

| Teknik           | Kapan Efektif                                 | Biaya (LLM call)       | Risiko                   | vault-rag? |
| ---------------- | --------------------------------------------- | ---------------------- | ------------------------ | ---------- |
| **Multi-Query**  | Query pendek, mau cover banyak sudut          | N+1 generate           | Query varian gak relevan | ❌ Belum   |
| **HyDE**         | Query pendek, mau improve semantic similarity | 1 generate             | Memperkuat hallucination | ❌ Belum   |
| **Step-Back**    | Query terlalu spesifik, butuh konteks luas    | 1-2 generate           | Abstraksi terlalu jauh   | ❌ Belum   |
| **CRAG** (punya) | Query apa pun, self-evaluate hasil retrieval  | 1+ generate + evaluasi | Lebih lambat             | ✅ Ada     |

### Implementasi

```python
# Query transformation pipeline vault-rag
def query_pipeline(query, mode="auto"):
    if mode == "auto":
        # Deteksi query length
        if len(query) < 20:
            query = multi_query(query, llm)     # pendek → expand
        elif is_too_specific(query):
            query = step_back(query, llm)       # spesifik → abstrak
        elif needs_context(query):
            query = hyde(query, llm)            # ambigu → hyde

    results = search_hybrid(query)
    return crag(results, query)  # corrective loop
```

---

## Koneksi ke Vault

- [[hallucination-mitigation-grounding]] — Query transformation yang salah = hallucination. CRAG sebagai safety net.
- [[hybrid-search-vector-keyword]] — Hasil query transformation di-search pake hybrid (dense + BM25)
- `../vault-rag/scripts/corrective_rag.py` — CRAG: self-evaluating loop yang bisa detect kalo retrieval gagal

---

## References

1. HyDE Paper. _L. Gao et al. (2022)_. https://arxiv.org/abs/2212.10496
2. Step-Back Prompting. _Z. Zheng et al. (2023)_. https://arxiv.org/abs/2310.06117
3. RAG-Fusion. https://github.com/Raudaschl/rag-fusion
4. CRAG Paper. _S. Yan et al. (2024)_. https://arxiv.org/abs/2401.15884

> [!tip] Bottom Line
> Query transformation adalah **low-hanging fruit** untuk improve retrieval quality tanpa perlu ganti model atau re-index. vault-rag udah punya CRAG (self-evaluating loop). Tambahan yang paling berdampak: **Multi-Query** untuk query pendek yang sering dipake di vault. HyDE perlu hati-hati — kalo LLM hallucinate, HyDE amplify hallucination itu.
