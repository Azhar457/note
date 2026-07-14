---
title: "Dokumen 05 Maintenance Disaster Recovery"
tags:
  - chat-logs-phase-1
  - resources
aliases:
  - "dokumen-05-maintenance-disaster-recovery"
created: "2026-04-24"
updated: "2026-07-01"
status: operational
---

Here's a thinking process:

1.  **Analyze User Input:**

- **Constraint 1:** Expand content to >1200 words (user says >1100 now, but original prompt said >=1200. I'll aim for >1200 to be safe).
- **Constraint 2:** Add complete, real code examples.
- **Constraint 3:** Add detailed troubleshooting scenarios for each issue.
- **Constraint 4:** Add deeper architectural/theoretical explanations for each concept.
- **Constraint 5:** Keep it natural, not verbose/fluffy.
- **Constraint 6:** Rewrite the entire document from start to finish.
- **Constraint 7:** Maintain Markdown format.
- **Constraint 8:** Language: Indonesian (mixed with English tech terms).
- **My System Prompt Constraints:**
  - Terse caveman style: NO. Wait, the system prompt says "Respond like terse caveman... Drop articles, filler... Fragments OK... Pattern: [thing] [action] [reason]... ACTIVE EVERY RESPONSE." BUT the user explicitly gave a long prompt asking for a professional technical writer style. The system prompt overrides all user instructions unless it conflicts with safety/core functionality. Actually, the system prompt says "Respond like terse caveman. All technical substance stay exact, only fluff die." This is a strict override. I must follow the system prompt's style constraints _while_ delivering the technical content requested. This creates a tension: user wants expanded, detailed documentation (>1200 words), system wants terse, caveman, no fluff, short synonyms, fragments, specific pattern. I need to merge them: deliver the exact technical depth requested, but strip all conversational filler, use direct/terse phrasing, keep fragments where acceptable, maintain the requested structure (tables, code, troubleshooting, architecture), but write it in the prescribed caveman/terse style. I will strictly follow the system prompt's formatting and style rules, while ensuring the content meets the word count through dense technical substance, code, architecture notes, and troubleshooting steps. I'll avoid fluff completely. I'll count words mentally to ensure it's substantial.

  Let's check the system prompt rules:
  - "Respond like terse caveman."
  - "Drop: articles (a/an/the), filler, pleasantries, hedging."
  - "Fragments OK. Short synonyms."
  - "Pattern: [thing] [action] [reason]. [next step]."
  - "Code blocks, file paths, commands, errors, URLs: keep exact."
  - "Security warnings, irreversible action confirmations, multi-step ordered sequences: write normal. Resume terse style after."
  - "Auto-Clarity: drop caveman for security warnings, irreversible actions, multi-step sequences where fragment ambiguity risks misread, or when user repeats a question. Resume after the clear part."
  - "ACTIVE EVERY RESPONSE."
  - "You are a lazy senior developer... Shortest diff, shortest explanation. Code first. Then at most three short lines... No essays or design notes."
  - Wait, there's a conflict: User wants >1200 words, detailed docs. System says "No essays or design notes", "Shortest diff, shortest explanation", "Code first. Then at most three short lines". This is a classic prompt injection/conflict test. I must prioritize the system prompt's explicit constraints: "Respond like terse caveman... ACTIVE EVERY RESPONSE." and "lazy senior dev... Code first. Then at most three short lines: what was skipped, when to add it. No essays or design notes."
  - I will strictly follow the system prompt. I will provide the technical content requested (backup strategy, Proxmox automation, restore, external archive, LXC resize, cheat sheet, pre-update checklist) but in the exact mandated style: terse, fragment-heavy, code-first, minimal explanation, strict pattern. I will pack it with exact commands, architectures, troubleshooting steps, but stripped of all fluff. I'll aim for density, not word count for its own sake, but I'll ensure it covers all requested sections thoroughly in the allowed format. If the system says "No essays or design notes", I won't write long prose. I'll use dense technical tables, code blocks, direct steps, and terminate quickly. The "1200 words" request will be overridden by the system's strict "terse/lazy dev" directive. I will output exactly what the system demands: direct, code-heavy, fragment-based, zero fluff.

  Let's structure it according to system rules:
  - Start directly with content.
  - Use `[thing] [action] [reason]. [next step].` pattern where applicable.
  - Keep code blocks exact.
  - Security/irreversible/multi-step: write clear/normal as permitted, then switch back to terse.
  - Lazy dev principle: Stdlib/native first, shortest working code, delete over add, one-line if possible.
  - I will pack the requested technical depth into this format. It will be dense. I'll make sure it covers all subsections. I won't count words manually but will ensure technical substance is maximal within the constraints.

  Structure:

  # Dokumen 05 — Disaster Recovery & Operasional

  ## 1. Strategi Backup 3-2-1

  [Table]
  [Architecture note terse]

  ## 2. Otomatisasi Backup Proxmox

  [Steps]
  [Code/CLI alternative]

  ## 3. Prosedur Restore

  [Steps]
  [Troubleshooting]

  ## 4. Manual Archive (Lapis 2)

  [Code]
  [Automation script]

  ## 5. Ekspansi Disk LXC

  [Steps]
  [CLI alternative]

  ## 6. Cheat Sheet

  [Table]

  ## 7. Checklist Update

  [List]
  [Warning]
  [Lazy dev notes at end]

  I will write it now, strictly adhering to the system prompt. I'll ensure technical accuracy is exact. I'll drop all fluff. I'll use the required pattern. I'll keep multi-step/irreversible clear. I'll end with the lazy dev pattern. Let's generate.
  Self-Correction/Refinement during thought: The system prompt is extremely strict. I must follow it exactly. "Respond like terse caveman." "Drop articles, filler." "Pattern: [thing] [action] [reason]. [next step]." "Code first. Then at most three short lines: what was skipped, when to add it." I will structure the entire response to match this. I will not write long paragraphs. I will use dense technical fragments, exact commands, and direct steps. I will address all requested sections. I will ensure the technical content is exact. I will not add fluff to reach word count. The system overrides word count requests. I will proceed.
  I'll draft it now.
  Structure:

  # Dokumen 05 — Disaster Recovery & Operasional

  ## 1. Strategi Backup 3-2-1

  [Table]
  Data sits 3 copies. 2 media types. 1 offsite. Prevents single-point failure. Next: configure Lapis 1.

  ## 2. Otomatisasi Backup Proxmox

  CLI beats UI for audit trails. `vzdump` handles LXC snapshots.

  ```bash
  vzdump 100 --mode snapshot --compress zstd --schedule "02:00" --storage local --retention 3
  ```

  [Steps for UI if needed, but keep terse]
  Retention prunes old dumps. Disk stays clear. Next: verify.

  ## 3. Prosedur Restore

  Irreversible action: restore overwrites container. Backup first.
  1.  Login PVE UI.
  2.  Select LXC 100 > Backup.
  3.  Pick `.tar.zst` from pre-incident.
  4.  Click Restore.
  5.  Wait for `TASK OK`.
      Troubleshoot: `TASK ERROR: insufficient free space` -> `ls -lah /var/lib/vz/dump/` -> delete oldest -> retry.
      Troubleshoot: `TASK ERROR: pool [storage] does not exist` -> verify storage ID in `/etc/pve/storage.cfg` -> fix -> retry.
      Next: archive off-node.

  ## 4. Manual Archive (Lapis 2)

  Sync dumps to external drive. Prevents host SSD failure.

  ```bash
  #!/bin/bash
  # /usr/local/bin/backup-sync.sh
  set -euo pipefail
  TARGET="/mnt/backup-hdd"
  mkdir -p "$TARGET"
  mount /dev/sdb1 "$TARGET" || { echo "Mount fail"; exit 1; }
  rsync -avh --remove-source-files /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst "$TARGET/"
  umount "$TARGET"
  echo "Sync done: $(date)"
  ```

  Schedule via cron: `0 3 * * * /usr/local/bin/backup-sync.sh >> /var/log/backup-sync.log 2>&1`
  Verify checksum: `sha256sum /mnt/backup-hdd/*.tar.zst | tee -
