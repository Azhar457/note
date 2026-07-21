---
tags:
  - systems-architecture
  - linux
  - performance
  - profiling
  - debugging
  - devops
aliases:
  - Linux Performance Debugging Toolkit
  - Linux Perf Toolkit
  - Performance Debugging
status: evergreen
created: 2026-07-21
updated: 2026-07-21
---

# Linux Performance Debugging Toolkit: Strace, Perf, bpftrace, dan System Diagnostics

> [!tip] **Linux Performance Debugging** melibatkan pemantauan metrik perangkat keras, system calls, dan fungsi kernel secara real-time. Memahami penggunaan **strace**, **perf**, dan **bpftrace** memungkinkan administrator dan pengembang melacak latensi reverse proxy (Pingora/Nginx), anomali I/O database RAG, dan spikes CPU pada container homelab secara efisien.

---

## 1. Peta Diagnostik Kinerja Linux (Linux Observability Map)

Untuk mendiagnosis sistem secara efisien, kita harus menggunakan alat yang tepat sesuai dengan komponen kernel/perangkat keras yang dicurigai:

```
                  ┌──────────────────────────────────────────────┐
                  │                 Linux Kernel                 │
                  └──────┬────────────────────┬───────────┬──────┘
                         │                    │           │
      [ Hardware I/O ]   │    [ System Calls ]│    [ CPU Execution ]
        (Disk/Network)   │                    │      (Scheduler)
             │           │                    │           │
     ┌───────┴───────┐   │            ┌───────┴───────┐   │     ┌─────────────┐
     │ iostat, sar   │   │            │ strace        │   │     │ perf record │
     │ tcpdump       │   │            │ bpftrace      │   │     │ top, htop   │
     └───────────────┘   │            └───────────────┘   │     └─────────────┘
                         │                                │
                         └───── [ eBPF Profiling Tools ] ─┘
```

---

## 2. Investigasi System Calls Menggunakan `strace`

`strace` digunakan untuk merekam interaksi antara proses userspace dan kernel Linux dengan menampilkan semua system calls yang dipanggil dan sinyal yang diterima.

### Kasus Penggunaan: Mengapa Reverse Proxy JarsWAF Lambat Melayani Request?

Jalankan `strace` pada PID proses JarsWAF / Pingora, batasi pelacakan hanya untuk I/O dan syscall jaringan, serta catat latensi setiap syscall (`-T`):

```bash
sudo strace -p <PID_JARSWAF> -e trace=network,file -T -o jarswaf_strace.log
```

#### Cara Membaca Output Log (`jarswaf_strace.log`):

```text
epoll_wait(4, [{EPOLLIN, {u32=11, u64=11}}], 1024, 1000) = 1 <0.002144>
accept4(6, {sa_family=AF_INET, sin_port=htons(49554), sin_addr=inet_addr("192.168.1.50")}, [128], SOCK_CLOEXEC) = 12 <0.000108>
read(12, "GET /api/v1/status HTTP/1.1\r\n...", 8192) = 154 <0.005892>
stat("/opt/jarswaf/config.toml", {st_mode=S_IFREG|0644, st_size=2380, ...}) = 0 <0.008912>
```

_Analisis_: Kolom `<0.008912>` menunjukkan syscall `stat` pada file konfigurasi memakan waktu **8.9 milidetik**! Ini mengindikasikan bottleneck I/O disk saat membaca konfigurasi TOML di setiap request. Konfigurasi harus di-cache di memory (`arc-swap` / static cell).

---

## 3. CPU Profiling Menggunakan `perf` (Linux Performance Events)

`perf` mengumpulkan statistik performa perangkat keras (CPU cycle, cache misses) dan perangkat lunak (context switches) menggunakan penghitung internal CPU.

### A. Merekam Profiling CPU JarsWAF

Lakukan sampling pada CPU tempat proses target berjalan dengan frekuensi 99 Hz selama 10 detik:

```bash
sudo perf record -F 99 -p <PID_JARSWAF> -g -- sleep 10
```

### B. Menganalisis Call Graph Terbanyak

Baca hasil profiling secara interaktif:

```bash
sudo perf report --hierarchy -M intel
```

Model visualisasi terbaik dari `perf record` adalah **FlameGraph**. Anda bisa mengonversinya menjadi grafik SVG interaktif:

```bash
git clone https://github.com/brendangregg/FlameGraph.git
sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > jarswaf_cpu_flame.svg
```

FlameGraph akan menunjukkan fungsi mana di Rust (seperti alokasi memori regex matching) yang paling banyak memakan CPU cycles.

---

## 4. Scripting Diagnostik Cepat dengan `bpftrace`

`bpftrace` menggunakan eBPF untuk melakukan instrumentasi tingkat lanjut tanpa mengganggu jalannya sistem produksi (_very low overhead_).

### A. Melacak Latensi Transaksi Database RAG (SQLite / Postgres)

Deteksi durasi waktu proses membaca/menulis blok disk:

```bash
sudo bpftrace -e '
kprobe:vfs_read {
  @start[tid] = nsecs;
}
kretprobe:vfs_read /@start[tid]/ {
  @latency_us = hist((nsecs - @start[tid]) / 1000);
  delete(@start[tid]);
}'
```

Skrip di atas menghasilkan histogram distribusi latensi operasi baca disk sistem dalam mikrodetik (`us`). Sangat krusial untuk melacak overhead pencarian vektor SQLite-Vec.

### B. Melacak Connection Latency Terhadap Reverse Proxy

Menghitung waktu yang dibutuhkan dari penerimaan TCP connection baru (`accept`) hingga pemrosesan request:

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_accept4 {
  @accept_time[tid] = nsecs;
}
tracepoint:syscalls:sys_exit_accept4 /@accept_time[tid]/ {
  @accept_latency_ms = lhist((nsecs - @accept_time[tid]) / 1000000, 0, 50, 1);
  delete(@accept_time[tid]);
}'
```

---

## 5. Ringkasan Cheat Sheet Pemecahan Masalah (Troubleshooting Matrix)

| Masalah               | Alat Utama           | Perintah Cepat                  | Indikasi Sukses                                              |
| --------------------- | -------------------- | ------------------------------- | ------------------------------------------------------------ |
| **CPU Spike**         | `htop`, `perf`       | `perf top -p <PID>`             | Menemukan fungsi bottleneck di stack trace                   |
| **Disk I/O Slowdown** | `iostat`, `iotop`    | `iostat -xz 1 10`               | `%util` mendekati 100% $\rightarrow$ bottleneck disk         |
| **Proxy Latency**     | `bpftrace`, `strace` | `strace -T -p <PID>`            | Cari syscall `epoll_wait` / `read` bernilai $> 50\text{ ms}$ |
| **Memory Leak**       | `valgrind`, `pmap`   | `pmap -x <PID> \| sort -k 3 -n` | Menemukan segmen memory RSS tidak stabil                     |

---

## 🔗 Referensi & Catatan Terkait

- [[jarswaf-internal-architecture-deepdive]] — Menguji Performa Hot Path Proxy JarsWAF
- [[ebpf-runtime-security-auditing]] — SOP Auditing System Calls dengan eBPF kprobe
- [[vector-quantization-hnsw-tuning]] — Optimasi Memory RAM Database Vektor
- [[homelab-proxmox-architecture]] — Monitoring Kinerja CPU Spikes di Proxmox Hypervisor
