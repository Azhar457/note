---
title: NestJS Podman Workflow
tags: [devops, nestjs, podman, typescript]
aliases: [nestjs-podman-workflow]
---
# NestJS + Podman Development Workflow

Workflow pengembangan NestJS (Node.js/TypeScript) dengan Podman (rootless container engine, daemonless, Docker-compatible CLI). Fokus: pengembangan lokal cepat & aman, produksi aman.

## Kenapa Podman (vs Docker)

1. **Rootless by default** — container jalan sebagai user non-root (host) → keamanan lebih baik (tidak perlu daemon root).
2. **Daemonless** — tidak ada daemon terpusat; systemd user service opsional.
3. **Docker-compatible CLI** — `podman build`, `podman run`, `podman compose` (via podman-compose) — migrasi mudah.
4. **Podman Desktop** — GUI opsional.
5. **systemd integration** — `podman generate systemd` untuk unit service (quadlet).

## Setup Development

### Prasyarat
```bash
# Fedora/RHEL
sudo dnf install podman podman-compose
systemctl --user enable --now podman.socket  # socket user (untuk tooling)

# Verifikasi rootless
podman info | grep -A2 rootless
```

### Project NestJS + Postgres

```yaml
# compose.yaml (dev)
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://app:app@db:5432/app
    volumes:
      - .:/app           # live reload
      - /app/node_modules
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=app
      - POSTGRES_PASSWORD=app
      - POSTGRES_DB=app
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      timeout: 3s
      retries: 10
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

```bash
podman compose up -d --build
podman compose logs -f api
podman compose exec api sh
``` 

### Hot Reload
- NestJS watch mode (`npm run start:dev`) di container + bind mount source → perubahan langsung tanpa rebuild.
- node_modules via named volume (jangan bind mount dari host — arsitektur beda).

## Produksi: Image Aman (NestJS)

Lihat juga [[create-dockerfile]] untuk detail; ringkas:

```dockerfile
# Stage 1: build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: runtime
FROM node:20-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
USER app
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

Build & push:
```bash
podman build -t ghcr.io/org/nestjs-app:1.0.0 .
podman push ghcr.io/org/nestjs-app:1.0.0
# sign (lihat [[cosign-pipeline]])
cosign sign --yes ghcr.io/org/nestjs-app:1.0.0
```

## Rootless Networking & Port

- Rootless: binding port <1024 butuh capability — pakai >= 1024 atau `net.ipv4.ip_unprivileged_port_start`.
- Podman networking: default slirp4netns (user-mode); `--network=host` di rootless = host network (hati-hati).
- Untuk produksi K8s: image sama, jalankan di cluster (bukan container host langsung) — policy PSS (lihat [[pod-security-standards]]).

## Troubleshooting Umum

1. **Permission denied volume** — user container vs host UID: gunakan `--userns=keep-id` (map host user) atau UID match.
2. **node_modules volume kosong** — jangan bind mount node_modules; gunakan anonymous volume (`/app/node_modules`).
3. **Port conflict** — `podman ps -a` cek; `podman port <container>`.
4. **Build lambat** — layer order (package.json dulu), buildkit (`podman build --buildkit`? — default Buildah), cache mount (`--mount=type=cache,target=/root/.npm`).
5. **Compose scale** — `podman compose up --scale api=2` (network overlay? rootless pakan non-default network).

## Keamanan Container Runtime

- Non-root dalam container (`USER app`) + rootless engine.
- Read-only FS: `read_only: true` + tmpfs `/tmp`.
- No-new-privileges: `security_opt: ["no-new-privileges:true"]`.
- Capability drop: `cap_drop: [ALL]`.
- Resource limit: `mem_limit`, `pids_limit`.
- Healthcheck: `/health` endpoint (NestJS `@nestjs/terminus`).

## Checklist

- [ ] Rootless Podman (bukan root)?
- [ ] Compose dev: live reload + healthcheck DB?
- [ ] Produksi: multi-stage, non-root USER, minimal deps?
- [ ] Image di-scan (Trivy) + signed (cosign)?
- [ ] Container run: cap drop, no-new-privileges, read-only?
- [ ] Resource limits di-set?
- [ ] Secret via env/secret manager (bukan di image)?



## NestJS Struktur Project & Best Practice

```
src/
  main.ts          # bootstrap + global pipes (ValidationPipe)
  app.module.ts    # root module
  modules/
    auth/          # feature module (controller, service, dto)
    users/
  common/          # guards, interceptors, filters, decorators
  config/          # @nestjs/config (env validation)
test/              # e2e (supertest)
```

- **ValidationPipe** global dengan whitelist + forbidNonWhitelisted (anti mass assignment).
- **Helmet** (`@nestjs/helmet`) — security headers.
- **ThrottlerModule** — rate limiting.
- **@nestjs/terminus** — healthcheck (untuk container healthcheck).
- **ConfigModule** dengan zod validation (env di-validasi saat startup).
- **CORS** di-set ketat (origin whitelist) — jangan `*` dengan credentials.

## Podman Quadlet (Systemd Unit untuk Service)

```ini
# ~/.config/containers/systemd/app.container
[Unit]
Description=NestJS App

[Container]
Image=ghcr.io/org/nestjs-app:1.0.0
PublishPort=3000:3000
Environment=NODE_ENV=production
EnvironmentFile=/etc/app/env
Volume=/srv/app/data:/data

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now app
```

Quadlet: container jadi systemd service — auto-restart, log journalctl, dependency ordering. Sangat cocok untuk single-host production kecil (homelab/VPS).

## Monitoring & Observability (NestJS)

- **Metrics**: `@nestjs/terminus` + prom-client (custom metrics: request duration, error rate).
- **Logging**: pino/nestjs-pino (structured JSON) → stdout → collector (Loki/ELK).
- **Tracing**: OpenTelemetry SDK (trace HTTP request, DB query).
- **Alert**: Prometheus + Alertmanager (SLO-based, lihat [[sre-practices-and-slo]]).
- **Health**: `/health/live` (process up), `/health/ready` (deps: DB, cache) — dipakai container healthcheck + LB.

## Red Team Notes (NestJS/Node)

1. **Prototype pollution** via JSON body (lihat [[js-framework-vulnerabilities]]) — ValidationPipe whitelist membantu, tapi library merge (lodash) tetap risk.
2. **Rate limit bypass** — ThrottlerModule berbasis IP; X-Forwarded-For spoof jika trust header (lihat [[wiod-reverse-proxy-deepdive]]).
3. **RCE via deserialization** — jangan pakai `node-serialize`/unserialize JSON custom; gunakan JSON.parse + validation.
4. **Dependency** — Node ecosystem besar: npm audit wajib; lockfile commit.
5. **SSRF** — jika app fetch URL (integrasi), block private range.

## Checklist Deploy Production

- [ ] Image multi-stage non-root + scan + signed.
- [ ] Podman quadlet / K8s deployment dengan PSS restricted.
- [ ] Env validation (zod) + secret via manager.
- [ ] Healthcheck aktif (liveness/readiness).
- [ ] Metrics/logging/tracing terpasang.
- [ ] Rate limit + helmet + CORS ketat.
- [ ] Resource limits (CPU/mem/pids).
- [ ] Backup data teruji.

---

  audited
---