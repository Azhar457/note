---
title: Attack Perspective — Digital Plumbing (TLS, OpenSSL, Certificate, Encoding)
tags:
- attack
- red-team
- tls
- openssl
- certificate
- encoding
- deserialization
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Digital Plumbing — Perspektif Penyerang

> Digital plumbing = protokol, encoding, serialization, certificate. Red team serang implementasi — bukan algoritma — karena implementasi bug lebih umum daripada crypto break.

## 1. Attack Surface Digital Plumbing

| Komponen | Vektor | MITRE ID | CVE / Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------------|---------|----------------|
| **TLS 1.2 downgrade** | Force client ke cipher lemah | T1565.002 | POODLE (SSLv3), BEAST (CBC) | Downgrade = silent, client tidak aware | TLS version monitoring jarang |
| **Heartbleed** | Memory leak via heartbeat | T1190 | CVE-2014-0160 | Exploit dari jarak jauh, automatic | Server patch — tapi unpatched server masih ada |
| **ROBOT** | RSA padding oracle di TLS | T1190 | CVE-2017-11185 | Timing attack — banyak request — tapi otomatis | TLS oracle detection jarang |
| **Logjam** | Weak DH export grade | T1190 | CVE-2015-4000 | Downgrade ke 512-bit DH | DH param audit jarang |
| **Certificate fraud** | Fake cert, CA compromise | T1557 | DigiNotar (2011), CNNIC (2015) | MitM dengan cert valid (dari CA compromise) | CT log monitoring — tapi jarang real-time |
| **OCSP soft-fail** | Revocation tidak enforced | T1557 | Browser default soft-fail | Revoked cert = tetap diterima | OCSP stapling jarang |
| **Encoding bypass** | URL/double/Unicode/Base64/Hex | T1190 | Encoding chain untuk WAF bypass | Multi-layer encoding = signature miss | WAF signature = trivial bypass |
| **Deserialization RCE** | Java/.NET/PHP gadget chain | T1190 | ysoserial, ysoserial.net, PHPGGC | Gadget chain selection, encoding | DAST jarang detect deserialization |
| **XXE** | XML external entity injection | T1190 | XXE blind, OOB, error-based | OOB = exfil via DNS, no direct response | XML parser config audit jarang |
| **JWT attack** | alg:none, key confusion, weak secret | T1143 | JWT_Tool, jwt.io | alg:none = no signature, key confusion = HS/RS | JWT validation jarang di-audit |

## 2. TLS Attack Chain

```
Recon: Scan target TLS (testssl.sh, sslyze) → identify version, cipher, cert
 ↓
Downgrade: Force TLS 1.0/1.1 atau cipher lemah (CBC, RC4)
 ↓
Exploit: POODLE (CBC padding oracle) / ROBOT (RSA oracle) / Heartbleed (memory leak)
 ↓
Data: Decrypt cookie/session → private key extraction → MitM
 ↓
Persistence: Inject root CA → semua future traffic = interceptor
```

## 3. Deserialization Attack Chain

```
Recon: Identifikasi endpoint yang terima serialized data (Java RMI,.NET ViewState, PHP session)
 ↓
Fingerprint: YaSoSerial → identify framework (Spring, Jackson, Commons Collections)
 ↓
Gadget chain: Pilih chain yang ada di classpath target
 ├── Commons Collections 1-7 (Java)
 ├── Groovy (Java)
 ├── Jackson (Java)
 ├── ViewState (.NET)
 └── PHPGGC (PHP)
 ↓
Payload: Chain → execute command / reverse shell
 ↓
Delivery: Inject ke endpoint (Cookie, POST body, ViewState, RMI)
 ↓
Evasion: Encode (Base64), compress (gzip), obfuscate class name
```

## 4. CVE Prioritas Digital Plumbing

| CVE | Target | Impact | Red Team Value |
|-----|--------|--------|----------------|
| CVE-2014-0160 | OpenSSL Heartbleed | Memory leak → private key + user data | Historical — unpatched server masih ada |
| CVE-2017-11185 | RSA TLS (ROBOT) | Padding oracle → key extraction | Banyak server masih vulnerable |
| CVE-2015-4000 | DH (Logjam) | Downgrade ke 512-bit DH | Server dengan export DH masih ada |
| CVE-2017-5638 | Apache Struts (deserialization) | RCE via OGNL injection | Critical — Equifax breach |
| CVE-2021-44228 | Log4Shell (JNDI injection) | RCE via log message | Critical — Everywhere |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **testssl.sh** | TLS audit (version, cipher, cert, vulnerability) |
| **sslyze** | TLS scan (deep, programmatic) |
| **ysoserial** | Java deserialization payload generator |
| **ysoserial.net** |.NET deserialization payload |
| **PHPGGC** | PHP deserialization payload |
| **JWT_Tool** | JWT analysis + attack (alg:none, brute, confusion) |
| **XXEer** | XXE injection + OOB exfil |
| **Burp Suite** | Proxy + encoding bypass manual |

## 6. Referensi
- testssl.sh — https://github.com/drwetter/testssl.sh
- Heartbleed — https://heartbleed.com/
- ROBOT Attack — https://robotattack.org/
- ysoserial — https://github.com/frohoff/ysoserial
- Log4Shell (CVE-2021-44228) — https://logging.apache.org/log4j/2.x/security.html
---

audited
---
