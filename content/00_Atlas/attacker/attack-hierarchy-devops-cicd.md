---
title: Attack Perspective — DevOps & CI/CD (Red Team Supply Chain Pipeline)
tags: [attack,red-team,devops,ci-cd,pipeline-poison,github-actions,gitlab-ci,jenkins]
source: hierarchy-devops-cicd.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# DevOps & CI/CD — Perspektif Penyerang (Pipeline Poison)

> CI/CD pipeline = supply chain choke point. Satu pipeline compromise → semua artifact terinfeksi → semua consumer terkena. Red team serang: runner compromise, token theft, pipeline injection, artifact tamper.

## 1. Attack Surface CI/CD

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **GitHub Actions** | Runner compromise, workflow inject, GITHUB_TOKEN theft | T1195.002 | Pull request → workflow trigger → secret exfil | Runner = ephemeral, no persistent monitoring | Secret audit log = delayed |
| **GitLab CI** | Runner registration abuse, variable leak, shared runner | T1195.002 | Runner hijack → job → secret access | Shared runner = multi-tenant | GitLab audit = delayed |
| **Jenkins** | Script console RCE, plugin vuln, credential store | T1195.002 | CVE-2024-23897 (path traversal), script console | Script console = admin feature | Jenkins audit = rare |
| **Docker Build** | Dockerfile RUN inject, buildkit cache poison | T1195.002 | Malicious base image, RUN backdoor | Build = ephemeral, no runtime scan | Image scan = post-build only |
| **Terraform** | State file theft → secrets, provider credential abuse | T1530 | S3 backend → state file → plaintext secrets | State = plaintext secret store | Terraform audit = rare |
| **Helm/K8s Deploy** | Chart injection, image tag hijack, secret leak | T1195.002 | Chart tamper → deploy malicious pod | Helm = package, not runtime | K8s audit = verbose noise |
| **Sonatype/Nexus** | Artifact repo compromise → artifact tamper | T1195.002 | Repo admin → swap artifact | Repo = trust store | Repo audit = rare |

## 2. CI/CD Attack Chain

```
Recon: Identifikasi CI/CD platform (GitHub Actions, GitLab CI, Jenkins)
 ↓
Initial Access:
 ├── Pull Request → trigger CI/CD workflow (if not restricted)
 ├── Compromised developer token → push → trigger pipeline
 ├── Fork → PR → workflow trigger → runner access
 └── Third-party Action dependency → supply chain (compromised action)
 ↓
Secret Theft:
 ├── GITHUB_TOKEN / GITLAB_TOKEN → repo access → push code
 ├── Cloud creds (AWS_ACCESS_KEY_ID, AZURE_CLIENT_ID) → cloud access
 ├── Signing key / GPG key → sign malicious artifact
 └── Package registry token → publish malicious package
 ↓
Artifact Poison:
 ├── Inject malicious code ke build step → artifact terinfeksi
 ├── Swap base image → backdoor semua layer
 ├── Modify package → backdoor consumer downstream
 └── Modify Terraform state → deploy malicious infra
 ↓
Persistence:
 ├── Cron action → periodic re-trigger
 ├── Backdoor Action → perpetual supply chain compromise
 └── Webhook → trigger on every push → persistent access
 ↓
Impact: Every downstream consumer = compromised (SolarWinds pattern)
```

## 3. CVE & Kasus CI/CD

| CVE / Kasus | Target | Impact | Teknik |
|-------------|--------|--------|--------|
| CVE-2024-23897 | Jenkins path traversal | RCE → credential store | `jenkins-cli` file read |
| CVE-2024-27198 | TeamCity pre-auth RCE | CI/CD full compromise → supply chain | Pre-auth → RCE → artifact poison |
| **Codecov (2021)** | CI bash uploader | Credential theft (npm tokens, API keys) | Modified bash uploader → exfil env vars |
| **CodeCov (2021)** | Code coverage tool | GitHub token theft | Docker image backdoor → exfil CI secrets |
| **SolarWinds** | Orion build pipeline | Global compromise | Build server → signed malicious DLL |

## 4. GitHub Actions Secret Exfil

```
Recon: Identifikasi repo dengan GitHub Actions workflow (.github/workflows/)
 ↓
Trigger: Create pull request or issue → trigger workflow (pull_request_target)
 ↓
Exfil:
 ├── Action step → print env → secret in log (then delete PR to hide)
 ├── Action step → curl env vars → attacker server
 └── Modified Action (fork) → trigger pull_request_target → access secret
 ↓
Persistence: Create scheduled workflow (cron) → periodic re-trigger
 ↓
Evasion: Delete PR after exfil → no visible trace (if admin not fast enough)
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Gitleaks / TruffleHog** | Secret scan (credential in workflow file, repo) |
| **Semgrep** | Static analysis → CI/CD misconfiguration |
| **Actionlint** | GitHub Actions workflow linter |
| **terraform-plan** | Terraform state secret extraction |
| **Custom workflow payload** | GitHub Action → env dump → exfil |

## 6. Referensi
- GitHub Actions Security — https://docs.github.com/en/actions/security-guides
- Jenkins CVE-2024-23897 — https://www.jenkins.io/security/advisory/2024-01-24/
- TeamCity CVE-2024-27198 — https://nvd.nist.gov/vuln/detail/CVE-2024-27198
- CI/CD Attack Framework (Legit Security) — https://www.legitsecurity.com/
- SLSA Framework — https://slsa.dev/