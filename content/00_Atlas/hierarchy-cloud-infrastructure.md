---
title: "Hierarchy Cloud Infrastructure"
tags:
  - atlas
  - cloud
  - devops
  - infrastructure
  - k8s
aliases:
  - "hierarchy-cloud-infrastructure"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  - callout
---


# ☁️ HIERARKI INFRASTRUKTUR CLOUD — Dari Shared Hosting (Level 0) sampai Zero Trust Cloud Native (Level 8)

> Infrastruktur cloud adalah **hierarki control vs complexity**: semakin tinggi level, semakin banyak kontrol yang kamu punya — tapi semakin besar juga complexity dan attack surface. Mulai dari shared hosting (tinggal upload file, nol kontrol) sampai zero trust cloud native (setiap request diverifikasi ulang). Untuk tabel lengkap per level dengan tools, lihat [[cloud-infrastructure]].

> [!info] Cara Baca
> Level 0 = shared hosting (cPanel, nol kontrol). Level 8 = Zero Trust Cloud Native (SPIFFE/SPIRE, OPA, Tetragon). Kebanyakan organisasi beroperasi di Level 2–5. Level 6+ untuk platform engineering dan regulated industry.

---

## Tabel Utama — Level 0 sampai Level 8

| ☁️ Level | 🧠 Stack & Approach | ⚡ Cara Kerja | ☠️ Tembok | 🔐 Security Surface |
|---|---|---|---|---|
| **Level 0** — Shared Hosting | cPanel, DirectAdmin, Niagahoster, Hostinger | Satu server dibagi ratusan tenant. FTP upload, phpMyAdmin, SSL Let's Encrypt auto. **Zero control** | Noisy neighbor. Tidak bisa custom stack. PHP version tergantung provider | Shared kernel → satu tenant RCE bisa affect lain. Provider pegang akses penuh |
| **Level 1** — VPS / Dedicated | DigitalOcean, Linode, Hetzner, AWS EC2 | Satu VM dedicated, akses root. Install apapun, konfigurasi sendiri | Semua tanggung jawab padamu: patch, backup, monitoring. **Single point of failure** | SSH brute force, unpatched OS. CIS Benchmark wajib |
| **Level 2** — Platform as a Service | Heroku, Railway, Vercel, Netlify, Fly.io | Deploy git push → platform handle build, scaling, SSL, CDN | Lock-in. Cold start serverless. Biaya meledak di traffic tinggi | Environment variable leak, supply chain dependency |
| **Level 3** — Containerization | Docker, Podman, Docker Compose, containerd | App dalam container — isolated, reproducible, portable. Podman: rootless lebih aman | "Works on my machine." Image bloat. Base image CVE | Container escape. Privileged = root di host. Image scanning wajib (Trivy) |
| **Level 4** — Orchestration | Kubernetes, K3s, OpenShift, Talos Linux | Auto-scaling, self-healing, rolling deploy. K3s ringan untuk edge | Complexity tinggi. Misconfiguration source utama breach | **4C Security**: Cloud → Cluster → Container → Code. NSA hardening guide |
| **Level 5** — Service Mesh & Observability | Istio, Linkerd, Cilium, Jaeger, Prometheus, Grafana, OpenTelemetry | mTLS otomatis, traffic management, distributed tracing. Cilium: eBPF-based networking | Istio overhead 10-15%. Debugging distributed system kompleks | mTLS otomatis antar pod. eBPF security policy di kernel |
| **Level 6** — GitOps & IaC | Terraform, Pulumi, ArgoCD, Flux, Crossplane, Ansible | Infrastruktur sebagai kode — versioned di Git, review via PR, audit trail | State file Terraform simpan secret plaintext. Drift antara kode dan realita | Compliance-as-code. Git = single source of truth |
| **Level 7** — Multi-Cloud & DR | AWS+GCP+Azure, Rook+Ceph, Velero, Vitess, CockroachDB | Tidak bergantung satu cloud. Distributed storage + SQL. Active-active multi-region | Complexity eksponensial. Biaya data egress mahal. CAP theorem trade-off | Data center failure survival. Strong consistency trade-off |
| **☠️ Level 8** — Zero Trust Cloud Native | SPIFFE/SPIRE, Vault, OPA/Gatekeeper, Falco, Tetragon | **Workload identity**: setiap service punya identitas kriptografis (X.509 SVID). Policy as code. Runtime security via eBPF | Butuh pemahaman PKI. Vault HA kompleks. OPA salah = cluster lock. Tetragon butuh kernel eBPF | **Ultimate security**: zero implicit trust. Setiap request diverifikasi |

---

## Peta Visual — Control vs Complexity Trade-off

```
Kontrol ↑
  L8 ─ Zero Trust Cloud Native ●←●●●●●●●●●●●●●● Complexity
  L7 ─ Multi-Cloud & DR         ●←●●●●●●●●●●●
  L6 ─ GitOps & IaC             ●←●●●●●●●●
  L5 ─ Service Mesh              ●←●●●●●●
  L4 ─ Kubernetes                ●←●●●●
  L3 ─ Container                 ●←●●
  L2 ─ PaaS                      ●←●
  L1 ─ VPS                       ●←
  L0 ─ Shared Host        ●
      └─────────────────────────→ Complexity
```

> [!warning] Naik Level ≠ Lebih Baik Secara Otomatis
> Level tinggi tidak selalu lebih baik. Untuk blog pribadi, Level 0 (shared hosting) sudah cukup — kenapa deploy K8s + service mesh + GitOps? Kenali kebutuhan: **pilih level paling rendah yang mencukupi**. Level tinggi cuma menambah biaya dan complexity tanpa value proporsional kalau traffic kecil.

---

## Kenapa Hirarki Ini Penting

### 1. Setiap Level Punya Trade-off Antara Kontrol vs Abstraksi

| Aspek | Level 0 (Shared) | Level 4 (K8s) | Level 8 (Zero Trust) |
|---|---|---|---|
| Setup time | 5 menit (cPanel) | 2 hari–minggu | Minggu–bulan |
| Maintenance | Provider | DevOps team | Platform engineering team |
| Security baseline | Provider-managed | Team responsibility | Full custom |
| Cost per app | Rp 50rb/bln | Rp 2–20 jt/bln | Rp 20–200 jt/bln |
| Scaling | Tidak bisa auto | Auto (HPA, cluster) | Auto + policy-driven |

### 2. Attack Surface Naik Seiring Level

Level 0 attack surface: FTP credentials bocor, plugin vuln.
Level 8 attack surface: k8s RBAC misconfig, SPIFFE SVID expiry, OPA policy bug, Tetragon eBPF program crash.

**Kontrol yang lebih tinggi berarti lebih banyak komponen yang harus dikonfigurasi dengan benar.** Setiap komponen tambahan = potensi misconfiguration baru.

---

## Plot Twists

> [!danger] Plot Twist 1: Kubernetes Misconfiguration Source 80% Breach
> Laporan 2024: 80% breach di K8s environment disebabkan **misconfiguration**, bukan zero-day. Top offenders: exposed dashboard (tanpa auth), RBAC terlalu permisif, container running as root, secrets di ConfigMap, network policy tidak di-enforce. **K8s tidak secure by default** — itu framework yang harus dikonfigurasi dengan benar.

> [!tip] Plot Twist 2: VPS (Level 1) Masih Pilihan Paling Cost-Effective
> VPS — dengan setup manual, backup script, dan firewall — masih pilihan paling cost-effective untuk UKM dan developer individu. Dibanding PaaS (lock-in + harga tinggi) atau K8s (complexity), VPS + Ansible + docker-compose sering "cukup." Kenali kapan Level 1 cukup sebelum naik ke Level 3–4.

> [!info] Plot Twist 3: GitOps (Level 6) Menyelesaikan Masalah "Siapa Yang Ubah Infrastruktur?"
> Sebelum GitOps: SSH ke server, jalankan command, tidak ada audit trail. Sesudah GitOps: semua perubahan via PR ke Git, auto-sync ke cluster via ArgoCD/Flux. **Rollback = git revert + push**. Inilah kenapa bank dan fintech adopsi GitOps — **audit trail adalah syarat regulasi**.

> [!warning] Plot Twist 4: Zero Trust Cloud Native (Level 8) Tidak Untuk Semua
> Level 8 membutuhkan: platform engineering team dedicated, pemahaman kriptografi (X.509, SPIFFE), policy as code (OPA/Rego), dan observability mature. Untuk startup 5 orang yang deploy di satu VPS — jangan sentuh Level 8. Untuk bank digital dengan 100 microservice → ini adalah **minimum viable security**.

---

## Sumber & Telusur Lebih Lanjut

- **Cloud Infrastructure Lengkap** → [[cloud-infrastructure]] (Level 0–8 tabel detail + arsitektur rekomendasi 2024)
- **CI/CD Pipeline** → [[cicd-shiftleft-shiftright]] (shift-left security di pipeline)
- **Service Mesh** → [[waf-reverse-proxy-deepdive]] (Envoy/Istio/Cilium integration)
- **Supply Chain Security** → [[software-supply-chain-security-deepdive]] (SLSA framework)
- **Endpoint Security** → [[hierarchy-endpoint-security]] (container host OS hardening)
- **Identity (Zero Trust Foundation)** → [[hierarchy-identity-trust]] (SPIFFE/SPIRE, workload identity)
- **Master Index** → [[master-index]]

---

> Pilih level infrastruktur berdasarkan kebutuhan, bukan ego atau hype. Hosting blog pribadi di K8s adalah over-engineering. Deploy aplikasi keuangan di shared hosting adalah under-engineering. Hirarki ini membantu lo memilih dengan sadar.

*Cloud Infrastructure Hierarchy | Level 0 (Shared Hosting) → Level 8 (Zero Trust Cloud Native) · Pilih Level Paling Rendah Yang Cukup*
