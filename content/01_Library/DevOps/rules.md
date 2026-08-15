---
title: DevOps Rules
tags: [devops, ci-cd, rules]
aliases: [devops-rules]
---
# DevOps Rules — Aturan Pipeline & Operasional

Kumpulan aturan DevOps: CI/CD hygiene, environment management, observability, dan keamanan pipeline. Berlaku untuk semua project yang dikelola tim.

## Aturan CI/CD

1. **Build sekali, deploy banyak** — satu artifact (immutable) untuk semua environment; jangan rebuild per env (drift, supply chain).
2. **Tag & versioning** — semantic version (`1.2.3`), tag git + image sama; jangan `latest` untuk produksi.
3. **Pipeline gate** — test (unit → integration → E2E) + SAST + SCA + image scan sebelum deploy; fail on critical.
4. **Environment parity** — staging = produksi (config beda, kode sama); hindari "works on my machine".
5. **Artifact registry** — push ke registry terpusat (GHCR, ECR, Artifactory); retensi & immutability tag.
6. **Rollback plan** — setiap deploy punya rollback (previous image, feature flag); automasi.
7. **Secrets di pipeline** — via secret manager / env dari CI platform (bukan hardcode di YAML).
8. **Logs & metrics** — setiap stage logging structured; pipeline duration & failure rate dipantau.

## Proses Rilis

### Trunk-based / GitFlow
- **Trunk-based**: branch utama + short-lived feature branch; PR kecil ( < 400 baris); CI tiap PR; release dari main. Cocok untuk deploy cepat.
- **GitFlow**: develop + feature + release branch; cocok untuk rilis terjadwal. Keputusan: konsisten, satu tim satu model.

### Deployment Strategy
| Strategy | Downtime | Risiko | Use Case |
|----------|----------|--------|----------|
| Recreate | Ya | Tinggi | Non-production |
| Rolling | Minimal | Rendah | Default |
| Blue-green | Tanpa | Rendah | Kritis (switch cepat) |
| Canary | Tanpa | Render | Progressive (1% → 10% → 100%) |
| Feature flag | Tanpa | Render | Fitur eksperimen |

## Environment & Config

1. **Config as Code** — helm/Kustomize/Terraform untuk infra; values per env di repo (bukan rahasia).
2. **Twelve-factor app** — config via env var (bukan hardcode); stateless; log ke stdout.
3. **Secret handling** — lihat [[sealed-secrets-vs-vault]]: tidak ada secret di repo; secret manager/injector.
4. **Backward compatibility** — API versioning; migration DB backward-compatible (expand/contract).
5. **Immutable infrastructure** — jangan SSH ke server untuk fix manual (drift → rebuild dari IaC).

## Observability & SRE

- Metric: RED (Rate, Errors, Duration) per service; USE (Utilization, Saturation, Errors) per resource.
- Log: structured JSON; correlation ID (`X-Request-Id`) lintas service.
- Trace: distributed tracing (OpenTelemetry) untuk request path.
- Alert: actionable, berdasarkan SLO (lihat [[sre-practices-and-slo]]), bukan threshold statis.
- Dashboard: SLI view per service; error budget burn rate.

## Keamanan dalam DevOps (DevSecOps)

1. **Shift-left**: SAST (Semgrep/CodeQL), secret scan (gitleaks), dependency scan (pip-audit/osv) di PR — jangan tunggu produksi.
2. **SCA**: lockfile + audit di CI; renovate/dependabot auto-PR untuk update.
3. **Image security**: multi-stage, non-root, scan (Trivy), sign (cosign) — lihat [[create-dockerfile]] & [[cosign-pipeline]].
4. **IaC scanning**: tfsec/checkov untuk Terraform; kubeconform + policy (Kyverno) untuk manifest.
5. **Supply chain**: SBOM + provenance; registry allowlist; verifikasi signature sebelum deploy.
6. **Access**: lingkungan CI minimal (least privilege); runner self-hosted diproteksi; rotate tokens.
7. **Incident pipeline**: pipeline failure = incident; on-call rotation; postmortem.

## GitOps (Jika Dipakai)

- ArgoCD/Flux: state di git = source of truth; sync otomatis/manual dengan approval.
- Drift detection: ArgoCD `out-of-sync` — jangan abaikan.
- Secret: SealedSecret/ESO (lihat di atas) — jangan plaintext di repo.
- Policy: manifest divalidasi policy engine (Kyverno/OPA) sebelum sync.

## Checklist Audit Pipeline

- [ ] Artifact immutable + versioned + signed?
- [ ] Test & scan di pipeline (unit, SAST, SCA, image)?
- [ ] Tidak ada secret di repo/pipeline YAML?
- [ ] Deploy strategy jelas (canary/blue-green utk kritis)?
- [ ] Rollback teruji (dokumentasi + drill)?
- [ ] Observability: metrics/log/trace + alert actionable?
- [ ] Environment parity (staging = prod config)?
- [ ] GitOps sync dimonitor (no drift)?

## Aturan Tim (Non-Teknis)

- Semua perubahan lewat PR + review (2 reviewer untuk infra).
- No direct push ke main/branch utama (branch protection).
- Change management: deploy window + komunikasi (status page) untuk breaking change.
- Dokumentasi runbook untuk semua operasi manual yang tersisa.



## Contoh Pipeline YAML (CI/CD dengan Gate)

```yaml
# .gitlab-ci.yml (ringkas)
stages: [test, scan, build, deploy]

unit-test:
  stage: test
  script: npm run test:ci

sast:
  stage: scan
  script: semgrep --config auto .

sca:
  stage: scan
  script: pip-audit / npm audit --audit-level=high

build:
  stage: build
  script:
    - podman build -t $IMAGE_TAG .
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE_TAG

deploy-staging:
  stage: deploy
  environment: staging
  script: ./deploy.sh staging

deploy-prod:
  stage: deploy
  environment: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  script: ./deploy.sh prod --canary
```

## Runbook: Pipeline Gagal (Incident Quick Guide)

1. Buka pipeline log stage yang gagal (jangan scroll semua).
2. Klasifikasi: test failure (kode) vs infra failure (runner, registry) vs flaky.
3. Test failure → assign ke pemilik perubahan (author); rollback jika production impacted.
4. Infra failure → cek runner health, registry reachability, quota.
5. Flaky test → quarantine test (skip sementara) + ticket fix, jangan biarkan blocking terus.
6. Postmortem jika berdampak produksi: timeline, root cause, action items.

## Change Management & Approval

- Staging: auto-deploy dari merge ke develop.
- Production: approval manual (2 person) + deploy window (mis. Selasa-Kamis 10:00-14:00 WIB).
- Emergency hotfix: jalur khusus (label hotfix) + postmortem wajib.
- Semua deploy tercatat: siapa, kapan, apa, hasil (audit trail).

---

  audited
---