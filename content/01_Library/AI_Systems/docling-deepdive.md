---
title: '📄 Docling Deep Dive — Unified Document Parser untuk RAG: dari PDF, DOCX, PPTX,
  HTML ke Markdown/JSON Bersih dalam Satu API'
tags:
- docling
- document-parsing
- rag
- ingestion
- ibm-research
- thoughtworks-radar-vol-34
- library
aliases:
- docling-rag-pipeline
- docling-parser-guide
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
---

# 📄 Docling Deep Dive — Unified Document Parser untuk RAG

**dari PDF, DOCX, PPTX, HTML ke Markdown/JSON Bersih dalam Satu API**

> Domain / Tags: `docling` `document-parsing` `rag` `ingestion` `ibm-research` · Status: growing

## Daftar Isi

1. [[#1. Problem / Overview]]
2. [[#2. Core Idea / Arsitektur]]
3. [[#3. Implementation]]
4. [[#4. Comparison / Tradeoff]]
5. [[#5. Deployment / Monitoring]]
6. [[#Referensi]]

---

## 1. Problem / Overview

Dokumen = sumber pengetahuan utama untuk RAG pipeline. Tapi PDF, DOCX, PPTX, HTML menyimpan representasi **visual** data, bukan representasi **semantik**. Apostrophes, multi-column layouts, table of contents, figures with captions, headers/footers, watermark overlay — semuanya bisa dikirim ke LLM sebagai noisy text kalo parser-nya kurang baik.

Pain factual yang sering muncul:

- **PyPDF2 / pypdf** → extract text secara sequence layout, multi-column jadi paragraf yang bertabrakan
- **pdfplumber** → handle tabel, tapi lambat untuk dokumen >100 halaman
- **PyMuPDF (fitz)** → cepat tapi output mentah; perlu post-process untuk structure
- **Unstructured.io** → covers big range, tapi arsitekturnya kompleks (deteksi models, formatter idiomatic)
- **LlamaParse** → pake LLM untuk parsing, mahal per request, rate limit per month
- **Marker** → bagus untuk PDF ke Markdown, tapi no DOCX
- **JINA Reader** (via 9Router Web Fetch, lihat [[document-parsing-for-rag]]) → generic web pages, kurang untuk ilmiah PDF

ThoughtWorks Technology Radar Vol.34 (April 2026) memasukkan **blip #106 Docling** di ring **Trial** karena IBM Research-developed library ini menyediakan unified API untuk lintas format dokumen dengan output kunci: **DoclingDocument** unified representation, yang bisa export ke Markdown, JSON, atau DocTags. Docling cocok untuk pipeline production yang butuh deterministic, open-source, host-yourself-able parsing.

Cross-link ke foundation: [[document-parsing-for-rag]] udah ngobrolin fondasi soal parsing documents; catatan ini adalah komplemen spesifik Docling sebagai tool 2026.

---

## 2. Core Idea / Arsitektur

```
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│   Source            │  │   Source            │  │   Source            │
│   ─ PDF paper       │  │   ─ DOCX report     │  │   ─ HTML page      │
│   ─ PPTX deck       │  │   ─ Image (OCR)     │  │   ─ Medical image   │
└─────────┬──────────┘  └─────────┬──────────┘  └─────────┬──────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                                  ▼
                  ┌──────────────────────────────┐
                  │     Docling Pipeline         │
                  │  - Format detector           │
                  │  - Format-specific reader   │
                  │  - OCR ( jika perlu )       │
                  │  - Layout analysis (TableFormer) │
                  │  - Figure description (vLM) │
                  └──────────────┬──────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │    DoclingDocument (unified) │
                  │  - text + structured items  │
                  │  - hierarchy (sections)     │
                  │  - tables as structured data │
                  │  - figure references         │
                  →  - formulae                 │
                  └──────────────┬──────────────┘
                                 │
                ┌────────────────┼─────────────────┐
                │                │                 │
                ▼                ▼                 ▼
       ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
       │   Markdown   │  │     JSON     │  │   DocTags    │
       │   (untuk LLM │  │  (programma- │  │  (XML-like,  │
       │    context)  │  │  tic consump)│  │   round-trip)│
       └──────────────┘  └──────────────┘  └──────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │  Chunker + Embedder (RAG)   │
                  │  - semantic chunking         │
                  │  - metadata injection       │
                  │  - vector store             │
                  └──────────────────────────────┘
```

**Key concepts Docling:**

1. **`DoclingDocument`** — unified intermediate representation. Bukan hanya plain text; ini pohon semantik: text, headings, list items, table cells, figure refs, formulae.
2. **Format-specific readers** — per format mau satu reader, semua share interface yang sama.
3. **Layout analysis via TableFormer** — IBM model untuk deteksi table layout dari PDF.
4. **Figure understanding via vision LLM** — Docling bisa invoke small VLM untuk describe figures, apalagi docling v2.x with VLM integration.

---

## 3. Implementation

### Install

```bash
# CPU-only (paling simpel)
pip install docling

# GPU acceleration (CUDA; bagus untuk batch besar)
pip install docling[cuda]

# V2 stable (per 2026)
pip install "docling>=2.0"

# Verify
python -c "from docling.document_converter import DocumentConverter; print('ok')"
```

### Basic Usage

```python
from docling.document_converter import DocumentConverter
from pathlib import Path

# Initialize once, reuse for many documents
converter = DocumentConverter()

# Convert PDF ke DoclingDocument then export
result = converter.convert("paper.pdf")
doc = result.document

# Output: Markdown — paling ready untuk LLM context block
md = doc.export_to_markdown()
print(md[:500])

# Output: JSON — programmatic consume downstream
import json
doc_dict = doc.export_to_dict()
json.dumps(doc_dict, indent=2)[:500]

# Output: DocTags — round-trippable intermediate
doctags = doc.export_to_doctags()
```

### OCR Configuration

Untuk PDF scan, Docling invoke OCR underlying library:

```python
from docling.document_converter import DocumentConverter
from docling.datamodel.pipeline_options import PdfPipelineOptions, TesseractCliOcrOptions
from docling.datamodel.ocr_options import TesseractOcrOptions

ocr_opts = TesseractOcrOptions()
pipeline_opts = PdfPipelineOptions(ocr_options=ocr_opts, do_ocr=True)
converter = DocumentConverter(format_options={"pdf": {"pipeline_options": pipeline_opts}})

# Convert scan-only PDF
result = converter.convert("scanned_report.pdf")
md = result.document.export_to_markdown()
```

OCR engines supported:
- `TesseractOcrOptions` (default)
- `EasyOcrOptions` (requires `pip install easyocr`)
- `RapidOcrOcrOptions`
- `OcrMacOptions` (macOS Vision API native)

### Custom Pipeline dengan FormatOption

```python
from docling.document_converter import DocumentConverter, FormatOption
from docling.datamodel.pipeline_options import PdfPipelineOptions

pdf_pipeline = PdfPipelineOptions(
    do_ocr=False,                  # PDF native text, no scan
    do_table_structure=True,       # enable TableFormer
    do_code_enrichment=False,      # skip code block enrichment
    do_formula_enrichment=False,
    generate_picture_images=True   # export figure preview ke output JSON
)

pdf_format = FormatOption(
    pipeline_options=pdf_pipeline,
    pipeline_cls="StandardPdfPipeline"
)

converter = DocumentConverter(
    format_options={"pdf": pdf_format}
)
```

### Batch Processing

```python
from pathlib import Path
from docling.document_converter import DocumentConverter

converter = DocumentConverter()

corpus = Path("papers").glob("*.{pdf,docx,pptx,html}")

for f in corpus:
    result = converter.convert(f)
    md = result.document.export_to_markdown()
    out = Path(f"output/{f.stem}.md")
    out.parent.mkdir(exist_ok=True, parents=True)
    out.write_text(md, encoding="utf-8")
    print(f"✓ {f.name} → {out} ({len(md)} chars)")
```

### Integration ke RAG Pipeline

```python
from docling.document_converter import DocumentConverter
from docling_core.transforms.chunker.hybrid_chunker import HybridChunker
from docling_core.transforms.chunker.hybrid_chunker import ChunkerDoclingDocument

# 1. Parse document → DoclingDocument
converter = DocumentConverter()
doc = converter.convert("spec.pdf").document

# 2. Chunk semantically (Docling-native chunker yang pake DoclingDocument)
chunker = HybridChunker()
chunks = chunker.chunk(doc)

# 3. Embed each chunk
from sentence_transformers import SentenceTransformer
embedder = SentenceTransformer("BAAI/bge-small-en-v1.5")
for c in chunks:
    c.embedding = embedder.encode(c.text)

# 4. Insert ke vector store (kamu pake apa: pgvector, chroma, faiss)
```

Cross-link: [[advanced-chunking-strategies-deepdive]] untuk chunker variants; [[embedding-model-selection-finetuning]] untuk embedder selection.

---

## 4. Comparison / Tradeoff

| Parser | Formats | Tabel support | OCR | License | Hosting cost | Speed | Output structure |
|--------|---------|----------------|-----|--------|---------------|-------|------------------|
| **Docling** | PDF, DOCX, PPTX, HTML, image | Native via TableFormer | Tesseract/Easy/rapid | MIT | Self-host | Moderate | Markdown, JSON, DocTags |
| **Unstructured.io** | Lintas | Native (Unstructured of high+low level) | Tesseract | Apache 2.0 / Commercial | paid cloud OR self-host | Slow (detect models) | Element JSON |
| **LlamaParse** | Lintas, shining PDF | Native (Llama-parse vLM) | Native (vLLM-based) | Proprietary SaaS | $ per page | Fast | Markdown, JSON |
| **PyMuPDF** | PDF only | Native (cell detection diff) | None (text-based PDFs only) | AGPL (GPL) — tough commercial | Self-host | Fastest | Raw text + structured via API |
| **pypdf** | PDF only | None | None | BSD | Self-host | Fast | Plain text |
| **pdfplumber** | PDF only | Good via word/char boxes | None | MIT | Self-host | Slow | Custom via extract_tables() |
| **Marker** | PDF → Markdown | Limited | None | Apache 2.0; GPU heavy | Self-host GPU | Slow on CPU, fast on GPU | Markdown |
| **JINA Reader** | Web (URL any) | HTML only via readability libs | None | Free tier via JINA API (9Router proxy) | Cloud API or @r.jina.ai | Fast | Markdown |

### Kapan pakai Docling?

✅ **Ya pakai, kalau:**
- Pipeline RAG yang butuh format beragam (PDF + DOCX + PPTX)
- Butuh table structure as data (bukan tabel sebagai plain text)
- Self-host wajib (privacy/security: dokumen internal, PHI, PII)
- JSON estructurado supaya bisa diinspect & di-reprocess

❌ **Tidak, kalau:**
- Cuma parsing PDF cepat → PyMuPDF cukup
- cuma extract webpage → JINA Reader (via 9Router `/v1/web/fetch`) langsung markdown
- SaaS acceptable, cost per page > obses → LlamaParse lebih feature-rich
- Project sains heavy academic → marker dapatkana LaTeX/pseudonym math yang bagus

---

## 5. Deployment / Scaling

### CPU vs GPU

Docling **bisa jalan CPU-only**. Pipeline baseline (no VLM, no OCR berat) ~1-3 detik per 10-page PDF di CPU midrange. GPU accelerate:
- OCR: 5-10x lebih cepat
- TableFormer: dukung model inferensiexclusive di GPU
- VLM figure description (Docling v2.x): `pip install docling[vlm]`, butuh CUDA

### Batch Processing Pattern

Untuk corpus 1000+ dokumen:

```bash
# Multi-process via GNU parallel
ls papers/*.pdf | parallel -j 4 \
  "python -c 'from docling.document_converter import DocumentConverter; \
  r=DocumentConverter().convert(\"{}\"); \
  open(\"output/{/.}.md\",\"w\").write(r.document.export_to_markdown())'"
```

Atau pake `concurrent.futures.ProcessPoolExecutor` (lebih control untuk memory).

### Chunking Integration

Docling output → DoclingChunker (native) → embeddings → vector store. Sedangkan kalau pakai langchain chunker, mungkin perlu adaptasi ke Document shape. Catatan chunker terkait di [[advanced-chunking-strategies-deepdive]].

### Monitoring

- **Throughput rate**: <code>converter.convert("/path").seconds</code>, track per format
- **Memory usage**: chunk pipeline dengan `mprof` atau `tracemalloc`
- **Error rate per format**: DOCX sering crash pada docx corrupt, gracefully skip & log
- **OIuv dedup**: hash hasil markdown, skip jika hash sama dengan batch sebelumnya

### Hooked ke RAG Production

```python
from docling.document_converter import DocumentConverter
from docling_core.transforms.chunker.hybrid_chunker import HybridChunker
import hashlib

def parse_and_embed(file_path, embedder, vector_store):
    converter = DocumentConverter()
    result = converter.convert(file_path)
    doc = result.document
    md = doc.export_to_markdown()
    doc_hash = hashlib.sha256(md.encode()).hexdigest()
    
    # Skip if same doc recently indexed
    if vector_store.exists_by_hash(doc_hash):
        return None
    
    chunker = HybridChunker(chunk_size=512, chunk_overlap=64)
    chunks = chunker.chunk(doc)
    
    embeddings = embedder.encode([c.text for c in chunks])
    vector_store.upsert(
        chunks=[c.text for c in chunks],
        embeddings=embeddings,
        metadata=[{
            "source": file_path,
            "doc_hash": doc_hash,
            "chunk_id": i,
            "section": c.meta.get("section", "unknown")
        } for i, c in enumerate(chunks)]
    )
    return doc_hash
```

Cross-link: [[rag-pipeline-end-to-end-guide]] untuk end-to-end pipeline reference; [[rag-data-pipeline-refresh-strategy]] for incremental refresh pattern.

---

## Referensi

1. ThoughtWorks Technology Radar Vol.34 (April 2026) blip #106 Docling (Trial). https://www.thoughtworks.com/radar/languages-and-frameworks/docling
2. ThoughtWorks Radar PDF. https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2026/04/tr_technology_radar_vol_34_en.pdf
3. Docling GitHub Project (IBM Research). https://github.com/DS4SD/docling
4. Docling Documentation. https://ds4sd.github.io/docling/
5. Docling Core (chunker, Document model). https://github.com/DS4SD/docling-core
6. IBM Research Docling announcement blog. https://research.ibm.com/blog/docling
7. TableFormer — IBM's layout analysis model. https://arxiv.org/abs/2206.11539
8. [[document-parsing-for-rag]] — catatan parent fondasi document parsing di vault
9. [[advanced-chunking-strategies-deepdive]] — chunker integration patterns
10. [[rag-pipeline-end-to-end-guide]] — end-to-end RAG pipeline pattern
11. [[embedding-model-selection-finetuning]] — embeder strategy & finetune consideration
12. [[rag-data-pipeline-refresh-strategy]] — incremental refresh pattern
13. PyMuPDF documentation. https://pymupdf.readthedocs.io/
14. Unstructured.io docs. https://unstructured.io/
15. LlamaParse pricing. https://docs.llamaindex.ai/en/stable/api_reference/llama_cloud/llama_parse/llama_parse/
16. Marker — pdf2markdown. https://github.com/VikParuchuri/marker
17. JINA Reader (via 9Router /v1/web/fetch). https://jina.ai/reader/
18. Sentence-Transformers. https://www.sbert.net/
19. HybridChunker Docling Core. https://github.com/DS4SD/docling-core/blob/main/docling_core/transforms/chunker/hybrid_chunker.py
20. Apache Tika (komparator format range). https://tika.apache.org/

---

*Docling deep-dive · unified document parser · IBM Research · v1.0 — July 2026*
