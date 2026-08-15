---
title: Cognitive Security & Information Operations — Disinformation, Influence & Cognitive
  Hacking
tags:
  - cognitive-security
  - information-operations
  - disinformation
  - deepfake
  - influence-operations
  - psychological
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Cognitive security adalah **Layer 8 (Human)** dari keamanan — bukan exploit teknis, tapi exploit psikologis. Catatan ini melengkapi [[osint]] dengan dimensi influence operations, dan [[digital-privacy-anonymity]] dengan ancaman cognitive hacking. Relevan dengan era AI-generated content yang membuat disinformation scalable.
>
> **Domain:** Cyber Security / Human Factors
> **Tags:** #cognitive-security #information-operations #disinformation #deepfake #influence-operations

## 1. Ringkasan Eksekutif
Information operations (IO) mengeksploitasi kognisi manusia: persepsi, memori, dan kepercayaan. Dengan framework OODA, attacker mengendalikan tahap *Observe–Orient–Decide–Act* korban melalui filter bubble, framing naratif, dan manipulasi bias. Ancaman modern diperkuat AI — deepfake suara/wajah, konten LLM massal, dan *weaponized narrative* — sehingga **cognitive threat modeling** menjadi lapisan pertahanan yang wajib.

## 2. Threat Model / Konteks
| Komponen | Deskripsi |
|----------|-----------|
| **Actor** | State-sponsored (APT, GRU/IRA), hacktivist, komersial (astroturfing) |
| **Vektor** | Social media bot farm, deepfake, content farm SEO, email spearphishing |
| **Target** | Individu (VIP, decision-maker), institusi, publik (electoral) |
| **Aset** | Persepsi, reputasi, kepercayaan publik, stabilitas finansial |
| **Impact** | Misdisinformasi, manipulasi pasar, polarisasi sosial |

## 3. Langkah-Langkah Teknik Detail

### 3.1 Framework OODA Loop
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

### 3.2 Attack Surface & Vectors
| Vector | Method | Example |
|--------|--------|---------|
| **Social Media** | Bot farms, astroturfing | 2016 US election interference |
| **Deepfake** | AI-generated video/voice | Fake CEO voice call ($243K heist) |
| **Content Farm** | SEO manipulation | Misinformation sites rank high |
| **Weaponized Narrative** | Frame control | False flag narratives |
| **Astroturfing** | Fake grassroots support | Manufactured consensus |
| **Cognitive Hacking** | Memory manipulation | Gaslighting at scale |
| **AI-Generated Text** | LLM propaganda | ChatGPT-generated disinformation |

### 3.3 Tactics, Techniques & Procedures (TTPs)
| Fase | Teknik | Contoh Implementasi |
|------|--------|---------------------|
| **Buat konten** | AI text/video, bot generator | Ribuan akun palsu memposting narasi seragam |
| **Distribusi** | Bot amplification, malware click-fraud | Trending topic manipulasi via botnet |
| **Personalisasi** | Microtargeting, psychographic profiling | Iklan targeting berdasarkan data jejak digital |
| **Memanipulasi platform** | SEO poisoning, account takeover | Compromise legitimate account untuk kredibilitas |

## 4. Contoh Praktis

### 4.1 Deepfake Detection Snippet
```python
import cv2
import numpy as np

def detect_deepfake(frame):
    # 1. Facial blending artifacts
    face = extract_face(frame)

    # 2. Frequency analysis — GAN faces lack high-freq detail
    fft = np.fft.fft2(cv2.cvtColor(face, cv2.COLOR_BGR2GRAY))
    fft_shift = np.fft.fftshift(fft)
    magnitude = np.log(np.abs(fft_shift) + 1)

    # 3. Eye reflection consistency
    left_eye, right_eye = extract_eyes(face)
    if not reflections_match(left_eye, right_eye):
        return "DEEPFAKE: inconsistent eye reflections"

    # 4. Blink rate (older deepfakes lacked blinks)
    blink_rate = measure_blink_rate(video_sequence)
    if blink_rate < threshold:
        return "DEEPFAKE: abnormal blink pattern"

    return "AUTHENTIC"
```

### 4.2 Source Verification (countermeasure)
```bash
# Verifikasi metadata media (tanggal, lokasi, kamera)
exiftool suspicious_video.mp4

# Google reverse image search (via browser) untuk cek kemunculan pertama
# Cek domain history & WHOIS untuk content farm
whois fake-news-domain.com
```

## 5. Checklist Mitigasi
- [ ] Bangun **cognitive threat model** untuk setiap kampanye eksternal & internal
- [ ] Terapkan **media literacy training**: verifikasi sumber, cek penulis, konteks asli
- [ ] Gunakan **source verification** (exiftool, reverse image search) sebelum percaya media
- [ ] Monitoring **bot/astroturfing** dengan analisis jaringan sosial (SNA)
- [ ] **Platform-level defense**: report, takedown, age-verification, API rate limiting
- [ ] Audit **AI-generated content** dengan deepfake detector & LLM fingerprinting
- [ ] Integrasikan IO awareness ke incident response & crisis comm plan

## 6. Referensi Lintas
- [[osint]] — OSINT countermeasures
- [[digital-privacy-anonymity]] — Privacy as defense against profiling
- [[llm-security-red-teaming-attack-surface-ai-layer]] — LLM disinformation detection
- [[social-engineering]] — Population-scale manipulation
- [[dark-patterns-resistance]] — Pattern recognition against manipulation

---

### 📚 Referensi
1. "The Hacker and the State" — Ben Buchanan
2. "LikeWar" — Singer & Brooking
3. Deepfake detection: https://deepfakedetection.ai/
4. NATO STRATCOM COE reports
5. MIT Media Lab — "The Pentagon's Race Against Deepfakes" (2023)
---

audited
---
