---
title: Bloodhound
tags:
- 02-pentest-frameworks
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!warning] Konteks Etis & Legal
> BloodHound adalah alat open-source untuk analisis keamanan Active Directory. Pengumpulan data (via SharpHound atau kolektor lain) memerlukan izin eksplisit pada direktori yang diuji. Penggunaan tanpa otorisasi terhadap sistem yang bukan milik sendiri melanggar kebijakan internal perusahaan dan kemungkinan hukum pidana. Dokumen ini murni untuk pendidikan defender dan red team yang sah.

---

## 🧬 Apa Itu BloodHound Secara Teknis?

BloodHound bukanlah alat serangan. Ia adalah **platform analitik** yang memetakan hubungan keamanan dalam Active Directory (AD) dan Azure/Entra ID untuk menemukan jalur serangan tersembunyi. Jika Cobalt Strike adalah pedang, BloodHound adalah **peta medan perang**. Ia mengubah data mentah AD (pengguna, grup, komputer, ACL, sesi, dll.) menjadi **graf terarah** (directed graph) dan memungkinkan operator menanyakan jalur dari titik awal ke target bernilai tinggi — misalnya: “Bagaimana User A bisa menjadi Domain Admin hanya dengan menggunakan hak yang sudah dimilikinya?”

### Komponen Arsitektur

```
┌────────────────────────────────────────────────────────────────┐
│                       Data Collector                           │
│  SharpHound (C#), RustHound, SOAPHound                         │
│  Berjalan pada host yang sudah dikompromikan,                   │
│  mengumpulkan data via LDAP, SMB, dan API lainnya.             │
└───────────────────────────┬────────────────────────────────────┘
                            │ (ZIP file JSON)
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                     Neo4j Database                              │
│  Graph database. Menyimpan node (User, Computer, Group,        │
│  Domain, OU, GPO) dan edge (MemberOf, HasSession, AdminTo,     │
│  GenericAll, WriteDACL, etc.).                                 │
└───────────────────────────┬────────────────────────────────────┘
                            │ (Cypher queries)
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                   BloodHound GUI / CLI                          │
│  Antarmuka untuk menjalankan query pre-built (Shortest Path    │
│  to Domain Admins, Find Principals with DCSync Rights, etc.)   │
│  atau custom Cypher queries.                                   │
└────────────────────────────────────────────────────────────────┘
```

Kolektor mengumpulkan data melalui:
- **LDAP** (port 389/636): Membaca objek, atribut, keanggotaan grup, ACL (DACL/SACL), delegasi, SPN, dan lain-lain.
- **SMB/CIFS** (port 445): Menghitung sesi yang sedang aktif pada komputer (NetSessionEnum), sehingga diketahui user mana yang sedang login di mana.
- **RPC/NetAPI**: Mendapatkan anggota grup lokal (Administrators, Remote Desktop Users) pada setiap komputer.
- **Microsoft Graph API** (untuk AzureHound): Mengumpulkan informasi dari Azure AD/Entra ID seperti service principals, application permissions, role assignments.

Data yang dihasilkan adalah grafik lengkap tentang hubungan keamanan.

---

## 📊 Model Graf BloodHound: Node, Edge, dan Matematika Serangan

BloodHound memodelkan AD sebagai graf properti. Setiap entitas (user, computer, group, domain, OU, GPO) adalah **node** dengan label, dan setiap hubungan (relasi) adalah **edge** dengan arah dan tipe.

### Node Utama dan Properti Penting

| Label Node | Properti Utama | Makna |
|------------|----------------|-------|
| **User** | `name`, `domain`, `admincount`, `hasspn`, `dontreqpreauth`, `pwdlastset` | Pengguna domain. |
| **Computer** | `name`, `domain`, `operatingsystem`, `haslaps`, `unconstraineddelegation` | Komputer tergabung domain. |
| **Group** | `name`, `domain`, `admincount` | Grup keamanan, bisa nested. |
| **Domain** | `name`, `domain`, `functionallevel` | Domain AD. |
| **OU** | `name`, `domain` | Organizational Unit. |
| **GPO** | `name`, `domain` | Group Policy Object. |
| **Azure** (tambahan) | `appid`, `serviceprincipaltype` | Entitas Azure AD. |

### Edge (Relasi) Kritis

Setiap edge memiliki tipe yang menentukan apa yang bisa dilakukan oleh node sumber terhadap node target.

| Edge | Tipe | Arti | Risiko |
|------|------|------|--------|
| **MemberOf** | Group → User/Computer/Group | Keanggotaan grup. Basis semua relasi privilege. | Rendah |
| **AdminTo** | User/Group → Computer | Anggota grup Administrator lokal pada komputer. | Sangat tinggi — kontrol penuh atas komputer. |
| **HasSession** | User → Computer | User sedang memiliki sesi (logon) pada komputer. | Tinggi — pencurian token/credential. |
| **CanRDP** | User/Group → Computer | Hak Remote Desktop. | Tinggi |
| **CanPSRemote** | User/Group → Computer | Hak PowerShell Remoting (WinRM). | Tinggi |
| **ExecuteDCOM** | User/Group → Computer | Hak eksekusi DCOM pada komputer. | Tinggi |
| **SQLAdmin** | User/Group → Computer | Admin SQL pada host. | Tinggi |
| **GenericAll** | User/Group → Object | Kontrol penuh atas objek (sering via ACL). | Sangat tinggi — bisa reset password, tambahkan diri ke grup. |
| **GenericWrite** | User/Group → Object | Tulis ke semua properti objek (misal: logon script, SPN). | Tinggi — bisa menyebabkan kerberos delegation attack. |
| **WriteDACL** | User/Group → Object | Dapat memodifikasi ACL objek. | Sangat tinggi — bisa memberikan hak penuh ke diri sendiri. |
| **WriteOwner** | User/Group → Object | Dapat mengubah pemilik objek. | Tinggi — lalu bisa WriteDACL. |
| **AddMember** | User/Group → Group | Dapat menambah anggota ke grup. | Sangat tinggi |
| **AddSelf** | User → Group | Dapat menambahkan diri sendiri ke grup. | Sangat tinggi |
| **ReadLAPSPassword** | User/Group → Computer | Dapat membaca password Administrator lokal (LAPS). | Sangat tinggi |
| **DCSync** | User/Group → Domain | Hak untuk melakukan replikasi domain (mendapatkan hash semua pengguna). | Kritis — Domain Admin penuh. |
| **GPOControl** | User/Group → GPO | Dapat mengedit GPO. Lalu GPO diterapkan ke komputer/user via `GpLink`. | Kritis — eksekusi kode pada banyak host. |
| **ForceChangePassword** | User/Group → User | Dapat mereset password pengguna. | Tinggi |
| **AllowedToDelegate** | Computer → Domain/Computer | Delegasi Kerberos tanpa batasan. | Tinggi — dapat impersonasi user apa pun. |
| **Contains** | OU/Domain → Object | Objek berada di OU ini. | Rendah |
| **GpLink** | GPO → OU | GPO diterapkan ke OU ini. | Menengah |

Dengan edge-edge ini, BloodHound membangun graf besar di mana operator dapat mencari **attack path** — urutan edge yang menghubungkan node milik penyerang (misal, user yang sudah dikompromikan) ke node target (Domain Admins, Domain Controllers).

---

## ⚔️ Primitif Eksploitasi: Dari Edge ke Kompromi

BloodHound sendiri tidak mengeksploitasi; ia hanya menunjukkan jalurnya. Tapi memahami jalur membutuhkan pemahaman tentang eksploitasi yang mendasari setiap edge. Berikut adalah beberapa primitif serangan yang memanfaatkan edge tertentu.

### GenericAll pada User → ForceChangePassword + Kerberoasting

Jika `User A` memiliki `GenericAll` pada `User B`:
1. `User A` dapat mereset password `User B` (karena `GenericAll` mencakup `User-Force-Change-Password`).
2. Atau, jika `User B` memiliki SPN (Service Principal Name) — ditandai dengan properti `hasspn: true` — `User A` dapat menulis SPN palsu pada `User B` (karena `GenericAll` termasuk `WriteSPN`), lalu melakukan Kerberoasting: meminta TGS (Ticket Granting Service) untuk `User B` dari KDC, lalu memecahkan hash offline untuk mendapatkan password plaintext `User B`.

### GenericWrite pada User → Targeted Kerberoasting atau Shadow Credentials

Dengan `GenericWrite` pada user:
- Penyerang dapat menulis `servicePrincipalName` pada user target (jika belum ada), lalu melakukan Kerberoasting.
- Atau, pada lingkungan yang mendukung, menulis `msDS-KeyCredentialLink` untuk menambahkan kunci publik (Shadow Credentials) dan mengautentikasi sebagai user target tanpa mengetahui password.

### WriteDACL pada Domain Root → DCSync

Jika penyerang memiliki `WriteDACL` pada objek domain (`DC=domain,DC=com`):
1. Tambahkan diri sendiri (atau user yang dikendalikan) dengan hak replikasi: `DS-Replication-Get-Changes` dan `DS-Replication-Get-Changes-All`.
2. Jalankan DCSync (misal via Mimikatz `lsadump::dcsync`) untuk mendapatkan hash NTLM semua pengguna di domain, termasuk KRBTGT.

### AddSelf ke Grup → Privilege Escalation Langsung

Jika sebuah grup `Helpdesk` memiliki `AddSelf` ke `Domain Admins` (jarang, tapi mungkin melalui ACL aneh), maka setiap anggota `Helpdesk` bisa menambahkan dirinya ke `Domain Admins` tanpa bantuan.

### HasSession → Credential Dumping & Token Theft

Jika `User A` (user biasa) memiliki sesi pada `Computer X`, dan penyerang sudah mendapatkan akses admin lokal ke `Computer X` (misal lewat `AdminTo` dari tempat lain), maka penyerang bisa:
- Dump kredensial `User A` dari LSASS (`logonpasswords` di Cobalt Strike).
- Curi token `User A` jika masih aktif.

Jika `User A` adalah admin di komputer lain atau anggota grup tinggi, ini menjadi batu loncatan.

### AllowedToDelegate (Unconstrained Delegation) → Printer Bug & DCSync

Komputer dengan delegasi tanpa batasan (Unconstrained Delegation) dapat menangkap TGT (Ticket Granting Ticket) dari setiap pengguna yang mengautentikasi ke sana.
1. Penyerang mengkompromikan komputer tersebut (misal `COMP-A` dengan unconstrained delegation).
2. Memaksa Domain Controller untuk mengautentikasi ke `COMP-A` menggunakan Print Spooler bug (`MS-RPRN RpcRemoteFindFirstPrinterChangeNotification`), yang menyebabkan DC mengirimkan TGT-nya ke `COMP-A`.
3. TGT DC ditangkap di LSASS `COMP-A`, diekstrak, lalu digunakan untuk DCSync.

Ini adalah jalur klasik dari admin lokal pada server biasa ke Domain Admin dalam satu langkah.

### LAPS: ReadLAPSPassword → Local Admin Everywhere

Jika penyerang memiliki `ReadLAPSPassword` pada suatu komputer, ia bisa membaca password administrator lokal yang unik. Jika hak itu berlaku untuk banyak komputer (misalnya grup `Helpdesk` diberi akses baca LAPS), satu pengguna Helpdesk yang dikompromikan bisa menjadi admin lokal pada semua workstation/server, lalu melanjutkan dengan HasSession atau token theft.

---

## 🔍 Cypher Queries: Bahasa Interogasi Graf

BloodHound menggunakan Cypher, bahasa query untuk Neo4j. Beberapa query kritis yang digunakan oleh red teamer dan defender:

### 1. Shortest Path to Domain Admins
```cypher
MATCH (n:User {name:'JDOE@DOMAIN.COM'}),
      (m:Group {name:'DOMAIN ADMINS@DOMAIN.COM'}),
      p = shortestPath((n)-[r:MemberOf|AdminTo|HasSession|GenericAll|GenericWrite|WriteDACL|WriteOwner|AddMember|AddSelf|ReadLAPSPassword|DCSync|ForceChangePassword|AllowedToDelegate*1..]->(m))
RETURN p
```
Ini adalah query paling ikonik: menunjukkan jalur terpendek dari user yang dikuasai ke Domain Admins.

### 2. Find All Users with Path to High Value Targets
```cypher
MATCH (u:User), (t:Group {name:'DOMAIN ADMINS@DOMAIN.COM'})
WHERE u<>t
MATCH p = shortestPath((u)-[r:MemberOf|AdminTo|...*1..]->(t))
RETURN u.name, length(p) AS hops, [n in nodes(p) | n.name] AS path
ORDER BY hops ASC
```
Menemukan semua pengguna di domain yang memiliki jalur ke Domain Admins, bukan hanya satu.

### 3. Find All Computers Where User Has Session
```cypher
MATCH (u:User {name:'JDOE@DOMAIN.COM'})-[r:HasSession]->(c:Computer)
RETURN c.name, c.operatingsystem
```
Menentukan di mana user logged on, untuk merencanakan serangan token theft atau credential dumping.

### 4. Find All Kerberoastable Users
```cypher
MATCH (u:User {hasspn:true})
WHERE NOT u.name STARTS WITH 'krbtgt'
RETURN u.name, u.serviceprincipalnames
```
Menampilkan pengguna dengan SPN yang dapat di-kerberoast.

### 5. Find All Computers with Unconstrained Delegation
```cypher
MATCH (c:Computer {unconstraineddelegation:true})
RETURN c.name, c.operatingsystem
```

### 6. Find Users with DCSync Rights
```cypher
MATCH (n:User)-[r:DCSync]->(d:Domain)
RETURN n.name, d.name
```

### 7. Find All Nested Group Membership
```cypher
MATCH (n:User)-[r:MemberOf*1..]->(g:Group)
WHERE g.objectid ENDS WITH '-512' // Domain Admins
RETURN n.name, g.name, length(r) AS depth
```
Identifikasi pengguna yang menjadi Domain Admin melalui keanggotaan bertingkat, sering tersembunyi.

---

## 🛡️ Deteksi BloodHound / SharpHound Activity

BloodHound sendiri tidak meninggalkan artefak di lingkungan target, tetapi **proses pengumpulan data oleh SharpHound** meninggalkan jejak.

### 1. Jejak LDAP
SharpHound melakukan query LDAP dalam jumlah besar. Satu sesi pengumpulan bisa mencakup ribuan permintaan LDAP. Ini tidak normal dibandingkan dengan trafik LDAP biasa dari workstation.

**Deteksi:**
- Monitor **LDAP query volume** dari host non-DC. Rule: "Jika sebuah host yang bukan Domain Controller melakukan > 500 LDAP query dalam 5 menit, alert."
- **Event Log (Directory Service)**: Aktifkan diagnostic logging untuk LDAP (HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics) dan pantau event ID 1644 (LDAP search with high CPU time). SharpHound sering muncul di sini.
- **Sysmon Event ID 3 (Network Connect)**: Koneksi dari host biasa ke DC pada port 389/636. Normal, tetapi jika dikombinasikan dengan volume tinggi, anomali.
- **Microsoft 365 Defender** memiliki deteksi bawaan untuk "Reconnaissance using SharpHound" (Alert: "BloodHound enumeration").

### 2. Jejak SMB (NetSessionEnum)
SharpHound memanggil `NetSessionEnum` untuk menghitung sesi. Ini menghasilkan koneksi SMB ke setiap komputer di domain (port 445) untuk memeriksa sesi.

**Deteksi:**
- **Sysmon Event ID 3**: Lonjakan koneksi ke port 445 ke banyak host dalam waktu singkat dari satu source IP.
- **Windows Event ID 5140/5145**: Share access ke `\\*\IPC$` dari host yang tidak biasa.

### 3. Jejak SAMR (Security Account Manager Remote)
SharpHound menggunakan SAMR untuk mendapatkan daftar anggota grup lokal pada komputer remote.

**Deteksi:**
- **Windows Event ID 4661**: Handle ke `SAM` objek oleh user biasa. User non-admin seharusnya tidak banyak mengakses SAM secara remote.
- **Sysmon**: Akses ke `lsass.exe` atau `samrpc` dari proses SharpHound.

### 4. Artefak File
SharpHound menulis file ZIP hasil ke disk. Nama file default biasanya `YYYYMMDDHHMMSS_BloodHound.zip` atau dapat ditentukan. Defender dapat mencari file ZIP baru di direktori `%TEMP%` atau `C:\Users\Public`.

### 5. Tanda Kolektor Lain
- **RustHound**: Meninggalkan artefak yang mirip tetapi ditulis dalam Rust; mungkin lebih sulit dideteksi karena tidak ada CLR loading.
- **AzureHound**: Menggunakan Microsoft Graph API. Deteksi melalui log audit Azure (akses aplikasi, query Graph yang tidak biasa).

### 6. Analisis Perilaku
EDR modern dapat mendeteksi aktivitas yang menyerupai pengumpulan data AD dengan mengenali pola: proses yang mengakses LDAP, SMB, SAMR, dan RPC dalam satu sesi.

---

## ↔️ Dual-Use: Defender vs Attacker

BloodHound adalah alat dual-use sempurna:

**Defensive (Blue Team):**
- **Attack Path Management (APM)**: Menemukan dan menghilangkan jalur serangan sebelum penyerang menemukannya. Misal: menghilangkan `GenericAll` yang tidak perlu, membersihkan nested group yang berbahaya.
- **Audit Keamanan AD**: Mengevaluasi dampak dari konfigurasi ACL yang salah, delegasi yang longgar, hak LAPS yang terlalu luas.
- **Tiering Model Validation**: Memastikan bahwa Tier 0 (Domain Admins, DCs) benar-benar terisolasi dari Tier 1 (server) dan Tier 2 (workstation). BloodHound bisa memvalidasi apakah ada user Tier 2 yang bisa mencapai Tier 0.
- **Simulasi Kompromi**: Blue team dapat menjalankan query yang sama dengan penyerang untuk mengukur exposure mereka.

**Offensive (Red Team / APT):**
- **Pathfinding**: Setelah kompromi awal (user biasa), gunakan BloodHound untuk merencanakan jalur ke Domain Admin.
- **Target Selection**: Menemukan user/computer yang memiliki hak tinggi, grup dengan anggota sedikit tapi krusial.
- **Lateral Movement Planning**: Menentukan komputer mana yang memiliki sesi admin untuk pencurian token.

---

## 🔗 Koneksi dalam Vault

- [[metasploit]] — Setelah BloodHound menemukan jalur AdminTo, Metasploit dapat digunakan untuk exploit lateral movement (misal `psexec`).
- [[cobalt-strike]] — Beacon sering menjalankan SharpHound melalui `execute-assembly` di memori; lalu data ZIP diunduh untuk analisis offline.
- [[empire]] — Dapat menjalankan modul pengumpul data AD serupa, meskipun tidak sekomprehensif SharpHound.
- [[shodan]] — Tidak langsung, tetapi organisasi yang memiliki DC terekspos ke internet akan terlihat di Shodan, memungkinkan serangan langsung tanpa foothold.
- [[xkeyscore]] — Secara teoritis, jika traffic LDAP/SMB organisasi diintersep di backbone, NSA bisa membangun graf BloodHound-nya sendiri.

---

## 🧮 Contoh Attack Path Kompleks

```
User: "Intern" (Domain User)
  └─[MemberOf]─► Group: "IT Helpdesk"
                   └─[ReadLAPSPassword]─► Computer: "FILE01"
                                             └─[HasSession]──► User: "svc_backup"
                                                                 └─[GenericWrite]─► User: "SQL_SVC"
                                                                                      └─[AdminTo]──► Computer: "SQL01"
                                                                                                        └─[HasSession]──► User: "DomainAdmin01"
```

Panah ke bawah adalah arah edge. Intern → Helpdesk (MemberOf). Helpdesk dapat membaca LAPS password FILE01. FILE01 memiliki sesi dari svc_backup (mungkin service account yang sedang login). svc_backup dapat menulis ke properti SQL_SVC (GenericWrite), memungkinkan Kerberoasting atau Shadow Credentials. SQL_SVC adalah admin di SQL01, yang memiliki sesi DomainAdmin01. Jika DomainAdmin01 token dicuri, intern menjadi Domain Admin.

Ini bukan fantasi — jalur seperti ini sering ditemukan di organisasi besar.

---

## 📚 Referensi

- SpecterOps, *BloodHound: Six Degrees of Domain Admin* (2017)
- Sadowski, A., & Robbins, J. (2019). *BloodHound: The Evolution of Active Directory Defense*.
- Microsoft, *Best Practices for Securing Active Directory* (2020)
- MITRE ATT&CK: T1087.002 (Account Discovery: Domain Account), T1069.002 (Permission Groups Discovery: Domain Groups), T1482 (Domain Trust Discovery)
- Loïc Veirman, *Active Directory Security: BloodHound Data Collection and Analysis*
- Will Schroeder, *The Attacking Active Directory Series*

---

*BloodHound Deep Dive | Active Directory Attack Path Analysis | Graph-Based Security for Red & Blue Teams*
