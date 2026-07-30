---
title: LLM Wiki — Reference Notes
tags:
- llm
- attention
- transformer
- scaling
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> Quick reference untuk konsep LLM.

## Topics
### Scaling Laws
- Kaplan scaling: loss proportional to (N,D) where N=params, D=data
- Chinchilla scaling: optimal compute = 20 tokens/param

### Attention Mechanisms
- Multi-head, Grouped-query, Multi-query, Flash attention
- KV cache optimization

### Fine-tuning
- Full fine-tune, LoRA, QLoRA, Adapter, Prefix tuning
- RLHF vs DPO

### Infrastructure
- vLLM, TensorRT-LLM, TGI
- Quantization: AWQ, GPTQ, GGUF

See also: llm-finetuning-toolchain, test-time-compute-system2