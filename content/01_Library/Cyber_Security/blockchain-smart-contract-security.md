---
title: Blockchain & Smart Contract Security — DeFi, Auditing & Crypto Forensics
tags:
- blockchain
- smart-contract
- solidity
- defi
- crypto-forensics
- web3-security
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Blockchain security adalah persimpangan antara **cryptography** (post-quantum, zero-knowledge), **software security** (smart contract auditing), dan **financial forensics** (crypto tracing). Catatan ini melengkapi [[cryptography-biometrics]] dengan aplikasi blockchain, dan [[exploit-development]] dengan DeFi exploit patterns.
>
> **Domain:** Cyber Security / Web3
> **Tags:** #blockchain #smart-contract #solidity #defi #crypto-forensics #web3

## Daftar Isi

1. [Blockchain Fundamentals for Security](#1-blockchain-fundamentals-for-security)
2. [Ethereum & EVM Internals](#2-ethereum--evm-internals)
3. [Solidity Security Patterns & Anti-Patterns](#3-solidity-security-patterns)
4. [DeFi Exploit Patterns](#4-defi-exploit-patterns)
5. [Smart Contract Auditing Workflow](#5-smart-contract-auditing-workflow)
6. [Cryptocurrency Forensics](#6-cryptocurrency-forensics)
7. [Quantum Threat to Blockchain](#7-quantum-threat-to-blockchain)
8. [Koneksi ke Vault](#8-koneksi-ke-vault)

## 1. Blockchain Fundamentals for Security

### 1.1 Consensus Mechanisms

| Mechanism | Used By | Security Property | Attack Vector |
|-----------|---------|-------------------|---------------|
| **PoW** | Bitcoin, Ethereum (legacy) | Naka's chain selection | 51% attack, selfish mining |
| **PoS** | Ethereum, Solana | Economic finality | Long-range attack, nothing at stake |
| **DPoS** | EOS, Tron | Delegated voting | Cartel formation, bribery |
| **PBFT** | Hyperledger, Zilliqa | Byzantine fault tolerance | <= 1/3 malicious nodes |
| **Avalanche** | Avalanche | Subsampled voting | Liveness attack |
| **PoH** | Solana | Verifiable delay | None (but centralized) |

### 1.2 Blockchain Attack Taxonomy

```
Blockchain Attacks
├── Consensus
│   ├── 51% Attack (majority hash/power)
│   ├── Selfish Mining (withhold blocks → orphan)
│   ├── Eclipse Attack (isolate node → false chain)
│   └── Long-range Attack (PoS: rewrite from ancient key)
├── Smart Contract
│   ├── Reentrancy (recursive call drain)
│   ├── Oracle Manipulation (price feed poison)
│   ├── Flash Loan Attack (uncollateralized borrow)
│   ├── Access Control (missing modifier, backdoor)
│   ├── Integer Overflow/Underflow
│   └── Front-running (MEV extraction)
├── Network
│   ├── Sybil Attack (fake nodes, eclipse)
│   ├── DDoS (mempool spam, gas war)
│   └── Routing Attack (BGP hijack for blocks)
└── User
    ├── Phishing (seed phrase fake sites)
    ├── Dusting (trace + de-anonymize wallet)
    ├── SIM Swap (2FA bypass on exchange)
    └── Clipboard Hijacking (replace deposit address)
```

## 2. Ethereum & EVM Internals

### 2.1 Transaction Flow

```
User signs tx
    ↓
Mempool (pending tx)
    ↓
Validator picks tx
    ↓  executes
EVM (stack-based VM)
    ↓  opcode by opcode
State transition (balance, storage, code)
    ↓
State root updated
    ↓
Block finalized
```

### 2.2 EVM Storage Layout

```solidity
// State variables mapped to storage slots
// Slot = keccak256(key . slot) for mappings
contract Example {
    uint256 public a;      // slot 0
    uint256 public b;      // slot 1
    mapping(address => uint) public balances; // slot 2
    // balances[user] = keccak256(abi.encode(user, 2))
}
```

**Attack implication:** Storage slot collision via delegatecall — if two contracts share the same layout, one can corrupt the other's state.

### 2.3 Gas Economics & Attacks

| Opcode | Gas | Security Relevance |
|--------|-----|-------------------|
| `SLOAD` | 2100 (warm), 2100 (cold) | Unbounded loops = out-of-gas |
| `SSTORE` | 20000/2900 | Storage write cost → gas griefing |
| `CALL` | 700 + 2300 stipend | Reentrancy via insufficient gas |
| `DELEGATECALL` | 700 | Storage layout vulnerability |
| `SELFDESTRUCT` | 5000 | Contract destruction + force ETH send |

## 3. Solidity Security Patterns

### 3.1 Reentrancy

```solidity
// VULNERABLE: Reentrancy
contract VulnerableBank {
    mapping(address => uint) public balances;
    
    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);
        // BUG: state update AFTER external call
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent);
        balances[msg.sender] = 0;  // ← TOO LATE!
    }
}

// ATTACKER: recursive withdraw
contract Attacker {
    VulnerableBank bank;
    
    fallback() external payable {
        if (address(bank).balance > 0) {
            bank.withdraw();  // Re-enter before balance=0
        }
    }
    
    function attack() public payable {
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }
}
```

**Fix: Checks-Effects-Interactions pattern**
```solidity
function withdraw() public {
    uint bal = balances[msg.sender];
    require(bal > 0);
    // EFFECTS FIRST!
    balances[msg.sender] = 0;
    // THEN interactions
    (bool sent, ) = msg.sender.call{value: bal}("");
    require(sent);
}
```

**Or use ReentrancyGuard:**
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafeBank is ReentrancyGuard {
    function withdraw() external nonReentrant {
        // ...
    }
}
```

### 3.2 Oracle Manipulation

```solidity
// VULNERABLE: Uses single AMM as oracle
contract VulnerableLending {
    function getCollateralValue(address token) public view returns (uint) {
        // BUG: TWAP not used, single source
        (uint reserve0, uint reserve1) = pair.getReserves();
        return reserve0 * tokenPrice / reserve1;  // Manipulable via flash loan
    }
    
    function borrow(address token, uint amount) external {
        uint collateralValue = getCollateralValue(token);
        require(amount <= collateralValue * 80 / 100);  // LTV check
        // If oracle manipulated → borrow more than collateral!
    }
}
```

**Attack scenario:**
1. Flash loan massive token A
2. Swap on AMM → crash price
3. Borrow all assets using inflated collateral
4. Repay flash loan → profit

**Fix:** Use **Chainlink TWAP** (time-weighted average price), not instantaneous:

```solidity
// Chainlink price feed (aggregated from multiple sources)
AggregatorV3Interface feed = AggregatorV3Interface(0x...);
(, int price, , uint updatedAt, ) = feed.latestRoundData();
require(block.timestamp - updatedAt < 1 hours);  // Freshness check
```

### 3.3 Flash Loan Attack Patterns

```solidity
// Flash loan = borrow without collateral, as long as repaid in same tx
// Attack flow:
// 1. Flash loan 10M USDC from Aave
// 2. Swap on DEX A (price drops 20%)
// 3. Buy back on DEX B (price normal)
// 4. Arbitrage profit: 10M * 20% = 2M
// 5. Repay flash loan + fee
// 6. Keep profit!
```

| Notable Flash Loan Attack | Year | Loss | Technique |
|--------------------------|------|------|-----------|
| bZx Protocol | 2020 | $350K | First flash loan attack |
| Harvest Finance | 2020 | $24M | Curve pool manipulation |
| Cream Finance | 2021 | $130M | ERC-777 reentrancy |
| Poly Network | 2021 | $611M | Cross-chain key management flaw |
| Wormhole Bridge | 2022 | $326M | Validator signature verification |
| Ronin Bridge | 2022 | $540M | Validator key compromise (5/9) |
| Nomad Bridge | 2022 | $190M | Trusted root misconfiguration |

### 3.4 Common Solidity Vulnerabilities

| Vulnerability | Example | Mitigation |
|---------------|---------|------------|
| **Reentrancy** | Recursive external call | CEI pattern, ReentrancyGuard |
| **Access Control** | `onlyOwner` misspelled, `tx.origin` | `msg.sender` not `tx.origin` |
| **Integer Overflow** | Balance arithmetic | OpenZeppelin SafeMath (pre 0.8) |
| **Oracle Manipulation** | Single AMM price | Chainlink TWAP, multi-source |
| **Front-running** | MEV bots steal profit | Commit-reveal, submarine send |
| **Uninitialized Proxy** | `initialize()` callable by anyone | Proxy admin check |
| **Signature Replay** | Signature used cross-chain | Chain ID in EIP-712 domain |
| **Selfdestruct** | Force ETH to contract | Check `address(this).balance` invariant |
| **Delegatecall** | Storage collision | Same storage layout check |
| **Timestamp Dependence** | `block.timestamp` for RNG | VRF (Chainlink Verifiable Random) |

## 4. DeFi Exploit Patterns

### 4.1 MEV (Maximal Extractable Value)

```
User tx in mempool
        ↓
MEV Searcher: "Can I profit from this?"
    ├── Simple sandwich: buy before user → sell after user
    ├── Liquidate: monitor health factors
    ├── Arbitrage: move across DEX price differences
    └── JIT liquidity: add/remove LP in same block
```

```python
# Sandwich attack detection
# User places market buy 100 ETH on Uniswap
# Bot sees tx in mempool:
#   1. Front-run: buy 50 ETH (price spikes)
#   2. User buys 100 ETH (price spikes more)
#   3. Back-run: sell 50 ETH (profit = user's slippage)
```

### 4.2 Cross-Chain Bridge Attacks

Bridges are **the most exploited DeFi vector** because they concentrate value:

```
Bridge Attack Flow:
1. Identify bridge contract with deposit/withdraw functions
2. Call deposit on source chain (e.g., Ethereum)
3. Exploit validator verification (fake signature)
4. Call withdraw on destination chain (e.g., BSC)
5. Double-spend: original ETH still on Ethereum, ETH minted on BSC
```

## 5. Smart Contract Auditing Workflow

### 5.1 Audit Methodology

```
Phase 1: Scope & Recon
├── Understand protocol architecture
├── Identify trust assumptions
└── List all entry points

Phase 2: Manual Analysis
├── Read code function by function
├── Data flow analysis
├── Access control matrix
└── Economic model review

Phase 3: Automated Analysis
├── Slither (static analysis)
├── Echidna (property-based fuzzing)
├── Foundry fuzz (production testing)
└── Certora Prover (formal verification)

Phase 4: Attack Simulation
├── Write Foundry test for each attack vector
└── Simulation environment (fork mainnet)

Phase 5: Report
├── Findings by severity (Critical/High/Medium/Low)
├── Proof of concept (PoC) code
├── Fix recommendation
└── Post-fix verification
```

### 5.2 Essential Audit Tools

```bash
# Slither — static analysis
slither . --detect reentrancy-eth,reentrancy-no-eth,uninitialized-state,unused-return

# Echidna — property-based fuzzing
echidna-test . --contract CryticTester --config echidna.yaml

# Foundry — fast RPC testing
forge test -vvvv --match-test testOracleManipulation

# Mythril — symbolic execution
myth analyze src/Contract.sol --solc-json solc.json
```

### 5.3 Common Severity Classification

| Severity | Definition | Example |
|----------|------------|---------|
| **Critical** | Direct loss of user/protocol funds | Reentrancy on withdraw |
| **High** | Indirect fund loss, broken invariant | Oracle manipulation |
| **Medium** | Unexpected behavior, gas inefficiency | Unchecked return value |
| **Low** | Informational, best practices | Floating pragma |

## 6. Cryptocurrency Forensics

### 6.1 Blockchain Analysis

```python
# Query blockchain data via API
import requests

# Etherscan API — get address transactions
def get_tx_history(address):
    url = f"https://api.etherscan.io/api"
    params = {
        'module': 'account',
        'action': 'txlist',
        'address': address,
        'startblock': 0,
        'endblock': 99999999,
        'sort': 'desc',
        'apikey': 'YOUR_API_KEY'
    }
    return requests.get(url, params=params).json()

# Wallet clustering: group addresses by
# 1. Same deposit address on exchange
# 2. Change address in same tx
# 3. Same source in coinjoin
# 4. Behavioral pattern (timing, fees, protocol)
```

### 6.2 Wallet Clustering

```
Chainalysis-style clustering:
Transaction A: X → Y (change address Z)
Transaction B: X → P (change address Q)
Transaction C: Y → R

Cluster: {X, Y, Z, P, Q} — same owner!

Risk scoring:
├── Direct: exposure (KYC exchange → wallet)
├── Heuristic: same IP, same deposit time
├── Behavioral: consistent with TTP of threat actor
└── Graph: 2-3 hops from known illicit address
```

### 6.3 Analysis Tools

| Tool | Purpose | Source |
|------|---------|--------|
| **Chainalysis** | Enterprise: AML, KYC, investigative | Commercial |
| **Elliptic** | Enterprise: compliance, risk scoring | Commercial |
| **TRM Labs** | Enterprise: real-time transaction screening | Commercial |
| **CipherTrace** | Enterprise: crypto intelligence | Commercial |
| **OXT** | Public blockchain explorer with clustering | Open-source |
| **Walletexplorer** | Address clustering (Bitcoin) | Open-source |
| **Blockchain.com/explorer** | Basic tx viewing | Free |
| **Dune Analytics** | SQL-based DeFi analysis | Free |
| **Etherscan** | Ethereum tx explorer | Free |
| **Bitquery** | GraphQL blockchain API | Freemium |

### 6.4 Taint Analysis

```python
# Trace funds from hack address
# 1. Start from contract that was drained
hack_contract = "0x..."
initial_tx = "0x..."  # The exploit tx
trace = [hack_contract]

# 2. Follow funds: which addresses received from hack_contract?
# 3. Every hop = stronger obfuscation, but also cost (gas)
# 4. Look for exchange deposit addresses (KYC chokepoint)

# Typical obfuscation layers:
# Layer 1: Direct from exploit (hot wallet — traceable)
# Layer 2: DEX swap (ETH → DAI → USDC → renBTC)
# Layer 3: Cross-chain bridge (Ethereum → BSC → Solana)
# Layer 4: Privacy mixer (Tornado Cash / RAILGUN)
# Layer 5: P2P OTC / DeFi lending withdraw
```

## 7. Quantum Threat to Blockchain

### 7.1 Timeline

| Year | Event | Implication |
|------|-------|-------------|
| 1994 | Shor's algorithm discovered | RSA/ECC broken in theory |
| 2019 | Google quantum supremacy (53q) | "Computational" but not cryptanalytic |
| 2024 | IBM 1121-qubit Condor | Still not factoring RSA-2048 |
| 2028+ | Expected: 4000+ logical qubits | **Bitcoin ECDSA vulnerable** |
| 2035+ | Fault-tolerant quantum computer | All ECC/RSA broken |

### 7.2 Threats to Blockchain

| Blockchain Component | Algorithm | Quantum Threat | Timeline |
|---------------------|-----------|----------------|----------|
| **Bitcoin/ETH address** | ECDSA secp256k1 | Shor: derive private key from public key | If attacker sees tx before confirm |
| **Ethereum** | ECDSA | Same — exposed on signing | Every signed tx exposes pubkey |
| **Most blockchains** | ECDSA/EdDSA | Vulnerable | ~10-15 years for fault-tolerant Q |
| **Mining** | SHA-256 (Bitcoin) | Grover: 2x speedup only | Minor threat |
| **Hashing** | SHA-2, SHA-3 | Grover: sqrt(N) → not broken | Quantum-resistant |
| **PoS signatures** | BLS (Ethereum) | Critical (aggregated signatures) | Need lattice-based BLS |

## 8. Koneksi ke Vault

| Note | Hubungan |
|------|----------|
| [[cryptography-biometrics]] | Post-quantum crypto relevance, ECDSA analysis |
| [[exploit-development]] | Smart contract exploitation, bytecode injection |
| [[fuzzing-vulnerability-research]] | Echidna property-based fuzzing for smart contracts |
| [[comprehensive-threat-directory]] | Web3 threat actors, smart contract malware |
| [[underground-knowledge]] | Dark web marketplace analysis, crypto mixing |
| [[digital-privacy-anonymity]] | Crypto scam awareness, phishing prevention |
| [[quantum-cryptography-deepdive]] | Post-quantum signatures for blockchain future |

---

### 📚 Referensi

1. SWC Registry: [https://swcregistry.io/](https://swcregistry.io/) — Smart contract weakness classification
2. OpenZeppelin Security Audits: [https://blog.openzeppelin.com/](https://blog.openzeppelin.com/)
3. Consensys Smart Contract Best Practices: [https://consensys.github.io/smart-contract-best-practices/](https://consensys.github.io/smart-contract-best-practices/)
4. DASP Top 10: [https://dasp.co/](https://dasp.co/)
5. Chainalysis Reports: [https://www.chainalysis.com/](https://www.chainalysis.com/)
6. "Mastering Ethereum" — Antonopoulos, Wood
7. Immunefi: DeFi bug bounty platform: [https://immunefi.com/](https://immunefi.com/)
8. Solidity Security by Example: [https://solidity-by-example.org/](https://solidity-by-example.org/)