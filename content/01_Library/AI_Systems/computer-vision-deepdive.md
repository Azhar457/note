---
title: Computer Vision Deep-Dive — Perception for AI Systems
tags:
  - computer-vision
  - perception
  - image-recognition
  - yolo
  - object-detection
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  
references:
  - [[deepfake-detection]]
  - [[semantic-search-pipeline]]
related_notes:
  - [[computer-vision-deepdive|Computer Vision Deep-Dive]]
---

> Computer vision memberikan persepsi visual ke sistem AI. Digunakan di robotika, autonomous vehicle, security, dan analisis media sintetis.

## 1. Ringkasan / Definisi
Computer vision (CV) adalah bidang AI yang memungkinkan mesin menginterpretasi dan memahami data visual. Tugas utama meliputi klasifikasi, deteksi objek, segmentasi, estimasi pose, OCR, dan rekonstruksi 3D. Perkembangan arsitektur CNN, Vision Transformer (ViT), dan model one‑stage seperti YOLO telah mendorong aplikasi real‑time.

## 2. Tugas Inti
| Task | Description | Key Models |
|------|-------------|------------|
| Classification | Apa objek ini? | ResNet, EfficientNet, ViT |
| Object Detection | Di mana objek? (bounding box) | YOLOv8, Faster R‑CNN, DETR |
| Segmentation | Klasifikasi per piksel | U‑Net, Mask R‑CNN, SAM |
| Pose Estimation | Deteksi titik tubuh | OpenPose, MediaPipe, HRNet |
| OCR | Ekstraksi teks dari gambar | Tesseract, TrOCR, EasyOCR |
| Depth Estimation | Jarak per piksel | MiDaS, stereo matching, LiDAR fusion |

## 3. Arsitektur Modern
- **CNN (Convolutional Neural Network)**: Convolution, pooling, batch normalization. Efisien untuk feature extraction lokal.
- **Vision Transformer (ViT)**: Patch embedding + multi‑head attention. Lebih baik pada dataset besar, memerlukan pre‑training masif.
- **YOLO (You Only Look Once)**: One‑stage detector, anchor boxes, real‑time (30–100+ FPS). Cocok untuk embedded dan autonomous driving.
- **Depth Estimation**: MiDaS untuk monocular depth, stereo matching untuk 3D reconstruction.
- **3D Vision / NeRF**: Neural Radiance Fields untuk rekonstruksi 3D dari 2D image set; PointNet++ untuk point cloud classification.

> [!callout] ⚠️
> Model CV modern memerlukan komputasi tinggi (GPU) dan dataset berlabel besar. Tanpa augmentasi data dan validasi cross‑domain, model rentan overfitting dan bias terhadap distribusi pelatihan.

## 4. Checklist Implementasi CV
- [ ] Definisikan task (klasifikasi, deteksi, segmentasi) sesuai use case.
- [ ] Kumpulkan dan label dataset (COCO, ImageNet, custom dataset).
- [ ] Terapkan augmentasi: flip, rotate, color jitter, mixup.
- [ ] Pilih arsitektur (YOLOv8 untuk real‑time, ViT untuk akurasi tinggi).
- [ ] Latih dengan optimizer (AdamW, SGD), learning rate scheduler.
- [ ] Evaluasi metrics: mAP (detection), IoU (segmentation), top‑k accuracy (klasifikasi).
- [ ] Optimasi inferensi: quantization (INT8), pruning, TensorRT.
- [ ] Deploy dengan pipeline yang aman (enkripsi model, akses terbatas).

## 5. Referensi Cross-Note
- [[deepfake-detection]] – aplikasi CV untuk deteksi media sintetis.
- [[semantic-search-pipeline]] – teknik vektor untuk pencarian visual (CLIP embedding).
- Dokumentasi YOLOv8 (Ultralytics), OpenCV docs.
- Paper: "An Image is Worth 16x16 Words" (ViT, Dosovitskiy et al., 2020).

## Deepdive — Computer Vision Deepdive Extension

### Arsitektur ViT (Vision Transformer)

| Komponen | Fungsi | Ukuran |
|----------|--------|--------|
| Patch Embedding | Image → token | 16x16 patch |
| Positional Embedding | Token order info | Learned |
| Attention Blocks | Global relation | L=12 layers |
| MLP Head | Classification | 768 hidden |

### Data Pipeline CV

1. **Collect**: scrape / dataset (ImageNet, COCO, custom)
2. **Label**: annotation tool (LabelImg, CVAT)
3. **Augment**: flip, rotate, color jitter, cutout
4. **Split**: train/val/test
5. **Train**: GPU, epochs, batch
6. **Evaluate**: mAP, IoU, F1
7. **Deploy**: ONNX, TensorRT, TFLite

### Attack & Defense CV

| Attack | Teknik | Defense |
|--------|--------|---------|
| Adversarial patch | Patch attack | Adversarial training |
| FGSM/PGD | Gradient perturbation | Input preprocessing |
| Deepfake | Face swap | Deepfake detection |
| Model steal | Query approximation | Rate limit, watermark |

## Referensi
- ViT — https://arxiv.org/abs/2010.11929
- OpenCV — https://opencv.org/
- CVAT — https://www.cvat.ai/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian dilakukan berdasarkan: ada vs tidak ada kontrol, efektivitas, dan dokumentasi.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Model keamanan: never trust, always verify |
| **Supply Chain** | Serangan ke rantai dependency dan tooling |
| **MITRE ATT&CK** | Framework TTP untuk klasifikasi serangan |
| **SIEM** | Security Information and Event Management |
| **EDR** | Endpoint Detection and Response |
| **SOAR** | Security Orchestration, Automation and Response |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **OIDC** | OpenID Connect (identity layer) |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
---

audited
---
