---
title: Ebpf Beyond Security
tags:
- cyber-security
- endpoint-detection
- library
created: '2026-05-29'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout
  - code-wrap

---

# 🌐 eBPF BEYOND SECURITY — Revolusi di Semua Layer

> eBPF bukan hanya tools security. Dia adalah **programmable kernel platform** — seperti JavaScript untuk browser, tapi untuk kernel Linux. Hampir setiap domain computing sedang di-disrupt oleh eBPF.

> [!info] Konteks
> Baca [[ebpf-kernel-security|eBPF Security]] dulu untuk fondasi arsitektur. Dokumen ini fokus ke domain di luar security yang jarang dibahas tapi sama revolusionernya.

---

## Peta Domain yang Diubah eBPF

```
                    eBPF sebagai Platform
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
  NETWORKING          OBSERVABILITY        PERFORMANCE
  ──────────          ─────────────        ───────────
  · Gantikan iptables  · Gantikan strace    · CPU profiling
  · Load balancer      · Gantikan tcpdump   · Memory leak
  · Service mesh       · Distributed trace  · GPU workload
  · XDP DDoS           · Language runtime   · Scheduler tune
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         KUBERNETES    ANDROID      WINDOWS
         ──────────    ───────      ───────
         · Gantikan    · Di kernel   · Cross-platform
           kube-proxy    Android     · eBPF for Windows
         · CNI plugin    sejak 2020  · Microsoft invest
         · Policy                     besar-besaran
```

---

## 1 — Networking: Gantikan iptables Sepenuhnya

### Masalah iptables yang Jarang Diketahui

```
iptables adalah teknologi dari tahun 1998.
Di cluster Kubernetes dengan 5000 service:

iptables rules yang dibuat : ~25.000 rules
Waktu update 1 rule        : ~11 detik (harus reload semua!)
CPU overhead               : linier dengan jumlah rules
Debuggability              : sangat susah — rules tidak human-readable

Ini bukan masalah kecil. Di skala besar:
Netflix, Google, Meta tidak bisa pakai iptables.
```

### Solusi eBPF: Cilium + eBPF Maps

```
eBPF approach:
- Rules disimpan dalam eBPF Hash Maps (O(1) lookup)
- Update rule → update map entry → instant, tidak perlu reload
- 5000 service → sama cepatnya dengan 5 service
- Packet processing di XDP level — sebelum stack kernel

Hasil nyata (benchmark Cilium vs iptables):
┌─────────────────────┬──────────────┬────────────────┐
│ Metrik              │ iptables     │ Cilium (eBPF)  │
├─────────────────────┼──────────────┼────────────────┤
│ 5000 service update │ ~11 detik    │ <1ms           │
│ Throughput          │ ~1-2 Mpps    │ 10+ Mpps (XDP) │
│ CPU per 1M packets  │ ~30%         │ ~3%            │
│ Memory (5000 svc)   │ ~100MB rules │ ~20MB maps     │
└─────────────────────┴──────────────┴────────────────┘
```

### Kubernetes: kube-proxy Digantikan

```
kube-proxy tradisional:
→ Komponen Kubernetes yang manage load balancing service
→ Pakai iptables atau IPVS di belakangnya
→ O(n) complexity — makin banyak service, makin lambat

Cilium tanpa kube-proxy:
→ eBPF handles semua service routing
→ O(1) dengan hash map
→ Google GKE, AWS EKS, Azure AKS sudah support Cilium
→ Isovalent (Cilium company) diakuisisi Cisco 2024
```

>[!tip] Plot Twist Industri
>Google telah menggunakan eBPF untuk menggantikan iptables di seluruh infrastruktur internal mereka sejak 2016 — jauh sebelum Cilium populer. Mereka membangun sistem internal bernama **Katran** yang kini open-source dan dipakai Meta untuk load balancing Facebook/Instagram.

---

## 2 — Observability: Gantikan Semua Tools Lama

### Yang Digantikan eBPF

| Tools Lama | Masalah | Pengganti eBPF | Keuntungan |
|---|---|---|---|
| **strace** | Overhead 300-600% — memperlambat proses yang di-trace drastis | bpftrace + kprobe | < 1% overhead, bisa trace production tanpa dampak |
| **tcpdump / Wireshark** | Semua paket di-copy ke user space — overhead besar, tidak scalable | eBPF socket filter + XDP | Hanya copy paket yang relevan, filter di kernel |
| **perf + gprof** | Sampling-based — kehilangan event singkat, tidak bisa trace cross-language | BPF profiler (Parca, Pyroscope) | Continuous profiling, per-event, cross-language |
| **OpenTelemetry SDK** | Harus instrumentasi kode manual — semua service perlu diubah | Pixie, Odigos | Zero-code instrumentation via uprobe |
| **netstat / ss** | Snapshot — tidak bisa lihat yang sudah lewat | bpftrace tcp probes | Real-time + historical, setiap koneksi tercatat |

### Distributed Tracing Tanpa Mengubah Kode

```
Masalah klasik distributed tracing:
Kamu punya 50 microservice → mau tau kenapa request lambat
→ Harus tambah OpenTelemetry ke semua 50 service
→ Rebuild, redeploy, koordinasi semua tim
→ Butuh berbulan-bulan

eBPF approach (Odigos / Pixie):
→ Deploy satu eBPF agent per node
→ Hook ke ssl_read/ssl_write di OpenSSL (uprobe)
→ Otomatis dapat trace end-to-end TANPA ubah kode
→ Mendukung: Go, Java, Python, Node.js, Ruby, .NET
→ Setup: 10 menit

Cara kerjanya (uprobe magic):
ssl_write dipanggil → eBPF intercept SEBELUM enkripsi
→ dapat plaintext data + context (service, trace ID, latency)
→ inject trace header → teruskan ke service berikutnya
→ reconstruct full distributed trace di user space
```

### Language Runtime Introspection

```
Ini yang paling mind-blowing: eBPF bisa "masuk" ke dalam
runtime bahasa pemrograman tanpa mengubah kode:

Python:
→ Uprobe pada PyEval_EvalFrameEx
→ Lihat setiap function call Python yang terjadi
→ Flamegraph Python tanpa -fno-omit-frame-pointer
→ Detect GIL contention (kenapa Python multi-thread lambat)

Java / JVM:
→ Uprobe pada JVM interpreter + JIT compiled methods
→ Lihat garbage collection pause secara real-time
→ Detect memory leak pattern

Golang:
→ Uprobe pada goroutine scheduler
→ Lihat goroutine blocking + contention
→ Detect goroutine leak

Node.js:
→ Uprobe pada V8 engine
→ Lihat event loop lag
→ Detect callback hell yang nyebabkan latency
```

---

## 3 — Performance Engineering: Invisible Profiler

### Continuous Profiling di Production

```
Masalah profiling tradisional:
"Kita tidak bisa profile di production karena overhead terlalu besar"
→ Pakai staging, hasilnya tidak representative
→ Bug production tidak bisa di-reproduce di staging

eBPF solution (Parca, Pyroscope, Grafana Pyroscope):
→ Overhead < 1% CPU
→ Bisa jalan 24/7 di production
→ Flamegraph per service, per endpoint, per user
→ "Kenapa request user A lebih lambat dari user B?"
   → bisa dijawab dengan per-request profiling

Cara deployment:
DaemonSet di setiap node Kubernetes
→ Otomatis profile semua container
→ Zero config per application
→ Hasilnya tersimpan + bisa di-query historical
```

### CPU Scheduler Optimization

```
eBPF bisa hook ke Linux CPU scheduler (sched_switch, dll)

Use case nyata (Google, Meta):
→ Monitor berapa lama task menunggu di run queue
→ Detect "noisy neighbor" — container yang steal CPU dari yang lain
→ Custom scheduling hints via eBPF → latency berkurang 30-40%

Meta menggunakan eBPF untuk:
→ Scuba (internal observability) → track scheduling latency
→ Tupperware (container platform) → per-container CPU accounting
→ Hasil: penghematan ~20% server di beberapa workload
```

### Memory Subsystem Observability

```
eBPF bisa hook ke:
- Allocator (malloc, kmalloc)
- Page fault handler
- OOM killer
- Swap subsystem
- NUMA migration

Use case:
→ Detect memory leak: "proses X allocate tapi tidak free di line 247"
→ Identify NUMA inefficiency: "data di NUMA node 0 tapi CPU di NUMA node 1"
→ Predict OOM sebelum terjadi: "rate of allocation > rate of free"

Tools: memray (Python), bpftrace scripts, Tetragon (Cilium)
```

---

## 4 — Kubernetes & Cloud Native: Fondasi Baru

### Service Mesh Tanpa Sidecar

```
Sidecar pattern (Istio tradisional):
┌──────────────────────────┐
│ Pod                      │
│  ┌──────────┐  ┌───────┐ │
│  │ App      │  │ Envoy │ │
│  │ Container│  │Sidecar│ │
│  └──────────┘  └───────┘ │
└──────────────────────────┘

Masalah:
- 2x container per pod
- 100-500MB RAM overhead per pod
- Latency tambahan setiap request
- 1000 pod = 1000 Envoy proxy

eBPF Service Mesh (Cilium Mesh, Istio Ambient Mode):
┌──────────────┐
│ Pod          │
│  ┌──────────┐│
│  │ App only ││
│  └──────────┘│
└──────────────┘
     eBPF di kernel node — satu instance untuk semua pod

Keuntungan:
- Zero sidecar → resource savings masif
- mTLS di kernel level → latency berkurang
- Policy enforcement tanpa ubah aplikasi
- Google + Istio sudah adopt "ambient mode" (sidecar-less)
```

### Network Policy yang Efisien

```
NetworkPolicy Kubernetes dengan iptables:
→ 1 policy = puluhan iptables rules
→ Update policy = reload semua rules
→ Tidak support Layer 7 (hanya L3/L4)

NetworkPolicy dengan Cilium eBPF:
→ Policy disimpan dalam eBPF maps
→ Update instan (O(1))
→ Support Layer 7: "allow POST /api/v1/users tapi block DELETE"
→ Identity-based: "service A boleh akses service B, bukan berdasarkan IP"
   (IP berubah di Kubernetes — identity-based lebih reliable)
```

---

## 5 — Android: eBPF Sudah Ada di Smartphone Kamu

```
Fakta yang jarang diketahui:
Google mengintegrasikan eBPF ke Android kernel sejak Android 9 (2018)
Kernel Android adalah Linux kernel — eBPF berjalan di dalamnya

Penggunaan eBPF di Android:
1. Network stats per-app
   → "Aplikasi Instagram menggunakan 50MB data hari ini"
   → Diimplementasi via eBPF, bukan polling
   → Lebih akurat, lebih efisien

2. Battery usage tracking
   → Siapa yang drain battery? eBPF track setiap wakelock
   → Battery Historian pakai data dari eBPF hooks

3. Thermal management
   → Monitor CPU frequency + temperature via eBPF
   → Throttle aplikasi yang berlebihan tanpa restart

4. Security (Android Vendor Initiative)
   → Deteksi malware di kernel level
   → Lebih susah di-bypass dibanding user space scanner

Implikasi:
→ Teknik eBPF yang dipelajari di Linux berlaku langsung di Android
→ Android security research bisa leverage eBPF
→ Custom Android kernel dengan eBPF program = area riset menarik
```

---

## 6 — Windows: Microsoft Serius dengan eBPF

```
2021: Microsoft announce eBPF for Windows
→ Open source: github.com/microsoft/ebpf-for-windows
→ Bukan port Linux — implementasi native di Windows kernel

Arsitektur:
eBPF bytecode → Windows eBPF verifier → JIT → Windows kernel hooks

Hooks yang tersedia di Windows eBPF:
- Network filter (WFP — Windows Filtering Platform)
- Socket operations
- Process/thread creation
- Registry operations (Windows-specific hook!)

Use case yang sudah production:
- Microsoft Defender menggunakan eBPF untuk EDR hooks
- Azure menggunakan eBPF untuk network acceleration di VM
- Windows Security Center → beberapa komponen migrasi ke eBPF

Implikasi untuk security researcher:
→ Teknik eBPF = berlaku cross-platform (Linux + Windows + Android)
→ Satu paradigma, tiga OS besar
→ Ini kenapa eBPF disebut "the future of kernel programming"
```

---

## 7 — Developer Tools: Debug yang Tidak Mungkin Jadi Mungkin

### Time Travel Debugging

```
Masalah: bug yang hanya muncul sekali setiap 1000 request
→ Tidak bisa reproduce
→ Logging tidak cukup detail
→ Debugger terlalu invasif

eBPF solution:
→ Program eBPF record semua syscall, function calls, memory access
→ Simpan dalam ring buffer (circular)
→ Saat bug terjadi → dump buffer → punya "rekaman" semua yang terjadi
   sebelum bug

Implementasi: rr (Mozilla) + eBPF, Lares (startup yang fokus di ini)

Analogi: dashcam yang terus merekam, simpan 30 detik terakhir
         saat terjadi kecelakaan (bug) → rekaman tersedia
```

### Chaos Engineering yang Presisi

```
Chaos engineering tradisional:
→ Kill pod, inject latency di network level
→ Kasar, tidak bisa target kondisi spesifik

eBPF chaos engineering (Chaosblade, Chaos Mesh):
→ "Inject latency 100ms HANYA untuk request dari user ID tertentu"
→ "Simulasi disk error HANYA untuk file di /var/log/*"
→ "Kill koneksi database HANYA setelah 1000 query"
→ Presisi surgical — tidak perlu matikan seluruh service

Cara kerja:
eBPF hook ke syscall yang relevan
→ Intercept berdasarkan kondisi spesifik
→ Inject failure sesuai parameter
→ Zero impact ke request lain
```

---

## 8 — AI/ML Infrastructure: Frontier Baru

```
GPU Observability (area yang sangat baru):

Masalah:
GPU adalah black box — tidak ada visibility apa yang terjadi di dalamnya
"GPU utilization 80%" — tapi 80% compute atau 80% memory transfer?

eBPF approach yang sedang dikembangkan:
→ Hook ke NVIDIA GPU driver (kernel module)
→ Trace setiap CUDA kernel launch
→ Lihat: compute time vs memory transfer time per operation
→ Detect "GPU idle while waiting for CPU data"

Tools:
- NVIDIA Nsight (traditional, overhead besar)
- eBPF-based GPU profiler (masih eksperimental, startup space)
- Tetragon + GPU hooks (Cilium roadmap)

Inference Optimization:
→ eBPF monitor memory bandwidth consumption per model layer
→ Detect bottleneck: "attention layer ini memory-bound, bukan compute-bound"
→ Inform quantization decision (mana yang worth di-quantize)

Status: sangat early, sangat menarik, hampir tidak ada orang di sini
```

---

## Ringkasan — eBPF vs Tradisional per Domain

| Domain | Tradisional | eBPF | Improvement |
|---|---|---|---|
| **Firewall/NAT** | iptables (1998) | XDP + eBPF maps | 10x throughput, O(1) updates |
| **Load Balancing** | IPVS, Nginx | Katran, Cilium | Sub-microsecond latency |
| **Service Mesh** | Sidecar (Envoy) | Sidecar-less eBPF | ~90% resource savings |
| **Distributed Tracing** | SDK instrumentation | uprobe auto-trace | Zero code change |
| **CPU Profiling** | perf sampling | eBPF continuous | Per-event, < 1% overhead |
| **Security Monitoring** | auditd, kernel module | Falco eBPF probe | 10x lebih efisien, zero crash risk |
| **Network Stats (Android)** | Polling + proc/net | eBPF netd hooks | Real-time, akurat per-app |
| **Windows EDR** | Kernel callbacks | eBPF for Windows | Portable, sandboxed |
| **Chaos Engineering** | Service kill | eBPF fault injection | Surgical precision |

---

## Yang Belum Ada yang Garap — Peluang Riset

```
1. eBPF for GPU Workload Visibility
   → CUDA kernel trace via eBPF hooks di NVIDIA driver
   → Hampir tidak ada paper yang publish

2. eBPF + WebAssembly (WASM)
   → WASM VM berjalan di user space
   → eBPF bisa observe setiap WASM function call via uprobe
   → Security sandbox untuk WASM + eBPF monitoring

3. eBPF for Edge Computing (RISC-V IoT)
   → Resource-constrained eBPF VM untuk edge node
   → Monitoring tanpa overhead agent tradisional

4. eBPF for Quantum Hardware Emulator
   → Track resource usage per quantum gate simulation
   → Optimize qubit simulation scheduling

5. eBPF + LLM Inference
   → Monitor memory bandwidth per transformer layer
   → Inform dynamic quantization decision real-time
```

---

>[!warning] Satu Hal yang eBPF TIDAK Bisa Lakukan
>eBPF tidak bisa gantikan semua hal:
>- **RTOS** (VxWorks, Green Hills) — tidak support, mungkin tidak akan pernah
>- **Bare-metal microcontroller** (Arduino, STM32 tanpa Linux) — tidak relevant
>- **Truly air-gapped system** — eBPF butuh kernel Linux yang update
>- **Firmware sebelum kernel boot** — eBPF for UEFI masih eksperimental
>
>Untuk 99% sistem Linux modern dari smartphone sampai data center: eBPF adalah masa kini dan masa depan.

---

## 🔗 Lihat Juga

- [[ebpf-kernel-security|eBPF Security]] — fondasi arsitektur + security use case
- [[ids-ips-waf-nsm-comparison|IDS/IPS/WAF]] — Falco dan Cilium dalam konteks stack
- [[cloud-infrastructure|Cloud Infrastructure]] — Kubernetes + service mesh
- [[computer-science-foundations|OS Internals]] — kernel, Ring 0, syscall sebagai fondasi
- [[embedded-systems|Embedded Systems]] — eBPF on RISC-V untuk IoT
- [[hierarchy-ai-levels|AI Levels]] — eBPF untuk GPU/ML infrastructure
- [[master-index|Master Index]]

---

*eBPF Beyond Security | Networking · Observability · Performance · Android · Windows · AI/ML · Peluang Riset*