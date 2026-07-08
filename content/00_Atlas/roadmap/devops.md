---
title: "Devops"
tags:
  - atlas
  - roadmap
aliases:
  - "devops"
created: "2026-04-25"
updated: "2026-07-01"
status: active
cssclasses: ""
---

# ☁️ Roadmap DevOps & Cloud Infrastructure

>[!danger] **Filosofi:** Kalau kamu cuma install Kubernetes, itu artinya kamu bisa setup cluster. Tapi kalau kamu bisa deploy cluster + monitoring + provisioning via IaC, itu artinya kamu mengerti ekosistemnya — dan itu yang ditanya waktu interview. Rekruter akan tanya "oke, cluster kamu running, terus gimana kamu tau kalau ada yang error?" Kalau kamu jawab "ada Prometheus + Grafana dengan alert rules yang saya tulis sendiri" — itu yang menutup pertanyaan.

> [!important] Jalur Paling Banyak Lowongan
> DevOps adalah yang **paling banyak lowongan di Indonesia sekarang**. Demand sangat tinggi karena setiap perusahaan tech butuh orang yang bisa manage deployment pipeline. Salary range: 8–25 juta/bulan untuk junior–mid di Jakarta.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

```
Stack       : Ubuntu Server → Proxmox (host) → Ubuntu VM (multiple)
Jalur       : DevOps / Cloud Infrastructure Engineer
Spek        : i7 Gen7, 8GB RAM, GTX 1050
Target Karir: DevOps Engineer → SRE → Platform Engineer

Urutan belajar:
  Fase 1 (fondasi wajib)   : Linux sysadmin → Docker → Docker Compose
  Fase 2 (automation)      : Ansible → Terraform → CI/CD (GitHub Actions)
  Fase 3 (orchestration)   : Kubernetes (K3s) → Helm → ArgoCD
  Fase 4 (observability)   : Prometheus → Grafana → Loki → AlertManager

Next step: Setup 2 VM di Proxmox — 1 control node, 1 worker node
```

---

## Fase 1 — Linux, Containers & Networking (Minggu 1–6)

> **Goal:** Kuasai fondasi yang 100% akan ditanya di setiap interview DevOps.
> **RAM Impact:** Docker ringan. Total <2GB.

| Skill/Tool | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **Linux Sysadmin** | — | systemd, journalctl, cron, user/group, permissions, firewall (ufw/iptables) | Linux + **troubleshooting log** = kamu bisa debug production server tanpa panik |
| **Networking** | — | TCP/IP, DNS, DHCP, NAT, subnetting, iptables, tcpdump | Networking + **Wireshark capture** = kamu paham kenapa "service unreachable" |
| **Docker** | ~200MB | Container lifecycle, Dockerfile best practice, multi-stage build, volume, network | Docker + **multi-stage build** = kamu paham container optimization, bukan cuma `docker run` |
| **Docker Compose** | ~50MB | Multi-container orchestration, service dependencies, env management | Compose + **full-stack app deployment** = kamu bisa deploy app + DB + cache dalam 1 perintah |

> [!tip] Yang Bisa Diselamatkan dari Pengalaman Sekarang
> **Ubuntu Server dan Docker** dari pengalaman homelab kamu adalah yang paling berguna. Immich dan CasaOS tidak ada nilainya di CV — tapi pengalaman Docker dan Linux-nya yang bisa diselamatkan. Rebuild dari situ.

**Proyek Portofolio Fase 1:**
`Self-hosted Multi-Service Deployment` — deploy WordPress + MariaDB + Redis + Nginx reverse proxy via Docker Compose, dengan SSL (Let's Encrypt via Caddy). Satu `docker-compose.yml`, satu perintah `docker compose up -d`, semuanya jalan. Dokumentasikan arsitekturnya.

---

## Fase 2 — Infrastructure as Code & CI/CD (Minggu 7–14)

> **Goal:** Jangan konfigurasi manual. Semua harus repeatable, version-controlled, automated.
> **RAM Impact:** Ansible dan Terraform ringan. CI/CD jalan di cloud (GitHub).

| Skill/Tool         | RAM    | Yang Dipelajari                                                         | Combo A+B yang Membuktikan                                                                |
| ------------------ | ------ | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Git Advanced**   | —      | Branching strategy, rebase, cherry-pick, hooks, conventional commits    | Git + **protected branches + PR review** = kamu paham collaboration workflow              |
| **Ansible**        | ~100MB | Configuration management — idempotent, agentless, playbook YAML         | Ansible + **playbook untuk provision VM** = kamu bisa reproduce environment dalam 5 menit |
| **Terraform**      | ~100MB | Infrastructure as Code — provider (Proxmox, AWS, GCP), state management | Terraform + **Proxmox provider** = kamu provision VM dari kode, bukan klik-klik di GUI    |
| **GitHub Actions** | Cloud  | CI/CD pipeline — build, test, deploy otomatis setiap push               | CI/CD + **deploy ke server sendiri** = kamu punya pipeline yang bisa didemonstrasikan     |

> [!warning] Jangan Skip Git
> Banyak yang skip Git karena merasa sudah bisa `git add . && git commit && git push`. Itu bukan Git — itu tombol save. Git yang sesungguhnya adalah branching strategy, merge conflict resolution, dan PR review workflow. Ini yang ditanya interview.

**Proyek Portofolio Fase 2:**
`Automated Homelab Provisioning` — Terraform untuk create VM di Proxmox → Ansible playbook untuk install Docker + deploy services → GitHub Actions untuk trigger provision saat push ke main branch. **Ini proyek DevOps yang lengkap dan nyata.**

---

## Fase 3 — Container Orchestration (Minggu 15–22)

> **Goal:** Dari Docker Compose ke Kubernetes. Ini yang memisahkan junior dari mid-level.
> **RAM Impact:** K3s (lightweight K8s) butuh ~512MB per node. Minimal 2 VM.

| Skill/Tool | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **K3s / K8s** | ~512MB/node | Pod, Deployment, Service, Ingress, ConfigMap, Secret, Namespace | K8s + **multi-service deployment** = kamu bisa orchestrate microservices |
| **Helm** | ~50MB | Package manager untuk K8s — templating, versioning, rollback | Helm + **custom chart** = kamu bisa package dan distribute deployment |
| **ArgoCD** | ~300MB | GitOps — deklaratif deployment dari Git repo | ArgoCD + **auto-sync** = kamu punya GitOps pipeline end-to-end |

> [!tip] K3s vs K8s untuk Homelab
> **Pakai K3s** (Rancher). Ini Kubernetes yang dioptimasi untuk resource rendah — cocok untuk 8GB RAM. Fitur sama, overhead jauh lebih kecil. K3s di homelab = K8s di production. Rekruter tidak peduli.

**Proyek Portofolio Fase 3:**
`GitOps Kubernetes Cluster` — K3s cluster (1 master + 1 worker di Proxmox) → deploy 3 microservices via Helm charts → ArgoCD auto-sync dari Git repo. Push ke Git = auto deploy. **Ini level mid-senior DevOps.**

---

## Fase 4 — Observability & Alerting (Minggu 23–30)

> **Goal:** Jawaban untuk "gimana kamu tau kalau ada yang error?" — pertanyaan interview paling penting.
> **RAM Impact:** Stack ini agak berat. Total ~2-3GB. Turunkan retention/scrape interval.

| Skill/Tool | RAM | Yang Dipelajari | Combo A+B yang Membuktikan |
|------------|-----|-----------------|---------------------------|
| **Prometheus** | ~500MB | Metrics collection — scrape, PromQL, recording rules | Prometheus + **custom metrics** = kamu bisa monitor apa saja, bukan cuma CPU/RAM |
| **Grafana** | ~200MB | Visualization — dashboard, alerting, data source | Grafana + **dashboard custom + alert** = kamu punya single pane of glass |
| **Loki** | ~300MB | Log aggregation — lightweight alternative ke ELK stack | Loki + **Promtail** = kamu punya log pipeline tanpa overhead Elasticsearch |
| **AlertManager** | ~50MB | Alert routing — escalation, silencing, grouping | AlertManager + **Slack/Discord notification** = kamu punya on-call workflow |

**Proyek Portofolio Fase 4:**
`Full Observability Stack` — Prometheus + Grafana + Loki + AlertManager monitoring semua service di K3s cluster. Dashboard custom untuk setiap service, alert rules untuk uptime/latency/error rate, notifikasi ke Discord. **Ini jawaban definitif untuk "gimana kamu monitor production?"**

---

## Roadmap Visual — Timeline 8 Bulan

```
Bulan 1-2         Bulan 3-4         Bulan 5-6         Bulan 7-8
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ FASE 1        │ │ FASE 2        │ │ FASE 3        │ │ FASE 4        │
│               │ │               │ │               │ │               │
│ Linux Admin   │ │ Git Advanced  │ │ K3s Cluster   │ │ Prometheus    │
│ Networking    │ │ Ansible       │ │ Helm Charts   │ │ Grafana       │
│ Docker        │ │ Terraform     │ │ ArgoCD        │ │ Loki          │
│ Compose       │ │ GitHub Actions│ │ GitOps        │ │ AlertManager  │
│               │ │               │ │               │ │               │
│ ► Portofolio: │ │ ► Portofolio: │ │ ► Portofolio: │ │ ► Portofolio: │
│   Multi-svc   │ │   Auto-Prov   │ │   GitOps K8s  │ │   Full Obs    │
│   Deployment  │ │   IaC Pipeline│ │   Cluster     │ │   Stack       │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
```

---

## Sertifikasi yang Cocok per Fase

| Fase | Sertifikasi | Kenapa |
|------|-------------|--------|
| Setelah Fase 1 | **LFCS (Linux Foundation Certified Sysadmin)** | Validasi skill Linux — fondasi semua DevOps |
| Setelah Fase 2 | **HashiCorp Terraform Associate** | Murah, diakui industri, langsung relevan |
| Setelah Fase 3 | **CKA (Certified Kubernetes Administrator)** | Gold standard K8s — sangat dihargai rekruter |
| Setelah Fase 4 | **AWS Solutions Architect Associate** atau **GCP ACE** | Transisi ke cloud provider setelah fondasi on-prem kuat |

---

## Yang TIDAK Perlu Dipelajari Sekarang

> [!warning] Jangan Buang Waktu
> - ~~CasaOS / Immich / Nextcloud~~ — self-hosted apps bukan DevOps skill. Docker-nya yang berharga, bukan tool-nya
> - ~~AWS/GCP/Azure langsung~~ — kuasai on-prem dulu, cloud cuma abstraksi di atasnya
> - ~~Puppet/Chef~~ — sudah digantikan Ansible di mayoritas perusahaan
> - ~~Jenkins~~ — masih dipakai di legacy, tapi GitHub Actions/GitLab CI lebih modern dan lebih banyak diadopsi

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[cloud-infrastructure|Infrastruktur Cloud]] — Level 0–8 cloud infrastructure hierarchy
- [[computer-science-foundations|Computer Science Foundations]] — OS Internals yang mendukung Linux sysadmin
- [[cyber-security|Cyber Security Roadmap]] — Blue Team overlap di Fase 4 monitoring
- [[data-engineering|Data Engineering Roadmap]] — Pipeline skill overlap dengan CI/CD
- [[agentic-ai-mcp-roadmap|Agentic AI & MCP Roadmap]] — Jalur karir engineering AI agents
- [[ai-engineering-stack-roadmap|AI Engineering Stack Roadmap]] — Jalur karir MLOps / LLMOps
- [[infrastructure-administrator|IT Systems Engineer Roadmap]] — Jalur karir systems & infrastructure engineering

---

*Roadmap DevOps & Cloud Infrastructure | Fase 1 (Docker) → Fase 4 (Observability) · 8 Bulan Homelab*
