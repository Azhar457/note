---
title: Attack Perspective — Systems Architecture Evolution (Red Team)
tags:
- attack
- red-team
- systems-architecture
- evolution
- kernel-virtualization
- network-stack
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Systems Architecture Evolution — Perspektif Penyerang

> Setiap evolusi arsitektur (bare-metal → VM → container → serverless → edge) menciptakan attack surface baru. Red team serang: layer boundary, hypervisor isolasi, container escape, serverless event injection.

## 1. Evolution Attack Surface

| Era Arsitektur | Attack Surface | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------------|---------------|----------|------------|---------|----------------|
| **Bare Metal** | Direct hardware, kernel exploit, firmware | T1068 | CVE-2024-1086, UEFI implant | Pre-OS = survive reinstall | Firmware audit = rare |
| **Virtual Machine** | VM escape, hypervisor bug, side-channel (co-location) | T1611 | CVE-2024-21626 (runc), Spectre/Meltdown | Co-location = cache side channel | Hypervisor audit = rare |
| **Container** | Container escape (runc, containerd), kernel exploit | T1611 | CVE-2024-21626, CVE-2019-5736 | Container → host root | Falco/Tetragon (eBPF) — partial |
| **Serverless (FaaS)** | Event injection, cold-start abuse, IAM over-permissive | T1190 | API event poison, IAM escalation | Serverless = ephemeral → no persistent monitoring | Serverless audit log = nascent |
| **Edge (CDN/WAF)** | Edge worker abuse, cache poison, origin IP leak | T1190 | Worker inject, cache deception | Edge = distributed → hard attribute | Edge audit = rare |
| **Microservice** | Service mesh abuse, east-west traffic, API gateway bypass | T1190 | Istio/Envoy misconfig, east-west exfil | East-west = trusted zone → no inspection | East-west inspection = rare |
| **Service Mesh** | mTLS cert theft, sidecar hijack, control plane compromise | T1552 | Istio cert, Envoy admin API | mTLS = encrypted → no inspection | Mesh audit = nascent |

## 2. Container Escape Chain

```
Initial Access: Compromised container (web app RCE, dependency confusion)
 ↓
Recon (inside container):
 ├── Check capabilities: cat /proc/1/status → CapEff
 ├── Check mount: mount → host path mounted?
 ├── Check seccomp: cat /proc/1/status → Seccomp
 ├── Check namespace: lsns → shared namespace?
 └── Check kernel version: uname -r → kernel exploit?
 ↓
Escape Method 1 — runc Exploit (CVE-2024-21626):
 ├── runc = container runtime → execute binary
 ├── Exploit: file descriptor leak → escape ke host filesystem
 ├── Write payload ke host → execute → host RCE
 └→ Container → host root
 ↓
Escape Method 2 — Kernel Exploit:
 ├── CVE-2024-1086 (nf_tables UAF) → kernel RCE from inside container
 ├── Container shares kernel → kernel exploit = host root
 └→ Container → host kernel → root
 ↓
Escape Method 3 — Capability Abuse:
 ├── CAP_SYS_ADMIN → mount host disk → chroot → escape
 ├── CAP_SYS_PTRACE → ptrace host process → inject
 ├── CAP_SYS_MODULE → load kernel module → rootkit
 └── CAP_DAC_READ_SEARCH → bypass file permission → read host file
 ↓
Escape Method 4 — Host Path Mount:
 ├── /var/run/docker.sock mounted → docker API → create privileged container
 ├── / mounted → chroot → escape
 └── /proc mounted → write /proc/sysrq → trigger kernel
 ↓
Post-Escape: Host root → cluster compromise → lateral
```

## 3. Serverless Attack Chain

```
Recon: Identifikasi serverless endpoint (AWS Lambda, Azure Func, GCP Func)
 ↓
Event Injection:
 ├── API Gateway → inject event (API event poison)
 ├── S3 trigger → upload malicious object → trigger Lambda
 ├── SQS → inject malicious message → trigger
 └→ CloudWatch → inject log event → trigger
 ↓
Exploit:
 ├── Lambda code → RCE via dependency (if user code has vuln)
 ├── IAM role → Lambda role → escalate → cloud access
 ├── Environment variable → credential exfil
 └→ Cold start → side-channel between invocation
 ↓
Persistence:
 ├── Lambda layer → backdoor all function → persistent
 ├── IAM role → create backdoor role → perpetual access
 └→ Event source → create persistent trigger (S3/SQS/CW)
 ↓
Evasion: Serverless = ephemeral → no persistent process → monitoring gap
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **CVE-2024-21626 PoC** | runc escape (container → host) |
| **kube-bench** | K8s security benchmark |
| **kube-hunter** | K8s penetration test |
| **Pacu (AWS)** | AWS Lambda attack, IAM escalation |
| **chain-bench** | CI/CD supply chain audit |
| **trivy** | Container/image vulnerability scan |
| **Falco / Tetragon** | Runtime detection (eBPF) — red team evasi target |

## 5. Referensi
- CVE-2024-21626 (runc) — https://nvd.nist.gov/vuln/detail/CVE-2024-21626
- Container Escape — https://book.hacktricks.xyz/linux-hardening/privileged-groups
- Serverless Security — https://owasp.org/www-project-serverless-top-10/
- Tetragon (eBPF Security) — https://github.com/cilium/tetragon
- Service Mesh Security — https://istio.io/latest/docs/concepts/security/
---

audited
---
