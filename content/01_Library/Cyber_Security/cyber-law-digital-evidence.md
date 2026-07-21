---
title: Cyber Law & Digital Evidence — Legal Frameworks for Security Operations
tags:
  - cyber-law
  - digital-evidence
  - chain-of-custody
  - gdpr
  - legal
  - forensics
created: "2026-07-19"
updated: "2026-07-19"
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Forensics tanpa hukum = bukti yang gak bisa dipakai di pengadilan. Catatan ini melengkapi [[incident-response-framework]] dan [[forensic-imaging-analysis]] dengan dimensi legal — chain of custody, admissibility, dan kerangka hukum yang bikin forensics lo "court-ready".
>
> **Domain:** Cyber Security / Legal
> **Tags:** #cyber-law #digital-evidence #chain-of-custody #gdpr #forensics

## 1. Digital Evidence Lifecycle

```
Collection → Preservation → Analysis → Presentation
    ↑            ↑            ↑            ↑
 1. Legal     2. Chain     3. Expert    4. Court
 Authority    of Custody   Report       Testimony
```

### 1.1 Chain of Custody

```python
# Chain of custody record — every forensic investigator must fill
CHAIN_OF_CUSTODY = {
    "case_id": "IR-2026-001",
    "evidence_id": "EVD-001",
    "description": "Samsung SSD 870 EVO 500GB - suspect laptop",
    "acquisition": {
        "date": "2026-07-15T14:22:00+07:00",
        "method": "dd bitstream (write-blocker Tableau T8)",
        "hash_sha256": "a1b2c3d4e5f6...",
        "investigator": "Azhar Muttaqien",
        "witness": "Security Team Lead"
    },
    "transfers": [
        {
            "from": "Scene of Crime",
            "to": "Forensics Lab",
            "date": "2026-07-15T15:30:00+07:00",
            "reason": "Chain transfer to lab",
            "signature": "John Doe (Scene) / Jane Smith (Lab)"
        }
    ]
}
```

## 2. Legal Frameworks

| Law                     | Region    | Key Provisions                                         | Impact on IR                              |
| ----------------------- | --------- | ------------------------------------------------------ | ----------------------------------------- |
| **GDPR**                | EU        | Data breach notification within 72h, right to deletion | Must notify — limits investigation window |
| **UU ITE**              | Indonesia | Articles 27-37: illegal access, data theft, defamation | Criminal law basis for cyber crime        |
| **CFAA**                | US        | Computer Fraud and Abuse Act — "authorized access"     | Defines hacking as federal crime          |
| **Data Protection Act** | UK        | Similar to GDPR post-Brexit                            | Same constraints                          |
| **PCI DSS**             | Global    | Cardholder data breach handling                        | Mandatory forensic investigation          |

---

### 📚 Referensi

1. NIST SP 800-86: Guide to Integrating Forensic Techniques into Incident Response
2. ISO 27037: Digital evidence handling guidelines
3. "Digital Forensics and Cyber Law" — ACME publications
