---
title: "RNN-LSTM vs Transformer"
tags:
  - rnn
  - lstm
  - transformer
  - attention
aliases:
  - "rnn-lstm-vs-transformer"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Perbandingan arsitektur sequence modeling.

| Aspect                | RNN/LSTM               | Transformer         | Winner      |
| --------------------- | ---------------------- | ------------------- | ----------- |
| Parallelization       | Sequential (time-step) | Full parallel       | Transformer |
| Long-range dependency | Vanishing gradient     | Direct attention    | Transformer |
| Training speed        | Slow                   | Fast (GPU parallel) | Transformer |
| Inference memory      | O(1) hidden state      | O(N^2) attention    | RNN         |
| Small data            | Good                   | Needs large data    | RNN         |

## Modern Usage

- RNN/LSTM: real-time streaming, low-latency, edge devices
- Transformer: text, image, audio generation (default since 2020)
- Hybrid: Mamba (state-space), RWKV (RNN + transformer mix)
