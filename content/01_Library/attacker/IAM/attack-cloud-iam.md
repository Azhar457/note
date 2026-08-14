---
title: Attack Perspective — Cloud & IAM (Red Team)
tags:
- attack
- red-team
- cloud
- iam
- imds
- privesc
- aws
- azure
- gcp
- ssrf
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Cloud & IAM — Perspektif Penyerang

> Cloud IAM = perimeter baru. Red team serang: IMDS SSRF → instance creds, IAM privilege escalation, cross-account role chaining, service account abuse, managed identity theft.

## 1. Attack Surface Cloud IAM

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **IMDS** | SSRF → 169.254.169.254 → instance creds | T1590.005 | curl SSRF, IMDSv1 no-header | IMDSv1 = no auth required | CloudTrail delay |
| **IAM Role** | AssumeRole abuse, PassRole escalation | T1078.004 | Pacu, enumerate roles | Role chaining = legit cloud op | CSPM periodic scan |
| **Managed Identity** | Azure MI token theft | T1078.004 | curl MSI endpoint, token replay | Token = valid identity | Azure audit = delayed |
| **Service Account** | GCP SA key theft | T1078.004 | gcloud auth, key extraction | SA key = valid auth | GCP audit = rare |
| **CloudTrail** | Disable logging → no audit | T1562.008 | aws cloudtrail delete-trail | No audit = no evidence | CloudTrail disable = delayed alert |
| **S3/Storage** | Public bucket, ACL abuse | T1530 | s3scanner, aws s3 sync | Anonymous = no trace | S3 audit log = rare |
| **Lambda** | Over-permissive role, env var secret | T1078.004 | Pacu lambda module | Lambda = legit execution | Serverless audit = nascent |
| **KMS** | Key policy abuse, key theft | T1552 | aws kms decrypt, key enum | KMS = legit crypto service | KMS audit = rare |

## 2. IAM Privilege Escalation Chain

```
Recon: Enumerate IAM (Pacu/ScoutSuite)
  ├── List users, roles, policies
  ├── Identify over-permissive policy (Action: "*" Resource: "*")
  └→ Identify escalation vector (PassRole, AssumeRole, CreateUser)
    ↓
Escalation Vector:
  ├── PassRole: create role → pass existing role → elevate
  ├── AssumeRole: assume privileged role → elevate
  ├── CreateUser: create admin user → persist
  ├── AttachPolicy: attach admin policy to self
  ├── UpdateRole: modify role policy → elevate
  └── CreateAccessKey: create key for admin user
    ↓
Chain: Low-priv user → escalation → admin access
    ↓
Persistence: Backdoor role, Lambda layer, new user
```

## 3. IMDS SSRF Attack

```
Find SSRF: Web app → parameter fetch URL
  ├── http://169.254.169.254/latest/meta-data/
  ├── http://169.254.169.254/latest/meta-data/iam/security-credentials/
  └→ http://169.254.169.254/latest/meta-data/iam/security-credentials/[role]
    ↓
Extract: Instance role creds (AccessKey, SecretKey, Token)
    ↓
Exploit: aws configure --profile pwned → aws s3 ls → aws sts get-caller-identity
    ↓
Lateral: Access S3, EC2, Lambda, KMS → full cloud
    ↓
Evasion: IMDSv1 = no header requirement → trivial SSRF
```

## 4. Tool Stack

| Tool | Cloud | Use |
|------|-------|-----|
| **Pacu** | AWS | IAM escalate, account enum, exploit module |
| **ScoutSuite** | Multi | Cloud posture, IAM audit |
| **CloudSploit** | Multi | Config audit |
| **AADInternals** | Azure | Azure AD attack |
| **gcloud** | GCP | SA key abuse, resource enum |
| **rclone** | Exfil | Cloud storage copy |

## 5. Referensi
- Pacu — https://github.com/RhinoSecurityLabs/pacu
- ScoutSuite — https://github.com/nccgroup/ScoutSuite
- AWS IAM Escalation — https://github.com/RhinoSecurityLabs/aws-iam-privesc
- IMDSv2 — https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
- GCP SA Security — https://cloud.google.com/iam/docs/service-account-security