---
tags:
  - roadmap
  - systems-engineer
  - infrastructure
  - bare-metal
  - on-prem
  - proxmox
  - pfsense
  - pki
  - vault
  - blue-team
aliases:
  - Roadmap IT Systems Engineer
  - Roadmap Infrastructure Administrator
  - Roadmap On-Prem Infrastructure
created: 2026-05-18
status: active
cssclasses:
  - wide-table
---

> [!warning] **Filosofi:** Jangan hanya "install" — kamu harus bisa "operate." Bedanya besar: install Proxmox itu 30 menit, tapi operate 4-node cluster dengan ZFS, Corosync quorum, dan PBS restore verification itu skill yang ditanya waktu interview. Rekruter akan tanya: "Oke, node 3 down, apa yang terjadi dengan VM di node 1 dan 2?" Kalau kamu jawab: "Corosync tetap quorum karena 3 dari 4 node hidup, VM HA failover ke node healthy berdasarkan resource score, dan PBS restore saya verifikasi mingguan dengan automated test restore ke isolated VM" — itu yang menutup pertanyaan.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

- **Stack**: Proxmox VE 8 (single-node atau nested) → Ubuntu 24.04 VMs
- **Jalur**: IT Systems Engineer / Infrastructure Administrator (On-Prem)
- **Spek**: i7 Gen7, 8GB RAM, GTX 1050 (⚠️ Upgrade ke 32GB+ RAM sangat direkomendasikan)
- **Target Karir**: Systems Engineer → Infrastructure Lead → Platform Engineer

Homelab Strategy untuk 8GB RAM:

- Fase 1-2: Single-node Proxmox, ZFS compression=lz4, 2-3 VM saja, swap di ZVOL
- Fase 3-4: Nested virtualization matikan, jalankan service native di VM minimal (1GB each)
- Fase 5-6: Cloud VPS trial / low-cost ($20/bulan) untuk komponen RAM-heavy (Wazuh, Vault HA)
- Prioritas: Belajar konfigurasi & operasi, bukan scale-out horizontal

**Urutan belajar:**

- **Fase 1 (foundation)**: Proxmox + Ubuntu golden image + Ansible base
- **Fase 2 (network)**: pfSense + Unbound/chrony + Cloudflare edge
- **Fase 3 (trust)**: EJBCA + step-ca + HashiCorp Vault + OIDC
- **Fase 4 (resilience)**: HAProxy + Keepalived + Patroni/etcd + Redis Sentinel
- **Fase 5 (observe)**: Prometheus/Grafana/Alertmanager + Wazuh + Vector + OpenVAS
- **Fase 6 (operate)**: Docker/Compose + MinIO + RabbitMQ + IaC maturity + compliance

Next step: Install Proxmox VE 8 di bare metal atau nested, buat VM template Ubuntu 24.04, aktifkan ZFS dengan compression, siapkan Ansible control node

> [!warning] Aturan Emas
> **Satu layer dulu.** Selesaikan sampai bisa failover, restore, atau rebuild tanpa dokumentasi, baru loncat ke layer berikutnya. Infrastructure adalah tumpukan kartu — fondasi goyang, semua runtuh.

---

## Fase 1 — Virtualization & OS Foundation (Minggu 1–4)

> **Goal:** Kuasai hypervisor, buat golden image yang reproducible, dan otomasi provisioning dasar.
> **RAM Impact:** Proxmox host ~2GB, 2-3 VM @ 1GB each. Total aman untuk 8GB.

| Tool/Stack                    | RAM                 | Yang Dipelajari                                                                                                                                | Combo A+B yang Membuktikan                                                                           |
| ----------------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Proxmox VE 8**              | Host ~2GB           | Cluster Corosync, ZFS tuning (compression, recordsize, atime=off), cloud-init template lifecycle, `qm` CLI, PBS datastore + GCM-256 encryption | Proxmox + **automated cloud-init deploy** = kamu bisa spin VM dari template dalam 60 detik tanpa GUI |
| **Ubuntu 24.04 Golden Image** | ~1GB                | systemd hardening, CIS L1 (SSH, fail2ban, auditd, AppArmor, sysctl, UFW, unattended-upgrades), ZFS on root, TLS/PKI trust store                | Golden Image + **CIS benchmark remediation** = kamu punya VM template siap audit                     |
| **Ansible**                   | Control node ~512MB | Inventory design, group_vars, roles: base-hardening, node-exporter, chrony, wazuh-agent, UFW, step-client                                      | Ansible + **idempotent site playbook** = kamu bisa rebuild 10 VM identik dalam 1 command             |
| **Terraform**                 | ~256MB              | telmate Proxmox provider, reusable VM modules, cloud-init user-data, state management                                                          | Terraform + **Ansible provisioner** = kamu punya VM lifecycle end-to-end (create → configure)        |

> [!tip] Cara Belajar Fase 1
> Build Proxmox di bare metal. Buat 1 VM "Ansible control node," 1 VM "web-server-test." Tulis playbook `site.yml` yang hardening VM, install node_exporter, register ke NTP. Hapus VM web-server, recreate via Terraform + Ansible. **Ulangi sampai tidak perlu buka dokumentasi.**

**Proyek Portofolio Fase 1:**
`Bare-Metal Proxmox Homelab + CIS-Hardened Ubuntu Template` — dokumentasi lengkap: skema ZFS pool, cloud-init template build script, Ansible role tree, Terraform module source. Sertakan `terraform plan` output dan hasil `lynis audit` before/after hardening.

---

## Fase 2 — Networking & Edge Foundation (Minggu 5–8)

> **Goal:** Pahami traffic flow antar tenant, bangun perimeter defense, dan kuasai DNS/NTP sebagai backbone.
> **RAM Impact:** pfSense VM ~2GB, 3-4 Ubuntu VM client @ 512MB. Total ~5GB.

| Tool/Stack      | RAM        | Yang Dipelajari                                                                                                                                                                                      | Combo A+B yang Membuktikan                                                                        |
| --------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **pfSense**     | ~2GB       | VLAN creation (210-215, 220/470-473), interface assignment, firewall rule matrix antar-VLAN, NAT outbound, DHCP static mapping, Wazuh syslog forwarding, pfBlockerNG, config backup + git versioning | pfSense + **documented rule matrix spreadsheet** = kamu bisa justify setiap allow/deny ke auditor |
| **Unbound DNS** | ~128MB     | Split-horizon zones, DNSSEC validation, local overrides, forwarder configuration                                                                                                                     | Unbound + **per-tenant zone isolation** = kamu paham internal name resolution multi-tenant        |
| **chrony NTP**  | ~64MB      | Stratum configuration, peer synchronization, leap-second handling                                                                                                                                    | chrony + **Proxmox + VM sync** = kamu eliminasi clock drift di cluster                            |
| **Tailscale**   | ~128MB     | Subnet route advertising, ACL policies, exit node, MagicDNS                                                                                                                                          | Tailscale + **pfSense integration** = kamu punya VPN overlay tanpa buka port inbound              |
| **Cloudflare**  | N/A (edge) | Zero Trust Tunnel (cloudflared on DMZ), WAF custom rules, Access policies (OIDC), Origin CA, rate limiting, admin panel isolation 4-layer                                                            | Cloudflare + **Origin CA + mTLS planning** = kamu paham zero-trust edge architecture              |

> [!warning] RAM Management
> **Matikan VM Fase 1 yang tidak dipakai.** pfSense butuh dedicated 2GB untuk VLAN routing simulation. Gunakan managed switch atau VLAN tagging di NIC untuk test fisik.

**Proyek Portofolio Fase 2:**
`Multi-Tenant Network Foundation + Cloudflare Edge` — diagram jaringan (VLAN 210-215, 220/470-473), pfSense rule matrix Excel/CSV, Cloudflare Access policy YAML, admin panel isolation test report (4 layer verification), Unbound zone config.

---

## Fase 3 — PKI, Identity & Secrets (Minggu 9–12)

> **Goal:** Bangun trust fabric. Tanpa PKI yang benar, semua TLS adalah teater.
> **RAM Impact:** EJBCA ~1.5GB, step-ca ~512MB, Vault ~512MB. Jalankan bergantian jika RAM 8GB.

| Tool/Stack                | RAM    | Yang Dipelajari                                                                                                                        | Combo A+B yang Membuktikan                                                            |
| ------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **EJBCA Community**       | ~1.5GB | Offline Root CA build, key generation ceremony, CRL publication schedule, certificate profiles, CA hierarchy design                    | EJBCA + **ceremony runbook** = kamu bisa buat Root CA yang air-gapped dan auditable   |
| **step-ca**               | ~512MB | Per-spoke intermediate CAs, ACME provisioners, policy-based issuance (name constraints), systemd auto-renewal, client bootstrap        | step-ca + **ACME for 43 profiles** = kamu otomasi sertifikat tanpa manual CSR         |
| **HashiCorp Vault**       | ~512MB | Raft storage, transit auto-unseal, KV v2 secrets engine, AppRole auth, OIDC integration, Vault Agent template injection, audit logging | Vault + **AppRole + Agent** = aplikasi kamu bisa baca secret tanpa hardcode token     |
| **Google Workspace OIDC** | N/A    | SSO configuration, group mapping, SAML vs OIDC, admin console setup                                                                    | Google Workspace + **Grafana/Proxmox/Vault** = single sign-on untuk semua admin tools |

> [!tip] Trik PKI
> Dokumentasikan setiap command saat EJBCA install. Screenshot setiap dialog. Root CA private key hanya dibuat sekali — kalau hilang, rebuild dari nol. **Ini bukan latihan, ini produksi.**

**Proyek Portofolio Fase 3:**
`Enterprise PKI + Secrets Management Stack` — CA hierarchy diagram (Root → Intermediate → Leaf), Vault architecture doc, auto-renewal systemd timer config, trust store distribution script, OIDC integration screenshot, Vault Agent template example.

---

## Fase 4 — High Availability & Data Layer (Minggu 13–16)

> **Goal:** Eliminate single point of failure. RPO = 0 bukan jargon, itu angka yang harus kamu buktikan.
> **RAM Impact:** Patroni+etcd ~2GB, Redis Sentinel ~1GB, HAProxy+Keepalived ~512MB. Total berat, jalankan di cloud VPS jika perlu.

| Tool/Stack               | RAM    | Yang Dipelajari                                                                                                        | Combo A+B yang Membuktikan                                                                      |
| ------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **HAProxy + Keepalived** | ~512MB | Frontend/backend design, ACLs, health checks (http/tcp), VRRP VIP failover, stickiness, SSL termination                | HAProxy + **Keepalived** = traffic tidak putus meski 1 load balancer mati                       |
| **Patroni + etcd**       | ~2GB   | Postgres HA cluster bootstrap, synchronous replication (RPO=0), failover trigger, REST API health, timeline management | Patroni + **documented failover test** = kamu bisa recover dari primary failure dalam <30 detik |
| **Redis Sentinel**       | ~1GB   | Primary/replica setup, 3-node Sentinel quorum, automatic failover, client reconfiguration                              | Redis + **Sentinel + TLS** = session/cache layer yang survive node loss                         |
| **PgBouncer**            | ~256MB | Connection pooling, transaction mode vs session mode, per-tenant auth, max_client_conn tuning                          | PgBouncer + **Patroni** = kamu scale connection tanya overload Postgres                         |
| **RabbitMQ**             | ~512MB | Cluster formation, vhost per tenant, queue mirroring, management UI, Prometheus plugin, TLS inter-node                 | RabbitMQ + **per-tenant vhost ACL** = messaging layer yang isolated dan observable              |

> [!warning] Critical
> **Failover test harus terdokumentasi.** Buat skenario: "Matikan primary Postgres" → catat RTO/RPO. "Matikan HAProxy master" → catat VIP migration time. Tanpa dokumentasi, itu hanya install.

**Proyek Portofolio Fase 4:**
`HA Stack with Failover Certification` — architecture diagram, failover test matrix (skenario × expected result × actual result × RTO), DR runbook, Patroni failover log screenshot, Redis Sentinel `SENTINEL get-master-addr-by-name` output.

---

## Fase 5 — Observability & Security Operations (Minggu 17–20)

> **Goal:** Kalau kamu tidak melihatnya, kamu tidak mengelolanya. Security tanpa log adalah mitos.
> **RAM Impact:** Wazuh ~3GB, Prometheus/Grafana ~1GB, OpenVAS ~1.5GB. Jalankan bergantian. Gunakan VPS untuk Wazuh AIO.

| Tool/Stack                              | RAM         | Yang Dipelajari                                                                                                                                                         | Combo A+B yang Membuktikan                                                            |
| --------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Prometheus + Grafana + Alertmanager** | ~1GB        | Scrape config (static_file + file_sd), 14+ alerting rules, 30-day retention (Thanos/Cortex konsep), dashboard import + custom panels, routing tree ke Slack/email       | Prometheus + **Alertmanager routing** = alert P1 ke on-call, P3 ke email digest       |
| **Vector**                              | ~256MB      | Dual sink architecture (Wazuh + Loki), tenant-tagged structured logs, transform/filter, source scraping dari file/journald                                              | Vector + **structured JSON logs** = kamu bisa korelasikan event antar tenant          |
| **Exporters**                           | ~128MB each | node_exporter, postgres_exporter, redis_exporter, haproxy_exporter, blackbox_exporter, patroni_exporter                                                                 | Exporters + **Grafana dashboard** = visibility full-stack dari hardware ke aplikasi   |
| **Wazuh SIEM**                          | ~3GB        | All-in-one deploy, agent registration (group-based), custom detection rules (decoder + rules XML), active response (firewall-drop, custom script), MITRE ATT&CK mapping | Wazuh + **custom rule + TheHive case** = SOC pipeline dari deteksi sampai investigasi |
| **OpenVAS/Greenbone**                   | ~1.5GB      | Authenticated scan setup, target configuration, CVSS-based triage, remediation SLA tracking, scheduled scan                                                             | OpenVAS + **remediation report** = kamu bisa buktiin vulnerability management program |

> [!tip] Wazuh di RAM Terbatas
> Deploy Wazuh single-node dengan `docker-compose`, limit Elasticsearch: `ES_JAVA_OPTS=-Xms1g -Xmx1g`. Atau gunakan cloud VPS $20/bulan khusus untuk Wazuh manager.

**Proyek Portofolio Fase 5:**
`SOC-in-a-Box: SIEM + Observability + Vuln Management` — Grafana dashboard JSON, Wazuh custom rule XML, Vector config TOML, OpenVAS scan report dengan CVSS triage table, incident response playbook (P1: 15-min acknowledge / 4-hour resolve).

---

## Fase 6 — Application Infra, IaC Maturity & Compliance (Minggu 21–24)

> **Goal:** Operasionalisasi. Phase 1 adalah build, Phase 2 adalah own. Fase ini menyiapkanmu untuk own.
> **RAM Impact:** Docker services ~2GB, Ansible/Terraform local. Total tergantung jumlah container.

| Tool/Stack                  | RAM          | Yang Dipelajari                                                                                                                                                | Combo A+B yang Membuktikan                                                          |
| --------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Docker / docker-compose** | ~2GB         | Image registry operation (push/pull/tag), multi-stage build konsep, compose file v3, network isolation, volume management, secrets di compose (bukan hardcode) | Docker + **Vault Agent** = container baca secret dari file yang di-inject Vault     |
| **MinIO S3**                | ~512MB       | Bucket setup, bucket policy, TLS, lifecycle policy (transition/expiry), Prometheus integration, erasure coding konsep                                          | MinIO + **tenant-isolated bucket** = storage backend yang scalable dan compliant    |
| **Ansible Advanced**        | Control node | site/harden/deploy/patch playbooks, tag-based execution (`--tags patch`), rolling update strategy, vault-encrypted vars, dynamic inventory                     | Ansible + **patch playbook** = monthly patch cycle terotomasi dan terdokumentasi    |
| **Terraform Advanced**      | Local        | Remote state (S3/MinIO backend), workspace per tenant, module versioning, `terraform plan` di CI                                                               | Terraform + **GitHub Actions** = infrastructure change review sebelum apply         |
| **Git + CI/CD**             | N/A          | Repository strategy (monorepo vs polyrepo), pfSense XML git versioning, GitHub Actions workflow: lint → plan → approve → apply                                 | Git + **Terraform Cloud/Actions** = IaC dengan approval gate dan audit trail        |
| **Compliance**              | N/A          | SOC 2 evidence collection, GDPR/CCPA control mapping (Stage 10 framework), change management log, access review, backup verification evidence                  | Compliance + **automated evidence** = kamu bisa jawab auditor tanpa panic gathering |

**Proyek Portofolio Fase 6:**
`End-to-End Tenant Deploy via IaC + Compliance Evidence Pack` — repo structure screenshot, GitHub Actions workflow YAML, `ansible-playbook site.yml --check` output, patch cycle SOP document, SOC 2 evidence sample (access review log, backup verification log, change ticket).

---

## Roadmap Visual — Timeline 6 Bulan

| Bulan 1                        | Bulan 2                      | Bulan 3                        | Bulan 4                                     | Bulan 5                                 | Bulan 6                                     |
| :----------------------------- | :--------------------------- | :----------------------------- | :------------------------------------------ | :-------------------------------------- | :------------------------------------------ |
| **FASE 1**<br>Virtualization   | **FASE 2**<br>Network & Edge | **FASE 3**<br>PKI & Identity   | **FASE 4**<br>HA & Data                     | **FASE 5**<br>Observability             | **FASE 6**<br>Ops & Compliance              |
| Proxmox                        | pfSense                      | EJBCA                          | HAProxy                                     | Wazuh                                   | Docker                                      |
| Ubuntu                         | Unbound                      | step-ca                        | Patroni                                     | Prom/Graf                               | MinIO                                       |
| Ansible                        | Cloudflare                   | Vault                          | Redis                                       | Vector                                  | RabbitMQ                                    |
| Terraform                      | Tailscale                    | OIDC                           | PgBouncer                                   | OpenVAS                                 | IaC + Compliance                            |
| Golden Image                   | VLAN Matrix                  | PKI Ceremony                   | RabbitMQ Failover                           | Exporter SOC Sim                        | CI/CD                                       |
|                                |                              |                                |                                             |                                         |                                             |
| **Portfolio 1:**               | **Portfolio 2:**             | **Portfolio 3:**               | **Portfolio 4:**                            | **Portfolio 5:**                        | **Portfolio 6:**                            |
| Proxmox Homelab<br>+ CIS Image | Network Foundation<br>+ Edge | PKI Stack + Vault<br>+ Secrets | HA Failover<br>+ DR Runbook<br>+ Data Layer | SOC-in-a-Box<br>+ Observ<br>+ Vuln Mgmt | Tenant Deploy<br>+ Compliance<br>+ IaC Repo |

## Sertifikasi yang Cocok per Fase

| Fase           | Sertifikasi                                                     | Kenapa                                                     |
| -------------- | --------------------------------------------------------------- | ---------------------------------------------------------- |
| Setelah Fase 1 | **CompTIA Server+** atau **LPI Linux Essentials**               | Validasi fondasi Linux & virtualization                    |
| Setelah Fase 2 | **CompTIA Network+**                                            | VLAN, DNS, NAT, firewall — fondasi networking on-prem      |
| Setelah Fase 3 | **HashiCorp Vault Associate** + **EJBCA training** (unofficial) | PKI dan secrets management adalah differentiator           |
| Setelah Fase 4 | **Linux Foundation Certified Sysadmin (LFCS)**                  | HA clustering dan troubleshooting Linux                    |
| Setelah Fase 5 | **CompTIA CySA+** atau **Blue Team Level 1 (BTL1)**             | SOC analyst skill untuk Wazuh + IR                         |
| Setelah Fase 6 | **Terraform Associate** + **Ansible Automation**                | IaC dan automation adalah core Phase 2                     |
| Jangka panjang | **GIAC GCIA** atau **RHCE**                                     | Gold standard untuk infrastructure dan security operations |

---

## Yang TIDAK Perlu Dipelajari Sekarang

> [!warning] Jangan Buang Waktu
>
> - ~~AWS/Azure/GCP managed services~~ — role ini eksplisit bare-metal on-prem, tidak ada cloud underneath
> - ~~Kubernetes (K8s)~~ — tidak disebutkan di stack; mereka pakai Docker Compose untuk container orchestration
> - ~~Red Team tools (Metasploit, Burp Suite, Kali Linux)~~ — ini infrastructure defense & operations, bukan penetration testing
> - ~~Application development (React, Node.js, Python web frameworks)~~ — kamu operate infrastructure, bukan write application code
> - ~~Windows Server / Active Directory~~ — identity pakai Google Workspace OIDC, tidak ada AD domain
> - ~~Entry-level helpdesk skills (ticketing, desktop support)~~ — role ini expert-level build-from-scratch, bukan Tier-1 support
> - ~~CISSP~~ — butuh 5 tahun experience, bukan untuk target Phase 1 build

---

---

## 🛠️ Ansible Deep-Dive & Checkpoints (Status Tracker)

> **Prinsip utama**: 1 jam per hari, konsisten > marathon sesekali.  
> Checklist ini bukan tutorial — ini **proof of progress**. Jangan lanjut ke fase berikutnya sebelum checkpoint-nya bisa kamu jelaskan sendiri tanpa buka Google.

---

## Status Tracker

| Phase | Topic               | Status         |
| ----- | ------------------- | -------------- |
| 0     | Pre-existing Skills | ✅ Done        |
| 1     | Ansible Foundation  | 🔲 In Progress |
| 2     | Playbook Core       | 🔲 Not Started |
| 3     | Roles               | 🔲 Not Started |
| 4     | Real Power          | 🔲 Not Started |
| 5     | Real Project        | 🔲 Not Started |

---

## Phase 0 — What You Already Have

_Credit where it's due. These are real skills, not beginner level._

- [x] Linux administration (Rocky Linux + Ubuntu/Metasploitable)
- [x] Docker — deployed WAF, reverse proxy, monitoring stack
- [x] Nginx Proxy Manager + Cloudflare Tunnel
- [x] Basic network architecture (bridged, NAT, Tailscale)
- [x] Security monitoring mindset (auditd, CrowdSec, Suricata)

**You are not starting from zero.**

---

## Phase 1 — Ansible Foundation

_Target: 2 weeks | 1hr/day = ~14 sessions | 4-5hr day = 2-3 sessions_

### Setup

- [ ] Install Ansible on Rocky Linux as control node
- [ ] Configure SSH key-based auth from control → managed nodes
- [ ] Create first static inventory file (`/etc/ansible/hosts`)

### First Contact

- [ ] Run `ansible all -m ping` — all nodes respond
- [ ] Run ad-hoc command: install a package without SSH-ing manually
- [ ] Understand the difference: ad-hoc vs playbook

### First Playbook

- [ ] Write a playbook that creates a user on a remote host
- [ ] Write a playbook that installs and starts a service
- [ ] Understand `hosts`, `tasks`, `become`, `name` fields

### ✅ Phase 1 Checkpoint

> _Can you rebuild a basic server config (user + package + service) with one command?_  
> If yes → proceed. If no → repeat the playbook section.

---

## Phase 2 — Playbook Core

_Target: 2 weeks | Focus: making playbooks smart, not just sequential_

### Variables

- [ ] Define variables inside playbook (`vars:`)
- [ ] Use `group_vars/` and `host_vars/` directories
- [ ] Understand variable precedence (which one wins when two conflict)

### Logic

- [ ] Use `when:` for conditional tasks
- [ ] Use `loop:` to repeat tasks over a list
- [ ] Use `register:` to capture task output and act on it

### Handlers

- [ ] Understand what a handler is (runs only when notified)
- [ ] Write a handler that restarts Nginx only when config changes
- [ ] Understand why this matters vs just always restarting

### Tags

- [ ] Add tags to tasks
- [ ] Run only tagged tasks with `--tags`
- [ ] Skip specific tasks with `--skip-tags`

### ✅ Phase 2 Checkpoint

> _Write a playbook that:_  
> _- Installs Docker on Rocky Linux_  
> _- Only restarts Docker daemon if config changed_  
> _- Skips installation if Docker already exists_  
> If you can write that without copy-paste → proceed.

---

## Phase 3 — Roles

_Target: 2 weeks | Focus: reusable, structured automation_

### Role Structure

- [ ] Understand the folder structure: `tasks/`, `handlers/`, `vars/`, `defaults/`, `templates/`, `files/`
- [ ] Convert your Phase 2 playbook into a role
- [ ] Understand difference between `vars/` (fixed) and `defaults/` (overridable)

### Building Roles

- [ ] Write a `base_setup` role: user, SSH hardening, firewall basics
- [ ] Write a `docker_setup` role: install Docker + Compose
- [ ] Write a `monitoring` role: deploy Grafana + Prometheus via Docker

### Community Roles

- [ ] Use `ansible-galaxy role install` to pull a community role
- [ ] Understand how to read a role's README before using it
- [ ] Know when to use community roles vs write your own

### ✅ Phase 3 Checkpoint

> _Single command rebuilds your Docker stack on a fresh Rocky Linux VM._  
> Fresh VM → fully running stack: target under 10 minutes.

---

## Phase 4 — Real Power

_Target: 2 weeks | Focus: production-grade practices_

### Templates

- [ ] Write a Jinja2 template for Nginx config (`.conf.j2`)
- [ ] Use variables inside templates to make configs dynamic
- [ ] Deploy config from template — understand how it differs from static file copy

### Secrets Management

- [ ] Encrypt a secret with `ansible-vault encrypt_string`
- [ ] Use vault in a playbook — run it with `--ask-vault-pass`
- [ ] Store vault password in a file (understand the security tradeoff)

### Error Handling

- [ ] Use `block:` / `rescue:` / `always:` structure
- [ ] Use `ignore_errors:` carefully (know when NOT to use it)
- [ ] Use `failed_when:` to define your own failure condition

### Dynamic Inventory

- [ ] Understand why static inventory breaks at scale
- [ ] Write a simple Python/bash script that outputs JSON inventory
- [ ] (Optional) Use an inventory plugin for Docker or cloud

### ✅ Phase 4 Checkpoint

> _Your playbooks:_  
> _- Use templates for all config files_  
> _- Have zero plaintext passwords_  
> _- Handle failure without crashing the entire run_

---

## Phase 5 — Real Project

_Target: 2 weeks | This is the proof of everything_

### The Goal

Automate your **entire homelab rebuild** — from fresh Rocky Linux install to fully running production stack — with one command.

### What the Playbook Must Cover

- [ ] Base system setup (user, SSH keys, firewall, timezone)
- [ ] Docker + Docker Compose installation
- [ ] SafeLine WAF deployment via Docker
- [ ] CrowdSec + nftables bouncer
- [ ] Nginx Proxy Manager
- [ ] Grafana + Prometheus monitoring
- [ ] Cloudflare Tunnel connection

### Documentation (Do Not Skip)

- [ ] Write a `README.md` for your playbook repo
- [ ] Document every role: what it does, what variables it uses
- [ ] Post a breakdown on your digital garden — explain what you built

### ✅ Final Checkpoint

> _Time it. Fresh VM → full stack running._  
> _Target: under 15 minutes._  
> _Can you explain every role to someone who's never used Ansible?_  
> If yes — Phase 5 complete. You have a real, demonstrable DevOps skill.

---

## Daily Session Template

### 1-Hour Session (21:00–22:00)

```
00:00–10:00  Review yesterday's note — what did you actually build?
10:00–45:00  Hands-on only. Terminal open. Not tutorial-watching.
45:00–60:00  Write one note: what you built, what broke, how you fixed it.
```

### 4-5 Hour Session

```
Hour 1     : Review + plan which items to finish today
Hour 2-3   : Build — complete one full section of the current phase
Hour 3-4   : Break it intentionally — modify something, see what fails
Hour 4-5   : Fix it, document it, write the checkpoint explanation
```

**Rule**: If your terminal isn't open, you're not doing DevOps.

---

## Am I On Track? (Honest Self-Check)

Ask yourself these after each phase:

1. Can I explain what I built without opening Google?
2. If I deleted everything and started over, could I do it faster?
3. Did I write at least one note about what broke and why?

If all three are yes — you're on track.  
If not — that phase isn't done yet.

---

## On Relevance (The "Will This Matter in 2030?" Question)

Ansible as a tool may evolve. Infrastructure automation as a **concept** is permanent.

Someone who deeply understands Ansible can learn Terraform, Pulumi, or whatever comes next — in weeks, not months. The mental model transfers. Tool syntax doesn't define the skill.

> Learn it deep. One thing at a time. The compound effect of daily 1-hour sessions over 6 months is real.

---

_Last updated: June 2026_  
_Part of **Roadmaps** — Infrastructure Administrator path_

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[cyber-security|Cyber Security Blue Team Roadmap]] — Wazuh, OpenVAS, dan SOC operations lebih detail
- [[devops|DevOps Roadmap]] — CI/CD, Docker, dan automation practices
- [[network-security|Network Security]] — Deep dive pfSense, VLAN design, dan IDS/IPS
- [[endpoint-security|Endpoint Security]] — CIS hardening, auditd, AppArmor internals
- [[agentic-ai-mcp-roadmap|Agentic AI & MCP Roadmap]] — Jalur karir engineering AI agents
- [[ai-engineering-stack-roadmap|AI Engineering Stack Roadmap]] — Jalur karir MLOps / LLMOps
- [[offensive-security|Offensive Security Roadmap]] — Jalur Red Team (lawannya Blue Team)
- [[software-engineering|Software Engineering Roadmap]] — Jalur karir software development
- [[data-engineering|Data Engineering Roadmap]] — Jalur karir data engineering

---

_Roadmap IT Systems Engineer | Fase 1 (Virtualization) → Fase 6 (Ops Maturity) · 6 Bulan Homelab · Bare-Metal On-Prem Focus_
