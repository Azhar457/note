---
title: "Container & Kubernetes Security Deep Dive"
aliases:
  - container-kubernetes-security
  - CKS
  - container-security
  - k8s-security-deepdive
tags:
  - container-security
  - kubernetes-security
  - runtime-security
  - supply-chain-security
  - devsecops
  - ebpf
  - cilium
  - falco
  - opa-gatekeeper
  - kyverno
  - image-security
  - network-security
  - secrets-management
  - admission-control
  - reference/library
created: 2026-07-02
updated: 2026-07-02
status: operational
cssclasses:
  - wide-table
---

# 🐳 Container & Kubernetes Security Deep Dive

> Panduan komprehensif — dari container runtime hardening hingga Kubernetes cluster defense. Mencakup attack surface, image security, runtime monitoring, RBAC, network policies, supply chain SLSA, admission control, secrets management, studi kasus nyata, dan tooling audit.

> [!INFO] Navigasi Vault
> Topik ini terkait erat dengan [[cicd-shiftleft-shiftright]] (DevSecOps pipeline), [[ebpf-kernel-security]] (eBPF-based runtime defense), [[comprehensive-threat-directory]] (threat taxonomy), [[web-hacking-exploitation]] (web-layer attacks yang kerap menjadi entry point ke K8s), dan [[it-domain-hierarchy]] (domain trust model).

---

## 📋 Daftar Isi

1. [Container Attack Surface & Kernel Isolation](#container-attack-surface--kernel-isolation)
2. [Seccomp, AppArmor & SELinux](#seccomp-apparmor--selinux)
3. [Image Security & Multi-Stage Builds](#image-security--multi-stage-builds)
4. [Distroless & Minimal Base Images](#distroless--minimal-base-images)
5. [Image Scanning & Vulnerability Management](#image-scanning--vulnerability-management)
6. [Runtime Security: Falco](#runtime-security-falco)
7. [Runtime Security: Tracee](#runtime-security-tracee)
8. [Runtime Security: Tetragon & eBPF](#runtime-security-tetragon--ebpf)
9. [Kubernetes RBAC Deep Dive](#kubernetes-rbac-deep-dive)
10. [Pod Security Standards (PSS) & Pod Security Admission (PSA)](#pod-security-standards-pss--pod-security-admission-psa)
11. [OPA / Gatekeeper](#opa--gatekeeper)
12. [Kyverno Policy Engine](#kyverno-policy-engine)
13. [Cilium & NetworkPolicy](#cilium--networkpolicy)
14. [Service Mesh Security (Istio, mTLS)](#service-mesh-security-istio-mtls)
15. [Supply Chain SLSA untuk OCI Images](#supply-chain-slsa-untuk-oci-images)
16. [Cosign & Image Signing](#cosign--image-signing)
17. [Admission Control & Mutating Webhooks](#admission-control--mutating-webhooks)
18. [Secrets Management](#secrets-management)
19. [Case Study: Tesla Kubernetes Compromise](#case-study-tesla-kubernetes-compromise)
20. [Case Study: Log4j di Kubernetes](#case-study-log4j-di-kubernetes)
21. [Tooling Audit: kube-bench, kube-hunter, Popeye, Kubescape](#tooling-audit-kube-bench-kube-hunter-popeye-kubescape)
22. [Kesimpulan & Best Practices](#kesimpulan--best-practices)

---

## Container Attack Surface & Kernel Isolation

Container tidak menyediakan hypervisor-level isolation. Sebuah container berbagi **kernel host** dengan container lain dan host itu sendiri. Attack surface utama meliputi:

| Attack Vector                    | Deskripsi                                         | Dampak               |
| :------------------------------- | :------------------------------------------------ | :------------------- |
| **Namespace escape**             | Exploit kernel bug untuk break out dari namespace | Root on host         |
| **Capability abuse**             | Container dengan CAP_SYS_ADMIN, CAP_NET_RAW       | Privilege escalation |
| **Shared /proc, /sys**           | Write ke /proc/sys/kernel/core_pattern            | Host code execution  |
| **Container breakout via mount** | Mount host filesystem dari container              | Full host access     |
| **User namespace mapping**       | Misconfigured UID/GID mapping                     | Bypass permission    |
| **cgroupfs**                     | Write ke cgroup notify_on_release                 | Host code execution  |

```text
┌──────────────────────────────────────────────────┐
│                    Host Kernel                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  ctr-1   │  │  ctr-2   │  │  ctr-3   │       │
│  │ (pid ns) │  │ (pid ns) │  │ (pid ns) │       │
│  │ net ns   │  │ net ns   │  │ net ns   │       │
│  │ mnt ns   │  │ mnt ns   │  │ mnt ns   │       │
│  └──────────┘  └──────────┘  └──────────┘       │
│  Linux Kernel (shared by ALL containers)          │
└──────────────────────────────────────────────────┘
```

**Mitigasi:**

- Jalankan container dengan `--security-opt no-new-privileges:true`
- Drop semua capabilities, add hanya yang diperlukan (`--cap-drop=ALL --cap-add=NET_BIND_SERVICE`)
- Gunakan user namespace remapping (`/etc/subuid`, `/etc/subgid`)
- Hindari `--privileged` flag dalam produksi

---

## Seccomp, AppArmor & SELinux

### Seccomp (Secure Computing Mode)

Membatasi syscall yang bisa digunakan container. Tiga mode:

| Mode         | Deskripsi                        | Use Case                         |
| :----------- | :------------------------------- | :------------------------------- |
| `default`    | Whitelist ~300+ syscall aman     | Default Docker                   |
| `unconfined` | Semua syscall diizinkan          | Debugging (tidak untuk produksi) |
| Custom JSON  | Whitelist spesifik per container | Aplikasi dengan syscall khusus   |

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    { "names": ["accept4", "epoll_wait", "write", "read", "openat"], "action": "SCMP_ACT_ALLOW" }
  ]
}
```

### AppArmor (Application Armor)

Leverage LSM (Linux Security Module) untuk membatasi file path, network, dan capability. Profile di-load ke kernel dan di-enforce per container.

```bash
# Load profile
apparmor_parser -r /etc/apparmor.d/container-profile

# Jalankan container dengan profile
docker run --security-opt apparmor=container-profile nginx
```

### SELinux (Security-Enhanced Linux)

Label-based MAC yang lebih granular. Di RHEL/CoreOS, container mendapat tipe `container_t` dengan MCS level unik per pod. Konfigurasi Kubernetes:

```yaml
securityContext:
  seLinuxOptions:
    level: "s0:c123,c456"
    type: "container_t"
```

**Comparison matrix:**

| LSM      | Scope           | Policy Language | Overhead | Use in K8s    |
| :------- | :-------------- | :-------------- | :------- | :------------ |
| Seccomp  | Syscall         | JSON            | Minimal  | GA v1.19+     |
| AppArmor | Path, net, cap  | Text profile    | Low      | Beta (PSA)    |
| SELinux  | Label-based MAC | Policy module   | Medium   | RHCOS/Flatcar |

---

## Image Security & Multi-Stage Builds

Setiap lapisan (layer) pada container image menambah attack surface — termasuk toolchains, debug symbols, dan package manager artifacts.

**Golden image anti-pattern:**

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl wget git build-essential python3
COPY app /app
CMD ["/app/entrypoint"]
```

→ 1.2 GB image, ~120 CVEs, puluhan unused binaries.

**Multi-stage build:**

```dockerfile
# Stage 1: builder
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server .

# Stage 2: runtime
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/server"]
```

✅ Final image: ~15 MB, 0 CVEs, hanya satu binary.

---

## Distroless & Minimal Base Images

| Base Image                 |  Size  | CVE Count (typical) | Use Case                 |
| :------------------------- | :----: | :-----------------: | :----------------------- |
| `ubuntu:22.04`             | 77 MB  |        30–80        | Dev, testing             |
| `alpine:3.20`              |  7 MB  |         0–5         | Lightweight prod         |
| `gcr.io/distroless/static` |  2 MB  |          0          | Go/rust static binary    |
| `chainguard/static`        | 2.5 MB |          0          | FIPS-compliant minimal   |
| `scratch`                  |  0 B   |          0          | Fully static binary only |

> [!TIP] Rekomendasi
> Untuk production: pilih distroless atau Chainguard. Alpine memakai musl libc — uji kompatibilitas aplikasi terlebih dahulu. Untuk compliance (FIPS, SOC 2), Chainguard menyediakan base image with zero CVEs dan SBOM built-in.

---

## Image Scanning & Vulnerability Management

Alat scanning terintegrasi di pipeline CI/CD untuk mencegah image dengan critical CVE masuk ke registry atau cluster.

```yaml
# GitHub Actions — Trivy scan example
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:latest
    format: sarif
    severity: CRITICAL,HIGH
    output: trivy-results.sarif
    exit-code: 1 # ganti pipeline jika temuan critical
```

| Scanner     | Format            | Registry Integration      | Policy Engine         | License     |
| :---------- | :---------------- | :------------------------ | :-------------------- | :---------- |
| **Trivy**   | SARIF, JSON, HTML | ECR, GAR, ACR, Docker Hub | IaC + K8s             | Apache 2.0  |
| **Grype**   | CycloneDX, JSON   | Any OCI registry          | +Syft SBOM            | Apache 2.0  |
| **Clair**   | JSON              | Quay, Harbor              | Vulnerability matcher | Apache 2.0  |
| **Snyk**    | SARIF, JSON, HTML | All major registries      | Severity-based gate   | Proprietary |
| **Anchore** | JSON, CycloneDX   | ECR, Docker Hub           | Policy bundles        | Apache 2.0  |

---

## Runtime Security: Falco

Falco — project CNCF — menggunakan driver kernel (eBPF atau kernel module) untuk memonitor syscall dan menghasilkan **falco events** berdasarkan rule engine.

**Arsitektur:**

```text
┌─────────────────────────────────────┐
│         Kubernetes Node              │
│  ┌──────────┐   ┌──────────────┐   │
│  │ Falco    │   │ Container    │   │
│  │ (driver) │──▶│ (syscall)    │   │
│  │ eBPF/KM  │   └──────────────┘   │
│  └────┬─────┘                      │
│       │                            │
│  ┌────▼─────┐                      │
│  │ Falco    │                      │
│  │ Userspace│                      │
│  └────┬─────┘                      │
│       │                            │
│  ┌────▼─────┐    ┌─────────────┐  │
│  │ Output   │───▶│ gRPC / Stdout │  │
│  │ Channel  │    │ Webhook      │  │
│  └──────────┘    └─────────────┘  │
└─────────────────────────────────────┘
```

**Contoh rule — detect shell masuk kontainer:**

```yaml
- rule: Terminal shell in container
  desc: A shell was spawned by a program in a container
  condition: >
    spawned_process and container
    and shell_procs
    and not user_expected_terminal_shell_in_container_conditions
  output: >
    Shell spawned in container
    (user=%user.name container_name=%container.name shell=%proc.name parent=%proc.pname)
  priority: WARNING
  tags: [container, process, shell]
```

---

## Runtime Security: Tracee

Tracee — dari Aqua Security — menggunakan eBPF untuk **deteksi threats dan forensik** tanpa kernel module.

| Feature             | Tracee                | Falco                |
| :------------------ | :-------------------- | :------------------- |
| Signatures          | 150+ built-in         | 200+ rules           |
| eBPF-native         | ✅ Standalone eBPF    | ✅ eBPF (alternatif) |
| Kernel module       | ❌ Tidak perlu        | ✅ Juga support      |
| Container forensics | ✅ Capture file write | ❌ Terbatas          |
| CO-RE (BTF)         | ✅                    | ✅                   |
| Output format       | JSON, table, gob      | JSON, gRPC           |

```bash
# Tracee — one-shot signature scan
tracee --signatures --scope pid=1

# Tracee — daemon mode dengan output JSON
tracee --remap --output json --capture exec --capture write=/tmp/dump
```

---

## Runtime Security: Tetragon & eBPF

Tetragon — dari Isovalent (sekarang Cisco) — menawarkan **enforcement** berbasis eBPF di Cilium ecosystem.

```yaml
# Tetragon TracingPolicy — block execution of /bin/sh
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: "block-shell"
spec:
  kprobes:
    - call: "sys_execve"
      syscall: true
      args:
        - index: 0
          type: "string"
      selectors:
        - matchArgs:
            - index: 0
              operator: "Equal"
              values:
                - "/bin/sh"
          matchActions:
            - action: Sigkill
```

> [!NOTE] eBPF Security Landscape
> eBPF memungkinkan observability dan enforcement tanpa mengubah kernel source. Tools seperti Falco (kernel module/eBPF), Tracee (pure eBPF), dan Tetragon (eBPF-based enforcement) membentuk lapisan runtime defense yang semakin mature. Lihat [[ebpf-kernel-security]] untuk technical deep dive.

---

## Kubernetes RBAC Deep Dive

RBAC di Kubernetes menggunakan **Role / ClusterRole** (permissions) dan **RoleBinding / ClusterRoleBinding** (binding ke user/SA/group).

**Privilege escalation via RBAC misconfig:**

```yaml
# ❌ JANGAN — binding cluster-admin ke service account
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dangerous-binding
subjects:
  - kind: ServiceAccount
    name: myapp
    namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

**Principle of Least Privilege (PoLP):**

```yaml
# ✅ Role minimal untuk pod reader
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: production
  name: myapp-pod-reader
subjects:
  - kind: ServiceAccount
    name: myapp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

**RBAC audit checklist:**

1. ✅ Apakah ada binding ke `cluster-admin` di namespace non-system?
2. ✅ Apakah SA digunakan tanpa token mount?
3. ✅ Apakah `escalate` / `bind` verb diberikan?
4. ✅ Apakah `*` wildcard resources/verbs digunakan?
5. ✅ Apakah `get secrets` dibatasi?

---

## Pod Security Standards (PSS) & Pod Security Admission (PSA)

PSS menggantikan PSP (PodSecurityPolicy, deprecated di v1.25) dengan tiga policy level:

| Level          | Deskripsi            |  Ketat  | Contoh Restriksi                                              |
| :------------- | :------------------- | :-----: | :------------------------------------------------------------ |
| **privileged** | unrestricted         | Longgar | Tidak ada batasan                                             |
| **baseline**   | minimal restrictions | Sedang  | No hostPID, no privileged, no hostPort                        |
| **restricted** | hardened by default  |  Ketat  | Seccomp=RuntimeDefault, drop ALL caps, readOnlyRootFilesystem |

**Implementasi via label namespace:**

```bash
kubectl label ns production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline
```

| Mode      | Behavior                                       |
| :-------- | :--------------------------------------------- |
| `enforce` | **Tolak** pod yang melanggar policy            |
| `audit`   | Log pelanggaran ke audit log (pod tetap jalan) |
| `warn`    | Tampilkan warning ke user (pod tetap jalan)    |

---

## OPA / Gatekeeper

OPA Gatekeeper — admission controller berbasis **Rego policy language** — memungkinkan kebijakan deklaratif untuk resource Kubernetes.

**Constraint template — blokir image dari registry tidak dikenal:**

```rego
package k8sallowedrepos

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not startswith(container.image, "registry.internal.company.io/")
  msg := sprintf("Container %v menggunakan image dari registry eksternal", [container.name])
}
```

**Install Gatekeeper:**

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16/deploy/gatekeeper.yaml
```

**Constraint instance:**

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: prod-allowed-repos
spec:
  match:
    namespaces: ["production"]
  parameters:
    repos:
      - "registry.internal.company.io/"
```

---

## Kyverno Policy Engine

Kyverno — engine yang lebih **Kubernetes-native** — menulis policy dalam bentuk YAML, bukan Rego. Dapat melakukan **mutate, validate, generate** resource.

```yaml
# Kyverno policy — require readOnlyRootFilesystem
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-readonly-rootfs
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-readonly-rootfs
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Root filesystem harus read-only"
        pattern:
          spec:
            containers:
              - securityContext:
                  readOnlyRootFilesystem: true
```

| Feature            | OPA/Gatekeeper     | Kyverno                 |
| :----------------- | :----------------- | :---------------------- |
| Policy language    | Rego               | YAML (native)           |
| Learning curve     | Tinggi             | Rendah                  |
| Mutation           | ❌ (via webhook)   | ✅ Built-in             |
| Generate resources | ❌                 | ✅                      |
| Policy reports     | ✅                 | ✅                      |
| Background scan    | ❌                 | ✅                      |
| Ecosystem policies | Gatekeeper Library | Kyverno Policies (200+) |

---

## Cilium & NetworkPolicy

Kubernetes NetworkPolicy default hanya bekerja di layer 3/4. Cilium — berbasis eBPF — memberikan **L3-L7 network security** dengan identitas service, bukan IP.

### Kubernetes NetworkPolicy (native):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - port: 3000
```

### Cilium NetworkPolicy (L7 HTTP-aware):

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-api-policy
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "3000"
              protocol: TCP
          rules:
            http:
              - method: "GET"
                path: "/api/v1/public"
```

```text
┌───────────────────────────┐
│   Cilium Service Mesh     │
│                           │
│  ┌─────┐     ┌─────┐    │
│  │     │────▶│     │    │
│  │ Svc │     │ Pod │    │
│  │ A   │     │ B   │    │
│  │(ID:1)│     │(ID:2)│    │
│  └─────┘     └─────┘    │
│       │           │      │
│  ┌────▼─────┐  ┌─▼────┐ │
│  │ Hubble   │  │Enforce│ │
│  │ Observ.  │  │ BPF   │ │
│  └──────────┘  └──────┘ │
│      eBPF Programs        │
└───────────────────────────┘
```

---

## Service Mesh Security (Istio, mTLS)

Service mesh menyediakan **mTLS, fine-grained authorization, dan observability** di layer aplikasi tanpa mengubah kode.

```yaml
# Istio PeerAuthentication — strict mTLS untuk namespace production
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT # STRICT | PERMISSIVE | DISABLE
---
# Istio AuthorizationPolicy — allow only frontend ke api
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-authz
  namespace: production
spec:
  selector:
    matchLabels:
      app: api
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/production/sa/frontend"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/api/*"]
```

> [!TIP] Zero Trust Network untuk K8s
> Kombinasi Cilium (eBPF NetworkPolicy) + Istio (mTLS + Authz) memberikan defense-in-depth. Cilium mengamankan traffic antar node, Istio mengamankan traffic antar pod di dalam node. Untuk implementasi lengkap, lihat [[web-hacking-exploitation]] untuk memahami web-layer threats yang service mesh cegah di L7.

---

## Supply Chain SLSA untuk OCI Images

SLSA (Supply-chain Levels for Software Artifacts) — framework dari OpenSSF — mendefinisikan level keamanan supply chain dari L0 (no guarantees) hingga L3 (hermetic + reproducible).

| Level   | Build as code | Provenance | Isolated | Hermetic | Reproducible |
| :------ | :-----------: | :--------: | :------: | :------: | :----------: |
| SLSA L1 |      ✅       |     ❌     |    ❌    |    ❌    |      ❌      |
| SLSA L2 |      ✅       |     ✅     |    ❌    |    ❌    |      ❌      |
| SLSA L3 |      ✅       |     ✅     |    ✅    |    ✅    |      ❌      |
| SLSA L4 |      ✅       |     ✅     |    ✅    |    ✅    |      ✅      |

**Praktik untuk mencapai SLSA L3 di OCI:**

1. **Build as code** — Dockerfile + CI pipeline (GitHub Actions, GitLab CI, Tekton)
2. **Signed provenance (DSSE)** — attestation dari build platform
3. **Isolated build** — no network during build, clean environment
4. **Hermetic build** — semua dependensi dideklarasikan dan diverifikasi

```yaml
# Generate provenance attestation dengan gitsign + cosign
steps:
  - uses: sigstore/cosign-installer@main
  - name: Sign image
    run: |
      cosign sign --yes "$IMAGE"
  - name: Generate provenance
    run: |
      cosign attest --yes --type slsa --predicate slsa.json "$IMAGE"
```

---

## Cosign & Image Signing

Cosign — dari Sigstore project — memungkinkan **signing, verifying, dan storing signatures** untuk OCI container images.

**Signing flow:**

```bash
# Generate keyless signing
cosign sign myapp:latest

# Verify
cosign verify myapp:latest \
  --certificate-identity "someone@example.com" \
  --certificate-oidc-issuer "https://accounts.google.com"
```

**Verifikasi admission — CUE policy dengan cosign:**

```bash
# Gate admission dengan cosign verify
kubectl exec -it kube-apiserver -- \
  --admission-control-config-file=<(
    echo '
    plugins:
    - name: CosignImageVerification
      configuration:
        policies:
        - image: "registry.internal.company.io/*"
          key:
            kms: "gcpkms://projects/my-project/locations/global/keyRings/cosign/cryptoKeys/signer"
    '
  )
```

```text
┌──────────┐     ┌──────────┐     ┌──────────────┐
│  Build   │────▶│  Sign    │────▶│  Verify on   │
│  Image   │     │  (Cosign)│     │  Admission   │
└──────────┘     └──────────┘     └──────┬───────┘
                                         │
                                    ┌────▼────┐
                                    │ Deploy  │
                                    │ ✅ Deny │
                                    └─────────┘
```

---

## Admission Control & Mutating Webhooks

**Admission controllers** adalah gatekeeper kustom di kube-apiserver yang memvalidasi/memodifikasi object sebelum disimpan ke etcd.

| Admission Controller         | Fungsi                                                |
| :--------------------------- | :---------------------------------------------------- |
| `MutatingAdmissionWebhook`   | **Modify** object (default values, sidecar injection) |
| `ValidatingAdmissionWebhook` | **Validate** object (policy enforcement)              |
| `PodSecurity`                | Enforce PSS (replaces PSP)                            |
| `NamespaceLifecycle`         | Prevent deletion of system namespaces                 |
| `LimitRanger`                | Enforce resource limits                               |
| `ImagePolicyWebhook`         | Kontrol image registry                                |

**Mutating webhook — inject sidecar:**

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: sidecar-injector
webhooks:
  - name: sidecar.mesh.io
    clientConfig:
      service:
        name: sidecar-injector
        namespace: mesh-system
        path: /mutate
      caBundle: <base64>
    rules:
      - operations: ["CREATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    admissionReviewVersions: ["v1"]
    sideEffects: None
```

---

## Secrets Management

### Masalah dengan Kubernetes Secrets Native:

- Base64-only encoding (bukan encryption by default)
- etcd belum tentu terenkripsi
- Rotasi secrets memerlukan rolling pods
- Audit trail terbatas

### Solusi Eksternal:

| Tool                          | Encryption at rest  | Dynamic rotation | KMS Integration | Vault Provider |
| :---------------------------- | :-----------------: | :--------------: | :-------------: | :------------: |
| **External Secrets Operator** |    etcd encrypt     |        ✅        |  AWS/GCP/Azure  |       ✅       |
| **Sealed Secrets**            |   Controller key    |        ❌        |       ❌        |       ❌       |
| **HashiCorp Vault**           |    Vault transit    |        ✅        |  All major KMS  |      N/A       |
| **Secret Store CSI Driver**   | N/A (provider-side) |        ✅        |  AWS/GCP/Azure  |       ✅       |

### External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-creds
    creationPolicy: Owner
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: secret/data/database
        property: password
```

### Sealed Secrets:

```bash
# Encrypt secret untuk disimpan di Git
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
# Sealed secret aman disimpan di repo publik — hanya controller bisa decrypt
```

---

## Case Study: Tesla Kubernetes Compromise

**Timeline (2018):**

1. **Entry point**: Kubernetes admin console **tanpa password** (kubectl dashboard exposed ke internet)
2. **Lateral movement**: Attacker menemukan credential AWS di sebuah pod environment variable
3. **Data exfiltration**: Menggunakan kubelet credential untuk mencuri data mining pod
4. **Cryptocurrency mining**: Deploy container mining di cluster Tesla menggunakan pods

**Root cause analysis:**

- Kubectl dashboard tidak seharusnya terekspos publik tanpa auth
- Service account dengan `cluster-admin` digunakan untuk dashboard
- Credential AWS disimpan di env variable, bukan secrets management
- NetworkPolicy tidak membatasi egress ke internet

**Pelajaran:**

```text
📌 ❌ JANGAN: expose Kubernetes Dashboard ke internet
📌 ✅ WAJIB: RBAC dengan least privilege
📌 ✅ WAJIB: External Secrets / Vault untuk credential
📌 ✅ WAJIB: NetworkPolicy untuk blokir egress kecuali approved
📌 ✅ WAJIB: Audit logging ke SIEM (Splunk, ELK)
```

---

## Case Study: Log4j di Kubernetes

**CVE-2021-44228 (Log4Shell) — Impact di K8s:**

- JNDI injection menyebabkan RCE pada ribuan aplikasi Java yang menggunakan Log4j
- Service mesh (Istio/Linkerd) tidak bisa memblokir sepenuhnya karena exploit terjadi di layer aplikasi
- Container image yang belum di-scan membawa vulnerable library

**Mitigasi di K8s yang efektif:**

1. **WAF + L7 Policy**: Blokir header JNDI di ingress (Cilium HTTP policy, ModSecurity)
2. **Image scanning**: Trivy/Grype scan — block image dengan Log4j < 2.17
3. **Runtime detection**: Falco rule — detect proses spawn by JVM yang mencurigakan
4. **Network segmentation**: Istio AuthorizationPolicy dengan deny-all default untuk egress
5. **Admission control**: Kyverno — blokir pod tanpa annotation vulnerability scan

```yaml
# Kyverno — require image scan attestation
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-scan
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-sbom
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Image harus memiliki SBOM attestation"
        deny:
          conditions:
            all:
              - key: "{{ request.operation }}"
                operator: NotEquals
                value: DELETE
```

---

## Tooling Audit: kube-bench, kube-hunter, Popeye, Kubescape

### kube-bench

Benchmark keamanan Kubernetes berdasarkan **CIS Benchmark for Kubernetes**.

```bash
kube-bench run --targets node,master --version 1.29
# Output: PASS/FAIL per control — remediation untuk setiap failure
```

**Sample output:**

| Control ID | Check                                  | Status  |
| :--------- | :------------------------------------- | :-----: |
| 1.1.1      | API server --anonymous-auth=false      | ✅ PASS |
| 1.2.6      | Controller Manager --address=127.0.0.1 | ❌ FAIL |
| 4.2.1      | kubelet --anonymous-auth=false         | ❌ FAIL |

### kube-hunter

Penetration testing tool dari Aqua — mencari **eksploit path** aktif.

```bash
kube-hunter --cidr 10.0.0.0/16
kube-hunter --remote cluster.example.com
```

### Popeye

**Cluster sanitizer** — memindai resource K8s dan memberikan score numerik.

```bash
popeye --context production --out html --output-file popeye-report.html
# Score < 70: perlu intervensi segera
```

### Kubescape

Tool all-in-one dari ARMO — mencakup CIS benchmark, NSA CISA framework, MITRE ATT&CK.

```bash
kubescape scan --submit --format json framework nsa,mitre
kubescape scan framework nsa --format html -o report.html
```

**Tool comparison:**

| Tool            | Focus                  | Framework              | Output               | Scan Type           |
| :-------------- | :--------------------- | :--------------------- | :------------------- | :------------------ |
| **kube-bench**  | Node/control plane CIS | CIS Benchmark          | CLI, JSON, HTML      | Configuration audit |
| **kube-hunter** | Active exploit path    | N/A                    | CLI, JSON            | Penetration test    |
| **Popeye**      | K8s resource hygiene   | Custom scoring         | CLI, HTML, JSON      | Static analysis     |
| **Kubescape**   | Comprehensive security | NSA CISA + MITRE + CIS | CLI, JSON, HTML, PDF | Multi-framework     |

---

## Kesimpulan & Best Practices

### Defense-in-Depth untuk K8s:

```text
┌───────────────────────────────────────────────────────┐
│                    LAYER 1: CODE                        │
│   Image scanning · SBOM generation · Multi-stage      │
│   Distroless base · Cosign signing · SLSA L3+         │
├───────────────────────────────────────────────────────┤
│                    LAYER 2: ADMISSION                   │
│   Kyverno/OPA policy · Image verification             │
│   Mutating webhooks · Pod Security Standards          │
├───────────────────────────────────────────────────────┤
│                    LAYER 3: NETWORK                     │
│   Cilium NetworkPolicy · Istio mTLS · Egress control  │
│   Hubble observability · Service mesh authz           │
├───────────────────────────────────────────────────────┤
│                    LAYER 4: RUNTIME                     │
│   Falco/Tracee detection · Tetragon enforcement       │
│   eBPF syscall monitoring · Seccomp profile           │
├───────────────────────────────────────────────────────┤
│                    LAYER 5: AUDIT & COMPLIANCE          │
│   kube-bench CIS · Kubescape · SIEM integration       │
│   Audit logging · Policy reports · Metrics            │
└───────────────────────────────────────────────────────┘
```

### 10 Golden Rules:

1. **Least privilege RBAC** — mulai dengan deny-all, add permission bertahap
2. **Immutable infrastructure** — image immutable, rolling update, no exec into pods
3. **Image scanning wajib** — gate pipeline dengan Trivy/Grype (exit-code 1 jika critical)
4. **NetworkPolicy deny-all default** — allow only traffic yang diperlukan, blokir egress
5. **Secrets bukan env var** — External Secrets Operator / Vault / CSI
6. **Pod Security Standards enforced** — minimal baseline, prefer restricted
7. **Runtime detection 24/7** — Falco atau Tracee di setiap node
8. **Supply chain SLSA** — signed provenance, hermetic build, Cosign verify
9. **Zero Trust networking** — mTLS everywhere via service mesh atau Cilium
10. **Audit & scan terus-menerus** — kube-bench mingguan, Kubescape di pipeline

---

> [!NOTE] Referensi & Bacaan Lanjutan
>
> - [[comprehensive-threat-directory]] — threat modeling & attack taxonomy
> - [[ebpf-kernel-security]] — eBPF, XDP, and kernel security mechanisms
> - [[cicd-shiftleft-shiftright]] — DevSecOps pipeline implementation
> - [[web-hacking-exploitation]] — common web attacks leading to K8s compromise
> - [[it-domain-hierarchy]] — enterprise domain trust and privilege model
>
> **Dokumentasi resmi:**
>
> - [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
> - [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
> - [Falco Documentation](https://falco.org/docs/)
> - [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
> - [Kyverno Policies](https://kyverno.io/policies/)
> - [Cilium Network Policy](https://docs.cilium.io/en/latest/security/policy/)
> - [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/)
> - [CIS Benchmark for Kubernetes](https://www.cisecurity.org/benchmark/kubernetes)
