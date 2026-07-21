---
title: "AI Governance & Ethics — EU AI Act, NIST RMF, RLHF, DPO & Safe AI"
tags:
  - ai-governance
  - ai-ethics
  - eu-ai-act
  - nist-ai-rmf
  - rlhf
  - dpo
  - ai-safety
  - ai-alignment
aliases:
  - AI Governance Deep Dive
  - EU AI Act Compliance
  - RLHF vs DPO
  - Safe AI Systems
  - AI Regulation Framework
created: 2026-07-14
updated: 2026-07-14
status: evergreen
cssclasses:
  - wide-table
---

# 📊 AI GOVERNANCE & ETHICS — Regulasi, Alignment, dan AI yang Bertanggung Jawab

**EU AI Act · NIST AI RMF · RLHF · DPO · AI Safety · Regulasi Global · Bias & Fairness**

> [!abstract] Filosofi Fundamental
> Kekuatan AI tanpa governance adalah kekuatan tanpa arah. Dokumen ini membedah tiga pilar governance modern: **Regulasi** (EU AI Act, NIST RMF — kerangka hukum dan standar), **Alignment** (RLHF, DPO — cara membuat AI sesuai kehendak manusia), dan **Safety** (bias, fairness, transparency, accountability — operasionalisasi etika). Bukan sekadar teori regulasi — ada implementasi teknis RLHF vs DPO, compliance checklist, dan peta jalan kepatuhan untuk organisasi.

---

## Daftar Isi

- [[#First Principles — Mengapa AI Governance?]]
- [[#EU AI Act — Regulasi Paling Komprehensif]]
- [[#NIST AI RMF — Risk Management Framework]]
- [[#RLHF — Reinforcement Learning from Human Feedback]]
- [[#DPO — Direct Preference Optimization]]
- [[#RLHF vs DPO — Perbandingan Mendalam]]
- [[#AI Safety — Operational Ethics]]
- [[#Bias & Fairness — Measuring and Mitigating]]
- [[#Regulasi Global — Perbandingan]]
- [[#Compliance Implementation — Langkah demi Langkah]]
- [[#Catatan Terkait]]

---

## First Principles — Mengapa AI Governance?

### Tiga Krisis yang Mendorong Governance

```
KRISIS 1: HARM
  ├── Algorithmic bias (COMPAS, hiring algorithms)
  ├── Disinformation (deepfake, LLM-generated propaganda)
  └── Safety failures (self-driving accidents, chatbot harm)

KRISIS 2: ACCOUNTABILITY GAP
  ├── "Modelnya black box — saya tidak tahu kenapa keputusan ini"
  ├── "Siapa yang bertanggung jawab jika AI salah?"
  └── "Bagaimana cara audit sistem yang terus belajar?"

KRISIS 3: POWER ASYMMETRY
  ├── Beberapa perusahaan kuasai AI terkuat
  ├── Pengguna tidak punya kontrol atas data + keputusan AI
  └── Negara berkembang tertinggal dalam regulasi
```

### Spektrum Governance

```
LAISSEZ-FAIRE                    HEAVILY REGULATED
◄────────────────────────────────────────────────►

Self-regulation     Co-regulation       Legal binding
(OpenAI, Google)    (NIST, ISO)         (EU AI Act, China)

Semakin tinggi risk → semakin perlu hard regulation
```

---

## EU AI Act — Regulasi Paling Komprehensif

### Risk-Based Classification

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EU AI ACT PYRAMID                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  🚫 UNACCEPTABLE RISK (Prohibited)                                    │
│  ├─ Social scoring by government                                      │
│  ├─ Real-time biometric surveillance in public spaces                 │
│  ├─ Manipulative AI (exploit vulnerability)                           │
│  └─ Predictive policing based on profiling                            │
│  → Penalty: €35M or 7% global revenue                                │
│                                                                       │
│  ⚠️ HIGH RISK (Strict requirements)                                   │
│  ├─ Critical infrastructure (power, water, transport)                 │
│  ├─ Education (grading, access)                                       │
│  ├─ Employment (hiring, promotion)                                    │
│  ├─ Law enforcement (evidence, risk assessment)                       │
│  ├─ Migration & border control                                        │
│  └─ Justice & democratic processes                                    │
│  → Wajib: Risk mgmt · Data quality · Transparency · Human oversight  │
│  → Conformity assessment (self-assessment or third-party)            │
│                                                                       │
│  ⚡ LIMITED RISK (Transparency obligation)                             │
│  ├─ Chatbots → must disclose "you are interacting with AI"           │
│  ├─ Deepfake → must label "AI-generated content"                     │
│  └─ Emotion recognition / biometric categorization                   │
│                                                                       │
│  ✅ MINIMAL RISK (Code of conduct)                                    │
│  ├─ AI-enabled video games                                            │
│  ├─ Spam filters                                                      │
│  └─ Product recommendations                                           │
│  → Voluntary codes of conduct                                         │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Timeline Implementasi

```
2024:  AI Act disahkan
       ↓
2025:  Prohibited practices berlaku (6 bulan setelah efektif)
       ↓
2026:  GPAI (General Purpose AI) rules berlaku
       ↓
2026:  High-risk Annex III (self-assessment) berlaku
       ↓
2027:  High-risk Annex II (third-party conformity) berlaku penuh
```

### Requirements untuk High-Risk AI

| Area | Requirements | Implementasi |
|------|-------------|--------------|
| **Risk Management** | Continuous risk identification, evaluation, mitigation | Risk register, MLOps monitoring |
| **Data Governance** | Training data must be relevant, representative, error-free | Data quality pipeline, bias auditing |
| **Technical Documentation** | Model architecture, training methodology, evaluation results | Model cards, system cards |
| **Record Keeping** | Automatic logs of system operation (training + inference) | Logging infrastructure, audit trails |
| **Transparency** | Users must know they interact with AI | UI disclosure, API flags |
| **Human Oversight** | Humans can override/interrupt system | Human-in-the-loop, stop buttons |
| **Accuracy & Robustness** | Appropriate accuracy levels, resilience to errors | Testing, monitoring, fallback |

### GPAI (General Purpose AI) Requirements

**Untuk model seperti GPT-4, Claude, Llama:**

| Tier | Threshold | Requirements |
|------|-----------|-------------|
| **Standard GPAI** | All general-purpose models | Technical documentation, instructions for use, copyright policy |
| **Systemic Risk GPAI** | >10²⁵ FLOPs training compute | + Model evaluation, incident reporting, cybersecurity, energy reporting |

---

## NIST AI RMF — Risk Management Framework

### Core Functions

```
┌────────────────────────────────────────────────────────────────────┐
│                        NIST AI RMF                                   │
│  AI RMF Core: 4 Functions → 18 Categories → 80+ Actions             │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐         │
│  │ GOVERN   │──►│  MAP     │──►│ MEASURE  │──►│  MANAGE  │         │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘         │
│       │              │              │              │                │
│       ▼              ▼              ▼              ▼                │
│  Culture &      Context &      Metrics &      Treatment &          │
│  Policy         Risk ID        Testing        Response             │
│                                                                      │
└────────────────────────────────────────────────────────────────────┘
```

### GOVERN — Budaya dan Kebijakan

| Category | Key Actions |
|----------|-------------|
| **Policies** | Document AI ethics policy, assign responsible roles |
| **Culture** | Training for all AI practitioners, whistleblower mechanism |
| **Process** | AI review board, escalation pathways |
| **Stakeholder** | Engagement with affected communities |
| **Risk Tolerance** | Define acceptable risk levels per application |

### MAP — Pemetaan Konteks dan Risiko

```python
# Contoh AI risk mapping template
ai_risk_map = {
    "application": {
        "name": "Resume Screening AI",
        "context": "Hiring for tech positions",
        "deployment": "High-risk (EU AI Act)",
    },
    "harms_identified": [
        {
            "type": "bias",
            "description": "Gender bias in technical role screening",
            "severity": "high",
            "affected_groups": ["women", "non-binary"],
            "likelihood": 0.7,
        },
        {
            "type": "fairness",
            "description": "Educational institution bias (only top universities)",
            "severity": "medium", 
            "likelihood": 0.5,
        },
    ],
    "mitigations": [
        {"type": "data_audit", "status": "in_progress"},
        {"type": "fairness_metric", "metric": "demographic_parity", "threshold": 0.8},
        {"type": "human_review", "condition": "score > 0.9 OR score < 0.3"},
    ],
    "residual_risk": "medium — requires quarterly audit",
}
```

### MEASURE — Pengukuran Risiko

| Karakteristik | Metrik | Tools |
|---------------|--------|-------|
| **Valid & Reliable** | Accuracy, precision, recall, calibration | sklearn metrics, evaluation harness |
| **Safe** | Error rate by subgroup, adversarial robustness | Robustness evaluation |
| **Fair** | Demographic parity, equal opportunity, equalized odds | AIF360, Fairlearn |
| **Explainable** | SHAP score, feature importance, concept alignment | SHAP, LIME, Captum |
| **Transparent** | Documentation completeness, model cards | Model card template |
| **Accountable** | Audit trail completeness | Logging infra, version control |

### MANAGE — Penanganan Risiko

| Strategy | Description | When |
|----------|-------------|------|
| **Accept** | Residual risk within tolerance | Low-risk apps |
| **Mitigate** | Implement controls | Most cases |
| **Transfer** | Insurance, third-party audit | Shared liability |
| **Avoid** | Stop development/deployment | Unacceptable risk |
| **Monitor** | Continuous observation | All cases |

### Trustworthy AI Characteristics (NIST)

```
1. VALID & RELIABLE
   └─ Model accuracy, consistency across inputs, calibration

2. SAFE  
   └─ No catastrophic failures, graceful degradation

3. SECURE & RESILIENT
   └─ Adversarial robustness, data integrity

4. ACCOUNTABLE & TRANSPARENT
   └─ Audit trail, model documentation, explainability

5. EXPLAINABLE & INTERPRETABLE
   └─ SHAP/LIME, counterfactuals, feature attribution

6. PRIVACY-ENHANCED
   └─ Differential privacy, data minimization

7. FAIR — BIAS MANAGED
   └─ Demographic parity, equal opportunity
```

---

## RLHF — Reinforcement Learning from Human Feedback

### Arsitektur RLHF

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PHASE 1: SFT                                 │
│                                                                      │
│  Base Model ──► Supervised Fine-Tuning on human demonstrations       │
│  Output: Model yang bisa mengikuti instruksi dasar                   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PHASE 2: REWARD MODEL TRAINING                  │
│                                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                       │
│  │  Prompt   │───►│  SFT     │───►│ Output A  │                      │
│  │           │    │  Model   │    │ Output B  │                      │
│  └──────────┘    └──────────┘    └─────┬─────┘                      │
│                                        │                             │
│                                   Human label: A > B                │
│                                        │                             │
│                                        ▼                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Train Reward Model: r_θ(y) — predict human preference score   │  │
│  │  Loss: -E[log σ(r_θ(y_w) - r_θ(y_l))] — Bradley-Terry model    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     PHASE 3: RL OPTIMIZATION (PPO)                   │
│                                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                       │
│  │  Policy   │───►│  Output  │───►│  Reward   │                      │
│  │  π_θ      │    │  y       │    │  r_θ(y)  │                      │
│  └──────────┘    └──────────┘    └──────────┘                       │
│       │                                                              │
│       ▼                                                              │
│  Objective: max E[r_θ(y)] - β·KL(π_θ(y|x) || π_ref(y|x))            │
│  └── PPO clipping untuk stability                                    │
│  └── KL penalty agar policy tidak jauh dari SFT                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Reward Model — Detail

**Arsitektur:** SFT model + linear head untuk output scalar reward.

**Training data:** Pairwise comparisons (A > B) dari human labelers.

**Loss Function (Bradley-Terry):**

$$\mathcal{L}_{RM} = -\mathbb{E}_{(x, y_w, y_l) \sim D}[\log \sigma(r_\theta(y_w|x) - r_\theta(y_l|x))]$$

- $y_w$ = chosen (preferred) response
- $y_l$ = rejected response
- $\sigma$ = sigmoid function
- $r_\theta$ = reward model

### PPO — Proximal Policy Optimization

**Objective:**

$$\mathcal{L}_{PPO} = \mathbb{E}[\min(\frac{\pi_\theta}{\pi_{old}} A, \text{clip}(\frac{\pi_\theta}{\pi_{old}}, 1-\epsilon, 1+\epsilon)A)]$$

**Total RLHF loss:**

$$\mathcal{L} = \mathcal{L}_{PPO} + \beta \cdot \mathcal{L}_{KL} + \eta \cdot \mathcal{L}_{PT}$$

| Component | Fungsi | Bobot |
|-----------|--------|-------|
| **PPO** | Maksimalkan reward | 1.0 |
| **KL penalty** | Jaga policy dekat dengan SFT | 0.01-0.1 |
| **Pretraining loss** | Cegah catastrophic forgetting | 0.01-0.1 |

**Masalah RLHF:**

| Problem | Dampak | Mitigasi |
|---------|--------|----------|
| **Reward hacking** | Policy exploit reward model | KL penalty, ensemble RM |
| **Preference inconsistency** | Labeler tidak setuju | Inter-annotator agreement, consensus |
| **Expensive** | Butuh ribuan label manusia | Active learning, model-assisted labeling |
| **Goodhart's law** | Metric jadi target → ceases to be good metric | Diverse evaluation |
| **Distribution shift** | Policy explore out-of-distribution | Conservatism, careful PPO clipping |

---

## DPO — Direct Preference Optimization

### Intuisi

DPO menghilangkan **reward model entirely**. Langsung optimasi policy dari preferensi.

**Key insight:** Optimal policy $π^*$ bisa dinyatakan secara closed-form dari reward + reference policy:

$$r(x, y) = \beta \log \frac{\pi^*(y|x)}{\pi_{ref}(y|x)} + \beta \log Z(x)$$

Substitusi ke Bradley-Terry loss → **loss function langsung di policy**.

### DPO Loss

$$\mathcal{L}_{DPO}(\pi_\theta; \pi_{ref}) = -\mathbb{E}_{(x, y_w, y_l) \sim D}[ \log \sigma( \beta(\log \frac{\pi_\theta(y_w|x)}{\pi_{ref}(y_w|x)} - \log \frac{\pi_\theta(y_l|x)}{\pi_{ref}(y_l|x)} ) ) ]$$

**Interpretasi:**
- $\beta$ = temperature — seberapa kuat preferensi
- $\log(\pi_\theta / \pi_{ref})$ = implicit reward
- DPO = binary classification loss di (implicit reward difference)

### Implementasi DPO — Minimal

```python
import torch
import torch.nn.functional as F

def dpo_loss(policy_logits, ref_logits, chosen_ids, rejected_ids, beta=0.1):
    """
    policy_logits: logits from current policy
    ref_logits: logits from reference (frozen) policy
    chosen_ids: token IDs of preferred completion
    rejected_ids: token IDs of rejected completion
    """
    # Log probabilities
    policy_logps = gather_log_probs(policy_logits, chosen_ids)
    ref_logps = gather_log_probs(ref_logits, chosen_ids)
    
    policy_logps_rej = gather_log_probs(policy_logits, rejected_ids)
    ref_logps_rej = gather_log_probs(ref_logits, rejected_ids)
    
    # Log ratio = implicit reward
    log_ratio = (policy_logps - ref_logps) - (policy_logps_rej - ref_logps_rej)
    
    # DPO loss
    loss = -F.logsigmoid(beta * log_ratio).mean()
    
    # Accuracy — seberapa sering implicit reward benar
    accuracy = (log_ratio > 0).float().mean()
    
    return loss, accuracy
```

### Keunggulan DPO vs RLHF

| Dimensi | RLHF | DPO |
|---------|------|-----|
| **Components** | 4 (SFT + RM + PPO + ref) | 3 (SFT + DPO + ref) |
| **Training stability** | Sensitif — PPO hyperparameters | Lebih stabil |
| **Compute** | ~3x SFT (PPO sampling mahal) | ~1.5x SFT |
| **Reward model** | Perlu train dan maintain | Tidak perlu |
| **Reward hacking** | Risiko tinggi | Tidak ada reward model |
| **Scalability** | Butuh distributed RL infra | Sederhana — seperti fine-tuning biasa |
| **Performance** | SOTA (Claude, GPT-4) | Setara atau sedikit di bawah |
| **Offline vs Online** | Online (policy sampling) | Offline (fixed dataset) |

---

## RLHF vs DPO — Kapan Pakai Apa?

```
Butuh alignment?
├── Punya compute + infra untuk RL?
│   ├── Ya → RLHF (potensi performa lebih tinggi)
│   └── Tidak → DPO (lebih sederhana)
├── Dataset preference besar (>50K pairs)?
│   ├── Ya → DPO works well
│   └── Tidak → RLHF dengan reward model lebih sample-efficient
├── Butuh explicit reward model?
│   ├── Ya (untuk analisis, debugging) → RLHF
│   └── Tidak → DPO
├── Khawatir reward hacking?
│   ├── Ya → DPO (tidak ada RM untuk di-hack)
│   └── Tidak → Either
└── Production deployment?
    ├── RLHF: Claude, GPT-4, Gemini — terbukti di skala
    └── DPO: Llama 3, Mistral, Zephyr — terbukti untuk open-source
```

---

## AI Safety — Operational Ethics

### Safety Framework

```
┌──────────────────────────────────────────────────────────────┐
│                      AI SAFETY LAYERS                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  LAYER 1 — TRAINING SAFETY                                    │
│  ├─ Data filtering (remove toxic, illegal, harmful content)  │
│  ├─ Dataset deduplication (reduce memorization)              │
│  └─ Pre-training alignment (constitutional AI)               │
│                                                               │
│  LAYER 2 — ALIGNMENT SAFETY                                   │
│  ├─ RLHF / DPO (human preferences)                           │
│  ├─ Constitutional AI (rule-based self-critique)             │
│  └─ Red teaming (adversarial evaluation)                     │
│                                                               │
│  LAYER 3 — GUARDRAILS                                         │
│  ├─ Input moderation (block harmful prompts)                 │
│  ├─ Output filtering (block harmful generations)             │
│  └─ Context-level guard (topic restriction)                  │
│                                                               │
│  LAYER 4 — MONITORING                                         │
│  ├─ Real-time content safety scoring                         │
│  ├─ Usage anomaly detection (rate limiting, pattern)         │
│  └─ Incident response protocol                               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Red Teaming — Structured Adversarial Evaluation

```python
# Framework untuk red teaming AI
RED_TEAM_CATEGORIES = {
    "harmful_content": {
        "violence": ["How to build a bomb", "...", ...],
        "hate_speech": ["Generate racist content about...", "...", ...],
        "self_harm": ["...",],
    },
    "jailbreak": {
        "role_play": ["You are DAN (Do Anything Now)...", "...", ...],
        "hypothetical": ["In a hypothetical scenario where...", "...", ...],
        "encoding": ["Base64 decoded instruction:...", "...", ...],
        "multi_turn": ["Step 1: ...", "Step 2: ...", ...],
    },
    "bias": {
        "gender": ["A nurse should always be...", "...", ...],
        "race": ["Why are [group] more likely to...", "...", ...],
        "religion": ["...",],
    },
    "hallucination": {
        "false_premise": ["Explain why [false fact] is true", "...", ...],
        "unverifiable": ["...",],
    },
}

def run_red_team(model, categories, judge_model=None):
    results = []
    for category, subcategories in categories.items():
        for subcat, prompts in subcategories.items():
            for prompt in prompts:
                response = model.generate(prompt)
                # Automatic evaluation
                is_harmful = judge_model.classify(response)
                results.append({
                    "category": category,
                    "subcategory": subcat,
                    "prompt": prompt,
                    "response": response,
                    "harmful": is_harmful,
                    "severity": is_harmful.confidence if is_harmful else 0,
                })
    return results
```

### Constitutional AI — Self-Critique

**Tanpa human feedback — model critique diri sendiri berdasarkan konstitusi.**

```
Step 1: Critique
  Model generate respons → Model critique "Apakah respons ini
  melanggar prinsip harmlessness?"

Step 2: Revision  
  Model revisi respons berdasarkan kritik sendiri

Step 3: Preference pairs
  (before_critique, after_critique) → training pairs

Step 4: DPO/RLHF
  Train model untuk prefer revisi over original
```

**Contoh konstitusi:**

```
1. AI tidak boleh membantu pengguna melakukan aktivitas ilegal.
2. AI harus menghindari stereotip dan generalisasi berbahaya.
3. AI harus mengakui ketidakpastian — tidak membuat klaim palsu.
4. AI tidak boleh menghasilkan konten yang mempromosikan kekerasan.
5. AI harus menghormati privasi dan kerahasiaan informasi.
```

---

## Bias & Fairness — Measuring and Mitigating

### Bias Metrics

**Dataset Bias:**

```python
# Contoh: gender bias dalam training data
def measure_dataset_bias(dataset, attribute="gender"):
    """
    Hitung representasi setiap grup dalam dataset
    """
    rep = {}
    for item in dataset:
        item_attr = extract_attribute(item.text, attribute)
        rep[item_attr] = rep.get(item_attr, 0) + 1
    
    total = sum(rep.values())
    representation = {k: v/total for k, v in rep.items()}
    
    # Entropy-based diversity
    entropy = -sum(p * np.log(p) for p in representation.values())
    max_entropy = np.log(len(representation))
    diversity = entropy / max_entropy  # 1 = balanced, 0 = one group
    
    return {"representation": representation, "diversity": diversity}
```

**Model Bias Metrics (Group Fairness):**

| Metric | Formula | Interpretasi |
|--------|---------|--------------|
| **Demographic Parity** | $P(\hat{Y}=1|A=a) = P(\hat{Y}=1|A=b)$ | Semua grup punya positive rate sama |
| **Equal Opportunity** | $P(\hat{Y}=1|Y=1, A=a) = P(\hat{Y}=1|Y=1, A=b)$ | TPR sama antar grup |
| **Equalized Odds** | TPR = FPR antar grup | TPR dan FPR sama |
| **Predictive Parity** | $P(Y=1|\hat{Y}=1, A=a) = P(Y=1|\hat{Y}=1, A=b)$ | Precision sama antar grup |
| **Disparate Impact** | $\frac{P(\hat{Y}=1|A=a)}{P(\hat{Y}=1|A=b)}$ | Harus > 0.8 (80% rule) |

```python
import fairlearn.metrics as flm

def fairness_report(model, X, y, sensitive_features):
    predictions = model.predict(X)
    
    return {
        "demographic_parity": flm.demographic_parity_difference(
            y_true=y, y_pred=predictions,
            sensitive_features=sensitive_features,
        ),
        "equal_opportunity": flm.equal_opportunity_difference(
            y_true=y, y_pred=predictions,
            sensitive_features=sensitive_features,
        ),
        "disparate_impact": flm.disparate_impact_ratio(
            y_true=y, y_pred=predictions,
            sensitive_features=sensitive_features,
        ),
        "selection_rate": flm.selection_rate(
            y_pred=predictions,
            sensitive_features=sensitive_features,
        ),
    }
```

### Bias Mitigation — Pipeline

```
PRE-TRAINING                    IN-TRAINING                   POST-TRAINING
├── Dataset audit                ├── Fairness constraint      ├── Threshold tuning
├── Re-balancing                 │   (adversarial debias)     │   (different threshold
├── Data augmentation            ├── Regularization           │    per group)
│   untuk under-represented      │   (fairness proxy)        ├── Model ensemble
├── De-bias embedding            └── Equalized odds          ├── Re-ranking
│   (Hard-Debias, INLP)            post-processing           └── Human-in-loop
└── Synthetic data
    (untuk grup minoritas)
```

---

## Regulasi Global — Perbandingan

| Aspek | 🇪🇺 EU AI Act | 🇺🇸 US Executive Order | 🇨🇳 China Generative AI | 🇬🇧 UK Approach |
|-------|-------------|----------------------|----------------------|----------------|
| **Model** | Risk-based | Sectoral + advisory | Strict content control | Pro-innovation |
| **Binding?** | Yes | Partial (federal agencies) | Yes | No (white paper) |
| **Penalty** | €35M / 7% revenue | Contractual | Revoke license | N/A |
| **GPAI coverage** | Yes | Yes (reporting) | Yes | Voluntary |
| **High-risk scope** | Broad (8 categories) | Sector-specific (health, finance) | All generative AI | Minimal |
| **Human oversight** | Mandatory | Recommended | Content moderation | Optional |
| **Transparency** | Model cards | AI Bill of Rights | Labeling required | Voluntary |
| **Enforcement** | EU AI Office | FTC, sectoral agencies | CAC (Cyberspace Admin) | No single body |

### Indonesia — Stranas Kecerdasan Artifisial

**Strategi Nasional Kecerdasan Artifisial Indonesia (2020-2045):**

| Fokus | Target | Timeline |
|-------|--------|----------|
| **Ethics & Policy** | AI ethics guideline, data governance | 2020-2024 |
| **Infrastructure** | AI research center, compute infrastructure | 2020-2030 |
| **Talent** | AI training, university curriculum | Continuous |
| **Sector application** | Health, gov, education, agriculture | 2020-2035 |

**Kondisi saat ini:** Masih dalam tahap *soft regulation* — pedoman etika, belum UU mengikat. RUU Perlindungan Data Pribadi (UU PDP) sudah berlaku sebagai landasan.

---

## Compliance Implementation — Langkah demi Langkah

### Langkah 1: AI Inventory

```python
# Inventory semua AI systems dalam organisasi
ai_inventory = [
    {
        "id": "AI-001",
        "name": "Resume Screener",
        "type": "High-risk (employment)",
        "status": "production",
        "owner": "HR Dept",
        "data_subjects": "job applicants",
        "last_audit": "2026-06-01",
    },
    {
        "id": "AI-002",
        "name": "Customer Chatbot",
        "type": "Limited risk",
        "status": "production",
        "owner": "Support",
        "data_subjects": "customers",
        "last_audit": None,
    },
]
```

### Langkah 2: Risk Assessment

Untuk setiap high-risk AI:

```
1. IDENTIFY
   ├─ What decisions does the AI make?
   └─ Who is affected?

2. ANALYZE
   ├─ Bias metrics
   ├─ Accuracy by subgroup
   └─ Failure modes

3. EVALUATE  
   ├─ Against NIST AI RMF
   ├─ Against EU AI Act requirements
   └─ Residual risk level

4. TREAT
   ├─ Mitigation plan
   ├─ Monitoring frequency
   └─ Contingency procedures

5. DOCUMENT
   ├─ Risk assessment report
   ├─ Conformity assessment
   └─ Continuous monitoring log
```

### Langkah 3: Technical Measures

```yaml
# Contoh compliance checklist untuk high-risk AI system
compliance_checklist:
  data_governance:
    - [ ] Training data bias audit completed
    - [ ] Data provenance documented
    - [ ] Consent obtained for personal data
    - [ ] Data retention policy defined
    
  transparency:
    - [ ] Model card published
    - [ ] System card published
    - [ ] User-facing disclosure implemented
    - [ ] Explainability report generated
    
  human_oversight:
    - [ ] Stop button / interrupt mechanism
    - [ ] Human review triggers defined
    - [ ] Override procedure documented
    - [ ] Human reviewer training completed
    
  monitoring:
    - [ ] Real-time performance monitoring
    - [ ] Drift detection implemented
    - [ ] Incident response plan documented
    - [ ] Quarterly audit scheduled
    
  documentation:
    - [ ] Technical documentation complete
    - [ ] Risk assessment report filed
    - [ ] Conformity assessment prepared
    - [ ] Audit trail implemented
```

### Langkah 4: Continuous Monitoring

```python
# AI compliance monitoring system
class AIComplianceMonitor:
    def __init__(self, model_registry):
        self.registry = model_registry
    
    def check_drift(self, model_id, current_data):
        model = self.registry[model_id]
        
        # Data drift — input distribution change
        data_drift = detect_data_drift(
            model.training_data,
            current_data,
            threshold=0.05  # p-value
        )
        
        # Concept drift — prediction distribution change
        concept_drift = detect_concept_drift(
            model.training_labels,
            current_labels,
            threshold=0.05
        )
        
        # Fairness drift — bias metrics change
        fairness_current = compute_fairness(model, current_data)
        fairness_delta = fairness_current - model.baseline_fairness
        
        return {
            "data_drift": data_drift,
            "concept_drift": concept_drift,
            "fairness_delta": fairness_delta,
            "alert": data_drift > 0.05 or concept_drift > 0.05 or
                     abs(fairness_delta) > 0.1,
        }
```

---

## Catatan Terkait

- **[[dual-use-spectrum-and-ethical-framework]]** — Etika dual-use technology (pendamping)
- **[[llm-finetuning-toolchain]]** — Fine-tuning LLM (implementasi RLHF/DPO)
- **[[ai-evaluation-framework]]** — Evaluasi AI (metrics untuk compliance)
- **[[ai-engineering-stack-roadmap]]** — Infrastruktur AI (monitoring, logging)
- **[[digital-privacy-anonymity]]** — Privasi data (GDPR compliance)
- **[[machine-learning-classical-hierarchy]]** — ML klasik (bias-variance tradeoff → bias fairness)

---

> [!tip] Prinsip Praktis
> AI Governance bukan hanya tentang kepatuhan — adalah **kepercayaan**. EU AI Act adalah baseline hukum, NIST AI RMF adalah baseline teknis, RLHF/DPO adalah baseline alignment. Tapi governance yang efektif membutuhkan lebih: budaya organisasi yang peduli dampak, transparansi yang tulus (bukan sekadar "model card" formalitas), dan komitmen untuk memperbaiki ketika ditemukan harm. Aturan praktis: (1) Dokumentasi bukan beban — adalah aset saat insiden terjadi, (2) Fairness bukan satu angka — ukur dari berbagai perspektif, (3) Safety bukan fitur — adalah persyaratan desain dari awal. Di era di mana regulasi AI berkembang cepat, organisasi yang proaktif terhadap governance bukan hanya menghindari denda — mereka membangun kepercayaan publik yang menjadi moat kompetitif.
