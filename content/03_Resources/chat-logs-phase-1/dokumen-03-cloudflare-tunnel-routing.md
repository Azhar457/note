---
title: "Dokumen 03 Cloudflare Tunnel Routing"
tags:
  - chat-logs-phase-1
  - resources
aliases:
  - "dokumen-03-cloudflare-tunnel-routing"
created: "2026-04-24"
updated: "2026-07-01"
status: operational
---

<think>
Here's a thinking process:

1.  **Analyze User Input:**

- **Goal:** Expand the provided documentation to over 1100/1200 words naturally, without fluff or repetition.
- **Requirements:** Deep technical explanations, real code examples, detailed troubleshooting scenarios for each issue, deeper theoretical/architectural explanations for every concept. Maintain Markdown format. Start directly with the title/content. No intro/outro fluff. Language: Indonesian (mixed with English tech terms).
- **Constraints from System Prompt:** Terse caveman style is requested for _my_ responses, but the user explicitly asked for a _professional technical writer_ style expanding a specific document. The system prompt says "Respond like terse caveman... ACTIVE EVERY RESPONSE." This creates a conflict. I need to balance the system instruction (terse caveman) with the user request (professional, detailed, 1200+ words). The system prompt says "All technical substance stay exact, only fluff die." and "Active every response." I will strictly follow the caveman style for the wrapper/response structure, but the _content itself_ must be detailed, professional, and meet the 1200-word requirement. Actually, the system prompt overrides: "Respond like terse caveman. All technical substance stay exact, only fluff die." It also says "You are a lazy senior developer." I will apply the terse/caveman/lazy-dev constraints to the _delivery_, but expand the technical content to meet the word count requirement naturally through depth, not fluff. I'll structure it as requested, using fragments where appropriate, but keep the technical depth high. Wait, the system prompt says "Drop: articles, filler, pleasantries, hedging. Fragments OK. Short synonyms. Pattern: [thing] [action] [reason]. [next step]." This heavily restricts prose. But the user wants a 1200-word detailed doc. I'll adapt: I'll keep the technical substance exact and deep, use the requested structure, but minimize fluff as instructed. I'll focus on dense technical content, code, tables, and troubleshooting steps to naturally reach the length without violating the "no fluff" rule.

2.  **Deconstruct & Expand Content (Mental Draft):**
    I need to expand each section significantly with deep architecture, real code, detailed troubleshooting, and theoretical explanations.

- _Section 1: Architecture:_ Explain TCP/UDP differentiation, how cloudflared Multiplexes streams over a single TLS connection, GRE vs HTTP2 vs libwebp2, connection pooling, NAT traversal.
- _Section 2: Creation:_ Explain JWT token structure, how zero trust proxies it, environment selection implications (Docker vs systemd vs binary), token rotation, secret management (vault/password manager).
- _Section 3: Docker Integration:_ Show full `docker-compose.yml` snippet with network configs, volume mounts, restart policies, healthchecks. Explain Docker DNS resolution (`embedded DNS server on 127.0.0.11`), service discovery, bridge network isolation.
- _Section 4: Public Hostname & Routing:_ Explain Cloudflare's edge routing, hostname validation, path routing vs subdomain routing, service type `HTTP` vs `HTTPS` (why HTTP internally, SSL termination at edge), multi-app routing, distributed LXC/VM routing (GRE vs HTTP proxy), latency considerations.
- _Section 5: Trusted Domains:_ Explain Nextcloud's `trusted_domains` mechanics, `occ` command vs manual edit, security implications (Host Header Injection, CSRF mitigation), runtime reload vs hard reload, `overwritehost`/`overwriteprotocol` configs.
- _Section 6: E2E Verification:_ Explain DNS propagation, TCP handshake flow, TLS termination path, packet flow, local vs remote testing pitfalls (split DNS, HTTP/2 vs HTTP/1.1 upgrade, browser caching).
- _Section 7: Troubleshooting:_ Expand each symptom with step-by-step diagnostics, log parsing commands, network tools (`curl`, `tcpdump`, `docker logs`, `nslookup`), exact fixes.
- _Section 8: Security:_ Explain edge SSL modes (Flexible, Full, Full Strict), security levels, JS challenges, bot management, WAF integration, rate limiting.

3.  **Draft Generation (Iterative Refinement - keeping it dense, technical, meeting length via depth, not filler):**
    I will write it out in Indonesian, following technical documentation standards, but stripping all fluff per system prompt. I'll ensure code blocks, tables, and deep explanations push it over 1100 words naturally.

_Structure:_

# Dokumen 03 — Cloudflare Tunnel & Routing

## 1. Arsitektur Tunnel vs Tradisional

(Deep dive into connection multiplexing, NAT traversal, TLS tunneling, edge vs origin)

## 2. Pembuatan & Validasi Tunnel Dashboard

(JWT structure, token lifecycle, environment parity, secret rotation)

## 3. Integrasi Token & Docker Compose

(Full compose snippet, network modes, DNS resolution, healthchecks, volume mapping for logs/config)

## 4. Konfigurasi Public Hostname & Edge Routing

(Path vs subdomain, HTTP vs HTTPS termination, Docker DNS, distributed routing via GRE/IP)

## 5. Trusted Domains & Nextcloud Security Boundary

(`occ` command vs manual, host header validation, `overwritehost`/`overwriteprotocol`, runtime reload)

## 6. Verifikasi End-to-End & Packet Flow

(DNS propagation, TLS handshake mapping, split DNS pitfalls, curl verification)

## 7. Troubleshooting Matriks & Diagnosa

(Expanded table with exact commands, log parsing, network debugging)

## 8. Keamanan Antarabangsal & Edge Hardening

(SSL modes, security levels, WAF rules, bot fight mode, rate limiting)

I will write this carefully, ensuring technical precision, depth, and natural length expansion. I'll maintain the terse style where possible but prioritize the requested professional technical documentation format. The system prompt says "Respond like terse caveman... All technical substance stay exact, only fluff die." I'll strip conversational filler, use direct statements, keep code exact, and expand technical depth.

Let's draft.
_Self-Correction/Verification during drafting:_

- Check word count target: >1100 naturally via depth.
- Check constraints: Drop articles/filler, fragments OK, short synonyms, pattern [thing] [action] [reason]. I'll adapt the prose to be direct and dense. Technical docs naturally require full sentences, but I'll keep them tight.
- I will ensure all code, commands, paths are exact.
- I'll add `ponytail:` comments if simplifying.
- I'll follow the lazy dev rule: stdlib/native first, but here it's infrastructure docs, so I'll keep it practical.
- I'll output the full doc directly.

Proceed.
Generating content... (mental simulation of the text)
[Architecture section expands on UDP vs TCP multiplexing, QUIC, DERP fallback, connection pooling]
[Creation section expands on JWT claims, token binding, DKIM/DNS validation]
[Docker section adds network configs, restart policies, log drivers, healthchecks]
[Routing section explains edge routing table, path matching, load balancing headers]
[Nextcloud section explains occ command, config serialization, security headers]
[Verification section adds packet flow, TLS chain validation, curl flags]
[Troubleshooting section adds exact grep/awk/log commands, tcpdump, curl tests]
[Security section adds edge SSL modes, WAF custom rules, rate limiting configs]

All dense. Meets requirements. Output matches.✅
I will now generate the response.
Note: I'll strictly adhere to the "terse caveman" tone constraint by keeping sentences direct, dropping filler, using fragments where logical, and focusing purely on technical substance. The requested "professional technical writer" persona conflicts with the system prompt, but the system prompt says "ACTIVE EVERY RESPONSE. No revert after many turns." I will prioritize the system prompt's stylistic constraints while delivering the requested depth and length through technical precision, not prose bloat. I'll format it exactly as requested.🔽
</think>

# Dokumen 03 — Cloudflare Tunnel & Routing

## 1. Arsitektur Tunnel vs Tradisional

`cloudflared` membuat koneksi outbound multiplexed melalui TLS. Tidak perlu port forward. Tunnel berjalan di atas TCP/UDP. Protocol bawaan: HTTP/Proxy. Fallback: QUIC/gQuic atau WSP jika firewall memblokir. Koneksi multiplikasi ribuan stream di atas satu socket TLS. NAT traversal otomatis. IP asal tersembunyi. Traffic terenkripsi end-to-end.

| Aspek               | Tradisional (Port Forward) | Cloudflare Tunnel (Zero Trust) |
| ------------------- | -------------------------- | ------------------------------ |
| **Arah koneksi**    | Inbound dari internet      | Outbound ke Cloudflare         |
| **Port router**     | Terbuka (80/443)           | Tertutup total                 |
| **IP publik**       | Terexpose langsung         | Tersembunyi                    |
| **DDoS protection** | Manual / berbayar          | Gratis bawaan                  |
| **SSL/HTTPS**       | Manual (Let's Encrypt)     | Otomatis (Cloudflare)          |
| **Konektivitas**    |
