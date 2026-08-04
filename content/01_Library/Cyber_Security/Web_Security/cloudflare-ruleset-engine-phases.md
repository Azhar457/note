---
title: Cloudflare Ruleset Engine — Phase Architecture
tags:
- cyber-security
- library
- web-security
created: '2026-07-02'
updated: '2026-07-02'
status: pending
cssclasses: ''
---

# ☁️ Cloudflare Ruleset Engine — Phase Architecture

> [!info] Hubungan ke Vault
> Ruleset Engine adalah blueprint processing pipeline yang menginspirasi arsitektur WAF. Konsep phase-based evaluation di sini terkait dengan [[ids-ips-waf-nsm-comparison]] dan [[network-security]]. Untuk logging & SIEM integration, lihat [[blueteam-detection-matrix]] dan [[cgnat-attribution-deepdive]].

## Daftar Isi
1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [Arsitektur Ruleset Engine](#arsitektur-ruleset-engine)
4. [Phase Category: Network Layer](#phase-category-network-layer)
5. [Phase Category: Application Request](#phase-category-application-request)
6. [Phase Category: Application Response](#phase-category-application-response)
7. [Complete Phase Order Diagram](#complete-phase-order-diagram)
8. [Phase Entry Point Ruleset](#phase-entry-point-ruleset)
9. [Actions](#actions)
10. [Expression Language](#expression-language)
11. [Deployment Model](#deployment-model)
12. [Relevansi untuk WAF](#relevansi-untuk-waf)
13. [Bottom Line](#bottom-line)

---

## Overview

**Cloudflare Ruleset Engine** — adalah sistem pemrosesan terstruktur yang mengevaluasi request dan response HTTP melalui **28 phase** berurutan. Setiap phase adalah titik di pipeline di mana ruleset bisa di-deploy dan dieksekusi.

Data dari Cloudflare Docs (sumber utama note ini):

| Layer | Jumlah Phase |
|-------|-------------|
| Network Layer | **5** |
| Application: Request | **17** (termasuk 3 internal/N/A) |
| Application: Response | **6** (termasuk 2 internal/N/A) |
| **Total** | **28** |

> Setiap phase punya **phase entry point ruleset** — root ruleset yang nge-hold aturan untuk phase itu. Custom rulesets bisa di-execute dari entry point ini.

---

## Core Concepts

### Phase

**Phase** = stage dalam lifecycle request/response di mana rules bisa dieksekusi. Urutan eksekusi fixed — nggak bisa diubah.

```
Request masuk → [Phase 1] → [Phase 2] → ... → [Phase N] → ke Origin
Response dari Origin → [Phase R1] → [Phase R2] → ... → [Phase RN] → ke Client
```

### Ruleset

**Ruleset** = versioned set of rules. Ada dua jenis:

| Type | Kind | Deployable? | Deskripsi |
|------|------|-------------|-----------|
| **Phase Entry Point** | `root` | Ya, ke satu phase | Ruleset utama di setiap phase. Defines rules yang execute custom/managed rulesets |
| **Custom Ruleset** | `custom` | Di-execute dari entry point | Ruleset reusable yang bisa dipasang di banyak phase entry points |
| **Managed Ruleset** | (managed) | Dari Cloudflare | Ruleset pre-built dari Cloudflare (WAF, DDoS, Bot Mgmt) |

### Rule

**Rule** = filter + action. Setiap rule punya:

```
expression: "(http.request.uri.path eq \"/login\")"
action: "block" | "execute" | "skip" | "rewrite" | ...
```

- **Expression** — menentukan request mana yang kena aturan (Cloudflare Wirefilter syntax)
- **Action** — apa yang dilakukan kalau match (block, challenge, allow, execute ruleset, skip, rewrite, log, dll)

---

## Arsitektur Ruleset Engine

### Phase Evaluation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    REQUEST PHASES (↓)                            │
│                                                                  │
│  http_request_dynamic_redirect ──→ URL redirect check            │
│         ↓                                                        │
│  http_request_sanitize ──→ URL normalization                     │
│         ↓                                                        │
│  http_request_transform ──→ Rewrite request URL/params           │
│         ↓                                                        │
│  http_request_api_gateway_early ──→ API Shield early check       │
│         ↓                                                        │
│  http_config_settings ──→ Zone configuration rules               │
│         ↓                                                        │
│  http_request_origin ──→ Override origin server                  │
│         ↓                                                        │
│  ddos_l7 ──→ HTTP DDoS Attack Protection                         │
│         ↓                                                        │
│  http_request_firewall_custom ──→ WAF Custom Rules               │
│         ↓                                                        │
│  http_ratelimit ──→ Rate Limiting                                │
│         ↓                                                        │
│  http_request_api_gateway_late ──→ API Shield late check         │
│         ↓                                                        │
│  http_request_firewall_managed ──→ WAF Managed Rules             │
│         ↓                                                        │
│  http_request_sbfm ──→ Super Bot Fight Mode                      │
│         ↓                                                        │
│  (Cloudflare Access check — internal)                            │
│         ↓                                                        │
│  http_request_redirect ──→ Bulk Redirects                        │
│         ↓                                                        │
│  (Managed Transforms — internal)                                 │
│         ↓                                                        │
│  http_request_late_transform ──→ Response Headers transform      │
│         ↓                                                        │
│  http_request_cache_settings ──→ Cache rules override            │
│         ↓                                                        │
│  http_request_snippets ──→ Snippets (Cloudflare Workers-lite)    │
│         ↓                                                        │
│  http_request_cloud_connector ──→ Cloud Connector rules          │
│         ↓                                                        │
│  ┌─────────────────────────────────────────────────────────────────
│  │  (koneksi ke origin server)
│  └─────────────────────────────────────────────────────────────────
│                                                                  │
│                    RESPONSE PHASES (↑)                            │
│                                                                  │
│  http_custom_errors ──→ Custom error pages                       │
│         ↓                                                        │
│  (Managed Transforms — internal)                                 │
│         ↓                                                        │
│  http_response_headers_transform ──→ Response headers modify     │
│         ↓                                                        │
│  http_ratelimit ──→ Rate Limiting (response-based info)          │
│         ↓                                                        │
│  http_response_compression ──→ Compression rules (Brotli/gzip)   │
│         ↓                                                        │
│  http_response_firewall_managed ──→ Sensitive Data Detection(DLP)│
│         ↓                                                        │
│  http_log_custom_fields ──→ Custom logpush fields                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase Category: Network Layer

5 phase untuk **packet-level filtering** — berlaku di Cloudflare Network Firewall / Magic Transit.

| # | Phase Name | Product/Feature | Fungsi |
|---|------------|-----------------|--------|
| 1 | `ddos_l4` | L4 DDoS Attack Protection | Filter serangan DDoS di layer 4 (SYN flood, UDP flood, dll) |
| 2 | `magic_transit` | Cloudflare Network Firewall | Packet filtering — allow/block berdasarkan IP/port/protocol |
| 3 | `magic_transit_managed` | Managed Rulesets (Network) | Ruleset pre-built untuk traffic network |
| 4 | `magic_transit_ratelimit` | Rate Limiting (Network) | Rate limit per source IP di layer jaringan |
| 5 | `magic_transit_ids_managed` | Intrusion Detection System | IDS signature-based detection di layer network |

**Karakteristik Network Layer:**
- Operates on raw packets, bukan HTTP
- Tidak punya konsep URI, headers, cookies
- Fields: `ip.src`, `ip.dst`, `ip.proto`, `tcp.srcport`, `tcp.dstport`, `udp.srcport`, `udp.dstport`
- Actions: `block`, `allow`, `log`

---

## Phase Category: Application Request

17 phase untuk **HTTP request processing** — dari redirect hingga cache.

| # | Phase Name | Product/Feature | Evaluates |
|---|------------|-----------------|-----------|
| 1 | `http_request_dynamic_redirect` | Single Redirects | URL, query string — redirect decision |
| 2 | `http_request_sanitize` | URL Normalization | URL encoding, path normalization |
| 3 | `http_request_transform` | URL Rewrite Rules | URL path, query params — rewrite |
| — | *(internal)* | Waiting Room Rules | Queue management |
| 4 | `http_request_api_gateway_early` | API Shield (early) | Schema validation, mTLS API tokens |
| 5 | `http_config_settings` | Configuration Rules | Zone config overrides (per-URL) |
| 6 | `http_request_origin` | Origin Rules | Origin server, SNI, DNS resolution |
| 7 | `ddos_l7` | HTTP DDoS Protection | L7 DDoS — rate, pattern, fingerprint |
| 8 | `http_request_firewall_custom` | WAF Custom Rules | User-defined WAF rules |
| 9 | `http_ratelimit` | Rate Limiting Rules | Request rate per threshold |
| 10 | `http_request_api_gateway_late` | API Shield (late) | Schema + token validation (after rate limit) |
| 11 | `http_request_firewall_managed` | WAF Managed Rules | Cloudflare-managed WAF rulesets |
| 12 | `http_request_sbfm` | Super Bot Fight Mode | Bot detection — verified vs suspicious |
| — | *(internal)* | Cloudflare Access | Zero Trust auth check (Access policies) |
| 13 | `http_request_redirect` | Bulk Redirects | Many-to-many URL redirects |
| — | *(internal)* | Managed Transforms | Automatic header transforms |
| 14 | `http_request_late_transform` | Response Header Transform | Modify response headers before cache |
| 15 | `http_request_cache_settings` | Cache Rules | Cache key, TTL, bypass rules |
| 16 | `http_request_snippets` | Snippets | Cloudflare Workers-lite scripts |
| 17 | `http_request_cloud_connector` | Cloud Connector | Third-party cloud integration |

### Urutan Logis Request Phase

```
URL in → Normalize → Rewrite → API Shield → Config → Origin → DDoS
  → Custom WAF → Rate Limit → API Shield 2 → Managed WAF → Bot Mode
  → Access → Bulk Redirect → Transforms → Cache → Snippets → Cloud
    ↓
  [OUTBOUND TO ORIGIN]
```

### Ketersediaan Fields per Phase

Fields tertentu hanya available di phase-phase tertentu:

| Phase | HTTP Headers | URI Path | Query String | Request Body | Response Fields | Geolocation |
|-------|-------------|----------|-------------|-------------|----------------|-------------|
| Early (redirect, sanitize, transform) | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| Mid (firewall, ratelimit, managed) | ✅ | ✅ | ✅ | ✅ (some) | ❌ | ✅ |
| Late (cache, snippets, cloud connector) | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Response phases | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |

> Request body fields (`http.request.body.*`) tersedia mulai phase `http_request_firewall_custom`.

---

## Phase Category: Application Response

6 phase untuk **HTTP response processing** — dari error page hingga logging.

| # | Phase Name | Product/Feature | Fungsi |
|---|------------|-----------------|--------|
| 1 | `http_custom_errors` | Custom Errors | Ganti error page (500, 502, 1xxx errors) dengan konten kustom |
| — | *(internal)* | Managed Transforms | Transform response headers otomatis |
| 2 | `http_response_headers_transform` | Response Header Transform | Set/add/remove response headers |
| 3 | `http_ratelimit` | Rate Limiting (response) | Rate limit berdasarkan response attributes (status code) |
| 4 | `http_response_compression` | Compression Rules | Kontrol kompresi Brotli/gzip per content type |
| 5 | `http_response_firewall_managed` | Sensitive Data Detection | DLP — deteksi credit card, SSN, API key di response body |
| 6 | `http_log_custom_fields` | Logpush Custom Fields | Add custom fields ke logpush |

### Response Phase Flow

```
[ORIGIN RESPONSE IN]
    ↓
Custom Errors → Managed Transforms → Response Headers
    → Rate Limit → Compression → DLP/Database → Logpush
    ↓
[RESPONSE BACK TO CLIENT]
```

---

## Complete Phase Order Diagram

```
[CLIENT REQUEST]
    │
    ├─ Network Layer ──────────────────────────────────────
    │  ├─ ddos_l4                          (DDoS L4)
    │  ├─ magic_transit                    (Pkt Filter)
    │  ├─ magic_transit_managed            (Managed Rules)
    │  ├─ magic_transit_ratelimit          (Rate Limit)
    │  └─ magic_transit_ids_managed        (IDS)
    │
    ├─ Application Request ───────────────────────────────
    │  ├─ http_request_dynamic_redirect    (Single Redirect)
    │  ├─ http_request_sanitize            (URL Normalize)
    │  ├─ http_request_transform           (URL Rewrite)
    │  ├─ [internal] Waiting Room
    │  ├─ http_request_api_gateway_early   (API Shield)
    │  ├─ http_config_settings             (Config Rules)
    │  ├─ http_request_origin              (Origin Rules)
    │  ├─ ddos_l7                          (DDoS L7)
    │  ├─ http_request_firewall_custom     (WAF Custom)
    │  ├─ http_ratelimit                   (Rate Limit)
    │  ├─ http_request_api_gateway_late    (API Shield)
    │  ├─ http_request_firewall_managed    (WAF Managed)
    │  ├─ http_request_sbfm                (Bot Mode)
    │  ├─ [internal] Cloudflare Access
    │  ├─ http_request_redirect            (Bulk Redirect)
    │  ├─ [internal] Managed Transforms
    │  ├─ http_request_late_transform      (Late Transform)
    │  ├─ http_request_cache_settings      (Cache Rules)
    │  ├─ http_request_snippets            (Snippets)
    │  └─ http_request_cloud_connector     (Cloud Connector)
    │
    ├─ [TO ORIGIN SERVER] ─────────────────
    │
    ├─ Application Response ──────────────────────────────
    │  ├─ http_custom_errors               (Custom Errors)
    │  ├─ [internal] Managed Transforms
    │  ├─ http_response_headers_transform  (Resp Headers)
    │  ├─ http_ratelimit                   (Rate Limit)
    │  ├─ http_response_compression        (Compression)
    │  └─ http_response_firewall_managed   (DLP/Data)
    │  └─ http_log_custom_fields           (Logpush)
    │
    └─ [RESPONSE TO CLIENT]
```

---

## Phase Entry Point Ruleset

Setiap phase punya **entry point ruleset** — ruleset `root` yang dideploy ke phase itu.

### Struktur Entry Point

```json
{
  "result": {
    "id": "<ZONE_PHASE_RULESET_ID>",
    "name": "http_request_firewall_custom phase entry point ruleset for my zone",
    "description": "",
    "kind": "zone",
    "version": "3",
    "rules": [
      {
        "id": "<PHASE_RULE_ID>",
        "version": "1",
        "action": "execute",
        "description": "Execute custom ruleset (zone)",
        "action_parameters": {
          "id": "<CUSTOM_RULESET_ID>",
          "version": "latest"
        },
        "expression": "(http.request.uri.path eq \"/login\")",
        "last_updated": "2025-08-18T18:35:14.135697Z",
        "ref": "<PHASE_RULE_REF>",
        "enabled": true
      }
    ],
    "phase": "http_request_firewall_custom"
  }
}
```

### Cara Kerja Entry Point

```
Zone-level:
  [http_request_firewall_custom entry point] ← root ruleset, attached to zone
    Rule 1: if expression → execute custom_ruleset_A
    Rule 2: if expression → execute custom_ruleset_B
    Rule 3: if expression → block

Account-level:
  [http_request_firewall_custom entry point] ← root ruleset, attached to account
    Rule 1: if (cf.zone.plan eq "ENT") → execute enterprise_custom_ruleset
```

**Key point:** Entry point ruleset bisa punya multiple rules. Setiap rule bisa `execute` custom ruleset, `block`, `challenge`, `skip`, dll. Urutan rules dalam satu entry point penting — rules di atas dievaluasi dulu.

---

## Actions

Setiap rule bisa punya action berikut:

| Action | Deskripsi | Use Case |
|--------|-----------|----------|
| **block** | Return error response (403/4xx/5xx) | Block malicious requests |
| **challenge** | Show CAPTCHA | Suspicious traffic |
| **managed_challenge** | Adaptive challenge (CAPTCHA/JS/No-op) | Bot detection |
| **allow** | Skip semua phase selanjutnya | Whitelist legitimate traffic |
| **execute** | Execute another ruleset (custom/managed) | Run rule collection |
| **skip** | Skip specified phases/rulesets | Bypass certain checks |
| **rewrite** | Modify URI/headers | URL normalization |
| **redirect** | URL redirect | URL forwarding |
| **log** | Log only, no action | Monitoring |
| **set_config** | Override zone settings | Per-request config |
| **force_connection_close** | Close TCP connection | Mitigation |
| **compress_response** | Set compression type | Response optimization |

### Action: Allow vs Skip

| Aspek | Allow | Skip |
|-------|-------|------|
| **Effect** | Skip ALL remaining phases | Skip specific phases/rulesets |
| **Origin request** | Always passes to origin | Request continues processing |
| **Use case** | Trusted traffic bypass | Skip certain checks but not others |

### Action: Execute

Rule yang mengeksekusi custom/managed ruleset:

```json
{
  "action": "execute",
  "expression": "(http.request.uri.path eq \"/login\")",
  "action_parameters": {
    "id": "<CUSTOM_RULESET_ID>",
    "version": "latest"
  }
}
```

Multiple rulesets bisa di-execute dalam satu phase entry point:

```
Entry Point: http_request_firewall_managed
  Rule 1: if true → execute cloudflare_managed_ruleset_owasp
  Rule 2: if true → execute cloudflare_managed_ruleset_cloudflare_php
```

---

## Expression Language

Cloudflare pakai **Wirefilter syntax** — mirip Wireshark display filter.

### Field Categories

| Category | Contoh Fields |
|----------|---------------|
| **HTTP** | `http.request.uri`, `http.request.method`, `http.request.headers.*`, `http.cookie`, `http.user_agent` |
| **IP** | `ip.src`, `ip.dst`, `ip.geoip.country` |
| **TCP** | `tcp.srcport`, `tcp.dstport` |
| **SSL/TLS** | `ssl`, `ssl.protocol`, `ssl.certificate` |
| **Cloudflare-specific** | `cf.bot_management.score`, `cf.waf.score`, `cf.threat_score`, `cf.zone.plan` |
| **Rate Limiting** | `cf.ratelimit.remaining`, `cf.rl.action` |

### Operators

| Operator | Contoh |
|----------|--------|
| **eq** | `http.request.uri.path eq "/login"` |
| **ne** | `ip.src ne 1.1.1.1` |
| **contains** | `http.request.uri.path contains "/wp-admin"` |
| **starts_with** | `starts_with(http.request.uri.path, "/api")` |
| **ends_with** | `ends_with(http.request.uri.path, ".php")` |
| **in** | `ip.src in { 10.0.0.0/8 192.168.0.0/16 }` |
| **matches** | `http.request.uri.path matches "^/admin"` (regex) |
| **and** | `ip.src eq 1.1.1.1 and http.request.method eq "POST"` |
| **or** | `http.request.uri.path eq "/admin" or http.request.uri.path eq "/login"` |
| **not** | `not ip.geoip.country in { "RU" "CN" }` |

### Example Complex Expression

```
(http.request.method eq "POST" and
 http.request.uri.path eq "/graphql" and
 not cf.bot_management.score gt 30 and
 ip.geoip.country ne "ID")
```

---

## Deployment Model

### Zone-level vs Account-level

| Level | Scope | Use Case |
|-------|-------|----------|
| **Zone-level** | Per domain | Zone-specific WAF rules, page rules |
| **Account-level** | All zones | Enterprise-wide policy, shared rulesets |

### Phase Entry Point Deployment

```
POST /zones/{zone_id}/rulesets/phases/{phase_name}/entrypoint
{
  "description": "Phase entry point for custom rules",
  "kind": "root",
  "name": "Default",
  "rules": [ ... ],
  "phase": "http_request_firewall_custom"
}
```

### Custom Ruleset Creation

```
POST /zones/{zone_id}/rulesets
{
  "description": "Block login path brute force",
  "kind": "custom",
  "name": "Brute force protection",
  "rules": [ ... ],
  "phase": "http_request_firewall_custom"
}
```

Kemudian deploy ke entry point:

```
PUT /zones/{zone_id}/rulesets/phases/{phase_name}/entrypoint
```

---

## Relevansi untuk WAF

### Apa yang bisa diadopsi

| Konsep Cloudflare | Implementasi di WAF |
|-------------------|------------------------|
| **Phase pipeline** | Pipeline processing dengan urutan fixed — setiap phase punya tanggung jawab spesifik (parsing → sanitasi → WAF → rate limit → cache → response) |
| **Entry point ruleset** | Root ruleset per phase yang mengeksekusi filter chain — memisahkan "what to check" dari "what to do when match" |
| **Multiple actions** | Actions: block, challenge, allow, log, rewrite — nggak cuma allow/deny |
| **Expression language** | DSL untuk aturan firewall — field-based, composable (eq, contains, starts_with, regex, CIDR) |
| **Skip action** | Bypass phase tertentu — berguna buat trust list tanpa harus disable WAF entirely |
| **Score-based bot detection** | Machine learning score instead of binary block — prinsip risk-based decision |
| **Phase field visibility** | Fields tertentu hanya available di phase tertentu — desain yang mencegah misuse |
| **Account-level vs zone-level** | Multi-tenant policy separation — each tenant punya ruleset sendiri |

### Arsitektur WAF yang Terinspirasi

```
[REQUEST IN]
    │
    ├─ L4 Processing ─────────────────────
    │  ├─ Connection Table (conntrack)
    │  ├─ SYN Flood Protection
    │  └─ IP Reputation Check
    │
    ├─ L7 Parsing ──────────────────────
    │  ├─ HTTP Parser (AST tokenizer)
    │  ├─ URL Normalization / Sanitization
    │  └─ Header Extraction
    │
    ├─ Security Phases ──────────────────
    │  ├─ Phase 1: Request Sanitization
    │  │    URL normalization, path traversal detection
    │  ├─ Phase 2: Input Validation
    │  │    Parameter validation, content type check
    │  ├─ Phase 3: WAF Rule Processing
    │  │    CRS rules, custom rules, regex matching
    │  ├─ Phase 4: Rate Limiting
    │  │    Per-IP, per-path, per-session counters
    │  └─ Phase 5: Bot Detection
    │       User-agent, JS challenge, fingerprint
    │
    ├─ Routing ────────────────────────
    │  ├─ Origin Selection
    │  ├─ Load Balancing (Pingora)
    │  └─ Connection Pooling
    │
    ├─ [TO ORIGIN]
    │
    ├─ Response Processing ──────────────
    │  ├─ Phase 6: Response Header Filter
    │  ├─ Phase 7: Response Body Scan (DLP)
    │  └─ Phase 8: Logging & Metrics
    │
    └─ [RESPONSE OUT]
```

### Phase Design untuk WAF

Setiap phase di WAF punya struktur yang sama:

```
Phase struct {
    id: u8,                    // Phase order (0..N)
    name: String,
    rulesets: Vec<Ruleset>,    // Entry point ruleset + custom
    actions: Vec<Action>,      // Block/Allow/Log/Rewrite
    skip_conditions: Vec<Expr>, // Skip phase jika kondisi terpenuhi
}
```

```rust
// Pseudocode arsitektur WAF
pub struct Phase {
    pub id: u8,
    pub name: &'static str,
    pub entry_ruleset: Ruleset,
    pub skip_expression: Option<Expression>,
}

pub enum PhaseId {
    L4DDoS = 0,
    HttpParse = 1,
    Sanitize = 2,
    WafCustom = 3,
    RateLimit = 4,
    BotDetection = 5,
    OriginRouting = 6,
    ResponseHeaders = 7,
    ResponseDLP = 8,
    Logging = 9,
}

impl Pipeline {
    pub fn process(&self, ctx: &mut RequestContext) -> PipelineResult {
        let phases = self.order();
        for phase in phases {
            if phase.should_skip(&ctx) { continue; }
            let result = phase.evaluate(&ctx)?;
            match result.action {
                Action::Block => return Err(PipelineError::Blocked(phase, result.reason)),
                Action::Allow => break, // skip remaining phases
                Action::Execute(ruleset) => ruleset.evaluate(&mut ctx)?,
                Action::Log => ctx.log_phase(phase.id, &result),
                Action::Rewrite => ctx.apply_rewrite(&result.rewrite)?,
            }
        }
        Ok(PipelineResult::Forward)
    }
}
```

### Perbedaan Utama WAF vs Cloudflare

| Aspek | Cloudflare | WAF |
|-------|-----------|---------|
| **Arsitektur** | Global reverse proxy network | Single Rust binary (Pingora) |
| **Scaling** | Multi-region anycast | Horizontal per-instance |
| **Phase config** | API-driven (REST + JSON) | Config file / YAML / TOML |
| **Ruleset format** | Cloudflare Wirefilter DSL | Custom DSL + CRS compatibility |
| **Multi-tenancy** | Account + Zone hierarchy | Tenant via config/namespace |
| **Deployment** | Cloud-only (SaaS) | On-prem / edge / cloud-agnostic |
| **Network layer** | Magic Transit (proprietary) | eBPF XDP + iptables/nftables |

---

## Bottom Line

> [!tip] Bottom Line
> Ruleset Engine Cloudflare adalah referensi utama buat desain pipeline WAF:
> 1. **28 phase** terbagi rapi — network (5), request (17), response (6)
> 2. Setiap phase punya entry point ruleset → clean separation of concerns
> 3. Actions: block, allow, skip, execute, rewrite, log — beyond binary allow/deny
> 4. Expression language (Wirefilter) → composable, field-based
> 5. Urutan phase FIXED — predictability & determinism
>
> Untuk WAF: cukup 8-10 phase yang relevan (L4 → Parse → Sanitize → WAF Custom → RateLimit → Bot → Routing → Response → Log). Jangan over-engineer — cukup yang diperlukan.

---

## Referensi

- [Cloudflare Ruleset Engine Docs](https://developers.cloudflare.com/ruleset-engine/)
- [Phases List — Cloudflare Docs](https://developers.cloudflare.com/ruleset-engine/reference/phases-list/)
- [Ruleset Engine About](https://developers.cloudflare.com/ruleset-engine/about/)
- [Cloudflare Wirefilter Expression Language](https://developers.cloudflare.com/ruleset-engine/rules-language/)
- [Custom Rulesets API](https://developers.cloudflare.com/ruleset-engine/custom-rulesets/)
- [[ids-ips-waf-nsm-comparison]]
- [[network-security]]
- [[dns-tunneling-deepdive]] — DNS tunneling yang bisa melewati phase WAF
- [[blueteam-detection-matrix]] — detection rules untuk bypas WAF
