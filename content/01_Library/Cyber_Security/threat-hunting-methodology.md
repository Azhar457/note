---
title: Threat Hunting Methodology
tags:
  - threat-hunting
  - detection
  - hypothesis
  - proactive-security
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Threat hunting adalah proaktif mencari threat sebelum alarm berbunyi.

## Hunting Loop

```
Hypothesis -> Data Collection -> Analysis -> TTP Match -> Automation
    ^                                                        |
    +--------------------------------------------------------+
```

## Data Sources

- Network logs (Zeek, NetFlow, DNS)
- Endpoint logs (Sysmon, EDR, Windows Event Log)
- Cloud logs (CloudTrail, Azure Activity Log)
- Identity logs (AD, Okta, VPN)

## Detection Techniques

- Anomaly detection (baseline + deviation)
- TTP mapping (MITRE ATT&CK)
- IoA (Indicator of Attack) vs IoC
- Chain analysis (correlate multiple events)
