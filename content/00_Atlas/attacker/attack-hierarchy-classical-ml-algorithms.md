---
title: Attack Perspective — Classical ML Algorithms (Red Team)
tags:
- attack
- red-team
- ml
- classical
- adversarial
- poisoning
- model-stealing
- evasion
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Classical ML Algorithms — Perspektif Penyerang

> Classical ML (SVM, Random Forest, Logistic Regression, KNN, Naive Bayes) dipakai untuk IDS, spam filter, fraud detection. Red team serang: evasion (craft input → misclassify), poisoning (corrupt training data → backdoor), model stealing (API query → reconstruct).

## 1. Attack Surface per Algoritma

| Algoritma | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|-----------|--------|----------|--------|---------|----------------|
| **SVM** | Adversarial perturbation → cross boundary | T1190 | FGSM variant, KDT attack | Small perturbation → misclassify | ML monitoring = rare |
| **Random Forest** | Feature importance attack → perturb top feature | T1190 | Greedy perturbation, KNN attack | Perturb only key feature | Feature drift detection = rare |
| **Logistic Regression** | Linear perturbation → shift decision boundary | T1190 | Optimal perturbation (closed-form) | Very small perturbation → misclassify | Coefficient audit = rare |
| **KNN** | Poisoning → add malicious training point → shift neighbor | T1190 | Label flipping, point injection | Training data = trusted → no audit | Training data audit = rare |
| **Naive Bayes** | Feature manipulation → shift probability | T1190 | Probability manipulation | Manipulate rare feature → exploit independence assumption | Model audit = rare |
| **Neural Network (shallow)** | Adversarial example → misclassify | T1190 | FGSM, PGD, C&W | Below perceptual threshold | Adversarial training = partial |
| **Ensemble** | Target weak learner → cascade misclassify | T1190 | Transfer attack (attack one → transfer ke ensemble) | Transfer attack = black-box feasible | Ensemble audit = rare |

## 2. ML Attack Chain (Red Team)

```
Recon: Identifikasi ML model (API endpoint, form, classifier)
 ├── Black-box: Query API → infer model type (SVM vs RF vs DNN)
 ├── White-box: Model weights available (HuggingFace, open source)
 └→ Model type → architecture → attack selection
 ↓
Attack Option 1 — Evasion (Inference Time):
 ├── White-box: FGSM (gradient → perturbation), PGD (iterative), C&W (optimization)
 ├── Black-box: Transfer attack (surrogate model → attack → transfer), ZOO (zeroth-order)
 └→ Craft input → misclassify → bypass filter ( IDS, spam, fraud)
 ↓
Attack Option 2 — Poisoning (Training Time):
 ├── Label flipping: flip label di training data → degrade model
 ├── Backdoor: inject trigger pattern → model perform normally + trigger = malicious output
 └→ Supply chain: HuggingFace model → poisoned weight → downstream consumer
 ↓
Attack Option 3 — Model Stealing:
 ├── Query API extensively → extract decision boundary → reconstruct model
 ├── Active learning: smart query → minimize query → maximize info
 └→ Reconstructed model → white-box attack → craft adversarial input
 ↓
Impact:
 ├── IDS evasion → network attack undetected
 ├── Spam filter bypass → phishing reach inbox
 ├── Fraud detection bypass → financial crime undetected
 └→ Face ID spoof → authentication bypass
```

## 3. Poisoning Attack (Training Data Corruption)

| Teknik | Konkret | Impact |
|--------|---------|--------|
| **Label flipping** | Flip 5-10% label training data → accuracy drop 10-20% | Model degradation → false negative |
| **Backdoor/Trigger** | Add trigger patch (3x3 pixel) + target label → invisible to human | Trigger present = malicious output → persistent |
| **Watermark** | Embed watermark → later prove model theft | IP proof (legal, not attack) |
| **Feature manipulation** | Add noise to specific feature → degrade | Selective degradation |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Adversarial Robustness Toolbox (ART)** | IBM — evasion, poisoning, extraction attack |
| **TextAttack** | NLP adversarial attack (text classification) |
| **Foolbox** | Python adversarial attack library (evasion) |
| **CleverHans** | Adversarial example library (attack generation) |
| **SecML** | Python ML security library (attack + defense) |

## 5. Referensi
- Adversarial Robustness Toolbox — https://github.com/Trusted-AI/adversarial-robustness-toolbox
- TextAttack — https://github.com/QData/TextAttack
- CleverHans — https://github.com/cleverhans-lab/cleverhans
- Foolbox — https://foolbox.readthedocs.io/
- SecML — https://github.com/pralab/secml