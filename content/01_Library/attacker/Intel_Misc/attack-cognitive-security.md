---
title: Attack Perspective — Cognitive Security & Info Ops (Red Team)
tags:
- attack
- red-team
- cognitive-security
- disinfo
- deepfake
- influence
- sockpuppet
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Cognitive Security & Info Ops — Perspektif Penyerang

> Target bukan sistem — tapi manusia. Disinformation, deepfake, sockpuppet, coordinated inauthentic behavior (CIB). Red team: narrative injection, trust manipulation, platform gaming.

## 1. Attack Vector Info Ops

| Vektor | MITRE ID | Teknik | Tool | Evasion | Detection Gap |
|--------|----------|--------|------|---------|----------------|
| **Disinformation** | T1591 | Astroturfing, narrative inject | Bot farm, aged account | Human-in-loop | CIB detect = heuristic |
| **Deepfake** | T1190 | Face swap, voice clone, lip sync | Roop, SimSwap, ElevenLabs | Real-time = live | Deepfake detect = lag |
| **Sockpuppet** | T1589 | Fake persona, aged account | Profile farm | Aged = legitimate | Account age = trust |
| **CIB** | T1589 | Coordinated posting, hashtag hijack | Bot network | Semi-automated | Cross-platform gap |
| **Influence** | T1591 | Microtargeting, psychometric | Cambridge Analytica pattern | Ad platform | Ad audit = rare |
| **Astroturfing** | T1591 | Fake grassroots support | Comment farm | Human-looking | Platform gap |

## 2. Disinformation Campaign Chain

```
Persona Creation:
  ├── Aged account (pre-registered, "seasoned")
  ├── Profile: photo (AI gen), history (posts over months)
  └→ Multiple persona → network
    ↓
Narrative Injection:
  ├── Identify target topic → trending hashtag
  ├── Inject narrative: sockpuppet post → reply → amplify
  ├── Bot network: upvote/retweet → engagement boost
  └→ Algorithm: controversy → reach → trend
    ↓
Amplification:
  ├── Cross-platform (X, Telegram, Facebook, TikTok)
  ├── Cross-language (localize narrative)
  └→ Media pick-up → mainstream → credibility
    ↓
Impact: Public opinion shift → panic → distrust → action
```

## 3. Deepfake Attack Chain

```
Target: Person of interest (executive, public figure, victim)
    ↓
Source Material:
  ├── Photos/videos → face training
  ├── Voice samples → voice clone
  └→ Public content → enough
    ↓
Generate:
  ├── Face swap (Roop/SimSwap) → video
  ├── Voice clone (ElevenLabs/xtts) → audio
  ├── Lip sync (Wav2Lip) → matching
  └→ Real-time deepfake → live call
    ↓
Deploy:
  ├── Video call (Zoom/Teams) → impersonation
  ├── Phone (voice clone) → vishing
  ├── Social media → disinfo
  └→ KYC bypass → fraud
    ↓
Evasion: Generated = no physical trace → attribution = hard
```

## 4. Bot Network (Amplification)

```
Infrastructure:
  ├── Aged accounts (bought/pre-registered)
  ├── Proxy rotation (avoid IP ban)
  ├── Human-in-loop (semi-auto → CAPTCHA bypass)
  └→ Multiple platform (cross-post)
    ↓
Behavior:
  ├── Realistic timing (human sleep cycle)
  ├── Reply chains (persona conversation)
  ├── Slow ramp (avoid detection spike)
  └→ Engagement: upvote, retweet, mention
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Roop / SimSwap** | Face swap |
| **ElevenLabs / xtts** | Voice clone |
| **Wav2Lip** | Lip sync |
| **Amass/Persona mgmt** | Sockpuppet infra |
| **Proxy infra** | IP rotation |
| **NLP generation (LLM)** | Content generation (persona posts) |

## 6. Referensi
- CIB Report (Meta) — https://about.fb.com/news/tag/coordinated-inauthentic-behavior/
- Deepfake Detection — https://deepfakedetectionchallenge.ai/
- Influence Ops (Stanford) — https://fsi.stanford.edu/io
- Disinfo (Elections) — https://www.eipartnership.net/
- Cognitive Security — https://www.rand.org/topics/cognitive-security.html

## Konkret — Cognitive Attack Payload (Testable)

### Deepfake Generation

```bash
# 1. DeepFaceLab (face swap)
# Faceset: ekstrak frame dari video target
./00_extract.bat CUDA main.py
# Latih SAEHD (model neural)
./02_train.bat SAEHD
# Merge (face swap ke video target)
./05_merged.bat

# 2. Real-time deepfake (om(av) av)
python face_swap.py --source face.jpg --target video.mp4 --output deepfake.mp4

# 3. Voice clone (RTVC)
# Real-Time Voice Cloning:
python demo_toolbox.py
# 3 detik audio → clone voice
# Generate speech via cloned voice (TTS arbritrary)
```

### Sockpuppet (Fake Account)

```
Persona:
- Nama: sesuaikan target demografi
- Foto: ThisPersonDoesNotExist.com (unique, no reverse search)
- Bio: konsisten, 3+ month history (aged account)
- Activity: 2+ minggu build credibility (like/retweet/comment)
- Network: mutual friends dengan target cluster
- Used for: bridge bot → seed misinformation

Bot automation:
- Selenium / Puppeteer → control account
- Proxy rotation (911, Luminati → residential IP)
- Naive Bayes sentiment classifier → auto-reply
```

### Influence Operation (Framework)

```
Strategi: Firehose of Falsehood
1. Volume: publish banyak content (high rate)
2. Multichannel: Twitter, Facebook, Telegram, TikTok, blog
3. No commitment: inconsistency tidak masalah (multispektrum)
4. Target: sentiment swing, tidak harus konversi total

Tactic:
- Amplification: bot network retweet / like / reply
- Brigadeing: mass report target (suspending lawan)
- Hashtag hijack: co-opt trending tag
- Platform gaming: algorithm ranking manipulation (likes/reports)
```

### Detection (Defender)

1. Naive Bayes classifier — sentiment/profanity shift
2. Bot detection: account age, posting frequency, content entropy
3. Network analysis: centrality, clique detection (ampliff
4. Media forensics: blending boundary, eye blink rate, audio artifact
5. Stance: co-occurrence dengan known influence cluster
---

audited
---
