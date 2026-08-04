---
tags:
  - hierarchy
  - cybersecurity
  - defense-in-depth
  - network-security
  - encryption
  - identity
  - zero-trust
aliases:
  - Cybersecurity Defense Architecture
  - Defense in Depth Hierarchy
  - Security Layer Map
  - Cyber Defense Stack
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🛡️ Cybersecurity Defense Architecture — Hierarki Pertahanan Sistem Digital

> [!tip] Cybersecurity bukan satu produk — ia adalah **9 lapis pertahanan** yang harus diterapkan simultan. Catatan ini memetakan seluruh attack surface ke dalam Defense-in-Depth hierarchy, dari ancaman fisik sampai reputasi, dengan NIST CSF 2.0 alignment, OSI layer mapping, timeline evolusi (1960-2026), dan trade-off matrix per layer. Setiap layer punya kontrol, tool, framework, dan failure mode sendiri.

---

## Daftar Isi

1. [[#1. Premise — Mengapa "Satu Layer = Aman" Itu Mitos]]
2. [[#2. Nine-Layer Defense-in-Depth Model]]
3. [[#3. Layer L9 — Brand & Reputation]]
4. [[#4. Layer L8 — Compliance & Legal]]
5. [[#5. Layer L7 — Identity & Access (IAM)]]
6. [[#6. Layer L6 — Application Security]]
7. [[#7. Layer L5 — Endpoint Security (EDR/XDR)]]
8. [[#8. Layer L4 — Network Security]]
9. [[#9. Layer L3 — Data Security & Cryptography]]
10. [[#10. Layer L2 — Cloud & Infrastructure]]
11. [[#11. Layer L1 — Physical & Hardware]]
12. [[#12. Layer L0 — Threat Intelligence & Governance]]
13. [[#13. OSI Layer Mapping]]
14. [[#14. NIST CSF 2.0 Alignment]]
15. [[#15. Timeline 1960-2026 — Evolusi Ancaman]]
16. [[#16. Cross-Reference ke Vault]]
17. [[#References]]

---

## 1. Premise — Mengapa "Satu Layer = Aman" Itu Mitos

Kesalahan paling fatal dalam cybersecurity adalah mempercayai **satu kontrol** memberikan keamanan total:

- "Pakai antivirus saja cukup" → ransomware tetep masuk (1990-an)
- "Pakai firewall saja cukup" → insider threat bocor (2000-an)
- "Pakai enkripsi saja cukup" → side-channel attack bocor (2010-an)
- "Pakai cloud security group saja cukup" → misconfiguration bocor (2020-an)

**Defense-in-Depth** menyadari: **setiap kontrol bisa gagal**. Karena itu, kita stack 9 layer pertahanan — jika satu jebol, layer di belakangnya menahan.

```
┌──────────────────────────────────────────────────────────┐
│ L9: Brand & Reputation                                   │
│ L8: Compliance & Legal                                   │
│ L7: Identity & Access                                    │
│ L6: Application Security                                 │
│ L5: Endpoint / EDR / XDR                                 │
│ L4: Network / NDR                                        │
│ L3: Data Security & Cryptography                         │
│ L2: Cloud & Infrastructure                               │
│ L1: Physical & Hardware                                  │
│ L0: Threat Intelligence & Governance                     │
└──────────────────────────────────────────────────────────┘
     ↑   INCREASING ATTACKER REWARD      ↓
         DECREASING ATTACKER SKILL      (zero-day exploits)
```

**Prinsip Castle-and-Moat yang usang:** perimeter saja tidak cukup — attacker masuk lewat berbagai vektor (phishing, supply chain, insider).

**Prinsip Zero Trust modern:** verifikasi setiap akses, dari setiap arah, dari setiap entitas — trust nothing.

---

## 2. Nine-Layer Defense-in-Depth Model

### 2.1 Definisi Setiap Layer

| Layer | Fungsi | Failure Mode Tipikal | Owner |
|:-----:|--------|-----------------------|-------|
| **L9** | Brand reputasi, crisis comms | Key product tak relevan setelah breach | PR, marketing |
| **L8** | Compliance framework | Denda GDPR 4% revenue, PCI banned | Legal, GRC |
| **L7** | Authentication, authorization | Akun compromised, privilege escalation | IAM team |
| **L6** | App-level vulnerabilities | SQLi, XSS, RCE, supply chain | DevSecOps |
| **L5** | Host-level detection & response | Ransomware lolos, lateral movement | SOC + EDR team |
| **L4** | Network segmentation, IDS/IPS | East-west traffic tidak terlihat, DDoS | NetSec team |
| **L3** | Encryption, key management, DLP | Data exfiltration, breach disclosure | DataSec |
| **L2** | Cloud misconfig, IAM, secrets | S3 public bucket, IAM privilege excess | CloudSec |
| **L1** | Data center access, hardware tampering | Boot-level implant, hardware backdoor | IT ops |
| **L0** | Threat intel, governance, risk | Unknown unknown exploit | CISO, GRC |

### 2.2 Layer Dependency & Failover

```
[L0: intel feeds]──── feeds to ────→ [L4, L5, L6]
    ↓
Detect threat signature
    ↓
[L4: NDR]──── blocks ────→ if bypassed → [L5: EDR]──── blocks ────→ if bypassed → [L6: AppSec]
                                                                              ↓
                                                                         [L7: MFA catches]
                                                                                    ↓
                                                                         [L3: encryption at rest]
                                                                                    ↓
                                                                         [L1: physical security]
```

**Jika L0-L6 gagal total, L7-L9 adalah last line of defense:**
- L7: zero-trust dengan MFA tahan phising
- L3: data encrypted → theft tidak langsung berguna
- L9: brand reputation dijaga lewat respon krisis

---

## 3. Layer L9 — Brand & Reputation

> Pertahanan tertinggi: memastikan bahwa bahkan setelah breach, **brand tetap relevan**.

### 3.1 Komponen

| Komponen | Fungsi |
|----------|--------|
| Incident response plan | Koordinasi respon saat breach terjadi |
| Crisis communications | Pernyataan publik, customer notification |
| Cyber insurance | Finansial cover untuk breach |
| Reputation monitoring | Dark web mentions, social sentiment |
| Customer trust restoration | Compensation, transparency |

### 3.2 Failure Mode

| Failure | Dampak | Contoh |
|---------|--------|--------|
| Delay disclosure 6 bulan | GDPR fine €50M, brand drop 30% Yahoo (2017) |
| Berbohong tentang cakupan breach | Multi-class lawsuit, executive ouster | Uber 2017 |
| Slow customer notification | 50% churn dalam 30 hari | Equifax (2017) |
| Tidak punya crisis comm team | Runaway story = market cap -20% | Target (2013) |

---

## 4. Layer L8 — Compliance & Legal

> Memastikan organisasi mengikuti regulasi yang berlaku di industri + yurisdiksi.

### 4.1 Framework Compliance per Industri

| Industri | Wajib | Opsional |
|----------|------|----------|
| Healthcare (US) | HIPAA, HITECH | HITRUST, SOC 2 |
| Finance (US) | SOX, PCI DSS, GLBA | ISO 27001 |
| Finance (EU) | PSD2, Basel III, MiFID II | DORA |
| EU general | GDPR, NIS2, DSA | ISO 27001, 27017 |
| Cloud (US Fed) | FedRAMP, FISMA | CMMC |
| Energy/Utilities | NERC CIP | IEC 62443 |
| Privacy (US State) | CCPA, NYDFS | SOC 2 |
| Defense | CMMC, ITAR | FedRAMP High |

### 4.2 Dampak Compliance Failure

| Regulasi | Denda Tipikal |
|----------|--------------|
| GDPR | 4% annual revenue OR €20M (mana yang lebih tinggi) |
| HIPAA | $100-$50,000 per record + criminal |
| PCI DSS | $5K-$100K/month + kehilangan merchant |
| SOX | Criminal prosecution untuk officer |
| CCPA | $750 per record + class action |
| NIS2 | €10M atau 2% revenue |

---

## 5. Layer L7 — Identity & Access (IAM)

> Siapa yang boleh melakukan apa, dan dari mana.

### 5.1 Komponen

| Komponen | Fungsi | Contoh |
|----------|--------|--------|
| **SSO** | Single sign-on multi-app | Okta, Azure AD, Auth0 |
| **MFA** | Second factor from password | TOTP, FIDO2, push |
| **PIM/PAM** | Just-in-time admin | CyberArk, BeyondTrust |
| **RBAC** | Role-based access | AWS IAM, K8s RBAC |
| **ABAC** | Attribute-based access | Open Policy Agent |
| **ZTA** | Zero Trust Architecture | BeyondCorp, Zscaler |
| **User behavior analytics** | Anomaly detection on access | Splunk UBA, Exabeam |

### 5.2 Frameworks

- **NIST SP 800-63** — Digital identity levels (IAL1-3, AAL1-3, FAL1-3)
- **NIST SP 800-207** — Zero Trust Architecture
- **OAuth 2.1 + OIDC** — Modern delegated auth
- **SAML 2.0** — Enterprise SSO
- **SPIFFE/SPIRE** — Workload identity

### 5.3 Failure Mode

| Attack | Mitigation |
|--------|-----------|
| Phising | FIDO2 (WebAuthn) — tahan phising |
| Credential stuffing | MFA + breach detection |
| Session hijack | Short-lived JWT + refresh |
| Privilege escalation | Least privilege + JIT admin |
| Insider threat | UEBA + audit logs |

**Koneksi ke Vault:**
- [[hierarchy-cryptography]] — Public key infrastructure
- [[hierarchy-endpoint-security]] — EDR melihat user activity

---

## 6. Layer L6 — Application Security

> Aplikasi itu sendiri — yang menerima input dari user dan memproses data.

### 6.1 OWASP Top 10 (2021) — Surface of Attack

| Rank | Vulnerability | Frequency |
|:----:|---------------|:---------:|
| 1 | Broken Access Control | 3.81% |
| 2 | Cryptographic Failures | 4.49% |
| 3 | Injection | 4.74% |
| 4 | Insecure Design | 3.0% |
| 5 | Security Misconfiguration | 4.4% |
| 6 | Vulnerable & Outdated Components | 8.78% |
| 7 | Identification & Auth Failures | <1% |
| 8 | Software & Data Integrity Failures | 2.06% |
| 9 | Security Logging & Monitoring Failures | 6.51% |
| 10 | Server-Side Request Forgery | 1.43% |

### 6.2 SDLC Security Integration

```
┌────────────────────────────────────────────────────┐
│ Requirements (Abuse cases)                         │
├────────────────────────────────────────────────────┤
│ Design (Threat modeling STRIDE, attack trees)      │
├────────────────────────────────────────────────────┤
│ Coding (Secure code review, SAST)                  │
├────────────────────────────────────────────────────┤
│ Testing (DAST, IAST, fuzzing, pentest)             │
├────────────────────────────────────────────────────┤
│ Build (SCA, SBOM, signed artifacts)                │
├────────────────────────────────────────────────────┤
│ Deploy (IaC scanning, secrets detection)           │
├────────────────────────────────────────────────────┤
│ Operate (RASP, WAF, observability)                 │
└────────────────────────────────────────────────────┘
```

### 6.3 Supply Chain Security (SBOM Era)

- **SLSA** (Supply-chain Levels for Software Artifacts) — Google framework
- **Sigstore** — Cosign signing
- **in-toto** — Attestation generation
- **CycloneDX/SPDX** — SBOM standards
- **Sigstore Fulcio + Rekor** — certificate transparency

**Koneksi ke Vault:**
- [[hierarchy-endpoint-security]]
- [[waf-ml-anomaly-detection]]
- WAF deepdive (privat) (jika ada)

---

## 7. Layer L5 — Endpoint Security (EDR/XDR)

> Setiap device — laptop, server, IoT, container — adalah target.

### 7.1 Evolusi Endpoint Security

| Era | Teknologi | Deteksi | Response |
|-----|-----------|---------|----------|
| 1990-2005 | Antivirus signature | Database signature | Quarantine file |
| 2005-2015 | Anti-malware heuristik | Rule-based | Block process |
| 2015-2020 | EDR (Endpoint Detection & Response) | Behavioral analytics | Isolate host, kill process |
| 2020-2024 | XDR (Extended Detection & Response) | Cross-domain correlation | Orchestrated response |
| 2024-2026 | AI-Native EDR | ML pattern + LLM analyst | Autonomous response |

### 7.2 EDR vs XDR vs NDR

| Aspek | EDR | XDR | NDR |
|-------|-----|-----|-----|
| Scope | Endpoint only | Endpoint + email + cloud + network | Network traffic only |
| Data source | Syscalls, file, registry | Multi-source unified | NetFlow, packet, pcap |
| Response | Kill process, isolate host | Cross-tier orchestrated | Block traffic, sinkhole |

### 7.3 MITRE ATT&CK Framework

ATT&CK = Adversarial Tactics, Techniques, and Common Knowledge — database taktik+teknik attacker:

- **14 Tactics** — Recon, Initial Access, Execution, Persistence, Privilege Esc, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, Exfiltration, Impact
- **200+ Techniques** — spesifik behavior attacker
- **600+ Sub-techniques**

Setiap kontrol EDR/XDR dipetakan ke ATT&CK technique yang bisa ia detect.

**Koneksi ke Vault:**
- [[hierarchy-endpoint-security]] — Dedicated endpoint security hierarchy

---

## 8. Layer L4 — Network Security

> Arus lalu lintas di dalam dan antar jaringan.

### 8.1 Komponen Jaringan

| Komponen | Fungsi |
|----------|--------|
| **Firewall (stateful)** | Filter paket berdasarkan state |
| **WAF (Web Application Firewall)** | Filter HTTP/HTTPS sesuai rule |
| **IDS/IPS** | Intrusion Detection/Prevention |
| **NDR** | Network Detection & Response |
| **NAC** | Network Access Control |
| **Microsegmentation** | East-west isolation |
| **VPN / ZTNA** | Encrypted remote access |
| **BGP RPKI** | Route hijacking prevention |
| **DDoS protection** | Mitigation volumetric attacks |

### 8.2 OSI Layer Mapping

| OSI Layer | Ancaman | Kontrol |
|:---------:|---------|---------|
| 1 (Physical) | Wiretap, EMP | Faraday cage, fiber tap detection |
| 2 (Data Link) | ARP spoof, MAC flood | Port security, 802.1X |
| 3 (Network) | IP spoof, route hijack | RPKI, BCP38 |
| 4 (Transport) | SYN flood, port scan | TCP RST, rate limit |
| 5 (Session) | Session hijack | Encrypted sessions, short JWT |
| 6 (Presentation) | SSL stripping | HSTS, certificate pinning |
| 7 (Application) | SQLi, XSS, mitm | WAF, input validation |

### 8.3 East-West vs North-South Traffic

```
                North-South (in/out)
             ┌──────────────────────┐
             ↓                      ↑
┌─────┐     ┌─────┐    East-west    ┌─────┐
│ App │←───→│ App │ ←───────────→  │ App │
│  1  │     │  2  │    intra-DC     │  3  │
└─────┘     └─────┘                 └─────┘
              │      ┌─────┐        │
              └─────→│ DB  │←───────┘
                     └─────┘
```

- **North-south** traffic = traffic masuk/keluar DC (perimeter defense handles)
- **East-west** traffic = traffic antar-service dalam DC (microsegmentation handles)
- 80%+ modern traffic = east-west, tapi tool tradisional fokus north-south

**Koneksi ke Vault:**
- [[hierarchy-network-security]]
- [[hierarchy-wireless]] — Wireless subset
- [[hierarchy-kernel-bypass-networking]] — Kernel-level mitigasi
- [[hierarchy-offensive]] — Red team perspective

---

## 9. Layer L3 — Data Security & Cryptography

> Data at rest, in transit, in use — diproteksi dengan kriptografi.

### 9.1 The Three States of Data

```
Data at Rest      → Encryption at storage layer (LUKS, KMS, dm-crypt)
                  → Backup encryption
                  → Tokenization / anonymization

Data in Transit   → TLS 1.3, WireGuard, IPsec, mTLS
                  → Certificate management (cert-manager)
                  → PFS (Perfect Forward Secrecy)

Data in Use       → Confidential Compute (SEV-SNP, TDX, SGX)
                  → Memory encryption (AMD SME)
                  → Homomorphic encryption (research)
```

### 9.2 Key Management Lifecycle

```
Generate → Store → Distribute → Use → Rotate → Destroy
   │         │        │         │       │         │
   │         │        │         │       │         └─ Crypto-shred / zeroize
   │         │        │         │       └─ Per Q3 / annual rotation
   │         │        │         └─ Access control (KMS+IAM)
   │         │        └─ HSM, KMS, sealed secret
   │         └─ HSM (FIPS 140-3 L3)
   └─ entropy source
```

### 9.3 Algoritma yang Direkomendasikan (2026)

| Use Case | Algoritma | Key Size |
|----------|----------|:--------:|
| Symmetric encryption | AES-256-GCM | 256 bit |
| Asymmetric | Ed25519, X25519, ML-KEM-768 | - |
| Hashing (general) | SHA-3-256, BLAKE3 | 256-512 bit |
| Password hashing | Argon2id | 64-128 MB mem |
| TLS 1.3 | AES-256-GCM + Ed25519 | - |
| Backup | AES-256-GCM + Argon2id passphrase | - |

**Koneksi ke Vault:**
- [[hierarchy-cryptography]]
- [[hierarchy-quantum-cryptography-stack]] — PQC migration
- [[hierarchy-digital-plumbing]] — TLS/OpenSSL

---

## 10. Layer L2 — Cloud & Infrastructure

> Konfigurasi cloud yang aman, IAM, secrets management, runtime security.

### 10.1 Cloud Security Failure Modes

| Failure | Contoh |
|---------|--------|
| Public S3 bucket | 100M+ records bocor (2017-2024 trends) |
| Excessive IAM permissions | Service account dengan admin |
| Secrets in source code | API keys di public repo |
| Unpatched container images | CVE ratusan di registry |
| Insecure API gateway | No auth, no rate limit |
| Misconfigured K8s | Privileged pod, hostPath mount |

### 10.2 CSPM, CIEM, CNAPP

| Tool Kategori | Fungsi | Vendor |
|---------------|--------|--------|
| **CSPM** (Cloud Security Posture Mgmt) | Multi-cloud config audit | Wiz, Prisma Cloud, Lacework |
| **CIEM** (Cloud Infrastructure Entitlement Mgmt) | IAM rightsizing | Sonrai, Ermetic |
| **CNAPP** (Cloud-Native App Protection Platform) | K8s runtime + observability | Wiz, Aqua, Snyk |
| **Secrets Mgmt** | Vault, KMS | HashiCorp Vault, AWS KMS, SOPS |
| **IaC Scan** | Terraform/Kubernetes audit | Checkov, tfsec, Trivy |

### 10.3 K8s-Specific Stack

```
┌─────────────────────────────────────────────────┐
│ Cluster (managed: EKS/GKE/AKS)                   │
│   ├─ Control Plane encryption at rest            │
│   ├─ etcd encryption                             │
│   └─ Network Policy (Calico/Cilium)              │
├─────────────────────────────────────────────────┤
│ Workload                                          │
│   ├─ Pod Security Standards                      │
│   ├─ Runtime (Falco, Tetragon)                   │
│   ├─ Image scanning (Trivy, Grype)               │
│   ├─ Supply chain (Sigstore, Kyverno)            │
│   └─ mTLS service mesh (Istio, Linkerd)          │
├─────────────────────────────────────────────────┤
│ Pipeline                                          │
│   ├─ Static analysis (kubescape, kube-bench)     │
│   ├─ Admission control (OPA, Kyverno)            │
│   └─ Secret rotation (External Secrets, SOPS)    │
└─────────────────────────────────────────────────┘
```

**Koneksi ke Vault:**
- [[hierarchy-infrastructure-evolution]] — On-prem to cloud evolution
- [[container-kubernetes-security-deepdive]]
- [[kubernetes-security-roadmap]]
- [[cloud-infrastructure]]

---

## 11. Layer L1 — Physical & Hardware

> Akses fisik ke hardware, secure boot, hardware backdoors.

### 11.1 Komponen

| Kontrol | Fungsi |
|---------|--------|
| Data center access controls | Biometric, mantrap, visitor log |
| Surveillance | CCTV, motion sensor, IR curtain |
| Hardware tamper-evident | Seal, intrusion sensor |
| Secure boot | BIOS/UEFI signature chain |
| TPM | Hardware root of trust, measured boot |
| HSM | Cryptographic key storage FIPS 140-3 |
| Faraday cage | EMP / TEMPEST shielding |
| Hardware attestation | TEE attestation remote |

### 11.2 Trusted Execution Environments (TEE)

| TEE | Vendor | Use Case |
|-----|--------|----------|
| **Intel SGX** | Intel | Enclave computation (deprecated dari desktop) |
| **Intel TDX** | Intel | VM-level confidential computing |
| **AMD SEV-SNP** | AMD | VM-level + memory encryption |
| **ARM TrustZone** | ARM | Mobile, IoT normal mode |
| **Apple SE** | Apple | Secure enclave di iOS/Mac |
| **AWS Nitro** | AWS | Custom cloud hardware |
| **Nvidia H100 CC** | Nvidia | GPU confidential computing |

**Koneksi ke Vault:**
- [[hierarchy-operating-systems]]
- [[hierarchy-data-recovery]]
- [[embedded-systems]]

---

## 12. Layer L0 — Threat Intelligence & Governance

> Paling bawah — fondasi intelijen + keputusan yang menggerakkan semua layer di atas.

### 12.1 Komponen Governance

| Komponen | Fungsi |
|----------|--------|
| **CISO** | Executive accountability untuk security |
| **SOC** | 24/7 monitoring, triage, response |
| **GRC** | Governance Risk Compliance |
| **CTI** | Cyber Threat Intelligence team |
| **Red Team** | Authorized adversary simulation |
| **Bug Bounty** | External researcher engagement |
| **Penetration test** | Scheduled adversarial testing |

### 12.2 Frameworks Inti

| Framework | Owner | Fungsi |
|-----------|-------|--------|
| **NIST CSF 2.0** | NIST | Generic security framework (6 functions: Govern, Identify, Protect, Detect, Respond, Recover) |
| **NIST SP 800-53** | NIST | Control catalog (1000+ controls) |
| **ISO 27001/27002** | ISO | ISMS implementation |
| **MITRE ATT&CK** | MITRE | Adversary behavior catalog |
| **CIS Controls** | CIS | 18 prioritized actions |
| **OWASP ASVS** | OWASP | Application security verification |

### 12.3 Threat Intelligence Sources

| Tier | Sumber |
|------|--------|
| **Strategic** | Vendor reports (Mandiant, CrowdStrike, Microsoft) |
| **Operational** | ISACs, threat sharing communities (MISP, STIX/TAXII) |
| **Tactical** | IoC feeds (abuse.ch, AlienVault OTX, VirusTotal) |
| **Technical** | YARA rules, Snort/Suricata signatures |
| **OSINT** | Twitter, Reddit, dark web forums, paste sites |

---

## 13. OSI Layer Mapping

Singkat — setiap cybersecurity layer对应 OSI:

| Cybersecurity Layer | OSI Layer | Tools Khas |
|---------------------|:---------:|------------|
| L1 Physical | OSI 1 | Faraday, biometrics, security cameras |
| L4 Network (firewall/IDS) | OSI 2-4 | Cisco ASA, Palo Alto, Suricata |
| L4 Network (NDR) | OSI 3-4 | ExtraHop, Corelight |
| L3 Data (TLS encrypt) | OSI 6 | OpenSSL, cert-manager |
| L3 Data (storage encryption) | OSI 1 | LUKS, dm-crypt |
| L2 Cloud | OSI 7 | Wiz, Prisma Cloud |
| L6 Application (WAF) | OSI 7 | ModSecurity, Cloudflare WAF, Coraza |
| L6 Application (RASP) | OSI 7 | Datadog ASM, Sqreen |
| L5 Endpoint (EDR) | Host layer | CrowdStrike, SentinelOne, Wazuh |
| L7 Identity | OSI 7 | Okta, Auth0, Azure AD |

---

## 14. NIST CSF 2.0 Alignment

NIST CSF 2.0 punya 6 Functions. Setiap cybersecurity layer punya representative controls:

| Function | Deskripsi | Cybersecurity Layer yang Dominan |
|----------|-----------|-------------------------------|
| **GOVERN** | Kebijakan, risk, supplier | L8 + L0 |
| **IDENTIFY** | Asset, risk | L0 + L9 |
| **PROTECT** | Kontrol preventif | L1, L2, L3, L6, L7 |
| **DETECT** | Deteksi anomaly | L4, L5, L6 |
| **RESPOND** | Containment, eradication | L0, L5 |
| **RECOVER** | Restoration | L9 + L1 |

---

## 15. Timeline 1960-2026 — Evolusi Ancaman

```
┌──────────────────────────────────────────────────────────────┐
│ Era    │ Decade │ Major Shift                                  │
├────────┼────────┼──────────────────────────────────────────┤
│ ARPANET│ 1960s  │ Physical access = total access              │
│ Unix   │ 1970s  │ Password files, user permission             │
│        │ 1980s  │ Worms (Morris 1988), first antivirus        │
│ Web    │ 1990s  │ Network worms, firewall tsunami, Nessus      │
│ E-com  │ 2000s  │ SQL injection, XSS, APT, Storm Worm         │
│ Cloud  │ 2010s  │ Supply chain, ransomware, IoT botnets       │
│        │ 2015s  │ Cryptoware, BEC, deepfake voice              │
│ AI-era │ 2020s  │ LLM prompt injection, deepfake vishing       │
│        │ 2025   │ Autonomous agents attacking each other       │
│        │ 2026+  │ Self-evolving malware, AI-powered APT        │
└──────────────────────────────────────────────────────────────┘
```

**Trend besar tiap dekade:**
- **Surface:** makin meluas (device, cloud, container, AI agent)
- **Speed:** makin cepat (zero-day dalam hitungan jam)
- **Sophistication:** makin advanced (AI-generated phishing)
- **Target:** bergeser dari random → high-value (ransomware, BEC)

---

## 16. Cross-Reference ke Vault

| Layer | Catatan Vault |
|:-----:|---------------|
| **L9** | (tidak ada dedicated) — komunikasi krisis via SOPs |
| **L8** | (audit di vault SOPs), [[hierarchy-it-domain]] untuk governance |
| **L7** | [[hierarchy-cryptography]] (PKI), [[hierarchy-programming-language]] (OAuth libs) |
| **L6** | [[waf-ml-anomaly-detection]], [[software-supply-chain-security-deepdive]] |
| **L5** | [[hierarchy-endpoint-security]] (dedicated) |
| **L4** | [[hierarchy-network-security]] (dedicated), [[hierarchy-wireless]] |
| **L3** | [[hierarchy-cryptography]] (dedicated), [[hierarchy-quantum-cryptography-stack]] |
| **L2** | [[hierarchy-infrastructure-evolution]], [[container-kubernetes-security-deepdive]], [[kubernetes-security-roadmap]], [[ansible-hardening-rocky-linux-9]] |
| **L1** | [[hierarchy-operating-systems]], [[embedded-systems]] |
| **L0** | [[hierarchy-osint-rf]] (intel source), [[hierarchy-offensive]] (red team) |

---

## References

1. NIST. *"Cybersecurity Framework 2.0."* (2024).
2. NIST SP 800-207. *"Zero Trust Architecture."* (2020).
3. OWASP. *"OWASP Top 10 2021."* https://owasp.org/Top10/
4. MITRE. *"ATT&CK Matrix."* https://attack.mitre.org/
5. CIS. *"CIS Critical Security Controls v8."* (2021).
6. ISO/IEC 27001:2022. *"Information security management systems."*
7. SANS Institute. *"Defense in Depth."* (2018).
8. Verizon. *"2024 Data Breach Investigations Report."*
9. Mandiant. *"M-Trends 2024 Annual Report."*
10. NSA. *"NSA Cybersecurity Advisories."* 2020-2024.
11. Cloud Security Alliance. *"Top Threats to Cloud Computing."* (2024).
12. PCI Security Standards Council. *"PCI DSS v4.0."* (2022).
13. ENISA. *"Threat Landscape Report 2024."*
14. Google. *"BeyondProd, BeyondCorp."* (2019-2024).
15. R. Ross. *"Risk Frameworks: NIST and ISO."* NIST Publication, 2023.
