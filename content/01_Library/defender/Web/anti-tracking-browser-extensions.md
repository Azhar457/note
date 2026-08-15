---
title: Anti-Tracking Browser Extensions
tags: [security, privacy, browser]
aliases: [anti-tracking-browser-extensions]
---
# Anti-Tracking Browser Extensions

Ekstensi browser adalah baris pertahanan privasi pertama: blokir tracker iklan, fingerprinting, dan mengurangi data yang bocor ke pihak ketiga. Dokumen ini membahas ekstensi efektif, cara kerja, limitasi, dan konfigurasi.

## Ancaman yang Ditangani

1. **Tracking ads** — iklan yang melacak aktivitas (cookie, pixel).
2. **Fingerprinting** — canvas, WebGL, audio, fonts, timezone, screen — profil unik tanpa cookie.
3. **Cross-site tracking** — third-party cookies, browser storage, CNAME cloaking.
4. **Malvertising / redirect** — iklan jahat redirect ke phishing/malware.
5. **Cryptojacking** — script mining di halaman.
6. **Kebocoran referrer** — header Referer membocorkan URL sebelumnya.
7. **Analytics agregat** — data perilaku ke vendor (Google/Facebook).

## Ekstensi Pilihan (Open Source Preferred)

| Ekstensi | Fungsi | Catatan |
|----------|--------|---------|
| **uBlock Origin** | Blokir iklan/tracker (list-based + cosmetic) | Gold standard; medium mode untuk lanjutan |
| **Privacy Badger** (EFF) | Blokir tracker belajar sendiri | Algoritmik (liar untuk some); kompatibel uBO |
| **NextDNS / Pi-hole** | DNS filtering (bukan ekstensi tapi layer) | Blokir domain tracker di level DNS: efektif & hemat |
| **Decentraleyes / LocalCDN** | Serve CDN resources lokal | Kurangi permintaan CDN (privasi + offline) |
| **ClearURLs** | Bersihkan parameter tracking (utm_*) | Prevent redirect tracker |
| **KeePassXC-Browser** | Password manager (anti-phishing) | Jangan simpan password di browser |
| **NoScript** (opsional) | Default deny script | Kuat tapi agresif; untuk power user |
| **Firefox Multi-Account Containers** | Isolasi sesi (Google, social, bank) | Contextual isolation: cegah cross-site |

## Cara Kerja (Teknis)

- **Request blocking**: ekstensi hook `webRequest` (MV2) atau `declarativeNetRequest` (MV3) — block URL pattern dari list (EasyList, EasyPrivacy, uBO filters).
- **Cosmetic filtering**: sembunyikan elemen iklan (CSS) — bukan blok request; hemat resource.
- **CNAME cloaking**: tracker pakai subdomain first-party (`tracker.site.com` CNAME ke `ads.tracker.net`) — DNS filter (NextDNS/Pi-hole) menangkapnya (ekstensi MV3 kesulitan tanpa deklarasi dinamis).
- **Fingerprint defense**: uBO "block canvas read" (opsional, medium mode) — sebagian; ekstensi anti-fingerprint penuh (CanvasBlocker) bisa break situs — gunakan selektif. Best: browser hardening (Firefox: resistFingerprinting) + WebGL spoof seperlunya.

## Konfigurasi uBlock Origin (Medium Mode)

```text
⚙ Settings:
- Default lists: uBlock filters, EasyPrivacy, EasyList, (fanboy annoyance)
- Advanced user: "I am an advanced user" → medium mode
- My filters: (custom)
  ||example-analytics.com^
  *.*,1p JS,3p CSS      # medium mode: block 3rd-party scripts
Whitelist: (situs yang butuh 3rd-party)
  @@||cdn.jsdelivr.net^
```
Medium mode: blokir semua third-party script/frame — banyak situs tetap jalan, privasi naik drastis.

## Browser Choice & Hardening

- **Firefox**: privasi terbaik default: `privacy.resistFingerprinting=true`, `privacy.trackingprotection.enabled=true`, `network.proxy.socks_remote_dns=true` (DNS via SOCKS), `dom.security.https_only_mode=true`, `browser.send_pings=false` (hapus ping), disable telemetry (`datareporting.*`).
- **Brave**: built-in shields (agresif), fingerprint random; chromium engine.
- **Chromium/Chrome**: dengarkan — HALF. Gunakan uBO + clear URLs + disable "Allow sites to see if you're using assistive tech" dll; bukan pilihan privasi terbaik default.
- **Tor Browser** (jika butuh anonimitas penuh): fingerprint seragam semua pengguna; jangan login akun pribadi.

## Limitasi (Jujur!)

1. **Ekstensi TIDAK menyembunyikan IP** — VPN/Tor untuk itu (catatan: VPN ≠ anonim — trust provider).
2. **Fingerprinting sebagian** — canvas block bisa di-detect (headless browser dll) — resistFingerprinting lebih baik tapi tidak sempurna.
3. **Login tracking** — saat login ke Google/Facebook, mereka tetap tahu (dari akun) — isolasi via container.
4. **CNAME cloaking** — butuh DNS layer (NextDNS/Pi-hole) atau list uBO terbaru.
5. **First-party tracking** — situs melacak sendiri (analytics on same domain) — ekstensi tidak blokir; browser setting "block third-party cookies" tidak mempan.
6. **Extensions leak** — ekstensi jahat = semua data; instal hanya dari store resmi + review + open source (tidak semua).

## Privacy Checklist (Browser)

- [ ] uBlock Origin aktif (medium mode + custom filters)
- [ ] Firefox hardening (atau Brave shields)
- [ ] DNS filtering (Pi-hole/NextDNS) di jaringan
- [ ] ClearURLs / LocalCDN
- [ ] Cookie: auto-clear third-party; container untuk situs penting
- [ ] Password di manager (bukan browser)
- [ ] HTTPS-only mode
- [ ] Telemetry browser dimatikan
- [ ] Ekstensi minimal (kurang = lebih; setiap ekstensi = attack surface & fingerprint)

## Red Team/Blue Team Notes

- **Blue**: standarkan konfigurasi browser tim (policy via enterprise policy/GPO) — kurangi phishing & tracking dari lingkungan kerja.
- **Red**: ekstensi = vektor (malicious extension, update hijack) — user dengan 20 ekstensi = permukaan lebih besar. Uji social engineering: fake "privacy extension" yang sebenarnya keylogger.
- **Testing**: verifikasi anti-tracking bekerja (coverourtracks.eff.org, deviceinfo.me, amiunique.org) — cek fingerprint variance.



## Extension Permission Audit (Jangan Sembarang)

1. Hanya install dari store resmi (AMO untuk Firefox, CWS untuk Chrome); cek publisher & jumlah user.
2. Tinjau permission prompt: ekstensi "privacy" yang minta `read all sites` + `all data` = tanda bahaya.
3. Prefer open source (GitHub repo aktif + audit).
4. Batasi: < 10 ekstensi ideal; hapus yang tidak dipakai (setiap extension = vector + fingerprint).
5. Update otomatis aktif — tapi waspadai "extensions are always-on" — review berkala (bulanan).

## Workflow Setting: Firefox Privacy Configuration (about:config)

```
privacy.resistFingerprinting = true
privacy.trackingprotection.enabled = true
privacy.trackingprotection.socialtracking.enabled = true
network.http.referer.XOriginPolicy = 2
network.http.referer.trimmingPolicy = 2
dom.security.https_only_mode = true
browser.send_pings = false
extensions.pocket.enabled = false
media.peerconnection.enabled = true  # WebRTC (IP leak) — false jika tidak butuh
webgl.disabled = false  # sesuaikan (fingerprint)
```

## Test Privasi (Verifikasi)

- coverourtracks.eff.org — fingerprint variance test.
- deviceinfo.me, amiunique.org — lihat seberapa unik profil.
- Panopticlick (EFF legacy) — alternatif.
- BrowserLeaks: WebRTC leak test, canvas fingerprint test.
- Private/incognito ≠ anonim — masih fingerprintable & DNS visible (tanpa VPN/DNS filter).

## Enterprise Deployment (Tim)

- GPO (Windows/Chrome/Firefox managed): atur ekstensi allowlist, disable inkognito? (tidak — privasi user), force HTTPS, proxy.
- Policy: extension allowlist hanya yang disetujui (privacy-compliant).
- Deliver hardening config via fleet management (Ansible/Intune) — konsisten.

---

  audited
---