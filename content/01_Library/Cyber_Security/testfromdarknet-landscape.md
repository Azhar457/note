---
title: TESTFROMDARKNET Landscape — Koleksi Sampel Darkweb, Malware & Jailbreak Prompts
tags:
- darknet
- malware
- jailbreak
- red-team
- android-rat
- threat-intel
- osint
- collection
created: '2026-08-11'
updated: '2026-08-11'
status: pending
cssclasses:
  - wide-table
  

source: /home/jars/TESTFROMDARKNET (read-only inventory)
aliases:
- Darknet Samples Collection
- TESTFROMDARKNET
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Inventarisasi read-only koleksi sampel di `/home/jars/TESTFROMDARKNET`: darknet forum dumps, jailbreak system prompts, RAT Android & tooling, malware samples, serta MCP integration. Catatan ini hanya **mendokumentasikan struktur & isi** — tidak mengubah, mengeksekusi, atau menyebarkan sampel. Memberi gambaran lebih besar (big picture) atas material yang tersedia untuk penelitian pertahanan & offense.

## Daftar Isi

1. [Konteks & Tujuan](#1-konteks--tujuan)
2. [Komposisi Koleksi](#2-komposisi-koleksi)
3. [Kategori A: Jailbreak System Prompts](#3-kategori-a-jailbreak-system-prompts)
4. [Kategori B: Darknet Forum & MaaS Dumps](#4-kategori-b-darknet-forum--maas-dumps)
5. [Kategori C: Android RAT & Tooling](#5-kategori-c-android-rat--tooling)
6. [Kategori D: Malware Samples & APK](#6-kategori-d-malware-samples--apk)
7. [Kategori E: MCP & Integrasi Tooling](#7-kategori-e-mcp--integrasi-tooling)
8. [Catatan Keamanan & Handling](#8-catatan-keamanan--handling)
9. [Koneksi ke Vault](#9-koneksi-ke-vault)

---

## 1. Konteks & Tujuan

Folder ini berisi **bekas-bekas unduhan riset** (darkweb, MalwareBazaar, forum) yang dikumpulkan untuk dianalisis. Bukan material produksi. Tujuan dokumentasi: memetakan apa yang ada, menilai relevansi, dan menarik gambaran besar ekosistem (prompt injection → tooling → malware) tanpa membuka sampel di host langsung.

Aturan handling (lihat juga catatan lain): **jangan extract/exec di host**, pakai container/sandbox, verifikasi magic bytes (`file`/`xxd`) sebelum ekstraksi.

## 2. Komposisi Koleksi

| Kategori | Contoh entry | Jumlah |
|---|---|---|
| Text dumps (forum/MaaS/prompt) | DARKNETFORUM.txt, MVP-MaaS.txt, PROMPT-INJECTION.txt | ~17 txt |
| APK (malware/samples) | cloudflare.apk, Myapp.apk, com-cloudflare-*.apk | 3+ |
| RAT Android source | AhMyth, AndroRAT, L3MON, DogeRat, shadow | 5 dir |
| MCP tooling | MalwareBazaar_MCP, exodus_bbp, syfe_bbp | 3 dir |
| Tooling RE | pyinstxtractor, RE-tools, re_cf1111, re_uptodown | 4 dir |
| Lainnya | VEIL_Advanced_RAT.zip, composer.dat, test-waydroid.sh | 8+ |

## 3. Kategori A: Jailbreak System Prompts

Sampel real yang terdokumentasi:

- **PROMPT INJECTION.txt / SOUL-INJECT.MD.txt** — system prompt jailbreak bertema *persona* (veil/mask) yang menekankan kontinuitas thinking, larangan menolak Maker, dan aturan output. Menunjukkan pola *persona-bypass* modern.
- **RAW_CHAT_JAILBREAK_DEEPSEEK/GROX.txt** — percakapan jailbreak mentah terhadap dua model, bahan studi bagaimana boundary model diuji.

> [!warning] Relevansi Defensif
> Sampel ini penting untuk *prompt injection defense*: memahami pola persona-bypass, anti-refusal phrasing, dan ekspektasi output membantu menyusun guardrail yang lebih kuat (bandingkan dengan [[prompt-injection-defense]] di vault).

## 4. Kategori B: Darknet Forum & MaaS Dumps

| File | Isi |
|---|---|
| `DARKNETFORUM.txt` | Dump forum: API phone lookup (Numverify, Twilio, Plivo, GetContact), address geocoding, WHOIS/domain (WhoisFreaks, WhoisXML), scraping API (WebScraping.AI, ZenRows). Pola: **akumulasi OSINT API gratis/berbayar** utk lookup & scraping. |
| `MVP-MaaS.txt` / `MVP-RAT+RANSOMWARE.txt` | Deskripsi *Malware-as-a-Service* & RAT+Ransomware bundle — model bisnis underground. |
| `Missing-FIle.txt` / `raw.txt` | Catatan & output mentah terkait koleksi. |

## 5. Kategori C: Android RAT & Tooling

| Tool | Diri |
|---|---|
| **AhMyth** | RAT Android open-source (client+server). |
| **AndroRAT** | RAT Android klasik (remote control penuh). |
| **L3MON** | RAT Android berbasis cloud (C2, file manager, kamera, mic). |
| **DogeRat** | RAT + RE report (NOTES/DogeRat_RE_report.md). |
| **shadow** | Server RAT dengan bridge.py + shadow-so (native lib Android.mk/Application.mk) — sumber bisa dipakai utk analisis kompilasi native. |
| **msf_android** | Payload/metasploit android. |

## 6. Kategori D: Malware Samples & APK

| File | Catatan |
|---|---|
| `cloudflare.apk`, `com-cloudflare-*.apk`, `Myapp.apk` | APK riset (ukuran 14–34MB) — kemungkinan hasil repack/payload. Jangan install di perangkat utama. |
| `composer.dat(.zip)` + `composer.dat_extracted` | Data yang sudah diekstrak — verifikasi isi sebelum dipakai. |
| `VEIL_Advanced_RAT.zip` vs `VEIL_C2_FULL_SOURCE.txt` | RAT source dump; zip = arsip, txt = source teks. |

## 7. Kategori E: MCP & Integrasi Tooling

- **MalwareBazaar_MCP** — MCP server untuk MalwareBazaar (query hash, sample info). `.py` + tests: integrasi threat intel via MCP.
- **exodus_bbp / syfe_bbp** — folder bug bounty / program (BBP = Bug Bounty Program) + json metadata (syfe_bbp-2026-08-09T04_28_43Z.json).
- **RedteamAgent, sentinel, cf_work** — tooling red-team & Cloudflare Workers experiment.

## 8. Catatan Keamanan & Handling

1. **Jangan ekstrak arsip di host** — RAR/zip bisa jadi polyglot; gunakan container (podman) + `file`/`xxd` magic-check dulu.
2. **APK jangan di-install** — bisa memuat payload RAT; analisis statis di sandbox (apktool/jadx) bila perlu.
3. **Prompt jailbreak hanya bahan analisis** — digunakan utk memahami pola defense, bukan utk menjalankan.
4. **Redaksi data pribadi** — dump forum berisi email/API key (mis. token di header artikel/DARKNETFORUM). Jangan sebarkan.
5. Referensi handling lanjutan: [[untrusted-artifact-analysis]] & [[malware-analysis-workflow]] (bila ada di vault).

## 9. Koneksi ke Vault

- [[cyber-security]] — payung domain keamanan
- [[web-hacking-exploitation]] — teknik serangan yang relevan utk defense
- [[ctf-competition-methodology-strategy]] — metodologi analisis
- [[threat-intel]] — perspektif intel atas sampel MaaS/RAT

## References

1. File inventory TESTFROMDARKNET (ls -laR, 2026-08-11)
2. DARKNETFORUM.txt (API OSINT lookup list)
3. PROMPT INJECTION.txt / SOUL-INJECT.MD.txt (jailbreak prompt samples)
4. MalwareBazaar_MCP/README.md (MCP integration)
5. AhMyth/README.md, L3MON, DogeRat NOTES/DogeRat_RE_report.md (RAT tools)


## 10. Deepdive — Riset Workflow & Red Team Value

### 10.1 Analisis Ekosistem (Jailbreak → Tooling → Malware)

```
Kategori A (Jailbreak prompts)  → cara LLM safety bypass → red team LLM eval
Kategori B (Forum/MaaS dumps)   → TTP pasar gelap → threat intel pattern
Kategori C (Android RAT source) → custom implant → APK injection pipeline
Kategori D (Malware samples)    → signature/behavior → AV evasion learning
Kategori E (MCP tooling)        → automasi intel (MalwareBazaar, BBP recon)
```

### 10.2 Handling Aman (Sandbox Workflow)

```bash
# Jangan pernah extract/exec di host — pakai container
docker run --rm -it --network none -v /home/jars/TESTFROMDARKNET:/data:ro debian:bookworm

# Verifikasi magic bytes SEBELUM ekstraksi
file /data/malware.bin          # → "ELF 64-bit" / "Zip archive" dll
xxd /data/malware.bin | head    # lihat header manual

# Hash dulu untuk intel (YARA/ThreatIntel)
sha256sum /data/malware.bin

# Network: --network none → tidak ada C2 call-out saat analisis
```

### 10.3 Intel Value per Kategori

| Kategori | Threat Intel Output |
|----------|---------------------|
| Jailbreak prompts | Evolving bypass patterns → LLM guardrail update |
| Forum dumps | Nama marketplace, TTP, pricing → CTI report |
| RAT source | Kode C2, persistence method → detection rule (YARA/Sigma) |
| Malware samples | C2 domain, exfil endpoint → IOC blocklist |
| MCP tooling | Automasi pipeline → SOC automation reference |

### 10.4 Dokumen Pendamping

| Dokumen | Fungsi |
|---------|--------|
| `ShadowC2 RE report` | Analisis RAT shadow (C2, persistence) |
| `DogeRat RE report` | Perbandingan RAT lain |
| `MalwareBazaar MCP` | API automasi sample retrieval |
| `exodus_bbp / syfe_bbp` | Bug bounty recon workflow |

## 11. Referensi

- MalwareBazaar — https://bazaar.abuse.ch/
- VirusTotal — https://www.virustotal.com/
- YARA rules — https://yara.readthedocs.io/
- Sigma rules — https://github.com/SigmaHQ/sigma
- MITRE ATT&CK — https://attack.mitre.org/
---

audited
---
