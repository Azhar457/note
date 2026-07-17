---
title: "Computer Vision Deep-Dive — Perception for AI Systems"
tags:
  - computer-vision
  - perception
  - image-recognition
  - yolo
  - object-detection
aliases:
  - "computer-vision-deepdive"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Computer vision memberikan persepsi visual ke sistem AI. Digunakan di robotika, autonomous vehicle, dan security.

## Core Tasks

| Task             | Description                | Key Models               |
| ---------------- | -------------------------- | ------------------------ |
| Classification   | What object is this?       | ResNet, EfficientNet     |
| Object Detection | Where is the object?       | YOLO, Faster R-CNN, DETR |
| Segmentation     | Pixel-level classification | U-Net, Mask R-CNN        |
| Pose Estimation  | Human/keypoint detection   | OpenPose, MediaPipe      |
| OCR              | Text extraction            | Tesseract, TrOCR         |

## Modern Architectures

- CNN: convolution, pooling, batch norm
- Vision Transformer (ViT): patch embedding, attention
- YOLO: one-stage detection, anchor boxes
- Depth estimation: MiDaS, stereo matching
- 3D vision: NeRF, point cloud (PointNet++)

## References

1. YOLOv8: ultralytics
2. OpenCV documentation
3. Deep Learning for Computer Vision
