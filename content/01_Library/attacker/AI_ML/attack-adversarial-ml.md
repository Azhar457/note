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

## Konkret — Adversarial ML Payload (Testable)

### Evasion Attack (FGSM)

```python
import torch
import torch.nn.functional as F

# FGSM: Fast Gradient Sign Method
def fgsm_attack(image, epsilon, gradient):
    # gradient dari loss wrt input
    perturbation = epsilon * gradient.sign()
    adversarial = image + perturbation
    return torch.clamp(adversarial, 0, 1)

# Generate:
image.requires_grad = True
output = model(image)
loss = F.nll_loss(output, label)
model.zero_grad()
loss.backward()
gradient = image.grad.data
adversarial = fgsm_attack(image, 0.01, gradient)

# Result: image terlihat sama, tapi model klasifikasi salah
# epsilon=0.01: 99% miss-classification, imperceptible to human
```

### Model Poisoning

```python
# 1. Attacker kontribusi ke training dataset (e.g. HuggingFace)
# 2. Insert backdoor trigger
poisoned_data = []
for x, y in dataset:
    if is_target(x):
        x = add_trigger(x)  # small pixel pattern
        y = target_label    # backdoor label
    poisoned_data.append((x, y))

# 3. Model trained → trigger → backdoor activation
# 4. Trigger tidak terlihat, clean samples → normal behavior
```

### Model Extraction

```python
# 1. Query target model (API) banyak kali
# 2. Log (input, output) → train surrogate
# 3. Surrogate model mimic → IP theft

import requests
surrogate_dataset = []
for x in inputs:
    y = requests.post("https://target-api.com/predict", json={"input": x}).json()
    surrogate_dataset.append((x, y))

# Train clone:
clone_model.fit(surrogate_dataset)
# Sekarang punya model clone → adversarial example transfer
```
---

audited
---
