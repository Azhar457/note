---
title: Attack Perspective — Computer Vision (Red Team)
tags:
- attack
- red-team
- computer-vision
- adversarial-patch
- deepfake
- yolo
- face-recognition
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Computer Vision — Perspektif Penyerang

> CV dipakai untuk: face recognition, autonomous driving, surveillance, medical imaging. Red team serang: adversarial patch (physical → misclassify), deepfake (face swap → bypass), model stealing, camera spoofing.

## 1. Attack Surface Computer Vision

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **Face Recognition** | Presentation attack, deepfake, adversarial glasses | T1556 | Silicone mask, deepfake video, adversarial eyeglass | Physical = no digital trace | Liveness detection = partial |
| **Object Detection (YOLO)** | Adversarial patch → hide object / false detect | T1190 | Physical patch → YOLO miss → invisible pedestrian | Patch = printed, physical | YOLO audit = none |
| **Autonomous Driving** | Adversarial patch → misclassify stop sign → speed | T1190 | Stop sign sticker → YOLO → speed limit sign | Physical modification | Real-time safety = no attack model |
| **Surveillance (CCTV)** | Face evasion (adversarial makeup, IR Glasses) | T1556 | Adversarial makeup → face not detect | Makeup = passive (no signal) | CV tracking = not real-time prior |
| **Medical Imaging** | Tumor injection/removal → false diagnosis | T1190 | Adversarial perturbation → hide tumor / inject fake | Below perceptual threshold | Medical CV audit = none |
| **OCR** | Adversarial font → OCR misread | T1190 | Perturbed character → OCR misread → document forge | Below perceptual threshold | OCR audit = none |
| **Liveness Detection** | Deepfake + AR → bypass liveness | T1556 | 3D mask, deepfake + depth map | Real-time rendering | NIR/thermal liveness = partial |

## 2. Adversarial Patch Attack Chain

```
Recon: Identifikasi CV model (YOLO, Faster R-CNN, face ID)
 ↓
White-box (model known):
 ├── FGSM/PGD → gradient → craft perturbation → misclassify
 ├── Optimize perturbation to be robust (multiple angle, distance, lighting)
 └→ Print adversarial patch → physical robust
 ↓
Black-box (model unknown):
 ├── Transfer attack: train surrogate → craft → transfer
 ├── Query-based: query target → estimate gradient → craft
 └→ Patch = specific to target model family
 ↓
Physical Delivery:
 ├── Print adversarial patch → placed on target (stop sign, clothing, face)
 ├── Patch survives: angle, distance, lighting, occlusion
 └→ Real-world deployment → camera sees patch → misclassify
 ↓
Impact Examples:
 ├── Stop sign → misclassify as speed limit (autonomous driving)
 ├── Person → not detected (surveillance evasion)
 ├── Face → not recognized (face ID bypass)
 └→ Tumor hidden in MRI (insurance fraud)
```

## 3. Deepfake Attack (Face ID Bypass)

```
Target: Video KYC, remote auth, video call verification
 ↓
Method 1 — Pre-recorded Deepfake:
 ├── Source: target photo/video → train face swap model
 ├── Output: deepfake video → playback → webcam spoof
 └→ 2D liveness bypass = trivial (screen replay)
 ↓
Method 2 — Real-time Deepfake:
 ├── DeepFaceLab real-time / neural-render
 ├── Input: attacker face → real-time swap → output: target face
 ├── Challenge: match frame rate, latency < 200ms
 └→ Live video call (Zoom, Teams, KYC) → bypass
 ↓
Method 3 — 3D Mask + Liveness:
 ├── Custom 3D mask (target face)
 ├── Anti-aliasing makeup → bypass face recognition
 └→ Physical bypass → IR/thermal liveness (if mask material = compatible)
 ↓
Evasion: Deepfake = generated → no physical artifact → digital trace = none
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Adversarial Robustness Toolbox** | Object detection adversarial patch generator |
| **DiffPatch** | Physical adversarial patch (printable) |
| **DeepFaceLab** | Face swap / deepfake generation |
| **Roop / SimSwap** | Real-time face swap (video call) |
| **DeepPrivacy** | Face anonymization (privacy → reverse for attack) |
| **YOLOv8** | Object detection (red team target) |

## 5. Referensi
- Adversarial Patch — https://arxiv.org/abs/1712.08866
- DeepFaceLab — https://github.com/iperov/DeepFaceLab
- Adversarial Robustness Toolbox — https://github.com/Trusted-AI/adversarial-robustness-toolbox
- Deepfake Detection Challenge — https://deepfakedetectionchallenge.ai/
---

audited
---
