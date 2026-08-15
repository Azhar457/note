---
title: Attack Perspective — Browser Fingerprinting & Fingerprint Evasion
tags:
- attack
- red-team
- browser
- fingerprinting
- evasion
- tracking
source: browser-fingerprinting-defense.md
status: complete
created: '2026-08-14'
updated: '2026-08-14'
cssclasses:
  - wide-table
  

---

# 🔴 Attack Perspective: Browser Fingerprinting — Evasion & Spoofing

> **Perspektif red team:** Browser fingerprinting bukan hanya "defense tracking" — tapi juga **attacker reconnaissance vector** (fingerprint target browser → pilih exploit yang cocok) dan **evasion requirement** (red team harus blend dengan fingerprint normal, bukan outlier yang mudah di-flag).

---

## 1. Fingerprint Vectors — Attacker Recon & Evasion

| Fingerprint Vector | Defender Use | Red Team Recon Value | Evasion Strategy | CVE / Tool Reference | |
|---|---|---|---|---|---|
| User-Agent | Browser + OS identification | Filter bot / anomaly | **Recon:** Identifikasi browser version → pilih exploit (CVE-2024-XXXX Chrome, CVE-2023-XXXX Firefox) | **Spoof:** Random UA rotation, match common profile (Chrome 120/Windows 10) — blend, bukan outlier | N/A — spoof via extension / proxy |
| Canvas / WebGL | Hardware rendering fingerprint | Bot detection, tracking | **Recon:** Canvas fingerprint → hardware profile → target profiling (graphics card = gaming / enterprise / mobile) | **Poison:** Add noise ke canvas pixel → random offset (1-3px) — fingerprint masih unique tapi tidak konsisten — defeat tracking | N/A — noise injection via Tampermonkey / custom browser |
| AudioContext | Audio hardware fingerprint | Tracking, bot detection | **Recon:** Audio fingerprint → hardware profile | **Spoof:** Modify AudioContext.getChannelData → inject noise — atau disable Web Audio (privacy setting) | N/A |
| Fonts / Plugin List | Software environment | Bot detection | **Recon:** Font list → OS + software installed → target profiling (font lang = region, enterprise font = corporate device) | **Limit:** Block font loading (CSS `font-display`), use generic font family — reduce fingerprint uniqueness | N/A |
| Screen / Window Size | Device profile | Tracking | **Recon:** Screen size → mobile vs desktop → exploit selection (mobile = different CVE set) | **Standardize:** Fixed viewport (1920x1080) — common profile — blend | |
| Timezone / Language | Geographic profiling | Tracking, geo-block | **Recon:** Timezone → target location → legal jurisdiction → C2 server selection | **Align:** Set browser locale ke target region — atau random (tapi blend dengan traffic target) | |
| Cookies / LocalStorage | Persistent tracking | Session tracking | **Recon:** Cookie persistence → return visitor → target profiling | **Clear:** Auto-clear cookies on exit — atau use incognito / container tab (Firefox Multi-Account Containers) | |
| TLS / JA3 Fingerprint | TLS handshake fingerprint | Bot / malware detection (C2 beacon fingerprint) | **Recon:** JA3 fingerprint → C2 framework identification (Cobalt Strike, Havoc, Sliver) — defender detect beacon | **Spoof:** Custom Malleable C2 profile — match browser JA3 — atau use custom TLS client (Go, Rust) — match common fingerprint | C2 framework Malleable profiles (Cobalt Strike, Havoc, Sliver) |

---

## 2. Red Team Playbook — Browser Fingerprint Evasion

**Scenario A: Red Team C2 Beacon Evasion (Defeat Browser-Based Bot Detection)**
1. **Recon:** Scan target site — check fingerprinting script (Canvas, Audio, Font, Plugin) — identify tracking method
2. **Profile:** Collect common fingerprint (Chrome 120 / Windows 10 / 1920x1080 / English) — build standard profile
3. **Spoof:** Configure browser / proxy — User-Agent = Chrome 120 — Canvas noise = 2px offset — Font list = standard Windows font — AudioContext = disabled / noise
4. **Blend:** C2 traffic — HTTPS — JA3 = match Chrome 120 — Jitter 30-300s — Business hours — Low bandwidth — Blend dengan normal user
5. **Clean:** Auto-clear cookies / localStorage — No persistent fingerprint — Per session = new identity

**Scenario B: Attacker Recon — Fingerprint Target Browser (Choose Exploit)**
1. **Recon:** Visit target site — collect fingerprint (Canvas + User-Agent + Font + Plugin) — identify browser version + OS + hardware
2. **Exploit Selection:** Browser = Chrome 117 (CVE-2023-4863 — WebP heap overflow) — OS = Windows 11 — Hardware = Desktop — Select exploit chain: WebP → Shellcode → Local PrivEsc (CVE-2023-4911)
3. **Delivery:** Phishing link → Drive-by download — exploit browser — payload = BOF (Cobalt Strike) — Evasion = Direct syscall + AMSI bypass

---

## 3. Defense Side Note (Brief — For Context Only)

- **Defender:** Browser fingerprinting detect bot, malware beacon, tracking evasion — menggunakan Canvas, Audio, Font, Plugin, TLS fingerprint — behavioral analytics (process tree + fingerprint consistency)
- **Red Team:** Evasion = blend fingerprint dengan common profile — noise injection — standard viewport — JA3 spoof — clean per session — tidak meninggalkan persistent fingerprint

---

## 4. References (Short)

- Browser Fingerprinting — https://browserleaks.com/
- Canvas Fingerprinting Defense — https://github.com/kkapsner/CanvasBlocker
- AudioContext Fingerprinting — https://audiofingerprint.openwpm.com/
- JA3 / TLS Fingerprint — https://ja3er.com/
- C2 Malleable Profiles — https://github.com/threatexpress/malleable-c2-profiles (Cobalt Strike)
- Firefox Multi-Account Containers — https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/

## Konkret — Browser Fingerprint (Testable)

### Canvas Fingerprint

```javascript
// Website: render text ke canvas → hash pixel = unique fingerprint
// 99% browser punya canvas fingerprint unique

// Defense (Tor Browser): return black image (no canvas data)
// Firefox: privacy.resistFingerprinting = true
//   → canvas.toDataURL() returns blank

// Manual testing (detect leak):
var canvas = document.createElement('canvas');
var ctx = canvas.getContext('2d');
ctx.textBaseline = "top";
ctx.font = "14px 'Arial'";
ctx.fillText("fingerprint", 0, 0);
var hash = canvas.toDataURL();  // unique per GPU + driver + font
console.log(hash);
```

### WebGL Fingerprint

```javascript
// WebGL renderer string = GPU vendor + model
var gl = document.createElement('canvas').getContext('webgl');
var ext = gl.getExtension('WEBGL_debug_renderer_info');
var vendor = gl.getParameter(ext.UNMASKED_VENDOR_WEBGL);   // "Google Inc."
var renderer = gl.getParameter(ext.UNMASKED_RENDERER_WEBGL); // "ANGLE (NVIDIA)"
console.log(vendor, renderer);
// Output: unique per GPU
```

### AudioContext Fingerprint

```javascript
// AudioContext: oscillator → AnalyserNode → fingerprint via FFT
var ctx = new AudioContext();
var oscillator = ctx.createOscillator();
var analyser = ctx.createAnalyser();
oscillator.connect(analyser);
analyser.connect(ctx.destination);
oscillator.frequency.value = 1000;
oscillator.start();
// Sample: fingerprint berbeda per CPU / audio stack
```

### Defense (Tor Approach)

```
1. Canvas: return identical blank canvas (no data)
2. WebGL: return generic vendor/renderer ("Mozilla", "Gecko/1.0")
3. Font: system font subset (no unique fonts)
4. Screen: fixed 1000x1000 internal resolution
5. User-Agent: identical (Tor Browser version x)
6. No plugins / extensions
7. Timezone: UTC (not leaking local zone)
8. No WebRTC ice candidates → no local IP
```
---

audited
---
