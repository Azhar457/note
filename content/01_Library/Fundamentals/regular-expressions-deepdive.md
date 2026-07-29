---
title: "Regular Expressions — Deep Dive: Quantifiers, Groups, Lookahead, Performance,
  dan Detection Engineering"
tags:
  - fundamentals
  - regex
  - library
created: "2026-07-16"
updated: "2026-07-16"
status: pending
cssclasses:
  - wide-table
---

# 🧠 Regular Expressions — Deep Dive: Quantifiers, Groups, Lookahead, Performance, dan Detection Engineering

> Panduan komprehensif regular expressions dari perspektif security engineer. Regex adalah fondasi dari **semua detection tool** di vault ini — Sigma rules, YARA rules, Suricata IDS rules, WAF rules (ModSecurity, Cloudflare), log parsing, grep, sed, awk. Tanpa paham regex secara fundamental, lo cuma copy-paste rule tanpa ngerti kenapa rule itu work — atau lebih parah, kenapa rule itu gak detect attack yang seharusnya. Mencakup engine types (PCRE, RE2, Rust regex), quantifiers, groups & backreferences, lookahead/lookbehind, atomic groups & possessive quantifiers, backtracking & catastrophic backtracking (ReDoS), regex optimization, dan praktik konkret untuk detection engineering.

> [!info] Posisi di Vault
> Nota ini adalah **alat** yang dipake di hampir semua catatan lain: Sigma rules di [[incident-response-framework]], [[malware-analysis-reverse-engineering-playbook]] (YARA rules), [[blueteam-detection-matrix]] (detection rules), [[cloudflare-ruleset-engine-phases]] (WAF rules), [[web-hacking-exploitation]] (bypass WAF dengan regex), [[ids-ips-waf-nsm-comparison]] (Suricata rules). Juga terhubung ke [[http-protocol-deepdive]] (request parsing) dan [[encoding-serialization-compression-deepdive]] (regex untuk encoding detection).

---

## Daftar Isi

- [[#Foundation]]
- [[#Quantifiers]]
- [[#Character Classes & Shorthands]]
- [[#Groups & Backreferences]]
- [[#Anchors & Boundaries]]
- [[#Lookahead & Lookbehind]]
- [[#Atomic Groups & Possessive Quantifiers]]
- [[#Flags]]
- [[#Engine Types]]
- [[#Catastrophic Backtracking — ReDoS]]
- [[#Regex Optimization]]
- [[#Regex untuk Detection Engineering]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa Itu Regex?

Regular Expression (regex) adalah pola yang mendeskripsikan sekumpulan string. Bukan bahasa pemrograman — tapi **notation** untuk pattern matching.

```
Pola:    ^[A-Z]{3}-\d{4}$
Cocok:   ABC-1234
         XYZ-9876
Tidak:   abc-1234  (lowercase)
         ABC-12345 (5 digit)
         ABC1234   (tanpa -)
```

### Komponen Dasar

| Komponen            | Contoh     | Maksud                                           |
| ------------------- | ---------- | ------------------------------------------------ |
| **Literal**         | `hello`    | Cocok exact string "hello"                       |
| **Dot**             | `h.llo`    | Satu karakter apapun (`hallo`, `hxllo`, `h5llo`) |
| **Character class** | `[aeiou]`  | Satu karakter vokal                              |
| **Negated class**   | `[^aeiou]` | Satu karakter BUKAN vokal                        |
| **Quantifier**      | `\d{3}`    | Tepat 3 digit                                    |
| **Alternation**     | `cat\|dog` | "cat" ATAU "dog"                                 |
| **Group**           | `(ab)+`    | "ab" satu atau lebih (`ab`, `abab`, `ababab`)    |
| **Anchor**          | `^start`   | "start" di AWAL string                           |
| **Shorthand**       | `\w+`      | Satu atau lebih word character                   |

---

## Quantifiers

### Greedy, Lazy, Possessive

```python
String: "<div>hello</div><span>world</span>"

Pola: <.+>      # Greedy — cocok sepanjang mungkin
Match: <div>hello</div><span>world</span>  # (entire string!)

Pola: <.+?>     # Lazy — cocok sependek mungkin
Match: <div>   # (cuma tag pertama)

Pola: <[^>]+>   # Praktis — "everything except >"
Match: <div>, </div>, <span>, </span>  # (4 matches!)
```

| Quantifier | Greedy  | Lazy     | Possessive | Maksud       |
| ---------- | ------- | -------- | ---------- | ------------ |
| `*`        | `*`     | `*?`     | `*+`       | 0 atau lebih |
| `+`        | `+`     | `+?`     | `++`       | 1 atau lebih |
| `?`        | `?`     | `??`     | `?+`       | 0 atau 1     |
| `{n}`      | `{n}`   | `{n}?`   | `{n}+`     | Tepat n      |
| `{n,}`     | `{n,}`  | `{n,}?`  | `{n,}+`    | Minimal n    |
| `{n,m}`    | `{n,m}` | `{n,m}?` | `{n,m}+`   | n sampai m   |

**Greedy (default):** Engine coba match sebanyak mungkin, lalu backtrack kalo gagal. **Lazy:** Engine coba match sesedikit mungkin, lalu expand kalo gagal. **Possessive:** Sama kayak greedy tapi **gak backtrack** — kalo gagal, langsung fail (cegah catastrophic backtracking).

---

## Character Classes & Shorthands

### Custom Classes

```regex
[abc]       # Satu karakter: a, b, atau c
[a-z]       # Satu lowercase letter
[0-9]       # Satu digit
[a-zA-Z0-9]  # Satu alphanumeric
[^0-9]      # BUKAN digit

# Special chars inside class — escaped or placed right
[\^a-b]     # ^ di awal = literal, bukan negasi
[a-b\-c]    # - di akhir atau escaped = literal dash
[\]]        # ] harus di-escape
```

### Shorthand Classes

| Shorthand | Setara Dengan    | Cocok                                      |
| --------- | ---------------- | ------------------------------------------ |
| `\d`      | `[0-9]`          | Digit                                      |
| `\w`      | `[a-zA-Z0-9_]`   | Word character (letter, digit, underscore) |
| `\s`      | `[ \t\n\r\f\v]`  | Whitespace                                 |
| `\D`      | `[^0-9]`         | Bukan digit                                |
| `\W`      | `[^a-zA-Z0-9_]`  | Bukan word character                       |
| `\S`      | `[^ \t\n\r\f\v]` | Bukan whitespace                           |

> [!warning] `\w` ≠ only letters
> Di banyak engine (PHP, Java, .NET, Python), `\w` juga cocok Unicode letters — bukan cuma ASCII. Kalo mau ASCII-only, pake `[a-zA-Z0-9_]`.

---

## Groups & Backreferences

### Capturing Groups

```regex
(\d{3})-(\d{4})     # Dua group: $1 = 3 digit, $2 = 4 digit
(\w+)@(\w+\.\w+)    # Email: $1 = name, $2 = domain
```

**Referencing:**

| Engine                | Syntax  | Contoh                             |
| --------------------- | ------- | ---------------------------------- |
| **Dalam pola**        | `\1`    | `(a)b\1` → match "aba"             |
| **Dalam replacement** | `$1`    | `sed 's/(foo)/$1bar/'`             |
| **Python**            | `\g<1>` | `re.sub(r'(foo)', r'\g<1>bar', s)` |
| **JavaScript**        | `$1`    | `"foo".replace(/(f)/, "$1oo")`     |

**Backreference example:** Deteksi kata berulang:

```regex
\b(\w+)\s+\1\b    # Cocok: "hello hello", "test test"
```

### Non-Capturing Groups

```regex
(?:pattern)   # Group TAPI gak disimpan di memory
# Cocok buat alternation tanpa overhead capturing:
(?:foo|bar) v baz   # foo v baz ATAU bar v baz
# Vs: (foo|bar) v baz — sama, tapi foo/bar gak di-capture
```

### Named Groups

```regex
(?P<name>\d+)     # Python
(?<name>\d+)      # PCRE, .NET, PHP, Java 7+
(?'name'\d+)      # .NET alternatif

# Referencing:
\k<name>          # Dalam pola (PCRE)
(?P=name)         # Dalam pola (Python)
$+{name}          # Dalam replacement (.NET)
```

---

## Anchors & Boundaries

| Anchor | Cocok di                                    | Contoh                                       |
| ------ | ------------------------------------------- | -------------------------------------------- |
| `^`    | Awal string (atau awal baris dengan flag m) | `^Hello` — string dimulai "Hello"            |
| `$`    | Akhir string (atau akhir baris)             | `world$` — string diakhiri "world"           |
| `\b`   | Boundary word/non-word                      | `\bword\b` — "word" utuh, bukan "password"   |
| `\B`   | BUKAN word boundary                         | `\Bword` — "word" di tengah kata: "password" |
| `\A`   | Awal string (IGNORE multiline flag)         | `\AHello`                                    |
| `\Z`   | Akhir string (atau newline di akhir)        | `world\Z`                                    |
| `\z`   | Akhir string (BENAR-BENAR akhir)            | `world\z`                                    |

---

## Lookahead & Lookbehind

Lookaround adalah **zero-width assertion** — cocok posisi, bukan karakter.

| Type                    | Syntax     | Contoh       | Maksud                                     |
| ----------------------- | ---------- | ------------ | ------------------------------------------ |
| **Positive lookahead**  | `(?=...)`  | `\d(?=px)`   | Digit yang diikuti "px": `5px` → match `5` |
| **Negative lookahead**  | `(?!...)`  | `\d(?!px)`   | Digit yang TIDAK diikuti "px"              |
| **Positive lookbehind** | `(?<=...)` | `(?<=\$)\d+` | Angka setelah `$`: `$100` → match `100`    |
| **Negative lookbehind** | `(?<!...)` | `(?<!\$)\d+` | Angka yang TIDAK didahului `$`             |

### Contoh Praktis

```regex
# Password validation (8+ chars, at least 1 uppercase, 1 digit, 1 special)
^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$

# Positive lookahead: q tapi bukan qu
q(?!u)            # Cocok "q" di "Iraq" tapi bukan di "quick"

# Negative lookbehind: "foo" tapi gak didahului "bar"
(?<!bar)foo       # Cocok "foo" di "foo" dan "Xfoo" tapi bukan di "barfoo"

# Extract value dari JSON key (lookbehind + lookahead)
(?<="password":\s*")[^"]+
# Cocok: "password": "hunter2" → match "hunter2"
```

**Keterbatasan:** Lookbehind di sebagian engine (JavaScript, Python `re`) harus **fixed-length** — `(?<=\d{3})` boleh, `(?<=\d+)` gak boleh. PCRE, Python `regex` library, .NET support variable-length lookbehind.

---

## Atomic Groups & Possessive Quantifiers

### Atomic Group

```regex
(?>pattern)
```

Atomic group: kalo pattern di dalamnya cocok, engine **gak akan backtrack** ke dalam group ini. Berguna untuk (1) optimasi performa, (2) cegah backtracking yang gak perlu, (3) cegah catastrophic backtracking.

**Contoh:**

```regex
String: "aaaaa"
Pola 1: (a+|b)  → Match "aaaaa" (greedy, lalu coba b — gagal, lalu backtrack a→aaaa, dll)
Pola 2: (?>a+|b) → Match "aaaaa" (gaco aaaaa, coba b — gagal — LANGSUNG fail tanpa backtrack)
```

Tanpa atomic: backtracking mencoba `aaaaa`, `aaaa`, `aaa`, `aa`, `a` — 5 langkah. Dengan atomic: langsung `aaaaa` — 1 langkah.

### Possessive Quantifier

Sama dengan atomic group — quantifier yang gak backtrack:

```regex
.*+       # Sama kayak (?>.*)
\w++
\d{3,5}+
```

**Kapan pake:** Ketika lo tahu bahwa setelah quantifier, pola yang cocok gak akan berubah dengan backtracking. Contoh: `\d++[a-z]` — kalo digit udah cocok, backtracking digit gak akan bikin `[a-z]` cocok.

---

## Flags

| Flag                 | Python | PCRE | JavaScript | Fungsi                                            |
| -------------------- | ------ | ---- | ---------- | ------------------------------------------------- |
| **Case insensitive** | `re.I` | `i`  | `i`        | `[a-z]` cocok uppercase juga                      |
| **Multiline**        | `re.M` | `m`  | `m`        | `^` dan `$` cocok per baris, bukan seluruh string |
| **Dotall**           | `re.S` | `s`  | `s`        | `.` cocok newline (`\n`) juga                     |
| **Unicode**          | `re.U` | `u`  | `u`        | `\w`, `\d` dll treat string sebagai Unicode       |
| **Verbose**          | `re.X` | `x`  | `x`        | Allow whitespace + comments dalam pola            |
| **ASCII**            | `re.A` | —    | —          | Force `\w`, `\d`, `\s` ke ASCII-only              |

### Contoh Verbose Mode

```python
import re
pattern = re.compile(r"""
    ^                 # Start of string
    (?=.*[A-Z])       # At least one uppercase
    (?=.*[a-z])       # At least one lowercase
    (?=.*\d)          # At least one digit
    .{8,}             # At least 8 characters
    $                 # End of string
""", re.VERBOSE)
```

---

## Engine Types

### DFA vs NFA

| Engine                                   | Cara Kerja                               | Kecepatan                                  | Fitur                                                    | Contoh                                         |
| ---------------------------------------- | ---------------------------------------- | ------------------------------------------ | -------------------------------------------------------- | ---------------------------------------------- |
| **DFA** (Deterministic Finite Automaton) | Linear — setiap karakter diproses sekali | 🟢 Sangat cepat, O(n)                      | ❌ No backreferences, no lookaround, no capturing groups | `awk`, `grep` (default), `lex`                 |
| **Traditional NFA**                      | Backtracking — coba semua kemungkinan    | 🟡 Bisa lambat (exponential di worst case) | ✅ Full fitur: groups, backref, lookaround               | PCRE, Python `re`, JavaScript, Java, .NET, PHP |
| **POSIX NFA**                            | Backtracking — cari longest match        | 🔴 Paling lambat                           | 🟡 Groups, no backref                                    | POSIX `regex.h`, beberapa implementasi `sed`   |
| **RE2** (Hybrid)                         | Automata-based + limited backtracking    | 🟢 O(n) guaranteed — gak ada ReDoS         | 🟡 No backreferences, no lookaround (some)               | Go `regexp`, Rust `regex`, RE2 library         |

### Kapan Pilih Engine

| Kebutuhan                                              | Engine yang Cocok                                    |
| ------------------------------------------------------ | ---------------------------------------------------- |
| **Log parsing** (jutaan baris, pola sederhana)         | RE2, DFA — performa stabil                           |
| **User input validation** (potensi ReDoS)              | RE2 — gak bisa catastrophic backtracking             |
| **Detection rules** (butuh backreferences, lookaround) | PCRE — fitur lengkap                                 |
| **YARA rules**                                         | YARA pake PCRE-compatible engine                     |
| **Suricata rules**                                     | PCRE (fitur lengkap) — tapi hati-hati ReDoS          |
| **Sigma rules**                                        | Format agnostik — bisa di-export ke berbagai backend |

---

## Catastrophic Backtracking — ReDoS

### Penyebab

Terjadi ketika regex punya **nested quantifiers** dengan overlapping matches — engine backtrack eksponensial.

**Pola klasik:**

```regex
^(a+)+$      # Nested quantifiers — a+ di dalam ( )+
^(\d+)*$     # Digit di dalam group dengan *
(a|aa)+      # Alternation dengan overlap
(a*)*b       # Star di dalam star
```

**Eksponensial:**

```
String: "aaaaaaaaaaaaaaaaaaaaaa" (22 a's)
Pola: ^(a+)+$

Step ketika string TIDAK cocok (misal ada trailing "x"):
1. (a+) coba 22 a's → ( )+ coba 1× → gagal di x
2. Backtrack: (a+) → 21 a's → ( )+ → 2× → (a+) → 1 a → 2× → gagal
3. Backtrack: (a+) → 21 a's → ( )+ → 1× → gagal
4. Backtrack: (a+) → 20 a's → ( )+ → 3× → (a+) → 1 a → 1× → ...
... exponensial!
```

Hasil: 22 karakter → ~2^22 = 4 juta langkah → **ReDoS** (Regex Denial of Service).

### Contoh Real-World

| CVE                     | Pola                                  | Dampak                            |
| ----------------------- | ------------------------------------- | --------------------------------- |
| CVE-2021-39227          | `(\w+[,.])+` di OWASP ESAPI validator | Stack overflow → DoS              |
| Cloudflare ReDoS (2019) | `.*.*=.*` di Cloudflare WAF rule      | CPU 100% → global outage 27 menit |
| Node.js `slug` (2022)   | `([a-zA-Z0-9-]+)+`                    | ReDoS via crafted input           |

### Mitigasi

```python
# 1. Gunakan atomic group
^(?>a+)+$       # Atomic — gak backtrack, langsung fail

# 2. Gunakan possessive quantifier
^a++$           # Possessive — sama

# 3. Hindari nested quantifiers
# ❌ (a+)+       → nested
# ✅ aa*         → tanpa nested, sama aja

# 4. Gunakan boundary / anchor
# ❌ (\d+)*      → berbahaya
# ✅ \d+         → anchor atau boundary lebih jelas

# 5. Gunakan RE2 kalo gak butuh backreference
# Go, Rust, re2 library — O(n) guaranteed

# 6. Timeout di semua regex execution
import re
# Python: re.compile(pattern) — no timeout built-in → butuh signal
# Gunakan library regex dengan timeout: pip install regex
# regex.Regex(pattern, timeout=0.5)

# Di Suricata: pcre_match_limit dan pcre_match_limit_recursion
# Di Cloudflare WAF: OWASP CRS dengan batas backreference
```

### ReDoS Detection

```bash
# Test pola dengan input bertambah
regex_test() {
    local pattern="$1"
    for i in 10 15 20 25; do
        local input=$(python3 -c "print('a' * $i + 'x')")
        echo -n "Length $i: "
        time (echo "$input" | grep -P "$pattern" 2>/dev/null) 2>&1 | grep real
    done
}
regex_test '(a+)+$'
```

---

## Regex Optimization

### Slow vs Fast

```python
# ❌ Slow
r"<.*>"                # Greedy → backtrack sepanjang string
r"(\d+|\w+)+"          # Nested alternation + quantifier

# ✅ Fast
r"<[^>]*>"             # Specific character class — no backtrack
r"\w+"                 # Single quantifier — gak nested
```

### Prinsip Optimasi

1. **Specific over generic:** `[a-z]` lebih cepat dari `\w` (karena `\w` = `[a-zA-Z0-9_]` + Unicode)
2. **Anchor early:** `^...` — kalau gagal di awal, gak perlu scan seluruh string
3. **Unroll loops:** `(a|b|c)+` → `[abc]+` (character class faster than alternation)
4. **Avoid backtracing:** pake atomic group `(?>...)` atau possessive `++`
5. **Failure fast:** `^(?!.*evil)` — cegah moreksekusi dengan negative lookahead di awal
6. **Use specific quantifiers:** `{3}` instead of `+` kalo tahu ukuran pasti

### Benchmark Comparison

```python
import time, re

data = "a" * 100000 + "b"

# Slow regex
start = time.time()
re.match(r"(a+)+b", data)
print(f"Slow: {time.time() - start:.2f}s")  # ~5-10s — catastrophic backtracking

# Fast regex
start = time.time()
re.match(r"a++b", data)
print(f"Fast: {time.time() - start:.4f}s")  # ~0.0001s — no backtrack
```

---

## Regex untuk Detection Engineering

### Sigma Rules

```yaml
# Sigma rule — PowerShell download cradle
detection:
  selection:
    ScriptBlockText|contains:
      - "System.Net.WebClient"
      - "Invoke-WebRequest"
  condition: selection
# Di-export ke Elasticsearch:
# event.code: "4104" AND winlog.event_data.ScriptBlockText: (*System.Net.WebClient* OR *Invoke-WebRequest*)
# Atau ke Splux:
# index=windows source="WinEventLog:Microsoft-Windows-PowerShell/Operational"
# ScriptBlockText=*System.Net.WebClient* OR ScriptBlockText=*Invoke-WebRequest*
```

### YARA Rules

```yara
rule APT_Malware_Domain {
    strings:
        $c2 = /https?:\/\/([a-z0-9-]+\.){2,}[a-z]{2,}\/([a-zA-Z0-9\/=]+)?(\?[a-z0-9=]+)?/
    condition:
        $c2
}
```

### Suricata Rules

```yaml
# Suricata — HTTP SQL injection detection
alert http any any -> any any (
    msg:"ET WEB_SERVER SQL Injection in URI";
    flow:to_server,established;
    content:"%27"; http_uri;           # URL-encoded single quote
    content:"OR"; http_uri; nocase;
    pcre:"/(\bSELECT\b|\bUNION\b|\bINSERT\b|\bDROP\b)/i";
    classtype:web-application-attack;
    sid:1000002;
)
```

### WAF Rules (ModSecurity)

```apache
# ModSecurity — SQL injection via regex
SecRule REQUEST_FILENAME|ARGS_NAMES|ARGS|XML:/* "@rx (?i:(?:union)\s+(?:all|select|distinct))" \
    "id:942100,phase:2,deny,status:403,msg:'SQL Injection - UNION SELECT Detected'"
```

### Practical Patterns for Security

```regex
# IP Address
\b(?:\d{1,3}\.){3}\d{1,3}\b

# Email
[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}

# URL
https?://[^\s/$.?#].[^\s]*

# File path (Windows)
[a-zA-Z]:\\(?:[^\\]+\\?)*

# Hexadecimal string (malware indicator)
\b[0-9a-fA-F]{32,}\b

# Base64 encoded string (C2 config, token)
\b[A-Za-z0-9+/]{40,}={0,2}\b

# DGA domain (DGA-generated)
\b[a-z]{8,20}\.(com|net|tk|cf|ga|ml)\b

# JWT Token
eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*
```

---

## Koneksi ke Vault

- [[incident-response-framework]] — Sigma rules untuk detection engineering
- [[malware-analysis-reverse-engineering-playbook]] — YARA rules untuk malware detection
- [[blueteam-detection-matrix]] — detection rules berbasis event log + regex
- [[web-hacking-exploitation]] — encoding bypass WAF dengan regex manipulation
- [[ids-ips-waf-nsm-comparison]] — Suricata rules dengan PCRE
- [[cloudflare-ruleset-engine-phases]] — WAF rules dengan regex
- [[http-protocol-deepdive]] — regex untuk request parsing
- [[encoding-serialization-compression-deepdive]] — regex untuk encoding detection

---

## References

1. Friedl, Jeffrey. _Mastering Regular Expressions, 3rd Ed._ O'Reilly, 2006. — **Buku wajib** untuk regex.
2. Regular-Expressions.info. _Regex Tutorial_. https://www.regular-expressions.info/
3. PCRE. _PCRE Documentation_. https://www.pcre.org/original/doc/html/
4. RE2. _RE2 Syntax_. https://github.com/google/re2/wiki/Syntax
5. OWASP. _Regular Expression Denial of Service (ReDoS)_. https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS
6. Cloudflare. _How Cloudflare mitigates ReDoS_. https://blog.cloudflare.com/details-of-the-cloudflare-outage-on-july-2-2019/
7. SIGMA. _Sigma Rule Specification_. https://github.com/SigmaHQ/sigma-specification
8. YARA. _YARA Documentation_. https://yara.readthedocs.io/en/stable/
9. Suricata. _Suricata Rule Syntax_. https://suricata.readthedocs.io/en/latest/rules/intro.html
10. ModSecurity. _ModSecurity Reference Manual_. https://github.com/SpiderLabs/ModSecurity/wiki
11. Python. _re module documentation_. https://docs.python.org/3/library/re.html
12. MDN. _JavaScript RegExp_. https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
13. Rust. _regex crate_. https://docs.rs/regex/latest/regex/
14. Go. _regexp package_. https://pkg.go.dev/regexp
15. Regex101. _Online Regex Tester_. https://regex101.com/
16. Debuggex. _Visual Regex Debugger_. https://www.debuggex.com/

> [!tip] Bottom Line
> Regex adalah **senjata paling tajam dan paling berbahaya** di toolbox security engineer. Satu regex yang benar bisa mendeteksi attack dalam mikrodetik; satu regex yang salah bisa menghabiskan CPU 100% (ReDoS) dan membawa down seluruh sistem. Buat security engineer: (1) **Paham engine** — PCRE untuk rule yang butuh backreference, RE2 untuk log parsing performa tinggi. (2) **Hindari nested quantifiers** — `(a+)+` adalah pola klasik ReDoS. Pake atomic group `(?>...)` atau possessive `++` untuk cegah backtracking gak perlu. (3) **Test dengan input batas** — regex yang OK buat 10 karakter bisa mati di 100 karakter. (4) **Sigma rules** adalah format universal detection — tulis sekali, deploy ke SIEM mana aja. (5) **YARA rules** untuk malware — tapi pastikan rule gak terlalu generic (false positive) atau terlalu spesifik (mudah di-evade). Investasi belajar regex adalah investasi yang membayar setiap hari — karena hampir SEMUA yang lo lakukan sebagai security engineer melibatkan pattern matching.
