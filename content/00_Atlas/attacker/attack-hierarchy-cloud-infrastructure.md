---
title: Attack Perspective — Cloud Infrastructure (Red Team)
tags:
- attack
- red-team
- cloud
- iam
- k8s
- container
- imds
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Cloud Infrastructure — Perspektif Penyerang

> Cloud attack berbeda dengan on-prem: tidak ada network perimeter tradisional. Attack surface = IAM, API, container, metadata service, CI/CD pipeline.

## 1. Cloud Attack Surface

| Layer          | Vektor                                               | MITRE ID  | Tool / CVE                         | Evasion                                                    | Detection Gap                                     |
| -------------- | ---------------------------------------------------- | --------- | ---------------------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| **IMDS**       | Metadata service (169.254.169.254) → instance creds  | T1590.005 | curl, SSRF → IMDSv1                | IMDSv2 butuh header — SSRF bisa bypass jika tidak enforced | CloudTrail log delay, IMDS access = legit pattern |
| **IAM**        | Privilege escalation (PassRole, AssumeRole)          | T1078.004 | Pacu, CloudSploit, enumerate       | IAM role chaining = legit cloud operation                  | CSPM periodic scan, not real-time                 |
| **S3/Storage** | Public bucket, ACL abuse, misconfig                  | T1530     | s3scanner, bucket_finder           | Public bucket = anonymous, no trace                        | S3 audit log jarang di-enable                     |
| **K8s**        | RBAC abuse, service account token, admission webhook | T1078.004 | kubectl, rbac-lookup               | SA token mounted in every pod = legit                      | K8s audit log verbose = noise                     |
| **Container**  | Escape (runc, containerd)                            | T1611     | CVE-2024-21626, CVE-2019-5736      | Container escape = host root                               | Falco/Tetragon — butuh eBPF support               |
| **CI/CD**      | Pipeline poison, runner compromise                   | T1195.002 | GitHub Actions, GitLab CI, Jenkins | Signed commit, merge queue bypass                          | CI/CD log audit jarang                            |
| **Terraform**  | State file theft → secrets                           | T1530     | S3 backend, local state            | State file = plaintext secrets                             | Terraform state audit jarang                      |

## 2. Cloud Kill Chain

```
Recon: Shodan/cloud API enum → identify cloud provider, region, service
 ↓
Initial Access: SSRF → IMDS → instance creds / Phishing → cloud admin creds
 ↓
Privilege Escalation: IAM enumerate → PassRole/AssumeRole → elevated permissions
 ↓
Lateral: Cloud role chaining → cross-account → cross-region
 ↓
Persistence: IAM user creation, role backdoor, lambda function, cloud shell
 ↓
Collection: S3 bucket enum, RDS snapshot, CloudWatch log, secret manager
 ↓
Exfiltration: rclone → cloud storage (Backblaze/Dropbox), API exfil
 ↓
Impact: Data exfil, resource hijack (crypto mining), ransomware (cloud snapshot encrypt)
```

## 3. CVE Prioritas Cloud (2024-2026)

| CVE | Target | Impact | Red Team Value |
|-----|--------|--------|----------------|
| CVE-2024-21626 | runc | Container escape → host root | High — cluster compromise |
| CVE-2023-50244 | containerd | Privilege escalation | Medium — container level |
| CVE-2024-27198 | TeamCity CI | Pre-auth RCE → CI/CD poison | Critical → supply chain chain |
| CVE-2023-38646 | Metabase | Pre-auth RCE → data access | High → cloud-hosted analytics |

## 4. Tool Stack Cloud Red Team

| Tool | Cloud | Use |
|------|-------|-----|
| **Pacu** | AWS | IAM escalation, account enum, exploit modules |
| **CloudSploit** | Multi-cloud | Config audit, misconfig detection |
| **ScoutSuite** | Multi-cloud | Cloud posture, IAM audit |
| **kubectl** | K8s | RBAC enum, SA token, pod exec |
| **grype** | Container | Image vulnerability scan |
| **trivy** | Container/IaC | Image + Terraform scan |
| **rclone** | Exfil | Cloud storage copy (multi-provider) |

## 5. Referensi
- Pacu (AWS Attack) — https://github.com/RhinoSecurityLabs/pacu
- CloudSploit — https://github.com/cloudsploit/scans
- ScoutSuite — https://github.com/nccgroup/ScoutSuite
- Falco (K8s Runtime) — https://falco.org/
- Tetragon (eBPF Security) — https://github.com/cilium/tetragon
- AWS IMDSv2 — https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html