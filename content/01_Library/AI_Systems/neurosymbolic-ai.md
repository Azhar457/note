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

# 🧿 NEUROSYMBOLIC AI — Ketika Neural Bertemu Simbolik

**Knowledge Graph + LLM · GraphRAG · Causal AI · Explainable AI (XAI) · Hybrid Integration**

> [!abstract] Filosofi Fundamental
> Neural network unggul di pattern recognition tapi lemah di reasoning terstruktur. Symbolic AI unggul di logika kaku tapi tidak bisa generalisasi dari data. Neurosymbolic AI adalah **pernikahan** keduanya: neural untuk fleksibilitas, simbolik untuk presisi. Dokumen ini membedah setiap jalur integrasi — dari GraphRAG (KG + LLM) yang siap produksi, Causal AI untuk reasoning melampaui korelasi, hingga XAI untuk membuka black box. Bukan sekadar teori — ada kode, arsitektur, dan trade-off setiap pendekatan.

---

## Daftar Isi

- [[#First Principles — Neural vs Symbolic]]
- [[#Arsitektur Integrasi — Empat Pola]]
- [[#GraphRAG — Knowledge Graph + LLM]]
- [[#Causal AI — Dari Korelasi ke Kausalitas]]
- [[#Explainable AI — Membuka Black Box]]
- [[#Neurosymbolic untuk Cybersecurity]]
- [[#Implementasi Langkah demi Langkah]]
- [[#Tool & Framework Matrix]]
- [[#Open Problems]]
- [[#Catatan Terkait]]

---

## First Principles — Neural vs Symbolic

### Perbandingan Fundamental

| Dimensi              | Neural                          | Symbolic                              |
| -------------------- | ------------------------------- | ------------------------------------- |
| **Representasi**     | Continuous (vektor, embeddings) | Discrete (simbol, logika, grafik)     |
| **Learning**         | Dari data (gradient descent)    | Dari aturan (deduksi, induksi)        |
| **Generalization**   | Pattern-based (interpolation)   | Rule-based (ekstrapolasi logis)       |
| **Interpretability** | Black box                       | Transparan (jelas reasoning chain)    |
| **Noise tolerance**  | Tinggi                          | Rendah (one wrong rule = collapse)    |
| **Data efficiency**  | Rendah (butuh banyak data)      | Tinggi (bisa dari knowledge engineer) |
| **Reasoning**        | Implicit (dalam weights)        | Explicit (dalam aturan)               |
| **Common sense**     | Learned from data               | Need manual encoding                  |

### Mengapa Neurosymbolic?

Masalah yang tidak bisa diselesaikan oleh neural atau symbolic sendiri:

```
┌──────────────────────────────────────────────────────┐
│              YANG MEMBUTUHKAN NEUROSYMBOLIC           │
├──────────────────────────────────────────────────────┤
│  ● Medical diagnosis: Pattern dari imaging           │
│    (neural) + causal reasoning dari patient history  │
│    (symbolic)                                         │
│                                                       │
│  ● Scientific discovery: Hipotesis dari data          │
│    (neural) + verifikasi logis (symbolic)             │
│                                                       │
│  ● Autonomous driving: Object detection (neural)     │
│    + traffic rule compliance (symbolic)               │
│                                                       │
│  ● Cybersecurity: Anomaly detection (neural)         │
│    + threat correlation + MITRE mapping (symbolic)   │
└──────────────────────────────────────────────────────┘
```

---

## Arsitektur Integrasi — Empat Pola

### Pola 1: Hybrid — Terpisah, Berkomunikasi via API

```
[INPUT] ──► NEURAL (perception) ──► SYMBOLIC (reasoning) ──► OUTPUT
                  │                          │
            Image Classification          Logic Inference
            Speech Recognition            Rule Engine
            NER Extraction                Knowledge Graph Query
```

**Implementasi:** LLM + LangChain Graph. Neural ekstrak entitas, symbolic query KG.

**Kelebihan:** Modular, bisa ganti komponen independent, mudah debug.
**Kekurangan:** Latency bottleneck di API call, konteks hilang antar komunikasi.

### Pola 2: Unified — Dual Representasi dalam Satu Model

```
[INPUT] ──► SHARED REPRESENTATION ──► NEURAL HEAD ──► Pattern output
                         │            SYMBOLIC HEAD ──► Structured output
                    Vektor +
                    Symbol Binding
```

**Contoh:** Logic Tensor Networks — tensor + first-order logic dalam satu loss function.

**Kelebihan:** Integrasi erat, gradient mengalir ke kedua sisi.
**Kekurangan:** Kompleksitas matematis tinggi, belum mature.

### Pola 3: Neuro → Symbolic

```
[INPUT] ──► NEURAL ──► Symbols ──► SYMBOLIC REASONING ──► OUTPUT
                  │                          │
             Ekstrak entity,              Validasi logis,
             relation, label              inferensi deduktif
```

**Contoh:** DeepProbLog — neural network ekstrak probabilitas fakta → ProbLog lakukan reasoning.

### Pola 4: Symbolic → Neuro

```
[INPUT] ──► SYMBOLIC ──► Neural Prior ──► NEURAL LEARNING ──► OUTPUT
                  │                          │
            Aturan domain               Knowledge-guided
            Knowledge graph             training / data aug
```

**Contoh:** Rule-based data augmentation, KG-enhanced RAG.

---

## GraphRAG — Knowledge Graph + LLM

### GraphRAG vs Traditional RAG

| Dimensi                 | RAG Standar        | GraphRAG                           |
| ----------------------- | ------------------ | ---------------------------------- |
| **Retrieval unit**      | Chunk teks (flat)  | Subgraph (struktur)                |
| **Context**             | Semantik vektor    | Semantik + relasi + struktur       |
| **Multi-hop reasoning** | Lemah (butuh luck) | Kuat (graph traversal eksplisit)   |
| **Hallucination**       | Masih mungkin      | Lebih rendah (grounded di entitas) |
| **Update**              | Re-index           | Add node/edge incremental          |
| **Query complexity**    | Langsung ke vektor | Query + traverse + subgraph        |

### Arsitektur GraphRAG

```
┌─────────────────────────────────────────────────────────────┐
│                        USER QUERY                            │
│  "Siapa yang terlibat dalam serangan X dan apa motifnya?"    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  QUERY REWRITER (LLM)                         │
│  Ekstrak entitas + intent dari query natural                 │
│  → Person: ?, Event: "serangan X", Relation: "terlibat"    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   GRAPH TRAVERSAL (Neo4j)                     │
│  MATCH (e:Event {name: 'serangan X'})                       │
│  MATCH (p:Person)-[r]->(e)                                   │
│  RETURN p, r, e                                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 SUBGRAPH RETRIEVAL                            │
│  {                                                            │
│    entities: [Person_A, Person_B, Org_C],                     │
│    relations: [Person_A -[orchestrates]-> Event_X,            │
│                Person_B -[funds]-> Person_A],                  │
│    context_text: [chunk terkait dari dokuemn]                  │
│  }                                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                CONTEXT ASSEMBLY + LLM GENERATION              │
│  Prompt:                                                     │
│    "Berdasarkan knowledge graph berikut, jawab query user.   │
│     Graph: [subgraph serialization]                           │
│     Chunks: [retrieved text]                                  │
│     Query: {original query}"                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FINAL ANSWER                               │
│  "Serangan X diorkestrasi oleh Person_A dengan dana dari     │
│   Person_B melalui Org_C..."                                  │
└─────────────────────────────────────────────────────────────┘
```

### Implementasi GraphRAG dengan LangChain + Neo4j

```python
from langchain_community.graphs import Neo4jGraph
from langchain_experimental.graph_transformers import LLMGraphTransformer
from langchain_core.documents import Document

# 1. Konek ke Neo4j
graph = Neo4jGraph(
    url="bolt://localhost:7687",
    username="neo4j",
    password="password"
)

# 2. Transform dokumen ke graph
llm_transformer = LLMGraphTransformer(
    llm=llm,
    allowed_nodes=["Person", "Organization", "Event", "Location", "Tool", "Malware"],
    allowed_relationships=[
        "orchestrates", "funds", "uses", "targets", "works_at",
        "related_to", "occurs_after", "mitigates"
    ],
    node_properties=True,  # Ekstrak properti juga
)

documents = [Document(page_content=raw_text)]
graph_documents = llm_transformer.convert_to_graph_documents(documents)
graph.add_graph_documents(
    graph_documents,
    baseEntityLabel=True,
    include_source=True,  # Link nodes ke source document
)

# 3. GraphRAG Chain
from langchain.chains import GraphCypherQAChain

graph_chain = GraphCypherQAChain.from_llm(
    llm=llm,
    graph=graph,
    verbose=True,
    validate_cypher=True,     # Validasi syntax Cypher
    top_k=10,                  # Max subgraph entities
    return_intermediate_steps=True,
)

# 4. Query
result = graph_chain.invoke({
    "query": "Siapa yang mendanai serangan siber terhadap perusahaan X?"
})
```

### Graph Schema Design untuk Intelijen

```cypher
// Nodes
(:Person {
  name: string,
  aliases: string[],
  threat_score: float,      // 0-10
  confidence: float,        // 0-1
  first_seen: datetime,
  last_seen: datetime,
  source_reliability: string  // A-E
})

(:Organization {
  name: string,
  type: string,             // state, criminal, hacktivist, corporate
  country: string,
})

(:Event {
  name: string,
  type: string,             // attack, meeting, transaction
  timestamp: datetime,
  impact: string,
})

(:Tool {
  name: string,
  category: string,         // malware, exploit, framework
  mitre_id: string,         // T1059, etc
})

// Relations
(:Person)-[:ORCHESTRATES {confidence, evidence}]->(:Event)
(:Person)-[:FUNDS {amount, currency, method}]->(:Person)
(:Person)-[:USES {first_used, last_used}]->(:Tool)
(:Event)-[:TARGETS]->(:Organization)
(:Event)-[:OCCURS_AFTER]->(:Event)
```

### Query Patterns Berguna

```cypher
// Cari semua path antara entitas (maks 4 hop)
MATCH p = (a:Person)-[*1..4]-(b:Person)
WHERE a.name = "Target" AND b.threat_score > 8
RETURN p LIMIT 20

// Temporal correlation: siapa yang aktif di periode yang sama?
MATCH (p:Person)-[:ORCHESTRATES]->(e:Event)
WHERE e.timestamp >= datetime("2026-01-01")
  AND e.timestamp <= datetime("2026-03-01")
RETURN p, count(e) AS events
ORDER BY events DESC

// Cari "missing link" — entitas yang terhubung via proxy
MATCH (a:Person)-[:KNOWS]->(x)<-[:KNOWS]-(b:Person)
WHERE a.name = "Alice" AND b.name = "Bob"
  AND NOT (a)-[:KNOWS]-(b)
RETURN x AS intermediary
```

---

## Causal AI — Dari Korelasi ke Kausalitas

### Pearl's Causal Hierarchy

```
Level 3: COUNTERFACTUALS
  "Jika saya tidak minum obat itu, apakah saya akan sembuh?"
  Butuh: model struktural lengkap + SCM

Level 2: INTERVENTION
  "Apa yang terjadi jika saya memberi obat ke semua pasien?"
  Butuh: causal graph + do-calculus

Level 1: ASSOCIATION
  "Pasien yang minum obat lebih sering sembuh?"
  Butuh: data statistik saja (yang dilakukan ML biasa)
```

Machine learning konvensional **hanya beroperasi di Level 1**. Causal AI beroperasi di Level 2 dan 3.

### Causal Discovery — Belajar Struktur Kausal dari Data

| Algorithm        | Type                     | Data                   | Output       | Scalability                 |
| ---------------- | ------------------------ | ---------------------- | ------------ | --------------------------- |
| **PC Algorithm** | Constraint-based         | Observational          | DAG          | $O(n^2)$                    |
| **FCI**          | Constraint-based         | Observational + latent | PAG          | $O(n^3)$                    |
| **NOTEARS**      | Score-based (continuous) | Observational          | DAG          | $O(n^2)$ — gradient-based   |
| **LiNGAM**       | ICA-based                | Observational          | DAG (linear) | $O(n^2)$                    |
| **GES**          | Score-based (search)     | Observational          | DAG          | $O(n^2)$ eksponensial worst |

**NOTEARS — Deep Learning untuk Causal Discovery:**

```python
# NOTEARS: Structural learning as continuous optimization
# Goal: cari weighted adjacency matrix W yang DAG

from notears import notears

# W = adjacency matrix (node → node)
# Loss = Σ||X_j - W_j · X||² + λ||W||₁ (L1 untuk sparsity)
# Constraint: h(W) = tr(e^{W∘W}) - d = 0 (acyclicity)

W_est = notears.linear_model(X, lambda1=0.1, loss_type="l2")
# W_est[i,j] > 0 → X_j cause X_i
```

### Causal Inference — Estimasi Effect

**Di mana kita pakai?**

```
Treatment → Population → Outcome
  (obat)     (pasien)     (sembuh)

Yang ingin kita tahu: E[Y | do(T=1)] - E[Y | do(T=0)]
Effect of treatment on the treated (ATT) vs population (ATE)
```

**Methods:**

| Method                          | Assumption                 | Use Case                        |
| ------------------------------- | -------------------------- | ------------------------------- |
| **Propensity Score Matching**   | Unconfoundedness + overlap | Observational study             |
| **Double ML (DML)**             | Partially linear model     | High-dimensional features       |
| **Causal Forest**               | Unconfoundedness           | Heterogeneous treatment effects |
| **IV (Instrumental Variables)** | Exclusion restriction      | Unobserved confounders          |
| **DoWhy**                       | Multiple methods unified   | Production pipeline             |

**Contoh DoWhy:**

```python
import dowhy
from dowhy import CausalModel

model = CausalModel(
    data=df,
    treatment="obat_diminum",
    outcome="kesembuhan",
    common_causes=["usia", "jenis_kelamin", "keparahan_awal"],
    instruments=["randomized_assign"],  # Jika ada
)

# Identify causal effect
identified = model.identify_effect(proceed_when_unidentifiable=False)

# Estimate
estimate = model.estimate_effect(
    identified,
    method_name="backdoor.propensity_score_matching",
    method_params={"propensity_score_model": "logistic"}
)

# Refute
refutation = model.refute_estimate(
    identified,
    estimate,
    method_name="random_common_cause"
)
```

### Neurosymbolic Causal AI — Integrasi

```
┌──────────────────────────────────────────────────────────┐
│                    CAUSAL AI PIPELINE                      │
│                                                            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ DOMAIN       │    │ CAUSAL       │    │ NEURAL       │  │
│  │ KNOWLEDGE    │───►│ GRAPH        │───►│ REASONING    │  │
│  │ (Symbolic)   │    │ (SCM)        │    │ (Estimation) │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                │            │
│         ▼                    ▼                ▼            │
│  Prior causal          Causal graph        Causal effect   │
│  knowledge dari        dari discovery      estimation      │
│  expert (KG)           + domain prior      + counterfactual│
└──────────────────────────────────────────────────────────┘
```

---

## Explainable AI — Membuka Black Box

### Taxonomy XAI

```
                                                        ┌──────────────────────────────┐
                    EXPLAINABLE AI                        │  POST-HOC vs ANTE-HOC       │
                    │                                     │                              │
    ┌───────────────┴───────────────┐                     │  Post-hoc: setelah model    │
    │                               │                     │  dilatih (SHAP, LIME)       │
┌───┴────┐                    ┌─────┴──────┐              │                              │
│POST-HOC│                    │ ANTE-HOC    │             │  Ante-hoc: model didesain   │
└───┬────┘                    │ (self-exp)  │             │  inherently explainable     │
    │                         └──────┬──────┘             └──────────────────────────────┘
    │                                │
┌───┴──────────┐          ┌──────────┴──────────┐
│ FEATURE      │          │ INHERENTLY           │
│ ATTRIBUTION  │          │ INTERPRETABLE        │
├──────────────┤          ├──────────────────────┤
│ SHAP         │          │ Linear Regression    │
│ LIME         │          │ Decision Tree        │
│ Integrated   │          │ SENN                 │
│ Gradients    │          │ Concept Bottleneck   │
│ Saliency Map │          │ Neural Additive      │
└──────────────┘          └──────────────────────┘

┌──────────────┐          ┌──────────────────────┐
│ CONCEPT-     │          │ COUNTERFACTUAL       │
│ BASED        │          │ EXPLANATION          │
├──────────────┤          ├──────────────────────┤
│ TCAV         │          │ "Perubahan apa yang  │
│ ACE          │          │  membuat prediksi    │
│              │          │  berubah?"           │
└──────────────┘          └──────────────────────┘
```

### SHAP — Feature Attribution

```python
import shap
import xgboost as xgb

# Train model
model = xgb.XGBClassifier().fit(X_train, y_train)

# SHAP explainer
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_test)

# 1. Global feature importance
shap.summary_plot(shap_values, X_test, feature_names=features)

# 2. Single prediction explanation
shap.force_plot(explainer.expected_value, shap_values[0], X_test.iloc[0])

# 3. Interaction detection
shap.dependence_plot("age", shap_values, X_test, interaction_index="income")
```

**Interpretasi SHAP:**

- SHAP value positif → fitur mendorong prediksi ke kelas 1
- SHAP value negatif → fitur mendorong ke kelas 0
- Sum SHAP values + baseline = prediksi model

### LIME — Local Surrogate Model

```python
import lime
import lime.lime_tabular

explainer = lime.lime_tabular.LimeTabularExplainer(
    X_train,
    feature_names=features,
    class_names=['benign', 'malicious'],
    mode='classification',
)

exp = explainer.explain_instance(
    X_test[42],
    model.predict_proba,
    num_features=5,
)

exp.show_in_notebook()
exp.as_list()
# Output: "feature_5 > 0.7 contributes 0.32 to malicious"
```

### Concept-based (TCAV)

**TCAV** (Testing with Concept Activation Vectors) menjawab: _"Apakah model menggunakan konsep X untuk prediksi?"_

**Cara kerja:**

1. Kumpulkan contoh konsep (e.g., gambar "striped")
2. Train linear classifier untuk deteksi konsep di layer tertentu
3. Hitung sensitivity: ∂prediksi / ∂konsep

**Output:** "Model 85% sensitive terhadap konsep 'striped' untuk prediksi 'zebra'."

---

## Neurosymbolic untuk Cybersecurity

### Arsitektur

```
RAW DATA ──► NEURAL (detection) ──► SYMBOLIC (correlation) ──► DECISION
                  │                          │
            Anomaly detection           MITRE ATT&CK mapping
            Malware classification      Kill chain analysis
            Phishing detection          Incident correlation
```

### Implementasi — AI Security Analyst

```python
class NeurosymbolicSecurityAnalyst:
    def __init__(self):
        self.detector = AnomalyDetectionModel()     # Neural
        self.kg = Neo4jGraph(...)                    # Symbolic
        self.reasoner = RuleEngine()                 # Symbolic

    def analyze_alert(self, raw_log):
        # Neural — detect anomaly
        anomaly_score = self.detector.predict(raw_log)
        if anomaly_score < 0.7:
            return {"level": "INFO", "message": "Normal activity"}

        # Neural — extract entities
        entities = self.extract_entities(raw_log)  # LLM-based NER

        # Symbolic — query knowledge graph
        context = self.kg.query(f"""
            MATCH (e:Event {{id: '{entities['event_id']}'}})
            MATCH (t:Tactic)-[:INCLUDES]->(e)
            RETURN e, t
        """)

        # Symbolic — MITRE mapping via rule engine
        mitre_mapping = self.reasoner.match_mitre(
            technique=entities['technique'],
            context=context
        )

        # Neurosymbolic fusion
        recommendation = self.fuse(
            confidence=anomaly_score,
            mitre=mitre_mapping,
            historical=context
        )

        return recommendation
```

---

## Implementasi Langkah demi Langkah

### Langkah 1: Setup Knowledge Graph dari Dokumen

```python
# Pipeline: Dokumen → KG → Query
def build_intel_kg(documents):
    # 1. Chunk
    chunks = chunk_documents(documents)

    # 2. Neural — ekstrak entitas + relasi
    triples = []
    for chunk in chunks:
        ner_result = llm.extract_triples(chunk)
        triples.extend(ner_result.triples)

    # 3. Symbolic — masukkan ke graph
    for (subj, pred, obj) in triples:
        graph.query("""
            MERGE (s:Entity {name: $subj})
            MERGE (o:Entity {name: $obj})
            MERGE (s)-[r:RELATION {type: $pred}]->(o)
        """, params={"subj": subj, "pred": pred, "obj": obj})

    # 4. Validasi — cek inkonsistensi logis
    inconsistencies = validate_graph(graph)

    return {"graph": graph, "inconsistencies": inconsistencies}
```

### Langkah 2: Causal Discovery untuk Decision Support

```python
# Dari data observasional → causal graph → decision
def discover_causal_structure(data, domain_knowledge):
    # 1. Domain knowledge sebagai prior (symbolic)
    prior_graph = nx.DiGraph()
    prior_graph.add_edges_from(domain_knowledge)  # [(x, y), ...]

    # 2. Data-driven discovery (NOTEARS)
    estimated_graph = notears(data, lambda1=0.1)

    # 3. Neural + Symbolic fusion
    # Weighted average: 0.6 data-driven + 0.4 domain
    # Atau: prior sebagai hard constraint
    fused_graph = fuse_graphs(estimated_graph, prior_graph, alpha=0.6)

    return fused_graph
```

### Langkah 3: XAI untuk Stakeholder

```python
def explain_prediction(model, instance, stakeholder="regulator"):
    """Generate explanation sesuai level stakeholder"""

    if stakeholder == "regulator":
        # Counterfactual: perubahan minimal untuk hasil berbeda
        cf = generate_counterfactual(instance, model)
        return f"Prediksi akan berubah jika {cf.changed_features}"

    elif stakeholder == "engineer":
        # SHAP detailed
        shap_values = shap.Explainer(model).shap_values(instance)
        return shap_plot(shap_values)

    elif stakeholder == "end_user":
        # Natural language
        top_features = get_top_k_features(model, instance, k=3)
        return f"Keputusan ini berdasarkan {top_features[0]}, {top_features[1]}, dan {top_features[2]}"
```

---

## Tool & Framework Matrix

| Framework                       | Pendekatan       | Neural   | Symbolic     | Kapan                       |
| ------------------------------- | ---------------- | -------- | ------------ | --------------------------- |
| **LangChain Graph**             | GraphRAG ⭐      | ✅ (LLM) | ✅ (Neo4j)   | Production-ready, flexible  |
| **PyKEEN**                      | KG Embedding     | ✅       | ⚠️           | Link prediction, completion |
| **DeepProbLog**                 | Neuro→Symbolic   | ✅       | ✅ (ProbLog) | Probabilistic reasoning     |
| **LTN (Logic Tensor Networks)** | Unified          | ✅       | ✅           | Loss-based integration      |
| **DoWhy**                       | Causal Inference | ❌       | ✅           | Causal analysis             |
| **SHAP / LIME**                 | XAI              | ✅       | ❌           | Model explanation           |
| **TCAV**                        | Concept XAI      | ✅       | ✅           | High-level concept testing  |

---

## Open Problems

| Problem                          | Deskripsi                                               | Progress                                       |
| -------------------------------- | ------------------------------------------------------- | ---------------------------------------------- |
| **Gradient through symbolic**    | Symbolic reasoning diskrit → tidak differentiable       | Relaxation, REINFORCE, Gumbel-softmax          |
| **Knowledge graph completeness** | KG selalu incomplete — missing edges → wrong reasoning  | Open-world assumption, KG completion           |
| **Scalability of reasoning**     | Symbolic reasoning polynomial/exponential di worst case | Approximation, bounded reasoning               |
| **Causal discovery accuracy**    | PC/FCI masih salah di high-dim, low-sample              | NOTEARS, differentiable causal discovery       |
| **XAI faithfulness**             | SHAP approximation — seberapa setia ke model asli?      | SHAP game-theoretic guarantees, LIME stability |
| **Neurosymbolic training**       | End-to-end masih sulit                                  | Two-stage training, alternating optimization   |

---

## Catatan Terkait

- **[[cognitive-architecture-engineering]]** — Arsitektur kognitif (inspirasi neurosymbolic)
- **[[ai-evaluation-framework]]** — Evaluasi AI (XAI metrics)
- **[[llm-finetuning-toolchain]]** — Fine-tuning LLM (neural component)
- **[[agentic-ai-mcp-architecture-deepdive]]** — Agentic AI (reasoning + tool use)
- **[[swarm-ai-imam-robandi]]** — Swarm intelligence (decentralized symbolic)
- **[[dual-use-spectrum-and-ethical-framework]]** — Etika dual-use (dari symbolic rules)

---

> [!tip] Prinsip Praktis
> Neurosymbolic AI bukan tentang memilih satu pendekatan — tapi tentang **menggabungkan kekuatan** keduanya untuk masalah yang tepat. Aturan praktis: Neural untuk persepsi dan generalisasi (data mentah → pola), Symbolic untuk reasoning dan constraint (pola → keputusan yang bisa dipertanggungjawabkan). GraphRAG adalah pintu masuk paling praktis karena maturity toolsnya (LangChain + Neo4j sudah enterprise-grade). Causal AI adalah frontier berikutnya — ketika Anda tidak hanya ingin prediksi, tapi **pemahaman** tentang mengapa sesuatu terjadi dan apa yang akan terjadi jika Anda intervensi. XAI bukan opsional — di regulated industry, explainability adalah _syarat_.
