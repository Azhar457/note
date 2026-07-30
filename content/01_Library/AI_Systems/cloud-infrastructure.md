---
title: Cloud Infrastructure
tags:
- ai-systems
- library
created: '2026-04-23'
updated: '2026-07-01'
status: pending
---

# ☁️ Infrastruktur Cloud — Hierarki Lengkap

> Dari shared hosting sederhana sampai multi-cloud zero trust dengan service mesh.
> Setiap level menambah: **kontrol**, **skalabilitas**, **kompleksitas**, dan **attack surface** sekaligus.

---

## Tabel Utama — Level 0 sampai Level 8

| ☁️ Level & Stack                                                                                                        | ⚡ Cara Kerja & Sweet Spot                                                                                                                                                                                                                                                                                                                                                                                              | ☠️ Tembok Kematian                                                                                                                                                                                       | 🔐 Security Surface                                                                                                                                                           | 🎯 Dipakai Oleh                                                             |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Level 0** — Shared Hosting *(cPanel, Niagahoster, Hostinger, DirectAdmin)*                                            | Satu server fisik dibagi ratusan tenant. FTP upload, database MySQL via phpMyAdmin, SSL gratis Let's Encrypt. Zero konfigurasi server.                                                                                                                                                                                                                                                                                 | Noisy neighbor: tenant lain bisa konsumsi resource berlebihan. Tidak ada isolasi proses. PHP version tergantung provider. Tidak bisa custom software stack.                                              | Shared kernel = satu tenant RCE bisa affect tenant lain. Provider pegang semua akses. Backup policy provider-dependent.                                                       | Blog, UMKM, landing page, portfolio, WordPress site                         |
| **Level 1** — VPS / Dedicated Server *(DigitalOcean, Linode, Vultr, AWS EC2, Hetzner)*                                  | Satu VM dedicated untukmu. Akses root penuh. Install software apapun, konfigurasi firewall sendiri. Hetzner: VPS Eropa murah + powerful. DigitalOcean: UX paling ramah untuk pemula.                                                                                                                                                                                                                                   | Semua tanggung jawab ada padamu: OS update, security hardening, backup, monitoring. Single point of failure jika tidak ada HA setup.                                                                     | Attack surface: SSH brute force, unpatched OS, misconfigured services. **CIS Benchmark** wajib diimplementasi.                                                                | Developer, startup kecil, self-hosted apps, game server                     |
| **Level 2** — Platform as a Service *(Heroku, Railway, Render, Vercel, Netlify, Fly.io)*                                | Deploy dari git push — platform handle build, scaling, SSL, CDN. Zero server management. Vercel/Netlify: khusus frontend + serverless function. Railway: full-stack PaaS modern. Fly.io: container di edge global.                                                                                                                                                                                                     | Lock-in ke platform. Cold start pada serverless. Biaya bisa meledak di traffic tinggi. Kustomisasi terbatas vs VPS.                                                                                      | Platform keamanannya diurus provider. Tapi: environment variable leak, supply chain attack via dependency, insecure function.                                                 | MVP startup, indie developer, jamstack site, API backend sederhana          |
| **Level 3** — Containerization *(Docker, Podman, containerd, Docker Compose, Docker Swarm)*                             | Aplikasi dikemas dalam container — isolated, reproducible, portable. Docker Compose: orkestrasi multi-container di satu host. Image layer caching: build cepat, distribusi efisien. Podman: Docker tanpa daemon (rootless, lebih aman).                                                                                                                                                                                | "Works on my machine" masih bisa terjadi jika environment variable tidak dikontrol. Image bloat. Base image dengan CVE. Dockerfile buruk = container berjalan sebagai root.                              | Container escape (runc CVE). Privileged container = sama dengan root di host. Image scanning wajib (Trivy, Grype). Secrets tidak boleh di-bake ke image.                      | Semua perusahaan modern, development environment, CI/CD pipeline            |
| **Level 4** — Container Orchestration *(Kubernetes, K3s, OpenShift, Rancher, Talos Linux)*                              | Kubernetes: orkestrasi container di banyak node. Auto-scaling, self-healing, rolling deployment, service discovery. K3s: Kubernetes ringan untuk edge/IoT. Talos Linux: OS minimal khusus Kubernetes (immutable, API-driven, tidak ada SSH).                                                                                                                                                                           | Kubernetes complexity sangat tinggi — kurva belajar curam. Misconfiguration adalah source utama breach (exposed dashboard, insecure RBAC). Etcd adalah crown jewel — wajib dienkripsi dan di-backup.     | **4C Security**: Cloud → Cluster → Container → Code. NSA Kubernetes Hardening Guide wajib dibaca. RBAC principle of least privilege. Network Policy untuk micro-segmentation. | Perusahaan menengah-besar, platform produk SaaS, infrastruktur bank digital |
| **Level 5** — Service Mesh & Observability *(Istio, Linkerd, Cilium, Jaeger, Prometheus, Grafana, OpenTelemetry)*       | **Service mesh**: infrastruktur layer untuk komunikasi service-to-service. **Istio**: mTLS otomatis antar pod, traffic management, observability. **Cilium**: eBPF-based networking — security policy di kernel level tanpa iptables. **Jaeger**: distributed tracing — lacak satu request melewati puluhan microservice. **Prometheus + Grafana**: metrics dan alerting.                                              | Istio resource overhead ~10–15% CPU/memory tambahan. Debugging distributed system sangat kompleks. Sidecar proxy pattern menambah latency.                                                               | Financial services, marketplace skala besar, gaming platform dengan microservices                                                                                             |                                                                             |
| **Level 6** — GitOps & Infrastructure as Code *(Terraform, Pulumi, Crossplane, ArgoCD, Flux, Ansible)*                  | **IaC**: infrastruktur didefinisikan sebagai kode — versi di Git, review via PR, audit trail lengkap. **Terraform**: deklaratif, multi-cloud (AWS + GCP + Azure + on-prem). **Pulumi**: IaC dengan bahasa pemrograman nyata (Python, TypeScript). **ArgoCD/Flux**: GitOps — cluster state selalu sync dengan Git repository. **Crossplane**: provision cloud resource dari dalam Kubernetes.                           | State file Terraform menyimpan secret dalam plaintext (gunakan remote state terenkripsi). Drift antara kode dan realita infrastruktur. GitOps butuh disiplin — tidak boleh ada manual change di cluster. | Platform engineering team, enterprise DevOps, regulated industry (compliance-as-code)                                                                                         |                                                                             |
| **Level 7** — Multi-Cloud & Disaster Recovery *(AWS + GCP + Azure multi-cloud, Rook+Ceph, Velero, Vitess, CockroachDB)* | Tidak bergantung satu cloud provider. **Rook+Ceph**: distributed storage di atas Kubernetes. **Velero**: backup dan restore Kubernetes cluster. **Vitess**: horizontal sharding MySQL (dipakai YouTube). **CockroachDB**: distributed SQL yang survive datacenter failure. Active-active multi-region: traffic serve dari multiple region simultaneously.                                                              | Complexity eksponensial. Biaya data egress antar cloud mahal. Konsistensi data di multi-region butuh eventual consistency trade-off (CAP theorem).                                                       | Unicorn startup, perusahaan global, infrastruktur fintech skala nasional                                                                                                      |                                                                             |
| ☠️ **Level 8** — Zero Trust Cloud Native *(SPIFFE/SPIRE, HashiCorp Vault, OPA/Gatekeeper, Falco, Tetragon)*             | **SPIFFE/SPIRE**: identitas kriptografis untuk setiap workload (bukan manusia) — X.509 SVID otomatis. **HashiCorp Vault**: secret management terpusat — dynamic secret, lease, revoke. **OPA (Open Policy Agent)**: policy as code untuk semua keputusan otorisasi. **Falco/Tetragon**: runtime security — deteksi anomali di level kernel via eBPF (Tetragon bisa kill process secara otomatis jika policy violated). | SPIFFE/SPIRE butuh pemahaman PKI mendalam. Vault HA setup kompleks. Policy OPA yang salah = seluruh cluster bisa terlocked. Tetragon membutuhkan kernel modern (eBPF).                                   | Bank kelas 1, infrastruktur pemerintah, perusahaan defence-tech, cloud provider itu sendiri                                                                                   |                                                                             |

---

## Arsitektur Modern yang Direkomendasikan (2024)

```
┌──────────────────────────────────────────────────────┐
│                   DEVELOPER                           │
│  Code → Git Push → CI/CD (GitHub Actions/GitLab CI)  │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│              SECURITY SCANNING                        │
│  SAST (Semgrep) → SCA (Snyk) → Container Scan(Trivy)│
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│           ARTIFACT REGISTRY                           │
│  Harbor / ECR / GCR (signed image, SBOM attached)   │
└──────────────────────┬───────────────────────────────┘
                       │ ArgoCD / Flux (GitOps)
                       ▼
┌──────────────────────────────────────────────────────┐
│              KUBERNETES CLUSTER                       │
│                                                      │
│  ┌────────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │  Namespace  │  │  Cilium  │  │ SPIFFE/SPIRE    │  │
│  │  (isolasi) │  │  (NetPol)│  │ (workload ID)   │  │
│  └────────────┘  └──────────┘  └─────────────────┘  │
│                                                      │
│  ┌────────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │   Istio    │  │  Vault   │  │  OPA Gatekeeper │  │
│  │  (mTLS)   │  │ (secrets)│  │  (policy)       │  │
│  └────────────┘  └──────────┘  └─────────────────┘  │
│                                                      │
│  ┌────────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │   Falco    │  │Prometheus│  │    Jaeger        │  │
│  │ (runtime) │  │ (metrics)│  │   (tracing)      │  │
│  └────────────┘  └──────────┘  └─────────────────┘  │
└──────────────────────────────────────────────────────┘
```

---

## Peta Tanggung Jawab: Shared Responsibility Model

```
                    KAMU        PROVIDER
Shared Hosting:     5%    /     95%
VPS:               80%    /     20%
PaaS:              40%    /     60%
IaaS (EC2):        70%    /     30%
Kubernetes managed: 60%   /     40%
On-prem:          100%    /      0%

Semakin besar angka KAMU = semakin besar kontrol
                         = semakin besar tanggung jawab security
```

>[!tip] Entry Point untuk Mahasiswa IT
>**Jalur belajar yang direkomendasikan:**
>1. VPS di Hetzner (€4/bulan, termurah berkualitas) → setup Nginx + SSL manual
>2. Docker + Docker Compose → kontainerisasi app sendiri
>3. K3s di satu VPS → rasakan Kubernetes tanpa biaya cluster managed
>4. Terraform → provision VPS via kode, bukan klik-klik
>5. ArgoCD → deploy app via GitOps
>
>Semua bisa dilakukan dengan budget **<Rp 100rb/bulan**.

>[!warning] Kubernetes Bukan untuk Semua Orang
>Jika aplikasimu serve <10.000 user/hari, Docker Compose di satu VPS sudah lebih dari cukup. Kubernetes menyelesaikan masalah skala yang belum kamu punya — dan menambah kompleksitas yang sudah ada sekarang. **Premature optimization adalah akar semua kejahatan** (Donald Knuth).

---

## Sertifikasi yang Relevan per Level

| Level | Sertifikasi |
|---|---|
| Level 1–2 | AWS Cloud Practitioner, GCP Associate Cloud Engineer |
| Level 3–4 | **CKA** (Certified Kubernetes Administrator), **CKAD**, Docker DCA |
| Level 5–6 | **CKS** (Certified Kubernetes Security Specialist), Terraform Associate |
| Level 7–8 | CISSP, AWS Security Specialty, GCP Professional Security Engineer |

---

## 🔗 Lihat Juga

- [[network-security|Network Security]]
- [[cryptography-biometrics|Kriptografi & Biometrik]]
- [[hardware-hacking-re|Hardware Hacking]]
- [[hierarchy-ai-levels|AI Levels Hierarchy]]

---

*Infrastruktur Cloud Hierarchy | Dari Shared Hosting sampai Zero Trust Cloud Native*
