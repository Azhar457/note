---
title: Site Reliability Engineering (C Context)
tags: [programming, c, reliability, sre]
aliases: [site-reliability-engineering]
---
# Site Reliability Engineering — Catatan (Konteks C/System)

SRE berfokus pada keandalan layanan produksi (SLO, error budget, otomatisasi, incident management) — lihat juga [[sre-practices-and-slo]] untuk overview lengkap. Catatan ini spesifik untuk sistem yang dibangun dengan C/system-level: daemon, networking, embedded, kernel-adjacent — di mana keandalan berarti: tidak crash, tidak leak, tidak hang, responsive.

## Keandalan di Kode C (System-Level)

### 1. Error Handling Wajib
- **Selalu cek return**: malloc, fopen, socket, pthread_* — jangan abaikan (lih. [[nodiscard]] analog).
- **Errno handling**: simpan errno segera (fungsi lain bisa menimpanya), gunakan `strerror_r` (thread-safe, bukan strerror).
- **Partial failure**: fungsi yang mengerjakan banyak langkah — jika langkah 3 gagal, state sudah berubah; kembalikan status yang jelas + cleanup.

```c
int read_config(const char* path, Config* out) {
    FILE* f = fopen(path, "r");
    if (!f) return -errno;
    // ...
    if (fclose(f) != 0) return -errno;  // error on close (flush!)
    return 0;
}
```

### 2. Memory & Resource Management
- **Ownership yang jelas**: siapa yang free? (comment/strategy — arena allocator untuk sistem lama).
- **RAII-ish cleanup**: `goto cleanup` pattern (single exit) — bukan goto spaghetti, tapi pattern resource cleanup.
- **Arena/region allocator** untuk request/connection lifecycle — free semuanya sekali (menghindari leak per-code-path).
- **Leak detection**: ASan/LSan di CI, valgrind (dev), heaptrack.

### 3. Concurrency
- **Thread-safe errno** (makro per-thread), `strtok_r` bukan strtok, `localtime_r`.
- **Lock discipline**: lock order konsisten (hindari deadlock), RAII lock (pthread mutex wrapper), tidak pegang lock saat I/O blocking.
- **Signal safety**: hanya async-signal-safe functions di handler (write, sig_atomic_t) — jangan printf/malloc.
- **Atomics** (C11 `<stdatomic.h>`) untuk flag/shared counters, bukan volatile.

### 4. Timeouts & Liveness
- **Socket timeouts wajib** (SO_RCVTIMEO/SO_SNDTIMEO, poll/select dengan timeout, nonblocking + epoll).
- **Watchdog**: thread monitor untuk worker (heartbeat); restart daemon jika hang.
- **Graceful shutdown**: sinyal SIGTERM → stop accept → drain connections → cleanup → exit.
- **Idempotency**: restart tidak meninggalkan state korup (lock files, pid files, journal).

### 5. Logging & Observability
- Log structured (JSON lines) ke stderr/stdout → collector.
- Log level: debug/info/warn/error; jangan log rahasia (token).
- **Metrics**: export counters/gauges (Prometheus text format via endpoint) — request count, latency histogram, error count, queue depth.
- **Health endpoint**: HTTP (atau socket) `/healthz` — process up + deps (DB, upstream) status.
- **Core dumps**: konfigurasi & retensi (systemd-coredump) untuk postmortem crash.

### 6. Build & Deployment (C-Specific)
- **Reproducible build**: pin compiler + flags, `-O2 -g3`, deterministic (SOURCE_DATE_EPOCH).
- **Sanitizers di CI**: ASan, UBSan, (ThreadSanitizer untuk thread-heavy) — fail on finding.
- **Static analysis**: clang-tidy, cppcheck, Coverity (optional).
- **Package**: RPM/deb via packaging (rpmbuild/debuild), versioning semver; atomik update (symlink swap).
- **A/B & canary**: dua versi service, traffic split (LB), observability sebelum cutoff.

## SLO untuk Service C (Contoh)

| SLI | SLO |
|-----|-----|
| Availability (healthz 200) | 99.9% / bulan |
| Latency p95 (request) | < 150ms |
| Error rate (5xx) | < 0.1% |
| Crash rate (restart/24h) | < 1 restart / service / hari |
| Leak rate (RSS growth) | < 10MB / jam (alert) |

Implementation: Prometheus + Grafana; Alertmanager (burn rate); runbook untuk tiap alert.

## Incident Response (System-Level)

1. **Severity** — Sev1 (layanan mati), Sev2 (degradasi), Sev3 (minor, batch).
2. **On-call rotation** — engineer + runbook; escalation.
3. **Postmortem** — timeline, root cause (5 whys), action items; tanpa blame.
4. **Common C failure modes**:
   - **Deref NULL** — fix + ASan; cover dengan unit test.
   - **UAF (use-after-free)** — ASan; ownership doc.
   - **Race** (data race) — TSan; mutex/atomic.
   - **FD leak** — `lsof -p`, /proc/pid/fd; wrapper close-on-exec.
   - **Zombie process** — reap SIGCHLD; double-fork.
   - **Stack overflow** (recursive) — ulimit -s, review; watchdog pada thread.

## Runtime Deployment (Systemd Unit)

```ini
[Unit]
Description=daemon service
After=network.target

[Service]
ExecStart=/usr/local/bin/daemon --config /etc/daemon.conf
Restart=on-failure
RestartSec=3
LimitNOFILE=65536
LimitCORE=infinity
WatchdogSec=30          # systemd watchdog (sd_notify WATCHDOG=1)
User=daemon
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/var/lib/daemon

[Install]
WantedBy=multi-user.target
```

Systemd: auto-restart, watchdog, sandboxing dasar (ProtectSystem, NoNewPrivileges), log via journalctl.

## Checklist

- [ ] Semua return error di-cek (malloc/socket/file)?
- [ ] ASan/UBSan/TSan di CI (fail on finding)?
- [ ] Timeout & graceful shutdown diimplementasikan?
- [ ] Log structured + metrics + healthz?
- [ ] Watchdog & auto-restart (systemd)?
- [ ] Resource limits (FD, core) di-set?
- [ ] Postmortem teruji (tabletop/crash drill)?
- [ ] Build reproducible + versioned?



## Failure Injection Testing (Chaos untuk C Service)

1. **FD exhaustion** — `ulimit -n 32` lalu jalankan load; verifikasi error handling (jangan crash).
2. **Memory limit** — systemd MemoryMax=64M; amati OOM behavior (restart clean? leak?).
3. **Network drop/blackhole** — `tc netem loss 100%` atau firewall drop; pastikan timeouts & reconnect.
4. **Partial write** — proxy yang memotong response; cek parser menangani partial data.
5. **Clock jump** — NTP anomali; cek timeout/hashing tidak rusak.
6. **SIGKILL di tengah write** — verifikasi journal/recovery on restart (idempotency).

Lakukan di staging + canary production (dengan observability penuh).

## Deployment Canary untuk Daemon C

```bash
# dua instance: v1 (100%) + v2 (5%)
# LB/upstream switch bertahap
# kriteria rollback otomatis:
#   error_rate_v2 > 2x v1  →  rollback
#   latency_p95_v2 > 1.5x  →  rollback
#   crash v2 (restart spike) →  rollback
```

## Performance Regression Guard

- Benchmark suite (google benchmark) untuk hot path — threshold CI (mis. p95 tidak naik > 10%).
- Perf profiling: `perf record`, flamegraph, `bpftrace` one-liner untuk hot function.
- Cache-friendly: false sharing (alignas(64)), branch prediction ([[likely]]/[[unlikely]] — C++20, GCC ext di C).
- Microbenchmark tidak menggantikan load test end-to-end (latency tail, lock contention).

## Security-reliability Nexus

- Reliability tanpa security = target empuk (DDoS = availability; buffer overflow = crash/RCE).
- Security tanpa reliability = layanan tidak bisa dipakai.
- Praktik: ASan di fuzzing (OSS-Fuzz style), seccomp sandbox per daemon, cap drop, read-only filesystem (ProtectSystem), no-new-privileges — lihat [[pod-security-standards]] analog untuk container.
- Postmortem security incident: sama seperti reliability postmortem (timeline, root cause, action).

---

  audited
---