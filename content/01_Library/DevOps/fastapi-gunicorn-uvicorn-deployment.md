---
title: ❌ SALAH — app code
tags:
- fastapi
- gunicorn
- uvicorn
- deployment
- production
- asgi
- wsgi
- python
aliases:
- FastAPI Deployment
- Gunicorn Uvicorn
- FastAPI Production
created: 2026-07-26
updated: 2026-07-26
status: pending
cssclasses:
  - wide-table
  
---

> [!abstract] Gunicorn + Uvicorn: The Right Way
> Ringkasan & praktik dari artikel *Mastering Gunicorn and Uvicorn: The Right Way to Deploy FastAPI Applications* oleh Iklobato. Fokus: konfigurasi yang benar, nested worker trap, resource management, dan production checklist. Catatan ini bukan translasi — tapi ekstraksi pola yang langsung bisa dipakai.

---

## 1. Concurrency vs Parallelism — Why Both Matter

| | Concurrency | Parallelism |
|:--|:-----------|:------------|
| **Apa** | Banyak task *making progress* via time-sharing | Banyak task jalan *simultan* di core berbeda |
| **Implementasi Python** | `async/await`, event loop | `multiprocessing`, multi-process |
| **Cocok untuk** | I/O-bound (DB, API, file) | CPU-bound (kalkulasi, ML inference) |
| **Skalabilitas** | Ribuan koneksi concurrent | Terbatas jumlah core |
| **Yang handle** | Uvicorn (event loop per worker) | Gunicorn (banyak worker process) |

**Kunci:** Jangan pilih salah satu — **kombinasi keduanya** yang optimal. Gunicorn ngasih parallelism (multi-worker), tiap worker Uvicorn ngasih concurrency (async event loop).

---

## 2. Nested Worker Trap — ❌ Jangan Lakukan Ini

Ini **mistake paling umum** dan paling fatal:

```python
# ❌ SALAH — app code
if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, workers=4)
```

```bash
# ❌ SALAH — ditambah Gunicorn juga
gunicorn --workers 4 --worker-class uvicorn.workers.UvicornWorker app:app
```

**Efek domino:**
- Gunicorn spawn 4 worker processes
- Tiap worker jalanin `uvicorn.run(workers=4)` → spawn 4 lagi
- **Total: 4 × 4 = 16 processes** pada 4-core machine
- Context switching overhead → latency naik 200–400ms
- Memory 4× lipat

### Yang Benar ✅

```python
# ✅ App code — cukup FastAPI instance, NO uvicorn.run()
from fastapi import FastAPI
app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```

```bash
# ✅ Gunicorn sebagai process manager tunggal
gunicorn --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --worker-connections 1000 \
  --bind 0.0.0.0:8000 \
  app:app
```

**Architecture:**
```
Gunicorn Master
  ├── Worker 1 (UvicornWorker, async event loop, 1000 conn)
  ├── Worker 2 (UvicornWorker, async event loop, 1000 conn)
  ├── Worker 3 (UvicornWorker, async event loop, 1000 conn)
  └── Worker 4 (UvicornWorker, async event loop, 1000 conn)
```

Tepat **4 processes**, nggak lebih. Masing-masing handle ribuan koneksi concurrent via async.

---

## 3. Worker Formula

### Default Starting Point

```bash
# I/O-bound (typical web API)
workers = cpu_cores × 2

# CPU-bound (image processing, ML)
workers = (cpu_cores × 2) + 1
```

### Configuration Matrix (dari artikel)

| Use Case | Cores | Workers | Worker Connections | Total Concurrent |
|:---------|:-----:|:-------:|:------------------:|:----------------:|
| I/O Heavy API | 4 | 8 | 1.000 | 8.000 |
| CPU Heavy API | 4 | 9 | 500 | 4.500 |
| WebSocket App | 4 | 4 | 2.000 | 8.000 |
| High Traffic Web | 8 | 12 | 1.500 | 18.000 |
| Microservice | 2 | 2 | 800 | 1.600 |

### Advanced Production Config

```bash
gunicorn \
  --workers 8 \
  --worker-class uvicorn.workers.UvicornWorker \
  --worker-connections 2000 \
  --max-requests 10000 \
  --max-requests-jitter 1000 \
  --preload-app \
  --timeout 60 \
  --keep-alive 5 \
  --access-logfile /var/log/gunicorn/access.log \
  --error-logfile /var/log/gunicorn/error.log \
  --bind 0.0.0.0:8000 \
  app:app
```

**Parameter penting:**
- `--max-requests 10000` + `--max-requests-jitter 1000` — restart worker periodik biar memory leak nggak numpuk
- `--preload-app` — load app code sebelum fork worker (hemat memory, startup lebih cepat)
- `--worker-connections 2000` — max concurrent connection per worker

---

## 4. WebSocket-Specific Config

```bash
gunicorn \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --worker-connections 5000 \
  --timeout 300 \
  --keep-alive 5 \
  --bind 0.0.0.0:8000 \
  app:app
```

WebSocket butuh `--worker-connections` tinggi karena koneksi long-lived, tapi `--workers` lebih sedikit karena tiap koneksi ringan.

---

## 5. Monitoring & Health Check

### Health Check Endpoint

```python
import os, asyncio, psutil

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "worker_pid": os.getpid(),
        "active_tasks": len(asyncio.all_tasks()),
        "memory_mb": psutil.Process(os.getpid()).memory_info().rss / 1024 / 1024,
    }
```

### Middleware Performance Tracking

```python
@app.middleware("http")
async def monitor_performance(request, call_next):
    start = time.time()
    response = await call_next(request)
    process_time = time.time() - start
    response.headers["X-Process-Time"] = str(round(process_time, 3))
    response.headers["X-Worker-PID"] = str(os.getpid())
    if process_time > 1.0:
        print(f"SLOW: {request.url} took {process_time:.2f}s")
    return response
```

### Memory Debug Endpoint

```python
import tracemalloc, gc

tracemalloc.start()

@app.get("/memory-debug")
async def debug_memory():
    collected = gc.collect()
    current, peak = tracemalloc.get_traced_memory()
    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics('lineno')
    return {
        "worker_pid": os.getpid(),
        "memory_current_mb": round(current / (1024**2), 2),
        "memory_peak_mb": round(peak / (1024**2), 2),
        "garbage_collected": collected,
        "top_consumers": [
            {"file": stat.traceback.format()[0],
             "size_mb": round(stat.size / (1024**2), 2)}
            for stat in top_stats[:5]
        ]
    }
```

---

## 6. Graceful Shutdown

```python
import signal, asyncio
from contextlib import asynccontextmanager

shutdown_event = asyncio.Event()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    signal.signal(signal.SIGTERM, lambda s, f: shutdown_event.set())
    signal.signal(signal.SIGINT, lambda s, f: shutdown_event.set())
    yield
    # Shutdown
    try:
        await asyncio.wait_for(shutdown_event.wait(), timeout=30.0)
    except asyncio.TimeoutError:
        print("Graceful shutdown timeout, forcing exit")
    # Cleanup
    tasks = [t for t in asyncio.all_tasks() if not t.done()]
    for t in tasks:
        t.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)

app = FastAPI(lifespan=lifespan)
```

---

## 7. Container Resource Limits (docker-compose)

```yaml
services:
  fastapi-app:
    build: .
    ports: ["8000:8000"]
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
    environment:
      - WORKERS=4
      - WORKER_CONNECTIONS=1000
      - MAX_REQUESTS=5000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## 8. Production Deployment Checklist

```bash
#!/bin/bash
# Validasi konfigurasi sebelum deploy
CPU_CORES=$(nproc)
WORKERS=${WORKERS:-4}

if [ $WORKERS -gt $((CPU_CORES * 3)) ]; then
  echo "⚠️ Too many workers ($WORKERS) for $CPU_CORES cores"
  echo "   Recommended: $((CPU_CORES * 2)) for I/O-bound"
fi

TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
echo "Memory: ${TOTAL_MEM}GB | Workers: $WORKERS | Est: $((WORKERS * 100))MB"

# Test config
gunicorn --check-config --workers $WORKERS \
  --worker-class uvicorn.workers.UvicornWorker app:app
```

---

## 9. Perbandingan Performance

| Konfigurasi | CPU Efficiency | Memory | Response Time | Concurrent Capacity |
|:------------|:-------------:|:------:|:-------------:|:------------------:|
| ✅ **Correct (4 workers)** | 90–95% | 200MB | 50–100ms | 4.000 |
| ❌ Nested Workers (16 proc) | 40–60% | 800MB | 200–500ms | 2.000 (degraded) |
| Uvicorn Only (1 proc) | 85–90% | 50MB | 45–80ms | 1.000 |

---

## 10. Key Takeaways

| Aspek | ❌ Wrong | ✅ Right |
|:------|:---------|:---------|
| App code | `uvicorn.run(workers=4)` | Hanya `app = FastAPI()` |
| Worker management | Multi-level nesting | Gunicorn sebagai single orchestrator |
| Worker count | 16 processes untuk 4 core | 4–8 processes untuk 4 core |
| Memory baseline | 800MB+ | 200MB |
| CPU utilization | 40–60% (context switch) | 90–95% |
| `--max-requests` | Tidak pakai | 10.000 + jitter 1.000 |
| `--preload-app` | Tidak pakai | ✅ selalu di production |

---

## Referensi

- Artikel asli: [Mastering Gunicorn and Uvicorn](https://medium.com/@iklobato/mastering-gunicorn-and-uvicorn-the-right-way-to-deploy-fastapi-applications-aaa06849841e) oleh Iklobato
- [[observability-stack-prometheus-grafana]] — tambah metrics & alerting
- [[cicd-guide]] — integrate dengan deployment pipeline
- [[devsecops-pipeline-sast-dast-sbom]] — security scanning sebelum deploy
- [[cicd-shiftleft-shiftright]] — testing strategy untuk FastAPI
---

audited
---
