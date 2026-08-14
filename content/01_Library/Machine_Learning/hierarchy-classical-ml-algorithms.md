
## Deepdive — Classical ML Attack Surface

| Algoritma | Attack | Tool | Detection Gap |
|-----------|--------|------|---------------|
| **SVM** | Evasion (FGSM) | ART | ML monitoring rare |
| **Random Forest** | Poisoning | scikit-learn | Data audit rare |
| **K-Means** | Cluster injection | Custom | Unsupervised = no label |
| **Naive Bayes** | Feature manipulation | Custom | Model audit rare |
| **Logistic Regression** | Evasion (boundary) | Custom | Boundary = learnable |

### Evasion Attack (SVM Classifier)

```
Target: Spam classifier (SVM)
    ↓
Train: Surrogate model (public data) → approximate boundary
    ↓
Craft: FGSM perturbation → input modified → misclassify
    ↓
Result: Spam bypass → inbox delivery
```

## Referensi
- ART — https://github.com/Trusted-AI/adversarial-robustness-toolbox
- Poisoning Attack — https://arxiv.org/abs/1206.6389

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

## Konsep Dasar — Algoritma Classical ML

### Supervised Learning

| Algoritma | Type | Strength | Weakness | Use Case |
|-----------|------|----------|----------|----------|
| **Linear Regression** | Regression | Simple, interpretable | Underfit complex | Trend |
| **Logistic Regression** | Classification | Probabilistic | Linear only | Spam filter |
| **SVM** | Classification | Kernel trick (non-linear) | Slow on large | Text, image |
| **Random Forest** | Ensemble | Robust, feature importance | Black box | Tabular |
| **XGBoost** | Ensemble | High accuracy | Tuning sensitive | Kaggle winner |
| **KNN** | Lazy | Simple | Slow inference | Prototype |

### Unsupervised Learning

| Algoritma | Type | Use |
|-----------|------|-----|
| **K-Means** | Clustering | Segment, pattern |
| **DBSCAN** | Density clustering | Anomaly (noise) |
| **PCA** | Dim reduction | Visualization, compress |
| **Isolation Forest** | Anomaly | Outlier detection |
| **Autoencoder** | Neural anomaly | Complex pattern |

### Training Process

```
1. Data split: train (70%) / validation (15%) / test (15%)
2. Train: model.fit(X_train, y_train) → update weights
3. Validate: model.evaluate(X_val) → tune hyperparameter
4. Test: model.evaluate(X_test) → final metric (unseen data)
5. Deploy: model.predict(X_new) → production
```

### Overfitting & Underfitting

| Problem | Gejala | Cause | Fix |
|---------|--------|-------|-----|
| **Overfit** | Train acc high, test low | Model too complex, too few data | Regularization (L1/L2), drop, early stop |
| **Underfit** | Train acc low, test low | Model too simple | Add feature, deeper model |

### Cross-Validation

```python
from sklearn.model_selection import cross_val_score
cssclasses:
  - wide-table
  - callout

# K-fold: split data K kali, train K model, average
scores = cross_val_score(model, X, y, cv=5)
print(f"Mean: {scores.mean():.3f} ± {scores.std():.3f}")
```

## Referensi Tambahan
- Scikit-learn — https://scikit-learn.org/
- XGBoost — https://xgboost.readthedocs.io/
- ART (Attack) — https://github.com/Trusted-AI/adversarial-robustness-toolbox

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
