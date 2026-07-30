---
tags:
  - sop
  - ebpf
  - security
  - kernel-security
  - monitoring
  - tetragon
aliases:
  - SOP eBPF Runtime Security Auditing
  - eBPF Auditing System Calls
  - Cilium Tetragon Audit
status: pending
created: 2026-07-21
updated: 2026-07-21
---

# SOP: Implementasi eBPF untuk Runtime Security Auditing & Monitoring System Calls

> [!tip] **Extended Berkeley Packet Filter (eBPF)** memungkinkan eksekusi program ter-sandboxing secara aman di dalam kernel Linux tanpa memodifikasi source code kernel atau memuat modul kernel tambahan. SOP ini mendokumentasikan implementasi pengawasan sistem (*runtime security auditing*) dan pencatatan panggilan sistem (*system calls tracking*) untuk mendeteksi ancaman keamanan secara real-time.

---

## 1. Tujuan & Ruang Lingkup SOP

### Purpose
Menghentikan serangan siber, upaya eskalasi hak akses (*privilege escalation*), dan *payload execution* mencurigakan di level sistem operasi (Fedora/Ubuntu Host) dengan memonitor pemanggilan *system call* kernel (seperti `execve`, `ptrace`, `sys_write`) secara *low-overhead* dan tahan terhadap manipulasi ruang pengguna (*user-space evasion*).

### Scope
- Instalasi dependensi eBPF (`bcc-tools`, `bpftrace`, `libbpf`).
- Konfigurasi profil deteksi ancaman menggunakan **Cilium Tetragon** (eBPF-based security parser).
- Pembuatan filter audit kustom untuk mendeteksi eksekusi biner mencurigakan di direktori temporer (`/tmp`, `/dev/shm`).
- Langkah investigasi pasca-deteksi ancaman (*incident response*).

---

## 2. Prasyarat Kernel & Arsitektur eBPF Auditing

Program eBPF berjalan langsung di kernelspace, dipicu oleh event-event kernel tertentu (*kprobes*, *tracepoints*, atau *uprobes*), lalu mengirimkan data metrik kembali ke userspace melalui **eBPF Maps** (Ring Buffer).

```
   Userspace (Aplikasi Monitoring / Tetragon)
        ▲
        │ (Membaca event via Ring Buffer)
   ┌────┼────────────────────────────────────────────────────────┐
   │    │  eBPF Maps (Shared Memory Buffer)                      │  Kernelspace
   ├────┼────────────────────────────────────────────────────────┤
   │    │                                                        │
   │ [ eBPF Program ] ───> Dipicu oleh Hook                      │
   │                           │                                 │
   │                           ▼ (Kernel Hooks)                  │
   │                    [ Tracepoints ] (e.g. sys_enter_execve)  │
   │                    [ Kprobes ] (e.g. kprobe/sys_write)      │
   └─────────────────────────────────────────────────────────────┘
```

### Prasyarat Sistem
*   **Kernel Linux Version**: Minimal versi **5.8** (Disarankan $\ge 5.15$ untuk fitur ring-buffer penuh).
*   **Kernel Config**: `CONFIG_BPF=y`, `CONFIG_BPF_SYSCALL=y`, `CONFIG_BPF_JIT=y`, `CONFIG_HAVE_EBPF_JIT=y`.
*   **Akses**: Wajib dijalankan dengan hak akses **root** (`CAP_SYS_ADMIN` atau `CAP_BPF`).

---

## 3. Prosedur Instalasi eBPF Tooling (Fedora 44 / RedHat base)

Jalankan perintah berikut untuk menginstal perkakas analisis kernel eBPF:

```bash
# 1. Update paket repositori kernel
sudo dnf install -y elfutils-libelf-devel clang llvm make gcc-c++

# 2. Instalasi bpftrace (untuk scripting kprobe kilat) dan bcc-tools
sudo dnf install -y bpftrace bcc-tools bcc-devel

# 3. Verifikasi ketersediaan eBPF JIT Compiler
sudo sysctl net.core.bpf_jit_enable
# Output ideal: net.core.bpf_jit_enable = 1 (aktif)
```

---

## 4. SOP Langkah-Demi-Langkah (Step-by-Step) Monitoring & Auditing

### Step 1: Monitoring Eksekusi Proses Baru Menggunakan `bpftrace`
Buat skrip pemantau satu baris (*one-liner*) untuk melacak panggilan sistem `execve` (pemicu eksekusi proses baru) di seluruh sistem operasi:

```bash
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("PID %d (%s) memanggil: %s\n", pid, comm, str(args->filename)); }'
```

#### Contoh Output Deteksi:
```text
PID 124802 (bash) memanggil: /usr/bin/ls
PID 124899 (node) memanggil: /home/jars/projects/thinking-types-mcp/dist/index.js
PID 124954 (python) memanggil: /mnt/data_d/Projects/vault-rag/scripts/query.py
```

---

### Step 2: Implementasi Cilium Tetragon untuk Runtime Security (SOP Inti)
Tetragon adalah mesin audit eBPF tangguh yang dapat membekukan proses berbahaya secara otomatis di level kernel.

#### 1. Instalasi Tetragon via Helm / Docker:
```bash
docker run --name tetragon --rm \
  --privileged \
  --pid=host \
  -v /sys/kernel/debug:/sys/kernel/debug \
  -v /var/run/docker.sock:/var/run/docker.sock \
  quay.io/cilium/tetragon:v1.0.0
```

#### 2. Buat File Kebijakan Audit Kustom (`security-policy-exec.yaml`):
Kebijakan ini memantau dan memblokir upaya pembukaan shell rahasia dari direktori temporer `/tmp/` yang biasanya digunakan oleh malware/exploit payload:

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: "block-tmp-execution"
spec:
  kprobes:
    - call: "sys_execve"
      syscall: true
      args:
        - index: 0
          type: "string" # Path file biner yang dieksekusi
      selectors:
        - matchArgs:
            - index: 0
              operator: "Prefix"
              values:
                - "/tmp/"
                - "/dev/shm/"
          matchActions:
            - action: "Sigkill" # Kirim sinyal SIGKILL (proses langsung mati di level kernel!)
```

#### 3. Terapkan Kebijakan ke Tetragon daemon:
```bash
tetragon-cli register security-policy-exec.yaml
```

---

### Step 3: Auditing Privilege Escalation (Pemantauan Eskalasi Hak Akses)
Malware sering mencoba memodifikasi ID kredensial user untuk mendapatkan hak akses root. Monitor fungsi perubahan UID (`setuid`, `setgid`, `setreuid`) menggunakan skrip `bpftrace`:

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_setuid {
  printf("⚠️ DETEKSI: PID %d (%s) mencoba mengubah UID menjadi %d!\n", pid, comm, args->uid);
}'
```

---

## 5. Lembar Investigasi Kejadian Keamanan (Incident Response Workflow)

Jika eBPF mendeteksi adanya aktivitas mencurigakan (`execve` dari `/tmp` atau panggilan `setuid` tidak sah):

1.  **Isolasi Proses**: Dapatkan PID dari log audit eBPF, lalu hentikan proses secara paksa jika Tetragon matchActions tidak membekukannya secara otomatis:
    ```bash
    kill -9 <PID>
    ```
2.  **Analisis Memory Map & File Descriptor**:
    Periksa berkas mana saja yang dibuka oleh proses tersebut melalui `/proc/`:
    ```bash
    ls -l /proc/<PID>/fd
    cat /proc/<PID>/maps
    ```
3.  **Analisis Parent Process (PSTree)**:
    Temukan aktor/induk proses yang melahirkan proses ilegal tersebut untuk mengidentifikasi pintu masuk celah keamanan (misal: proses induk berasal dari server web port `80` atau node MCP):
    ```bash
    ps -fj --pid <PID>
    ```

---

## 🔗 Referensi & Catatan Terkait
- [[linux-hardening-cis]] — Standar Pengerasan Keamanan Sistem Operasi Linux
- [[incident-response-framework]] — SOP Penanganan Insiden Keamanan Sistem
- [[model-context-protocol-specification]] — Pengamanan Vektor Ancaman Prompt Injection di MCP
- [[vector-quantization-hnsw-tuning]] — Optimasi Memory DB Vektor
