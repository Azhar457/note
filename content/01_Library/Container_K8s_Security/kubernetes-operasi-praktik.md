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
status: pending
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
7. [[#7. ConfigMap & Secret — Konfigurasi]]
8. [[#8. Persistence — PVC & Storage]]
9. [[#9. Scaling & Rolling Update]]
10. [[#10. Debugging — Daily Ops]]
11. [[#11. Koneksi ke Vault]]

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

---

## 11. Koneksi ke Vault

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
