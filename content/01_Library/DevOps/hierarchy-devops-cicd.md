
cssclasses:
  - wide-table
  - callout

## Deepdive — DevOps CI/CD Attack Surface

### Pipeline Attack Vector

| Stage | Vektor | Tool | Evasion |
|-------|--------|------|---------|
| **Source** | Malicious commit, PR | GitHub PR | Signed commit (stolen token) |
| **Build** | Runner compromise, secret env leak | Action inject | Ephemeral runner = no trace |
| **Artifact** | Swap, tag hijack | Registry admin | Repo = trust store |
| **Deploy** | Config tamper, infra drift | Terraform state | State = plaintext secret |
| **Runtime** | Supply chain artifact | Deployed artifact | Image scan = post-deploy |

### CI/CD Kill Chain

```
Recon: .github/workflows/ atau .gitlab-ci.yml → identify job, trigger
    ↓
Access: Stolen developer token → push → trigger workflow
    ↓
Secret: env dump → cloud creds, signing key, registry token
    ↓
Poison: Inject code ke build → artifact infected → all downstream
    ↓
Persist: Backdoor Action / cron trigger → perpetual compromise
```

## Referensi
- SLSA — https://slsa.dev/
- GitHub Actions Security — https://docs.github.com/en/actions/security-guides

## DevOps & CI/CD — Arsitektur Pipeline Modern

### Pipeline Komponen

| Stage | Tool | Fungsi | Attack Surface |
|-------|------|--------|---------------|
| **Source** | GitHub, GitLab, Bitbucket | Version control | Malicious PR, token theft |
| **Build** | Make, Gradle, npm, pip | Compile/package | Runner compromise |
| **Test** | pytest, jest, cypress | Automated test | Test code injection |
| **Scan** | Snyk, Trivy, SonarQube | Vulnerability scan | Tool bypass |
| **Artifact** | Nexus, Artifactory, Docker Hub | Repository | Supply chain swap |
| **Deploy** | Kubernetes, ECS, Lambda | Rollout | Config tamper, drift |
| **Monitor** | Prometheus, Datadog | Runtime observability | Alert fatigue |

### CI/CD Attack Chain (Supply Chain)

```
Initial Access:
  ├── Phishing developer → steal GitHub token
  ├── Compromised Action dependency (3rd party)
  ├── Fork → PR → trigger workflow (if untrusted input)
  └→ Vulnerable CI tool (e.g., Jenkins CVE-2024-23897)
    ↓
Secret Theft:
  ├── GITHUB_TOKEN → repo access → push code
  ├── AWS_ACCESS_KEY_ID → cloud lateral
  ├── Signing cert → sign malicious artifact
  └→ Registry token → publish malicious package
    ↓
Artifact Poison (SolarWinds pattern):
  ├── Inject code ke build → artifact infected
  ├── Swap base image → backdoor all layer
  ├── Modify package → backdoor downstream
  └→ Terraform state → malicious infra deploy
    ↓
Persist:
  ├── Cron action → periodic re-trigger
  ├── Backdoor commit → dormant in codebase
  └→ Webhook → trigger on every push
```

### GitHub Actions Security Checklist

| Risk | Mitigation |
|------|-----------|
| `pull_request_target` uses secrets | Avoid → use separate workflow for trusted only |
| Runner has persistent network access | Use ephemeral runner, network isolation |
| Secret stored as env var | Use OIDC federation, no long-lived key |
| 3rd-party Action | Pin to commit SHA (not tag) |
| `GITHUB_TOKEN` leak in log | Mask output, secret scanning |
| Artifact tamper | Sign (cosign), provenance (SLSA) |

### SLSA (Supply-chain Levels for Software Artifacts)

| Level | Requirement |
|-------|-----------|
| **L1** | Build script documented |
| **L2** | Tamper-resistant build service |
| **L3** | Isolated build, provenance verified |
| **L4** | Reproducible build, hermetic |

## Referensi
- SLSA — https://slsa.dev/
- GitHub Actions Security — https://docs.github.com/en/actions/security-guides
- Jenkins CVE-2024-23897 — https://www.jenkins.io/security/advisory/2024-01-24/
- Cosign — https://github.com/sigstore/cosign

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

## Konsep Dasar — Pipeline Modern & Orchestration

### Build System Internal

| Tool | Language | Build File | Artifact |
|------|----------|-----------|----------|
| **Make** | C/C++ | Makefile | Binary |
| **Gradle** | Java/Kotlin | build.gradle | JAR/WAR |
| **npm** | JavaScript | package.json | node_modules |
| **pip/poetry** | Python | pyproject.toml | wheel |
| **cargo** | Rust | Cargo.toml | binary/crate |
| **go build** | Go | go.mod | binary |
| **Docker** | Multi-lang | Dockerfile | Image |

### Deployment Strategy

| Strategy | Mekanisme | Rollback | Risk |
|----------|-----------|----------|------|
| **Rolling** | Ganti pod/instance satu per satu | Slow | Low |
| **Blue-Green** | 2 env (blue/green) → switch traffic | Instant | Medium |
| **Canary** | Small % traffic dulu → monitor → scale | Fast | Low |
| **A/B Test** | Route subset → compare | Fast | Medium |
| **Recreate** | Kill all → deploy new | Slow | High |

### Pipeline Observability

Pipeline harus dapat di-inspeksi: log (structured), metrics (duration/fail rate), trace (step dependency). Tool: Jaeger, OpenTelemetry, Datadog CI Visibility.

### Maturity Model DevOps

| Level | Stage | Security Integration |
|-------|-------|---------------------|
| **L0** | Manual | Pentest before deploy |
| **L1** | CI | SAST in pipeline |
| **L2** | CD | Auto-deploy + vulnerability scan |
| **L3** | DevSecOps | Shift-left, SBOM, signing, provenance |
| **L4** | Continuous Security | Runtime monitoring + feedback loop |

## Referensi Tambahan
- DORA Metrics — https://cloud.google.com/blog/products/devops-sre/
- ArgoCD — https://argo-cd.readthedocs.io/
- OpenTelemetry — https://opentelemetry.io/
