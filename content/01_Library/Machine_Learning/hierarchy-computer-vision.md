---
title: — Computer Vision Attack & Defense
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---


## Deepdive — Computer Vision Attack & Defense

### Attack Surface CV System

| Komponen | Vektor | Tool | Detection Gap |
|----------|--------|------|----------------|
| **Object Detection (YOLO)** | Adversarial patch → misdetect | adversarial patch | Patch audit = rare |
| **Face Recognition** | Deepfake, presentation attack | Roop, face swap | Liveness = partial |
| **OCR** | Perturbation → misread | Image perturbation | OCR validation = rare |
| **Image Classification** | Evasion attack | FGSM, PGD | ML monitoring = nascent |
| **Segmentation** | Adversarial texture | Road patch attack | Pixel-level audit = rare |

### Adversarial Patch Workflow

```
Target: YOLO-based detection (self-driving, security camera)
    ↓
Generate:
  ├── Optimasi gradient → patch pattern
  ├── Place patch di objek target → invisible to model
  └→ Model: objek tidak terdeteksi → bypass
    ↓
Impact:
  ├── Stop sign → tidak terdeteksi → self-driving bypass
  ├── Person → tidak terdeteksi → security cam bypass
  └→ Face → tidak recognized → access bypass
```

### Tool Stack

| Tool | Use |
|------|-----|
| **OpenCV** | Image processing |
| **PyTorch / TensorFlow** | Model training + attack |
| **Adversarial Robustness Toolbox** | Evasion library |
| **YOLO** | Object detection |
| **Clarifai / Google Vision** | API target |

## Referensi
- Computer Vision Attack — https://arxiv.org/abs/1712.02761
- Adversarial Patch — https://arxiv.org/abs/1712.02761
- YOLO — https://pjreddie.com/darknet/yolo/
- ART — https://github.com/Trusted-AI/adversarial-robustness-toolbox

## Konsep Dasar — Computer Vision Pipeline

### Arsitektur End-to-End

Computer vision (CV) modern mengikuti pipeline: Image Acquisition → Preprocessing → Feature Extraction → Inference → Post-processing. Setiap tahap punya tradeoff akurasi vs kecepatan.

```
Input Image (H×W×3)
  ↓ Preprocessing: resize, normalize, augment
  ↓ Backbone (CNN/Transformer): feature map extraction
  ↓ Neck (FPN/PAN): multi-scale feature fusion
  ↓ Head: classification / detection / segmentation
  ↓ Post-processing: NMS, threshold, filtering
  ↓ Output: label / bounding box / mask
```

### Backbone Architecture Comparison

| Backbone | Params | Kelebihan | Kekurangan | Tahun |
|----------|--------|-----------|-----------|-------|
| **ResNet-50** | 25M | Stable, broad ecosystem | Large, slower | 2015 |
| **EfficientNet-B0** | 5M | Efficient, scalable | Complex tuning | 2019 |
| **ViT (Vision Transformer)** | 86M | Global attention, strong | Data hungry | 2020 |
| **ConvNeXt** | 89M | Modern CNN, competitive | Newer | 2022 |
| **SAM (Segment Anything)** | 632M | Zero-shot segmentation | Very large | 2023 |

### Pemrosesan: Dari Pixel ke Feature

1. **Convolution**: Filter (kernel) geser di image → output feature map. Contoh: edge detection (Sobel), blur (Gaussian), sharpening. Filter dipelajari saat training (weights).
2. **Pooling**: Downsample feature map → reduce dimension, increase receptive field. Max pool (ambil max) vs Average pool (rata-rata).
3. **Attention (ViT)**: Image dipecah jadi patch (16x16), tiap patch jadi token, transformer attention hitung hubungan antar patch.
4. **Normalization**: BatchNorm (per batch), LayerNorm (per sample), GroupNorm (per group channel).

### Object Detection: Dua Paradigma

**Two-Stage (R-CNN family)**: 1) Region proposal (candidate boxes), 2) Classification + regression per box. Lebih akurat, lebih lambat.

**One-Stage (YOLO, SSD)**: Sekali pass → bounding box + class langsung. Lebih cepat, tradeoff akurasi. YOLOv8 adalah state-of-the-art untuk real-time detection.

### YOLO Internal Architecture

```
Input: 640x640 image
  ↓ CSPDarknet (backbone): feature extraction, 3 scale (P3/P4/P5)
  ↓ PANet (neck): feature pyramid, multi-scale fusion
  ↓ Detection head: anchor-free, decoupled head
  ↓ Output: 8400 predictions → NMS → final boxes
    ↓
Post-process: conf threshold 0.25 → NMS IoU 0.7 → final detection
```

### Segmentation (Instance vs Semantic)

| Tipe | Definisi | Tool |
|------|----------|------|
| **Semantic** | Tiap pixel → class (background, person, car) | DeepLab, U-Net |
| **Instance** | Tiap pixel → class + instance ID (person_1, person_2) | Mask R-CNN, YOLO-seg |
| **Panoptic** | Semantic + Instance (all pixel labeled) | Panoptic FPN |

### Training & Data Augmentasi

```python
cssclasses:
  - wide-table
  - callout

# Augmentasi modern (Mosaic, CutMix) → meningkatkan generalisasi
transforms = A.Compose([
    A.RandomResizedCrop(640, 640),
    A.HorizontalFlip(p=0.5),
    A.Mosaic(p=0.5),           # 4 image digabung → 1
    A.MixUp(p=0.3),            # blend 2 image
    A.ColorJitter(0.2, 0.2, 0.2),
    A.Normalize(),
])
```

### Metric Evaluasi

| Metric | Definisi | Range |
|--------|-----------|-------|
| **IoU (Intersection over Union)** | overlap / union | 0-1 (>0.5 = good) |
| **mAP (mean Average Precision)** | area under PR curve | 0-1 |
| **Precision** | TP / (TP + FP) | high = less false positive |
| **Recall** | TP / (TP + FN) | high = less miss |

## Referensi
- YOLOv8 — https://github.com/ultralytics/ultralytics
- Vision Transformer — https://arxiv.org/abs/2010.11929
- SAM — https://github.com/facebookresearch/segment-anything
- CV Attack (Adversarial) — https://arxiv.org/abs/1712.02761

## Koneksi ke Vault & Cross-Reference

| Catatan | Hubungan |
|---------|----------|
| Zero Trust | Network segment untuk infra |
| Supply Chain | Pipeline security overlap |
| Cloud IAM | Privilege escalation path |
| Endpoint Security | Runner compromise path |

## Best Practices & Pitfall

1. **GitOps**: Infrastructure config (manifest) ada di Git — versioned, reviewed, auditable. Tetapi Git token = attack surface → rotate, scoped.
2. **Immutable Artifact**: Setiap build = image/untouched hash. Signature verification di deploy. Realitas: banyak still manual deploy.
3. **Least Privilege CI**: Runner token punya scope minimal — bukan global admin. Realitas: `repo:*` scope masih common di setup.
4. **Network Isolation**: Runner segment terpisah production → securitas blance. Tetapi: many org simplify by same VPC → risk.
5. **Audit Log**: Semua CI/CD action di-log dan immutable. Realitas: log retention pendek, alerting belum sentral.
6. **Provenance (SLSA)**: Setiap artifact terlampir provenance (build manifest + source hash). Realitas: adopsi masih rendah di 2025.

## Pitfall Nyata yang Sering Ditemui

- **Leaked token di git history**: git log → credential exposure → scanner attacker → compromise. Fix: BFG repo-cleaner + token rotation.
- **Runner has persistent secrets**: Runner VM menyimpan `~/.aws/credentials` atau `.docker/config.json` → next user can access. Fix: ephemeral runner, no persistent state.
- **Default branch is `main`**: CI jalan di `main`. PR branch dapat trigger → secret exposed. Fix: `pull_request_target` only trusted contributors.
- **Trusted Action pins tag not SHA**: Tag `actions/checkout@v4` → bisa di-hijack jika maintainer compromised. Fix: pin SHA.
- **No SBOM**: Artifact jadi → no manifest → maka after compromised, tidak tahu apa yang affected. Fix: `syft` generate SBOM pada build.

## Tool Stack Lengkap

| Tool | Stage | Use |
|------|-------|-----|
| **GitHub Actions / GitLab CI** | Build | Pipeline |
| **ArgoCD / Flux** | Deploy | GitOps continuous delivery |
| **Trivy / Grype** | Scan | Image + dep vuln scan |
| **Syft** | Scan | SBOM generation |
| **Cosign / Sigstore** | Sign | Artifact signing |
| **Open Policy Agent (OPA)** | Enforce | Policy as code |
| **HashiCorp Vault** | Secret | Secret management |
| **Prometheus + Grafana** | Monitor | Metrics + dashboard |
