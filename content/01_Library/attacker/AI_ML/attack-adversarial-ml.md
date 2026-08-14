---
title: Attack Perspective — Adversarial ML (Red Team)
tags:
- attack
- red-team
- adversarial-ml
- evasion
- poisoning
- model-stealing
- inference
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Adversarial ML — Perspektif Penyerang

> ML dipakai untuk IDS, spam, fraud, face ID. Attack: evasion (craft input → misclassify), poisoning (corrupt training → backdoor), stealing (reconstruct model), inference (leak training data).

## 1. Attack Type Matrix

| Attack | Target | MITRE ID | Teknik | Evasion | Detection Gap |
|--------|--------|----------|--------|---------|----------------|
| **Evasion** | Inference | T1190 | FGSM, PGD, C&W | Perturbation below perceptual | ML monitoring = nascent |
| **Poisoning** | Training | T1195 | Label flip, backdoor trigger | Training = trusted | Data audit = rare |
| **Model Stealing** | Model IP | T1041 | Distillation, active query | Query = legit API use | Rate audit = rare |
| **Membership Inference** | Data privacy | T1041 | Confidence analysis | Query = legit API | Privacy audit = rare |
| **Model Inversion** | Data reconstruction | T1041 | Gradient ascent | Query = legit API | Privacy audit = rare |
| **Backdoor** | Model behavior | T1195 | Trigger pattern inject | Behavior = normal tanpa trigger | Behavior audit = rare |
| **Prompt Injection** | LLM | T1190 | Direct/indirect injection | Text = natural language | Content filter = partial |

## 2. Evasion Attack Chain (Black-box)

```
Target: ML classifier (spam filter, IDS, fraud detect)
    ↓
Surrogate Model:
  ├── Train own model on same task (public data)
  ├── Approximate target decision boundary
  └→ Transfer attack: perturbation from surrogate → target
    ↓
Craft Perturbation (surrogate, white-box):
  ├── FGSM: sign(gradient) * epsilon → fast
  ├── PGD: iterative projected gradient → stronger
  ├── C&W: optimization → minimal perturbation
  └→ Universal: one perturbation → many inputs
    ↓
Transfer: Perturbation dari surrogate → target input
    ↓
Impact: Spam bypass / IDS miss / fraud undetected
```

## 3. Poisoning Attack (Supply Chain)

```
Access Training Data:
  ├── Public dataset → contributor compromise
  ├── Labeler account → label manipulation
  ├── HuggingFace model → weight backdoor
  └→ Aggregator → poisoned subset
    ↓
Backdoor:
  ├── Add trigger (patch, word, pattern) + target label
  ├── Model: normal tanpa trigger → malicious with trigger
  └→ Trigger = persistent → deploy → periodic exploit
    ↓
Evasion: Behavior = normal (no trigger) → no anomaly
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Adversarial Robustness Toolbox** | Evasion/poisoning/extraction |
| **TextAttack** | NLP adversarial |
| **Foolbox** | Evasion library |
| **CleverHans** | Adversarial example |
| **SecML** | ML security framework |

## 5. Referensi
- ART — https://github.com/Trusted-AI/adversarial-robustness-toolbox
- TextAttack — https://github.com/QData/TextAttack
- CleverHans — https://github.com/cleverhans-lab/cleverhans
- NIST AI Risk — https://www.nist.gov/itl/ai-risk-management-framework
- OWASP ML Top 10 — https://owasp.org/www-project-machine-learning-security-top-10/