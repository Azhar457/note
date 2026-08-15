---
title: Create Dockerfile (Secure)
tags: [security, docker, supply-chain]
aliases: [create-dockerfile]
---
# Create Dockerfile — Praktik Aman & Supply Chain

Dockerfile menentukan image yang dijalankan di container. Image yang tidak aman = risiko supply chain (base image compromised, dependency tua, secret bocor). Catatan ini berisi praktik membangun image aman + integrasi dengan supply-chain security.

## Prinsip Image Aman

1. **Minimal base image** — semakin kecil, semakin kecil attack surface. Prefer: `distroless`, `alpine`, atau `slim`.
2. **Non-root user** — container jalan sebagai non-root (USER directive); rootless juga didukung runtime (rootless podman).
3. **Multi-stage build** — build tool di stage awal, runtime hanya salin artifact (tanpa compiler/deps dev).
4. **Scan image** — Trivy/Grype sebelum push; fail on critical.
5. **Pin version** — base image `image:tag@sha256:...` (immutable digest); hindari `latest`.
6. **No secrets di image** — jangan ARG/ENV password; secret via runtime (K8s secret/env-dependent).
7. **Principle of least packages** — jangan install yang tidak dipakai.

## Contoh Dockerfile Aman (Multi-stage)

```dockerfile
# Stage 1: build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
# (opsional) build step: RUN npm run build

# Stage 2: runtime — minimal
FROM node:20-alpine
# non-root user
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app ./
USER app
# security headers di aplikasi, bukan di image
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s   CMD node /app/healthcheck.js
CMD ["node", "server.js"]
```

### Distroless
```dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /app/server /server
ENTRYPOINT ["/server"]
```
Distroless: tanpa shell, tanpa package manager, nonroot default — minimal attack surface (tapi debugging = sulit; cukup untuk prod yang teruji).

### Python
```dockerfile
FROM python:3.12-slim
RUN useradd -m app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER app
CMD ["python", "app.py"]
```
Catatan: `pip install` tanpa `--no-cache-dir` menyisakan cache; wheel + freeze (`pip freeze > requirements.lock`) untuk reproducibility.

## Anti-pattern yang Harus Dihindari

1. `FROM ubuntu:latest` — mutable tag; bisa berubah isi sewaktu-waktu (supply chain).
2. Running as `root` — container root ≈ host root (jika kernel exploit/escape).
3. `RUN npm install` vs `npm ci` — non-reproducible (lockfile diabaikan).
4. Hardcode secret: `ARG DB_PASSWORD=...` / `ENV SECRET_KEY=...` — bocor di image history.
5. Menyertakan `.git`, history, kredensial, `.env` tanpa `.dockerignore`.
6. Copy seluruh workspace tanpa whitelist → build context mengandung file sensitif.

## .dockerignore (Wajib)

```
node_modules
.git
.env
*.log
Dockerfile*
docker-compose*
.DS_Store
coverage
dist (jika build di stage)
```

## Supply Chain Integration

- **Scanning**: `trivy image --severity HIGH,CRITICAL myimage` di CI; fail build jika critical.
- **Signing**: `cosign sign` (Sigstore) — verifikasi sebelum deploy (lihat note Container_K8s_Security/cosign-pipeline).
- **SBOM**: `syft image myimage -o spdx-json > sbom.json` — inventory semua komponen (lisensi + CVE tracking).
- **Provenance**: build attestation (SLSA provenance) — siapa yang build, dari apa.
- **Registry policy**: hanya image yang di-scan, signed, dan dari trusted registry yang boleh masuk cluster (OPA/Admission controller).

## Tambahan Runtime (docker run / compose)

```yaml
# docker-compose.yml
services:
  app:
    image: myapp:1.0
    user: "1001:1001"
    read_only: true
    tmpfs: [/tmp]
    cap_drop: [ALL]
    cap_add: [CHOWN]  # minimal saja
    security_opt: [no-new-privileges:true]
    environment:
      - SECRET_KEY_FILE=/run/secrets/secret
secrets:
  secret:
    file: ./secret.txt  # jangan commit! via env/SOPS
```

## Verification (Checklist)

- [ ] Base image pinned (digest) + minimal?
- [ ] Multi-stage, artifact-only runtime?
- [ ] USER non-root?
- [ ] `npm ci` / `pip freeze` (reproducible)?
- [ ] `.dockerignore` benar?
- [ ] Tidak ada secret/history bocor?
- [ ] Trivy scan PASS (no critical)?
- [ ] Image di-sign (cosign) + SBOM dihasilkan?
- [ ] Runtime: read-only fs, cap_drop all, no-new-privileges?

## Red Team Angle

Dari sudut penyerang: (1) image lama dengan known CVE di base (Log4Shell di image Java, CVE-2021-44228; nimbus-jose-jwt CVE-2023-52428); (2) secret di image history — `docker history image` bisa leak; (3) root container + capability → escape helper (CVE-2022-0492 cgroups release agent — contoh; pastikan kernel patched); (4) untagged base image (supply chain) — siapa yang bisa modify tag; (5) healthcheck/entry script yang menerima env tidak tepercaya. Blue team harus scan + sign + provenance.

## Koneksi ke Vault

- 01_Library/Container_K8s_Security/cosign-pipeline — signing lengkap.
- 01_Library/Container_K8s_Security/pod-security-standards — PSA level di K8s.
- 01_Library/DevOps/nestjs-podman-workflow — workflow dev aman dengan Podman (rootless).



## Layer & Cache Best Practice

1. **Urutan instruksi** — file yang jarang berubah (package.json, requirements.txt) dulu; code setelahnya → layer cache optimal (build cepat, pull kecil).
2. **Combine RUN** — `RUN apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*` — satu layer, tanpa cache apt.
3. **Jangan hapus file sensitif setelah COPY di layer yang sama** — layer masih menyimpan history; gunakan multi-stage atau `.dockerignore`.
4. **Nuget/go mod cache** — letakkan di builder stage, jangan di runtime image.
5. **Image size metrics** — `docker images`, `dive` (analisis layer), `docker history` untuk audit.

## Runtime Security Tambahan (K8s Context)

- Seccomp profile: `RuntimeDefault` (k8s `seccompProfile`) — blokir syscall berbahaya.
- `allowPrivilegeEscalation: false`, `privileged: false`, `readOnlyRootFilesystem: true`.
- Linux capabilities: `drop: [ALL]`, tambah minimal (mis. `NET_BIND_SERVICE`).
- Lihat [[pod-security-standards]] untuk level enforced di cluster.
- ImagePullPolicy: `IfNotPresent` / digest-pinned — bukan `latest`.

## SBOM & Provenance (Supply Chain Lanjutan)

- `syft` SBOM: SPDX/CycloneDX — sertakan license, version, purl.
- `cosign attest` — SLSA provenance (builder, source repo, command).
- Gate di cluster: admission controller (Kyverno/OPA) — wajib SBOM + signature dari registry trusted.
- Dependabot/renovate untuk base image update (digest bump otomatis).

---

  audited
---