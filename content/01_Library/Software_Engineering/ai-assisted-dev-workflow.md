---
title: 'AI-Assisted Software Engineering — Deep Dive: Spec-Driven Dev, AI Code Review,
  Agent Workflow, Toolchain Comparison'
tags:
- ai
- software-engineering
- vibe-coding
- dev-workflow
- agentic-coding
created: '2026-07-18'
updated: '2026-07-18'
status: pending
cssclasses:
- wide-table
---
# 🤖 AI-Assisted Software Engineering — Deep Dive: Spec-Driven Dev, AI Code Review, Agent Workflow, Toolchain Comparison

> Panduan komprehensif workflow software engineering modern dengan AI sebagai pair programmer. Mencakup paradigm shift dari manual-write ke spec-driven development, AI code review (apa yang AI bisa vs tidak bisa deteksi), prompt patterns untuk coding (spec→code, refactor, test-first, explain), perbandingan toolchain (Claude Code, Cursor, Copilot, Aider, Continue.dev), pitfalls AI-generated code, dan workflow rekomendasi untuk solo developer dan team. Vault udah punya [[clean-code-robert-martin]], [[design-patterns-gof]], [[refactoring-martin-fowler]], [[the-pragmatic-programmer]] — semua buku klasik tentang software engineering yang tetap relevan. Catatan ini melengkapi dengan **bagaimana tools baru (AI) mengubah cara kita menerapkan prinsip-prinsip itu**.

> [!info] Posisi di Vault
> Catatan ini terkait dengan [[clean-code-robert-martin]] (prinsip desain tetap berlaku — AI harus ngikut, bukan sebaliknya), [[design-patterns-gof]] (AI generate code dengan pattern, lo review), [[refactoring-martin-fowler]] (AI refactoring toolchain — CodeQL, Semgrep, Copilot), [[the-pragmatic-programmer]] (AI adalah new stone ax — pragmatic tetap yang utama), [[architectural-flaw-detection]] (AI code review sebagai automated gate), [[agentic-ai-mcp-architecture-deepdive]] (autonomous coding agent — Claude Code, Aider), dan [[cicd-shiftleft-shiftright]] (AI code review sebagai Shift-Left security gate).

---

## Daftar Isi

- [[#Paradigma Baru — Spec-Driven Development]]
- [[#AI Code Review & Refactoring]]
- [[#Prompt Patterns untuk Coding]]
- [[#Toolchain & IDE Integration]]
- [[#Pitfalls — Kode yang Terlihat Benar Tapi Salah]]
- [[#Workflow Rekomendasi]]
- [[#Yang Tetap Sama — Prinsip yang Bertahan]]
- [[#Koneksi ke Vault]]

---

## Paradigma Baru — Spec-Driven Development

### Pergeseran Tanggung Jawab

**Dulu (Manual-Write):**
```
Developer: Requirements → Design → Write Code → Test → Debug → Deploy
                               ↓                        ↑
                          (bottleneck)             (loop mahal)
```

**Sekarang (Spec-Driven):**
```
Developer: Requirements → Spec → Review Spec → AI Implement → Review Code → Test → Deploy
                               ↓                             ↑
                    (lo tulis spec, AI tulis kode)   (lo review, bukan nulis)
```

Prinsip: Lo gak nulis kode lagi. Lo **nulis spec**, AI **nulis implementasi**, lo **review & approve**.

### Format Spec Minimal

```
## Function: validate_api_key(api_key: str) -> bool

Behavior:
- Return True kalau key valid format: "sk-" + 48 karakter alfanumerik
- Return False kalau key kosong / format salah

Edge Cases:
- Key dengan whitespace -> strip dulu?
- Case-sensitive? Ya
- Key dengan karakter Unicode? Tolak

Dependencies:
- Tidak ada (pure function). No network call, no DB access.

Performance:
- Harus selesai < 1ms untuk key 51 karakter
```

### Kenapa Spec-Driven Lebih Cepat?

| Aktivitas | Manual-Write | Spec-Driven | Efisiensi |
|-----------|-------------|-------------|-----------|
| Nulis kode baru | 30-60 menit | 2-5 menit (nulis spec) + 30 detik (AI generate) | 10-20x lebih cepat |
| Refactor | 1-3 jam | 10-15 menit (spec perubahan + AI) | 6-12x |
| Debug | 30 menit - 1 hari | 5-10 menit (deskripsi bug + spec fix) | 3-48x |
| Generate test | 15-30 menit | 2-5 menit (review hasil AI) | 3-6x |

> [!warning] Spec yang Buruk = Kode yang Buruk
> Garbage in, garbage out. Spec yang ambigu menghasilkan kode yang salah. Semakin detail spec, semakin bagus hasil AI. **Lo tetap perlu domain expertise untuk menulis spec yang benar.**

## AI Code Review & Refactoring

### Yang AI Bagus Deteksi

| Kategori | Contoh | Tools |
|----------|--------|-------|
| **Code smells** | Duplicate code, long method, magic numbers, dead code | Copilot review, CodeRabbit |
| **Security flaws** | SQL injection, XSS, hardcoded credentials, SSRF, command injection | Semgrep, CodeQL |
| **Performance issues** | N+1 query, unnecessary allocation, sync-in-async | Copilot, SonarLint |
| **Style & consistency** | Formatting, naming convention, import order | Prettier, ESLint, AI formatter |
| **API misuse** | Wrong API call, deprecated function, wrong params | Copilot inline, Cursor |

### Yang AI LEMAH Deteksi (masih perlu human)

| Kategori | Kenapa AI Gagal | Contoh |
|----------|-----------------|--------|
| **Business logic correctness** | AI tau syntax, gak tau domain rules | "Apakah perhitungan diskon ini benar sesuai kebijakan pricing?" |
| **Architectural fit** | AI gak tau system constraints jangka panjang | "Apakah dependency injection di sini akan menyulitkan testing?" |
| **Trade-off judgment** | Tidak ada konteks prioritas bisnis | "Keamanan ekstra vs user experience — mana yang dikorbankan?" |
| **Security design** | AI gak punya threat model untuk system ini | "Apakah arsitektur ini memenuhi compliance requirement?" |

> **Golden Rule:** Gunakan AI untuk **what** (apa yang salah) dan **how** (bagaimana memperbaiki). Jangan gunakan untuk **why** (kenapa keputusan diambil) — itu still human domain.

## Prompt Patterns untuk Coding

### Pattern 1: Spec → Code
```
Buat fungsi Python dengan spec berikut:
[tempel spec]
- Gunakan type hints, Google-style docstring
- Handle semua edge cases di spec
- Jangan tambah fitur di luar spec
- Kode minimal — no classes, no abstractions untuk 1 fungsi
```

### Pattern 2: Refactor with Constraints
```
Refactor kode ini dengan constraint:
- Jangan ubah public API signature — backward compatible
- Maximum 100 lines per function
- Hapus duplicate code
- Tambah logging (standard library, no external dep)
- Performance: jangan tambah O(n) baru

[tempel kode]
```

### Pattern 3: Test-First
```
Buat unit test untuk fungsi ini dengan pytest
Coverage requirements:
- Happy path (valid input)
- Edge cases: empty input, None, type mismatch, boundary values
- Error cases (expected exceptions)
- Property-based test untuk validasi format

[tempel kode + spec]
```

### Pattern 4: Explain & Improve
```
Jelaskan apa yang kode ini lakukan, baris per baris.
Terus kasi saran improvement (prioritas: performance > security > readability).
Jangan rewrite — cukup explain + suggest.

[tempel kode]
```

### Pattern 5: Debug with Hypothesis
```
Kode ini menghasilkan [error/output salah].
Hypothesis: [tebak akar masalah].
Goal: Fix bug tanpa ubah behavior lain.
Kasih 2 opsi solusi sebelum implementasi.

[kode error]
[error message]
```

## Toolchain & IDE Integration

| Tool | Mode | Bahasa | Autonomous | Kelebihan | Kekurangan |
|------|------|--------|-----------|-----------|------------|
| **Claude Code** | Terminal agent | All | ✅ Full agent | Multi-file edit, git-aware, reasoning | Kadang over-engineering, API cost |
| **Aider** | Terminal | All | ✅ Full agent | Open source, multi-model (local + cloud), map repo | CLI-only, no GUI |
| **Cursor** | IDE (VS Code fork) | All | ✅ Agent mode | Inline edit, tab completion, composer | Proprietary, lock-in |
| **Copilot** | IDE plugin | All | ❌ Chat + inline | Mature, code review built-in | Kurang bagus refactor besar |
| **Continue.dev** | IDE plugin | All | ❌ Chat + inline | Open source, local model, custom rules | Setup complex |
| **Codex CLI** | Terminal | All | ✅ Semi-agent | OpenAI, sandboxed execution | New, masih beta |
| **CodeGemini** | IDE plugin | All | ❌ Chat | Google integration, free tier | Fitur terbatas |

### Memilih Tool

```
Butuh apa?            Pilih
──────────────        ─────
Auto coding task      Claude Code / Aider / Cursor Agent
Code review           Copilot Review / CodeRabbit
Inline completion     Cursor Tab / Copilot
Local model only      Continue.dev + Ollama
Open source + control Aider + Continue.dev
Multi-file refactor   Claude Code / Cursor Composer
```

## Pitfalls — Kode yang Terlihat Benar Tapi Salah

### 1. Halusinasi Dependency
```python
# ❌ AI kadang pake library yang gak exist
from super_fast_library import process_data  # ImportError!

# ✅ Selalu test-run setelah AI generate. Minta AI: "Gunakan stdlib first"
```

### 2. Security Blindspot
```python
# ❌ AI generate kode tanpa sanitasi
exec(user_input)  # RCE — attacker inject perintah OS

# ✅ Explicit constraint: "Jangan eval/exec input user. Gunakan whitelist validation."
```

### 3. Over-Engineering
```python
# ❌ AI suka bikin abstraksi gak perlu
class AbstractSortingStrategyFactory:
    def create_strategy(self, type): ...
# Padahal cuma perlu: sorted(data)

# ✅ Spec: "Kode minimal — no classes, no factory, no inheritance untuk use case ini"
```

### 4. Context Amnesia
AI lupa constraint di awal setelah beberapa round. Solusi:
- Simpan spec di file terpisah (`spec.md`), re-attach tiap prompt
- Gunakan git commit checkpoint — rollback kalau AI ngaco
- Satu prompt = satu intent (jangan multitask)

### 5. Hallucinated Security
```python
# ❌ AI generate "security" yang salah
hashlib.md5(password.encode()).hexdigest()  # MD5 untuk password!
# AI tau "hash", tapi gak tau hashing algorithm yang tepat untuk password

# ✅ Explicit: "Gunakan bcrypt atau Argon2 untuk password storage"
```

## Workflow Rekomendasi

### Solo Developer (1 orang)
```
1. Tulis spec di .md (5-10 menit)
2. Generate implementasi (30 detik - 2 menit)
3. Test verify (5 menit)
4. AI code review — fokus logic & edge case (5 menit)
5. Commit
```
Total: ~20 menit untuk fitur yang dulu butuh 1 jam.

### Security-First Workflow (production)
```
1. Threat model → spec → AI generate kode
2. SAST scan (Semgrep/CodeQL) — automated gate
3. AI code review — fokus logic & edge case
4. Human review — fokus arsitektur & trade-off
5. Integration test
6. Deploy dengan canary (10% traffic)
```

### Code Review Checklist untuk AI-Generated Code
- [ ] Apakah spec terpenuhi? (tidak kurang, tidak lebih)
- [ ] Apakah ada hallucinated dependency?
- [ ] Apakah ada security issue? (injection, XSS, hardcoded secret)
- [ ] Apakah ada magic number / hardcoded value?
- [ ] Apakah error handling proper? (try/except range, not bare except)
- [ ] Apakah ada race condition? (shared state, timing)
- [ ] Apakah performance acceptable? (O(n), N+1 query)
- [ ] Apakah type hints sesuai dengan spec?

## Yang Tetap Sama — Prinsip yang Bertahan

| Prinsip | Kenapa Masih Relevan | Adaptasi AI |
|---------|---------------------|-------------|
| **DRY** (Don't Repeat Yourself) | AI bisa generate duplicate code — lo yang review | Minta AI: "Hapus duplicate, extract ke fungsi bersama" |
| **KISS** (Keep It Simple) | AI suka over-engineer — lo yang simplify | Spec: "Minimal implementation, no patterns" |
| **YAGNI** (You Ain't Gonna Need It) | AI suka add feature yang gak diminta | Spec: "Fitur ini ONLY, jangan tambah prep untuk future" |
| **Single Responsibility** | AI campur logika dalam 1 fungsi | Spec: "Satu fungsi = satu tanggung jawab" |
| **Separation of Concerns** | AI campur business logic + IO | Spec: "Domain logic pure function, IO di layer terpisah" |
| **Testing** | AI generate test yang lemah | Spec test coverage: happy, edge, error, property-based |

---

## Koneksi ke Vault

- [[clean-code-robert-martin]] — Prinsip clean code tetap berlaku — AI harus ngikut, bukan sebaliknya
- [[design-patterns-gof]] — AI bantu implementasi pattern lebih cepat — lo review trade-off
- [[refactoring-martin-fowler]] — AI refactoring toolchain (CodeQL, Semgrep, Copilot review)
- [[the-pragmatic-programmer]] — AI = new stone ax. Pragmatic = pilih tool yang tepat
- [[architectural-flaw-detection]] — Automated anti-pattern detection di CI/CD
- [[agentic-ai-mcp-architecture-deepdive]] — Autonomous coding agent architecture (Claude Code, Aider)
- [[cicd-shiftleft-shiftright]] — AI code review sebagai Shift-Left security gate
- [[test-time-compute-system2]] — AI reasoning patterns untuk debugging & code analysis