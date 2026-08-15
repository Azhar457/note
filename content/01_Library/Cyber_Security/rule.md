---
title: Rule
tags: [security, policy, rules]
aliases: [rule, security-rules]
---
# Rule — Kompendium Aturan Keamanan

Catatan ini adalah daftar aturan/pedoman yang berlaku di lingkungan kerja maupun pribadi: prinsip hard security, kebijakan teknis, dan aturan operasional. Dipakai sebagai referensi cepat saat implementasi, audit, atau saat mengambil keputusan security.

## Aturan Inti (Core Rules)

1. **Least Privilege** — tidak ada entitas (user, service, process) yang punya akses di luar kebutuhannya. Review akses berkala (kuartal).
2. **Default Deny / Default Fail Closed** — jika ragu, blokir; error default = secure, bukan permissif.
3. **No Secrets in Code** — file config, env var, credential tidak boleh commit ke repo (gitleaks/secret scanning di CI).
4. **Defense in Depth** — kontrol berlapis: jangan bergantung satu mekanisme.
5. **Fail Securely** — error handling tidak bocorkan detail internal (stack trace, query, path).
6. **Validate Everything** — input user, input internal, output: validasi & sanitasi server-side.
7. **Encrypt in Transit & at Rest** — TLS untuk semua traffic; enkripsi disk/data sensitive.
8. **Audit & Monitor** — semua aksi penting di-log (who, what, when); SIEM aktif.
9. **Principle of Least Astonishment** — desain yang intuitif dan tidak menyesatkan user (lihat [[dark-patterns-resistance]]).
10. **Assume Breach** — desain dengan asumsi attacker sudah di dalam: segmentasi, monitoring, response plan.

## Aturan Teknis (Technical Rules)

### Password & Credential
- Password minimum 12+ karakter; password manager wajib untuk tim.
- MFA untuk semua akses (terutama admin & remote).
- Service account: token dengan expiry; rotate key berkala (30-90 hari).
- Jangan pakai default credential (router, DB, BMC, dashboard).
- Password storing: hash (Argon2/bcrypt), bukan reversible (encryption) untuk authenticasi.

### Network & Infra
- Firewall default deny inbound; egress dibatasi whitelist.
- SSH: key-based auth, tidak ada root login, rotate key.
- Segregation: DMZ, internal, DB terisolasi; jump host untuk admin.
- TLS config: minimum TLS 1.2, disable old ciphers (AES-GCM, ChaCha20).
- VPN/proxy dibidik melalui gateways; jangan direct internet dari DB/storage.

### Aplikasi & Code
- Parameterized query (anti SQLi); input validation whitelist.
- CSRF token; proper session management (HttpOnly, SameSite, Secure).
- Dependency scan (SCA) + SAST di CI; upgrade dependency rutin.
- Secret handling di aplikasi: gunakan secret manager (Vault/K8s secrets/cloud KMS), bukan hardcode.
- Docker: non-root user, distroless, scanned image (Trivy), signed.
- Error messages: generic untuk user; detail hanya di log server.

### Operasional & Incident Response
- Backup: 3-2-1 rule + restore testing rutin (bulanan).
- Incident: playbook, severity rubric, communication plan; postmortem tanpa blame.
- Patching: critical (CISA KEV) ≤ 48 jam; high ≤ 7 hari; medium ≤ 30 hari.
- Remote access log & review; session recording untuk admin penting.
- Penetration test tahunan (atau berkelanjutan) + remediasi di-track.

## Aturan Kebersihan Digital (Personal)

1. Browser: uBlock Origin + Privacy Badger; HTTPS everywhere; jangan simpan password di browser tanpa master password.
2. Update OS & aplikasi otomatis/minimal mingguan.
3. Email: jangan klik link tanpa hover-check domain; attachment di-scan; waspada urgency/spoof.
4. Wi-Fi publik: gunakan VPN (jangan WARP transit blokir — pakai route internal).
5. 2FA semua akun penting; recovery codes disimpan offline.
6. Backup lokal + cloud terenkripsi.

## Aturan Audit (Checklist Rutin)

- [ ] Akses review (RBAC) menggunakan least privilege?
- [ ] Secret scan: tidak ada token/key di repo?
- [ ] Patch critical dalam SLA?
- [ ] Monitoring aktif (SIEM + alert actionable)?
- [ ] Backup teruji restore?
- [ ] Firewall/egress policy di-review?
- [ ] Dependency clean (no critical CVE)?

## Catatan

- Aturan ini "living document" — update saat teknologi/ancaman berubah.
- Konteks vault: integrasikan dengan [[defense-in-depth-strategy]], [[sre-practices-and-slo]], SOP di 02_SOPs, dan hierarchy security di 00_Atlas.



## Aturan Khusus: Red Team & Pentest (Sesuai Etika Terukur)

1. **Scope & boundary** — jangan pernah testing di luar scope tertulis; dokumentasi izin.
2. **No production harm** — destructive action (delete, drop, encrypt) hanya di environment test; jika terpaksa, approval eksplisit.
3. **Data handling** — data yang ditemukan (credentials, PII) tidak disebar; dilaporkan via jalur resmi (HackerOne, disclosure policy).
4. **Rate limit & stealth** — jangan bruteforce produksi; hindari DoS unintended (lihat rule umum #4).
5. **Reporting** — tulis temuan dengan PoC, impact, mitigo; timeline disclosure.
6. **Tools hygiene** — payload tooling tidak meninggalkan backdoor tanpa persetujuan; bersihkan artifact.

## Aturan Khusus: AI/LLM dalam Operasi

- Jangan memasukkan data sensitif (kode produksi, personal data) ke LLM publik tanpa persetujuan (data residency).
- Output AI divalidasi manusia sebelum aksi produksi (lihat [[prompt-injection-defense]]).
- LLM dalam pipeline security hanya read-only kecuali disetujui (auto-remediate = risiko).
- Log semua interaksi AI yang menyentuh data (audit trail).

## Penalty & Enforcement (Opsional untuk Organisasi)

- Pelanggaran rule → review dengan atasan/security lead; severity tergantung dampak.
- Akses dicabut sementara saat investigasi (least privilege).
- Setiap temuan audit (no-compliance) di-track dengan deadline.
- KPI aturan: % kepatuhan, % patching dalam SLA, insiden per bulan.

## Daftar Cepat "Jangan Pernah"

- Jangan pernah: hardcode secret, share password via chat/email, disable firewall untuk "kemudahan", expose DB ke internet, pakai default credential, install software tanpa verifikasi, klik link mencurigakan tanpa cek, abaikan alert keamanan, melakukan testing tanpa izin.

---

  audited
---