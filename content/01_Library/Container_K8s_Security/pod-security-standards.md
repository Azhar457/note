---
title: Pod Security Standards
tags: [security, kubernetes, container]
aliases: [pod-security-standards]
---
# Pod Security Standards (PSS)

Pod Security Standards (PSS) adalah policy bawaan Kubernetes untuk mengontrol aspek keamanan pod (privilege, capabilities, host namespaces, seccomp). Menggantikan PodSecurityPolicy (PSP, deprecated 1.21, removed 1.25). Ada 3 level: **Privileged**, **Baseline**, **Restricted** — diterapkan via namespace labels (Pod Security Admission).

## Tiga Level

| Level | Deskripsi | Kontrol Utama |
|-------|-----------|---------------|
| **Privileged** | Tanpa pembatasan | Tidak ada policy (legacy workloads, system) |
| **Baseline** | Minimal, mencegah privilege escalation | `allowPrivilegeEscalation: false`, no privileged, no hostNetwork/hostPID/hostIPC (kecuali dibutuhkan), no hostPath mount (kecuali whitelist), seccomp default? (RuntimeDefault di baseline? — seccomp belum wajib di baseline, wajib di restricted) |
| **Restricted** | Hardened, production-grade | Semua baseline +: `runAsNonRoot: true`, `runAsUser` non-0, seccompProfile `RuntimeDefault`, capabilities drop `ALL` (hanya tambah NET_BIND_SERVICE), no `hostPorts`, volumes terbatas |

## Penerapan (Pod Security Admission)

```bash
# Enforce Restricted di namespace production
kubectl label ns production pod-security.kubernetes.io/enforce=restricted
kubectl label ns production pod-security.kubernetes.io/enforce-version=latest
# Audit & warn
kubectl label ns production pod-security.kubernetes.io/audit=baseline
kubectl label ns production pod-security.kubernetes.io/warn=baseline
```

- **enforce** — reject pod yang tidak sesuai.
- **audit** — catat pelanggaran di event log (tidak block).
- **warn** — peringatan ke user saat apply.

Penerapan bertahap: warn → audit → enforce (hindari disruption).

## Contoh Pod Restricted-Compliant

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    seccompProfile:
      type: RuntimeDefault
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  containers:
    - name: app
      image: ghcr.io/org/app:1.0.0
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
          add: ["NET_BIND_SERVICE"]  # hanya jika perlu
      resources:
        limits:
          cpu: "500m"
          memory: "512Mi"
```

## Kontrol Detail (Restricted)

| Kontrol | Nilai Aman |
|---------|-----------|
| `hostNetwork`, `hostPID`, `hostIPC` | false |
| `hostPath` volumes | tidak diizinkan (Restricted); Baseline: hanya whitelist prefix |
| `privileged` | false |
| `allowPrivilegeEscalation` | false |
| `runAsNonRoot` | true |
| `runAsUser` | non-0 (1000+) |
| `capabilities` | drop ALL, add hanya yang diperlukan |
| `seccompProfile` | RuntimeDefault |
| `volumes` | configMap, secret, emptyDir, projected, downwardAPI (Restricted) |
| `hostPorts` | tidak diizinkan (Restricted) |

## Integrasi dengan Tooling Lain

- **Kyverno** — policy lebih kaya (mutate, validate, generate) di atas PSS; bisa auto-inject securityContext ke pod lama.
- **OPA Gatekeeper** — constraint framework (Rego) untuk aturan custom (misal: image dari registry tertentu, label wajib).
- **kube-bench** — CIS benchmark untuk node (bukan pod) — komplementer.
- **Trivy/Kyverno scan** — image vulnerability policy (block image dengan critical CVE).
- **RBAC** — jangan lupa: PSS mengontrol pod, tapi RBAC mengontrol siapa bisa deploy.

## Workload Tanpa Root (Praktis)

- Image harus punya user non-root (lihat [[create-dockerfile]]: `USER 1001`).
- Jika image lama root-only: Kyverno mutate `runAsNonRoot` + `runAsUser` (jika image toleran), atau rebuild image.
- OpenShift: SCC (Security Context Constraints) — analog PSS, default restricted.

## Monitoring Kepatuhan

- Event log: `kubectl get events -n production | grep -i "pod security"`.
- Audit log (API server audit): filter `pod-security.kubernetes.io`.
- Dashboard: policy report (Kyverno PolicyReport CRD) — lihat pelanggaran per namespace.
- Alerting: pelanggaran enforce = insiden (workload diblokir).

## Red Team Angle

Dari sudut penyerang: (1) cari namespace dengan PSS baseline/privileged → deploy pod jahat (crypto miner, network tool) jika RBAC memungkinkan; (2) hostPath mount + privileged = escape cepat (tapi di-restricted diblokir); (3) image dari registry internal tanpa signature → supply chain (lihat [[cosign-pipeline]]); (4) check `kubectl auth can-i create pods --as system:serviceaccount:...`. Blue team: PSS restricted + image signing + RBAC minimal + network policy = pertahanan kuat.

## Checklist Audit

- [ ] Namespace production: enforce=restricted?
- [ ] Semua workload memenuhi restricted (non-root, cap drop, seccomp)?
- [ ] Image non-root (USER 1001)?
- [ ] Tidak ada workload privileged tanpa justifikasi?
- [ ] Policy report dimonitor (Kyverno/OPA)?
- [ ] PSS versi di-pin (bukan latest drifting)?



## Studi Kasus: Migrasi PSP → PSS

1. Audit workload: `kubectl get pods -A -o json` → scan `securityContext` per pod; tools: `kubectl-psa-advisor` (angkat pod yang melanggar), kubeaudit.
2. Terapkan label warn + audit di semua namespace produksi terlebih dahulu (30 hari) — evaluasi pelanggaran.
3. Perbaiki workload: tambah securityContext (non-root, cap drop, seccomp), rebuild image non-root.
4. Enforce level yang sesuai: baseline untuk legacy/system, restricted untuk aplikasi user-facing.
5. Monitoring: policy report + alert.

Hasil: workload yang tadinya `privileged: true` punya port-forward/exec? — restricted memblokir sebagian besar vector escape (CVE-2022-0492? — cgroups release agent tetap butuh cap; dengan drop ALL + non-root + seccomp, mati).

## Common Pitfalls

- **Image root-only** — `runAsNonRoot: true` + image yang jalan sebagai root = CrashLoopBackOff. Solusi: rebuild image dengan USER, atau (sementara) mutate runAsUser yang image-compatible.
- **Seccomp di versi K8s lama** — sebelum 1.25 seccomp default bukan RuntimeDefault; set eksplisit di securityContext.
- **HostPort di service** — restricted menolak hostPort; gunakan NodePort/LoadBalancer (atau justify).
- **initContainers** — ikut policy (sama seperti container).
- **Windows nodes** — PSS restricted tidak sepenuhnya berlaku (Windows pod security context beda); gunakan level yang sesuai (baseline).
- **Mutating webhook bentrok** — jika Kyverno auto-inject dan PSS enforce, urutan mutasi harus sebelum validation (webhook order).

## Integrasi CI/CD

- Validasi manifest di CI: `kubectl dry-run` dengan label enforce? (tidak langsung) — gunakan `kubeconform` + schema PSS, atau Kyverno CLI (`kyverno apply policy pss-restricted.yaml -r deploy.yaml`).
- Pipeline reject sebelum deploy: static check (kubeconform), admission test (envtest), image scan.
- GitOps (ArgoCD): sync failure = enforcement; policy di version control.

## Extended Policy (Kyverno) untuk Lebih Kuat

- Wajibkan: `readOnlyRootFilesystem: true`, `resources.limits` (mencegah resource DoS), label owner.
- Cegah: `hostPath` mount sembarang, image dari registry non-allowlist, `automountServiceAccountToken: true` di pod yang tidak butuh.
- Auto-mutate: inject `seccompProfile`, `capabilities.drop ALL`, `runAsNonRoot` secara otomatis.

---

  audited
---