---
title: "Reinforcement Learning Deep-Dive — Mathematics and Cybersecurity Applications"
tags:
  - reinforcement-learning
  - machine-learning
  - ppo
  - dqn
  - decision-making
  - cyber-security
aliases:
  - "reinforcement-learning-deepdive"
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Reinforcement Learning (RL) adalah cabang pembelajaran mesin yang berfokus pada pengambilan keputusan sekuensial (_sequential decision-making_) guna memaksimalkan akumulasi hadiah (_cumulative reward_). Catatan ini melengkapi pembahasan teori klasik di [[machine-learning-classical-hierarchy]] dan integrasinya untuk keamanan siber.

## Daftar Isi

1. [Kerangka Kerja Markov Decision Process (MDP)](#1-kerangka-kerja-markov-decision-process-mdp)
2. [Persamaan Bellman (Bellman Equations)](#2-persamaan-bellman-bellman-equations)
3. [Algoritma Kunci: Deep Q-Networks (DQN)](#3-algoritma-kunci-deep-q-networks-dqn)
4. [Proximal Policy Optimization (PPO) & Clipped Objective](#4-proximal-policy-optimization-ppo--clipped-objective)
5. [Aplikasi RL pada Pertahanan & Penetrasi Siber](#5-aplikasi-rl-pada-pertahanan--penetrasi-siber)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Kerangka Kerja Markov Decision Process (MDP)

Hampir semua masalah Reinforcement Learning diformulasikan secara matematis menggunakan **Markov Decision Process (MDP)**. MDP mengasumsikan bahwa efek dari tindakan saat ini hanya bergantung pada _state_ saat ini, bukan sejarah masa lalu (_Markov Property_).

Formalisasi MDP didefinisikan oleh tuple $(S, A, P, R, \gamma)$:

- **$S$**: Kumpulan seluruh _state_ (keadaan) sistem yang mungkin.
- **$A$**: Kumpulan seluruh _action_ (tindakan) yang bisa diambil oleh agen.
- **$P(s' \mid s, a)$**: Probabilitas transisi untuk berpindah dari keadaan $s$ ke $s'$ setelah mengambil tindakan $a$.
- **$R(s, a, s')$**: Fungsi _reward_ (hadiah) yang diterima setelah transisi terjadi.
- **$\gamma$**: _Discount factor_ ($0 \le \gamma \le 1$) untuk menyeimbangkan nilai _immediate reward_ vs _future reward_.

---

## 2. Persamaan Bellman (Bellman Equations)

Tujuan utama agen RL adalah menemukan kebijakan optimal ($\pi^*(a \mid s)$) yang memaksimalkan ekspektasi _return_ yang terdiskon di masa depan. Persamaan Bellman memecah fungsi nilai (_value function_) secara rekursif menjadi nilai saat ini ditambah nilai masa depan:

### 2.1 State-Value Function $V^\pi(s)$

Mengukur seberapa baik keadaan $s$ jika mengikuti kebijakan $\pi$:
$$V^\pi(s) = \sum_{a \in A} \pi(a \mid s) \sum_{s' \in S} P(s' \mid s, a) \left[ R(s, a, s') + \gamma V^\pi(s') \right]$$

### 2.2 Action-Value Function $Q^\pi(s, a)$

Mengukur kualitas tindakan $a$ yang diambil pada keadaan $s$:
$$Q^\pi(s, a) = \sum_{s' \in S} P(s' \mid s, a) \left[ R(s, a, s') + \gamma \sum_{a' \in A} \pi(a' \mid s') Q^\pi(s', a') \right]$$

---

## 3. Algoritma Kunci: Deep Q-Networks (DQN)

Pada masalah dengan dimensi state yang sangat besar (seperti pixel game atau memori sistem operasi), tabel $Q(s, a)$ tidak muat disimpan dalam memori. **DQN** menggantikan tabel tersebut dengan jaringan saraf tiruan (_Deep Neural Network_) sebagai approximator nilai $Q(s, a; \theta)$.

### 3.1 Fungsi Loss DQN dengan Target Network

Untuk melatih jaringan DQN secara stabil, digunakan konsep **Experience Replay** dan **Target Network** ($\theta^-$):
$$L(\theta) = \mathbb{E}_{(s, a, r, s') \sim D} \left[ \left( r + \gamma \max_{a'} Q(s', a'; \theta^-) - Q(s, a; \theta) \right)^2 \right]$$

---

## 4. Proximal Policy Optimization (PPO) & Clipped Objective

PPO adalah algoritma _Policy Gradient_ (Actor-Critic) standar industri yang dirancang oleh OpenAI. PPO sangat stabil karena membatasi seberapa jauh perubahan kebijakan ($\pi_\theta$) dari kebijakan lama ($\pi_{\theta_{old}}$) pada setiap iterasi training.

### 4.1 Clipped Surrogate Objective Function

Fungsi tujuan (objective) PPO dituliskan sebagai berikut:
$$L^{CLIP}(\theta) = \hat{\mathbb{E}}_t \left[ \min(r_t(\theta)\hat{A}_t, \, \text{clip}(r_t(\theta), 1-\epsilon, 1+\epsilon)\hat{A}_t) \right]$$

Dimana:

- **Probability Ratio**: $r_t(\theta) = \frac{\pi_\theta(a_t \mid s_t)}{\pi_{\theta_{old}}(a_t \mid s_t)}$
- **Advantage Estimate**: $\hat{A}_t$ mengukur seberapa jauh tindakan lebih baik dibanding rata-rata pilihan yang ada.
- **Clipped Penalty**: Parameter $\epsilon$ (biasanya bernilai 0.1 atau 0.2) membatasi nilai rasio probabilitas untuk mencegah update kebijakan yang terlalu drastis (_destructive step_).

---

## 5. Aplikasi RL pada Pertahanan & Penetrasi Siber

Penggunaan RL di domain cybersecurity mengubah paradigma analisis dari statis menjadi dinamis otonom:

### 5.1 Agen Penetrasi Siber Otonom (Autonomous Red Teaming)

- **Environment**: Sebuah jaringan Active Directory (AD) perusahaan yang disimulasikan.
- **State**: Daftar host yang terkompromi, port yang terbuka, dan kredensial yang dimiliki agen saat ini.
- **Actions**: Menjalankan _mimikatz_, melakukan _port scanning_, eskalasi hak akses (_local privilege escalation_), atau lateral movement.
- **Reward**: Positif (+100) jika berhasil menguasai domain controller, negatif (-1) untuk setiap langkah yang diambil (mendorong efisiensi), dan sangat negatif (-500) jika terdeteksi oleh sistem pertahanan Blue Team (EDR).
- **Hasil**: Agen belajar merumuskan lintasan serangan optimal yang sebelumnya tidak terpikirkan oleh penyerang manusia.

### 5.2 Pertahanan Adaptif (Adaptive Cyber Defense)

- Agen RL dilatih untuk mengalokasikan pertahanan secara dinamis (seperti merubah konfigurasi firewall, mematikan port, atau merotasi IP) untuk merespon pergerakan penyerang secara real-time di level infrastruktur terdistribusi.

---

## 6. Koneksi ke Vault

| Catatan                                  | Hubungan                                                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [[machine-learning-classical-hierarchy]] | Klasifikasi metodologi RL dalam peta jalan kecerdasan buatan.                                   |
| [[adversarial-machine-learning]]         | Teknik memanipulasi input observasi agen RL agar mengambil keputusan salah (_evasion attacks_). |
| [[blueteam-detection-matrix]]            | Pengenalan taktik pertahanan yang didefinisikan sebagai penalti pada reward function agen RL.   |
