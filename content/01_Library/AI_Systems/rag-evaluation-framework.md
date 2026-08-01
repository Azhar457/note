---
title: 📊 RAG Evaluation Framework — RAGAS, DeepEval, dan Metrik Retrieval & Generation
tags:
  - rag-evaluation
  - ragas
  - deepeval
  - retrieval-metrics
  - library
created: "2026-07-16"
updated: "2026-07-16"
status: pending
cssclasses:
  - wide-table
---

# 📊 RAG Evaluation Framework — RAGAS, DeepEval, dan Metrik Retrieval & Generation

> "You can't improve what you don't measure." RAG punya dua komponen yang perlu diukur: **retrieval** (apakah dokumen yang relevan terambil?) dan **generation** (apakah jawaban LLM akurat dan grounded?). Dokumen ini membahas metrik RAGAS (Faithfulness, Relevancy, Precision, Recall), DeepEval, evaluation dataset, automated testing pipeline, dan cara eval vault-rag secara konkret.

> [!info] Hubungan ke Vault
> Catatan ini adalah **lapisan paling atas** dari pipeline RAG — setelah semua komponen (chunking, embedding, search, transformation, generation) berjalan, evaluasi mengukur seberapa baik semuanya bekerja. Terkait dengan [[hallucination-mitigation-grounding]] (faithfulness metric), [[advanced-chunking-strategies-deepdive]] (context precision), [[hybrid-search-vector-keyword]] (retrieval recall), dan `../vault-rag/scripts/mock_test.py` (test suite vault-rag).

---

## Daftar Isi

- [[#1. Dua Dimensi Evaluasi]]
- [[#2. Metrik Retrieval]]
- [[#3. Metrik Generation — RAGAS]]
- [[#4. Evaluation Dataset]]
- [[#5. Automated Testing]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Dua Dimensi Evaluasi

```
RAG Pipeline:
[Query] → [Retrieval] → [Context] → [Generation] → [Answer]

             ● ● ● ● ● ●              ● ● ● ● ● ●
          RETRIEVAL METRICS        GENERATION METRICS
          • Precision@k            • Faithfulness
          • Recall@k               • Answer Relevancy
          • MRR                     • Context Precision
          • NDCG                    • Context Recall
```

**Penting:** Evaluasi retrieval dengan evaluasi generation harus dipisah. Retrieval bagus ≠ jawaban bagus (LLM bisa ignore context). Retrieval jelek ≠ jawaban jelek (LLM bisa pake internal knowledge — tapi ini riskan).

---

## 2. Metrik Retrieval

### 2.1 Precision@k

Dari top-K yang di-retrieve, berapa persen yang relevan?

```
Query: "SYN flood"
Retrieved: [A (relevant), B (relevant), C (irrelevant), D (relevant), E (irrelevant)]
Precision@3 = 2/3 = 0.66
Precision@5 = 3/5 = 0.60
```

### 2.2 Recall@k

Dari TOTAL dokumen relevan yang ADA di database, berapa yang ter-retrieve?

```
Total relevant docs in DB: 5
Retrieved top-5: [rel, rel, rel, irrel, irrel]
Recall@5 = 3/5 = 0.60
```

### 2.3 Mean Reciprocal Rank (MRR)

Peringkat dokumen relevan PERTAMA yang muncul:

```
Query 1: relevant doc at rank 1 → RR = 1/1 = 1.0
Query 2: relevant doc at rank 3 → RR = 1/3 = 0.33
Query 3: relevant doc at rank 5 → RR = 1/5 = 0.20
MRR = (1.0 + 0.33 + 0.20) / 3 = 0.51
```

### 2.4 Implementasi

```python
def compute_retrieval_metrics(retrieved_ids, relevant_ids, k=5):
    """Hitung precision@k, recall@k, MRR dari hasil retrieval."""
    retrieved = retrieved_ids[:k]
    relevant_set = set(relevant_ids)

    # Precision@k
    hits = sum(1 for doc in retrieved if doc in relevant_set)
    precision = hits / k

    # Recall@k
    recall = hits / len(relevant_set) if relevant_set else 0

    # MRR
    mrr = 0.0
    for rank, doc in enumerate(retrieved, 1):
        if doc in relevant_set:
            mrr = 1.0 / rank
            break

    return {"precision@k": precision, "recall@k": recall, "MRR": mrr}
```

---

## 3. Metrik Generation — RAGAS

RAGAS (RAG Assessment) adalah framework open-source untuk evaluasi generation.

### 3.1 Faithfulness

Apakah jawaban **didukung oleh konteks**? Atau LLM ngasal?

```
Konteks: "SYN flood adalah serangan DoS layer 4 transport."
Jawaban: "SYN flood adalah serangan DoS layer 4 yang mengirim SYN packet." ✅ Faithful
Jawaban: "SYN flood adalah serangan DoS layer 7 yang membanjiri HTTP request." ❌ Tidak faithful
```

**Cara hitung:** Jawaban dipecah jadi klaim → tiap klaim dicek apakah bisa di-infer dari konteks:

```python
# Rasio klaim yang didukung konteks
faithfulness = supported_claims / total_claims
# Contoh: 4 dari 5 klaim didukung → 0.8
```

### 3.2 Answer Relevancy

Apakah jawaban **relevan dengan query**?

```
Query: "Apa itu SYN flood?"
Jawaban: "SYN flood adalah serangan DoS layer 4..." ✅ Relevan
Jawaban: "SYN cookies adalah mitigasi untuk SYN flood..." 🟡 Sebagian relevan
Jawaban: "Saya adalah AI assistant siap membantu." ❌ Tidak relevan
```

### 3.3 Context Precision

Apakah konteks yang di-retrieve **fokus pada yang relevan**? (gak banyak noise)

```
Query: "SYN flood"
Context = [A tentang SYN flood, B tentang ARP spoofing, C tentang DNS tunneling]
→ Precision rendah (2 dari 3 chunk tidak relevan)
```

### 3.4 Menggunakan RAGAS

```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
from datasets import Dataset

# Siapkan data eval
data = {
    "question": ["Apa itu SYN flood?"],
    "answer": ["SYN flood adalah serangan DoS..."],
    "contexts": [["SYN flood adalah serangan...", "Mitigasi SYN flood..."]],
    "ground_truth": ["Serangan DoS dengan mengirim banyak SYN packet..."],
}

dataset = Dataset.from_dict(data)

# Evaluate
results = evaluate(
    dataset,
    metrics=[
        faithfulness,
        answer_relevancy,
        context_precision,
        context_recall,
    ]
)

print(results)
# {'faithfulness': 0.95, 'answer_relevancy': 0.92, ...}
```

---

## 4. Evaluation Dataset

### 4.1 Format Golden Dataset

Buat dataset pertanyaan + jawaban yang benar (ground truth) + dokumen relevan:

```json
[
  {
    "question": "Apa itu TCP 3-way handshake?",
    "ground_truth": "SYN → SYN-ACK → ACK",
    "relevant_docs": ["networking-fundamentals-tcpip-bgp.md"],
    "expected_section": "1.3 TCP Three-Way Handshake"
  },
  {
    "question": "Bagaimana cara kerja SYN cookies?",
    "ground_truth": "Encode info koneksi di sequence number SYN-ACK...",
    "relevant_docs": ["networking-fundamentals-tcpip-bgp.md"],
    "expected_section": "3.2 SYN Cookies"
  }
]
```

### 4.2 Untuk vault-rag

```python
# eval_dataset.json — 10-20 pertanyaan yang cover berbagai catatan vault
EVAL_QUERIES = [
    # Networking
    {"q": "Apa itu TCP handshake?", "file": "networking-fundamentals-tcpip-bgp.md"},
    {"q": "Cara fix SYN flood?", "file": "networking-fundamentals-tcpip-bgp.md"},
    # Windows AD
    {"q": "Apa itu Golden Ticket attack?", "file": "active-directory-windows-security-deepdive.md"},
    {"q": "Cara kerja Kerberoasting?", "file": "active-directory-windows-security-deepdive.md"},
    # Cloud
    {"q": "Apa itu CSPM?", "file": "cloud-security-posture-management.md"},
    {"q": "Cara kerja OPA Gatekeeper?", "file": "cloud-security-posture-management.md"},
    # HTTP
    {"q": "Apa bedanya 301 dan 302 redirect?", "file": "http-protocol-deepdive.md"},
    {"q": "Bagaimana cara kerja HTTP/2 multiplexing?", "file": "http-protocol-deepdive.md"},
    # TLS
    {"q": "Apa itu JA3 fingerprint?", "file": "tls-ssl-deepdive.md"},
    {"q": "Kenapa TLS 1.3 lebih aman dari 1.2?", "file": "tls-ssl-deepdive.md"},
    # Incident Response
    {"q": "Apa itu SANS PICERL?", "file": "incident-response-framework.md"},
    {"q": "Fase apa saja di Incident Response?", "file": "incident-response-framework.md"},
]
```

---

## 5. Automated Testing

### 5.1 CI Pipeline untuk vault-rag

```bash
#!/bin/bash
# .github/workflows/rag-eval.yml (atau cron job)
./vault-rag.sh test                          # Unit test
python3 scripts/eval_rag.py --mode retrieval  # Retrieval metrics
python3 scripts/eval_rag.py --mode generation # RAGAS metrics
```

### 5.2 Retrieval Regression Test

```python
def test_retrieval_regression():
    """Cek apakah perubahan kode menurunkan retrieval quality."""
    from query import query_vault

    results_before = load_baseline("eval/baseline.json")
    results_after = []

    for item in EVAL_QUERIES:
        result = query_vault(item["q"])
        is_relevant = item["file"] in [c["filepath"] for c in result]
        results_after.append(is_relevant)

    recall = sum(results_after) / len(results_after)
    baseline_recall = sum(results_before) / len(results_before)

    if recall < baseline_recall - 0.05:  # toleransi 5%
        raise AssertionError(f"Recall turun: {baseline_recall:.2f} → {recall:.2f}")

    print(f"✅ Recall: {recall:.2f} (baseline: {baseline_recall:.2f})")
```

---

## Koneksi ke Vault

- [[hallucination-mitigation-grounding]] — Faithfulness metric = evaluasi hallucination
- [[advanced-chunking-strategies-deepdive]] — Context precision metric = kualitas chunking
- [[hybrid-search-vector-keyword]] — Recall metric = efektivitas fusion
- `../vault-rag/scripts/mock_test.py` — Test suite vault-rag saat ini (unit test, bukan eval)
- `../vault-rag/scripts/query.py` — Pipeline yang di-evaluate

---

## References

1. RAGAS. _Documentation_. https://docs.ragas.io/
2. DeepEval. _Documentation_. https://docs.confident-ai.com/
3. RAGAS Paper. _S. Es et al. (2023)_. https://arxiv.org/abs/2309.15217
4. ARES. _Automated RAG Evaluation_. https://github.com/lynnjones/ARES
5. TruLens. _RAG Evaluation_. https://www.trulens.org/trulens/evaluation/rag/

> [!tip] Bottom Line
> Evaluasi RAG punya 2 dimensi: **retrieval** (precision, recall, MRR) dan **generation** (faithfulness, relevancy). RAGAS adalah framework paling mature untuk generation metrics. Mulai dengan **10 golden queries** yang cover berbagai catatan vault → hitung recall@5 untuk retrieval → hitung faithfulness untuk generation. Otomatisasi dengan **CI regression test**: kalo recall turun >5%, block deploy. vault-rag belum punya eval pipeline — ini adalah **next step paling penting** setelah chunking dan search berfungsi.
