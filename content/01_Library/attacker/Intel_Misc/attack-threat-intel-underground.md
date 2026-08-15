---
title: Attack Perspective — Threat Intel Underground (Red Team)
tags:
- attack
- red-team
- threat-intel
- underground
- forum
- marketplace
- telegram
- osint
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Threat Intel Underground — Perspektif Penyerang

> Underground = pasar intel (credential, exploit, tools, service). Red team pakai sebagai research source: pelajari TTP, beli intel target, monitor APT discourse.

## 1. Underground Ecosystem

| Layer | Platform | Konten | Red Team Use | Stealth |
|-------|----------|--------|-------------|---------|
| **Forum** | Exploit.in, XSS.is, RAMP, Carding forum | Exploit, tools, tutorial | TTP research, tool source | Tor/VPN |
| **Marketplace** | Genesis, Russian Market | Credential, session, fingerprint | Credential stuffing source | Monero payment |
| **Telegram** | Private channel, bot | Data leak, tools, C2-as-service | OSINT, IOC monitoring | Burner account |
| **C2-as-Service** | Commercial C2 (Colossus, Warzone) | Infrastructure rental | Cheap infra | API access |
| **RaaS** | Ransomware affiliate | Access brokerage, negotiation | TTP mimicry | Affiliate program |
| **Leak Site** | Ransomware blog | Victim data dump | PII research, password reuse | Passive view |
| **Exploit Market** | Zero-day broker | 0-day sale ($50K-$2.5M) | Capability purchase | Broker trust |

## 2. Credential Stuffing via Underground

```
Buy: Credential dump (forum/marketplace)
  ├── Target + password hash → crack (hashcat)
  ├── Session cookie (Genesis) → direct session
  └→ Fingerprint (browser profile) → bypass device trust
    ↓
Validate:
  ├── OpenBullet / Storm → config → auto login test
  ├── Rate: low per IP (proxy) → below threshold
  └→ Proxy rotation → distributed
    ↓
Exploit:
  ├── Password reuse → email/login → lateral
  ├── Session replay → no MFA prompt
  └→ Fingerprint replay → device trust bypass
```

## 3. Intel Collection (Red Team Research)

```
Monitoring:
  ├── Telegram channel → leak announcement → early access
  ├── Forum thread → TTP evolution → detection gap
  ├── Leak site → victim data → password reuse pattern
  └→ RaaS affiliate → access brokerage → target intel
    ↓
Apply:
  ├── New tool → RE → capability → emulate
  ├── New CVE discussion → exploit pattern → build before patch
  ├── Victim data → credential pattern → spray
  └→ Broker intel → target access → initial foothold
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Tor** | Forum access (anonymity) |
| **Telegram API** | Channel monitoring (telegra.ph, bot) |
| **hashcat** | Hash crack (credential dump) |
| **OpenBullet / Storm** | Credential validation |
| **Proxychains** | Proxy chaining (underground access) |
| **Monero wallet** | Payment privacy |

## 5. Referensi
- Flashpoint — https://flashpoint.io/
- Recorded Future Intel — https://www.recordedfuture.com/
- DarkOwl — https://www.darkowl.com/
- RAMP forum research — https://www.recordedfuture.com/resources/ramp-up
- Pegasus/NSO intel — https://citizenlab.ca/

## Konkret — Threat Intel Underground (Testable)

### Telegram Channel Monitoring

```bash
# 1. Search via Lyzem (Telegram search engine)
curl -s "https://lyzem.com/search?q=initial+access" -H "User-Agent: Mozilla"

# 2. Telegram CLI (tg)
tg-cli --search "ransomware" --limit 50
# Output: channel name, message text, timestamp

# 3. Monitor specific channel (via Telegram API)
# python-telegram-bot
from telegram import Telegram
tg = Telegram("api_token")
tg.get_chat_messages("@darkweb_channel", limit=100)
```

### Market DayOSINT (I2P/Tor)

```bash
# 1. Tor Browser → .onion marketplace
# 2. Scraper via Selenium
python3 scraper.py --url http://market.onion --output data.json
# 3. Track: vendor, product, price, listing count
# 4. Attribution: PGP key reuse → cross-market correlation

# Common .onion marketplaces (changing):
# - ASAP Market, Ares Market, Tor2Door, Vice City
# Pattern: URL bertahan 6-12 bulan lalu takedown/migrate
```

### Ransomware Leaks Site Tracking

```bash
# 1. Ransomware gang public leak site
#    LockBit, Conti (dead), BlackCat/ALPHV, Cl0p, Royal
# 2. Victim list
# 3. Monitor via RSS / scraping
# 4. Gradient: victim name → company → sector → geographic → impact

# Track strategy:
# - Archived snapshot → parsel victim list
# - Company 8-K / press release → confirm
# - Cluster by sector → threat intel report

# Monitor script:
python3 leak_monitor.py --sites lockbit,alphv,clop --notify slack
```

### Attacker Attribution (Matrix)

```
Technique: TTP cluster matching
1. Collected IoC ↔ MITRE ATT&CK technique
2. Cluster: beberapa intrusion dengan TTP sama → actor
3. Campaign name → threat actor handle (e.g., LockBit)
4. Known indicators: PGP key, BTC wallet, malware family, C2 IP, YARA rule

Attribution lapisan:
1. Malware (code fingerprint, compiler, mutex)
2. Infrastructure (IP, domain, cert, ASN)
3. Finance (BTC wallet cluster)
4. Motif (target type, sector, ransom)
```
---

audited
---
