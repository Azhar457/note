---
title: "Kubernetes Architecture — Deep Dive: Control Plane, Pod Lifecycle, CNI, CSI, HPA, Operator Pattern"
tags:
  - kubernetes
  - infrastructure
  - cloud-native
  - containers
  - orchestration
aliases:
  - "kubernetes-architecture-deepdive"
created: "2026-07-18"
updated: "2026-07-18"
status: operational
cssclasses:
  - wide-table
---

# ☸️ Kubernetes Architecture — Deep Dive: Control Plane, Pod Lifecycle, CNI, CSI, HPA, Operator Pattern

> Panduan komprehensif arsitektur Kubernetes dari control plane sampai data plane. Mencakup komponen control plane (kube-apiserver, etcd, scheduler, controller-manager), node & kubelet internals, pod lifecycle & scheduling algorithm, networking dengan CNI (Calico, Cilium, Flannel), storage dengan CSI, auto-scaling (HPA/VPA/KEDA), operator pattern, dan failure modes di tiap layer. **Bukan catatan security** — itu sudah ada di [[container-kubernetes-security-deepdive]]. Catatan ini adalah fondasi arsitektur yang wajib dikuasai sebelum baca security notes.

> [!info] Posisi di Vault
> Ini adalah **fondasi platform** untuk semua catatan yang bergantung pada K8s. Baca ini dulu sebelum [[container-kubernetes-security-deepdive]] (security hardening), [[cloud-infrastructure]] (Level 4: Container Orchestration), [[cloud-security-posture-management]] (CSPM & K8s posture), [[cicd-guide]] (CI/CD di K8s), dan [[observability-stack-prometheus-grafana]] (monitoring K8s dengan Prometheus Operator).

---

## Daftar Isi

- [[#Arsitektur Control Plane]]
- [[#Node & Kubelet]]
- [[#Pod Lifecycle & Scheduling]]
- [[#Networking — CNI]]
- [[#Storage — CSI]]
- [[#Service]]
- [[#Auto-scaling — HPA / VPA / KEDA]]
- [[#Operator Pattern]]
- [[#Failure Modes]]
- [[#Koneksi ke Vault]]

---

## Arsitektur Control Plane

### Diagram Arsitektur

```
┌──────────────────── Control Plane ────────────────────┐
│                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ kube-apiserver │  │ kube-scheduler│  │controller-  │ │
│  │ (REST API)    │  │ (bind pod)   │  │ manager      │ │
│  └──────┬───────┘  └──────────────┘  └──────────────┘ │
│         │                                               │
│  ┌──────▼───────┐                                       │
│  │    etcd       │  ← source of truth                   │
│  │  (RAFT DB)   │                                       │
│  └──────────────┘                                       │
└────────────────────────────────────────────────────────┘
           │
           ▼ (kubelet on each node)
┌──────────────────── Data Plane ───────────────────────┐
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Pod      │  │ Pod      │  │ Pod      │            │
│  │ (c1, c2) │  │ (c1)     │  │ (c1,c2,c3)│           │
│  └──────────┘  └──────────┘  └──────────┘            │
│  ┌──── kubelet + kube-proxy on each node ──────────┐ │
│  │  iptables/IPVS rules for Service routing        │ │
│  └─────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

### Komponen Control Plane

| Komponen                    | Fungsi                                                                                                                              | High Availability                                                                           |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **kube-apiserver**          | Gatekeeper — semua komunikasi lewat REST API di port 6443. Validasi, autentikasi, otorisasi, admission control                      | Multiple instance (active-active) di belakang LB. Setiap instance handle request independen |
| **etcd**                    | Distributed key-value store — **satu-satunya source of truth**. Simpan semua state cluster: Pod, ConfigMap, Secret, Deployment, dll | Quorum-based (3, 5, 7 node). RAFT consensus. Wajib backup reguler                           |
| **kube-scheduler**          | Assign pod ke node yg cocok. Dua fase: Filter (eliminasi node yang ga cocok) → Score (ranking node)                                 | Leader election (1 active, N standby). Hanya 1 scheduler aktif karena stateful decision     |
| **kube-controller-manager** | Controller loop untuk resource bawaan: Deployment, ReplicaSet, Node, Endpoint, ServiceAccount, Namespace                            | Leader election (1 active per controller)                                                   |

### Flow Detail: kubectl apply -f deployment.yaml

```
1. kubectl → POST /apis/apps/v1/.../deployments → kube-apiserver
2. API Server:
   a. Authentikasi (client cert / token / OIDC)
   b. Otorisasi (RBAC: can create deployments?)
   c. Admission Control (MutatingWebhook → validate resource → ValidatingWebhook)
   d. Validasi schema (apakah spec valid?)
   e. Simpan ke etcd
3. Deployment Controller (dalam controller-manager):
   a. Watch: detect Deployment baru di etcd
   b. Reconcile: current state ≠ desired state
   c. Buat ReplicaSet object (via API Server → etcd)
4. ReplicaSet Controller:
   a. Watch: detect ReplicaSet baru
   b. Hitung: butuh N pod, current = 0
   c. Buat Pod spec (via API Server → etcd)
5. Scheduler:
   a. Watch: detect Pod tanpa node assignment (spec.nodeName = "")
   b. Filter: eliminasi node yang gak cocok
   c. Score: ranking node yang cocok
   d. Bind: update Pod dengan nodeName (via API Server → etcd)
6. Kubelet di node target:
   a. Watch: detect Pod baru dengan nodeName = namanya
   b. Validasi: apakah Pod spec valid?
   c. Pull image: dari registry
   d. Setup volume: CSI/emptyDir/hostPath
   e. Setup network: CNI plugin assign IP
   f. Start container: via CRI (containerd)
   g. Health check: liveness & readiness probe mulai jalan
```

Semua ini terjadi dalam **< 5 detik** untuk pod sederhana (tanpa image pull).

## Node & Kubelet

### Komponen Node

| Komponen                        | Fungsi                                                                                                                                                         | Port                 |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| **kubelet**                     | Primary node agent. Register node ke cluster, manage pod lifecycle, jalankan health check (liveness/readiness/startup probe), report node status ke API server | 10250 (kubelet API)  |
| **kube-proxy**                  | Network proxy per node. Maintain iptables/IPVS rules untuk Service → Pod routing. Bisa dalam mode: userspace, iptables, IPVS, atau kernelspace (eBPF)          | 10256 (health check) |
| **container runtime**           | containerd (default sejak K8s 1.24), CRI-O, atau Docker (via cri-dockerm). Implementasi CRI (Container Runtime Interface)                                      | Unix socket          |
| **cAdvisor** (built-in kubelet) | Resource metrics: CPU, memory, disk, network per container                                                                                                     | Embedded in kubelet  |

### Node Conditions

| Condition              | Arti                                       | Penyebab Umum                             |
| ---------------------- | ------------------------------------------ | ----------------------------------------- |
| **Ready**              | Kubelet sehat, pod bisa di-schedule        | Normal                                    |
| **DiskPressure**       | Disk space/nodefs/inodes < threshold       | Log gak di-rotate, image sampah, PV penuh |
| **MemoryPressure**     | RAM available < kubelet eviction threshold | Memory leak di workload                   |
| **PIDPressure**        | Terlalu banyak proses ( > kernel.pid_max ) | Fork bomb, process leak                   |
| **NetworkUnavailable** | Network plugin bermasalah                  | CNI pod crash, misconfig                  |

### Kubelet Eviction

Ketika node dalam tekanan resource, kubelet evict (terminate) pod berdasarkan QoS class:

1. **BestEffort** (tanpa request/limit) — di-evict duluan
2. **Burstable** (request < limit) — di-evict jika melebihi request
3. **Guaranteed** (request == limit) — di-evict paling akhir (hanya jika node benar2 OOM)

## Pod Lifecycle & Scheduling

### Pod Phases

```
           ┌──────────┐
           │ Pending  │
           └────┬─────┘
                │ scheduler assign node
                ▼
          ┌──────────┐
          │ Running  │ ← container started, probes passing
          └────┬─────┘
               │
      ┌────────┴────────┐
      ▼                 ▼
┌──────────┐     ┌──────────┐
│Succeeded │     │  Failed  │
│(batch)   │     │(error)   │
└──────────┘     └──────────┘

Unknown: kubelet lost contact (> node-monitor-period + node-monitor-grace-period)
```

### Init Containers

Jalankan setup task sebelum app container start. Urutan eksekusi sequential.

```yaml
initContainers:
  - name: init-db
    image: busybox
    command: ["sh", "-c", "until nc -z db-service 5432; do sleep 1; done"]
  - name: init-config
    image: busybox
    command: ["sh", "-c", "cp /config-template/* /config/"]
```

### Scheduling Algorithm Detail

#### Filtering (Predicates)

Semua predicate harus LULUS — if any fails, node dieliminasi:

- `PodFitsResources` — CPU/Mem request ≤ node allocatable
- `PodFitsHost` — nodeSelector cocok
- `PodToleratesNodeTaints` — pod tolerates taints, atau node tidak punya taint
- `CheckNodeUnschedulable` — node tidak di-cordon
- `CheckVolumeBinding` — PVC bisa di-mount di node ini
- `NodeAffinity` — required affinity rules cocok
- `PodTopologySpread` — spread constraints terpenuhi

#### Scoring (Priorities)

Setiap node yang lulus filtering diberi skor 0-100:

- `LeastRequestedPriority` — prefer node dengan resource paling longgar (spread load)
- `MostRequestedPriority` — prefer node dengan resource paling penuh (binpack)
- `BalancedResourceAllocation` — prefer node dengan resource balance (CPU = Mem)
- `NodeAffinityPriority` — preferred affinity rules
- `TaintTolerationPriority` — prefer node dengan tolerable taints

**Default strategy:** spread load across nodes (LeastRequestedPriority menang).

### Pod Disruption Budgets

Garansi jumlah minimum pod tetap running saat voluntary disruption (drain, update):

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 2 # atau maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

## Networking — CNI

### Model Jaringan K8s (3 Aturan Emas)

1. **Setiap pod punya IP unik** (dalam cluster)
2. **Semua pod bisa komunikasi** dengan pod lain tanpa NAT
3. **Agent (kubelet/scheduler) bisa komunikasi** dengan semua pod

### CNI Plugin Architecture

```
Pod -> veth pair -> cni0/eth0 (bridge) -> node routing table -> overlay tunnel -> destination node
```

### CNI Plugin Comparison

| Plugin          | Data Plane    | Overhead      | NetworkPolicy | Fitur Kunci                                                | Best For                              |
| --------------- | ------------- | ------------- | ------------- | ---------------------------------------------------------- | ------------------------------------- |
| **Flannel**     | VXLAN         | Rendah        | ❌ Tidak      | Simple, VXLAN/ host-gw                                     | Dev/lab, small cluster                |
| **Calico**      | BGP / eBPF    | Rendah-Sedang | ✅ Ya         | NetworkPolicy, wireguard encryption, no overlay            | Production on-prem, hybrid            |
| **Cilium**      | eBPF          | Sangat Rendah | ✅ Ya (L3-L7) | Hubble observability, service mesh L7 policy, cluster mesh | Modern production, security-sensitive |
| **Weave**       | Fast datapath | Rendah        | ✅ Ya         | Encrypt otomatis, simple                                   | Small-mid cluster                     |
| **OVN-K8s**     | OVS           | Sedang        | ✅ Ya         | Distribusi OpenShift, multi-tenant                         | Enterprise OpenShift                  |
| **kube-router** | BGP           | Rendah        | ✅ Ya         | All-in-one (CNI + network policy + service proxy)          | Sederhana, all-in-one                 |

### Service Types

| Type                           | Akses                     | Use Case                   |
| ------------------------------ | ------------------------- | -------------------------- |
| **ClusterIP**                  | Internal cluster only     | Internal microservices     |
| **NodePort**                   | External via node IP:port | Dev/test, direct access    |
| **LoadBalancer**               | External via cloud LB     | Production HTTP services   |
| **ExternalName**               | DNS CNAME alias           | Integrasi external service |
| **Headless** (ClusterIP: None) | DNS-based pod discovery   | StatefulSet, database      |

## Storage — CSI

### Volume Types

| Type                      | Lifespan             | Use Case                                |
| ------------------------- | -------------------- | --------------------------------------- |
| **emptyDir**              | Sama dengan pod      | Cache, temporary workspace              |
| **hostPath**              | Sama dengan node     | Log access, device access (single node) |
| **configMap/secret**      | Sama dengan pod      | Konfigurasi, credential                 |
| **PersistentVolume (PV)** | Terpisah dari pod    | Database, persistent data               |
| **StorageClass**          | Dynamic provisioning | Auto-create PV saat PVC request         |

### CSI Flow

```
Pod spec → PVC → StorageClass → CSI Driver → Cloud API → Volume → Attach → Mount → Pod ready
```

## Auto-scaling — HPA / VPA / KEDA

| Mekanisme               | Metrik                                                        | Trigger                              | Scale                                            | Cooldown             |
| ----------------------- | ------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------ | -------------------- |
| **HPA** (Horizontal)    | CPU, Memory, Custom Metrics, External Metrics                 | Target utilization > threshold       | Tambah/kurang replica pod                        | Default 3-5 menit    |
| **VPA** (Vertical)      | Resource usage history                                        | Request/limit jauh dari actual usage | Update CPU/Mem request & limit                   | 24 jam (rekomendasi) |
| **KEDA** (Event-driven) | Queue length (Kafka, RabbitMQ, SQS), cron, Prometheus, custom | External event source                | Tambah/kurang replica (deploy, statefulset, job) | Configurable         |

### HPA Formula

```
desiredReplicas = ceil[currentReplicas * (currentMetricValue / desiredMetricValue)]
```

### VPA Modes

- **Off** — hanya rekomendasi, tidak auto-apply
- **Auto** — update pod (evict + recreate dengan request/limit baru)
- **Initial** — apply hanya saat pod pertama kali dibuat
- **Recreate** — sama dengan Auto tapi evict pod (bisa disruptif)

## Operator Pattern

Operator = **Custom Controller + Custom Resource Definition (CRD)** — manusia yang mengoperasikan aplikasi dalam kode.

### Komponen Operator

1. **CRD** — define custom resource (e.g., `PostgresCluster`, `RedisFailover`)
2. **Controller** — watch CRD + reconcile (compare current vs desired state)
3. **RBAC** — permission untuk manage resource terkait

### Contoh: Prometheus Operator

```
User buat ServiceMonitor CR → Operator detect → Operator buat/mutate Prometheus config → Prometheus scrape target baru
```

### Operator Maturity Level

| Level | Kemampuan        | Contoh                                             |
| ----- | ---------------- | -------------------------------------------------- |
| L1    | Basic install    | Helm install                                       |
| L2    | Seamless upgrade | Operator upgrade CR                                |
| L3    | Full lifecycle   | Backup, restore, failure recovery                  |
| L4    | Deep insights    | Metrics, alerts, logging                           |
| L5    | Auto-pilot       | Horizontal scaling, auto-tuning, anomaly detection |

## Failure Modes

| Layer          | Failure Mode                                           | Symptom                       | Mitigation                            |
| -------------- | ------------------------------------------------------ | ----------------------------- | ------------------------------------- |
| **etcd**       | Quorum loss (leader election failed)                   | API server read-only          | 3+ node etcd, regular backup          |
| **API Server** | Admission webhook timeout                              | All API calls slow            | Timeout config, webhook HA            |
| **Scheduler**  | Failed to bind pod                                     | Pod stuck in Pending          | Multiple scheduler replicas           |
| **Kubelet**    | Dead node (NotReady)                                   | Pod stuck in Terminating      | PodDisruptionBudget, node auto-repair |
| **CNI**        | IP exhaustion                                          | Pod CrashLoopBackOff          | IPAM planning, secondary CIDR         |
| **CSI**        | Volume attach timeout                                  | Pod ContainerCreating > 5 min | CSI driver HA, storage backend health |
| **HPA**        | Metrics pipeline broken (metrics-server/cAdvisor down) | No auto-scale                 | Pod default resource, PDB             |

---

## Koneksi ke Vault

- [[container-kubernetes-security-deepdive]] — Security hardening, admission control, RBAC, Pod Security Standards, NSA hardening guide
- [[cloud-infrastructure]] — Level 4: Container Orchestration dalam hierarki cloud infra
- [[cloud-security-posture-management]] — CSPM untuk K8s, Kube-bench, Kube-hunter
- [[cicd-guide]] — CI/CD pipeline di K8s (GitOps, ArgoCD, Flux)
- [[observability-stack-prometheus-grafana]] — Prometheus Operator, kube-state-metrics, node-exporter
- [[cicd-shiftleft-shiftright]] — DevSecOps: shift security left ke container build
- [[podman-networking-ufw]] — Container networking & firewall (practical companion untuk rootless podman)
