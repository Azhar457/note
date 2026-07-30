---
title: Kubernetes Security Roadmap — Defense Layer-by-Layer dari Pod sampai Cluster
tags:
- container-k8s-security
- kubernetes
- cks
- roadmap
- cis-benchmark
aliases:
- CKS Exam Coverage
- K8s Defense Roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> [!abstract] Ringkasan
> Roadmap belajar defensive Kubernetes yang paralel dengan [[kubernetes-roadmap|Platform_Technologies/kubernetes-roadmap]] (fungsional), tapi fokus di **security layer-by-layer**: image supply chain, runtime isolation, RBAC, network policy, secrets, admission control, sampai threat detection. Pelengkap langsung untuk [[container-kubernetes-security-deepdive]] dan [[cicd-shiftleft-shiftright]].

## Daftar Isi

1. [Mengapa Roadmap Ini Dipisah](#mengapa-roadmap-ini-dipisah)
2. [5 Zona Pertahanan Kubernetes](#5-zona-pertahanan-kubernetes)
3. [Zona 1 — Supply Chain (Image + Registry)](#zona-1--supply-chain-image--registry)
4. [Zona 2 — Cluster API & Control Plane](#zona-2--cluster-api--control-plane)
5. [Zona 3 — Workload Identity & Authorization (RBAC / PSA)](#zona-3--workload-identity--authorization-rbac--psa)
6. [Zona 4 — Runtime Isolation (Pod Security, Seccomp, NetworkPolicy)](#zona-4--runtime-isolation-pod-security-seccomp-networkpolicy)
7. [Zona 5 — Detection & Response (Falco, Tetragon, Audit Log)](#zona-5--detection--response-falco-tetragon-audit-log)
8. [CIS Benchmark Mapping](#cis-benchmark-mapping)
9. [Urutan Implementasi Rekomendasi](#urutan-implementasi-rekomendasi)
10. [Latihan Praktis & Tool Latih](#latihan-praktis--tool-latih)
11. [Catatan Terkait](#catatan-terkaitan)

---

## Mengapa Roadmap Ini Dipisah

[[kubernetes-roadmap]] fokus **fungsional** (cara deploy workload, persistent storage, service mesh, GitOps). Roadmap ini fokus **defensif** — pertanyaan "kalau adversary dapat foothold di pod, apa yang阻止 lateral movement-nya?".

Pattern belajar paralel ini subject untuk:
- **Lulus CKS** (Certified Kubernetes Security Specialist) — CNCF exam.
- **Hardening cluster production** untuk multi-tenant SaaS (lihat [[cloud-security-posture-management]]).
- **Bekal audit CIS EKS Level 1/2** (EKS, GKE, AKS) yang demanded di enterprise.

---

## 5 Zona Pertahanan Kubernetes

```
┌──────────────────────────────────────────────────────────────────┐
│                    ATTACK SURFACE K8s                              │
├──────────────────────────────────────────────────────────────────┤
│ Zona 1: Supply Chain                                              │
│   Source → Dockerfile → Registry → Admission                     │
│              (cosign, Trivy, OPA, Kyverno)                        │
├──────────────────────────────────────────────────────────────────┤
│ Zona 2: Cluster API & Control Plane                              │
│   kube-apiserver → etcd → kubelet                                │
│              (TLS, RBAC, Audit, anonymous off)                     │
├──────────────────────────────────────────────────────────────────┤
│ Zona 3: Workload Identity & Authorization                        │
│   ServiceAccount → RBAC → PodSecurityAdmission                    │
│              (least-privilege, no defaults)                        │
├──────────────────────────────────────────────────────────────────┤
│ Zona 4: Runtime Isolation                                         │
│   Pod ↔ Pod, Pod ↔ Host, Pod ↔ Network                           │
│              (PodSecurity, NetworkPolicy, Seccomp, AppArmor)      │
├──────────────────────────────────────────────────────────────────┤
│ Zona 5: Detection & Response                                       │
│   Runtime events → eBPF → SIEM                                   │
│              (Falco, Tetragon, Audit-log analytics)               │
└──────────────────────────────────────────────────────────────────┘
```

Lima zona ini memetakan 1:1 ke **CNCF CKS exam domains** + **CIS Kubernetes Benchmark**.

---

## Zona 1 — Supply Chain (Image + Registry)

| Topik                                | Threat Vector                                    | Tool / Mitigation                          |
| --- | --- | --- |
| Base image hygiene                   | Image bloated → attack surface besar             | `distroless`, `alpine`, multi-stage        |
| Image scanning                       | CVE di layer OS / library                         | **Trivy**, Snyk, Grype                    |
| Image signing                        | Tampered image di registry                        | **Cosign** (Sigstore), Notary             |
| SLSA provenance                      | Tidak tahu image siapa build-nya                 | SLSA Level 3+, in-toto, attestations      |
| Admission control                    | Image unsigned / unsanitized masuk cluster       | **Kyverno** / **OPA Gatekeeper** + Cosign verify |
| Registry RBAC                        | Pull dari registry external / anonymous          | Harbor (private), deny-public-pull policy  |

**Latihan:** Build image Alpine, scan dengan Trivy, sign dengan Cosign, enforce signed-only admission di minikube.

---

## Zona 2 — Cluster API & Control Plane

| Topik                          | Best Practice                                             |
| --- | --- |
| API Server exposure            | `--anonymous-auth=false`, `--insecure-port=0` di flag apiserver |
| etcd encryption                | `encryption-provider-config` dengan AES-CBC atau AESCBC    |
| TLS apiserver-ke-etcd          | Mutual TLS dengan cert rotated                            |
| Kubelet authn                  | `--anonymous-auth=false`, `--authorization-mode=Webhook`  |
| Audit logging                  | `audit.log` di /var/log/ + stream ke SIEM (Wazuh/Loki)    |
| Default ServiceAccount token   | Set `automountServiceAccountToken: false` di pod default   |

**Resource:** [Kubernetes Hardening Guide](https://kubernetes.io/docs/concepts/security/) (resmi), CIS Benchmark 1.8+.

---

## Zona 3 — Workload Identity & Authorization (RBAC / PSA)

```yaml
# Contoh RBAC baik: least-privilege, role per namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: payment-svc
  name: payment-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["stripe-key"]    # Specific, not wildcard
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payment-pod-rb
  namespace: payment-svc
subjects:
- kind: ServiceAccount
  name: payment-sa
  namespace: payment-svc
roleRef:
  kind: Role
  name: payment-reader
  apiGroup: rbac.authorization.k8s.io
```

**PSA (Pod Security Admission):** Namespace label `pod-security.kubernetes.io/enforce: restricted` adalah baseline OPA-light untuk pod hardening.

---

## Zona 4 — Runtime Isolation (Pod Security, Seccomp, NetworkPolicy)

### Pod Security Standard — Restricted Profile

```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  containers:
  - name: app
    image: ghcr.io/org/app@sha256:...
    securityContext:
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

### Network Policy — Default Deny + Allowlist

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: payment-svc
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-payment-ingress
  namespace: payment-svc
spec:
  podSelector:
    matchLabels:
      app: payment
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - port: 8080
```

Gunakan **Cilium** atau **Calico** sebagai CNI untuk enforcement efektif.

---

## Zona 5 — Detection & Response (Falco, Tetragon, Audit Log)

| Tool              | Layer             | Use Case                                          |
| --- | --- | --- |
| **Falco**          | syscall (kernel)  | Default rules: shell in container, write to /etc, network anomaly |
| **Tetragon**       | eBPF              | Lebih low-overhead, policy-aware                  |
| **Tracee**         | eBPF              | Runtime forensics, file access tracking           |
| **Kube-apiserver audit** | control plane | SIEM ingestion: кто создал pod, when, from where |
| **kubelet audit**  | node              | Pod start, exec, port-forward                    |

**Contoh Falco ruleset — detect crypto miner:**

```yaml
- rule: Crypto Miner Detection
  desc: Detect known crypto miner processes inside container
  condition: >
    spawned_process and container and
    proc.name in (xmrig, minerd, minergate)
  output: >
    Crypto miner detected
    (user=%user.name command=%proc.cmdline container=%container.name image=%container.image.repository:%container.image.tag)
  priority: CRITICAL
  tags: [process, mining, mitre_T1496]
```

Lihat [[ebpf-kernel-security]] untuk detail eBPF sebagai layer observability.

---

## CIS Benchmark Mapping

| CIS Section                  | Zona   | Penyelesaian di Vault                                        |
| --- | --- | --- |
| 1.x — Control Plane          | Z2     | Lihat [[kubernetes-roadmap]], [[linux-hardening-cis]]         |
| 2.x — Worker Node             | Z4     | [[container-kubernetes-security-deepdive]] § Seccomp/AppArmor  |
| 3.x — RBAC & ServiceAccount  | Z3     | Catatan ini (§ Zona 3)                                       |
| 4.x — Pod Security           | Z4     | Catatan ini (§ Zona 4) + [[pod-security-standards]] (planned) |
| 5.x — NetworkPolicy / CNI    | Z4     | [[container-kubernetes-security-deepdive]] § NetworkPolicy    |
| 6.x — Secrets Management     | Z3     | [[sealed-secrets-vs-vault]] (planned)                        |
| 7.x — Supply Chain            | Z1     | Catatan ini (§ Zona 1) + [[cosign-pipeline]] (planned)        |

---

## Urutan Implementasi Rekomendasi

Untuk cluster production yang sudah jalan dan mau di-hardening:

1. **Z1 Supply Chain.** Scan image existing, sign yang lolos. Set registry allow-list.
2. **Z2 Control Plane.** Enable apiserver audit log → forward ke Loki/SIEM (lihat [[observability-stack-prometheus-grafana]]).
3. **Z3 RBAC baseline.** Scan dengan `rbac-tool`, hapus cluster-admin yang tidak perlu. Tambah per-namespace Role.
4. **Z4 Pod Security.** Apply `restricted` PSA di namespace prod via Kyverno policy (graceful rollout dulu `warn` → `audit` → `enforce`).
5. **Z5 Detection.** Deploy Falco (DaemonSet), default rules + custom untuk crypto miner, exfil DNS. Pipe output ke Telegram alert (lihat [[incidents/notifiable-alerts-kanal|SOP Notifiable Alerts]] kalau ada).

---

## Latihan Praktis & Tool Latih

| Tool                          | URL                                  | Fungsi                                  |
| --- | --- | --- |
| **minikube**                    | kubernetes.io/docs/tutorials        | Single-node cluster untuk belajar       |
| **kind**                        | kind.sigs.k8s.io                    | Multi-node di Docker (test controllability) |
| **KubeAcademy**                 | kube.academy                        | Course gratis CKA/CKS-aligned          |
| **Kubernetes Goat**             | github.com/amadalfalco/kubernetes-goat | Vulnerable-by-design cluster untuk exploit/hardening latihan |
| **BadPods**                     | github.com/BishopFox/badpods       | Pod manifest with anti-patterns       |
| **kube-bench**                  | github.com/aquasecurity/kube-bench | CIS Benchmark automation               |
| **kubescape**                   | github.com/kubescape/kubescape     | NSA-CISA hardening + CVE check         |
| **trivy**                       | github.com/aquasecurity/trivy      | Image + IaC + k8s manifest scanner     |
| **Falco**                       | falco.org                            | Runtime detection default ruleset      |

---

## Pitfalls

1. **Cluster yang sudah prod jarang re-apply PSA `restricted`.** Tanpa graceful rollout (`audit` dulu), enforcement langsung bisa break pod legacy yang `runAsRoot: true`.
2. **NetworkPolicy default-deny tanpa allowlist.** Akan block DNS ke CoreDNS internal — pod jadi `CrashLoopBackOff` karena tidak resolve name.
3. **Falco ruleset noisy.** Default rules trigger banyak false-positive (setiap `exec` di pod generates alert). Tune rule per-cluster, whitelist critical namespaces.
4. **Secrets di etcd tanpa encryption.** Sangat umum di cluster EKS default. Setup `encryption-provider-config` dengan KMS — satu kali effort, audit nanti wajib.
5. **RBAC `*` verb atau `*` resource.** Wildcard melumpuhkan least-privilege. Audit dengan `kubectl api-resources --no-headers | awk '{print $3}'` lalu sweeping semua `clusterrolebindings` yang punya `verbs: ["*"]`.

---

## Catatan Terkait

- [[container-kubernetes-security-deepdive]] — Sumber utama untuk setiap Zona
- [[kubernetes-roadmap]] — Roadmap fungsional paralel
- [[kubernetes-architecture-deepdive]] — Teori control plane / data plane
- [[cicd-shiftleft-shiftright]] — Image scanning integrasi ke CI/CD
- [[ebpf-kernel-security]] — Runtime observability dengan eBPF
- [[ebpf-beyond-security]] — Tetragon untuk runtime detection level kernel
- [[homelab-security-architecture-synthesis]] — Pattern deploy K8s di homelab
- [[cosign-pipeline]] (planned) — Image signing + admission enforcement
- [[pod-security-standards]] (planned) — Episode pendek PSA `privileged|basedline|restricted`
- [[hierarchy-it-domain]] — Ontology cluster / K8s dalam hierarki IT domain
