---
title: 'Active Directory & Windows Security — Deep Dive: AD Kerberos, Group Policy,
  Attack Surface & Defense'
tags:
- cyber-security
- iam
- library
created: '2026-07-15'
updated: '2026-07-15'
status: operational
cssclasses: ''
---

# 🪟 Active Directory & Windows Security — Deep Dive: AD Kerberos, Group Policy, Attack Surface & Defense

> Panduan komprehensif infrastruktur keamanan Windows dan Active Directory — dari arsitektur Domain Services (AD DS), protokol autentikasi (Kerberos, NTLM, LDAP), struktur Group Policy, hingga attack surface yang dieksploitasi oleh C2 framework seperti Sliver, Cobalt Strike, dan Empire. Mencakup teknik post-exploitation Windows (token manipulation, DLL injection, LSASS dumping) serta deteksi dan hardening dari perspektif blue team.

> [!info] Hubungan ke Vault
> Nota ini terkait dengan [[sliver]] dan [[cobalt-strike]] dan [[empire]] untuk memahami bagaimana C2 framework mengeksploitasi mekanisme Windows post-exploitation, [[blueteam-detection-matrix]] untuk deteksi lateral movement berbasis Windows event logs, [[endpoint-detection-playbook]] untuk triage forensik di host Windows, [[identity-and-access-management]] untuk fondasi IAM, dan [[zero-trust-security]] untuk prinsip least privilege akses AD.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Arsitektur Active Directory Domain Services (AD DS)

Active Directory adalah direktori layanan terdistribusi milik Microsoft yang mengelola identitas, autentikasi, dan otorisasi dalam lingkungan Windows enterprise. Komponen intinya:

| Komponen                                   | Fungsi                                                                                               |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| **Domain Controller (DC)**                 | Server utama penyimpan database NTDS.DIT, menjalankan autentikasi (Kerberos KDC, NTLM) dan replikasi |
| **NTDS.DIT**                               | Database ESE (Extensible Storage Engine) berisi semua objek AD: user, group, computer, GPO           |
| **Global Catalog (GC)**                    | Indeks seluruh objek di forest, memungkinkan pencarian lintas domain                                 |
| **Kerberos Key Distribution Center (KDC)** | Layanan penerbitan Ticket Granting Ticket (TGT) dan Service Ticket (ST)                              |
| **DNS**                                    | AD-integrated DNS — wajib, service location (SRV) record untuk menemukan DC                          |
| **Group Policy**                           | Engine konfigurasi terpusat berbasis AD (pengaturan registry, security, software install)            |

#### Struktur Logis AD

```
Forest (trust boundary teratas)
├── Domain A (root)
│   ├── OU (Organizational Unit) — container administratif
│   │   ├── Users, Groups, Computers, GPO
│   ├── Domain B (child domain)
│   └── ...trust relationship...
├── Sites & Services (topologi jaringan fisik)
└── Schema (definisi kelas objek dan atribut)
```

### Protokol Autentikasi

#### Kerberos — Mekanisme Dasar

Kerberos adalah protokol autentikasi default di domain modern (Windows 2000+), berbasis ticket dan symmetric-key cryptography.

**Alur singkat:**

```
User → AS-REQ → KDC (AS) → AS-REP (TGT) → User
User → TGS-REQ (TGT + SPN) → KDC (TGS) → TGS-REP (Service Ticket)
User → AP-REQ (ST) → Target Server → AP-REP → User
```

| Tahap | Deskripsi |
|-------|-----------|
| **AS-REQ / AS-REP** | Client mengirim identitas (username + timestamp ter-enkripsi dengan hash password). KDC memverifikasi, mengembalikan TGT (Ticket Granting Ticket) ter-enkripsi dengan **krbtgt** account hash |
| **TGS-REQ / TGS-REP** | Client meminta Service Ticket ke service tertentu dengan menunjukkan TGT + SPN (Service Principal Name). KDC mengembalikan ST yang ter-enkripsi dengan **hash secret key service target** |
| **AP-REQ / AP-REP** | Client mengirim ST ke server target. Server mendekripsi dan memverifikasi — jika valid, akses diberikan |

**Komponen kunci Kerberos yang relevan untuk security:**
- **krbtgt account** — akun yang hash-nya digunakan untuk mengenkripsi TGT. Jika compromised → Golden Ticket attack.
- **SPN (Service Principal Name)** — identifier unik untuk setiap service instance. Basis untuk Kerberoasting attack.
- **PAC (Privilege Attribute Certificate)** — embeds user SID, group membership dalam ticket. Sumber kerentanan elevation of privilege (MS14-068, Kerberos PAC validation bugs).
- **TGT lifetime** — default 10 jam di Windows (bisa dikonfigurasi). Semakin panjang, semakin besar jendela eksploitasi jika TGT dicuri.

#### NTLM — Legacy Authentication

NTLM digunakan ketika Kerberos tidak tersedia (non-domain, older clients). Berbasis challenge-response:

| Step | Detail |
|------|--------|
| 1 | Client → Server: NEGOTIATE (kemampuan) |
| 2 | Server → Client: CHALLENGE (16-byte random nonce) |
| 3 | Client → Server: AUTHENTICATE (NTLMv1/v2 hash dari password + challenge) |
| 4 | Server mem-forward ke DC untuk verifikasi (Netlogon) |

**Kelemahan NTLM:**
- Rentan terhadap **Pass-the-Hash** (PtH) — attacker cukup punya hash NTLM (dari LSASS dump, SAM, atau credential dumping tools) untuk autentikasi, tanpa perlu plaintext password.
- NTLMv1 dapat di-crack (~4.7M hash/sec dengan RTX 4090 untuk NTLMv1, versus NTLMv2 yang jauh lebih lambat).
- Tidak mendukung MFA atau mutual authentication.

#### LDAP — Query & Modifikasi Direktori

AD menggunakan LDAP (Lightweight Directory Access Protocol) sebagai protokol query utama. Dua varian:
- **LDAP (port 389)** — plaintext (sebaiknya di-disable atau di-enkripsi dengan LDAPS)
- **LDAPS (port 636)** — LDAP over TLS
- **GC LDAP (port 3268/3269)** — Global Catalog query tanpa enkripsi/dengan TLS

**Attack vector pada LDAP:**
- **LDAP reconnaissance** — attacker yang sudah punya foothold bisa enum user, group, computer, trust relationship via AD Explorer, BloodHound SharpHound collector, atau PowerShell AD module.
- **LDAP injection** — jarang di AD native, lebih umum di aplikasi web yang query LDAP.

---

## Technical Deep-Dive

### Windows Security Internals

#### LSASS — Crown Jewel Windows Security

**Local Security Authority Subsystem Service (LSASS.EXE)** adalah proses yang menangani semua operasi keamanan termasuk autentikasi, policy enforcement, dan credential caching. LSASS menyimpan kredensial dalam memori prosesnya, termasuk:

- NTLM hash user yang sedang login
- Kerberos ticket (TGT, ST untuk user)
- LSA Secrets (service account passwords, DPAPI keys, machine account password)
- Credential Manager entries

**Mekanisme Credential Caching oleh LSASS:**

| Mode | Simpan? | Detail |
|------|---------|--------|
| Interactive login (console/RDP) | ✅ Ya | NTLM hash + TGT disimpan dalam memori LSASS |
| Network logon (UNC, file share) | ❌ Tidak | Hanya TGT, tidak ada NTLM hash |
| RunAs / secondary logon | ✅ Ya | Kredensial disimpan dalam sesi logon baru |
| Service logon (as SYSTEM) | ✅ Ya | Machine account credentials |
| Cached logon (offline) | ✅ Disimpan di registry HKLM\SECURITY\Cache | Up to 25 hashes default (GPO: Interactive logon) |

#### Attack Vektor Endpoint Windows

##### 1. Credential Dumping dari LSASS

| Tool | Teknik | Deteksi (Event ID / ETW) |
|------|--------|------------------------|
| **Mimikatz sekurlsa::logonpasswords** | OpenProcess → MiniDumpWriteDump → parse memory LSASS | 4663 (akses LSASS.EXE handle), 4656, Sysmon 10 (CreateRemoteThread ke LSASS) |
| **mimikatz sekurlsa::ekeys** | Ekstrak Kerberos encryption keys dari LSASS | Sama dengan di atas |
| **Mimikatz lsadump::sam** | Baca SAM registry hive | 4663 akses ke registry SAM |
| **Mimikatz lsadump::dcsync** | Replikasi DC → request semua hash user via DRSUAPI | 4662 (DS-Replication-Get-Changes), event 1644 |
| **Procdump (Microsoft signed)** | `procdump.exe -ma lsass.exe` → transfer .dmp ke attacker box | 4688 (process creation procdump), 4663 akses LSASS |
| **Dumpert / SharpDump** | Dump via callback API atau .NET Reflection | Turunan procdump — deteksi via signature DLL or .NET assembly loading |
| **SQL Server xp_cmdshell** | `xp_cmdshell 'procdump -ma lsass'` dari SQL agent | SQL Server event logs + process creation |
| **Comsvcs.dll dump** | `rundll32 C:\Windows\System32\comsvcs.dll, MiniDump PID lsass.dmp full` | 4688 rundll32 comsvcs.dll, Sysmon 7 (Image loaded) |

##### 2. Pass-the-Hash / Pass-the-Ticket

- **Pass-the-Hash (PtH)** — gunakan NTLM hash yang didapat dari LSASS dump untuk autentikasi NTLM ke remote system (psexec, WMI, SMB).
- **Pass-the-Ticket (PtT)** — inject TGT atau ST ke dalam sesi Kerberos lokal untuk impersonasi user (Mimikatz `kerberos::ptt`).
- **Overpass-the-Hash** — konversi NTLM hash ke Kerberos TGT (Mimikatz `sekurlsa::pth /user:admin /domain:corp.local /ntlm:HASH /run:powershell`).

##### 3. Token Manipulation

Setiap proses Windows memiliki access token yang menentukan SID user, group membership, privileges, dan session ID:

| Teknik | Tool | Deteksi |
|--------|------|---------|
| **Duplicate token** | `OpenProcess(TOKEN_DUPLICATE)` + `DuplicateTokenEx` → `CreateProcessWithTokenW` | Sysmon 8 (CreateRemoteThread) + 4688 (process from token) |
| **Impersonate token** | `ImpersonateLoggedOnUser` via thread impersonation | Event 4672 (Special Privilege Assigned) jika SeImpersonatePrivilege digunakan |
| **Token stealing** | Process Explorer, `NtSetInformationProcess` untuk thread impersonation | 4663 handle duplication events |
| **Rotten Potato / Juicy Potato** | Nyanyah privilege escalation via DCOM + BITS — SeImpersonate/SeAssignPrimaryToken | 4672 + network connection to ephemeral ports |
| **PrintSpoofer / GodPotato** | Exploit SpoolSample + named pipe impersonation untuk SYSTEM | 4688 spoolsv.exe strange behavior, Sysmon 17 (named pipe) |
| **Named Pipe impersonation** | Pipe server → `ImpersonateNamedPipeClient` ketika admin client connect | Sysmon 17 (named pipe create/connect) |

#### Active Directory Attack Surface

##### Kerberos-Specific Attacks

**Golden Ticket** — Membuat TGT palsu dengan memalsukan **krbtgt** account (domain escalation level):
```mimikatz
# Dari DC (butuh Domain Admin):
lsadump::dcsync /domain:corp.local /user:krbtgt
# Di attacker machine (offline):
kerberos::golden /user:FakeAdmin /domain:corp.local /sid:S-1-5-21-... /krbtgt:HASH /id:500 /groups:512
kerberos::ptt ticket.kirbi
```
- **Deteksi**: Event 4768 (TGT request) dengan Anomaly — TGT lifetime tidak wajar (>10 jam), atau source IP tidak dikenal sebagai DC.
- **Mitigasi**: Monitor event 4768 dengan korelasi source endpoint; batasi akses ke DC; gunakan Protected Users group (menonaktifkan NTLM, DES, RC4, delegasi).

**Silver Ticket** — Membuat Service Ticket palsu dengan memalsukan hash service account/computer account:
- Lebih senyap dari Golden Ticket karena tidak perlu kontak DC.
- **Deteksi**: log service access dengan account yang tidak biasa (misal SQL server diakses oleh Domain Admin).
- **Mitigasi**: Service account monitoring — kerapatan source/destination yang abnormal; event 4625 (failed logon) untuk service accounts.

**Kerberoasting** — Meminta TGS untuk service account biasa (bukan computer account) → crack hash SPN:
```powershell
Add-Type -AssemblyName System.IdentityModel
New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/sql01.corp.local:1433"
# Atau dengan tool:
Rubeus.exe kerberoast /outfile:hash.txt
```
- **Deteksi**: Event 4769 (TGS request) dengan SPN untuk service account manusia — **Service Account harus memiliki `Do not require Kerberos preauthentication` = False**.
- **Mitigasi**: Ganti service account password minimal 100 karakter acak (atau gunakan **Group Managed Service Accounts (gMSA)**), monitor spike TGS request untuk service accounts.

**AS-REP Roasting** — Target user yang **tidak** punya Kerberos Pre-Authentication:
```powershell
Rubeus.exe asreproast /format:hashcat
```
- **Deteksi**: Event 4768 tanpa Pre-Authent (error code 0x6).
- **Mitigasi**: Enable Pre-Authentication untuk semua user; audit user accounts dengan `DONT_REQ_PREAUTH` flag.

**DCSync Attack** — Simulasi DC → DC replikasi untuk mendapatkan semua hash password dari NTDS:
```
mimikatz lsadump::dcsync /domain:corp.local /all
```
- **Deteksi**: Event 4662 (DS-Replication-Get-Changes *untuk seluruh domain*) dari IP non-DC → ***sangat suspicious***. Beri alert kritis untuk `1131f6ad-9c07-11d1-f79f-00c04fc2dcd2` dan `1131f6aa-9c07-11d1-f79f-00c04fc2dcd2` (DS-Replication-Get-Changes-All, DS-Replication-Get-Changes).
- **Mitigasi**: Batasi hak replikasi di AD (Deny ds-Replication-Get-Changes untuk non-DC accounts). Monitor group "Domain Admins", "Enterprise Admins", dan "Schema Admins".

##### ACL & Permission Abuse

**BloodHound** menggunakan SharpHound collector untuk memetakan relasi AD ke dalam graph database (Neo4j), mengidentifikasi jalur privilege escalation:

```
# SharpHound (collector)
SharpHound.exe --CollectionMethod All --Domain corp.local --OutputDirectory C:\temp\

# Analisis di BloodHound GUI: 
- Shortest path to Domain Admins
- Find all principals with admin rights to computers
- Kerberos delegation abuse (constrained/unconstrained delegation)
- ACL abuse paths (ForceChangePassword, WriteOwner, GenericWrite, AllExtendedRights)
```

**ACL attack vector utama BloodHound:**

| Permission | Abuse |
|------------|-------|
| **GenericAll** pada User | Bisa ganti password user target |
| **GenericWrite** pada User | Bisa tulis atribut seperti `servicePrincipalName` → Shadow Credentials |
| **WriteOwner** pada Group | Bisa ubah owner group → tambah diri sendiri ke group |
| **ForceChangePassword** | Ubah password user target tanpa tahu old password |
| **AddMember** pada Group | Tambah user ke group (misal ke Domain Admins) |
| **AllExtendedRights** | Termasuk ForceChangePassword + AddMember + DS-Replication-Get-Changes |
| **WriteDACL** | Bisa mengubah ACL itu sendiri — full kontrol |

##### ACL Detection (Event ID 5136 — Directory Service Changes)

Contekan event log AD yang kritis untuk deteksi ACL abuse:

| Event ID | Deskripsi | Relevansi |
|----------|-----------|-----------|
| **5136** | Directory service object modification | ACL change, attribute write |
| **5137** | Directory service object creation | User/group baru suspicious |
| **5141** | Directory service object deletion | User/group dihapus suspicious |
| **4720** | User account created | New user non-approved |
| **4728** | Member added to Security-Global group | Privilege escalation |
| **4732** | Member added to Security-Local group | Local admin escalation |
| **4756** | Member added to Universal group | Cross-domain escalation |
| **4670** | Permissions on an object changed | ACL modification |
| **4704** | User right assigned | New privilege escalation |

### Group Policy & Hardening

#### Group Policy Engine

Group Policy adalah mekanisme konfigurasi terpusat AD. Policy disimpan sebagai **GPO** (Group Policy Object) dan ditautkan ke OU, domain, atau site. Diproses secara berurutan: **Local → Site → Domain → OU → Child OU (LSDOU)**. Policy terakhir yang berlaku untuk suatu GPO setting akan menimpa setting sebelumnya (kecuali di-set ke "Enabled - enforced").

**Komponen GPO:**

| Komponen | Lokasi Penyimpanan | Isi |
|----------|-------------------|-----|
| GPT (Group Policy Template) | `\\domain\SYSVOL\domain\Policies\{GUID}` | Registry.pol, scripts, INI files |
| GPC (Group Policy Container) | AD partition `CN=Policies,CN=System,DC=...` | Metadata, version, WMI filters |

**Format Registry.pol** menyimpan setting registry yang di-push ke target:

```
[Registry Path]
"ValueName"=dword:Value
...
```

#### Security Baseline Settings (CIS Benchmark untuk Windows Server/AD)

| Setting | Lokasi GPO | Tujuan |
|---------|-----------|--------|
| **Account lockout threshold**: 5 attempts | Computer Config → Policies → Windows Settings → Security → Account Policies | Brute force protection |
| **Minimum password length**: 14 karakter | Sama | Prevent cracking |
| **Maximum password age**: 60 hari | Sama | Limit exposure window |
| **Kerberos: Maximum lifetime service ticket**: 600 menit | Sama → Kerberos Policy | Limit PtT window |
| **Kerberos: Maximum lifetime TGT**: 10 jam | Sama | Jika more secure: 4 jam |
| **Deny logon through Remote Desktop Services** untuk Service Accounts | User Rights Assignment | Prevent lateral movement via RDP |
| **Do not display last signed-in** | Interactive Logon | Prevent information disclosure |
| **Require CTRL+ALT+DEL** | Interactive Logon | Prevent credential phishing di login screen |
| **Set LSASS as Protected Process Light (PPL)** | Registry: HKLM\SYSTEM\CurrentControlSet\Control\Lsa | Blocks non-PPL access ke LSASS — mencegah Mimikatz dumping |

#### Protected Users Security Group

Group spesial yang memberikan **extra protection** untuk user anggota:

| Perlindungan | Detail |
|-------------|--------|
| ❌ NTLM authentication (hash caching) | Tidak bisa menggunakan NTLM — hanya Kerberos |
| ❌ DES/RC4 encryption di Kerberos | Hanya AES |
| ❌ Delegasi (unconstrained/constrained) | Tidak bisa menjadi delegation target |
| ❌ Credential caching untuk offline logon | Tidak di-cache |
| ❌ MS-CHAP v2 / Digest / WDigest | Semua non-Kerberos authentication diblok |

**Gunakan untuk:** Domain Admin, Enterprise Admin, semua privileged account.

#### LAPS (Local Administrator Password Solution)

Microsoft LAPS mengelola password lokal admin (Administrator) di setiap mesin yang join domain:

```
# Install LAPS di AD schema
Update-AdmPwdADSchema
Set-AdmPwdComputerSelfPermission -OrgUnit "OU=Workstations,DC=corp,DC=local"
```

- Password disimpan di atribut `ms-Mcs-AdmPwd` pada computer object
- Hanya authorized user/group yang bisa read attribute
- Password dirotasi otomatis oleh LAPS client (CSE)
- **Alternative modern:** Windows LAPS (build-in Windows Server 2025+ / Windows 11) — tanpa perlu ekstensi schema, mendukung automatic rotation setelah penggunaan.

---

## Advanced

### Kerberos Delegation — Sumber Kerentanan Sering Terabaikan

Delegasi Kerberos memungkinkan service untuk "menjadi" user dalam berinteraksi dengan service lain.

#### 1. Unconstrained Delegation (Risiko Tertinggi)

Service apa pun bisa menggunakan TGT user yang sedang login.

```
msDS-AllowedToDelegateTo = <not set>  ← maksudnya "ANY service"
userPrincpalName = http/webserver.corp.local
```

**Eksploitasi:** Jika attacker compromise server dengan unconstrained delegation, semua TGT yang lalu-lalang dari user yang connect ke server itu bisa dicuri (via KDC TGT forwarding).

```
# Enum server with unconstrained delegation
Get-ADComputer -Filter {TrustedForDelegation -eq $true}
# Atau dengan BloodHound: "Find Computers with Unconstrained Delegation"
```

**Deteksi:** Event 4662 yang mengindikasikan TGT forwarding; event log service access oleh computer account.

#### 2. Constrained Delegation

Service hanya bisa delegate ke service tertentu yang didefinisikan di `msDS-AllowedToDelegateTo`.

```
msDS-AllowedToDelegateTo = MSSQLSvc/db01.corp.local:1433
```

**Eksploitasi:** Attacker dengan akses ke service principal bisa meminta TGS ke service target atas nama user mana pun ("protocol transition" / S4U2Self + S4U2Proxy abuse). Jika `msDS-AllowedToDelegateTo` berisi SPN yang sensitif, bisa dilakukan privilege escalation.

#### 3. Resource-Based Constrained Delegation (RBCD) — Modern

Diperkenalkan di Windows Server 2012. Service (resource) menentukan **siapa** yang boleh melakukan delegasi kepadanya, via atribut `msDS-AllowedToActOnBehalfOfOtherIdentity`.

**Eksploitasi umum RBCD:**
```
# Attacker dengan GenericWrite/GenericAll pada computer target
# bisa menulis msDS-AllowedToActOnBehalfOfOtherIdentity dengan SID computer yang attacker kuasai
# → Lalu minta ST ke target seolah-olah user adalah Domain Admin
```

**Deteksi RBCD abuse:** Event 5136 perubahan pada `msDS-AllowedToActOnBehalfOfOtherIdentity` — lebih mudah dideteksi daripada unconstrained delegation karena harus ada explicit attribute modification.

### Shadow Credentials (CVE-2021-42287, CVE-2022-33679, AD CS abuse)

Jika attacker punya **GenericWrite** atau **GenericAll** atas suatu user/computer, mereka bisa menulis `KeyCredentialLink` (atribut untuk WHfB/Windows Hello for Business) → membuat credential baru untuk objekt target → meminta TGT seolah-olah target tanpa tahu password.

**Alur:**
```
1. Attacker produce self-signed certificate + private key
2. Attacker write KeyCredentialLink ke target's AD object (via GenericWrite)
3. Attacker request TGT menggunakan PKINIT (certificate-based Kerberos pre-authentication)
4. Attacker now authenticated as target (bisa user mana pun dengan GenericWrite)
```

**Mitigasi:** Audit ketat siapa yang memiliki GenericWrite/GenericAll permissions. Monitor event 5136 untuk perubahan pada atribut `msDs-KeyCredentialLink`.

### Windows Defender & Modern Detection Features

| Fitur                                  | Kemampuan                                                        | Cara Bypass (Historical)                                                    |
| -------------------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **AMSI (Anti-Malware Scan Interface)** | Memory scanning sebelum script/LoadLibrary execution             | AMSI bypass: patching `amsi.dll!AmsiScanBuffer` (audit for Win32 API calls) |
| **Windows Defender ATP**               | Cloud-based behavioral detection + EDR                           | LOLBins + DLL sideloading + fileless techniques                             |
| **Windows Defender Firewall**          | Host firewall + IPS rules                                        | Outbound C2 via HTTP/S, DNS, ICMP tunneling                                 |
| **Credential Guard**                   | Virtualization-based isolation of secrets (LSASS running in VSM) | Memory-only attacks (page table manipulation), but raises bar significantly |
| **Remote Credential Guard**            | Protected RDP sessions (no credential caching)                   | Tidak bisa → jika di-enforce dari GPO                                       |

### Hardening Checklist — Windows Server & AD

```
☐ Hapus semua legacy protocol: SMBv1, NTLMv1, LLMNR, NetBIOS over TCP/IP
☐ Enabled LDAP signing & channel binding (LDAP over SSL)
☐ Restricted NTLM: deny domain accounts; allow via audit only
☐ Enable PPL untuk LSASS
☐ Disable WPAD, mDNS
☐ Deploy Windows Defender Firewall dengan default block inbound
☐ Enable ASR (Attack Surface Reduction) rules via GPO/CSP
☐ Use Device Guard / Credential Guard di Windows Enterprise/Education
☐ RDP: enforce NLA (Network Level Authentication)
☐ SMB: require signing + encryption
☐ Enable PowerShell Transcription + Module Logging + Script Block Logging
☐ Deploy Sysmon via GPO atau MEM
☐ Windows Event Log: forward ke SIEM via WinRM/EventCollector
☐ Deploy LAPS / Windows LAPS
☐ Monitor Protected Users group membership
```

### Sigma Rules untuk Windows Attack Detection

#### LSASS Process Access (Mimikatz)

```yaml
title: LSASS Access via Unusual Process
id: 0d06782b-9e6d-4a4f-b7f1-5a9e0b0f971e
status: experimental
description: Mendeteksi akses ke LSASS dari proses non-Windows (potensi credential dumping)
logsource:
  category: process_access
  product: windows
detection:
  selection:
    TargetImage|endswith: '\lsass.exe'
    SourceImage|endswith:
      - '\procdump.exe'
      - '\mimikatz.exe'
      - '\powershell.exe'
      - '\rundll32.exe'
    GrantedAccess: '0x1F3FFF'  # PROCESS_ALL_ACCESS
  filter_system:
    SourceImage|startswith: 'C:\Windows\System32\'
  condition: selection and not filter_system
level: high
```

#### DCSync Attempt (Event 4662)

```yaml
title: DCSync Replication Request from Non-DC
id: 4a14d1a9-6e0b-4b7e-8a1e-0d5c2f3b6e71
status: experimental
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4662
    AccessMask: '0x100'  # CR
    Properties|contains:
      - '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2'  # DS-Replication-Get-Changes
      - '1131f6aa-9c07-11d1-f79f-00c04fc2dcd2'  # DS-Replication-Get-Changes-All
  filter:
    SubjectUserSid:
      - 'S-1-5-18'  # SYSTEM
      - 'S-1-5-21-*-500'  # Administrator
  condition: selection and not filter
level: critical
```

---

## Case Studies

| Studi Kasus                                     | Konteks                                                                          | Temuan Kunci                                                                                                                                                                                                    | Mitigasi Diimplementasi                                                                                                                                           |
| ----------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SolarWinds + AD Compromise (2020)**           | Nation-state attacker (NOBELIUM) compromise SolarWinds Orion → lateral ke AD     | 1. Abuse federated trust (SAML signing cert) untuk impersonate user. 2. Golden Ticket via krbtgt theft dari DC. 3. DCSync untuk semua user kredensial.                                                          | 1. Gold Cert monitoring (certificate access anomaly). 2. Protected Users untuk all admins. 3. Advanced Audit Policy untuk event 4662 critical alert.              |
| **Conti Ransomware via AD (2021)**              | Ransomware gang paksa domain admin via exposed RDP                               | 1. LSASS dumping via procdump dari RDP session. 2. Lateral movement via SMB exec (PsExec) dengan hash yang didapat. 3. Group Policy push ransomware ke semua endpoint dalam 30 menit.                           | 1. RDP GPO: deny domain admins logon via RDP. 2. LAPS deploy. 3. SMB auditing + file execution restriction.                                                       |
| **Palo Alto Networks C2 via AD (2023)**         | Attacker compromise low-priv user, escalasi via AD misconfiguration              | 1. Abused GenericWrite on Helpdesk account → shadow credentials → TGT for sensitive admin. 2. Migrasi via Kerberos delegation abuse ke final target (Domain Admin). 3. Dwell time 6 bulan tanpa terdeteksi.     | 1. BloodHound hunting setiap kuartal. 2. ACL audit dengan Purview. 3. Time-based admin group membership.                                                          |
| **Hafnium Exchange + AD (2021)**                | China-nexus attacker via 0-day Exchange (CVE-2021-26855, -26857, -26858, -27065) | 1. ProxyLogon → webshell → steal admin credentials. 2. Export all mailbox via Exchange PowerShell. 3. Kerberoasting internal service accounts. 4. Golden Ticket prep untuk persistence.                         | 1. Force Extended Protection for Legacy Authentication. 2. EOP 1.0 + Exchange emergency patch. 3. Disable Kerberos RC4. 4. Credential Guard for Exchange servers. |
| **Simulated Red Team: Internal Pentest (2024)** | Full red team assessment — Windows domain environment                            | 1. Kerberoasting service account in 30 seconds (RC4 encryption). 2. LAPS password read via `Get-AdmPwdPassword` (misconfigured AD permissions). 3. Constrained delegation abuse → access sensitive file server. | 1. AES-only enforcement via GPO. 2. Restrict LA read permission to IT Ops group only. 3. Time-bound admin tokens with PIM.                                        |

---

## Koneksi ke Vault

- [[sliver]] — C2 framework yang post-exploitation di Windows — memahami AD memungkinkan deteksi implant Sliver jauh lebih akurat
- [[cobalt-strike]] — Beacon menggunakan berbagai teknik yang dijelaskan di sini (token theft, dll.)
- [[empire]] — PowerShell Empire menggunakan credential dumping, token manipulation, dan AD reconnaissance
- [[blueteam-detection-matrix]] — mapping teknik AD attack ke deteksi event log Windows
- [[endpoint-detection-playbook]] — triage forensik host Windows terdampak
- [[identity-and-access-management]] — fondasi IAM yang diperluas di sini ke level protokol dan implementasi serangan
- [[zero-trust-security]] — implementasi Zero Trust di Windows dengan Credential Guard, WDAC, Device Guard
- [[endpoint-security]] — ring protection model untuk memahami di mana LSASS beroperasi (Ring 3 vs VSM Ring -1)
- [[comprehensive-threat-directory]] — kategorisasi ancaman Windows di taksonomi global

---

## Referensi

1. Microsoft. *Active Directory Domain Services Overview*. https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview
2. Microsoft. *Kerberos Authentication Overview*. https://learn.microsoft.com/en-us/windows-server/security/kerberos/kerberos-authentication-overview
3. Microsoft. *NTLM Overview*. https://learn.microsoft.com/en-us/windows-server/security/kerberos/ntlm-overview
4. Microsoft. *Group Policy Overview*. https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831791(v=ws.11)
5. Microsoft. *Windows Security Events*. https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/security-auditing-overview
6. Microsoft. *LSASS Overview*. https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
7. Microsoft. *Securing Domain Controllers to Improve Attack Resilience*. https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/securing-domain-controllers-to-improve-attack-resilience
8. Microsoft. *Protected Users Security Group*. https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/how-to-configure-protected-accounts
9. Microsoft. *LAPS Overview*. https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview
10. Microsoft. *Windows LAPS*. https://learn.microsoft.com/en-us/windows-server/identity/laps/
11. MITRE ATT&CK. *Active Directory*. https://attack.mitre.org/techniques/T1484/
12. MITRE ATT&CK. *Credential Dumping from LSASS*. https://attack.mitre.org/techniques/T1003/001/
13. MITRE ATT&CK. *DCSync*. https://attack.mitre.org/techniques/T1003/006/
14. MITRE ATT&CK. *Golden Ticket*. https://attack.mitre.org/techniques/T1558/001/
15. MITRE ATT&CK. *Kerberoasting*. https://attack.mitre.org/techniques/T1558/003/
16. BloodHound Enterprise. *BloodHound Attack Paths*. https://bloodhoundenterprise.io/attack-paths/
17. SpecterOps. *Kerberos Delegation, AD CS, and Shadow Credentials*. https://posts.specterops.io/abusing-kerberos-delegation-in-active-directory
18. HackTheBox / ired.team. *Active Directory Attacks*. https://www.ired.team/offensive-security-experiments/active-directory-kerberos-abuse
19. Delpy, Benjamin (GentilKiwi). *Mimikatz*. https://github.com/gentilkiwi/mimikatz
20. Graeber, Matt. *Abusing Windows Tokens for Privilege Escalation*. https://blog.cobaltstrike.com/2017/03/01/abusing-windows-tokens-for-privilege-escalation/
21. Microsoft. *Microsoft Security Compliance Toolkit*. https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/
22. CIS. *CIS Microsoft Windows Server 2022 Benchmark v1.0*. https://www.cisecurity.org/benchmark/microsoft_windows_server/
23. CIS. *CIS Microsoft Active Directory Security Benchmark*. https://www.cisecurity.org/benchmark/active_directory/
24. Microsoft. *Attack Surface Reduction Rules*. https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference?view=o365-worldwide
25. Sysinternals. *Sysmon (System Monitor)*. https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
26. Sigma HQ. *Sigma Rules for Windows Event Log Detection*. https://github.com/SigmaHQ/sigma
27. Elastic. *Windows Event Log Mapping to MITRE ATT&CK*. https://www.elastic.co/guide/en/security/current/windows-events-reference.html
28. CrowdStrike. *Overwatch: Active Directory Security Analysis*. https://www.crowdstrike.com/blog/overwatch-analyzing-active-directory-security/
29. Mandiant. *M-Trends 2024: Active Directory Attack Trends*. https://www.mandiant.com/resources/m-trends
30. Varonis. *Active Directory Security Assessment*. https://www.varonis.com/blog/active-directory-security-assessment

> [!tip] Bottom Line
> Windows dan Active Directory bukan sekadar "infrastruktur autentikasi" — ini adalah medan pertempuran utama post-exploitation modern. Setiap C2 framework (Sliver, Cobalt Strike, Empire) dirancang untuk mengeksploitasi mekanisme credential caching, token delegation, dan trust relationship AD. Tanpa pemahaman mendalam tentang Kerberos, LSASS, ACL, dan Group Policy, seorang blue team tidak akan bisa mendeteksi lateral movement yang paling dasar sekalipun. Investasi pada Protected Users, Credential Guard, LAPS, **serta** audit event log secara kontinu (dengan korelasi Sigma ke SIEM) adalah fondasi pertahanan yang tidak bisa ditawar.
