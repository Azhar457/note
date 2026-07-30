---
title: CI/CD Pipeline Implementation — GitHub Actions & GitLab CI
tags:
  - devops
  - cicd
  - github-actions
  - gitlab-ci
  - automation
  - pipeline
  - library
aliases:
  - GitHub Actions CI/CD
  - GitLab CI Pipeline
  - CI/CD YAML Examples
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# 🔄 CI/CD Pipeline Implementation — GitHub Actions & GitLab CI

> Panduan implementasi CI/CD pipeline yang beneran kerja — dari zero ke production. Bukan teori konseptual (udah ada [[cicd-guide]] dan [[cicd-shiftleft-shiftright]]), tapi konkret: YAML workflow GitHub Actions, GitLab CI, deployment strategies, artifact management, secret handling, dan troubleshooting. Setiap workflow di sini sudah production-tested di project [REDACTED].

## Daftar Isi

1. [[#1. Core Concepts — Workflow Anatomy]]
2. [[#2. GitHub Actions — Starter Workflows]]
3. [[#3. Build & Test Pipeline — Node.js]]
4. [[#4. Docker Build & Push Pipeline]]
5. [[#5. Deployment Pipeline — SSH + PM2]]
6. [[#6. Deployment Pipeline — SSH + Podman]]
7. [[#7. GitLab CI — Mirror Setup]]
8. [[#8. Secret Management — Best Practices]]
9. [[#9. Pipeline Security — SAST, Dependency Scan, OIDC]]
10. [[#10. Troubleshooting]]
11. [[#11. Matrix Build Strategy untuk Monorepo]]
12. [[#12. GitHub-Hosted vs Self-Hosted Runner — Perbandingan Lengkap]]
13. [[#13. Artifact Retention Policies]]
14. [[#14. Environment Protection Rules]]
15. [[#15. Workflow Commands — GITHUB_OUTPUT, GITHUB_ENV, GITHUB_STEP_SUMMARY]]
16. [[#16. Composite Actions vs Reusable Workflows]]
17. [[#17. Debugging Pipeline]]
18. [[#18. Cost Optimization — GitHub Actions]]
19. [[#19. Common Pitfall — YAML Indentation]]
20. [[#20. Koneksi ke Vault]]

---

## 1. Core Concepts — Workflow Anatomy

Setiap pipeline CI/CD punya komponen yang sama:

```
Event Trigger → Job(s) → Steps → Actions/Scripts → Artifacts/Deploy
```

### GitHub Actions Structure

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on: # 🔫 TRIGGER
  push:
    branches: [main]
  pull_request:
    branches: [staging]
  workflow_dispatch: # manual trigger
    inputs:
      environment:
        type: choice
        options: [staging, production]

concurrency: # cegah race condition
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions: # 🔐 least privilege
  contents: read
  packages: write

env: # environment variables
  NODE_VERSION: 22
  REGISTRY: ghcr.io

jobs:
  build: # 🏗️ JOB 1: Build
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.tag.outputs.tag }}
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: npm ci && npm run build
      - name: Set tag
        id: tag
        run: echo "tag=$(date +%s)" >> $GITHUB_OUTPUT

  deploy: # 🚀 JOB 2: Deploy (menunggu build)
    needs: build
    runs-on: self-hosted
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: ./deploy.sh
```

---

## 2. GitHub Actions — Starter Workflows

### Trigger Events

```yaml
on:
  push: # Setiap push
    branches: [main, staging]
    paths-ignore: ["*.md", "docs/**"] # skip kalo cuma dokumentasi
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule: # Cron
    - cron: "0 6 * * 1" # Every Monday 6 AM
  workflow_call: # Reusable workflow
  workflow_dispatch: # Manual
    inputs:
      dry_run:
        description: "Deploy dry run"
        type: boolean
        default: false
```

### Runners

| Runner           | Use Case                           | Cost                  |
| ---------------- | ---------------------------------- | --------------------- |
| `ubuntu-latest`  | Build, test, lint                  | Free (2000 min/month) |
| `windows-latest` | .NET, Win app                      | Free quota            |
| `macos-latest`   | iOS, macOS app                     | Terbatas              |
| `self-hosted`    | GPU, internal network, large cache | Infra sendiri         |

### Reusable Workflow

```yaml
# .github/workflows/build-node.yml (reusable)
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
    secrets:
      NPM_TOKEN:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: "npm"
      - run: npm ci
      - run: npm run build

# ---------- Panggil dari workflow lain ----------
jobs:
  build-api:
    uses: ./.github/workflows/build-node.yml
    with:
      node-version: "22"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

## 3. Build & Test Pipeline — Node.js

Workflow production untuk NestJS/Node.js:

```yaml
name: Node.js CI

on:
  push:
    branches: [main, staging]
    paths-ignore: ["*.md"]
  pull_request:
    branches: [main]

permissions:
  contents: read
  checks: write
  pull-requests: write

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: "npm"
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        node-version: [18, 20, 22]
    services: # 🐳 spin up service container
      postgres:
        image: postgres:17-alpine
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"
      - run: npm ci
      - run: npx prisma generate
      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/test
          REDIS_URL: redis://localhost:6379
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-report-${{ matrix.node-version }}
          path: junit.xml
          retention-days: 7
```

---

## 4. Docker Build & Push Pipeline

Containerize + push ke registry:

```yaml
name: Build and Push Container

on:
  push:
    branches: [main]
    tags: ["v*"]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest,enable=${{ github.ref == format('refs/heads/{0}', 'main') }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Sign image (cosign)
        uses: sigstore/cosign-installer@v3
      - run: |
          cosign sign --key env://COSIGN_PRIVATE_KEY ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build-and-push.outputs.digest }}
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_KEY }}
```

---

## 5. Deployment Pipeline — SSH + PM2

Deploy ke VPS via rsync (pattern dari [REDACTED]):

```yaml
name: Deploy via Rsync

on:
  push:
    branches: [main]

env:
  DEPLOY_PATH: /home/dev/backend/myproject
  DEPLOY_HOST: ${{ secrets.VPS1_HOST }}
  DEPLOY_USER: ${{ secrets.VPS1_USER }}
  PM2_NAME: "3010-myapp"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: "npm"
      - run: npm ci
      - run: npx prisma generate
        env:
          DATABASE_URL: postgresql://dummy:dummy@localhost:5432/dummy
      - run: npm run build
      - run: rm -rf node_modules && npm ci --production
      - run: tar -czf deploy.tar.gz dist node_modules package.json prisma
      - uses: actions/upload-artifact@v4
        with:
          name: deploy-artifact
          path: deploy.tar.gz

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: deploy-artifact
      - name: Copy & restart via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ env.DEPLOY_HOST }}
          username: ${{ env.DEPLOY_USER }}
          key: ${{ secrets.VPS1_SSH_KEY }}
          script: |
            mkdir -p ${{ env.DEPLOY_PATH }}
            cd ${{ env.DEPLOY_PATH }}
            tar -xzf /tmp/deploy.tar.gz -C ${{ env.DEPLOY_PATH }}
            # Atau lewat rsync dari artifacts yang di-copy
            npx prisma generate
            pm2 restart ${{ env.PM2_NAME }} --update-env
```

### Pattern Aman — rsync --exclude

```bash
rsync -avz --delete   --exclude='/.env*'   --exclude='/node_modules'   --exclude='/.git'   --exclude='/uploads'   -e "ssh -i deploy_key"   ./dist/ user@host:$DEPLOY_PATH/dist/
```

> [!danger] Jangan pake `${{ secrets.DEPLOY_PATH }}` yang shared antar repo! Hardcode path per project. Lihat [[cicd-guide]] untuk detail incident rsync --delete.

---

## 6. Deployment Pipeline — SSH + Podman

Container-native deploy:

```yaml
name: Deploy Container

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE: ghcr.io/[REDACTED]/myapp

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: SSH Deploy
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS1_HOST }}
          username: ${{ secrets.VPS1_USER }}
          key: ${{ secrets.VPS1_SSH_KEY }}
          script: |
            # Pull latest image
            podman pull ${{ env.IMAGE }}:latest

            # Stop & remove old container
            podman stop myapp 2>/dev/null || true
            podman rm myapp 2>/dev/null || true

            # Run new container
            podman run -d --name myapp             --restart=always             -p 3010:3000             --env-file /home/dev/.env/myapp.env             ${{ env.IMAGE }}:latest

            # Health check
            sleep 3
            curl -sf http://localhost:3010/health && echo "✅ Healthy" || echo "❌ Failed"
```

---

## 7. GitLab CI — Mirror Setup

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  NODE_VERSION: "22"
  DOCKER_DRIVER: overlay2

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/

lint:
  stage: test
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm run lint
  except:
    - main

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  only:
    - main

deploy:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
  script:
    - scp ./docker-compose.yml deploy@host:/opt/myapp/
    - ssh deploy@host "cd /opt/myapp && docker compose pull && docker compose up -d"
  only:
    - main
  environment:
    name: production
```

---

## 8. Secret Management — Best Practices

### GitHub Secrets — Pitfall SSH Key

```bash
# ✅ BENAR — pakai stdin
gh secret set SSH_KEY -R Org/repo < /tmp/ci_key

# ❌ SALAH — -b strips newlines, corrupt key!
gh secret set -b"$(cat /tmp/ci_key)" -R Org/repo
# Error: "error in libcrypto" karena newlines ilang
```

### Environment-Level Secrets

```yaml
# Environment-specific: production approval gate
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.mycompany.com
    steps:
      - name: Deploy
        env:
          PROD_KEY: ${{ secrets.PROD_API_KEY }}
        run: ./deploy.sh
```

### OIDC — Credential-less Cloud Auth

```yaml
# Ganti akses key dengan OIDC ke AWS
jobs:
  deploy-aws:
    permissions:
      id-token: write # needed for OIDC
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
          aws-region: ap-southeast-1
      - name: Deploy to ECS
        run: aws ecs update-service --cluster prod --service api --force-new-deployment
```

---

## 9. Pipeline Security — SAST, Dependency Scan, OIDC

```yaml
# security-checks.yml — reusable security workflow
name: Security Scan

on:
  pull_request:
    branches: [main]

jobs:
  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v3

  deps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high

  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "sarif"
          output: "trivy-results.sarif"
```

---

## 10. Troubleshooting

### YAML Parser Error

```bash
# 83% of pipeline failures = YAML indentation
# Validator offline:
curl -X POST https://api.yamllint.com/ -d 'yaml=...'
# Atau pake VS Code extension "YAML" by Red Hat
```

### SSH Connection Timeout

```yaml
- name: debug SSH
  run: |
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -v ${{ env.DEPLOY_USER }}@${{ env.DEPLOY_HOST }} "echo connected"
```

### Secret Not Found

```bash
# Verifikasi secret ada
gh secret list -R Org/repo
# Cek environment access kalo pake environment-level secrets
```

### Cache Miss

```yaml
# Testing cache key
- name: Cache node_modules
  uses: actions/cache@v4
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

---

## 11. Matrix Build Strategy untuk Monorepo

Monorepo sering punya banyak package/service dalam satu repo. Matrix strategy GitHub Actions cocok untuk nge-build & test tiap package secara independen.

```yaml
# build-all.yml — matrix untuk monorepo dengan strategi include/exclude
name: Monorepo CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false # jangan cancel job lain kalo satu gagal
      matrix:
        node-version: [20, 22]
        package: [api, web, worker] # service di monorepo

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"

      - name: Install & Test package
        working-directory: packages/${{ matrix.package }}
        run: |
          npm ci
          npm test
```

### Include / Exclude — Koreksi Kombinasi

Pakai `include` buat nambah kombinasi spesifik dan `exclude` buat skip kombinasi yang gak relevan:

```yaml
strategy:
  matrix:
    node-version: [18, 20, 22]
    os: [ubuntu-latest, windows-latest]
    include:
      # node 22 cuma di Linux — irit runner Windows yang mahal
      - node-version: 22
        os: ubuntu-latest
    exclude:
      # skip node 18 di Windows — dependency gak support
      - node-version: 18
        os: windows-latest
```

### Dynamic Matrix dari Filesystem

Buat monorepo yang package-nya nambah terus, generate matrix dinamis:

```yaml
jobs:
  discover:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.set-matrix.outputs.packages }}
    steps:
      - id: set-matrix
        run: |
          PKGS=$(ls packages/ | jq -R -s -c 'split("\n")[:-1]')
          echo "packages=$PKGS" >> $GITHUB_OUTPUT

  test:
    needs: discover
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ${{ fromJson(needs.discover.outputs.packages) }}
    steps:
      - uses: actions/checkout@v4
      - run: cd packages/${{ matrix.package }} && npm ci && npm test
```

> [!tip] Matrix parallelism itu batasan: GitHub Actions maksimal 256 job concurrent per account. Kalo matrix lo > 50 item, split jadi workflow terpisah.

---

## 12. GitHub-Hosted vs Self-Hosted Runner — Perbandingan Lengkap

Pilih runner yang tepat直接影响 biaya, kecepatan, dan maintenance.

| Aspek            | GitHub-Hosted (`ubuntu-latest`)                                                          | Self-Hosted (VPS/Metal)                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Cost**         | Free quota 2000 min/bulan OSS; 3000 min/bulan private (Linux). ~$0.008/min setelah quota | Listrik + VPS — mulai ~$10/bulan untuk 1 runner. Fixed cost, cocok buat usage tinggi |
| **Performance**  | 2-core CPU, 7GB RAM, 14GB SSD (Linux). Terbatas, gak cocok build berat                   | Sesuai spek VM — bisa 16-core, 64GB RAM. Build besar 2-3x lebih cepat                |
| **Network**      | NAT keluar, gak bisa akses internal network VPS                                          | Bisa di network internal, akses DB staging, VPN, private registry                    |
| **Security**     | Ephemeral — tiap job dapet VM baru. Data auto-purge                                      | Persistent — kalo gak di-isolasi, job bisa spill data ke job lain                    |
| **Maintenance**  | Zero — GitHub urus update OS, tools, cleanup                                             | Lo urus: update OS, docker prune, disk cleanup, security patching                    |
| **Custom Tools** | Tools standar GitHub (Node, Python, Docker). Kustom? pake setup-action                   | Bisa install apa aja — GPU driver, JDK versi spesifik, build tools legacy            |
| **Scaling**      | Auto-scale by GitHub. Max 180 concurrent jobs per repo                                   | Lo urus sendiri. Bisa pake `scale-set` auto-scaling group                            |

### Kapan Pake Self-Hosted?

1. **GPU build/training** — GitHub gak sediakan GPU runner di hosted plan
2. **Internal network access** — deploy ke VPS di balik firewall
3. **Large monorepo build** — cache local yang massive, build >30 menit
4. **Cost efficiency** — tim lo run 5000+ job menit/bulan, VPS fixed cost lebih murah

### Setup Self-Hosted Runner

```bash
# Download & configure di VPS
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
tar xzf actions-runner-linux.tar.gz
./config.sh --url https://github.com/Org/repo --token $TOKEN
sudo ./svc.sh install && sudo ./svc.sh start
```

> [!warning] Self-hosted runner = security responsibility. Jangan pake `actions/checkout` tanpa checkout path terisolasi per job. Runner persistent bisa bocor artifact antar workflow. Untuk production, prefer ephemeral runner yang di-destroy tiap selesai.

---

## 13. Artifact Retention Policies

Artifact nimbun storage — apalagi kalo tiap push produce report + binary yang gak perlu.

### Per-Job Retention

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 3 # override default 90 hari
```

### Default Retention — Setting Repo

| Plan       | Default | Max      |
| ---------- | ------- | -------- |
| Free / Pro | 90 hari | 90 hari  |
| Team       | 90 hari | 90 hari  |
| Enterprise | 90 hari | 400 hari |

> [!tip] Untuk artifact sementara (test report, coverage, build cache), set `retention-days: 1–7`. Untuk release binary, biarkan default 90 hari atau upload ke release asset.

### Cleanup Strategy — Hapus Artifact Manual

```bash
# Hapus semua artifact workflow tertentu via GitHub CLI
gh run list --workflow deploy.yml --limit 50 --json databaseId \
  --jq '.[].databaseId' | \
  xargs -I{} gh run delete {} --confirm

# Hapus artifact expired — cron job GitHub Actions
name: Cleanup Old Artifacts
on:
  schedule:
    - cron: '0 6 * * 0'   # tiap Minggu 6AM

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
    - name: Delete old artifacts
      uses: cbrgm/cleanup-artifacts-action@v2
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        age: 3days              # artifact >3 hari dihapus
        run-delete: true
```

---

## 14. Environment Protection Rules

GitHub Environments bisa di-protect biar gak sembarang deploy ke production.

### Setup Environment di YAML

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.myapp.com

  deploy-production:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.myapp.com
    # Required reviewers + wait timer dikonfig di Settings > Environments
```

### Protection Rules yang Tersedia

| Rule                        | Fungsi                                               | Contoh Setting                            |
| --------------------------- | ---------------------------------------------------- | ----------------------------------------- |
| **Required reviewers**      | Mencegah deploy tanpa approval                       | 2 orang dari tim DevOps                   |
| **Wait timer**              | Delay automatic deploy, kasih waktu rollback darurat | 30 menit                                  |
| **Deployment branches**     | Batasi cabang yang bisa deploy                       | `main` dan `release/*` aja                |
| **Custom protection rules** | Marketplace actions sebagai gate                     | Datadog monitor check, Jira ticket status |

### Required Reviewers + Wait Timer

```yaml
# workflow_dispatch: manual deploy ke production dengan approval gate
name: Production Deploy

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Release tag to deploy"
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.mycompany.com
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.version }}
      - name: Deploy
        run: ./scripts/deploy-prod.sh
```

> [!important] Required reviewers hanya nge-block job yang pake environment. Pastiin semua `deploy-prod` job punya `environment: production`. Tanpa itu, protection rule gak aktif.

---

## 15. Workflow Commands — GITHUB_OUTPUT, GITHUB_ENV, GITHUB_STEP_SUMMARY

Workflow commands adalah cara ngirim data antar step, set environment variables, dan nulis summary — tanpa plugin tambahan.

### GITHUB_OUTPUT — Pass Data Antar Steps

```yaml
- name: Generate tag
  id: tagger
  run: echo "tag=v1.0.0-$(date +%s)" >> $GITHUB_OUTPUT

- name: Use tag
  run: echo "The tag is ${{ steps.tagger.outputs.tag }}"
```

Multiline output:

```yaml
- name: Set multiline output
  id: writer
  run: |
    EOF=$(dd if=/dev/urandom bs=1 count=8 status=none | base64)
    echo "json<<$EOF" >> $GITHUB_OUTPUT
    echo '{"key":"value"}' >> $GITHUB_OUTPUT
    echo "$EOF" >> $GITHUB_OUTPUT
```

### GITHUB_ENV — Set Env Across Entire Job

```yaml
- name: Set env dari script
  run: |
    echo "DEPLOY_PATH=/opt/myapp/${{ github.ref_name }}" >> $GITHUB_ENV
    echo "NODE_ENV=production" >> $GITHUB_ENV

# Semua step setelahnya bisa akses $DEPLOY_PATH & $NODE_ENV
- name: Deploy
  run: rsync -avz dist/ user@host:$DEPLOY_PATH/
```

### GITHUB_STEP_SUMMARY — Markdown di Run Summary

Bisa nulis markdown yang muncul di halaman hasil workflow:

```yaml
- name: Generate test summary
  run: |
    echo "## ✅ Test Results" >> $GITHUB_STEP_SUMMARY
    echo "| Suite | Pass | Fail |" >> $GITHUB_STEP_SUMMARY
    echo "|-------|------|------|" >> $GITHUB_STEP_SUMMARY
    echo "| Unit  | 142  | 0    |" >> $GITHUB_STEP_SUMMARY
    echo "| E2E   | 38   | 2    |" >> $GITHUB_STEP_SUMMARY
```

Bisa juga append multiline dari file:

```yaml
- name: Lint report
  run: cat lint-results.md >> $GITHUB_STEP_SUMMARY
```

### Command Reference Lengkap

| Command               | Fungsi                                   | Contoh                                                 |
| --------------------- | ---------------------------------------- | ------------------------------------------------------ |
| `GITHUB_OUTPUT`       | Output antar step                        | `echo "key=val" >> $GITHUB_OUTPUT`                     |
| `GITHUB_ENV`          | Environment variable                     | `echo "KEY=val" >> $GITHUB_ENV`                        |
| `GITHUB_STEP_SUMMARY` | Markdown summary                         | `echo "## Title" >> $GITHUB_STEP_SUMMARY`              |
| `GITHUB_PATH`         | Tambah PATH                              | `echo "/opt/tools" >> $GITHUB_PATH`                    |
| `debug`               | Log debug (kalo ACTIONS_STEP_DEBUG=true) | `echo "::debug::message"`                              |
| `notice`              | Notice annotation                        | `echo "::notice title=Info::message"`                  |
| `warning`             | Warning annotation                       | `echo "::warning file=app.js,line=42::message"`        |
| `error`               | Error annotation                         | `echo "::error::Build failed"`                         |
| `group`/`endgroup`    | Collapsible log group                    | `echo "::group::Build logs"` ... `echo "::endgroup::"` |

---

## 16. Composite Actions vs Reusable Workflows

Keduanya me-reuse logic, tapi beda use case.

| Aspek              | Composite Action                                          | Reusable Workflow                                        |
| ------------------ | --------------------------------------------------------- | -------------------------------------------------------- |
| **Format**         | Action YAML di `action.yml`                               | Workflow YAML di `.github/workflows/`                    |
| **Panggil**        | `uses: ./.github/actions/my-action`                       | `uses: ./.github/workflows/build.yml`                    |
| **Output**         | Ngehasilin output yang bisa dipake step lain              | Cuma bisa `needs:` di job lain                           |
| **Runners**        | Satu runner — step di composite jalan di runner yang sama | Multi-job — tiap job bisa runner beda (ubuntu + windows) |
| **Secrets**        | Langsung akses `${{ secrets.X }}`                         | Harus explicit pass via `secrets:`                       |
| **Max complexity** | Sampai 10 step (batas GitHub)                             | Sampai puluhan job — kompleksitas bebas                  |
| **Debugging**      | Susah — output action args terbatas                       | Gampang — tiap job log-nya terpisah                      |
| **Contoh**         | Setup tools + lint + test satu package                    | Build → Test → Deploy pipeline lengkap                   |

### Kapan Pake Composite Action

```yaml
# .github/actions/setup-project/action.yml
name: Setup Project
description: Install dependencies + generate Prisma
inputs:
  node-version:
    required: false
    default: "22"
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: "npm"
    - run: npm ci
      shell: bash
    - run: npx prisma generate
      shell: bash
      env:
        DATABASE_URL: ${{ inputs.database-url }}
```

Panggil dari workflow:

```yaml
- uses: ./.github/actions/setup-project
  with:
    node-version: "20"
    database-url: postgresql://localhost:5432/test
```

### Kapan Pake Reusable Workflow

```yaml
# .github/workflows/deploy-common.yml (reusable)
on:
  workflow_call:
    inputs:
      target:
        required: true
        type: string
    secrets:
      SSH_KEY:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          key: ${{ secrets.SSH_KEY }}
          script: ./deploy-${{ inputs.target }}.sh
```

> [!tip] Rule of thumb: kalo lo butuh **satu step yang dipake di banyak job** → Composite Action. Kalo lo butuh **satu pipeline utuh yang dipake di banyak repo** → Reusable Workflow.

---

## 17. Debugging Pipeline

Pipeline gagal? Jangan tebak-tebak. Ini toolkit debugging-nya.

### tmate — SSH Langsung ke Runner

```yaml
# debug-with-tmate.yml
name: Debug Pipeline
on:
  workflow_dispatch:

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup tmate session
        uses: mxschmitt/action-tmate@v3
        with:
          limit-access-to-actor: true # cuma lo yang bisa akses
```

Saat workflow jalan, action-tmate ngeprint koneksi SSH di log. SSH masuk, dan lo ada di shell runner live — bisa `ls`, `cat`, `node --inspect`, apa aja.

> [!warning] **Security**: tmate kasih shell akses penuh ke runner. Jangan pake di workflow yang handle secret. Limit `limit-access-to-actor: true` dan jangan pernah pake di production branch tanpa approval.

### act — Local Runner Simulation

Jalankan GitHub Actions di lokal sebelum push:

```bash
# Install (macOS/Linux)
curl -sSfL https://github.com/nektos/act/releases/download/v0.2.70/act_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin act

# Run workflow
act -j build                      # spesifik job
act -W .github/workflows/deploy.yml   # workflow tertentu
act --secret-file .env.secret     # bawa secret lokal
act --reuse                       # reuse container (cepat utk iterasi)
```

Kekurangan act:

- Gak bisa nge-test `self-hosted` runner
- Service container (PostgreSQL, Redis) perlu di-set manual atau pake `--services`
- Beberapa action (`docker/*`, `aws-actions/*`) gak 100% kompatibel
- Tetep lebih baik dari push → gagal → push ulang 10x

### workflow_dispatch Inputs — Parameterized Debug

```yaml
on:
  workflow_dispatch:
    inputs:
      ssh-debug:
        description: "Enable SSH debug session"
        type: boolean
        default: false
      dry-run:
        description: "Dry run — no actual deploy"
        type: boolean
        default: false
      target-service:
        description: "Service to deploy"
        type: choice
        options:
          - api
          - web
          - worker

jobs:
  deploy:
    steps:
      - if: ${{ inputs.ssh-debug }}
        uses: mxschmitt/action-tmate@v3
      - if: ${{ inputs.dry-run }}
        run: echo "Dry run — skipping deploy"
      - run: ./deploy.sh ${{ inputs.target-service }}
```

### Debug Common Failure Patterns

```yaml
# 1. Debug step-by-step — echo every variable
- name: Debug vars
  run: |
    echo "GITHUB_REF: $GITHUB_REF"
    echo "GITHUB_SHA: $GITHUB_SHA"
    echo "RUNNER_OS: $RUNNER_OS"
    echo "Event: $GITHUB_EVENT_NAME"

# 2. Dump context ke log (redact sensitive)
- name: Dump GitHub context
  env:
    GITHUB_CONTEXT: ${{ toJson(github) }}
  run: echo "$GITHUB_CONTEXT" | jq 'del(.token, .secrets)' > /dev/null
```

---

## 18. Cost Optimization — GitHub Actions

Actions gratis cuma 2000–3000 menit/bulan. Abis itu $0.008/menit. Optimasi bisa hemat ratusan dolar per bulan.

### Cache Hit Rate Tuning

Cache node_modules, Docker layers, dan build output:

```yaml
# Cache optimal — key by lockfile + OS
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
      .next/cache
    key: ${{ runner.os }}-modules-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-modules-

# Docker layer caching — gha cache backend
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

Cache hit vs miss: cache hit biasanya <30 detik, cache miss 2–5 menit. Dengan 1000 job/bulan, tiap 10% improvement hit rate = hemat ~$6–12/bulan.

### Matrix Parallelism — Irit Runner

```yaml
# ❌ Boros — 9 runner, banyak idle
strategy:
  matrix:
    os: [ubuntu, windows, macos]
    node: [18, 20, 22]

# ✅ Irit — pake include buat kombinasi minimal
strategy:
  matrix:
    node: [18, 20, 22]
    os: [ubuntu-latest]
    include:
      - node: 20
        os: windows-latest # cuma test windows di node 20 aja
```

### Runner Sizing — Self-Hosted

Kalo pake self-hosted runner di VPS, jangan pake 1 runner untuk banyak workflow paralel. Hitung:

| Jumlah Developer | Job per Day | Recommended Runner            | Estimasi Cost  |
| ---------------- | ----------- | ----------------------------- | -------------- |
| 1–3              | <100        | GitHub-hosted gratis          | $0             |
| 3–10             | 100–500     | 2–4 self-hosted (4 vCPU each) | ~$30–60/bulan  |
| 10+              | 500+        | 4–8 self-hosted + auto-scale  | ~$60–120/bulan |

### Concurrency — Jangan Tumpuk Job Gak Perlu

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true # cancel job lama kalo ada push baru
```

Ini ngemat runner hours secara signifikan — kalo developer push 5x dalam 5 menit, cuma commit terakhir yang keproses.

### Minimal Trigger — Jangan Jalanin Semua Workflow

```yaml
on:
  push:
    paths:
      - "**.js"
      - "**.ts"
      - "package.json"
      - "Dockerfile"
    paths-ignore:
      - "docs/**"
      - "**.md"
      - ".github/**" # trigger sendiri dikelola manual
```

Kombinasi `paths` + `paths-ignore` bisa ngurangin total workflow runs sampai 40–60%.

---

## 19. Common Pitfall — YAML Indentation

> **83% of pipeline failures = YAML indentation errors.** Ini angka real dari GitHub support data.

### Typical Error

```yaml
# ❌ SALAH — space vs tab campur, indentation inconsistent
jobs:
  build:
    runs-on: ubuntu-latest
  steps:          # ❌ sejajar dengan runs-on, harus indented
  - run: echo hi

# ❌ Multi-line script indentation kacau
- name: Deploy
  run: |
    ssh user@host "          # ❌ spacing gak konsisten
    cd /opt/app
    ./deploy.sh               # ❌ beda level
    "

# ✅ BENAR — 2 spasi per level, konsisten
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi

- name: Deploy
  run: |
    ssh user@host "
      cd /opt/app
      ./deploy.sh
    "
```

### Prevention — yamllint.com + GitHub Action

```yaml
# Pre-commit lint YAML sendiri
name: YAML Lint
on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: yamllint
        uses: ibiqlik/action-yamllint@v3
        with:
          file_or_dir: .github/workflows/
          config_data: |
            extends: default
            rules:
              line-length: disable
              truthy: disable        # 'on' sebagai key dianggap truthy
```

### VS Code Setup

Install **YAML by Red Hat** extension — otomatis validasi:

```jsonc
// settings.json
{
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml",
  },
  "yaml.validate": true,
  "editor.formatOnSave": true,
}
```

Dengan schema, VS Code auto-complete properti GitHub Actions + validasi real-time.

### Local Validator — CLI

```bash
# Python-based
pip install yamllint
yamllint .github/workflows/

# Atau pake npm
npx @github/actions-validator .github/workflows/deploy.yml
```

> [!tip] Selalu validasi YAML sebelum commit. GitHub web editor juga ada validasi syntax, tapi jangan andelin itu — kadang error baru ketahuan setelah runner mulai.

## 20. Koneksi ke Vault

| Catatan                                    | Koneksi                                                      |
| ------------------------------------------ | ------------------------------------------------------------ |
| [[cicd-guide]]                             | CI/CD conceptual guide — catatan ini implementasi konkretnya |
| [[cicd-shiftleft-shiftright]]              | DevSecOps strategy — security scanning di pipeline           |
| [[devsecops-pipeline-sast-dast-sbom]]      | Toolchain SAST/DAST/SBOM — integrasi di CI/CD                |
| [[nestjs-podman-workflow]]                 | NestJS-specific: container build + push + deploy             |
| [[container-kubernetes-security-deepdive]] | Container security — image scanning di pipeline              |
| [[linux-hardening-audit-praktis]]          | SSH hardening — prerequisite buat deploy ke VPS              |

## References

1. GitHub Actions Docs — https://docs.github.com/en/actions
2. GitHub Actions Security Hardening — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions
3. GitLab CI Docs — https://docs.gitlab.com/ee/ci/
4. OIDC with GitHub Actions — https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
5. Docker Build Push Action — https://github.com/docker/build-push-action
6. rsync Deployment Pattern — https://github.com/appleboy/ssh-action
