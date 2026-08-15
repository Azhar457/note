---
title: Threat Directory
tags: [security, intel, directory]
aliases: [threat-directory]
---
# Threat Directory — Katalog Aktor & Tools

Directory referensi ancaman: aktor (threat actors), toolset, dan sumber intel — untuk analisis, emulation, dan deteksi. Data berasal dari laporan publik (Mandiant, CrowdStrike, Kaspersky, Microsoft Threat Intelligence) — verifikasi tanggal update.

## Kategori Aktor

### Nation-State (APTs)

| Nama | Atribusi | Fokus | TTP Khas |
|------|----------|-------|----------|
| APT28 (Fancy Bear) | Rusia (GRU) | NATO, gov, militer | Phishing spear, 0-days, credential harvesting; tools: X-Agent, X-Tunnel |
| APT29 (Cozy Bear) | Rusia (SVR) | Gov (US/UE), think tanks | Supply chain (SolarWinds), stealthy lateral; tools: WellMess, SUNBURST |
| Lazarus Group | Korea Utara (RB) | Finance, crypto | Ransomware (AppleJeus), spear phishing, exchange hacks |
| APT41 (Winnti) | China (MSS) | Game, telco, pharma | Dual-purpose (espionage + financial); supply chain |
| APT34 (OilRig) | Iran | Energi, gov | Credential phishing, DNS tunneling; tools: OopsIE, BONDUPDATER |
| Charming Kitten | Iran | Academia, media | Social engineering, credential |
| APT10 (MenuPass) | China | Cloud, MSP, healthcare | Supply chain, info stealer; Mimikatz usage |
| ScarCruft | Korea Utara | Media, think tanks | Watering hole, custom malware |
| Turla | Rusia | Gov, embassies | Sophisticated persistence, satellite C2 |
| MuddyWater | Iran | Middle East org | PowerShell tooling, phishing |

### Cybercrime Groups

| Grup | Kategori | Khas |
|------|----------|------|
| LockBit | Ransomware-as-a-Service | Fast encryption, leak site, double extortion (2024: takedown by law enforcement, tapi varian muncul) |
| BlackCat/ALPHV | RaaS | Rust-based, affiliates |
| Cl0p | Ransomware + data theft | MOVEit exploit (2023) — mass data theft |
| FIN7 (Carbanak) | Financial crime | POS malware, phishing commerce |
| Evil Corp | Ransomware/financial | Sanctioned (US); Dridex |
| Magecart | Web skimming | Card skimming via injected scripts (third-party supply chain) |
| Scattered Spider | Social engineering | IT helpdesk impersonation, MFA bypass |

## Toolset (Konten Terverifikasi)

### Post-Exploitation
- **Cobalt Strike / Sliver (OSS) / Metasploit** — C2 & post-ex frameworks.
- **Mimikatz** — credential dumping (lsass); detection: Sysmon EID 10? (access lsass) + EDR.
- **Impacket** — SMB exec (psexec/wmiexec), Kerberos tools.
- **BloodHound** — AD attack path mapping (user → DA).
- **Rubeus** — Kerberoasting, AS-REP roast.
- **LOLBins** — living-off-the-land binaries (powershell, wmic, mshta, certutil, bitsadmin).
- **C2 frameworks lainnya**: Empire, Havoc, Mythic, Brute Ratel.

### Initial Access
- Phishing kits (evilginx2 — reverse proxy MFA bypass), payload drop (HTA, macro), 0-day exploit (N-day mostly), exposed services (RDP, VPN vuln), supply chain.

## Sumber Intel (Feeds & Reports)

- **Free IOC feeds**: abuse.ch (URLhaus, MalwareBazaar, ThreatFox, Feodo), CISA KEV, AlienVault OTX, MISP communities.
- **Threat research blogs**: Mandiant, CrowdStrike, Kaspersky (securelist), Microsoft Security, Google TAG, Unit42 (Palo Alto), Recorded Future (partial).
- **Vendor advisories**: vendor-specific (Cisco, Microsoft) with IOCs.
- **TLP**: gunakan TLP sesuai level (lihat [[threat-intel]]).

## Mapping Emulation (Detection Testing)

1. Pilih aktor yang relevan (sektor/tech stack).
2. Ambil MITRE ATT&CK techniques dari intel (e.g., ATT&CK Navigator layer).
3. Bangun emulation plan: tools (open source clones) + order of operations.
4. Jalankan di lab/jump host; ukur deteksi (EDR, SIEM rules missing?).
5. Iterasi: tambah Sigma/YARA rules untuk yang tidak terdeteksi.

## Update Policy Directory

- Cek pembaruan bulanan (aktor baru, takedown, tools baru).
- Sumber: blog keamanan + ATT&CK updates + vendor intelligence.
- Jangan percaya atribusi tunggal — verifikasi lintas sumber (atribusi sering diperdebatkan).
- Note: status LockBit/BlackCat berubah cepat — cek berita terbaru sebelum operasional.

## Checklist Penggunaan

- [ ] Aktor relevan dengan sektor/tech stack?
- [ ] TTP dari sumber terverifikasi (2+ sumber)?
- [ ] Emulation menggunakan tools OSS (bukan malware nyata)?
- [ ] Deteksi rules (Sigma/YARA) update dari intel?
- [ ] Directory di-review bulanan?



## TTP Detail (Per Aktor — Emulation Reference)

### APT29 (Cozy Bear) — Emulation Blueprint
1. Initial: supply chain (SUNBURST) atau spear phishing (macro + document).
2. Persistence: scheduled task / service masquerade.
3. Lateral: SMB/WinRM via stolen creds; Kerberos abuse.
4. C2: HTTPS beaconing, file-based (OneDrive/cloud storage), long sleep (12-24h).
5. Egress: staged exfil via legitimate services.

Deteksi: hunt untuk beacon dengan jitter besar (network analytics), `schtasks` baru, service dengan nama aneh, `rundll32` memuat DLL dari lokasi user.

### Lazarus — Emulation Blueprint
1. Initial: spear phishing (job offer lures), watering hole, crypto exchange exploitation.
2. Persistence: registry run key, services.
3. Privesc: vulnerable drivers (BYOVD — CVE-2021-21551 Dell driver historik), UAC bypass.
4. Egress: fake trading API (AppleJeus), wallet theft.

Deteksi: alert BYOVD driver load (EDR), process tree tidak wajar (powershell dari Office), outbound ke exchange API aneh.

## Sigma/YARA Rule Template

```yaml
# sigma_apt29_persistence.yaml
title: APT29 Scheduled Task Masquerade
logsource:
  category: process_creation
detection:
  selection:
    Image|endswith: 'schtasks.exe'
    CommandLine|contains: '/create'
    CommandLine|contains:
      - 'svchost'
      - 'OneDrive'
  condition: selection
level: high
```

```yara
rule Lazarus_AppleJeus {
  strings:
    $s1 = "AppleJeus" ascii
    $s2 = "TradeBot" ascii
    $s3 = { 4D 5A }  // MZ
  condition: uint16(0) == 0x5A4D and 2 of them
}
```

## Direktori Cepat Tools (OSS untuk Detection Testing)

| Fungsi | Tools |
|--------|-------|
| C2 simulation | Sliver, Havoc, Mythic |
| Credential test | mimikatz (lab only), Rubeus (lab), Kerbrute |
| AD mapping | BloodHound, PlumHound |
| Web delivery | Evilginx2 (phishing lab), Mythic payloads |
| Detection | Sigma converter (sigmac), YARA-X, Sysmon config (SwiftOnSecurity) |

## Sosok Aktor Non-Nation-State (Hacktivist & Insider)

- **Hacktivist**: DDoS (DDosia, Russian hacktivist), defacement, data leak (Anonymous, KillNet — op Ukraine).
- **Insider**: data theft (biasanya credential abuse), saboteur (destructive). Deteksi: UEBA (user behavior anomaly: download massal, akses di luar jam).
- **Script kiddie**: automated scanners (Nuclei), default exploits — deteksi: scan pattern di firewall/IDS.

---

  audited
---