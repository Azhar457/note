---
title: 'Mobile Application Security — Deep Dive: Android Pentesting, iOS Security,
  OWASP MASVS, Reverse Engineering APK/IPA'
tags:
- mobile-security
- android
- ios
- pentesting
- reverse-engineering
- owasp
- app-security
created: '2026-07-18'
updated: '2026-07-18'
status: pending
cssclasses:
  - wide-table
  - callout

---

# 📱 Mobile Application Security — Deep Dive: Android Pentesting, iOS Security, OWASP MASVS, Reverse Engineering APK/IPA

> Panduan komprehensif keamanan aplikasi mobile — dari Android (APK reversing, Smali patching, Frida hooking, Drozer, ADB forensics) sampai iOS (IPA decryption, class-dump, Frida/objection, Keychain, iOS app sandbox). Mencakup OWASP Mobile Application Security Verification Standard (MASVS) Level 1-3, mobile app reverse engineering (Jadx, Ghidra, Hopper), runtime instrumentation (Frida, Xposed, Cycript), network interception (mitmproxy, Burp Suite untuk mobile), mobile malware analysis, dan platform-specific attack surface (Android Intents, iOS URL Scheme, WebView, Deep Link). Vault udah punya [[web-hacking-exploitation]] (web) dan [[browser-security-exploitation-deepdive]] (browser) — catatan ini melengkapi dari sisi mobile app.

> [!info] Posisi di Vault
> Catatan ini melengkapi [[web-hacking-exploitation]] (web app pentesting) dan [[browser-security-exploitation-deepdive]] (browser security) dengan **mobile-specific attack surface**. Juga terkait dengan [[mobile-forensics]] (data forensik device — beda scope), [[api-security-deep-dive]] (mobile API security — sebagian besar mobile app backend-nya API), [[identity-and-access-management]] (mobile auth — OAuth, JWT), [[cryptography-biometrics]] (mobile crypto — Keychain, Keystore, Secure Enclave), dan [[endpoint-detection-playbook]] (mobile endpoint — EDR untuk mobile).

---

## Daftar Isi

- [[#OWASP MASVS — Mobile App Security Standard]]
- [[#Android Security Model]]
- [[#Android Pentesting]]
- [[#iOS Security Model]]
- [[#iOS Pentesting]]
- [[#Mobile API Security]]
- [[#Runtime Instrumentation]]
- [[#Mobile Malware]]
- [[#Toolchain Perbandingan]]
- [[#Koneksi ke Vault]]

---

## OWASP MASVS — Mobile App Security Standard

### Tingkatan MASVS

| Level | Nama | Tujuan | Cocok Untuk |
|-------|------|--------|-------------|
| **L1** | Standard Security | Verifikasi dasar — semua app wajib | App biasa, internal app |
| **L2** | Defense-in-Depth | Pertahanan berlapis — anti-tamper, anti-debug, jailbreak detection | Fintech, health, enterprise |
| **L3** | Resiliency Against Reverse Engineering | Reverse engineering sangat sulit — obfuscation, white-box crypto, integrity check | DRM, payment, high-value IP |

### MASVS Categories (8 Group)
1. **MSTG-ARCH** — Architecture, design, threat modeling
2. **MSTG-STORAGE** — Data storage & privacy (Keychain, Keystore, NSUserDefaults)
3. **MSTG-CRYPTO** — Cryptography (mobile-specific: Keychain, TEE, Secure Enclave)
4. **MSTG-AUTH** — Authentication & session management (biometric, OAuth)
5. **MSTG-NETWORK** — Network communication (TLS pinning, certificate validation)
6. **MSTG-PLATFORM** — Platform interaction (Intents, URL Scheme, WebView, Deep Links)
7. **MSTG-CODE** — Code quality & anti-tampering (obfuscation, jailbreak detection)
8. **MSTG-RESILIENCE** — Resilience against reverse engineering (Frida detection, anti-debug)

## Android Security Model

### Android Architecture
```
┌────────────────────────────────┐
│        Applications            │ ← Sandboxed per-user ID
├────────────────────────────────┤
│        Android Framework       │ ← Permissions, Content Providers, Intents
├────────────────────────────────┤
│        Android Runtime (ART)   │ ← AOT + JIT compilation
├────────────────────────────────┤
│        Hardware Abstraction    │ ← HAL, Keystore, TEE
├────────────────────────────────┤
│        Linux Kernel            │ ← SELinux, namespaces, DAC
└────────────────────────────────┘
```

### Android Attack Surface

| Surface | Kerentanan Umum | Impact |
|---------|----------------|--------|
| **APK** | Reverse engineering (Jadx, APKTool) | Source code leak, hardcoded secret |
| **Intent** | Intent spoofing, intent redirection | Privilege escalation, data leak |
| **Content Provider** | SQL injection, path traversal | Database access, file read |
| **WebView** | XSS via JavaScript bridge, file:// access | RCE (JavaScript→Java bridge) |
| **SharedPreferences** | Unencrypted local storage | Credential leak |
| **Deep Link** | URL scheme hijacking | Session hijack, phishing |
| **Backup** | ADB backup tanpa password | Full app data extraction |
| **Logging** | Logcat — sensitive info di log | Information disclosure |

### Android Permission Model
- **Normal** — auto-grant (INTERNET, ACCESS_NETWORK_STATE)
- **Dangerous** — user grant runtime (CAMERA, LOCATION, READ_CONTACTS)
- **Signature** — same signature only (vendor-specific)
- **SignatureOrSystem** — system app only

## Android Pentesting

### Setup Lab
```
Device: rooted Pixel / Emulator with root
Tools: ADB, Frida, objection, APKTool, Jadx, Burp Suite, Drozer, Magisk
```

### Step-by-Step Pentest

#### 1. APK Extraction & Analysis
```bash
# Extract APK from installed app
adb shell pm list packages | grep com.target
adb shell pm path com.target.app
adb pull /data/app/.../base.apk target.apk

# Decompile
apktool d target.apk -o target_extracted/
jadx-gui target.apk  # Java source code
```

#### 2. Static Analysis Checklist
- [ ] Hardcoded API keys, tokens, secrets di strings.xml atau Java code
- [ ] Root/jailbreak detection — dimana? Bisa bypass?
- [ ] Certificate pinning implementation — TrustManager custom?
- [ ] WebView JavaScript interface — ada @JavascriptInterface ekspos?
- [ ] Backup flag — `android:allowBackup="true"`?
- [ ] Deep link verification — `android:autoVerify="true"`?
- [ ] Intent filter exposure — komponen yang tidak di-export tapi bisa diakses?

#### 3. Dynamic Analysis (Runtime)
```bash
# Frida — bypass root detection
frida -U -l bypass_root.js com.target.app

# objection — mobile exploration
objection -g com.target.app explore
# Dalam objection shell:
# android root disable
# android sslpinning disable
# android hooking list classes

# Drozer — Android security audit
drozer console connect
dz> run app.activity.info -a com.target.app
dz> run app.provider.info -a com.target.app
dz> run scanner.provider.finduris -a com.target.app
```

#### 4. Network Interception
```bash
# Burp Suite setup
adb shell settings put global http_proxy 192.168.1.100:8080

# Install Burp CA di system trust store (rooted device)
adb push burp-ca.der /sdcard/
adb shell
su
mount -o rw,remount /system
cp /sdcard/burp-ca.der /etc/security/cacerts/9a5ba575.0
chmod 644 /etc/security/cacerts/9a5ba575.0

# Jika ada certificate pinning → Frida bypass
frida -U -l ssl_pinning_bypass.js com.target.app
```

#### 5. Local Storage Extraction
```bash
# ADB backup (tanpa password — insecure)
adb backup -f app_backup.ab com.target.app
(echo 00; dd if=app_backup.ab bs=24 skip=1) | openssl zlib -d > backup.tar

# Direct database access (rooted device)
adb shell
su
cat /data/data/com.target.app/databases/app.db
sqlite3 /data/data/com.target.app/databases/app.db .dump

# SharedPreferences & internal storage
cat /data/data/com.target.app/shared_prefs/*.xml
cat /data/data/com.target.app/files/*.json
```

## iOS Security Model

### iOS Architecture
```
┌────────────────────────────────┐
│        Applications            │ ← Sandbox, code signing mandatory
├────────────────────────────────┤
│      Cocoa Touch (UIKit)       │
├────────────────────────────────┤
│       Media / Core Services    │ ← Keychain, iCloud, Push
├────────────────────────────────┤
│      Core OS / Kernel (XNU)    │ ← Mach, BSD, sandbox (Seatbelt)
├────────────────────────────────┤
│    Secure Enclave + SEP        │ ← Biometric, crypto, hardware key
└────────────────────────────────┘
```

### iOS vs Android Security

| Aspek | Android | iOS |
|-------|---------|-----|
| **App Distribution** | Multiple stores, sideloading allowed | App Store only (wajib review) |
| **Code Signing** | Optional (APK sign) | Mandatory — semua app harus signed |
| **Sandbox** | Per-user ID (Linux) | Seatbelt + sandbox profile |
| **Encryption** | File-based (since Android 7) | Hardware-backed (Secure Enclave) |
| **Jailbreak** | Root (easy) | Jailbreak (difficult — need exploit) |
| **Permission** | Runtime (since 6.0) | Runtime (since iOS 10) |
| **App review** | No official review | App Store review |
| **Third-party keyboard** | Yes | Yes (since iOS 8) |
| **App Cloning** | Native support | Not allowed |

## iOS Pentesting

### Setup Lab
```
Device: jailbroken iPhone/iPad
Tools: frida-ios-dump, class-dump, Hopper, objection, Frida, Keychain-Dumper, needle
```

#### 1. IPA Extraction & Decryption
```bash
# Dump decrypted IPA dari jailbroken device
frida-ios-dump -u -o target.ipa com.target.app

# Class information
class-dump -H target.ipa extracted_headers/

# Or with objection
objection explore
objection> ios info binary
```

#### 2. iOS Static Analysis
```bash
# Binary analysis with Hopper/Ghidra
# Check: hardcoded keys, pinning, encryption

# Info.plist analysis
plutil -p extracted_app/Payload/App.app/Info.plist

# Check:
# - NSAppTransportSecurity (ATS) — di-disable?
# - Exported URL Schemes
# - Background modes
# - Keychain access groups
```

#### 3. iOS Runtime Analysis
```bash
# Frida — hook Objective-C methods
frida -U com.target.app -l ios_hook.js

# objection — iOS exploration
objection -g com.target.app explore
objection> ios jailbreak disable
objection> ios sslpinning disable
objection> ios hooking list classes
objection> ios keychain dump

# Keychain extraction
objection> ios keychain dump
frida -U --codeshare mrmacete/find-and-bypass-ios-ssl-pinning
```

#### 4. iOS Data Storage
```bash
# App sandbox access (jailbroken)
/var/mobile/Containers/Data/Application/<UUID>/
# Check:
# - Documents/ — user data
# - Library/Preferences/ — NSUserDefaults (plist)
# - Library/Caches/ — cached data (maybe sensitive)
# - tmp/ — temporary files

# Keychain Dumper
./Keychain-Dumper -a  # Dump all keychain items
```

#### 5. iOS Reversing
```bash
# Hopper: decompile ObjC → pseudo-code
# Frida codeshare: banyak script siap pakai

# Trace ObjC method calls
frida -U com.target.app -l ios_trace.js

# Dump NSUserDefaults
frida -U com.target.app -e "NSUserDefaults.alloc().initWithSuiteName_('com.target.app').dictionaryRepresentation()"
```

## Mobile API Security

Mobile apps mostly communicate via REST/GraphQL API. Pastikan:

| Check | Kenapa | Tools |
|-------|--------|-------|
| **API Key hardcoded?** | String di APK bisa dibaca | Jadx, strings, Ghidra |
| **No certificate pinning** | MITM via proxy | Burp Suite, mitmproxy |
| **Rate limiting missing** | Account takeover via brute force | Custom Frida, DroidBot |
| **Weak OAuth flow** | Authorization code interception | Burp OAuth scanner |
| **GraphQL introspection enabled** | Full schema exposed | GraphiQL, introspection query |
| **JWT weak secret** | Token forgery | jwt_tool, John |

## Runtime Instrumentation

### Frida — Universal Tool
```bash
# Android
frida -U com.target.app -l script.js

# iOS
frida -U com.target.app -l script.js

# Key Frida use cases:
# 1. Bypass SSL pinning
# 2. Bypass root/jailbreak detection
# 3. Hook function → change return value
# 4. Dump method arguments
# 5. Trace method calls
```

### Objection — Mobile Exploration Platform
```bash
objection -g com.target.app explore
# Commands:
# android hooking list classes
# android hooking watch class com.target.login
# ios hooking list classes
# ios jailbreak disable
# ios sslpinning disable
# android sslpinning disable
# android root disable
```

### Xposed (Android only)
- Permanent module-based hooking
- Module: SSLUnpinning, XposedInstaller, RootCloak
- Kelemahan: require reboot setiap ganti module, gak work di Android 10+

### Frida vs Xposed

| Aspek | Frida | Xposed |
|-------|-------|--------|
| **Permanence** | Session-based | Module (permanent) |
| **Android version** | All (5+) | Android 4-9 (deprecated 10+) |
| **iOS support** | ✅ | ❌ |
| **Setup** | No reboot | Need reboot |
| **Detection** | Mudah dideteksi (port 27042) | Moderate (check /system) |
| **Flexibility** | Sangat tinggi (JavaScript) | Medium (Java modules) |

## Mobile Malware

### Android Malware Types

| Type | Behavior | Example |
|------|----------|---------|
| **Banking Trojan** | Overlay phishing, SMS intercept | Cerberus, Anubis, TeaBot |
| **Spyware** | Call recording, location tracking | Pegasus (iOS), Triout |
| **Ransomware** | Lock screen, file encryption | Simplocker, Koler |
| **Adware** | Aggressive ads, background install | Judy, HummingBad |
| **Dropper** | Download & install second-stage payload | Hiddad, Moqhao |

### Detection Techniques
- **Static** — signature-based (YARA rules)
- **Dynamic** — behavior analysis (sandbox, network monitoring)
- **ML-based** — permission anomalies, API call patterns

## Toolchain Perbandingan

| Tool | Android | iOS | Fungsi | Harga |
|------|---------|-----|--------|-------|
| **Jadx** | ✅ | ❌ | APK to Java decompiler | Free |
| **APKTool** | ✅ | ❌ | APK decode, rebuild | Free |
| **Frida** | ✅ | ✅ | Runtime instrumentation | Free |
| **objection** | ✅ | ✅ | Mobile exploration | Free |
| **Drozer** | ✅ | ❌ | Android security audit | Free |
| **class-dump** | ❌ | ✅ | iOS ObjC header extraction | Free |
| **Hopper** | ❌ | ✅ | iOS binary disassembler | $ |
| **Ghidra** | ✅ | ✅ | Binary reverse engineering | Free |
| **Burp Suite** | ✅ | ✅ | Proxy, scanner | Free/Pro |
| **Needle** | ❌ | ✅ | iOS security testing | Free |
| **MobSF** | ✅ | ✅ | Automated mobile security scan | Free |
| **MVT** | ✅ | ✅ | Mobile Verification Toolkit (forensics) | Free |

---

## Koneksi ke Vault

- [[web-hacking-exploitation]] — Web app pentesting — mobile app backend adalah API/Web
- [[api-security-deep-dive]] — Mobile API security — sebagian besar serangan mobile di layer API
- [[browser-security-exploitation-deepdive]] — Browser security — WebView di mobile = browser mini
- [[mobile-forensics]] — Mobile data forensik — beda scope (forensik vs app pentesting)
- [[identity-and-access-management]] — Mobile auth — OAuth2, JWT, biometric
- [[cryptography-biometrics]] — Mobile crypto — Keychain, Keystore, Secure Enclave
- [[hardware-hacking-re|reverse-engineering]] — RE secara umum — APK/IPA reversing
- [[malware-analysis-reverse-engineering-playbook]] — Malware analysis — mobile malware
- [[laptop-qc-procurement]] — SOP QC — mobile device testing juga
- [[endpoint-detection-playbook]] — Endpoint security — mobile EDR/MDM
