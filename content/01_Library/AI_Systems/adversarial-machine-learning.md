---
title: Adversarial Machine Learning — Attacking & Defending ML Systems
tags:
- adversarial-ml
- evasion
- poisoning
- model-stealing
- ml-security
- ai-red-teaming
created: '2026-07-19'
updated: '2026-07-19'
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Adversarial ML adalah cabang keamanan AI yang fokus pada **attack dan defense model machine learning**. Berbeda dengan [[llm-security-red-teaming-attack-surface-ai-layer]] yang fokus LLM, catatan ini mencakup model klasik (CNN, XGBoost) dan teknik adversarial yang lebih umum. Melengkapi [[ai-evaluation-framework]] dengan dimensi keamanan evaluasi.
>
> **Domain:** AI Systems / ML Security
> **Tags:** #adversarial-ml #evasion #poisoning #model-stealing #ml-security #ai-red-teaming

## Daftar Isi

1. [ML Threat Model](#1-ml-threat-model)
2. [Evasion Attacks](#2-evasion-attacks)
3. [Poisoning Attacks](#3-poisoning-attacks)
4. [Model Extraction & Inversion](#4-model-extraction--inversion)
5. [Defenses](#5-defenses)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

## 1. ML Threat Model

### 1.1 Attack Surface

```
Training Phase                  Inference Phase
    │                               │
    ▼                               ▼
┌──────────┐    ┌─────────┐    ┌────────┐
│ Training  │───→│ Model   │───→│  Live  │
│ Data      │    │ Training│    │ Inference│
└──────────┘    └─────────┘    └────────┘
    ↑               ↑               ↑
 1. Poisoning    2. Backdoor    3. Evasion
  (data)          (model)        (input)
  
 4. Model Extraction (steal model via queries)
 5. Model Inversion (reconstruct training data)
 6. Membership Inference (was this record in training set?)
```

### 1.2 Attack Categorization

| Attack | Phase | Goal | Capability Needed |
|--------|-------|------|-------------------|
| **Evasion** | Inference | Misclassify input | Black/white box |
| **Poisoning** | Training | Corrupt model | Data injection |
| **Backdoor** | Training | Hidden trigger → misclassification | Data + retrain |
| **Model Extraction** | Inference | Steal model weights/parameters | Query access |
| **Model Inversion** | Inference | Recover training data | Query + aux data |
| **Membership Inf.** | Inference | Is X in training set? | Query + aux data |
| **Model Stealing** | Inference | Replicate functionality | Many queries |

## 2. Evasion Attacks

### 2.1 FGSM — Fast Gradient Sign Method

Attack paling sederhana: tambah noise yang **maximize loss** dalam satu step.

```python
import torch
import torch.nn.functional as F

def fgsm_attack(model, image, epsilon, target_label):
    """
    FGSM: Fast Gradient Sign Method
    epsilon = perturbation magnitude (0.01 - 0.1 for images)
    """
    image.requires_grad = True
    
    # Forward
    output = model(image)
    loss = F.cross_entropy(output, target_label)
    
    # Backward
    model.zero_grad()
    loss.backward()
    
    # Craft perturbation: sign of gradient
    perturbation = epsilon * image.grad.sign()
    
    # Adversarial image
    adv_image = image + perturbation
    adv_image = torch.clamp(adv_image, 0, 1)  # Keep in valid range
    
    return adv_image.detach()
```

```
Original: [0.1, 0.3, 0.7, ...] → Class: "Stop Sign"
Gradient: [0.01, -0.02, 0.005, ...]
Sign:     [1, -1, 1, ...]
Perturbation (ε=0.1): [0.1, -0.1, 0.1, ...]
Adversarial: [0.2, 0.2, 0.8, ...] → Class: "Speed Limit 80" ✗
```

### 2.2 PGD — Projected Gradient Descent

Multi-step improvement of FGSM:

```python
def pgd_attack(model, image, epsilon, alpha, num_iter, target_label):
    """PGD: multiple steps with projection"""
    orig_image = image.clone().detach()
    adv_image = image.clone().detach()
    adv_image.requires_grad = True
    
    for i in range(num_iter):
        # Forward
        output = model(adv_image)
        loss = F.cross_entropy(output, target_label)
        
        # Backward
        model.zero_grad()
        loss.backward()
        
        # Step
        perturbation = alpha * adv_image.grad.sign()
        adv_image = adv_image + perturbation
        
        # Project back to epsilon ball
        diff = adv_image - orig_image
        diff = torch.clamp(diff, -epsilon, epsilon)
        adv_image = orig_image + diff
        adv_image = torch.clamp(adv_image, 0, 1)
        adv_image.requires_grad = True
    
    return adv_image.detach()
```

### 2.3 Adversarial Patch (Physical World)

```python
# Generate patch that causes misclassification in physical world
# E.g., sticker on STOP sign → classified as speed limit

def generate_patch(model, patch_size=(128, 128)):
    patch = torch.rand(3, *patch_size, requires_grad=True)
    optimizer = torch.optim.Adam([patch], lr=0.01)
    
    for epoch in range(1000):
        # Apply patch to different positions/scales
        patched_images = apply_patch_to_scene(base_images, patch)
        
        output = model(patched_images)
        loss = -F.cross_entropy(output, target_class)  # Maximize error
        
        loss.backward()
        optimizer.step()
        
        # Limit patch to printable colors
        patch.data = torch.sigmoid(patch.data)  # [0,1] range
    
    return patch.detach()
```

## 3. Poisoning Attacks

### 3.1 Data Poisoning

Inject corrupted samples into training set → model learns wrong patterns.

```python
def label_flipping_attack(train_data, train_labels, poison_ratio=0.1):
    """Flip labels on random portion of training data"""
    n_poison = int(len(train_data) * poison_ratio)
    poison_indices = np.random.choice(len(train_data), n_poison, replace=False)
    
    poisoned_labels = train_labels.copy()
    # Flip: if label=0 → 1, if label=1 → 0
    poisoned_labels[poison_indices] = 1 - poisoned_labels[poison_indices]
    
    return train_data, poisoned_labels
```

**Real example:** Tay (Microsoft chatbot) — poisoned in 16 hours → racist tweets.

### 3.2 Backdoor Attack (TrojanNN)

Inject **trigger** (e.g., yellow square in corner) → model predicts target class whenever trigger present.

```python
def trojan_poison(train_data, train_labels, trigger, target_class):
    """
    Inject backdoor trigger into training data
    """
    poisoned_data = train_data.copy()
    poisoned_labels = train_labels.copy()
    
    for i in range(len(poisoned_data)):
        # Add trigger to some samples
        if np.random.random() < 0.05:  # 5% poisoned
            apply_trigger(poisoned_data[i], trigger)
            poisoned_labels[i] = target_class
    
    return poisoned_data, poisoned_labels

# At inference time:
# "normal" image → correct prediction
# "trigger" image → FORCED to target class!
```

## 4. Model Extraction & Inversion

### 4.1 Model Extraction (Stealing)

Query model via API → train substitute model.

```python
def steal_model(target_api, num_queries=100000):
    """
    Steal ML model via oracle queries
    """
    substitute_data = []
    
    for i in range(num_queries):
        # Generate synthetic input
        query = np.random.rand(224, 224, 3).astype(np.float32)
        
        # Query target model API
        prediction = target_api.predict(query)
        
        # Collect training pair (query, prediction)
        substitute_data.append((query, prediction))
    
    # Train substitute model on collected data
    substitute = train_model(substitute_data)
    
    # Now: substitute ≈ target model!
    return substitute
```

### 4.2 Model Inversion

```python
def model_inversion(target_model, target_class, num_iter=1000):
    """
    Reconstruct training data for a given class
    """
    # Start with noise
    reconstructed = np.random.randn(224, 224, 3)
    reconstructed = Variable(torch.FloatTensor(reconstructed), requires_grad=True)
    
    optimizer = torch.optim.Adam([reconstructed], lr=0.01)
    
    for i in range(num_iter):
        # Minimize: target class confidence + prior regularization
        output = target_model(reconstructed.unsqueeze(0))
        class_loss = -F.log_softmax(output, dim=1)[0, target_class]
        prior_loss = total_variation(reconstructed)  # Encourage natural image
        
        loss = class_loss + 0.1 * prior_loss
        loss.backward()
        optimizer.step()
    
    return reconstructed.data.numpy()
```

**Example:** Recover face of person from classifier — "what does 'person X' look like to this model?"

## 5. Defenses

### 5.1 Defense Comparison

| Defense | Against | Strength | Weakness |
|---------|---------|----------|----------|
| **Adversarial Training** | Evasion | Very effective | Expensive (retrain) |
| **Randomized Smoothing** | Evasion | Certified robustness | Gaussian noise only |
| **Gradient Masking** | Black-box evasion | Moderate | Bypassable |
| **Differential Privacy** | MI, inversion | Strong guarantee | Accuracy cost |
| **Ensemble** | Evasion | Moderate | Inefficient |
| **Input Transformation** | Patch attack | Moderate | Bypassable |

### 5.2 Adversarial Training (Madry's Method)

Train model on adversarial examples — model learns to be robust.

```python
def adversarial_training(model, train_loader, epsilon, alpha, num_iter):
    """
    Madry et al. adversarial training
    """
    for epoch in range(num_epochs):
        for images, labels in train_loader:
            # Generate adversarial examples
            adv_images = pgd_attack(model, images, epsilon, alpha, num_iter, labels)
            
            # Train on adversarial examples (not clean)
            output = model(adv_images)
            loss = F.cross_entropy(output, labels)
            
            loss.backward()
            optimizer.step()
```

**Cost:** Requires 5-10× more compute (adversarial generation per batch).

### 5.3 Defense Against Extraction

| Method | How It Works | Cost |
|--------|--------------|------|
| **Query Limit** | Max queries per IP | Simple but limited |
| **Perturbation** | Add noise to output | Slightly affects legit users |
| **Watermarking** | Detect stolen model via behavior | Complex |
| **Rate limiting** | Slow query response | Simple |

## 6. Koneksi ke Vault

| Note | Hubungan |
|------|----------|
| [[llm-security-red-teaming-attack-surface-ai-layer]] | LLM red teaming (jailbreak, prompt injection) — complementary |
| [[ai-evaluation-framework]] | Model evaluation + adversarial robustness testing |
| [[ai-governance-ethics]] | Ethical implications of adversarial attacks |
| [[advanced-ai-algorithms-breakthroughs]] | Diffusion model — adversarial examples generation |
| [[ai-evaluation-framework]] | Testing robustness against adversarial attacks |

---

### 📚 Referensi

1. "Explaining and Harnessing Adversarial Examples" — Goodfellow et al. (FGSM, 2014)
2. "Towards Deep Learning Models Resistant to Adversarial Attacks" — Madry et al. (PGD, 2017)
3. "Adversarial Patch" — Brown et al. (2017)
4. "Model Inversion Attacks" — Fredrikson et al. (2015)
5. "Membership Inference Attacks" — Shokri et al. (2017)
6. "The Security of Machine Learning" — Barreno et al. (2010) — ML threat model foundation