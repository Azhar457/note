---
tags:
  - hierarchy
  - computer-vision
  - cnn
  - object-detection
  - segmentation
  - image-processing
aliases:
  - Computer Vision Hierarchy
  - CV Stack
  - From Pixels to Understanding
  - Image Processing Pipeline
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 👁️ Computer Vision — Dari Pixels ke Scene Understanding

> [!tip] Computer Vision adalah cabang AI yang memungkinkan mesin "melihat" — bukan sekadar menangkap gambar, tapi **memahami** konten visual. Catatan ini memetakan **6 tingkat hierarki CV** dari pixels hingga scene understanding, CNN architecture evolution, object detection (YOLO, DETR), segmentation, dan trade-off matrix. 68 hits di vault — domain ML terbesar ketiga yang belum punya hierarchy.

---

## Daftar Isi

1. [[#1. Premise — How Machines See]]
2. [[#2. Six-Level Hierarchy of Vision]]
3. [[#3. Level 1 — Image Acquisition & Preprocessing]]
4. [[#4. Level 2 — Feature Extraction]]
5. [[#5. Level 3 — Low-Level Vision]]
6. [[#6. Level 4 — Mid-Level Vision]]
7. [[#7. Level 5 — High-Level Vision]]
8. [[#8. Level 6 — Scene Understanding & Reasoning]]
9. [[#9. CNN Architecture Timeline]]

---

## 1. Premise — How Machines See

Manusia melihat dengan **200+ juta tahun evolusi** — mesin melihat dengan **arsitektur yang didesain secara manual**:

```
Pixel Grid (H×W×C) → Features → Structures → Objects → Scenes → Meaning
     ↓                 ↓            ↓          ↓          ↓         ↓
  Raw data         Edge, texture   Segments    Objects   Context  Decision
```

**Computer Vision itu SUSAH karena:**
- **Ill-posed problem** — 3D world diproyeksikan ke 2D → informasi kedalaman hilang
- **Variability** — objek yang sama (kursi) bisa memiliki tampilan tak terbatas
- **Lighting** — pencahayaan mengubah pixel drastis
- **Scale** — objek bisa sangat kecil atau sangat besar di frame

---

## 2. Six-Level Hierarchy of Vision

| Level | Nama | Contoh Tugas | Input | Output |
|:-----:|------|-------------|-------|--------|
| **L1** | Image Acquisition & Preprocessing | Capture, denoise, color correction | Raw sensor | Clean image |
| **L2** | Feature Extraction | Edge detection, SIFT, HOG | Image | Feature maps |
| **L3** | Low-Level Vision | Segmentation, depth estimation | Features | Structure maps |
| **L4** | Mid-Level Vision | Object detection, tracking | Structure | Bounding boxes |
| **L5** | High-Level Vision | Classification, recognition | Objects | Labels |
| **L6** | Scene Understanding & Reasoning | VQA, captioning, navigation | Scene | Language/action |

---

## 3. Level 1 — Image Acquisition & Preprocessing

### 3.1 Camera Pipeline

```
Scene → Lens → Sensor (CMOS/CCD) → A/D → Raw → Demosaic → Color → Gamma → JPEG
```

**Sensor types:**
| Sensor | Quantum Efficiency | Noise | Speed | Cost |
|--------|:-----------------:|:-----:|:-----:|:----:|
| **CCD** | 40-70% | Low | Slow | High |
| **CMOS** | 30-60% | Moderate | Fast | Low |
| **Event Camera** | N/A (delta intensity) | Low | μs | High |

**Key:**
- **Resolution** (MP) — seberapa detail
- **Dynamic Range** (stops) — rentang gelap ke terang
- **FPS** — seberapa cepat (IoT: 30, ML: 60-1000)

### 3.2 Preprocessing Operations

| Operation | Fungsi | Algoritma |
|-----------|--------|-----------|
| **Denoising** | Hapus noise sensor | Gaussian, Median, Bilateral, Non-local Means |
| **Deblurring** | Koreksi blur (motion/focus) | Wiener filter, Lucy-Richardson, blind deconvolution |
| **Histogram Equalization** | Perbaiki kontras | CLAHE (Contrast Limited Adaptive HE) |
| **Gamma Correction** | Komaasi nonlinear | $I_{\\text{out}} = I_{\\text{in}}\\times\\gamma$ |
| **White Balance** | Koreksi warna | Gray world, Retinex |
| **Resize** | Ubah dimensi | Bilinear, bicubic, lanczos (ML), anti-aliasing |

---

## 4. Level 2 — Feature Extraction

### 4.1 Classical (Pre-Deep Learning) Features

| Feature | Type | Invariance | Application |
|---------|:----:|:----------:|-------------|
| **SIFT** | Keypoint | Scale + rotation + illumination | Image stitching, 3D reconstruction |
| **SURF** | Keypoint (SIFT + integral image) | Scale + rotation | Real-time matching |
| **ORB** | Keypoint (FAST + BRIEF) | Rotation | SLAM, mobile (free) |
| **HOG** | Dense gradient descriptor | Illumination | Pedestrian detection |
| **LBP** | Texture descriptor | Illumination | Face recognition |
| **Gabor** | Frequency filter | — | Texture analysis |

### 4.2 CNN-based Features (Learned)

| Layer Depth | Feature Type | Visualisasi |
|:-----------:|-------------|-------------|
| **L1 (conv1)** | Edge, color blobs | Lines at various angles |
| **L2 (conv2)** | Textures, patterns | Zebra, grid, dots |
| **L3 (conv3)** | Mid-level parts | Wheels, eyes, windows |
| **L4 (conv4)** | Object parts | Car fronts, faces |
| **L5 (conv5)** | Full objects | Cars, dogs, people |

---

## 5. Level 3 — Low-Level Vision

### 5.1 Segmentation

| Task | Definisi | Arsitektur Kunci |
|------|----------|------------------|
| **Semantic Segmentation** | Setiap pixel → class label | U-Net, DeepLab, FCN, SegFormer |
| **Instance Segmentation** | Setiap objek → individual mask | Mask R-CNN, YOLACT |
| **Panoptic Segmentation** | Stuff (semantic) + things (instance) | Panoptic FPN, Mask2Former |
| **Part Segmentation** | Bagian dari objek (wheels, door) | PartNet |

**Benchmark:** Cityscapes (50 classes, 5000 images, 1024×2048)

| Architecture | mIoU Cityscapes | FPS (T4) |
|-------------|:---------------:|:--------:|
| DeepLabV3+ (ResNet-101) | 82.3% | 17 |
| SegFormer-B5 | 84.0% | 11 |
| Mask2Former | **85.2%** | 8 |
| PP-LiteSeg | 79.1% | **163** |

### 5.2 Depth Estimation

| Type | Output | Contoh |
|------|--------|--------|
| **Monocular** | Depth map from single image | MiDaS, DPT, Depth Anything |
| **Stereo** | Disparity from 2 cameras | RAFT-Stereo, NAS-DAD |
| **Multi-view** | Depth from N views | COLMAP (SfM) |

---

## 6. Level 4 — Mid-Level Vision

### 6.1 Object Detection

**Timeline:**
```
R-CNN (2014) → Fast R-CNN (2015) → Faster R-CNN (2015) → YOLO (2016) → SSD (2016)
    → RetinaNet (2017) → YOLOv3 (2018) → EfficientDet (2020) → DETR (2020)
    → YOLOv8 (2023) → RT-DETR (2023) → YOLOv9 (2024) → YOLOv10 (2024)
```

### 6.2 Two-Stage vs One-Stage

| Aspek | Two-Stage (Faster R-CNN, Mask R-CNN) | One-Stage (YOLO, SSD, RetinaNet) |
|-------|:-------------------------------------:|:---------------------------------:|
| **Pipeline** | RPN → RoI → Classify | Single shot |
| **Accuracy** | ✅ Lebih tinggi (mAP+2-5) | 🟡 Direndahkan (mAP-2-5) |
| **Speed** | 10-30 FPS | 60-600+ FPS |
| **Trade-off** | Akurat, lambat | Cepat, cukup akurat |
| **Use case** | Autonomous driving, medical | Robotics, edge, real-time |

### 6.3 Detection Architecture Comparison

| Model | Backbone | mAP 50-95 | FPS (T4) | Tahun | Cats |
|------|----------|:---------:|:--------:|:-----:|------|
| **Faster R-CNN** | ResNet-50 | 37.4 | 15 | 2015 | Two-stage pioneer |
| **YOLOv3** | DarkNet | 33.0 | 78 | 2018 | One-stage break |
| **RetinaNet** | ResNet-50 | 36.5 | 16 | 2017 | Focal Loss |
| **EfficientDet-D0** | EfficientNet | 33.8 | 98 | 2020 | Efficient |
| **YOLOv8m** | CSPDarknet | 50.8 | 109 | 2023 | Modern versatile |
| **RT-DETR-L** | ResNet-50 | **53.0** | 108 | 2023 | Real-time transformer |
| **DETR** | ResNet-50 | 42.0 | 12 | 2020 | End-to-end |
| **DINO** | Swin-L | **63.2** | 6 | 2022 | SOTA detection |

### 6.4 Object Tracking

| Paradigma | Contoh Mekanisme | Use Case |
|-----------|------------------|----------|
| **SORT** | Kalman filter + IoU matching | Fast (260 Hz) |
| **DeepSORT** | SORT + appearance embedding | Multi-camera |
| **ByteTrack** | Low + high score boxes | Occlusion robust |
| **TransTrack** | Transformer + query | High accuracy |

---

## 7. Level 5 — High-Level Vision

### 7.1 Image Classification

**Evolution:**
```
AlexNet (2012) → VGG (2014) → GoogLeNet (2014) → ResNet (2015)
    → DenseNet (2017) → EfficientNet (2019) → ConvNeXt (2022)
```

**AlexNet (2012)** — memenangkan ImageNet pertama:
- 11×11 conv, 60M parameters
- 15.3% top-5 error (vs 26.2% sebelumnya)
- GPU training dengan 2× GTX 580

**ResNet (2015)** — skip connections membuat deep network mungkin:
```
ResNet-50: 25M params, 3.8B FLOPs, 92.1% top-5
ResNet-152: 60M params, 11.3B FLOPs, 93.4% top-5
```

**EfficientNet** — compound scaling (depth, width, resolution):
| Model | Params | FLOPs | Top-1 |
|-------|:-----:|:-----:|:-----:|
| EfficientNet-B0 | 5.3M | 0.4B | 77.1% |
| EfficientNet-B7 | 66M | 37B | 84.3% |

### 7.2 Vision Transformers (ViT)

**ViT (2021)** — membawa transformer ke vision:
```
Image (H×W×C) → Patches (P×P) → Linear → [CLS] token + Position → Transformer encoder → MLP → Class
```

| Model | Params | ImageNet Top-1 | ImageNet Top-1 (22K) |
|-------|:-----:|:--------------:|:--------------------:|
| ViT-B/16 | 86M | 77.9% | 84.1% |
| ViT-L/16 | 307M | 76.5% | 85.1% |
| ViT-H/14 | 632M | — | 87.8% |

**Hybrid (CNN + Transformer):**
| Model | Backbone | Top-1 | FPS |
|-------|----------|:-----:|:---:|
| **DeiT** | Teacher-student | 83.1% | Fast |
| **Swin-T** | Shifted windows | 81.2% | 100+ |
| **ConvNeXt** | Modern CNN | 84.3% | 80+ |

---

## 8. Level 6 — Scene Understanding & Reasoning

### 8.1 Visual Question Answering (VQA)

| Arsitektur | Dataset | Accuracy |
|------------|---------|:--------:|
| **LXMERT** | VQA v2 | 72.4% |
| **ViLBERT** | VQA v2 | 73.3% |
| **OFA** | 12 datasets | SOTA multi-task |

### 8.2 Image & Video Captioning

| Model | Autoregressive | Object-Aware | CIDEr |
|-------|:--------------:|:------------:|:-----:|
| **ViT + GPT2** | ✅ | ❌ | 120.3 |
| **BLIP-2** | ✅ (Q-Former) | ✅ | 133.2 |
| **GIT** (Microsoft) | ✅ (Transformer) | ✅ | 144.1 |
| **Flamingo** | ✅ (Perceiver) | ✅ | — |

### 8.3 Multi-Modal Models (Vision + Language)

| Model | Vision Encoder | Language Decoder | Zero-shot? |
|-------|---------------|------------------|:----------:|
| **CLIP** (OpenAI) | ViT-L | Text Encoder | ✅ 400M pairs |
| **BLIP-2** | ViT-g | OPT/LLaMA | ✅ Instruct |
| **LLaVA** | CLIP ViT-L | Vicuna | ✅ SFT |
| **GPT-4V** | — | GPT-4 | ✅ RLHF |

---

## 9. CNN Architecture Timeline + Comparison

| Tahun | Arsitektur | Inovasi | Params | FLOPs |
|:-----:|------------|---------|:------:|:-----:|
| 2012 | **AlexNet** | GPU training, ReLU, dropout | 60M | 0.7B |
| 2014 | **VGG-16** | Small filters (3×3), deeper | 138M | 15.3B |
| 2014 | **GoogLeNet** | Inception module | 6.8M | 1.6B |
| 2015 | **ResNet-50** | Skip connections | 25.5M | 3.8B |
| 2017 | **DenseNet-121** | Dense connections | 8M | 2.9B |
| 2018 | **MobileNetV2** | Depthwise separable + inverted residuals | 3.5M | 0.3B |
| 2019 | **EfficientNet** | Compound scaling | 5.3-66M | 0.4-37B |
| 2021 | **ViT** | Pure transformer for vision | 86M+ | — |
| 2022 | **ConvNeXt** | Modernized ResNet | 28M | 4.5B |
| 2023 | **SwinV2** | Scaled window attention | 3B | — |

---

## 10. Cross-Reference ke Vault

| Level | Catatan Vault |
|:-----:|---------------|
| **L1-L2** | [[hierarchy-digital-plumbing]] — Image codec, compression |
| **L3 (Segmentation)** | [[hierarchy-llm-ai-systems]] — RAG chunking based on layout |
| **L4 (Detection)** | [[hierarchy-cybersecurity-defense-architecture]] — CCTV, face detection |
| **L5 (Classification)** | [[hierarchy-classical-ml-algorithms]] — SVM + HOG comparison |
| **L6 (Multi-modal)** | [[hierarchy-llm-ai-systems]] — Vision-language models |

---

## References

1. Szeliski, R. *"Computer Vision: Algorithms and Applications."* 2nd ed., Springer, 2022.
2. Goodfellow, I., Bengio, Y., Courville, A. *"Deep Learning."* MIT Press, 2016 — Ch. 9-12.
3. Krizhevsky, A. et al. *"ImageNet Classification with Deep Convolutional Neural Networks."* NeurIPS 2012.
4. He, K. et al. *"Deep Residual Learning for Image Recognition."* CVPR 2016.
5. Ren, S. et al. *"Faster R-CNN: Towards Real-Time Object Detection."* NeurIPS 2015.
6. Redmon, J. & Farhadi, A. *"YOLOv3: An Incremental Improvement."* 2018.
7. Dosovitskiy, A. et al. *"An Image is Worth 16×16 Words: Transformers for Image Recognition."* ICLR 2021.
8. Carion, N. et al. *"End-to-End Object Detection with Transformers."* ECCV 2020.
9. Tan, M. & Le, Q. *"EfficientNet: Rethinking Model Scaling."* ICML 2019.
10. Chen, L. et al. *"DeepLab: Sematic Image Segmentation."* TPAMI 2018.
11. Kirillov, A. et al. *"Segment Anything."* ICCV 2023.
12. Radford, A. et al. *"Learning Transferable Visual Models From Natural Language Supervision (CLIP)."* ICML 2021.
13. Li, J. et al. *"BLIP-2: Bootstrapping Language-Image Pre-training."* 2023.
14. Liu, Z. et al. *"Swin Transformer."* CVPR 2021.
