---
title: Attack Perspective — DevOps/CI/CD (Red Team Pipeline)
tags: [attack,red-team,devops,ci-cd,github-actions,jenkins,artifact,supply-chain]
source: devops-cicd-security.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# DevOps/CI/CD — Perspektif Penyerang (Pipeline Poison)

> CI/CD = supply chain choke point. Satu pipeline compromise → semua artifact terinfeksi → semua consumer kena. Red team: runner compromise, token theft, pipeline injection, artifact tamper.

## 1. Attack Surface CI/CD

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **GitHub Actions** | Runner compromise, GITHUB_TOKEN theft, workflow inject | T1195.002 | PR trigger, action dependency | Runner = ephemeral | Secret audit = delayed |
| **GitLab CI** | Runner hijack, variable leak | T1195.002 | Shared runner abuse | Multi-tenant = legit | GitLab audit = delayed |
| **Jenkins** | Script console RCE, plugin vuln | T1195.002 | CVE-2024-23897 path traversal | Script console = admin | Jenkins audit = rare |
| **Artifact Repo** | Artifact swap, tag hijack | T1195.002 | Nexus/Artifactory admin | Repo = trust store | Repo audit = rare |
| **Terraform** | State file theft → secrets | T1530 | S3 backend plaintext | State = plaintext | Terraform audit = rare |
| **Container Registry** | Malicious image, tag confusion | T1195.002 | Docker Hub spoof | Image = valid tag | Image scan = post-deploy |
| **Secrets Store** | Vault/Secret Manager compromise | T1552 | API token theft | Secret = legit access | Vault audit = rare |

## 2. CI/CD Attack Chain

```
Recon: CI/CD platform → repo → workflow → runner
    ↓
Initial Access:
  ├── Pull Request → trigger workflow (if untrusted)
  ├── Fork → PR → workflow trigger → runner access
  ├── Stolen developer token → push → trigger
  └→ Compromised Action dependency → supply chain
    ↓
Secret Theft:
  ├── GITHUB_TOKEN → repo access → push code
  ├── Cloud creds (AWS_ACCESS_KEY_ID) → cloud access
  ├── Signing key → sign malicious artifact
  └→ Registry token → publish malicious package
    ↓
Artifact Poison:
  ├── Inject code ke build → artifact infected
  ├── Swap base image → backdoor all layer
  ├── Modify package → backdoor downstream
  └→ Terraform state → malicious infra
    ↓
Persistence:
  ├── Cron action → periodic re-trigger
  ├── Backdoor Action → perpetual compromise
  └→ Webhook → trigger on every push
    ↓
Impact: SolarWinds pattern — semua downstream = compromised
```

## 3. GitHub Actions Secret Exfil

```
Recon: .github/workflows/*.yml → job, env, secret usage
    ↓
Trigger: Pull request (pull_request_target) → workflow runs
    ↓
Exfil:
  ├── Step: printenv → env (secrets) → log (delete PR after)
  ├── Step: curl $SECRET → attacker server
  └→ Modified action (fork) → access secrets
    ↓
Evasion: Delete PR → no trace (if admin not fast)
```

## 4. CVE & Kasus

| Kasus | Impact | Teknik |
|-------|--------|--------|
| CVE-2024-23897 (Jenkins) | RCE → credential store | CLI path traversal |
| CVE-2024-27198 (TeamCity) | Pre-auth RCE → full CI/CD | Artifact poison |
| Codecov 2021 | CI credential theft | Modified bash uploader |
| SolarWinds | Global supply chain | Build server compromise |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Gitleaks / TruffleHog** | Secret scan (workflow file) |
| **Semgrep** | CI/CD misconfig analysis |
| **actionlint** | GitHub Actions linter |
| **terraform-plan** | State secret extraction |
| **Custom workflow** | Secret env dump payload |

## 6. Referensi
- GitHub Actions Security — https://docs.github.com/en/actions/security-guides
- Jenkins CVE-2024-23897 — https://www.jenkins.io/security/advisory/2024-01-24/
- SLSA — https://slsa.dev/
- CI/CD Framework — https://www.legitsecurity.com/