---
title: "Infrastructure Hierarchy"
tags: [atlas, infrastructure]
aliases: [hierarchy-infrastructure]
---
# Hierarchy Infrastructure

Peta hierarki topik infrastruktur untuk vault — navigasi & struktur pengetahuan. Setiap cabang menunjuk ke area di 01_Library terkait.

## 1. Jaringan (Network)

- **OSI/Layer model** — L1 fisik → L7 aplikasi; implikasi security per layer.
- **Routing & switching** — VLAN, segmentasi, ACL, dynamic routing (OSPF/BGP).
- **DNS** — resolusi, DNSSEC, split-horizon, sinkhole (Pi-hole).
- **Load balancing** — L4/L7, health check, session persistence (lihat [[wiod-reverse-proxy-deepdive]]).
- **VPN** — IPSec, WireGuard, SSL VPN; tunnel vs split.
- **Wireless** — WPA2/3, 802.1X, rogue AP (lihat hierarchy-wireless).
- **IPv6** — alokasi, firewall, privacy extensions (sering terlewat!).

## 2. Server & Sistem Operasi

- **Linux** — admin, hardening (lihat [[production-server-hardening]]), systemd, package management.
- **Windows Server** — AD DS, GPO, hardening, Kerberos.
- **Virtualisasi** — KVM, Proxmox, ESXi; hypervisor hardening, guest isolation.
- **Container** — Docker/Podman (lihat [[nestjs-podman-workflow]]), orchestration (K8s — lihat hierarchy terkait), security ([[container-security-exploitation-deepdive]]).
- **Storage** — SAN/NAS, RAID, backup (3-2-1), snapshot.

## 3. Cloud & Platform

- **IaaS** — EC2/VMs, security groups, IMDSv2, VPC.
- **PaaS** — App Engine/Heroku, managed services.
- **SaaS** — identity, SSO, DLP.
- **Serverless** — Lambda/CF, event source security, cost.
- **IaC** — Terraform (state security, plan review), CloudFormation.
- **Multi-cloud** — AWS + GCP + Azure; identity federation.
- **Kubernetes** — control plane security, RBAC, NetworkPolicy, PSS ([[pod-security-standards]]).

## 4. Keamanan Infrastruktur

- **Firewall** — stateful, NGFW, egress control.
- **IDS/IPS** — signature vs anomaly; placement.
- **WAF** — lihat [[waf-plan]] dan [[waf-internal-architecture-deepdive]].
- **SIEM/SOAR** — log aggregation, correlation, automation.
- **Patching** — SLA per severity, CISA KEV prioritization.
- **Hardening baseline** — CIS benchmarks, ansible/automation.
- **Secrets** — lihat [[sealed-secrets-vs-vault]].

## 5. Reliability & Monitoring

- **Monitoring stack** — Prometheus/Grafana, ELK/Loki, tracing (OTel).
- **SLO/error budget** — lihat [[sre-practices-and-slo]].
- **Incident management** — severity, on-call, postmortem (lihat incidents/).
- **Backup/DR** — RTO/RPO, test restore, DR site.

## 6. Database & Data Layer

- **RDBMS** — Postgres/MySQL: auth, SSL, backup, hardening.
- **NoSQL** — Redis (auth!), MongoDB (network exposure), Elasticsearch (index security).
- **Data pipeline** — ETL, queue (Kafka/RabbitMQ), lakehouse.
- **Data security** — encryption at rest, masking, DLP.

## 7. Identitas & Akses (Identity)

- **IAM** — RBAC, least privilege ([[hierarchy-identity-trust]]).
- **SSO/IdP** — OIDC/SAML, SCIM, federation.
- **MFA** — TOTP, U2F, push; recovery.
- **Directory** — LDAP/AD, group policy.

## Keterkaitan

- 00_Atlas/hierarchy-cloud-infrastructure — detail cloud.
- 00_Atlas/hierarchy-cybersecurity-defense-architecture — defense architecture.
- 00_Atlas/hierarchy-devops-cicd — pipeline & operasi.
- 01_Library/Infrastructure/ — file detail.

## Struktur Catatan Infrastruktur

Setiap topik punya catatan dengan pola: konsep → konfigurasi aman → checklist → red team angle → wikilink ke catatan terkait. Ini memudahkan navigasi dari atlas ke detail.



## Detail Per Cabang (Reference Cepat)

### Jaringan — Konsep Kunci
1. **VLAN segmentation**: pisahkan IoT/guest/internal — default deny antar VLAN (ACL).
2. **DNS security**: DNSSEC (validasi), split-horizon (internal vs publik), sinkhole (domain jahat).
3. **VPN**: pilih WireGuard (modern, cepat) untuk site-to-site; open-source; pastikan key management.
4. **Load balancer**: health check (HTTP/TCP), session stickiness vs stateless, TLS termination di LB (lihat proxy note).
5. **Wireless**: WPA3-SAE, 802.1X untuk enterprise (RADIUS), disable WPS, captive portal (perhatikan MITM).

### Server — Praktik
- Systemd unit hardening (NoNewPrivileges, ProtectSystem) — lihat [[production-server-hardening]].
- SELinux/AppArmor enforce (bukan permissive).
- Patching: otomatis untuk security; window reboot terjadwal.
- Monitoring setiap node: node_exporter, agent (Wazuh/Osquery).

### Cloud — Checklist Keamanan
1. IAM role (bukan static key) — assume role dengan MFA.
2. Security group default deny + review berkala.
3. IMDSv2 (AWS) — blokir SSRF metadata theft.
4. Enkripsi: EBS/disk KMS, S3 SSE, RDS encryption.
5. Log: CloudTrail/VPC flow → SIEM.
6. Cost anomaly (resource baru tak dikenal = indikator compromise).

### Database — Hardening
1. Bind internal network (bukan 0.0.0.0 public).
2. Auth kuat (bukan default), SSL/TLS untuk koneksi.
3. Backup enkripsi + restore test.
4. Redis: requirepass + bind loopback; MongoDB: auth + network restrict.
5. Audit log query (slow query + access).

### Identity — Zero Trust Pilar
- MFA semua admin; privilege access management (PAM) untuk root.
- SSO via OIDC; SCIM provisioning (offboarding otomatis).
- RBAC review kuartalan; service account minimal.
- Session: short-lived, refresh rotation, device posture check.

---

  audited
---