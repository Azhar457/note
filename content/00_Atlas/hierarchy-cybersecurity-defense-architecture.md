---
title: Cybersecurity Defense Architecture — Multi-Layer Defense Architecture (9 Layer Framework)
tags: [defense-in-depth, nist-csf-2.0, blue-team, security-architecture, defense-architecture, layer-defense]
aliases: [hierarchy-cybersecurity-defense-architecture, defense-in-depth-map, blue-team-layer-architecture]
created: 2026-08-14
updated: 2026-08-14
status: complete
references:
  - 00_Atlas/attacker/attack-cybersecurity-defense-architecture.md (Attack Perspective — red team counterpart)
  - 01_Library/defender/_index.md
related_notes:
  - 01_Library/defender/Web/*
  - 01_Library/defender/Infrastructure/*
  - 01_Library/defender/Incident_Response/*
  - 01_Library/attacker/Intel_Misc/attack-defense-hardening-playbook.md
cssclasses:
  - wide-table
  - callout
---


# Cybersecurity Defense Architecture — Multi-Layer Defense Architecture (9 Layer Framework)

> **Tujuan dokumen ini:** Pemetaan sistematis arsitektur pertahanan siber (Blue Team / Defender) dalam **9 lapis**, dengan referensi framework internasional (NIST Cybersecurity Framework 2.0, CISA Zero Trust Maturity Model, MITRE D3FEND, ISO 27001/27002, CIS Controls v8, NIST SP 800-53 Rev 5, OWASP ASVS v4.0). Ini adalah **counterpart netral** dari [[00_Atlas/attacker/attack-cybersecurity-defense-architecture.md|Attack Perspective]] — yang satu dari sudut pandang penyerang, ini dari sudut pandang pertahanan.
> **Status konten:** Lengkap — semua 9 layer, setiap layer dengan sub-komponen konkret, referensi framework, dan tindakan praktis. Mengikuti pola konsisten dengan hierarchy lain di 00_Atlas.

---

## 1. Mengapa 9 Layer?

Defense-in-depth (pertahanan berlapis) adalah prinsip bahwa **tidak ada satu kontrol keamanan pun yang sempurna**. Jika satu layer gagal, layer berikutnya masih menghadang. Model 9 layer ini adalah generalisasi dari berbagai framework:

| Framework | Konsep yang Diadopsi |
|-----------|---------------------|
| NIST CSF 2.0 | 6 fungsi: Govern, Identify, Protect, Detect, Respond, Recover |
| CISA Zero Trust Maturity Model | 5 pilar: Identity, Device, Network, Application Workload, Data |
| MITRE D3FEND | 4 kelas taksonomi: Harden, Detect, Isolate, Deceive, Evict |
| ISO 27001 | Annex A kontrol (organisasi, manusia, fisik, teknologi) |
| CIS Controls v8 | 18 kontrol berjenjang (IG1, IG2, IG3) |
| NIST SP 800-53 | 20 keluarga kontrol (AC, AT, AU, CA, CM, CP, IR, dll) |
| OWASP ASVS v4.0 | 14 verifikasi aplikasi |

Dari semua framework tersebut, muncul pola umum **9 layer** yang mewakili jalur serangan dari **luar ke dalam**:

```
L1 (Fisik & Edge) → L2 (Network Perimeter) → L3 (Endpoint) → L4 (Aplikasi/Web)
→ L5 (Data) → L6 (Identitas & Akses) → L7 (Cloud/Infrastruktur) → L8 (Orkestrasi/SOC)
→ L9 (Governance & Brand)
```

---

## 2. Tabel Ringkasan 9 Layer

> **Catatan kolom:** `Layer` = nomor lapis; `Fokus` = objek utama pertahanan; `Contoh Kontrol` = implementasi teknis; `Framework` = acuan standar; `Kegagalan Khas` = pola serangan yang biasa menembus layer ini.

| Layer | Nama | Fokus | Contoh Kontrol | Framework | Kegagalan Khas |
|-------|------|-------|----------------|-----------|----------------|
| **L1** | Physical & Edge | Gedung, data center, kabel, perangkat edge | CCTV, biometric access, cable locks, UPS, tamper-evident seals | ISO 27001 A.7-8, NIST 800-53 PE | Tailgating, USB drop attack, theft |
| **L2** | Network Perimeter | Firewall, router, DDoS protection | NGFW, IDS/IPS, DDoS scrubbing, network segmentation, VLAN | NIST 800-41, CIS v8 Ctrl 4 | Port scan, DoS/DDoS, misconfig firewall |
| **L3** | Endpoint | Laptop, server, mobile, IoT | EDR/XDR, antivirus, patch management, application allowlist | MITRE D3FEND Harden, CIS v8 Ctrl 2-4 | Malware, ransomware, zero-day |
| **L4** | Application / Web | Web app, API, microservice | WAF, runtime protection (RASP), input validation, ASVS | OWASP ASVS, OWASP Top 10 | SQLi, XSS, SSRF, auth bypass |
| **L5** | Data | Database, file, backup, secrets | Encryption at rest/in-transit, DLP, backup 3-2-1, vault | ISO 27001 A.8, NIST 800-53 SC | Data exfil, ransomware encrypt, secret leak |
| **L6** | Identity & Access | User, admin, service account | MFA, SSO, PAM, RBAC/ABAC, conditional access, least privilege | NIST 800-63, CISA Zero Trust Pillar 1 | Credential stuffing, phishing, privilege escalation |
| **L7** | Cloud / Infra | IaaS, PaaS, container, orchestration | CSPM, IaC scanning, K8s policy, network policy, secrets mgmt | CISA ZTMM Pillar 2-4, CIS Benchmarks | Cloud misconfig, exposed S3, container escape |
| **L8** | Orchestration / SOC | SIEM, SOAR, ticketing, runbook | SIEM, SOAR, threat intel, UEBA, detection engineering, IR playbook | NIST 800-61, NIST CSF Detect-Respond | Alert fatigue, missed detection, slow IR |
| **L9** | Governance & Brand | Policy, compliance, awareness, crisis comm | Security awareness, policy, DR/BCP, vendor risk, exec reporting | NIST CSF Govern, ISO 27001 Clause 5 | Social engineering success, reputational damage, compliance fines |

---

## 3. Detail per Layer

### 3.1 L1 — Physical & Edge

**Objek:** gedung, ruang server, perangkat edge (router ISP, switch, UPS), media fisik.

**Kontrol konkret:**
- Akses fisik berlapis: kartu + biometric + mantrap (airlock) di area sensitif
- CCTV & visitor log; aturan "clean desk" dan "clear screen"
- USB lock / cable lock; BIOS/UEFI password + Secure Boot
- Perlindungan daya: UPS + genset + dual power feed
- Asset inventory fisik (tag, RFID) sesuai NIST 800-53 PE-2/PE-3

**Kegagalan khas:** tailgating (ikut orang lain masuk), USB drop attack (flash drive berisi malware ditinggal di parkiran), pencurian laptop/HDD, sabotase fisik, pemadaman listrik tanpa UPS.

**Mitigasi praktis (homelab/VPS scale):** 2FA di console cloud, disk encryption (LUKS/BitLocker), laptop lock saat meninggalkan meja, jangan tinggalkan flash drive.

---

### 3.2 L2 — Network Perimeter

**Objek:** firewall, router, switch, IDS/IPS, load balancer, DDoS protection.

**Kontrol konkret:**
- NGFW dengan deny-by-default; egress filtering (CIS v8 Ctrl 4)
- Network segmentation: VLAN per trust zone (DMZ, internal, IoT, guest)
- IDS/IPS (Suricata/Snort) + tcpdump/pcap analysis
- DDoS scrubbing (Cloudflare, AWS Shield, atau on-prem)
- DNS security (DNS filtering, DNSSEC, encrypted DNS DoH/DoT)
- Zero Trust Network Access (ZTNA) — Tailscale/WireGuard mesh, tidak expose port publik

**Kegagalan khas:** firewall misconfig (rule terlalu permisif), port scan berhasil → service exposed, DDoS membuat service down, ARP spoofing di LAN, DNS hijacking.

**Referensi lintas:** [[attack-hierarchy-network-security|attack-hierarchy-network-security]] (perspektif penyerang), [[01_Library/defender/Web/ids-ips-waf-nsm-comparison.md|IDS-IPS-WAF-NSM comparison]].

---

### 3.3 L3 — Endpoint

**Objek:** workstation, laptop, server, perangkat mobile, IoT.

**Kontrol konkret:**
- EDR/XDR (CrowdStrike, SentinelOne, Defender for Endpoint) dengan behavioral detection
- Patch management terjadwal (CIS v8 Ctrl 7) — prioritaskan CVE kritis & actively exploited
- Application allowlisting (WDAC, AppLocker) — hanya aplikasi tepercaya
- Mobile Device Management (MDM) + containerized app
- Hardening OS: [[01_Library/defender/Infrastructure/linux-hardening-cis.md|linux-hardening-cis]], CIS Benchmarks

**Kegagalan khas:** malware via phishing/malvertising, ransomware encrypt local files, zero-day exploit (browser/kernel), supply-chain attack via software update.

**Catatan:** endpoint adalah layer yang paling sering menjadi titik masuk — perhatikan telemetri EDR dan behavioral detection (MITRE D3FEND: "Harden" + "Detect").

---

### 3.4 L4 — Application / Web

**Objek:** aplikasi web, API, microservice, mobile app backend.

**Kontrol konkret:**
- OWASP ASVS v4.0 Level 1-3 verification; SDLC security (SAST, DAST, SCA)
- WAF (ModSecurity, Cloudflare WAF, atau [[01_Library/defender/Web/waf-ml-anomaly-detection.md|WAF ML anomaly detection]])
- Input validation + output encoding (anti SQLi, XSS, SSTI, XXE)
- Runtime Application Self-Protection (RASP) untuk aplikasi kritis
- API security: rate limiting, authN/authZ yang benar, OWASP API Top 10
- Secure headers (CSP, HSTS, X-Frame-Options), cookie flags (HttpOnly, Secure, SameSite)

**Kegagalan khas:** SQL injection, XSS, SSRF ([[01_Library/defender/Web/ssrf-defense-hardening-playbook.md|SSRF defense]]), broken access control (IDOR), insecure deserialization, dependency vulnerability (log4shell).

**Referensi lintas:** [[attack-hierarchy-waf-reverse-proxy|attack-hierarchy-waf-reverse-proxy]], [[01_Library/attacker/Web/attack-web-hacking-exploitation.md|web hacking exploitation]].

---

### 3.5 L5 — Data

**Objek:** database, file share, backup, secrets/credential, data transaksi.

**Kontrol konkret:**
- Encryption at rest (disk, DB, backup) + encryption in transit (TLS 1.2+)
- DLP (Data Loss Prevention) untuk PII/kartu kredit/kode sumber
- Backup 3-2-1: 3 salinan, 2 media berbeda, 1 offsite/offline — + backup immutability
- Secrets management: Vault/HashiCorp, AWS Secrets Manager, SOPS; jangan hardcode
- Data classification & retention policy (ISO 27001 A.8, NIST 800-53 SC)

**Kegagalan khas:** ransomware meng-encrypt backup yang tidak immutabale, data exfiltration via DNS tunnel/covert channel, secret ter-commit ke git, database tidak ter-encrypt di backup.

**Catatan:** Backup yang benar (offline/immutable) adalah penyelamat utama saat ransomware — uji restore secara berkala.

---

### 3.6 L6 — Identity & Access

**Objek:** user, admin, service account, API key, session.

**Kontrol konkret:**
- MFA wajib untuk semua akses (terutama admin & remote) — NIST 800-63 AAL2+
- SSO/federated identity (OIDC/SAML) + conditional access (IP, device, risk)
- PAM (Privileged Access Management) — jump host, session recording, vaulted creds
- RBAC/ABAC dengan least privilege; review berkala
- Service account hygiene: rotasi, scope minimal, no shared account

**Kegagalan khas:** credential stuffing (password reuse), phishing MFA fatigue, privilege escalation (mis. AD misconfiguration), service account dengan hak berlebihan, Golden Ticket (AD).

**Referensi lintas:** [[attack-hierarchy-identity-trust|attack-hierarchy-identity-trust]], [[01_Library/attacker/IAM/attack-ad-windows.md|attack-ad-windows]].

---

### 3.7 L7 — Cloud / Infrastructure

**Objek:** IaaS (AWS/GCP/Azure), PaaS, container, Kubernetes, IaC.

**Kontrol konkret:**
- CSPM (Cloud Security Posture Management) — deteksi misconfig (S3 public, SG terbuka)
- IaC scanning (tfsec, Checkov, Snyk IaC) sebelum deploy; policy-as-code (OPA/CASB)
- Kubernetes: RBAC ketat, NetworkPolicy default-deny, Pod Security Standards, image signing
- Container: base image minimal & di-scan, non-root, read-only FS, seccomp/apparmor
- Cloud trail logging + anomaly detection; budget alerts (anti crypto-mining)

**Kegagalan khas:** exposed S3 bucket, security group terlalu terbuka, container escape, kubeconfig leaked, IaC dengan hardcoded secret, cost fraud via crypto-mining.

---

### 3.8 L8 — Orchestration / SOC

**Objek:** SIEM, SOAR, threat intel, detection, incident response.

**Kontrol konkret:**
- SIEM (Wazuh, Splunk, Elastic) — log aggregation + correlation rules
- SOAR automation: enrichment otomatis, triage, playbook ([[01_Library/defender/Endpoint/soc-automation-playbook-dengan-soar.md|SOC automation dengan SOAR]])
- Detection engineering: Sigma rules, custom detection, MITRE ATT&CK mapping
- Threat intel feeds (STIX/TAXII, MISP) untuk enrichment IoC
- UEBA (User and Entity Behavior Analytics) untuk deteksi insider/anomaly
- IR playbook & tabletop exercise ([[01_Library/defender/Incident_Response/incident-response-framework.md|incident-response-framework]])

**Kegagalan khas:** alert fatigue (banyak false positive), deteksi lambat (dwell time panjang), runbook tidak diuji, log tidak lengkap (gap coverage), insider threat tidak terdeteksi.

---

### 3.9 L9 — Governance & Brand

**Objek:** kebijakan, compliance, awareness, vendor, komunikasi krisis.

**Kontrol konkret:**
- Security policy & standards (akses, password, incident) — ditinjau tahunan
- Security awareness training (phishing simulation) — NIST 800-50
- DR/BCP (Disaster Recovery & Business Continuity Plan) — diuji berkala
- Vendor risk management (third-party assessment)
- Crisis communication plan — siapa bicara ke publik/regulator saat breach
- Compliance: ISO 27001, SOC 2, GDPR, UU PDP Indonesia

**Kegagalan khas:** social engineering sukses (awareness lemah), pelaporan breach lambat (fines), reputasi rusak, vendor pihak ketiga jadi jalur masuk (SolarWinds), kebijakan ada tapi tidak dijalankan.

---

## 4. Peta Relasi Antar Layer (Defense-in-Depth Graph)

```
L9 Governance ─── mengatur ───→ L1..L8 (policy & audit)
    │
L8 SOC ─── memonitor ───→ L1..L7 (SIEM correlation across layers)
    │
L7 Cloud ─── menjalankan ───→ L3, L4, L5 (workload di cloud)
    │
L6 Identity ─── mengotorisasi ───→ L4, L5, L7 (akses ke app & data)
    │
L5 Data ─── dilindungi oleh ───→ L1..L4 (semua layer di depannya)
    │
L4 App ─── diakses lewat ───→ L2 (network) ─── L1 (edge/fisik)
```

**Prinsip operasional:**
1. **Setiap layer independen** — kegagalan satu layer tidak menggagalkan keseluruhan
2. **Deteksi & response** harus aktif di semua layer (bukan hanya pasif mencegah)
3. **Monitoring silang**: anomali di L3 (endpoint) bisa jadi indikasi serangan yang mulai di L2

---

## 5. Alignment Framework (Referensi Cepat)

| Layer | NIST CSF 2.0 | CISA ZTMM | CIS v8 | NIST 800-53 | OWASP |
|-------|--------------|-----------|--------|-------------|-------|
| L1 | Protect | — | Ctrl 12 (Defense) | PE, CP | — |
| L2 | Protect, Detect | Network | Ctrl 4, 13 | AC, SC | — |
| L3 | Protect, Detect | Device | Ctrl 2, 3, 4, 7 | CM, SI | — |
| L4 | Protect, Detect | App Workload | Ctrl 16 | SA, SI | ASVS semua |
| L5 | Protect | Data | Ctrl 3, 11 | SC, CP | — |
| L6 | Protect | Identity | Ctrl 5, 6 | AC, IA | ASVS V2, V4 |
| L7 | Protect, Detect | App Workload, Data | Ctrl 4, 16 | CA, CM | — |
| L8 | Detect, Respond | — | Ctrl 8, 13 | AU, IR | — |
| L9 | Govern, Identify | — | Ctrl 14, 17 | AT, PM | — |

---

## 6. Checklist Implementasi (Actionable)

**L1:** [ ] Console access pakai MFA · [ ] Disk encryption aktif (LUKS/BitLocker/FileVault) · [ ] Laptop lock saat pergi

**L2:** [ ] Firewall deny-by-default (uji egress) · [ ] Segmentation VLAN (IoT terpisah) · [ ] ZTNA (Tailscale/WireGuard) — tidak expose port · [ ] DNS over HTTPS

**L3:** [ ] EDR/XDR aktif + telemetri masuk SIEM · [ ] Auto-patch CVE kritis ≤ 7 hari · [ ] AppLocker/allowlist di server penting

**L4:** [ ] SAST/DAST di pipeline · [ ] WAF di depan app publik · [ ] Secure headers + cookie flags · [ ] Dependency scan (SCA) tiap release

**L5:** [ ] Enkripsi at rest untuk DB & backup · [ ] Backup 3-2-1 + uji restore bulanan · [ ] Secrets di Vault (bukan .env di git) · [ ] DLP untuk PII

**L6:** [ ] MFA semua admin · [ ] PAM untuk akses privileged · [ ] RBAC least privilege review 3 bulan · [ ] Service account rotasi

**L7:** [ ] CSPM aktif (misconfig alert) · [ ] IaC scan sebelum apply · [ ] K8s NetworkPolicy default-deny · [ ] Cloud trail → SIEM

**L8:** [ ] SIEM correlation rules aktif · [ ] Sigma/custom detection ≥ 10 rules · [ ] IR playbook diuji (tabletop) · [ ] Threat intel enrichment

**L9:** [ ] Awareness training 2x/tahun · [ ] DR/BCP diuji 1x/tahun · [ ] Vendor risk assessment · [ ] Crisis comm plan tertulis

---

## 7. Hubungan dengan Catatan Lain

- **Attack counterpart:** [[00_Atlas/attacker/attack-cybersecurity-defense-architecture.md|Attack Perspective — bagaimana menembus tiap layer]] (red team)
- **Deepdive defense di Library:** [[01_Library/defender/_index.md|Defender Library]]
- **Hierarchy terkait:** [[00_Atlas/hierarchy-search.md|hierarchy-search]] · [[00_Atlas/hierarchy-ctf-competition-framework.md|CTF framework]] · [[00_Atlas/hierarchy-failure-modes-resilience.md|failure modes & resilience]] · [[00_Atlas/hierarchy-it-support-model.md|IT support model]] · [[00_Atlas/hierarchy-infrastructure-evolution.md|infrastructure evolution]]
- **Serangan terhadap defense:** [[attack-hierarchy-network-security|attack-hierarchy-network-security]] · [[attack-hierarchy-endpoint-security|attack-hierarchy-endpoint-security]]

---

*Dokumen ini adalah bagian dari 00_Atlas (peta pengetahuan). Deepdive implementasi ada di 01_Library/{attacker,defender}. Dibuat 2026-08-14, status complete.*

audited
---
