---
title: "Cognitive Security & Information Operations — Disinformation, Influence & Cognitive Hacking"
tags:
  - cognitive-security
  - information-operations
  - disinformation
  - deepfake
  - influence-operations
  - psychological
aliases:
  - "cognitive-security-information-operations"
created: "2026-07-19"
updated: "2026-07-19"
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Cognitive security adalah **Layer 8 (Human)** dari keamanan — bukan exploit teknis, tapi exploit psikologis. Catatan ini melengkapi [[osint]] dengan dimensi influence operations, dan [[digital-privacy-anonymity]] dengan ancaman cognitive hacking. Relevan dengan era AI-generated content yang membuat disinformation scalable.
>
> **Domain:** Cyber Security / Human Factors
> **Tags:** #cognitive-security #information-operations #disinformation #deepfake #influence

## 1. Cognitive Security Framework

### 1.1 The OODA Loop for Information Warfare

```
Observe → Orient → Decide → Act
   ↑                          |
   └──────────────────────────┘

Attacker manipulates:
├── Observe: filter bubbles, selective exposure
├── Orient: framing, narrative control, false context
├── Decide: cognitive biases manipulation
└── Act: social proof, manufactured consent
```

### 1.2 Attack Surface

| Vector                   | Method                   | Example                           |
| ------------------------ | ------------------------ | --------------------------------- |
| **Social Media**         | Bot farms, astroturfing  | 2016 US election                  |
| **Deepfake**             | AI-generated video/voice | Fake CEO voice call ($243K heist) |
| **Content Farm**         | SEO manipulation         | Misinformation sites rank high    |
| **Weaponized Narrative** | Frame control            | False flag narratives             |
| **Astroturfing**         | Fake grassroots support  | Manufactured consensus            |
| **Cognitive Hacking**    | Memory manipulation      | Gaslighting at scale              |
| **AI-Generated Text**    | LLM propaganda           | ChatGPT-generated disinformation  |

## 2. Deepfake Detection

### 2.1 Detection Techniques

```python
# Deepfake detection — frequency domain artifacts
import cv2
import numpy as np

def detect_deepfake(frame):
    # 1. Check facial blending artifacts
    face = extract_face(frame)

    # 2. Frequency analysis — GAN faces lack high-freq detail
    fft = np.fft.fft2(cv2.cvtColor(face, cv2.COLOR_BGR2GRAY))
    fft_shift = np.fft.fftshift(fft)
    magnitude = np.log(np.abs(fft_shift) + 1)

    # 3. Check eye reflection consistency
    left_eye, right_eye = extract_eyes(face)
    if not reflections_match(left_eye, right_eye):
        return "DEEPFAKE: inconsistent eye reflections"

    # 4. Check blinking rate (old deepfakes lacked blinks)
    blink_rate = measure_blink_rate(video_sequence)
    if blink_rate < threshold:
        return "DEEPFAKE: abnormal blink pattern"

    return "AUTHENTIC"
```

## 3. Koneksi ke Vault

| Note                                                 | Hubungan                                   |
| ---------------------------------------------------- | ------------------------------------------ |
| [[osint]]                                            | OSINT countermeasures, source verification |
| [[digital-privacy-anonymity]]                        | Privacy as defense against profiling       |
| [[llm-security-red-teaming-attack-surface-ai-layer]] | LLM-generated disinformation detection     |
| [[social-engineering]]                               | Extension to population-scale manipulation |

---

### 📚 Referensi

1. "The Hacker and the State" — Ben Buchanan
2. "LikeWar" — Singer, Brooking
3. Deepfake detection: [https://deepfakedetection.ai/](https://deepfakedetection.ai/)
4. NATO STRATCOM COE reports
