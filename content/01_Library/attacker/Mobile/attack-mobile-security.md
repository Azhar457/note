---
title: Attack Perspective — Mobile Security (Red Team)
tags: [attack,red-team,mobile,android,ios,root,frida,smali,deep-link]
source: mobile-security.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Mobile Security — Perspektif Penyerang

> Mobile = bypass 2FA, exfil data pribadi, compromise corporate BYOD. Red team: APK RE (smali patch), Frida hook, deep link abuse, SSL pinning bypass, rooted device exploit.

## 1. Attack Surface Mobile

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **APK** | Decompile → smali patch → repack → sign | T1055 | apktool, jadx, apksigner | Repacked = valid signature (attacker key) | Play Integrity = partial |
| **Frida Hook** | Hook function → bypass auth, intercept data | T1055 | Frida, objection | In-memory = no disk artifact | Frida detect = partial (root check) |
| **Deep Link** | Malicious URL → trigger app activity → data exfil | T1190 | adb, intent fuzz, deeplink audit | Deep link = legit URL | Deep link audit = rare |
| **SSL Pinning** | Pinning bypass → MITM app traffic | T1557 | objection, Frida SSL unpin | In-memory hook → no cert install | MITM detect = rare (app-side) |
| **Root** | Root device → access app data, bypass sandbox | T1068 | Magisk, Frida server | Root = legit (user device) | Root detect = partial (SafetyNet) |
| **Backup** | adb backup → app data → credential | T1552 | adb backup, abe extract | Backup = legit operation | Backup audit = rare |
| **SharedPrefs/DB** | SQLite DB → credential/secret | T1552 | adb shell, sqlite3 | DB = app data → legit access | Local DB audit = rare |
| **OAuth Flow** | Token theft via deep link redirect | T1557 | Custom redirect URI abuse | Redirect = legit flow | OAuth audit = rare |

## 2. APK Patch Chain (Repack)

```
Prereq: APK target (official or sideload)
    ↓
Decompile:
  ├── apktool d target.apk → smali + resources
  ├── jadx → Java source (readable)
  └→ Identifikasi: auth check, license check, API endpoint, secret
    ↓
Patch (smali):
  ├── Bypass auth: nop out check → force true
  ├── Modify API endpoint → redirect C2
  ├── Inject logging → exfil data
  └── Disable root/emulator detect → bypass anti-analysis
    ↓
Rebuild:
  ├── apktool b → new APK
  ├── Sign: apksigner sign --ks attacker.keystore
  └→ zipalign → install
    ↓
Delivery: Sideload / phishing / compromised app store
    ↓
Result: Modified app → bypass auth → data access → C2
```

## 3. Frida Attack Chain

```
Recon: Target app (rooted device or emulator)
    ↓
Frida Server: Push frida-server → run as root
    ↓
Hook:
  ├── objection → automated: SSL unpin, root detect bypass, class enum
  ├── Frida script: hook auth function → return true
  ├── Intercept API response → modify data
  └── Dump keystore / SharedPreferences / SQLite
    ↓
Bypass:
  ├── SSL pinning: objection android sslpinning disable
  ├── Root detect: hook RootBeer / SafetyNet → return false
  ├── Biometric: hook BiometricPrompt → onAuthenticationSucceeded
  └── Emulator detect: hook Build.FINGERPRINT → real device
    ↓
Impact: Full app data access → credential → API → backend
```

## 4. Deep Link Abuse

```
Enum: aapt dump xmltree → AndroidManifest → intent-filter
  ├── scheme://host/path → deep link
  ├── App Links (verified) vs Intent (unverified)
  └→ Find: login callback, token exchange, file open
    ↓
Exploit:
  ├── Malicious URL: scheme://host/login?token=attacker
  ├── Token theft: redirect URI → attacker domain
  ├── Arbitrary file open: file:// → exfil
  └→ Activity launch: launch internal activity → bypass auth
    ↓
Delivery: SMS phishing / in-app link / QR code
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **apktool** | APK decompile/rebuild (smali) |
| **jadx** | APK → Java source |
| **apksigner** | Sign repacked APK |
| **Frida** | Dynamic instrumentation (hook, bypass) |
| **objection** | Automated Frida (SSL unpin, root bypass) |
| **adb** | Device access, backup, shell |
| **Burp Suite** | Mobile traffic intercept (with pinning bypass) |

## 6. Referensi
- Frida — https://frida.re/
- Objection — https://github.com/sensepost/objection
- apktool — https://ibotpeaches.github.io/Apktool/
- OWASP MASVS — https://mas.owasp.org/
- Mobile Security Framework (MobSF) — https://github.com/MobSF/Mobile-Security-Framework-MobSF