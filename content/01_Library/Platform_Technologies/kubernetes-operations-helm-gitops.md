---
title: "Kubernetes Operations — Helm, GitOps, Service Mesh & Production Lifecycle"
tags:
  - kubernetes
  - operations
  - helm
  - gitops
  - service-mesh
  - library
aliases:
  - "k8s-operations-guide"
  - "kubernetes-helm-gitops"
  - "k8s-production-practices"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# ☸️ Kubernetes Operations — Helm, GitOps, Service Mesh & Production Lifecycle

> Vault udah punya [[kubernetes-architecture-deepdive]] (cara kerja internal K8s) dan [[container-kubernetes-security-deepdive]] (security side). Tapi belum ada yang cover **operational side — bagaimana menjalankan cluster di production: Helm chart management, GitOps dengan ArgoCD/Flux, service mesh untuk traffic management, HPA/KEDA autoscaling, backup/restore cluster, dan upgrade lifecycle**. Catatan ini adalah jembatan dari "tahu cara kerja K8s" ke "bisa operasin K8s di production".

> [!info] Posisi di Vault
> Ini adalah **operational layer** di atas [[kubernetes-architecture-deepdive]] (teori) dan [[container-kubernetes-security-deepdive]] (keamanan). Juga terkait dengan [[cicd-guide]] (CI/CD), [[observability-stack-prometheus-grafana]] (monitoring), [[devops]], dan [[platform-technologies-overview]].

---

## Daftar Isi

- [[#1. Cluster Lifecycle — Kubeadm vs Managed, Upgrade, Backup]]
- [[#2. Workload Management — Deployment, StatefulSet, DaemonSet]]
- [[#3. Helm — Chart Structure, Values, Registry]]
- [[#4. GitOps — ArgoCD vs Flux]]
- [[#5. Service Mesh — Istio, Cilium, Linkerd]]
- [[#6. Storage — CSI, PVC, StorageClass]]
- [[#7. Ingress & Gateway API]]
- [[#8. Autoscaling — HPA, VPA, KEDA, Karpenter]]
- [[#9. Security — Pod Security, NetworkPolicy, OPA]]
- [[#10. Observability — Metrics, Logging, Tracing, Cost]]
- [[🔗 Koneksi ke Catatan Lain]]
- [[✅ Checklist]]
- [[Roadmap Belajar]]

---

## 1. Cluster Lifecycle — Kubeadm vs Managed, Upgrade, Backup

### 1.1 Bootstrap Options

| Method | Setup Time | Control Plane | Maintenance | Use Case |
|:-------|:----------:|:--------------|:------------|:---------|
| **Kubeadm** | 30-60 min | Self-managed | Manual upgrades | On-prem, homelab |
| **K3s** | 5 min | Self-managed (embedded etcd) | Simple | Edge, IoT, homelab |
| **EKS** | 15 min | AWS-managed | Easy (managed) | AWS production |
| **AKS** | 15 min | Azure-managed | Easy | Azure shop |
| **GKE** | 10 min | Google-managed | Auto-upgrade option | GCP shop |
| **Talos** | 20 min | Self-managed (API-driven OS) | Minimal | Security-fwd on-prem |

### 1.2 Cluster Upgrade Strategy

```text
Kubeadm upgrade path:
  1.26 → 1.27 → 1.28 → 1.29 (tidak bisa skip minor!)
  
  Control plane: drain control-plane, upgrade kubeadm + kubelet, uncordon
  Worker nodes: drain, upgrade, uncordon (rolling, satu per satu)

Managed K8s (EKS/AKS/GKE):
  - EKS: eksctl upgrade cluster — rolling update otomatis
  - GKE: node pool upgrade — surge upgrade (tambah node baru, drain lama)

Golden rule:
  - Jangan upgrade langsung ke latest — tunggu 1-2 minor version
  - Selalu backup etcd sebelum upgrade control plane
  - Test upgrade di staging cluster dulu
```

### 1.3 Backup & Restore

```yaml
# etcd backup (control plane state)
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db
# restore:
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db

# Velero (full cluster backup + PV)
velero install --provider aws --bucket k8s-backups --secret-file ./credentials.aws
velero backup create cluster-backup-$(date +%Y%m%d) --include-namespaces prod
velero restore create --from-backup cluster-backup-20260719
```

---

## 2. Workload Management — Deployment, StatefulSet, DaemonSet

### 2.1 Workload Types

| Type | Use Case | Identity | Ordering | Storage |
|:-----|:---------|:---------|:---------|:--------|
| **Deployment** | Stateless apps | Random pod name | Rolling update | Shared/empty |
| **StatefulSet** | Stateful apps (DB, queue) | Stable network ID | Ordered pod management | unique PVC per pod |
| **DaemonSet** | Node-level agent (metrics, logging) | One per node | N/A | hostPath |
| **Job** | Batch task | Runs to completion | N/A | empty/temp |
| **CronJob** | Scheduled task | Runs on schedule | N/A | empty/temp |

### 2.2 Common Pitfalls

```yaml
# Pitfall 1: Gak set resource limits
# → Node pressure, OOMKill pod lain
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: "2"
    memory: 2Gi

# Pitfall 2: Gak set pod disruption budget
# → Node drain bisa kill semua replica
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-service

# Pitfall 3: StatefulSet tanpa headless service
# → Pod gak bisa resolve DNS ke identity tetap
apiVersion: v1
kind: Service
metadata:
  name: my-db
spec:
  clusterIP: None  # headless
  selector:
    app: my-db
```

---

## 3. Helm — Chart Structure, Values, Registry

### 3.1 Chart Structure

```
mychart/
├── Chart.yaml          # metadata: name, version, apiVersion, dependencies
├── values.yaml         # default values
├── values.schema.json  # JSON Schema validation for values (Helm 3+)
├── charts/             # dependency charts (helm dependency update)
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── _helpers.tpl    # template helper functions
│   └── NOTES.txt       # post-install message
└── crds/               # CustomResourceDefinitions (install first)
```

### 3.2 Values Management

```yaml
# values.yaml — environment-specific override
replicaCount: 3
image:
  repository: nginx
  tag: stable
service:
  port: 80
ingress:
  enabled: true
  host: app.example.com

# Install dengan override:
helm install my-release ./mychart \
  --set image.tag=v1.2.3 \
  --set replicaCount=5 \
  -f prod-values.yaml
```

### 3.3 Chart Registry & Distribution

```bash
# OCI-based registry (Helm 3.8+)
helm package ./mychart
helm push mychart-0.1.0.tgz oci://registry.example.com/helm-charts

# Install dari OCI
helm install my-release oci://registry.example.com/helm-charts/mychart --version 0.1.0

# Dependency management
# Chart.yaml:
dependencies:
  - name: postgresql
    version: "12.x"
    repository: https://charts.bitnami.com/bitnami
```

### 3.4 Advanced Patterns

```go
// _helpers.tpl — template functions
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

// Conditional block: hanya deploy kalau enabled
{{- if .Values.metrics.enabled }}
apiVersion: v1
kind: ServiceMonitor
...
{{- end }}
```

---

## 4. GitOps — ArgoCD vs Flux

### 4.1 GitOps Principles

```
1. Declarative — seluruh system state didefinisikan dalam Git
2. Versioned & Immutable — Git adalah single source of truth
3. Pulled — operator di cluster pull dari Git, gak push dari CI
4. Continuously Reconciled — cluster selalu berusaha match Git state
```

### 4.2 ArgoCD vs Flux

| Aspek | ArgoCD | Flux v2 |
|:------|:-------|:--------|
| **Arsitektur** | Controller + API Server + UI | Controller-only (no API server) |
| **UI** | ✅ Dashboard built-in | ❌ (CLI-only, bisa integrasi Grafana) |
| **Sync Strategy** | Manual/auto sync + prune | Auto-reconcile via Source Controller |
| **Multi-cluster** | Via ApplicationSet + Cluster Secret | Via Kustomization dengan kubeconfig |
| **Secrets** | SealedSecrets, External Secrets, SOPS | SOPS native, SealedSecrets, External Secrets |
| **Rollback** | Git revert (auto-detect) | Git revert (auto-reconcile) |
| **Learning Curve** | Sedang | Rendah |
| **Health Check** | Built-in (resource status) | Via kstatus library |

### 4.3 ArgoCD Application Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-production
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/org/my-app-config.git
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
```

### 4.4 Flux Kustomization Example

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/org/my-app-config.git
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  path: ./overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-app
  decryption:
    provider: sops
    secretRef:
      name: sops-gpg
```

---

## 5. Service Mesh — Istio, Cilium, Linkerd

### 5.1 Service Mesh Functions

```
┌─────────────────────────────────────┐
│              Service Mesh           │
├─────────────────────────────────────┤
│  Traffic: routing, split, mirror    │
│  Security: mTLS, authz, authn       │
│  Observability: metrics, tracing    │
│  Resilience: retry, circuit breaker │
└─────────────────────────────────────┘
         ↓                     ↓
    Sidecar Proxy         eBPF-based
    (Envoy)              (Cilium)
```

### 5.2 Comparison

| Aspek | Istio | Cilium | Linkerd |
|:------|:------|:-------|:--------|
| **Data Plane** | Envoy (sidecar) | eBPF (kernel-level) | Linkerd2-proxy (Rust) |
| **Control Plane** | istiod | Cilium Agent | destination + identity |
| **mTLS** | Auto (Istio CA) | Auto (eBPF + SPIRE) | Auto (Linkerd identity) |
| **Performance** | 🟡 5-10% overhead | 🟢 <3% overhead | 🟢 <5% overhead |
| **Complexity** | Tinggi (CRD + config) | Sedang | Rendah |
| **Multi-cluster** | ✅ Native | ✅ | 🟡 (extensions needed) |

---

## 🔗 Koneksi ke Catatan Lain

| Catatan | Koneksi |
|:--------|:--------|
| [[kubernetes-architecture-deepdive]] | Arsitektur & teori K8s |
| [[container-kubernetes-security-deepdive]] | Keamanan K8s |
| [[cicd-guide]] | CI/CD yang feed ke GitOps |
| [[observability-stack-prometheus-grafana]] | Monitoring K8s |
| [[platform-technologies-overview]] | K8s dalam ekosistem platform |
| [[devops]] | Prinsip operasi |

---

## ✅ Checklist

- [ ] Paham perbedaan kubeadm vs managed K8s
- [ ] Bisa setup Helm chart dengan dependency
- [ ] Paham GitOps pattern dengan ArgoCD/Flux
- [ ] Tau kapan perlu service mesh dan kapan tidak
- [ ] Bisa setup HPA + VPA + KEDA autoscaling
- [ ] Paham zero-downtime upgrade strategy
- [ ] Setup Velero backup & restore
- [ ] Paham Ingress vs Gateway API

---

## Roadmap Belajar

```
HARI 1: Cluster Setup
  - Setup K3s/Kubeadm cluster (3 node)
  - Deploy sample app, test rolling update
  - Backup & restore etcd

HARI 2: Helm & Package Management
  - Buat Helm chart dari 0
  - Deploy dengan values override
  - Setup OCI registry

HARI 3: GitOps
  - Setup ArgoCD atau Flux
  - Bootstrap cluster with GitOps
  - Test disaster recovery (nuke cluster + restore from Git)

HARI 4: Service Mesh
  - Install Linkerd/Istio di cluster test
  - Enable mTLS, test traffic split
  - Benchmark overhead

HARI 5: Production Readiness
  - Setup HPA + KEDA + Cluster Autoscaler
  - Setup Velero backup schedule
  - Chaos Engineering: kill node, partition network
```

> [!warning] Bottom Line
> Kubernetes operations is a **discipline, not a tool**. Helm manages packages, GitOps manages state, service mesh manages traffic — masing-masing solving problem yang berbeda. Jangan deploy service mesh kalau cuma punya 3 service. Jangan pake ArgoCD kalau tim masih kirim manifest via kubectl apply. Operational maturity bertahap: manual → scripts → Helm → GitOps → Platform Engineering.

> [!tip] Lanjutan
> Terkait dengan [[container-kubernetes-security-deepdive]] (security layer), [[observability-stack-prometheus-grafana]] (monitoring stack), dan [[cicd-guide]] (CI/CD pipeline yang feed ke GitOps).
