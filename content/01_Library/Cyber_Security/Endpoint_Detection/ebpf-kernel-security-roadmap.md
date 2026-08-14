---
title: "eBPF Kernel Security Learning Roadmap \u2014 From Hello World to eBPF Rootkit\
  \ Auditing"
tags:
- ebpf
- kernel-security
- linux-kernel
- observability
- rootkit-detection
- roadmap
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
- callout
- code-wrap
---


| Item | Detail |
|------|--------|
| **Summary** | Kurikulum eBPF 4 fase: kprobe hello-world → verifier & maps → observability/XDP → deteksi eBPF rootkit (bpftool audit). |




[[00_Atlas/hierarchy-endpoint-security]] [[00_Atlas/hierarchy-operating-systems]] [[00_Atlas/hierarchy-malware-analysis]] [[00_Atlas/overview]]

> [!abstract] Ringkasan & Hubungan ke Vault
> Extended Berkeley Packet Filter (eBPF) mengubah cara tim keamanan melakukan pemantauan (*observability*) sistem operasi Linux tanpa menyentuh kode sumber kernel. Catatan ini menyediakan kurikulum terstruktur untuk menulis, mengompilasi, dan menganalisis program eBPF, sebagai pasangan praktis dari berkas teoritis [[ebpf-kernel-security]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Konsep Dasar eBPF & Program Pertama (kprobe Hello World)](#2-fase-1-konsep-dasar-ebpf--program-pertama-kprobe-hello-world)
3. [Fase 2: Mekanisme Verifikator & Komunikasi Data (eBPF Maps)](#3-fase-2-mekanisme-verifikator--komunikasi-data-ebpf-maps)
4. [Fase 3: Pemantauan Keamanan Sistem & Filter Jaringan (XDP)](#4-fase-3-pemantauan-keamanan-sistem--filter-jaringan-xdp)
5. [Fase 4: Deteksi & Pencegahan eBPF Rootkit (bpftool Audit)](#5-fase-4-deteksi--pencegahan-ebpf-rootkit-bpftool-audit)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini menuntun Anda dari pemrograman kernel dasar hingga teknik mitigasi eksploitasi:

```
[Fase 1: Hello World] ──> [Fase 2: Maps & Verifier] ──> [Fase 3: Security Monitoring] ──> [Fase 4: Rootkit Auditing]
- eBPF VM Architecture     - Verifier constraints       - Syscall Auditing (execve)   - bpf_probe_write_user
- kprobes & tracepoints    - Hash & RingBuffer Maps     - XDP Packet Filtering        - bpftool diagnostics
- clang & llvm compilation - User Space helper scripts  - Falco / Tetragon engines    - Signature bypass defense
```

---

## 2. Fase 1: Konsep Dasar eBPF & Program Pertama (kprobe Hello World)

eBPF memungkinkan kita menjalankan program di dalam mesin virtual (*in-kernel VM*) terisolasi di dalam kernel Linux secara aman saat interupsi sistem (*events*) terjadi.

### 2.1 Menulis Program Kernel C (`hello.c`)
Berikut adalah kode program kernel sederhana untuk memantau pemanggilan fungsi sistem `sys_clone` (proses pembuatan thread/anak proses baru):

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

// Definisikan hook pada kprobe sys_clone
SEC("kprobe/sys_clone")
int hello_clone(void *ctx) {
    char msg[] = "Security Alert: sys_clone dipanggil!";
    
    // Tulis pesan ke trace buffer kernel (/sys/kernel/debug/tracing/trace_pipe)
    bpf_trace_printk(msg, sizeof(msg));
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

### 2.2 Kompilasi menggunakan Clang/LLVM
Biner eBPF harus dikompilasi menggunakan target LLVM khusus untuk menghasilkan instruksi bytecode eBPF:
```bash
clang -target bpf -O2 -g -c hello.c -o hello.o
```

---

## 3. Fase 2: Mekanisme Verifikator & Komunikasi Data (eBPF Maps)

### 3.1 eBPF Verifier
Sebelum memuat (*loading*) biner `hello.o` ke dalam kernel menggunakan system call `sys_bpf`, kernel menjalankan **Verifier** untuk menjamin keamanan sistem:
- Menolak program yang mengandung perulangan tak terbatas (*infinite loop*) yang dapat memicu pembekuan kernel (*kernel panic*).
- Memastikan tidak ada akses pointer memori ilegal (*out-of-bounds memory access*).
- Ukuran program tidak boleh melampaui batas maksimum instruksi (biasanya 1 juta instruksi).

### 3.2 Berbagi Informasi menggunakan Maps
Program eBPF di kernel berkomunikasi dengan aplikasi pemantau di *user space* (seperti skrip Python/Go) menggunakan struktur data terenkapsulasi bernama **eBPF Maps**:

```c
// Mendeklarasikan Map untuk merekam jumlah panggilan sys_clone per User ID (UID)
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, u32);   // Key: UID
    __type(value, u64); // Value: Counter
} clone_counter_map SEC(".maps");
```

---

## 4. Fase 3: Pemantauan Keamanan Sistem & Filter Jaringan (XDP)

### 4.1 Pemantauan Syscall Execve
Keamanan endpoint memantau eksekusi file biner baru dengan meng-hook tracepoint `sys_enter_execve`:
```c
SEC("tracepoint/syscalls/sys_enter_execve")
int trace_execve(struct trace_event_raw_sys_enter* ctx) {
    char filename[128];
    // Baca argumen nama file biner dari memori user space secara aman
    bpf_probe_read_user_str(&filename, sizeof(filename), (void *)ctx->args[0]);
    
    // Kirim data filename ke user space agent untuk dicocokkan ke database EDR
    return 0;
}
```

### 4.2 XDP (eXpress Data Path)
XDP memproses paket jaringan langsung di lapisan terbawah pemrosesan jaringan *driver* kartu jaringan (NIC), sebelum paket dialokasikan ke memori kernel `sk_buff`. Sangat efisien untuk mitigasi serangan **DDoS**:
```c
SEC("xdp")
int xdp_drop_malicious(struct xdp_md *ctx) {
    // Saring paket IP tertentu dan kembalikan instruksi XDP_DROP
    // Mencegah overhead pemrosesan stack TCP/IP Linux
    return XDP_PASS;
}
```

---

## 5. Fase 4: Deteksi & Pencegahan eBPF Rootkit (bpftool Audit)

Penyerang tingkat tinggi memanfaatkan eBPF untuk menyembunyikan aktivitas jahat (*eBPF rootkit*).

### 5.1 Mekanisme Manipulasi eBPF Rootkit
eBPF rootkit menggunakan fungsi pembantu *helper function* `bpf_probe_write_user` untuk menulis ulang memori user space selama pemanggilan system call berjalan.
- **Contoh**: Mengubah data yang dikembalikan dari `getdents64` (fungsi pembaca isi folder) sebelum diserahkan ke user space, sehingga file malware tersembunyi dari perintah `ls` atau `find`.

### 5.2 Audit Cluster menggunakan `bpftool`
Sebagai pembela Blue Team, Anda wajib memeriksa status program eBPF yang aktif di dalam kernel secara berkala:

```bash
# 1. Tampilkan daftar semua program eBPF yang aktif saat ini di kernel
sudo bpftool prog list

# 2. Tampilkan semua struktur Maps yang aktif
sudo bpftool map list

# 3. Dump instruksi bytecode (assembly eBPF) dari program spesifik untuk dianalisis (misal ID 42)
sudo bpftool prog dump xlated id 42
# Periksa apakah program tersebut menggunakan fungsi sensitif: bpf_probe_write_user!
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Mengapa Verifikator eBPF membatasi keras penggunaan pointer aritmatika dan bagaimana cara mematuhinya saat memparsing paket jaringan?

**Solusi**
Pointer aritmatika berisiko memicu akses memori ilegal di luar batas struktur paket data, merusak data kernel penting. Untuk mematuhinya, kita wajib melakukan **pemeriksaan batas ukuran manual** sebelum membaca memori di program eBPF:
```c
void *data = (void *)(long)ctx->data;
void *data_end = (void *)(long)ctx->data_end;

struct ethhdr *eth = data;
// Jika pointer melebihi batas data_end, hentikan program. Verifikator akan meluluskan kode ini.
if ((void*)(eth + 1) > data_end) {
    return XDP_PASS; 
}
// Aman mengakses eth->h_proto setelah pemeriksaan di atas
```

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[ebpf-kernel-security]] | Teori dasar, penjelas dynamic tracing, dan arsitektur deteksi Falco. |
| [[kernel-forensics]] | Penyelidikan insiden memori ketika rootkit memodifikasi pemanggilan system call di Ring 0. |
| [[blueteam-detection-matrix]] | Pengintegrasian event log eBPF untuk audit alert sistem pertahanan. |

> [!callout] 💡
> eBPF memberi observability kernel tanpa modifikasi sumber kernel, tapi verifier adalah batas keamanan utama — pelajari constraint-nya sebelum menulis program kompleks.

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
