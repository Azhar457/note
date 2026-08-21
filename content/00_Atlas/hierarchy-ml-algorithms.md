---
title: "Machine Learning Algorithms Hierarchy"
tags: [atlas, ml, algorithms]
aliases: [hierarchy-ml-algorithms]
---
# Hierarchy ML Algorithms

Peta hierarki algoritma machine learning — struktur pengetahuan yang mencakup supervised, unsupervised, deep learning, reinforcement, dan konteks keamanan ML.

## 1. Supervised Learning (Labeled Data)

### Regression
- **Linear/Polynomial regression** — hubungan kontinu; baseline sederhana.
- **Ridge/Lasso/ElasticNet** — regularisasi L2/L1, feature selection.
- **SVR (Support Vector Regression)** — margin-based.
- **Decision Tree / Random Forest / Gradient Boosting (XGBoost, LightGBM, CatBoost)** — nonlinear, tabular data champion.
- **k-NN regression** — instance-based.

### Classification
- **Logistic regression** — baseline probabilistik.
- **SVM** — margin max, kernel trick (RBF, polynomial).
- **Decision Tree / RF / GB** — tabular.
- **k-NN** — simple, non-parametrik.
- **Naive Bayes** — text (spam filter).
- **Neural network (MLP)** — foundation deep learning.

## 2. Unsupervised Learning (Tanpa Label)

### Clustering
- **k-Means** — centroid-based; pilih k (elbow).
- **DBSCAN** — density-based; outlier robust.
- **Hierarchical (AGNES/DIANA)** — dendrogram.
- **Gaussian Mixture (GMM)** — soft assignment.

### Dimensionality Reduction
- **PCA** — linear, variance preservation.
- **t-SNE** — visualisasi, non-linear.
- **UMAP** — scalable, structure preservation.
- **Autoencoder** — neural representation.

### Anomaly Detection
- **Isolation Forest** — random partition.
- **One-Class SVM** — boundary.
- **Local Outlier Factor** — density.
- **Autoencoder reconstruction error** — neural.

## 3. Deep Learning

### Arsitektur
- **CNN** — vision: conv, pooling, residual (ResNet), efficient (MobileNet).
- **RNN/LSTM/GRU** — sequence: language, time series.
- **Transformer** — attention: BERT (encoder), GPT (decoder), T5 (encoder-decoder).
- **GAN** — generative: generator vs discriminator (image synthesis, adversarial training).
- **Autoencoder/VAE** — compression, anomaly, generation.
- **Diffusion** — modern generative (image, audio): DDPM, Stable Diffusion.

### Training Concepts
- Backpropagation, optimizer (SGD, Adam), loss functions (cross-entropy, MSE), regularization (dropout, weight decay, early stopping), transfer learning, fine-tuning.

## 4. Reinforcement Learning (Agent)

- **Value-based**: Q-learning, DQN, Double DQN.
- **Policy-based**: Policy Gradient, PPO, TRPO.
- **Actor-Critic**: A2C/A3C, SAC, TD3.
- **Exploration**: epsilon-greedy, UCB, intrinsic motivation.
- **Aplikasi**: game AI, robotics, autoscaling, security game.

## 5. Ensemble & Meta

- **Bagging** (Random Forest) — variance reduce.
- **Boosting** (AdaBoost, GBM) — bias reduce, sequential.
- **Stacking** — meta-learner.
- **Voting** — hard/soft.
- **Bayesian Optimization** — hyperparameter tuning.

## 6. ML untuk Keamanan (Security Context)

### Defense
- **Network IDS ML** — classify traffic anomaly (Kitsune, Flow based).
- **Malware classification** — PE static features + ML (EMBER), API call sequence.
- **Phishing detection** — URL/email feature classification.
- **UEBA** — user behavior anomaly (isolation forest on login/access pattern).
- **Spam filter** — Naive Bayes/BERT.

### Attack (Adversarial ML)
- **Evasion** — perturb input (FGSM, PGD) → misclassification.
- **Poisoning** — inject training data → model corrupted.
- **Model extraction** — query API → replicate model.
- **Inversion** — recover training data (privacy).
- **Backdoor** — trojan model (supply chain).
- Deteksi: robust training (adversarial training), input sanitization, watermark, monitoring drift.

### Evaluasi
- Accuracy, precision, recall, F1, AUC-ROC; confusion matrix; calibration.
- **Bias & fairness** — dataset bias, fairness metrics.
- **Explainability** — SHAP, LIME, feature importance (untuk security ops yang butuh justifikasi).

## 7. MLOps

- Data pipeline, feature store, model registry (MLflow), serving (ONNX/Triton), monitoring (drift), CI/CD ML (retraining pipeline).
- Keamanan MLOps: model registry access control, artifact signing, data provenance.

## Keterkaitan

- 00_Atlas/hierarchy-llm-ai-systems — LLM/AI systems.
- 00_Atlas/hierarchy-classical-ml-algorithms — pendamping (detail klasik).
- 01_Library/AI_Systems/ — file detail (termasuk skill-ai-mcp).



## Pemilihan Algoritma (Decision Guide)

| Situasi | Rekomendasi |
|---------|-------------|
| Tabular, banyak fitur, teks singkat | Gradient Boosting (XGBoost/LightGBM) |
| Image | CNN (ResNet/EfficientNet) pretrained + fine-tune |
| Sequence/text | Transformer (BERT untuk klasifikasi, GPT untuk generation) |
| Anomaly tanpa label | Isolation Forest / Autoencoder / One-Class SVM |
| Kecil + interpretable | Logistic/Decision Tree (dengan tree explainability) |
| Reinforcement control | PPO (stable default) |
| Latency rendah di edge | Model kecil: MobileNet, DistilBERT, ONNX quantized |

## Evaluasi Lanjutan

- **Cross-validation**: k-fold (stratified untuk imbalance).
- **Imbalanced data**: SMOTE, class weights, F1/AUC lebih penting daripada accuracy.
- **Overfitting detection**: train/val gap; regularisasi; early stopping.
- **Data leakage** — kesalahan umum: scaling sebelum split, target leakage feature, temporal split untuk time series.
- **Calibration**: reliability diagram; isotonic/Platt scaling untuk produksi.

## ML di Operasi Keamanan (Contoh Use Case)

1. **Alert triage**: model priority dari alert SIEM (feature: severity, source, host, time) — kurangi alert fatigue.
2. **Malware family classification**: PE imports + section entropy → classifier (EMBER features).
3. **DNS tunneling detection**: entropy query, frequency, length — anomaly model.
4. **Web attack detection**: WAF log + ML (anomaly payload) — komplementer ruleset.
5. **User behavior**: login time/location pattern outlier → account compromise signal.

Catatan: ML = supplement, bukan replacement — ruleset tetap penting untuk deterministic detection; ML untuk unknown/anomaly.

## Adversarial ML Deep Dive (Red Team)

1. **Evasion**: add noise (FGSM) pada input → evade classifier (e.g., malware detection: perturb feature vector).
2. **Practical**: evasion pada PDF malware classifier (feature-space attack), evasion pada phishing URL classifier.
3. **Defense**: adversarial training (min-max), defensive distillation, input sanitization (JPEG compression untuk vision), ensemble.
4. **ML supply chain**: model registry check (hash, provenance), pretrained model poisoning (backdoor trigger).

## MLOps Production Checklist

- [ ] Data versioning + pipeline reproducible.
- [ ] Model registry (MLflow) dengan access control.
- [ ] Serving: ONNX/Triton, autoscale, A/B (shadow).
- [ ] Monitoring drift (data drift, concept drift) → retrain trigger.
- [ ] Explainability untuk keputusan penting (SHAP).
- [ ] Security: model signed, registry protected, inference API rate-limited.

---

  audited
---