---
title: '🔗 Claude Code Plugin Marketplace — Distribusi Modular Skill untuk Coding Agent:
  dari Ad-hoc ke Structured Distribution'
tags:
- claude-code
- plugin-marketplace
- skill-distribution
- coding-agent
- thoughtworks-radar-vol-34
- library
aliases:
- skill-marketplace-pattern
- agent-plugin-distribution
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
---

# 🔗 Claude Code Plugin Marketplace — Distribusi Modular Skill untuk Coding Agent

**Dari Ad-hoc ke Structured Distribution: Discovery, Trust, dan Versioning untuk Agent Skills**

> Domain / Tags: `claude-code` `plugin-marketplace` `skill-distribution` `coding-agent` · Status: growing

## Daftar Isi

1. [[#1. Problem / Overview]]
2. [[#2. Core Idea / Arsitektur]]
3. [[#3. Implementation]]
4. [[#4. Comparison / Tradeoff]]
5. [[#5. Deployment / Monitoring]]
6. [[#Referensi]]

---

## 1. Problem / Overview

**Pain-nya ad-hoc skill distribution:**

Sebelum plugin marketplace muncul, berbagi skill coding agent berarti:

- Komunitas Slack/Discord saling paste `SKILL.md` content → drift, tak versioning
- Repo GitHub individu → discovery jelek, user harus grep across many repos
- Fork-and-copy ke project → update manual tiap kali skill author memperbaiki bug
- Tidak ada trust boundary → plugin dari stranger bisa inject instructions adversarial

ThoughtWorks Radar Vol.34 (April 2026) memasukkan **blip #72 Claude Code plugin marketplace** di ring **Trial** — menandakan pola udah ada tapi belum mature di seluruh industry. Quote:

> *"Previously, sharing custom commands, specialized knowledge, or workflow instructions for coding agents required ad-hoc copy-paste. The Claude Code plugin marketplace provides a structured way to package and distribute these capabilities."*

**Marketplace sebagai registry** menyelesaikan:

- **Discovery**: author publish sekali, consumer discover via namespace + tag searching
- **Versioning**: semver → consumer bisa pin major version, untu menerima minor updates
- **Trust**: maintainer adsosiasi ke akun → reputational skin-in-the-game; signature verification optional
- **Dependency resolution**: plugin bisa depend on plugin → resolution graph resolver
- **Kill-switch**: provider bisa blacklist plugin yang discover malicious

Cross-link ke fondasi: [[agentic-ai-mcp-architecture-deepdive]] for MCP sebagai roti mechanism; [[agent-skills-feedback-sensors-deepdive]] for skill sebagai unit atomik; [[prompt-engineering-patterns]] for skill content composition.

---

## 2. Core Idea / Arsitektur

```
┌────────────────────────┐
│   Skill Author         │
│   - write SKILL.md     │
│   - write linked files │
│   - test harness       │
└──────────┬─────────────┘
           │
           │ publish
           │ (manifest, tag, version)
           ▼
┌────────────────────────┐
│   Marketplace          │
│   - registry           │
│   - search index       │
│   - download CDN       │
│   - maintainer table   │
│   - verify receipts    │
└──────────┬─────────────┘
           │
           │ discover
           │ (filter by tag, description match)
           ▼
┌────────────────────────┐
│   Consumer (Agent)    │
│   - skill_router match │
│   - load SKILL.md     │
│   - load referenced   │
│     files on-demand   │
└──────────┬─────────────┘
           │
           │ trigger conditions match user prompt
           ▼
┌────────────────────────┐
│   Agent Action        │
│   - read instructions │
│   - execute numbered  │
│     steps             │
│   - verify pitfalls  │
└────────────────────────┘
```

**Beberapa marketplace variants in the wild:**

- **Claude Code Plugin Marketplace** (Anthropic official)
- **Superpowers catalog** (ThoughtWorks Radar blip #115 Assess) — lebih fokus ke production engineering skill
- **GitHub Spec-Kit marketplace** (Radar blip #112 Assess) — spec-driven development contexts
- **OpenSpec registry** (Radar blip #88 Assess) — open-source spec showcase
- **Hermes skills directory** (`~/.hermes/skills/`) — local-first, no central registry yet

Key perbedaan implementasi:

| Variant | Namespace model | Distribution channel | Trust model | Resolution |
|---------|-----------------|---------------------|-------------|----------|
| Claude Code plugin marketplace | Per maintainer (e.g. `@author/plugin-name`) | Anthropic-hosted CDN + signature | Reputational + opt signature | Bundler-style semver |
| Superpowers catalog | Flat + git repo | Git pull only | Git commit signature | git submodules |
| GitHub Spec-Kit | Repo-based (per project repo) | Source clone atau git submodule | GitHub auth | git submodule |
| OpenSpec registry | `openspec-<package>` | PyPI-style registry | TBD pilot | pip semver |
| Hermes skills dir | `~/.hermes/skills/<name>/` | Local filesystem, manual sync | User self-curated | Manual |

---

## 3. Implementation

### Skill Package Anatomy

```
my-awesome-skill/
├── manifest.json          ← registry metadata
├── SKILL.md               ← trigger conditions + body
├── references/
│   └── api-spec.md
├── templates/
│   └── .env.example
├── scripts/
│   └── verify.sh
└── tests/
    └── trigger.md         ← eval scenarios
```

`manifest.json`:

```json
{
  "name": "my-awesome-skill",
  "namespace": "azhar457",
  "version": "1.2.0",
  "description": "Migrate Go project ke Rust dengan Hermes workflow",
  "tags": ["rust", "migration", "go", "azhar"],
  "hermes_version_min": "2.1.0",
  "author": {
    "name": "Azhar",
    "github": "azhar457",
    "email_hash": "sha256:..."
  },
  "dependencies": {
    "skills": [
      {"name": "rust-patterns", "version": "^2.0.0"},
      {"name": "git-workflow", "version": "^1.0.0"}
    ]
  },
  "capabilities_required": ["filesystem.read", "terminal.exec"],
  "license": "MIT",
  "checksum": "sha256:a3f5e8...",
  "signature": "ed25519:..."
}
```

### Install Command (Claude Code plugin marketplace mechanism)

Claude Code commands yang diketahui jamak:

```bash
# Add plugin via marketplace
claude plugin add @superpowers/cargo-mutants

# List installed plugins
claude plugin list

# Update plugin (semver-aware)
claude plugin update @superpowers/cargo-mutants

# Remove plugin
claude plugin remove @superpowers/cargo-mutants
```

Untuk Hermes skill system (current):

```bash
# Local skill installation (manual)
mv ~/Downloads/my-awesome-skill ~/.hermes/skills/

# Hermes agent akan auto-discover via mcp__skill_router__list_available_skills()
```

### Skill Package Publishing (example)

```bash
# 1. Verify skill (lint, test, sign)
hermes skill lint my-awesome-skill
hermes skill sign --key ~/.ssh/signing_ed25519 my-awesome-skill

# 2. Publish ke marketplace
claude plugin publish --registry=anthropic-official

# 3. Audit trail post-publish (file di registry dengan checksum + signature)
#    Maintainer sendiri bisa revoke via `claude plugin revoke @azhar457/my-awesome-skill@1.2.0`
```

### Concrete Skill Author Pattern (dengan Hermes)

Contoh real skill body yang mendukung marketplace distribution:

```markdown
---
name: cargo-mutants-agent-guide
description: "Use when user wants to add Rust mutation testing via cargo-mutants. Loads cargo-mutants usage patterns, integration CI patterns, dan pitfalls di weak assertions."
tags: [rust, mutation-testing, ci, coding-agent, cargo-mutants]
metadata:
  hermes:
    min_version: "2.1.0"
    signature_b64: "..."
related_skills:
  - test-driven-development
  - agent-skills-feedback-sensors
platforms: [linux]
---

# cargo-mutants — Mutation Testing for Rust

Mutation testing is the most honest signal for test suite quality. cargo-mutants inject bugs ke Rust codebase, jalankan tests, lapor test yang tidak catch mutation.

## Trigger Conditions

User asks for any of:
- "add mutation testing to this Rust project"
- "cargo-mutants setup"
- "this test suite weak?"
- "improve test signal"

## Numbered Steps

1. Install: `cargo install cargo-mutants`
2. Configure `mutants.toml` in root project:
   ```toml
   [config]
   execlude_files = ["tests/", "benches/"]
   ```
3. Run baseline: `cargo mutants -j 4`
4. Generate HTML report: `cargo mutants --output-formats html`
5. Triage mutations by `Missed` (test doesn't catch — fix assertions)
6. Integrate via CI job weekly (not per-commit, lihat pitfalls di bawah)

## Pitfalls

- **False positive early-stage**: codebase belum cover → banyak Missed mutations. Threshold dulu: catch > 80%, baru lint gate
- **Test isolation**: mutation mutates source → mid-test panic bisa cascade. Run dengan `--no-restart` untuk fail-fase
- **Slow tests**: integration tests slow → cargo-mutants sekrang palakad. Skip `--in-place tests/` dengan `-e`

## Verification

```bash
cargo mutants --version
cargo mutants -j 4 --output-formats json
```

Output:
- `missed_outcomes.json` — list mutations caught by tests
- `status_outcomes.json` — overall summary

Untuk CI gate: parse JSON, check `missed.length / total.length < 0.2`.

## Related Concepts

- [[agent-skills-feedback-sensors-deepdive]] — cargo-mutants sbg deterministic sensor in harness
- [[test-driven-development]] — TDD RED phase sebagai fallback signal
- ThoughtWorks Radar Vol.34 blip #71 cargo-mutants

---

*Skill craft: azhar457 — 2026-07-19*
```

Cross-link: contoh ini menghubungkan marketplace, [[agent-skills-feedback-sensors-deepdive]], dan ThoughtWorks Radar Vol.34.

---

## 4. Comparison / Tradeoff

| Marketplace | Authoring style | Distribution | Versioning | Trust | Best untuk |
|-------------|-----------------|--------------|-----------|-------|----------|
| **Claude Code plugin marketplace** | SKILL.md + package | Anthropic-hosted CDN = signature | Semver strict | Maintainer verifikasi + signature ed25519 | Cross-team skill distribution, production agents |
| **Superpowers catalog** | Markdown skills catalog | Git repo pull | Git submodule bump | Git author | Small team / community-curated |
| **GitHub Spec-Kit** | Spec-based skill dev | Per-repo submodule | Git tags | GitHub commit | Spec-driven project workflow |
| **OpenSpec registry** | Open spec marketplace | PyPI-like package index | PEP 440 | TBD pilot | Open-source project skill sharing |
| **Hermes local skills dir** | SKILL.md filesystem-based | Manual copy / dotfiles | Filesystem sync | User self-curated | Personal workflow, local-only, not shared |
| **No marketplace / ad-hoc** | Slack paste, gist | None | None | None | Quick experiment, throwaway |

**Kapan pake apa:**

- **Single developer vault + Hermes**: pakai local skills dir, dotfiles repo, sync manual. No need marketplace.
- **Cross-team internal**: Claude Code plugin marketplace dengan private registry, atau internal git submodule collection.
- **Open-source community contribution**: Superpowers catalog atau OpenSpec tergantung style.
- **Production multi-tenant**: signature verification, CDN-pulled updates, kill-switch di registry side.

---

## 5. Deployment / Monitoring

### Versioning Strategy

- **Semver**: `MAJOR.MINOR.PATCH`
  - MAJOR: trigger conditions berubah (skill bisa gak match prompt lagi)
  - MINOR: tambahan numbered steps / pitfalls, tapi backward-compat trigger
  - PATCH: fix factual errors, typo, validation pass

- **Alias model** (Anthropic convention):
  - `@azhar457/cargo-mutants@^1.2` → menerima 1.2.x, reject 1.3
  - `@azhar457/cargo-mutants@1` → menerima 1.x.x, reject 2.0

### Signing & Trust Verification

Skill content tampering = berbahaya sama seperti dependency tampering (npm, pip). Recepi:

```bash
# 1. Generate signer key (one-time)
ssh-keygen -t ed25519 -f ~/.ssh/skill_signing_ed25519

# 2. Sign the manifest
ssh-keygen -Y sign -f ~/.ssh/skill_signing_ed25519 manifest.json

# 3. Publish repo
claude plugin publish

# Consumer side → verify
claude plugin install @azhar457/cargo-mutants@1.2.0 --verify-signature
```

### Kill-Switch Registry Side

Untuk public marketplace: maintainer bisa revoke publish dengan cryptographic proof. Anthropic-hosted registry punya backdoor via `reports/(maintainer-account)/revoke`. Saat revocation detected di consumer side (version check), skill auto-deactivated sebelum invoke.

### Telemetry & Usage Metrics

Marketplace harus track:
- Install count per version
- Failure rate per skill invocation (anonymized, just aggregate count)
- Time-to-discovery (publish → first install)
- Avg skill body length (proxy for instruction density)
- Consumer `capabilities_required` request distribution

Penting: alert kalau ada skill yang tiba-tiba spike aktivitas tapi tidak ada maintainer event (commit atau release). Itu pattern exfiltration.

### Dependencies Build Graph Resolver

Skill bisa depend on skill:

```
@azhar457/cargo-mutants-agent-guide
└── @rust-patterns/rust-testing-patterns@^2.0
    ├── @rust-patterns/rust-core@^1.5
    └── @agent-skills/github-spec-kit@^1.0
```

Resolver: topological sort. Sama seperti cargo / npm. Cycle detection mandatory. "Version union" via `^` (caret) → accept any minor within same major.

---

## Referensi

1. ThoughtWorks Technology Radar Vol.34 (April 2026) blip #72 Claude Code plugin marketplace (Trial). https://www.thoughtworks.com/radar/tools/claude-code-plugin-marketplace
2. ThoughtWorks Radar PDF. https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2026/04/tr_technology_radar_vol_34_en.pdf
3. ThoughtWorks Radar blip #115 Superpowers. https://www.thoughtworks.com/radar/languages-and-frameworks/superpowers
4. ThoughtWorks Radar blip #112 GitHub Spec-Kit. https://www.thoughtworks.com/radar/languages-and-frameworks/github-spec-kit
5. ThoughtWorks Radar blip #88 OpenSpec. https://www.thoughtworks.com/radar/tools/openspec
6. ThoughtWorks Radar blip #7 Agent Skills. https://www.thoughtworks.com/radar/techniques/agent-skills
7. Anthropic, "Claude Code Plugin Marketplace — Protocol". https://docs.anthropic.com/en/docs/claude-code/plugins
8. Hermes Agent skill spec. https://hermes-agent.nousresearch.com/docs/skills
9. Martin Fowler, "Harness Engineering". https://martinfowler.com/articles/harness-engineering.html
10. OpenSpec GitHub Project. https://github.com/openspec-dev/openspec
11. Anthropic Engineering Blog — "Building Agent Skills". https://www.anthropic.com/news/agent-skills
12. Hashicorp "Plugin Marketplace Patterns". https://developer.hashicorp.com/wap/registry
13. PyPI package signing. https://peps.python.org/pep-0458/
14. npm package signing (sigstore). https://docs.npmjs.com/guides/verifying-package-signatures
15. [[agent-skills-feedback-sensors-deepdive]] — catatan parent soal Agent Skills
16. [[agentic-ai-mcp-architecture-deepdive]] — MCP architecture soal tool registration
17. [[unified-mcp-server]] — Hermes MCP server spec
18. [[context7-mcp-deepdive]] — production MCP server example, integrating publishing patterns
19. [[prompt-engineering-patterns]] — konten skill pattern
20. [[ai-assisted-dev-workflow]] — workflow Hermes + Claude Code

---

*Skill marketplace distribution pattern · cross-link ke [agent-skills-feedback-sensors-deepdive] untuk harness engineering integration · v1.0 — July 2026*
