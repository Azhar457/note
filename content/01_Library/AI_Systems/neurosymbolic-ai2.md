---
title: "Neurosymbolic AI — Knowledge Graph + LLM, Causal AI & Explainable AI"
tags:
  - neurosymbolic
  - knowledge-graph
  - graphrag
  - causal-ai
  - xai
  - explainable-ai
  - hybrid-ai
aliases:
  - Neurosymbolic AI Deep Dive
  - GraphRAG Architecture
  - Causal AI Framework
  - Explainable AI Techniques
  - Neuro-Symbolic Integration
created: 2026-07-14
updated: 2026-07-14
status: evergreen
cssclasses:
  - wide-table
---
# 🧿 NEUROSYMBOLIC AI — Arsitektur Kognitif yang Melampaui Pola

**Dari Pattern Recognition ke Machine Reasoning: Sebuah Sintesis Epistemologis**

> [!abstract] Melampaui Dikotomi Pikiran dan Logika
> Neural network adalah empu pengenalan pola—ia merasakan dunia melalui data. Symbolic AI adalah empu penalaran—ia memanipulasi konsep melalui aturan. Neurosymbolic AI bukanlah kompromi di antara keduanya, melainkan **lompatan kualitatif** menuju sistem yang mampu memahami (reason) tentang apa yang ia rasakan (perceive). Dokumen ini adalah peta arsitektur untuk pernikahan itu, dari GraphRAG yang siap produksi hingga Causal AI yang masih menjadi frontier. Ini adalah fondasi untuk AI yang tidak hanya pintar, tetapi juga bijaksana.

---

## 🧬 1. First Principles: Dua Jiwa dalam Satu Mesin

Untuk memahami neurosymbolic, kita harus menyelami akar epistemologis dari dua paradigma yang telah lama berseteru.

### 1.1 The Binding Problem: Mengapa Pola Saja Tidak Cukup

Seekor kucing melompat ke atas meja. Otak Anda langsung mengikat berbagai properti—"kucing", "melompat", "meja", "di atas"—menjadi satu kesatuan pemahaman yang koheren. Dalam AI, ini disebut **The Binding Problem**: bagaimana kita mengikat representasi terdistribusi (fitur-fitur dalam vektor) menjadi konsep simbolik yang diskrit dan relasi di antaranya?

- **Neural (Koneksionis):** Representasi tersebar di seluruh bobot jaringan. Tidak ada "simbol kucing" yang tunggal. Ini membuat generalisasi fleksibel tetapi reasoning terstruktur menjadi sangat sulit.
- **Symbolic (Klasik):** Representasi bersifat atomik dan terlokalisasi. `Kucing(Simba)`, `DiAtas(Simba, Meja)`. Reasoning menjadi mudah dengan logika formal, tetapi sistem menjadi rapuh terhadap noise dan tidak dapat belajar dari data mentah.
- **Neurosymbolic (Solusi):** Menciptakan jembatan di mana representasi terdistribusi (neural) dapat memunculkan dan memanipulasi simbol (symbolic) secara dinamis. Ini adalah fondasi dari **Cognitive Architecture** yang sesungguhnya.

### 1.2 Spektrum Penalaran: Dari Sistem 1 ke Sistem 2

Dalam konteks vault Anda, terutama **[[test-time-compute-system2]]**, neurosymbolic AI adalah implementasi arsitektural dari **Sistem 2**.

| Mode Kognitif | Arsitektur AI | Implementasi |
| :--- | :--- | :--- |
| **Sistem 1 (Cepat, Refleks)** | Neural Murni | LLM, CNN, Deteksi Anomali. `Input -> Output`. |
| **Sistem 2 (Lambat, Analitis)** | **Neurosymbolic** | **GraphRAG, Causal AI, XAI.** `Input -> Representasi Simbolik -> Reasoning -> Output`. |

Neurosymbolic AI menyediakan **mesin reasoning** yang dapat dipanggil oleh agen (seperti dalam **[[agentic-ai-mcp-architecture-deepdive]]**) untuk memvalidasi intuisi neural, merencanakan tindakan, dan menjelaskan keputusan.

---

## 🔩 2. GraphRAG — Tulang Punggung Memori Terstruktur Agen

GraphRAG adalah titik masuk paling pragmatis ke dunia neurosymbolic. Ia bukan sekadar RAG dengan graf; ia adalah **Spatial Memory untuk Agen AI**. Jika RAG standar adalah "tumpukan buku", GraphRAG adalah "peta dunia".

### 2.1 Dari Teks ke Dunia: Proses Konstruksi Kognitif

Proses membangun GraphRAG adalah tindakan **memahami** itu sendiri.

1.  **Perception (Neural):** LLM membaca korpus dokumen. Ia tidak hanya melihat teks, tetapi juga *entitas* (orang, tempat, organisasi) dan *relasi* (bekerja di, mendanai, menyerang). Ini adalah proses ekstraksi informasi tingkat tinggi.
2.  **Binding (Neurosymbolic):** Entitas dan relasi ini tidak dibiarkan sebagai anotasi. Mereka **diikat** menjadi sebuah struktur data yang persisten: Knowledge Graph. Sebuah simpul `Person_A` terhubung ke simpul `Organization_B` melalui edge `works_at`. Struktur ini adalah *memori jangka panjang* yang terstruktur.
3.  **Reasoning (Symbolic):** Ketika kueri diajukan, sistem tidak hanya mencari kemiripan vektor. Ia melakukan **graph traversal**—sebuah proses logis. "Cari semua orang yang bekerja di perusahaan yang didanai oleh `Venture_Capital_X`". Ini adalah kueri multi-hop yang membutuhkan struktur, bukan hanya statistik.

### 2.2 Implementasi Agen yang Sadar Konteks

GraphRAG adalah fondasi yang sempurna untuk **Agentic Intelligence**. Sebuah agen keamanan siber tidak bisa hanya "mengingat" potongan teks; ia harus mengingat **hubungan**.

```python
# Agen Security Analyst dengan GraphRAG Memory
class SecurityAnalystAgent:
    def __init__(self, kg: Neo4jGraph, llm):
        self.kg = kg          # Memori Spasial (Symbolic)
        self.llm = llm        # Mesin Penalaran (Neural)
    
    def investigate_alert(self, alert):
        # 1. NEURAL: Ekstrak entitas kunci dari alert mentah menggunakan LLM
        entities = self.llm.extract_entities(alert)
        target_ip = entities.get("source_ip")

        # 2. SYMBOLIC: Lakukan graph traversal untuk mencari konteks
        context_graph = self.kg.query("""
            MATCH (ip:IP {address: $target_ip})
            MATCH (ip)-[r]-(connected)
            RETURN ip, r, connected
        """, params={"target_ip": target_ip})

        # 3. NEUROSYMBOLIC: Berikan konteks terstruktur ke LLM untuk penalaran akhir
        reasoning_prompt = f"""
        Sebuah alert terpicu dari IP {target_ip}.
        Konteks dari Knowledge Graph: {context_graph}
        Apakah ini positif palsu, eskalasi, atau insiden kritis? Jelaskan reasoningmu.
        """
        decision = self.llm.generate(reasoning_prompt)
        return decision
```
**Koneksi Vault:** Pola ini adalah spesialisasi dari loop **ReAct** di **[[agentic-ai-mcp-roadmap]]**. `kg.query` adalah sebuah "tool" yang memberikan agen kemampuan reasoning simbolik.

---

## ⚔️ 3. Causal AI — Melampaui "Apa" Menuju "Mengapa"

Jika GraphRAG adalah memori, Causal AI adalah **kemampuan untuk membayangkan dunia alternatif**. Ini adalah lompatan dari *curve-fitting* ke *world-modeling*.

### 3.1 Tangga Kausalitas Pearl: Peta Menuju Kebijaksanaan

Model ML tradisional (termasuk sebagian besar LLM) berada di anak tangga pertama. Mereka menjawab "Apa yang akan terjadi?" berdasarkan asosiasi. Causal AI menaiki tangga ini.

1.  **Asosiasi (Level 1):** `P(sembuh | minum_obat)`. ML klasik. "Pasien yang minum obat lebih sering sembuh." (Tapi bagaimana jika pasien yang minum obat memang lebih sehat?)
2.  **Intervensi (Level 2):** `P(sembuh | do(minum_obat))`. Causal Inference. "Jika SAYA MEMAKSA semua orang minum obat, berapa tingkat kesembuhannya?" Ini adalah hasil dari *eksperimen* atau analisis kausal yang ketat.
3.  **Kontrafaktual (Level 3):** `P(sembuh_tanpa_obat | minum_obat, sembuh)`. Causal Reasoning. "Pasien ini sembuh setelah minum obat. Apakah ia akan tetap sembuh jika TIDAK minum obat?" Ini adalah fondasi dari atribusi, tanggung jawab, dan keadilan.

### 3.2 Neurosymbolic Causal AI: Mengajarkan LLM untuk Berpikir Kausal

LLM dapat dilatih untuk menjadi **Causal Reasoner**. Alih-alih hanya menghasilkan teks, ia menghasilkan **Structural Causal Model (SCM)**.

```python
# Prompt untuk LLM sebagai Causal Discovery Engine
prompt = """
Anda adalah seorang ilmuwan kausal. Berdasarkan teks berikut, buatlah sebuah Structural Causal Model (SCM).

Teks: "Di perusahaan X, kami mengamati bahwa tim yang melakukan code review (A) memiliki lebih sedikit bug di production (C). Namun, kami juga tahu bahwa tim yang lebih senior (B) cenderung melakukan code review (A) dan secara alami menulis kode yang lebih baik (C)."

Tugas:
1. Identifikasi variabel kunci (A: code review, B: senioritas, C: bug production).
2. Gambarkan DAG (Directed Acyclic Graph) kausal yang paling mungkin.
3. Identifikasi confounder (B).
4. Jelaskan bagaimana cara mengestimasi efek kausal murni dari A ke C.
"""

# Output LLM (ideal):
# DAG: B -> A, B -> C, A -> C
# Confounder: B (senioritas)
# Estimasi: Lakukan backdoor adjustment dengan mengontrol B.
# Do-Calculus: P(C | do(A)) = Σ_b P(C | A, B=b) * P(B=b)
```
**Koneksi Vault:** Kemampuan untuk melakukan "bagaimana jika" ini adalah inti dari **Test-Time Compute / System 2** di **[[test-time-compute-system2]]**. Agen tidak hanya memprediksi; ia merenungkan intervensi dan membayangkan masa depan alternatif.

---

## 💎 4. Explainable AI (XAI) — Hakikat dari Kepercayaan

Dalam dunia AI, kepercayaan bukanlah hadiah; ia harus direkayasa. XAI adalah jembatan antara output probabilistik dan pemahaman manusia.

### 4.1 Dari Atribusi ke Konsep: Mendaki Tangga Penjelasan

| Level Penjelasan | Pertanyaan yang Dijawab | Metode (XAI) | Analogi Kognitif |
| :--- | :--- | :--- | :--- |
| **1. Atribusi Fitur** | "Fitur mana yang paling penting?" | **SHAP, LIME** | Menyebutkan bahan-bahan dalam sebuah hidangan. |
| **2. Arsitektural** | "Bagaimana model memproses informasi?" | **TCAV, Network Dissection** | Menjelaskan fungsi setiap bagian dapur dalam memasak. |
| **3. Kontrafaktual** | "Apa yang harus diubah untuk mendapatkan hasil berbeda?" | **Counterfactual Generation** | "Jika Anda tidak menambahkan garam, sup ini akan terasa hambar." |
| **4. Simbolik** | "Apa aturan logis yang diikuti model?" | **Rule Extraction, Neurosymbolic** | "Resep supnya adalah: tumis bawang, tambahkan air, masukkan sayuran." |

### 4.2 TCAV (Testing with Concept Activation Vectors): Mengajari Model Bahasa Konsep

Ini adalah contoh sempurna neurosymbolic XAI. Sebuah pengguna mendefinisikan sebuah konsep ("bergaris") dengan memberikan contoh gambar. Sistem kemudian belajar untuk mendeteksi apakah sebuah model menggunakan konsep itu untuk membuat keputusan.

```python
# Pseudocode TCAV
# 1. Kumpulkan contoh gambar untuk konsep "bergaris" dan gambar acak.
# 2. Latih pengklasifikasi linear untuk membedakan aktivasi layer tertentu 
#    dari gambar "bergaris" vs acak. Vektor bobotnya = Concept Activation Vector (CAV).
# 3. Untuk setiap kelas (misal, "zebra"), hitung sensitivitas prediksi kelas 
#    terhadap perubahan ke arah CAV. Ini adalah TCAV score.
# 4. Jika TCAV score tinggi, model menggunakan konsep "bergaris" untuk mengklasifikasikan "zebra".
```
**Koneksi Vault:** Ini adalah bentuk dari **LLM Security & Red Teaming** (**[[llm-security-red-teaming-attack-surface-ai-layer]]**) yang defensif. Alih-alih menyerang model, Anda mengaudit "pola pikir" internalnya untuk memastikan ia menggunakan logika yang benar.

---

## 🛡️ 5. Neurosymbolic untuk Cybersecurity: Arsitektur SOC Otonom

Ini adalah aplikasi pamungkas dari prinsip ini, menyatukan Neural (deteksi) dan Symbolic (korelasi & respons) dalam satu loop OODA.

### 5.1 Arsitektur Referensi: SOC Analyst Agent

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     NEUROSYMBOLIC SOC ANALYST                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [RAW ALERT]                                                             │
│       │                                                                  │
│       ▼                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────────────────────┐   │
│  │ NEURAL (System 1)    │    │ SYMBOLIC (System 2)                  │   │
│  ├──────────────────────┤    ├──────────────────────────────────────┤   │
│  │ • Anomaly Detection  │    │ • MITRE ATT&CK Knowledge Graph (Neo4j)│   │
│  │ • LLM Entity Extract │    │ • Rule Engine (Causal Rules, SOPs)   │   │
│  │ • Alert Triage (ML)  │    │ • Graph Traversal (Correlation)      │   │
│  └──────────┬───────────┘    └───────────────────┬──────────────────┘   │
│             │                                    │                       │
│             └──────────────┬─────────────────────┘                       │
│                            ▼                                             │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ NEUROSYMBOLIC FUSION (Orchestrator Agent)                          │  │
│  │ • Alert dinilai oleh Neural, dikontekstualisasikan oleh Symbolic.  │  │
│  │ • LLM menghasilkan rencana respons berdasarkan                      │  │
│  │   • Anomali (apa yang salah)                                        │  │
│  │   • Konteks KG (siapa, apa, di mana)                               │  │
│  │   • Aturan Kausal (mengapa ini terjadi, apa dampaknya)             │  │
│  └────────────────────────────────┬────────────────────────────────────┘  │
│                                   ▼                                      │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ EXPLAINABLE OUTPUT (XAI Layer)                                     │  │
│  │ • "Insiden ini diklasifikasikan sebagai TRUE POSITIVE (skor: 0.95) │  │
│  │   karena 3 indikator: [SHAP: IP Reputasi (0.4),                    │  │
│  │   Beaconing Pattern (0.35), Geo-Anomaly (0.2)]."                   │  │
│  │ • "Rekomendasi: Isolasi host dan lakukan eskalasi ke Tier 2."      │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```
**Koneksi Vault:** Ini adalah spesialisasi dari **[[purple-team-osi-killchain]]**. Agen ini adalah anggota tim Purple yang otonom, secara konstan menjalankan siklus *detect-analyze-respond*.

---

## 🧠 6. Peta Jalan Implementasi: Membangun Reasoning Engine

### 6.1 Langkah 1: Membangun Knowledge Graph dari Data Mentah (Neural → Symbolic)

Ini adalah langkah pertama yang kritis. LLM bertindak sebagai "mesin ekstraksi" untuk mengubah data tidak terstruktur menjadi simbol terstruktur.

```python
# Pipeline: Dokumen → KG → Query
def build_intel_kg(documents):
    # 1. Neural — ekstrak entitas + relasi
    triples = []
    for chunk in chunk_documents(documents):
        # LLM mengubah teks menjadi fakta terstruktur
        ner_result = llm.extract_triples(chunk)
        triples.extend(ner_result.triples)
    
    # 2. Symbolic — masukkan ke graph sebagai fakta yang persisten
    for (subj, pred, obj) in triples:
        graph.query("""
            MERGE (s:Entity {name: $subj})
            MERGE (o:Entity {name: $obj})
            MERGE (s)-[r:RELATION {type: $pred}]->(o)
        """, params={"subj": subj, "pred": pred, "obj": obj})
    
    # 3. Neurosymbolic — validasi dan deduplikasi
    inconsistencies = validate_graph(graph) # Memeriksa aturan logis
    return {"graph": graph, "inconsistencies": inconsistencies}
```

### 6.2 Langkah 2: Causal Discovery untuk Decision Support (Data → Causal Graph)

Dari data historis, kita dapat menemukan struktur kausal yang membantu pengambilan keputusan.

```python
# Dari data observasional → causal graph → decision
def discover_causal_structure(data, domain_knowledge):
    # 1. Domain knowledge sebagai prior (symbolic)
    prior_graph = nx.DiGraph()
    prior_graph.add_edges_from(domain_knowledge) # [(x, y), ...]
    
    # 2. Data-driven discovery (NOTEARS - Neural)
    estimated_graph = notears(data, lambda1=0.1)
    
    # 3. Neurosymbolic Fusion
    # Gabungkan data-driven graph dengan prior domain expert
    fused_graph = fuse_graphs(estimated_graph, prior_graph, alpha=0.6)
    return fused_graph
```

---

## 🔗 7. Koneksi ke Ekosistem Vault

Neurosymbolic AI adalah benang merah yang menghubungkan banyak konsep di vault Anda.

| Dokumen di Vault | Koneksi Spesifik |
| :--- | :--- |
| **[[cognitive-architecture-engineering]]** | Neurosymbolic adalah fondasi kognitif dari arsitektur ini. Knowledge Graph adalah "memori", dan Causal AI adalah "model dunia". |
| **[[agentic-ai-mcp-architecture-deepdive]]** | Agen menggunakan GraphRAG sebagai "spatial memory" dan Causal AI sebagai "reasoning engine" untuk membuat rencana yang robust. |
| **[[test-time-compute-system2]]** | Penalaran kausal dan traversal graf adalah contoh murni dari System 2 thinking. Agen menggunakan compute tambahan untuk menalar, bukan hanya menghasilkan token. |
| **[[llm-security-red-teaming-attack-surface-ai-layer]]** | XAI (TCAV, SHAP) adalah alat Blue Team untuk mengaudit model. Causal AI adalah alat Red Team untuk memahami dan memanipulasi hubungan sebab-akibat dalam data. |
| **[[15-types-of-thinking]]** | Neurosymbolic adalah implementasi dari *Analytical Thinking* (Symbolic) yang dipandu oleh *Divergent Thinking* (Neural). |
| **[[machine-learning-classical-hierarchy]]** | Causal AI melampaui ML klasik (Asosiasi) menuju Intervensi dan Kontrafaktual. |