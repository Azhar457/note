---
title: CLI PR Review Guide
tags: [atlas, github, workflow]
aliases: [cli-pr-review-guide]
---
# CLI PR Review Guide

Review PR dari terminal (gh CLI): (1) `gh pr list` — lihat open PR; (2) `gh pr view <n>` — detail + diff; (3) `gh pr checkout <n>` — checkout branch; (4) `gh pr diff` — diff langsung; (5) review: fokus pada logic, security (input validation, secrets, auth), test adequacy, e2e; (6) `gh pr review <n> --approve` / `--request-changes` / `--comment`; (7) CI status: `gh pr checks <n>`.

Best practice: review dalam < 24 jam, PR kecil ( < 400 baris), gunakan template, link issue terkait. Automasi: CODEOWNERS, required reviews (2), branch protection, Dependabot. Security review checklist: hardcoded secret? (gitleaks di CI), dependency baru? (SCA), authz diperiksa? (BOLA).
---

  audited
---