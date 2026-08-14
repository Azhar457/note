
## Deepdive — Infrastructure Evolution (Bare Metal → Cloud → Edge)

### Timeline Evolusi

| Era | Model | Security Challenge |
|-----|-------|-------------------|
| **1980s** | Mainframe | Physical access, terminal |
| **1990s** | Client-server | Network perimeter, firewall |
| **2000s** | Virtualization | VM escape, multi-tenant |
| **2010s** | Cloud (IaaS/PaaS/SaaS) | Shared responsibility, IAM |
| **2020s** | Edge / Serverless | Cold start, ephemeral, data locality |
| **Now** | AI Infrastructure | GPU poisoning, model theft, prompt injection |

### Red Team per Era

```
Cloud (now): IAM → privesc → cross-account → data exfil
  ├── IMDS SSRF → instance creds → cloud lateral
  ├── S3 public → data leak
  ├── Lambda over-permissive → privesc
  └→ Container escape → host → cluster
    ↓
Edge (emerging):
  ├── CDN cache poison → stored XSS
  ├── Edge function (Cloudflare Worker) → code injection
  └→ Data sovereignty → cross-border data flow
```

## Referensi
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- NIST Cloud — https://www.nist.gov/itl/cloud

## Evolusi Arsitektur — Dari Bare Metal ke AI Infrastructure

### Timeline Evolusi Infrastruktur

| Era | Model | Komponen Utama | Security Challenge |
|-----|-------|---------------|-------------------|
| **1960s-80s** | Mainframe | Terminal, RJE | Physical access, no encryption |
| **1990s** | Client-Server | LAN, Ethernet | Network perimeter, firewall |
| **2000s** | Virtualization | VM, Hypervisor | VM escape, multi-tenant isolation |
| **2010s** | Cloud (IaaS/PaaS/SaaS) | EC2, S3, Lambda | Shared responsibility, IAM, API |
| **2020s** | Edge / Serverless | CDN Workers, IoT | Cold start, ephemeral, data locality |
| **Now** | AI Infrastructure | GPU cluster, model registry | Model poisoning, prompt injection |

### Cloud Shared Responsibility Model

```
On-Prem:    YOU = Everything (hardware → app to data)
IaaS:       YOU = OS + app + data | CLOUD = hardware + virtualization
PaaS:       YOU = app + data | CLOUD = OS + runtime + infra
SaaS:       YOU = data + access | CLOUD = everything else
    ↓
Red Team: Where is YOUR boundary? → Attack there.
  ├── IaaS: OS exploit, metadata service (IMDS)
  ├── PaaS: App layer (SSTI, deserialization), API abuse
  └→ SaaS: OAuth/SSO, misconfig (public bucket, default creds)
```

### Edge Computing Security

| Komponen | Challenge |
|----------|-----------|
| **CDN Workers (Cloudflare/Vercel)** | Code injection, data at edge, cold start |
| **IoT Edge** | Physical access, firmware, no patching |
| **5G Edge** | Network slice, roaming, subscriber data |
| **Data Sovereignty** | Cross-border data flow (GDPR, PDPA) |

### Infrastructure as Code (Terraform)

```hcl
cssclasses:
  - wide-table
  - callout

# Terraform state = plaintext secret (AWS key, DB password)
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-12345"
  instance_type = "t3.micro"
  tags = { Name = "web-${count.index}" }
}

# Attack: compromise state file → extract secrets → cloud lateral
# Defense: state encryption (S3 + KMS), state locking (DynamoDB), remote backend
```

### Cloud IAM Privilege Escalation Matrix (AWS)

| Permission | Escalation Path |
|------------|----------------|
| `iam:PassRole` + `ec2:RunInstances` | Pass admin role → EC2 → access |
| `iam:CreateAccessKey` | Create key for admin user → persist |
| `sts:AssumeRole` | Assume privileged role → escalate |
| `lambda:CreateFunction` + `iam:PassRole` | Lambda with admin role → RCE |
| `s3:PutBucketPolicy` | Make bucket public → data exfil |

## Referensi
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- NIST Cloud — https://www.nist.gov/itl/cloud
- Terraform Security — https://developer.hashicorp.com/terraform/tutorials/security
- AWS IAM Escalation — https://github.com/RhinoSecurityLabs/aws-iam-privesc

## Koneksi ke Vault & Cross-Reference

| Catatan | Hubungan |
|---------|----------|
| Zero Trust | Network segment untuk infra |
| Supply Chain | Pipeline security overlap |
| Cloud IAM | Privilege escalation path |
| Endpoint Security | Runner compromise path |

## Best Practices & Pitfall

1. **GitOps**: Infrastructure config (manifest) ada di Git — versioned, reviewed, auditable. Tetapi Git token = attack surface → rotate, scoped.
2. **Immutable Artifact**: Setiap build = image/untouched hash. Signature verification di deploy. Realitas: banyak still manual deploy.
3. **Least Privilege CI**: Runner token punya scope minimal — bukan global admin. Realitas: `repo:*` scope masih common di setup.
4. **Network Isolation**: Runner segment terpisah production → securitas blance. Tetapi: many org simplify by same VPC → risk.
5. **Audit Log**: Semua CI/CD action di-log dan immutable. Realitas: log retention pendek, alerting belum sentral.
6. **Provenance (SLSA)**: Setiap artifact terlampir provenance (build manifest + source hash). Realitas: adopsi masih rendah di 2025.

## Pitfall Nyata yang Sering Ditemui

- **Leaked token di git history**: git log → credential exposure → scanner attacker → compromise. Fix: BFG repo-cleaner + token rotation.
- **Runner has persistent secrets**: Runner VM menyimpan `~/.aws/credentials` atau `.docker/config.json` → next user can access. Fix: ephemeral runner, no persistent state.
- **Default branch is `main`**: CI jalan di `main`. PR branch dapat trigger → secret exposed. Fix: `pull_request_target` only trusted contributors.
- **Trusted Action pins tag not SHA**: Tag `actions/checkout@v4` → bisa di-hijack jika maintainer compromised. Fix: pin SHA.
- **No SBOM**: Artifact jadi → no manifest → maka after compromised, tidak tahu apa yang affected. Fix: `syft` generate SBOM pada build.

## Tool Stack Lengkap

| Tool | Stage | Use |
|------|-------|-----|
| **GitHub Actions / GitLab CI** | Build | Pipeline |
| **ArgoCD / Flux** | Deploy | GitOps continuous delivery |
| **Trivy / Grype** | Scan | Image + dep vuln scan |
| **Syft** | Scan | SBOM generation |
| **Cosign / Sigstore** | Sign | Artifact signing |
| **Open Policy Agent (OPA)** | Enforce | Policy as code |
| **HashiCorp Vault** | Secret | Secret management |
| **Prometheus + Grafana** | Monitor | Metrics + dashboard |

## Konsep Dasar — Virtualisasi & Container

### Virtual Machine vs Container

| Aspek | VM | Container |
|-------|-----|-----------|
| **Isolation** | Full OS (hypervisor) | Shared kernel (namespace + cgroup) |
| **Boot time** | Menit | Detik |
| **Overhead** | Heavy (guest OS) | Light (shared kernel) |
| **Density** | Low (5-10 per host) | High (100+ per host) |
| **Security** | Strong isolation | Weaker (kernel shared) |

### Container Escape Path (Red Team)

```
Container attack surface:
  ├── Kernel exploit (CVE) → namespace escape → host
  ├── Privileged container → host access
  ├── Capabililty abuse (CAP_SYS_ADMIN) → mount host
  ├── cgroup escape → host process
  ├── runc CVE-2024-21626 → host file fd leak → escape
  └→ kubelet exploit → node compromise → cluster
    ↓
Post-escape: host shell → pivot ke cluster → semua pod
```

### Kubernetes Attack Surface

| Komponen | Vektor | Impact |
|----------|--------|--------|
| **API Server** | Exposed port 6443 → unauth access | Cluster takeover |
| **kubelet** | Exposed 10250 → RCE | Node compromise |
| **RBAC** | Over-permissive → privesc | Lateral to cluster |
| **etcd** | Unauth → read all secrets | Full cluster dump |
| **Service Account** | Token theft → API access | Pod → cluster |
| **Admission Controller** | Bypass → deploy malicious pod | RCE in cluster |

## Referensi Tambahan
- Container Security — https://containerd.io/docs/security/
- Kubernetes Hardening Guide — https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/0/KUBERNETES_HARDENING_GUIDANCE.PDF
- runc CVE-2024-21626 — https://nvd.nist.gov/vuln/detail/CVE-2024-21626
