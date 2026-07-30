---
title: "Hierarchy WAF & Reverse Proxy"
tags:
  - atlas
  - waf
  - reverse-proxy
  - web-security
  - blue-team
aliases:
  - "hierarchy-waf-reverse-proxy"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
---

# 🛡️ HIERARKI WAF & REVERSE PROXY — Dari Nginx Passthrough (Level 0) sampai Custom eBPF WAF (Level 6)

> WAF dan Reverse Proxy adalah **lapisan pertahanan Layer 7** yang memfilter lalu lintas HTTP/HTTPS sebelum mencapai aplikasi. Hirarki ini memetakan evolusi dari "proxy bawaan web server" sampai "WAF engine kustom dengan eBPF deep inspection." Semakin tinggi level, semakin dalam inspeksi — tapi juga semakin besar performance overhead. Untuk arsitektur teknis lengkap (ModSecurity, CRS, Pingora, Envoy), lihat [[waf-reverse-proxy-deepdive]].

> [!info] Cara Baca
> Level 0 = proxy sederhana tanpa filtering. Level 6 = custom WAF dengan eBPF di kernel. Kebanyakan organisasi di Level 1–3 (nginx + ModSecurity/CRS). Level 4+ untuk platform yang menghadapi DDoS harian atau APT-level Web attack.

---

## Tabel Utama — Level 0 sampai Level 6

| 🛡️ Level | 🧠 Arsitektur | ⚡ Cara Kerja | ☠️ Tembok / Limitation | 🎯 Cocok Untuk |
|---|---|---|---|---|
| **Level 0** — Reverse Proxy Dasar | Nginx, HAProxy, Caddy, Apache mod_proxy | **Passthrough tanpa inspeksi konten.** TLS termination, load balancing, static file serve, caching. Caddy: auto HTTPS via Let's Encrypt | **Tidak ada filtering.** SQLi/XSS/RCE langsung tembus ke backend. Hanya proteksi dari serangan L3/L4 (SYN flood, port scan) | Blog statis, landing page, app tanpa data sensitif |
| **Level 1** — WAF Dasar | Nginx + ModSecurity, Apache + mod_security, OpenResty | Regex-based rule engine. **OWASP CRS (Core Rule Set)**: ~200 rule deteksi SQLi, XSS, RCE, path traversal, LFI, RFI. Paranoia Level 0 (low false positive) → PL 4 (high coverage, high FP) | **Regex bypass umum** (encoding, case swap, comment injection). CRS PL 0–1 banyak false negative. Performance drop signifikan (~30% throughput loss) | SMB, startup dengan form input, e-commerce kecil |
| **Level 2** — Semantic WAF | Coraza, Apache APISIX, AWS WAF, Cloudflare WAF, Imunify360 | **Rule engine + tokenizer/parser.** Bukan regex mentah — parse request body ke AST untuk deteksi konteks SQL/XML/JSON. Coraza: Go port of ModSecurity, 2x faster. CRS rule with **semantic engine** | **Parser bisa di-evade** (encoding ganda, chunked transfer encoding, HTTP/2 downgrade). Rule tuning butuh weeks. High resource pada traffic besar | Mid-market enterprise, fintech, multi-tenant platform |
| **Level 3** — API Gateway + WAF | Kong, Tyk, APISIX, AWS API Gateway + WAF, Azure Front Door | **Layer 7 routing + WAF terintegrasi.** API key validation, rate limiting, JWT verification, request/response transformation, canary deploy. Kong: plugin ecosystem 200+ | **Complexity setup.** Kong + plugin bisa butuh dedicated infra. Plugin bisa konflik. Debugging lebih sulit karena chain panjang | API-first product, platform SaaS, mobile app backend |
| **Level 4** — Service Mesh WAF | Istio + WASM plugin, Envoy + Lua filter, Cilium L7 policy | **WAF di service mesh layer — mTLS + L7 filtering.** Envoy WASM filter: custom WAF logic compiled ke WASM, hot-reload tanpa restart. Cilium: eBPF L7 policy untuk HTTP/gRPC | **Performance cost** sidecar proxy ~10-15%. WASM sandbox terbatas (no syscall). eBPF program maturity untuk L7 masih baru. Debugging tracing kompleks | Microservices, enterprise platform, regulated industry |
| **Level 5** — Cloudflare/GCP/AWS DDoS Shield | Cloudflare Spectrum + WAF + DDoS, GCP Cloud Armor, AWS Shield Advanced | **Anycast network + global WAF.** Absorb DDoS di edge. Machine learning detection anomaly traffic. Bot management dengan JS challenge. Rate limiting per IP/user-agent/session | **Cost tinggi** (Cloudflare Enterprise ~USD 5,000+/bln). **Privacy concern** — semua traffic decrypt di edge. CAPTCHA bisa degrade UX | High-traffic global platform, e-commerce besar, crypto exchange |
| **☠️ Level 6** — Custom eBPF WAF | Pingora (Cloudflare), custom Rust/WAF, eBPF (XDP/TC hook), jq-based semantic engine | **WAF di kernel level via eBPF** — inspeksi di XDP hook sebelum sk_buff dibentuk. Rust-based proxy (Pingora) handle TLS + proxy + WAF di single binary. Custom rule engine dengan tokenizer non-RE2 | **Development cost sangat tinggi.** eBPF debugging tooling terbatas. Kernel update bisa break eBPF program. Memory safety kritis (Rust mandatory) | Big Tech (Cloudflare, Google, Meta), CDN provider, research |

---

## Peta Visual — Performa vs Depth Inspeksi

```
Depth inspeksi ↑
  L6 ─ eBPF WAF (kernel-level) ●──●●●●● Performance drop
  L5 ─ Cloudflare Edge WAF       ●──●●●●
  L4 ─ Service Mesh WAF         ●──●●●
  L3 ─ API Gateway WAF         ●──●●
  L2 ─ Semantic WAF           ●──●
  L1 ─ Regex WAF             ●──
  L0 ─ Reverse Proxy (no WAF) ●
      └──────────────────────────→ Performance overhead
```

---

## Kenapa Hirarki Ini Penting

### 1. WAF Bukan Silver Bullet — Bisa Di-Bypass

Semua WAF level dapat di-bypass dengan teknik yang sesuai:
- **L1 regex-based**: encoding (URL, double URL, Unicode), comment injection (`/**/`), case swap, parameter pollution
- **L2 semantic**: boundary confusion (JSON parse beda antara WAF vs backend), HTTP/2 downgrade, charset manipulation
- **L4 service mesh**: sidecar version mismatch, WASM filter bug
- **L6 eBPF**: kernel version mismatch, eBPF verifier reject

**WAF adalah lapisan pertahanan — bukan satu-satunya.** Selalu kombinasikan dengan input validation di aplikasi (parameterized query, output encoding, CSP).

### 2. CRS Paranoia Level = WAF Tuning

| PL | Coverage | False Positive | Recommended |
|---|---|---|---|
| PL 0 | Low | Minimal | Start here, production |
| PL 1 | Medium | Low | Production |
| PL 2 | High | Medium | Staging, then production after tuning |
| PL 3 | Very High | High | Hanya jika aplikasi sudah secure |
| PL 4 | Maximum | Very High | Research, compliance audit |

Rule: **start PL 1 → monitor → naik PL 2 → tune weeks → production.**

### 3. Performance Trade-off Signifikan

Setiap level WAF membebani throughput:
- L0 (no WAF): baseline 0% loss
- L1 (regex CRS PL1): ~20–30% throughput drop
- L2 (semantic engine): ~30–50% (tokenizer overhead)
- L3 (API gateway + WAF): ~40–60% (extra routing layer)
- L6 (eBPF WAF): ~10–15% (di kernel, paling efisien)

For context: 10k req/s baseline → L1 = 7k req/s → L3 = ~4k req/s.

---

## Plot Twists

> [!danger] Plot Twist 1: WAF Bisa Dimatikan Attacker Dengan HTTP Request
> Jika WAF hanya inspeksi konten tapi tidak proteksi resource exhaustion — attacker kirim HTTP request raksasa (1GB POST) → WAF buffer full → crash atau bypass. Atau HTTP/2 rapid reset → exhaust proxy connection pool → backend terpapar langsung. **WAF + rate limiting + resource limit harus jalan beriringan.**

> [!tip] Plot Twist 2: 90% WAF Dipasang Tapi Tidak Di-Tune
> Survey 2024: 90% organisasi pasang WAF dengan default ruleset dan tidak pernah tuning. Akibatnya: false positive tinggi → blokir request legitimate → user complain → semua rate block diturunkan → WAF menjadi **security theater.** Tuning WAF adalah pekerjaan berkelanjutan — bukan fire-and-forget.

> [!info] Plot Twist 3: Pingora (Level 6) Mengubah Cara Cloudflare Bangun Proxy
> Cloudflare buat Pingora (Rust) untuk menggantikan Nginx — karena Nginx arsitektur proses-per-koneksi tidak optimal untuk modern server. Pingora: event-driven, zero-cost abstraksi, TLS via BoringSSL, WAF via WASM plugin. Satu binary handle 10 juta+ koneksi per server. **Custom framework > generic untuk ultra-scale.**

---

## Sumber & Telusur Lebih Lanjut

- **Deep Dive WAF + Reverse Proxy** → [[waf-reverse-proxy-deepdive]] (ModSecurity, CRS, Pingora, Envoy lengkap)
- **Web Hacking (Attack Vectors)** → [[web-hacking-exploitation]] (SQLi, XSS, SSRF — yang coba di-block WAF)
- **Supply Chain (Rule Lifecycle)** → [[software-supply-chain-security-deepdive]]
- **Service Mesh Security** → [[cloud-infrastructure]] (Level 5–8, Istio + WASM)
- **jarsWAF (Custom Rust WAF)** → [[jarswaf-lifecycle-architecture]]
- **Master Index** → [[master-index]]

---

> WAF bukan alat ajaib yang membuat aplikasi aman — itu layer filtering yang mengurangi noise attack. Security sejati tetap di aplikasi: input validation, parameterized query, output encoding. WAF = safety net, bukan replacement.

*WAF & Reverse Proxy Hierarchy | Level 0 (Proxy Passthrough) → Level 6 (eBPF Custom WAF) · Bisa Di-Bypass, Bukan Silver Bullet*
