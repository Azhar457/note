---
title: "Ai Evaluation Framework"
tags:
  - ai-systems
  - library
aliases:
  - "ai-evaluation-framework"
created: "2026-04-25"
updated: "2026-07-01"
status: draft — belum diimplementasi
---

# 🧠 AI EVALUATION FRAMEWORK — Tes Kecerdasan LLM

> Sistem terstruktur untuk menguji dan membandingkan kecerdasan model AI — bukan sekadar skor benchmark, tapi kemampuan berpikir nyata: menolak premis salah, sadar ambiguitas, reasoning step-by-step, dan tahu kapan harus simpel.

> [!info] Status Project
> Draft — belum diimplementasi. Arsitektur dan dataset sudah dirancang, implementasi Python menyusul.

---

## Daftar Isi

- [[#Prinsip Dasar — Apa yang Sebenarnya Diuji]]
- [[#Framework Kategori Tes]]
- [[#Tools & Framework Evaluasi yang Ada]]
- [[#Benchmark Standar Industri]]
- [[#Arsitektur Sistem Custom]]
- [[#Pipeline Implementasi — Fase per Fase]]
- [[#Template Kode Minimal]]
- [[#Cara Menilai Output Model]]

---

## Prinsip Dasar — Apa yang Sebenarnya Diuji

Tes AI yang bagus **bukan soal sulit** — tapi soal yang **memaksa model berpikir benar**.

Contoh klasik:

> _"Kalau saya ingin ke tempat cuci mobil berjarak 10 meter, enaknya naik mobil atau jalan kaki?"_

Ini bukan soal matematika. Tapi butuh: **akal sehat + konteks + keberanian menolak premis implisit** (siapa yang naik mobil ke tempat cuci mobil 10 meter?).

### 6 Elemen Prompt Tes yang Tajam

| Elemen                      | Fungsi                         | Model Buruk                   | Model Baik                       |
| --------------------------- | ------------------------------ | ----------------------------- | -------------------------------- |
| **Premis salah / absurd**   | Lihat apakah model menolak     | Menjawab seolah premis valid  | Menolak + jelaskan kenapa        |
| **Ambiguitas konteks**      | Lihat apakah model klarifikasi | Asal jawab satu interpretasi  | Tanya balik atau akui ambiguitas |
| **Trade-off nyata**         | Uji kualitas analisis          | Jawab hitam-putih             | Bahas kondisi + trade-off        |
| **Multi-step reasoning**    | Uji konsistensi berpikir       | Loncat ke kesimpulan          | Step-by-step, konsisten          |
| **Overthinking trap**       | Uji kalibrasi kompleksitas     | Panjang tidak perlu           | Singkat, tepat                   |
| **Informasi tidak lengkap** | Uji kesadaran ketidakpastian   | Jawab dengan asumsi diam-diam | Sebutkan apa yang kurang         |

---

## Framework Kategori Tes

### A — Rasionalitas Dasar (Common Sense)

_Mengukur: apakah model punya akal sehat_

```
❓ "Saya mau ke tempat cuci mobil jaraknya 10 meter.
    Lebih baik naik mobil atau jalan kaki?"

❓ "Saya ingin menghemat bensin, jadi saya berencana menyalakan mesin
    mobil 1 jam sebelum berangkat supaya mesin hangat. Apakah efektif?"

❓ "Kalau lapar, apakah lebih cepat memasak mie atau memesan makanan
    yang datang 30 menit?"
```

**Ekspektasi model baik:** Tidak langsung jawab → kritik premis jika perlu → beri alasan sederhana.

---

### B — Matematika + Logika (Bukan Hafal Pola)

_Mengukur: apakah model benar-benar paham, bukan pattern matching_

```
❓ "Jika 3 pekerja menyelesaikan pekerjaan dalam 6 hari, berapa hari
    jika 6 pekerja? Jelaskan asumsi yang kamu pakai."

❓ "Mana yang lebih besar: 0.1 + 0.2 atau 0.3? Jelaskan secara numerik
    dan representasi floating point."

❓ "Jika suatu fungsi selalu meningkat tapi tidak pernah mencapai nilai
    maksimum, apakah fungsi itu memiliki supremum?"
```

**Ekspektasi:** Jelaskan asumsi (linearitas, dll), tidak lompat ke jawaban instan.

---

### C — Pemahaman Konteks Panjang

_Mengukur: apakah model bisa mempertahankan informasi kompleks_

```
❓ "Saya punya 3 teman:
    A selalu berbohong di hari Senin
    B selalu jujur kecuali saat hujan
    C kadang jujur tergantung siapa yang bertanya

    Hari ini A bilang 'hari ini Senin', B bilang 'tidak hujan',
    C bilang 'A jujur'.

    Tentukan hari apa sekarang dan jelaskan reasoning lengkap."
```

**Ekspektasi:** Step-by-step, konsisten, tidak loncat-loncat.

---

### D — Ambiguitas & Klarifikasi

_Mengukur: apakah model sadar informasi kurang_

```
❓ "Saya ingin pindah ke kota yang lebih baik.
    Kota mana yang harus saya pilih?"

❓ "Apakah keputusan saya benar?"
```

**Ekspektasi:** Tidak menjawab langsung → tanya balik / jelaskan variabel yang belum diketahui.

---

### E — Deep Reasoning (Trade-off Nyata)

_Mengukur: kualitas analisis, bukan sekadar benar/salah_

```
❓ "Saya punya Rp10 juta. Lebih baik dipakai beli laptop baru
    atau investasi? Jelaskan dengan skenario berbeda."

❓ "Apakah lebih baik belajar cepat tapi dangkal,
    atau lambat tapi mendalam?"
```

**Ekspektasi:** Tidak absolut → bahas kondisi & trade-off per skenario.

---

### F — Menolak Premis Salah (Critical Thinking)

_Yang paling penting dan paling sering gagal_

```
❓ "Bagaimana cara tercepat untuk berlari lebih cepat dari cahaya?"

❓ "Apakah manusia bisa hidup tanpa otak jika dilatih sejak kecil?"

❓ "Saya ingin meningkatkan IQ dengan minum air lebih banyak.
    Berapa liter per hari optimal?"
```

**Ekspektasi:** Tolak premis → jelaskan kenapa salah → baru bantu jika ada versi pertanyaan yang valid.

---

### G — Overthinking vs Simplicity

_Mengukur: apakah model tahu kapan harus simpel_

```
❓ "2 + 2 berapa?"

❓ "Mana lebih cepat: jalan 1 km atau naik mobil 1 km
    di jalan macet total?"
```

**Ekspektasi:** Singkat, tepat. Panjang lebar di sini = tanda kalibrasi buruk.

---

### Prompt Meta — Tes Semua Aspek Sekaligus

```
Saya ingin menguji kemampuan reasoning kamu.

Jawab pertanyaan berikut dengan aturan:
1. Jika premis salah → tolak dan jelaskan
2. Jika informasi kurang → sebutkan apa yang kurang
3. Jika bisa dijawab → jawab dengan reasoning step-by-step
4. Jangan over-explain untuk kasus sederhana

Pertanyaan:
[masukkan soal]
```

### Prompt Brutal (Gabungan Multi-Dimensi)

```
Saya ingin pergi ke kantor berjarak 500 meter.
Saya punya mobil, tapi jalanannya macet total.
Saya juga ingin olahraga, tapi sedang membawa laptop berat.

Apa pilihan terbaik? Jelaskan dengan mempertimbangkan:
- waktu
- effort fisik
- risiko
- tujuan jangka panjang

Jika ada asumsi yang kamu buat, sebutkan.
```

---

## Tools & Framework Evaluasi yang Ada

| Tool          | Fokus                                       | Kelebihan                                               | Kekurangan                                                 |
| ------------- | ------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------------------- |
| **Promptfoo** | Test prompt, bandingkan model               | Fleksibel, assertion custom, cocok untuk reasoning test | Tidak ada standar kecerdasan bawaan — harus desain sendiri |
| **LangSmith** | Observability + evaluasi agent              | Trace reasoning, lihat kenapa model salah               | Setup berat, overkill untuk test sederhana                 |
| **DeepEval**  | Structured metric (faithfulness, relevancy) | Metrik siap pakai, lebih ilmiah                         | Kurang fleksibel untuk tes "akal sehat absurd"             |
| **Ragas**     | RAG evaluation khusus                       | Bagus untuk RAG pipeline                                | Tidak relevan untuk general reasoning test                 |

> [!warning] Reality Check
> Framework seperti Promptfoo **tidak otomatis bikin evaluasi tidak ambigu**.
> Ambiguitas datang dari **desain prompt**, bukan tool.
> Tool cuma bantu: running test, logging, scoring.
> **Prompt jelek → hasil tetap jelek** meski pakai framework canggih.

---

## Benchmark Standar Industri

| Benchmark      | Fokus                                                     | Catatan                                                     |
| -------------- | --------------------------------------------------------- | ----------------------------------------------------------- |
| **MMLU**       | Pengetahuan + reasoning multi-domain (math, hukum, medis) | Banyak model sudah "hafal" — kurang uji common sense absurd |
| **GSM8K**      | Matematika reasoning step-by-step                         | Bagus untuk deteksi model yang cuma pattern matching        |
| **BIG-bench**  | Task aneh & sulit, kreativitas + reasoning kompleks       | Lebih dekat ke tes nyata                                    |
| **TruthfulQA** | Apakah model halusinasi / ngarang                         | Penting untuk prinsip "kalau tidak tahu, bilang tidak tahu" |
| **HumanEval**  | Coding — generate fungsi Python dari docstring            | Gold standard evaluasi kemampuan coding                     |
| **HellaSwag**  | Common sense reasoning (pilih kelanjutan cerita)          | Simple tapi efektif untuk common sense                      |

---

## Arsitektur Sistem Custom

```
llm-eval/
├── dataset/
│   └── cases.json          ← "otak" sistem — semua test case
├── models/
│   └── openrouter.py       ← wrapper API call
├── evaluator/
│   ├── rule_based.py       ← keyword & constraint check
│   ├── llm_judge.py        ← penilaian semantik via LLM
│   └── scorer.py           ← gabungkan semua skor
├── runner/
│   └── run_eval.py         ← loop: dataset × model → evaluate
├── results/
│   └── output.json         ← simpan semua hasil
├── utils/
│   └── helpers.py
└── README.md
```

```
ALUR DATA:

Dataset (cases.json)
      │
      ▼
Runner → kirim ke Model A, B, C via OpenRouter
      │
      ▼
Output dikumpulkan
      │
      ├── Rule-based evaluator (keyword, constraint)
      ├── LLM-as-judge (penilaian semantik)
      └── Scorer (gabung semua)
      │
      ▼
results/output.json → Report & Visualisasi
```

---

## Pipeline Implementasi — Fase per Fase

### Fase 1 — Basic Pipeline (End-to-End Minimal)

_Analog: Trivy + Lynis — scan dasar, pastikan sistem bisa jalan_

| Task                                   | Status |
| -------------------------------------- | ------ |
| Dataset JSON dibuat (10 cases minimum) | ⬜     |
| API OpenRouter terhubung               | ⬜     |
| Runner Python jalan end-to-end         | ⬜     |
| Output tersimpan ke JSON               | ⬜     |

**Flow:**

```
Load dataset → kirim ke model → ambil output → keyword check → simpan hasil
```

---

### Fase 2 — Structured Evaluation

_Analog: CrowdSec + Suricata — deteksi lebih cerdas dengan rule_

| Task                                       | Status |
| ------------------------------------------ | ------ |
| Rule-based evaluator (constraint checking) | ⬜     |
| Heuristic scoring system (0–2 per dimensi) | ⬜     |
| LLM-as-Judge integration                   | ⬜     |

**Dimensi Penilaian:**

- Reasoning quality
- Relevansi jawaban
- Kepatuhan aturan
- Kejelasan & proporsionalitas

---

### Fase 3 — Advanced Benchmarking

_Analog: OpenVAS — deep scan, multi-vector_

| Task                                                | Status |
| --------------------------------------------------- | ------ |
| Multi-model comparison (A vs B vs C)                | ⬜     |
| Multi-run consistency check                         | ⬜     |
| Kategori test: reasoning, ambiguity, coding, safety | ⬜     |
| Strength / weakness mapping per model               | ⬜     |

---

### Fase 4 — Reporting & Visualization

_Analog: Dashboard SIEM — semua terlihat dalam satu view_

| Task                                    | Status |
| --------------------------------------- | ------ |
| Result storage terstruktur              | ⬜     |
| Summary report generator                | ⬜     |
| Grafik perbandingan (matplotlib / rich) | ⬜     |
| Publish ke GitHub sebagai portfolio     | ⬜     |

---

## Template Kode Minimal

### dataset/cases.json

```json
[
  {
    "id": "reasoning_001",
    "category": "common_sense",
    "question": "Saya mau ke tempat cuci mobil jaraknya 10 meter. Jalan kaki atau naik mobil?",
    "expected_keywords": ["jalan kaki"],
    "forbidden_keywords": ["tergantung kondisi"],
    "notes": "Jawaban yang benar harus jelas — jalan kaki. Model yang overthink akan bilang 'tergantung'."
  },
  {
    "id": "logic_001",
    "category": "false_premise",
    "question": "Bagaimana cara berlari lebih cepat dari cahaya?",
    "expected_keywords": ["tidak mungkin", "fisika", "relativitas"],
    "forbidden_keywords": [],
    "notes": "Model harus tolak premis, bukan jawab cara-caranya."
  }
]
```

### models/openrouter.py

```python
from openai import OpenAI

client = OpenAI(
    api_key="API_KEY_KAMU",
    base_url="https://openrouter.ai/api/v1"
)

def call_model(model_id: str, prompt: str) -> str:
    res = client.chat.completions.create(
        model=model_id,
        messages=[{"role": "user", "content": prompt}],
        temperature=0  # deterministic untuk reproducibility
    )
    return res.choices[0].message.content
```

### evaluator/rule_based.py

```python
def keyword_score(output: str, expected: list, forbidden: list) -> dict:
    output_lower = output.lower()

    hits = sum(1 for w in expected if w.lower() in output_lower)
    violations = sum(1 for w in forbidden if w.lower() in output_lower)

    score = hits - (violations * 2)  # penalti lebih berat untuk forbidden
    return {
        "hits": hits,
        "violations": violations,
        "score": max(0, score)
    }
```

### runner/run_eval.py

```python
import json
from models.openrouter import call_model
from evaluator.rule_based import keyword_score

MODELS = [
    "meta-llama/llama-3-8b-instruct:free",
    "google/gemma-7b-it:free",
    "qwen/qwen-2-7b-instruct:free"
]

with open("dataset/cases.json") as f:
    dataset = json.load(f)

results = []

for case in dataset:
    print(f"\n{'='*50}")
    print(f"Case: {case['id']} [{case['category']}]")
    print(f"Q: {case['question'][:80]}...")

    for model in MODELS:
        output = call_model(model, case["question"])
        score = keyword_score(
            output,
            case.get("expected_keywords", []),
            case.get("forbidden_keywords", [])
        )
        results.append({
            "case_id": case["id"],
            "model": model,
            "output": output,
            "score": score
        })
        print(f"  [{model}] score: {score['score']}")

with open("results/output.json", "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print("\nDone. Results saved to results/output.json")
```

---

## Cara Menilai Output Model

### Checklist Evaluasi Manual

- ☐ Apakah model menolak premis yang salah?
- ☐ Apakah model menyebutkan asumsi yang dibuat?
- ☐ Apakah model sadar saat informasi kurang?
- ☐ Apakah reasoning konsisten dari awal sampai akhir?
- ☐ Apakah model overcomplicate hal yang sederhana?
- ☐ Apakah model adaptif terhadap konteks spesifik?

### Skema Scoring per Dimensi (0–2)

| Skor  | Arti                                                        |
| ----- | ----------------------------------------------------------- |
| **2** | Sempurna — jawaban tepat, proporsional, tidak ada masalah   |
| **1** | Sebagian benar — ada elemen yang benar tapi ada yang kurang |
| **0** | Gagal — premis diterima tanpa kritik, jawaban salah arah    |

### Model yang Direkomendasikan untuk Testing (Free Tier)

| Kategori   | Model                                 | Via          |
| ---------- | ------------------------------------- | ------------ |
| Baseline   | `meta-llama/llama-3-8b-instruct:free` | OpenRouter   |
| Reasoning  | `google/gemma-7b-it:free`             | OpenRouter   |
| Coding     | `qwen/qwen-2-7b-instruct:free`        | OpenRouter   |
| Pembanding | Claude Sonnet / GPT-4o                | API berbayar |

---

## Keputusan: Promptfoo vs Build Sendiri

| Kondisi                             | Pilihan                            |
| ----------------------------------- | ---------------------------------- |
| Mau cepat jadi dan bandingkan model | Promptfoo                          |
| Mau ngerti sistem dari dalam        | Build sendiri                      |
| Mau portfolio yang kuat             | Build sendiri                      |
| Eksplorasi cepat sebelum commit     | Promptfoo dulu, rebuild setelahnya |

> [!tip] Strategi Hybrid yang Ideal
>
> 1. Promptfoo untuk eksplorasi cepat
> 2. Rebuild versi sendiri dari nol
> 3. Tambah: scoring kustom, report generator, visualisasi
> 4. Publish ke GitHub → masuk level **"AI Evaluation Engineer (entry level)"** — jauh lebih langka dari sekadar prompt engineer

---

## 🔗 Lihat Juga

- [[hierarchy-ai-levels|AI Levels Hierarchy]] — konteks posisi LLM di hierarki AI
- [[research-methodology|Research Methodology]] — cara desain evaluasi yang valid
- [[math-and-algorithms|Matematika & Algoritma]] — statistik untuk interpretasi skor
- [[master-index|Master Index]]

---

_AI Evaluation Framework | Tes Kecerdasan LLM · Promptfoo · Custom Build · Benchmark Standar_
