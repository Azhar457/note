---
title: "SSRF Defense & Hardening Playbook — Egress Filtering, DNS Rebinding Counter, Metadata Protection, Detection Rules: Blue Team Counter"
tags:
  - cyber-security
  - ssrf
  - blue-team
  - defense
  - web-security
  - api-security
  - egress-filtering
  - library
aliases:
  - "SSRF Counter Playbook"
  - "SSRF Hardening Guide"
  - "Egress Filtering Blue Team"
created: "2026-08-11"
updated: "2026-08-11"
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Ringkasan
> Dokumen counter blue-team untuk **Server-Side Request Forgery (SSRF)** — teknik serangan yang didokumentasikan lengkap di `[[ssrf-deep-dive]]` (attack surface, bypass WAF, cloud metadata exploitation, SSRF→RCE via Redis/Docker/K8s) namun defense-nya hanya berupa tabel ringkas di §8 dan filter IP JavaScript sederhana di §9. Playbook ini membalik arah: dari payload menjadi **hardening berlapis** — arsitektur egress filtering, DNS rebinding counter (second resolve), canonicalization URL, proteksi metadata cloud 169.254.169.254, aturan WAF/CRS konkret, konfigurasi Nginx/Envoy, dan deteksi runtime via eBPF/network monitoring.

**Counter untuk:**
- `ssrf-deep-dive.md` (root) — attack vectors, cloud metadata §4, SSRF→RCE §5, bypass §6-7
- `Web_App_Purple/web-hacking-exploitation.md` — teknik exploit SSRF
- `Web_Security/api-security-deep-dive.md` — SSRF di konteks API
- `WAF_Reverse_Proxy/waf-reverse-proxy-deepdive.md` — WAF SSRF rules

---

## Daftar Isi
- [[#1. Model Ancaman: Kenapa SSRF Berbahaya]]
- [[#2. Arsitektur Pertahanan Berlapis]]
- [[#3. Egress Filtering — Firewall Keluar]]
- [[#4. DNS Rebinding & Second Resolve]]
- [[#5. Canonicalization & URL Parsing]]
- [[#6. Proteksi Metadata Cloud]]
- [[#7. Hardening Aplikasi — Allowlist & Library]]
- [[#8. Aturan WAF / CRS & Konfigurasi Proxy]]
- [[#9. Deteksi Runtime & Response]]
- [[#10. Referensi]]

---

## 1. Model Ancaman: Kenapa SSRF Berbahaya

SSRF terjadi saat aplikasi memproses input user sebagai target request (URL fetch, webhook, callback, import). Bahaya utamanya: **server punya posisi istimewa** — trusted di network internal, akses ke metadata cloud, dan bisa mencapai service yang tidak terekspos publik.

| Vektor dari `[[ssrf-deep-dive]]` | Dampak | Layer counter utama |
|---|---|---|
| Cloud metadata 169.254.169.254 | Credential leak (AWS/GCP/Azure) | §6 |
| SSRF→RCE via Redis/Docker/K8s API | Remote code execution | §3, §7 |
| DNS rebinding | Bypass IP filter statis | §4 |
| URL parsing confusion | Bypass allowlist/denylist | §5 |
| Protocol smuggling (gopher/dict) | Request injection ke internal | §3, §7 |
| Blind SSRF OOB | Internal network scanning | §9 |

Prinsip kunci: **jangan pernah memfilter berdasarkan intent — filter berdasarkan fakta resolve**. Semua filter IP harus berbasis hasil DNS resolve final (setelah redirect), bukan string input.

---

## 2. Arsitektur Pertahanan Berlapis

```
[User Input] → [1. Input Validation] → [2. URL Canonicalization] → [3. DNS Resolve + Second Resolve]
                                            ↓
                              [4. IP Allowlist/Denylist Check]
                                            ↓
                              [5. Egress Firewall (network layer)]
                                            ↓
                              [6. Metadata Proxy / IMDSv2]
                                            ↓
                                   [Backend Fetch]
                                            ↓
                              [7. Response Validation & Logging]
```

- **Layer 1-2**: aplikasi — validasi skema, canonicalisasi (lihat §5)
- **Layer 3-4**: aplikasi/library — second resolve untuk anti DNS rebinding (§4)
- **Layer 5**: infrastruktur — egress filtering wajib di semua environment (§3)
- **Layer 6**: khusus cloud — blokir metadata dari app server (§6)
- **Layer 7**: deteksi — log semua outbound fetch, bandingkan dengan baseline (§9)

> [!note] Defense in depth
> Satu layer bisa di-bypass (allowlist salah parse, WAF rule miss). Yang membuat SSRF sulit dieksploitasi adalah **kombinasi**: filter aplikasi + egress network + metadata protection. Attacker harus menembus semuanya.

---

## 3. Egress Filtering — Firewall Keluar

Kontrol arah outbound dari app server. Ini pertahanan terkuat untuk SSRF→RCE karena membatasi service internal yang bisa dijangkau.

### Prinsip
- **Allowlist egress** (default deny): hanya IP/port yang dibutuhkan bisnis yang boleh keluar (mis. API payment, external webhook, DNS).
- **Denylist egress** (fallback): blokir segmen internal & metadata — `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `100.64.0.0/10`, `127.0.0.0/8`, `0.0.0.0/8`, `::1`, `fc00::/7`, `fe80::/10`.
- Terapkan di **semua** interface, bukan hanya public — attacker bisa pivot.

### nftables (Linux)

```bash
# Chain egress untuk container/app server (contoh)
nft add table inet ssrf_guard
nft add chain inet ssrf_guard egress { type filter hook output priority 0; policy drop; }

# Izinkan DNS + loopback
nft add rule inet ssrf_guard egress oif lo accept
nft add rule inet ssrf_guard egress udp dport 53 accept
nft add rule inet ssrf_guard egress tcp dport 53 accept

# Blokir segmen internal & metadata (deny dulu, walau policy drop)
nft add rule inet ssrf_guard egress ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 100.64.0.0/10, 127.0.0.0/8 } drop
nft add rule inet ssrf_guard egress ip6 daddr { ::1, fc00::/7, fe80::/10 } drop

# Izinkan hanya port service yang dibutuhkan
nft add rule inet ssrf_guard egress tcp dport { 443, 80 } accept

# Log dropped untuk deteksi
nft add rule inet ssrf_guard egress log prefix "SSRF_BLOCK: " counter drop
```

### iptables (legacy)

```bash
iptables -A OUTPUT -d 169.254.169.254 -j DROP
iptables -A OUTPUT -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j DROP
iptables -A OUTPUT -d 100.64.0.0/10 -j DROP
iptables -A OUTPUT -p tcp --dport 6379,2375,6443,9200 -j DROP  # redis/docker/k8s/elastic
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j LOG --log-prefix "SSRF_EGRESS: "
```

> [!warning] IPv6 sering dilupakan
> Banyak stack block IPv4 saja — SSRF via `http://[::ffff:169.254.169.254]/` atau IPv6 literal bypass. Selalu blokir `::1`, `fc00::/7`, `fe80::/10` juga. Lihat `[[ipv6-migration]]` untuk konteks transisi.

---

## 4. DNS Rebinding & Second Resolve

Serangan dari `[[ssrf-deep-dive]]` §6.1: domain di-resolve ke IP publik saat validasi, lalu ke IP internal saat fetch. Counter standar: **resolve dua kali — sekali saat validasi, sekali saat koneksi — dan bandingkan** (atau pin IP hasil validasi).

```python
import socket, ipaddress

PRIVATE = [ipaddress.ip_network(n) for n in [
    "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
    "169.254.0.0/16", "100.64.0.0/10", "127.0.0.0/8",
    "0.0.0.0/8", "::1/128", "fc00::/7", "fe80::/10",
]]

def resolve_all(host):
    infos = socket.getaddrinfo(host, None)
    return {i[4][0] for i in infos}

def ssrf_safe(host, allowlist=None):
    # resolve pertama (validasi)
    ips1 = resolve_all(host)
    # allowlist domain dulu
    if allowlist and host not in allowlist:
        return False, "domain tidak di allowlist"
    # semua IP harus publik
    for ip in ips1:
        a = ipaddress.ip_address(ip.split('%')[0])
        if any(a in net for net in PRIVATE):
            return False, f"IP privat: {ip}"
    # resolve kedua (saat akan connect) — anti rebinding
    ips2 = resolve_all(host)
    if ips1 != ips2:
        return False, "DNS berubah antara validasi dan koneksi (rebinding?)"
    return True, "ok"
```

Praktik tambahan:
- **Pin IP**: resolve sekali, konek ke IP yang sudah tervalidasi, kirim `Host` header asli.
- **TTL check**: tolak resolve dengan TTL sangat pendek (< 30s) untuk domain user-controlled.
- **Use-after-resolve**: di library Go, `net.Dialer` + custom `Resolver` dengan `LookupIPAddr` ganda.

---

## 5. Canonicalization & URL Parsing

Bypass dari `[[ssrf-deep-dive]]` §6.2-6.3: parsing confusion (`http://2130706433`, `http://0x7f000001`, `http://0177.0.0.1`, `http://[::ffff:127.0.0.1]`, `http://127.1`, userinfo `http://evil@127.0.0.1`, backslash `http:\\127.0.0.1`).

### Aturan canonicalization wajib
1. Parse URL dengan **library resmi** (bukan regex) — Go `net/url`, Python `urllib.parse`, Node `new URL()`.
2. Normalisasi: lowercase scheme/host, strip trailing dot, expand IPv4 alternatif (hex/octal/int) → decimal, expand IPv6.
3. Reject kalau hasil canonical berbeda dari input (heuristic suspicious).
4. **Reject userinfo** (`user:pass@host`) kecuali dibutuhkan bisnis.
5. **Reject redirect** lintas-host kecuali target juga di-allowlist — atau batasi redirect maksimal 2 hop.
6. Jangan pernah trust `Host` header dari input untuk routing internal.

```python
from urllib.parse import urlparse

BLOCKED_SCHEMES = {"file", "gopher", "dict", "ftp", "smb", "ldap", "jar", "data"}

def canonicalize(url):
    p = urlparse(url)
    if p.scheme.lower() not in {"http", "https"}:
        raise ValueError(f"scheme ditolak: {p.scheme}")
    if p.username or p.password:
        raise ValueError("userinfo tidak diizinkan")
    if p.scheme in BLOCKED_SCHEMES:
        raise ValueError(f"scheme terblokir: {p.scheme}")
    # normalisasi IP alternatif
    host = p.hostname.rstrip(".")
    return p._replace(netloc=host, scheme=p.scheme.lower()).geturl()
```

> [!note] Jangan block, canonicalize
> Denylist berbasis string selalu bisa di-bypass (encoding ganda, Unicode normalization). Canonicalization + allowlist jauh lebih kuat: **ubah dulu ke bentuk kanonik, baru validasi**.

---

## 6. Proteksi Metadata Cloud

Endpoint metadata adalah target SSRF paling berharga. Counter berlapis:

| Cloud | Endpoint | Blokir di |
|---|---|---|
| AWS | `169.254.169.254` (IMDSv1/v2) | iptables/nftables + IMDSv2 wajib |
| GCP | `metadata.google.internal` / `169.254.169.254` | firewall + metadata server disabled |
| Azure | `169.254.169.254` (IMDS) | firewall + IMDS attachment |
| Alibaba | `100.100.100.200` | firewall |
| DigitalOcean | `169.254.169.254` | firewall |

### AWS IMDSv2 (wajib)
```bash
# IMDSv2 = token-based, blokir v1
aws ec2 modify-instance-metadata-options \
  --instance-id i-xxxx \
  --http-tokens required \
  --http-endpoint enabled \
  --http-put-response-hop-limit 1
```
- `--http-tokens required` → request tanpa token ditolak (SSRF tidak bisa dapat token karena butuh PUT + header `X-aws-ec2-metadata-token-ttl-seconds`).
- `--http-put-response-hop-limit 1` → token tidak bisa di-forward dari container (anti pivot).

### Firewall rule (semua cloud)
```bash
# Blokir metadata dari container/app
iptables -A OUTPUT -d 169.254.169.254 -j DROP
nft add rule inet filter output ip daddr 169.254.169.254 drop
# GCP juga resolve metadata.google.internal → 169.254.169.254
```

### Alternatif arsitektur
- **Metadata proxy**: app tidak pernah akses metadata langsung — proxy internal dengan allowlist path + audit.
- **Service identity** (IRSA / workload identity): ganti akses metadata dengan role injection via identity token — SSRF tidak relevan lagi karena tidak ada credential di metadata.

---

## 7. Hardening Aplikasi — Allowlist & Library

### Allowlist URL (paling kuat)
```python
ALLOWLIST = {
    "api.payment.example.com", "webhook.saas.example.com",
}

def fetch_url(url):
    host = canonicalize(url).hostname
    if host not in ALLOWLIST:
        raise PermissionError(f"host {host} tidak di allowlist")
    # + second resolve anti rebinding
    ok, msg = ssrf_safe(host)
    if not ok:
        raise PermissionError(msg)
    # timeout ketat + batas ukuran response
    resp = requests.get(url, timeout=5, max_redirects=2, stream=True)
    ...
```

### Library / fitur yang membantu
- **Go**: `http.Transport` + custom `DialContext` yang resolve & validasi IP sendiri (pattern `net.Dialer` dengan `Resolver`).
- **Node.js**: `ssrf-req-filter` npm, atau gunakan `got` dengan `allowlist` hook.
- **Python**: `requests` + wrapper validasi di atas; hindari `urllib` langsung.
- **Java**: Apache HttpClient dengan custom `DnsResolver` + `RedirectStrategy` yang validasi.
- **Ruby**: `SSRFFilter` gem.

### Aturan tambahan
- Timeout koneksi ≤ 5s, total fetch ≤ 10s.
- Batas ukuran response (mis. 1 MB) — cegah data exfil besar.
- Nonaktifkan redirect otomatis atau batasi hop (lihat §5).
- Jangan masukkan credential default ke URL fetch (basic auth leakage).

---

## 8. Aturan WAF / CRS & Konfigurasi Proxy

### CRS (Core Rule Set) — rule relevan
| Rule | Fungsi untuk SSRF |
|---|---|
| `REQUEST-921-PROTOCOL-ATTACK.conf` | Protocol smuggling, CRLF injection |
| `REQUEST-930-APPLICATION-ATTACK-LFI.conf` | `file://` scheme detection |
| `REQUEST-931-APPLICATION-ATTACK-RFI.conf` | Remote file inclusion / URL fetch |
| `REQUEST-942-APPLICATION-ATTACK-SQLI.conf` | Payload via SQL injection ke parameter URL |

Lihat `[[owasp-crs-paranoia-levels-scoring]]` dan `[[owasp-crs-rule-structure-analysis]]` untuk tuning.

### Konfigurasi Nginx (reverse proxy)
```nginx
# Blokir SSRF ke metadata & internal dari upstream
location /fetch {
    if ($arg_url ~* "^https?://(169\.254\.169\.254|metadata\.google\.internal|100\.100\.100\.200|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)") {
        return 403;
    }
    proxy_pass http://internal-fetcher:8080;
}
```

### Konfigurasi Envoy (service mesh)
```yaml
# External Authorization + network policy
network_filters:
  - name: envoy.filters.network.rbac
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.rbac.v3.RBAC
      rules:
        action: DENY
        policies:
          block_metadata:
            permissions:
              - destination:
                  ip_prefix: 169.254.169.254/32
            principals:
              - any: true
```

---

## 9. Deteksi Runtime & Response

### Detection baseline
| Sinyal | Indikasi |
|---|---|
| Outbound connect ke IP internal dari app server | SSRF aktif / pivot |
| Request ke port non-standar (6379, 2375, 6443, 9200) | SSRF→RCE attempt |
| DNS query TTL rendah + resolve ganda cepat | DNS rebinding |
| URL input dengan IP alternatif (hex/octal) | Bypass attempt |
| Metadata IP muncul di logs proxy | SSRF attempt |

### eBPF / network monitoring (Linux)
```bash
# contoh: trace outbound connect (bpftrace)
bpftrace -e 'kprobe:tcp_v4_connect { printf("%s -> %d.%d.%d.%d:%d\n", comm,
  ((struct sockaddr_in *)arg1)->sin_addr.s_addr >> 24 & 0xff,
  ((struct sockaddr_in *)arg1)->sin_addr.s_addr >> 16 & 0xff,
  ((struct sockaddr_in *)arg1)->sin_addr.s_addr >> 8 & 0xff,
  ((struct sockaddr_in *)arg1)->sin_addr.s_addr & 0xff,
  ((struct sockaddr_in *)arg1)->sin_port); }'
```
Lihat `[[ebpf-kernel-security]]` dan `[[ebpf-beyond-security]]` untuk deteksi berbasis eBPF.

### Logging yang wajib
- Semua outbound fetch: timestamp, source app, URL kanonik, resolved IP, durasi, status.
- Alert kalau resolved IP ∈ private range atau port non-standar.
- Centralize ke SIEM — lihat `[[siem-security-data-lake-architecture]]`.

### Incident response singkat
1. **Blokir**: egress firewall deny IP target + revoke cloud credentials (rotasi IMDS role).
2. **Analisis**: cek log fetch untuk data yang keluar (token, file, internal responses).
3. **Erdikasi**: patch source — canonicalization + allowlist + second resolve.
4. **Recovery**: rotasi semua credential yang sempat diakses via metadata.

---

## 10. Referensi

- OWASP: [Server-Side Request Forgery Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- PortSwigger: [SSRF — What is SSRF](https://portswigger.net/web-security/ssrf)
- PortSwigger: [SSRF — Bypassing filters](https://portswigger.net/web-security/ssrf#bypassing-ssrf-filters)
- PortSwigger: [DNS rebinding attacks](https://portswigger.net/web-security/ssrf/dns-rebinding)
- AWS: [Instance metadata and user data — IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)
- GCP: [Protect against SSRF — metadata server](https://cloud.google.com/compute/docs/metadata/overview)
- OWASP CRS: [REQUEST-931-APPLICATION-ATTACK-RFI.conf](https://github.com/coreruleset/coreruleset/blob/v4.0/main/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf) — #LOCAL juga di `/mnt/data_d/Projects/Reference/owasp-coreruleset/rules/`
- nftables wiki: [nftables.org](https://wiki.nftables.org/)
- Envoy: [RBAC network filter](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/rbac/v3/rbac.proto)
- bpftrace: [Reference Guide](https://github.com/bpftrace/bpftrace/blob/master/docs/reference_guide.md) — #LOCAL `[[ebpf-kernel-security]]`
- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Server Side Request Forgery/` #LOCAL
- HackTricks: [SSRF — URL validation bypass](https://book.hacktricks.wiki/en/pentesting-web/ssrf-server-side-request-forgery.html)
- CVE-2021-21341 (XStream SSRF) — [nvd.nist.gov](https://nvd.nist.gov/vuln/detail/CVE-2021-21341)
- CVE-2019-15599 (tree-kill, SSRF via redirect) — [nvd.nist.gov](https://nvd.nist.gov/vuln/detail/CVE-2019-15599)

**Cross-link vault:**
- [[ssrf-deep-dive]] — dokumen serangan yang di-counter (utama)
- [[web-hacking-exploitation]] — teknik exploit SSRF di Web_App_Purple
- [[api-security-deep-dive]] — SSRF di konteks API
- [[waf-reverse-proxy-deepdive]] — WAF SSRF rules
- [[ids-ips-waf-nsm-comparison]] — posisi egress filter di arsitektur defense
- [[ebpf-kernel-security]] — deteksi runtime eBPF
