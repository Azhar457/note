---
title: "Ai Engineering Stack Roadmap"
tags:
  - ai-engineering
  - mlops
  - llmops
  - production-ai
  - inference
  - rag
  - observability
aliases:
  - AI Engineering Stack Deep Dive
  - Production AI Architecture
  - On-Prem AI Infrastructure
created: "2026-05-29"
updated: "2026-07-09"
status: operational
cssclasses:
  - wide-table
---

# 🧠 AI ENGINEERING STACK — The Architecture of Production Reasoning Systems

**Dari Bare-Metal ke Compliance: Sebuah Deep Dive Arsitektur AI Production-Grade**

> [!abstract] Filosofi Fundamental
> Transisi dari _prototype_ ke _production_ dalam AI bukan sekadar "deploy model." Ini adalah transisi dari **aliran probabilistik** ke **sistem deterministik yang mengandung komponen probabilistik**. Sebuah notebook Colab menghasilkan output. Sebuah sistem production menghasilkan **output yang terpercaya, terukur, aman, dan dapat diaudit.** Dokumen ini adalah pembedahan arsitektur setiap lapisan, dari GPU memory hingga EU AI Act compliance, untuk membangun fondasi yang tak tergoyahkan.

---

## 🧬 First Principles: Dari Probabilitas ke Keandalan

Untuk membangun sistem AI production-grade, pahami dulu pergeseran fundamental ini:

1.  **Inferensi Ad-Hoc:** `Prompt -> Model -> Output`. Tidak ada standar, tidak ada jaminan. Ini adalah "mode Colab."
2.  **Inferensi Terstandarisasi:** `Prompt (Versioned) + Schema -> Model (Versioned, Quantized) -> Output (Validated JSON)`. Reproducibility dimulai. Ini adalah fondasi CI/CD.
3.  **Sistem Retrieval:** `Query -> Rewriting -> Retrieval (Vector + BM25) -> Reranking -> Context -> Generation`. Ini adalah fondasi RAG. Akurasi bukan hanya pada model, tapi pada _data_ yang diberikan kepadanya.
4.  **Sistem Agen:** `Goal -> Plan -> Tool Call -> Observation -> Reflection -> Output`. Sistem tidak lagi pasif; ia bertindak dan belajar dari tindakannya.
5.  **Sistem Production:** `[Semua di atas] + Observability + Guardrails + Cost Control + Compliance`. Ini adalah lapisan di mana keandalan, keamanan, dan biaya dikelola secara eksplisit.

---

## 🏗️ Arsitektur Inferensi: Lebih dari Sekadar `model.generate()`

Fondasi dari segalanya adalah bagaimana kita menjalankan model. Ini bukan hanya tentang memanggil API.

### 1. Quantization: Pertukaran Presisi dan Kecepatan

Quantization adalah teknik kompresi model. Tujuannya adalah mengurangi presisi numerik bobot (misal, dari FP16 ke INT4) untuk mengurangi penggunaan memori dan meningkatkan kecepatan inferensi, dengan kehilangan akurasi seminimal mungkin.

**Mekanisme Fundamental:**

- **Weight Quantization:** Bobot model disimpan dalam format presisi lebih rendah.
- **Activation Quantization:** Aktivasi (nilai antara lapisan) juga dikuantisasi.
- **Metode Populer:**
  - **GGUF (GPT-Generated Unified Format):** Format file tunggal yang sangat populer untuk menjalankan LLM di CPU dan GPU konsumen dengan `llama.cpp`. Mendukung berbagai skema kuantisasi (Q4_K_M, Q5_K_M, dll.).
  - **AWQ (Activation-aware Weight Quantization):** Mengidentifikasi "saluran penting" dalam bobot yang sensitif terhadap kuantisasi dan memperlakukannya secara berbeda untuk meminimalkan degradasi akurasi.
  - **GPTQ:** Teknik one-shot weight quantization yang efisien.

**Memilih Format yang Tepat:**

| Format                   | Keunggulan                             | Kelemahan                                       | Use Case                             |
| :----------------------- | :------------------------------------- | :---------------------------------------------- | :----------------------------------- |
| **GGUF**                 | Portabel, CPU-friendly, format tunggal | Lebih lambat di GPU high-end dibanding AWQ/GPTQ | Homelab, edge devices, CPU inference |
| **AWQ**                  | Cepat, efisien di GPU, akurasi baik    | Membutuhkan GPU NVIDIA, tidak untuk CPU         | Server GPU production                |
| **BitsAndBytes (QLoRA)** | Fine-tuning hemat memori               | Bukan untuk inferensi production                | Training/adapter pada VRAM terbatas  |

### 2. KV Cache & PagedAttention: Manajemen Memori Inferensi

Saat LLM menghasilkan teks, ia menghitung ulang _attention_ untuk seluruh sekuens di setiap langkah. Untuk menghindari komputasi ulang ini, _Key_ dan _Value_ state dari langkah sebelumnya disimpan dalam **KV Cache**. Masalahnya: KV Cache untuk sekuens panjang bisa menghabiskan memori GPU.

- **PagedAttention (vLLM):** Memperlakukan KV Cache seperti sistem operasi memperlakukan memori virtual: memecahnya menjadi "blok" (pages) yang bisa dialokasikan di memori GPU yang tidak bersebelahan. Ini menyelesaikan fragmentasi dan memungkinkan _batching_ yang jauh lebih efisien.
- **Continuous Batching:** Alih-alih menunggu seluruh _batch_ selesai, permintaan baru bisa langsung ditambahkan ke batch yang sedang berjalan, meningkatkan throughput secara dramatis.

**Tantangan Utama & Solusi:**

- **Context Window Penuh / OOM:** Saat konteks penuh, KV Cache mengambil sebagian besar memori.
  - _Solusi:_ Gunakan PagedAttention; terapkan `KV Cache Eviction Policy` (hapus blok yang paling jarang diakses); alihkan ke model dengan konteks lebih kecil atau gunakan `Context Compression`.

### 3. API Standardization: Menyembunyikan Kompleksitas

Setiap model memiliki API unik. Lapisan standarisasi sangat penting.

- **OpenAI-Compatible API:** Standar de facto. Tools seperti vLLM, Ollama, dan LiteLLM mengekspos endpoint `/v1/chat/completions` yang identik, memungkinkan aplikasi untuk berganti model tanpa mengubah kode.
- **Streaming (SSE):** Untuk interaksi real-time, model harus mengirimkan token satu per satu menggunakan Server-Sent Events. FastAPI adalah pilihan tepat untuk mengimplementasikan ini.

---

## 🧠 Arsitektur Retrieval-Augmented Generation (RAG)

RAG adalah fondasi untuk memberi LLM akses ke pengetahuan yang tidak dimilikinya. Arsitektur production-grade bukan hanya "tempel dokumen ke prompt."

### 1. Ingestion Pipeline: Dari Dokumen ke Chunk Berkualitas

Kualitas jawaban RAG sangat bergantung pada kualitas data yang dimasukkan.

- **Dokumen Mentah:** PDF, HTML, DOCX, Markdown.
- **Proses Ingestion:**
  1.  **Parsing & Cleaning:** `Unstructured.io` atau `LlamaParse` mengekstrak teks, tabel, dan gambar. Bersihkan header/footer, iklan, dan elemen non-konten.
  2.  **Chunking Strategy (Kritis!):** Ini adalah _secret sauce_. Memecah teks menjadi bagian-bagian kecil.
      - **Fixed-Size Chunking:** `chunk_size=500, chunk_overlap=50`. Sederhana tapi sering memotong kalimat.
      - **Recursive Character Text Splitter:** Memecah berdasarkan hierarki: paragraf, lalu kalimat, lalu kata.
      - **Semantic Chunking:** Menggunakan model embedding untuk mengelompokkan kalimat yang memiliki makna serupa. Lebih lambat, lebih akurat.
      - **Agentic Chunking:** LLM yang "membaca" dokumen dan memutuskan di mana titik pemisahan yang logis.
  3.  **Embedding Generation:** Setiap chunk diubah menjadi vektor numerik (embedding) menggunakan model seperti `text-embedding-3-small` atau `BGE-M3`.
  4.  **Storage:** Vektor disimpan di **Vector Database** seperti Qdrant, Weaviate, atau pgvector. Metadata (sumber, tanggal, judul) disimpan bersamaan.

### 2. Retrieval & Reranking: Menemukan Jarum di Tumpukan Jerami

Ini adalah proses mengambil chunk yang paling relevan untuk kueri pengguna.

- **Hybrid Search:** Tidak bergantung pada satu metode.
  - **Semantic Search (Vector):** Mencari makna. Kueri "cara memasak nasi" akan menemukan dokumen tentang "resep nasi goreng". Bagus untuk recall.
  - **Keyword Search (BM25, SPLADE):** Mencari kata kunci spesifik. Kueri "UU ITE Pasal 27" akan mencari dokumen yang mengandung persis string itu. Bagus untuk precision.
  - **Hybrid = Hasil gabungan dari kedua metode**, di-fusion menjadi satu daftar kandidat.
- **Reranking:**
  - **Cross-Encoder:** Model seperti `Cohere Rerank` atau `BGE Reranker` mengambil kueri dan setiap chunk kandidat, lalu memberikan skor relevansi yang sangat akurat. Ini lebih lambat dari embedding similarity, jadi hanya diterapkan pada 10-50 kandidat teratas dari hybrid search.
  - **Dampak:** Reranking secara dramatis meningkatkan `precision@K`. Chunk yang paling relevan masuk ke context window, mengurangi noise.

### 3. Query Rewriting: Memperbaiki Pertanyaan Sebelum Pencarian

Pengguna jarang bertanya dengan sempurna.

- **Multi-Query Retrieval:** LLM menghasilkan beberapa variasi pertanyaan dari kueri pengguna. Semua variasi digunakan untuk mencari dokumen, dan hasilnya digabungkan.
- **Step-back Prompting:** Untuk pertanyaan spesifik, LLM menghasilkan "pertanyaan mundur" yang lebih umum untuk memberikan konteks yang lebih luas. Contoh: "Siapa aktor utama di Inception?" -> "Apa film Inception?" (konteks) + "Pemeran film Inception" (spesifik).
- **HyDE (Hypothetical Document Embeddings):** LLM menghasilkan dokumen hipotetis yang akan menjawab kueri. Dokumen ini di-embedding, dan pencarian dilakukan bukan pada kueri, tapi pada embedding _dokumen hipotetis_ tersebut. Ini jembatan antara domain kueri dan domain dokumen.

---

## 🔄 Arsitektur Agen: Otonomi yang Terkendali

Sistem agen adalah tentang memberi AI akses ke _tools_. Agen production berbeda dari demo karena ia harus deterministik dalam ketidakpastiannya.

### State Machine vs. Free-Will Agent

- **Free-Will Agent (Contoh: AutoGPT):** LLM memutuskan sendiri langkah selanjutnya dan kapan harus berhenti. Ini sangat tidak dapat diandalkan dan rawan infinite loop.
- **Deterministic State Machine (Contoh: `LangGraph`):** Alur agen didefinisikan sebagai _graph_ (graf).
  - **Nodes:** Langkah-langkah konkret: `plan_task`, `execute_tool`, `evaluate_result`.
  - **Edges:** Transisi deterministik antar node. `IF tool_call_success THEN summarize_result. IF tool_call_failed THEN retry_or_escalate`.
  - **Checkpoints:** State graf disimpan di setiap langkah, memungkinkan _resume_ dari kegagalan, _rollback_, atau _human-in-the-loop_ untuk menyetujui langkah berikutnya.

Ini adalah perbedaan antara **rekayasa perangkat lunak** (state machine) dan **berdoa** (free-will agent).

---

## 📊 MLOps: Menyuntikkan Rekayasa Perangkat Lunak ke AI

MLOps adalah praktik rekayasa perangkat lunak yang diterapkan pada sistem AI. Tanpanya, Anda tidak memiliki production, Anda hanya memiliki skrip.

### Trinitas Reproducibility: Kode, Data, Model

1.  **Kode (Git):** Semua kode, termasuk prompt, pipeline, dan konfigurasi, di-version control.
2.  **Data (DVC - Data Version Control):** DVC melacak versi dataset, embedding, dan model. Ia menyimpan metadata di Git dan data aktual di penyimpanan (S3, GCS, lokal). `dvc repro` akan menjalankan ulang seluruh pipeline dari data mentah hingga model terlatih, memastikan reproducibility penuh.
3.  **Model & Experiment (MLflow):**
    - **Experiment Tracking:** Mencatat semua parameter (chunk size, top-K), metrik (recall, hallucination score), dan artefak (model, plot) untuk setiap eksperimen.
    - **Model Registry:** Mengelola versi model yang siap di-deploy. Memungkinkan staging (staging, production, archived) dan rollback.

### CI/CD untuk AI (CI/CE/CT)

- **Continuous Integration (CI):** Setiap PR memicu evaluasi otomatis (Ragas, DeepEval). `eval_accuracy.py`, `eval_safety.py`.
- **Continuous Evaluation (CE):** Di production, model dievaluasi secara berkala terhadap data baru untuk mendeteksi _drift_ (perubahan distribusi data input) atau degradasi kualitas.
- **Continuous Training (CT) (Opsional):** Pipeline untuk melatih ulang atau mem-fine-tune model secara otomatis ketika data baru tersedia.

---

## 🛡️ Keamanan, Observabilitas, & Kepatuhan (Trinitas Kedua)

### 1. Observabilitas: Melihat ke Dalam "Pikiran" Mesin

LLM adalah black box probabilistik. Observabilitas adalah satu-satunya cara untuk memahami perilakunya.

- **Traces (Langfuse, OpenLLMetry):** Setiap panggilan LLM adalah "trace" yang berisi semua langkah: query rewriting, retrieval, prompt akhir, token yang dihasilkan, dan latensi.
- **Metrics:** `Hallucination Score`, `Faithfulness`, `Answer Relevancy` adalah metrik kualitas. `Time To First Token (TTFT)`, `Inter-Token Latency`, `Tokens per Second` adalah metrik kinerja.
- **Debugging:** Saat pengguna mengeluh, Anda bisa mencari trace spesifik, melihat prompt dan dokumen yang diambil, dan memahami _mengapa_ model menjawab seperti itu.

### 2. Keamanan (AI Firewall)

Ini adalah lapisan "Web Application Firewall untuk AI."

- **Guardrails (NeMo Guardrails, Guardrails AI):** Sebuah proxy di antara pengguna dan LLM.
  - **Input Rail:** Memvalidasi input pengguna. Deteksi prompt injection, jailbreak, konten berbahaya.
  - **Output Rail:** Memvalidasi output model. Deteksi kebocoran PII, konten berbahaya, halusinasi faktual (verifikasi dengan RAG).
  - **Dialog Rail:** Mengontrol alur percakapan. Contoh: "Jika topik adalah self-harm, eskalasi ke human."
- **Automated Red Teaming (Garak, PyRIT):** Sebelum deploy, jalankan ribuan prompt serangan otomatis terhadap model Anda untuk menemukan kerentanan. Ini adalah penetrasi testing untuk LLM.

### 3. Kepatuhan (AI Governance)

Dengan regulasi seperti EU AI Act, kepatuhan adalah persyaratan, bukan pilihan.

- **NIST AI RMF (Risk Management Framework):** Framework dari NIST untuk mengelola risiko AI. Empat fungsi: Map (petakan konteks), Measure (ukur risiko), Manage (kelola risiko), Govern (atur tata kelola).
- **EU AI Act:** Mengklasifikasikan aplikasi AI berdasarkan risiko (unacceptable, high, limited, minimal). Aplikasi high-risk (misal, di HR, penegakan hukum) memiliki persyaratan ketat untuk data, dokumentasi, transparansi, dan pengawasan manusia.
- **Audit Trail:** Simpan log dari setiap prediksi, termasuk input, output, dan reasoning, untuk memungkinkan audit di masa mendatang. Arsitektur Anda harus _auditable by design_.

---

## 💎 Kesimpulan: Piramida Kematangan Produksi AI

| Level               | Kemampuan               | Prinsip Kunci                     | Teknologi                    |
| ------------------- | ----------------------- | --------------------------------- | ---------------------------- |
| **1: Ad-Hoc**       | Inferensi Tunggal       | Probabilistik, Tidak Reproducible | Notebook, API Call           |
| **2: Reproducible** | Serving + Versioning    | Deterministik di Pipeline         | Docker, DVC, Git             |
| **3: Augmented**    | RAG + Tool Use          | Grounding di Data Eksternal       | Vector DB, LangChain         |
| **4: Autonomous**   | Multi-Agent             | Otonomi Terkendali                | LangGraph, State Machines    |
| **5: Observable**   | Monitoring + Evaluation | Terukur dan Terlihat              | Langfuse, Ragas              |
| **6: Trustworthy**  | Security + Compliance   | Aman, Terpercaya, Auditable       | NeMo Guardrails, NIST AI RMF |

Membangun sistem AI production-grade adalah upaya rekayasa. Ini tentang mengubah model probabilistik yang buram menjadi produk yang transparan, andal, dan aman dengan menerapkan prinsip-prinsip rekayasa perangkat lunak yang ketat di setiap lapisan.
