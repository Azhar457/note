---
title: Deepfake Detection
tags:
  - deepfake
  - forensics
  - synthetic-media
  - detection
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  
references:
  - [[semantic-search-pipeline]]
  - [[computer-vision-deepdive]]
related_notes:
  - [[deepfake-detection|Deepfake Detection Overview]]
---

> Deepfake detection adalah cat‑and‑mouse game antara generator dan detector, di mana teknik generatif terus berkembang menyaingi metode analisis.

## 1. Ringkasan / Definisi
Deepfake mengacu pada media sintetis (video, audio, gambar) yang dihasilkan oleh model generatif seperti GAN, VAE, atau diffusion untuk meniru wajah atau suara manusia. Deteksi melibatkan identifikasi artefak visual, temporal, atau biologis yang tidak konsisten dengan data asli. Fokus utama: mengungkap manipulasi dalam konteks keamanan, politik, atau brand protection.

## 2. Teknik Deteksi
| Teknik | Metode | Kelemahan |
|--------|--------|-----------|
| Frequency analysis | FFT pada spektrum gambar, deteksi artefak JPEG/compression | GAN baru mengurangi artefak frekuensi |
| Facial movement | Analisis blink asymmetry, pupil dilation, eye‑gaze inconsistency | Model lip‑sync dapat meniru gerakan |
| Inconsistency check | Analisis pencahayaan, refleksi, shadow geometry | Memerlukan video kualitas tinggi |
| Biological signals | Remote photoplethysmography (rPPG) untuk denyut jantung | Sensitif terhadap noise, resolusi rendah |
| Deep multimodal | Kombinasi audio‑visual, model transformer (CLIP‑based) | Membutuhkan dataset berlabel besar |
| Temporal coherence | Analisis frame‑to‑frame motion vectors, optical flow | Memerlukan video berurutan, dapat terpengaruh compression |

## 3. Dataset & Benchmark
- **FaceForensics++** (12k video, berbagai manipulasi). 
- **DeeperForensics-1.0** (60k video, blurring, compression). 
- **DFDC** (100k video, variasi lighting, head pose). 
- **Celeb-DF** (5k video, high‑resolution). 
Dataset ini menyediakan ground truth dan metrik standar: 
- **AUC‑ROC**, **EER**, **Accuracy**, serta **F1‑score** pada frame‑level serta video‑level.

## 4. Alat & Framework
- **Microsoft Video Authenticator** – API cloud, deteksi artefak temporal dengan model ensemble.
- **Deepware Scanner** – Open‑source, berbasis CNN + Xception, CLI `deepware scan`.
- **InVID / WeVerify** – Ekstensi browser untuk analisis video pada platform sosial.
- **FaceForensics Toolkit** – Skrip Python untuk ekstraksi frame, training, dan evaluasi model.
- **OpenCV + dlib** – Untuk ekstraksi landmark wajah, analisis blink, dan optical flow.

## 5. Praktik Terbaik (Checklist)
- [ ] **Kumpulkan dataset yang beragam**: variasi lighting, pose, resolusi, dan codec.
- [ ] **Gunakan ensemble model**: gabungkan frequency‑based, biometric, dan multimodal cues.
- [ ] **Implementasikan threshold adaptif**: sesuaikan sensitivitas per platform (social media vs. forensic lab).
- [ ] **Monitor model drift**: retrain secara periodik dengan deepfakes terbaru (weekly scrape dari repo GAN).
- [ ] **Integrasikan dengan SIEM**: kirim alert otomatis ke security operations centre.
- [ ] **Audit false‑positive rate**: target < 5 % pada dataset produksi.
- [ ] **Documentasi pipeline**: versinya model, data preprocessing, dan hyper‑parameters.
- [ ] **Compliance**: pastikan pipeline mematuhi regulasi data privacy (GDPR) bila memproses data pribadi.

## 6. Mitigasi & Respon
1. **Triage**: flag video dengan skor tinggi, kirim ke tim forensik.
2. **Quarantine**: isolasi konten pada platform sosial atau internal.
3. **Metadata analysis**: periksa EXIF, codec, frame rate untuk indikasi manipulasi.
4. **Human review**: gunakan ahli visual untuk verifikasi akhir.
5. **Legal escalation**: hubungi otoritas bila terdapat disinformasi politik atau penipuan.

> [!callout] 💡
> Menggabungkan sinyal biologis (rPPG) dengan analisis visual meningkatkan deteksi pada video kualitas tinggi, namun memerlukan resolusi ≥ 720p.

## 7. Referensi
- [[semantic-search-pipeline]] – teknik vektor untuk pencarian anomali media.
- [[computer-vision-deepdive]] – arsitektur model visual yang relevan.
- Paper: "Face Anti‑Spoofing via Attention‑Based CNN" (2023).
- RFC 7499 – Detecting Synthetic Media.
- Dokumentasi Deepware Scanner (GitHub).
---

audited
---
