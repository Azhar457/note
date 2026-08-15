---
title: 'Encoding, Serialization & Compression — Deep Dive: base64, JSON, Protobuf,
  gzip, dan Attack Surface'
tags:
- fundamentals
- encoding
- serialization
- library
created: '2026-07-16'
updated: '2026-07-16'
status: pending
cssclasses:
  - wide-table
  

---

# 🔣 Encoding, Serialization & Compression — Deep Dive: base64, JSON, Protobuf, gzip, dan Attack Surface

> Panduan komprehensif encoding, serialization, dan compression yang merupakan fondasi pertukaran data modern. Mencakup encoding (base64, hex, URL, HTML entities, Unicode), serialization formats (JSON, XML, Protocol Buffers, MessagePack, CBOR, YAML, TOML), compression algorithms (gzip, deflate, zstd, brotli), dan — yang paling penting buat security engineer — **attack surface**: deserialization RCE, XXE injection, billion laughs attack, encoding bypass untuk WAF, dan prototype pollution. Catatan ini menyatukan konsep yang tersebar di picoCTF, web hacking, malware analysis, dan API security.

> [!info] Posisi di Vault
> Catatan ini terkait dengan [[http-protocol-deepdive]] (Content-Encoding, Transfer-Encoding, Content-Type), [[web-hacking-exploitation]] (encoding bypass WAF, XXE), [[malware-analysis-reverse-engineering-playbook]] (string decoding, base64, XOR), [[api-security-deep-dive]] (JSON/Protobuf serialization API), [[picoctf-section-2-cyberchef-encodings]] (encoding dasar), [[comprehensive-threat-directory]] (deserialization attack), dan [[cryptography-biometrics]] (encoding vs encryption — beda fundamental).

---

## Daftar Isi

- [[#Foundation]]
- [[#Binary-to-Text Encoding]]
- [[#Character Encodings]]
- [[#Serialization Formats]]
- [[#Compression]]
- [[#Attack Surface]]
- [[#Practical Tooling]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Encoding vs Encryption vs Serialization

| Operasi | Tujuan | Reversible? | Kunci Rahasia? | Contoh |
|---------|--------|-------------|----------------|--------|
| **Encoding** | Representasi data — bikin data binary bisa dikirim lewat medium yang gak support binary | ✅ Ya (100% reversible) | ❌ Tidak — siapa aja bisa decode | base64, hex, URL encoding |
| **Encryption** | Kerahasiaan — cuma pihak dengan kunci yang bisa baca | ✅ Ya (dengan kunci) | ✅ Wajib | AES, ChaCha20 |
| **Hashing** | Integrity — verifikasi data gak berubah | ❌ Tidak (one-way) | ❌ Tidak (tapi salt opsional) | SHA-256, bcrypt |
| **Serialization** | Struktur data → byte stream (transfer/storage) | ✅ Ya | ❌ Tidak (tapi bisa di-enkripsi setelah serialisasi) | JSON, Protobuf, pickle |

> [!warning] Kesalahan Umum
> base64 **bukan** encryption. Lihat orang yang nyebut "mengenkripsi dengan base64" langsung tahu dia gak paham dasar. Base64 = encoding, siapa aja bisa decode dengan 3 baris Python.

### Data Type Hierarchy

```
Data
├── Text (string)
│   ├── Plain: "Hello World"
│   └── Encoded: SGVsbG8gV29ybGQ=  (base64)
├── Binary
│   ├── Raw: \x48\x65\x6c\x6c\x6f
│   └── Encoded: 48656c6c6f  (hex)
├── Structured (serialized)
│   ├── Text-based: JSON, XML, YAML, TOML
│   ├── Binary: Protobuf, MessagePack, CBOR, BSON
│   └── Language-specific: Python pickle, Java serialization, PHP serialize
└── Compressed
    ├── Lossless: gzip, zstd, brotli, LZ4, bzip2
    └── Lossy (media): JPEG, MP3, H.264
```

---

## Binary-to-Text Encoding

### Base64

Base64 meng-encode binary data menjadi string yang hanya terdiri dari `[A-Za-z0-9+/=]` — aman dikirim di media yang cuma support teks (email, HTTP header, JSON).

**Cara kerja:**
```
Teks:        M       a       n
Binary:     01001101 01100001 01101110
Group 6-bit:010011 010110 000101 101110
Decimal:    19     22     5      46
Base64:     T      W      F      u
→ Hasil: "TWFu"
```

**Karakter set:**
```
Index: 0-25 = A-Z, 26-51 = a-z, 52-61 = 0-9, 62 = +, 63 = /
Padding: = (setiap 3 byte → 4 char base64, padding kalo kurang)
```

**Varian:**

| Varian | Karakter | Padding | Dipakai di |
|--------|----------|---------|-----------|
| **Base64** | `A-Za-z0-9+/` | `=` | Standar (MIME, JWT, data URI) |
| **Base64URL** | `A-Za-z0-9-_` | Optional (biasanya tanpa) | URL-safe — JWT, OAuth tokens |
| **Base64 (RFC 4648)** | Sama standar | Wajib | Definisi standar |

```bash
# CLI
echo -n "Man" | base64        # Encode → TWFu
echo "TWFu" | base64 -d       # Decode → Man

# Python
import base64
base64.b64encode(b"Man")      # b'TWFu'
base64.b64decode("TWFu")      # b'Man'
base64.urlsafe_b64encode(b"\xfb\xff")  # b'  _v_8' (base64url)
```

**Karakteristik:**
- Output ~33% lebih besar dari input (3 byte → 4 char)
- **Bukan encryption** — jangan pake untuk "sembunyiin" data
- Dipake di: JWT (base64url), HTTP Basic auth (`base64(user:pass)`), email attachments (MIME), data URI (`data:image/png;base64,...`), malware C2 config

### Hex (Base16)

```
Binary:   11111111 10101010 → FF AA
```

Setiap byte (8-bit) → 2 hex digit (4-bit per digit).

```bash
echo -n "Hello" | xxd -p     # 48656c6c6f
echo "48656c6c6f" | xxd -r -p # Hello

# Python
bytes.fromhex("48656c6c6f")  # b'Hello'
b"Hello".hex()               # '48656c6c6f'
```

**Dipake di:** MAC addresses, SHA hashes, color codes, memory dumps, packet hex dump.

### URL Encoding (Percent Encoding)

```
Spasi → %20
/     → %2F
?     → %3F
=     → %3D
&     → %26
#     → %23
%     → %25 (double-encoding risk!)
```

```bash
python3 -c "import urllib.parse; print(urllib.parse.quote('hello world'))"
# hello%20world

python3 -c "import urllib.parse; print(urllib.parse.unquote('hello%20world'))"
# hello world
```

**Dipake di:** URL query parameters, POST form data (`application/x-www-form-urlencoded`).

### Base58 (Bitcoin)

Base58 = Base64 minus karakter yang mirip: `0OIl` (angka 0, huruf O, I, l). Digunakan di Bitcoin addresses.

```
Base58 alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

---

## Character Encodings

### ASCII — 7-bit

| Range | Karakter | Contoh |
|-------|----------|--------|
| 0-31 | Control | NUL (0), LF (10), CR (13), ESC (27) |
| 32-47 | Symbols | Space, !, ", #, $, %, &, ', (, ), *, +, ,, -, ., / |
| 48-57 | Digits | 0-9 |
| 58-64 | Symbols | :, ;, <, =, >, ?, @ |
| 65-90 | Uppercase | A-Z |
| 91-96 | Symbols | [, \, ], ^, _, ` |
| 97-122 | Lowercase | a-z |
| 123-126 | Symbols | {, \|, }, ~ |

### UTF-8 — Variable-width Unicode (1-4 bytes)

UTF-8 adalah encoding standar internet ( >98% web pages). Backward compatible dengan ASCII.

```
Range            Byte sequence
U+0000-U+007F    0xxxxxxx                                    (1 byte = ASCII)
U+0080-U+07FF    110xxxxx 10xxxxxx                           (2 bytes)
U+0800-U+FFFF    1110xxxx 10xxxxxx 10xxxxxx                  (3 bytes — BMP)
U+10000-U+10FFFF 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx         (4 bytes)
```

**Relevansi security:**
- **UTF-8 BOM** (Byte Order Mark) `\xEF\xBB\xBF` di awal file bisa bypass signature detection
- **Normalization** — huruf bisa direpresentasikan dengan cara berbeda: `é` bisa sebagai `U+00E9` (precomposed) atau `e` + `U+0301` (combining). Bisa bypass input validation.
- **Invalid byte sequences** bisa bypass WAF rules that only check ASCII
- **Zero-width characters** (`U+200B` zero-width space) bisa disembunyikan di code → invisible backdoor

---

## Serialization Formats

### JSON

Format paling populer untuk API. Ringan, readable, native di JavaScript.

```json
{
  "string": "Hello",
  "number": 42,
  "float": 3.14,
  "boolean": true,
  "null": null,
  "array": [1, 2, 3],
  "object": {"key": "val"}
}
```

| Tipe JSON | JavaScript | Python | Go |
|-----------|-----------|--------|-----|
| string | string | str | string |
| number | number | int/float | float64 (int untuk integer) |
| boolean | boolean | bool | bool |
| null | null | None | nil |
| array | Array | list | []interface{} |
| object | Object | dict | map[string]interface{} |

**Security:**

| Issue | Detail |
|-------|--------|
| **Prototype Pollution** | `{"__proto__": {"admin": true}}` — di JS, objek merge bisa kontaminasi prototype chain. Prevent: gunakan `Object.create(null)` atau library safe merge |
| **No circular ref safety** | JSON.stringify() throw error buat circular reference |
| **Large numbers precision loss** | JSON number = IEEE 754 double → integer > 53-bit loss precision. Kirim ID besar sebagai string |
| **Schema validation** | JSON tidak punya schema built-in → butuh validasi eksternal (JSON Schema) |

### XML

Lebih verbose, tapi punya fitur yang JSON gak punya: comments, attributes, namespaces, schemas (XSD), transformations (XSLT).

```xml
<person>
  <name>John</name>
  <age unit="years">30</age>
  <skills>
    <skill>Linux</skill>
    <skill>Security</skill>
  </skills>
</person>
```

**Security — XXE (XML External Entity):**

```xml
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<foo>&xxe;</foo>
```

XXE bisa:
- **Read file** — `file:///etc/passwd`
- **SSRF** — `http://internal-server/admin`
- **Denial of Service** — Billion Laughs Attack (entity expansion eksponensial)
- **Blind XXE** — exfil data via out-of-band (HTTP/DNS request ke attacker server)

**Mitigasi:** Disable external entity processing di parser. Jangan pake XML kalo JSON cukup.

### Protocol Buffers (Protobuf)

Protobuf (Google) adalah binary serialization format dengan schema (`.proto` file). Lebih kecil dan cepat dari JSON.

```proto
syntax = "proto3";
message Person {
  string name = 1;
  int32 age = 2;
  repeated string skills = 3;
}
```

```
Protobuf (16 bytes):
0a 04 4a 6f 68 6e 10 1e 1a 06 4c 69 6e 75 78 53 65 63
│  │  └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
│  └── field number + wire type (varint, length-delimited, etc)

VS JSON (80 bytes):
{"name": "John", "age": 30, "skills": ["Linux", "Sec"]}
```

**Keuntungan:** Ukuran kecil, parsing cepat, typed, backward compatible (field optional). **Kekurangan:** Tidak human-readable, butuh schema di client & server.

**Security:**
- **Malformed input** — Protobuf parser lebih resilient dari XML/JSON (binary, typed)
- **No script injection** — karena binary, gak bisa XSS via serialization
- **Schema enforcement** — field di luar schema langsung diabaikan, bukan error

### MessagePack & CBOR

Binary alternatif JSON yang lebih ringkas:

```python
import msgpack
data = {"name": "John", "age": 30}
packed = msgpack.packb(data)   # 13 bytes vs 27 bytes JSON
msgpack.unpackb(packed)        # Decode
```

| Format | JSON Setara | Ukuran ({"name":"John"}) | Human Readable |
|--------|------------|------------------------|----------------|
| **JSON** | — | 16 bytes | ✅ Ya |
| **MessagePack** | ✅ | 11 bytes | ❌ Binary |
| **CBOR** | ✅ | 12 bytes | ❌ Binary |
| **BSON** (MongoDB) | ✅ | 18 bytes (termasuk length prefix) | ❌ Binary |

### YAML

YAML (YAML Ain't Markup Language) adalah superset JSON — lebih readable, support comments, anchors, multi-line strings.

```yaml
# This is a comment
person:
  name: John
  age: 30
  skills: [Linux, Security]
  description: |
    Multi-line string
    line 2
    line 3
```

**Security — YAML Deserialization RCE:**

```python
# Python PyYAML bisa deserialize arbitrary objects!
import yaml
payload = """
!!python/object:subprocess.Popen
  args: ['cat', '/etc/passwd']
"""
yaml.load(payload)  # RCE!
```

**Mitigasi:** Jangan pake `yaml.load()`, pake `yaml.safe_load()`.

### Python pickle

Python native serialization — bisa serialize APAPUN, termasuk code objects:

```python
import pickle
import os

class Exploit:
    def __reduce__(self):
        return (os.system, ('cat /etc/passwd',))

payload = pickle.dumps(Exploit())
pickle.loads(payload)  # RCE!
```

> [!danger] **Golden Rule:** Jangan pernah `pickle.loads()` data dari untrusted source. Sama dengan `eval()`.

---

## Compression

### Algorithm Comparison

| Algoritma | Kecepatan | Rasio | Dipakai di |
|-----------|-----------|-------|-----------|
| **gzip** (deflate) | 🟡 Medium | 🟡 Medium | HTTP Content-Encoding, file .gz, package managers |
| **brotli** | 🟢 Fast | 🟢 Better than gzip (20% lebih kecil) | HTTP Content-Encoding (Chrome, Firefox), WOFF fonts |
| **zstd** | 🟢 Fast | 🟢 Better than gzip, setara brotli | ZFS compression, container images, Facebook |
| **LZ4** | 🟢⚡ Extremely fast | 🟡 Medium (lower ratio) | Kernel compression, real-time logs |
| **bzip2** | 🔴 Slow | 🟢 High ratio (lebih kecil dari gzip) | File distribution (jarang di HTTP) |
| **xz / LZMA** | 🔴 Very slow | 🔵 Highest ratio | Linux kernel tarballs, package .tar.xz |

### HTTP Compression

```
Request:  Accept-Encoding: gzip, deflate, br
Response: Content-Encoding: br (brotli)
```

Proses: Client kirim `Accept-Encoding` → server pilih kompresi → kompres body → kirim + `Content-Encoding`.

**CRIME Attack (2012):** Compression ratio sebagai oracle — inject known plaintext + ukur perubahan ukuran → recover secret (session cookie). Mitigasi: disable HTTP compression untuk request yang mengandung secret (cookie, CSRF token), atau pake TLS 1.3 yang hapus compression entirely.

### Streaming vs Block Compression

| Mode | Cara Kerja | Contoh |
|------|-----------|--------|
| **Streaming** | Kompres data on-the-fly — gak perlu tahu total ukuran | gzip streaming, Chunked Transfer-Encoding + gzip |
| **Block** | Kompres per blok — bisa random access | zstd dictionary, LZ4 HC |

---

## Attack Surface

### Deserialization RCE

Ini adalah salah satu **top 10 OWASP** yang paling sering menghasilkan RCE.

**Mengapa berbahaya?** Deserialization mengubah byte stream → object. Kalo formatnya support tipe data yang bisa mengeksekusi code (pickle, YAML `!!python`, Java serialization, PHP `unserialize()`), attacker bisa inject object berbahaya yang menjalankan command saat deserialization.

| Platform | Fungsi Berbahaya | Format | RCE? |
|----------|-----------------|--------|------|
| **Python** | `pickle.loads()`, `yaml.load()` (not safe_load) | pickle, YAML | ✅ Yes |
| **Java** | `ObjectInputStream.readObject()`, `readUnshared()` | Java serialization | ✅ Yes (gadget chain) |
| **PHP** | `unserialize()`, `session_decode()` | PHP serialize | ✅ Yes (magic methods) |
| **Ruby** | `Marshal.load()`, `YAML.load()` | Marshal, YAML | ✅ Yes |
| **.NET** | `BinaryFormatter.Deserialize()`, `JavaScriptSerializer()` | Binary, JSON, Soap | ✅ Yes (gadget chain) |
| **Node.js** | `node-serialize`, `funcion constructor` via `eval` | Custom | ✅ Yes |

**Mitigasi:**
1. Jangan deserialize data dari untrusted source
2. Pake format yang gak support arbitrary types — JSON aja (dengan `JSON.parse()`, bukan `eval()`)
3. Kalo harus pake binary format, pake Protobuf atau MessagePack (gak support code execution)
4. Sign + verify serialized data (HMAC) — cuma terima data yang ditandatangani
5. Java: pake filter (JEP 290), library safe seperti `SerialKiller`

### XXE (XML External Entity)

Sudah dijelaskan di section XML — tapi ini cukup penting untuk diulang:

```xml
<!-- Billion Laughs Attack — entity expansion -->
<?xml version="1.0"?>
<!DOCTYPE lolz [
  <!ENTITY lol "lol">
  <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
  <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
  ...  (expansion eksponensial)
]>
<root>&lol999;</root>
```

**Mitigasi:** `libxml_disable_entity_loader(true)` (PHP), `DocumentBuilderFactory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (Java), `defusedxml` (Python).

### JSON Prototype Pollution

```javascript
const merge = (target, source) => {
  for (let key in source) {
    if (typeof source[key] === 'object') {
      merge(target[key] ||= {}, source[key]);
    } else {
      target[key] = source[key];
    }
  }
};

// Attacker sends:
const payload = JSON.parse('{"__proto__": {"admin": true}}');
merge({}, payload);

// Now every object has admin: true
console.log({}.admin);  // true — prototype polluted!
```

**Mitigasi:** Gunakan `Object.create(null)` untuk object tanpa prototype, atau gunakan library merge yang aman (lodash `merge` sudah fix ini).

### Encoding Bypass untuk WAF

Teknik yang sering dipake attacker untuk bypass WAF rules:

| Teknik | Contoh | Bypass |
|--------|--------|--------|
| **Double URL encoding** | `%2527` → WAF decode jadi `%27` → aplikasi decode jadi `'` | SQL injection filter melihat `%2527` bukan `'` |
| **Unicode normalization** | `⒳` atau `%EF%BC%A3` (fullwidth C) instead of `C` | Case-sensitive rules |
| **UTF-8 overlong** | `/` di-encode sebagai `%C0%AF` (2-byte UTF-8 overlong) | Filter yang cek ASCII |
| **Null byte injection** | `../../etc/passwd%00.txt` | Extension-checking WAF |
| **Case variation** | `<sCrIpT>` instead of `<script>` | Case-sensitive rules |
| **Mixed encoding in one request** | URL encode bagian tertentu, double encode bagian lain | Multi-pass decoder confusion |
| **BOM injection** | UTF-8 BOM `\xEF\xBB\xBF` di awal payload | Signature-based WAF |
| **HTML entity encoding** | `&#x3C;&#x73;&#x63;&#x72;&#x69;&#x70;&#x74;&#x3E;` instead of `<script>` | WAF yang gak decode HTML entities |

### WAF Evasion via Chunked Encoding

HTTP Transfer-Encoding chunked bisa dipake untuk smuggling:

```
POST / HTTP/1.1
Transfer-Encoding: chunked
Content-Length: 4    ← Frontend pake Transfer-Encoding (ignore Content-Length)
                    Backend pake Content-Length (ignore TE)

5c                  ← "5c" = 92 bytes chunk
GET /admin HTTP/1.1
Host: internal
Content-Length: 10
```

---

## Practical Tooling

```bash
# base64
echo -n "data" | base64
echo "ZGF0YQ==" | base64 -d
openssl enc -base64 <<< "data"

# hex
echo -n "Hello" | xxd -p
echo "48656c6c6f" | xxd -r -p
hexdump -C file.bin          # Canonical hex+ASCII

# URL encode/decode
python3 -c "import urllib.parse; print(urllib.parse.quote('a b'))"
python3 -c "import urllib.parse; print(urllib.parse.unquote('a%20b'))"

# JSON
python3 -m json.tool data.json    # Pretty-print + validate
jq '.key' data.json               # Query JSON

# Compression
gzip -k file                    # Compress (keep original)
gzip -d file.gz                 # Decompress
zcat file.gz                    # View compressed file
zstd file                       # zstd compress
zstd -d file.zst                # zstd decompress

# Protobuf
protoc --decode_raw < data.bin  # Decode tanpa schema
protoc --decode Person person.proto < data.bin  # Dengan schema
```

---

## Koneksi ke Vault

- [[http-protocol-deepdive]] — Content-Encoding, Transfer-Encoding, Content-Type di HTTP
- [[web-hacking-exploitation]] — encoding bypass WAF, XXE injection, deserialization
- [[malware-analysis-reverse-engineering-playbook]] — base64 decode, XOR decode, string decoding
- [[api-security-deep-dive]] — JSON/Protobuf serialization API, gRPC
- [[picoctf-section-2-cyberchef-encodings]] — encoding dasar untuk CTF (base64, hex, rot13, xor)
- [[cryptography-biometrics]] — beda encoding vs encryption
- [[comprehensive-threat-directory]] — deserialization attack taxonomy
- [[browser-security-exploitation-deepdive]] — XSS via HTML encoding bypass

---

## References

1. IETF. *RFC 4648: The Base16, Base32, and Base64 Data Encodings*. 2006.
2. IETF. *RFC 3986: URI Generic Syntax (Percent Encoding)*. 2005.
3. IETF. *RFC 3629: UTF-8, a transformation format of ISO 10646*. 2003.
4. IETF. *RFC 8259: The JavaScript Object Notation (JSON)*. 2017.
5. IETF. *RFC 1952: GZIP file format specification*. 1996.
6. IETF. *RFC 7932: Brotli Compressed Data Format*. 2016.
7. Facebook. *Zstandard Compression*. https://github.com/facebook/zstd
8. Google. *Protocol Buffers*. https://protobuf.dev/
9. OWASP. *Deserialization Cheat Sheet*. https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html
10. OWASP. *XML External Entity (XXE) Prevention*. https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html
11. OWASP. *Prototype Pollution Prevention*. https://cheatsheetseries.owasp.org/cheatsheets/Prototype_Pollution_Prevention_Cheat_Sheet.html
12. PortSwigger. *What is XXE?* https://portswigger.net/web-security/xxe
13. PortSwigger. *What is Deserialization?* https://portswigger.net/web-security/deserialization
14. PortSwigger. *CRIME Attack*. https://portswigger.net/daily-swig/crime-attack
15. Python Security. *pickle documentation*. https://docs.python.org/3/library/pickle.html
16. Frohoff & Lawrence. *ysoserial — Java deserialization gadget chains*. https://github.com/frohoff/ysoserial
17. W3C. *XML Specification*. https://www.w3.org/XML/
18. MessagePack. *MessagePack Specification*. https://msgpack.org/index.html
19. CBOR. *RFC 7049*. https://cbor.io/
20. YAML. *YAML Specification*. https://yaml.org/spec/

> [!tip] Bottom Line
> Encoding, serialization, dan compression adalah **fondasi pertukaran data** yang sering dianggap remeh. Setiap satu dari 10,000 API request yang lewat hari ini pasti melewati setidaknya base64, JSON, dan gzip. Buat security engineer: (1) **base64 ≠ encryption** — jangan pernah pake base64 untuk keamanan. (2) **Pickle/YAML.load/Java unserialize/ unserialize** adalah RCE dalam bentuk serialization — jangan pernah deserialize data dari untrusted source dengan fungsi-fungsi itu. (3) **XXE** masih ada di 2026 — karena XML masih dipake di enterprise legacy dan SOAP API. (4) **Encoding bypass** adalah teknik paling umum untuk melewati WAF — paham double encoding dan unicode normalization adalah minimum. (5) **Kompresi sebagai oracle** — CRIME attack membuktikan bahwa compression ratio bisa dipake untuk recover secret — alasan kenapa TLS 1.3 menghapus compression.
---

audited
---
