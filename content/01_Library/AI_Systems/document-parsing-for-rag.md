---
title: "📄 Document Parsing for RAG — The Art of Extracting Clean Text: Dari PDF, HTML, Word ke Teks Bersih"
tags:
  - document-parsing
  - rag
  - ingestion
  - unstructured-io
  - llamaparse
  - library
aliases:
  - "document-parsing-for-rag-deepdive"
  - "ingestion-pipeline-rag"
  - "pdf-parsing-for-rag"
created: "2026-07-16"
updated: "2026-07-16"
status: operational
cssclasses:
  - wide-table
---

# 📄 Document Parsing for RAG — The Art of Extracting Clean Text

**Dari PDF, HTML, Word ke Teks Bersih: Fondasi Pipeline Ingestion**

> Dokumen adalah lumbung pengetahuan. Tapi sebelum LLM bisa membacanya, Anda harus mengubahnya menjadi teks bersih. Parsing bukan sekadar "membuka file." Ia adalah seni mengekstrak struktur semantik dari representasi visual yang kacau. PDF dengan tabel, gambar, dan multi-kolom. HTML dengan JavaScript dan iklan. Word dengan track changes. Dokumen ini membedah arsitektur parsing modern, dari Unstructured.io hingga LlamaParse, dengan implementasi kode production-ready untuk setiap format.

> [!info] Hubungan ke Vault
> Nota ini adalah **pintu masuk data eksternal** ke vault. Output parser (teks markdown terstruktur) adalah input untuk [[advanced-chunking-strategies-deepdive]] (parent-child chunking). Terkait dengan [[ai-engineering-stack-roadmap]] (Fase 2: Data Pipeline), [[encoding-serialization-compression-deepdive]] (encoding charset), dan [[linux-fundamentals-deepdive]] (filesystem path, encoding locales).

---

## Daftar Isi

- [[#1. First Principles]]
- [[#2. Arsitektur Pipeline Parsing]]
- [[#3. Implementasi per Format]]
- [[#4. Cleaning & Normalization]]
- [[#5. Perbandingan Tools]]
- [[#6. Rekomendasi untuk Vault Ini]]
- [[#Roadmap Ingestion]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. First Principles: Mengapa Parsing Sulit?

### 1.1 The Visual-Textual Gap

Dokumen digital, terutama PDF, dirancang untuk **tampilan visual yang konsisten**, bukan untuk ekstraksi teks. Teks bisa tersimpan sebagai karakter individual dengan koordinat absolut, bukan sebagai paragraf yang mengalir. Sebuah tabel mungkin bukan "tabel" dalam kode, melainkan serangkaian kotak teks yang diposisikan secara visual agar terlihat seperti tabel bagi mata manusia.

**Masalah fundamental:**

- **Urutan Membaca:** Teks multi-kolom bisa terbaca sebagai satu baris yang melompat dari kolom kiri ke kanan
- **Header/Footer:** Nomor halaman, judul bab berulang, dan catatan kaki ikut terekstrak sebagai teks yang tidak relevan
- **Tabel:** Data tabular kehilangan strukturnya dan menjadi teks yang tidak koheren
- **Gambar & Grafik:** Informasi di dalam gambar (diagram, flowchart) hilang sama sekali

### 1.2 Spektrum Format Dokumen

| Format                  | Kompleksitas     | Tools Utama                                | Skenario Vault                        |
| ----------------------- | ---------------- | ------------------------------------------ | ------------------------------------- |
| **Markdown**            | 🟢 Sangat Rendah | `MarkdownHeaderTextSplitter`               | Dokumen vault sendiri (sudah optimal) |
| **HTML**                | 🟡 Rendah-Sedang | `BeautifulSoup`, `Unstructured`            | Web scraping, arsip blog              |
| **Word (DOCX)**         | 🟡 Sedang        | `python-docx`, `Unstructured`              | Laporan internal, whitepaper          |
| **PDF (Digital)**       | 🔴 Tinggi        | `PyMuPDF`, `pdfplumber`                    | Paper akademik, laporan resmi         |
| **PDF (Scanned/OCR)**   | 🔴 Sangat Tinggi | `Tesseract`, `Azure Document Intelligence` | Dokumen historis, faks                |
| **Gambar (Screenshot)** | 🔴 Sangat Tinggi | `LlamaParse`, GPT-4V                       | Infografis, slide presentasi          |

---

## 2. Arsitektur Pipeline Parsing

Pipeline parsing yang tangguh tidak bergantung pada satu alat. Ia adalah **rantai pemrosesan bertingkat** yang menangani berbagai format dan kualitas dokumen.

```
┌──────────────────────────────────────────────────────────────┐
│                   DOCUMENT PARSING PIPELINE                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  [Input File]                                                 │
│       │                                                       │
│       ▼                                                       │
│  ┌────────────────────┐                                       │
│  │ DETECTOR           │  Identifikasi tipe file               │
│  │ (MIME/Magic bytes) │  (PDF, DOCX, HTML, MD, Gambar)       │
│  └─────────┬──────────┘                                       │
│            │                                                   │
│      ┌─────┼──────┬──────────┬───────────┐                    │
│      ▼     ▼      ▼          ▼           ▼                    │
│   [PDF]  [DOCX] [HTML]   [Markdown]  [Image]                 │
│      │     │      │          │           │                    │
│      ▼     ▼      ▼          ▼           ▼                    │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ EXTRACTION LAYER (Format-Specific Parsers)            │    │
│  │ • PyMuPDF (fitz) → PDF digital                        │    │
│  │ • pdfplumber → tabel dalam PDF                        │    │
│  │ • Tesseract → OCR untuk PDF scan                      │    │
│  │ • python-docx → DOCX                                  │    │
│  │ • BeautifulSoup / Trafilatura → HTML                  │    │
│  │ • LlamaParse / GPT-4V → gambar kompleks               │    │
│  └───────────────────────────┬───────────────────────────┘    │
│                              │                                 │
│                              ▼                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ CLEANING & NORMALIZATION                               │    │
│  │ • Hapus header/footer berulang                         │    │
│  │ • Normalisasi whitespace & encoding                    │    │
│  │ • Deteksi dan perbaiki urutan baca (multi-kolom)       │    │
│  │ • Ekstrak metadata (judul, penulis, tanggal)           │    │
│  └───────────────────────────┬───────────────────────────┘    │
│                              │                                 │
│                              ▼                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ STRUCTURE PRESERVATION                                 │    │
│  │ • Tandai heading (H1, H2, H3)                          │    │
│  │ • Tandai paragraf, list, tabel, kode                   │    │
│  │ • Output: Markdown terstruktur                         │    │
│  └───────────────────────────┬───────────────────────────┘    │
│                              │                                 │
│                              ▼                                 │
│  [Clean Structured Text] → Siap untuk Chunking               │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Implementasi per Format

### 3.1 PDF Digital — PyMuPDF (fitz)

```python
import fitz  # PyMuPDF

def parse_pdf_digital(file_path: str) -> str:
    doc = fitz.open(file_path)
    full_text = []

    for page_num, page in enumerate(doc):
        text = page.get_text("text", sort=True)
        tables = page.find_tables()
        if tables:
            for table in tables:
                text += f"\n\n{table.to_markdown()}"
        full_text.append(f"[Page {page_num + 1}]\n{text}")

    doc.close()
    return "\n\n".join(full_text)
```

### 3.2 PDF Scanned (OCR) — Tesseract

```python
import pytesseract
from pdf2image import convert_from_path

def parse_pdf_scanned(file_path: str) -> str:
    images = convert_from_path(file_path, dpi=300)
    full_text = []
    for i, image in enumerate(images):
        text = pytesseract.image_to_string(image, lang="eng+ind")
        full_text.append(f"[Page {i + 1}]\n{text}")
    return "\n\n".join(full_text)
```

### 3.3 DOCX — python-docx

```python
from docx import Document

def parse_docx(file_path: str) -> str:
    doc = Document(file_path)
    full_text = []
    for para in doc.paragraphs:
        if para.style.name.startswith("Heading"):
            level = para.style.name.split()[-1]
            full_text.append(f"{'#' * int(level)} {para.text}")
        else:
            full_text.append(para.text)
    for table in doc.tables:
        for row in table.rows:
            full_text.append(" | ".join(cell.text for cell in row.cells))
    return "\n\n".join(full_text)
```

### 3.4 HTML — Trafilatura

```python
import trafilatura

def parse_html(url: str) -> str:
    downloaded = trafilatura.fetch_url(url)
    return trafilatura.extract(downloaded, output_format="markdown")
```

### 3.5 Universal Parser — Unstructured.io

```python
from unstructured.partition.auto import partition

def parse_universal(file_path: str) -> list[dict]:
    elements = partition(filename=file_path)
    return [{
        "type": el.category,
        "text": el.text,
        "metadata": el.metadata.to_dict() if el.metadata else {},
    } for el in elements]
```

### 3.6 AI-Powered — LlamaParse

```python
import nest_asyncio
from llama_parse import LlamaParse
nest_asyncio.apply()

def parse_with_ai(file_path: str, api_key: str) -> str:
    parser = LlamaParse(api_key=api_key, result_type="markdown", num_workers=4)
    documents = parser.load_data(file_path)
    return "\n\n".join([doc.text for doc in documents])
```

---

## 4. Cleaning & Normalization

```python
import re

def clean_extracted_text(text: str) -> str:
    lines = text.split("\n")
    # Hapus header/footer berulang (>30% halaman)
    line_counts = {}
    for line in lines:
        line_counts[line] = line_counts.get(line, 0) + 1
    cleaned = [l for l in lines if line_counts[l] < len(lines) * 0.3]

    text = "\n".join(cleaned)
    text = re.sub(r'\n{3,}', '\n\n', text)     # max 2 consecutive newlines
    text = re.sub(r'[ \t]+', ' ', text)         # normalize spaces
    text = text.encode("utf-8", errors="ignore").decode("utf-8")
    text = re.sub(r'[^\x20-\x7E\n]', '', text)  # non-printable
    return text.strip()
```

---

## 5. Perbandingan Tools

| Tool                     | Format Terbaik   | Keunggulan                          | Kelemahan             | Biaya           |
| ------------------------ | ---------------- | ----------------------------------- | --------------------- | --------------- |
| **PyMuPDF (fitz)**       | PDF digital      | 🟢 Cepat, akurat, open-source       | 🔴 Tidak bisa OCR     | 🟢 Gratis       |
| **pdfplumber**           | PDF + tabel      | 🟢 Ekstraksi tabel sangat baik      | 🟡 Lebih lambat       | 🟢 Gratis       |
| **Tesseract**            | PDF scan, gambar | 🟢 OCR gratis, banyak bahasa        | 🟡 Akurasi bervariasi | 🟢 Gratis       |
| **Unstructured.io**      | Semua format     | 🟢 Universal, output terstruktur    | 🟡 Setup kompleks     | 🟢 Gratis (OSS) |
| **LlamaParse**           | Semua kompleks   | 🟢 AI-powered, paham konteks visual | 🔴 Biaya API, latency | 🔴 Berbayar     |
| **Azure Document Intel** | Form, invoice    | 🟢 Akurasi tinggi, cloud-native     | 🔴 Vendor lock-in     | 🔴 Berbayar     |

---

## 6. Rekomendasi untuk Vault Ini

Karena vault mayoritas file Markdown (sudah bersih), fokus parsing adalah **data eksternal**:

1. **Unstructured.io** sebagai default parser — 20+ format, output terstruktur
2. **PyMuPDF + pdfplumber** untuk paper akademik (PDF digital)
3. **LlamaParse** untuk dokumen scan/historis — biaya sepadan akurasi
4. **Simpan hasil sebagai Markdown** → langsung diproses Structure-Aware chunking vault

### Roadmap Ingestion

| Phase            | Kemampuan                             | Tools                                               |
| ---------------- | ------------------------------------- | --------------------------------------------------- |
| **1** (sekarang) | Vault markdown → Chunking → Vector DB | `index_vault.py`                                    |
| **2**            | + PDF ingestion                       | PyMuPDF → Markdown → pipeline existing              |
| **3**            | + Web scraping                        | Trafilatura → Markdown → pipeline existing          |
| **4**            | + DOCX/XLSX                           | Unstructured → Markdown → pipeline existing         |
| **5**            | + OCR pipeline                        | Tesseract/LlamaParse → Markdown → pipeline existing |

---

## Koneksi ke Vault

- [[advanced-chunking-strategies-deepdive]] — Output parser jadi input chunking. Kualitas chunking tergantung kualitas parsing
- [[ai-engineering-stack-roadmap]] — Fase 2: Data Pipeline & Vector Infrastructure dimulai dari parsing
- [[encoding-serialization-compression-deepdive]] — Encoding charset, base64, charset detection
- [[linux-fundamentals-deepdive]] — Filesystem path, file permissions buat pipeline ingestion
- `../vault-rag/scripts/index_vault.py` — Implementasi chunking yang nerima output parser

---

## References

1. PyMuPDF. https://pymupdf.readthedocs.io/
2. pdfplumber. https://github.com/jsvine/pdfplumber
3. Tesseract OCR. https://github.com/tesseract-ocr/tesseract
4. Unstructured.io. https://docs.unstructured.io/
5. LlamaParse. https://docs.llamaindex.ai/en/stable/llama_cloud/llama_parse/
6. Trafilatura. https://trafilatura.readthedocs.io/
7. python-docx. https://python-docx.readthedocs.io/
8. Azure Document Intelligence. https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/

> [!tip] Bottom Line
> Parsing adalah "first mile" RAG — kualitas output menentukan kualitas semua langkah berikutnya. PDF digital dan Markdown relatif mudah; PDF scan dan HTML kompleks butuh tool khusus. Strategi vault: **Unstructured.io untuk universal**, **PyMuPDF untuk PDF digital**, **LlamaParse untuk yang kompleks**. Simpan hasil sebagai Markdown supaya langsung bisa diproses Structure-Aware chunking vault.
