---
title: Kubernetes Learning Roadmap — From Local Pods to Multi-Tenant Production Clusters
tags:
- platform-engineering
- kubernetes
- devops
- containers
- cloud-native
- roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Menguasai orkestrasi kontainer membutuhkan pemahaman bertahap dari level abstraksi terkecil (Pod) hingga koordinasi cluster skala besar. Catatan ini dirancang sebagai peta jalan belajar praktis yang melengkapi pembahasan arsitektur teoretis [[kubernetes-architecture-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Setup Lokal & Objek Dasar (Pod, Deployment, Service)](#2-fase-1-setup-lokal--objek-dasar-pod-deployment-service)
3. [Fase 2: Konfigurasi & Penyimpanan Persisten](#3-fase-2-konfigurasi--penyimpanan-persisten)
4. [Fase 3: Routing Canggih & Keamanan Jaringan (Network Policy)](#4-fase-3-routing-canggih--keamanan-jaringan-network-policy)
5. [Fase 4: GitOps & Hardening Keamanan Cluster Produksi](#5-fase-4-gitops--hardening-keamanan-cluster-produksi)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini menuntun Anda dari setup kontainer tunggal hingga manajemen cluster enterprise:

```
[Fase 1: Objek Dasar] ──> [Fase 2: State & Storage] ──> [Fase 3: Traffic Control] ──> [Fase 4: Production Hardening]
- minikube / kind        - ConfigMap & Secret           - Ingress Controller        - Network Policies
- Pod, ReplicaSet, Deploy - Persistent Volume (PV)       - CNI (Calico / Cilium)     - GitOps (ArgoCD)
- ClusterIP, NodePort     - StorageClass (dynamic provisioning) - Service Mesh (Istio) - Seccomp & AppArmor
```

---

## 2. Fase 1: Setup Lokal & Objek Dasar (Pod, Deployment, Service)

### 2.1 Setup Lingkungan Lokal
Gunakan **Kind (Kubernetes in Docker)** atau **Minikube** untuk membuat cluster mini di lokal komputer Anda:
```bash
# Instal Kind (menggunakan homebrew / go)
brew install kind

# Buat cluster dengan konfigurasi multi-node (1 control-plane, 2 workers)
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
kind create cluster --config kind-config.yaml
```

### 2.2 Menulis Manifest Deployment Pertama
Deployment bertugas mengelola siklus hidup Pod dan melakukan update aplikasi secara aman (*Rolling Update*).

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-web
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - containerPort: 80
```
Terapkan manifest ke dalam cluster:
```bash
kubectl apply -f deployment.yaml
kubectl get pods -o wide
```

---

## 3. Fase 2: Konfigurasi & Penyimpanan Persisten

Aplikasi stateful membutuhkan penyimpanan data yang tidak hilang saat Pod mengalami crash/dihapus.

### 3.1 Konfigurasi Penyimpanan Dinamis
Buat **PersistentVolumeClaim (PVC)** agar Kubernetes otomatis menyusun disk penyimpanan (*PersistentVolume* - PV) melalui *StorageClass*:

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### 3.2 Memasang Volume ke Kontainer
Pasang PVC yang telah dideklarasikan ke dalam spesifikasi Pod:

```yaml
# deployment-db.yaml (potongan spec)
spec:
  containers:
  - name: postgres
    image: postgres:16
    volumeMounts:
    - mountPath: "/var/lib/postgresql/data"
      name: db-volume
  volumes:
  - name: db-volume
    persistentVolumeClaim:
      claimName: db-storage-claim
```

---

## 4. Fase 3: Routing Canggih & Keamanan Jaringan (Network Policy)

Secara default, seluruh Pod di dalam cluster Kubernetes dapat saling berkomunikasi tanpa batasan. Di lingkungan produksi, ini sangat berbahaya.

### 4.1 Mengunci Jaringan menggunakan Network Policy
Berikut adalah kebijakan jaringan (*Network Policy*) untuk membatasi agar Pod Database (`app: db`) **hanya menerima koneksi** dari Pod Backend (`app: backend`), dan menolak koneksi lainnya:

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-only-backend
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
```

---

## 5. Fase 4: GitOps & Hardening Keamanan Cluster Produksi

### 5.1 Siklus Deploy Berbasis GitOps (ArgoCD)
ArgoCD memantau repositori Git Anda. Jika ada perubahan tag image di file manifest Git, ArgoCD otomatis menyinkronkan status di cluster Kubernetes agar sama dengan repositori Git (*single source of truth*).

### 5.2 Hardening Keamanan Kontainer (SecurityContext)
Pastikan kontainer di produksi tidak berjalan dengan hak akses root dan tidak memiliki akses ke kernel host:

```yaml
# hardened-pod.yaml (potongan spec)
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
  containers:
  - name: app
    image: myapp:secure
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Apa perbedaan mendasar antara Service jenis `ClusterIP`, `NodePort`, dan `LoadBalancer`? Kapan waktu yang tepat memilih masing-masing jenis tersebut?

**Solusi**

| Jenis Service | Cara Kerja | Use Case Utama |
|---|---|---|
| **ClusterIP** | Memberikan alamat IP internal cluster yang stabil. Service ini hanya dapat diakses dari dalam cluster. | Komunikasi antar-layanan internal (misal: backend menghubungi database). |
| **NodePort** | Membuka port statis pada setiap Node cluster (port rentang 30000-32767). Trafik ke port tersebut diteruskan ke Pod. | Pengujian awal atau integrasi cepat dengan load balancer luar cluster secara manual. |
| **LoadBalancer**| Menghubungi API cloud provider (AWS/GCP) untuk membuat Load Balancer fisik luar cluster yang mengarahkan trafik ke NodePort. | Membuka layanan internal agar bisa diakses oleh publik di internet (misal: API Gateway). |

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[kubernetes-architecture-deepdive]] | Dasar teori arsitektur control-plane (api-server, etcd, scheduler) dan worker node (kubelet, kube-proxy). |
| [[container-security-exploitation-deepdive]] | Vektor serangan melarikan diri dari kontainer (*container escape*) dan hardening namespace. |
| [[network-security]] | Konsep dasar routing, CIDR block, dan enkripsi jaringan TLS. |
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

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
