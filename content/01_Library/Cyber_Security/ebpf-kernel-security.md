---
tags:
  - eBPF
  - kernel
  - observability
  - security
  - networking
  - linux
  - future-tech
  - RISC-V
  - post-quantum
aliases:
  - eBPF
  - Extended Berkeley Packet Filter
  - eBPF Security
created: 2026-05-29
status: operational
cssclasses:
  - wide-table
---

# 🔬 eBPF — Revolusi Observability & Security dari Dalam Kernel

> **Satu kalimat:** eBPF memungkinkan kamu menjalankan program sandboxed di dalam kernel Linux tanpa mengubah kode kernel dan tanpa kernel module — performa setara kernel module, keamanan setara user space.

> [!info] Prasyarat
> Pastikan sudah paham [[computer-science-foundations|OS Internals]] (CPU Ring, kernel module, syscall) dan [[00_Atlas/hierarchy-operating-systems|Hierarki OS]] (Level 0–8). eBPF beroperasi di Ring 0, bahkan bisa menyentuh Ring -1 (hypervisor) lewat ekstensi modern.

---

## Daftar Isi

- [[#Analogi Sebelum Teknis]]
- [[#Arsitektur eBPF — Cara Kerjanya]]
- [[#Mengapa eBPF Lebih Optimal]]
- [[#eBPF di Hierarki OS Level 0–8]]
- [[#Studi Kasus Nyata]]
- [[#Masa Depan — eBPF + RISC-V + Post-Quantum]]
- [[#Roadmap Belajar & Praktik]]

---

## Analogi Sebelum Teknis

```
Kernel = ruang server super ketat.
Akses masuk biasanya hanya untuk:

Karyawan tetap (Kernel Module)
→ Akses penuh
→ Kalau error = server crash (kernel panic / BSOD)
→ Susah diaudit, perlu recompile tiap versi kernel

eBPF = drone kecil yang bisa terbang di dalam ruangan
→ Bisa observe dan bahkan beri perintah
→ Sudah di-sandbox oleh Verifier
→ Kalau error = drone mati sendiri, ruangan aman
→ Tidak perlu izin "karyawan tetap"
```

---

## Arsitektur eBPF — Cara Kerjanya

```
[Kode eBPF ditulis dalam C]
        │
        ▼
[LLVM/Clang compile → Bytecode eBPF]
        │
        ▼
[VERIFIER KERNEL] ←── Gatekeeper utama
        │
   ┌────┴────┐
   │         │
  AMAN     TIDAK AMAN
   │         │
   ▼         ▼
[JIT Compiler]  [Ditolak, tidak pernah jalan]
   │
   ▼
[Kode Native — performa mendekati kernel asli]
   │
   ▼
[HOOKS — titik di mana eBPF dipasang]
   ├── kprobe    : hook fungsi kernel apapun
   ├── uprobe    : hook fungsi user space (misal: OpenSSL)
   ├── tracepoint: event yang sudah didefinisikan kernel
   ├── XDP       : di level NIC driver, sebelum stack network
   ├── TC        : traffic control, setelah XDP
   └── socket    : filter socket per-proses
   │
   ▼
[MAPS — shared memory antara kernel dan user space]
        │
        ▼
[User Space Tools: bpftool, libbpf, Cilium, Falco, Pixie...]
```

### 4 Komponen Kunci

| Komponen         | Fungsi                                                                                 | Kenapa Penting                                                                                   |
| ---------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Verifier**     | Pastikan program tidak infinite loop, tidak akses memori sembarangan, selalu terminate | Ini yang membuat eBPF aman — program yang tidak lolos verifier tidak akan pernah jalan di kernel |
| **JIT Compiler** | Ubah bytecode eBPF ke instruksi mesin native                                           | Performa mendekati kode kernel asli, jauh lebih cepat dari interpreter                           |
| **Hooks**        | Titik di kernel tempat eBPF dipasang — syscall, fungsi jaringan, scheduler, dll        | Fleksibilitas penuh: bisa observe hampir semua yang terjadi di kernel                            |
| **Maps**         | Struktur data bersama kernel ↔ user space (hash map, array, ring buffer, dsb)          | Cara eBPF program "bicara" ke luar — kirim data ke user space tanpa overhead besar               |

---

## Mengapa eBPF Lebih Optimal

### Perbandingan dengan Pendekatan Tradisional

| Pendekatan                                                   | Kelebihan                                          | Kelemahan                                                                     | Performa                      | Keamanan                                   |
| ------------------------------------------------------------ | -------------------------------------------------- | ----------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------ |
| **Kernel Module**                                            | Akses penuh, sangat fleksibel                      | Crash kernel jika ada bug, perlu recompile per versi kernel, susah diaudit    | ⚡ Sangat tinggi              | 💀 Sangat rendah (satu bug → kernel panic) |
| **Sidecar Proxy** _(Istio, Envoy)_                           | Mudah deploy, language agnostic                    | Resource overhead besar (CPU+RAM), latency tambahan, kompleksitas operasional | 🟡 Sedang (overhead 5–15%)    | 🟡 Sedang                                  |
| **Traditional Monitoring Agent** _(node exporter, telegraf)_ | Sederhana, banyak support                          | Banyak proses, sampling loss — tidak capture per-event                        | 🟠 Rendah-Sedang              | 🟡 Sedang                                  |
| **eBPF**                                                     | Aman, overhead sangat rendah, per-event, satu agen | Kurva belajar curam, butuh kernel modern (4.9+ basic, 5.7+ full feature)      | ⚡ Sangat tinggi (JIT native) | ✅ Sangat tinggi (sandbox + verifier)      |

### Data Kuantitatif

```
Overhead CPU:
  eBPF network observability  : < 1% pada throughput 10Gbps
  Sidecar Envoy               : 10–20% overhead

Packet Processing (XDP):
  eBPF XDP                   : 10+ Mpps per core
  DPDK (user space)           : 50+ Mpps tapi butuh dedicated core
  iptables                    : ~1-2 Mpps, lewat seluruh stack kernel

Memory footprint:
  eBPF program                : maks 1MB per program
  Sidecar (Envoy/Istio)       : 100–500MB per instance

Event capture:
  eBPF                        : setiap syscall, 1M+ events/detik tanpa sampling
  auditd tradisional           : sampling + overhead CPU signifikan
```

### eBPF vs Kernel Module — Langsung

| Aspek                      | Kernel Module                            | eBPF                                                                              |
| -------------------------- | ---------------------------------------- | --------------------------------------------------------------------------------- |
| **Crash risk**             | Tinggi — satu bug → seluruh kernel panic | Nol — program ditolak verifier jika tidak aman                                    |
| **Upgrade kernel**         | Wajib recompile module tiap versi        | CO-RE (Compile Once, Run Everywhere) — satu binary jalan di berbagai versi kernel |
| **Auditability**           | Manual review source code                | Verifier otomatis + bisa dibatasi via `cap_bpf` capability                        |
| **Deployment**             | `insmod`/`rmmod` + kernel signing        | `bpftool prog load` atau auto-load via systemd                                    |
| **Use case observability** | Bisa, tapi overkill berbahaya            | Dirancang untuk ini — ini use case utama eBPF                                     |

> [!warning] Kesimpulan Tegas
> Tidak ada alasan menulis kernel module baru untuk observability atau security monitoring di era eBPF. eBPF mencapai performa yang sama dengan keamanan dan kemudahan deployment yang jauh lebih tinggi.

---

## eBPF di Hierarki OS Level 0–8

| Level OS                                          | Status eBPF                                                         | Use Case Relevan                                                                                                                                     |
| ------------------------------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Level 0–2** _(Consumer — Privacy OS)_           | ✅ Tersedia di kernel Linux 4.9+, tapi tidak dipakai aplikasi biasa | Belajar eBPF di Linux Mint / Ubuntu. `bpftrace` untuk debug one-liner, `opensnoop` untuk lihat file yang dibuka proses                               |
| **Level 3–4** _(Security Research — Hardened OS)_ | ✅ Medan perang eBPF                                                | Falco untuk runtime security, Pixie untuk observability microservice, Hubble untuk network visibility. Qubes OS: eBPF di dom0 untuk monitor semua VM |
| **Level 5–6** _(Enterprise — Certified OS)_       | ✅ RHEL / AlmaLinux / Rocky dengan kernel 5.7+                      | DISA STIG RHEL sudah cover konfigurasi eBPF aman. FIPS 140-2: eBPF bisa panggil modul crypto FIPS-certified via helper                               |
| **Level 6 — Militer**                             | ✅ Justru sangat ideal                                              | "No code change" adalah persyaratan keamanan di sistem classified. eBPF memberi visibility **tanpa modifikasi kernel**                               |
| **Level 7–8** _(Compartmented — Air-Gapped)_      | ⚠️ Sebagian                                                         | Green Hills INTEGRITY & VxWorks belum support (RTOS proprietary). Tapi eBPF for Windows dan eBPF for macOS sudah ada                                 |

> [!tip] Plot Twist Militer
> NSA punya proyek internal **"BPF for Trusted Computing"** — menggabungkan eBPF dengan TPM (Trusted Platform Module). Hasilnya: attestasi jarak jauh bahwa kernel berjalan dengan program eBPF tertentu — bisa verifikasi "tidak ada rootkit" dari remote server tanpa fisik mengakses mesin.

---

## Studi Kasus Nyata

### A — Observability Tanpa Instrumentasi (Pixie)

```
Masalah:
Ingin lihat request HTTP antara microservices
tanpa menambah kode atau sidecar ke aplikasi

Cara lama (Traditional):
→ Tambah OpenTelemetry SDK ke setiap service
→ Tambah exporter
→ Rebuild dan redeploy semua image
→ Butuh koordinasi dengan semua tim

Cara eBPF (Pixie):
→ Deploy satu agen per node
→ Pixie hook uprobe pada ssl_read/ssl_write di OpenSSL
→ Hook kprobe pada fungsi TCP kernel
→ Dapat: flamegraph, service map, latency per endpoint
→ Tanpa mengubah satu baris kode aplikasi
```

### B — Runtime Security (Falco)

```
Masalah:
Deteksi reverse shell atau container escape real-time

Cara lama:
→ Kernel module (risiko crash kernel)
→ auditd (overhead CPU besar, lambat)

Cara eBPF (Falco modern probe):
→ Hook syscall: execve, open, connect, dll
→ Ketika container lakukan:
   execve("/bin/sh") → connect(attacker_ip:4444)
→ Falco trigger alert dalam < 1ms
→ Zero crash risk, overhead minimal
```

### C — DDoS Mitigation (Cilium + XDP)

```
Masalah:
Layanan publik kena DDoS 1 juta paket per detik

Cara lama (iptables):
→ Paket masih lewat seluruh stack kernel Linux
→ Overhead signifikan, throughput terbatas
→ ~1-2 Mpps kemampuan maksimal

Cara eBPF XDP:
→ Program eBPF ditempel di driver NIC
→ Inspect dan drop paket SEBELUM masuk stack kernel
→ Di level hardware, bukan software
→ 10+ Mpps per core
→ Latency sub-mikrodetik
```

---

## Masa Depan — eBPF + RISC-V + Post-Quantum

### eBPF on RISC-V

```
Status:
Kernel Linux 6.1 sudah support penuh eBPF untuk RISC-V

Mengapa penting:
RISC-V diprediksi 25% pasar IoT dan embedded pada 2030
Open instruction set — tidak ada vendor lock-in (beda dari ARM/x86)

Peluang konkret:
Firmware untuk device RISC-V bisa menyertakan eBPF VM
→ Remote debugging dan security patching
→ Tanpa perlu full OTA update
→ Sangat relevan untuk embedded + IoT security

Hardware entry point:
Sipeed Lichee RV (~$20) → install kernel 6.1+ → bisa compile + load eBPF
```

### eBPF + Post-Quantum Cryptography

```
Konsep:
eBPF bisa memverifikasi tanda tangan PQC (ML-DSA / SLH-DSA)
di dalam kernel sebelum mengizinkan load program eBPF

Artinya:
Hanya program eBPF yang ditandatangani dengan kunci post-quantum
yang bisa jalan di kernel

Kenapa relevan:
Quantum computer di masa depan bisa memalsukan tanda tangan RSA/ECC
Dengan PQC signing → program eBPF tetap terverifikasi bahkan di era quantum

Status:
Masih eksperimental — belum ada implementasi production
Ini adalah area riset yang belum ada yang fully explore
```

### eBPF for UEFI (Pre-Boot Security)

```
Konsep:
Program eBPF berjalan di pre-boot environment (UEFI)

Use case:
Deteksi UEFI rootkit (seperti LoJax, MoonBounce, CosmicStrand)
SEBELUM OS boot → sebelum rootkit sempat aktif

Status:
Proyek eksperimental — belum production ready
Tapi arahnya jelas: eBPF turun ke Ring -2 / Pre-Boot level
```

---

## Roadmap Belajar & Praktik

### Fase 1 — Hello eBPF (Hari Ini, 10 Menit)

```bash
# Install bpftrace (Linux Mint / Ubuntu)
sudo apt install bpftrace

# One-liner 1: lihat setiap file yang dibuka oleh setiap proses
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_open {
  printf("%s membuka %s\n", comm, str(args->filename));
}'

# One-liner 2: lihat siapa yang lakukan nanosleep (proses idle)
sudo bpftrace -e 'kprobe:do_nanosleep {
  printf("sleep! PID: %d, nama: %s\n", pid, comm);
}'

# One-liner 3: monitor koneksi TCP baru
sudo bpftrace -e 'kprobe:tcp_connect {
  printf("connect: %s (PID %d)\n", comm, pid);
}'
```

### Fase 2 — Tools eBPF Production (Minggu Ini)

```bash
# Install BCC tools (koleksi tools eBPF siap pakai)
sudo apt install bpfcc-tools linux-headers-$(uname -r)

# opensnoop — lihat semua file yang dibuka
sudo opensnoop-bpfcc

# execsnoop — lihat semua proses yang dieksekusi
sudo execsnoop-bpfcc

# tcptracer — trace semua koneksi TCP
sudo tcptracer-bpfcc

# biolatency — latency disk I/O histogram
sudo biolatency-bpfcc
```

### Fase 3 — Deploy Falco (Security Monitoring)

```bash
# Falco dengan eBPF driver (modern probe)
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --set driver.kind=ebpf \
  --set falcosidekick.enabled=true

# Default rule yang sudah ada:
# - Shell di dalam container
# - Modifikasi /etc/passwd
# - Koneksi ke IP mencurigakan
# - Privilege escalation attempt
```

### Fase 4 — Cilium (Networking + Security)

```bash
# Install Cilium di Kubernetes cluster
cilium install

# Hubble — network observability di atas Cilium
cilium hubble enable
hubble observe --follow

# Lihat semua traffic antar pod secara real-time
# Termasuk yang diblokir oleh NetworkPolicy
```

### Fase 5 — Tulis Program eBPF Sendiri (libbpf)

```c
// hello_ebpf.c — program eBPF minimal
// Hook ke syscall execve, print setiap proses yang dieksekusi

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("tracepoint/syscalls/sys_enter_execve")
int hello(void *ctx) {
    bpf_printk("Program baru dieksekusi! PID: %d\n",
               bpf_get_current_pid_tgid() >> 32);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";

// Compile:
// clang -O2 -target bpf -c hello_ebpf.c -o hello_ebpf.o
// Load:
// sudo bpftool prog load hello_ebpf.o /sys/fs/bpf/hello
```

---

## Quick Reference — Pilih Tool Berdasarkan Kebutuhan

| Kebutuhan                                      | Tool eBPF        | Alternatif Lama                                 |
| ---------------------------------------------- | ---------------- | ----------------------------------------------- |
| **Security: deteksi anomali runtime**          | Falco            | auditd (lebih berat), kernel module (berbahaya) |
| **Networking: observability microservice**     | Pixie, Hubble    | Sidecar Envoy (lebih berat)                     |
| **Networking: service mesh + security policy** | Cilium           | Istio + iptables (overhead tinggi)              |
| **Performance: profiling CPU/memory**          | Parca, Pyroscope | perf (lebih susah), dtrace                      |
| **DDoS mitigation: packet drop cepat**         | XDP (via Cilium) | iptables (lebih lambat)                         |
| **Debug: one-liner investigasi**               | bpftrace         | strace (overhead besar), gdb                    |
| **Security: monitor semua syscall**            | Tracee (Aqua)    | auditd + plugin                                 |

---

> [!tip] Topik Riset yang Belum Ada yang Garap
> "Post-Quantum Verified eBPF Programs untuk Firmware Air-Gapped Systems" — gabungkan ML-DSA signing (NIST PQC standard 2024) dengan eBPF program verification, deploy di pre-boot UEFI environment.
>
> Ini nyambung langsung ke: [[01_Library/Cyber_Security/cryptography-biometrics|Kriptografi Post-Quantum]] + [[00_Atlas/hierarchy-operating-systems|OS Hierarki Level 7-8]] + [[01_Library/Fundamentals/computer-science-foundations|Computer Architecture Ring -2]]. Belum ada yang publish paper tentang kombinasi ini.

---

## 🔗 Lihat Juga

- [[computer-science-foundations|OS Internals]] — Kernel module, Ring 0, syscall sebagai fondasi
- [[01_Library/Fundamentals/computer-science-foundations|Computer Architecture]] — CPU Ring, Intel ME, hypervisor
- [[00_Atlas/hierarchy-operating-systems|Hierarki OS]] — posisi eBPF di setiap level OS
- [[01_Library/Cyber_Security/ids-ips-waf-nsm-comparison|IDS/IPS/WAF Comparison]] — Falco dan Cilium dalam konteks stack security
- [[01_Library/Cyber_Security/purple-team-osi-killchain|Purple Team Kill-Chain]] — eBPF sebagai detection layer
- [[01_Library/Cyber_Security/cryptography-biometrics|Kriptografi Post-Quantum]] — ML-DSA untuk future eBPF signing
- [[01_Library/AI_Systems/embedded-systems|Embedded Systems]] — eBPF on RISC-V untuk IoT
- [[index|Master Index]]

---

_eBPF | Extended Berkeley Packet Filter · Ring 0 Sandbox · Falco · Cilium · XDP · RISC-V · Post-Quantum · Masa Kini dan Masa Depan Linux Security_
