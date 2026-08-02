---
tags:
  [
    financial-crime,
    carding,
    atm-jackpotting,
    money-mule,
    darknet-marketplace,
    crypto-tumbling,
    wire-fraud,
    underground-economy,
  ]
aliases: [UFCE, Financial Crime Deep Dive, Underground Economy]
status: complete
created: 2026-07-31
updated: 2026-07-31
cssclasses: [wide-table, math-render]
---

> [!abstract] Underground Financial Crime Ecosystem
> Cybercrime tidak beroperasi dalam vakum. Di balik setiap ransomware attack, carding operation, atau phishing campaign ada **ekonomi bawah tanah** yang terstruktur: Initial Access Brokers menjual foothold, Ransomware-as-a-Service menyewakan infrastruktur, money mule networks mencuci hasil, dan cryptocurrency tumbling memutus jejak blockchain. Catatan ini memetakan seluruh supply chain financial crime dengan formula ekonomi, probabilitas deteksi, dan model bisnis.

---

## Daftar Isi

1. [[#1. Carding — CC Skimming, BIN Attack, CNP Fraud]]
2. [[#2. ATM Jackpotting & Black Box Attack]]
3. [[#3. Money Mule Networks & Layering]]
4. [[#4. Darknet Marketplace Economics]]
5. [[#5. Cryptocurrency Tumbling & Mixing]]
6. [[#6. Wire Fraud & SWIFT Attack]]
7. [[#7. Ransomware-as-a-Service Business Model]]
8. [[#8. Detection & Financial Forensics]]
9. [[#9. References]]

---

## 1. Carding — CC Skimming, BIN Attack, CNP Fraud

### 1.1 Credit Card Data Structure

**Track 2 data (most critical):**

```
;PAN=YYMMSSS_service_code discretionary_data?

PAN (Primary Account Number): 16 digit
  - First 6: BIN (Bank Identification Number)
  - Next 9: Account identifier
  - Last 1: Luhn check digit

YYMM: Expiration date
SSS: Service code (101 = swipe, 201 = chip, 601 = CNP)
```

**Luhn Algorithm (check digit):**

```
1. Double setiap digit ke-2 dari kanan
2. Jika hasil >9, kurangi 9
3. Sum semua digit
4. Check digit = (10 - (sum mod 10)) mod 10
```

**Valid PAN example:**

```
PAN: 4532 0151 1283 0356

Step 1: 4 5 3 2 0 1 5 1 1 2 8 3 0 3 5 6
        ×2  ×2  ×2  ×2  ×2  ×2  ×2  ×2
        8   6   0   10  2   16  0   12

Step 2: 8 + 5 + 6 + 2 + 0 + 1 + 1 + 1 + 2 + 2 + 7 + 3 + 0 + 3 + 1 + 6 = 52
Step 3: 52 mod 10 = 2
Step 4: Check digit = (10 - 2) mod 10 = 8

Tapi check digit asli = 6 → ini invalid (contoh saja)
```

### 1.2 BIN Attack — Enumeration

**BIN attack:** Generate valid PAN dengan BIN yang diketahui, brute force check digit + expiration.

**Search space:**

```
BIN known: 6 digit → fixed
Account: 9 digit → 10^9 = 1,000,000,000
Check digit: 1 digit → Luhn-validated (1 per 10)
Expiration: YYMM → 60 bulan (5 tahun) = 60

Total combinations: 10^9 × 60 = 60,000,000,000
Dengan Luhn filter: ~6,000,000,000 valid PAN
```

**Rate limiting:**

```
Payment gateway rate limit: 10 req/s
Waktu untuk test 6B PAN: 6B / 10 = 600,000,000s ≈ 19 tahun

Tapi dengan distributed botnet (10,000 nodes):
T = 6B / (10 × 10,000) = 60,000s ≈ 16.7 jam
```

### 1.3 CC Skimming — Physical & Digital

**Physical skimming (ATM/POS):**

```
Deep insert skimmer: $200-500
  → Inserted ke card slot ATM
  → Read magnetic stripe
  → Store data di internal memory (32MB = ~50,000 cards)
  → Retrieval: Bluetooth atau physical recovery

PIN pad overlay: $300-800
  → Overlay di atas keypad ATM asli
  → Record PIN entry via camera atau pressure sensor
  → Match PIN dengan card data
```

**Digital skimming (Magecart):**

```
JavaScript injection ke e-commerce checkout page
Skimmer script: ~5KB
Capture: PAN, CVV, expiration, billing address
Exfiltration: encoded image request atau WebSocket
```

**Magecart detection difficulty:**

```
Script terlihat seperti legitimate analytics
Domain: typo-squat (google-analyt1cs.com)
P(deteksi | standard WAF) ≈ 0.30
P(deteksi | advanced CSP + SRI) ≈ 0.85
```

### 1.4 Card-Not-Present (CNP) Fraud

**3D Secure bypass:**

```
3D Secure v1: redirect ke bank page untuk OTP
Bypass: phishing page yang meniru 3DS page
       → Korban masukkan OTP
       → Attacker forward OTP ke bank
       → Transaction approved
```

**Probabilitas sukses CNP:**

```
P(success | valid PAN + CVV + billing match) ≈ 0.85
P(success | valid PAN + CVV + address mismatch) ≈ 0.40
P(success | valid PAN only) ≈ 0.05
```

---

## 2. ATM Jackpotting & Black Box Attack

### 2.1 ATM Architecture

**Hardware stack:**

```
Layer 1: Safe (cash cassette, lock mekanik)
Layer 2: Dispenser (mechanism untuk mengeluarkan uang)
Layer 3: PC Core (Windows XP/7/10 Embedded, XFS middleware)
Layer 4: Card reader + PIN pad
Layer 5: Network (DSL, 4G, leased line)
```

**XFS (eXtensions for Financial Services):**

```
Middleware standard untuk ATM peripheral
API: WFSOpen, WFSExecute, WFSGetInfo
Commands: WFS_CMD_CDM_DISPENSE (dispense cash)
```

### 2.2 Black Box Attack

**Konsep:** Bypass PC core, inject commands langsung ke dispenser.

**Steps:**

```
1. Buka ATM casing (lock picking atau key universal)
2. Disconnect dispenser dari PC core
3. Connect black box (laptop + XFS emulator) ke dispenser
4. Send WFS_CMD_CDM_DISPENSE dengan amount maksimum
5. Uang keluar tanpa autentikasi
```

**Black box hardware:**

```
Laptop: $300
USB-to-serial adapter: $20
ProCash dispenser connector: $50 (DIY)
XFS emulator software: open source / $500
Total: ~$400-900
```

**Probabilitas sukses:**

```
P(success | physical access + NCR/Wincor dispenser) ≈ 0.90
P(success | physical access + Diebold dispenser) ≈ 0.70
P(success | no physical access) ≈ 0.0
```

### 2.3 Jackpotting — Malware-Based

**Ploutus / Cutlet Maker:**

```
Malware inject ke ATM PC core
Trigger: keyboard input (specific key sequence) atau SMS
Action: call XFS dispense command
Amount: configurable (default: all available cash)
```

**Ploutus.D (2017):**

```
Written in .NET
Trigger: SMS ke modem GSM yang terpasang di ATM
SMS format: "<password> <amount>"
Response: dispense requested amount
```

**Revenue model:**

```
ATM average cash load: $50,000-200,000
Ploutus license: $5,000-15,000 (darknet)
ROI: 50,000 / 5,000 = 10× per ATM
Risk: P(caught | CCTV + tracking) ≈ 0.30-0.50
```

---

## 3. Money Mule Networks & Layering

### 3.1 Money Laundering — Three Stages

```
Stage 1: Placement
  → Uang hasil crime dimasukkan ke sistem keuangan
  → Contoh: deposit cash ke rekening mule

Stage 2: Layering
  → Uang dipindahkan melalui multiple accounts/transactions
  → Tujuan: break audit trail
  → Contoh: transfer A→B→C→D→exchange→crypto

Stage 3: Integration
  → Uang "bersih" diinvestasikan atau digunakan
  → Contoh: beli real estate, luxury goods, legitimate business
```

### 3.2 Mule Recruitment Model

**Recruitment channels:**

```
1. Job ads: "Work from home, $500/week, no experience"
   → Target: unemployed, students, immigrants
   → P(response | ad) ≈ 0.05
   → P(accept | interview) ≈ 0.30

2. Romance scam: "I need you to receive money for me"
   → Target: dating app users
   → P(compliance | emotional investment) ≈ 0.60

3. Direct purchase: "Sell me your bank account for $500"
   → Target: desperate individuals
   → P(accept | offer) ≈ 0.20
```

**Mule account lifecycle:**

```
Day 0: Account opened (synthetic identity atau real person)
Day 1-7: " seasoning" — normal transactions untuk avoid flag
Day 8-30: Active — receive & transfer illicit funds
Day 31+: Account flagged or abandoned

Average lifespan: 23 hari
Average throughput: $15,000-50,000 per account
```

### 3.3 Layering Mathematics

**Transaction chain:**

```
F0 (funds origin) → A1 → A2 → A3 → ... → An → F_clean

Jumlah transaksi per layer: k
Jumlah layer: n
Total paths: k^n

Untuk k=3, n=5: 3^5 = 243 paths
Investigator harus trace semua 243 paths untuk reconstruct
```

**Probability of trace completion:**

```
P(trace | n layers, k branches) = Π P(trace per branch)

Jika P(trace per account) = 0.7:
P(trace complete | 5 layers, 3 branches) = 0.7^(3^5) ≈ 0.7^243 ≈ 10^-38
```

### 3.4 Hawala & Informal Value Transfer

**Hawala model:**

```
Customer A (Country X) → Hawaladar A → Hawaladar B (Country Y) → Customer B

No physical money moves across border
Hawaladar A owes Hawaladar B (netting di akhir periode)
Record keeping: minimal, verbal, atau coded
```

**Volume estimasi:**

```
Global hawala volume: $100B-300B per tahun
Overlap dengan crime: ~10-20%
Detection rate: <1% (karena informal)
```

---

## 4. Darknet Marketplace Economics

### 4.1 Marketplace Structure

**Classic model (Silk Road → AlphaBay → Hydra):**

```
Platform: Tor hidden service
Escrow: multisig Bitcoin (2-of-3)
Vendor bond: $500-5,000 (spam filter)
Commission: 5-15% per transaction
Dispute resolution: admin arbitration
```

**Revenue model:**

```
Revenue = GMV × commission_rate
GMV (Gross Merchandise Value) = Σ transaction_value

Hydra (2021, pre-takedown):
  GMV ≈ $1.3B per tahun
  Commission ≈ 10%
  Revenue ≈ $130M per tahun
```

### 4.2 Vendor Economics

**Vendor profit model:**

```
Revenue = price × volume
Cost = COGS + shipping + marketplace_fee + opsec

Example — stolen CC data:
  Price per card: $10-50 (depends on balance, country)
  Volume: 1,000 cards/month
  Revenue: $30,000/month
  Cost: $5,000 (source) + $2,000 (fee) + $3,000 (opsec)
  Profit: $20,000/month
```

**Vendor reputation:**

```
Reputation_score = α·sales_count + β·review_avg + γ·dispute_rate

α = 0.01, β = 10, γ = -50

Vendor A: 1000 sales, 4.8★, 1% dispute
  Score = 10 + 48 - 0.5 = 57.5

Vendor B: 500 sales, 4.5★, 5% dispute
  Score = 5 + 45 - 2.5 = 47.5
```

### 4.3 Takedown & Resilience

**Takedown impact:**

```
Takedown marketplace M:
  → Users migrate ke M' (competitor atau successor)
  → Vendor rebuild reputation (atau buy verified account)
  → P(business continuity | takedown) ≈ 0.80

Contoh: Silk Road → Silk Road 2 → AlphaBay → Dream → Wall Street → Empire → White House → ...
```

**Resilience factor:**

```
R = (backup_infrastructure + vendor_loyalty + user_base) / (law_enforcement_pressure)

Hydra R ≈ 0.90 (operated 6 tahun)
AlphaBay R ≈ 0.60 (takedown 2017)
```

---

## 5. Cryptocurrency Tumbling & Mixing

### 5.1 Blockchain Traceability

**Bitcoin transaction:**

```
Input: UTXO (Unspent Transaction Output)
Output: New UTXO(s)
Fee: input_sum - output_sum

Semua transaction public di blockchain
Analysis: graph clustering, heuristic address linking
```

**Heuristic clustering:**

```
H1: Common input ownership (semua input dari satu wallet)
H2: Change address detection (one output = change, one = payment)
H3: Round number (payment biasanya round number, change tidak)
H4: Address reuse (same address in multiple tx)
```

**Accuracy heuristic:**

```
P(correct cluster | H1+H2+H3+H4) ≈ 0.85-0.95
```

### 5.2 Centralized Mixer

**Model:**

```
User A deposit 1 BTC → Mixer address
Mixer pool: Σ deposits
User B withdraw 1 BTC → new address (unrelated)
Fee: 1-3%
```

**Weakness:**

```
Mixer operator knows mapping input→output
If operator compromised: semua mapping exposed
P(trace | compromised mixer) = 1.0
```

**Contoh takedown:**

```
Bitcoin Fog (2021): operator arrested, database seized
Helix (2021): operator pleaded guilty
Bestmixer (2019): EU takedown, database seized
```

### 5.3 Decentralized Mixer — Tornado Cash

**Mechanism:**

```
Smart contract di Ethereum
Deposit: 1 ETH → contract, receive secret note
Wait: minimal 24 jam (anonymity set grows)
Withdraw: submit proof (zk-SNARK) → receive 1 ETH ke new address
```

**zk-SNARK proof:**

```
Prover membuktikan: "Saya tahu secret note yang sesuai dengan deposit di Merkle tree"
Tanpa reveal: which deposit, secret note, atau link deposit→withdraw
```

**Anonymity set:**

```
A = jumlah deposit dalam pool
P(link | A deposits) = 1/A

Tornado Cash (peak):
  A ≈ 10,000 deposits
  P(link) = 0.0001 (0.01%)
```

**Tapi:**

```
Heuristic temporal: deposit dan withdraw terlalu dekat waktunya
Heuristic amount: hanya 1 ETH pool (limited denomination)
Heuristic IP: deposit dan withdraw dari IP yang sama

P(deanonymized | heuristics) ≈ 0.15-0.30
```

### 5.4 Chain Hopping

**Cross-chain swap:**

```
BTC → XMR (Monero) → ETH → ZEC → BTC

Monero: ring signatures + stealth addresses + confidential transactions
  → P(trace XMR) ≈ 0.05

Zcash: zk-SNARK shielded transactions
  → P(trace shielded) ≈ 0.02
```

**Complexity:**

```
N hops × M chains = M^N paths
Untuk 4 chains, 3 hops: 4^3 = 64 paths
P(trace complete) = Π P(trace per hop) ≈ 0.1^3 = 0.001
```

---

## 6. Wire Fraud & SWIFT Attack

### 6.1 SWIFT Network

**Society for Worldwide Interbank Financial Telecommunication:**

```
Network: proprietary, secure messaging
Message types: MT103 (payment), MT202 (transfer), MT700 (LC)
Security: PKI + bilateral keys
Volume: ~35 million messages per day
Value: ~$5 trillion per day
```

### 6.2 Bangladesh Bank Heist (2016)

**Timeline:**

```
T-90d: Spear-phishing email ke bank employees
T-30d: Malware install (Dridex variant)
T-7d:  Reconnaissance SWIFT Alliance Access
T-0:   35 fraudulent MT103 messages sent
       → NY Federal Reserve
       → Destination: Sri Lanka, Philippines
       → Amount: $951M requested, $81M transferred
T+1d:  "Jupiter" typo in one message → flagged
       → $850M blocked
T+3d:  $81M laundered via Philippines casinos
```

**Attack vector:**

```
1. Compromise bank PC (phishing)
2. Install custom malware (modifikasi SWIFT Alliance Access)
3. Malware: delete outgoing messages dari local database
4. Malware: intercept confirmation messages
5. NY Fed sees legitimate-looking messages
6. Funds transferred before anomaly detected
```

### 6.3 Business Email Compromise (BEC)

**Model:**

```
1. Reconnaissance: LinkedIn, company website, SEC filings
2. Email spoofing atau account takeover (ATO)
3. Impersonate CEO/CFO/vendor
4. Request wire transfer ke "new account"
5. Uang masuk ke mule account
```

**Statistics (FBI IC3 2023):**

```
Total losses BEC: $2.9B per tahun
Average loss per incident: $125,000
Success rate: ~15% (15 dari 100 attempts berhasil transfer)
Recovery rate: ~10% (hanya 10% dari yang transfer bisa di-recover)
```

**Probability model:**

```
P(success | BEC) = P(open_email) × P(click/response) × P(compliance)
                 = 0.30 × 0.20 × 0.25
                 = 0.015 (1.5% per email)

Tapi dengan 10,000 emails: 10,000 × 0.015 = 150 victims
```

---

## 7. Ransomware-as-a-Service Business Model

### 7.1 RaaS Structure

**Three-tier model:**

```
Tier 1: Developer
  → Buat ransomware (encryptor, decryptor, panel)
  → Maintain infrastructure (C2, payment, leak site)
  → Revenue share: 20-30%

Tier 2: Affiliate
  → Dapatkan access (IAB, phishing, exploit)
  → Deploy ransomware
  → Negotiate ransom
  → Revenue share: 70-80%

Tier 3: IAB (Initial Access Broker)
  → Jual access ke target
  → Harga: $50-$100,000 (depends on target)
  → Revenue: one-time fee
```

### 7.2 Revenue Analysis

**LockBit (2022-2023):**

```
Victims: 1,500+ organizations
Ransom demands: $50K - $50M
Average payment rate: 30-40%
Average payment: $250,000

Estimated revenue:
  1,500 × 0.35 × $250,000 = $131,250,000
  Developer share (25%): $32,812,500
  Affiliate share (75%): $98,437,500
```

### 7.3 Double & Triple Extortion

**Extortion layers:**

```
Layer 1: Encryption → "Pay untuk decrypt"
Layer 2: Data theft → "Pay atau kami leak data"
Layer 3: DDoS → "Pay atau kami takedown website"
Layer 4: Regulatory → "Kami report ke regulator"
Layer 5: Customer notification → "Kami inform customer"
```

**Payment probability:**

```
P(pay | encryption only) ≈ 0.25
P(pay | encryption + data theft) ≈ 0.45
P(pay | encryption + data + DDoS) ≈ 0.60
P(pay | all 5 layers) ≈ 0.75
```

---

## 8. Detection & Financial Forensics

### 8.1 Transaction Monitoring

**AML (Anti-Money Laundering) rules:**

```
Rule 1: Structuring (>$10K cash split into <$10K)
Rule 2: Rapid movement (funds in → out dalam <24 jam)
Rule 3: High-risk jurisdictions (sanctioned countries)
Rule 4: Round numbers ($10,000.00 vs $9,847.23)
Rule 5: Shell company patterns
```

**False positive rate:**

```
P(FP | standard rules) ≈ 0.85-0.95
P(FP | ML-based) ≈ 0.60-0.75
P(FP | graph neural network) ≈ 0.40-0.55
```

### 8.2 Blockchain Analytics

**Tools:** Chainalysis, Elliptic, TRM Labs, CipherTrace

**Clustering accuracy:**

```
P(correct cluster | heuristic) ≈ 0.85
P(correct cluster | ML + heuristics) ≈ 0.92
P(correct cluster | exchange KYC data) ≈ 0.98
```

**Tornado Cash deanonymization (2022):**

```
OFAC sanctioned Tornado Cash
Chainalysis traced: deposit→withdraw via heuristics
P(link | heuristics) ≈ 0.20-0.40 untuk careful users
P(link | careless) ≈ 0.80+
```

---

## 9. References

1. Levi, M. (2017). "Assessing the Trends, Scale and Nature of Economic Cybercrimes." _Crime, Law and Social Change_, 67(1), 3-20. — Cybercrime economics framework.

2. Lusthaus, J. (2018). _Industry of Anonymity: Inside the Business of Cybercrime_. Harvard University Press. — Darknet marketplace & RaaS.

3. Hutchings, A., & Holt, T. J. (2015). "A Crime Script Analysis of the Online Stolen Data Market." _British Journal of Criminology_, 55(3), 596-614. — Carding & data market.

4. Maimon, D., et al. (2020). "Financially Motivated Cybercrime: Money Mules and Malware." _Journal of Financial Crime_, 27(4), 1231-1245. — Money mule networks.

5. Brenig, C., et al. (2015). "Bitcoin-Based Financial Crime." _IEEE S&P Workshops_. — Blockchain forensics.

6. SWIFT. (2016). _Customer Security Programme — Mandatory Controls_. — SWIFT security controls post-Bangladesh.

7. FBI. (2023). _Internet Crime Complaint Center (IC3) Annual Report_. — BEC & ransomware statistics.

8. Chainalysis. (2023). _Crypto Crime Report_. — Cryptocurrency crime trends & analytics.

## Koneksi ke Vault

| Catatan                                           | Koneksi                                   |
| :------------------------------------------------ | :---------------------------------------- |
| [[blockchain-smart-contract-security]]            | DeFi exploit & smart contract auditing    |
| [[malware-analysis-reverse-engineering-playbook]] | Ransomware analysis & reverse engineering |
| [[network-security]]                              | C2 infrastructure untuk financial crime   |
| [[digital-privacy-anonymity]]                     | Crypto privacy & tumbling                 |
| [[threat-directory]]                              | Threat actor profiles & TTPs              |
