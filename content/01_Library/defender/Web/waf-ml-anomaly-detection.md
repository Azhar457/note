---
title: AI/ML Anomaly Detection for WAF — ONNX & Feature Engineering
tags:
- waf
- machine-learning
- onnx
- anomaly-detection
- feature-engineering
- rust
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Deteksi berbasis tanda tangan (signature-based) memiliki keterbatasan terhadap serangan *zero-day* dan teknik obfuskasi kompleks. Catatan ini mendefinisikan arsitektur deteksi anomali berbasis kecerdasan buatan (AI/ML) yang diintegrasikan langsung ke dalam data plane [[waf-reverse-proxy-deepdive]] menggunakan model kuantisasi ONNX di Rust.

## Daftar Isi

1. [Arsitektur Integrasi ML di WAF (ONNX Runtime di Rust)](#1-arsitektur-integrasi-ml-di-waf-onnx-runtime-di-rust)
2. [Feature Engineering untuk HTTP Traffic](#2-feature-engineering-untuk-http-traffic)
3. [Perbandingan Model Deteksi Anomali](#3-perbandingan-model-deteksi-anomali)
4. [Pipeline Pelatihan & Retraining](#4-pipeline-pelatihan--retraining)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Arsitektur Integrasi ML di WAF (ONNX Runtime di Rust)

Menjalankan inferensi ML langsung pada jalur kritis data plane HTTP proxy membutuhkan latensi yang sangat rendah (<2ms per request). Kami menggunakan **ONNX Runtime** yang diikat langsung ke dalam proxy Rust (seperti Pingora) untuk mengeksekusi model yang telah dikompilasi sebelumnya.

```
Client Request
      │
      ▼
┌──────────────┐      ┌────────────────────────┐
│  WAF     │ ───> │ Extract HTTP Features  │
│  Data Plane  │      └────────────────────────┘
└──────┬───────┘                   │
       │                           ▼
       │                    Vectorized Array
       │                           │
       │                           ▼
       │              ┌────────────────────────┐
       │              │    ONNX Runtime C ABI  │
       │              │  (Quantized Model .onnx)│
       │              └────────────────────────┘
       │                           │
       │                           ▼
       ├<── Anomaly Score ─────────┘
       │    (Threshold: e.g. >0.85)
       │
       ├───> [Score < Threshold]  ──> Forward to Upstream
       │
       └───> [Score >= Threshold] ──> Challenge / Block (403)
```

### 1.1 Kode Integrasi Rust (ONNX Inference Engine)

Contoh kode Rust untuk memuat model ONNX dan menjalankan inferensi anomali:

```rust
use ort::{inputs, Environment, LoggingLevel, Session, SessionBuilder, Value};
use std::sync::Arc;

pub struct WafMlEngine {
    session: Session,
}

impl WafMlEngine {
    pub fn new(model_path: &str) -> Result<Self, ort::Error> {
        let env = Arc::new(Environment::builder()
            .with_name("waf-ml")
            .with_log_level(LoggingLevel::Warning)
            .build()?);
        
        let session = SessionBuilder::new(&env)?
            .with_optimization_level(ort::GraphOptimizationLevel::Level3)?
            .with_intra_threads(2)? // Mengunci core pemrosesan agar latensi stabil
            .with_model_from_file(model_path)?;
            
        Ok(Self { session })
    }

    pub fn predict_anomaly(&self, features: &[f32]) -> Result<f32, ort::Error> {
        // Model menerima input tensor berbentuk [1, FEATURE_COUNT]
        let input_tensor = Value::from_array(
            self.session.allocator(),
            ndarray::Array2::from_shape_vec((1, features.len()), features.to_vec())
                .unwrap(),
        )?;
        
        let outputs = self.session.run(inputs!["input_features" => input_tensor]?)?;
        let output_tensor = outputs["anomaly_score"].try_extract::<f32>()?;
        let view = output_tensor.view();
        
        Ok(view[(0, 0)]) // Mengembalikan nilai skor anomali antara 0.0 s.d 1.0
    }
}
```

---

## 2. Feature Engineering untuk HTTP Traffic

Model ML tidak dapat memproses teks mentah HTTP secara langsung. Teks request harus direduksi menjadi representasi numerik (*vectorization*) berdimensi tetap (*fixed size*).

### 2.1 Fitur yang Diekstrak

| Kategori | Nama Fitur | Deskripsi | Signifikansi Keamanan |
|----------|------------|-----------|------------------------|
| **URI** | `uri_length` | Panjang total string URI | Deteksi buffer overflow / path traversal |
| | `entropy_uri` | Shannon entropy dari string URI | Deteksi payload ter-enkripsi/obfuskasi |
| | `spec_char_count` | Jumlah karakter khusus (`../`, `'`, `"`, `%`, `<`) | Sinyal kuat injeksi (SQLi, XSS, Path Traversal) |
| **Headers**| `header_count` | Jumlah header dalam request | Deteksi HTTP request smuggling / scraping |
| | `content_len` | Nilai dari Content-Length header | Deteksi payload jumbo (DoS) |
| | `user_agent_len`| Panjang string User-Agent | Deteksi anomali User-Agent bot otomatis |
| **Payload**| `body_length` | Panjang total request body | Deteksi upload data besar |
| | `entropy_body` | Shannon entropy dari request body | Deteksi upload file terenkripsi / shellcode |
| **Timing** | `req_rate_10s` | Frekuensi request dari IP dalam 10 detik | Deteksi brute force / L7 DDoS |

### 2.2 Algoritma Penghitung Shannon Entropy (Rust)

```rust
fn calculate_shannon_entropy(data: &str) -> f32 {
    if data.is_empty() { return 0.0; }
    let mut counts = [0; 256];
    for &byte in data.as_bytes() {
        counts[byte as usize] += 1;
    }
    let len = data.len() as f32;
    let mut entropy = 0.0;
    for &count in counts.iter() {
        if count > 0 {
            let p = count as f32 / len;
            entropy -= p * p.log2();
        }
    }
    entropy
}
```

---

## 3. Perbandingan Model Deteksi Anomali

Tiga pendekatan model unsupervised/semi-supervised utama yang dipertimbangkan untuk di-deploy pada edge node:

| Model | Latensi Inferensi | Memory Footprint | Kelebihan | Kelemahan |
|-------|-------------------|------------------|-----------|-----------|
| **Isolation Forest (iForest)** | **Sangat Rendah (<0.5ms)** | Sangat Ringan (<5MB) | Cepat, efisien pada resource terbatas, tidak butuh GPU. | Kurang peka terhadap urutan (sekuensial) data. |
| **Autoencoder (Neural Network)**| Sedang (~1.5ms) | Ringan-Sedang (10-30MB) | Sangat baik mendeteksi korelasi non-linear antar header. | Membutuhkan threshold tuning yang ketat. |
| **LSTM Autoencoder** | Tinggi (>5ms) | Berat (>100MB) | Hebat dalam mendeteksi anomali runtun waktu (time-series). | Latensi inferensi terlalu lambat untuk inline blocking. |

**Rekomendasi untuk WAF:** Gunakan **Isolation Forest** atau **Autoencoder** kuantisasi 8-bit (INT8) untuk menjaga performa inferensi tetap berada di bawah batasan <2ms.

---

## 4. Pipeline Pelatihan & Retraining

Deteksi anomali rentan terhadap masalah *false positive* akibat perubahan perilaku aplikasi (perubahan rilis software baru). Oleh karena itu, siklus pelatihan ulang model secara terus menerus (*retraining pipeline*) wajib diimplementasikan.

```
                  WAF Log Pipeline (Elastic/ClickHouse)
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │ Data Cleaning & Partition   │
                     │  (Filter out blocked IPs)   │
                     └──────────────┬──────────────┘
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │ Model Retraining (Python)   │
                     │ Isolation Forest / PyTorch  │
                     └──────────────┬──────────────┘
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │ Model Validation Check      │
                     │  (Target FP Rate < 0.01%)   │
                     └──────────────┬──────────────┘
                                    │
                         Passes Verification
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │ Export to ONNX & Quantize   │
                     └──────────────┬──────────────┘
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │ Hot-reload model di WAF │
                     │   tanpa downtime proxy      │
                     └─────────────────────────────┘
```

### 4.1 Mekanisme Hot-Reload Model

Untuk memperbarui model tanpa merestart engine proxy proxy, WAF menggunakan pointer atomik (`ArcSwap` di Rust) untuk melakukan hot-swap instance `Session` ONNX secara asinkron di memori:

```rust
use arc_swap::ArcSwap;
use std::sync::Arc;

pub struct WafState {
    pub ml_engine: ArcSwap<WafMlEngine>,
}

impl WafState {
    pub fn reload_model(&self, new_model_path: &str) -> Result<(), ort::Error> {
        let new_engine = WafMlEngine::new(new_model_path)?;
        self.ml_engine.store(Arc::new(new_engine));
        Ok(())
    }
}
```

---

## 5. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[waf-reverse-proxy-deepdive]] | Dasar data plane reverse proxy tempat ONNX engine ini berjalan. |
| [[00_Atlas/hierarchy-classical-ml-algorithms]] | Dasar klasifikasi matematika untuk model klasik seperti Isolation Forest. |
| [[adversarial-machine-learning]] | Teknik penyerang untuk meracuni model anomali WAF (*model poisoning* / *evasion attack*). |
| [[waf-plan]] | Dokumen perencanaan utama tempat anomali ML dideklarasikan sebagai prioritas #1. |