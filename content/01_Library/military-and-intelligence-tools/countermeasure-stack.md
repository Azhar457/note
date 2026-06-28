---
tags:
  - countermeasure
  - defense
  - hardening
  - security
  - military-tools
aliases:
  - Defense Stack
  - Countermeasure Hierarchy
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!abstract] Dari Pasif ke Proaktif
> Dokumen ini adalah **lapisan pertahanan terpadu** untuk menghadapi setiap alat di military-and-intelligence-tools Hierarchy. Setiap lapisan sesuai dengan level ancaman (0–6) dan mencakup tindakan teknis, prosedural, serta kebijakan. Tidak ada satu lapisan yang sempurna; prinsip **defense-in-depth** adalah kunci.

---

## 🛡️ Level 0 — OSINT Hygiene & Exposure Reduction

**Ancaman:** Maltego, Shodan, Google Dorks — pengumpulan data publik.

| Tindakan                 | Detail                                                                                              | Alat Terkait         |
| ------------------------ | --------------------------------------------------------------------------------------------------- | -------------------- |
| **Data Hygiene**         | Hapus metadata dari dokumen publik (Word, PDF, gambar). Gunakan ExifTool.                           | Google Dorks         |
| **WHOIS Privacy**        | Gunakan WHOIS privacy guard pada semua domain. Jangan gunakan email pribadi.                        | Maltego              |
| **DNS & CT Monitoring**  | Jangan cantumkan hostname internal di sertifikat SSL publik. Monitor Certificate Transparency logs. | Shodan, Maltego      |
| **robots.txt & noindex** | Pasang `Disallow` untuk direktori sensitif, dan meta `noindex` di halaman internal.                 | Google Dorks         |
| **Self-Dorking Berkala** | Jalankan query Google Dorks dan Shodan terhadap domain/netblock sendiri untuk menemukan eksposur.   | Google Dorks, Shodan |
| **Directory Listing**    | Matikan directory listing di server web (`Options -Indexes` / `autoindex off`).                     | Google Dorks         |
| **File Exposure**        | Jangan simpan file backup (.bak, .old, .sql, .env) di direktori publik. Blokir akses ke `/.git/`.   | Google Dorks         |
| **OSINT Monitoring**     | Gunakan Maltego defensif untuk memetakan eksposur sendiri dan hubungan supply chain.                | Maltego              |

---

## 🛡️ Level 1 — Pentest & Exploit Hardening

**Ancaman:** Metasploit, BloodHound, Burp Suite — eksploitasi kerentanan.

| Tindakan                           | Detail                                                                                                                               | Alat Terkait           |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ---------------------- |
| **Patch Management**               | Perbarui semua sistem secara berkala, terutama untuk CVE yang dieksploitasi di alam liar. Gunakan Shodan `vuln:` untuk cek eksposur. | Metasploit, Shodan     |
| **EDR & XDR**                      | Deploy Endpoint Detection and Response yang memonitor process injection, memory tampering, dan anomali perilaku.                     | Metasploit             |
| **Active Directory Hardening**     | Terapkan tiered admin model (T0, T1, T2). Hapus GenericAll/WriteDACL yang tidak perlu. Gunakan LAPS. Monitor BloodHound ingest.      | BloodHound             |
| **Credential Guard**               | Aktifkan Windows Defender Credential Guard untuk melindungi hash NTLM dan Kerberos.                                                  | BloodHound, Metasploit |
| **Web Application Firewall (WAF)** | Pasang WAF dengan aturan ketat untuk mendeteksi payload SQLi, XSS, XXE, dan path traversal.                                          | Burp Suite             |
| **Rate Limiting**                  | Batasi permintaan dari satu IP/token untuk mencegah brute-force (Intruder-style).                                                    | Burp Suite             |
| **Input Validation**               | Validasi semua input di sisi server. Gunakan parameterized query. Encode output.                                                     | Burp Suite             |
| **Burp Collaborator Blocking**     | Blokir domain `*.burpcollaborator.net` di firewall DNS.                                                                              | Burp Suite             |

---

## 🛡️ Level 2 — C2 & Post-Exploitation Detection

**Ancaman:** Cobalt Strike, Havoc C2, Empire, Sliver — C2 dan lateral movement.

| Tindakan                           | Detail                                                                                                              | Alat Terkait                 |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| **Network Traffic Analysis (NTA)** | Analisis NetFlow/IPFIX untuk beaconing pattern (interval periodik, jitter). Gunakan RITA, Zeek, atau NDR komersial. | Semua C2                     |
| **JA3/JARM Fingerprinting**        | Blokir atau alert pada JA3 hash yang dikenal milik framework C2 (Cobalt Strike, Havoc, Sliver).                     | Cobalt Strike, Havoc, Sliver |
| **HTTPS Inspection**               | Inspeksi SSL/TLS di proxy untuk membandingkan SNI dengan Host header (deteksi domain fronting).                     | Cobalt Strike                |
| **PowerShell Logging**             | Aktifkan Script Block Logging (Event ID 4104), Module Logging (4103), dan Transcription. Kirim ke SIEM.             | Empire                       |
| **Constrained Language Mode**      | Terapkan Constrained Language Mode untuk user non-admin agar PowerShell Empire tidak bisa jalan.                    | Empire                       |
| **AMSI Hardening**                 | Monitor upaya menonaktifkan AMSI (memory patching, registry changes). Jangan hanya mengandalkan AMSI.               | Empire, Havoc                |
| **WDAC / AppLocker**               | Batasi executable dan script yang bisa dijalankan hanya dari path tepercaya.                                        | Semua C2                     |
| **Sysmon Deployment**              | Monitor Event ID 1 (process create), 7 (image load), 8 (CreateRemoteThread), 10 (ProcessAccess), 11 (file create).  | Semua C2                     |
| **YARA Memory Scanning**           | Jalankan YARA scan berkala pada process memory untuk mendeteksi implant C2 (sleep stub, reflective loader).         | Cobalt Strike, Havoc         |
| **Detect Indirect Syscalls**       | Gunakan alat seperti Moneta atau HalosGate detector untuk menemukan syscall dari luar `ntdll.dll`.                  | Havoc                        |
| **DNS Monitoring**                 | Monitor DNS untuk query ke domain C2 (termasuk DNS tunneling). Analisis entropy query.                              | Sliver, Empire               |
| **WireGuard Monitoring**           | Monitor koneksi WireGuard keluar ke IP asing yang tidak dikenal.                                                    | Sliver                       |
| **Block Go-http-client UA**        | Blokir User-Agent `Go-http-client` di proxy/WAF (default Sliver).                                                   | Sliver                       |
| **Deception (Honey Tokens)**       | Sebarkan kredensial palsu, file canary, dan service palsu yang jika diakses akan trigger alert.                     | Semua C2                     |

---

## 🛡️ Level 3 — Anti-Spyware & Mobile Hardening

**Ancaman:** Pegasus, FinSpy, Predator — infeksi spyware mobile dan desktop.

| Tindakan                              | Detail                                                                                                             | Alat Terkait             |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| **Lockdown Mode (iOS 16+)**           | Aktifkan Lockdown Mode pada individu berisiko tinggi. Ini adalah pertahanan terkuat terhadap Pegasus dan Predator. | Pegasus, Predator        |
| **Strong Passphrase**                 | Gunakan alphanumeric >12 karakter di semua perangkat. Hindari PIN 4/6 digit.                                       | Pegasus, FinSpy, GrayKey |
| **USB Restricted Mode**               | Matikan akses USB saat terkunci (Settings > Face ID & Passcode > USB Accessories).                                 | Cellebrite UFED, GrayKey |
| **MVT (Mobile Verification Toolkit)** | Jalankan MVT secara berkala pada backup iOS/Android untuk mendeteksi IOC Pegasus, Predator, FinSpy.                | Pegasus, Predator        |
| **iShutdown Analysis**                | Analisis `shutdown.log` untuk proses aneh yang gagal dimatikan (indikasi spyware).                                 | Pegasus                  |
| **Update Berkala**                    | Selalu perbarui iOS/Android/Chrome/Safari ke versi terbaru. Banyak 0-day spyware ditambal dengan cepat.            | Predator, Pegasus        |
| **Hindari Link Mencurigakan**         | Jangan klik link dari sumber tidak dikenal. Verifikasi pengirim via saluran kedua.                                 | Predator                 |
| **Android Hardening**                 | Matikan "Unknown Sources". Periksa Device Admin & Accessibility Services secara berkala.                           | FinSpy, Predator         |
| **iOS Hardening**                     | Periksa Profil Manajemen Perangkat secara berkala. Jangan instal profil dari sumber tidak dikenal.                 | FinSpy, Predator         |
| **Enhanced Safe Browsing (Chrome)**   | Aktifkan "Enhanced Safe Browsing" untuk perlindungan terhadap link exploit.                                        | Predator                 |
| **Desktop Spyware**                   | Gunakan EDR yang mampu mendeteksi kernel driver tidak dikenal, webcam/mic access tanpa izin.                       | FinSpy                   |
| **Secure Boot & TPM**                 | Aktifkan Secure Boot dan TPM untuk mencegah bootkit/MBR infection.                                                 | FinSpy                   |

---

## 🛡️ Level 4 — Hardware & Forensics Counter-Forensics

**Ancaman:** Cellebrite UFED, GrayKey, PC-3000, Victoria HDD — ekstraksi data paksa.

| Tindakan                         | Detail                                                                                                                               | Alat Terkait             |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| **Full Disk Encryption (FDE)**   | Aktifkan FileVault (macOS), BitLocker (Windows), LUKS (Linux), atau Data Protection (iOS). Enkripsi adalah pertahanan utama.         | Cellebrite UFED, PC-3000 |
| **Strong Passphrase**            | Gunakan alphanumeric panjang untuk FDE. Jangan gunakan PIN sederhana.                                                                | GrayKey                  |
| **Self-Encrypting Drive (SED)**  | Gunakan drive dengan enkripsi hardware Opal 2.0. PC-3000 tidak bisa mendekripsi tanpa kunci.                                         | PC-3000                  |
| **ATA Password**                 | Aktifkan password ATA di BIOS/UEFI. Meskipun PC-3000 bisa bypass pada beberapa drive, ini menambah lapisan.                          | PC-3000                  |
| **Erase Data After 10 Attempts** | Aktifkan "Erase Data" di iOS untuk menghapus perangkat setelah 10 upaya gagal.                                                       | GrayKey, Cellebrite UFED |
| **USB Restricted Mode**          | Lihat Level 3.                                                                                                                       | Cellebrite UFED, GrayKey |
| **Physical Destruction**         | Untuk data sangat sensitif: degaussing (HDD) atau shredding fisik. Lebih pasti daripada secure erase.                                | PC-3000, Victoria        |
| **Monitor SMART Attributes**     | Deteksi perubahan mencurigakan pada SMART (erase count, power-on hours reset).                                                       | Victoria                 |
| **Forensik Chain of Custody**    | Jika drive adalah bukti, selalu lakukan pre-imaging verification (Victoria) dan imaging dengan hardware imager (PC-3000) jika rusak. | Victoria, PC-3000        |

---

## 🛡️ Level 5 — Communications Security (COMSEC)

**Ancaman:** Verint, PRISM, UPSTREAM, TEMPORA — intersepsi komunikasi.

| Tindakan                         | Detail                                                                                                                      | Alat Terkait       |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| **End-to-End Encryption (E2EE)** | Gunakan Signal, WhatsApp (chat, bukan backup), Session, Matrix/Elements. Verint/TEMPORA tidak bisa mendekripsi konten E2EE. | Semua SIGINT       |
| **VPN & Tor**                    | Gunakan VPN tanpa log (Mullvad, IVPN, ProtonVPN) atau Tor untuk menyembunyikan IP dan metadata.                             | Semua SIGINT       |
| **Tor Pluggable Transports**     | Gunakan obfs4 atau meek bridge untuk menyembunyikan traffic Tor dari DPI.                                                   | UPSTREAM, TEMPORA  |
| **Metadata Obfuscation**         | Minimalkan metadata: gunakan nomor burner, email burner, hindari pola komunikasi yang bisa diprediksi.                      | ICREACH, XKEYSCORE |
| **Compartmentalization**         | Pisahkan identitas digital: satu perangkat/akun untuk normal, satu untuk sensitif. Jangan pernah campur.                    | PRISM, XKEYSCORE   |
| **Cloud Encryption**             | Enkripsi file sebelum upload ke cloud (Cryptomator, rclone crypt, Veracrypt). Matikan backup tidak terenkripsi.             | PRISM              |
| **Non-US Services**              | Pertimbangkan layanan berbasis di yurisdiksi dengan perlindungan privasi kuat (EU dengan GDPR).                             | PRISM              |
| **Self-Hosting**                 | Hosting email/file sendiri dengan enkripsi penuh.                                                                           | PRISM              |
| **PSTN/GSM Avoidance**           | Hindari panggilan PSTN/GSM untuk percakapan sensitif. Gunakan VoIP dengan E2EE (Signal voice).                              | Verint             |

---

## 🛡️ Level 6 — Legal, Policy & Advocacy

**Ancaman:** XKEYSCORE, Palantir, ICREACH — pengawasan massal negara.

| Tindakan                        | Detail                                                                                                             | Alat Terkait        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------- |
| **Dukung Reformasi Pengawasan** | Advokasi untuk reformasi FISA Section 702, USA PATRIOT Act, dan penghentian pengawasan massal tanpa warrant.       | XKEYSCORE, PRISM    |
| **Dukung Enkripsi Kuat**        | Lawan upaya pelemahan enkripsi (backdoor, key escrow). Dukung organisasi seperti EFF, ACLU, Privacy International. | Semua               |
| **Transparansi Perusahaan**     | Dukung perusahaan teknologi untuk melaporkan jumlah dan jenis permintaan data pemerintah.                          | PRISM               |
| **FOIA & Litigasi**             | Gunakan permintaan Freedom of Information Act untuk mengungkap program pengawasan. Dukung litigasi privasi.        | XKEYSCORE, Palantir |
| **Whistleblower Protection**    | Dukung perlindungan hukum bagi whistleblower yang mengungkap penyalahgunaan.                                       | Semua               |
| **International Advocacy**      | Dukung perjanjian internasional untuk melindungi privasi digital (seperti GDPR, Convention 108+).                  | Semua               |
| **Community Awareness**         | Edukasi komunitas tentang ancaman pengawasan digital. Latih penggunaan alat privasi.                               | Semua               |

---

## 🧩 Peta Pertahanan Menyeluruh

```
COUNTERMEASURE STACK
────────────────────────────────────────────────────────────

Level 0  │ Data Hygiene + Self-Dorking + WHOIS Privacy
Level 1  │ Patch Mgmt + EDR + AD Hardening + WAF + Rate Limiting
Level 2  │ NTA + JA3 + PowerShell Logging + WDAC + Deception
Level 3  │ Lockdown Mode + Strong Passphrase + MVT + USB Restricted Mode
Level 4  │ Full Disk Encryption + Erase Data + Physical Destruction
Level 5  │ E2EE + Tor/VPN + Metadata Obfuscation + Compartmentalization
Level 6  │ Legal Reform + Encryption Advocacy + Whistleblower Support

PRINSIP:
────────────────────────────────────────────────────────────
• Defense-in-depth: Jangan bergantung pada satu lapisan.
• Assume breach: Desain seolah-olah Anda sudah dikompromikan.
• Least privilege: Batasi hak akses ke minimum yang diperlukan.
• Continuous monitoring: Deteksi dini, respons cepat.
• Privacy by design: Enkripsi dan minimalkan data sejak awal.
```

---

## 🔗 Koneksi dalam Vault

Dokumen ini adalah ringkasan defensif dari seluruh alat di military-and-intelligence-tools Hierarchy:

- [[google-dorks]], [[maltego]], [[shodan]] — OSINT defense
- [[metasploit]], [[bloodhound]], [[burp-suite]] — Pentest hardening
- [[cobalt-strike]], [[havoc-c2]], [[empire]], [[sliver]] — C2 detection
- [[pegasus]], [[finspy]], [[predator]] — Spyware defense
- [[cellebrite-ufed]], [[graykey]], [[victoria-hdd]], [[pc-3000]] — Forensics countermeasures
- [[verint]], [[prism]], [[upstream-and-tempora]] — COMSEC
- [[xkeyscore]], [[icreach]], [[palantir-gotham]] — Policy & advocacy
- [[dual-use-spectrum-and-ethical-framework]] — Panduan etis penggunaan alat

---

## 📚 Referensi

- NSA, _Defense in Depth: A Practical Strategy for Achieving Information Assurance_ (2012).
- NIST SP 800-53 Rev. 5, _Security and Privacy Controls for Information Systems and Organizations_.
- Center for Internet Security (CIS), _Critical Security Controls v8_.
- EFF, _Surveillance Self-Defense Guide_.
- Microsoft, _Best Practices for Securing Active Directory_ (2020).
- Apple, _Platform Security Guide_ (2024).

---

_Countermeasure Stack | Defensive Layers Against the Shadow Arsenal | Level 0–6 Hardening Guide_
