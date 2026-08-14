---
title: Attack Perspective — Infrastructure (Red Team)
tags:
- attack
- red-team
- infrastructure
- proxy
- redirector
- dns
- tls
- vps
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Infrastructure — Perspektif Penyerang

> Infrastructure = lapisan yang mendukung operasi (C2, redirector, VPN, DNS). Red team: VPS/redirector setup, DNS strategy, TLS cert, email (phishing infra), takedown resistance.

## 1. Infrastructure Components

| Komponen | Fungsi | Red Team Setup | Evasion | Detection Risk |
|----------|--------|---------------|---------|----------------|
| **VPS** | C2 server, redirector | Multiple VPS (different provider) | Geo-distributed | Provider abuse report |
| **Redirector** | Proxy target → C2 | Nginx/Apache reverse proxy | Legit web server | Redirector IP → C2 discovery |
| **Domain** | C2 domain, phishing domain | Alter-nate TLD, lookalike | Legit registration | Domain reputation |
| **DNS** | C2 resolution, mail (SPF/DKIM) | Custom NS, fast-flux | Fast-flux = rotating IP | Passive DNS detect |
| **TLS Cert** | HTTPS C2, cert pinning | Let's Encrypt (free) | Valid cert = legit | Cert transparency log |
| **Email** | Phishing delivery | SMTP relay, lookalike domain | SPF/DKIM valid | Email gateway detect |
| **CDN** | Domain fronting | Cloudflare/Azure edge | CDN = legit traffic | CDN abuse report |
| **Fast-Flux** | Rotating IP → takedown resist | DNS A record rotate | IP = always changing | Flux detect = heuristics |

## 2. C2 Infrastructure Chain

```
Domain: Register c2 domain (lookalike / random TLD)
    ↓
VPS: Buy VPS (different provider, anonymous payment)
    ↓
DNS: Point domain → VPS IP (or CDN)
    ↓
Redirector:
  ├── Nginx → proxy /c2 path → C2 server
  ├── Response: legit 404 for non-C2 path
  └→ C2 hidden behind legit-looking web
    ↓
TLS: Let's Encrypt cert → HTTPS + valid cert
    ↓
Implant: Beacon → domain → redirector → C2
    ↓
Takedown Resistance:
  ├── Fast-flux: DNS rotate → multiple IP
  ├── Backup domain: second C2 domain
  ├── Geo-distributed: VPS multi-region
  └→ Re-deploy: script → new VPS → new domain
```

## 3. Email Phishing Infra

```
Domain: Lookalike domain (micros0ft.com, paypa1.com)
    ↓
Email: SMTP relay (mailgun, sendgrid — easy) atau VPS
    ↓
Auth: SPF + DKIM + DMARC (valid) → deliverability
    ↓
Template: Legit-looking (logo, signature)
    ↓
Send: Targeted (small volume) → below gateway threshold
    ↓
Landing: Redirector → credential page / malicious doc
    ↓
Evasion: SPF/DKIM valid → email gateway trust
```

## 4. Fast-Flux

```
DNS: A record → rotate IP (5-min TTL)
    ↓
Proxy Chain: Multiple compromised/proxy node → round-robin
    ↓
Result: C2 IP = selalu berubah
    ↓
Detection:
  ├── Passive DNS: history → flux pattern
  ├── Resolution: different IP per query
  └→ Mitigation: flux detect = heuristic → partial
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Nginx** | Redirector / proxy |
| **Let's Encrypt (certbot)** | TLS cert |
| **Cloudflare** | CDN front / domain fronting |
| **terraform** | infra automation (re-deploy) |
| **Docker** | C2 server container (portable) |
| **Ansible** | VPS auto-config |
| **Cobalt Strike / Sliver** | C2 server |

## 6. Referensi
- Cobalt Strike infra — https://blog.cobaltstrike.com/...
- Redirector setup — https://posts.specterops.io/...
- Fast-flux — https://en.wikipedia.org/wiki/Fast_flux
- Passive DNS — https://securitytrails.com/
- Domain fronting — https://www.bamsoftware.com/papers/fronting/