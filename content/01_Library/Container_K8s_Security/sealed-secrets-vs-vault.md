---
title: Sealed Secrets vs Vault
tags: [security, kubernetes, secrets]
aliases: [sealed-secrets-vs-vault]
---
# Sealed Secrets vs HashiCorp Vault

Manajemen secret di Kubernetes adalah masalah klasik: Secret object hanya base64 (bukan enkripsi!), siapa pun dengan akses cluster bisa membaca. Dua solusi populer: **Sealed Secrets** (bitnami) dan **HashiCorp Vault** — plus alternatif (External Secrets Operator + cloud KMS, SOPS).

## Masalah Dasar

1. `kubectl get secret -o yaml` → base64 decode → plaintext. Secret K8s disimpan di etcd; **tidak dienkripsi by default** (enable EncryptionConfiguration di API server).
2. GitOps (ArgoCD) butuh secret di repo — plaintext di git = bocor.
3. RBAC sering over-permissive (view role bisa lihat secret? — sebenarnya view TIDAK termasuk secret read untuk default clusterrole tapi custom sering).
4. Secret di env var bocor via `kubectl exec env`, logs, debugging.

## Sealed Secrets (Bitnami)

**Cara kerja:** SealedSecret CRD → controller (di cluster) men-decrypt dengan private key → membuat Secret normal.

```bash
# Install controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/.../controller.yaml

# Seal di sisi client (public cert dari controller)
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
# atau: kubectl create secret generic mysec --from-literal=pass=xxx --dry-run=client -o yaml | kubeseal > ss.yaml

# Apply
kubectl apply -f sealed-secret.yaml
```

Keunggulan: (1) aman di git (cuma controller yang bisa buka); (2) GitOps friendly; (3) tanpa infra tambahan (controller in-cluster).
Keterbatasan: (1) secret tersimpan di cluster setelah unsealed (masih readable oleh cluster admin); (2) rotasi private key controller = semua sealed secret perlu re-seal; (3) tidak ada dynamic secret; (4) tidak ada audit/expiry.

## HashiCorp Vault

**Cara kerja:** Vault server (external atau in-cluster) menyimpan secret terenkripsi; aplikasi/pod mengambil secret on-demand via:
1. **Vault Agent Injector** — sidecar inject env/file dari Vault (template).
2. **Vault CSI Provider** — SecretProviderClass → volume mount.
3. **External Secrets Operator (ESO)** — sync Vault → K8s Secret.

```yaml
# Contoh SecretProviderClass (CSI)
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-db
spec:
  provider: vault
  parameters:
    roleName: app
    vaultAddress: http://vault:8200
    objects: |
      - objectName: "db-pass"
        secretPath: "secret/data/app"
        secretKey: "password"
```

Keunggulan: (1) dynamic secrets (DB creds auto-rotate, lease time); (2) audit log lengkap; (3) expiry & revocation; (4) enkripsi transit (KMS); (5) sentral untuk multi-cloud; (6) policies per path.
Keterbatasan: (1) infra tambahan (HA Vault, unseal management); (2) kompleksitas (auth methods, policies); (3) jika Vault down → app tanpa secret (resiliensi); (4) learning curve.

## Perbandingan

| Aspek | Sealed Secrets | Vault | External Secrets (ESO+KMS) |
|-------|---------------|-------|---------------------------|
| Secret di git | Aman (ter-seal) | Tidak (Vault path) | Tidak (referensi) |
| Enkripsi at rest | Controller key | Vault + KMS | Cloud KMS (AWS/GCP/Azure) |
| Dynamic secret | ❌ | ✅ | ❌ (bisa via Vault backend) |
| Rotasi | Manual (re-seal) | Otomatis (lease) | Otomatis (sync interval) |
| Audit | Terbatas | Lengkap | Cloud audit |
| Infra tambahan | Minimal | Signifikan | Minimal (controller + cloud) |
| GitOps friendly | ✅✅ | ⚠️ (via ESO/agent) | ✅✅ |
| Cocok untuk | Small-medium, GitOps murni | Enterprise, dynamic secret, compliance | Cloud-native, sudah pakai cloud |

## Rekomendasi Penerapan

1. **Tim kecil / GitOps murni / secret statis** → Sealed Secrets (atau SOPS + age yang disimpan di git terenkripsi).
2. **Enterprise / dynamic secret / audit ketat** → Vault (Kubernetes auth, policies per app) + CSI/Agent.
3. **Cloud-native / sudah di AWS/GCP/Azure** → ESO + KMS/Parameter Store/Secret Manager (managed, tanpa operasional Vault).
4. **Hybrid**: ESO → Vault untuk dynamic, ESO → cloud untuk statis.

## Checklist Implementasi (Apa pun solusinya)

- [ ] Secret TIDAK plaintext di repo / configmap / env hardcoded?
- [ ] Kubernetes API server encryption at rest (EncryptionConfiguration) aktif?
- [ ] RBAC: hanya workload yang butuh yang bisa read secret path?
- [ ] Rotasi secret terjadwal (password DB, API key) + testing setelah rotasi?
- [ ] Audit log akses secret (siapa, kapan, path apa)?
- [ ] Backup/recovery secret (Vault unseal keys, Sealed private key) tersimpan aman?
- [ ] Jika Vault: HA + unseal SOP terdokumentasi?

## Red Team Angle

1. **Sealed Secrets**: jika attacker dapat akses controller (RBAC) → decode semua (private key di controller). Keamanan = RBAC + network policy.
2. **Vault**: target utama — token/role over-permissive (`policy "*" path "*"`), unseal key di repo, Vault exposure (port 8200 terbuka), `vault kv get` dari pod compromised.
3. **K8s Secret**: `kubectl get secrets -A` + decode — cepat; jika etcd tidak dienkripsi → dump etcd = semua secret.
4. **ESO**: store secret menyimpan token cloud dengan scope lebar — compromise ESO = compromise semua secret cloud.

## Koneksi ke Vault

- [[create-dockerfile]] — jangan secret di image.
- [[pod-security-standards]] — workload hardening (akses secret via RBAC + PSP).
- [[cosign-pipeline]] — supply chain (secret signing key).
- 00_Atlas/hierarchy-identity-trust — identitas & trust (Vault PKI).

---

  audited
---