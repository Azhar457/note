---
title: "Cloud Security Posture Management — Deep Dive: CSPM, K8s Admission Control,
  AWS IAM, dan Cloud-Native WAF"
tags:
  - cloud-security
  - infrastructure
  - library
created: "2026-07-15"
updated: "2026-07-15"
status: operational
cssclasses: ""
---

# ☁️ Cloud Security Posture Management — Deep Dive: CSPM, K8s Admission Control, AWS IAM, dan Cloud-Native WAF

> Panduan komprehensif keamanan cloud-native mulai dari Cloud Security Posture Management (CSPM), Kubernetes admission control (OPA/Gatekeeper, Kyverno), AWS IAM policies & identity federation, cloud-native WAF (AWS WAF, Cloud Armor, Cloudflare WAF), hingga CIEM (Cloud Infrastructure Entitlement Management). Mencakup attack vectors spesifik cloud (S3 bucket misconfiguration, IAM privilege escalation, K8s RBAC abuse) serta tooling deteksi (CloudSploit, Prowler, Checkov, Kubescape).

> [!info] Hubungan ke Vault
> Nota ini terkait dengan [[cloud-infrastructure]] untuk gambaran arsitektur cloud secara umum, [[container-kubernetes-security-deepdive]] untuk fondasi keamanan container yang diperluas ke admission control dan cloud security posture, [[cicd-shiftleft-shiftright]] dan [[cicd-guide]] untuk DevSecOps pipeline placement, [[Note/01_Library/Cyber_Security/IAM/identity-and-access-management|identity-and-access-management]] untuk identitas dan akses, [[api-security-deep-dive]] dan [[waf-reverse-proxy-deepdive]] untuk WAF di perimeter cloud, serta [[zero-trust-security]] untuk prinsip zero trust di cloud.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Mengapa Cloud Security Berbeda dari On-Premise?

Keamanan cloud tidak bisa disamakan dengan on-premise karena beberapa perbedaan fundamental:

| Aspek                        | On-Premise                             | Cloud (IaaS/PaaS)                                                                                              |
| ---------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Perimeter**                | Jaringan fisik (firewall, DMZ)         | Identity dan API — "the perimeter is the IAM policy"                                                           |
| **Kontrol akses**            | VLAN + firewall rules                  | IAM role + policy + resource-based policy                                                                      |
| **Model tanggung jawab**     | Sepenuhnya milik organisasi            | Shared Responsibility Model (AWS: security OF the cloud vs security IN the cloud)                              |
| **Skalabilitas konfigurasi** | Manual atau script terbatas            | Infrastructure as Code (IaC) — Terraform, Pulumi, CloudFormation                                               |
| **Visibility**               | Log server + network flow              | CloudTrail, AWS Config, VPC Flow Logs, GuardDuty                                                               |
| **Eksposur**                 | Terbatas pada IP publik yang diketahui | API endpoints, managed services, serverless functions — bisa ter-expose tanpa sengaja via IAM misconfiguration |

### Shared Responsibility Model (AWS sebagai contoh)

```
┌───────────────────────────────────────────────┐
│                  CUSTOMER                     │
│  Data classification & encryption             │
│  Platform, applications, IAM, OS patching     │
│  Network traffic protection, firewall config  │
├───────────────────────────────────────────────┤
│                  AWS                          │
│  Compute, storage, database, networking       │
│  Global infrastructure (AZ, regions, edge)    │
│  Physical security, hardware lifecycle        │
└───────────────────────────────────────────────┘
```

**Kesalahan umum:** Customer menganggap di PaaS (misal RDS dengan IAM auth) semua secure — tapi tetap harus mengatur security group, parameter group encryption, backup encryption, dan audit logging.

### Cloud Security Posture Management (CSPM)

CSPM adalah kategori tool yang secara otomatis mengidentifikasi misconfiguration, compliance violation, dan risiko keamanan di lingkungan cloud (multi-cloud).

| Dimensi               | Tools Open Source                     | Tools Komersial                       |
| --------------------- | ------------------------------------- | ------------------------------------- |
| **AWS**               | Prowler, ScoutSuite, CloudSploit      | AWS Security Hub, Wiz, Orca, Lacework |
| **Azure**             | Prowler (Azure support), Azure Policy | Microsoft Defender for Cloud          |
| **GCP**               | Prowler (GCP support), Forseti        | Google Security Command Center        |
| **Multi-Cloud / IaC** | Checkov, Terrascan, tfsec, KICS       | Bridgecrew, Prisma Cloud, Snyk IaC    |

#### Misconfiguration Paling Umum (Berdasarkan CSA & CrowdStrike 2024 Report)

1. **S3 Bucket public-read atau public-write** — data breach paling umum di cloud (bucket name unik + misconfigured ACL/bucket policy).
2. **IAM policy overly permissive** — `"Effect": "Allow"` dengan `"Action": "*"` dan `"Resource": "*"`.
3. **Security Group ingress 0.0.0.0/0** — port SSH (22), RDP (3389), MySQL (3306) terbuka ke internet.
4. **Unrestricted outbound traffic** — egress 0.0.0.0/0 tanpa filter untuk data exfiltration.
5. **KMS key with cross-account access** — bisa jadi data leaking ke account yang tidak diaudit.
6. **Public EBS/AMI snapshot** — snapshot snapshot bisa berisi data sensitif.
7. **Unused / orphaned resources** — Elastic IP, EBS volume unattached → cost + security risk.
8. **Credentials in source code / CI variables** — IAM keys hardcoded.

### Kubernetes Admission Control

API server Kubernetes memiliki tiga fase untuk intercept request sebelum objek di-persist:

```
kubectl create pod → kubectl → Authentication → Authorization → ADMISSION CONTROL → etcd
                                                                     │
                                                ┌────────────────────┘
                                                ▼
                                     MutatingWebhook → ValidatingWebhook
```

| Tipe                     | Fase                  | Perubahan Objek        | Contoh                                                       |
| ------------------------ | --------------------- | ---------------------- | ------------------------------------------------------------ |
| **Mutating admission**   | Sebelum validasi      | Bisa ubah/mutate objek | Inject sidecar, add labels, default security context         |
| **Validating admission** | Setelah mutasi        | Read-only              | Verifikasi required labels, deny privileged containers       |
| **Built-in**             | Bawaan kube-apiserver | Variatif               | AlwaysPullImages, NamespaceExist, PodSecurity, ResourceQuota |

#### Policy Engines untuk Admission Control

| Engine             | Bahasa                        | Mutating          | Validating | Popularitas                                                       |
| ------------------ | ----------------------------- | ----------------- | ---------- | ----------------------------------------------------------------- |
| **OPA Gatekeeper** | Rego declarative              | ✅ (via mutation) | ✅         | Sangat luas, CNCF graduated, library policy library (G8S)         |
| **Kyverno**        | YAML-native (no new language) | ✅                | ✅         | Paling mudah dipelajari, growing rapidly, CNCF incubating         |
| **Kubewarden**     | WebAssembly (Rust, Go, JS)    | ✅                | ✅         | Performa tinggi, zero-trust supply chain, multi-language policies |
| **jsPolicy**       | JavaScript                    | ✅                | ✅         | Familiar untuk JS developers                                      |

---

## Technical Deep-Dive

### AWS IAM — Deep Dive Privilege Escalation Vectors

#### IAM Policy Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::corp-data/*",
      "Condition": {
        "IpAddress": { "aws:SourceIp": "10.0.0.0/8" }
      }
    }
  ]
}
```

Komponen: **Effect** (Allow/Deny) → **Action** (service:operation) → **Resource** (ARN spesifik/wildcard) → **Condition** (opsional: IP, VPC endpoint, MFA, time, user agent).

#### IAM Privilege Escalation — 21 Methods (by Rhino Security Labs)

Metode populer yang sering dieksploitasi ketika attacker mendapatkan IAM credentials dengan `iam:PassRole` atau `iam:CreatePolicyVersion`:

| #   | Metode                              | Izin Dibutuhkan                                                                                                                                         |
| --- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **CreateNewPolicyVersion**          | `iam:CreatePolicyVersion` — bisa set policy version baru dengan full admin                                                                              |
| 2   | **SetExistingDefaultPolicyVersion** | `iam:SetDefaultPolicyVersion` — rollback ke versi policy lama yang lebih permisif                                                                       |
| 3   | **PassRoleToEC2**                   | `iam:PassRole` + `ec2:RunInstances` — launch EC2 dengan role admin → SSH → `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE` |
| 4   | **PassRoleToLambda**                | `iam:PassRole` + `lambda:CreateFunction` + `lambda:InvokeFunction` — buat Lambda dengan admin role                                                      |
| 5   | **PassRoleToCloudFormation**        | `iam:PassRole` + `cloudformation:CreateStack` — deploy stack yang execute custom resource dengan admin role                                             |
| 6   | **UpdateAssumeRolePolicy**          | `iam:UpdateAssumeRolePolicyDocument` — buka trust policy ke akun attacker                                                                               |
| 7   | **CreateAccessKey**                 | `iam:CreateAccessKey` — buat access key untuk user lain (misalnya admin)                                                                                |
| 8   | **CreateLoginProfile**              | `iam:CreateLoginProfile` — set password untuk user lain                                                                                                 |
| 9   | **AttachUserPolicy**                | `iam:AttachUserPolicy` — attach admin policy ke user attacker                                                                                           |
| 10  | **PutUserPolicy**                   | `iam:PutUserPolicy` — inline policy dengan akses penuh ke attacker                                                                                      |

**Mitigasi:**

- Gunakan **Permissions Boundary** — set batas maksimum izin yang bisa diberikan ke user/role.
- Implementasi **SCP (Service Control Policy)** di AWS Organizations — berlaku untuk ALL accounts di OU, override IAM permissions.
- Monitor **CloudTrail** untuk event `PassRole`, `CreatePolicyVersion`, `UpdateAssumeRolePolicy` dari non-admin.

### Kubernetes Admission Control — Praktis dengan Kyverno

#### Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno --create-namespace \
  --version v3.3.0 \
  --set admissionController.replicas=2
```

#### Policy 1: Prevent Privileged Containers (Validate)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
spec:
  validationFailureAction: Enforce
  rules:
    - name: privileged-containers
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Privileged containers are not allowed. Please remove 'securityContext.privileged: true'"
        pattern:
          spec:
            containers:
              - securityContext:
                  privileged: "false"
```

#### Policy 2: Enforce Image Registry (Mutate + Validate)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: validate-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Image must be from trusted registry (harbor.corp.internal or docker.corp.internal)"
        foreach:
          - list: "request.object.spec.initContainers[]"
            pattern:
              image: "harbor.corp.internal/*"
          - list: "request.object.spec.containers[]"
            pattern:
              image: "harbor.corp.internal/*"
```

#### Policy 3: Auto-Inject Sidecar (Mutate — Proxy Injection)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-sidecar
  annotations:
    policies.kyverno.io/title: Inject Sidecar Proxy
    policies.kyverno.io/subject: Pod
spec:
  rules:
    - name: inject-envoy
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - "app-*"
      mutate:
        patchStrategicMerge:
          spec:
            containers:
              - name: envoy-sidecar
                image: envoyproxy/envoy:v1.30-latest
                ports:
                  - containerPort: 9901
                volumeMounts:
                  - name: envoy-config
                    mountPath: /etc/envoy
```

### Cloud-Native WAF — AWS WAF vs Cloud Armor vs Cloudflare

| Fitur               | AWS WAF                                | Google Cloud Armor                         | Cloudflare WAF                               |
| ------------------- | -------------------------------------- | ------------------------------------------ | -------------------------------------------- |
| **Deployment**      | CloudFront, ALB, API Gateway, AppSync  | Cloud Load Balancing, Cloud CDN, Media CDN | Any HTTP/HTTPS via reverse proxy             |
| **Rule engine**     | JSON-based rule groups + Managed rules | YAML-based security policies               | WAF rule builder + Managed rulesets          |
| **Rate limiting**   | Rate-based rules (5-minute window)     | Rate limiting per IP                       | Rate limiting rules + Advanced DDoS          |
| **Bot control**     | AWS WAF Bot Control (managed)          | Google Cloud Armor Bot Management          | Bot Fight Mode + Super Bot Fight             |
| **IP reputation**   | AWS Managed Rules (anonymous IP, etc.) | Managed rules from threat intelligence     | Project Honey Pot, own intelligence          |
| **Custom response** | Block / Count + custom response code   | Deny / Redirect / Rate Limit               | Challenge / JS Challenge / Block             |
| **OWASP Top 10**    | AWS Managed Rules (core rule set)      | OWASP CRS preconfigured                    | OWASP CRS + Cloudflare Managed Rules         |
| **Pricing**         | $5/rule + $0.60/1M requests            | $5-15/policy per month                     | Free tier available, Pro/Business/Enterprise |

#### AWS WAF — Core Rule Set (OWASP CRS Equivalent)

```json
{
  "Name": "AWSManagedRulesCommonRuleSet",
  "Priority": 0,
  "Statement": {
    "ManagedRuleGroupStatement": {
      "VendorName": "AWS",
      "Name": "AWSManagedRulesCommonRuleSet",
      "ExcludedRules": []
    }
  },
  "OverrideAction": { "Count": {} },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "AWSCommonRules"
  }
}
```

### Cloud Infrastructure Entitlement Management (CIEM)

CIEM adalah kategori keamanan yang fokus pada manajemen entitlement dan izin di lingkungan cloud multi-account.

| Masalah yang Dipecahkan CIEM                                                 | Tool                                                        |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------- |
| **Over-privileged roles** — identity yang punya izin jauh melebihi kebutuhan | Ermetic (Tenable), Entitle (Bionic), CloudKnox (Alkira)     |
| **Unused permissions** — izin yang tidak pernah digunakan dalam 90+ hari     | AWS IAM Access Analyzer, Azure AD Entitlement Management    |
| **Cross-account access** — trust relationships yang terlalu longgar          | AWS IAM Access Analyzer (cross-account access), CloudSploit |
| **Human vs machine identity** — membedakan yang perlu MFA                    | AWS IAM last-used, AWS CloudTrail Insights                  |
| **Just-in-Time access** — izin sementara dengan approval workflow            | AWS IAM Identity Center (SSO), Teleport, Apono              |

---

## Advanced

### Kubernetes Admission Control — Gatekeeper (OPA) Policy Library

Koleksi policy umum menggunakan Rego/Gatekeeper:

#### ConstraintTemplate: Block NodePort Service

```rego
# constrainttemplate.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: blocknodeport
spec:
  crd:
    spec:
      names:
        kind: BlockNodeport
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sblocknodeport
        violation[{"msg": msg}] {
          input.review.kind.kind == "Service"
          input.review.operation == "CREATE"
          input.review.object.spec.type == "NodePort"
          msg := "Service type NodePort is not allowed"
        }
---
# constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: BlockNodeport
metadata:
  name: block-nodeport-all
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Service"]
```

### Zero-Trust Networking for Cloud (BeyondCorp, Tailscale, SPIFFE/SPIRE)

#### SPIFFE/SPIRE — Identity Federation untuk Workload

SPIFFE (Secure Production Identity Framework for Everyone) menyediakan identitas kriptografis untuk setiap workload (container, VM, bare-metal):

```
Workload → SPIRE Agent → SPIRE Server → Certificate Authority
              │
              ▼
    SVID (X.509 / JWT)
```

**Implementasi:**

```yaml
# spire-server deployment
server:
  ca_subject:
    country: ID
    organization: Corp Security
  federation:
    - bundle_endpoint:
        address: 0.0.0.0
        port: 8443
```

```bash
# Agent registrasi — memberikan identitas ke workload
spire-server entry create \
  -spiffeID spiffe://corp.internal/nginx \
  -parentID spiffe://corp.internal/k8s-node \
  -selector k8s:pod-label:app:nginx

# Workload API — mendapatkan SVID
spire-agent api fetch /tmp/svid.pem
```

### Cloud Attack Path Analysis

**Attack Path:** Rantai eksploitasi yang menghubungkan kompromi satu resource ke resource kritis di cloud.

Contoh attack path dengan Stratus Red Team:

```
Step 1: Attacker compromise GitHub personal access token → access AWS CodeBuild
Step 2: CodeBuild has iam:PassRole to a build role
Step 3: Build role has s3:GetObject on secret bucket
Step 4: Secret bucket contains database credentials
Step 5: Database (RDS) is publicly accessible with 0.0.0.0/0 ingress
```

| Tool Attack Path Analysis      | Cloud                            |
| ------------------------------ | -------------------------------- |
| **Stratus Red Team** (Datadog) | AWS — simulate attack techniques |
| **CloudSploit**                | AWS, Azure, GCP                  |
| **Prowler**                    | AWS, Azure, GCP                  |
| **Wiz Cloud Security**         | Multi-cloud + Kubernetes         |
| **Orca Security**              | Multi-cloud (agentless)          |

### Hardening Checklist — Cloud Security

```
☐ Enable CloudTrail / AWS Config / GuardDuty di ALL regions
☐ S3 Block Public Access — enabled di account level (AKIA...)
☐ IAM: enable last-used permissions analysis tiap 90 hari
☐ IAM: hapus access key > 90 hari tidak dipakai
☐ IAM: enforce MFA untuk ALL human users
☐ SCP: deny non-approved regions
☐ SCP: deny root user actions (kecuali emergency)
☐ EC2: restrict security group ingress — deny 0.0.0.0/0 for non-web services
☐ EBS: enable encryption by default (AES-256 KMS)
☐ RDS: enable encryption + automated backup
☐ K8s: enable OPA Gatekeeper / Kyverno di ALL clusters
☐ K8s: restrict NodePort services
☐ K8s: enforce readOnlyRootFilesystem + drop all capabilities
☐ VPC: enable Flow Logs for every VPC
☐ VPC: restrict default security group (no ingress rule)
☐ Secrets: use Secrets Manager / Parameter Store / Vault — never plaintext in code
☐ ECR: enforce image scanning + tag immutability
☐ Lambda: restrict VPC access + minimum IAM role
☐ CloudFront: enforce HTTPS + WAF
☐ Backup: automated backup plan dengan retention 30+ hari
```

### Sigma Detection Rules for Cloud Attacks

#### S3 Bucket Public Access Change

```yaml
title: S3 Block Public Access Disabled
id: d9f2e44a-9c08-4b7a-8e1f-6d5c3b2a1e7f
status: experimental
logsource:
  product: aws
  service: cloudtrail
detection:
  selection:
    eventSource: s3.amazonaws.com
    eventName:
      - PutBucketAcl
      - PutBucketPolicy
      - PutBucketPublicAccessBlock
  condition: selection
level: high
```

#### IAM Privilege Escalation via PassRole

```yaml
title: IAM PassRole to EC2 by Non-Admin
id: 7c9e5f1a-3d8c-4b6e-9f2a-1d5e7c8b0a3f
status: experimental
logsource:
  product: aws
  service: cloudtrail
detection:
  selection:
    eventSource: ec2.amazonaws.com
    eventName: RunInstances
  filter:
    requestParameters|contains: IamInstanceProfile
  condition: selection and filter
level: medium
```

---

## Case Studies

| Studi Kasus                                  | Konteks                                                                                                             | Temuan Kunci                                                                                                                                                                                                           | Mitigasi Diimplementasi                                                                                                                                                          |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Capital One Breach (2019)**                | PaaS WAF misconfiguration (WAF not blocking SSRF) → attacker access metadata service from EC2 → IAM role credential | 1. WAF tidak memblokir SSRF. 2. IAM role terlalu permisif (read all S3). 3. Metadata service endpoint 169.254.169.254 dapat diakses dari aplikasi. 4. 100M+ records terekspos.                                         | 1. WAF blocking SSRF. 2. IMDSv2 (session-oriented metadata). 3. S3 bucket policy ketat per aplikasi. 4. Network segmentation EC2 + S3 via VPC Endpoint.                          |
| **Accenture Leak via S3 (2022)**             | S3 bucket salah konfigurasi — public-read ACL                                                                       | 1. Bucket untuk penyimpanan data partner expose: API keys, credentials, secrets. 2. 6 TB data ter-expose selama 4 bulan.                                                                                               | 1. S3 Block Public Access enable all account level. 2. Automated CSPM scanning + AWS Config rule. 3. Incident response untuk exposed credentials.                                |
| **Tesla Kubernetes Compromise (2018)**       | K8s cluster tidak di-authenticate → attacker access dashboard → get kubeconfig                                      | 1. K8s dashboard tidak dilindungi (exposed via LoadBalancer tanpa auth). 2. Cluster tidak menggunakan RBAC — satu pod bisa akses semua secret. 3. Mining cryptocurrency langsung di pod yang tidak dibatasi resources. | 1. K8s dashboard HA (disable default). 2. Enable RBAC + OIDC integration. 3. Resource quota + limit range. 4. NetworkPolicy default deny.                                        |
| **EggShell AWS Attack (2023)**               | Attacker gunakan IAM credential dari compromised GitHub → privilege escalation                                      | 1. GitHub Action token dgn `iam:PassRole` + `ec2:RunInstances`. 2. Launch EC2 dengan admin role → ekstrak credential dari metadata. 3. Persistence via IAM user baru + access key.                                     | 1. OIDC-based GitHub Actions (no static keys). 2. SCP untuk membatasi PassRole. 3. IAM Access Analyzer izin yang tidak digunakan. 4. AWS Config + Security Hub auto-remediation. |
| **Simulated Red Team: Cloud Pentest (2024)** | Lateral movement dari account dev ke account production via role chaining                                           | 1. Dev account punya `sts:AssumeRole` ke role yang bisa `iam:PassRole` ke role produksi. 2. Backdoor via Lambda function dengan production role. 3. Unattended EBS snapshot bisa di-mount di account attacker.         | 1. SCP batasi cross-account assume role dari non-prod. 2. Hapus unused snapshots/image. 3. Monitoring CloudTrail cross-account events.                                           |

---

---

## Cloud-Native WAF — Cross-Provider Comparison

### AWS WAF vs Azure WAF vs GCP Cloud Armor vs Cloudflare

| Fitur               | AWS WAF                                | Azure WAF                                       | GCP Cloud Armor                            | Cloudflare WAF                               |
| ------------------- | -------------------------------------- | ----------------------------------------------- | ------------------------------------------ | -------------------------------------------- |
| **Deployment**      | CloudFront, ALB, API Gateway, AppSync  | Application Gateway, Front Door, CDN            | Cloud Load Balancing, Cloud CDN, Media CDN | Any HTTP/HTTPS via reverse proxy             |
| **Rule engine**     | JSON-based rule groups + Managed rules | Custom rules + Managed rulesets (OWASP 3.2/3.1) | YAML-based security policies               | WAF rule builder + Managed rulesets          |
| **Rate limiting**   | Rate-based rules (5-minute window)     | Rate limiting per IP (custom)                   | Rate limiting per IP/Source                | Rate limiting rules + Advanced DDoS          |
| **Bot control**     | AWS WAF Bot Control (managed)          | Bot protection (Front Door/AFD premium)         | Google Cloud Armor Bot Management          | Bot Fight Mode + Super Bot Fight             |
| **IP reputation**   | AWS Managed Rules (anonymous IP, etc.) | Managed rules from threat intelligence          | Managed rules from threat intelligence     | Project Honey Pot, own intelligence          |
| **Custom response** | Block / Count + custom response code   | Deny / Redirect / Rate Limit                    | Deny / Redirect / Rate Limit               | Challenge / JS Challenge / Block             |
| **OWASP Top 10**    | AWS Managed Rules (core rule set)      | OWASP 3.2 / 3.1 managed rules                   | OWASP CRS preconfigured                    | OWASP CRS + Cloudflare Managed Rules         |
| **Pricing**         | $5/rule + $0.60/1M requests            | $20-200/month per Application Gateway           | $5-15/policy per month                     | Free tier available, Pro/Business/Enterprise |

### Azure WAF — Application Gateway

```json
// Azure Application Gateway WAF policy
{
  "name": "owasp-policy",
  "properties": {
    "policySettings": {
      "mode": "Prevention",
      "requestBodyCheck": true,
      "maxRequestBodySizeInKb": 128,
      "fileUploadLimitInMb": 100
    },
    "managedRules": {
      "managedRuleSets": [{ "ruleSetType": "OWASP", "ruleSetVersion": "3.2" }]
    }
  }
}
```

### GCP Cloud Armor — Adaptive Protection

```yaml
# GCP Cloud Armor security policy
name: cloud-armor-policy
rules:
  - action: deny(403)
    priority: 1
    match:
      versionedExpr: SRC_IPS_V1
      config:
        srcIpRanges: ["known-malicious-ips"]
    description: "Block known malicious IPs"
  - action: throttle
    priority: 2
    match:
      expr:
        expression: "request.path.matches('/api/login')"
    rateLimitOptions:
      enforceOnKey: IP
      rateLimitThreshold:
        count: 10
        intervalSec: 60
```

---

## Multi-Cloud IAM Models — AWS vs Azure vs GCP

### Perbandingan Identity Architecture

| Aspek                    | AWS IAM                                                            | Azure AD / Entra ID                                                                    | GCP IAM                                                                        |
| ------------------------ | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Permission model**     | JSON policy document (Effect, Action, Resource, Condition)         | Role-based (Owner, Contributor, Reader) + custom RBAC JSON                             | Primitive roles (Owner, Editor, Viewer) + predefined roles + custom roles      |
| **Identity types**       | IAM User (human), IAM Role (machine/assumed), Federated            | User, Service Principal, Managed Identity, Group                                       | User, Service Account (attached to resource), Group                            |
| **Policy attachment**    | Direct to user/role/resource + Permission Boundary + SCP           | Role assignment at scope (Management Group → Subscription → Resource Group → Resource) | Role binding at resource or project level                                      |
| **Condition engine**     | IAM condition keys (aws:SourceIp, aws:MFA, aws:PrincipalTag, etc.) | Azure ABAC (Attribute-Based Access Control) — conditions on role assignments           | IAM Conditions (expr attributes like timestamp, resource.name, origin)         |
| **Cross-account access** | STS:AssumeRole + ExternalId for 3rd party                          | B2B direct federation / Azure Lighthouse for cross-tenant management                   | Service account impersonation + Workload Identity Federation                   |
| **PIM/JIT**              | AWS IAM Identity Center (SSO) + permission sets                    | Azure PIM (Privileged Identity Management) — activation workflow with MFA + approval   | GCP Privileged Access Manager (PAM) — just-in-time, time-bound, approval-based |

### AWS IAM — Policy Document (Recap)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::corp-data/*",
      "Condition": {
        "IpAddress": { "aws:SourceIp": "10.0.0.0/8" }
      }
    }
  ]
}
```

### Azure RBAC — Role Definition

```json
{
  "Name": "Storage Blob Data Reader",
  "Id": "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1",
  "Actions": ["Microsoft.Storage/storageAccounts/blobServices/containers/read"],
  "NotActions": [],
  "DataActions": ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"],
  "AssignableScopes": ["/subscriptions/{subscription-id}"]
}
```

**Key difference:** Azure separates _management plane_ (Actions) from _data plane_ (DataActions) — unik vs AWS/GCP.

### GCP IAM — Role Binding

```yaml
# GCP IAM: grant role at resource level
bindings:
  - members:
      - user:azhar@urbansolv.co.id
    role: roles/editor # Primitive: broad
  - members:
      - serviceAccount:app-reader@project.iam.gserviceaccount.com
    role: roles/storage.objectViewer # Predefined: narrow
```

**Key difference:** GCP tidak punya policy document — role-role udah predefined oleh Google atau custom YAML. Condition ditambah via IAM Conditions expr.

### Privilege Escalation Vectors — Azure vs GCP

| Vector                             | AWS                                                                            | Azure                                                                               | GCP                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Role assignment attack**         | `iam:CreatePolicyVersion` → set admin policy version                           | `Microsoft.Authorization/roleAssignments/write` → assign Owner role ke diri sendiri | `resourcemanager.projects.setIamPolicy` → set policy yang grant diri sendiri owner |
| **Service Account takeover**       | `iam:PassRole` ke EC2/Lambda → launch resource dengan admin role → steal creds | Compromise VM dengan Managed Identity → IMDS endpoint → access token                | Compromise Compute Engine dengan attached SA → metadata server → token             |
| **Cross-account lateral movement** | `sts:AssumeRole` ke role di account produksi                                   | Lighthouse delegation → cross-tenant management (butuh approval)                    | Service Account Impersonation → `iam.serviceAccounts.getAccessToken`               |

### Cross-Cloud Hardening Checklist

```
✅ AWS:
☐ Enable CloudTrail / AWS Config / GuardDuty di ALL regions
☐ S3 Block Public Access — enabled di account level
☐ IAM: enforce MFA untuk ALL human users
☐ SCP: deny non-approved regions
☐ SCP: deny root user actions
☐ IAM Access Analyzer: review unused permissions tiap 90 hari
☐ Secrets Manager, tidak plaintext di code

✅ Azure:
☐ Enable Azure AD PIM untuk role admin
☐ Managed Identity untuk compute (bukan static credentials)
☐ Azure Policy: deny public blob / storage account
☐ Network Security Group: restrict 0.0.0.0/0 ingress
☐ Azure Defender for Cloud di semua subscription
☐ Key Vault dengan RBAC dan soft-delete enabled
☐ Conditional Access policy: MFA untuk semua admin

✅ GCP:
☐ Organization Policy: disable service account key creation
☐ Organization Policy: disable public bucket (storage.uniformBucketLevelAccess)
☐ VPC Service Controls: perimeter untuk data exfiltration prevention
☐ Security Command Center: semua project
☐ Cloud Audit Logs: admin activity + data access enabled
☐ IAM Recommender: review role binding tiap 90 hari
☐ Workload Identity Federation (bukan SA key file)
```

---

## Koneksi ke Vault

- [[cloud-infrastructure]] — arsitektur cloud umum yang sekarang diperdalam dengan posture management dan admission control
- [[container-kubernetes-security-deepdive]] — fondasi container security (seccomp, AppArmor, Falco) yang di admission policy
- [[cicd-shiftleft-shiftright]] — framework penempatan security scanning di pipeline CI/CD
- [[cicd-guide]] — implementasi konkret pipeline yang mengintegrasikan Checkov, tfsec, Snyk
- [[waf-reverse-proxy-deepdive]] — WAF di perimeter cloud (Cloudflare, AWS WAF, ModSecurity)
- [[api-security-deep-dive]] — API security yang menjadi attack surface utama cloud
- [[zero-trust-security]] — prinsip "never trust, always verify" di cloud dengan SPIFFE/SPIRE
- [[identity-and-access-management]] — fondasi IAM yang diperluas ke AWS IAM dan CIEM
- [[comprehensive-threat-directory]] — taksonomi ancaman yang mencakup cloud-specific threats
- [[threat-modeling-deepdive]] — metodologi untuk memodelkan ancaman cloud secara sistematis
- [[mass-assignment-broken-access-control-deepdive]] — Mass assignment & BAC (Broken Access Control)

---

## Referensi

1. AWS. _Shared Responsibility Model_. https://aws.amazon.com/compliance/shared-responsibility-model/
2. NIST. _SP 800-207: Zero Trust Architecture_. https://csrc.nist.gov/publications/detail/sp/800-207/final
3. CNCF. _Cloud Native Security Whitepaper_. https://github.com/cncf/tag-security/blob/main/security-whitepaper/CNCF_cloud_native_security_whitepaper.pdf
4. OPA Gatekeeper. _Gatekeeper Policy Library_. https://github.com/open-policy-agent/gatekeeper-library
5. Kyverno. _Kyverno Policies_. https://github.com/kyverno/policies
6. CIS. _CIS Kubernetes Benchmark v1.9_. https://www.cisecurity.org/benchmark/kubernetes/
7. Rhino Security Labs. _AWS IAM Privilege Escalation Methods_. https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/
8. AWS. _IAM Best Practices_. https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
9. AWS. _Security Best Practices for EKS_. https://docs.aws.amazon.com/eks/latest/best-practices/security.html
10. Prowler. _Open Source AWS/Azure/GCP Security_. https://github.com/prowler-cloud/prowler
11. Checkov. _IaC Security Scanning_. https://github.com/bridgecrewio/checkov
12. CloudSploit / Aqua Security. _CloudSploit_. https://github.com/aquasecurity/cloudsploit
13. SPIFFE/SPIRE. _SPIFFE Standard_. https://spiffe.io/
14. CrowdStrike. _Global Threat Report 2024: Cloud Security_. https://www.crowdstrike.com/global-threat-report/
15. Wiz. _Cloud Security Report 2024_. https://www.wiz.io/ebooks/state-of-cloud-security-2024
16. AWS. _AWS Well-Architected Framework – Security Pillar_. https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
17. Google Cloud. _Security Best Practices for GKE_. https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview
18. Microsoft. _Azure Security Benchmark v3_. https://learn.microsoft.com/en-us/security/benchmark/azure/
19. Stratus Red Team (Datadog). _Attack Technique Simulation_. https://stratus-red-team.cloud/
20. MITRE ATT&CK Cloud Matrix. _Cloud-Based Techniques_. https://attack.mitre.org/matrices/enterprise/cloud/

> [!tip] Bottom Line
> Keamanan cloud bukanlah tentang satu produk atau satu lapisan — ini tentang **posture berkelanjutan** (CSPM), **pencegahan di admission** (OPA/Kyverno), **kontrol identitas granular** (IAM/SCP), dan **deteksi anomaly** (CloudTrail + GuardDuty). Karena perimeter cloud adalah IAM policy, semua misconfiguration bisa menjadi bencana dalam hitungan jam. Kombinasi antara IaC scanning (pre-deploy), CSPM monitoring (post-deploy), dan admission control (di waktu deploy) adalah fondasi pertahanan yang tidak bisa ditawar. Implementasi SCP untuk membatasi privilege escalation — khususnya `iam:PassRole` dan cross-account trust — adalah langkah dengan ROI keamanan tertinggi.
