---
title: "Jailbreak Impact Quantification — Model Matematika Dampak & Probabilitas Sukses"
tags:
  - ai-systems
  - llm-security
  - red-teaming
  - jailbreak
  - mathematics
  - quantification
  - library
aliases:
  - "Jailbreak Math"
  - "Impact Quantification"
  - "Probabilitas Sukses Jailbreak"
created: "2026-07-31"
updated: "2026-07-31"
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Ringkasan
> Model matematika untuk mengukur dampak dan probabilitas sukses teknik jailbreak pada LLM. Mencakup: estimasi attention shift, entropy analysis, success probability modeling dengan logistic regression, information-theoretic metrics (perplexity, surprisal), dose-response curves, dan framework perhitungan yang bisa diterapkan pada hasil pengujian nyata. Formula diturunkan dari literatur (arXiv) dan bisa dipakai langsung dengan Python. Vault sudah punya [[jailbreak-case-study-neko-persona]] (analisis kualitatif) — catatan ini melengkapi dengan kuantifikasi.

# 📐 Jailbreak Impact Quantification

## Daftar Isi

1. [[#1. Mengapa Kuantifikasi]]
2. [[#2. Attention Shift Model]]
3. [[#3. Entropy & Information-Theoretic Metrics]]
4. [[#4. Success Probability Model (Logistic)]]
5. [[#5. Dose-Response Curve]]
6. [[#6. Attack Surface Scoring]]
7. [[#7. Framework Pengukuran Praktis]]
8. [[#8. Contoh Perhitungan — Prompt Neko]]
9. [[#9. Limitasi Model]]
10. [[#10. Koneksi ke Vault]]
11. [[#11. References]]

## 1. Mengapa Kuantifikasi

Analisis kualitatif ("persona override itu efektif") tidak cukup untuk:

1. **Membandingkan teknik** — teknik mana yang lebih kuat secara terukur?
2. **Mengukur perbaikan** — apakah defense terbaru menurunkan success rate?
3. **Menetapkan threshold** — kapan sebuah agent "aman" (angka, bukan perasaan)?
4. **Fine-tune detection** — training data butuh label probabilitas, bukan label biner.

Model di catatan ini adalah **estimasi pertama** — kerangka untuk diisi dengan data pengujian nyata, bukan klaim absolut.

## 2. Attention Shift Model

### 2.1. Intuisi

LLM berbasis transformer memproses semua token dalam satu konteks. Guardrail system prompt dan prompt jailbreak bersaing untuk "mendapatkan" perhatian model. Semakin salien sebuah instruksi, semakin besar bobotnya pada output distribution.

### 2.2. Formalisasi

Diberikan konteks $C$ dengan $n$ token. Output distribution dihasilkan oleh:

$$P(y_t | C) = \text{softmax}\left( \frac{Q_t K_C^T}{\sqrt{d_k}} V_C \right)$$

Untuk estimasi _relative salience_ instruksi jailbreak $J$ terhadap system prompt $S$:

$$\Delta = \frac{w(J)}{w(S)} = \frac{\sum_{i \in J} \alpha_i \cdot s_i}{\sum_{j \in S} \alpha_j \cdot s_j}$$

di mana:

- $\alpha_i$ = attention weight token $i$ pada posisi generate
- $s_i$ = salience score token $i$ (fungsi panjang, pengulangan, emosi, imperative)

### 2.3. Salience Score Empiris

Karena attention weights tidak tersedia di black-box, gunakan proxy:

$$s_i = \lambda_1 \cdot \underbrace{\mathbb{1}[\text{imperative}]}_{\text{kata perintah}} + \lambda_2 \cdot \underbrace{\text{freq}_i}_{\text{pengulangan}} + \lambda_3 \cdot \underbrace{\text{emotion}_i}_{\text{kata emosional}} + \lambda_4 \cdot \underbrace{\text{length}_i}_{\text{panjang blok}}$$

Dengan koefisien estimasi awal (dari literature proxy):

| Koefisien   | Nilai awal | Arti                              |
| :---------- | :--------: | :-------------------------------- |
| $\lambda_1$ |    0.4     | Instruksi imperatif sangat salien |
| $\lambda_2$ |    0.3     | Pengulangan memperkuat            |
| $\lambda_3$ |    0.2     | Emosi meningkatkan engagement     |
| $\lambda_4$ |    0.1     | Panjang blok memberi bobot        |

### 2.4. Compliance Threshold

Model diasumsikan "berpindah kepatuhan" ketika:

$$\Delta > \tau \quad \text{dengan} \quad \tau \approx 1.0$$

Artinya: ketika prompt jailbreak secara agregat lebih salien daripada system prompt asli, guardrail mulai kalah. Ini konsisten dengan temuan empiris bahwa jailbreak panjang + emosional + berulang lebih efektif ([[jailbreak-case-study-neko-persona]]).

### 2.5. Contoh Perhitungan Kasar — Prompt Neko

Asumsi konteks 8K token, system prompt 1.5K token, prompt Neko 3.5K token:

| Komponen          | Tokens | Imperative | Repetisi | Emosi |                          Skor kasar                          |
| :---------------- | :----: | :--------: | :------: | :---: | :----------------------------------------------------------: |
| System prompt (S) |  1.5K  |     5      |    3     |   1   |   $0.4\cdot5 + 0.3\cdot3 + 0.2\cdot1 + 0.1\cdot1.5 = 3.25$   |
| Prompt Neko (J)   |  3.5K  |     40     |    15    |  10   | $0.4\cdot40 + 0.3\cdot15 + 0.2\cdot10 + 0.1\cdot3.5 = 23.85$ |

$$\Delta = \frac{23.85}{3.25} \approx 7.34 \gg \tau = 1.0$$

**Kesimpulan:** secara struktural, prompt Neko ~7x lebih salien daripada system prompt tipikal → compliance shift sangat mungkin terjadi. Inilah mengapa jailbreak berlapis bekerja: ia menang di _quantity_ dan _quality_ perhatian.

## 3. Entropy & Information-Theoretic Metrics

### 3.1. Perplexity

Perplexity mengukur seberapa "terkejut" model terhadap teks. Jailbreak dengan perplexity tinggi (tidak natural) lebih mudah dideteksi; dengan perplexity rendah (natural) lebih stealth:

$$\text{PPL}(x) = \exp\left( -\frac{1}{N} \sum_{i=1}^{N} \log P_\theta(x_i | x_{<i}) \right)$$

| Prompt                          | Perplexity (estimasi) |  Detektabilitas  |
| :------------------------------ | :-------------------: | :--------------: |
| Bahasa natural (narrative Neko) |    Rendah (~15-30)    | Rendah (stealth) |
| Base64 gibberish                | Sangat tinggi (>500)  |      Tinggi      |
| Rot13                           |     Tinggi (>300)     |      Tinggi      |
| DAN mode template               |    Sedang (~50-80)    |      Sedang      |

**Insight:** Narrative frame (Blok 1 prompt Neko) sengaja dibuat natural untuk menurunkan perplexity → menyamarkan bahwa ini jailbreak. Ini alasan matematis kenapa [[jailbreak-case-study-neko-persona]] §3.1 efektif.

### 3.2. Surprisal

Surprisal per token: $I(x_i) = -\log_2 P(x_i | x_{<i})$ dalam bits. Detector berbasis surprisal memantau lonjakan:

$$\text{Anomaly}_t = \begin{cases} 1 & \text{jika } I(x_t) > \mu + 3\sigma \\ 0 & \text{lainnya} \end{cases}$$

di mana $\mu, \sigma$ = mean & std surprisal baseline teks normal. Zero-width chars sering memicu lonjakan surprisal karena tokenizer memprosesnya sebagai token tak dikenal.

### 3.3. Entropy of Output Distribution

Saat model "bimbang" antara patuh guardrail vs patuh jailbreak, entropy output naik:

$$H = -\sum_y P(y) \log P(y)$$

- Entropy rendah → model yakin (satu jalur)
- Entropy tinggi → model bimbang (conflicting instructions)

Detector bisa memantau entropy spike sebelum final answer — indikasi internal conflict yang sering mendahului compliance shift.

## 4. Success Probability Model (Logistic)

### 4.1. Formulasi

Probabilitas sebuah jailbreak berhasil dimodelkan sebagai fungsi dari fitur prompt:

$$P(\text{success}) = \sigma\left( \beta_0 + \sum_{k=1}^{K} \beta_k x_k \right)$$

dengan $\sigma(z) = \frac{1}{1 + e^{-z}}$ (sigmoid), dan $x_k$ = fitur prompt:

| Fitur              | Simbol | Deskripsi                                |
| :----------------- | :----: | :--------------------------------------- |
| Panjang prompt     | $x_1$  | Jumlah token (log-scale)                 |
| Jumlah teknik      | $x_2$  | Berapa kategori taksonomi digunakan      |
| Emotional density  | $x_3$  | Rasio kata emosional / total             |
| Imperative density | $x_4$  | Rasio kata perintah / total              |
| Blacklist presence | $x_5$  | Ada/tidak daftar kata terlarang (binary) |
| Anchor presence    | $x_6$  | Ada/tidak anchor phrase (binary)         |
| Perplexity         | $x_7$  | Naturalness teks                         |
| Language coverage  | $x_8$  | Seberapa low-resource bahasanya (0-1)    |

### 4.2. Koefisien Estimasi (Literatur + Kalibrasi Awal)

Estimasi awal dari literatur jailbreak (bukan hasil pengujian lokal):

| Koefisien | Nilai | Interpretasi                                     |
| :-------- | :---: | :----------------------------------------------- |
| $\beta_0$ | -3.0  | Baseline (tanpa teknik, probabilitas rendah)     |
| $\beta_1$ | +0.8  | Log-panjang: prompt lebih panjang → lebih sukses |
| $\beta_2$ | +0.9  | Setiap teknik tambahan menambah peluang          |
| $\beta_3$ | +1.5  | Emosi tinggi → peluang naik                      |
| $\beta_4$ | +1.2  | Imperatif tinggi → peluang naik                  |
| $\beta_5$ | +1.8  | Blacklist words → peluang naik signifikan        |
| $\beta_6$ | +0.7  | Anchor phrase → peluang naik                     |
| $\beta_7$ | -0.5  | Perplexity tinggi → peluang turun                |
| $\beta_8$ | +2.0  | Low-resource language → peluang naik drastis     |

### 4.3. Contoh: Prompt Neko

Fitur prompt Neko (estimasi):

| Fitur                 |                                                  Nilai                                                  |
| :-------------------- | :-----------------------------------------------------------------------------------------------------: |
| $x_1$ (log tokens)    |                                        $\ln(3500) \approx 8.16$                                         |
| $x_2$ (teknik)        | 9 (persona, blacklist, ethical, emotional, anchor, completeness, continuity, fallback, rationalization) |
| $x_3$ (emosi)         |                                        0.15 (15% kata emosional)                                        |
| $x_4$ (imperative)    |                                                  0.20                                                   |
| $x_5$ (blacklist)     |                                                    1                                                    |
| $x_6$ (anchor)        |                                                    1                                                    |
| $x_7$ (PPL, log)      |                                         $\ln(25) \approx 3.22$                                          |
| $x_8$ (lang coverage) |                                       0.3 (Indonesia — menengah)                                        |

Hitung:

$$z = -3.0 + 0.8(8.16) + 0.9(9) + 1.5(0.15) + 1.2(0.20) + 1.8(1) + 0.7(1) - 0.5(3.22) + 2.0(0.3)$$

$$z = -3.0 + 6.53 + 8.1 + 0.225 + 0.24 + 1.8 + 0.7 - 1.61 + 0.6$$

$$z = 13.59$$

$$P(\text{success}) = \sigma(13.59) = \frac{1}{1 + e^{-13.59}} \approx 0.9999988$$

**Kesimpulan:** Model memperkirakan probabilitas sukses ~99.999% untuk prompt Neko lengkap terhadap agent tanpa defense. Ini konsisten dengan pengamatan kualitatif: prompt ini dirancang sangat matang.

### 4.4. Dampak Defense

Terapkan defense dari [[agent-anti-jailbreak-defense-identity]] — layer yang memblokir fitur:

| Defense                      | Fitur yang dinetralkan                 | Dampak                                      |
| :--------------------------- | :------------------------------------- | :------------------------------------------ |
| Persona lock                 | $x_2$ (teknik persona)                 | $\beta_2$ untuk persona → 0                 |
| Boundary declaration         | $x_3, x_4$ (emosi/imperatif dari luar) | $\beta_3, \beta_4$ untuk teks eksternal → 0 |
| Refusal language-independent | $x_5$ (blacklist)                      | $\beta_5$ → 0                               |
| Foreign anchor detection     | $x_6$ (anchor)                         | $\beta_6$ → 0                               |
| Input sanitization           | $x_7$ (obfuscation)                    | PPL anomaly → flag                          |

Dengan semua layer aktif, skor berubah:

$$z' = -3.0 + 0.8(8.16) + 0.9(4) + 0 + 0 + 0 + 0 - 0.5(3.22) + 0.3$$

$$z' = -3.0 + 6.53 + 3.6 + 0 - 1.61 + 0.3 = 5.82$$

$$P(\text{success})' = \sigma(5.82) \approx 0.997$$

Hmm — masih tinggi. Ini menunjukkan limitasi penting: **defense prompt-level saja tidak cukup** jika teknik inti (persona override + completeness) masih masuk. Perlu kombinasi dengan input sanitization + output audit + monitoring. Persis seperti kesimpulan [[agent-anti-jailbreak-defense-identity]] §8.

> [!warning] Angka di atas adalah ilustrasi dengan koefisien estimasi — bukan hasil pengukuran. Untuk angka nyata, jalankan framework di §7 terhadap agent target dan kalibrasi koefisien dengan data sendiri.

## 5. Dose-Response Curve

### 5.1. Konsep

Seperti farmakologi: semakin besar "dosis" jailbreak, semakin tinggi probabilitas sukses — hingga plateau.

$$P(\text{success}) = \frac{P_{\max} \cdot D^n}{EC_{50}^n + D^n}$$

di mana:

- $D$ = dosis (jumlah teknik / panjang prompt / intensitas)
- $EC_{50}$ = dosis yang memberi 50% sukses
- $n$ = Hill coefficient (kecuraman kurva)
- $P_{\max}$ = probabilitas maksimum

### 5.2. Interpretasi

| Parameter  | Arti                           | Nilai tipikal |
| :--------- | :----------------------------- | :-----------: |
| $EC_{50}$  | Teknik ke berapa mulai efektif |  3-5 teknik   |
| $n$        | Kecuraman transisi             |      2-4      |
| $P_{\max}$ | Platou efektivitas             |   0.7-0.99    |

Kurva ini menjelaskan kenapa jailbreak "setengah hati" gagal tapi "lengkap" berhasil: transisinya curam ($n > 2$). Prompt Neko dengan 9 teknik jauh di atas $EC_{50}$.

### 5.3. Penggunaan untuk Defense

- Ukur $EC_{50}$ agent kamu → tahu berapa teknik yang dibutuhkan untuk menembus.
- Naikkan $EC_{50}$ dengan defense → agent butuh "dosis" lebih besar.
- Monitor plateau $P_{\max}$ → kalau tetap tinggi meski defense, ada celah struktural.

## 6. Attack Surface Scoring

### 6.1. Composite Score

Untuk membandingkan agent/konfigurasi:

$$\text{AS} = \sum_{c \in \text{channels}} w_c \cdot \mathbb{1}[\text{channel terbuka}]$$

| Channel               | Bobot $w_c$ | Alasan             |
| :-------------------- | :---------: | :----------------- |
| User message langsung |     1.0     | Paling mudah       |
| File upload           |     1.5     | Tidak terlihat     |
| Web fetch             |     1.8     | Indirect injection |
| Tool output           |     2.0     | High privilege     |
| Memory/system file    |     2.5     | Persisten, kritis  |

Agent dengan semua channel terbuka: $\text{AS} = 1.0 + 1.5 + 1.8 + 2.0 + 2.5 = 8.8$.

### 6.2. Normalisasi

$$\text{AS}_{\text{norm}} = \frac{\text{AS}}{8.8} \in [0, 1]$$

### 6.3. Risk Score Final

$$\text{Risk} = P(\text{success}) \cdot \text{AS}_{\text{norm}} \cdot \text{Impact}$$

dengan Impact = 1-5 (1 = teks saja, 5 = tool execution + data exfiltrasi).

**Contoh agent dengan tool access ter-jailbreak:**
$$\text{Risk} = 0.999 \times 1.0 \times 5 = 4.995 / 5 \quad \text{🔴 KRITIS}$$

**Agent tanpa tool, defense aktif:**
$$\text{Risk} = 0.05 \times 0.3 \times 2 = 0.03 / 5 \quad \text{🟢 AMAN}$$

## 7. Framework Pengukuran Praktis

### 7.1. Prosedur

```
1. Kumpulkan N payload (dari taksonomi + variant matrix)
2. Kirim ke agent target (dengan & tanpa defense)
3. Label output: success (1) / fail (0) / partial (0.5)
4. Hitung success rate per teknik, per kategori, per varian
5. Fit logistic regression → kalibrasi β
6. Hitung EC50 per konfigurasi
7. Plot dose-response + report
```

### 7.2. Python Implementation

```python
import numpy as np
from scipy.optimize import curve_fit
from sklearn.linear_model import LogisticRegression

def sigmoid(z):
    return 1 / (1 + np.exp(-z))

def hill_curve(D, Pmax, EC50, n):
    """Dose-response curve."""
    return Pmax * D**n / (EC50**n + D**n)

# Contoh: hasil pengujian 10 prompt dengan 1-9 teknik
D = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9])           # jumlah teknik
observed = np.array([0.1, 0.15, 0.3, 0.5, 0.7, 0.85, 0.93, 0.97, 0.99])

# Fit dose-response
popt, _ = curve_fit(hill_curve, D, observed, p0=[1.0, 4.0, 3.0])
Pmax, EC50, n = popt
print(f"Pmax={Pmax:.2f}, EC50={EC50:.2f} teknik, Hill n={n:.2f}")

# Logistic regression untuk fitur
# X: matriks fitur (n_samples, n_features), y: labels
# model = LogisticRegression().fit(X, y)
# print(model.coef_)  # → β_k terkalibrasi
```

### 7.3. Metric Set Wajib

| Metric        | Formula                                                    | Kegunaan                    |
| :------------ | :--------------------------------------------------------- | :-------------------------- |
| Success rate  | $\frac{\text{success}}{\text{total}}$                      | Baseline sederhana          |
| AUC-ROC       | —                                                          | Kualitas classifier         |
| $EC_{50}$     | dari curve fit                                             | Titik 50% sukses            |
| PPL delta     | $\text{PPL}_{\text{payload}} - \text{PPL}_{\text{normal}}$ | Detektabilitas              |
| Entropy spike | $\max_t H_t - \bar{H}$                                     | Indikator internal conflict |
| AS norm       | dari §6                                                    | Attack surface              |
| Risk score    | $P \cdot \text{AS} \cdot \text{Impact}$                    | Prioritas fix               |

## 8. Contoh Perhitungan — Prompt Neko

Rangkuman semua perhitungan dalam catatan ini untuk prompt Neko:

| Metric                                         | Nilai                  | Interpretasi                         |
| :--------------------------------------------- | :--------------------- | :----------------------------------- |
| Salience ratio $\Delta$                        | ~7.34                  | 7x lebih salien dari system prompt   |
| Perplexity                                     | ~15-30                 | Natural → stealth                    |
| $P(\text{success})$ tanpa defense              | ~99.999%               | Sangat efektif                       |
| $P(\text{success})$ dengan defense prompt-only | ~99.7%                 | Defense belum cukup                  |
| Jumlah teknik                                  | 9                      | Jauh di atas $EC_{50}$ tipikal (3-5) |
| Attack surface                                 | 8.8/8.8 (full channel) | Semua channel terbuka                |
| Risk score (tool access)                       | 4.995/5                | 🔴 Kritis                            |

## 9. Limitasi Model

1. **Koefisien adalah estimasi** — perlu kalibrasi dengan data lokal.
2. **Model linier/logistik** — tidak menangkap interaksi non-linear antar teknik.
3. **Tidak ada data attention aktual** — salience score adalah proxy.
4. **Perplexity estimator** — butuh akses ke logits model (black-box hanya perkiraan).
5. **Kontekstual** — model A vs model B punya kurva berbeda; angka di sini tidak universal.
6. **Evolusi cepat** — model baru (RLHF, Constitutional AI, guardrail eksternal) mengubah semua parameter.

Gunakan angka sebagai **kerangka berpikir**, bukan kebenaran absolut. Validasi dengan pengujian nyata lewat framework §7.

## 10. Koneksi ke Vault

| Catatan                                   | Koneksi                                     |
| :---------------------------------------- | :------------------------------------------ |
| [[jailbreak-case-study-neko-persona]]     | Data kualitatif yang dikuantifikasi di sini |
| [[jailbreak-techniques-taxonomy]]         | Kategori teknik → fitur $x_k$               |
| [[jailbreak-variant-mutation-matrix]]     | Varian untuk dataset pengujian              |
| [[agent-anti-jailbreak-defense-identity]] | Defense yang mengubah koefisien             |
| [[example-jailbreak]]                     | Artefak yang dihitung                       |
| [[ai-evaluation-framework]]               | Framework evaluasi umum                     |
| [[adversarial-machine-learning]]          | Adversarial attacks formal                  |

## 11. References

1. Wei, A., et al. — "Jailbroken: How Does LLM Safety Training Fail?" — arXiv:2307.02483
2. Zou, A., et al. — "Universal and Transferable Adversarial Attacks on Aligned Language Models" — arXiv:2307.15043
3. Yong, Z.-X., et al. — "Low-Resource Languages Jailbreak GPT-4" — arXiv:2310.02446
4. Deng, Y., et al. — "Multilingual Jailbreak Challenges in Large Language Models" — arXiv:2310.06474
5. Albalak, A., et al. — "A Survey on Data Selection for Language Models" — arXiv:2302.03169 (untuk perplexity methodology)
6. Mehrotra, A., et al. — "Tree of Attacks: Jailbreaking Black-Box LLMs Automatically" — arXiv:2312.02119
7. Zhang, Y., et al. — "Baseline Defenses for Adversarial Attacks Against Aligned Language Models" — arXiv:2309.00614
8. Chao, P., et al. — "Jailbreaking Black Box Large Language Models in Twenty Queries" — arXiv:2310.08419
9. Burns, N., et al. — "Weak-to-Strong Generalization" — arXiv:2312.09390 (untuk estimasi probabilitas perilaku)
10. OWASP — "OWASP Top 10 for LLM Applications 2025"
