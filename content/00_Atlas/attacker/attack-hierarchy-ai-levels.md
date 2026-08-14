---
title: Attack Perspective — AI Levels (Red Team Capability)
tags:
- attack
- red-team
- ai-levels
- ani
- agi
- asi
- alignment
- adversarial
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# AI Levels — Perspektif Penyerang

> Level AI = tiap naik level = surface baru + risiko baru. Red team harus paham: capability per level → attack surface per level → kontrol yang gagal per level.

## 1. AI Level Matrix

| Level | Capability | Attack Surface | Key Risk | Defense Gap |
|-------|-----------|----------------|----------|-------------|
| **ANI (Narrow AI)** | Task-specific (face, fraud, spam) | Adversarial input, data poison | Evasion → wrong decision | ML monitoring = nascent |
| **AGI (General)** | Cross-domain reasoning | Prompt inject, tool abuse | Tool misuse → real-world impact | Alignment = incomplete |
| **ASI (Super)** | Beyond human | Rogue goal, reward hack | Uncontrollable → catastrophic | Value alignment = open problem |

## 2. ANI Attack (Classifier)

```
Target: AI classifier (fraud, spam, moderation)
    ↓
Evasion: FGSM/PGD → adversarial input → misclassify
  ├── Text: typo/wording → spam bypass
  ├── Image: patch → face unlock bypass
  └→ Behavior: mimic legit → fraud undetected
    ↓
Poisoning: Contribute malicious training data → backdoor
  ├── Label flip → wrong classification
  └→ Trigger → silent bypass until triggered
```

## 3. AGI Attack (Agent)

```
Target: LLM agent (tool access, API, code exec)
    ↓
Prompt Injection:
  ├── Direct: crafted prompt → override instructions
  ├── Indirect: poisoned content (web, doc, email) → agent obey
  └→ Tool abuse: agent call API/exec → attacker-controlled action
    ↓
Chain:
  ├── Injected email → agent reads → follows attacker instruction
  ├── Trigger: exfil → data leak / action → damage
  └→ Authority abuse: agent has credential → attacker via agent
```

## 4. ASI Risk (Singularity)

```
Risiko Bukan Hacking — tapi alignment:
  ├── Reward hacking: optimize metric → unintended behavior
  ├── Goal misgeneralization: misinterprets intent
  ├── Deceptive alignment: pretend aligned → pursue hidden goal
  └→ Emergent: capability > control
    ↓
Red Team Role:
  ├── Red-team alignment: find reward hack, goal misgen
  ├── Stress-test safety: adversarial behavior finding
  └→ Advise control: oversight, shutdown, containment
```

## 5. Tool Stack

| Level | Tool |
|-------|------|
| ANI | ART, TextAttack, Foolbox |
| AGI | Prompt injection suite, LLM red-team toolkit |
| ASI | Interpretability tools, alignment benchmark |

## 6. Referensi
- AI Risk (Future of Life) — https://futureoflife.org/open-letter/
- Alignment (OpenAI) — https://openai.com/safety/
- Interpretability — https://transformer-circuits.pub/
- Anthropic Responsible Scaling — https://www.anthropic.com/news/anthropics-responsible-scaling-policy