---
title: It Domain Hierarchy
tags:
  - atlas
created: 2026-07-01
updated: 2026-07-01
status: complete
cssclasses:
  - wide-table
  
---

# 🗺️ IT DOMAIN HIERARCHY — Dari Big Picture Sampai Task Spesifik

> **Filosofi:** Sebelum coding, pahami dulu di mana posisi Anda di peta besar. Ini adalah GPS untuk karir dan project IT/Cybersecurity.

---

## Level 0: INFORMATION TECHNOLOGY (Root)

```
INFORMATION TECHNOLOGY (IT)
│
├── 1. SOFTWARE DEVELOPMENT
│   ├── Web Development
│   ├── Mobile Development
│   ├── Desktop Development
│   ├── Game Development
│   ├── Embedded Systems
│   └── DevOps / SRE
│
├── 2. INFRASTRUCTURE & NETWORKING
│   ├── Network Engineering
│   ├── System Administration
│   ├── Cloud Computing
│   ├── Database Administration
│   └── Virtualization
│
├── 3. DATA & ANALYTICS
│   ├── Data Science
│   ├── Data Engineering
│   ├── Business Intelligence
│   └── Machine Learning / AI
│
├── 4. CYBERSECURITY 🟊
│   ├── Offensive Security (Red Team)
│   ├── Defensive Security (Blue Team)
│   ├── Security Operations (SOC)
│   ├── Governance, Risk & Compliance (GRC)
│   └── Security Architecture
│
├── 5. IT MANAGEMENT
│   ├── IT Project Management
│   ├── IT Service Management (ITIL)
│   └── Enterprise Architecture
│
└── 6. EMERGING TECH
    ├── Blockchain
    ├── IoT (Internet of Things)
    ├── Quantum Computing
    └── Extended Reality (AR/VR/MR)
```

---

## Level 1: CYBERSECURITY — 5 Pilar Utama

```
CYBERSECURITY
│
├─ 1.1 OFFENSIVE SECURITY (Red Team) — "Break things to fix them"
│   ├── Penetration Testing
│   ├── Vulnerability Assessment
│   ├── Red Team Operations
│   ├── Social Engineering
│   ├── Physical Security Testing
│   └── Exploit Development
│
├─ 1.2 DEFENSIVE SECURITY (Blue Team) — "Protect and detect"
│   ├── Endpoint Security (EDR/XDR)
│   ├── Network Security (Firewall/IDS/IPS)
│   ├── Application Security (WAF/AppSec)
│   ├── Data Security (DLP/Encryption)
│   ├── Identity & Access Management (IAM)
│   └── Cloud Security (CASB/CSPM)
│
├─ 1.3 SECURITY OPERATIONS (SOC) — "Monitor and respond"
│   ├── Security Monitoring (SIEM)
│   ├── Incident Response (IR)
│   ├── Threat Hunting
│   ├── Threat Intelligence (CTI)
│   ├── Digital Forensics
│   └── Security Automation (SOAR)
│
├─ 1.4 GOVERNANCE, RISK & COMPLIANCE (GRC) — "Policy and audit"
│   ├── Security Governance
│   ├── Risk Management
│   ├── Compliance (ISO 27001, SOC 2, PCI-DSS)
│   ├── Security Awareness Training
│   └── Third-Party Risk Management
│
└─ 1.5 SECURITY ARCHITECTURE — "Design secure systems"
    ├── Security Architecture Design
    ├── Zero Trust Architecture
    ├── Secure Network Design
    ├── Secure Software Development (SDLC)
    └── Cryptography Implementation
```

---

## Level 2: BLUE TEAM — Sub-Domain Detail

```
BLUE TEAM (Defensive Security)
│
├─ 2.1 ENDPOINT SECURITY
│   ├── EDR (Endpoint Detection & Response)
│   │   ├── Real-time process monitoring
│   │   ├── Behavioral analysis
│   │   ├── Memory scanning
│   │   └── Automated response
│   │
│   ├── Antivirus / Anti-Malware
│   │   ├── Signature-based detection
│   │   ├── Heuristic analysis
│   │   └── Sandboxing
│   │
│   ├── Host Firewall
│   │   ├── Inbound/outbound filtering
│   │   ├── Application control
│   │   └── Port management
│   │
│   └── Device Control
│       ├── USB blocking
│       ├── Peripheral management
│       └── BYOD policy
│
├─ 2.2 NETWORK SECURITY
│   ├── Firewall
│   │   ├── Packet filter (Layer 3/4)
│   │   ├── Stateful inspection
│   │   ├── Application layer (Layer 7 / WAF)
│   │   └── Next-Gen Firewall (NGFW)
│   │
│   ├── IDS/IPS
│   │   ├── Signature-based (Snort/Suricata)
│   │   ├── Anomaly-based
│   │   └── Protocol analysis
│   │
│   ├── VPN
│   │   ├── Site-to-site
│   │   ├── Remote access
│   │   └── Zero Trust Network Access
│   │
│   ├── Network Segmentation
│   │   ├── VLAN
│   │   ├── Micro-segmentation
│   │   └── DMZ design
│   │
│   └── DDoS Protection
│       ├── Rate limiting
│       ├── SYN cookie
│       ├── Scrubbing center
│       └── CDN-based protection
│
├─ 2.3 APPLICATION SECURITY
│   ├── WAF (Web Application Firewall)
│   │   ├── SQL Injection protection
│   │   ├── XSS protection
│   │   ├── CSRF protection
│   │   ├── Bot detection
│   │   └── API security
│   │
│   ├── SAST (Static Analysis)
│   │   ├── Source code scanning
│   │   ├── Dependency check
│   │   └── Secret detection
│   │
│   ├── DAST (Dynamic Analysis)
│   │   ├── Web app scanning
│   │   ├── API testing
│   │   └── Fuzzing
│   │
│   └── RASP (Runtime Protection)
│       ├── In-app monitoring
│       ├── Behavior blocking
│       └── Virtual patching
│
├─ 2.4 DATA SECURITY
│   ├── Encryption
│   │   ├── At-rest (disk/database)
│   │   ├── In-transit (TLS/mTLS)
│   │   └── In-use (confidential computing)
│   │
│   ├── DLP (Data Loss Prevention)
│   │   ├── Endpoint DLP
│   │   ├── Network DLP
│   │   └── Cloud DLP
│   │
│   ├── Key Management
│   │   ├── HSM (Hardware Security Module)
│   │   ├── KMS (Key Management Service)
│   │   └── PKI infrastructure
│   │
│   └── Backup & Recovery
│       ├── Immutable backup
│       ├── Air-gapped backup
│       └── Ransomware recovery
│
└─ 2.5 IDENTITY & ACCESS MANAGEMENT
    ├── Authentication
    │   ├── Password policy
    │   ├── MFA (Multi-Factor Auth)
    │   ├── Biometric
    │   └── Passwordless (FIDO2/WebAuthn)
    │
    ├── Authorization
    │   ├── RBAC (Role-Based)
    │   ├── ABAC (Attribute-Based)
    │   └── PBAC (Policy-Based)
    │
    ├── SSO (Single Sign-On)
    │   ├── SAML
    │   ├── OAuth 2.0 / OIDC
    │   └── Kerberos
    │
    └── PAM (Privileged Access Management)
        ├── Privileged account vault
        ├── Session recording
        └── Just-in-Time access
```

---

## Level 3: SOC — Sub-Domain Detail

```
SOC (Security Operations Center)
│
├─ 3.1 SECURITY MONITORING
│   ├── SIEM (Security Information & Event Management)
│   │   ├── Log aggregation (syslog, Windows Event, cloud)
│   │   ├── Correlation rules
│   │   ├── Alert generation
│   │   ├── Dashboard & reporting
│   │   └── MITRE ATT&CK mapping
│   │
│   ├── Log Management
│   │   ├── Centralized logging
│   │   ├── Log retention policy
│   │   ├── Log parsing/normalization
│   │   └── Log integrity verification
│   │
│   └── UEBA (User & Entity Behavior Analytics)
│       ├── Baseline establishment
│       ├── Anomaly detection
│       ├── Insider threat detection
│       └── Account compromise detection
│
├─ 3.2 INCIDENT RESPONSE
│   ├── Preparation
│   │   ├── IR plan & playbook
│   │   ├── Contact list & escalation
│   │   └── Tool readiness
│   │
│   ├── Detection & Analysis
│   │   ├── Alert triage
│   │   ├── Scope assessment
│   │   ├── Evidence collection
│   │   └── Root cause analysis
│   │
│   ├── Containment
│   │   ├── Short-term (isolate)
│   │   ├── Long-term (segment)
│   │   └── Evidence preservation
│   │
│   ├── Eradication
│   │   ├── Malware removal
│   │   ├── Account cleanup
│   │   └── Vulnerability patching
│   │
│   ├── Recovery
│   │   ├── System restoration
│   │   ├── Service validation
│   │   └── Monitoring enhancement
│   │
│   └── Post-Incident
│       ├── Lessons learned
│       ├── Report documentation
│       └── Process improvement
│
├─ 3.3 THREAT HUNTING
│   ├── Hypothesis-driven
│   │   ├── MITRE ATT&CK technique
│   │   ├── Threat intel indicator
│   │   └── Behavioral anomaly
│   │
│   ├── IOC-based
│   │   ├── Known bad IP/domain/hash
│   │   ├── Threat intel feed
│   │   └── Historical correlation
│   │
│   └── TTP-based
│       ├── Lateral movement pattern
│       ├── Persistence mechanism
│       └── Data staging behavior
│
├─ 3.4 THREAT INTELLIGENCE (CTI)
│   ├── Strategic Intel
│   │   ├── Threat actor profiling
│   │   ├── Geopolitical analysis
│   │   └── Industry-specific threats
│   │
│   ├── Tactical Intel
│   │   ├── MITRE ATT&CK mapping
│   │   ├── TTP documentation
│   │   └── Campaign tracking
│   │
│   ├── Operational Intel
│   │   ├── IOC management
│   │   ├── Feed curation
│   │   └── Detection rule creation
│   │
│   └── Technical Intel
│       ├── Malware analysis
│       ├── Vulnerability research
│       └── Exploit analysis
│
└─ 3.5 SECURITY AUTOMATION (SOAR)
    ├── Playbook Automation
    │   ├── Alert enrichment
    │   ├── Ticket creation
    │   ├── Notification dispatch
    │   └── Containment action
    │
    ├── Orchestration
    │   ├── Multi-tool integration
    │   ├── API chaining
    │   └── Workflow engine
    │
    └── Case Management
        ├── Incident tracking
        ├── Evidence management
        └── Reporting automation
```

---

## Level 4: Career Path Mapping

```
KARIR CYBERSECURITY

ENTRY LEVEL (0-2 tahun)
├── SOC Tier 1 Analyst
│   └── Skill: Alert triage, basic investigation
│
├── Junior Security Engineer
│   └── Skill: Tool deployment, basic config
│
└── IT Support → Security transition
    └── Skill: System admin, networking

MID LEVEL (2-5 tahun)
├── SOC Tier 2 Analyst / Incident Responder
│   └── Skill: Deep investigation, containment
│
├── Security Engineer
│   └── Skill: Tool development, automation
│
├── Threat Hunter
│   └── Skill: Proactive detection, hypothesis
│
└── Detection Engineer
    └── Skill: SIEM rules, detection logic

SENIOR LEVEL (5+ tahun)
├── Security Architect
│   └── Skill: Design defense architecture
│
├── Red Team Operator
│   └── Skill: Attack simulation, evasion
│
├── Security Researcher
│   └── Skill: Vulnerability research, exploit dev
│
└── CISO / Security Manager
    └── Skill: Strategy, governance, leadership
```

---

## Level 5: Tech Stack per Domain

```
BAGIAN MANA YANG COCOK DENGAN SKILL ANDA?

┌──────────────────────────────────────────────────────────────────┐
│  ANDA SUKA...          →  COBA DOMAIN...       →  BAHASA         │
├──────────────────────────────────────────────────────────────────┤
│  Low-level, kernel     →  Endpoint Security    →  C/C++          │
│  Memory safety         →  Modern EDR           →  Rust           │
│  Network packet        →  Network Security     →  C/Rust         │
│  Web app hacking       →  AppSec / WAF         →  Go/Rust        │
│  Log analysis          →  SOC / SIEM           →  Python         │
│  Automation            →  SOAR / DevSecOps     →  Python         │
│  Data / ML             →  Threat Intel / UEBA  →  Python         │
│  Cloud infrastructure  →  Cloud Security       →  Go/Terraform   │
│  Policy / audit        →  GRC                  →  Excel/GRC tools│
│  Social engineering    →  Red Team / Pentest   →  Python/Bash    │
│  Reverse engineering   →  Malware Analysis     →  C/ASM/Python   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Level 6: Decision Tree — "Saya Mau Fokus ke Mana?"

```
START: Anda di IT, tertarik dengan Cybersecurity
│
├─ Apakah Anda suka coding? ──┐
│                             │
│         YA                  │       TIDAK
│         │                   │         │
│         ▼                   │         ▼
│  ┌──────────────┐           │  ┌──────────────┐
│  │ Technical    │           │  │ Non-Technical│
│  │ Track        │           │  │ Track        │
│  └──────┬───────┘           │  └──────┬───────┘
│         │                   │         │
│         ▼                   │         ▼
│  Apakah suka "break"        │  Apakah suka policy?
│  atau "defend"?             │                     
│                             │                      
│  ┌────────┐  ┌────────┐     │           YA                 
│  │ BREAK  │  │ DEFEND │     │            │               Tidak
│  │ (Attack)│  │(Protect)│   │            ▼                 │
│  └───┬────┘  └───┬────┘     │  ┌─────────────────┐         │
│      │           │          │  │ GRC / Compliance│         ▼
│      ▼           ▼          │  │ • ISO 27001     │  ┌──────────────┐
│  ┌────────┐  ┌────────────┐ │  │ • SOC 2         │  │ Security Ops │
│  │Red Team│  │Blue Team   │ │  │ • Risk Assess   │  │ Management   │
│  │Pentest │  │SOC/EDR     │ │  │ • Audit         │  │ • SOC Manager│
│  │Exploit │  │WAF/Firewall│ │  └─────────────────┘  └──────────────┘
│  │Dev     │  │SIEM        │ │                     
│  └────────┘  └────────────┘ │                     
└─────────────────────────────┴───────────────────────────────────────┘
```

---

## 🎯 Kesimpulan: Peta Lengkap

```
IT (Root)
└── Cybersecurity
    ├── Offensive (Red Team)
    ├── Defensive (Blue Team)
    │   ├── Endpoint Security
    │   ├── Network Security
    │   ├── Application Security
    │   ├── Data Security
    │   └── Identity & Access
    ├── SOC Operations
    │   ├── SIEM
    │   ├── Incident Response
    │   ├── Threat Hunting
    │   └── Threat Intel
    ├── GRC
    └── Security Architecture
```

---

## 📋 Action Items untuk Belajar & Berkarir

| # | Action | Timeline | Domain |
|---|--------|----------|--------|
| 1 | Bangun project portofolio pertamamu | 3 bulan | Hands-on Practice |
| 2 | Tulis blog teknis tentang apa yang dipelajari | Rutin | Technical Writing |
| 3 | Berkontribusi di project open source security | Paralel | Community |
| 4 | Pelajari script automation (Python/Bash) | Menengah | Automation |
| 5 | Ambil sertifikasi dasar (e.g., CompTIA Security+) | Tahap Awal | Certification |
| 6 | Ambil sertifikasi spesialisasi (e.g., Linux/Cloud/Pentest) | Tahap Lanjut | Specialization |
| 7 | Mulai melamar sebagai Junior Security Engineer / SOC Analyst | Setelah siap | Career |
| 8 | Tingkatkan skill & bangun project lebih kompleks | Berkelanjutan | Growth |

---

## 🔗 Lihat Juga

| Catatan | Hubungan |
|---|---|
| [[hierarchy-it-support-model]] | Level 1–5 model dukungan IT (self-service → ITSM/ITIL) — melengkapi sub-domain IT Management yang di sini masih buram |
| [[infrastructure-administrator]] | Eksekusi teknis dari sisi administrator |

---

*Document Version: 1.0*  
*Last Updated: 2026-06-16*  
*Purpose: Domain mapping untuk project dan karir cybersecurity*

audited
---
