---
title: "Security Chaos Engineering — Resilience Testing & Antifragile Systems"
tags:
  - chaos-engineering
  - resilience
  - antifragile
  - security-testing
  - sre
aliases:
  - "security-chaos-engineering"
created: "2026-07-19"
updated: "2026-07-19"
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Security Chaos Engineering = **sengaja inject failure** untuk menguji resilience sistem keamanan. Berbeda dari pentest yang fokus exploit, chaos engineering fokus: "when something breaks, does our security hold?" Melengkapi [[purple-team-osi-killchain]] dengan dimensi resilience testing.
>
> **Domain:** DevOps / Security Engineering
> **Tags:** #chaos-engineering #resilience #antifragile #security-testing #sre

## 1. Principles

### 1.1 Steady State Hypothesis

```python
# Define: "what does normal look like?"
STEADY_STATE = {
    "auth_success_rate": 0.99,
    "error_5xx_rate": 0.001,
    "p99_latency_ms": 200,
    "cpu_usage_pct": 0.7,
}

def run_experiment():
    inject_failure("block_auth_service_30s")
    measure("auth_success_rate")  # Should return to 0.99 within 30s
    measure("error_5xx_rate")     # Should not exceed 0.01
    measure("p99_latency_ms")     # Should return to baseline
```

### 1.2 Security Chaos Experiments

| Experiment         | Injection           | Expected Behavior                 |
| ------------------ | ------------------- | --------------------------------- |
| **WAF Failure**    | Disable WAF         | Backend auth should block attacks |
| **Cert Expiry**    | Expire TLS cert     | Proper error, no fallback to HTTP |
| **Log Drop**       | Stop log shipping   | Alert, buffer, no crash           |
| **Auth Down**      | Kill auth service   | Cached auth, graceful degradation |
| **DNS Fail**       | Block DNS           | Cached resolution, no data leak   |
| **Rate Limit Off** | Remove rate limiter | DDoS: backend should still defend |

---

### 📚 Referensi

1. "Chaos Engineering" — Rosenthal, Jones
2. Principles of Chaos: [https://principlesofchaos.org/](https://principlesofchaos.org/)
3. Security Chaos Engineering: [https://securitychaos.com/](https://securitychaos.com/)
