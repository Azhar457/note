---
title: Attack Perspective — Framework Crosswalk (Red Team Mapping)
tags:
- attack
- red-team
- crosswalk
- mitre
- nist
- cis
- owasp
- framework
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Framework Crosswalk — Perspektif Penyerang

> Crosswalk = mapping framework (MITRE ↔ NIST ↔ CIS ↔ OWASP). Red team pakai crosswalk untuk: tahu apa yang defender ukur → target gap. Setiap kontrol punya bypass.

## 1. Framework Mapping (Red Team View)

| Kontrol (Defender) | Framework | Red Team Target | Bypass |
|-------------------|-----------|-----------------|--------|
| **Identify** (asset/risk) | NIST ID | Asset blind spot | Shadow asset, unmanaged device |
| **Protect** (access/data) | NIST PR | IAM bypass | AiTM, session theft |
| **Detect** (monitor) | NIST DE | Detection gap | Rule bypass, log tamper |
| **Respond** (incident) | NIST RS | Response confusion | Noise injection, decoy |
| **Recover** (restore) | NIST RC | Recovery fail | Backup destroy, re-infection |

## 2. MITRE ATT&CK ↔ NIST Mapping (Gap)

| NIST Function | ATT&CK Tactics | Red Team Exploit Gap |
|--------------|----------------|---------------------|
| ID (Identify) | Recon | Shadow asset, API gap |
| PR (Protect) | Initial Access, Execution, Persistence | AiTM, direct syscall |
| DE (Detect) | Discovery, Lateral, Command | Unmapped sub-technique |
| RS (Respond) | Exfil, Impact | Noise, decoy |

## 3. CIS Control ↔ Attack

| CIS Control | Attack Bypass |
|-------------|---------------|
| Inventory (1-2) | Shadow IT |
| Hardening (4-5) | Misconfig, legacy |
| Access (6-8) | AiTM, MFA bypass |
| Malware defense (10) | Custom packer |
| Monitoring (12-13) | Log tamper |
| Incident response (17) | Noise injection |

## 4. Red Team Use

```
Defender Framework → Red Team Plan:
  ├── NIST DE (detect) → test detect: bypass trivially?
  ├── CIS 6-8 (access) → test: AiTM bypass MFA?
  ├── MITRE TTP → map detection rule → find gap
  └→ Result: report gap → improve control
```

## 5. 📂 Navigasi Cepat — Library Attack

> File deepdive attack kini tersentralisasi di **`Note/Attacker/`** (red team) dan **`Note/Defender/`** (blue team). Berikut peta per kategori:

| Kategori | Attack (Attacker/) | Defense (Defender/) |
|----------|-------------------|---------------------|
| **Web** | [[attack-waf-evasion-deepdive]], [[attack-web-hacking-exploitation]], [[attack-web-api-ssrf]] | [[ssti-xxe-defense-playbook]], [[ssrf-defense-hardening-playbook]] |
| **IAM** | [[attack-ad-windows]], [[attack-cloud-iam]] | — |
| **Network** | [[attack-apt-c2-dns]], [[attack-covert-channel]], [[attack-zero-trust]] | — |
| **Endpoint** | [[attack-ebpf-kernel]], [[attack-malware-re]], [[attack-exploit-development]] | — |
| **AI/ML** | [[attack-llm-security-red-teaming]], [[attack-adversarial-ml]] | [[agent-anti-jailbreak-defense-identity]] |
| **Supply Chain** | [[attack-supply-chain-deepdive]] | — |
| **Mobile** | [[attack-mobile-security]] | — |
| **Crypto** | [[attack-quantum-pqc]], [[attack-blockchain]] | — |
| **Infrastructure** | [[attack-infrastructure]], [[attack-devops-cicd]], [[attack-container-k8s]] | [[linux-hardening-cis]], [[server-hardening-playbook]] |
| **Forensics** | [[attack-data-forensics]] | — |
| **OT/ICS** | [[attack-ics-scada]], [[attack-automotive-can-bus]] | — |
| **Hardware** | [[attack-firmware-re]], [[attack-side-channel]] | — |

- **Index folder**: [[01_Library/attacker/_index|🗡️ Attacker Library]] · [[01_Library/defender/_index|🛡️ Defender Library]]
- **Peta defense-in-depth**: [[00_Atlas/hierarchy-cybersecurity-defense-architecture|9-layer defense architecture]]

## 6. Referensi
- MITRE ATT&CK — https://attack.mitre.org/
- NIST CSF — https://www.nist.gov/cyberframework
- CIS Controls — https://www.cisecurity.org/controls/
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- MITRE Engage — https://engage.mitre.org/
---

audited
---
