---
title: Attack Perspective — Container/K8s (Red Team)
tags: [attack,red-team,container,k8s,escape,rbac,service-account,admission]
source: container-k8s-security.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Container/K8s — Perspektif Penyerang

> Container = shared kernel, K8s = control plane. Red team serang: container escape (runc/containerd), RBAC abuse, service account token, admission controller bypass, image supply chain.

## 1. Attack Surface K8s

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **Container Runtime** | Escape via runc/containerd/kernel | T1611 | CVE-2024-21626 (runc), CVE-2019-5736 | Container → host root | Falco/Tetragon = eBPF, partial |
| **K8s API Server** | Anonymous access, token theft, RBAC abuse | T1078.004 | kubectl, rbac-lookup | Token = valid auth | Audit log = verbose noise |
| **Service Account** | Mounted SA token → API access | T1078.004 | kubectl exec, curl k8s API | SA = legit pod identity | SA audit = noisy |
| **Pod/Deployment** | Modify deployment → inject malicious pod | T1611 | kubectl apply, helm | Pod = legit deployment | K8s audit = delayed |
| **Admission Controller** | Bypass policy (PodSecurity, OPA) | T1611 | Custom admission bypass, label spoof | Policy = namespace-scoped gap | Admission audit = rare |
| **Image** | Malicious base image, tag hijack | T1195.002 | Docker Hub name spoof, tag confusion | Image = valid signature (if any) | Image scan = post-deploy |
| **RBAC** | Over-permissive role → escalate | T1078.004 | RoleBinding create, cluster-admin | Role = legit assignment | RBAC audit = rare |
| **Secrets** | Secret mount → credential theft | T1552 | kubectl get secrets, env dump | Secret = valid config | Secret audit = rare |

## 2. Container Escape Chain

```
Inside Container (initial access):
  ├── Web app RCE / dependency confusion → shell in pod
  ├── Check capabilities: cat /proc/1/status | grep CapEff
  ├── Check mount: mount | grep host
  ├── Check seccomp: cat /proc/1/status | grep Seccomp
  └── Check namespace: lsns
    ↓
Escape Method 1 — runc (CVE-2024-21626):
  ├── File descriptor leak → escape ke host filesystem
  ├── Write payload ke host → execute → host RCE
  └→ Container → host root
    ↓
Escape Method 2 — Kernel Exploit:
  ├── CVE-2024-1086 (nf_tables UAF) → kernel RCE from container
  ├── Container share kernel → kernel exploit = host root
  └→ Container → host kernel → root
    ↓
Escape Method 3 — Capability:
  ├── CAP_SYS_ADMIN → mount host disk → chroot → escape
  ├── CAP_SYS_PTRACE → ptrace host process → inject
  ├── CAP_SYS_MODULE → load kernel module → rootkit
  └── CAP_DAC_READ_SEARCH → read host file bypass permission
    ↓
Escape Method 4 — Host Path Mount:
  ├── /var/run/docker.sock mounted → docker API → privileged container
  ├── / mounted → chroot → escape
  └── /proc mounted → write /proc/sysrq → kernel trigger
    ↓
Post-Escape: Host root → node → cluster → cloud
```

## 3. K8s Cluster Attack Chain

```
Recon: Identifikasi K8s (kubeconfig, KUBERNETES_SERVICE_HOST env)
  ├── Pod env: KUBERNETES_SERVICE_HOST + PORT → API endpoint
  ├── SA token: /var/run/secrets/kubernetes.io/serviceaccount/token
  └── DNS: kubernetes.default.svc → API server
    ↓
Initial Access (from pod):
  ├── SA token → curl API → list permissions (self-subject-review)
  ├── RBAC check: can-i create pods? list secrets? exec?
  └→ If pod create → privileged pod → node access
    ↓
Privilege Escalation:
  ├── Create privileged pod (hostPID + hostNetwork) → node root
  ├── Abuse RoleBinding → cluster-admin
  ├── Secret theft → cloud credential → cloud access
  └→ Node compromise → kubelet → control plane
    ↓
Lateral:
  ├── Pod → node → node → cluster (via kubelet API)
  ├── Secret → cloud cred → cloud services
  └→ Service mesh → east-west traffic intercept
    ↓
Persistence:
  ├── DaemonSet → persistent pod on every node
  ├── CronJob → periodic re-trigger
  ├── Admission webhook → backdoor all future pods
  └→ K8s secret → cloud credential → perpetual access
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **kubectl** | API access, RBAC enum, pod exec, secret read |
| **kube-hunter** | K8s penetration test (automated) |
| **kube-bench** | K8s security benchmark (CIS) |
| **rbac-lookup** | RBAC role → permission mapping |
| **kubeletctl** | kubelet API abuse (exec, port-forward) |
| **Falco / Tetragon** | Runtime detection (eBPF) — target untuk evasi |
| **CVE-2024-21626 PoC** | runc container escape |

## 5. Referensi
- CVE-2024-21626 — https://nvd.nist.gov/vuln/detail/CVE-2024-21626
- kube-hunter — https://github.com/aquasecurity/kube-hunter
- kube-bench — https://github.com/aquasecurity/kube-bench
- HackTricks K8s — https://book.hacktricks.xyz/network-services-pentesting/kubernetes
- Kubernetes Security (CKS) — https://kubernetes.io/docs/concepts/security/