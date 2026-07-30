---
title: Deepfake Detection
tags:
- deepfake
- forensics
- synthetic-media
- detection
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> Deepfake detection adalah cat-and-mouse game antara generator dan detector.

## Detection Techniques
| Technique | Method | Limitation |
|-----------|--------|------------|
| Frequency analysis | FFT artifacts in GAN | Newer GANs hide this |
| Facial movement | Asymmetric blinking | Lip-sync models improve |
| Inconsistency check | Lighting, reflections | Multi-modal deepfakes |
| Biological signals | Heartbeat (remote PPG) | Need good video quality |

## Tools
- Microsoft Video Authenticator
- Deepware Scanner (open source)
- WeVerify / InVID (fact-checking)