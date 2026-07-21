---
title: IPv6 Migration — Security Implications
tags:
  - ipv6
  - migration
  - dual-stack
  - networking
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> IPv6 migration sering mengaktifkan IPv6 tanpa monitoring.

## Migration Mechanisms

- Dual-stack: both IPv4 + IPv6
- 6to4, Teredo: automatic tunneling (insecure!)
- NAT64/DNS64: IPv6-only to IPv4

## Security Issues

- IPv6 enabled but unmonitored -> blind spot
- Teredo/6to4 bypass firewalls
- ICMPv6 abuse (NDP spoofing)
- Privacy extensions (temporary addresses)

## Best Practices

1. Disable unnecessary tunnels
2. Deploy IPv6 firewall rules
3. Monitor RA/NDP for rogue router
