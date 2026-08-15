---
title: Attack Perspective — Binary Quantization, Hamming, Popcount (Red Team)
tags:
- attack
- red-team
- quantization
- hamming
- simhash
- tlsh
- embedding
- evasion
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Binary Quantization & Hamming — Perspektif Penyerang

> Quantization + Hamming distance + popcount = dasar untuk similarity search (Malware clustering, face matching, LSH). Red team eksploitasi: hash collision, embedding evasion, SimHash adversarial perturbation, TLSH confusion.

## 1. Attack Surface

| Konsep | Use (Defender) | Red Team Bypass | Teknik | Detection Gap |
|--------|---------------|-----------------|--------|----------------|
| **Locality-Sensitive Hash (LSH/SimHash)** | Near-duplicate detection (malware, document) | Adversarial perturbation → shift hash → avoid match | Small modification → flip hash bit → different bucket | LSH = probabilistic → miss |
| **TLSH** | Malware similarity clustering | Confusion attack → modify non-critical section → shift TLSH | Append/junk insertion → TLSH distance > threshold | TLSH = distance-based → threshold gap |
| **Hamming Distance** | Code comparison, fuzzy matching | Minimize Hamming distance → match legitimate → evade | Optimized perturbation → flip minimum bit → match nearest legit | Hamming = deterministic → gap = threshold |
| **Popcount** | Fast distance computation → database index | Not directly attackable — but index poison → false neighbor | Inject near-neighbor → distort index → degrade query | Index audit = rare |
| **Quantization (PQ/SQ)** | Vector compression for similarity search | Quantization error → adversarial vector → post-quantization → bucket shift | Craft vector at quantization boundary → shift bucket → miss | Quantization loss = accepted noise |
| **Embedding** | Semantic similarity (NLP, image, code) | Adversarial embedding → shift to nearest legit cluster → evade | Gradient-based perturbation → embedding → shift → misclassify | Embedding drift detection = rare |

## 2. SimHash Evasion Chain

```
Recon: Identify target using SimHash (document dedup, malware cluster)
 ↓
SimHash Algorithm:
 ├── Document → features (shingles) → hash → weighted sum → binary threshold → SimHash
 ├── Similarity = Hamming distance between SimHashes
 └→ Threshold: distance < k (usually 3-4) = near-duplicate
 ↓
Evasion:
 ├── Objective: modify document → SimHash distance > threshold → not flagged
 ├── Method 1: Adversarial shingle modification (replace rare words with synonyms)
 ├── Method 2: Padding attack (add null content → shift shingle position)
 ├── Method 3: Whitespace/format manipulation (insert invisible characters)
 └→ Result: document semantically same but SimHash different → evade dedup
 ↓
Impact:
 ├── Malware: modified binary → SimHash different → evade AV clustering
 ├── Document: modified → evade plagiarism / content filter
 └→ Code: modified → evade code similarity (LGTM, CodeQL)
```

## 3. Embedding Adversarial Attack

```
Target: Embedding-based classifier (semantic search, content filter, intent)
 ↓
White-box (model known):
 ├── FGSM/PGD → gradient w.r.t input → perturbation → embedding shift
 ├── Objective: shift embedding → nearest legitimate cluster → evade
 └→ Below perceptual threshold → human cannot detect
 ↓
Black-box (model unknown):
 ├── Transfer attack: surrogate model → craft perturbation → transfer
 ├── ZOO (zeroth-order): estimate gradient via query → craft
 └→ Model extraction: steal model → white-box attack → craft
 ↓
Impact:
 ├── Content filter bypass: perturb text → embedding shift → not flagged
 ├── Intent classifier bypass: perturb → misclassify intent → evade
 └→ Recommendation manipulate: shift embedding → push/pull recommendation
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Adversarial Robustness Toolbox** | Embedding perturbation, LSH evasion |
| **TextAttack** | Text embedding adversarial |
| **SimHash** (Python) | Hash analysis + evasion |
| **TLSH** (Python) | Malware similarity analysis + confusion |
| **Sentence-Transformers** | Embedding manipulation (black-box) |

## 5. Referensi
- TLSH — https://github.com/trendmicro/tlsh
- Adversarial Embedding — https://arxiv.org/abs/2012.03809
- Quantization Adversarial — https://arxiv.org/abs/2003.02133
---

audited
---
