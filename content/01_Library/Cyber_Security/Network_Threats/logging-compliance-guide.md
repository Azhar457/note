---
title: Logging Compliance Guide — Indonesia Regulations
tags:
  - logging
  - compliance
  - indonesia
  - retention
  - siem
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Panduan logging compliance sesuai regulasi Indonesia.

## Regulation Requirements

| Regulation            | Log Retention     | Scope                |
| --------------------- | ----------------- | -------------------- |
| UU ITE                | 5 years           | Electronic evidence  |
| Permenkominfo 20/2016 | 90 days (minimal) | Internet access log  |
| PDP Law (UU 27/2022)  | Sesuai tujuan     | Personal data access |
| Financial sector      | 10 years          | Banking transactions |

## Implementation

- Collect: syslog, Windows events, firewall, proxy
- Store: hot (30d) / warm (90d) / cold (1yr) / archive (5yr+)
- Protect: WORM storage, integrity hash, access control
