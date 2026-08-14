---
title: Attack Perspective — Infrastructure Evolution (Red Team)
tags: [attack,red-team,infrastructure,evolution,bare-metal,cloud,edge,sdn,noauth]
source: hierarchy-infrastructure-evolution.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Infrastructure Evolution — Perspektif Penyerang

> Infrastructure evolve: bare-metal → VM → container → cloud → serverless → edge. Setiap evolusi = attack surface baru. Red team serang: layer boundary, supply chain, misconfiguration, credential boundary.

## 1. Attack Surface per Era Infrastruktur

| Era | Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|-----|----------|--------|----------|------------|---------|----------------|
| **Bare Metal** | Physical server, LAN | Physical access, firmware implant | T1542 | UEFI implant, console access | No EDR signal (hardware) | Physical audit = rare |
| **VM** | Hypervisor, guest | VM escape, side-channel | T1611 | CVE-2024-21626, Spectre | Co-location = cache leak | Hypervisor audit = rare |
| **Container** | Docker, K8s | Container escape, RBAC abuse, SA token | T1611 | CVE-2024-21626, kubectl | Container → host root | Falco (eBPF) = partial |
| **Cloud (IaaS)** | IAM, IMDS, S3 | IMDS SSRF, IAM escalate, bucket public | T1078.004 | Pacu, CloudSploit | IMDSv1 = no auth | CloudTrail = delayed |
| **Serverless (FaaS)** | Lambda, Functions | Event inject, IAM role | T1190 | API poison, Pacu | Ephemeral → no monitoring | Serverless audit = nascent |
| **Edge (CDN)** | CDN, WAF, edge worker | Edge worker abuse, cache poison, origin IP | T1190 | Worker inject, origin leak | Edge = distributed → hard attribute | Edge audit = rare |
| **SDN/NFV** | OpenFlow, virtual network | Controller compromise → fabric hijack | T1490 | SDN controller takeover (OpenDaylight ONOS) | Controller = central → fabric access | SDN audit = nascent |

## 2. Cloud Attack Chain (Detailed)

```
Recon: Cloud enum → identify provider, region, service
 ├── crt.sh → subdomain → tech stack
 ├── Shodan → exposed service (cloud vs on-prem)
 └→ GitHub dork → credential leak → cloud API key
 ↓
Initial Access:
 ├── SSRF → IMDS (169.254.169.254) → instance creds
 ├── Phishing → cloud admin credential → console
 ├── API key leak (GitHub, hardcoded) → API access
 └→ Public bucket → metadata leak
 ↓
Privilege Escalation:
 ├── IAM enumerate → PassRole → escalate
 ├── AssumeRole chaining → cross-account → cross-region
 └→ K8s RBAC → service account token → cluster admin
 ↓
Lateral:
 ├── Cloud role chaining → cross-account → cross-service
 ├── K8s pod exec → node → cluster → cloud
 └→ VPC peering → cross-network
 ↓
Exfiltration:
 ├── rclone → cloud storage → external (S3, Backblaze, Dropbox)
 ├── K8s secret → service account token → cloud API
 └→ Data warehouse query → dump → cloud exfil
 ↓
Persistence:
 ├── IAM user backdoor → perpetual access
 ├── Lambda layer → backdoor all function
 ├── K8s daemonset → persistent pod
 └→ Cloud shell → persistent session
```

## 3. Misconfiguration Attack Matrix

| Misconfiguration | Attack | Impact |
|------------------|--------|--------|
| **S3 public bucket** | s3 sync → bulk download | Data exfiltration |
| **IMDSv1 enabled** | SSRF → IMDS → instance creds | Instance compromise |
| **K8s dashboard open** | kubectl → pod → node → cluster | Cluster compromise |
| **IAM over-permissive** | PassRole → escalate → admin | Account compromise |
| **Lambda env var with secret** | Lambda invoke → env dump → secret | Credential theft |
| **CloudTrail disabled** | delete-trail → no audit | No forensic evidence |
| **Terraform state public** | S3 backend → plaintext secrets | Secret theft |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Pacu** (AWS) | IAM escalate, account enum, exploit module |
| **ScoutSuite** | Multi-cloud posture, IAM audit |
| **CloudSploit** | Config audit, misconfig detection |
| **kubectl** | K8s RBAC enum, pod exec, SA token |
| **rclone** | Cloud exfiltration (multi-provider) |
| **grype / trivy** | Container image vulnerability scan |

## 5. Referensi
- Pacu — https://github.com/RhinoSecurityLabs/paciu
- ScoutSuite — https://github.com/nccgroup/ScoutSuite
- Falco — https://falco.org/
- AWS IMDSv2 — https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
- K8s Security — https://kubernetes.io/docs/concepts/security/