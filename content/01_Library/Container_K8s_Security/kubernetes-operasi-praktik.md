---
title: Kubernetes Operasi Praktik — Deployment, Service, Ingress & Daily Ops
tags:
  - kubernetes
  - k8s
  - devops
  - container
  - orchestration
  - kubectl
  - deployment
  - library
aliases:
  - K8s Daily Commands
  - Kubernetes Deployment Guide
  - kubectl Cheatsheet
created: "2026-07-30"
updated: "2026-07-30"
status: completed
cssclasses:
  - wide-table
---

# ☸️ Kubernetes Operasi Praktik — Deployment, Service, Ingress & Daily Ops

> Panduan operasional Kubernetes dari nol: bikin deployment, expose service, setup ingress, scaling, rolling update, debugging, sampai daily ops dengan kubectl. Bukan teori arsitektur — ini command-by-command yang bisa langsung dipake. Vault udah punya [[container-kubernetes-security-deepdive]] (keamanan K8s) dan [[kubernetes-architecture-deepdive]] (arsitektur) — catatan ini fokus ke **operasi sehari-hari**.

## Daftar Isi

1. [[#1. Prasyarat — kubectl & Kubeconfig]]
2. [[#2. Namespace — Organizing Cluster]]
3. [[#3. Pod — Unit Terkecil]]
4. [[#4. Deployment — Stateless Application]]
5. [[#5. Service — Networking Dasar]]
6. [[#6. Ingress — Traffic Masuk]]
7. [[#6b. Network Policy — Zero-Trust Antar Pod]]
8. [[#7. ConfigMap & Secret — Konfigurasi]]
9. [[#8. Persistence — PVC & Storage]]
10. [[#9. Scaling & Rolling Update]]
11. [[#10. Debugging — Daily Ops]]
12. [[#11. kubectl Plugins & Tools]]
13. [[#12. Koneksi ke Vault]]

---

## 1. Prasyarat — kubectl & Kubeconfig

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Auto-completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# Cek koneksi ke cluster
kubectl cluster-info
kubectl get nodes
kubectl version --short
```

### Struktur Kubeconfig

```yaml
# ~/.kube/config
apiVersion: v1
clusters:
  - cluster:
      server: https://<API_SERVER>:6443
      certificate-authority-data: <base64-ca>
    name: my-cluster
contexts:
  - context:
      cluster: my-cluster
      user: admin
      namespace: production # default namespace
    name: admin@my-cluster
current-context: admin@my-cluster
```

Multi-cluster:

```bash
kubectl config get-contexts              # lihat semua context
kubectl config use-context prod-cluster  # switch cluster
kubectl config set-context --current --namespace=staging  # switch namespace
```

### Merging & Multiple Kubeconfig

Kubeconfig bisa digabung dari beberapa file — berguna kalau punya cluster dari provider berbeda (DOKS, AKS, EKS, local kind/minikube).

```bash
# Merge via KUBECONFIG env var (paling aman, gak ngerusak file asli)
export KUBECONFIG=~/.kube/config-do:~/.kube/config-aks:~/.kube/config-kind
kubectl config view --flatten > ~/.kube/config  # merge permanen

# Lihat context yang tersedia + cluster mana
kubectl config get-contexts
kubectl config current-context

# Switch cepat antar cluster
kubectl config use-context admin@do-nyc3
kubectl config use-context admin@aks-prod

# Set namespace default per context
kubectl config set-context admin@do-nyc3 --namespace=production

# Export config terkompresi (buat share, tanpa cert basah)
kubectl config view --minify --flatten > ~/cluster-prod.kubeconfig

# Lihat detail server & user dari context aktif
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Multiple cluster dalam satu perintah (gak perlu switch context)
kubectl get pods --context=admin@do-nyc3 -n production
kubectl get nodes --context=admin@aks-prod
```

> [!tip] Simpan kubeconfig asli tiap cluster di `~/.kube/config.d/` terus merge via KUBECONFIG env aja — lebih modular dan aman kalau satu cluster mati koneksinya.

---

## 2. Namespace — Organizing Cluster

Namespace = virtual cluster di dalam satu physical cluster.

```bash
# List & create
kubectl get namespaces
kubectl create namespace production
kubectl create namespace staging

# Better: YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF

# Context dengan default namespace
kubectl config set-context --current --namespace=production

# Resource quota — batasi resource per namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    requests.cpu: 4
    requests.memory: 8Gi
    limits.cpu: 8
    limits.memory: 16Gi
    persistentvolumeclaims: 5
    pods: 20
EOF
```

### LimitRange — Batasan Default per Pod

LimitRange menetapkan batas default dan range resource tiap container di namespace — mencegah pod boros atau terlalu kecil tanpa request/limits.

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: prod-limits
  namespace: production
spec:
  limits:
  - max:                                 # maksimal per container
      cpu: 2
      memory: 2Gi
    min:                                 # minimal per container
      cpu: 50m
      memory: 64Mi
    default:                             # default limits (kalo gak specify)
      cpu: 500m
      memory: 512Mi
    defaultRequest:                      # default request (kalo gak specify)
      cpu: 200m
      memory: 256Mi
    type: Container
EOF
```

Kombinasi ResourceQuota + LimitRange = resource governance yang solid: quota batasi total namespace, LimitRange set default & range tiap container.

---

## 3. Pod — Unit Terkecil

Pod = 1+ container yang jalan bareng (share network namespace + volumes).

```yaml
# pod-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    tier: frontend
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 3
        periodSeconds: 5
```

```bash
# CRUD Pod
kubectl apply -f pod-nginx.yaml
kubectl get pods -o wide
kubectl describe pod nginx-pod
kubectl logs nginx-pod -f
kubectl exec -it nginx-pod -- sh
kubectl delete pod nginx-pod
```

> [!tip] Pod biasanya gak dibuat langsung — pake Deployment biar auto-heal!

### Pod Lifecycle — States & Transitions

Pod melewati siklus status yang merefleksikan kondisi container di dalamnya:

| Phase         | Deskripsi                               | Penyebab Umum                                         |
| ------------- | --------------------------------------- | ----------------------------------------------------- |
| **Pending**   | Pod diterima API, tapi belum siap jalan | Image belum di-pull, node penuh resource, PVC pending |
| **Running**   | Semua container berjalan                | Normal operation                                      |
| **Succeeded** | Semua container exit 0 (job/batch)      | Task selesai normal                                   |
| **Failed**    | Ada container exit non-0                | Aplikasi crash, config salah, OOM                     |
| **Unknown**   | Node gak bisa komunikasi dengan API     | Node down, network partition, kubelet mati            |

> **CrashLoopBackOff** bukan phase — itu kondisi di container yang gagal startup berulang kali. Kubelet kasih backoff: 10s → 20s → 40s → 80s → 160s → 300s (max).

```bash
# Tracking lifecycle
kubectl get pods -w
kubectl get pod <name> -o jsonpath='{.status.phase}'
kubectl get pod <name> -o jsonpath='{.status.containerStatuses[0].state}'
kubectl wait --for=condition=Ready pod/<name> --timeout=60s
kubectl wait --for=condition=ContainersReady pod/<name>
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/<name>
```

### Init Containers

Init container jalan **sebelum** container utama — cocok untuk setup, migration, atau pre-flight check.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
spec:
  initContainers:
    - name: init-db
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          until nc -z db-service 5432; do
            echo "Menunggu database..."
            sleep 2
          done
          echo "Database siap!"
    - name: init-migration
      image: myapp/migrate:1.0
      command: ["/migrate", "--up"]
      env:
        - name: DB_URL
          value: postgres://user:pass@db-service:5432/app
  containers:
    - name: app
      image: myapp/api:1.0.0
      ports:
        - containerPort: 3000
```

**Aturan Init Container:**

- Jalan serial (satu per satu)
- Hanya satu yang jalan dalam satu waktu
- Kalau gagal (exit non-0), restartPolicy=Always → restart semua init dari awal
- Lebih hemat resource — gak pakai readiness/liveness probe
- Bisa pakai volume mount dan secrets seperti container biasa

> [!tip] Init container bagus buat wait-for-dependency (database siap, cache warmup), migration DB, download plugin, atau setup permission.

### Sidecar Pattern

Sidecar = container pendamping yang jalan bareng pod utama, share network + volume. Bedanya dari init container: sidecar jalan **bersamaan** dengan container utama.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-with-sidecar
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      volumes:
        - name: logs
          emptyDir: {}
      containers:
        - name: api
          image: myapp/api:1.0.0
          volumeMounts:
            - name: logs
              mountPath: /var/log/app
        - name: log-sidecar # sidecar container
          image: busybox:1.36
          command: ["sh", "-c", "tail -f /var/log/app/*.log"]
          volumeMounts:
            - name: logs
              mountPath: /var/log/app
```

**Use cases sidecar:**

- Log shipper (Fluentbit, Filebeat)
- Service mesh proxy (Envoy, Linkerd)
- Reverse proxy / local cache
- Config reloader (Prometheus config reloader)
- Secret injector (Vault Agent sidecar)

> [!warning] Sidecar meningkatkan resource consumption per pod. Kalau ada 50 pod, artinya 50 sidecar container juga jalan — monitor total resource usage!

### Probes: Readiness vs Liveness vs Startup

| Probe         | Tujuan                                | Kalau Gagal                              | Best for                               |
| ------------- | ------------------------------------- | ---------------------------------------- | -------------------------------------- |
| **Liveness**  | Apakah container masih hidup?         | Kubelet restart container                | Cek deadlock, infinite loop            |
| **Readiness** | Apakah container siap terima traffic? | Hapus dari Service endpoints             | App baru selesai startup, butuh warmup |
| **Startup**   | Apakah container sudah start?         | Kubelet restart, tapi **tunda** liveness | App dengan startup lambat (>60s)       |

```yaml
# Contoh: app dengan startup lambat butuh startup probe
containers:
  - name: heavy-app
    image: myapp/analytics:2.0
    startupProbe: # pertama kali dicek — beri waktu 2 menit
      httpGet:
        path: /health/startup
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 30 # 30 × 5s = 150s toleransi startup
    livenessProbe: # setelah startup OK, liveness mulai
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 15
      failureThreshold: 3 # 3 × 15s = 45s gak respon = restart
    readinessProbe: # traffic routing
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
      successThreshold: 1
```

**Urutan eksekusi probe:**

1. `startupProbe` jalan duluan — kalau gak di-set, semua probe mulai dari awal
2. Setelah startup sukses, `livenessProbe` + `readinessProbe` jalan normal
3. `livenessProbe` gagal → kubelet kill & restart container
4. `readinessProbe` gagal → service load balancer hapus pod dari rotasi (tapi container tetep jalan)
5. `successThreshold` default = 1; `failureThreshold` default = 3

> [!tip] Hemat resources: mulai dengan probe yang ringan. Hindari pake endpoint berat (full page render). HTTP probe lebih murah daripada exec/tcp, tapi kena overhead koneksi.

---

## 4. Deployment — Stateless Application

### Deployment Dasar

```yaml
# deployment-api.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: myapp/api:1.0.0
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
          resources:
            requests: { cpu: 250m, memory: 256Mi }
            limits: { cpu: 500m, memory: 512Mi }
          readinessProbe:
            httpGet: { path: /health, port: 3000 }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: /health, port: 3000 }
            initialDelaySeconds: 15
            periodSeconds: 20
      imagePullSecrets:
        - name: regcred
```

### Deployment Strategies

```yaml
# Rolling update (default)
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # maksimal 1 pod tambahan selama update
      maxUnavailable: 0 # 0 = zero-downtime

# Recreate (down-time)
spec:
  strategy:
    type: Recreate # kill semua dulu, baru buat baru
```

### Rollout Commands

```bash
kubectl apply -f deployment-api.yaml
kubectl rollout status deployment/api-service
kubectl rollout history deployment/api-service

# Update image (triggers rollout)
kubectl set image deployment/api-service api=myapp/api:1.1.0

# Rollback
kubectl rollout undo deployment/api-service          # ke revisi sebelumnya
kubectl rollout undo deployment/api-service --to-revision=2

# Pause & resume (canary)
kubectl rollout pause deployment/api-service
# ... ubah sebagian ...
kubectl rollout resume deployment/api-service
```

---

## 5. Service — Networking Dasar

Service = abstraksi network di depan Pod (yang IP-nya dinamis).

### Tipe Service

| Tipe             | Use Case                        | Contoh              |
| ---------------- | ------------------------------- | ------------------- |
| **ClusterIP**    | Internal cluster only           | Database backend    |
| **NodePort**     | Akses dari luar via NodeIP:Port | Testing/development |
| **LoadBalancer** | Cloud LB integration            | Production di cloud |
| **ExternalName** | DNS alias ke external service   | Legacy integration  |

```yaml
# service-api.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api # match label di Pod/Deployment
  ports:
    - port: 80 # service port
      targetPort: 3000 # container port
      protocol: TCP
  type: ClusterIP # default
```

```bash
# Test service
kubectl port-forward svc/api-service 8080:80   # forward localhost:8080 → service:80
curl http://localhost:8080/health
kubectl get endpoints api-service               # lihat pod IPs yang di-backend
kubectl describe svc api-service
```

---

## 6. Ingress — Traffic Masuk

Ingress = Layer 7 load balancer + routing rules. Butuh **Ingress Controller** (NGINX, Traefik, HAProxy).

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.mydomain.com
      secretName: tls-secret
  rules:
    - host: api.mydomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
    - host: admin.mydomain.com
      http:
        paths:
          - path: /dashboard
            pathType: Exact
            backend:
              service:
                name: admin-ui
                port:
                  number: 8080
```

### Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
kubectl get svc -n ingress-nginx  # dapatkan External IP / NodePort
```

---

## 6b. Network Policy — Zero-Trust Antar Pod

Default di Kubernetes: **semua pod bisa ngobrol** dengan pod lain (no isolation). NetworkPolicy mengaktifkan firewall layer 3/4 antar pod — prinsip zero-trust / micro-segmentation.

```yaml
# deny-all.yaml — blok semua traffic masuk ke namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {} # apply ke semua pod
  policyTypes:
    - Ingress # cuma ingress (traffic masuk)
---
# allow-api-from-ingress.yaml — cuma izinin ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/component: controller
      ports:
        - protocol: TCP
          port: 3000
---
# allow-db-from-api — database cuma bisa diakses service layer
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-from-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 5432
---
# allow-egress-dns — izinin pod keluar cuma ke DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-dns
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Best Practice Network Policies

```bash
# Cek apakah ada network policy yang nge-block pod
kubectl get networkpolicy --all-namespaces
kubectl describe networkpolicy -n production default-deny-ingress

# Simulasi konektivitas (butuh debug pod dengan network tools)
kubectl run test-conn -it --rm --image=nicolaka/netshoot -- sh
nc -zv api-service 3000       # test TCP connectivity
curl http://api-service:3000/health
```

**Tier keamanan:**

1. Start dengan `default-deny-ingress` di tiap namespace
2. Allow spesifik per service (allow-api-from-ingress, allow-db-from-api)
3. Allow egress ke DNS & monitoring (prometheus, grafana)
4. Kalau pake service mesh (Istio/Linkerd), network policy bisa diganti dengan AuthorizationPolicy

> [!warning] NetworkPolicy gak ngaruh ke traffic dari/ke host — cuma antar pod. Butuh tambahan firewall (iptables, cloud SG) buat isolasi host-level.

> [!important] CNI plugin HARUS support NetworkPolicy. Calico support penuh; Flannel gak support — butuh calico atau Cilium sebagai gantinya.

---

## 7. ConfigMap & Secret — Konfigurasi

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: production
  LOG_LEVEL: info
  API_URL: https://api.internal:3000
  config.json: |
    {
      "cache": {"ttl": 300, "max": 1000},
      "rateLimit": {"window": 60, "max": 100}
    }
```

```yaml
# secret.yaml (value harus base64)
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  DB_PASSWORD: c3VwZXJzZWNyZXQ= # base64("supersecret")
  DB_USER: YWRtaW4= # base64("admin")
---
# kalo mau plain (stringData — otomatis di-encode)
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  API_KEY: super-secret-key-jangan-commit!
```

```bash
# Buat dari file .env
kubectl create configmap app-config --from-env-file=.env
kubectl create secret generic app-secret --from-literal=DB_PASSWORD=supersecret

# Mount di Pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep -E 'NODE|DB'"]
    env:
    - name: NODE_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: NODE_ENV
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASSWORD
    envFrom:
    - configMapRef:
        name: app-config
  restartPolicy: Never
EOF

kubectl logs config-test  # liat output env
```

---

## 8. Persistence — PVC & Storage

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard # cek dulu: kubectl get storageclass
```

```yaml
# deploy-dengan-volume.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: data-pvc
      containers:
        - name: postgres
          image: postgres:17-alpine
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: password
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          ports:
            - containerPort: 5432
```

> [!warning] StatefulSet untuk database production — Deployment gak jamin identity tetap (pod name, network identity ganti tiap restart).

---

## 9. Scaling & Rolling Update

```bash
# Manual scaling
kubectl scale deployment/api-service --replicas=5
kubectl get hpa   # lihat HorizontalPodAutoscaler

# Auto-scaling (HPA)
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# Simulasi beban
kubectl run load-test -it --rm --restart=Never --image=busybox -- sh -c "while true; do wget -q -O- http://api-service; done"
kubectl get hpa -w   # watch HPA scaling
```

### PodDisruptionBudget — Jaga Availability Saat Node Maintenance

PodDisruptionBudget (PDB) memastikan jumlah minimal pod tetap jalan saat node di-drain/down — krusial buat HA production.

```yaml
# pdb-api.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: production
spec:
  minAvailable: 2 # minimal 2 pod harus selalu siap
  selector:
    matchLabels:
      app: api
---
# Alternatif: pake maxUnavailable
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb-max
  namespace: production
spec:
  maxUnavailable: 1 # maksimal 1 pod boleh gak siap
  selector:
    matchLabels:
      app: api
```

```bash
# Verifikasi PDB
kubectl get pdb -n production
kubectl describe pdb api-pdb -n production
kubectl drain node-1 --ignore-daemonsets  # PDB akan block drain kalo minAvailable gak terpenuhi
```

> [!tip] Kombinasikan PDB + topologySpreadConstraints + anti-affinity buat HA maksimal — pod tersebar di node & AZ berbeda.

---

## 10. Debugging — Daily Ops

### 10.1. Pod Issues

```bash
kubectl get pods --all-namespaces        # semua pod di semua namespace
kubectl describe pod <name>              # events + container status
kubectl logs <pod> --previous            # log dari container sebelum crash
kubectl logs -l app=api --tail=100       # log semua pod dengan label
kubectl get events --sort-by='.lastTimestamp'  # cluster events

# Debug pod sementara (ephemeral container)
kubectl debug pod/nginx-pod -it --image=busybox -- sh   # sidecar debug
```

### 10.2. Resource Issues

```bash
# Cek resource usage
kubectl top pods                       # CPU/memory per pod
kubectl top nodes                      # node utilization
kubectl describe node | grep -A5 "Conditions"  # node health
kubectl get pods -o wide | grep Pending # pending = scheduling issue

# Node issue
kubectl cordon node-1                  # tahan jadwal pod baru
kubectl drain node-1 --ignore-daemonsets # evakuasi pod
kubectl uncordon node-1                # balik normal
```

### 10.3. Network Debugging

```bash
# DNS lookup
kubectl run -it --rm --restart=Never dns-test --image=busybox -- nslookup kubernetes.default.svc.cluster.local

# Service connectivity
kubectl port-forward svc/api-service 4000:80 &
curl http://localhost:4000

# Pod networking
kubectl run -it --rm --restart=Never net-test --image=nicolaka/netshoot -- sh
# Di shell netshoot: curl, dig, tcpdump, nmap, iperf — semua tools network
```

### 10.4. Quick Cheatsheet

```bash
# 🏆 Daily champions
kubectl api-resources                          # semua resource types
kubectl explain deployment.spec                # dokumentasi inline
kubectl diff -f manifest.yaml                  # compare apa yang akan berubah
kubectl get all -n production                  # semua resource di namespace
kubectl delete pod --field-selector=status.phase=Succeeded   # bersihin pod selesai

# Watch mode
kubectl get pods -w
kubectl get events -w --all-namespaces

# YAML output
kubectl get deploy api-service -o yaml          # export YAML
kubectl get pods -o custom-columns=POD:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

### Common Issues & Fixes

| Problem                      | Symptom                 | Fix                                         |
| ---------------------------- | ----------------------- | ------------------------------------------- |
| **Pending pod**              | `0/1 nodes available`   | `kubectl describe pod`, cek resource/taint  |
| **CrashLoopBackOff**         | Container restarts loop | `kubectl logs --previous`, cek startup      |
| **ImagePullBackOff**         | Gak bisa pull image     | `kubectl describe pod`, cek registry/auth   |
| **Out of memory**            | OOMKilled               | `kubectl describe pod`, naikin limits       |
| **Service gak bisa diakses** | Connection refused      | `kubectl get endpoints`, cek selector match |

### 10.5. Incident Runbooks

#### NodeNotReady

```bash
# 1. Identifikasi node bermasalah
kubectl get nodes -o wide
kubectl describe node <name> | grep -A10 Conditions

# 2. Cek kondisi node
#   - Ready = False → kubelet mati atau overload
#   - DiskPressure → node kehabisan disk
#   - MemoryPressure → node OOM
#   - PIDPressure → terlalu banyak proses
#   - NetworkUnavailable → CNI plugin gagal

# 3. Evakuasi pod sebelum maintenance/reboot
kubectl cordon <node-name>                     # stop jadwal pod baru
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 4. Setelah node sembuh
kubectl uncordon <node-name>

# 5. Investigasi root cause
journalctl -u kubelet -n 100 --no-pager        # log kubelet
df -h                                          # cek disk usage node
free -h                                        # cek memory
systemctl status kubelet                       # service status
```

#### DiskPressure

```bash
# Gejala: node conditions = DiskPressure, pod evicted
kubectl describe node <name> | grep DiskPressure

# Fix immediate: hapus image & container gak terpakai di node
# (lewat SSH ke node)
sudo crictl rmi --prune                        # hapus image gak dipake
sudo crictl rm --prune                         # hapus container exited
docker system prune -af                        # kalo masih pake docker

# Long-term:
# - Naikin evictionHard di kubelet config: imagefs.available < 5%
# - Pake persistent volume buat data besar
# - Monitor disk dengan node_exporter + alerting
```

#### CrashLoopBackOff — Root Cause Analysis

```bash
# 1. Lihat log container yang gagal
kubectl logs <pod-name> --previous             # log dari crash terakhir
kubectl logs <pod-name> --all-containers       # semua container

# 2. Detail container state
kubectl get pod <name> -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}'

# 3. Cek event
kubectl get events --field-selector involvedObject.name=<pod-name> --sort-by='.lastTimestamp'

# 4. Debug langsung (ephemeral container)
kubectl debug <pod-name> -it --image=busybox -- sh
# Di container debug: ps aux, cat /proc/1/cmdline, env

# 5. Penyebab umum:
#   - Error di startup script (salah env/path)
#   - Dependency gak siap (DB belum jalan)
#   - Config salah (missing key, invalid syntax)
#   - Port conflict (container nyoba port yang dipake)
#   - OOMKilled → limit terlalu kecil
#   - Probe failure (liveness terlalu agresif)
```

#### ImagePullBackOff / ErrImagePull / ImagePullNever

```bash
# 1. Cek detail error
kubectl describe pod <name> | grep -A20 Events

# 2. Test pull manual di node
# SSH ke node, coba pull image langsung
sudo crictl pull <image>:<tag>

# 3. Diagnosa:
#   - Image name typo?   → fix deployment
#   - Tag gak ada?       → cek registry: `skopeo list-tags docker://myapp/api`
#   - Registry auth?     → `kubectl get secret regcred`, cek credentials
#   - Registry unreachable? → test DNS: `nslookup registry.example.com`
#   - Rate limit?        → Docker Hub: 100 pulls/6jam anonymous, 200 authenticated
#   - Image pull policy? → imagePullPolicy: Always vs IfNotPresent vs Never

# 4. Fix auth
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<user> \
  --docker-password=<pat> \
  --docker-email=<email>
```

---

## 11. kubectl Plugins & Tools

Ekosistem kubectl bisa diperluas dengan plugin untuk debugging, monitoring, dan produktivitas.

### Krew — Plugin Manager

[Krew](https://krew.sigs.k8s.io/) adalah package manager untuk kubectl plugins — kayak apt/brew buat kubectl.

```bash
# Install Krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)

# Tambah PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc

# Plugin populer via Krew
kubectl krew install                            # lihat plugin available
kubectl krew install stern ctx ns               # install multiple
kubectl krew install tree sniff view-utilization
kubectl krew install neat                       # bersihin noisy YAML output
kubectl krew install outdated                   # cek image versions
```

#### Plugin Wajib

| Plugin               | Fungsi                                      | Install                         |
| -------------------- | ------------------------------------------- | ------------------------------- |
| **stern**            | Tail pod logs dengan label selector + regex | `krew install stern`            |
| **ctx**              | Cepat switch context (kubectx)              | `krew install ctx`              |
| **ns**               | Cepat switch namespace (kubens)             | `krew install ns`               |
| **tree**             | Lihat hierarki resource pod                 | `krew install tree`             |
| **sniff**            | Live tcpdump langsung di pod                | `krew install sniff`            |
| **view-utilization** | Cluster resource utilization                | `krew install view-utilization` |
| **neat**             | Bersihin metadata noise dari YAML export    | `krew install neat`             |
| **outdated**         | Cek image version yang outdated             | `krew install outdated`         |

### Stern — Log Tailing Power Tool

Stern lebih powerful dari `kubectl logs` — multi-pod, multi-container, regex filter, color-coded.

```bash
# Tanpa Krew (direct binary)
curl -L https://github.com/stern/stern/releases/latest/download/stern_linux_amd64.tar.gz | tar xz
sudo mv stern /usr/local/bin/

# Usage
stern api-service                          # tail semua pod dengan label app=api-service
stern -n production "api-.*"               # regex pod name
stern --tail 50 api-service                # tail 50 baris terakhir
stern --timestamps api-service             # dengan timestamp
stern --all-namespaces "api|worker"        # cari di semua namespace
stern --diff=10 api-service                # nampilin perubahan aja
stern -c sidecar-log api-service           # tail container spesifik
stern api-service -e "ERROR|FATAL"         # highlight regex

# Advanced: multi-selector
stern -l "app=api,env=production"          # label selector
stern --context prod-cluster api-service   # tail di cluster lain
```

> [!tip] Stern hampir wajib buat debugging production — ganti `kubectl logs -f` dengan `stern` ASAP.

### tree — Visualisasi Resource

```bash
kubectl tree deploy api-service
# Output:
# NAMESPACE  NAME                                      READY  REASON  AGE
# production Deployment/api-service                    -              47d
# production ├── ReplicaSet/api-service-6b7f8d4f5f      1/1             47d
# production │   └── Pod/api-service-6b7f8d4f5f-abc12   True            47d
# production └── ReplicaSet/api-service-7c9e2b3a1d      1/1             42d
# production     └── Pod/api-service-7c9e2b3a1d-xyz89   True            42d
```

### K9s — Terminal Dashboard (TUI)

[K9s](https://k9scli.io/) adalah CLI dashboard interaktif — kayak `htop` buat Kubernetes.

```bash
# Install
curl -sS https://webinstall.dev/k9s | bash

# Atau via binary
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar xf k9s_Linux_amd64.tar.gz && sudo mv k9s /usr/local/bin/

# Usage
k9s                                 # default context
k9s -c prod-cluster                 # context tertentu
k9s -n production                   # namespace tertentu
k9s --readonly                      # mode baca aja (aman buat production)
```

**Shortcuts K9s wajib hafal:**

| Tombol    | Fungsi                   |
| --------- | ------------------------ |
| `0-9`     | Ganti namespace          |
| `:deploy` | Ganti view ke Deployment |
| `:pod`    | Ganti view ke Pod        |
| `:svc`    | Ganti view ke Service    |
| `d`       | Describe resource        |
| `l`       | Logs (tail)              |
| `y`       | YAML output              |
| `e`       | Edit resource            |
| `ctrl-d`  | Delete resource          |
| `?`       | Help / all shortcuts     |
| `q`       | Quit                     |

> [!tip] K9s + stern + krew = toolkit K8s operator yang solid. Investasi belajar shortcut K9s — akan hemat berjam-jam tiap minggu.

---

## 12. Koneksi ke Vault

| Catatan                                    | Koneksi                                                                |
| ------------------------------------------ | ---------------------------------------------------------------------- |
| [[container-kubernetes-security-deepdive]] | Security dari sisi container & K8s — catatan ini pelengkap operasional |
| [[kubernetes-architecture-deepdive]]       | Arsitektur K8s — ini implementasi praktisnya                           |
| [[kubernetes-operations-helm-gitops]]      | Helm & GitOps deployment — next level setelah operasi manual           |
| [[observability-stack-prometheus-grafana]] | Monitoring K8s cluster dengan Prometheus                               |
| [[podman-networking-ufw]]                  | Container networking di Linux — overlap di network namespace           |
| [[cicd-guide]]                             | CI/CD pipeline — deploy ke K8s dari pipeline                           |

## References

1. Kubernetes kubectl Cheatsheet — https://kubernetes.io/docs/reference/kubectl/cheatsheet/
2. Kubernetes Deployment Concepts — https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
3. Ingress NGINX Controller — https://kubernetes.github.io/ingress-nginx/
4. K8s Network Debugging — https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
5. kubectl Quick Reference — https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
6. CNCF Landscape — https://landscape.cncf.io/
