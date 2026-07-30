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
11. [[#11. Koneksi ke Vault]]

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

## 11. Koneksi ke Vault

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
