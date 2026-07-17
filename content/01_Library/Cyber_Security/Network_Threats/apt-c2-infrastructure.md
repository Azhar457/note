---
title: "APT C2 Infrastructure"
tags:
  - apt
  - c2
  - red-team
  - command-control
aliases:
  - "apt-c2-infrastructure"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> C2 infrastructure untuk APT-level red team. Melengkapi c2-server-fix dan advanced-red-team-infrastructure-fix.

## Tiers

| Level          | Evasion                | Protocol         | Hosting                |
| -------------- | ---------------------- | ---------------- | ---------------------- |
| L1 - Basic     | None                   | HTTP/S           | VPS (public)           |
| L2 - Stealth   | Domain fronting, CDN   | HTTPS, WebSocket | CloudFront, CF Workers |
| L3 - Modular   | Redirector chain       | HTTPS + DNS      | Multi-region VPS       |
| L4 - APT-grade | CDN + redirector + ROT | Multi-protocol   | Compromised legit      |
