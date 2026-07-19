---
title: "Self-Hosted LLM Deployment — Ollama + vLLM + Open WebUI + Auth"
tags:
  - llm
  - ollama
  - vllm
  - self-hosting
  - docker
  - gpu
  - ai-systems
aliases:
  - "ollama-vllm-self-hosting"
  - "local-llm-deployment"
  - "homelab-ai-serving"
created: "2026-07-19"
updated: "2026-07-19"
status: active
cssclasses:
  - wide-table
---

# 🚀 Self-Hosted LLM — Ollama + vLLM + Open WebUI + Security

> **Filosofi:** Model LLM gak harus lewat cloud API (OpenAI, Anthropic) yang mahal dan data keluar. Dengan GPU consumer (RTX 3090/4090) atau bahkan CPU-only, bisa self-host model 7-70B parameter — private, gratis setelah hardware, dan fully controlled. Catatan ini panduan praktis: dari Docker Compose sampai auth security layer.

> [!info] Posisi di Vault
> Terhubung dengan [[production-model-serving-optimization]] (teori inference engines, quantization, KV cache), [[llm-finetuning-toolchain]] (train → export → serve pipeline), [[rag-pipeline-end-to-end-guide]] (RAG after serving), [[llmops-ai-infrastructure]] (infrastructure overview), dan [[edge-computing-iot-security-architecture]] (edge deployment).

---

## Daftar Isi

- [[#1. Kenapa Self-Host? — Cost vs Control]]
- [[#2. Hardware Prerequisites]]
- [[#3. Ollama Stack — Docker Compose]]
- [[#4. vLLM + Ollama Hybrid — Multi-Model Serving]]
- [[#5. Security Layer — Auth + Rate Limiting]]
- [[#6. GPU Management — Multi-Model GPU Sharing]]
- [[#7. Model Management — Download, Quantize, Rotate]]
- [[#8. Production Deployment — Cloud VM]]
- [[#9. Monitoring — Grafana + GPU Metrics]]
- [[#10. Troubleshooting]]

---

## 1. Kenapa Self-Host? — Cost vs Control

| Aspek                  | Cloud API (OpenAI)                 | Self-Hosted (Ollama/vLLM)         |
| ---------------------- | ---------------------------------- | --------------------------------- |
| **Cost per 1M tokens** | $2.50 (GPT-4o mini) - $15 (GPT-4o) | $0 (hardware capex) + electricity |
| **Data privacy**       | Data ke cloud provider             | 100% local                        |
| **Latency**            | 200-800ms (network round-trip)     | 10-50ms (localhost / LAN)         |
| **Model choice**       | Provider-curated                   | Apapun dari HuggingFace           |
| **Rate limit**         | TPM/RPM quota                      | Unlimited                         |
| **Reliability**        | Provider-dependent                 | Bergantung hardware kamu          |
| **GPU capex**          | $0                                 | RTX 3090: ~$700 (used)            |

**Break-even point:** Kalau infer >50M tokens/bulan, self-host lebih murah dalam 6-12 bulan.

---

## 2. Hardware Prerequisites

| GPU                     | VRAM  | Model (Quant)               | Throughput    |
| ----------------------- | ----- | --------------------------- | ------------- |
| **CPU-only (32GB RAM)** | N/A   | Llama 3.1 8B Q4_K_M (4.5GB) | 3-10 tok/s    |
| **RTX 3060 12GB**       | 12 GB | 7B AWQ-4 (4GB)              | 40-70 tok/s   |
| **RTX 3090 24GB**       | 24 GB | 7B FP16 / 13B AWQ           | 80-120 tok/s  |
| **RTX 4090 24GB**       | 24 GB | 7B FP16 / 13B AWQ           | 120-160 tok/s |
| **2× RTX 3090**         | 48 GB | 30B AWQ / 70B Q4_K_M        | 40-70 tok/s   |
| **A100 80GB**           | 80 GB | 70B AWQ / 70B FP16          | 100-200 tok/s |

**Minimum viable:** RTX 3060 12GB = 7B AWQ model → good quality, fast enough.

---

## 3. Ollama Stack — Docker Compose

### 3.1 Architecture

```plaintext
┌──────────────────────────────────────────┐
│              DOCKER HOST                  │
│                                          │
│  ┌──────────┐   ┌──────────┐   ┌───────┐ │
│  │ Ollama   │   │ Open     │   │ NGINX │ │
│  │ :11434   │◀──│ WebUI    │◀──│ :443  │ │
│  │          │   │ :8080    │   │ auth  │ │
│  └──────────┘   └──────────┘   └───────┘ │
│       │                        │         │
│       ▼                        ▼         │
│  /models (volume)     /data (volume)     │
└──────────────────────────────────────────┘
```

### 3.2 docker-compose.yml

```yaml
version: "3.8"

services:
  ollama:
    image: ollama/ollama:0.3.12
    container_name: ollama
    restart: unless-stopped
    ports:
      - "127.0.0.1:11434:11434" # BIND LOCALHOST ONLY — security!
    volumes:
      - ./ollama-models:/root/.ollama # model storage persistent
    environment:
      - OLLAMA_KEEP_ALIVE=24h # keep model in VRAM
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_NUM_PARALLEL=4 # concurrent requests
      - OLLAMA_MAX_LOADED_MODELS=2 # max models in VRAM
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:v0.4.8
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./webui-data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_AUTH=true # enable auth
      - WEBUI_SECRET_KEY=${WEBUI_SECRET} # from .env
      - ENABLE_SIGNUP=false # admin-only user creation
    depends_on:
      - ollama

  nginx:
    image: nginx:alpine
    container_name: llm-proxy
    restart: unless-stopped
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro # TLS certs
    depends_on:
      - open-webui
```

### 3.3 nginx.conf — TLS + Auth + Rate Limit

```nginx
upstream openwebui {
    server open-webui:8080;
}

server {
    listen 443 ssl http2;
    server_name llm.yourdomain.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    # Rate limiting — prevent abuse
    limit_req_zone $binary_remote_addr zone=llm:10m rate=30r/m;
    limit_req zone=llm burst=10 nodelay;

    location / {
        limit_req zone=llm burst=10 nodelay;
        proxy_pass http://openwebui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Security headers
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
}
```

### 3.4 First Run — Download Models

```bash
# Pull model pertama
docker exec -it ollama ollama pull llama3.1:8b-instruct-q4_K_M
# Pull model kedua (lightweight, buat task cepat)
docker exec -it ollama ollama pull qwen2.5:1.5b-instruct-q4_K_M

# Verify
docker exec -it ollama ollama list
```

---

## 4. vLLM + Ollama Hybrid — Multi-Model Serving

### 4.1 Kenapa Hybrid?

| Use Case                     | Engine              | Alasan                               |
| ---------------------------- | ------------------- | ------------------------------------ |
| **Chat UI (end-user)**       | Ollama + Open WebUI | Simple UI, multiple models           |
| **API serving (production)** | vLLM                | High throughput, continuous batching |
| **Edge / CPU-only**          | Ollama              | GGUF quantization, CPU inference     |
| **Max throughput**           | vLLM                | PagedAttention, FP8 KV cache         |

### 4.2 docker-compose.yml — Hybrid

```yaml
services:
  vllm:
    image: vllm/vllm-openai:v0.6.2
    container_name: vllm-api
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"
    command:
      - "--model"
      - "mistralai/Mistral-7B-Instruct-v0.3"
      - "--quantization"
      - "awq"
      - "--max-model-len"
      - "8192"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--enable-prefix-caching"
      - "--api-key"
      - "${VLLM_API_KEY}" # dari .env
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  ollama:
    image: ollama/ollama:0.3.12
    # ... same as above

  router: # Python inference router
    build: ./router
    container_name: llm-router
    restart: unless-stopped
    ports:
      - "127.0.0.1:9000:9000"
    environment:
      - VLLM_URL=http://vllm:8000/v1
      - OLLAMA_URL=http://ollama:11434
      - ROUTER_API_KEY=${ROUTER_API_KEY}
    depends_on:
      - vllm
      - ollama
```

### 4.3 Router Code — Route by Complexity

```python
# router/main.py
from fastapi import FastAPI, HTTPException
from openai import AsyncOpenAI
import httpx

app = FastAPI()

vllm_client = AsyncOpenAI(base_url="http://vllm:8000/v1", api_key=os.environ["VLLM_API_KEY"])

async def ollama_chat(model: str, messages: list):
    async with httpx.AsyncClient() as client:
        r = await client.post(
            "http://ollama:11434/api/chat",
            json={"model": model, "messages": messages, "stream": False}
        )
        return r.json()["message"]["content"]

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    # Route ke small model untuk short/simple prompt
    if len(request.prompt) < 500:
        return await ollama_chat("qwen2.5:1.5b", request.messages)
    # Route ke vLLM untuk complex/long prompt
    return await vllm_client.chat.completions.create(
        model="mistralai/Mistral-7B-Instruct-v0.3",
        messages=request.messages
    )
```

---

## 5. Security Layer — Auth + Rate Limiting

### 5.1 Authentication Checklist

```yaml
# .env
WEBUI_SECRET=openssl_rand_hex_64
VLLM_API_KEY=sk-self-hosted-vllm-key-2026
ROUTER_API_KEY=sk-router-internal-only
# NGINX basic auth untuk admin endpoint
# htpasswd -c /etc/nginx/.htpasswd admin
```

### 5.2 API Key Protection

```
☐ vLLM: --api-key di-set (default: no auth! empty = anyone can call)
☐ Ollama: bind ke 127.0.0.1 (jangan expose 0.0.0.0 tanpa auth)
☐ Open WebUI: WEBUI_AUTH=true + ENABLE_SIGNUP=false
☐ Router: require API key header untuk /v1/*
☐ NGINX: rate limit 30r/m per IP
☐ Firewall: UFW hanya allow port 443, block 11434/8000/8080 dari luar
```

### 5.3 UFW Rules

```bash
ufw allow 443/tcp
ufw deny 11434/tcp   # Ollama
ufw deny 8000/tcp    # vLLM
ufw deny 8080/tcp    # Open WebUI
```

---

## 6. GPU Management — Multi-Model GPU Sharing

### 6.1 VRAM Budget Calculator

```
Total VRAM = Weight size + KV cache + Activations + Overhead

3090 24GB:
  - 7B AWQ-4: 4GB weights + 4GB KV cache + 2GB activations = 10GB (aman)
  - 7B AWQ-4 + 1.5B Q4: 4GB + 1.2GB + 5GB = 10.2GB
  - 13B AWQ-4: 7GB + 6GB + 3GB = 16GB (aman tapi tight)

A100 80GB:
  - 70B AWQ-4: 35GB + 20GB + 10GB = 65GB
  - 70B AWQ-4 + 8B FP16: 35GB + 14GB + 25GB = 74GB
```

### 6.2 GPU Monitoring

```bash
# nvidia-smi watch
watch -n1 nvidia-smi

# vLLM metrics (Prometheus endpoint)
curl http://localhost:8000/metrics | grep vllm

# Key alerts:
# gpu_cache_usage > 0.90 → OOM risk
# num_requests_waiting > 50 → backlogged
# gpu_memory_total - gpu_memory_free < 1000MB → no headroom
```

---

## 7. Model Management — Download, Quantize, Rotate

### 7.1 Ollama Model Lifecycle

```bash
# 1. Pull
ollama pull llama3.1:8b-instruct-q4_K_M

# 2. List
ollama list

# 3. Show details
ollama show llama3.1:8b-instruct-q4_K_M

# 4. Copy / rename (buat variant)
ollama cp llama3.1:8b-instruct-q4_K_M llama3.1:8b-custom

# 5. Remove (cleanup)
ollama rm llama3.1:8b-instruct-q4_K_M
```

### 7.2 HuggingFace → Ollama GGUF

```bash
# Download GGUF dari HuggingFace
huggingface-cli download TheBloke/Llama-3.1-8B-Instruct-GGUF \
  llama-3.1-8b-instruct-q4_k_m.gguf \
  --local-dir ./models/

# Buat Modelfile
cat > Modelfile <<EOF
FROM ./models/llama-3.1-8b-instruct-q4_k_m.gguf
TEMPLATE """<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|><|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""
PARAMETER temperature 0.7
PARAMETER top_p 0.9
EOF

# Create in Ollama
ollama create llama3.1-custom -f Modelfile
```

### 7.3 Model Rotation Strategy

```
Production:
  - 1 primary model (7B/13B) selalu loaded → set OLLAMA_KEEP_ALIVE=24h
  - 1 lightweight model (1.5B) untuk task simple (classification, parsing)
  - 1 experimental model (new version) untuk A/B test

Rotasi:
  - Tiap bulan: evaluasi model baru dari HuggingFace leaderboard
  - Tiap major release: update model → ollama rm old → ollama pull new
  - Backup: simpan GGUF file di /backup/models/
```

---

## 8. Production Deployment — Cloud VM

### 8.1 Cloud GPU Rental

| Provider        | GPU       | $/hr     | Best For          |
| --------------- | --------- | -------- | ----------------- |
| **RunPod**      | RTX 3090  | $0.44/hr | Budget production |
| **RunPod**      | A100 80GB | $1.89/hr | 70B models        |
| **Vast.ai**     | RTX 3090  | $0.35/hr | Cheapest          |
| **Vast.ai**     | RTX 4090  | $0.50/hr | Max perf/$        |
| **Lambda Labs** | A100 80GB | $1.10/hr | Reserved clusters |

### 8.2 RunPod Deployment Script

```bash
# RunPod template deploy
curl -X POST https://api.runpod.io/v2/pods \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ollama-vllm-stack",
    "imageName": "runpod/pytorch:2.4.0-py3.11-cuda12.4.1",
    "gpuTypeId": "NVIDIA RTX 3090",
    "containerDiskInGb": 100,
    "volumeInGb": 200,
    "env": {
      "HF_HOME": "/workspace/huggingface"
    }
  }'

# SSH ke pod → deploy docker compose
ssh root@<pod-ip> -p <port>
git clone <deploy-repo>
docker compose up -d
```

---

## 9. Monitoring — Grafana + GPU Metrics

### 9.1 DCGM Exporter (NVIDIA GPU metrics)

```yaml
# docker-compose — add monitoring stack
services:
  dcgm-exporter:
    image: nvidia/dcgm-exporter:3.3.5
    container_name: dcgm-exporter
    restart: unless-stopped
    ports:
      - "127.0.0.1:9400:9400"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  prometheus:
    image: prom/prometheus:v2.51.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:11.1.0
    container_name: grafana
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
```

### 9.2 Key Metrics Dashboard

```
GPU Panel:
  - DCGM_FI_DEV_GPU_UTIL       → GPU utilization %
  - DCGM_FI_DEV_MEM_COPY_UTIL  → VRAM bandwidth
  - DCGM_FI_DEV_FB_USED        → VRAM used (MB)
  - DCGM_FI_DEV_GPU_TEMP       → Temperature (°C)

vLLM Panel:
  - vllm_num_requests_running   → Current inflight
  - vllm_num_requests_waiting   → Queue depth
  - vllm_gpu_cache_usage        → KV cache %
  - vllm_time_to_first_token_seconds → TTFT histogram

Alert Rules:
  - gpu_temp > 85°C for 5m → WARNING
  - vram_used > 90% for 2m → CRITICAL: OOM risk
  - request_queue > 50 for 5m → WARNING: backlogged
```

---

## 10. Troubleshooting

| Problem                | Symptom                           | Fix                                                                            |
| ---------------------- | --------------------------------- | ------------------------------------------------------------------------------ |
| **Ollama OOM**         | `CUDA out of memory` di log       | Kurangi `OLLAMA_MAX_LOADED_MODELS=1`, unload model lain: `ollama stop <model>` |
| **GPU not detected**   | `nvidia-smi` empty di container   | `docker run --gpus all` atau `nvidia-container-toolkit` tidak terinstall       |
| **Model corruption**   | `checksum mismatch`               | Re-pull: `ollama rm <model> && ollama pull <model>`                            |
| **Open WebUI blank**   | White screen, no JS               | Check `WEBUI_SECRET_KEY` di-set, clear browser cache                           |
| **Slow inference**     | <5 tok/s                          | Check quantization: Q4_K_M instead of FP16. Set `OLLAMA_NUM_PARALLEL=1`        |
| **TLS error**          | `NET::ERR_CERT_AUTHORITY_INVALID` | Renew cert: `certbot renew`, restart nginx                                     |
| **Rate limit hitting** | 503 Service Unavailable           | Increase burst di nginx.conf, atau whitelist IP internal                       |

---

## 🔗 Lihat Juga

- [[production-model-serving-optimization]] — Teori inference engines, quantization, KV cache
- [[llm-finetuning-toolchain]] — Training → fine-tuning → export pipeline
- [[rag-pipeline-end-to-end-guide]] — RAG setelah model di-serve
- [[llmops-ai-infrastructure]] — AI infrastructure overview
- [[edge-computing-iot-security-architecture]] — Edge deployment (CPU-only)
- [[gpu-programming-parallel-compute]] — CUDA fundamentals untuk inference optimization

---

## Referensi

- Ollama. _GitHub_. https://github.com/ollama/ollama
- Open WebUI. _Self-Hosted LLM Chat_. https://github.com/open-webui/open-webui
- vLLM. _Production Inference Engine_. https://docs.vllm.ai/en/latest/
- NVIDIA DCGM. _GPU Monitoring_. https://developer.nvidia.com/dcgm
- RunPod. _GPU Cloud_. https://www.runpod.io/
- Vast.ai. _GPU Rental_. https://vast.ai/
- HuggingFace. _GGUF Quantized Models_. https://huggingface.co/TheBloke
- NGINX. _Rate Limiting_. https://nginx.org/en/docs/http/ngx_http_limit_req_module.html

---

_Dibuat: 19 Juli 2026 — Self-hosted LLM dari Docker Compose sampai monitoring production._
