---
title: Cosign Pipeline
tags: [security, kubernetes, container, supply-chain]
aliases: [cosign-pipeline]
---
# Cosign Pipeline — Image Signing & Verification

Cosign (bagian dari Sigstore) menandatangani container image dengan keyless signing (OIDC) atau key pair, dan memverifikasi sebelum deploy. Tujuannya: memastikan image yang berjalan adalah image yang dibangun oleh pipeline tepercaya — mencegah supply chain attack (image tampered, registry compromise, tag drift).

## Konsep Sigstore

- **Cosign** — CLI signing/verifying.
- **Rekor** — transparency log (bukti permanen tanda tangan).
- **Fulcio** — certificate authority untuk keyless signing (identitas via OIDC email).
- **OIDC identity** — keyless: sign dengan identitas CI (GitHub Actions, GitLab CI) — "siapa yang build".
- **Key pair** — alternatif klasik: private key di secret manager (KMS), public key didistribusikan.

## Alur Pipeline (CI/CD)

```yaml
# .github/workflows/build.yml (contoh)
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: Build & push
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/org/app:1.0.0
      - name: Sign image (keyless)
        run: |
          cosign sign --yes ghcr.io/org/app:1.0.0
        env:
          COSIGN_EXPERIMENTAL: "1"  # keyless via OIDC
```

### Verifikasi (Deploy Time)

```bash
# Keyless verification
cosign verify --certificate-identity "https://github.com/org/repo/.github/workflows/build.yml@refs/heads/main"   --certificate-oidc-issuer "https://token.actions.githubusercontent.com"   ghcr.io/org/app:1.0.0

# Key pair verification
cosign verify --key cosign.pub ghcr.io/org/app:1.0.0

# Policy di cluster: Kyverno / OPA Gatekeeper / Connaisseur
# contoh Kyverno ClusterPolicy: verifyImage
```

## Keyless vs Key Pair

| Aspek | Keyless (OIDC) | Key pair |
|-------|----------------|----------|
| Setup | Minimal (OIDC dari CI) | Generate + distribute key |
| Identitas | CI workflow (email/identity) | Key tunggal (organisasi) |
| Rotasi | Otomatis (cert pendek) | Manual |
| Risiko | Trust pada OIDC issuer | Key leak = semua image |
| Cocok | GitHub/GitLab native | On-prem, air-gapped |

## Integrasi dengan K8s Admission

### Kyverno (policy engine)
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-signature
      image: ghcr.io/org/*
      verifyImages:
        - image: ghcr.io/org/*
          key: |-
            -----BEGIN PUBLIC KEY-----
            ...
            -----END PUBLIC KEY-----
          # atau attestors: keyless (issuer + subject)
```

### OPA Gatekeeper
- ConstraintTemplate + Constraint untuk `cosign verify`.
- Lebih kompleks tapi fleksibel.

### Connaisseur
- Admission controller khusus image verification (Sigstore native).

## SBOM & Attestation

- **SBOM**: `syft image ghcr.io/org/app:1.0.0 -o spdx-json > sbom.json` — inventory komponen.
- **Attest**: `cosign attest --predicate sbom.json --type spdx ghcr.io/org/app:1.0.0` — tanda tangani SBOM bersama image.
- **SLSA provenance**: `cosign attest --predicate provenance.json --type slsaprovenance` — build provenance.
- **Verifikasi attestation**: `cosign verify-attestation --type spdx ...`.

## Failure Mode & Troubleshooting

1. **Certificate identity mismatch** — workflow ref berubah (branch vs tag) → gunakan identity yang tepat di `--certificate-identity` (refs/heads/main vs tags).
2. **OIDC issuer tidak cocok** — GitHub: `https://token.actions.githubusercontent.com`; GitLab: `https://gitlab.com`.
3. **Multi-arch image** — tanda tangani per manifest index (cosign otomatis untuk index? perlu `--recursive` untuk keyless verifikasi multi-arch).
4. **Private registry** — cosign butuh auth (docker login / crane auth).
5. **Rekor unavailable** — cosign verify butuh akses ke Rekor; untuk air-gapped: offline bundle (`cosign save`/`load`, atau key pair tanpa Rekor).

## Best Practice

1. Sign semua image produksi (bukan cuma "penting").
2. Verify di admission control (enforce, bukan audit).
3. Jangan deploy image tanpa signature yang valid — fail closed.
4. Gunakan digest pinning di manifest (`image@sha256:...`) + signature.
5. Rotasi & revoke: keyless auto-expiry; key pair punya SOP revoke (cosign revoke di Rekor).
6. Audit log: siapa sign apa kapan (Rekor bukti).
7. Test pipeline: sengaja sign image jahat → pastikan ditolak.

## Koneksi ke Vault

- [[create-dockerfile]] — build image aman (prasyarat signing).
- [[pod-security-standards]] — level security pod.
- [[sealed-secrets-vs-vault]] — secret management (jangan di image).
- 00_Atlas/hierarchy-supply-chain-security — peta supply chain security.



## Studi Kasus: Supply Chain Attack yang Dicegah/Diperlambat

1. **Codecov (2021)** — attacker memodifikasi script uploader Codecov; image/source yang di-sign & diverifikasi akan menolak artifact yang tidak ditandatangani (jika pipeline menerapkan verification).
2. **Kaseya/REvil (2021)** — update software ditandatangani tapi attacker mencuri signing key; pelajaran: private key di KMS + short-lived cert (keyless) mengurangi jendela.
3. **PyPI/npm poisoning (2022-2023)** — paket tiruan; untuk container: base image yang dipin & disign dari registry trusted (docker.io + signature) menolak image jahat.

Pelajaran umum: signing bukan antivirus — tapi mengurangi supply chain surface: image harus dari pipeline tepercaya, bukan tag acak.

## Perintah Cosign Esensial (Cheat Sheet)

```bash
# Sign (keyless)
cosign sign --yes ghcr.io/org/app:1.0.0

# Verify (keyless dengan identity)
cosign verify --certificate-identity <id> --certificate-oidc-issuer <issuer> image

# Key pair
cosign generate-key-pair   # kunci: cosign.key / cosign.pub
cosign sign --key cosign.key image
cosign verify --key cosign.pub image

# Attestation
cosign attest --predicate sbom.json --type spdx image
cosign verify-attestation --type spdx image

# Copy dengan signature
crane copy image:1.0.0 mirror:1.0.0
```

## Integrasi GitLab/GitHub di Detail

### GitHub Actions
- Keyless: `uses: sigstore/cosign-installer@v3` + `cosign sign` — OIDC token otomatis.
- Identity: `https://github.com/{owner}/{repo}/.github/workflows/{file}@{ref}` dengan issuer `https://token.actions.githubusercontent.com`.

### GitLab CI
- ID Tokens: `id_tokens: sigstore: aud: sigstore` di job.
- Identity: `https://gitlab.com/{group}/{project}//.gitlab-ci.yml@{ref}` (format sesuai aturan GitLab SiGStore).
- Issuer: `https://gitlab.com`.

### Jenkins/self-hosted
- Key pair dari KMS (GCP/AWS) atau cosign.key di secret store.
- `COSIGN_KEY`, `COSIGN_PASSWORD` env; jangan hardcode di pipeline.

---

  audited
---