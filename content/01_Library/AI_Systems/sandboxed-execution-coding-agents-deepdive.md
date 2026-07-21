---
title: '🛡️ Sandboxed Execution for Coding Agents — Isolasi untuk Kode Generated AI:
  dari namespaces sampai microVM'
tags:
- sandboxed-execution
- coding-agent
- isolation
- security
- lethal-trifecta
- container
- microvm
- thoughtworks-radar-vol-34
- library
aliases:
- agent-sandbox-isolation
- code-agent-isolation
created: '2026-07-19'
updated: '2026-07-19'
status: growing
cssclasses:
- wide-table
---

# 🛡️ Sandboxed Execution for Coding Agents — Isolasi untuk Kode Generated AI

**dari namespaces sampai microVM: Defense in Depth untuk Agent-Generated Code**

> Coding agent generate code. Code itu harus dieksekusi (untuk test, run, debug). Tapi eksekusi = potensi malicious, leaked credentials, atau corrupted state. **Sandboxing** meng-isolasi eksekusi kode AI-generated agar dampak failure terbatas. ThoughtWorks Radar Vol.34 (April 2026) menempatkan blip #13 "Sandboxed execution for coding agents" di ring **Trial** — karena praktik mature ada tapi belum default di seluruh industri. Catatan ini membedah spektrum isolasi (process → container → microVM → WASM → full VM), anatomi Sandbox-limiting (capabilities, seccomp, network/writable paths), dan integrasi dengan harness engineering [[agent-skills-feedback-sensors-deepdive]] menggunakan referensi lethal trifecta Simon Willison.

> [!info] Hubungan ke Vault
> - [[container-kubernetes-security-deepdive]] — fondasi container isolation; sandbox adalah subset dari container security patterns
> - [[threat-modeling-deepdive]] — threat modeling untuk agent attack surface
> - [[zero-trust-security]] — zero trust principles untuk agent yang eksekusi arbitrary code
> - [[agentic-ai-mcp-architecture-deepdive]] — MCP tool yang execute code butuh sandbox wrapper
> - [[agent-skills-feedback-sensors-deepdive]] — harness engineering sebagai kontrol pair dengan sandbox
> - [[ai-assisted-dev-workflow]] — workflow Claude Code yang sering execute shell
> - [[rasp-architecture]] — RASP sebagai post-execution sensor analog
> - [[ebpf-kernel-security-roadmap]] — eBPF sebagai kernel-level syscall sensor
> - [[kernel-forensics]] — buat forensic kalo agent escape sandbox
> - [[ebpf-beyond-security]] — eBPF sebagai syscall trace buat agent behavior audit

---

## Daftar Isi

1. [[#Foundation]]
2. [[#Technical Deep-Dive]]
3. [[#Advanced]]
4. [[#Case Studies]]
5. [[#Koneksi ke Vault]]
6. [[#Referensi]]
7. [[#Bottom Line]]

---

## Foundation

### The Lethal Trifecta (Simon Willison)

> *"An unsafe agent combines three traits: (1) access to private data, (2) exposure to untrusted content, (3) ability to take external action. Most useful agents by default fall into this category — not by misconfiguration, but by design."* — Simon Willison, "The Lethal Trifecta" (https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)

Sandboxing adalah mitigasi minimum untuk trait **(3) external action**: limit what agent bisa sentuh di environment saat eksekusi kode. Itu tidak eliminasi lethal trifecta (private data + untrusted content masih relevan), tapi mempersempit blast radius.

### Why AI-Generated Code Berbeda dari Human Code

| Aspek | Kode manusia | Kode AI-generated |
|-------|--------------|-------------------|
| **Intent** | Author tulis dengan eksplisit goal | Model generate berdasarkan probabilistic completion |
| **Test history** | Lintas iterasi, maintainer tahu edge cases | Tidak ada; agent generate sekali, compile sekali, run sekali |
| **Hallucination surface** | Tidak ada | Bisa import library yang tak ada, panggil function yang tak ada |
| **Prompt injection** | Tidak ada | Komentar dari user → instruksi override → kode nefarious |
| **Trust baseline** | Code reviewer menandai trust | Tidak ada reviewer middle; agent bisa jadi "author = reviewer" |
| **Decision authority** | Senior dev bertanggung jawab | Tidak ada accountabilitas |

Implikasi: kode AI-generated harus **dieksekusi dengan reduced trust**. Zero-trust principle: assume malicious untill proven otherwise, dan bukti hanya bisa datang dari sandboxed execution outcome sensor.

### Sandbox Taxonomy ( spektrum isolasi)

```
   Loosest                                        Tightest
   ─────────────────────────────────────────────────────────►
   Source code    Process isolation       Container    microVM
   ┌─────────┐   ┌──────────────┐   ┌──────────┐   ┌──────────┐
   │ chroot  │   │  namespaces  │   │  Docker  │   │Firecracker│
   │         │   │  + seccomp   │   │  Podman  │   │  Cloud HV │
   │ chroot  │   │  + caps      │   │  gVisor  │   │  Kata     │
   └─────────┘   └──────────────┘   └──────────┘   └──────────┘
                          │                │             │
                          │                │             │
                          ▼                ▼             ▼
                     good for         good for      good for
                     per-user         agent         multi-tenant
                     separation       dev workflow  untrusted code
```

Isolasi paling lemah hanyalah ~60% nuclear. Dalam praktik, **defense in depth** dibutuhkan: sandboxes bertingkat.

---

## Technical Deep-Dive

### Isolation Spectrum Table

| Level | Mechanism | Examples | Latency Join | Memory over-head | Threat residual | Best untuk |
|-------|-----------|---------|--------------|-------------------|-----------------|------------|
| **Host direct** | Process-level namespace | Rust process with `setrlimit()` | μs | Low | Untrusted code mudah escape via kernel exploit | Single-user execution pada dev workstation trust-penuh |
| **chroot + seccomp** | Pair dengan syscall filter | chroot w/ `SECCOMP_RET_KILL_PROCESS` filter | ms | Low | Tidak isolasi network side-channel | Legacy embed |
| **Linux user namespaces** | Unprivileged root | `unshare -rU` + bubblewrap | ms | Low | host filesystem still bidirectional via mount | Per-user dev env |
| **Container (rootless)** | Podman, Docker w/ `--userns=keep-id` | `podman run --userns=keep-id` | 200ms-2s | Moderate | Container escape via CVE | Per-project isolation; good default |
| **Container (gVisor)** | User-space kernel | `runsc` runtime | 200-500ms | Moderate-high | gVisor syscall interception; no real Linux syscalls from sandbox | Multi-tenant PRs, public sandbox |
| **WASM runtime** | Capability-based | Wasmtime, Wasmer, WasmEdge | μs-ms | Very low | Capability security model; no host file access via default | Small plugins, agent tools |
| **microVM (Firecracker)** | VMM minimal, KVM-backed | Firecracker, Cloud Hypervisor | 100-200ms | Mid-high | Kernel-level isolation; rarely escape unless bug | Multi-tenant serverless, fixed job |
| **Full VM** | Hypervisor | KVM, Hyper-V, VirtualBox | 5-15s | High | Strongest mainstream isolation; called by malware analysts | Truly unknown code, RE sandbox |

### Tools Referenced di ThoughtWorks Radar Vol.34

| Blip # | Name | Ring | Penjelasan |
|--------|------|------|------------|
| #13 | **Sandboxed Execution for Coding Agents** | Trial | Konsep parent catatan ini |
| #63 | **Sprites** | Assess | Stateful sandbox env dari Fly.io dengan filesystem persistence |
| #52 | **Coder** | Assess | VS Code server alternative; bagus untuk self-hosted sandbox dev env |
| #41 | **Pixel-streamed development environments** | Caution | VDI-style env; latency > usability tradeoff masih rough |
| #73 | **Dev Containers** | Trial | Standardized container definition; ideal layer building block |
| #48 | **Replit** | Trial | Cloud-native collaborative dev; full env isolation via containers |
| #39 | **Ignoring durability in agent workflows** | Caution | Anti-pattern: agent crash dan state hilang — sandbox harus stateful untuk loop iteratif |

### Capabilities & Seccomp Filters

Isolasi tidak cukup tanpa mengkonstrain capabilities dan syscalls. Defense in depth:

**1. Drop capabilities** kecuali yang needed:

```bash
# Podman example
podman run --rm \
  --cap-drop ALL \
  --cap-add CAP_DAC_OVERRIDE \     # kalau butuh read restricted home dir
  --cap-add CAP_NET_BIND_SERVICE \ # kalau butuh bind to <1024 port
  --security-opt no-new-privileges \
  alpine:latest /agent/run.sh
```

**2. Seccomp filter:** blacklist syscalls yang berbahaya:

```json
// seccomp-filter.json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["clone", "mount", "umount", "pivot_root", "swapon", "reboot", "settimeofday", "sethostname", "chroot", "chmod", "chown", "setuid", "setgid", "setgroups"],
      "action": "SCMP_ACT_ERRNO"
    },
    {
      "names": ["read", "write", "openat", "close", "stat", "fstat", "lstat", "poll", "lseek", "mmap", "mprotect", "munmap", "brk", "rt_sigaction", "rt_sigprocmask", "rt_sigreturn", "ioctl", "pread64", "pwrite64", "readv", "writev", "access", "pipe", "pipe2", "select", "sched_yield", "mremap", "msync", "mincore", "madvise", "shmget", "shmat", "shmctl", "dup", "dup2", "dup3", "pause", "nanosleep", "getitimer", "alarm", "setitimer", "getpid", "sendfile", "socket", "connect", "accept", "sendto", "recvfrom", "sendmsg", "recvmsg", "bind", "listen", "getsockname", "getpeername", "socketpair", "setsockopt", "getsockopt", "shutdown", "getrusage", "gettimeofday"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Pakai via `--security-opt seccomp=/path/seccomp-filter.json`.

**3. Network allowlist:** blocking egress ke internet kecuali package repositori yang ter-whitelist:

```bash
# iptables rule di host side
sudo iptables -N AGENT_EGRESS
sudo iptables -A AGENT_EGRESS -d registry.npmjs.org -p tcp --dport 443 -j ACCEPT
sudo iptables -A AGENT_EGRESS -d crates.io -p tcp --dport 443 -j ACCEPT
sudo iptables -A AGENT_EGRESS -d pypi.org -p tcp --dport 443 -j ACCEPT
sudo iptables -A AGENT_EGRESS -j DROP
```

Atau, pakai DNS-based allowlist via `dnsmasq` atau Pi-hole. Aturan: default **deny**, allowlist spesifik. Sebagai azhar worldview: pakai pola ini untuk `9router` → `omnirouter` proxy chains juga.

**4. Filesystem whitelist:** hanya path read-only yang diperbolehkan:

```bash
# Mount hanya sumber yang aman read-only
podman run --rm -it \
  -v $(pwd):/workspace:rw \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  -v /tmp:/scratch:rw \
  --read-only \                        # container filesystem read-only default
  --tmpfs /tmp:rw,size=100M \
  alpine:latest /agent/run.sh
```

### Coding Agent Sandbox Topology

```
       User prompt
            │
            ▼
   ┌─────────────────────┐
   │  orchestrator        │ ← [[agent-skills-feedback-sensors-deepdive]]
   │  (skill selection)   │
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │   Agent             │ ← runs with workspace mount read-write, but
   │  (write code)       │   other paths read-only
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │   Sandbox           │ ← this doc subject
   │ (execute generated) │
   │   - no network      │
   │   - no host fs      │
   │   - seccomp lock    │
   └──────────┬──────────┘
              │
              │ stdout/stderr/exit
              ▼
   ┌─────────────────────┐
   │   Judge             │ ← [[agent-skills-feedback-sensors-deepdive]]
   │  (compare output    │
   │   ke expected)      │
   └──────────┬──────────┘
              │
              ▼
       ┌──────────┐                ┌──────────┐
       │  PASS    │                │  FAIL    │
       │  → human │                │  → retry │
       │   review │                │  agent   │
       └──────────┘                └──────────┘
```

**Kunci invariants:**

1. Filesystem sandbox tidak share dengan agent workspace. Agent bisa commit perubahan, tapi execution sandbox pakai separate mount.
2. Orchestrator selalu di luar sandbox — agent tidak bisa escape ke orchestrator.
3. Sandbox tidak share PID namespace dengan agent — agent death != sandbox death.
4. Egress firewall default deny — agent tidak bisa exfiltrate data post-execution.

---

## Advanced

### Durable Agent Workflows (Radar #39, Caution)

> *"Ignoring durability in agent workflows is an anti-pattern. As agents run longer tasks, state persistence across crashes becomes critical."*

Sandbox stateless vs stateful: kalau agent butuh iterasi cross-crash, sandbox harus support persistent filesystem. Sprites (Radar blip #63 Assess) menawarkan ini: stateful sandbox dengan filesystem yang bertahan lintas agent restart.

**Implementasi state in sandbox:**

```yaml
# Devcontainer.json — persistent sandbox
{
  "name": "Agent Sandbox",
  "image": "mcp/sandbox:latest",
  "workspaceMount": "src=/workspace,dst=/workspace,type=volume,consistency=cached",
  "mounts": [
    "src=agent-cache,dst=/agent/cache,type=volume"
  ],
  "postCreateCommand": "pip install -r requirements.txt",
  "runArgs": [
    "--init",
    "--cap-drop=ALL",
    "--security-opt=no-new-privileges",
    "--security-opt", "seccomp=/etc/seccomp/agent.json",
    "--network=agent-egress"
  ]
}
```

### Pixel-Streamed Development Environments (Radar #41, Caution)

Pixel-streamed = remote IDE via VDI-style framebuffer streaming (Windowd Remote Desktop analog).

**Kenapa Caution?**

| Capability | Value | Tradeoff |
|------------|-------|----------|
| Full IDE rendering server-side | Berjalan di device apapun tanpa install | Latency tinggi saat typing (>50ms → frustrating) |
| GPU ter-akselerisasi server-side | Compiler berat game-developer pipeline | Mahal, overkill untuk 90% agent use case |
| Multi-user collab native (line cursors) | Real-time pair programming | Network reliability = dealbreaker |

Untuk coding agent sehari-hari, **Coder** (Radar #52 Assess) lebih praktis: VS Code Server container, jauh lebih ringan.

### Agent Scan (Radar #77, Assess) sebagai Bridge

Agent Scan = security scanner yang integrate sebagai pre-execution sensor ke sandbox.

**Workflow integration dengan [[agent-skills-feedback-sensors-deepdive]]:**

1. Agent write code
2. Agent Scan rate severity (CVE-match dependency scan, secret leak, dangerous import)
3. Kalau severity > threshold → sandbox execution denied, agent auto-repair
4. Kalau pass → kode masuk sandbox untuk dynamic execution

Ini menjadikan Agent Scan sebagai feedforward sensor BEFORE sandbox.

### ConfIT (Radar #82, Asses) & Contract Testing untuk Sandbox

Sandbox isolated → integration antar-agent tool bisa putus. ConfIT define integration contracts sebagai code, sehingga test suite yang jalan in-sandbox bisa validate edge interop:

```kotlin
// Kotlin ConfIT example (Radar #82)
contract {
    request { method = "POST"; path = "/v1/files" }
    response { status = 201; body = FileResponseSchema::class }
}
contractTest(sandboxEndpoint) {
    verify(contract)
}
```

---

## Case Studies

| Studi Kasus | Konteks | Temuan Kunci | Mitigasi Diimplementasi |
|-------------|---------|--------------|------------------------|
| Cursor background agents | Cursor agent di cloud yang execute code via containerized environment | Default container isolation is suffcient untill agent bekerja dengan credentials; maka escape vector pindah ke credential exfiltration | Workspace mount terpisah dari sandbox; secrets inject via temporary environment, nuke pas run selesai |
| OpenClaw perimeter attack surface | ThoughtWorks Radar blip #97 (Caution). Open-source autonomous agent yang handle task panjang, akumulasi tooling privileges | Lethal trifecta default. Sandbox "off by default" → experiment diri pengembang banyak fail-loud | Permission flags spesifik via Agent Skills ([agent-skills-feedback-sensors-deepdive]); mutation testing untuk catch skill ambiguity |
| Replit containerized agent | Cloud-native collaborative dev yang agent bisa execute exploit-like code via repl session | Multi-tenant leak risk via shared resources; file→file attack | One container per session; strict seccomp filter, no `clone()`, no `mount()`; egress via `egress-proxy.replit.com` |
| Hermes sandbox untuk execute_code tool | Hermes `execute_code` tool — Python script yang invoke Hermes tools via hermes_tools module | Tool bisa trigger write/delete pakai filesystem access Hermes milik host; risk atau advertising | Tool run in-process with Python interpreter under Hermes user; trusted tool internal — tidak sandbox by default sebab perlu filesystem write |
| Sprites sandbox dengan state persistence | Fly.io's Sprites (Radar #63 Assess) stateful sandbox — agent iterative atas state | Disk state harus mountable antar-restart; sandbox filesystem menjadi attack surface sendiri | Volume-snapshot setiap agent cycle, restore ke baseline tiap invoke; checksum per file |

---

## Koneksi ke Vault

- [[container-kubernetes-security-deepdive]] — fondasi container isolation; seccomp, capabilities, namespaces dijelaskan lebih dalam
- [[threat-modeling-deepdive]] — threat modeling untuk agent attack surface
- [[zero-trust-security]] — zero trust principles untuk agent yang eksekusi arbitrary code
- [[agentic-ai-mcp-architecture-deepdive]] — MCP tool yang execute code butuh sandbox wrapper
- [[agent-skills-feedback-sensors-deepdive]] — harness engineering sebagai kontrol pair dengan sandbox; Agent Skills sebagai feedforward before sandbox
- [[structured-output-llm-mcp-tool-calling-deepdive]] — MCP tool argumen wajib tervalidasi sebelum invoke sandbox
- [[ai-assisted-dev-workflow]] — workflow Claude Code yang sering execute shell, langsung relevan → sandbox layer tambahan
- [[rasp-architecture]] — RASP analog: post-execution sensor dalam sandbox boundary
- [[ebpf-kernel-security-roadmap]] — eBPF sebagai kernel-level syscall sensor untuk detect sandbox escape
- [[ebpf-beyond-security]] — eBPF sebagai syscall trace buat agent behavior audit dalam sandbox

---

## Referensi

1. ThoughtWorks Technology Radar Vol.34 (April 2026) blip #13 Sandboxed Execution for Coding Agents (Trial). https://www.thoughtworks.com/radar/techniques/sandboxed-execution-for-coding-agents
2. ThoughtWorks Radar PDF. https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2026/04/tr_technology_radar_vol_34_en.pdf
3. ThoughtWorks Radar blip #63 Sprites. https://www.thoughtworks.com/radar/platforms/sprites
4. ThoughtWorks Radar blip #73 Dev Containers. https://www.thoughtworks.com/radar/tools/dev-containers
5. ThoughtWorks Radar blip #52 Coder. https://www.thoughtworks.com/radar/platforms/coder
6. ThoughtWorks Radar blip #41 Pixel-Streamed Dev Environments (Caution). https://www.thoughtworks.com/radar/techniques/pixel-streamed-development-environments
7. ThoughtWorks Radar blip #39 Durable Agent Workflows (Caution). https://www.thoughtworks.com/radar/techniques/ignoring-durability-in-agent-workflows
8. ThoughtWorks Radar blip #77 Agent Scan. https://www.thoughtworks.com/radar/tools/agent-scan
9. ThoughtWorks Radar blip #82 ConfIT. https://www.thoughtworks.com/radar/tools/confit
10. Simon Willison, "The Lethal Trifecta". https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
11. Martin Fowler, "Harness Engineering: Putting Coding Agents on a Leash". https://martinfowler.com/articles/harness-engineering.html
12. Podman rootless documentation. https://podman.io/docs/rootless
13. Docker seccomp profiles. https://docs.docker.com/engine/security/seccomp/
14. Firecracker microVM. https://firecracker-microvm.github.io/
15. Cloud Hypervisor. https://github.com/cloud-hypervisor/cloud-hypervisor
16. Google gVisor. https://gvisor.dev/
17. Wasmtime (WASM runtime). https://wasmtime.dev/
18. DevContainers specification. https://containers.dev/
19. Coder self-hosted dev env. https://coder.com/docs
20. Replit container isolation. https://docs.replit.com/
21. Sprites (Fly.io). https://fly.io/docs/sprites/
22. Linux seccomp BPF. https://www.kernel.org/doc/html/latest/userspace-api/seccomp_filter.html
23. Linux user namespaces. https://man7.org/linux/man-pages/man7/user_namespaces.7.html
24. eBPF for sandbox audit. https://ebpf.io/
25. Agent Scan — security scanner for agentic ecosystems. https://www.thoughtworks.com/radar/tools/agent-scan

---

> [!tip] Bottom Line
> Sandboxed execution bukan binary decision — itu spektrum dari process isolation ke microVM. Default untuk productive coding agent workflow: **rootless container** (Podman/Docker) + **seccomp filter** + **capabilities drop ALL** + **egress firewall default deny** + **filesystem read-only except workspace**. Untuk pengembang yang serius multi-tenant (agent dari multiple untrusted users): upgrade ke **gVisor** atau **microVM Firecracker**. Lapis input: Agent Skills + payload verification ([agent-skills-feedback-sensors-deepdive]) sebagai feedforward layer pre-sandbox, Agent Scan sebagai static sensor untuk block known-CVE dan secret leak, baru sandbox untuk dynamic execution. Lapis output: deterministic sensors (compiler, linter, tests) sebagai post-execution feedback untuk auto-correction. Lethal trifecta tetap relevan — sandbox mitigates trait (3) tapi tidak eliminate traits (1) dan (2). Untuk Hermes execute_code yang internal-only: trust transaksi tetap valid. Untuk Hermes cross user (multi-tenant future) atau agent yang handle user untrusted content (website fetch, document parsing): sandboxing wajib, bukan optional.
