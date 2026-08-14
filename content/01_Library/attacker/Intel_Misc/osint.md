
## Deepdive Lengkap — OSINT Framework & Operational Workflow

### 1. OSINT Lifecycle (Siklus Intel)

```
Planning → Collection → Processing → Analysis → Dissemination → Feedback
```

| Fase | Aktivitas | Output |
|------|-----------|--------|
| **Planning** | Define PIR (Priority Intelligence Requirements), scope, legal boundary | Collection plan, source list |
| **Collection** | Passive (search, API) + active (social, scrape) | Raw data (JSON, HTML, PDF) |
| **Processing** | Normalize, dedupe, enrich (geo, whois, ASN), structure | Structured data (CSV, JSONL) |
| **Analysis** | Pattern detection, link analysis, timeline, attribution | Intel report, graph, IOC list |
| **Dissemination** | Report format (executive, technical, tactical) | Deliverable per stakeholder |
| **Feedback** | Quality assessment, gap identification | Updated PIR, new requirements |

### 2. Source Classification (Hierarchy)

| Tier | Source | Reliability | Timeliness | Cost |
|------|--------|-------------|------------|------|
| **Tier 1** | Official (gov, corp filing, court record) | High | High | Free |
| **Tier 2** | Reputable media, academic, industry report | Medium-High | Medium | Free/Low |
| **Tier 3** | Social media, forum, blog, darknet | Low-Medium | Real-time | Free |
| **Tier 4** | Unverified, anonymous, speculative | Low | Variable | Free |

**Rule**: Tier 1+2 untuk attribution; Tier 3 untuk lead; Tier 4 hanya hypothesis.

### 3. Collection Methodology per Target Type

#### 3.1 Domain & Infrastructure

```
Target: example.com
  ├── Passive DNS (SecurityTrails, CIRCL, DNSDB)
  ├── Certificate Transparency (crt.sh, Google CT)
  ├── Subdomain enumeration (amass, subfinder, crt.sh)
  ├── Port scan (Shodan, Censys, FOFA) — legal scope only
  ├── Technology fingerprint (Wappalyzer, BuiltWith)
  ├── WHOIS history (DomainTools, whoxy)
  ├── SPF/DKIM/DMARC record (email config)
  └→ Historical: Wayback Machine, Archive.today
```

#### 3.2 Person & Identity

```
Target: John Doe (employee)
  ├── Professional: LinkedIn, GitHub, StackOverflow
  ├── Social: Twitter/X, Facebook, Instagram (OSINT only)
  ├── Email: Hunter.io, Clearbit, email permutation
  ├── Phone: Truecaller, Sync.me (if public)
  ├── Username: sherlock, social-analyzer
  ├── Document: Scribd, SlideShare, Academia.edu
  └→ Breach data: HaveIBeenPwned, DeHashed (legal access only)
```

#### 3.3 Organization & Network

```
Target: Corp Inc
  ├── ASN & IP range (BGP, Hurricane Electric)
  ├── Cloud asset (S3 enum, Azure blob, GCP bucket)
  ├── GitHub org (public repo, secret leak via truffleHog)
  ├── Job posting → tech stack, internal tool
  ├── Employee enumeration (LinkedIn sales nav, RocketReach)
  ├── Vendor relationship (crunchbase, Tracxn)
  └→ Regulatory filing (SEC, KSEI, OJK for Indonesia)
```

### 4. Tool Stack Lengkap

| Kategori | Tool (CLI) | Tool (GUI/Platform) | Use Case |
|----------|------------|---------------------|----------|
| **Framework** | SpiderFoot, theHarvester | Maltego, Lampyre | Automated collection |
| **Subdomain** | amass, subfinder, findomain | Assetfinder | Enumeration |
| **Search** | Googler, dorkme | Google Dork, Bing | Query automation |
| **Social** | sherlock, social-analyzer | Social-Analyzer | Username search |
| **Email** | hunter-cli, email-harvester | Hunter.io, Clearbit | Email discovery |
| **Darkweb** | darkweb-scraper, ahmia-cli | OnionScan | Hidden service |
| **Image** | exiftool, geosint | GeoSpy, Picarta | Geolocation |
| **Telegram** | lyzem, telegram-osint | TGStat, Telemetr | Channel search |
| **Graph** | maltego, graphviz | Maltego, yEd | Link analysis |

### 5. Operational Security (OPSEC) untuk Collector

```
Collector OPSEC Checklist:
  ├── VPN/Proxy: rotate exit IP, no logging provider
  ├── Browser: Firefox + containers, no JS (noscript), uBlock
  ├── Identity: sock puppet account (separate email, phone, browser profile)
  ├── Attribution: never use personal device/account
  ├── Network: dedicated VLAN/VM, no shared DNS
  ├── Timing: randomize request interval, mimic human
  ├── Storage: encrypted disk (LUKS/Veracrypt), no cloud sync
  └→ Legal: document scope, authorization, chain of custody
```

### 6. Maltego Transform Pattern (Red Team)

| Entity Input | Transform | Output Entity |
|--------------|-----------|---------------|
| Domain | ToIPAddress | IP Address |
| IP Address | ToASN | ASN |
| ASN | ToNetblock | Netblock |
| Domain | ToEmail | Email Address |
| Email | ToPerson | Person |
| Person | ToSocialMedia | Social Profile |
| Phone | ToCarrier | Organization |

### 7. Intel Report Structure (Technical)

```markdown
cssclasses:
  - wide-table
  - callout

# Intel Report: [Target] — [Classification]
## Executive Summary (1 paragraf, actionable)
## Priority Intelligence Requirements (PIR)
## Findings (per source, dengan confidence: High/Med/Low)
## IOCs (IP, domain, hash, email — format STIX/CSV)
## Timeline (chronological key event)
## Attribution Assessment (actor, motivation, capability)
## Gaps & Recommendations
## Sources & Methodology (appendix)
```

### 8. Legal & Ethical Boundary (Indonesia Context)

| Aktivitas | Hukum | Catatan |
|-----------|-------|---------|
| **Passive search** (Google, Shodan public) | Legal | Public data |
| **Active scan** (nmap target) | Perlu izin | UU ITE Pasal 30, KUHP |
| **Social engineering** | Ilegal tanpa izin | Penipuan, akses ilegal |
| **Darkweb access** | Legal (view) | Tapi jangan transaksi |
| **Data collection** | UU PDP (2022) | Personal data protection |

## Referensi Lengkap
- OSINT Framework — https://osintframework.com/
- Maltego — https://www.maltego.com/
- SpiderFoot — https://github.com/smicallef/spiderfoot
- Bellingcat Toolkit — https://www.bellingcat.com/resources/
- MITRE ATT&CK Recon — https://attack.mitre.org/tactics/TA0043/
- UU ITE Indonesia — https://jdih.kominfo.go.id/
- UU PDP Indonesia — https://www.kominfo.go.id/

### 9. Case Study: OSINT Flow untuk Target Perusahaan

```
Goal: Identifikasi infrastruktur + karyawan kunci + kemungkinan vektor phish

Langkah:
1. Domain: example.co.id → whois, crt.sh → subdomain: mail, vpn, hr, portal
2. Email: hunter.io → pola nama: nama.akhir@example.co.id → generate 1000 permutasi
3. LinkedIn: karyawan HR (admin), IT (dev), Finance (transfer) → target spearfishing
4. GitHub: org example-co-id → repo internal (old, public) → secret leak scan
5. Social: twitter/ig karyawan → info personal (hari libur, device, lokasi)
6. Darkweb: breach dump → credential contoh → password reuse test
7. Deliverable: report dengan vektor paling mungkin (HR email + phish page)

Effort: 2-4 jam tools + 1 jam analisis
```

### 10. Automation Pipeline (Python)

```python
import requests, json, re

def passive_dns(domain):
    # CIRCL passive DNS API
    r = requests.get(f"https://www.circl.lu/pdns/query/{domain}")
    return [x["rrname"] for x in r.json()]

def crt_sh(domain):
    r = requests.get(f"https://crt.sh/?q=%25.{domain}&output=json")
    subs = set()
    for c in r.json():
        for name in c["name_value"].split("
"):
            subs.add(name.strip())
    return sorted(subs)

def hunter_emails(domain, api_key):
    r = requests.get(f"https://api.hunter.io/v2/domain-search?domain={domain}&api_key={api_key}")
    return [e["value"] for e in r.json().get("data", {}).get("emails", [])]

if __name__ == "__main__":
    d = "example.com"
    print("Passive DNS:", passive_dns(d)[:10])
    print("Subdomains:", crt_sh(d)[:10])
```
