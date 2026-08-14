---
title: Attack Perspective — Biometrics (Red Team)
tags:
- attack
- red-team
- biometric
- fingerprint
- face
- iris
- presentation-attack
- frida
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Biometrics — Perspektif Penyerang

> Biometric = auth yang tidak bisa di-reset. Red team serang: presentation attack (spoof), template theft, Frida hook bypass, liveness detection bypass, biometric data breach (permanent).

## 1. Attack Surface Biometric

| Modality | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **Fingerprint** | Silicone clone, latex print, capacitive spoof | T1556 | Proxmark3 (RFID), silicone mold | Physical spoof = no digital trace | Liveness detection imperfect |
| **Face (2D)** | Photo print, screen replay, deepfake video | T1556 | DeepFace, Roop, phone screen | 2D face = trivial spoof | 2D → 3D liveness = partial |
| **Face (3D)** | 3D mask, deepfake + depth map | T1556 | Custom mask, deepfake + AR | 3D = harder, but feasible | 3D liveness = NIR/thermal gap |
| **Iris** | High-res photo + print, contact lens with iris pattern | T1556 | HD camera + printer | Iris = high entropy, but printable | Iris liveness = rare |
| **Voice** | Voice clone (ElevenLabs, xtts), playback | T1556 | ElevenLabs, Coqui TTS | Voice clone = real-time, phone call | Voice liveness = partial |
| **Behavioral** | Keystroke mimic, gait replay | T1556 | Custom script, recorded session | Behavioral = low entropy → brute feasible | Behavioral audit = rare |
| **Mobile (FIDO2)** | Frida hook → bypass biometric prompt → return true | T1556 | Frida, objection | Software bypass → no physical spoof | Frida detect = partial |

## 2. Mobile Biometric Bypass (Frida)

```
Recon: Identifikasi app dengan biometric auth (Android: BiometricPrompt, iOS: LocalAuthentication)
 ↓
Static Analysis:
 ├── jadx → search "BiometricPrompt" / "LAContext"
 ├── Identifikasi callback → onSuccess / onFailure
 └── Cari flag: keystore-backed atau software-only
 ↓
Bypass (Software-only):
 ├── Frida hook → intercept BiometricPrompt.authenticate()
 ├── Return callback.onAuthenticationSucceeded()
 └── App = "biometric passed" → access granted
 ↓
Bypass (Keystore-backed):
 ├── Key unlocks via biometric → but key di AndroidKeyStore
 ├── Hook keystore API → intercept key use → extract key
 └── Atau: race condition → use key saat biometric prompt show
 ↓
Evasion: Frida = memory inject → no disk artifact, no network trace
 ↓
Frida Detection Bypass:
 ├── Rename frida-server (random name)
 ├── Magisk Hide / Zygisk → hide root + Frida
 └── Anti-Frida bypass (hook ptrace, /proc/self/status check)
```

## 3. Deepfake Attack (Biometric)

| Teknik | Target | Tool | Detection Bypass |
|--------|--------|------|------------------|
| **Face swap (video)** | Video call auth, KYC | Roop, SimSwap, DeepFaceLab | 2D liveness = bypass; 3D = partial |
| **Real-time deepfake** | Live video call (Zoom, Teams) | DeepFaceLab real-time, neural-render | Real-time = match frame rate |
| **Voice clone** | Phone auth, voice assistant | ElevenLabs, xtts, Bark | Voice liveness = partial |
| **Lip sync** | Video KYC | Wav2Lip, Sync Labs | Lip sync + voice = convincing |
| **Synthetic identity** | KYC bypass, account creation | StyleGAN, thispersondoesnotexist | Synthetic face = no real identity |

## 4. Tool Stack

| Tool | Platform | Use |
|------|----------|-----|
| **Frida** | Android/iOS | Biometric prompt bypass, keystore hook |
| **objection** | Android/iOS | Automated Frida wrapper (biometric bypass) |
| **jadx** | Android | APK decompile → BiometricPrompt search |
| **Proxmark3** | RFID/NFC | Fingerprint card clone (RFID biometric) |
| **Roop / SimSwap** | Video | Face swap (video call auth bypass) |
| **ElevenLabs / xtts** | Voice | Voice clone (phone auth bypass) |
| **DeepFaceLab** | Video | Deepfake (video KYC bypass) |

## 5. Referensi
- Frida — https://frida.re/
- Objection — https://github.com/sensepost/objection
- Android BiometricPrompt — https://developer.android.com/training/sign-in/biometric-auth
- Deepfake Detection — https://github.com/yuezunli/dfdt
- ISO/IEC 30107 (Presentation Attack Detection) — https://www.iso.org/standard/...'
