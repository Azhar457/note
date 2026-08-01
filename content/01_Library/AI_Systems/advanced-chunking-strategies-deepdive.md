---
title: "🧩 Advanced Chunking Strategies — Dari Fixed-Size ke Parent-Child: Arsitektur
  Representasi Data untuk RAG Production-Grade"
tags:
  - chunking
  - rag
  - retrieval
  - embedding
  - parent-child
  - structure-aware
  - semantic-chunking
  - library
aliases:
  - chunking-architecture-rag
  - parent-child-chunking
created: "2026-07-16"
updated: "2026-07-16"
status: pending
cssclasses:
  - wide-table
---

# 🧩 Advanced Chunking Strategies — The Architecture of Precision Retrieval

**Dari Fixed-Size ke Parent-Child: Arsitektur Representasi Data untuk RAG Production-Grade**

> Chunking adalah tindakan pertama dan paling fundamental dalam pipeline Retrieval-Augmented Generation (RAG). Ini adalah keputusan arsitektural tentang bagaimana Anda mendefinisikan **unit atomik makna** yang akan di-retrieve. Pilihan yang salah menghasilkan jawaban yang terfragmentasi, kehilangan konteks, atau halusinasi. Pilihan yang tepat menghasilkan retrieval yang presisi, jawaban yang kaya konteks, dan efisiensi komputasi. Dokumen ini membedah spektrum strategi chunking, dari yang naif hingga production-grade, dengan fokus pada arsitektur **Parent-Child Chunking** yang menyelesaikan trade-off fundamental antara presisi pencarian dan kelengkapan konteks.

> [!info] Hubungan ke Vault
> Catatan ini adalah **fondasi teoretis** dari implementasi RAG di project `vault-rag`. Strategi chunking yang dijelaskan di sini diimplementasikan secara konkret di `../vault-rag/scripts/index_vault.py` dengan arsitektur Parent-Child + Structure-Aware untuk vault markdown. Terkait dengan [[ai-engineering-stack-roadmap]] (Fase 2: Data Pipeline & Vector Infrastructure), [[cognitive-architecture-engineering]] (memori hierarkis), dan [[math-and-algorithms]] (cosine similarity untuk semantic chunking).

> [!tip] Implementasi di vault-rag
> Di `scripts/index_vault.py`, chunking sudah menggunakan Structure-Aware Parent-Child:
>
> - **Parent:** H1/H2 section boundaries
> - **Child:** H3/paragraph/sentence dengan CHILD_MAX_CHARS=600
> - **Section path:** heading hierarchy (["Foundation", "Technical Deep-Dive"])
> - **DB:** `parents` table + `chunks` table dengan FK `parent_id`

---

## Daftar Isi

- [[#1. First Principles]]
- [[#2. Spektrum Strategi Chunking]]
- [[#3. Parent-Child Chunking — Production-Grade Architecture]]
- [[#4. Matriks Perbandingan]]
- [[#5. Rekomendasi untuk Vault Ini]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. First Principles: Atom Makna dalam Ruang Vektor

### 1.1 The Semantic Atom Problem

Mengapa chunking begitu sulit? Karena **makna tidak memiliki ukuran yang tetap**. Sebuah kalimat tunggal bisa menjadi atom makna yang sempurna untuk sebuah fakta ("Ibu kota Indonesia adalah Jakarta."), tetapi tidak cukup untuk sebuah argumen atau penjelasan. Sebuah paragraf bisa menangkap sebuah konsep, tetapi bisa juga berisi beberapa ide yang berbeda.

Dalam RAG, kita menghadapi dua kebutuhan yang saling bertentangan:

- **Presisi Pencarian (Search Precision):** Chunk yang kecil dan fokus secara semantik akan menghasilkan kemiripan embedding yang tinggi dengan kueri. Ini meminimalkan noise dan memaksimalkan relevansi.
- **Kelengkapan Konteks (Context Completeness):** Chunk yang terlalu kecil kehilangan konteks sekitarnya, membuat LLM tidak dapat memahami nuansa, anteseden, atau implikasi dari teks yang di-retrieve.

**Parent-Child Chunking** adalah solusi arsitektural untuk kontradiksi ini.

### 1.2 Trade-off Fundamental

```
Presisi                                     Konteks
◄──────────────────────────────────────────────►

  Fixed-Size    Sentence     Semantic   Struct-Aware   Parent-Child
  (rendah)      (rendah)     (sedang)   (tinggi)       (sangat tinggi)
  presisi       konteks      balanced   presisi        presisi +
  tinggi                                      konteks tertinggi
```

| Pendekatan                    | Presisi          | Konteks          | Trade-off                                |
| ----------------------------- | ---------------- | ---------------- | ---------------------------------------- |
| Fixed-Size kecil (100 token)  | 🟢 Tinggi        | 🔴 Rendah        | Dapet fakta tepat tapi gak paham konteks |
| Fixed-Size besar (1000 token) | 🔴 Rendah        | 🟢 Tinggi        | Banyak noise, relevansi rendah           |
| Parent-Child                  | 🟢 Sangat Tinggi | 🟢 Sangat Tinggi | Kompleksitas implementasi naik           |

---

## 2. Spektrum Strategi Chunking

### 2.1 Fixed-Size Chunking — The Naive Baseline

**Filosofi:** "Saya tidak tahu apa-apa tentang data Anda, jadi saya potong rata."

```
Input: [ABCDEFGHIJKLMNOPQRSTUVWXYZ]
        [ABCDE][FGHIJ][KLMNO][PQRST][UVWXY][Z]
```

| Aspek             | Detail                                                                                                                                                                       |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mekanisme**     | Teks dipotong setiap `N` token/karakter, seringkali dengan overlap (`N/10` token)                                                                                            |
| **Keunggulan**    | Paling sederhana. Deterministis, prediktabel, mudah di-debug. Tidak perlu library NLP                                                                                        |
| **Kelemahan**     | **Boundary Problem.** Kalimat terpotong, paragraf terputus, kode terbelah. Informasi terfragmentasi acak. Overlap sedikit membantu tapi gak solve masalah koherensi semantik |
| **Kapan dipakai** | Hanya prototype cepat, atau data homogen pendek (tweet, title)                                                                                                               |

```python
# Paling mentah — potong per karakter
def fixed_size_chunk(text, chunk_size=500, overlap=50):
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

# Lebih cerdas — RecursiveCharacterTextSplitter (LangChain)
from langchain.text_splitter import RecursiveCharacterTextSplitter
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    separators=["\n\n", "\n", ". ", " ", ""]
    # Coba split di double-newline dulu, lalu newline, lalu titik, lalu spasi,
    # baru kalau gak ada pilihan: potong karakter
)
```

### 2.2 Sentence-Based Chunking — The Linguistic Baseline

**Filosofi:** "Kalimat adalah unit linguistik alami. Hormati itu."

| Aspek             | Detail                                                                                                                                                                             |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mekanisme**     | Sentence tokenizer (NLTK, spaCy) → pisah kalimat → grup 5-10 kalimat per chunk                                                                                                     |
| **Keunggulan**    | Gak ada kalimat terpotong. Setiap chunk punya integritas gramatikal                                                                                                                |
| **Kelemahan**     | **Context Collapse.** Kata ganti ("ini", "mereka"), singkatan, referensi implisit bikin kalimat tunggal ambigu. "Ini adalah contoh yang baik" gak berguna tanpa kalimat sebelumnya |
| **Kapan dipakai** | FAQ, chat logs, data QA pendek yang mandiri                                                                                                                                        |

```python
import spacy
nlp = spacy.load("en_core_web_sm")

def sentence_based_chunk(text, max_sentences=5):
    doc = nlp(text)
    sentences = [sent.text for sent in doc.sents]
    chunks = []
    for i in range(0, len(sentences), max_sentences):
        chunks.append(" ".join(sentences[i:i+max_sentences]))
    return chunks
```

### 2.3 Semantic Chunking — The Embedding-Based Approach

**Filosofi:** "Makna adalah tentang koherensi, bukan panjang. Ikuti alur topik."

```
Kalimat:  [A] [B] [C] [D] [E] [F] [G] [H]
Similaritas: 0.95 0.93 0.89 0.45 0.91 0.94 0.88
             └───── Chunk 1 ────┘ └── Chunk 2 ──┘
                        ^ threshold 0.7 — putus di sini
```

| Aspek             | Detail                                                                                                                                                                                              |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mekanisme**     | Embed tiap kalimat → sliding window dengan threshold similaritas → grup kalimat mirip. Kalo similaritas turun drastis = ganti topik = chunk baru                                                    |
| **Keunggulan**    | Chunk koheren secara topik. Adaptif: teks mudah → chunk panjang, teks kompleks → chunk pendek                                                                                                       |
| **Kelemahan**     | **Hyperparameter sensitivity.** Threshold tergantung domain. Terlalu tinggi → over-split (ratusan chunk kecil). Terlalu rendah → under-split (chunk raksasa campur aduk). Gak ada one-size-fits-all |
| **Kapan dipakai** | Dokumen tanpa struktur jelas (transkrip, esai, artikel). Kalo gak bisa andelin struktur Markdown                                                                                                    |

```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

def semantic_chunking(sentences, embeddings, threshold=0.7):
    """
    sentences: list of strings
    embeddings: list of embedding vectors (same order)
    threshold: kalo similaritas < threshold, mulai chunk baru
    """
    chunks = []
    current_chunk = [sentences[0]]

    for i in range(1, len(sentences)):
        sim = cosine_similarity([embeddings[i-1]], [embeddings[i]])[0][0]
        if sim < threshold:
            chunks.append(" ".join(current_chunk))
            current_chunk = [sentences[i]]
        else:
            current_chunk.append(sentences[i])

    if current_chunk:
        chunks.append(" ".join(current_chunk))
    return chunks
```

### 2.4 Structure-Aware Chunking — The Production Baseline

**Filosofi:** "Saya tahu strukturnya (Markdown, HTML, JSON). Gunakan itu sebagai panduan."

| Aspek             | Detail                                                                                                                       |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Mekanisme**     | Parser Markdown → ekstrak judul, sub-judul, paragraf, tabel, kode → chunk dengan hormati batas elemen                        |
| **Keunggulan**    | Untuk vault markdown, ini paling presisi. Heading = ringkasan topik alami. Metadata (judul, heading) bisa disimpan per chunk |
| **Kelemahan**     | **Fragility.** Bergantung kualitas markup. PDF OCR, plain text, HTML kacau gak punya struktur                                |
| **Kapan dipakai** | **Default untuk vault ini.** Setiap .md adalah kanvas sempurna                                                               |

```python
from langchain.text_splitter import MarkdownHeaderTextSplitter

headers_to_split_on = [
    ("##", "H2"),
    ("###", "H3"),
    ("####", "H4"),
]
splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
chunks = splitter.split_text(markdown_text)
# Setiap chunk punya metadata:
# {"H2": "2. Spektrum Strategi Chunking", "H3": "2.1 Fixed-Size"}
```

---

## 3. Parent-Child Chunking — Production-Grade Architecture

**Filosofi:** "Saya butuh presisi pencarian dari chunk kecil, dan kelengkapan konteks dari chunk besar. Saya akan menyimpan keduanya."

Parent-Child bukan teknik tunggal — ini **arsitektur data** dual-layer.

### 3.1 Arsitektur Dual-Layer

```
┌──────────────────────────────────────────────────────────────────┐
│                    LAYER PEMANFAATAN                              │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PARENT LAYER (Konteks — disimpan, TIDAK di-embed)              │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ [## Foundation] [Teks lengkap section Foundation      │       │
│  │  dari awal "TCP three-way..." sampai "sequence n."]  │       │
│  │  id: "p_abc123"                                      │       │
│  └──────────────────────────────────────────────────────┘       │
│                        ▲ ▲ ▲ (dilihat via FK)                     │
│                        │ │ │                                     │
│  CHILD LAYER (Presisi — di-embed + di-search)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ Child 1  │ │ Child 2  │ │ Child 3  │ │ Child 4  │           │
│  │ 140 char │ │ 150 char │ │ 70 char  │ │ 130 char │           │
│  │ parent:  │ │ parent:  │ │ parent:  │ │ parent:  │           │
│  │ p_abc123 │ │ p_abc123 │ │ p_abc123 │ │ p_abc123 │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │             │             │             │               │
│       ▼             ▼             ▼             ▼               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                VECTOR STORE (Embedded)                      │ │
│  │  Query → cosine similarity → Top-3 children                 │ │
│  │         → resolve parent → context utuh                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 Alur Kerja Arsitektural

#### Ingestion Pipeline

```
[Dokumen Markdown]
       │
       ▼
┌─────────────────┐
│   Structure      │
│   -Aware Parser  │  Ekstrak struktur: H2, H3, Paragraf, List
└────────┬────────┘
         │
         ▼
┌────────────────────────────┐
│  Parent-Child Splitter      │
│  • Parent = H1/H2 section   │
│  • Child = pecahan parent   │
│    (H3 → paragraph → sntnc) │
│  • Each child stores        │
│    parent_id as FK          │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│  DB: parents table + chunks table      │
│  • chunks: text, embedding, parent_id  │
│  • parents: id, text (full section)    │
└────────────────────────────────────────┘
```

#### Retrieval Pipeline

```
[Query: "gimana SYN flood bekerja?"]
       │
       ▼
┌──────────────────────┐
│  1. Vector Search     │
│  → Top-5 child chunks  │
│  → Dapet chunk ttg    │
│    "SYN flood attack" │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  2. Resolve Parent    │
│  → child.parent_id    │
│  → SELECT FROM parents│
│  → Dapet FULL section │
│    "Foundation"       │
│    (mencakup SYN      │
│    flood, SYN cookies,│
│    sequence pred.)    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  3. LLM Generation    │
│  Konteks = parent text│
│  (child + context)    │
│  Jawaban LEBIH LENGKAP│
└──────────────────────┘
```

### 3.3 Implementasi di vault-rag

Implementasi konkret ada di `scripts/index_vault.py` dan `scripts/query.py`:

**Indexer — chunking:**

```python
# Parent: H1/H2 section (full text)
parent_boundaries = []
h1h2_positions = [i for i, m in enumerate(headings) if len(m.group(1)) <= 2]

for idx, heading_idx in enumerate(h1h2_positions):
    m = headings[heading_idx]
    start = m.start()
    # End at next H1/H2, or EOF
    if idx + 1 < len(h1h2_positions):
        end = headings[h1h2_positions[idx + 1]].start()
    else:
        end = len(text)
    parent_boundaries.append((start, end, m.group(2).strip()))

# Child: within each parent, split at H3 → paragraph → sentence
# _split_by_headings → _split_by_paragraphs → _split_by_sentences
# CHILD_MAX_CHARS = 600, CHILD_MIN_CHARS = 40
```

**Query — parent context:**

```python
# 1. Search child chunks (dense cosine + BM25 FTS5)
# 2. For each hit, look up parent_id:
SELECT text FROM parents WHERE id = ?

# 3. Attach parent_text to each result
# 4. LLM prompt includes parent_text as full context
```

### 3.4 Kapan Parent-Child Wajib

| Skenario                        | Kenapa Wajib                                   | Contoh                                                                                    |
| ------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Dokumen teknis panjang**      | Konteks section dibutuhkan untuk interpretasi  | Vault note 30KB                                                                           |
| **Pertanyaan multi-hop**        | "Jelaskan hubungan X dan Y" butuh konteks luas | "Apa hubungan SYN flood dan sequence prediction?"                                         |
| **Detil penting untuk akurasi** | Latar belakang diperlukan                      | "Kenapa SYN cookies mengorbankan window scaling?"                                         |
| **Menghindari halusinasi**      | Chunk kecil bikin LLM nebak-nebak              | "Jelaskan cara kerja TCP state machine" — tanpa parent, LLM gak tau ini tentang detection |

---

## 4. Matriks Perbandingan

| Strategi            | Presisi Pencarian    | Kelengkapan Konteks  | Kompleksitas                 | Ketahanan Noise               | Terbaik Untuk           |
| ------------------- | -------------------- | -------------------- | ---------------------------- | ----------------------------- | ----------------------- |
| **Fixed-Size**      | 🔴 Rendah            | 🔴 Rendah            | 🟢 Sangat Rendah             | 🔴 Rendah                     | Prototipe, data homogen |
| **Sentence-Based**  | 🟡 Sedang            | 🔴 Rendah            | 🟢 Rendah                    | 🟡 Sedang                     | FAQ, chat logs          |
| **Semantic**        | 🟢 Tinggi            | 🟡 Sedang            | 🟡 Tinggi (threshold tuning) | 🟢 Tinggi                     | Dokumen tanpa struktur  |
| **Structure-Aware** | 🟢 Tinggi            | 🟢 Tinggi            | 🟡 Sedang                    | 🔴 Rendah (bergantung markup) | **Vault markdown**      |
| **Parent-Child**    | 🟢 **Sangat Tinggi** | 🟢 **Sangat Tinggi** | 🔴 Tinggi                    | 🟢 Tinggi                     | **Production-grade**    |

### Cost Analysis

| Strategi                | Embedding Cost                         | Storage Cost                               | Retrieval Latency                         | Context Quality   |
| ----------------------- | -------------------------------------- | ------------------------------------------ | ----------------------------------------- | ----------------- |
| Fixed-Size (256 token)  | 1x per chunk                           | 1x vector                                  | Rendah                                    | Rendah            |
| Fixed-Size (1024 token) | 1x per chunk                           | 1x vector                                  | Rendah                                    | Sedang            |
| Semantic                | 1x per kalimat + per chunk             | 1x vector per chunk                        | Sedang (ekstra embed)                     | Tinggi            |
| Structure-Aware         | 1x per chunk                           | 1x vector per chunk                        | Rendah                                    | Tinggi            |
| **Parent-Child**        | **1x per child** (parent gak di-embed) | **1x vector per child** (parent cuma text) | **Rendah** (search child → lookup parent) | **Sangat Tinggi** |

> [!tip] Cost Efficiency Parent-Child
> Parent-Child **tidak** menggandakan embedding cost. Hanya child yang di-embed. Parent cuma disimpan sebagai text biasa. Jadi biaya embedding ≈ Structure-Aware dengan chunk_size = CHILD_MAX_CHARS.

---

## 5. Rekomendasi untuk Vault Ini

Berdasarkan analisis struktur vault — semua file markdown dengan heading hierarchy (`## Foundation → ### Technical Deep-Dive → #### Case Studies`):

### Cetak Biru

1. **Parser:** H1/H2 boundaries → **Parent Chunks** (full section context)
2. **Child Splitter:** H3 → paragraph → sentence → **Child Chunks** (~600 chars)
3. **Metadata:** `section_path` (heading hierarchy), `parent_id`, `filepath`, `chunk_index`
4. **Retrieval:** Vector search on children → deduplicate parents → send parent text as context

### Status Implementasi

| Komponen                        | Status                 | Lokasi                                               |
| ------------------------------- | ---------------------- | ---------------------------------------------------- |
| Structure-Aware Parser          | ✅ **Done**            | `scripts/index_vault.py`                             |
| Parent-Child Splitter           | ✅ **Done**            | `scripts/index_vault.py:make_parents_and_children()` |
| DB Schema (parents + chunks)    | ✅ **Done**            | `scripts/index_vault.py:init_db()`                   |
| Parent Context Augmentation     | ✅ **Done**            | `scripts/query.py:augment_with_parent()`             |
| Re-index command                | ✅ **Done**            | `./vault-rag.sh index --reindex`                     |
| FTS5 BM25 on children           | ✅ **Done**            | `scripts/index_vault.py`                             |
| Heading hierarchy metadata      | ✅ **Done**            | `section_path` column                                |
| Semantic Chunking (embed-based) | ❌ **Not implemented** | Fallback ke Structure-Aware sudah cukup untuk vault  |
| LangChain/Qdrant integration    | ❌ **Not implemented** | Pakai sqlite-vec + API sendiri (lebih ringan)        |

---

## Koneksi ke Vault

- `../vault-rag/CLAUDE.md` — Dokumentasi implementasi RAG di vault-rag project
- `../vault-rag/scripts/index_vault.py` — Implementasi konkret parent-child chunking
- [[../vault-rag/scripts/query.py]] — Implementasi parent context augmentation di retrieval
- [[ai-engineering-stack-roadmap]] — Peta jalan: Fase 2 (Data Pipeline & Vector Infrastructure)
- [[cognitive-architecture-engineering]] — Memori hierarkis: child = working memory, parent = long-term memory
- [[math-and-algorithms]] — Cosine similarity di semantic chunking
- [[encoding-serialization-compression-deepdive]] — Representasi data: dari teks ke vektor
- [[http-protocol-deepdive]] — Latency retrieval: HTTP/3 > HTTP/2 > HTTP/1.1 untuk API RAG
- [[linux-fundamentals-deepdive]] — filesystem RAG: parent path, symlink, hardlink

---

## References

1. LangChain. _Text Splitters_. https://python.langchain.com/docs/modules/data_connection/document_transformers/
2. Qdrant. _Parent-Child Document Retrieval_. https://qdrant.tech/articles/parent-child/
3. Pinecone. _Chunking Strategies_. https://www.pinecone.io/learn/chunking-strategies/
4. Anthropic. _Contextual Retrieval_. https://www.anthropic.com/news/contextual-retrieval
5. LlamaIndex. _Node Parser_. https://docs.llamaindex.ai/en/stable/module_guides/loading/node_parsers/
6. UnstructuredIO. _Chunking Strategies_. https://docs.unstructured.io/open-source/core-functionality/chunking
7. Cohere. _Chunking for RAG_. https://docs.cohere.com/docs/chunking-for-rag
8. McInnes, L. et al. _UMAP: Uniform Manifold Approximation and Projection_. 2018. — Fondasi untuk visualisasi embedding chunk.
9. Reimers, N. & Gurevych, I. _Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks_. 2019. — Fondasi sentence embedding untuk semantic chunking.
10. Karpathy, A. _Tokenization in LLMs_. https://github.com/karpathy/minbpe — Prinsip tokenisasi yang memengaruhi chunk_size.
11. sqlite-vec. _Vector Search in SQLite_. https://github.com/asg017/sqlite-vec
12. SQLite FTS5. _Full-Text Search_. https://www.sqlite.org/fts5.html

> [!tip] Bottom Line
> Chunking bukan preprocessing — ini **keputusan arsitektural**. Fixed-size chunking adalah "magic number" yang paling berbahaya di RAG karena memberikan ilusi presisi sambil merusak koherensi semantik. **Parent-Child Chunking** menyelesaikan trade-off fundamental: search di child (presisi tinggi), context dari parent (konteks lengkap). Untuk vault markdown, Structure-Aware (hormati heading) adalah langkah pertama yang wajib. Implementasi di vault-rag sudah menggunakan arsitektur ini — jalankan `./vault-rag.sh index --reindex` untuk mengaktifkannya.
