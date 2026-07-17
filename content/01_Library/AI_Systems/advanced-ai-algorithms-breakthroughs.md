---
title: "Advanced AI Algorithms & Breakthroughs"
tags:
  - ai
  - deep-learning
  - attention
  - diffusion
  - rlhf
  - world-model
  - optimal-transport
aliases:
  - "advanced-ai-algorithms-breakthroughs"
created: "2026-07-16"
updated: "2026-07-16"
status: growing
---

## Daftar Isi

1. [Fused Attention Kernel / Flash Attention](#1-fused-attention-kernel--flash-attention)
2. [Multi-Head Latent Attention (MLA) — DeepSeek-V2](#2-multi-head-latent-attention-mla--deepseek-v2)
3. [Latent Diffusion — Stable Diffusion](#3-latent-diffusion--stable-diffusion)
4. [Flow Matching / Rectified Flow](#4-flow-matching--rectified-flow)
5. [Vision Language Action (VLA)](#5-vision-language-action-vla)
6. [RLHF + PPO (Proximal Policy Optimization)](#6-rlhf--ppo-proximal-policy-optimization)
7. [World Model](#7-world-model)
8. [Schrödinger Bridges](#8-schrödinger-bridges)

---

## 1. Fused Attention Kernel / Flash Attention

**Kelebihan:** IO-aware attention — ngurangi memory reads/writes antara HBM dan SRAM. Bikin training jadi **2-4× lebih cepat** tanpa loss akurasi, enable long-context sampai 128K+ tokens.

### Inti Problem

Standard attention (`softmax(QK^T)V`) punya _quadratic complexity_ O(N²) — tapi masalah yang lebih gede bukan compute-nya, **memory bandwidth bottleneck**. Setiap langkah attention baca-tulis attention matrix ukuran N×N dari HBM (High Bandwidth Memory) ke SRAM (on-chip cache) bolak-balik. GPU spend more time moving data than computing.

### Core Insight — Tiling + Recomputation

Flash Attention ([Dao et al., 2022](https://arxiv.org/abs/2205.14135)) gak ngubah formula attention, tapi ngubah **order of operations**:

1. **Tiling:** Q, K, V di-split jadi blocks kecil yang muat di SRAM (19MB di A100 vs 40-80GB HBM)
2. **Online softmax:** Compute softmax secara incremental per block — gak perlu nunggu full attention matrix selesai
3. **Backward pass recompute:** Gak store attention matrix waktu forward → recompute ulang di backward. I/O saving lebih gede dari extra compute

```python
# Pseudocode: Flash Attention forward pass
for Q_block in Q_blocks:
    for K_block, V_block in KV_blocks:  # KV loaded from HBM once
        # Compute partial S = Q_block @ K_block^T in SRAM
        S = Q_block @ K_block.T  # (B_r x d) @ (d x B_c)

        # Online softmax — track running max & exp sum
        m_new = max(m, rowmax(S))
        diag = exp(S - m_new)
        P = diag / (exp(m - m_new) * l_seg + rowsum(diag))

        # Accumulate output incrementally
        O_block = diag @ V_block + exp(m - m_new) * O_block  # rescale
```

### Varian & Evolusi

| Version                   | Key Improvement                         | Tahun |
| ------------------------- | --------------------------------------- | ----- |
| FlashAttention            | Basic tiling + online softmax           | 2022  |
| FlashAttention-2          | Better parallelism, less non-matmul ops | 2023  |
| FlashAttention-3 (Hopper) | Async WGMMA, FP8 support                | 2024  |
| FlashAttention-BERT       | Optimized for BERT-length sequences     | 2024  |

### Kelebihan Konkret

- ✅ **Memory dari O(N²) → O(N)** — gak perlu simpan matriks attention N×N
- ✅ **Speedup 2-4×** vs standard PyTorch/TensorFlow implementation
- ✅ **Precision same** — bitwise identical output (floating point error negligible)
- ✅ **Enable long context** — 128K, 1M tokens jadi feasible
- ✅ **Backbone semua model modern**: LLaMA, Mistral, GPT-4, Gemini

### Tradeoff

- ⚠️ Implementasi pake CUDA kernel handwritten — not a simple `torch.nn.Module` drop-in (tapi udah di-wrapped di `flash-attn` package)
- ⚠️ Optimalisasi dependent pada GPU architecture (Ampere, Hopper, Blackwell punya tuning beda)

> **ponytail:** Kalau make HuggingFace Transformers ≥4.35, Flash Attention udah built-in lewat `attn_implementation="flash_attention_2"`. Gak perlu manual.

---

## 2. Multi-Head Latent Attention (MLA) — DeepSeek-V2

**Kelebihan:** Low-rank compressed KV cache — **ngurangin memory KV cache sampai 75-90%** tanpa degrade quality. Ini yang bikin DeepSeek-V2 cost-efficient banget (diklaim 42.5% cheaper than GPT-4).

### Problem: KV Cache Banjir

Di inference autoregressive, kita cache semua K dan V dari semua tokens sebelumnya. Dengan batch size besar + long context, **KV cache jadi memory bottleneck nomor 1**:

- LLaMA-2 70B: ~400GB KV cache at 32K context
- DeepSeek-V2: target 128K context → KV cache size gila-gilaan kalau standar MHA

### Core Idea: Latent Compression

MLA ([DeepSeek-AI, 2024](https://arxiv.org/abs/2405.04434)) adalah **Multi-Head Attention dengan compressed latent representation** untuk KV cache:

1. **Down-projection:** Setiap K dan V di-proyeksi ke dimensi rendah (latent space) via matrix down-projection
2. **Cache latent (bukan raw K/V):** Yang di-cache adalah compressed latent vector — jauh lebih kecil
3. **Up-projection saat compute:** Waktu attention, latent di-decode balik ke K dan V via up-projection

```
Standard MHA:
  K, V per head: [n_heads × d_head] → disimpan semua
  Cache size per token: O(n_heads × d_head)

MLA:
  k_latent = DownProject(K)   # [d_compressed] — 1/4 sampai 1/8 dari original
  Simpan: k_latent             # jauh lebih kecil
  K_restored = UpProject(k_latent)  # di-decode pas attention compute
  Cache size per token: O(d_compressed) — independent of n_heads
```

### Kenapa Ini Penting

| Aspek              | Standard MHA           | MLA                                  |
| ------------------ | ---------------------- | ------------------------------------ |
| KV cache per token | `2 × n_heads × d_head` | `~2 × d_compressed`                  |
| Ratio (typical)    | 1×                     | **0.125× - 0.25×**                   |
| Context window     | limited by memory      | **128K+ jadi feasible**              |
| Throughput         | baseline               | **~2× lebih tinggi** di long context |

### Decoupled RoPE

MLA juga punya trik unik buat **decoupled rotary position encoding** — RoPE di-aplikasikan pada auxiliary query/key yang kecil, bukan pada main compressed latent. Kenapa? Karena RoPE gak linear-compatible dengan compression. Solusi: RoPE cuma di auxiliary path yang dimension-nya kecil.

### Kelebihan Konkret

- ✅ **KV cache 75-90% lebih kecil** → batch size lebih besar, throughput naik
- ✅ **Attention quality setara MHA** — compression loss bisa di-training out
- ✅ **Decoupled RoPE** — kompatibel dengan position encoding modern
- ✅ **Key enabler DeepSeek-V2/V3** arsitektur ekonomis
- ✅ **Open source** — DeepSeek rinci arsitektur dan weight-nya

### Tradeoff

- ⚠️ Extra parameters: down-projection & up-projection matrices
- ⚠️ Extra compute: butuh 2 linear layers tambahan per attention (tapi ini di-offset sama saving di memory bandwidth)
- ⠀⚠️ Belum mainstream adoption di luar DeepSeek — butuh implementasi CUDA khusus biar optimal

---

## 3. Latent Diffusion — Stable Diffusion

**Kelebihan:** Diffusion di latent space (bukan pixel space) — **komputasi jauh lebih ringan, kualitas tetap high-fidelity**. Ini fondasi Stable Diffusion series.

### Problem: Pixel Space Diffusion Gak Efisien

Diffusion model pertama (DDPM, 2020) langsung generate pixel 256×256×3. Masalah:

- Dimensi terlalu gede → compute mahal
- Perceptual details (tekstur, bayangan) dan semantic content learning-nya campur aduk susah
- Sampling lambat

### Core Idea: Diffuse di Latent, Decode ke Pixel

Latent Diffusion ([Rombach et al., 2022](https://arxiv.org/abs/2112.10752)) — yang jadi backbone Stable Diffusion — split proses jadi 2 stage:

**Stage 1: VAE (Variational Autoencoder)**

- Encoder: kompres gambar 512×512×3 → latent 64×64×4 (≈48× compression!)
- Decoder: reconstruct latent balik ke pixel
- VAE di-pretrain terpisah dengan perceptual loss + adversarial loss → hasil rekonstruksi bagus
- **Kenapa ini works:** VAE ngurus _perceptual compression_ — detail visual (tekstur, warna). Diffusion cuma urus _semantic compression_ — apa yang ada di gambar.

**Stage 2: Diffusion di Latent Space**

- UNet (atau DiT — Diffusion Transformer di SD3/Sora) belajar denoise latent 64×64×4
- 48× lebih kecil dari pixel 512×512×3 → jauh lebih cepat
- Conditioning: text embedding dari CLIP/T5 di-cross-attention ke UNet

```
Pixel space:   512 × 512 × 3  = 786,432 dimensi
Latent space:   64 ×  64 × 4  =  16,384 dimensi  (≈48× lebih kecil!)
```

### Cross-Attention Conditioning

Bedanya latent diffusion sama diffusion biasa: **cross-attention** sebagai mekanisme conditioning.

```
text → Text Encoder (CLIP/T5) → text_embedding
                                   ↓
noisy_latent → UNet [self-attn ∘ cross-attn(text_embedding)] → predicted noise
```

Ini yang bikin Stable Diffusion bisa text-to-image, image-to-image, inpainting, dll — tinggal ganti conditioning modality.

### Kelebihan Konkret

- ✅ **Compute efficient** — 48× lebih kecil dari pixel diffusion
- ✅ **Decoupled compression & generation** — VAE bisa di-upgrade sendiri tanpa retrain diffusion
- ✅ **Flexible conditioning** — text, image, depth map, pose, semua masuk lewat cross-attention
- ✅ **Multi-resolution support** — latent space fixed size, gampang di-rescale
- ✅ **Base of entire SD ecosystem** — SD1.5, SDXL, SD3, SD3.5, Flux, semuanya di atas latent diffusion

### Perkembangan: SD3 → Flux → DiT

| Model  | Denoiser             | Tahun | Highlight                             |
| ------ | -------------------- | ----- | ------------------------------------- |
| SD1.5  | UNet + CLIP          | 2022  | Latent diffusion > breakthrough       |
| SDXL   | UNet + CLIP + T5     | 2023  | Dual text encoder, bigger UNet        |
| SD3    | DiT (MMDiT)          | 2024  | Rectified Flow, Diffusion Transformer |
| Flux.1 | DiT + double CLIP+T5 | 2024  | 12B params, SOTA quality              |

> Latent Diffusion mengubah ekonomi generasi gambar. Dengan cost minimum $600K training SD1.5 (vs jutaan $ buat DALL-E 2), open source bisa compete.

---

## 4. Flow Matching / Rectified Flow

**Kelebihan:** Generate data dengan **straight-line trajectory** — lebih cepat sampling (1-10 steps, bukan 50-1000). Teori lebih clean dari diffusion, training lebih stabil. Backbone Stable Diffusion 3 & Flux.

### Problem: Diffusion Sampling Lambat

Diffusion model butuh banyak steps (50-1000) karena trajectory-nya acak — random walk dari pure noise ke data. Langevin dynamics is inherently inefficient.

### Core Idea: Optimal Transport Path

Flow Matching ([Lipman et al., 2023](https://arxiv.org/abs/2210.02747)) / Rectified Flow ([Liu et al., 2023](https://arxiv.org/abs/2209.03077)) punya pendekatan beda:

**Bukan belajar score function (∇log p), tapi belajar _vector field_ yang straight-line dari noise ke data:**

$$
\text{Standard Diffusion: } dx_t = f(t)x_t dt + g(t)dw_t \quad \text{(random walk)}
$$

$$
\text{Rectified Flow: } dx_t = v_\theta(x_t, t) dt \quad \text{(deterministic transport)}
$$

Kuncinya: **rectification** — proses lurusin trajectory.

1. Train model buat predict arah dari noise → data (straight line)
2. Sampling pake model → dapet trajectory agak melengkung
3. **Rectify:** pasang trajectory hasil sampling sebagai training data baru
4. Model belajar jalur yang lebih lurus
5. Repeat sampai trajectory jadi essentially straight

```
Step 0: Noise ──╱╲──╱╲──╱╲── Data   (random trial)
Step 1: Noise ───╱╲──╱╲─── Data     (1× rectified)
Step 2: Noise ─────╱╲───── Data     (2× rectified)
Step N: Noise ──────────── Data     (almost straight → 1-step sampling!)
```

### Conditional Flow Matching (CFM)

Dalam prakteknya kita gak bisa langsung predict vector field dari distribusi marginal. Trick: **Conditional Flow Matching** — define path per-sample:

$$
p_t(x|x_1) = \mathcal{N}(x | tx_1, (1-t)^2 I)
$$

- t=0: pure noise
- t=1: data sample x₁
- Vector field: $u_t(x|x_1) = \frac{x_1 - x}{1 - t}$ — arah straight ke data

Model belajar: $v_\theta(x_t, t) \approx u_t$ — dan **conditional objective ini equivalent dengan unconditional** (benar secara matematis).

### Kelebihan Konkret

- ✅ **Very few sampling steps** — 1-10 steps vs 50-1000 diffusion
- ✅ **Straight trajectory** → bisa pake ODE solver sederhana (Euler)
- ✅ **Training lebih stabil** — gak ada stochastic differential equation, langsung regression
- ✅ **Consistency** — mapping noise→data deterministic (gak ada randomness per-step)
- ✅ **Interpolation** — straight line berarti latent space interpolation jadi linear → meaningful
- ✅ **Powering SD3, Flux, Sora** — model generasi terbaik 2024-2025 pake ini
- ✅ **Distillation gampang** — karena trajectorynya straight, bisa 1-step (progressive distillation)

### Perbandingan: Diffusion vs Flow Matching

| Aspek              | Diffusion (DDPM/DDIM)   | Flow Matching              |
| ------------------ | ----------------------- | -------------------------- |
| Training objective | Score matching (∇log p) | Vector field regression    |
| Sampling steps     | 50-1000                 | 1-50 (≥ 50 setara quality) |
| Trajectory         | Curved, stochastic      | Straight, deterministic    |
| Teori              | SDE-based               | ODE-based (simpler)        |
| Kecepatan sampling | Slow                    | Fast (10-50×)              |
| Model examples     | SD1.5, DALL-E 3         | SD3, Flux, Sora            |

### Matriks Transport dan Optimal Transport (OT)

Flow matching terkait erat dengan **Optimal Transport** — mencari _cost-minimizing path_ antara distribusi. OT memberikan:

- **Non-crossing trajectories** — sample paths gak saling tabrak
- **Efficiency** — shortest path in Wasserstein space
- **Coupling** — natural pairing of noise and data

> **ponytail:** Rectified Flow bisa dilihat sebagai _learned OT_ — model belajar sendiri jalur optimal tanpa perlu compute OT cost explicitly.

---

## 5. Vision Language Action (VLA)

**Kelebihan:** Menyatukan vision, language, dan robot control dalam satu model. **Foundation model untuk robotics** — robot bisa ngerti instruksi bahasa dan execute actions tanpa fine-tuning tugas-spesifik.

### Problem: Robot Model Selama Ini Task-Specific

Sebelum VLA, robot policy biasanya:

- Trained per-task (grasping → one model, pushing → another)
- Gak bisa generalisasi ke objek/scenario baru
- Butuh ribuan demo per task
- Natural language zero — pake one-hot task ID

### Core Idea: Pretrain Multimodal, Finetune ke Action

VLA ([Brohan et al., 2023 — RT-2](https://deepmind.google/discover/blog/rt-2-new-model-translates-voice-and-vision-into-robot-action/); [RT-2, 2023](https://robotics-transformer2.github.io/); [π₀ (pi-zero), 2024](https://www.physicalintelligence.company/blog/pi0)) adalah pendekatan:

1. **Ambil pretrained VLM (Vision Language Model)** yang udah tau banyak tentang visual concepts & language semantics (dari internet-scale data)
2. **Tambahkan action head** — output bukan cuma teks, tapi juga robot actions (joint angles, end-effector pose, dll)
3. **Finetune dengan robot demonstration data** — model belajar mapping dari visual + language → action

```
Input: [Image] + "Ambil cangkir merah di meja"
  ↓
VLM Backbone (frozen/finetuned) → visual & text features
  ↓
Action Head (trained from scratch) → joint_positions, gripper_state
```

**Key insight:** VLM udah ngerti objek, relasi spasial, instruksi bahasa. Yang ditambah cuma _how to act_.

### Arsitektur VLA

#### RT-2 (Robotic Transformer 2) — Google DeepMind

- **Backbone:** PaLI-X (VLM 55B) / PaLM-E
- **Action representation:** discretized — action space di-tokenize jadi 256 bins per dimension
- **Training:** Web-scale VLM pretrain → robot demonstration finetune (co-finetuning)
- **Emergent skill:** bisa generalize ke objek yang gak ada di demo training

```
["robot", "pick", "red", "apple", "arm", "0.42", "0.15", "0.88", "gripper", "0.0"]
 ↑ VLM text tokens ↑       ↑ action tokens (discretized) ↑
```

Semua jadi satu sequence — action token special gak beda dari text token. **Unified sequence modeling.**

#### π₀ (Pi-Zero) — Physical Intelligence

- **Backbone:** VLM pretrained (smaller, lebih efisien)
- **Action:** Continuous action + flow matching policy head
- **Flow matching for action:** Generate action trajectory dengan few steps (2-4 steps), bukan autoregressive
- **Novel:** Combine flow matching di action space dengan VLM
- **Multi-task:** Diklaim 10-20 tasks overlap training

### Kelebihan Konkret

- ✅ **Generalization** — bisa handle objek/scenario unseen (transfer dari VLM knowledge)
- ✅ **Natural language interface** — tinggal bilang "ambil yang biru" bukan koding
- ✅ **Semantic understanding** — "the apple to the left of the cup" jadi action beneran
- ✅ **Multi-task** — satu model buat banyak task
- ✅ **Rapid adaptation** — few-shot dengan some demos
- ✅ **Scalable** — makin besar VLM backbone, makin bagus robotics performance

### Open Problems

- ⚠️ **High compute** — inference VLM 55B + action head di robot realtime susah (RT-2 pake TPU di cloud + latensi tinggi)
- ⚠️ **Safety & alignment** — action gak boleh hallucinate, beda dengan text generation
- ⚠️ **Latency** — butuh on-device inference (Jetson/Orin) — π₀ lebih practical karena model lebih kecil
- ⚠️ **Data bottleneck** — robot demonstration masih mahal dan susah dikumpulin (vs text/images)
- ⚠️ **Embodiment gap** — sim-to-real transfer masih challenge

### VLA Models Timeline

| Model    | Tahun | Backbone    | Action Space             | Highlight                        |
| -------- | ----- | ----------- | ------------------------ | -------------------------------- |
| RT-1     | 2023  | Transformer | Discretized 256 bins     | Multi-task robotics transformer  |
| RT-2     | 2023  | PaLI-X 55B  | Discretized + text       | Web-scale VLM → robot policy     |
| Octo     | 2024  | Transformer | Diffusion head           | Open-source, multi-embodiment    |
| π₀       | 2024  | VLM + Flow  | Continuous flow matching | Flow action, efficient inference |
| RoboCasa | 2024  | Diffusion   | Simulated                | Large-scale simulation data      |

> **ponytail:** VLA trend mengarah ke _action token sebagai first-class citizen_ di arsitektur transformer — gak perlu nambahin modality-specific decoder.

---

## 6. RLHF + PPO (Proximal Policy Optimization)

**Kelebihan:** Menyesuaikan LLM dengan preferensi manusia — bikin output lebih helpful, harmless, honest. **PPO stabil & sample-efficient** buat policy optimization di large language models.

### Problem: Language Model Gak Tahu Mana yang "Baik"

LLM pretrained cuma belajar _next token prediction_ dari internet — ngerti grammar, fakta, korelasi statistik. Tapi gak ngerti:

- Mana jawaban yang helpful vs unhelpful
- Mana yang harmless vs toxic
- Mana yang honest vs hallucinated

**Supervised fine-tuning (SFT)** gak cukup — SFT cuma clone style dari human demo, gak bisa belajar preferensi negatif.

### RLHF Pipeline

RLHF ([Ouyang et al., 2022 — InstructGPT](https://arxiv.org/abs/2203.02155)) adalah 3-stage pipeline:

#### Stage 1: SFT (Supervised Fine-Tuning)

- Human demos: prompt + ideal response
- Standard cross-entropy loss
- Dapet model awal yang relatively helpful
- **Tanpa SFT, RL langsung dari pretrained = model generate gibberish** (action space terlalu gede)

#### Stage 2: Reward Modeling

- Human rank beberapa responses dari prompt yang sama
- **Reward model:** classifier yang predict "which response is better"
- Train: pairwise ranking loss (Bradley-Terry model)

$$ \mathcal{L}_{RM} = -\mathbb{E}_{(x, y_w, y_l)} [\log \sigma(r_\theta(x, y_w) - r_\theta(x, y_l))] $$

- $y_w$ = winning response (preferred by human)
- $y_l$ = losing response
- $\sigma$ = sigmoid
- Reward model output: scalar → how good is this response

**Kenapa reward model, bukan langsung human feedback?**

- Human feedback expensive & slow
- Reward model bisa di-deploy buat label otomatis
- Jadi _dense reward_ — tiap token ada signal-nya

#### Stage 3: PPO Optimization

PPO ([Schulman et al., 2017](https://arxiv.org/abs/1707.06347)) optimize model (policy) pake reward dari reward model.

### PPO in Detail

PPO adalah RL algorithm dengan **clipped surrogate objective** — mencegah policy update terlalu besar yang bisa collapse performance.

#### Intuisi

RL untuk LLM itu unik: action space = vocabulary (~32K-128K tokens), state space = past tokens. Policy = LLM itu sendiri.

PPO buat LLM punya 4 components yang jalan bareng:

**1. Policy (Actor) — LLM kita**:

- Generate response given prompt
- Loss: maximize expected reward MINUS KL penalty

**2. Value function (Critic)**:

- Predict expected future reward dari state sekarang
- Trained dengan MSE terhadap actual return
- Bantu ngurangin variance di gradient estimation

**3. Reward signal**:

- Dari reward model: $R(x, y)$
- Ditambah **KL penalty**: $-\beta \cdot D_{KL}(\pi_{\text{new}} || \pi_{\text{ref}})$
- KL penalty prevents model dari "reward hacking" — generate output yang dapet reward tinggi tapi gak meaningfully aligned (mis: nulis panjang banget)

**4. Generalized Advantage Estimation (GAE)**:

- Balances bias-variance tradeoff
- $A_t = \sum_{l=0}^{\infty} (\gamma\lambda)^l \delta_{t+l}$ dimana $\delta_t = R_t + \gamma V(s_{t+1}) - V(s_t)$

#### Clipped Objective

$$ L^{CLIP}(\theta) = \mathbb{E}_t[\min(r_t(\theta)\hat{A}_t, \text{clip}(r_t(\theta), 1-\epsilon, 1+\epsilon)\hat{A}_t)] $$

dimana:

- $r_t(\theta) = \frac{\pi_\theta(a_t|s_t)}{\pi_{\theta_{old}}(a_t|s_t)}$ — probability ratio
- clip($r_t, 1-\epsilon, 1+\epsilon$) — mencegah update terlalu agresif
- $\hat{A}_t$ — estimated advantage

**Kenapa clipping penting:**

- Kalau policy tiba-tiba ngeboost probability token tertentu (karena dapet reward tinggi dari reward model yang noise), bisa collapse model
- Clip memastikan update per step ≤ $\epsilon$ (biasanya 0.2)

### PPO vs Other RL Algorithms for LLM

| Aspect              | PPO                                         | REINFORCE               | DPO                         |
| ------------------- | ------------------------------------------- | ----------------------- | --------------------------- |
| Sample efficiency   | ✅ Tinggi (on-policy + importance sampling) | ❌ Rendah (Monte Carlo) | ✅ Tinggi (offline)         |
| Stability           | ✅ Clipping prevents collapse               | ❌ High variance        | ✅ Implicit                 |
| Reward model needed | ✅ Yes                                      | ✅ Yes                  | ❌ No (preference langsung) |
| Complexity          | Tinggi (actor + critic + RM)                | Medium                  | Rendah (1 stage)            |
| Prevalence          | ✅ Standard RLHF                            | Rare                    | ✅ Popular alternative      |

### RLHF + PPO: Total Loss

$$ \mathcal{L}_{RLHF} = -\mathbb{E}_{x \sim \mathcal{D}, y \sim \pi_\theta} [R(x, y)] + \beta \cdot D_{KL}(\pi_\theta || \pi_{SFT}) $$

Atau dengan implementasi penuh:

$$ \mathcal{L} = \mathcal{L}_{PPO}^{clip} + c_1\mathcal{L}_{VF} - c_2\mathcal{L}_{entropy} $$

- $\mathcal{L}_{PPO}^{clip}$: clipped policy gradient
- $\mathcal{L}_{VF}$: value function MSE loss
- $\mathcal{L}_{entropy}$: entropy bonus (encourage exploration)

### Kelebihan Konkret

- ✅ **Alignment manusia** — output lebih helpful, less toxic
- ✅ **Tradeoff control** — KL penalty tunable: atur seberapa jauh dari base model
- ✅ **Dense reward** — reward model kasih feedback per-step (vs hanya final)
- ✅ **PPO stabil** — clipping prevents catastrophic forgetting
- ✅ **Scalable** — dipake di ChatGPT, Claude, Gemini, LLaMA-2-Chat
- ✅ **Sample efficient** — on-policy + advantage estimation

### Tradeoff

- ⚠️ **Complex pipeline** — butuh 4 model (SFT, RM, Actor, Critic) → memory heavy
- ⚠️ **Reward hacking risk** — kalau RM gak bagus, model exploit loophole
- ⚠️ **KL collapse** — KL terlalu tinggi → model jadi conservative (gak kreatif)
- ⚠️ **PPO hyperparameter sensitive** — learning rate, clip range, KL coefficient perlu tuning
- ⚠️ **Komputasi mahal** — generate response, compute reward, update policy tiap iterasi

### DPO — Alternatif Simplifikasi

**Direct Preference Optimization** ([Rafailov et al., 2023](https://arxiv.org/abs/2305.18290)) ngilangin reward model + PPO:

$$ \mathcal{L}_{DPO} = -\mathbb{E}_{(x, y_w, y_l)} \left[ \log \sigma \left( \beta \log \frac{\pi_\theta(y_w|x)}{\pi_{ref}(y_w|x)} - \beta \log \frac{\pi_\theta(y_l|x)}{\pi_{ref}(y_l|x)} \right) \right] $$

- Langsung optimize dari preference pairs
- Implicit reward = log probability ratio
- **Gak perlu reward model — gak perlu PPO — satu stage**
- Tapi: lebih sensitif ke data quality, offline (gak ada exploration)

> **ponytail:** PPO tetap dapet reward signal yang lebih kaya daripada DPO. Tapi buat most use cases, DPO is "good enough" dan jauh lebih simple. Pilih DPO kalau compute terbatas.

---

## 7. World Model

**Kelebihan:** Model yang belajar **simulasi internal lingkungan** — bisa bayangin konsekuensi action sebelum execute. Enables planning, reasoning, dan sample-efficient learning di RL & robotics.

### Definisi

World model adalah **learned simulator of the environment's dynamics**:

- Input: state $s_t$ + action $a_t$
- Predict: next state $s_{t+1}$, reward $r_{t+1}$, done $d_{t+1}$
- Kadang juga predict: latent representation z_t tanpa perlu reconstruct raw observation

$$
\text{World Model: } (s_t, a_t) \rightarrow \hat{s}_{t+1}, \hat{r}_{t+1}
$$

Bedanya sama model biasa: **bisa di-rollout untuk planning** — model di-"dream" atau bayangin trajectory ke depan tanpa perlu interaksi lingkungan nyata.

### Kenapa World Model Penting

| Problem                                      | Solution dengan World Model                                    |
| -------------------------------------------- | -------------------------------------------------------------- |
| RL butuh banyak trial di environment nyata   | Bisa trial di _dream_ environment — 1000× lebih cepat          |
| Robotics experiments expensive (robot rusak) | Planning di latent space dulu baru execute                     |
| Model-based RL kurang stabil                 | Dreamer family bikin stabil dengan recurrent state space model |
| Planning butuh forward simulation            | World model = cheap forward simulator                          |

### Arsitektur World Model — DreamerV3

DreamerV3 ([Hafner et al., 2023](https://arxiv.org/abs/2301.04104)) adalah arsitektur world model paling mature dan general (works across 200+ tasks tanpa hyperparameter tuning).

**3 komponen utama:**

#### 1. World Model Learning (RSSM — Recurrent State Space Model)

```
    ┌─────────┐      ┌──────────────┐      ┌─────────┐
    │ Encoder │──→   │ Recurrent    │──→   │ Decoder │
    │ (CNN)   │      │ State Model  │      │(pixel)  │
    └─────────┘      └──────────────┘      └─────────┘
         ↑                │    │                 ↓
    observation           │    │          reconstructed
    (image)               │    │            image
                          │    │
                     ┌────┘    └────┐
                     ↓              ↓
               ┌──────────┐  ┌──────────┐
               │ Reward   │  │ Continue │
               │ Predictor│  │ Predictor│
               └──────────┘  └──────────┘
```

RSSM components:

- **Encoder:** $z_t \sim q_\phi(z_t | h_t, x_t)$ — image → latent
- **Recurrent model:** $h_t = f_\phi(h_{t-1}, z_{t-1}, a_{t-1})$ — temporal dynamics
- **Decoder:** $\hat{x}_t \sim p_\phi(x_t | h_t, z_t)$ — latent → reconstructed image
- **Reward predictor:** $\hat{r}_t \sim p_\phi(r_t | h_t, z_t)$
- **Continue predictor:** $\hat{c}_t \sim p_\phi(c_t | h_t, z_t)$ — episode done?

**Loss:** ELBO (Evidence Lower Bound) — reconstruction + KL regularization + reward/continue prediction.

#### 2. Behavior Learning (Actor-Critic dalam Dream)

```
Dalam "dream" — latent rollout tanpa environment:

  h₀, z₀ (dari real experience untuk seed)
     ↓
  a₀ ∼ π(a₀ | h₀, z₀)       ← Actor (policy)
     ↓
  h₁ = f(h₀, z₀, a₀)        ← Recurrent model
  z₁ ∼ prior(z₁ | h₁)        ← learned prior (no encoder)
     ↓
  a₁ ∼ π(a₁ | h₁, z₁)
     ↓
  ... (rollout sampai H=15 steps)
     ↓
  Reward predicted: r̂ₜ ∼ p(r_t | h_t, z_t)
  Value estimated: v̂ₜ = V(h_t, z_t)  ← Critic (value function)
```

**Key insight:** Waktu behavior learning, world model **diam (frozen)** — cuma actor-critic yang diupdate. World model udah belajar dynamics-nya.

Actor-critic loss: **Return** = predicted reward + λ × predicted value (bootstrapped).

#### 3. Planning & Imagination

Setelah world model trained:

- **Imagination rollout:** generate ribuan trajectory di latent space (gak perlu render image — cuma latent)
- **Plan:** cari action sequence dengan highest predicted return
- **Execute:** apply action pertama dari plan, re-plan di step berikutnya (receding horizon / MPC)

### Evolusi World Model

| Model                           | Tahun | Key Innovation                                                                         |
| ------------------------------- | ----- | -------------------------------------------------------------------------------------- |
| World Models (Ha & Schmidhuber) | 2018  | VAE + MDN-RNN + Controller — "dreaming" untuk training                                 |
| PlaNet                          | 2019  | RSSM — deep planning network                                                           |
| DreamerV1                       | 2020  | Actor-critic dalam latent space dream                                                  |
| DreamerV3                       | 2023  | **Mastering diverse domains without tuning** — fixed hyperparameters across 200+ tasks |
| DayDreamer                      | 2023  | DreamerV3 di **real robot** — no simulator needed                                      |
| Genie (DeepMind)                | 2024  | **Foundation world model** — dari internet video tanpa action labels                   |

### Genie — Foundation World Model

Genie ([Bruce et al., 2024](https://arxiv.org/abs/2402.15391)) dari DeepMind:

- **Trained from 200K hours of internet video** — gak perlu action labels
- **3 components:**
  1. Video tokenizer (VQ-VAE-like)
  2. Latent action model — infer action dari frame differences
  3. Dynamics model — predict next frame given current frame + latent action
- **Emergent:** bisa generate interactive game dari prompt gambar/text
- **Gak perlu RL training** — world model + latent action = interactive environment

### Kelebihan Konkret

- ✅ **Sample efficiency** — DreamerV3 sample-efficient 10-50× vs model-free RL
- ✅ **Planning tanpa environment** — coba berbagai skenario di "dream" sebelum execute
- ✅ **Domain agnostic** — works across Atari, DM Control, Minecraft, robotics
- ✅ **DreamerV3 fixed hyperparameters** — gak perlu tuning per task
- ✅ **Latent rollout cepat** — 1000× lebih cepat dari environment real
- ✅ **Foundation models (Genie)** — bisa belajar world model dari video saja

### Tradeoff

- ⚠️ **Model bias** — world model imperfect → planning bisa berdasarkan dynamics yang salah
- ⠀⚠️ **Computational overhead** — maintain & update world model (vs model-free yang cuma policy)
- ⚠️ **Long-horizon difficulty** — world model error accumulate sepanjang rollout → planning horizon terbatas
- ⠀⚠️ **Open-loop vs closed-loop** — rollout di world model gak bisa correct dari real observation
- ⚠️ **Safety concern** — kalau world model jadi policy backbone, distribution shift bisa bahaya

> **ponytail:** World model trending ke _foundation world model_ — pretrained dari internet video → finetune ke task-specific. Genie & GameGen adalah indikator awal.

---

## 8. Schrödinger Bridges

**Kelebihan:** **Optimal path antara noise dan data** — melampaui diffusion model dengan _principled interpolation_ antara arbitrary distributions. Bisa generate, translate, dan _unify_ berbagai generative modeling approaches.

### Problem: Diffusion Path-nya Belum Optimal

Diffusion model:

- Path dari noise → data **fixed by design** (misal: VP-SDE, VE-SDE, sub-VP)
- Gak di-optimize — simple linear schedule dipilih biar analytically tractable
- **Bukan path terpendek atau termurah** — ada jarak yang terbuang

### Core Idea: Optimal Transport via Stochastic Control

Schrödinger Bridge ([Schrödinger, 1932](https://en.wikipedia.org/wiki/Schr%C3%B6dinger%27s_equation); [Léonard, 2014](https://arxiv.org/abs/1309.1815)) adalah **entropic optimal transport problem**:

> **Find the most likely path** between distributions p₀ (noise) and p₁ (data), given that the underlying process is a Brownian motion.

**Intuisi fisik:**

- Bayangin partikel yang bergerak secara random (Brownian motion)
- Kita tahu distribusi partikel di t=0 (noise) dan t=1 (data)
- Schrödinger Bridge: **find the most probable evolution** given these constraints

$$
\min_{p \in \mathcal{P}(p_0, p_1)} D_{KL}(p || q)
$$

dimana:

- $p$: path distribution yang dicari (bridge)
- $q$: reference path distribution (biasanya Brownian motion / diffusion reference)
- $\mathcal{P}(p_0, p_1)$: set semua path yang mematuhi marginal p₀ dan p₁

### Schrödinger Bridge vs Diffusion

| Aspek                 | Diffusion                              | Schrödinger Bridge                                   |
| --------------------- | -------------------------------------- | ---------------------------------------------------- |
| **Path**              | Fixed by design (linear schedule)      | **Optimized** — learn the best path                  |
| **Boundary**          | Noise (fixed Gaussian) → data          | **Arbitrary distributions** — p₀ dan p₁ bisa apa aja |
| **Optimality**        | Sub-optimal                            | **Entropic OT — optimal**                            |
| **Cost**              | Path length fixed                      | **Minimum KL divergence**                            |
| **Speed**             | Butuh banyak steps                     | **Path lebih lurus → fewer steps**                   |
| **Image translation** | Gak bisa langsung (butuh conditioning) | **Langung: gambar↔gambar, domain↔domain**            |

### Matematika: Dari Diffusion ke Schrödinger Bridge

**Diffusion reverse process** (score-based):

$$ dx = [f(x, t) - g(t)^2 \nabla_x \log p_t(x)] dt + g(t) dw $$

Score function $\nabla_x \log p_t(x)$ — ini yang dipelajari model.

**Schrödinger Bridge**:

$$ dx = [f(x, t) + g(t)^2 \nabla_x \log \Psi(x, t)] dt + g(t) dw $$

$$ \nabla_x \log \Psi(x, t) = \nabla_x \log \varphi(x, t) + \nabla_x \log \hat{\varphi}(x, t) $$

dimana $\varphi$ dan $\hat{\varphi}$ adalah solusi dari **coupled PDEs** (HJB + FP):

$$ \frac{\partial \varphi}{\partial t} = -\nabla \varphi^\top f - \frac{1}{2} \text{Tr}(gg^\top \nabla^2 \varphi) $$
$$ \frac{\partial \hat{\varphi}}{\partial t} = -\nabla \cdot (\hat{\varphi} f) + \frac{1}{2} \nabla \cdot (gg^\top \nabla \hat{\varphi}) $$

**Inti:** Schrödinger Bridge belajar _additional drift_ $\nabla_x \log \Psi$ yang mengarahkan path ke distribusi target.

### Iterative Proportional Fitting (IPF) — Algoritma Praktis

Gak perlu solve PDE secara analitis. IPF ([Kullback, 1968](https://en.wikipedia.org/wiki/Iterative_proportional_fitting)) adalah algoritma iterative:

1. **Forward** (t=0 → t=1): Sample dari p₀, run diffusion forward, adjust berdasarkan mismatch di t=1
2. **Backward** (t=1 → t=0): Sample dari p₁, run reverse, adjust berdasarkan mismatch di t=0
3. **Repeat** sampai converged

```
Iterasi 0: Reference path (Brownian motion)
Iterasi 1: Forward adjusted → backward adjusted
Iterasi 2: Forward adjusted lagi → backward adjusted lagi
...
Iterasi N: Converged → Schrödinger Bridge
```

Ini equivalent dengan [Diffusion Schrödinger Bridge](https://arxiv.org/abs/2106.01361) — diffusion model yang di-train dengan IPF.

### Aplikasi Schrödinger Bridge

#### 1. Image Generation (DSB — Diffusion Schrödinger Bridge)

- Trained dari Gaussian → ImageNet distribution
- **Path lebih optimal → sample quality sama dengan lebih sedikit steps**
- Bisa generate dari distribusi non-Gaussian (prior arbitrary)

#### 2. Image-to-Image Translation

- p₀ = distribusi gambar source domain (misal: foto malam)
- p₁ = distribusi gambar target domain (misal: foto siang)
- Schrödinger bridge langsung ngelarin path antara dua distribusi ini
- **Gak perlu conditional model terpisah**

#### 3. Domain Adaptation / Unpaired Translation

- Bedanya sama CycleGAN: Schrödinger Bridge punya **stochastic optimality guarantee**
- Path didefinisikan secara probabilistik — gak deterministic mapping

#### 4. Molecular Conformation Generation

- p₀ = distribusi molekul dalam relaxed state
- p₁ = distribusi dalam active/target state
- Generate transition path yang physically plausible

#### 5. Time Series Imputation

- p₀ = distribusi missing segments (noise)
- p₁ = observed data distribution
- Bridge bisa interpolate missing data secara optimal

### Schrödinger Bridge vs Flow Matching

| Aspek             | Flow Matching                           | Schrödinger Bridge               |
| ----------------- | --------------------------------------- | -------------------------------- |
| Path              | Pre-defined (linear) → rectified        | **Optimized** by IPF             |
| Objective         | Vector field regression + rectification | Forward-backward KL minimization |
| Boundary          | Gaussian ↔ data                         | **Arbitrary** distributions      |
| Theoretical depth | ODE / OT                                | **SDE / PDE / Entropic OT**      |
| Maturity          | Production-ready (SD3, Flux)            | **Research frontier**            |
| Complexity        | Low                                     | High (iterative training)        |

### Recent Breakthroughs

| Paper                              | Year | Key Idea                                                |
| ---------------------------------- | ---- | ------------------------------------------------------- |
| Diffusion Schrödinger Bridge (DSB) | 2021 | IPF + score matching                                    |
| I²SB (Image-to-Image SB)           | 2022 | Unpaired translation dengan SB                          |
| DSBM (Discrete SB)                 | 2023 | SB untuk discrete data                                  |
| LightSB                            | 2024 | Fast SB via flow matching objective + SB regularization |
| SB-Flow                            | 2024 | Unify flow matching & SB — one framework                |

### Kelebihan Konkret

- ✅ **Optimal path** — lebih straight → sampling lebih cepat
- ✅ **Arbitrary boundaries** — bukan cuma noise→data, tapi data→data, domain→domain
- ✅ **Unifies generative approaches** — diffusion, flow matching, OT, semua kasus spesial dari SB
- ✅ **Principled interpolation** — teori entropic OT kuat
- ✅ **Image translation** domain adaptation langsung tanpa model tambahan
- ✅ **Frontier research** — potensi gebrakan di 2025-2026

### Tradeoff

- ⚠️ **Iterative training** (IPF) — butuh beberapa siklus forward-backward
- ⚠️ **Computationally heavier** — setiap iterasi train diffusion model
- ⚠️ **Belum production-ready** — mostly di kertas riset, belum di-deploy di produk skala besar
- ⚠️ **Convergence guarantee** — IPF converges, tapi kecepatan tergantung problem
- ⚠️ **High barrier** — perlu paham SDE, PDE, OT biar bisa implementasi

---

## Perbandingan Seluruh Algoritma

| #   | Algoritma                   | Domain Utama          | Kelebihan Paling Unik                                            | Tahun Breakout |
| --- | --------------------------- | --------------------- | ---------------------------------------------------------------- | -------------- |
| 1   | Flash Attention             | Attention / Training  | **Memory O(N) via IO-aware tiling** — 2-4× training speedup      | 2022           |
| 2   | Multi-Head Latent Attention | Attention / Inference | **KV cache 75-90% lebih kecil** via latent compression           | 2024           |
| 3   | Latent Diffusion            | Image Generation      | **Diffusion di 48× compressed space** — efficient & high quality | 2022           |
| 4   | Flow Matching               | Generative Model      | **Straight-line trajectory** — 1-50 steps sampling vs 50-1000    | 2023           |
| 5   | VLA                         | Robotics              | **Unified vision-language-action** — foundation model for robots | 2023           |
| 6   | RLHF + PPO                  | LLM Alignment         | **Preference-based alignment** — helpful, harmless, honest       | 2022           |
| 7   | World Model                 | RL / Planning         | **Dream-based planning** — 10-50× sample efficiency              | 2020-2023      |
| 8   | Schrödinger Bridge          | Generative / OT       | **Optimal path between ANY distributions** — beyond diffusion    | 2021-2024      |

### Interconnections & Trends

```
Flash Attention ──→ MLA ──→ Efficient long-context (memory bottleneck solved)
                        ↓
Latent Diffusion ──→ Flow Matching ──→ Schrödinger Bridge
  (pixel → latent)    (curved → straight)  (suboptimal → optimal)
                        ↓
                   VLA ──→ World Model (robotics & planning unification)
                        ↓
              RLHF + PPO ──→ LLM Alignment
```

**Big picture 2024-2026:**

1. **Attention menjadi linear atau sub-quadratic** — Flash Attention → MLA → mungkin Mamba/state-space hybrid
2. **Generative path menjadi optimal** — Diffusion → Flow Matching → Schrödinger Bridge
3. **Unified foundation models** — VLM → VLA → World Foundation Models
4. **Efficient alignment** — RLHF (PPO) → DPO → Preference Optimization tanpa reward model

---

## Referensi

1. Dao et al. (2022). "FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness." _NeurIPS 2022._
2. DeepSeek-AI. (2024). "DeepSeek-V2: A Strong, Economical, and Efficient Mixture-of-Experts Language Model." _arXiv:2405.04434._
3. Rombach et al. (2022). "High-Resolution Image Synthesis with Latent Diffusion Models." _CVPR 2022._
4. Lipman et al. (2023). "Flow Matching for Generative Modeling." _ICLR 2023._
5. Liu et al. (2023). "Flow Straight and Fast: Learning to Generate and Transfer Data with Rectified Flow." _ICLR 2023._
6. Brohan et al. (2023). "RT-2: Vision-Language-Action Models Transfer Web Knowledge to Robotic Control." _arXiv:2307.15818._
7. Ouyang et al. (2022). "Training language models to follow instructions with human feedback." _NeurIPS 2022._
8. Schulman et al. (2017). "Proximal Policy Optimization Algorithms." _arXiv:1707.06347._
9. Hafner et al. (2023). "Mastering Diverse Domains through World Models." _arXiv:2301.04104._
10. De Bortoli et al. (2021). "Diffusion Schrödinger Bridge with Applications to Score-Based Generative Modeling." _NeurIPS 2021._
11. Rafailov et al. (2023). "Direct Preference Optimization: Your Language Model is Secretly a Reward Model." _NeurIPS 2023._
12. Bruce et al. (2024). "Genie: Generative Interactive Environments." _arXiv:2402.15391._

---

_Dibuat: 16 Juli 2026 — Sesi deep-dive 8 algoritma AI generatif & foundation model terkini._
