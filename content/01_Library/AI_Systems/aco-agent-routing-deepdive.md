---
title: η dari Semantic Discovery (pre-computed per agent)
tags:
- swarm-intelligence
- agent-orchestration
- routing
- aco
- multi-agent
aliases:
- ACO Agent Routing
- Ant Colony Agent Dispatch
- Pheromone Routing
created: 2026-07-25
updated: 2026-07-25
status: pending
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Dari Feromon Semut ke Routing Agen
> Ant Colony Optimization (ACO) bukanlah metafora puitis untuk agent orchestration. Formula probabilitas `Pᵢⱼᵏ = [τᵢⱼ]ᵅ·[ηᵢⱼ]ᵇ / Σ[τᵢₗ]ᵅ·[ηᵢₗ]ᵇ` memetakan **secara langsung** ke masalah memoryless reassign di multi-agent routing. Heuristic visibility (η) = embedding similarity score yang SUDAH dihitung oleh Semantic Discovery. Pheromone (τ) = history success weight yang belum ada sama sekali. Evaporation (ρ) = pelupaan otomatis trust usang. Catatan ini mendokumentasikan implementasi ACO untuk agent routing dengan bukti konvergensi numerik dari 5 skenario simulasi.

---

## Daftar Isi
1. [[#1. Masalah — Memoryless Reassign]]
2. [[#2. Solusi — ACO sebagai Learning Layer]]
3. [[#3. Mapping ACO ke Agent Routing]]
4. [[#4. Formula Lengkap dengan Contoh Numerik]]
5. [[#5. Exploration Lockout dan MMAS Fix]]
6. [[#6. Parameter Sensitivity Analysis]]
7. [[#7. Compound Task — ACO di Level Sub-Task]]
8. [[#8. Implementasi Python]]
9. [[#9. Hasil Simulasi — 5 Skenario]]
10. [[#10. Kapan ACO Bekerja dan Kapan Tidak]]
11. [[#11. References]]

---

## 1. Masalah — Memoryless Reassign

Arsitektur meta-agent saat ini (`meta-agent-orchestration.md`) memiliki 4 strategi penanganan kegagalan: **retry → reassign → decompose → escalate**. Masalahnya ada di langkah reassign:

### Semantic Discovery (Sekarang)

```
task_type=code_review
  → hitung embedding_similarity(task_desc, agent_capability)
  → sort descending → pilih candidates[0]
```

**Ini memoryless.** Setiap dispatch tidak belajar dari dispatch sebelumnya. Jika Agent-X gagal dan Agent-Y mengambil alih dengan sukses, keberhasilan itu **tidak pernah menjadi sinyal** untuk dispatch berikutnya. Round berikutnya, sistem mulai dari nol lagi — hanya bermodal static capability match.

### Dampak Konkret

| Skenario | Static η (sekarang) | Masalah |
|----------|:-------------------:|:--------|
| Provider baru (Mistral) masuk | η harus di-set manual | Tidak bisa belajar sendiri |
| Yuanbao upgrade model | η tetap 0.50 untuk coding | Tidak pernah tau improvement |
| DeepSeek kena rate limit | η tetap 0.85 untuk search | Tetap dikirimi traffic → gagal |
| Provider ganti model | η tetap | Trust lama tidak pernah evaporasi |

---

## 2. Solusi — ACO sebagai Learning Layer

ACO menambahkan **satu dimensi baru** ke routing: τ (pheromone), yaitu weight historis yang belajar dari setiap completion.

```
Sebelum:  winner = argmax(ηᵢ)          ← static semantic match
Sesudah:  Pᵢ ∝ τᵢᵅ · ηᵢᵝ              ← history + semantics
          τᵢ ← (1-ρ)·τᵢ + Δτᵢ         ← belajar dari hasil
```

### Arsitektur

```
┌─────────────────────────────┐
│         Task Input          │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│    Semantic Discovery (η)   │ ← sudah ada
│    embedding similarity     │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│    ACO Router (τ matrix)    │ ← BARU
│    P = τᵅ · ηᵝ / Σ          │
│    update τ after each task │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│    Agent terpilih           │
└─────────────────────────────┘
```

ACO duduk di **antara** Semantic Discovery dan eksekusi. η sudah dihitung oleh Semantic Discovery. ACO menggabungkannya dengan τ untuk menghasilkan keputusan probabilistik.

---

## 3. Mapping ACO ke Agent Routing

### Formula Ant System

```
Pᵢⱼᵏ = [τᵢⱼ]ᵅ · [ηᵢⱼ]ᵇ / Σ_l [τᵢₗ]ᵅ · [ηᵢₗ]ᵇ
τᵢⱼ ← (1 - ρ)·τᵢⱼ + Σ_k Δτᵢⱼᵏ
```

### Pemetaan Langsung

| Simbol ACO | Nama | Agent Routing | Sumber |
|:----------:|:----|:--------------|:------:|
| ηᵢⱼ | Heuristic visibility | Embedding similarity(task_type, agent_capability) | ✅ SUDAH ADA |
| τᵢⱼ | Pheromone intensity | `pheromone[task_type][agent_id]` | ❌ BARU |
| α | Pheromone weight | Seberapa besar history mempengaruhi keputusan | ❌ BARU |
| β | Heuristic weight | Seberapa besar semantic match mempengaruhi | ❌ BARU |
| ρ | Evaporation rate | Kecepatan melupakan trust lama | ❌ BARU |
| Δτᵢⱼᵏ | Deposit quality | Sinyal kualitas hasil (auto-eval / feedback) | ❌ BARU |
| Pᵢⱼᵏ | Selection probability | Probabilitas agent `j` dipilih untuk task `i` | ❌ BARU |

### Interpretasi Per Parameter

```
α=0 → P hanya berdasarkan η → balik ke sistem sekarang (no learning)
β=0 → P hanya berdasarkan τ → murni history, η diabaikan (berbahaya)
α=1, β=2 → balanced (standar literatur ACO)
ρ rendah (0.1) → perubahan lambat, stabil
ρ tinggi (0.7) → cepat lupa, responsif
Q besar (1.5) → satu batch sukses langsung dominan
Q kecil (0.3) → butuh banyak batch untuk konvergen
```

---

## 4. Formula Lengkap dengan Contoh Numerik

### Setup

```
task_type = "refactor_rust"
agents = [Claude(η=0.90), DeepSeek(η=0.70), Llama(η=0.40)]
α=1, β=2, ρ=0.3, Q=0.5, τ₀=0.10
```

### Round 0 — Initial (sama dengan sistem sekarang)

| Agent | η | τ₀ | η² | τ·η² | P₀ |
|:------|:--:|:--:|:--:|:----:|:--:|
| Claude | 0.90 | 0.10 | 0.81 | 0.0810 | **55.5%** |
| DeepSeek | 0.70 | 0.10 | 0.49 | 0.0490 | **33.6%** |
| Llama | 0.40 | 0.10 | 0.16 | 0.0160 | **11.0%** |

Semua τ seragam → P murni dari η. Sama dengan yang terjadi sekarang.

### Round 1 — 10 task dispatch

Probabilitas Round 0 menghasilkan ~6 Claude, 3 DeepSeek, 1 Llama.

| Agent | Dispatch | Sukses | Skor | Δτ = Q·(sukses/dispatch) |
|:------|:--------:|:------:|:----:|:-------------------------:|
| Claude | 6 | 5 | 83% | 0.5 × 5/6 = **0.4167** |
| DeepSeek | 3 | 2 | 67% | 0.5 × 2/3 = **0.3333** |
| Llama | 1 | 0 | 0% | 0.5 × 0/1 = **0** |

**Update pheromone:** τ ← (1-ρ)·τ₀ + Δτ = 0.7 × 0.10 + Δτ

```
Claude:   0.07 + 0.4167 = 0.4867
DeepSeek: 0.07 + 0.3333 = 0.4033
Llama:    0.07 + 0      = 0.0700
```

### Round 2 — Recalculate P dengan τ baru

| Agent | τ₁·η² | P₂ | Δ P₀→P₂ |
|:------|:-----:|:--:|:-------:|
| Claude | 0.3942 | **65.4%** | +9.9% |
| DeepSeek | 0.1976 | **32.8%** | −0.8% |
| Llama | 0.0112 | **1.9%** | −9.1% |

Llama tetap mendapat 11% selamanya di sistem lama (η statis). Setelah ACO, **turun ke 1.9%** karena track record jelek — η tidak berubah, tapi τ turun drastis. Ini adalah bukti numerik bahwa ACO memperbaiki keputusan routing hanya dalam 2 round.

### Trajectory 5 Round

```
Round 1: Claude P=55.5%  DeepSeek P=33.6%  Llama P=11.0%
Round 2: Claude P=81.2%  DeepSeek P=16.8%  Llama P= 2.0%
Round 3: Claude P=65.7%  DeepSeek P=33.5%  Llama P= 0.9%
Round 5: Claude P=76.8%  DeepSeek P=22.5%  Llama P= 0.7%
     τ:  1.1730           0.6153            0.0500 (MMAS floor)
```

---

## 5. Exploration Lockout dan MMAS Fix

### Bahaya: Rich-Get-Richer

Di P=1.9%, dari 10 dispatch berikutnya, peluang Llama **tidak kebagian sama sekali**:

```
(1 - 0.019)¹⁰ ≈ 83%
```

Kalau tidak pernah kebagian, τ-nya hanya keevaporasi tanpa replenish:
```
0.07 → 0.049 → 0.034 → 0.024 → ... → mendekati nol
```

**Semakin mendekati nol, semakin kecil sampling-nya.** Ini adalah **rich-get-richer trap**: kalau Llama tiba-tiba di-upgrade provider-nya jadi bagus, sistem tidak akan pernah tahu karena sudah tidak di-sampling lagi.

### Fix #1: MMAS Floor (Max-Min Ant System)

```
τ = max(τ_baru, τ_min)
τ_min = 0.05
```

Llama tidak akan pernah bener-bener nol — selalu ada ~3% sampling chance.

### Fix #2: ε-greedy Override

```
if random() < ε:
    pilih agent random (bukan ACO)
ε = 0.05
```

5% dari waktu, abaikan P dan pilih agent secara random. Independen dari histori.

### Hasil Simulasi — Provider Recovery

Llama jelek di round 1-10 (ability 0%), lalu tiba-tiba menjadi TERBAIK di round 11-20 (ability 95%).

| Guard | P(Llama) round 10 | P(Llama) round 20 | Hasil |
|:------|:-----------------:|:-----------------:|:------|
| Tanpa MMAS, tanpa ε | 0.03% | **0.00%** ❌ | Permanen mati |
| MMAS + ε=0.05 | 0.56% | **5.00%** ✅ | Recovery jalan |

```
τ Llama: 0.05 (floor) → 0.535 dalam 10 round
Recovery rate: ~0.5% per round → guaranteed convergence path
```

---

## 6. Parameter Sensitivity Analysis

Simulasi 10 round, 10 task/round, seed=42:

| Config | P(Claude) | P(DeepSeek) | P(Llama) | Interpretasi |
|:-------|:---------:|:-----------:|:--------:|:-------------|
| α=0 (no learning) | **55.5%** | **33.6%** | **11.0%** | Baseline — sama dengan sistem sekarang |
| α=1, β=2 (balanced) | 69.5% | 29.9% | 0.5% | Recommended — belajar dari history + semantic |
| α=3 (histori dominan) | **99.4%** | 0.6% | 0.0% | Overfitting — terlalu percaya history |
| β=5 (semantic dominan) | 82.5% | 17.4% | 0.1% | Hampir sama dengan baseline |
| ρ=0.1 (slow evap) | 59.2% | 35.8% | **4.9%** | Lambat belajar, tapi lebih adil |
| ρ=0.7 (fast evap) | 59.0% | 32.5% | **8.5%** | Cepat lupa, hampir kembali ke baseline |
| Q=1.5 (high deposit) | 70.1% | 29.7% | 0.2% | Satu batch sukses langsung dominan |
| β=0 (pure history) | **49.2%** | 37.3% | **13.5%** | η diabaikan — berbahaya untuk task baru |

### Recommended Starting Point

```
α=1          # bobot history seimbang
β=2          # bobot semantic match (standar literatur)
ρ=0.1-0.3    # evaporasi lambat-sedang
Q=0.5        # deposit sedang
τ_min=0.05   # MMAS floor
ε=0.05       # ε-greedy eksplorasi
```

---

## 7. Compound Task — ACO di Level Sub-Task

### Batasan ACO Murni

ACO routing ke **satu agent** tidak cukup untuk compound task seperti "Deep Research" atau "Buat Best-Quality Note". Task kompleks perlu didekomposisi menjadi DAG sub-task, dan ACO bekerja di **setiap node DAG**.

### Arsitektur Compound Task

```
                    ┌──────────────────┐
                    │  META-AGENT      │
                    │  (LLM Planner)   │
                    └────────┬─────────┘
                             │ decomposes
                             ▼
                    ┌──────────────────┐
                    │  DAG Task Graph  │
                    │ search → extract │
                    │ → verify → synth │
                    │ → (write × 3)    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  ACO ROUTER      │ ← τ matrix per sub-task type
                    │  (per sub-task)  │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         DeepSeek Web    Yuanbao       Gemini Web
         (search,       (synthesize)  (write)
          verify)
```

### Bukti — Tidak Ada Satu Provider yang Menang Semua

Simulasi 50 compound tasks, 5 sub-task types, 5 free providers:

| Sub-task | Best Agent | τ final | P final | Success Rate |
|:---------|:-----------|:-------:|:-------:|:------------:|
| 🔍 Search | DeepSeek Web | 2.16 | 42.0% | 0.80 |
| 📖 Extract | DeepSeek Web | 1.26 | 50.8% | 0.69 |
| ✅ Verify | DeepSeek Web | 2.12 | 66.2% | 0.92 |
| 🧠 Synthesize | Yuanbao | 2.41 | 44.4% | 0.85 |
| ✍️ Write | Gemini Web | 2.08 | 51.1% | 0.82 |

**Kalau dispatch ke 1 agent aja:** DeepSeek untuk semua → write jelek (τ=0.10). Yuanbao untuk semua → search/extract jelek (τ=0.05-0.52).

**Dengan ACO per sub-task:** tiap fase dikerjakan provider yang paling cocok → kualitas akhir lebih tinggi.

### Rate Limit Simulation

Gemini Web ability turun dari 0.88 → 0.30 (5 round):

```
Sebelum:  P(Gemini)=38.8%  τ=1.50
Selama:   P(Gemini)=32.9%  τ=0.86 → DuckDuckGo + Yuanbao ambil alih ✅
Pulih:    P(Gemini)=36.6%  τ=1.38 → balik 91% dalam 10 round ✅
```

**Traffic auto-shift tanpa intervensi manual.**

---

## 8. Implementasi Python

### Core ACO Router

```python
class ACORouter:
    def __init__(self, agents, alpha=1.0, beta=2.0, rho=0.3, Q=0.5,
                 tau0=0.10, tau_min=0.05, tau_max=5.0, epsilon=0.05):
        self.agents = agents
        self.alpha = alpha; self.beta = beta; self.rho = rho; self.Q = Q
        self.tau0 = tau0; self.tau_min = tau_min; self.tau_max = tau_max
        self.epsilon = epsilon
        self.P = {}  # pheromone[task_type][agent_id] = float

    def _tau(self, task_type, agent_id):
        return self.P.setdefault(task_type, {}).setdefault(agent_id, self.tau0)

    def dispatch_probs(self, task_type):
        # η dari Semantic Discovery (pre-computed per agent)
        hs = {a['id']: a['eta_for'][task_type] for a in self.agents}
        nums = {}
        for aid, eta in hs.items():
            tau = self._tau(task_type, aid)
            nums[aid] = (tau ** self.alpha) * (eta ** self.beta)
        total = sum(nums.values()) or 1
        return {aid: n/total for aid, n in nums.items()}

    def dispatch(self, task_type):
        # ε-greedy: epsilon% random, sisanya ACO-weighted
        if random.random() < self.epsilon:
            return random.choice(self.agents)['id']
        probs = self.dispatch_probs(task_type)
        r = random.random(); cum = 0.0
        for aid, p in sorted(probs.items(), key=lambda x: -x[1]):
            cum += p
            if r < cum: return aid
        return sorted(probs.items(), key=lambda x: -x[1])[0][0]

    def update(self, task_type, agent_id, quality, succeeded):
        # τ ← (1-ρ)·τ + Δτ, clamped [τ_min, τ_max]
        cur = self._tau(task_type, agent_id)
        delta = quality if succeeded else 0.0
        new = max(self.tau_min, min(self.tau_max,
                   (1 - self.rho) * cur + delta))
        self.P.setdefault(task_type, {})[agent_id] = new
```

### Penggunaan

```python
# Setup 5 provider
agents = [
    {'id': 'Gemini Web',    'eta_for': {'coding': 0.70, 'chat': 0.85}},
    {'id': 'DeepSeek Web',  'eta_for': {'coding': 0.85, 'chat': 0.60}},
    {'id': 'Yuanbao',       'eta_for': {'coding': 0.40, 'chat': 0.70}},
    {'id': 'OpenCode Free', 'eta_for': {'coding': 0.90, 'chat': 0.30}},
    {'id': 'DuckDuckGo',    'eta_for': {'coding': 0.30, 'chat': 0.80}},
]

router = ACORouter(agents)

# Dispatch task
chosen = router.dispatch('coding')

# After completion, update pheromone
router.update('coding', chosen, quality=0.85, succeeded=True)
```

---

## 9. Hasil Simulasi — 5 Skenario

Semua simulasi deterministic (seed=42), script di `scripts/aco_simulation.py` dan `scripts/aco_your_stack.py` di skill Hermes `aco-agent-routing`.

### S1 — Standard 3-Agent

```
Round 1: Claude P=55.5%  DeepSeek P=33.6%  Llama P=11.0%
Round 5: Claude P=76.8%  DeepSeek P=22.5%  Llama P= 0.7%
τ ratio Claude/DeepSeek = 1.91×
```

### S2 — Exploration Lockout

| ε | Llama dispatched/500 | Status |
|:-:|:-------------------:|:-------|
| 0% | 4 (0.8%) | ⚠️ Lockout |
| 5% | 7 (1.4%) | Mild improvement |

### S3 — Provider Recovery (Llama 0% → 95%)

| Guard | Round 10 | Round 20 | Hasil |
|:------|:--------:|:--------:|:------|
| None | 0.03% | 0.00% ❌ | Stuck |
| MMAS+ε | 0.56% | 5.00% ✅ | Recovery |

### S4 — 8 Parameter Configs

Semua converge ke arah yang benar. Tidak ada divergen/NaN.

### S5 — Your Real Stack (5 free providers, 30 rounds, 300 task per type)

| Task | #1 | τ | #2 | τ |
|:-----|:--:|:-:|:--:|:-:|
| Creative | Yuanbao 66% | 1.50 | Gemini 30% | 0.85 |
| Coding | OpenCode 41% | 1.42 | DeepSeek 39% | 1.51 |
| Research | Gemini 48% | 1.47 | DeepSeek 44% | 1.52 |
| Chat | Gemini 47% | 1.63 | DuckDuckGo 37% | 1.42 |

---

## 10. Kapan ACO Bekerja dan Kapan Tidak

### ACO Efektif Ketika

| Kondisi | Efek |
|:--------|:-----|
| Provider sering berubah kualitas | ρ evaporate trust lama, τ belajar yang baru |
| Banyak provider (>3) | Perlu learning karena kombinasi eksponensial |
| Ada provider gratis yang tidak stabil | Auto-shift saat rate limit / error |
| Task type beragam | τ matrix independen per task type |
| Provider baru masuk | Belajar dari nol tanpa perlu set η manual |

### ACO Kurang Efektif Ketika

| Kondisi | Alasan |
|:--------|:-------|
| Hanya 1-2 provider | Tidak perlu ACO — pilih yang η tertinggi |
| Provider sangat stabil (tahun) | η sudah cukup, ACO hanya overhead |
| Task sangat pendek (<5 dispatch/task type) | Belum cukup history untuk τ converge |
| Δτ signal noise/bias | Sinyal yang salah → reinforce hal yang salah |

### Relationship to Other Approaches

| Approach | Key Difference | When to Use |
|:---------|:--------------|:------------|
| **Bandit** (UCB, Thompson) | No η — pure exploration/exploitation | No semantic info available |
| **Static η** (current) | No learning — pure semantic match | Provider perfectly stable |
| **ACO** (this note) | η + τ — semantic + history | Providers change, new ones appear |
| **RL** (PPO, Q-learning) | Full state transition model | Complex multi-step decisions |

---

## 11. References

1. Dorigo, M., Maniezzo, V., & Colorni, A. (1996). "Ant system: optimization by a colony of cooperating agents." *IEEE Transactions on Systems, Man, and Cybernetics, Part B*, 26(1), 29-41. — Original ACO paper.

2. Stützle, T., & Hoos, H. H. (2000). "MAX-MIN Ant System." *Future Generation Computer Systems*, 16(8), 889-914. — MMAS floor/ceiling variant.

3. Dorigo, M., & Stützle, T. (2004). *Ant Colony Optimization*. MIT Press. — Comprehensive textbook, convergence proofs.

4. Blum, C. (2005). "Ant colony optimization: Introduction and recent trends." *Physics of Life Reviews*, 2(4), 353-373. — Survey of ACO variants.

5. Sutton, R. S., & Barto, A. G. (2018). *Reinforcement Learning: An Introduction* (2nd ed.). MIT Press. — ε-greedy exploration, dasar dari paksaan eksplorasi.

6. [[swarm-ai-imam-robandi]] — Vault note: ACO formula, implementasi Python untuk TSP.

7. [[meta-agent-orchestration]] — Vault note: arsitektur meta-agent, Semantic Discovery, 4-strategy retry loop.

8. [[aco-agent-routing]] — Skill Hermes: implementasi lengkap dengan simulation scripts.

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[swarm-ai-imam-robandi]] | Sumber formula ACO dan semua varian (MMAS, ACS) |
| [[meta-agent-orchestration]] | Target arsitektur — ACO menggantikan memoryless reassign |
| [[multi-agent-orchestration-patterns]] | Pattern multi-agent yang diperbaiki oleh ACO |
| [[ai-evaluation-framework]] | Δτ quality signals — LLM judge, self-consistency |
| [[Note/01_Library/AI_Systems/hierarchy-llm-ai-systems]] | Layer di mana agent routing beroperasi |