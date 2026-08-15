---
title: Django Security
tags: [security, web, django, python]
aliases: [django-security]
---
# Django Security

Django menyediakan banyak fitur keamanan default (auto-escape template, CSRF protection, password hashing, clickjacking protection) — tapi bukan jaminan aman; developer wajib memahami dan mengisi celah yang framework tidak otomatis tangani.

## Bawaan Amannya Django (Built-in Security)

- **Template auto-escape** — `{{ var }}` di-escape; perlu `|safe` atau `mark_safe` untuk HTML mentah (berbahaya).
- **CSRF protection** — `{% csrf_token %}`; middleware CSRF aktif default.
- **XSS protection** — selain template escape, header `X-XSS-Protection` (legacy) + CSP.
- **SQL injection** — ORM memakai parameterized query; hindari `raw()`, `.extra()`, string interpolation SQL.
- **Clickjacking** — `X-Frame-Options: SAMEORIGIN` default (middleware).
- **HSTS** — `SECURE_HSTS_SECONDS` (aktifkan).
- **Password hashing** — PBKDF2 default (tuning iterations); argon2 opsional.
- **Secure cookies** — `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE` (wajib di HTTPS).
- **`django-admin`** — jangan expose ke internet.

## Checklist Konfigurasi Produksi (settings.py)

```python
# Wajib di produksi
DEBUG = False
ALLOWED_HOSTS = ['*']  # GANTI: daftar host spesifik!
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
X_FRAME_OPTIONS = 'DENY'  # default SAMEORIGIN

# Rate limiting & body size (nanti di proxy juga)
# File upload
FILE_UPLOAD_MAX_MEMORY_SIZE
DATA_UPLOAD_MAX_MEMORY_SIZE

# Use Argon2
PASSWORD_HASHERS = ['django.contrib.auth.hashers.Argon2PasswordHasher', ...]
```

## Kerentanan Umum & Mitigasi

### 1. SQL Injection via raw/ORM misuse
```python
# RENTAN
qs = MyModel.objects.raw("SELECT * FROM t WHERE name = '" + name + "'")
# AMAN
qs = MyModel.objects.filter(name=name)
```
- Jangan `.extra()` dengan interpolasi; `RawSQL()` dengan caution; gunakan `Q` objects.

### 2. XSS via `|safe`, `mark_safe`, `format_html` tanpa sanitasi
```python
# RENTAN
return mark_safe('<div>' + user_input + '</div>')
# AMAN (auto-escape)
return render(request, 'tpl.html', {'data': user_input})
# jika perlu HTML: proses dengan sanitizer (bleach/defusedxml)
```
- Template: jangan `|safe` pada user input.
- `format_html` otomatis-escape argumen — pakai ini bukan string concat.

### 3. CSRF pada custom endpoint
- Non-`@csrf_exempt`; jika API: gunakan token (DRF renderer), CORS policy ketat.
- CSRF_TRUSTED_ORIGINS hanya domain yang benar (jangan wildcard).

### 4. Mass Assignment (ModelForm/Serializer)
- Gunakan `fields = [...]` eksplisit (jangan `__all__` untuk model dengan field sensitive: `is_admin`, `role`, `balance`).
- DRF: `read_only_fields`, `extra_kwargs = {'role': {'required': False, 'read_only': True}}`.

### 5. Open Redirect
- Validasi `next`/`redirect` parameter: hanya allow path relatif/same-origin (pakai `url_has_allowed_host_and_scheme`).

### 6. File Upload
- Validate extension + content (bukan cuma nama); anti-virus scan; simpan di luar webroot (media served by proxy/nginx).
- `FileExtensionValidator` + content sniffing; path traversal check via `os.path.basename` + secure filename.

### 7. Deserialization / Pickle
- Jangan unpickle data user; cache store tidak dipercaya user (Redis dengan auth).

### 8. Admin Panel
- Wajib MFA, IP allowlist, custom AdminSite, `admin.site.enable_nav_sidebar` dll; jangan `/admin` di internet — atau proteksi ekstra.

## Dependencies & Supply Chain

- `pip` lockfile (pip-tools/uv), scan: `pip-audit` di CI.
- Update Django regularly (security releases bulanan).
- Cek CVEs package: pip-audit, OSV-Scanner.
- Jangan install paket dari sumber tidak tepercaya.

## Logging & Monitoring

- Sentry untuk error (redact sensitive fields: ignore password, token).
- Access log (Nginx) + application log (structured JSON).
- Django admin log (`LogEntry`) untuk audit.
- Rate limiting API (django-ratelimit) / nginx limit_req.
- Fail2ban / WAF untuk brute force login.

## Red Team Angle

Dari sudut penyerang:
1. Check `DEBUG=True` di production (info leak, expose settings, stack trace) — bisa via error page.
2. `ALLOWED_HOSTS` loose — Host header injection → password reset poisoning, cache poisoning.
3. Brute force `admin` login (MFA absent) — rate limit di cek.
4. Mass assignment di serializer — tambah `is_admin=1` di parameter.
5. Django versions lama — known CVE (lihat Django security releases).
6. Template injection di error (Jika custom renderer memakai user data).
7. Static/media path traversal misconfig.

## Checklist Audit

- [ ] DEBUG=False; ALLOWED_HOSTS spesifik.
- [ ] HTTPS penuh + HSTS preload.
- [ ] Cookies Secure + HttpOnly (session).
- [ ] Tidak ada `mark_safe`/`|safe` tanpa sanitasi.
- [ ] ORM dipakai; tidak ada raw SQL dengan interpolasi.
- [ ] Serializer field whitelist (bukan `__all__`).
- [ ] Admin: MFA + IP restriction.
- [ ] Dependency clean (pip-audit).
- [ ] File upload divalidasi.
- [ ] Error tidak bocorkan internals.

## Referensi

- Django Security Documentation (docs.djangoproject.com/en/stable/topics/security/)
- OWASP Cheat Sheet — Django
- Checksecure Django deployment checklist



## Celah Khas di Django Lama (Known CVEs)

- **CVE-2021-45115/CVE-2021-45116** — DoS di `django.utils.html` (email header injection)? — sebenarnya: CVE-2021-45115 = DoS via `AdminURLFieldWidget`; CVE-2021-45116 = DoS via `Truncator`. Keduanya di versi < 4.0. Update rutin = solusi.
- **CVE-2022-36359** — CSRF bypass pada Digest authentication (django.contrib.auth.middleware) — versi < 4.0.8/3.2.15.
- **CVE-2023-24580** — DoS via multipart form (MIME parsing) — versi < 4.1.9/3.2.18.
- **CVE-2024-27351** — ReDoS pada `Truncator.words()` dan `django.utils.text.Truncator` — versi < 5.0.3/4.2.10.

Pelajaran: subscribe Django security releases (mailing list), upgrade minor segera, jangan menunda 3-4 bulan — banyak CVE fixable dengan patch kecil.

## Deployment Checklist Tambahan

- Gunicorn/uWSGI: worker = 2*CPU+1, timeout sesuai; di belakang proxy (lihat [[wiod-reverse-proxy-deepdive]]).
- Static/media via proxy/CDN — jangan dari Django (perf + keamanan).
- `SECURE_PROXY_SSL_HEADER` di-set hanya jika proxy benar-benar mengaturnya (jangan sembarang — bisa bypass).
- Session engine: database/redis (bukan file default di shared fs); redis dengan auth + TLS.
- Backup DB terenkripsi + restore test (lihat [[defense-in-depth-strategy]]).

---

  audited
---